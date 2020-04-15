unit KM_ResMapElements;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KromUtils,
  KM_CommonTypes, KM_Defaults;


type
  TKMKillByRoad = (kbrNever, kbrNWCorner, kbrWest);

  TKMChopableAge = (caAge1, caAge2, caAge3, caAgeFull, caAgeFall, caAgeStump);

  TKMChopableAgeSet = set of TKMChopableAge;

  TKMMapElement = packed record
    Anim: TKMAnimLoop;          //Animation loop info
    CuttableTree: LongBool;     //This tree can be cut by a woodcutter
    DiagonalBlocked: LongBool;  //Can't walk diagonally accross this object (mainly trees)
    AllBlocked: LongBool;       //All passibility blocked. Can't walk, swim, etc. EXCEPT BUILD
    WineOrCorn: LongBool;       //Draw multiple (4 or 2) sprites per object (corn or grapes)
    CanGrow: LongBool;          //This object can grow (i.e. change to another object)
    DontPlantNear: LongBool;    //This object can't be planted within one tile of
    Stump: ShortInt;            //Tree stump ID
    CanBeRemoved: LongBool;     //Can be removed in favor of building house (actually means we can build over this object)
    KillByRoad: TKMKillByRoad;  //Object will be removed if these neighboring tiles are roads
  end;

  TKMResMapElements = class
  private
    fCount: Integer;
    fCRC: Cardinal;
  public
    property Count: Integer read fCount;
    property CRC: Cardinal read fCRC;

    procedure LoadFromFile(const FileName: string);
    procedure SaveToFile(const FileName: string);
    procedure ExportToText(const FileName: string);
  end;


  function ObjectIsChoppableTree(aObjId: Integer): Boolean; overload;
  function ObjectIsChoppableTree(aObjId: Integer; aStage: TKMChopableAge): Boolean; overload;
  function ObjectIsChoppableTree(aObjId: Integer; aStages: TKMChopableAgeSet): Boolean; overload;

  function ObjectIsCorn(aObjId: Integer): Boolean;
  function ObjectIsWine(aObjId: Integer): Boolean;


const
  OBJECTS_CNT = 255;

var
  //MapElem is in global access because of the recursive FloodFill algorithm
  //when it uses TKMResMapElements.MapElem each call takes 8 times more memory
  //on the stack (View>Debug>CPU>Stack) for reasons unknown to me.
  gMapElements: array [0..OBJECTS_CNT] of TKMMapElement;


const
  //Chopable tree, Chopdown animation,
  //Age1, Age2, Age3, Age4, Falling, Stump
  ChopableTrees: array [1..13, TKMChopableAge] of Word = (
  //For grass
  (  88,  89,  90,  90,  91,  37), //These two are very look alike
  (  97,  98,  99, 100, 101,  41), //yet different in small detail and fall direction
  ( 102, 103, 104, 105, 106,  45),
  ( 107, 108, 109, 110, 111,  41),
  ( 112, 113, 114, 114, 115,  25), //These two are very look alike
  ( 116, 117, 118, 119, 120,  25), //yet different in small detail and fall direction
  //For grass and yellow
  (  92,  93,  94,  95,  96,  49),
  //For yellow soil only
  ( 121, 122, 123, 124, 125,  64),
  //For dirt (pine trees)
  ( 149, 150, 151, 151, 152,  29),
  ( 153, 154, 155, 155, 156,  29),
  ( 157, 158, 159, 160, 161,  33),
  ( 162, 163, 164, 165, 166,  33),
  ( 167, 168, 169, 170, 171,  33));

  //Ages at which trees/fields grow up/change sprite multiplied by TERRAIN_PACE
  TREE_AGE_1 = 2400 div TERRAIN_PACE;
  TREE_AGE_2 = 5000 div TERRAIN_PACE;
  TREE_AGE_FULL = 8000 div TERRAIN_PACE; //Tree is old enough to be chopped

  CORN_STAGES_COUNT = 7; //0..6
  //0 = empty field, 1 = sown corn, 2 = young seedings, 3 = seedings,
  //4 = greenish corn , 5 = ready to be cut, 6 = corn has been cut

  CORN_AGE_1 = 1400 div TERRAIN_PACE;    //Measured from KaM ~150sec
  CORN_AGE_2 = 2200 div TERRAIN_PACE;   //Number measured from KaM ~195sec
  CORN_AGE_3 = 4400 div TERRAIN_PACE;
  CORN_AGE_FULL = 6400 div TERRAIN_PACE; //Corn ready to be cut
  CORN_AGE_MAX = 255; //todo: Remove. We set it to this once it's fully grown

  //Wine values have been tweaked for balance. In KaM they matched corn.
  WINE_STAGES_COUNT = 4; //0..3
  //0 = new fruits, 1 = starts to grow, 2 = continues to grow, 3 = ready to be harvested

  WINE_AGE_1 = 1600 div TERRAIN_PACE;
  WINE_AGE_2 = 3400 div TERRAIN_PACE;
  WINE_AGE_FULL = 5000 div TERRAIN_PACE; //Wine ready to be harvested

implementation

const
  ObjKillByRoads : array [Byte] of Byte = (
    1, 2, 2, 2, 2, 2, 1, 1, 0, 0, 2, 2, 2, 1, 1, 1,
    1, 2, 2, 2, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 1, 2, 1, 1, 1, 1, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 2, 2, 0, 0, 1, 0, 1, 1, 1, 1, 0, 2, 2, 2,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

{ TKMResMapElements }
//Reading map elements properties and animation data
procedure TKMResMapElements.LoadFromFile(const FileName: string);
const
  ELEMENT_SIZE = 99; // Old size of TKMMapElement (before we have added our fields to it)
var
  S: TMemoryStream;
  I: Integer;
begin
  if not FileExists(FileName) then Exit;

  S := TMemoryStream.Create;
  S.LoadFromFile(FileName);
  for I := Low(gMapElements) to High(gMapElements) do
  begin
    S.Read(gMapElements[I], ELEMENT_SIZE);
    gMapElements[I].KillByRoad := TKMKillByRoad(ObjKillByRoads[I]);
  end;
  fCount := S.Size div ELEMENT_SIZE; //254 by default
  fCRC := Adler32CRC(S);
  S.Free;

  gMapElements[63].Anim.Count := 1;
  gMapElements[63].Anim.Step[1] := 16;
  gMapElements[63].CuttableTree := False;
  gMapElements[63].DiagonalBlocked := False;
  gMapElements[63].AllBlocked := False;
  gMapElements[63].WineOrCorn := False;
  gMapElements[63].CanGrow := False;
  gMapElements[63].DontPlantNear := False;
  gMapElements[63].Stump := -1;
  gMapElements[63].CanBeRemoved := True;

  //Save ti file if we want to have it there. For now hardcoded is ok
  //SaveToFile(FileName);
end;


procedure TKMResMapElements.SaveToFile(const FileName: string);
var
  S: TMemoryStream;
begin
  S := TMemoryStream.Create;
  S.Write(gMapElements[0], fCount * SizeOf(TKMMapElement));
  S.SaveToFile(FileName);
  S.Free;
end;


procedure TKMResMapElements.ExportToText(const FileName: string);
var
  I: Integer; ft: TextFile;
  Str1, Str2, Str3, Str4, Str5, Str6, Str7: String;
begin
  AssignFile(ft, ExeDir + 'Trees.txt');
  Rewrite(ft);
  Str1 := 'not AllBlocked and Block Build: ';
  Str2 := 'AllBlocked and Allow Build: ';
  Str3 := 'DiagonalBlocked and AllBlocked: ';
  Str4 := 'DiagonalBlocked and Can Build: ';
  Str5 := 'DiagonalBlocked and Can not build: ';
  Str6 := 'AllBlocked and and Block Build: ';
  Str7 := 'Stump <> -1: ';
  for I := 1 to fCount do
  begin
    //Writeln(ft);
    Write(ft, inttostr(I) + ' Anim: ' + inttostr(gMapElements[I].Anim.Count));
//    for K := 1 to 30 do
//      if gMapElements[I].Anim.Step[K] > 0 then
//        Write(ft, gMapElements[I].Anim.Step[K], '.')
//      else
//        Write(ft, '_.');
    Write(ft, '; DiagonalBlocked = ', gMapElements[I].DiagonalBlocked);
    Write(ft, '; AllBlocked = ', gMapElements[I].AllBlocked);
    Write(ft, '; CanBeRemoved = ', gMapElements[I].CanBeRemoved);
    Write(ft, '; Stump = ', IntToStr(gMapElements[I].Stump));
    Writeln(ft);

    if (gMapElements[I].Anim.Count > 0) and (gMapElements[I].Anim.Step[1] > 0)
      and (gMapElements[I].Stump = -1) then
    begin
      if not gMapElements[I].AllBlocked and not gMapElements[I].CanBeRemoved then
        Str1 := Str1 + IntToStr(I) + ' ';

      if gMapElements[I].AllBlocked and gMapElements[I].CanBeRemoved then
        Str2 := Str2 + IntToStr(I) + ' ';

      if gMapElements[I].AllBlocked and not gMapElements[I].CanBeRemoved then
        Str6 := Str6 + IntToStr(I) + ' ';

      if gMapElements[I].DiagonalBlocked and gMapElements[I].AllBlocked then
        Str3 := Str3 + IntToStr(I) + ' ';

      if gMapElements[I].DiagonalBlocked and gMapElements[I].CanBeRemoved then
        Str4 := Str4 + IntToStr(I) + ' ';

      if gMapElements[I].DiagonalBlocked and not gMapElements[I].CanBeRemoved then
        Str5 := Str5 + IntToStr(I) + ' ';
    end;

    if gMapElements[I].Stump <> -1 then
      Str7 := Str7 + IntToStr(I) + ' ';
    // for K:=1 to 16 do
    // write(ft,MapElem[I].CuttableTree,''); //Those are 1/0 so we can ommit space between them


    //Writeln(ft);
  end;
  Writeln(ft);
  Writeln(ft, Str1);
  Writeln(ft);
  Writeln(ft, Str2);
  Writeln(ft);
  Writeln(ft, Str6);
  Writeln(ft);
  Writeln(ft, Str3);
  Writeln(ft);
  Writeln(ft, Str4);
  Writeln(ft);
  Writeln(ft, Str5);
  Writeln(ft);
  Writeln(ft, Str7);
  CloseFile(ft);
end;


function ObjectIsChoppableTree(aObjId: Integer): Boolean;
var
  I: Integer;
  K: TKMChopableAge;
begin
  Result := True;

  for I := 1 to Length(ChopableTrees) do
    for K := Low(TKMChopableAge) to High(TKMChopableAge) do
      if (aObjId = ChopableTrees[I,K]) then Exit;

  Result := False;
end;


function ObjectIsChoppableTree(aObjId: Integer; aStage: TKMChopableAge): Boolean;
var
  I: Integer;
begin
  Result := True;

  for I := 1 to Length(ChopableTrees) do
    if (aObjId = ChopableTrees[I, aStage]) then Exit;

  Result := False;
end;


function ObjectIsChoppableTree(aObjId: Integer; aStages: TKMChopableAgeSet): Boolean;
var
  I: Integer;
  Stage: TKMChopableAge;
begin
  Result := True;

  for I := 1 to Length(ChopableTrees) do
    for Stage in aStages do
      if (aObjId = ChopableTrees[I, Stage]) then Exit;

  Result := False;
end;


function ObjectIsCorn(aObjId: Integer): Boolean;
begin
  Result := aObjId in [58..59];
end;


function ObjectIsWine(aObjId: Integer): Boolean;
begin
  Result := aObjId in [54..57];
end;


end.

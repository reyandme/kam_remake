unit KM_CommonClasses;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KM_Points, KM_CommonTypes;


type
  { Extended with custom Read/Write commands which accept various types without asking for their length}
  TKMemoryStream = class(TMemoryStream)
  public
    {$DEFINE PERMIT_ANSI_STRING}
    {$IFDEF PERMIT_ANSI_STRING}
    //Legacy format for campaigns info, maxlength 65k ansichars
    procedure ReadA(out Value: AnsiString); reintroduce; overload;
    procedure WriteA(const Value: AnsiString); reintroduce; overload;
    //Assert for savegame sections
    procedure ReadAssert(const Value: AnsiString);

    //Ansistrings saved by PascalScript into savegame
    procedure ReadHugeString(out Value: AnsiString); overload;
    procedure WriteHugeString(const Value: AnsiString); overload;
    {$ENDIF}

    procedure ReadHugeString(out Value: UnicodeString); overload;
    procedure WriteHugeString(const Value: UnicodeString); overload;

    //Replacement of ReadAnsi for legacy use (campaign Ids (short names) in CMP)
    procedure ReadBytes(out Value: TBytes);
    procedure WriteBytes(const Value: TBytes);

    //Unicode strings
    procedure ReadW(out Value: UnicodeString); reintroduce; overload;
    procedure WriteW(const Value: UnicodeString); reintroduce; overload;

    //ZLib's decompression streams don't work with the normal TStreams.CopyFrom since
    //it uses ReadBuffer. This procedure will work when Source is a TDecompressionStream
    procedure CopyFromDecompression(Source: TStream);

    procedure Write(const Value:TKMPointDir ); reintroduce; overload;
    function Write(const Value:TKMDirection): Longint; reintroduce; overload;
    function Write(const Value:TKMPoint ): Longint; reintroduce; overload;
    function Write(const Value:TKMPointW): Longint; reintroduce; overload;
    function Write(const Value:TKMPointF): Longint; reintroduce; overload;
    function Write(const Value:TKMRangeInt): Longint; reintroduce; overload;
    function Write(const Value:TKMRangeSingle): Longint; reintroduce; overload;
    function Write(const Value:TKMRect  ): Longint; reintroduce; overload;
    function Write(const Value:Single   ): Longint; reintroduce; overload;
    function Write(const Value:Integer  ): Longint; reintroduce; overload;
    function Write(const Value:Cardinal ): Longint; reintroduce; overload;
    function Write(const Value:Byte     ): Longint; reintroduce; overload;
    function Write(const Value:Boolean  ): Longint; reintroduce; overload;
    function Write(const Value:Word     ): Longint; reintroduce; overload;
    function Write(const Value:ShortInt ): Longint; reintroduce; overload;
    function Write(const Value:SmallInt ): Longint; reintroduce; overload;
    function Write(const Value:TDateTime): Longint; reintroduce; overload;

    procedure Read(out Value:TKMPointDir); reintroduce; overload;
    function Read(out Value:TKMDirection): Longint; reintroduce; overload;
    function Read(out Value:TKMPoint    ): Longint; reintroduce; overload;
    function Read(out Value:TKMPointW   ): Longint; reintroduce; overload;
    function Read(out Value:TKMPointF   ): Longint; reintroduce; overload;
    function Read(out Value:TKMRangeInt ): Longint; reintroduce; overload;
    function Read(out Value:TKMRangeSingle): Longint; reintroduce; overload;
    function Read(out Value:TKMRect     ): Longint; reintroduce; overload;
    function Read(out Value:Single      ): Longint; reintroduce; overload;
    function Read(out Value:Integer     ): Longint; reintroduce; overload;
    function Read(out Value:Cardinal    ): Longint; reintroduce; overload;
    function Read(out Value:Byte        ): Longint; reintroduce; overload;
    function Read(out Value:Boolean     ): Longint; reintroduce; overload;
    function Read(out Value:Word        ): Longint; reintroduce; overload;
    function Read(out Value:ShortInt    ): Longint; reintroduce; overload;
    function Read(out Value:SmallInt    ): Longint; reintroduce; overload;
    function Read(out Value:TDateTime   ): Longint; reintroduce; overload;
  end;

  TStreamEvent = procedure (aData: TKMemoryStream) of object;
  TStreamIntEvent = procedure (aData: TKMemoryStream; aSenderIndex: ShortInt) of object;

  //TXStringList using integer values, instead of its String represantation, when sorted
  TXStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;


  //TKMList owns items and frees them when they are deleted from the list
  TKMList = class(TList)
  protected
    //This one function is enough to free all deleted/cleared/rewritten objects
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  end;

  TKMPointList = class
  private
    fCount: Integer;
    fItems: array of TKMPoint; //0..Count-1
    function GetPoint(aIndex: Integer): TKMPoint; inline;
    procedure SetPoint(aIndex: Integer; const aValue: TKMPoint); inline; //1..Count
    function GetLast: TKMPoint;
  public
    constructor Create;

    property Count: Integer read fCount write fCount;
    property Items[aIndex: Integer]: TKMPoint read GetPoint write SetPoint; default;
    property Last: TKMPoint read GetLast;
    function IsEmpty: Boolean;

    procedure Clear; virtual;
    procedure Copy(aSrc: TKMPointList);
    procedure Add(const aLoc: TKMPoint);
    procedure AddList(aList: TKMPointList);
    procedure AddUnique(const aLoc: TKMPoint);
    procedure AddListUnique(aList: TKMPointList);
    function  Remove(const aLoc: TKMPoint): Integer; virtual;
    procedure Delete(aIndex: Integer); virtual;
    procedure Insert(ID: Integer; const aLoc: TKMPoint);
    function  GetRandom(out Point: TKMPoint): Boolean;
    function  GetClosest(const aLoc: TKMPoint; out Point: TKMPoint): Boolean;
    function Contains(const aLoc: TKMPoint): Boolean;
    function IndexOf(const aLoc: TKMPoint): Integer;
    procedure Inverse;
    procedure SparseToDense;
    function  GetBounds(out Bounds: TKMRect): Boolean;
    procedure SaveToStream(SaveStream: TKMemoryStream); virtual;
    procedure LoadFromStream(LoadStream: TKMemoryStream); virtual;
  end;

  TKMPointListArray = array of TKMPointList;

  TKMPointTagList = class(TKMPointList)
  public
    Tag, Tag2: array of Cardinal; //0..Count-1
    procedure Clear; override;
    procedure Add(const aLoc: TKMPoint; aTag: Cardinal; aTag2: Cardinal = 0); reintroduce;
    function IndexOf(const aLoc: TKMPoint; aTag: Cardinal; aTag2: Cardinal): Integer;
    procedure SortByTag;
    function Remove(const aLoc: TKMPoint): Integer; override;
    procedure Delete(aIndex: Integer); override;
    procedure SaveToStream(SaveStream: TKMemoryStream); override;
    procedure LoadFromStream(LoadStream: TKMemoryStream); override;
  end;


  TKMPointDirList = class //Used for finding fishing places, fighting positions, etc.
  private
    fItems: array of TKMPointDir; //0..Count-1
    fCount: Integer;
    function GetItem(aIndex: Integer): TKMPointDir;
  public
    procedure Clear;
    procedure Add(const aLoc: TKMPointDir);
    property Count: Integer read fCount;
    property Items[aIndex: Integer]: TKMPointDir read GetItem; default;
    function GetRandom(out Point: TKMPointDir):Boolean;
    procedure LoadFromStream(LoadStream: TKMemoryStream); virtual;
    procedure SaveToStream(SaveStream: TKMemoryStream); virtual;
  end;


  TKMPointDirTagList = class(TKMPointDirList)
  public
    Tag: array of Cardinal; //0..Count-1
    procedure Add(const aLoc: TKMPointDir; aTag: Cardinal); reintroduce;
    procedure SortByTag;
    procedure SaveToStream(SaveStream: TKMemoryStream); override;
    procedure LoadFromStream(LoadStream: TKMemoryStream); override;
  end;


  TKMMapsCRCList = class
  private
    fMapsList: TStringList;
    fOnMapsUpdate: TUnicodeStringEvent;

    procedure MapsUpdated;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromString(const aString: UnicodeString);
    function PackToString: UnicodeString;

    property OnMapsUpdate: TUnicodeStringEvent read fOnMapsUpdate write fOnMapsUpdate;

    procedure Clear;
    procedure RemoveMissing(aMapsCRCArray: TKMCardinalArray);
    function Contains(aMapCRC: Cardinal): Boolean;
    procedure Add(aMapCRC: Cardinal);
    procedure Remove(aMapCRC: Cardinal);
    procedure Replace(aOldCRC, aNewCRC: Cardinal);
  end;


  //Custom Exception that includes a TKMPoint
  ELocError = class(Exception)
    Loc: TKMPoint;
    constructor Create(const aMsg: UnicodeString; const aLoc: TKMPoint);
  end;


implementation
uses
  Math, KM_CommonUtils;

const
  MAPS_CRC_DELIMITER = ':';

{TXStringList}
//List custom comparation, using Integer value, instead of its String represantation
function TXStringList.CompareStrings(const S1, S2: string): Integer;
var
  i1, i2, e1, e2: Integer;
begin
  Val(S1, i1, e1);
  Assert((e1 = 0) or (S1[e1] = NameValueSeparator));
  Val(S2, i2, e2);
  Assert((e2 = 0) or (S2[e2] = NameValueSeparator));
  Result := CompareValue(i1, i2);
end;

{ ELocError }
constructor ELocError.Create(const aMsg: UnicodeString; const aLoc: TKMPoint);
begin
  inherited Create(aMsg);
  Loc := aLoc;
end;


{ TKMList }
//We were notified that the item is deleted from the list
procedure TKMList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  inherited;
  if (Action = lnDeleted) then
    TObject(Ptr).Free;
end;


{ TKMemoryStream }
{$IFDEF PERMIT_ANSI_STRING}
procedure TKMemoryStream.ReadA(out Value: AnsiString);
var I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;

procedure TKMemoryStream.WriteA(const Value: AnsiString);
var I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;

procedure TKMemoryStream.ReadHugeString(out Value: AnsiString);
var I: Cardinal;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;

procedure TKMemoryStream.WriteHugeString(const Value: AnsiString);
var I: Cardinal;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;

procedure TKMemoryStream.ReadHugeString(out Value: UnicodeString);
var I: Cardinal;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I * SizeOf(WideChar));
end;

procedure TKMemoryStream.WriteHugeString(const Value: UnicodeString);
var I: Cardinal;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I * SizeOf(WideChar));
end;

procedure TKMemoryStream.ReadAssert(const Value: AnsiString);
var S: AnsiString;
begin
  ReadA(s);
  Assert(s = Value, 'TKMemoryStream.Read <> Value: '+Value);
end;
{$ENDIF}


procedure TKMemoryStream.WriteW(const Value: UnicodeString);
var I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I * SizeOf(WideChar));
end;

procedure TKMemoryStream.ReadBytes(out Value: TBytes);
var
  I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I);
end;

procedure TKMemoryStream.WriteBytes(const Value: TBytes);
var
  I: Word;
begin
  I := Length(Value);
  inherited Write(I, SizeOf(I));
  if I = 0 then Exit;
  inherited Write(Pointer(Value)^, I);
end;

procedure TKMemoryStream.Write(const Value: TKMPointDir);
begin
  Write(Value.Loc);
  inherited Write(Value.Dir, SizeOf(Value.Dir));
end;

function TKMemoryStream.Write(const Value: TKMDirection): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TKMPoint): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TKMPointW): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TKMPointF): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TKMRangeInt): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TKMRangeSingle): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TKMRect): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:single): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:integer): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:cardinal): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:byte): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:boolean): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:word): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:shortint): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:smallint): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;

function TKMemoryStream.Write(const Value:TDateTime): Longint;
begin Result := inherited Write(Value, SizeOf(Value)); end;


procedure TKMemoryStream.ReadW(out Value: UnicodeString);
var I: Word;
begin
  Read(I, SizeOf(I));
  SetLength(Value, I);
  if I > 0 then
    Read(Pointer(Value)^, I * SizeOf(WideChar));
end;


procedure TKMemoryStream.Read(out Value: TKMPointDir);
begin
  Read(Value.Loc);
  Read(Value.Dir, SizeOf(Value.Dir));
end;

function TKMemoryStream.Read(out Value:TKMDirection): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TKMPoint): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TKMPointW): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TKMPointF): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TKMRangeInt ): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TKMRangeSingle ): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TKMRect): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:single): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:integer): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:cardinal): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:byte): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:boolean): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:word): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:shortint): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:smallint): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;

function TKMemoryStream.Read(out Value:TDateTime): Longint;
begin Result := inherited Read(Value, SizeOf(Value)); end;


procedure TKMemoryStream.CopyFromDecompression(Source: TStream);
const
  MaxBufSize = $F000;
var
  Count: Integer;
  Buffer: PByte;
begin
  Source.Position := 0;
  GetMem(Buffer, MaxBufSize);
  try
    Count := Source.Read(Buffer^, MaxBufSize);
    while Count > 0 do
    begin
      WriteBuffer(Buffer^, Count);
      Count := Source.Read(Buffer^, MaxBufSize);
    end;
  finally
    FreeMem(Buffer, MaxBufSize);
  end;
end;


{ TKMPointList }
constructor TKMPointList.Create;
begin
  inherited;
end;


procedure TKMPointList.Clear;
begin
  fCount := 0;
end;


procedure TKMPointList.Add(const aLoc: TKMPoint);
begin
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 32);
  fItems[fCount] := aLoc;
  Inc(fCount);
end;


procedure TKMPointList.AddList(aList: TKMPointList);
var
  I: Integer;
begin
  for I := 0 to aList.Count - 1 do
    Add(aList[I]);
end;


procedure TKMPointList.AddUnique(const aLoc: TKMPoint);
begin
  if not Contains(aLoc) then
    Add(aLoc);
end;


procedure TKMPointList.AddListUnique(aList: TKMPointList);
var
  I: Integer;
begin
  for I := 0 to aList.Count - 1 do
    AddUnique(aList[I]);
end;


//Remove point from the list if is there. Return index of removed entry or -1 on failure
function TKMPointList.Remove(const aLoc: TKMPoint): Integer;
var
  I: Integer;
begin
  Result := -1;

  //Scan whole list to detect duplicate entries
  for I := 0 to fCount - 1 do
    if KMSamePoint(fItems[I], aLoc) then
      Result := I;

  //Remove found entry
  if (Result <> -1) then
    Delete(Result);
end;


procedure TKMPointList.Delete(aIndex: Integer);
begin
  if not InRange(aIndex, 0, Count-1) then Exit;
  if (aIndex <> fCount - 1) then
    Move(fItems[aIndex+1], fItems[aIndex], SizeOf(fItems[aIndex]) * (fCount - 1 - aIndex));
  Dec(fCount);
end;


//Insert an entry and check if list is still walkable
//Walkable means that every point is next to neighbour points }
procedure TKMPointList.Insert(ID: Integer; const aLoc: TKMPoint);
begin
  Assert(InRange(ID, 0, fCount));

  //Grow the list
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 32);

  //Shift items towards end
  if fCount <> 0 then
    Move(fItems[ID], fItems[ID+1], SizeOf(fItems[ID]) * (fCount - ID));

  fItems[ID] := aLoc;
  Inc(fCount);
end;


function TKMPointList.GetRandom(out Point: TKMPoint): Boolean;
begin
  Result := fCount <> 0;
  if Result then
    Point := fItems[KaMRandom(fCount, 'TKMPointList.GetRandom')];
end;


function TKMPointList.GetClosest(const aLoc: TKMPoint; out Point: TKMPoint): Boolean;
var
  I: Integer;
begin
  Result := fCount <> 0;
  if Result then
  begin
    Point := fItems[0];
    for I := 1 to fCount - 1 do
    if KMLengthSqr(fItems[I], aLoc) < KMLengthSqr(Point, aLoc) then
      Point := fItems[I];
  end;
end;


function TKMPointList.Contains(const aLoc: TKMPoint): Boolean;
begin
  Result := IndexOf(aLoc) <> -1;
end;


function TKMPointList.IndexOf(const aLoc: TKMPoint): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := fCount - 1 downto 0 do
  if KMSamePoint(aLoc, fItems[I]) then
  begin
    Result := I;
    Break;
  end;
end;


function TKMPointList.GetLast: TKMPoint;
begin
  if IsEmpty then
    raise Exception.Create('No points in list');
  Result := fItems[fCount - 1];
end;


function TKMPointList.IsEmpty: Boolean;
begin
  Result := fCount = 0;
end;


procedure TKMPointList.Copy(aSrc: TKMPointList);
begin
  fCount := aSrc.Count;
  SetLength(fItems, fCount);

  Move(aSrc.fItems[0], fItems[0], SizeOf(fItems[0]) * fCount);
end;


function TKMPointList.GetPoint(aIndex: Integer): TKMPoint;
begin
  Result := fItems[aIndex];
end;


procedure TKMPointList.SetPoint(aIndex: Integer; const aValue: TKMPoint);
begin
  fItems[aIndex] := aValue;
end;


//Reverse the list
procedure TKMPointList.Inverse;
var
  I: Integer;
begin
  for I := 0 to fCount div 2 - 1 do
    KMSwapPoints(fItems[I], fItems[fCount-1-I]);
end;


//Used in JPS pathfinding
//Take the sparse walk route with nodes in corners (A------B)
//and add all the missing nodes inbetween like so: (A123456B)
procedure TKMPointList.SparseToDense;
var
  I,K,J: Integer;
  Tmp: array of TKMPoint;
  Span: Word;
  C,N: ^TKMPoint;
begin
  K := 0;
  SetLength(Tmp, 8192);
  for I := 0 to fCount - 1 do
  begin
    Tmp[K] := fItems[I];
    Inc(K);

    if (I <> fCount - 1) then
    begin
      C := @fItems[I];
      N := @fItems[I+1];
      Span := Max(Abs(N.X - C.X), Abs(N.Y - C.Y));
      for J := 1 to Span - 1 do
      begin
        Tmp[K].X := C.X + Round((N.X - C.X) / Span * J);
        Tmp[K].Y := C.Y + Round((N.Y - C.Y) / Span * J);
        Inc(K);
      end;
    end;
  end;

  fCount := K;
  SetLength(fItems, fCount);
  Move(Tmp[0], fItems[0], SizeOf(fItems[0]) * fCount);
end;


function TKMPointList.GetBounds(out Bounds: TKMRect): Boolean;
var I: Integer;
begin
  Result := fCount <> 0;

  if Result then
  begin
    //Something to start with
    Bounds.Left   := fItems[0].X;
    Bounds.Top    := fItems[0].Y;
    Bounds.Right  := fItems[0].X;
    Bounds.Bottom := fItems[0].Y;
    for I := 1 to fCount - 1 do
    begin
      if fItems[I].X < Bounds.Left then Bounds.Left := fItems[I].X;
      if fItems[I].Y < Bounds.Top then Bounds.Top := fItems[I].Y;
      if fItems[I].X > Bounds.Right then Bounds.Right := fItems[I].X;
      if fItems[I].Y > Bounds.Bottom then Bounds.Bottom := fItems[I].Y;
    end;
  end;
end;


procedure TKMPointList.SaveToStream(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fCount);
  if fCount > 0 then
    SaveStream.Write(fItems[0], SizeOf(fItems[0]) * fCount);
end;


procedure TKMPointList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fCount);
  SetLength(fItems, fCount);
  if fCount > 0 then
    LoadStream.Read(fItems[0], SizeOf(fItems[0]) * fCount);
end;


{ TKMPointTagList }
procedure TKMPointTagList.Clear;
begin
  inherited;
end;


procedure TKMPointTagList.Add(const aLoc: TKMPoint; aTag: Cardinal; aTag2: Cardinal = 0);
begin
  inherited Add(aLoc);

  if fCount >= Length(Tag) then  SetLength(Tag, fCount + 32); //Expand the list
  if fCount >= Length(Tag2) then SetLength(Tag2, fCount + 32); //+32 is just a way to avoid further expansions
  Tag[fCount-1]  := aTag;
  Tag2[fCount-1] := aTag2;
end;


function TKMPointTagList.IndexOf(const aLoc: TKMPoint; aTag, aTag2: Cardinal): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := fCount - 1 downto 0 do
  if KMSamePoint(aLoc, fItems[I]) and (aTag = Tag[I]) and (aTag2 = Tag2[I]) then
  begin
    Result := I;
    Break;
  end;
end;


function TKMPointTagList.Remove(const aLoc: TKMPoint): Integer;
begin
  Result := inherited Remove(aLoc);
  //Tags are moved by Delete function. No need to move them here
end;


procedure TKMPointTagList.Delete(aIndex: Integer);
begin
  if not InRange(aIndex, 0, Count-1) then Exit;

  inherited Delete(aIndex);

  //Note that fCount is already decreased by 1
  if (aIndex <> fCount) then
  begin
    Move(Tag[aIndex+1], Tag[aIndex], SizeOf(Tag[aIndex]) * (fCount - aIndex));
    Move(Tag2[aIndex+1], Tag2[aIndex], SizeOf(Tag2[aIndex]) * (fCount - aIndex));
  end;
end;


procedure TKMPointTagList.SaveToStream(SaveStream: TKMemoryStream);
begin
  inherited; //Writes Count

  if fCount > 0 then
  begin
    SaveStream.Write(Tag[0], SizeOf(Tag[0]) * fCount);
    SaveStream.Write(Tag2[0], SizeOf(Tag2[0]) * fCount);
  end;
end;


procedure TKMPointTagList.SortByTag;
  // Quicksort implementation (because there is not specified count of elements buble does not give any sense)
  procedure QuickSort(MinIdx,MaxIdx: Integer);
  var
    I,K,X: Integer;
  begin
    I := MinIdx;
    K := MaxIdx;
    X := Tag[ (MinIdx+MaxIdx) div 2 ];
    repeat
      while (Tag[I] < X) do
        I := I + 1;
      while (X < Tag[K]) do
        K := K - 1;
      if (I <= K) then
      begin
        KMSwapPoints(fItems[I], fItems[K]);
        KMSwapInt(Tag[I], Tag[K]);
        KMSwapInt(Tag2[I], Tag2[K]);
        I := I + 1;
        K := K - 1;
      end;
    until (I > K);
    if (MinIdx < K) then
      QuickSort(MinIdx,K);
    if (I < MaxIdx) then
      QuickSort(I,MaxIdx);
  end;

//var I,K: Integer;
begin
  // Buble sort
  //for I := 0 to fCount - 1 do
  //  for K := I + 1 to fCount - 1 do
  //    if Tag[K] < Tag[I] then
  //    begin
  //      KMSwapPoints(fItems[I], fItems[K]);
  //      KMSwapInt(Tag[I], Tag[K]);
  //      KMSwapInt(Tag2[I], Tag2[K]);
  //    end;
  if (fCount > 1) then
    QuickSort(0, fCount - 1);
end;


procedure TKMPointTagList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  inherited; //Reads Count

  SetLength(Tag, fCount);
  SetLength(Tag2, fCount);
  if fCount > 0 then
  begin
    LoadStream.Read(Tag[0], SizeOf(Tag[0]) * fCount);
    LoadStream.Read(Tag2[0], SizeOf(Tag2[0]) * fCount);
  end;
end;


{ TKMPointList }
procedure TKMPointDirList.Clear;
begin
  fCount := 0;
end;


procedure TKMPointDirList.Add(const aLoc: TKMPointDir);
begin
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 32);
  fItems[fCount] := aLoc;
  inc(fCount);
end;


function TKMPointDirList.GetItem(aIndex: Integer): TKMPointDir;
begin
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fItems[aIndex];
end;


function TKMPointDirList.GetRandom(out Point: TKMPointDir):Boolean;
begin
  Result := False;
  if fCount > 0 then
  begin
    Point := fItems[KaMRandom(fCount, 'TKMPointDirList.GetRandom')];
    Result := True;
  end;
end;


procedure TKMPointDirList.SaveToStream(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fCount);
  if fCount > 0 then
    SaveStream.Write(fItems[0], SizeOf(fItems[0]) * fCount);
end;


procedure TKMPointDirList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fCount);
  SetLength(fItems, fCount);
  if fCount > 0 then
    LoadStream.Read(fItems[0], SizeOf(fItems[0]) * fCount);
end;


procedure TKMPointDirTagList.Add(const aLoc: TKMPointDir; aTag: Cardinal);
begin
  inherited Add(aLoc);

  if fCount >= Length(Tag) then SetLength(Tag, fCount + 32); //Expand the list
  Tag[fCount-1] := aTag;
end;


procedure TKMPointDirTagList.SortByTag;
var
  I, K: Integer;
begin
  for I := 0 to fCount - 1 do
  for K := I + 1 to fCount - 1 do
  if Tag[K] < Tag[I] then
  begin
    KMSwapPointDir(fItems[I], fItems[K]);
    KMSwapInt(Tag[I], Tag[K]);
  end;
end;


procedure TKMPointDirTagList.SaveToStream(SaveStream: TKMemoryStream);
begin
  inherited; //Writes Count

  if fCount > 0 then
    SaveStream.Write(Tag[0], SizeOf(Tag[0]) * fCount);
end;


procedure TKMPointDirTagList.LoadFromStream(LoadStream: TKMemoryStream);
begin
  inherited; //Reads Count

  SetLength(Tag, fCount);
  if fCount > 0 then
    LoadStream.Read(Tag[0], SizeOf(Tag[0]) * fCount);
end;


{ TKMMapsCRCList }
constructor TKMMapsCRCList.Create;
begin
  inherited;
  fMapsList := TStringList.Create;
  fMapsList.Delimiter       := MAPS_CRC_DELIMITER;
  fMapsList.StrictDelimiter := True; // Requires D2006 or newer.
end;


destructor TKMMapsCRCList.Destroy;
begin
  FreeAndNil(fMapsList);
  inherited;
end;


procedure TKMMapsCRCList.MapsUpdated;
begin
  if Assigned(fOnMapsUpdate) then
    fOnMapsUpdate(PackToString);
end;


procedure TKMMapsCRCList.LoadFromString(const aString: UnicodeString);
var I: Integer;
    MapCRC : Int64;
    StringList: TStringList;
begin
  fMapsList.Clear;
  StringList := TStringList.Create;
  StringList.Delimiter := MAPS_CRC_DELIMITER;
  StringList.DelimitedText   := Trim(aString);

  for I := 0 to StringList.Count - 1 do
  begin
    if TryStrToInt64(Trim(StringList[I]), MapCRC)
      and (MapCRC > 0)
      and not Contains(Cardinal(MapCRC)) then
      fMapsList.Add(Trim(StringList[I]));
  end;

  StringList.Free;
end;


function TKMMapsCRCList.PackToString: UnicodeString;
begin
  Result := fMapsList.DelimitedText;
end;


procedure TKMMapsCRCList.Clear;
begin
  fMapsList.Clear;
end;


//Remove missing Favourites Maps from list, check if are of them are presented in the given maps CRC array.
procedure TKMMapsCRCList.RemoveMissing(aMapsCRCArray: TKMCardinalArray);
  function ArrayContains(aValue: Cardinal): Boolean;
  var I: Integer;
  begin
    Result := False;
    for I := Low(aMapsCRCArray) to High(aMapsCRCArray) do
      if aMapsCRCArray[I] = aValue then
      begin
        Result := True;
        Break;
      end;
  end;
var I: Integer;
begin
  I := fMapsList.Count - 1;
  //We must check, that all values from favorites are presented in maps CRC array. If not - then remove it from favourites
  while (fMapsList.Count > 0) and (I >= 0) do
  begin
    if not ArrayContains(StrToInt64(fMapsList[I])) then
    begin
      fMapsList.Delete(I);
      MapsUpdated;
    end;

    Dec(I);
  end;
end;


function TKMMapsCRCList.Contains(aMapCRC: Cardinal): Boolean;
begin
  Result := fMapsList.IndexOf(IntToStr(aMapCRC)) <> -1;
end;


procedure TKMMapsCRCList.Add(aMapCRC: Cardinal);
begin
  if not Contains(aMapCRC) then
  begin
    fMapsList.Add(IntToStr(aMapCRC));
    MapsUpdated;
  end;
end;


procedure TKMMapsCRCList.Remove(aMapCRC: Cardinal);
var Index: Integer;
begin
  Index := fMapsList.IndexOf(IntToStr(aMapCRC));
  if Index <> -1 then
    fMapsList.Delete(Index);
  MapsUpdated;
end;


procedure TKMMapsCRCList.Replace(aOldCRC, aNewCRC: Cardinal);
begin
  if Contains(aOldCRC) then
  begin
    Remove(aOldCRC);
    Add(aNewCRC);
  end;
end;


end.

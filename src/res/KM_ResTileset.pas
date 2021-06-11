unit KM_ResTileset;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KromUtils,
//  KM_IoXML,
  KM_Defaults, KM_CommonTypes, KM_CommonClasses, KM_ResTilesetTypes;


var
  // Mirror tiles arrays, according to the tiles corners terrain kinds
  // If no mirror tile is found, then self tile is set by default
  // for tiles below 256 we set default tiles (themselfs)
  ResTileset_MirrorTilesH: array [0..TILES_CNT-1] of Integer; // mirror horizontally
  ResTileset_MirrorTilesV: array [0..TILES_CNT-1] of Integer; // mirror vertically

type
  TKMTilesParamsArray = array[0..TILES_CNT - 1] of TKMTileParams;

  TKMResTileset = class
  private
    fTiles: TKMTilesParamsArray;

//    fXML: TKMXmlDocument;
    fCRC: Cardinal;

    TileTable: array [1 .. 30, 1 .. 30] of packed record
      Tile1, Tile2, Tile3: Byte;
      b1, b2, b3, b4, b5, b6, b7: Boolean;
    end;

    function GetTerKindsCnt(aTile: Word): Integer;

//    function LoadPatternDAT(const FileName: string): Boolean;
//    procedure InitRemakeTiles;

    procedure InitMirrorTiles;

//    function GetTilesXMLPath: string;
    function GetTilesJsonPath: string;

    function GetTileParams(aIndex: Word): TKMTileParams;
  public
//    PatternDAT: array [1..TILES_CNT] of packed record
//      MinimapColor: Byte;
//      Walkable: Byte;  //This looks like a bitfield, but everything besides <>0 seems to have no logical explanation
//      Buildable: Byte; //This looks like a bitfield, but everything besides <>0 seems to have no logical explanation
//      u1: Byte; // 1/2/4/8/16 bitfield, seems to have no logical explanation
//      u2: Byte; // 0/1 Boolean? seems to have no logical explanation
//      u3: Byte; // 1/2/4/8 bitfield, seems to have no logical explanation
//    end;

    constructor Create;
    destructor Destroy; override;

    property CRC: Cardinal read fCRC;

//    procedure ExportPatternDat(const aFilename: string);

    {$IFDEF BATCHER}
    property Tiles: TKMTilesParamsArray read fTiles write fTiles;
    {$ENDIF}

    property Tile[aIndex: Word]: TKMTileParams read GetTileParams; default;
    procedure SetTilesColor(var aTilesColor: TKMColor3bArray);

    function TileIsWater(aTile: Word): Boolean;
    function TileHasWater(aTile: Word): Boolean;
    function TileIsIce(aTile: Word): Boolean;
    function TileIsSand(aTile: Word): Boolean;
    function TileIsStone(aTile: Word): Word;
    function TileIsSnow(aTile: Word): Boolean;
    function TileIsCoal(aTile: Word): Word;
    function TileIsIron(aTile: Word): Word;
    function TileIsGold(aTile: Word): Word;
    function TileIsSoil(aTile: Word): Boolean;
    function TileIsWalkable(aTile: Word): Boolean;
    function TileIsRoadable(aTile: Word): Boolean;
    function TileIsCornField(aTile: Word): Boolean;
    function TileIsWineField(aTile: Word): Boolean;

    function TileIsGoodForIronMine(aTile: Word): Boolean;
    function TileIsGoodForGoldMine(aTile: Word): Boolean;

    function TileIsCorner(aTile: Word): Boolean;
    function TileIsEdge(aTile: Word): Boolean;

//    procedure SaveToXML;

    procedure SaveToJson(aCompact: Boolean = False; aSaveStream: TKMemoryStream = nil);
    procedure LoadFromJson;

    class function TileIsAllowedToSet(aTile: Word): Boolean;
  end;


implementation
uses
  TypInfo, Math,
  JsonDataObjects,
  KM_FileIO,
  KM_CommonUtils, KM_CommonClassesExt;

const
//  TILES_XML_PATH = 'data' + PathDelim + 'defines' + PathDelim + 'tiles.xml';
  TILES_JSON_PATH = 'data' + PathDelim + 'defines' + PathDelim + 'tiles.json';

  TILES_NOT_ALLOWED_TO_SET: array [0..13] of Word = (
    55,59,60,61,62,63,              // wine and corn
    //189,169,185,                  // duplicates of 108,109,110
    248,249,250,251,252,253,254,255 // roads and overlays
  );


{ TKMResTileset }
constructor TKMResTileset.Create;
var
//  I: Integer;
  crcStream: TKMemoryStream;
begin
  inherited;

  LoadFromJson;

  crcStream := TKMemoryStream.Create;
  try
    SaveToJson(True, crcStream);
    fCRC := Adler32CRC(crcStream);
  finally
    crcStream.Free;
  end;

  InitMirrorTiles;

//  LoadPatternDAT(aPatternPath);
//  InitRemakeTiles;

//  for I := 0 to TILES_CNT - 1 do
//  begin
//    fTiles[I] := TKMTileParams.Create;
//    fTiles[I].ID          := I;
//    fTiles[I].Walkable    := TileIsWalkable(I);
//    fTiles[I].Roadable    := TileIsRoadable(I);
//    fTiles[I].Water       := TileIsWater(I);
//    fTiles[I].HasWater    := TileHasWater(I);
//    fTiles[I].Ice         := TileIsIce(I);
//    fTiles[I].Sand        := TileIsSand(I);
//    fTiles[I].Stone       := TileIsStone(I);
//    fTiles[I].Snow        := TileIsSnow(I);
//    fTiles[I].Coal        := TileIsCoal(I);
//    fTiles[I].Gold        := TileIsGold(I);
//    fTiles[I].Iron        := TileIsIron(I);
//    fTiles[I].Soil        := TileIsSoil(I);
//    fTiles[I].Corn        := TileIsCornField(I);
//    fTiles[I].Wine        := TileIsWineField(I);
//    fTiles[I].IronMinable := TileIsGoodForIronMine(I);
//    fTiles[I].GoldMinable := TileIsGoodForGoldMine(I);
//    fTiles[I].TerKinds[0] := TILE_CORNERS_TERRAIN_KINDS[I, 0];
//    fTiles[I].TerKinds[1] := TILE_CORNERS_TERRAIN_KINDS[I, 1];
//    fTiles[I].TerKinds[2] := TILE_CORNERS_TERRAIN_KINDS[I, 2];
//    fTiles[I].TerKinds[3] := TILE_CORNERS_TERRAIN_KINDS[I, 3];
//  end;


//  fXML := TKMXmlDocument.Create;
end;


destructor TKMResTileset.Destroy;
var
  I: Integer;
begin
//  fXML.Free;

  for I := TILES_CNT - 1 downto 0 do
    fTiles[I].Free;

  inherited;
end;


//procedure TKMResTileset.InitRemakeTiles;
//const
//  //ID in png_name
//  WALK_BUILD:     array[0..185] of Integer = (257,262,264,274,275,283,291,299,302,303,304,305,306,313,314,315,316,317,318,319,//20
//                                              320,321,322,338,352,355,362,363,364,365,366,367,368,369,374,375,376,377,378,379,//40
//                                              380,381,384,385,386,387,390,391,392,393,398,399,400,401,402,403,404,405,410,411,//60
//                                              412,413,414,415,416,417,420,421,422,423,426,427,428,429,434,435,436,437,438,439,//80
//                                              440,441,446,447,448,449,450,451,452,453,458,459,460,461,462,463,464,465,470,471,//100
//                                              472,473,474,475,476,477,480,481,482,483,486,487,488,489,494,495,496,497,498,499,//120
//                                              500,501,506,507,508,509,510,511,512,513,518,519,520,521,522,523,524,525,530,531,//140
//                                              532,533,534,535,536,537,540,541,542,543,546,547,548,549,554,555,556,557,558,559,//160
//                                              560,561,566,567,568,569,570,571,572,573,578,579,580,581,582,583,584,585,590,591,//180
//                                              592,593,594,595,596,597);
//  WALK_NO_BUILD:   array[0..106] of Integer = (258,263,269,270,271,272,278,279,280,281,286,287,288,289,294,295,296,297,309,310,//20
//                                              311,312,339,350,351,353,356,358,359,360,361,370,371,372,373,382,383,388,389,394,//40
//                                              395,396,397,406,407,408,409,418,419,424,425,430,431,432,433,442,443,444,445,454,//60
//                                              455,456,457,466,467,468,469,478,479,484,485,490,491,492,493,502,503,504,505,514,//80
//                                              515,516,517,526,527,528,529,538,539,544,545,550,551,552,553,562,563,564,565,574,//100
//                                              575,576,577,586,587,588,589);
//  NO_WALK_NO_BUILD: array[0..44] of Integer = (259,260,261,265,266,267,268,273,276,277,282,284,285,290,292,293,298,300,301,307,//20
//                                              308,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,340,341,342,343,//40
//                                              344,345,346,354,357);
//var
//  I: Integer;
//begin
//  for I := Low(WALK_BUILD) to High(WALK_BUILD) do
//  begin
//    Assert(WALK_BUILD[I] > 255); //We init only new tiles with ID > 255
//    PatternDAT[WALK_BUILD[I]].Walkable := 1;
//    PatternDAT[WALK_BUILD[I]].Buildable := 1;
//  end;
//
//  for I := Low(WALK_NO_BUILD) to High(WALK_NO_BUILD) do
//  begin
//    Assert(WALK_NO_BUILD[I] > 255); //We init only new tiles with ID > 255
//    PatternDAT[WALK_NO_BUILD[I]].Walkable := 1;
//    PatternDAT[WALK_NO_BUILD[I]].Buildable := 0;
//  end;
//
//  for I := Low(NO_WALK_NO_BUILD) to High(NO_WALK_NO_BUILD) do
//  begin
//    Assert(NO_WALK_NO_BUILD[I] > 255); //We init only new tiles with ID > 255
//    PatternDAT[NO_WALK_NO_BUILD[I]].Walkable := 0;
//    PatternDAT[NO_WALK_NO_BUILD[I]].Buildable := 0;
//  end;
//
//  InitMirrorTiles;
//end;


procedure TKMResTileset.InitMirrorTiles;
const
  MIRROR_TILES_INIT_FROM = 256;
var
  I, J, K: Integer;
  skipH, skipV: Boolean;
begin
  // Init MirrorTilesH and MirrorTilesV
  // We can put into const arrays though, if needed for speedup the process
  for I := Low(fTiles) to High(fTiles) do
  begin
    skipH := False;
    skipV := False;

    // 'Self' mirror by default
    ResTileset_MirrorTilesH[I] := I;
    ResTileset_MirrorTilesV[I] := I;

    if I < MIRROR_TILES_INIT_FROM then
      Continue;

    // Skip if we have custom terrain here (maybe we can use it too?)
    for J := 0 to 3 do
      if fTiles[I].TerKinds[J] = tkCustom then
      begin
        skipH := True;
        skipV := True;
        Break;
      end;

    // Check if mirror tile is needed
    if (fTiles[I].TerKinds[0] = fTiles[I].TerKinds[1])
      and (fTiles[I].TerKinds[2] = fTiles[I].TerKinds[3]) then
      skipH := True;

    if (fTiles[I].TerKinds[0] = fTiles[I].TerKinds[3])
      and (fTiles[I].TerKinds[1] = fTiles[I].TerKinds[2]) then
      skipV := True;

    // try to find mirror tiles based on corners terrain kinds
    for K := MIRROR_TILES_INIT_FROM to High(fTiles) do
    begin
      if skipH and skipV then
        Break;

      if not skipH
        and (fTiles[I].TerKinds[0] = fTiles[K].TerKinds[1])
        and (fTiles[I].TerKinds[1] = fTiles[K].TerKinds[0])
        and (fTiles[I].TerKinds[2] = fTiles[K].TerKinds[3])
        and (fTiles[I].TerKinds[3] = fTiles[K].TerKinds[2]) then
      begin
        ResTileset_MirrorTilesH[I] := K;
        skipH := True;
      end;

      if not skipV
        and (fTiles[I].TerKinds[0] = fTiles[K].TerKinds[3])
        and (fTiles[I].TerKinds[3] = fTiles[K].TerKinds[0])
        and (fTiles[I].TerKinds[1] = fTiles[K].TerKinds[2])
        and (fTiles[I].TerKinds[2] = fTiles[K].TerKinds[1]) then
      begin
        ResTileset_MirrorTilesV[I] := K;
        skipV := True;
      end;
    end;
  end;
end;


//Reading pattern data (tile info)
//function TKMResTileset.LoadPatternDAT(const FileName: string): Boolean;
//var
//  I: Integer;
//  f: file;
//  s: Word;
//begin
//  Result := false;
//  if not FileExists(FileName) then
//    Exit;
//  AssignFile(f, FileName);
//  FileMode := fmOpenRead;
//  Reset(f, 1);
//  BlockRead(f, PatternDAT[1], 6 * 256);
//  for I := 1 to 30 do
//  begin
//    BlockRead(f, TileTable[I, 1], 30 * 10);
//    BlockRead(f, s, 1);
//  end;
//
//  CloseFile(f);
//  fCRC := Adler32CRC(FileName);
//
//  if WriteResourceInfoToTXT then
//    ExportPatternDat(ExeDir + 'Export'+PathDelim+'Pattern.csv');
//
//  Result := true;
//end;


procedure TKMResTileset.SetTilesColor(var aTilesColor: TKMColor3bArray);
var
  I: Integer;
begin
  Assert(Length(aTilesColor) = Length(fTiles));

  for I := Low(aTilesColor) to High(aTilesColor) do
    fTiles[I].MainColor := aTilesColor[I];
end;


//procedure TKMResTileset.ExportPatternDat(const aFileName: string);
//var
//  I, K: Integer;
//  ft: TextFile;
//begin
//  AssignFile(ft, ExeDir + 'Pattern.csv');
//  Rewrite(ft);
//  Writeln(ft, 'PatternDAT');
//  for I := 0 to 15 do
//  begin
//    for K := 1 to 16 do
//      write(ft, inttostr(I * 16 + K), ' ', PatternDAT[I * 16 + K].u1, ';');
//    writeln(ft);
//  end;
//  writeln(ft, 'TileTable');
//  for I := 1 to 30 do
//  begin
//    for K := 1 to 30 do
//    begin
//      write(ft, inttostr(TileTable[I, K].Tile1) + '_' + inttostr(TileTable[I, K].Tile2) + '_' +
//        inttostr(TileTable[I, K].Tile3) + ' ');
//      write(ft, inttostr(Word(TileTable[I, K].b1)));
//      write(ft, inttostr(Word(TileTable[I, K].b2)));
//      write(ft, inttostr(Word(TileTable[I, K].b3)));
//      write(ft, inttostr(Word(TileTable[I, K].b4)));
//      write(ft, inttostr(Word(TileTable[I, K].b5)));
//      write(ft, inttostr(Word(TileTable[I, K].b6)));
//      write(ft, inttostr(Word(TileTable[I, K].b7)));
//      write(ft, ';');
//    end;
//
//    writeln(ft);
//  end;
//  closefile(ft);
//end;


function TKMResTileset.GetTerKindsCnt(aTile: Word): Integer;
var
  I: Integer;
  terKinds: TKMTerrainKindSet;
begin
  terKinds := [];

  for I := 0 to 3 do
    Include(terKinds, fTiles[aTile].TerKinds[I]);

  Result := TSet<TKMTerrainKindSet>.Cardinality(terKinds);
end;


function TKMResTileset.TileIsCorner(aTile: Word): Boolean;
const
  CORNERS = [10,15,18,21..23,25,38,49,51..54,56,58,65,66,68..69,71,72,74,78,80,81,83,84,86..87,89,90,92,93,95,96,98,99,
             101,102,104,105,107..108,110..111,113,114,116,118,119,120,122,123,126..127,138,142,143,165,176..193,196,
             202,203,205,213,220,234..241,243,247];
begin
  if aTile in CORNERS then
    Exit(True);

  Result := GetTerKindsCnt(aTile) = 2;
end;


function TKMResTileset.TileIsEdge(aTile: Word): Boolean;
const
  EDGES = [4,12,19,39,50,57,64,67,70,73,76,79,82,85,88,91,94,97,
           100,103,106,109,112,115,117,121,124..125,139,141,166..175,194,198..200,
           204,206..212,216..219,223,224..233,242,244];
begin
  if aTile in EDGES then
    Exit(True);

  Result :=    ((fTiles[aTile].TerKinds[0] = fTiles[aTile].TerKinds[1])
            and (fTiles[aTile].TerKinds[2] = fTiles[aTile].TerKinds[3]))
          or   ((fTiles[aTile].TerKinds[0] = fTiles[aTile].TerKinds[3])
            and (fTiles[aTile].TerKinds[1] = fTiles[aTile].TerKinds[2]));
end;


// Check if requested tile is water suitable for fish and/or sail. No waterfalls, but swamps/shallow water allowed
function TKMResTileset.TileIsWater(aTile: Word): Boolean;
begin
  Result := fTiles[aTile].Water;

//  Result := aTile in [48,114,115,119,192,193,194,196, 200, 208..211, 235,236, 240,244];
end;


// Check if requested tile has ice
function TKMResTileset.TileIsIce(aTile: Word): Boolean;
begin
  Result := fTiles[aTile].Ice;
//  Result := aTile in [4, 10, 12, 22, 23, 44];
end;


// Check if requested tile has any water, including ground-water transitions
function TKMResTileset.TileHasWater(aTile: Word): Boolean;
begin
  Result := fTiles[aTile].HasWater;
//  Result := aTile in [48,105..107,114..127,142,143,192..194,196,198..200,208..211,230,232..244];
end;


// Check if requested tile is sand suitable for crabs
function TKMResTileset.TileIsSand(aTile: Word): Boolean;
const
  SAND_TILES: array[0..55] of Word =
                (31,32,33,70,71,99,100,102,103,108,109,112,113,116,117,169,173,181,189,269,273,302,319,320,
                 493,494,495,496,497,498,499,500,505,506,507,508,509,510,511,512,553,554,555,556,557,558,
                 559,560,565,566,567,568,569,570,571,572);
begin
  Result := fTiles[aTile].Sand;
//  Result := ArrayContains(aTile, SAND_TILES);
end;


// Check if requested tile is Stone and returns Stone deposit
function TKMResTileset.TileIsStone(aTile: Word): Word;
begin
  Result := fTiles[aTile].Stone;
//  case aTile of
//    132,137: Result := 5;
//    131,136: Result := 4;
//    130,135: Result := 3;
//    129,134,266,267,275,276,283,284,291,292: Result := 2;
//    128,133: Result := 1;
//    else     Result := 0;
//  end;
end;


// Check if requested tile is snow
function TKMResTileset.TileIsSnow(aTile: Word): Boolean;
const
  SNOW_TILES: array[0..46] of Word =
                (45, 46, 47, 49, 52, 64, 65, 166, 171, 203, 204, 205, 212, 213, 220, 256, 257, 261, 262,
                 286, 290, 294, 298, 304, 305, 312,313,314,315,317,318,433,434,435,436,437,438,439,440,
                 445,446,447,448,449,450,451,452);
begin
  Result := fTiles[aTile].Snow;
//  Result := ArrayContains(aTile, SNOW_TILES);
end;


function TKMResTileset.TileIsCoal(aTile: Word): Word;
begin
  Result := fTiles[aTile].Coal;
//  Result := 0;
//  if aTile > 151 then
//  begin
//    if aTile < 156 then
//      Result := aTile - 151
//    else
//      if aTile = 263 then
//        Result := 5;
//  end;
end;


function TKMResTileset.TileIsGoodForIronMine(aTile: Word): Boolean;
const
  IRON_MINE_TILES: array[0..58] of Word =
                      (109,166,167,168,169,170,257,338,355,369,370,371,372,387,
                       388,405,406,407,408,423,424,441,442,443,444,465,466,467,
                       468,483,484,501,502,503,504,525,526,527,528,483,484,501,
                       502,503,504,525,526,527,528,543,544,561,562,563,564,585,
                       586,587,588);
begin
  Result := fTiles[aTile].IronMinable;
//  Result := ArrayContains(aTile, IRON_MINE_TILES);
end;


function TKMResTileset.TileIsGoodForGoldMine(aTile: Word): Boolean;
const
  GOLD_MINE_TILES: array[0..46] of Word =
                      (171,172,173,174,175,262,352,357,358,359,360,381,382,393,394,395,
                       396,417,418,429,430,431,432,453,454,455,456,477,478,489,490,491,
                       492,505,513,515,516,537,538,549,550,551,552,573,574,575,576);
begin
  Result := fTiles[aTile].GoldMinable;
//  Result := ArrayContains(aTile, GOLD_MINE_TILES);
end;


function TKMResTileset.TileIsIron(aTile: Word): Word;
begin
  Result := fTiles[aTile].Iron;
//  Result := 0;
//  if aTile > 147 then
//  begin
//    if aTile < 152 then
//      Result := aTile - 147
//    else
//      case aTile of
//        259: Result := 3;
//        260: Result := 5;
//      end;
//  end;
end;


function TKMResTileset.TileIsGold(aTile: Word): Word;
begin
  Result := fTiles[aTile].Gold;
//  Result := 0;
//  if aTile > 143 then
//  begin
//    if aTile < 148 then
//      Result := aTile - 143
//    else
//      if aTile = 307 then
//        Result := 5;
//  end;
end;


// Check if requested tile is soil suitable for fields and trees
function TKMResTileset.TileIsSoil(aTile: Word): Boolean;
const
  SOIL_TILES: array[0..176] of Word =
                (0,1,2,3,5,6, 8,9,11,13,14, 16,17,18,19,20,21, 26,27,28, 34,35,36,37,38,39, 47, 49, 55,56,
                57,58,64,65,66,67,68,69,72,73,74,75,76,77,78,79,80, 84,85,86,87,88,89, 93,94,95,96,97,98,
                180,182,183,188,190,191,220,247,274,282,301,303, 312,313,314,315,316,317,318,337,351,354,
                361,362,363,364,365,366,367,368,373,374,375,376,377,378,379,380,383,384,385,386,389,390,
                391,392,397,398,399,400,401,402,403,404,409,410,411,412,413,414,415,416,419,420,421,422,
                425,426,427,428,433,434,435,436,437,438,439,440,445,446,447,448,449,450,451,452,457,458,
                459,460,461,462,463,464,469,470,471,472,473,474,475,476,577,578,579,580,581,582,583,584,
                589,590,591,592,593,594,595,596);
begin
  Result := fTiles[aTile].Soil;
//  Result := ArrayContains(aTile, SOIL_TILES);
end;


// Check if requested tile is generally walkable
function TKMResTileset.TileIsWalkable(aTile: Word): Boolean;
begin
  //Includes 1/2 and 3/4 walkable as walkable
  //Result := Land^[Loc.Y,Loc.X].BaseLayer.Terrain in [0..6, 8..11,13,14, 16..22, 25..31, 32..39, 44..47, 49,52,55, 56..63,
  //                                        64..71, 72..79, 80..87, 88..95, 96..103, 104,106..109,111, 112,113,116,117, 123..125,
  //                                        138..139, 152..155, 166,167, 168..175, 180..183, 188..191,
  //                                        197, 203..205,207, 212..215, 220..223, 242,243,247];
  //Values can be 1 or 2, What 2 does is unknown
//  Result := PatternDAT[aTile+1].Walkable <> 0;
  Result := fTiles[aTile].Walkable;
end;


// Check if requested tile is generally suitable for road building
function TKMResTileset.TileIsRoadable(aTile: Word): Boolean;
begin
  //Do not include 1/2 and 1/4 walkable as roadable
  //Result := Land^[Loc.Y,Loc.X].BaseLayer.Terrain in [0..3,5,6, 8,9,11,13,14, 16..21, 26..31, 32..39, 45..47, 49, 52, 55, 56..63,
  //                                        64..71, 72..79, 80..87, 88..95, 96..103, 104,108,111, 112,113,
  //                                        152..155,180..183,188..191,
  //                                        203..205, 212,213,215, 220, 247];
//  Result := PatternDAT[aTile+1].Buildable <> 0;
  Result := fTiles[aTile].Roadable;
end;


function TKMResTileset.TileIsCornField(aTile: Word): Boolean;
begin
  Result := fTiles[aTile].Corn;
//  Result := aTile in [59..63];
end;


function TKMResTileset.TileIsWineField(aTile: Word): Boolean;
begin
  Result := fTiles[aTile].Wine;
//  Result := aTile = 55;
end;


//function TKMResTileset.GetTilesXMLPath: string;
//begin
//  Result := ExeDir + TILES_XML_PATH;
//end;


function TKMResTileset.GetTilesJsonPath: string;
begin
  Result := ExeDir + TILES_JSON_PATH;
end;


function TKMResTileset.GetTileParams(aIndex: Word): TKMTileParams;
begin
  Assert(InRange(aIndex, 0, High(fTiles)));
  Result := fTiles[aIndex];
end;


//procedure TKMResTileset.SaveToXML;
//var
//  nTile: TKMXmlNode;
//
//  procedure AddTileBAttr(aName: string; aValue: Boolean);
//  begin
//    if aValue then
//      nTile.Attributes[aName] := aValue;
//  end;
//
//  procedure AddTileIAttr(aName: string; aValue: Integer);
//  begin
//    if aValue > 0 then
//      nTile.Attributes[aName] := aValue;
//  end;
//
//var
//  I, J, K: Integer;
//  animLayerStr: string;
//  nRoot, nTiles, nAnimLayer: TKMXmlNode;
//begin
//  nRoot := fXML.Root;
//
//  nRoot.Clear;
//
//  nTiles := nRoot.AddChild('Tiles');
//
//  for I := 0 to TILES_CNT - 1 do
//  begin
//    nTile := nTiles.AddChild('Tile');
//    nTile.Attributes['ID']          := I;
//    nTile.Attributes['Walkable']    := fTiles[I].Walkable;
//    nTile.Attributes['Roadable']    := fTiles[I].Roadable;
//
//    AddTileIAttr('Stone', fTiles[I].Stone);
//    AddTileIAttr('Coal',  fTiles[I].Coal);
//    AddTileIAttr('Iron',  fTiles[I].Iron);
//    AddTileIAttr('Gold',  fTiles[I].Gold);
//
//    AddTileBAttr('IronMinable', fTiles[I].IronMinable);
//    AddTileBAttr('GoldMinable', fTiles[I].GoldMinable);
//
//    AddTileBAttr('Water',      fTiles[I].Water);
//    AddTileBAttr('HasWater',   fTiles[I].HasWater);
//    AddTileBAttr('Ice',        fTiles[I].Ice);
//    AddTileBAttr('Sand',       fTiles[I].Sand);
//    AddTileBAttr('Snow',       fTiles[I].Snow);
//    AddTileBAttr('Soil',       fTiles[I].Soil);
//    AddTileBAttr('Corn',       fTiles[I].Corn);
//    AddTileBAttr('Wine',       fTiles[I].Wine);
//
//    nTile.Attributes['CornersTerKinds'] := GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[0])) + ',' +
//                                           GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[1])) + ',' +
//                                           GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[2])) + ',' +
//                                           GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[3]));
//
//    if not fTiles[I].Animation.HasAnim then Continue;
//
//    for J := Low(fTiles[I].Animation.Layers) to High(fTiles[I].Animation.Layers) do
//    begin
//      nAnimLayer := nTile.AddChild('AnimLayer');
//      nAnimLayer.Attributes['Frames'] := fTiles[I].Animation.Layers[J].Frames;
//
//      animLayerStr := '';
//      for K := Low(fTiles[I].Animation.Layers[J].Anims) to High(fTiles[I].Animation.Layers[J].Anims) do
//      begin
//        if animLayerStr <> '' then
//          animLayerStr := animLayerStr + ',';
//
//        animLayerStr := animLayerStr + IntToStr(fTiles[I].Animation.Layers[J].Anims[K]);
//      end;
//
//      nAnimLayer.Attributes['AnimIDs'] := animLayerStr;
//    end;
//  end;
//
//  fXML.SaveToFile(GetTilesXMLPath);
//end;


procedure TKMResTileset.SaveToJson(aCompact: Boolean = False; aSaveStream: TKMemoryStream = nil);
var
  nTile: TJsonObject;

  procedure AddTileBAttr(aName: string; aValue: Boolean);
  begin
    if aValue or aCompact then
      nTile.B[aName] := aValue;
  end;

  procedure AddTileIAttr(aName: string; aValue: Integer);
  begin
    if (aValue <> 0) or aCompact then
      nTile.I[aName] := aValue;
  end;

var
  I, J, K: Integer;
  nRoot, nAnimLayer: TJsonObject;
  nTiles, nTerKinds, nAnimLayers, nAnims: TJsonArray;
begin
  if not aCompact then
  begin
    JsonSerializationConfig.InlinedByDefault := True;
    JsonSerializationConfig.IndentChar := '  '; // 2 spaces
    JsonSerializationConfig.LineBreak := #13#10;
  end;

  nRoot := TJsonObject.Create;
  nRoot.Inlined := False;
  try
    nTiles := nRoot.A['Tiles'];
    nTiles.Inlined := False;
    for I := 0 to TILES_CNT - 1 do
    begin
      nTile := nTiles.AddObject;

//      nTile.FromSimpleObject(fTiles[I], False, True);

      nTile.I['ID'] := I;
      nTile.B['Walkable'] := fTiles[I].Walkable;
      nTile.B['Roadable'] := fTiles[I].Roadable;

      AddTileIAttr('Stone', fTiles[I].Stone);
      AddTileIAttr('Coal',  fTiles[I].Coal);
      AddTileIAttr('Iron',  fTiles[I].Iron);
      AddTileIAttr('Gold',  fTiles[I].Gold);

      AddTileBAttr('IronMinable', fTiles[I].IronMinable);
      AddTileBAttr('GoldMinable', fTiles[I].GoldMinable);

      AddTileBAttr('Water',      fTiles[I].Water);
      AddTileBAttr('HasWater',   fTiles[I].HasWater);
      AddTileBAttr('Ice',        fTiles[I].Ice);
      AddTileBAttr('Snow',       fTiles[I].Snow);
      AddTileBAttr('Sand',       fTiles[I].Sand);
      AddTileBAttr('Soil',       fTiles[I].Soil);
      AddTileBAttr('Corn',       fTiles[I].Corn);
      AddTileBAttr('Wine',       fTiles[I].Wine);

      nTerKinds := nTile.A['CornersTerKinds'];
      nTerKinds.Add(GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[0])));
      nTerKinds.Add(GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[1])));
      nTerKinds.Add(GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[2])));
      nTerKinds.Add(GetEnumName(TypeInfo(TKMTerrainKind), Integer(fTiles[I].TerKinds[3])));

      if not fTiles[I].Animation.HasAnim then Continue;

      for J := Low(fTiles[I].Animation.Layers) to High(fTiles[I].Animation.Layers) do
      begin
        nAnimLayers := nTile.A['AnimLayers'];
        nAnimLayer := nAnimLayers.AddObject;
        nAnimLayer.I['Frames'] := fTiles[I].Animation.Layers[J].Frames;

        for K := Low(fTiles[I].Animation.Layers[J].Anims) to High(fTiles[I].Animation.Layers[J].Anims) do
        begin
          nAnims := nAnimLayer.A['Anims'];
          nAnims.Add(fTiles[I].Animation.Layers[J].Anims[K]);
        end;
      end;
    end;

    if aSaveStream = nil then
      nRoot.SaveToFile(GetTilesJsonPath, aCompact, TEncoding.UTF8)
    else
      nRoot.SaveToStream(aSaveStream, aCompact, TEncoding.UTF8);
  finally
    nRoot.Free;
  end;
end;


procedure TKMResTileset.LoadFromJson;
var
  I, J, K: Integer;
  jsonPath: string;
  nTile, nRoot, nAnimLayer: TJsonObject;
  nTiles, nTerKinds, nAnimLayers, nAnims: TJsonArray;
  terKind: TKMTerrainKind;
  crcStream: TKMemoryStream;
begin
  jsonPath := GetTilesJsonPath;
  nRoot := TJsonObject.ParseFromFile(jsonPath) as TJsonObject;

  nTiles := nRoot.A['Tiles'];
  Assert(nTiles.Count = TILES_CNT);

  for I := 0 to nTiles.Count - 1 do
  begin
    nTile := nTiles.O[I];

    FreeAndNil(fTiles[I]);
    fTiles[I] := TKMTileParams.Create;

//    nTile.ToSimpleObject(tile, False);

    fTiles[I].ID := nTile.I['ID'];
    fTiles[I].Walkable := nTile.B['Walkable'];
    fTiles[I].Roadable := nTile.B['Roadable'];

    fTiles[I].Stone := nTile.I['Stone'];
    fTiles[I].Coal  := nTile.I['Coal'];
    fTiles[I].Iron  := nTile.I['Iron'];
    fTiles[I].Gold  := nTile.I['Gold'];

    fTiles[I].IronMinable := nTile.B['IronMinable'];
    fTiles[I].GoldMinable := nTile.B['GoldMinable'];

    fTiles[I].Water       := nTile.B['Water'];
    fTiles[I].HasWater    := nTile.B['HasWater'];
    fTiles[I].Ice         := nTile.B['Ice'];
    fTiles[I].Snow        := nTile.B['Snow'];
    fTiles[I].Sand        := nTile.B['Sand'];
    fTiles[I].Soil        := nTile.B['Soil'];
    fTiles[I].Corn        := nTile.B['Corn'];
    fTiles[I].Wine        := nTile.B['Wine'];

    nTerKinds := nTile.A['CornersTerKinds'];
    Assert(nTerKinds.Count = 4);
    for K := 0 to 3 do
      if TKMEnumUtils.TryGetAs<TKMTerrainKind>(nTerKinds.S[K], terKind) then
        fTiles[I].TerKinds[K] := terKind
      else
        raise Exception.Create('Error loading ' + jsonPath + ': wrong CornersTerKind: ' + nTerKinds.S[K]);

    if not nTile.Contains('AnimLayers') then Continue;

    nAnimLayers := nTile.A['AnimLayers'];

    SetLength(fTiles[I].Animation.Layers, nAnimLayers.Count);

    for J := 0 to nAnimLayers.Count - 1 do
    begin
      nAnimLayer := nAnimLayers.O[J];

      fTiles[I].Animation.Layers[J].Frames := nAnimLayer.I['Frames'];

      nAnims := nAnimLayer.A['Anims'];
      SetLength(fTiles[I].Animation.Layers[J].Anims, nAnims.Count);
      for K := 0 to nAnims.Count - 1 do
      begin
        fTiles[I].Animation.Layers[J].Anims[K] := nAnims[K];
      end;
    end;
  end;
end;


class function TKMResTileset.TileIsAllowedToSet(aTile: Word): Boolean;
begin
  Result := not ArrayContains(aTile, TILES_NOT_ALLOWED_TO_SET);
end;


end.

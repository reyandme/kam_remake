unit KM_Eye;
{$I KaM_Remake.inc}
interface
uses
  Classes, Graphics, KromUtils, Math, SysUtils, Contnrs,
  KM_Defaults, KM_Points, KM_CommonClasses, KM_CommonTypes, KM_CommonUtils,
  KM_ResHouses, KM_Houses, KM_ResWares, KM_Units,
  KM_AIArmyEvaluation, KM_AIInfluences, KM_FloodFill, KM_NavMeshFloodFill, KM_AIParameters;

const
  MAX_SCAN_DIST_FROM_HOUSE = 10;
  MIN_SCAN_DIST_FROM_HOUSE = 2; // Houses must have at least 1 tile of space between them

type
  TDirection = (dirN,dirE,dirS,dirW);
  THouseMapping = record // Record of vectors from loc of house to specific point
    Tiles: TKMPointArray; // Tiles inside house plan
    Surroundings: array[1..MAX_SCAN_DIST_FROM_HOUSE] of array[TDirection] of TKMPointArray; // Tiles around house plan in specific distance and direction
    MoveToEntrance: array[TDirection] of TKMPoint; // Move entrance of house in dependence of direction to be able to place house plan
    // Note: if we want place houses close to each other without "try and see" method we have to move from Loc of exist house into surrounding tiles and then move by entrance offset of new house)
  end;
  THouseMappingArray = array [HOUSE_MIN..HOUSE_MAX] of THouseMapping;


  TKMBuildState = (bsNoBuild = 0, bsHousePlan = 1, bsFieldPlan = 2, bsRoadPlan = 3, bsRoad = 4, bsBuild = 9, bsTree = 10, bsForest = 11, bsCoal = 12, bsMine = 13, bsDebug = 200, bsReserved = 255);
  TKMBuildInfo = record
    Visited, VisitedHouse: Byte;
    State: TKMBuildState;
    Next,Distance,DistanceInitPoint,Y: Word;
  end;
  TKMBuildInfoArray = array of TKMBuildInfo;

  TKMHouseRequirements = record
    HouseType: TKMHouseType;
    IgnoreTrees,IgnoreAvoidBuilding: Boolean;
    MaxCnt, MaxDist: Word;
  end;

  TKMForestInfo = record
    PartOfForest: Boolean;
    Loc: TKMPoint;
    TreeCout, Distance: Word;
    Bid: Single;
  end;
  TKMForestsInfo = record
    Count: Integer;
    Forests: array of TKMForestInfo;
  end;

  PDistElement = ^TKMDistElement;
  TKMDistElement = record
    X,Y,Distance: Word;
  end;

  // This class transforms all house placing requirements into 1 array to avoid overlapping conditions
  // Placing new house is then question of internal house tiles
  TKMBuildFF = class
  private
    fOwner: TKMHandID;
    fOwnerUpdateInfo: array[0..MAX_HANDS-1] of Byte;
    fVisitIdx, fVisitIdxHouse: Byte;
    fStartQueue, fEndQueue, fQueueCnt, fMapX, fMapY: Word;
    fUpdateTick: Cardinal;
    fHouseReq: TKMHouseRequirements;
    fHMA: THouseMappingArray;
    fLocs: TKMPointList;
    fInfoArr: TKMBuildInfoArray;

//    function GetInfo(const aY,aX: Word): TKMBuildInfo;
//    procedure SetInfo(const aY,aX,aNext,aDistance: Word; const aVisited: Byte; const aState: TKMBuildState);
    function GetVisited(const aY,aX: Word): Byte;
    procedure SetVisited(const aY,aX: Word; const aVisited: Byte);
    function GetOwnersIndex(const aOwner: TKMHandID): Byte;
    function GetState(const aY,aX: Word): TKMBuildState;
    procedure SetState(const aY,aX: Word; const aState: TKMBuildState);
    function GetStateFromIdx(const aIdx: Word): TKMBuildState;
    function GetDistance(const aPoint: TKMPoint): Word;
    function GetDistanceInitPoint(const aPoint: TKMPoint): Word;
    function GetNext(const aY,aX: Word): Word;
    procedure SetNext(const aY,aX,aNext: Word);

  protected
    procedure InitQueue(aHouseFF: Boolean);
    function InsertInQueue(const aIdx: Word): Word;
    function RemoveFromQueue(var aX,aY,aIdx: Word): Boolean;

    function CanBeVisited(const aX,aY,aIdx: Word; const aHouseQueue: Boolean = False): Boolean; overload;
    procedure MarkAsVisited(const aY,aIdx,aDistance: Word; const aState: TKMBuildState); overload;
    procedure MarkAsVisited(const aX,aY,aIdx,aDistance: Word); overload;

    function GetTerrainState(const aX,aY: Word): TKMBuildState;
    procedure MarkPlans();
    procedure TerrainFF(aMaxDistance: Word);
    procedure HouseFF();
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    //property Info[const aY,aX: Word]: TKMBuildInfo read GetInfo write SetInfo;
    property VisitIdx: Byte read fVisitIdx;
    property VisitIdxHouse: Byte read fVisitIdxHouse;
    property Visited[const aY,aX: Word]: Byte read GetVisited write SetVisited;
    property VisitIdxOwner[const aOwner: TKMHandID]: Byte read GetOwnersIndex;
    property State[const aY,aX: Word]: TKMBuildState read GetState write SetState;
    property StateIdx[const aIdx: Word]: TKMBuildState read GetStateFromIdx;
    property Distance[const aPoint: TKMPoint]: Word read GetDistance;
    property DistanceInitPoint[const aPoint: TKMPoint]: Word read GetDistanceInitPoint;
    property Next[const aY,aX: Word]: Word read GetNext write SetNext;
    property Locs: TKMPointList read fLocs write fLocs;
    property HouseRequirements: TKMHouseRequirements read fHouseReq write fHouseReq;

    procedure AfterMissionInit();
    procedure UpdateState(aMaxFFDistance: Word = 40);
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure ActualizeTile(aX, aY: Word);
    function CanBePlacedHouse(const aLoc: TKMPoint): Boolean;
    procedure FindPlaceForHouse(aHouseReq: TKMHouseRequirements; InitPointsArr: TKMPointArray; aClearHouseList: Boolean = True);
  end;


  TKMFFInitPlace = class
  private
    fMapX, fMapY: Word;
    fArea: TKMByteArray;
    fVisitArr: TBooleanArray;
    fQueue: TQueue;
  protected
    function CanBeVisited(const aX,aY, aDistance: Word): Boolean;
    procedure MarkAsVisited(const aIdx, aDistance: Word);
    procedure InsertInQueue(const aX,aY, aDistance: Word);
    function RemoveFromQueue(var aX,aY, aDistance: Word): Boolean;
  public
    constructor Create(aMapX,aMapY: Word; var aArea: TKMByteArray);
    destructor Destroy(); override;

    procedure FillArea(aCount: Word; aInitPoints: TKMPointArray);
  end;


  TKMFFCheckStoneTiles = class(TKMQuickFlood)
  private
    fMapX, fMapY: Word;
    fVisitIdx: Byte;
    fVisitArr: TKMByteArray;
    fStoneCnt, fStoneLimit: Integer;
  protected
    function CanBeVisited(const aX,aY: SmallInt): Boolean; override;
    function IsVisited(const aX,aY: SmallInt): Boolean; override;
    procedure MarkAsVisited(const aX,aY: SmallInt); override;
  public
    constructor Create(aStoneLimit: Integer; const aScanEightTiles: Boolean = False); reintroduce;
    function CheckCount(aX,aY: SmallInt): Boolean;
  end;


  // Transform game data into "AI view" ... this is how AI see the map (influences have its own class)
  TKMEye = class
  private
    fOwner: TKMHandID;
    fMapX, fMapY: Word;
    fHousesMapping: THouseMappingArray;
    fGoldLocs, fIronLocs, fStoneMiningTiles: TKMPointList; // Store coal tiles is not effective
    fSoil, fRoutes, fFlatArea: TKMByteArray; // Soil = detection of soil tiles; fRoutes = expected city area; fFlatArea = terrain evaluation

    fBuildFF: TKMBuildFF;
    fArmyEvaluation: TKMArmyEvaluation;

    function GetSoil(const aY,aX: Word): Byte;
    procedure SetSoil(const aY,aX: Word; const aValue: Byte);
    function GetRoutes(const aY,aX: Word): Byte;
    procedure SetRoutes(const aY,aX: Word; const aValue: Byte);
    function GetFlatArea(const aY,aX: Word): Byte;
    procedure SetFlatArea(const aY,aX: Word; const aValue: Byte);

    procedure InitHousesMapping();
    function CheckResourcesNearMine(aLoc: TKMPoint; aHT: TKMHouseType): Boolean;
//    function GetResourcesNearMine(aLoc: TKMPoint; aHT: TKMHouseType): Word;
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property HousesMapping: THouseMappingArray read fHousesMapping write fHousesMapping;
    property BuildFF: TKMBuildFF read fBuildFF;
    property ArmyEvaluation: TKMArmyEvaluation read fArmyEvaluation;
    property Soil[const aY,aX: Word]: Byte read GetSoil write SetSoil;
    property Routes[const aY,aX: Word]: Byte read GetRoutes write SetRoutes;
    property FlatArea[const aY,aX: Word]: Byte read GetFlatArea write SetFlatArea;

    procedure AfterMissionInit();
    procedure UpdateState(aTick: Cardinal);
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure ScanLoc();

    function CanPlaceHouse(aLoc: TKMPoint; aHT: TKMHouseType; aIgnoreTrees: Boolean = False): Boolean;
    function CanAddHousePlan(aLoc: TKMPoint; aHT: TKMHouseType; aIgnoreAvoidBuilding: Boolean = False; aIgnoreTrees: Boolean = False; aIgnoreLocks: Boolean = True): Boolean;

    function FindSeparateMineLocs(aAllMines: Boolean; aMineType: TKMHouseType): TKMPointArray;
    function GetMineLocs(aHT: TKMHouseType): TKMPointTagList;
    function GetStoneLocs(): TKMPointTagList;
    function GetForests(): TKMForestsInfo;
    function GetPotentialForests(aMaxCnt: Integer): TKMForestsInfo;
    function GetCityCenterPolygons(aMultiplePoints: Boolean = False): TKMWordArray;
    function GetCityCenterPoints(aMultiplePoints: Boolean = False): TKMPointArray;

    function GetClosestUnitAroundHouse(aHT: TKMHouseType; aLoc: TKMPoint; aInitPoint: TKMPoint): TKMUnit;

    procedure Paint(aRect: TKMRect);
  end;



implementation
uses
  KM_Game, KM_Terrain, KM_Hand, KM_Resource, KM_AIFields, KM_HandsCollection, KM_RenderAux, KM_ResMapElements,
  KM_NavMesh, KM_NavMeshGenerator, KM_CityPlanner;


{ TKMEye }
constructor TKMEye.Create();
begin
  fGoldLocs := TKMPointList.Create();
  fIronLocs := TKMPointList.Create();
  fStoneMiningTiles := TKMPointList.Create();

  fBuildFF := TKMBuildFF.Create();
  fArmyEvaluation := TKMArmyEvaluation.Create();

  InitHousesMapping();
end;

destructor TKMEye.Destroy();
begin
  fGoldLocs.Free;
  fIronLocs.Free;
  fStoneMiningTiles.Free;

  fBuildFF.Free;
  fArmyEvaluation.Free;

  inherited;
end;


procedure TKMEye.Save(SaveStream: TKMemoryStream);
  procedure SaveByteArr(var aArray: TKMByteArray);
  var
    Len: Integer;
  begin
    Len := Length(aArray);
    SaveStream.Write(Len);
    SaveStream.Write(aArray[0], SizeOf(aArray[0]) * Len);
  end;
begin
  SaveStream.PlaceMarker('Eye');
  SaveStream.Write(fOwner);
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);

  fGoldLocs.SaveToStream(SaveStream);
  fIronLocs.SaveToStream(SaveStream);
  fStoneMiningTiles.SaveToStream(SaveStream);

  SaveByteArr(fSoil);
  SaveByteArr(fRoutes);
  SaveByteArr(fFlatArea);

  fArmyEvaluation.Save(SaveStream);
  fBuildFF.Save(SaveStream);

  // The following does not requires save
  // fHousesMapping
end;

procedure TKMEye.Load(LoadStream: TKMemoryStream);
  procedure LoadByteArr(var aArray: TKMByteArray);
  var
    Len: Integer;
  begin
    LoadStream.Read(Len);
    SetLength(aArray, Len);
    LoadStream.Read(aArray[0], SizeOf(aArray[0]) * Len);
  end;
begin
  LoadStream.CheckMarker('Eye');
  LoadStream.Read(fOwner);
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);

  fGoldLocs.LoadFromStream(LoadStream);
  fIronLocs.LoadFromStream(LoadStream);
  fStoneMiningTiles.LoadFromStream(LoadStream);

  LoadByteArr(fSoil);
  LoadByteArr(fRoutes);
  LoadByteArr(fFlatArea);

  fArmyEvaluation.Load(LoadStream);
  fBuildFF.Load(LoadStream);
end;


function TKMEye.GetSoil(const aY,aX: Word): Byte;
begin
  Result := fSoil[aY*fMapX + aX];
end;
procedure TKMEye.SetSoil(const aY,aX: Word; const aValue: Byte);
begin
  fSoil[aY*fMapX + aX] := aValue;
end;

function TKMEye.GetRoutes(const aY,aX: Word): Byte;
begin
  Result := fRoutes[aY*fMapX + aX];
end;
procedure TKMEye.SetRoutes(const aY,aX: Word; const aValue: Byte);
begin
  fRoutes[aY*fMapX + aX] := aValue;
end;

function TKMEye.GetFlatArea(const aY,aX: Word): Byte;
begin
  Result := fFlatArea[aY*fMapX + aX];
end;
procedure TKMEye.SetFlatArea(const aY,aX: Word; const aValue: Byte);
begin
  fFlatArea[aY*fMapX + aX] := aValue;
end;


procedure TKMEye.AfterMissionInit();
  procedure GeneralizeArray(const RADIUS: Byte; var aArr: TKMByteArray);
  var
    X,Y,Y2,X2,Idx: Integer;
    CopyArr: TKMByteArray;
  begin
    SetLength(CopyArr, Length(aArr));
    Move(aArr[0],CopyArr[0],Sizeof(aArr[0])*Length(aArr));

    for Y := 1 to fMapY - 1 do
    for X := 1 to fMapX - 1 do
    begin
      Idx := Y*fMapX + X;
      for Y2 := Max(1, Y-RADIUS) to Min(fMapY-1, Y+RADIUS) do
      for X2 := Y2*fMapX + Max(1, X-RADIUS) to Y2*fMapX + Min(fMapX-1, X+RADIUS) do
        Inc(aArr[Idx], CopyArr[X2]);
    end;

  //  for Y := 1 to 1+RADIUS-1 do
  //  for X := 1 to 1+RADIUS do
  //    Inc(aArr[1*fMapX + 1], CopyArr[Y*fMapX + X]);
  //  for Y := 1 to fMapY - 1 do
  //  begin
  //    Idx := Y*fMapX + 1;
  //    aArr[Idx] := aArr[Max(Y-1,1)*fMapX + 1];
  //    if (Y-RADIUS-1 > 0) then
  //      for X := 1 to 1+RADIUS do
  //        Dec(aArr[Idx], CopyArr[(Y-RADIUS-1)*fMapX + X]);
  //    if (Y+RADIUS < fMapY) then
  //      for X := 1 to 1+RADIUS do
  //        Inc(aArr[Idx], CopyArr[(Y+RADIUS)*fMapX + X]);
  //
  //    for X := 2 to fMapX - 1 do
  //    begin
  //      Idx := Y*fMapX + X;
  //      aArr[Idx] := aArr[Idx-1];
  //      if (X-RADIUS-1 > 0) then
  //        for Y2 := Max(1,Y-RADIUS) to Min(fMapY-1,Y+RADIUS) do
  //          Dec(aArr[Idx], CopyArr[Y2*fMapX + X-RADIUS-1]);
  //      if (X+RADIUS < fMapY) then
  //        for Y2 := Max(1,Y-RADIUS) to Min(fMapY-1,Y+RADIUS) do
  //          Inc(aArr[Idx], CopyArr[Y2*fMapX + X+RADIUS]);
  //    end;
  //  end;
  end;
const
  MIN_STONES_IN_MINE = 50;
var
  X,Y: Integer;
  Loc: TKMPoint;
  StoneCheck: TKMFFCheckStoneTiles;
begin
  fBuildFF.AfterMissionInit();
  fArmyEvaluation.AfterMissionInit();

  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;

  SetLength(fSoil, fMapX * fMapY);
  SetLength(fRoutes, fMapX * fMapY);
  SetLength(fFlatArea, fMapX * fMapY);
  FillChar(fSoil, fSoil[0] * Length(fSoil), #0);
  FillChar(fRoutes, fRoutes[0] * Length(fRoutes), #0);
  FillChar(fFlatArea, fFlatArea[0] * Length(fFlatArea), #0);

  StoneCheck := TKMFFCheckStoneTiles.Create(MIN_STONES_IN_MINE);
  try
    for Y := 1 to fMapY - 1 do
    for X := 1 to fMapX - 1 do
    begin
      Loc := KMPoint(X,Y);
      FlatArea[Y,X] := Byte(gTerrain.TileIsWalkable(Loc));
      if gTerrain.TileIsSoil(X,Y) then
        Soil[Y,X] := 1
      //else if (gTerrain.TileIsCoal(X,Y) > 1) then
      else if gTerrain.TileHasStone(X,Y) then
      begin
        Soil[Y,X] := 1; // Stone tile can be mined and used for farms
        if (Y < fMapY - 1) AND (tpWalk in gTerrain.Land[Y+1,X].Passability) AND  StoneCheck.CheckCount(X,Y) then
          fStoneMiningTiles.Add(Loc);
      end
      else if CanAddHousePlan(Loc, htGoldMine, True, False) then
      begin
        if CheckResourcesNearMine(Loc, htGoldMine) then
          fGoldLocs.Add(Loc);
      end
      else if CanAddHousePlan(Loc, htIronMine, True, False) then
      begin
        if CheckResourcesNearMine(Loc, htIronMine) then
          fIronLocs.Add(Loc);
      end;
    end;
  finally
    StoneCheck.Free();
  end;
  GeneralizeArray(4,fSoil);
  GeneralizeArray(4,fFlatArea);
end;


// Search for ore - gold and iron mines have similar requirements so there are booth in 1 method
function TKMEye.CheckResourcesNearMine(aLoc: TKMPoint; aHT: TKMHouseType): Boolean;
var
  X,Y: Integer;
begin
  Result := True;
  for X := Max(aLoc.X-4, 1) to Min(aLoc.X+3+Byte(aHT = htGoldMine), fMapX-1) do
    for Y := Max(aLoc.Y-8, 1) to aLoc.Y do
      if   (aHT = htGoldMine) AND gTerrain.TileHasGold(X, Y)
        OR (aHT = htIronMine) AND gTerrain.TileHasIron(X, Y) then
        Exit;
  Result := False; //Didn't find any ore
end;


//function TKMEye.GetResourcesNearMine(aLoc: TKMPoint; aHT: TKMHouseType): Word;
//var
//  X,Y: Integer;
//begin
//  Result := 0;
//  for X := Max(aLoc.X-4, 1) to Min(aLoc.X+3+Byte(aHT = htGoldMine), fMapX-1) do
//    for Y := Max(aLoc.Y-8, 1) to aLoc.Y do
//      if (aHT = htGoldMine) then
//        Result := Result + gTerrain.TileIsGold(X, Y)
//      else if (aHT = htIronMine) then
//        Result := Result + gTerrain.TileIsIron(X, Y);
//end;



function TKMEye.FindSeparateMineLocs(aAllMines: Boolean; aMineType: TKMHouseType): TKMPointArray;
var
  I,K, Cnt: Integer;
  InfluenceArr: TBooleanArray;
  Mines: TKMPointList;
  Output: TKMPointArray;
begin
  SetLength(Result, 0);
  if aAllMines then
  begin
    if (aMineType = htIronMine) then
      Mines := fIronLocs
    else if (aMineType = htGoldMine) then
      Mines := fGoldLocs
    else
      Exit;
  end
  else
  begin
    if (aMineType = htIronMine) then
      Mines := GetMineLocs(htIronMine)
    else if (aMineType = htGoldMine) then
      Mines := GetMineLocs(htGoldMine)
    else
      Exit;
  end;
  Cnt := 0;
  SetLength(Output, Mines.Count);
  if (Mines.Count > 0) then
  begin
    SetLength(InfluenceArr, Mines.Count);
    FillChar(InfluenceArr[0], SizeOf(InfluenceArr[0]) * Length(InfluenceArr), #0); // => False
    for I := 0 to Mines.Count-1 do
    begin
      InfluenceArr[I] := True;
      for K := 0 to I-1 do
        if InfluenceArr[K] AND
          not (   (Mines.Items[K].Y <> Mines.Items[I].Y)
                OR (  Abs(Mines.Items[K].X - Mines.Items[I].X) > (3 + Byte(aMineType = htIronMine)) )   ) then
        begin
          InfluenceArr[I] := False;
          break;
        end;
      if InfluenceArr[I] then
      begin
        Output[Cnt] := Mines.Items[I];
        Inc(Cnt);
      end;
    end;
  end;
  if (not aAllMines) then
    Mines.Free;
  SetLength(Output, Cnt);
  Result := Output;
end;


procedure TKMEye.ScanLoc();
var
  PointsCnt: Word;
  Road: TKMPointList;
  InitPoints: TKMPointArray;

  procedure ScanLocArea(aStartP, aEndP: TKMPoint);
  var
    I: Integer;
    FieldType: TKMFieldType;
  begin
    Road.Clear();
    if gHands[fOwner].AI.CityManagement.Builder.Planner.GetRoadBetweenPoints(aStartP, aEndP, Road, FieldType) then
    begin
      if (PointsCnt + Road.Count >= Length(InitPoints)) then
        SetLength(InitPoints, PointsCnt + Road.Count + 512);
      for I := 0 to Road.Count - 1 do
      begin
        InitPoints[PointsCnt] := Road.Items[I];
        PointsCnt := PointsCnt + 1;
      end;
    end;
  end;
var
  K, X,Y, FieldCnt, BuildCnt: Integer;
  CenterPointArr, MineLocs: TKMPointArray;
  //TagList: TKMPointTagList;
  FFInitPlace: TKMFFInitPlace;
begin
  // Init city center point (storehouse / school etc.)
  CenterPointArr := GetCityCenterPoints(False);
  PointsCnt := 0;
  SetLength(InitPoints,0);
  Road := TKMPointList.Create();
  try
    // Scan Resources - gold, iron
    MineLocs := FindSeparateMineLocs(false, htIronMine);
    for K := 0 to Length(MineLocs) - 1 do
      ScanLocArea(CenterPointArr[0], MineLocs[K]);
    MineLocs := FindSeparateMineLocs(false, htGoldMine);
    for K := 0 to Length(MineLocs) - 1 do
      ScanLocArea(CenterPointArr[0], MineLocs[K]);
    // Scan Resources - coal
    //TagList := TKMPointTagList.Create();
    //try
    //  K := 0;
    //  Increment := Ceil(TagList.Count / 10.0); // Max 10 paths
    //  while (K < TagList.Count) do
    //  begin
    //    ScanLocArea(CenterPointArr[0], TagList.Items[K]);
    //    K := K + Increment;
    //  end;
    //finally
    //  TagList.Free;
    //end;
    // Scan Resources - stones
    {
    TagList := GetStoneLocs(True);
    try
      K := 0;
      Increment := Ceil(TagList.Count / 5.0); // Max 5 paths
      while (K < TagList.Count) do
      begin
        ScanLocArea(TagList.Items[K]);
        K := K + Increment;
      end;
    finally
      TagList.Free;
    end
    //}
  finally
    Road.Free;
  end;

  if (PointsCnt > 0) then
  begin
    FFInitPlace := TKMFFInitPlace.Create(fMapX,fMapY, fRoutes);
    try
      FFInitPlace.FillArea(PointsCnt, InitPoints);
    finally
      FFInitPlace.Free;
    end;
  end;

  FieldCnt := 0;
  BuildCnt := 0;
  for Y := 1 to fMapY - 1 do
  for X := 1 to fMapX - 1 do
    if (gAIFields.Influences.GetBestOwner(X,Y) = fOwner) AND gTerrain.TileIsRoadable( KMPoint(X,Y) ) then
    begin
      Inc(FieldCnt, Byte(Soil[Y,X] > 0));
      Inc(BuildCnt, 1);
    end;
  gHands[fOwner].AI.CityManagement.Predictor.FieldCnt := FieldCnt;
  gHands[fOwner].AI.CityManagement.Predictor.BuildCnt := BuildCnt;
end;


// Create mapping of surrounding tiles for each house
procedure TKMEye.InitHousesMapping();
var
  EnterOff: ShortInt;
  House: TKMHouseType;
  POMArr: array[1-MAX_SCAN_DIST_FROM_HOUSE..4+MAX_SCAN_DIST_FROM_HOUSE,1-MAX_SCAN_DIST_FROM_HOUSE..4+MAX_SCAN_DIST_FROM_HOUSE] of Byte;
  CntArr, Index: array [TDirection] of Integer;

  procedure SearchAndFill(const aIdx: Integer; aFill: Boolean = False);
  var
    PointAdded: Boolean;
    X,Y: Integer;
    Dir: TDirection;
  begin
    //FillChar(CntArr, SizeOf(CntArr), #0); //Clear up
    for dir := Low(CntArr) to High(CntArr) do
      CntArr[dir] := 0;

    for Y := 1-aIdx to 4+aIdx do
    for X := 1-aIdx to 4+aIdx do
      if (POMArr[Y,X] = aIdx) then
      begin
        PointAdded := False;
        if (X = Index[dirW]-aIdx) then
        begin
          PointAdded := True;
          if aFill then
            fHousesMapping[House].Surroundings[aIdx,dirW,CntArr[dirW]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirW],1);
        end
        else if (X = Index[dirE]+aIdx) then
        begin
          PointAdded := True;
          if aFill then
            fHousesMapping[House].Surroundings[aIdx,dirE,CntArr[dirE]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirE],1);
        end;
        if (Y = Index[dirS]+aIdx) then
        begin
          if aFill then
            fHousesMapping[House].Surroundings[aIdx,dirS,CntArr[dirS]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirS],1);
        end
        else if not PointAdded OR (Y = Index[dirN]-aIdx) then // Plans with cutted top corners
        begin
          if aFill then
            fHousesMapping[House].Surroundings[aIdx,dirN,CntArr[dirN]] := KMPoint(X - 3 - EnterOff, Y - 4);
          Inc(CntArr[dirN],1);
        end;
      end;
    if not aFill then
      for dir := Low(CntArr) to High(CntArr) do
        SetLength(fHousesMapping[House].Surroundings[aIdx,dir], CntArr[dir]);
  end;

var
  I, X,Y,aX,aY, ActualIdx, Cnt: Integer;
  HA: THouseArea;
begin
  for House := HOUSE_MIN to HOUSE_MAX do
  begin
    EnterOff := gRes.Houses[House].EntranceOffsetX;

    // Init POMArr with value 255;
    for Y := Low(POMArr) to High(POMArr) do
    for X := Low(POMArr[Y]) to High(POMArr[Y]) do
      POMArr[Y,X] := 255;

    // Find house plan and save its shape into POMArr
    HA := gRes.Houses[House].BuildArea;
    Cnt := 0;
    for Y := 1 to 4 do
    for X := 1 to 4 do
      if (HA[Y,X] <> 0) then
      begin
        POMArr[Y,X] := 0;
        Inc(Cnt,1);
      end;

    // Save vectors from entrance to each tile which is in house plan
    SetLength(fHousesMapping[House].Tiles, Cnt);
    Cnt := 0;
    for Y := 1 to 4 do
    for X := 1 to 4 do
      if (POMArr[Y,X] = 0) then
      begin
        fHousesMapping[House].Tiles[Cnt] := KMPoint(X - 3 - EnterOff, Y - 4);
        Inc(Cnt);
      end;

    // Create around the house plan layers of increasing values in dependence on distance from the plan
    for I := 1 to MAX_SCAN_DIST_FROM_HOUSE do
    begin
      ActualIdx := I-1;
      for Y := 1-ActualIdx to 4+ActualIdx do
      for X := 1-ActualIdx to 4+ActualIdx do
        if (POMArr[Y,X] = ActualIdx) then
          for aY := -1 to 1 do
          for aX := -1 to 1 do
            if (POMArr[Y+aY,X+aX] > I) then
              POMArr[Y+aY,X+aX] := I;
    end;

    // Calculate size of plan
    Index[dirN] := 3 - Byte(POMArr[2,2] = 0) - Byte(POMArr[1,2] = 0);
    Index[dirS] := 4;
    Index[dirW] := 2 - Byte(POMArr[4,1] = 0);
    Index[dirE] := 3 + Byte(POMArr[4,4] = 0);

    // Get entrance with respect to array HA
    for X := 1 to 4 do
      if (HA[4,X] = 2) then
        break;
    fHousesMapping[House].MoveToEntrance[dirN] := KMPoint(0, 0);
    fHousesMapping[House].MoveToEntrance[dirS] := KMPoint(0, 4 - Index[dirN]);
    fHousesMapping[House].MoveToEntrance[dirW] := KMPoint(X - Index[dirE], 0);
    fHousesMapping[House].MoveToEntrance[dirE] := KMPoint(X - Index[dirW], 0);

    // Fill fHousesSurroundings
    for I := 1 to MAX_SCAN_DIST_FROM_HOUSE do
    begin
      SearchAndFill(I, False);
      SearchAndFill(I, True);
    end;

  end;
end;


procedure TKMEye.UpdateState(aTick: Cardinal);
begin
  fArmyEvaluation.UpdateState(aTick);
end;


procedure TKMEye.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fBuildFF.OwnerUpdate(aPlayer);
end;


// This function is copied (and reworked) from TKMTerrain.CanPlaceHouse and edited to be able to ignore trees
function TKMEye.CanPlaceHouse(aLoc: TKMPoint; aHT: TKMHouseType; aIgnoreTrees: Boolean = False): Boolean;
var
  Output: Boolean;
  I,X,Y: Integer;
begin
  Output := True;
  for I := Low(fHousesMapping[aHT].Tiles) to High(fHousesMapping[aHT].Tiles) do
  begin
    X := aLoc.X + fHousesMapping[aHT].Tiles[I].X;
    Y := aLoc.Y + fHousesMapping[aHT].Tiles[I].Y;
    // Inset one tile from map edges
    Output := Output AND gTerrain.TileInMapCoords(X, Y, 1);
    // Mines have specific requirements
    case aHT of
      htIronMine: Output := Output AND gTerrain.CanPlaceIronMine(X, Y);
      htGoldMine: Output := Output AND gTerrain.CanPlaceGoldMine(X, Y);
      else         Output := Output AND ( (tpBuild in gTerrain.Land[Y,X].Passability)
                                          OR (aIgnoreTrees
                                              AND gTerrain.ObjectIsChopableTree(KMPoint(X,Y), [caAge1,caAge2,caAge3,caAgeFull])
                                              AND gHands[fOwner].CanAddFieldPlan(KMPoint(X,Y), ftWine))
                                        );
    end;
    if not Output then
      break;
  end;
  Result := Output;
end;


// Modified version of TKMHand.CanAddHousePlan - added possibilities
// aIgnoreAvoidBuilding = ignore avoid building areas
// aIgnoreTrees = ignore trees inside of house plan
// aIgnoreLocks = ignore existing house plans inside of house plan tiles
function TKMEye.CanAddHousePlan(aLoc: TKMPoint; aHT: TKMHouseType; aIgnoreAvoidBuilding: Boolean = False; aIgnoreTrees: Boolean = False; aIgnoreLocks: Boolean = True): Boolean;
  function CanBeRoad(X,Y: Integer): Boolean;
  begin
    Result := (gTerrain.Land[Y, X].Passability * [tpMakeRoads, tpWalkRoad] <> [])
              OR (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(X,Y)) <> ftNone) // We dont need strictly road just make sure that it is possible to place something here (and replace it by road later)
              OR (gTerrain.Land[Y, X].TileLock in [tlFieldWork, tlRoadWork]);
  end;
var
  LeftSideFree, RightSideFree: Boolean;
  X, Y, I, K, PL: Integer;
  Point: TKMPoint;
  Dir: TDirection;
begin
  Result := False;

  // The loc is out of map or in inaccessible area
  if not gTerrain.TileInMapCoords(aLoc.X, aLoc.Y, 1) then
    Exit;

  // Check if we can place house on terrain, this also makes sure the house is
  // at least 1 tile away from map border (skip that below)
  if not CanPlaceHouse(aLoc, aHT, aIgnoreTrees) then
    Exit;

  // Make sure we can add road below house (1 tile is ok, BuildFF checked everything)
  if not CanBeRoad(aLoc.X,aLoc.Y+1) then
    Exit;

  // Make sure that we dont put new house into another plan (just entrance is enought because houses have similar size)
  //if gHands[fOwner].BuildList.HousePlanList.HasPlan(KMPoint(aLoc.X,aLoc.Y)) then
  //  Exit;

  // Scan tiles inside house plan
  for I := Low(fHousesMapping[aHT].Tiles) to High(fHousesMapping[aHT].Tiles) do
  begin
    X := aLoc.X + fHousesMapping[aHT].Tiles[I].X;
    Y := aLoc.Y + fHousesMapping[aHT].Tiles[I].Y;
    Point := KMPoint(X,Y);

    // Check with AvoidBuilding array to secure that new house will not be build in forests / coal tiles
    if aIgnoreAvoidBuilding then
    begin
      if not aIgnoreLocks AND
        (gAIFields.Influences.AvoidBuilding[Y, X] in [AVOID_BUILDING_HOUSE_OUTSIDE_LOCK, AVOID_BUILDING_HOUSE_INSIDE_LOCK]) then
      Exit;
    end
    else if (gAIFields.Influences.AvoidBuilding[Y, X] > 0) then
      Exit;

    //This tile must not contain fields/houseplans of allied players
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = atAlly) then// AND (PL <> fOwner) then
        if (gHands[PL].BuildList.FieldworksList.HasField(Point) <> ftNone) then
          Exit;
  end;

  // Scan tiles in distance 1 from house plan
  LeftSideFree := True;
  RightSideFree := True;
  I := 1;
  for Dir := Low(fHousesMapping[aHT].Surroundings[I]) to High(fHousesMapping[aHT].Surroundings[I]) do
  for K := Low(fHousesMapping[aHT].Surroundings[I,Dir]) to High(fHousesMapping[aHT].Surroundings[I,Dir]) do
  begin
    X := aLoc.X + fHousesMapping[aHT].Surroundings[I,Dir,K].X;
    Y := aLoc.Y + fHousesMapping[aHT].Surroundings[I,Dir,K].Y;
    Point := KMPoint(X,Y);
    // Surrounding tiles must not be a house
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = atAlly) then
        if gHands[PL].BuildList.HousePlanList.HasPlan(Point) then
          Exit;
    if (aHT in [htGoldMine, htIronMine]) then
      continue;
    // Quarry / Woodcutters / CoalMine / Towers may take place for mine so its arena must be scaned completely
    if aIgnoreAvoidBuilding then
    begin
      if (gAIFields.Influences.AvoidBuilding[Y, X] = AVOID_BUILDING_HOUSE_INSIDE_LOCK) then
        Exit;
    end
    // For "normal" houses there must be at least 1 side also free (on the left or right from house plan)
    else if (Dir = dirE) then // Direction east
      RightSideFree := RightSideFree AND CanBeRoad(X,Y)
    else if (Dir = dirW) then // Direction west
      LeftSideFree := LeftSideFree AND CanBeRoad(X,Y);
    if not (LeftSideFree AND RightSideFree) then
      Exit;
  end;

  Result := True;
end;


function TKMEye.GetMineLocs(aHT: TKMHouseType): TKMPointTagList;
var
  Ownership: Byte;
  I,X,Y: Integer;
  Mines: TKMPointList;
  Output: TKMPointTagList;
begin
  Output := TKMPointTagList.Create();
  Mines := nil;
  case aHT of
    htGoldMine: Mines := fGoldLocs;
    htIronMine: Mines := fIronLocs;
  end;

  if (Mines <> nil) then
    for I := Mines.Count - 1 downto 0 do
    begin
      X := Mines.Items[I].X;
      Y := Mines.Items[I].Y;
      Ownership := gAIFields.Influences.Ownership[fOwner, Y, X];
      if ([tpMakeRoads, tpWalkRoad] * gTerrain.Land[Y+1,X].Passability <> [])
        AND (Ownership > 0) AND gAIFields.Influences.CanPlaceHouseByInfluence(fOwner, X,Y) then
        if CanAddHousePlan(Mines.Items[I], aHT, True, False) AND CheckResourcesNearMine(Mines.Items[I], aHT) then
          Output.Add(Mines.Items[I], Ownership)
        else
          Mines.Delete(I);
    end;
  Result := Output;
end;


function TKMEye.GetStoneLocs(): TKMPointTagList;
  function AddStoneCount(var aX,aY, aCount: Integer): Byte;
  begin
    Result := gTerrain.TileIsStone(aX, aY);
    aCount := aCount + Result;
  end;
const
  SCAN_LIMIT = 10;
var
  X,Y,K, MaxDist, Sum: Integer;
  Output: TKMPointTagList;
begin
  Output := TKMPointTagList.Create();
  for K := fStoneMiningTiles.Count-1 downto 0 do
  begin
    X := fStoneMiningTiles.Items[K].X;
    Y := fStoneMiningTiles.Items[K].Y;
    MaxDist := Max(1, Y-SCAN_LIMIT);
    // Find actual stone tile (if exist)
    while not gTerrain.TileHasStone(X, Y) AND (Y > MaxDist) do
      Y := Y - 1;
    // Check if is possible to mine it
    if gTerrain.TileHasStone(X, Y) AND (tpWalk in gTerrain.Land[Y+1,X].Passability) then
    begin
      fStoneMiningTiles.Items[K] := KMPoint(X,Y);
      // Save tile as a potential point for quarry
      if gAIFields.Influences.CanPlaceHouseByInfluence(fOwner, X,Y+1) then
      begin
        Sum := 0;
        while (Y > 1) AND (AddStoneCount(X,Y,Sum) > 0) do
          Y := Y - 1;
        Output.Add(fStoneMiningTiles.Items[K], Sum);
      end;
    end
    else // Else remove point
      fStoneMiningTiles.Delete(K);
  end;
  Result := Output;
end;


// Cluster algorithm (inspired by DBSCAN but clusters may overlap)
// Create possible places for forests and return count of already existed forests
function TKMEye.GetForests(): TKMForestsInfo;
const
  UNVISITED_TILE = 0;
  VISITED_TILE = 1;
  UNVISITED_TREE = 2;
  VISITED_TREE = 3;
  UNVISITED_TREE_IN_FOREST = 4;
  VISITED_TREE_IN_FOREST = 5;
  MAX_SPARE_POINTS = 20;
var
  InForest: Boolean;
  Ownership, AvoidBulding: Byte;
  RADIUS, MAX_DIST: Word;
  I,X,Y,X2,Y2, Distance, SparePointsCnt, Cnt: Integer;
  Point, sumPoint: TKMPoint;
  VisitArr: TKMByte2Array;
  FI: TKMForestsInfo;
begin
  fBuildFF.UpdateState(); // Mark walkable area in owner's city

  // Init visit array and fill trees
  SetLength(VisitArr, fMapY, fMapX);
  for Y := 1 to fMapY - 1 do
    for X := 1 to fMapX - 1 do
    begin
      VisitArr[Y,X] := VISITED_TILE;
      if (BuildFF.VisitIdx = BuildFF.Visited[Y,X])
         AND (BuildFF.State[Y,X] = bsTree) then
      begin
        AvoidBulding := gAIFields.Influences.AvoidBuilding[Y,X];
        // Tree is not part of existing forest
        if (AvoidBulding < AVOID_BUILDING_FOREST_MINIMUM) then
          VisitArr[Y,X] := UNVISITED_TREE
        // Ignore trees which are too cloose to exist forest
        else if (AvoidBulding < AVOID_BUILDING_FOREST_MINIMUM + GA_EYE_GetForests_MaxAB) then
          VisitArr[Y,X] := UNVISITED_TREE_IN_FOREST;
      end;
    end;

  // Detect potential forests as a cluster of trees
  RADIUS := Round(GA_EYE_GetForests_Radius);
  MAX_DIST := RADIUS + 1;
  FI.Count := 0;
  for Y := 1 to fMapY - 1 do
  for X := 1 to fMapX - 1 do
    if (VisitArr[Y,X] = UNVISITED_TREE) OR (VisitArr[Y,X] = UNVISITED_TREE_IN_FOREST) then
    begin
      Point := KMPoint(X,Y);
      InForest := False;
      sumPoint := KMPOINT_ZERO;
      Cnt := 0;
      // It is faster to find points in required radius than find closest points from list of points (small radius)
      for Y2 := Max(1, Y-RADIUS) to Min(Y+RADIUS, fMapY-1) do
      for X2 := Max(1, X-RADIUS) to Min(X+RADIUS, fMapX-1) do
        if (VisitArr[Y2,X2] >= UNVISITED_TREE) // Detect tree and check maximal distance
          AND (KMDistanceAbs(Point, KMPoint(X2,Y2)) <= MAX_DIST) then
        begin
          Cnt := Cnt + 1;
          sumPoint := KMPointAdd(sumPoint, KMPoint(X2,Y2));
          if (VisitArr[Y2,X2] = UNVISITED_TREE) then
            VisitArr[Y2,X2] := VISITED_TREE
          else if (VisitArr[Y2,X2] >= UNVISITED_TREE_IN_FOREST) then
          begin
            InForest := True;
            VisitArr[Y2,X2] := VISITED_TREE_IN_FOREST;
          end;
        end;
      if (Cnt > GA_EYE_GetForests_MinTrees) then
      begin
        Point := KMPoint( Round(sumPoint.X/(Cnt*1.0)), Round(sumPoint.Y/(Cnt*1.0)) );
        if (Length(FI.Forests) >= FI.Count) then
          SetLength(FI.Forests,Length(FI.Forests)+100);
        with FI.Forests[ FI.Count ] do
        begin
          PartOfForest := InForest;
          Loc := KMPoint( Round(sumPoint.X/Cnt), Round(sumPoint.Y/Cnt) );
          TreeCout := Cnt;
          // Center point does not have to be visited by BuildFF
          if (BuildFF.VisitIdx = BuildFF.Visited[Loc.Y,Loc.X]) then
            Distance := BuildFF.Distance[Loc]
          else
            Distance := BuildFF.Distance[Point];
          Bid := 0;
        end;
        Inc(FI.Count);
      end;
    end;
  Result := FI;
end;


function TKMEye.GetPotentialForests(aMaxCnt: Integer): TKMForestsInfo;
var
  K: Integer;
  Ownership: Byte;
  Point: TKMPoint;
  FI: TKMForestsInfo;
  Polygons: TPolygonArray;
begin
  fBuildFF.UpdateState(); // Mark walkable area in owner's city
  // Try to find potential forests only in owner's influence areas
  FI.Count := 0;
  Polygons := gAIFields.NavMesh.Polygons;
  for K := 0 to Length(Polygons) - 1 do
  begin
    if (FI.Count >= aMaxCnt) then
      break;
    Ownership := gAIFields.Influences.OwnPoly[fOwner, K];
    if (Ownership > GA_EYE_GetForests_SPRndOwnLimMin) AND
       (Ownership < GA_EYE_GetForests_SPRndOwnLimMax) then
    begin
      Point := Polygons[K].CenterPoint;
      if (Soil[Point.Y,Point.X] > GA_EYE_GetForests_MinRndSoil) then
      begin
        if (Length(FI.Forests) >= FI.Count) then
          SetLength(FI.Forests,Length(FI.Forests)+100);
        with FI.Forests[ FI.Count ] do
        begin
          PartOfForest := False;
          Loc := Point;
          TreeCout := 0;
          Distance := Byte(BuildFF.VisitIdx = BuildFF.Visited[Point.Y,Point.X]) * BuildFF.Distance[Point];
          Bid := 0;
        end;
        Inc(FI.Count);
      end;
    end;
  end;
  Result := FI;
end;



function TKMEye.GetCityCenterPolygons(aMultiplePoints: Boolean = False): TKMWordArray;
var
  I: Integer;
  PointArray: TKMPointArray;
begin
  PointArray := GetCityCenterPoints(aMultiplePoints);
  SetLength(Result, Length(PointArray));
  for I := Low(Result) to High(Result) do
    Result[I] := gAIFields.NavMesh.KMPoint2Polygon[ PointArray[I] ];
end;


function TKMEye.GetCityCenterPoints(aMultiplePoints: Boolean = False): TKMPointArray;
const
  SCANNED_HOUSES = [htStore, htSchool, htBarracks];
var
  I, Cnt: Integer;
  HT: TKMHouseType;
  H: TKMHouse;
begin
  // Find required house cnt
  Cnt := 0;
  for HT in SCANNED_HOUSES do
    Cnt := Cnt + gHands[fOwner].Stats.GetHouseQty(HT);
  SetLength(Result, 1 + (Cnt-1) * Byte(aMultiplePoints));
  // Exit if we have 0 houses
  if (Cnt = 0) then
    Exit;

  Cnt := 0;
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[I];
    if (H <> nil) AND not H.IsDestroyed AND H.IsComplete AND (H.HouseType in SCANNED_HOUSES) then
    begin
      Result[Cnt] := KMPointBelow(H.Entrance);
      Cnt := Cnt + 1;
      if (Length(Result) <= Cnt) then // in case of not aMultiplePoints
        Exit;
    end;
  end;
  SetLength(Result, Cnt); // Just to be sure ...
end;



function TKMEye.GetClosestUnitAroundHouse(aHT: TKMHouseType; aLoc: TKMPoint; aInitPoint: TKMPoint): TKMUnit;
const
  INIT_DIST = 10000;
var
  X, Y, I, Dist, Closest, Distance: Integer;
  Dir: TDirection;
  U: TKMUnit;
begin
  Result := nil;
  Closest := INIT_DIST;
  Dist := 1;
  for Dir := Low(fHousesMapping[aHT].Surroundings[Dist]) to High(fHousesMapping[aHT].Surroundings[Dist]) do
    for I := Low(fHousesMapping[aHT].Surroundings[Dist,Dir]) to High(fHousesMapping[aHT].Surroundings[Dist,Dir]) do
    begin
      Y := aLoc.Y + fHousesMapping[aHT].Surroundings[Dist,Dir,I].Y;
      X := aLoc.X + fHousesMapping[aHT].Surroundings[Dist,Dir,I].X;
      U := gTerrain.UnitsHitTest(X,Y);
      if (U <> nil)
       AND not U.IsDeadOrDying
       AND (U.Owner >= 0) // Dont select animals!
       AND (U.Owner <> fOwner)
       AND (gHands[fOwner].Alliances[U.Owner] <> atAlly) then
      begin
        Distance := KMDistanceAbs(KMPoint(X,Y), aInitPoint);
        if (Closest > Distance) then
        begin
          Closest := Distance;
          Result := U;
        end;
      end;
    end;
end;



procedure TKMEye.Paint(aRect: TKMRect);
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $8000FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;

  procedure DrawHMA();
  var
    Dist,Idx,OFFSET,MAX_DIST: Integer;
    Color: Cardinal;
    Dir: TDirection;
    Loc,Point: TKMPoint;
    HT: TKMHouseType;
    HMA: THouseMappingArray;
  begin
    MAX_DIST := Length(HMA[HOUSE_MIN].Surroundings);
    OFFSET := MAX_DIST * 2 + 5;
    Loc := KMPoint(0,OFFSET);
    HMA := fHousesMapping;
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      if (Loc.X + OFFSET > gTerrain.MapX - OFFSET) then
      begin
        if (Loc.Y + OFFSET > gTerrain.MapY - OFFSET) then
          break;
        Loc.X := 0;
        Loc.Y := Loc.Y + OFFSET;
      end;
      Loc.X := Loc.X + OFFSET;
      for Idx := Low(HMA[HT].Tiles) to High(HMA[HT].Tiles) do
        begin
          Point := KMPointAdd(Loc, HMA[HT].Tiles[Idx]);
          gRenderAux.Quad(Point.X, Point.Y, $80000000 OR COLOR_BLUE);
        end;
      for Dist := Low(HMA[HT].Surroundings) to High(HMA[HT].Surroundings) do
        for Dir := Low(HMA[HT].Surroundings[Dist]) to High(HMA[HT].Surroundings[Dist]) do
          for Idx := Low(HMA[HT].Surroundings[Dist,Dir]) to High(HMA[HT].Surroundings[Dist,Dir]) do
          //for Idx := Low(HMA[HT].Surroundings[Dist,Dir]) + Byte((Dir = dirE) OR (Dir = dirW)) to High(HMA[HT].Surroundings[Dist,Dir]) - Byte((Dir = dirE) OR (Dir = dirW)) do
          begin
            Point := KMPointAdd(Loc, HMA[HT].Surroundings[Dist,Dir,Idx]);
            Color := ((255 - Round(200 / MAX_DIST * Dist)) shl 24) OR COLOR_WHITE;
            gRenderAux.Quad(Point.X, Point.Y, Color);
          end;
      gRenderAux.Quad(Loc.X, Loc.Y, $FF000000 OR COLOR_RED);
      gRenderAux.Text(Point.X, Point.Y, gRes.Houses[HT].HouseName, $FF000000);
    end;
  end;
  procedure DrawTriangle(aIdx: Integer; aColor: Cardinal);
  var
    PolyArr: TPolygonArray;
    NodeArr: TKMPointArray;
  begin
    PolyArr := gAIFields.NavMesh.Polygons;
    NodeArr := gAIFields.NavMesh.Nodes;
    gRenderAux.TriangleOnTerrain(
      NodeArr[ PolyArr[aIdx].Indices[0] ].X,
      NodeArr[ PolyArr[aIdx].Indices[0] ].Y,
      NodeArr[ PolyArr[aIdx].Indices[1] ].X,
      NodeArr[ PolyArr[aIdx].Indices[1] ].Y,
      NodeArr[ PolyArr[aIdx].Indices[2] ].X,
      NodeArr[ PolyArr[aIdx].Indices[2] ].Y, aColor);
  end;
var
  PL: TKMHandID;
  I,X,Y: Integer;
begin
  //{ Build flood fill
  if OVERLAY_AI_EYE then
  begin
    for PL := 0 to gHands.Count - 1 do
    begin
      OwnerUpdate(PL);
      fBuildFF.UpdateState();
    end;
    for Y := 1 to fMapY - 1 do
      for X := 1 to fMapX - 1 do
        //if (fBuildFF.Visited[Y,X] = fBuildFF.VisitIdxOwner[fOwner]) then
        //if (fBuildFF.Visited[Y,X] = fBuildFF.VisitIdx) then
          case fBuildFF.State[Y,X] of
            bsNoBuild:   gRenderAux.Quad(X, Y, $BB000000 OR COLOR_BLACK);
            bsHousePlan: gRenderAux.Quad(X, Y, $66000000 OR COLOR_BLACK);
            bsFieldPlan: gRenderAux.Quad(X, Y, $55000000 OR COLOR_GREEN);
            bsRoadPlan:  gRenderAux.Quad(X, Y, $55000000 OR COLOR_BLUE);
            bsRoad:      gRenderAux.Quad(X, Y, $22000000 OR COLOR_BLUE);
            bsBuild:     gRenderAux.Quad(X, Y, $11000000 OR COLOR_YELLOW);
            bsTree:      gRenderAux.Quad(X, Y, $99000000 OR COLOR_GREEN);
            bsForest:    gRenderAux.Quad(X, Y, $33000000 OR COLOR_GREEN);
            bsCoal:      gRenderAux.Quad(X, Y, $66000000 OR COLOR_BLACK);
            bsMine:      gRenderAux.Quad(X, Y, $33000000 OR COLOR_RED);
            bsDebug:     gRenderAux.Quad(X, Y, $FF000000 OR COLOR_RED);
            bsReserved:  gRenderAux.Quad(X, Y, $66000000 OR COLOR_RED);
            else begin end;
          end;
    //{ Build places of the last plan
    for I := 0 to fBuildFF.Locs.Count - 1 do
      gRenderAux.Quad(fBuildFF.Locs.Items[I].X, fBuildFF.Locs.Items[I].Y, $99000000 OR COLOR_YELLOW);
    //}
    //{ Stone mining tiles
    for I := 0 to fStoneMiningTiles.Count - 1 do
      gRenderAux.Quad(fStoneMiningTiles.Items[I].X, fStoneMiningTiles.Items[I].Y, $99000000 OR COLOR_RED); //}
  end
  else if OVERLAY_AI_SOIL then
  begin
    //{ Soil
    for Y := 1 to fMapY - 1 do
      for X := 1 to fMapX - 1 do
        gRenderAux.Quad(X, Y, (Soil[Y,X] shl 24) OR COLOR_RED); //}
  end
  else if OVERLAY_AI_FLATAREA then
  begin
    //{ Flat Area
    for Y := 1 to fMapY - 1 do
      for X := 1 to fMapX - 1 do
        gRenderAux.Quad(X, Y, (FlatArea[Y,X] shl 24) OR COLOR_RED); //}
  end
  else if OVERLAY_AI_ROUTES then
  begin
    //{ Routes
    for Y := 1 to fMapY - 1 do
      for X := 1 to fMapX - 1 do
        gRenderAux.Quad(X, Y, (Routes[Y,X] shl 24) OR COLOR_RED); //}
  end;
end;




{ TKMBuildFF }
constructor TKMBuildFF.Create();
begin
  inherited Create();
  fUpdateTick := 0;
  SetLength(fInfoArr,0);
  fLocs := TKMPointList.Create();
end;

destructor TKMBuildFF.Destroy();
begin
  inherited;
  fLocs.free;
end;


procedure TKMBuildFF.Save(SaveStream: TKMemoryStream);
var
  Len: Integer;
begin
  SaveStream.PlaceMarker('BuildFF');

  SaveStream.Write(fOwner);
  SaveStream.Write(fVisitIdx);
  SaveStream.Write(fVisitIdxHouse);
  SaveStream.Write(fStartQueue);
  SaveStream.Write(fEndQueue);
  SaveStream.Write(fQueueCnt);
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
  SaveStream.Write(fUpdateTick);

  SaveStream.Write(fOwnerUpdateInfo, SizeOf(fOwnerUpdateInfo));
  SaveStream.Write(fHouseReq, SizeOf(fHouseReq));

  fLocs.SaveToStream(SaveStream);

  Len := Length(fInfoArr);
  SaveStream.Write(Len);
  if (Len > 0) then
    SaveStream.Write(fInfoArr[0], SizeOf(fInfoArr[0]) * Len);
  //}
end;


procedure TKMBuildFF.Load(LoadStream: TKMemoryStream);
var
  Len: Integer;
begin
  LoadStream.CheckMarker('BuildFF');

  LoadStream.Read(fOwner);
  LoadStream.Read(fVisitIdx);
  LoadStream.Read(fVisitIdxHouse);
  LoadStream.Read(fStartQueue);
  LoadStream.Read(fEndQueue);
  LoadStream.Read(fQueueCnt);
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
  LoadStream.Read(fUpdateTick);

  LoadStream.Read(fOwnerUpdateInfo, SizeOf(fOwnerUpdateInfo));
  LoadStream.Read(fHouseReq, SizeOf(fHouseReq));

  fLocs.LoadFromStream(LoadStream);

  LoadStream.Read(Len);
  SetLength(fInfoArr,Len);
  if (Len > 0) then
    LoadStream.Read(fInfoArr[0], SizeOf(fInfoArr[0]) * Len);
  //}
end;


// Transform 1D array to 2D
//function TKMBuildFF.GetInfo(const aY,aX: Word): TKMBuildInfo;
//begin
//  Result := fInfoArr[aY*fMapX + aX];
//end;
//procedure TKMBuildFF.SetInfo(const aY,aX,aNext,aDistance: Word; const aVisited: Byte; const aState: TKMBuildState);
//begin
//  with fInfoArr[aY*fMapX + aX] do
//  begin
//    Visited := aVisited;
//    State := aState;
//    Next := aNext;
//    Distance := aDistance;
//  end;
//end;

function TKMBuildFF.GetVisited(const aY,aX: Word): Byte;
begin
  Result := fInfoArr[aY*fMapX + aX].Visited;
end;
procedure TKMBuildFF.SetVisited(const aY,aX: Word; const aVisited: Byte);
begin
  fInfoArr[aY*fMapX + aX].Visited := aVisited;
end;

function TKMBuildFF.GetOwnersIndex(const aOwner: TKMHandID): Byte;
begin
  Result := fOwnerUpdateInfo[aOwner];
end;

function TKMBuildFF.GetState(const aY,aX: Word): TKMBuildState;
begin
  Result := fInfoArr[aY*fMapX + aX].State;
end;
procedure TKMBuildFF.SetState(const aY,aX: Word; const aState: TKMBuildState);
begin
  fInfoArr[aY*fMapX + aX].State := aState;
end;

function TKMBuildFF.GetStateFromIdx(const aIdx: Word): TKMBuildState;
begin
  Result := fInfoArr[aIdx].State;
end;

function TKMBuildFF.GetDistance(const aPoint: TKMPoint): Word;
begin
  Result := fInfoArr[aPoint.Y*fMapX + aPoint.X].Distance;
end;
function TKMBuildFF.GetDistanceInitPoint(const aPoint: TKMPoint): Word;
begin
  Result := fInfoArr[aPoint.Y*fMapX + aPoint.X].DistanceInitPoint;
end;

function TKMBuildFF.GetNext(const aY,aX: Word): Word;
begin
  Result := fInfoArr[aY*fMapX + aX].Next;
end;
procedure TKMBuildFF.SetNext(const aY,aX,aNext: Word);
begin
  fInfoArr[aY*fMapX + aX].Next := aNext;
end;


// Init queue
procedure TKMBuildFF.InitQueue(aHouseFF: Boolean);
var
  K: Integer;
begin
  fHMA := gAIFields.Eye.HousesMapping; // Make sure that HMA is actual
  fQueueCnt := 0;
  if (fVisitIdx >= 254) then
  begin
    fVisitIdx := 0;
    for K := 0 to Length(fInfoArr) - 1 do
      fInfoArr[K].Visited := 0;
    //FillChar(fInfoArr[0], SizeOf(TKMBuildInfo[0])*Length(fInfoArr), #0);
  end;
  if (fVisitIdxHouse >= 254) then
  begin
    fVisitIdxHouse := 0;
    for K := 0 to Length(fInfoArr) - 1 do
      fInfoArr[K].VisitedHouse := 0;
  end;
  if aHouseFF then
    fVisitIdxHouse := fVisitIdxHouse + 1
  else
    fVisitIdx := fVisitIdx + 1;
end;


function TKMBuildFF.InsertInQueue(const aIdx: Word): Word;
begin
  if (fQueueCnt = 0) then
    fStartQueue := aIdx
  else
    fInfoArr[fEndQueue].Next := aIdx;
  fEndQueue := aIdx;
  fQueueCnt := fQueueCnt + 1;
  Result := aIdx;
end;


function TKMBuildFF.RemoveFromQueue(var aX,aY,aIdx: Word): Boolean;
begin
  Result := (fQueueCnt > 0);
  if Result then
  begin
    aIdx := fStartQueue;
    aY := fInfoArr[fStartQueue].Y;// aIdx div fMapX;
    aX := aIdx - aY * fMapX;
    fStartQueue := fInfoArr[fStartQueue].Next;
    fQueueCnt := fQueueCnt - 1;
  end;
end;


function TKMBuildFF.CanBeVisited(const aX,aY,aIdx: Word; const aHouseQueue: Boolean = False): Boolean;
begin
  // tpOwn - walkable tile + height evaluation
  if aHouseQueue then
    Result := (fInfoArr[aIdx].Visited = fVisitIdx) AND (fInfoArr[aIdx].VisitedHouse < fVisitIdxHouse) AND gTerrain.TileIsRoadable( KMPoint(aX,aY) ) AND (tpOwn in gTerrain.Land[aY,aX].Passability)
  else
    Result := (fInfoArr[aIdx].Visited < fVisitIdx) AND gTerrain.TileIsRoadable( KMPoint(aX,aY) );//(tpOwn in gTerrain.Land[aY,aX].Passability);
end;


procedure TKMBuildFF.MarkAsVisited(const aY,aIdx,aDistance: Word; const aState: TKMBuildState);
begin
  with fInfoArr[aIdx] do
  begin
    Y := aY;
    Visited := fVisitIdx;
    State := aState;
    Distance := aDistance;
  end;
end;
procedure TKMBuildFF.MarkAsVisited(const aX,aY,aIdx,aDistance: Word);
var
  Point: TKMPoint;
begin
  with fInfoArr[aIdx] do
  begin
    VisitedHouse := fVisitIdxHouse;
    DistanceInitPoint := aDistance;

    Point := KMPoint(aX,aY);
    if CanBePlacedHouse(Point) then
      fLocs.Add(Point);
  end;
end;


function TKMBuildFF.CanBePlacedHouse(const aLoc: TKMPoint): Boolean;
const
  DIST = 1;
var
  LeftSideFree, RightSideFree, CoalUnderPlan: Boolean;
  K: Integer;
  Point: TKMPoint;
  Dir: TDirection;
begin
  Result := False;
  CoalUnderPlan := False;
  with fHMA[fHouseReq.HouseType] do
  begin
    for K := Low(Tiles) to High(Tiles) do
    begin
      Point := KMPointAdd(aLoc, Tiles[K]);
      if (Point.Y < 2) OR (Point.X < 2) OR (Point.X > fMapX - 2) OR (Point.Y > fMapY - 2) then
        Exit;
      case State[Point.Y, Point.X] of
        bsDebug,bsBuild:
        begin

        end;
        bsTree:
        begin
          if not fHouseReq.IgnoreTrees then
            Exit;
        end;
        bsCoal:
        begin
          CoalUnderPlan := True;
          if not fHouseReq.IgnoreAvoidBuilding then
            Exit;
        end;
        bsForest:
        begin
          if not fHouseReq.IgnoreAvoidBuilding then
            Exit;
        end;
        else
          Exit;
      end;
    end;
    if (fHouseReq.HouseType = htCoalMine) AND not CoalUnderPlan then
      Exit;
    // Scan tiles in distance 1 from house plan
    LeftSideFree := True;
    RightSideFree := True;
    for Dir := Low(Surroundings[DIST]) to High(Surroundings[DIST]) do
      //for K := Low(Surroundings[DIST,Dir]) to High(Surroundings[DIST,Dir]) do
      for K := Low(Surroundings[DIST,Dir]) + Byte(Dir = dirS) to High(Surroundings[DIST,Dir]) - Byte(Dir = dirS) do
      begin
        Point := KMPointAdd(aLoc, Surroundings[DIST,Dir,K]);
        if fHouseReq.IgnoreAvoidBuilding AND (State[Point.Y, Point.X] in [bsReserved, bsHousePlan]) then
          Exit;
        if (Dir = dirS) AND (State[Point.Y, Point.X] in [bsNoBuild, bsHousePlan, bsFieldPlan]) then
          Exit;
        if (Dir = dirE) then
          RightSideFree := RightSideFree AND not (State[Point.Y, Point.X] in [bsNoBuild, bsHousePlan]);
        if (Dir = dirW) then
          LeftSideFree := LeftSideFree AND not (State[Point.Y, Point.X] in [bsNoBuild, bsHousePlan]);
        if not (LeftSideFree OR RightSideFree) then
          Exit;
      end;
  end;
  Result := True;
end;


function TKMBuildFF.GetTerrainState(const aX,aY: Word): TKMBuildState;
var
  AB: Byte;
  Output: TKMBuildState;
begin
  Result := bsNoBuild;

  // Passability
  if (tpBuild in gTerrain.Land[aY,aX].Passability) then
    Output := bsBuild
  else if (gTerrain.ObjectIsChopableTree(KMPoint(aX,aY), [caAge1,caAge2,caAge3,caAgeFull])
        AND gHands[fOwner].CanAddFieldPlan(KMPoint(aX,aY), ftWine)) then
    Output := bsTree
  else if (gTerrain.Land[aY,aX].Passability * [tpMakeRoads, tpWalkRoad] <> []) then
    Output := bsRoad
  else if (gTerrain.Land[aY,aX].TileLock = tlRoadWork) then
    Output := bsRoadPlan
  else
    Exit;
  // Avoid building
  AB := gAIFields.Influences.AvoidBuilding[aY, aX];
  case AB of
    AVOID_BUILDING_NODE_LOCK_FIELD:    Output := bsFieldPlan;
    AVOID_BUILDING_NODE_LOCK_ROAD:     Output := bsRoadPlan;
    AVOID_BUILDING_HOUSE_INSIDE_LOCK:  Output := bsReserved;
    AVOID_BUILDING_HOUSE_OUTSIDE_LOCK:
      begin
        if (Output = bsBuild) then
          Output := bsRoad;
      end;
    AVOID_BUILDING_HOUSE_ENTRANCE:     Output := bsRoad;
    AVOID_BUILDING_MINE_TILE:          Output := bsMine;
    AVOID_BUILDING_COAL_TILE:
      begin
        case Output of
          bsTree: Output := bsNoBuild;
          bsNoBuild: Output := bsNoBuild;
          bsBuild: Output := bsCoal;
          //bsRoad: Output := bsCoal;
          //bsRoadPlan: Output := bsCoal;
        end;
      end;
    else
    begin
      if (AB > AVOID_BUILDING_FOREST_MINIMUM) AND (Output <> bsTree) then
        Output := bsForest;
    end;
  end;
  Result := Output;
end;


procedure TKMBuildFF.MarkPlans();
const
  DIST = 1;
var
  PL: TKMHandID;
  K,L: Integer;
  Dir: TDirection;
  P1,P2: TKMPoint;
  HT: TKMHouseType;
begin
// Mark plans (only allied houses)
  for PL := 0 to gHands.Count - 1 do
    if (gHands[fOwner].Alliances[PL] = atAlly) then
    begin
      // House plans
      for K := 0 to gHands[PL].BuildList.HousePlanList.Count - 1 do
        with gHands[PL].BuildList.HousePlanList.Plans[K] do
        begin
          HT := HouseType;
          if (HT = htNone) then
            continue;
          P1 := KMPointAdd( Loc, KMPoint(gRes.Houses[HT].EntranceOffsetX,0) ); // Plans have moved offset so fix it (because there is never enought exceptions ;)
          // Internal house tiles
          for L := Low(fHMA[HT].Tiles) to High(fHMA[HT].Tiles) do
          begin
            P2 := KMPointAdd(P1, fHMA[HT].Tiles[L]);
            State[P2.Y, P2.X] := bsHousePlan;
          end;
          // External house tiles in distance 1 from house plan
          for Dir := Low(fHMA[HT].Surroundings[DIST]) to High(fHMA[HT].Surroundings[DIST]) do
            for L := Low(fHMA[HT].Surroundings[DIST,Dir]) to High(fHMA[HT].Surroundings[DIST,Dir]) do
            begin
              P2 := KMPointAdd(P1, fHMA[HT].Surroundings[DIST,Dir,L]);
              if (gTerrain.Land[P2.Y,P2.X].Passability * [tpMakeRoads, tpWalkRoad] <> []) then
                State[P2.Y, P2.X] := bsRoad
              else if (State[P2.Y, P2.X] <> bsNoBuild) then
                State[P2.Y, P2.X] := bsHousePlan;
            end;
        end;
      // Field plans
      for K := 0 to gHands[PL].BuildList.FieldworksList.Count - 1 do
        with gHands[PL].BuildList.FieldworksList.Fields[K] do
          case FieldType of
            ftNone: continue;
            ftRoad: State[Loc.Y, Loc.X] := bsRoadPlan;
            else State[Loc.Y, Loc.X] := bsFieldPlan;
          end;
    end;
end;


procedure TKMBuildFF.TerrainFF(aMaxDistance: Word);
var
  X,Y,Idx,Distance: Word;
begin
  while RemoveFromQueue(X,Y,Idx) do
  begin
    Distance := fInfoArr[Idx].Distance + 1;
    if (Distance > aMaxDistance) then
      break;
    if (Y-1 >= 1      ) AND CanBeVisited(X,Y-1,Idx-fMapX) then MarkAsVisited(Y-1, InsertInQueue(Idx-fMapX), Distance, GetTerrainState(X,Y-1));
    if (X-1 >= 1      ) AND CanBeVisited(X-1,Y,Idx-1    ) then MarkAsVisited(Y,   InsertInQueue(Idx-1)    , Distance, GetTerrainState(X-1,Y));
    if (X+1 <= fMapX-1) AND CanBeVisited(X+1,Y,Idx+1    ) then MarkAsVisited(Y,   InsertInQueue(Idx+1)    , Distance, GetTerrainState(X+1,Y));
    if (Y+1 <= fMapY-1) AND CanBeVisited(X,Y+1,Idx+fMapX) then MarkAsVisited(Y+1, InsertInQueue(Idx+fMapX), Distance, GetTerrainState(X,Y+1));
  end;
end;


procedure TKMBuildFF.HouseFF();
const
  MAX_DIST = 40-10;
var
  X,Y,Idx,Distance: Word;
begin
  while RemoveFromQueue(X,Y,Idx) do
  begin
    Distance := fInfoArr[Idx].DistanceInitPoint + 1;
    if (Distance > MAX_DIST)
      OR (fHouseReq.MaxCnt <= fLocs.Count)
      OR (Distance > fHouseReq.MaxDist) then
      break;
    if (Y-1 >= 1      ) AND CanBeVisited(X,Y-1,Idx-fMapX,True) then MarkAsVisited(X,Y-1, InsertInQueue(Idx-fMapX), Distance);
    if (X-1 >= 1      ) AND CanBeVisited(X-1,Y,Idx-1    ,True) then MarkAsVisited(X-1,Y, InsertInQueue(Idx-1)    , Distance);
    if (X+1 <= fMapX-1) AND CanBeVisited(X+1,Y,Idx+1    ,True) then MarkAsVisited(X+1,Y, InsertInQueue(Idx+1)    , Distance);
    if (Y+1 <= fMapY-1) AND CanBeVisited(X,Y+1,Idx+fMapX,True) then MarkAsVisited(X,Y+1, InsertInQueue(Idx+fMapX), Distance);
  end;
end;


procedure TKMBuildFF.AfterMissionInit();
begin
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
  SetLength(fInfoArr, fMapX * fMapY);
  FillChar(fInfoArr[0], SizeOf(fInfoArr[0])*Length(fInfoArr), #0);
  fVisitIdx := 255;
  fVisitIdxHouse := 255;
end;


procedure TKMBuildFF.UpdateState(aMaxFFDistance: Word = 40);
  procedure MarkHouse(Loc: TKMPoint);
  begin
    MarkAsVisited(Loc.Y, InsertInQueue(Loc.Y*fMapX + Loc.X), 0, GetTerrainState(Loc.X,Loc.Y));
  end;
var
  K: Integer;
  H: TKMHouse;
  HT: TKMHouseType;
  Planner: TKMCityPlanner;
begin
  Planner := gHands[fOwner].AI.CityManagement.Builder.Planner;

  if (fUpdateTick = 0) OR (fUpdateTick < gGame.GameTick) then // Dont scan multile times terrain in 1 tick
  begin
    InitQueue(False);
    fOwnerUpdateInfo[fOwner] := fVisitIdx; // Debug tool

    if (gGame.GameTick <= MAX_HANDS) then // Make sure that Planner is already updated otherwise take only available houses
    begin
      for K := 0 to gHands[fOwner].Houses.Count - 1 do
      begin
        H := gHands[fOwner].Houses[K];
        if (H <> nil) AND not H.IsDestroyed AND not (H.HouseType in [htWatchTower, htWoodcutters]) then
          MarkHouse(H.Entrance);
      end;
    end
    else
    begin
      for HT := HOUSE_MIN to HOUSE_MAX do
        if not (HT in [htWatchTower, htWoodcutters]) then
          with Planner.PlannedHouses[HT] do
            for K := 0 to Count - 1 do
              MarkHouse(Plans[K].Loc);
    end;
    TerrainFF(aMaxFFDistance);

    fUpdateTick := gGame.GameTick;
    MarkPlans(); // Plans may change during placing houses but this event is caught in CityBuilder
  end;
end;


procedure TKMBuildFF.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fUpdateTick := 0; // Make sure that area will be scanned in next update
end;


procedure TKMBuildFF.ActualizeTile(aX, aY: Word);
begin
  if (fUpdateTick = gGame.GameTick) then // Actualize tile only when we need scan in this tick
    State[aY, aX] := GetTerrainState(aX,aY);
end;


procedure TKMBuildFF.FindPlaceForHouse(aHouseReq: TKMHouseRequirements; InitPointsArr: TKMPointArray; aClearHouseList: Boolean = True);
var
  K: Integer;
begin
  if aClearHouseList then
    fLocs.Clear;
  if (Length(InitPointsArr) <= 0) then
    Exit;

  fHouseReq := aHouseReq;
  UpdateState();

  InitQueue(True);
  for K := 0 to Length(InitPointsArr) - 1 do
    with InitPointsArr[K] do
      if CanBeVisited(X,Y,Y*fMapX + X, True) then
        MarkAsVisited(X,Y, InsertInQueue(Y*fMapX + X), 0);

  HouseFF();
end;




{ TKMFFInitPlace }
constructor TKMFFInitPlace.Create(aMapX,aMapY: Word; var aArea: TKMByteArray);
begin
  fMapX := aMapX;
  fMapY := aMapY;
  fArea := aArea;
  SetLength(fVisitArr, (aMapX+1) * (aMapY+1));
  fQueue := TQueue.Create();
end;

destructor TKMFFInitPlace.Destroy();
begin
  fQueue.Free();
  inherited;
end;

function TKMFFInitPlace.CanBeVisited(const aX,aY, aDistance: Word): Boolean;
var
  Idx: Word;
begin
  Idx := aY*fMapX + aX;
  Result := not fVisitArr[Idx] AND (fArea[Idx] < aDistance);
end;

procedure TKMFFInitPlace.MarkAsVisited(const aIdx, aDistance: Word);
begin
  fVisitArr[aIdx] := True;
  fArea[aIdx] := aDistance;
end;

procedure TKMFFInitPlace.InsertInQueue(const aX,aY, aDistance: Word);
var
  DE: PDistElement;
begin
  MarkAsVisited(aY*fMapX + aX,aDistance);
  New(DE);
  DE^.X := aX;
  DE^.Y := aY;
  DE^.Distance := aDistance;
  fQueue.Push(DE);
end;

function TKMFFInitPlace.RemoveFromQueue(var aX,aY, aDistance: Word): Boolean;
var
  DE: PDistElement;
begin
  Result := (fQueue.Count > 0);
  if Result then
  begin
    DE := fQueue.Pop;
    aX := DE^.X;
    aY := DE^.Y;
    aDistance := DE^.Distance;
    Dispose(DE);
  end;
end;

procedure TKMFFInitPlace.FillArea(aCount: Word; aInitPoints: TKMPointArray);
const
  INIT_VALUE = 255;
  DEC_COEF = 15;
var
  I,X,Y,Distance: Word;
begin
  FillChar(fVisitArr[0], SizeOf(fVisitArr[0]) * Length(fVisitArr), #0);
  for I := 0 to aCount - 1 do
    if CanBeVisited(aInitPoints[I].X, aInitPoints[I].Y, INIT_VALUE) then
      InsertInQueue(aInitPoints[I].X, aInitPoints[I].Y, INIT_VALUE);
  while RemoveFromQueue(X,Y,Distance) do
    if (Distance > DEC_COEF) then
    begin
      Distance := Distance - DEC_COEF;
      if (X > 0)       AND CanBeVisited(X-1,Y,Distance) then InsertInQueue(X-1,Y,Distance);
      if (X < fMapX-1) AND CanBeVisited(X+1,Y,Distance) then InsertInQueue(X+1,Y,Distance);
      if (Y > 0)       AND CanBeVisited(X,Y-1,Distance) then InsertInQueue(X,Y-1,Distance);
      if (Y < fMapY-1) AND CanBeVisited(X,Y+1,Distance) then InsertInQueue(X,Y+1,Distance);
    end;
end;



{ TKMFFCheckStoneTiles }
constructor TKMFFCheckStoneTiles.Create(aStoneLimit: Integer; const aScanEightTiles: Boolean = False);
begin
  inherited Create(aScanEightTiles);
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
  fMinLimit := KMPoint(1,1);
  fMaxLimit := KMPoint(fMapX-1,fMapY-1);
  fStoneLimit := aStoneLimit;
  fVisitIdx := 0;
  SetLength(fVisitArr,fMapX*fMapY);
end;


function TKMFFCheckStoneTiles.CanBeVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := gTerrain.TileHasStone(aX,aY) AND (fStoneLimit > fStoneCnt);
end;


function TKMFFCheckStoneTiles.IsVisited(const aX,aY: SmallInt): Boolean;
begin
  Result := fVisitArr[aY*fMapX + aX] = fVisitIdx;
end;


procedure TKMFFCheckStoneTiles.MarkAsVisited(const aX,aY: SmallInt);
begin
  fVisitArr[aY*fMapX + aX] := fVisitIdx;
  fStoneCnt := fStoneCnt + gTerrain.TileIsStone(aX,aY)*3;
end;


function TKMFFCheckStoneTiles.CheckCount(aX,aY: SmallInt): Boolean;
begin
  if (fVisitIdx > 254) then
  begin
    fVisitIdx := 0;
    FillChar(fVisitArr[0], SizeOf(fVisitArr[0]) * Length(fVisitArr), #0);
  end;
  fVisitIdx := fVisitIdx + 1;
  fStoneCnt := 0;
  QuickFlood(aX,aY);
  Result := (fStoneLimit <= fStoneCnt);
end;


end.


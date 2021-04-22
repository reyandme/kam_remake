unit KM_Terrain;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils, Graphics,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils, KM_ResTileset,
  KM_TerrainTypes,
  KM_ResHouses, KM_ResWares, KM_TerrainFinder, KM_ResMapElements,
  KM_CommonTypes,
  KM_ResTypes;


type
  {Class to store all terrain data, aswell terrain routines}
  TKMTerrain = class
  private
    fLand: TKMLand;
    fMainLand: PKMLand; // pointer to the actual fLand with all terrain data

    fAnimStep: Cardinal;
    fMapEditor: Boolean; //In MapEd mode some features behave differently
    fMapX: Word; //Terrain width
    fMapY: Word; //Terrain height
    fMapRect: TKMRect; //Terrain rect (1, 1, MapX, MapY)

    fTileset: TKMResTileset;
    fFinder: TKMTerrainFinder;

    fBoundsWC: TKMRect; //WC rebuild bounds used in FlattenTerrain (put outside to fight with recursion SO error in FlattenTerrain EnsureWalkable)

    fUnitPointersTemp: array [1..MAX_MAP_SIZE, 1..MAX_MAP_SIZE] of Pointer;

    function TileHasParameter(X,Y: Word; aCheckTileFunc: TBooleanWordFunc; aAllow2CornerTiles: Boolean = False;
                              aStrictCheck: Boolean = False): Boolean;

    function GetMiningRect(aRes: TKMWareType): TKMRect;

    function ChooseCuttingDirection(const aLoc, aTree: TKMPoint; out CuttingPoint: TKMPointDir): Boolean;
    procedure DoFlattenTerrain(const Loc: TKMPoint; var aDepth: Byte; aUpdateWalkConnects: Boolean; aIgnoreCanElevate: Boolean);

    procedure UpdateWalkConnect(const aSet: TKMWalkConnectSet; aRect: TKMRect; aDiagObjectsEffected: Boolean);

    procedure SetField_Init(const Loc: TKMPoint; aOwner: TKMHandID; aRemoveOverlay: Boolean = True);
    procedure SetField_Complete(const Loc: TKMPoint; aFieldType: TKMFieldType);

    function TrySetTile(X, Y: Integer; aType, aRot: Integer; aUpdatePassability: Boolean = True): Boolean; overload;
    function TrySetTile(X, Y: Integer; aType, aRot: Integer; out aPassRect: TKMRect;
                        out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean; overload;
    function TrySetTileHeight(X, Y: Integer; aHeight: Byte; aUpdatePassability: Boolean = True): Boolean;
    function TrySetTileObject(X, Y: Integer; aObject: Word; aUpdatePassability: Boolean = True): Boolean; overload;
    function TrySetTileObject(X, Y: Integer; aObject: Word; out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean; overload;

    function HousesNearTile(X,Y: Word): Boolean;
  public
    Land: PKMLand;

    Fences: TKMLandFences;
    FallingTrees: TKMPointTagList;

    constructor Create;
    destructor Destroy; override;

    procedure MakeNewMap(aWidth, aHeight: Integer; aMapEditor: Boolean);
    procedure LoadFromFile(const FileName: UnicodeString; aMapEditor: Boolean);
    procedure SaveToFile(const aFile: UnicodeString); overload;
    procedure SaveToFile(const aFile: UnicodeString; const aInsetRect: TKMRect); overload;

    property MainLand: PKMLand read fMainLand; // readonly

    property MapX: Word read fMapX;
    property MapY: Word read fMapY;
    property MapRect: TKMRect read fMapRect;

    procedure SetMainLand;

    procedure SetTileLock(const aLoc: TKMPoint; aTileLock: TKMTileLock);
    procedure UnlockTile(const aLoc: TKMPoint);
    procedure SetRoads(aList: TKMPointList; aOwner: TKMHandID; aUpdateWalkConnects: Boolean = True);
    procedure SetRoad(const Loc: TKMPoint; aOwner: TKMHandID);
    procedure SetInitWine(const Loc: TKMPoint; aOwner: TKMHandID);
    function GetFieldType(const Loc: TKMPoint): TKMFieldType;
    procedure SetFieldNoUpdate(const Loc: TKMPoint; aOwner: TKMHandID; aFieldType: TKMFieldType; aStage: Byte = 0);
    procedure SetField(const Loc: TKMPoint; aOwner: TKMHandID; aFieldType: TKMFieldType; aStage: Byte = 0;
                       aRandomAge: Boolean = False; aKeepOldObject: Boolean = False; aRemoveOverlay: Boolean = True;
                       aDoUpdate: Boolean = True);
    procedure SetHouse(const Loc: TKMPoint; aHouseType: TKMHouseType; aHouseStage: TKMHouseStage; aOwner: TKMHandID; const aFlattenTerrain: Boolean = False);
    procedure SetHouseAreaOwner(const Loc: TKMPoint; aHouseType: TKMHouseType; aOwner: TKMHandID);

    procedure RemovePlayer(aPlayer: TKMHandID);
    procedure RemRoad(const Loc: TKMPoint);
    procedure RemField(const Loc: TKMPoint); overload;
    procedure RemField(const Loc: TKMPoint; aDoUpdatePass, aDoUpdateWalk, aDoUpdateFences: Boolean); overload;
    procedure RemField(const Loc: TKMPoint; aDoUpdatePass, aDoUpdateWalk: Boolean; out aUpdatePassRect: TKMRect;
                       out aDiagObjectChanged: Boolean; aDoUpdateFences: Boolean); overload;
    procedure ClearPlayerLand(aPlayer: TKMHandID);

    procedure IncDigState(const Loc: TKMPoint);
    procedure ResetDigState(const Loc: TKMPoint);

    function CanPlaceUnit(const Loc: TKMPoint; aUnitType: TKMUnitType): Boolean;
    function CanPlaceGoldMine(X, Y: Word): Boolean;
    function CanPlaceIronMine(X, Y: Word): Boolean;
    function CanPlaceHouse(Loc: TKMPoint; aHouseType: TKMHouseType): Boolean;
    function CanPlaceHouseFromScript(aHouseType: TKMHouseType; const Loc: TKMPoint): Boolean;
    function CheckHouseBounds(aHouseType: TKMHouseType; const Loc: TKMPoint; aInsetRect: TKMRect): Boolean;
    function CanAddField(aX, aY: Word; aFieldType: TKMFieldType): Boolean;
    function CheckHeightPass(const aLoc: TKMPoint; aPass: TKMHeightPass): Boolean;
    procedure AddHouseRemainder(const Loc: TKMPoint; aHouseType: TKMHouseType; aBuildState: TKMHouseBuildState);

    procedure FindWineFieldLocs(const aLoc: TKMPoint; aRadius: Integer; aCornLocs: TKMPointList);
    function FindWineField(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; out FieldPoint: TKMPointDir): Boolean;
    procedure FindCornFieldLocs(const aLoc: TKMPoint; aRadius: Integer; aCornLocs: TKMPointList);
    function FindCornField(const aLoc: TKMPoint; aRadius:integer; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                           out PlantAct: TKMPlantAct; out FieldPoint: TKMPointDir): Boolean;
    function FindStone(const aLoc: TKMPoint; aRadius: Byte; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                       out StonePoint: TKMPointDir): Boolean;
    procedure FindStoneLocs(const aLoc: TKMPoint; aRadius: Byte; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                            aStoneLocs: TKMPointList);
    function FindOre(const aLoc: TKMPoint; aRes: TKMWareType; out OrePoint: TKMPoint): Boolean;
    procedure FindOrePoints(const aLoc: TKMPoint; aRes: TKMWareType; var aPoints: TKMPointListArray);
    procedure FindOrePointsByDistance(aLoc: TKMPoint; aRes: TKMWareType; var aPoints: TKMPointListArray);
    function CanFindTree(const aLoc: TKMPoint; aRadius: Word; aOnlyAgeFull: Boolean = False):Boolean;
    procedure FindTree(const aLoc: TKMPoint; aRadius: Word; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                       Trees: TKMPointDirCenteredList; BestToPlant,SecondBestToPlant: TKMPointCenteredList);
    procedure FindPossibleTreePoints(const aLoc: TKMPoint; aRadius: Word; aTiles: TKMPointList);
    procedure FindFishWaterLocs(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                                ChosenTiles: TKMPointDirList);
    function FindFishWater(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits:
                           Boolean; out FishPoint: TKMPointDir): Boolean;
    function FindBestTreeType(const aLoc: TKMPoint): TKMTreeType;
    function CanFindFishingWater(const aLoc: TKMPoint; aRadius: Integer): Boolean;

    function ChooseTreeToPlant(const aLoc: TKMPoint): Integer;
    function ChooseTreeToPlace(const aLoc: TKMPoint; aTreeAge: TKMChopableAge; aAlwaysPlaceTree: Boolean): Integer;

    procedure GetHouseMarks(const aLoc: TKMPoint; aHouseType: TKMHouseType; aList: TKMPointTagList);

    function WaterHasFish(const aLoc: TKMPoint): Boolean;
    function CatchFish(aLoc: TKMPointDir; TestOnly: Boolean = False): Boolean;

    procedure SetObject(const Loc: TKMPoint; ID: Integer);
    procedure SetOverlay(const Loc: TKMPoint; aOverlay: TKMTileOverlay; aOverwrite: Boolean);
    function FallTree(const Loc: TKMPoint): Boolean;
    procedure ChopTree(const Loc: TKMPoint);
    procedure RemoveObject(const Loc: TKMPoint);
    procedure RemoveObjectsKilledByRoad(const Loc: TKMPoint);

    procedure SowCorn(const Loc: TKMPoint);
    function CutCorn(const Loc: TKMPoint): Boolean;
    function CutGrapes(const Loc: TKMPoint): Boolean;

    function DecStoneDeposit(const Loc: TKMPoint): Boolean;
    function DecOreDeposit(const Loc: TKMPoint; rt: TKMWareType): Boolean;

    function GetPassablePointWithinSegment(OriginPoint, TargetPoint: TKMPoint; aPass: TKMTerrainPassability; MaxDistance: Integer = -1): TKMPoint;
    function CheckPassability(X, Y: Integer; aPass: TKMTerrainPassability): Boolean; overload;
    function CheckPassability(const Loc: TKMPoint; aPass: TKMTerrainPassability): Boolean; overload;
    function HasUnit(const Loc: TKMPoint): Boolean;
    function HasVertexUnit(const Loc: TKMPoint): Boolean;
    function GetRoadConnectID(const Loc: TKMPoint): Byte;
    function GetWalkConnectID(const Loc: TKMPoint): Byte;
    function GetConnectID(aWalkConnect: TKMWalkConnect; const Loc: TKMPoint): Byte;

    function CheckAnimalIsStuck(const Loc: TKMPoint; aPass: TKMTerrainPassability; aCheckUnits: Boolean = True): Boolean;
    function GetOutOfTheWay(aUnit: Pointer; const PusherLoc: TKMPoint; aPass: TKMTerrainPassability; aPusherWasPushed: Boolean = False): TKMPoint;
    function FindSideStepPosition(const Loc, Loc2, Loc3: TKMPoint; aPass: TKMTerrainPassability; out SidePoint: TKMPoint; OnlyTakeBest: Boolean = False): Boolean;
    function Route_CanBeMade(const LocA, LocB: TKMPoint; aPass: TKMTerrainPassability; aDistance: Single): Boolean;
    function Route_CanBeMadeToVertex(const LocA, LocB: TKMPoint; aPass: TKMTerrainPassability): Boolean;
    function GetClosestTile(const TargetLoc, OriginLoc: TKMPoint; aPass: TKMTerrainPassability; aAcceptTargetLoc: Boolean): TKMPoint;
    function GetClosestRoad(const aFromLoc: TKMPoint; aWalkConnectIDSet: TKMByteSet; aPass: TKMTerrainPassability = tpWalkRoad): TKMPoint;

    procedure UnitAdd(const LocTo: TKMPoint; aUnit: Pointer);
    procedure UnitRem(const LocFrom: TKMPoint);
    procedure UnitWalk(const LocFrom,LocTo: TKMPoint; aUnit: Pointer);
    procedure UnitSwap(const LocFrom,LocTo: TKMPoint; UnitFrom: Pointer);
    procedure UnitVertexAdd(const LocTo: TKMPoint; Usage: TKMVertexUsage); overload;
    procedure UnitVertexAdd(const LocFrom, LocTo: TKMPoint); overload;
    procedure UnitVertexRem(const LocFrom: TKMPoint);
    function VertexUsageCompatible(const LocFrom, LocTo: TKMPoint): Boolean;
    function GetVertexUsageType(const LocFrom, LocTo: TKMPoint): TKMVertexUsage;

    function CoordsWithinMap(X, Y: Single; aInset: Byte = 0): Boolean; inline;
    function PointFInMapCoords(const aPointF: TKMPointF; aInset: Byte = 0): Boolean; inline;
    function TileInMapCoords(X, Y: Integer; Inset: Byte = 0): Boolean; overload; inline;
    function TileInMapCoords(const aCell: TKMPoint; Inset: Byte = 0): Boolean; overload; inline;
    function TileInMapCoords(X,Y: Integer; InsetRect: TKMRect): Boolean; overload; inline;
    function VerticeInMapCoords(X, Y: Integer; Inset: Byte = 0): Boolean; overload; inline;
    function VerticeInMapCoords(const aCell: TKMPoint; Inset: Byte = 0): Boolean; overload; inline;
    procedure EnsureCoordsWithinMap(var X, Y: Single; aInset: Byte = 0); inline;
    function EnsureTilesRectWithinMap(const aRectF: TKMRectF; aInset: Single = 0): TKMRectF; inline;
    function EnsureVerticesRectWithinMap(const aRectF: TKMRectF; aInset: Single = 0): TKMRectF; inline;
    function EnsureTileInMapCoords(X, Y: Integer; aInset: Byte = 0): TKMPoint; overload; inline;
    function EnsureTileInMapCoords(const aLoc: TKMPoint; aInset: Byte = 0): TKMPoint; overload; inline;

    function TileGoodForIronMine(X, Y: Word): Boolean;
    function TileGoodForGoldmine(X, Y: Word): Boolean;
    function TileGoodForField(X, Y: Word): Boolean;
    function TileGoodToPlantTree(X, Y: Word): Boolean;
    function TileIsWater(const Loc: TKMPoint): Boolean; overload; inline;
    function TileIsWater(X, Y: Word): Boolean; overload; inline;
    function TileIsStone(X, Y: Word): Byte; inline;
    function TileIsSnow(X, Y: Word): Boolean; inline;
    function TileIsCoal(X, Y: Word): Byte; inline;
    function TileIsIron(X, Y: Word): Byte; inline;
    function TileIsGold(X, Y: Word): Byte; inline;
    function TileIsCornField(const Loc: TKMPoint): Boolean;
    function TileIsWineField(const Loc: TKMPoint): Boolean;
    function TileIsWalkableRoad(const Loc: TKMPoint): Boolean;
    function TileIsLocked(const aLoc: TKMPoint): Boolean;
    function TileIsGoodToCutTree(const aLoc: TKMPoint): Boolean;

    function TileHasStone(X, Y: Word): Boolean; inline;
    function TileHasCoal(X, Y: Word): Boolean; inline;
    function TileHasIron(X, Y: Word): Boolean; inline;
    function TileHasGold(X, Y: Word): Boolean; inline;

    function TileHasTerrainKindPart(X, Y: Word; aTerKind: TKMTerrainKind): Boolean; overload;
    function TileHasTerrainKindPart(X, Y: Word; aTerKind: TKMTerrainKind; aDir: TKMDirection): Boolean; overload;
    function TileHasOnlyTerrainKinds(X, Y: Word; const aTerKinds: array of TKMTerrainKind): Boolean;
    function TileHasOnlyTerrainKind(X, Y: Word; const aTerKind: TKMTerrainKind): Boolean;

    function TileTryGetTerKind(X, Y: Word; var aTerKind: TKMTerrainKind): Boolean;

    function TileIsSand(const Loc: TKMPoint): Boolean; inline;
    function TileIsSoil(X,Y: Word): Boolean; overload; inline;
    function TileIsSoil(const Loc: TKMPoint): Boolean; overload; inline;
    function TileIsIce(X, Y: Word): Boolean; inline;
    function TileHasWater(X, Y: Word): Boolean; inline;
    function VerticeIsFactorable(const Loc: TKMPoint): Boolean;
    function TileIsWalkable(const Loc: TKMPoint): Boolean; inline;
    function TileIsRoadable(const Loc: TKMPoint): Boolean; inline;

    function TileCornerTerrain(aX, aY: Integer; aCorner: Byte): Word;
    function TileCornersTerrains(aX, aY: Integer): TKMWordArray;
    function TileCornerTerKind(aX, aY: Integer; aCorner: Byte): TKMTerrainKind;
    procedure GetTileCornersTerKinds(aX, aY: Integer; out aCornerTerKinds: TKMTerrainKindCorners);

    procedure GetVerticeTerKinds(const aLoc: TKMPoint; out aVerticeTerKinds: TKMTerrainKindCorners);

    function TileHasRoad(const Loc: TKMPoint): Boolean; overload; inline;
    function TileHasRoad(X,Y: Integer): Boolean; overload; inline;

    function UnitsHitTest(X, Y: Word): Pointer;
    function UnitsHitTestF(const aLoc: TKMPointF): Pointer;
    function UnitsHitTestWithinRad(const aLoc: TKMPoint; MinRad, MaxRad: Single; aPlayer: TKMHandID; aAlliance: TKMAllianceType;
                                   Dir: TKMDirection; const aClosest: Boolean): Pointer;

    function ScriptTrySetTile(X, Y, aType, aRot: Integer): Boolean;
    function ScriptTrySetTileHeight(X, Y, aHeight: Integer): Boolean;
    function ScriptTrySetTileObject(X, Y, aObject: Integer): Boolean;
    function ScriptTrySetTilesArray(var aTiles: array of TKMTerrainTileBrief; aRevertOnFail: Boolean; var aErrors: TKMTerrainTileChangeErrorArray): Boolean;

    function ObjectIsCorn(const Loc: TKMPoint): Boolean; overload; inline;
    function ObjectIsCorn(X,Y: Word): Boolean; overload; inline;

    function ObjectIsWine(const Loc: TKMPoint): Boolean; overload; inline;
    function ObjectIsWine(X,Y: Word): Boolean; overload; inline;

    function ObjectIsChopableTree(X,Y: Word): Boolean; overload; inline;
    function ObjectIsChopableTree(const Loc: TKMPoint; aStage: TKMChopableAge): Boolean; overload; inline;
    function ObjectIsChopableTree(const Loc: TKMPoint; aStages: TKMChopableAgeSet): Boolean; overload; inline;
    function CanWalkDiagonaly(const aFrom: TKMPoint; bX, bY: SmallInt): Boolean;

    function GetFieldStage(const Loc: TKMPoint): Byte;
    function GetCornStage(const Loc: TKMPoint): Byte;
    function GetWineStage(const Loc: TKMPoint): Byte;

    function TopHill: Byte;
    procedure FlattenTerrain(const Loc: TKMPoint; aUpdateWalkConnects: Boolean = True; aIgnoreCanElevate: Boolean = False); overload;
    procedure FlattenTerrain(LocList: TKMPointList); overload;

    function ConvertCursorToMapCoord(inX,inY:single): Single;
    function FlatToHeight(inX, inY: Single): Single; overload;
    function FlatToHeight(const aPoint: TKMPointF): TKMPointF; overload;
    function RenderFlatToHeight(inX, inY: Single): Single; overload;
    function RenderFlatToHeight(const aPoint: TKMPointF): TKMPointF; overload;
    function HeightAt(inX, inY: Single): Single;
    function RenderHeightAt(inX, inY: Single): Single;

    procedure UpdateLighting; overload;
    procedure UpdateLighting(const aRect: TKMRect); overload;
    procedure UpdateLighting(X, Y: Integer); overload;

    procedure UpdatePassability; overload;
    procedure UpdatePassability(const aRect: TKMRect); overload;
    procedure UpdatePassability(const Loc: TKMPoint); overload;

    procedure UpdateFences(aCheckSurrounding: Boolean = True); overload;
    procedure UpdateFences(const aRect: TKMRect; aCheckSurrounding: Boolean = True); overload;
    procedure UpdateFences(const Loc: TKMPoint; aCheckSurrounding: Boolean = True); overload;

    procedure UpdateAll; overload;
    procedure UpdateAll(const aRect: TKMRect); overload;

    procedure CallOnMainLand(aProc: TProc);

    procedure IncAnimStep; //Lite-weight UpdateState for MapEd
    property AnimStep: Cardinal read fAnimStep;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    procedure UpdateState;

    class procedure WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID; aGameSave: Boolean); overload;
    class procedure WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID; aGameSave: Boolean; var aMapDataSize: Cardinal); overload;
    class procedure ReadTileFromStream(aStream: TKMemoryStream; var aTileBasic: TKMTerrainTileBasic; aGameRev: Integer = 0);
  end;

var
  //Terrain is a globally accessible resource by so many objects
  //In rare cases local terrain is used (e.g. main menu minimap)
  gTerrain: TKMTerrain;


implementation
uses
  KM_Log, KM_HandsCollection, KM_TerrainWalkConnect, KM_Resource, KM_Units, KM_DevPerfLog,
  KM_ResSound, KM_Sound, KM_UnitActionStay, KM_UnitWarrior, KM_TerrainPainter, KM_Houses,
  KM_ResUnits, KM_ResSprites, KM_Hand, KM_Game, KM_GameParams, KM_GameTypes, KM_ScriptingEvents, KM_Utils, KM_DevPerfLogTypes,
  KM_CommonExceptions;


{ TKMTerrain }
constructor TKMTerrain.Create;
begin
  inherited;

  fAnimStep := 0;
  FallingTrees := TKMPointTagList.Create;
  fTileset := gRes.Tileset; //Local shortcut

  fMainLand := @fLand;
  SetMainLand;
end;


destructor TKMTerrain.Destroy;
begin
  FreeAndNil(FallingTrees);
  FreeAndNil(fFinder);

  inherited;
end;


procedure TKMTerrain.SetMainLand;
begin
  if Self = nil then Exit;

  Land := @fLand;
end;


//Reset whole map with default values
procedure TKMTerrain.MakeNewMap(aWidth, aHeight: Integer; aMapEditor: Boolean);
var
  I, K: Integer;
begin
  fMapEditor := aMapEditor;
  fMapX := Min(aWidth,  MAX_MAP_SIZE);
  fMapY := Min(aHeight, MAX_MAP_SIZE);
  fMapRect := KMRect(1, 1, fMapX, fMapY);

  for I := 1 to fMapY do
    for K := 1 to fMapX do
    begin
      with Land^[I, K] do
      begin
        //Apply some random tiles for artisticity
        if KaMRandom(5, 'TKMTerrain.MakeNewMap') = 0 then
          BaseLayer.Terrain := RandomTiling[tkGrass, KaMRandom(RandomTiling[tkGrass, 0], 'TKMTerrain.MakeNewMap 2') + 1]
        else
          BaseLayer.Terrain := 0;
        LayersCnt    := 0;
        BaseLayer.SetAllCorners;
        Height      := HEIGHT_DEFAULT + KaMRandom(HEIGHT_RAND_VALUE, 'TKMTerrain.MakeNewMap 3');  //variation in Height
        BaseLayer.Rotation     := KaMRandom(4, 'TKMTerrain.MakeNewMap 4');  //Make it random
        Obj          := OBJ_NONE;             //none
        IsCustom     := False;
        BlendingLvl  := TERRAIN_DEF_BLENDING_LVL;
        //Uncomment to enable random trees, but we don't want that for the map editor by default
        //if KaMRandom(16)=0 then Obj := ChopableTrees[KaMRandom(13)+1,4];
        TileOverlay  := toNone;
        TileLock     := tlNone;
        JamMeter     := 0;
        Passability  := []; //Gets recalculated later
        TileOwner    := -1;
        IsUnit       := nil;
        IsVertexUnit := vuNone;
        FieldAge     := 0;
        TreeAge      := IfThen(ObjectIsChopableTree(KMPoint(K, I), caAgeFull), TREE_AGE_FULL, 0);
      end;
      Fences[I, K].Kind := fncNone;
      Fences[I, K].Side := 0;
    end;

  fFinder := TKMTerrainFinder.Create;
  UpdateLighting;
  UpdatePassability;

  //Everything except roads
  UpdateWalkConnect([wcWalk, wcFish, wcWork], MapRect, True);
end;


procedure TKMTerrain.LoadFromFile(const FileName: UnicodeString; aMapEditor: Boolean);
var
  I, J, L: Integer;
  S: TKMemoryStream;
  newX, newY: Integer;
  gameRev: Integer;
  tileBasic: TKMTerrainTileBasic;
begin
  fMapX := 0;
  fMapY := 0;

  if not FileExists(FileName) then Exit;

  fMapEditor := aMapEditor;

  gLog.AddTime('Loading map file: ' + FileName);

  S := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFile(FileName);

    LoadMapHeader(S, newX, newY, gameRev);

    fMapX := newX;
    fMapY := newY;

    fMapRect := KMRect(1, 1, fMapX, fMapY);

    for I := 1 to fMapY do
      for J := 1 to fMapX do
      begin
        Land^[I,J].TileLock     := tlNone;
        Land^[I,J].JamMeter     := 0;
        Land^[I,J].Passability  := []; //Gets recalculated later
        Land^[I,J].TileOwner    := PLAYER_NONE;
        Land^[I,J].IsUnit       := nil;
        Land^[I,J].IsVertexUnit := vuNone;
        Land^[I,J].FieldAge     := 0;
        Land^[I,J].TreeAge      := 0;
        Fences[I,J].Kind   := fncNone;
        Fences[I,J].Side   := 0;

        ReadTileFromStream(S, tileBasic, gameRev);

        Land^[I,J].BaseLayer   := tileBasic.BaseLayer;
        Land^[I,J].Height     := tileBasic.Height;
        Land^[I,J].Obj         := tileBasic.Obj;
        Land^[I,J].LayersCnt   := tileBasic.LayersCnt;
        Land^[I,J].IsCustom    := tileBasic.IsCustom;
        Land^[I,J].BlendingLvl := tileBasic.BlendingLvl;
        Land^[I,J].TileOverlay := tileBasic.TileOverlay;

        for L := 0 to tileBasic.LayersCnt - 1 do
          Land^[I,J].Layer[L] := tileBasic.Layer[L];

        if ObjectIsChopableTree(KMPoint(J,I), caAge1) then Land^[I,J].TreeAge := 1;
        if ObjectIsChopableTree(KMPoint(J,I), caAge2) then Land^[I,J].TreeAge := TREE_AGE_1;
        if ObjectIsChopableTree(KMPoint(J,I), caAge3) then Land^[I,J].TreeAge := TREE_AGE_2;
        if ObjectIsChopableTree(KMPoint(J,I), caAgeFull) then Land^[I,J].TreeAge := TREE_AGE_FULL;
        //Everything else is default
      end;
  finally
    S.Free;
  end;

  fFinder := TKMTerrainFinder.Create;
  UpdateLighting;
  UpdatePassability;

  //Everything except roads
  UpdateWalkConnect([wcWalk, wcFish, wcWork], MapRect, True);
  gLog.AddTime('Map file loaded');
end;


procedure TKMTerrain.SaveToFile(const aFile: UnicodeString);
begin
  SaveToFile(aFile, KMRECT_ZERO);
end;

//Save (export) map in KaM .map format with additional tile information on the end?
procedure TKMTerrain.SaveToFile(const aFile: UnicodeString; const aInsetRect: TKMRect);
var
  mapDataSize: Cardinal;
const
  H_RND_HALF = HEIGHT_RAND_VALUE div 2;

  //aDir - direction of enlarge for new generated tile
  procedure SetNewLand(var S: TKMemoryStream; aToX, aToY, aFromX, aFromY: Word;
                       aNewGenTile: Boolean; aDir: TKMDirection = dirNA);
  var
    L, D, adj, hMid: Integer;
    TileBasic: TKMTerrainTileBasic;
    terKind: TKMTerrainKind;
    cornersTerKinds: TKMTerrainKindCorners;
    tileOwner: TKMHandID;
  begin
    tileOwner := PLAYER_NONE;
    // new appended terrain, generate tile then
    if aNewGenTile then
    begin
      //Check if terrainKind is same for all 4 corners
      if not TileTryGetTerKind(aFromX, aFromY, terKind) then
      begin
        GetTileCornersTerKinds(aFromX, aFromY, cornersTerKinds);

        if aDir = dirNA then // that should never happen usually
          terKind := tkGrass
        else
        begin
          D := Ord(aDir);
          if (D mod 2) = 0 then // corner direction
            terKind := CornersTerKinds[(D div 2) mod 4]
          else
          begin
            adj := Random(2); //Choose randomly between 2 corners terkinds
            terKind  := CornersTerKinds[((D div 2) + adj) mod 4];
          end;
        end;
      end;

      //Apply some random tiles for artisticity
      TileBasic.BaseLayer.Terrain  := gGame.TerrainPainter.PickRandomTile(terKind, True);
      TileBasic.BaseLayer.Rotation := Random(4);
      TileBasic.BaseLayer.SetAllCorners;
      //find height mid point to make random elevation even for close to 0 or 100 height
      hMid := Max(0, fLand[aFromY,aFromX].Height - H_RND_HALF) + H_RND_HALF;
      hMid := Min(100, hMid + H_RND_HALF) - H_RND_HALF;
      TileBasic.Height    := EnsureRange(hMid - H_RND_HALF + Random(HEIGHT_RAND_VALUE), 0, 100);
      TileBasic.Obj       := OBJ_NONE; // No object
      TileBasic.IsCustom  := False;
      TileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL;
      TileBasic.LayersCnt := 0;
      TileBasic.TileOverlay := toNone;
    end
    else
    begin
      // Use fLand, to be sure we save actual Land
      TileBasic.BaseLayer   := fLand[aFromY,aFromX].BaseLayer;
      TileBasic.Height      := fLand[aFromY,aFromX].Height;
      TileBasic.Obj         := fLand[aFromY,aFromX].Obj;
      TileBasic.LayersCnt   := fLand[aFromY,aFromX].LayersCnt;
      TileBasic.IsCustom    := fLand[aFromY,aFromX].IsCustom;
      TileBasic.BlendingLvl := fLand[aFromY,aFromX].BlendingLvl;
      TileBasic.TileOverlay := fLand[aFromY,aFromX].TileOverlay;
      for L := 0 to 2 do
        TileBasic.Layer[L] := fLand[aFromY,aFromX].Layer[L];

      tileOwner := fLand[aFromY,aFromX].TileOwner;
    end;
    WriteTileToStream(S, TileBasic, tileOwner, False, mapDataSize);
  end;

  procedure WriteFileHeader(S: TKMemoryStream);
  begin
    S.Write(Integer(0));     //Indicates this map has not standart KaM format, Can use 0, as we can't have maps with 0 width
    S.WriteW(UnicodeString(GAME_REVISION)); //Write KaM version, in case we will change format in future
    S.Write(mapDataSize);
  end;

var
  S: TKMemoryStream;
  //MapInnerRect: TKMRect;
  NewGenTileI, NewGenTileK, extLeft, extRight, extTop, extBot: Boolean;
  I, K, IFrom, KFrom, D: Integer;
  SizeX, SizeY: Integer;
begin
  Assert(fMapEditor, 'Can save terrain to file only in MapEd');
  ForceDirectories(ExtractFilePath(aFile));

  mapDataSize := 0;
  S := TKMemoryStreamBinary.Create;
  WriteFileHeader(S);
  try
    //Dimensions must be stored as 4 byte integers
    SizeX := fMapX + aInsetRect.Left + aInsetRect.Right;
    SizeY := fMapY + aInsetRect.Top + aInsetRect.Bottom;
    S.Write(SizeX);
    S.Write(SizeY);
    //MapInnerRect := KMRect(1 + EnsureRange(aInsetRect.Left, 0, aInsetRect.Left),
    //                       1 + EnsureRange(aInsetRect.Top, 0, aInsetRect.Top),
    //                       EnsureRange(fMapX + aInsetRect.Left, fMapX + aInsetRect.Left, fMapX + aInsetRect.Left + aInsetRect.Right),
    //                       EnsureRange(fMapY + aInsetRect.Top, fMapY + aInsetRect.Top, fMapY + aInsetRect.Top + aInsetRect.Bottom));


    // Check if we need to generate some of the tiles, if we expand terrain land
    for I := 1 to SizeY do
    begin
      IFrom := EnsureRange(I - aInsetRect.Top, 1, fMapY - 1); //-1 because last row is not part of the map

      // Last col/row is saved into the .map file, but its actually not used!
      // So in case we resize map we do not need to use the exact last row/col, but previous one
      // So we will do that means when aInsetRect.Bottom > 0 or aInsetRect.Right > 0
      // And for simple map save (or when we do not enlarge to the right / bottom)
      // there is no need to generate new tile, just save those 'fake/bot used' tiles
      // Prolly we would need to get rid of that last tiles in the future
      NewGenTileI := (IFrom <> I - aInsetRect.Top)
                      and ((I - aInsetRect.Top <> fMapY) or (aInsetRect.Bottom > 0)); //
      extTop := I <= aInsetRect.Top;
      extBot := I - aInsetRect.Top >= fMapY;
      D :=  Ord(dirN)*Byte(extTop) + Ord(dirS)*Byte(extBot); //Only 1 could happen
      for K := 1 to SizeX do
      begin
        KFrom := EnsureRange(K - aInsetRect.Left, 1, fMapX - 1); //-1 because last col is not part of the map
        NewGenTileK := (KFrom <> K - aInsetRect.Left)
                        and ((K - aInsetRect.Left <> fMapX) or (aInsetRect.Right > 0)); //
        extLeft := K <= aInsetRect.Left;
        extRight := K - aInsetRect.Left >= fMapX;

        if D = 0 then
          D := Ord(dirW)*Byte(extLeft) + Ord(dirE)*Byte(extRight) //Only 1 could happen
        else
        begin
          D := D + (Byte(extBot)*2 - 1)*Byte(extLeft) + (Byte(extTop)*2 - 1)*Byte(extRight); //step left or right
          D := ((D - 1 + 8) mod 8) + 1; //circle around for 0-value as dirNE
        end;

        SetNewLand(S, K, I, KFrom, IFrom, NewGenTileK or NewGenTileI, TKMDirection(D));
      end;
    end;

    //Update header info with MapDataSize
    S.Seek(0, soFromBeginning);
    WriteFileHeader(S);

    S.SaveToFile(aFile);
  finally
    S.Free;
  end;
end;


function TKMTerrain.TrySetTileHeight(X, Y: Integer; aHeight: Byte; aUpdatePassability: Boolean = True): Boolean;

  function UnitWillGetStuck(CheckX, CheckY: Integer): Boolean;
  var
    U: TKMUnit;
  begin
    U := Land^[CheckY, CheckX].IsUnit;
    if (U = nil) or U.IsDeadOrDying
    or (gRes.Units[U.UnitType].DesiredPassability = tpFish) then //Fish don't care about elevation
      Result := False
    else
      Result := not CheckHeightPass(KMPoint(CheckX, CheckY), hpWalking); //All other units/animals need Walkable
  end;

var
  oldHeight: Byte;
  I, K: Integer;
begin
  //To use CheckHeightPass we must apply change then roll it back if it failed
  oldHeight := aHeight;
  //Apply change
  Land^[Y, X].Height := aHeight;

  //Don't check canElevate: If scripter wants to block mines that's his choice

  //Elevation affects all 4 tiles around the vertex
  for I := -1 to 0 do
    for K := -1 to 0 do
      if TileInMapCoords(X+K, Y+I) then
        //Did this change make a unit stuck?
        if UnitWillGetStuck(X+K, Y+I)
        //Did this change elevate a house?
        or (Land^[Y+I, X+K].TileLock = tlHouse) then
        begin
          //Rollback change
          Land^[Y, X].Height := oldHeight;
          Exit(False);
        end;

  //Accept change
  if aUpdatePassability then
  begin
    UpdateLighting(KMRectGrow(KMRect(X, Y, X, Y), 2));
    UpdatePassability(KMRectGrowTopLeft(KMRect(X, Y, X, Y)));
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(X, Y, X, Y)), False);
  end;
  Result := True;
end;


function TKMTerrain.TrySetTile(X, Y: Integer; aType, aRot: Integer; aUpdatePassability: Boolean = True): Boolean;
var
  tempRect: TKMRect;
  tempBool: Boolean;
begin
  Result := TrySetTile(X, Y, aType, aRot, tempRect, tempBool, aUpdatePassability);
end;


function TKMTerrain.TrySetTile(X, Y: Integer; aType, aRot: Integer; out aPassRect: TKMRect;
                               out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean;
  function UnitWillGetStuck: Boolean;
  var
    U: TKMUnit;
  begin
    U := Land^[Y, X].IsUnit;
    if (U = nil) or U.IsDeadOrDying then
      Result := False
    else
      if gRes.Units[U.UnitType].DesiredPassability = tpFish then
        Result := not fTileset.TileIsWater(aType) //Fish need water
      else
        Result := not fTileset.TileIsWalkable(aType); //All other animals need Walkable
  end;
var
  loc: TKMPoint;
  locRect: TKMRect;
  doRemField: Boolean;
begin
  Assert((aType <> -1) or (aRot <> -1), 'Either terrain type or rotation should be set');

  // Do not allow to set some special terrain tiles
  if (aType <> -1) // We could have aType = -1 if only specify rotation
    and not gRes.Tileset.TileIsAllowedToSet(aType) then
    Exit(False);
 
  loc := KMPoint(X, Y);
  locRect := KMRect(loc);
  aPassRect := locRect;
  
  //First see if this change is allowed
  //Will this change make a unit stuck?
  if UnitWillGetStuck
    //Will this change block a construction site?
    or ((Land^[Y, X].TileLock in [tlFenced, tlDigged, tlHouse])
      and (not fTileSet.TileIsRoadable(aType) or not fTileset.TileIsWalkable(aType))) then
    Exit(False);

  aDiagonalChanged := False;

  // Remove field only if we will change tile type
  // and aType is a new one
  doRemField := (aType <> -1)
    and (TileIsCornField(loc) or TileIsWineField(loc));
  if doRemField then
    RemField(loc, False, False, aPassRect, aDiagonalChanged, False);

  //Apply change
  if aType <> -1 then // Do not update terrain, if -1 is passed as an aType parameter
    Land^[Y, X].BaseLayer.Terrain := aType;
  if aRot <> -1 then // Do not update rotation, if -1 is passed as an aRot parameter
    Land^[Y, X].BaseLayer.Rotation := aRot;
 

  if doRemField then
    UpdateFences(loc); // after update Terrain

  if aUpdatePassability then
  begin
    UpdatePassability(aPassRect);
    UpdateWalkConnect([wcWalk, wcRoad, wcFish, wcWork], aPassRect, aDiagonalChanged);
  end;

  Result := True;
end;


function TKMTerrain.TrySetTileObject(X, Y: Integer; aObject: Word; aUpdatePassability: Boolean = True): Boolean;
var
  diagonalChanged: Boolean;
begin
  Result := TrySetTileObject(X, Y, aObject, diagonalChanged, aUpdatePassability);
end;


function TKMTerrain.TrySetTileObject(X, Y: Integer; aObject: Word; out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean;
  function HousesNearObject: Boolean;
  var
    I, K: Integer;
  begin
    Result := False;
    //If the object blocks diagonals, houses can't be at -1 either
    for I := -1 * Byte(gMapElements[aObject].DiagonalBlocked) to 0 do
      for K := -1 * Byte(gMapElements[aObject].DiagonalBlocked) to 0 do
      if TileInMapCoords(X+K, Y+I) then
        //Can't put objects near houses or house sites
        if (Land^[Y+I, X+K].TileLock in [tlFenced, tlDigged, tlHouse]) then
          Exit(True);
  end;

  // We do not want falling trees
  function AllowableObject: Boolean;
  begin
    // Hide falling trees
    // Invisible objects like 254 or 255 can be useful to clear specified tile (since delete object = place object 255)
    Result := (gMapElements[aObject].Stump = -1) or (aObject in [OBJ_INVISIBLE, OBJ_NONE]);
  end;
var
  loc: TKMPoint;
  locRect: TKMRect;
begin
  loc := KMPoint(X,Y);
  aDiagonalChanged := False;

  //There's no need to check conditions for 255 (NO OBJECT)
  if (aObject <> OBJ_NONE) then
  begin
    //Will this change make a unit stuck?
    if ((Land^[Y, X].IsUnit <> nil) and gMapElements[aObject].AllBlocked)
      //Is this object part of a wine/corn field?
      or TileIsWineField(loc) or TileIsCornField(loc)
      //Is there a house/site near this object?
      or HousesNearObject
      //Is this object allowed to be placed?
      or not AllowableObject then
      Exit(False);
  end;

  //Did block diagonal property change? (hence xor) UpdateWalkConnect needs to know
  aDiagonalChanged := gMapElements[Land^[Y,X].Obj].DiagonalBlocked xor gMapElements[aObject].DiagonalBlocked;

  Land^[Y, X].Obj := aObject;
  Result := True;
  //Apply change
  //UpdatePassability and UpdateWalkConnect are called in SetField so that we only use it in trees and other objects
  case aObject of
    88..124,
    126..172: // Trees - 125 is mushroom
              begin
                if ObjectIsChopableTree(loc, caAge1) then Land^[Y,X].TreeAge := 1;
                if ObjectIsChopableTree(loc, caAge2) then Land^[Y,X].TreeAge := TREE_AGE_1;
                if ObjectIsChopableTree(loc, caAge3) then Land^[Y,X].TreeAge := TREE_AGE_2;
                if ObjectIsChopableTree(loc, caAgeFull) then Land^[Y,X].TreeAge := TREE_AGE_FULL;
              end
  end;
  if aUpdatePassability then
  begin
    locRect := KMRect(loc);
    UpdatePassability(locRect); //When using KMRect map bounds are checked by UpdatePassability
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(locRect), aDiagonalChanged);
  end;
end;


// Try to set an array of Tiles from script. Set terrain, rotation, height and object.
// Update Passability, WalkConnect and Lighting only once at the end.
// This is much faster, then set tile by tile with updates on every change
//
// Returns True if succeeded
// use var for aTiles. aTiles can be huge so we do want to make its local copy. Saves a lot of memory
function TKMTerrain.ScriptTrySetTilesArray(var aTiles: array of TKMTerrainTileBrief; aRevertOnFail: Boolean; var aErrors: TKMTerrainTileChangeErrorArray): Boolean;

  procedure UpdateRect(var aRect: TKMRect; X, Y: Integer);
  begin
    if KMSameRect(aRect, KMRECT_INVALID_TILES) then
      aRect := KMRect(X, Y, X, Y)
    else
      KMRectIncludePoint(aRect, X, Y);
  end;

  procedure UpdateRectWRect(var aRect: TKMRect; aRect2: TKMRect);
  begin
    if KMSameRect(aRect, KMRECT_INVALID_TILES) then
      aRect := aRect2
    else 
      KMRectIncludeRect(aRect, aRect2);
  end;

  procedure SetErrorNSetResult(aType: TKMTileChangeType; var aHasErrorOnTile: Boolean; var aErrorType: TKMTileChangeTypeSet; var aResult: Boolean);
  begin
    Include(aErrorType, aType);
    aHasErrorOnTile := True;
    aResult := False;
  end;

  procedure UpdateHeight(aTileBrief: TKMTerrainTileBrief; var aHeightRect: TKMRect; var aHasErrorOnTile: Boolean; var aErrorTypesOnTile: TKMTileChangeTypeSet);
  begin
    // Update height if needed
    if aTileBrief.UpdateHeight then
    begin
      if InRange(aTileBrief.Height, 0, 100) then
      begin
        if TrySetTileHeight(aTileBrief.X, aTileBrief.Y, aTileBrief.Height, False) then
          UpdateRect(aHeightRect, aTileBrief.X, aTileBrief.Y)
        else
          SetErrorNSetResult(tctHeight, aHasErrorOnTile, aErrorTypesOnTile, Result);
      end else
        SetErrorNSetResult(tctHeight, aHasErrorOnTile, aErrorTypesOnTile, Result);
    end;
  end;

var 
  I, J, terr, rot: Integer;
  T: TKMTerrainTileBrief;
  rect, terrRect, heightRect: TKMRect;
  diagonalChangedTotal, diagChanged: Boolean;
  backupLand: array of array of TKMTerrainTile;
  errCnt: Integer;
  hasErrorOnTile: Boolean;
  errorTypesOnTile: TKMTileChangeTypeSet;
begin
  Result := True;
  if Length(aTiles) = 0 then Exit;

  //Initialization
  diagonalChangedTotal := False;
  rect := KMRECT_INVALID_TILES;
  // Use separate HeightRect, because UpdateLight invoked only when Height is changed
  heightRect := KMRECT_INVALID_TILES;
  errCnt := 0;

  // make backup copy of Land only if we may need revert changes
  if aRevertOnFail then
  begin
    SetLength(backupLand, fMapY, fMapX);
    for I := 1 to fMapY do
      for J := 1 to fMapX do
        backupLand[I-1][J-1] := Land^[I, J];
  end;

  for I := 0 to High(aTiles) do
  begin
    T := aTiles[I];

    hasErrorOnTile := False;
    errorTypesOnTile := [];

    if TileInMapCoords(T.X, T.Y) then
    begin
      terr := -1;
      if T.UpdateTerrain then
        terr := T.Terrain;
        
      rot := -1;
      if T.UpdateRotation and InRange(T.Rotation, 0, 3) then
        rot := T.Rotation;

      if T.UpdateTerrain or T.UpdateRotation then
      begin
        if (terr <> -1) or (rot <> -1) then
        begin
          // Update terrain and rotation if needed
          if TrySetTile(T.X, T.Y, terr, rot, terrRect, diagChanged, False) then
          begin
            diagonalChangedTotal := diagonalChangedTotal or diagChanged;
            UpdateRectWRect(rect, terrRect);
          end else begin
            SetErrorNSetResult(tctTerrain, hasErrorOnTile, errorTypesOnTile, Result);
            SetErrorNSetResult(tctRotation, hasErrorOnTile, errorTypesOnTile, Result);
          end;
        end else begin
          SetErrorNSetResult(tctTerrain, hasErrorOnTile, errorTypesOnTile, Result);
          SetErrorNSetResult(tctRotation, hasErrorOnTile, errorTypesOnTile, Result);
        end;
      end;

      // Update height if needed
      UpdateHeight(T, heightRect, hasErrorOnTile, errorTypesOnTile);

      //Update object if needed
      if T.UpdateObject then
      begin
        if TrySetTileObject(T.X, T.Y, T.Obj, diagChanged, False) then
        begin
          UpdateRect(rect, T.X, T.Y);
          diagonalChangedTotal := diagonalChangedTotal or diagChanged;
        end else
          SetErrorNSetResult(tctObject, hasErrorOnTile, errorTypesOnTile, Result);
      end;
    end
    else
    if VerticeInMapCoords(T.X, T.Y) then
      // Update height if needed
      UpdateHeight(T, heightRect, hasErrorOnTile, errorTypesOnTile)
    else
    begin
      hasErrorOnTile := True;
      //When tile is out of map coordinates we treat it as all operations failure
      if T.UpdateTerrain then
        Include(errorTypesOnTile, tctTerrain);
      if T.UpdateHeight then
        Include(errorTypesOnTile, tctHeight);
      if T.UpdateObject then
        Include(errorTypesOnTile, tctObject);
    end;

    // Save error info, if there was some error
    if hasErrorOnTile then
    begin
      if Length(aErrors) = errCnt then
        SetLength(aErrors, errCnt + 16);
      aErrors[errCnt].X := T.X;
      aErrors[errCnt].Y := T.Y;
      aErrors[errCnt].ErrorsIn := errorTypesOnTile;
      Inc(errCnt);
    end;

    if not Result and aRevertOnFail then
      Break;
  end;

  if not Result and aRevertOnFail then
  begin
    //Restore backup Land, when revert needed
    for I := 1 to fMapY do
      for J := 1 to fMapX do
        Land^[I, J] := backupLand[I-1][J-1];
    SetLength(backupLand, 0); // Release dynamic array memory. This array can be huge, so we should clear it as fast as possible
  end
  else
  begin
    // Actualize terrain for map editor (brushes have array which helps them make smooth transitions)
    if (gGameParams.Mode = gmMapEd) then
      for I := 1 to fMapY do
        for J := 1 to fMapX do
          gGame.TerrainPainter.RMG2MapEditor(J,I, Land^[I, J].BaseLayer.Terrain);

    if not KMSameRect(heightRect, KMRECT_INVALID_TILES) then
      gTerrain.UpdateLighting(KMRectGrow(heightRect, 2)); // Update Light only when height was changed

    gTerrain.UpdatePassability(KMRectGrowTopLeft(rect));
    gTerrain.UpdateWalkConnect([wcWalk, wcRoad, wcFish, wcWork], KMRectGrowTopLeft(rect), diagonalChangedTotal);
  end;

  //Cut errors array to actual size
  if Length(aErrors) <> errCnt then
    SetLength(aErrors, errCnt);
end;


// Try to set an tile (Terrain and Rotation) from the script. Failure is an option
function TKMTerrain.ScriptTrySetTile(X, Y, aType, aRot: Integer): Boolean;
begin
  Result := TileInMapCoords(X, Y) and TrySetTile(X, Y, aType, aRot);
end;


// Try to set an tile Height from the script. Failure is an option
function TKMTerrain.ScriptTrySetTileHeight(X, Y, aHeight: Integer): Boolean;
begin
  Result := TileInMapCoords(X, Y) and TrySetTileHeight(X, Y, aHeight);
end;


// Try to set an object from the script. Failure is an option
function TKMTerrain.ScriptTrySetTileObject(X, Y, aObject: Integer): Boolean;
begin
  Result := TileInMapCoords(X, Y) and TrySetTileObject(X, Y, aObject);
end;


{Check if requested tile (X,Y) is within Map boundaries}
{X,Y are unsigned int, usually called from loops, hence no TKMPoint can be used}
function TKMTerrain.TileInMapCoords(X,Y: Integer; Inset: Byte = 0): Boolean;
begin
  Result := InRange(X, 1 + Inset, fMapX - 1 - Inset) and InRange(Y, 1 + Inset, fMapY - 1 - Inset);
end;


function TKMTerrain.CoordsWithinMap(X, Y: Single; aInset: Byte = 0): Boolean;
begin
  Result :=     (X >= 1 + aInset)
            and (X <= fMapX - 1 - aInset)
            and (Y >= 1 + aInset)
            and (Y <= fMapY - 1 - aInset)
end;


function TKMTerrain.PointFInMapCoords(const aPointF: TKMPointF; aInset: Byte = 0): Boolean;
begin
  Result := CoordsWithinMap(aPointF.X, aPointF.Y, aInset);
end;


function TKMTerrain.TileInMapCoords(const aCell: TKMPoint; Inset: Byte = 0): Boolean;
begin
  Result := TileInMapCoords(aCell.X, aCell.Y, Inset);
end;


function TKMTerrain.TileInMapCoords(X,Y: Integer; InsetRect: TKMRect): Boolean;
begin
  Result :=     InRange(X, 1 + InsetRect.Left, fMapX - 1 + InsetRect.Right)
            and InRange(Y, 1 + InsetRect.Top,  fMapY - 1 + InsetRect.Bottom);
end;


{Check if requested vertice is within Map boundaries}
{X,Y are unsigned int, usually called from loops, hence no TKMPoint can be used}
function TKMTerrain.VerticeInMapCoords(X,Y: Integer; Inset: Byte = 0): Boolean;
begin
  Result := InRange(X, 1 + Inset, fMapX - Inset) and InRange(Y, 1 + Inset, fMapY - Inset);
end;


function TKMTerrain.VerticeInMapCoords(const aCell: TKMPoint; Inset: Byte = 0): Boolean;
begin
  Result := VerticeInMapCoords(aCell.X, aCell.Y, Inset);
end;


{Ensure that requested tile is within Map boundaries}
{X,Y are unsigned int, usually called from loops, hence no TKMPoint can be used}
function TKMTerrain.EnsureTileInMapCoords(X,Y: Integer; aInset: Byte = 0): TKMPoint;
begin
  Result.X := EnsureRange(X, 1 + aInset, fMapX - 1 - aInset);
  Result.Y := EnsureRange(Y, 1 + aInset, fMapY - 1 - aInset);
end;


procedure TKMTerrain.EnsureCoordsWithinMap(var X, Y: Single; aInset: Byte = 0);
begin
  X := EnsureRange(X, 1 + aInset, fMapX - 1 - aInset);
  Y := EnsureRange(Y, 1 + aInset, fMapY - 1 - aInset);
end;


function TKMTerrain.EnsureTilesRectWithinMap(const aRectF: TKMRectF; aInset: Single = 0): TKMRectF;
begin
  Result.Left   := EnsureRangeF(aRectF.Left,   1 + aInset, fMapX - 1 - aInset);
  Result.Right  := EnsureRangeF(aRectF.Right,  1 + aInset, fMapX - 1 - aInset);
  Result.Top    := EnsureRangeF(aRectF.Top,    1 + aInset, fMapY - 1 - aInset);
  Result.Bottom := EnsureRangeF(aRectF.Bottom, 1 + aInset, fMapY - 1 - aInset);
end;


function TKMTerrain.EnsureVerticesRectWithinMap(const aRectF: TKMRectF; aInset: Single = 0): TKMRectF;
begin
  Result.Left   := EnsureRangeF(aRectF.Left,   aInset, fMapX - aInset);
  Result.Right  := EnsureRangeF(aRectF.Right,  aInset, fMapX - aInset);
  Result.Top    := EnsureRangeF(aRectF.Top,    aInset, fMapY - aInset);
  Result.Bottom := EnsureRangeF(aRectF.Bottom, aInset, fMapY - aInset);
end;


function TKMTerrain.EnsureTileInMapCoords(const aLoc: TKMPoint; aInset: Byte = 0): TKMPoint;
begin
  Result := EnsureTileInMapCoords(aLoc.X, aLoc.Y, aInset);
end;


function TKMTerrain.TileGoodForIronMine(X,Y: Word): Boolean;
var
  cornersTKinds: TKMTerrainKindCorners;
begin
  Result :=
    (fTileset.TileIsGoodForIronMine(Land^[Y,X].BaseLayer.Terrain)
      and (Land^[Y,X].BaseLayer.Rotation mod 4 = 0)); //only horizontal mountain edges allowed
  if not Result then
  begin
    GetTileCornersTerKinds(X, Y, cornersTKinds);
    Result :=
          (cornersTKinds[0] in [tkIron, tkIronMount])
      and (cornersTKinds[1] in [tkIron, tkIronMount])
      and fTileset.TileIsRoadable(BASE_TERRAIN[cornersTKinds[2]])
      and fTileset.TileIsRoadable(BASE_TERRAIN[cornersTKinds[3]]);
  end;
end;


function TKMTerrain.CanPlaceIronMine(X,Y: Word): Boolean;
begin
  Result := TileGoodForIronMine(X,Y)
    and ((Land[Y,X].Obj = OBJ_NONE) or (gMapElements[Land^[Y,X].Obj].CanBeRemoved))
    and TileInMapCoords(X,Y, 1)
    and not HousesNearTile(X,Y)
    and (Land^[Y,X].TileLock = tlNone)
    and CheckHeightPass(KMPoint(X,Y), hpBuildingMines);
end;


function TKMTerrain.TileGoodForGoldMine(X,Y: Word): Boolean;
var
  cornersTKinds: TKMTerrainKindCorners;
begin
  Result :=
    (fTileset.TileIsGoodForGoldMine(Land^[Y,X].BaseLayer.Terrain)
      and (Land^[Y,X].BaseLayer.Rotation mod 4 = 0)); //only horizontal mountain edges allowed
  if not Result then
  begin
    GetTileCornersTerKinds(X, Y, cornersTKinds);
    Result :=
          (cornersTKinds[0] in [tkGold, tkGoldMount])
      and (cornersTKinds[1] in [tkGold, tkGoldMount])
      and fTileset.TileIsRoadable(BASE_TERRAIN[cornersTKinds[2]])
      and fTileset.TileIsRoadable(BASE_TERRAIN[cornersTKinds[3]]);
  end;
end;


function TKMTerrain.TileGoodForField(X,Y: Word): Boolean;
begin
  Result := TileIsSoil(X,Y)
    and not gMapElements[Land^[Y,X].Obj].AllBlocked
    and (Land^[Y,X].TileLock = tlNone)
    and not (Land^[Y,X].TileOverlay in ROAD_LIKE_OVERLAYS)
    and not TileIsWineField(KMPoint(X,Y))
    and not TileIsCornField(KMPoint(X,Y))
    and CheckHeightPass(KMPoint(X,Y), hpWalking);
end;


function TKMTerrain.TileGoodToPlantTree(X,Y: Word): Boolean;
  function IsObjectsNearby: Boolean;
  var
    I,K: Integer;
    P: TKMPoint;
  begin
    Result := False;
    for I := -1 to 1 do
      for K := -1 to 1 do
        if ((I<>0) or (K<>0)) and TileInMapCoords(X+I, Y+K) then
        begin
          P := KMPoint(X+I, Y+K);

          //Tiles next to it can't be trees/stumps
          if gMapElements[Land^[P.Y,P.X].Obj].DontPlantNear then
            Result := True;

          //Tiles above or to the left can't be road/field/locked
          if (I <= 0) and (K <= 0) then
            if (Land^[P.Y,P.X].TileLock <> tlNone)
            or (Land^[P.Y,P.X].TileOverlay in ROAD_LIKE_OVERLAYS)
            or TileIsCornField(P)
            or TileIsWineField(P) then
              Result := True;

          if Result then Exit;
        end;
  end;

  function HousesNearVertex: Boolean;
  var
    I,K: Integer;
  begin
    Result := False;
    for I := -1 to 1 do
    for K := -1 to 1 do
      if TileInMapCoords(X+K, Y+I)
      and (Land^[Y+I,X+K].TileLock in [tlFenced,tlDigged,tlHouse]) then
      begin
        if (I+1 in [0,1]) and (K+1 in [0,1]) then //Only houses above/left of the tile
          Result := True;
      end;
  end;

  // Do not allow to plant tree on vertex with NW-SE only passable tiles around
  // It could trap woodcutter if he came from top-left tile or close some narrow path between areas
  function Is_NW_SE_OnlyVertex: Boolean;
  begin
    Result :=       CheckPassability(X    , Y    , tpWalk)  // O | X   // O - walkable (OK)
            and     CheckPassability(X - 1, Y - 1, tpWalk)  // --T--   // X - not walkable
            and not CheckPassability(X    , Y - 1, tpWalk)  // X | W   // T - Tree to plant
            and not CheckPassability(X - 1, Y    , tpWalk); //         // W - woodcutter
  end;

begin
  //todo: Optimize above functions. Recheck UpdatePass and WC if the check Rects can be made smaller

  Result := TileIsSoil(X,Y)
    and not IsObjectsNearby //This function checks surrounding tiles
    and (Land^[Y,X].TileLock = tlNone)
    and (X > 1) and (Y > 1) //Not top/left of map, but bottom/right is ok
    and not (Land^[Y,X].TileOverlay in ROAD_LIKE_OVERLAYS)
    and not HousesNearVertex
    and not Is_NW_SE_OnlyVertex
    //Woodcutter will dig out other object in favour of his tree
    and ((Land[Y,X].Obj = OBJ_NONE) or (gMapElements[Land^[Y,X].Obj].CanBeRemoved))
    and CheckHeightPass(KMPoint(X,Y), hpWalking)
    and (FindBestTreeType(KMPoint(X,Y)) <> ttNone); // We could plant some tree type
end;


//Check if requested tile is water suitable for fish and/or sail. No waterfalls, but swamps/shallow water allowed
function TKMTerrain.TileIsWater(const Loc: TKMPoint): Boolean;
begin
  Result := TileIsWater(Loc.X, Loc.Y);
end;


function TKMTerrain.TileIsWater(X,Y : Word): Boolean;
begin
  Result := TileHasParameter(X, Y, fTileset.TileIsWater);
end;


//Check if requested tile is sand suitable for crabs
function TKMTerrain.TileIsSand(const Loc: TKMPoint): Boolean;
begin
  Result := TileHasParameter(Loc.X, Loc.Y, fTileset.TileIsSand);
end;


function TKMTerrain.TileIsSnow(X, Y: Word): Boolean;
begin
  Result := TileHasParameter(X, Y, fTileset.TileIsSnow);
end;


//Check if requested tile is Stone and returns Stone deposit
function TKMTerrain.TileIsStone(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].HasNoLayers, fTileset.TileIsStone(Land^[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileIsCoal(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].HasNoLayers, fTileset.TileIsCoal(Land^[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileIsIron(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].HasNoLayers, fTileset.TileIsIron(Land^[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileIsGold(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].HasNoLayers, fTileset.TileIsGold(Land^[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileHasStone(X, Y: Word): Boolean;
begin
  Result := TileIsStone(X, Y) > 0;
end;


function TKMTerrain.TileHasCoal(X, Y: Word): Boolean;
begin
  Result := TileIsCoal(X, Y) > 0;
end;


function TKMTerrain.TileHasIron(X, Y: Word): Boolean;
begin
  Result := TileIsIron(X, Y) > 0;
end;


function TKMTerrain.TileHasGold(X, Y: Word): Boolean;
begin
  Result := TileIsGold(X, Y) > 0;
end;


function TKMTerrain.TileHasTerrainKindPart(X, Y: Word; aTerKind: TKMTerrainKind): Boolean;
var
  K: Integer;
  cornersTerKinds: TKMTerrainKindCorners;
begin
  Result := False;
  GetTileCornersTerKinds(X, Y, cornersTerKinds);
  for K := 0 to 3 do
    if cornersTerKinds[K] = aTerKind then
    begin
      Result := True;
      Exit;
    end;
end;


function TKMTerrain.TileHasTerrainKindPart(X, Y: Word; aTerKind: TKMTerrainKind; aDir: TKMDirection): Boolean;
var
  cornersTKinds: TKMTerrainKindCorners;
begin
  Result := False;
  GetTileCornersTerKinds(X, Y, cornersTKinds);

  case aDir of
    dirNA:  Result := TileHasStone(X, Y);
    dirN:   Result := (cornersTKinds[0] = aTerKind) and (cornersTKinds[1] = aTerKind);
    dirNE:  Result := (cornersTKinds[1] = aTerKind);
    dirE:   Result := (cornersTKinds[1] = aTerKind) and (cornersTKinds[2] = aTerKind);
    dirSE:  Result := (cornersTKinds[2] = aTerKind);
    dirS:   Result := (cornersTKinds[2] = aTerKind) and (cornersTKinds[3] = aTerKind);
    dirSW:  Result := (cornersTKinds[3] = aTerKind);
    dirW:   Result := (cornersTKinds[3] = aTerKind) and (cornersTKinds[0] = aTerKind);
    dirNW:  Result := (cornersTKinds[0] = aTerKind);
  end;
end;


function TerKindArrayContains(aElement: TKMTerrainKind; const aArray: array of TKMTerrainKind): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(aArray) to High(aArray) do
    if aElement = aArray[I] then
      Exit (True);
end;


function TKMTerrain.TileHasOnlyTerrainKinds(X, Y: Word; const aTerKinds: array of TKMTerrainKind): Boolean;
var
  I: Integer;
  cornersTerKinds: TKMTerrainKindCorners;
begin
  Result := True;
  GetTileCornersTerKinds(X, Y, cornersTerKinds);
  for I := 0 to 3 do
    if not TerKindArrayContains(cornersTerKinds[I], aTerKinds) then
      Exit(False);
end;


function TKMTerrain.TileHasOnlyTerrainKind(X, Y: Word; const aTerKind: TKMTerrainKind): Boolean;
var
  I: Integer;
  cornersTerKinds: TKMTerrainKindCorners;
begin
  Result := True;
  GetTileCornersTerKinds(X, Y, cornersTerKinds);
  for I := 0 to 3 do
    if cornersTerKinds[I] <> aTerKind then
      Exit(False);
end;


//Try get the only terkind that this tile represents
function TKMTerrain.TileTryGetTerKind(X, Y: Word; var aTerKind: TKMTerrainKind): Boolean;
var
  I: Integer;
  cornersTerKinds: TKMTerrainKindCorners;
begin
  Result := True;
  GetTileCornersTerKinds(X, Y, cornersTerKinds);
  aTerKind := cornersTerKinds[0];
  for I := 1 to 3 do
    if cornersTerKinds[I] <> aTerKind then
    begin
      aTerKind := tkCustom;
      Exit(False); // Corners has different terKinds, return tkCustom then
    end;
end;


//Check if requested tile is soil suitable for fields and trees
function TKMTerrain.TileIsSoil(X,Y: Word): Boolean;
begin
  Result := TileHasParameter(X, Y, fTileset.TileIsSoil);
end;


function TKMTerrain.TileIsSoil(const Loc: TKMPoint): Boolean;
begin
  Result := TileIsSoil(Loc.X, Loc.Y);
end;


function TKMTerrain.TileIsIce(X, Y: Word): Boolean;
begin
  Result := TileHasParameter(X, Y, fTileset.TileIsIce);
end;


function TKMTerrain.TileHasWater(X, Y: Word): Boolean;
begin
  Result := fTileset.TileHasWater(Land^[Y,X].BaseLayer.Terrain);
end;


function TKMTerrain.TileHasParameter(X,Y: Word; aCheckTileFunc: TBooleanWordFunc; aAllow2CornerTiles: Boolean = False;
                                     aStrictCheck: Boolean = False): Boolean;
const
  PROHIBIT_TERKINDS: array[0..1] of TKMTerrainKind = (tkLava, tkAbyss);
  //Strict check (for roadable)
  STRICT_TERKINDS: array[0..4] of TKMTerrainKind = (tkGrassyWater, tkSwamp, tkIce, tkWater, tkFastWater);
var
  I, K, Cnt: Integer;
  corners: TKMTerrainKindCorners;
begin
  Result := False;

  if not TileInMapCoords(X, Y) then Exit;

  if Land^[Y,X].HasNoLayers then
    Result := aCheckTileFunc(Land^[Y, X].BaseLayer.Terrain)
  else
  begin
    Cnt := 0;
    GetTileCornersTerKinds(X, Y, corners);
    for K := 0 to 3 do
    begin
      for I := 0 to High(PROHIBIT_TERKINDS) do
        if corners[K] = PROHIBIT_TERKINDS[I] then
          Exit(False);

      if aStrictCheck then
        for I := 0 to High(STRICT_TERKINDS) do
          if corners[K] = STRICT_TERKINDS[I] then
            Exit(False);

      if aCheckTileFunc(BASE_TERRAIN[corners[K]]) then
        Inc(Cnt);
    end;

    //Consider tile has parameter if it has 3 corners with that parameter or if it has 2 corners and base layer has the parameter
    Result := (Cnt >= 3) or (aAllow2CornerTiles and (Cnt = 2) and aCheckTileFunc(Land^[Y, X].BaseLayer.Terrain));
  end;
end;


//Check if requested tile is generally walkable
function TKMTerrain.TileIsWalkable(const Loc: TKMPoint): Boolean;
//var
//  L: Integer;
//  Ter: Word;
//  TerInfo: TKMGenTerrainInfo;
begin
  Result := TileHasParameter(Loc.X, Loc.Y, fTileset.TileIsWalkable, True);
//  Result := fTileset.TileIsWalkable(Land^[Loc.Y, Loc.X].BaseLayer.Terrain);
//  for L := 0 to Land^[Loc.Y, Loc.X].LayersCnt - 1 do
//  begin
//    if not Result then Exit;
//
//    Ter := Land^[Loc.Y, Loc.X].Layer[L].Terrain;
//    TerInfo := gRes.Sprites.GetGenTerrainInfo(Ter);
//    // Check if this layer walkable
//    // It could be, if its mask does not restrict walkability or its BASE terrain is walkable
//    Result := Result
//                and ((TILE_MASKS_PASS_RESTRICTIONS[TerInfo.Mask.MType,TerInfo.Mask.SubType,0] = 0)
//                  or fTileset.TileIsWalkable(BASE_TERRAIN[TerInfo.TerKind]));
//
//  end;
end;


//Check if requested tile is generally suitable for road building
function TKMTerrain.TileIsRoadable(const Loc: TKMPoint): Boolean;
//var
//  L: Integer;
//  Ter: Word;
//  TerInfo: TKMGenTerrainInfo;
begin
  Result := TileHasParameter(Loc.X, Loc.Y, fTileset.TileIsRoadable, False, True);
//  Result := fTileset.TileIsRoadable(Land^[Loc.Y, Loc.X].BaseLayer.Terrain);
//  for L := 0 to Land^[Loc.Y, Loc.X].LayersCnt - 1 do
//  begin
//    if not Result then Exit;
//
//    Ter := Land^[Loc.Y, Loc.X].Layer[L].Terrain;
//    TerInfo := gRes.Sprites.GetGenTerrainInfo(Ter);
//    // Check if this layer walkable
//    // It could be, if its mask does not restrict walkability or its BASE terrain is walkable
//    Result := Result
//                and ((TILE_MASKS_PASS_RESTRICTIONS[TerInfo.Mask.MType,TerInfo.Mask.SubType,1] = 0)
//                  or fTileset.TileIsRoadable(BASE_TERRAIN[TerInfo.TerKind]));
//
//  end;
end;


//Check if Tile has road overlay
function TKMTerrain.TileHasRoad(const Loc: TKMPoint): Boolean;
begin
  Result := TileHasRoad(Loc.X,Loc.Y);
end;


function TKMTerrain.TileHasRoad(X,Y: Integer): Boolean;
begin
  Result := TileInMapCoords(X, Y) and (Land^[Y, X].TileOverlay = toRoad);
end;


//Check if the tile is a corn field
function TKMTerrain.TileIsCornField(const Loc: TKMPoint): Boolean;
begin
  Result := False;
  if not TileInMapCoords(Loc.X,Loc.Y) then
    Exit;
  //Tile can't be used as a field if there is road or any other overlay
  if not fMapEditor then
    Result := fTileset.TileIsCornField(Land^[Loc.Y, Loc.X].BaseLayer.Terrain)
              and (Land^[Loc.Y,Loc.X].TileOverlay = toNone)
  else
    Result := (gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWine = 1) and (Land^[Loc.Y,Loc.X].TileOverlay = toNone);
end;


//Check if the tile is a wine field
function TKMTerrain.TileIsWineField(const Loc: TKMPoint): Boolean;
begin
  Result := False;
  if not TileInMapCoords(Loc.X,Loc.Y) then 
    Exit;
  //Tile can't be used as a winefield if there is road or any other overlay
  //It also must have right object on it
  if not fMapEditor then
    Result := fTileset.TileIsWineField(Land^[Loc.Y, Loc.X].BaseLayer.Terrain)
              and (Land^[Loc.Y,Loc.X].TileOverlay = toNone)
              and ObjectIsWine(Loc)
  else
    Result := (gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWine = 2) and (Land^[Loc.Y,Loc.X].TileOverlay = toNone);
end;


//Check if the tile is a walkable road
function TKMTerrain.TileIsWalkableRoad(const Loc: TKMPoint): Boolean;
begin
  Result := False;
  if not TileInMapCoords(Loc.X,Loc.Y) then
    Exit;
  // Is map editor OK with this?
  Result := (tpWalkRoad in Land^[Loc.Y,Loc.X].Passability);
end;   


function TKMTerrain.VerticeIsFactorable(const Loc: TKMPoint): Boolean;
const
  //Non factorable terkinds
  NON_FACT_TER_KINDS: set of TKMTerrainKind = [tkIron, tkIronMount, tkGold, tkGoldMount, tkLava, tkAbyss, tkCustom];

var
  I: Integer;
  verticeTKinds: TKMTerrainKindCorners;
begin
  if   not TileInMapCoords(Loc.X,     Loc.Y)
    or not TileInMapCoords(Loc.X - 1, Loc.Y)
    or not TileInMapCoords(Loc.X,     Loc.Y - 1)
    or not TileInMapCoords(Loc.X - 1, Loc.Y - 1) then Exit(False);

  Result := True;

  GetVerticeTerKinds(Loc, verticeTKinds);

  for I := 0 to 3 do
    if verticeTKinds[I] in NON_FACT_TER_KINDS then
      Exit(False);
end;


function TKMTerrain.TileIsGoodToCutTree(const aLoc: TKMPoint): Boolean;
var
  U: TKMUnit;
begin
  U := Land^[aLoc.Y,aLoc.X].IsUnit;

  Result := (U = nil)
            or U.IsAnimal
            or (U.Action = nil)
            or not U.Action.Locked;
end;


function TKMTerrain.TileIsLocked(const aLoc: TKMPoint): Boolean;
var
  U: TKMUnit;
begin
  U := Land^[aLoc.Y,aLoc.X].IsUnit;
  //Action=nil can happen due to calling TileIsLocked during Unit.UpdateState.
  //Checks for Action=nil happen elsewhere, this is not the right place.
  if (U <> nil) and (U.Action = nil) then
    Result := False
  else
    Result := (U <> nil) and (U.Action.Locked);
end;


//Get tile corner terrain id
function TKMTerrain.TileCornerTerrain(aX, aY: Integer; aCorner: Byte): Word;
const
  TOO_BIG_VALUE = 50000;
var
  L: Integer;
begin
  Assert(InRange(aCorner, 0, 3), 'aCorner = ' + IntToStr(aCorner) + ' is not in range [0-3]');
  Result := TOO_BIG_VALUE;
  with gTerrain.Land^[aY,aX] do
  begin
    if BaseLayer.Corner[aCorner] then
      Result := BASE_TERRAIN[TILE_CORNERS_TERRAIN_KINDS[BaseLayer.Terrain, (aCorner + 4 - BaseLayer.Rotation) mod 4]]
    else
      for L := 0 to LayersCnt - 1 do
        if Layer[L].Corner[aCorner] then
          Result := BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain).TerKind];
  end;
  Assert(Result <> TOO_BIG_VALUE, Format('[TileCornerTerrain] Can''t determine tile [%d:%d] terrain at Corner [%d]', [aX, aY, aCorner]));
end;


//Get tile corners terrain id
function TKMTerrain.TileCornersTerrains(aX, aY: Integer): TKMWordArray;
var
  K: Integer;
  cornersTKinds: TKMTerrainKindCorners;
begin
  SetLength(Result, 4);
  GetTileCornersTerKinds(aX, aY, cornersTKinds);
  for K := 0 to 3 do
    Result[K] := BASE_TERRAIN[cornersTKinds[K]];
end;


function TKMTerrain.TileCornerTerKind(aX, aY: Integer; aCorner: Byte): TKMTerrainKind;
var
  L: Integer;
begin
  Assert(InRange(aCorner, 0, 3));
  
  Result := tkCustom;
  with gTerrain.Land^[aY,aX] do
  begin
    if BaseLayer.Corner[aCorner] then
      Result := TILE_CORNERS_TERRAIN_KINDS[BaseLayer.Terrain, (aCorner + 4 - BaseLayer.Rotation) mod 4]
    else
      for L := 0 to LayersCnt - 1 do
        if Layer[L].Corner[aCorner] then
        begin
          Result := gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain).TerKind;
          Break;
        end;
  end;
end;


//Get tile corners terrain kinds
procedure TKMTerrain.GetTileCornersTerKinds(aX, aY: Integer; out aCornerTerKinds: TKMTerrainKindCorners);
var
  K: Integer;
begin
  for K := 0 to 3 do
    aCornerTerKinds[K] := TileCornerTerKind(aX, aY, K);
end;


// Get vertice terrain kinds
procedure TKMTerrain.GetVerticeTerKinds(const aLoc: TKMPoint; out aVerticeTerKinds: TKMTerrainKindCorners);
  function GetTerKind(aX, aY, aCorner: Integer): TKMTerrainKind;
  begin
    Result := tkCustom;
    if TileInMapCoords(aX, aY) then
      Result := TileCornerTerKind(aX, aY, aCorner);
  end;
begin
  aVerticeTerKinds[0] := GetTerKind(aLoc.X - 1, aLoc.Y - 1, 2); //  0 | 1
  aVerticeTerKinds[1] := GetTerKind(aLoc.X    , aLoc.Y - 1, 3); //  __|__
  aVerticeTerKinds[2] := GetTerKind(aLoc.X    , aLoc.Y    , 0); //    |
  aVerticeTerKinds[3] := GetTerKind(aLoc.X - 1, aLoc.Y    , 1); //  3 | 2
end;


// Check if there's unit on the tile
// Note that IsUnit refers to where unit started walking to, not the actual unit position
// (which is what we used in unit interaction), so check all 9 tiles to get accurate result
function TKMTerrain.UnitsHitTest(X,Y: Word): Pointer;
var
  I, K: Integer;
  U: TKMUnit;
begin
  Result := nil;
  for I := Max(Y - 1, 1) to Min(Y + 1, fMapY) do
  for K := Max(X - 1, 1) to Min(X + 1, fMapX) do
  begin
    U := Land^[I,K].IsUnit;
    if (U <> nil) and U.HitTest(X,Y) then
      Result := Land^[I,K].IsUnit;
  end;
end;


//Test up to 4x4 related tiles around and pick unit whos no farther than 1 tile
function TKMTerrain.UnitsHitTestF(const aLoc: TKMPointF): Pointer;
var
  I, K: Integer;
  U: TKMUnit;
  T: Single;
begin
  Result := nil;
  for I := Max(Trunc(aLoc.Y) - 1, 1) to Min(Trunc(aLoc.Y) + 2, fMapY) do
  for K := Max(Trunc(aLoc.X) - 1, 1) to Min(Trunc(aLoc.X) + 2, fMapX) do
  begin
    U := Land^[I,K].IsUnit;
    if U <> nil then
    begin
      T := KMLengthSqr(U.PositionF, aLoc);
      if (T <= 1) and ((Result = nil) or (T < KMLengthSqr(TKMUnit(Result).PositionF, aLoc))) then
        Result := U;
    end;
  end;
end;


//Function to use with WatchTowers/Archers/Warriors
{ Should scan withing given radius and return closest unit with given Alliance status
  Should be optimized versus usual UnitsHitTest
  Prefer Warriors over Citizens}
function TKMTerrain.UnitsHitTestWithinRad(const aLoc: TKMPoint; MinRad, MaxRad: Single; aPlayer: TKMHandID; aAlliance: TKMAllianceType;
                                          Dir: TKMDirection; const aClosest: Boolean): Pointer;
type
  TKMUnitArray = array of TKMUnit;
  procedure Append(var aArray: TKMUnitArray; var aCount: Integer; const aUnit: TKMUnit);
  begin
    if aCount >= Length(aArray) then
      SetLength(aArray, aCount + 32);

    aArray[aCount] := aUnit;
    Inc(aCount);
  end;

  function Get90DegreeSectorRect: TKMRect;
  var IntegerRadius: Integer;
  begin
    //Scan one tile further than the maximum radius due to rounding
    IntegerRadius := Round(MaxRad + 1);  //1.42 gets rounded to 1

    //If direction is east we can skip left half
    if Dir in [dirNE, dirE, dirSE] then Result.Left := aLoc.X+1
                                      else Result.Left := aLoc.X-IntegerRadius;
    //If direction is west we can skip right half
    if Dir in [dirNW, dirW, dirSW] then Result.Right := aLoc.X-1
                                      else Result.Right := aLoc.X+IntegerRadius;
    //If direction is south we can skip top half
    if Dir in [dirSE, dirS, dirSW] then Result.Top := aLoc.Y+1
                                      else Result.Top := aLoc.Y-IntegerRadius;
    //If direction is north we can skip bottom half
    if Dir in [dirNE, dirN, dirNW] then Result.Bottom := aLoc.Y-1
                                      else Result.Bottom := aLoc.Y+IntegerRadius;

    Result := KMClipRect(Result, 1, 1, fMapX, fMapY); //Clip to map bounds
  end;

var
  I,K: Integer; //Counters
  boundsRect: TKMRect;
  dX,dY: Integer;
  requiredMaxRad: Single;
  U: TKMUnit;
  P: TKMPoint;
  wCount, cCount, initialSize: Integer;
  W, C: TKMUnitArray;
begin
  wCount := 0;
  cCount := 0;

  if aClosest then
    initialSize := 1 //We only need to keep 1 result
  else
    initialSize := 32; //Should be enough most times, Append will add more if needed

  SetLength(W, initialSize);
  SetLength(C, initialSize);

  //This function sets LowX, LowY, HighX, HighY based on the direction
  boundsRect := Get90DegreeSectorRect;

  for I := boundsRect.Top to boundsRect.Bottom do
  for K := boundsRect.Left to boundsRect.Right do
  begin
    U := Land^[I,K].IsUnit;
    if U = nil then Continue; //Most tiles are empty, so check it first

    //Check archer sector. If it's not within the 90 degree sector for this direction, then don't use this tile (continue)
    dX := K - aLoc.X;
    dY := I - aLoc.Y;
    case Dir of
      dirN : if not ((Abs(dX) <= -dY) and (dY < 0)) then Continue;
      dirNE: if not ((dX > 0)         and (dY < 0)) then Continue;
      dirE:  if not ((dX > 0) and (Abs(dY) <= dX))  then Continue;
      dirSE: if not ((dX > 0)         and (dY > 0)) then Continue;
      dirS : if not ((Abs(dX) <= dY)  and (dY > 0)) then Continue;
      dirSW: if not ((dX < 0)         and (dY > 0)) then Continue;
      dirW:  if not ((dX < 0) and (Abs(dY) <= -dX)) then Continue;
      dirNW: if not ((dX < 0)         and (dY < 0)) then Continue;
    end;

    //Alliance is the check that will invalidate most candidates, so do it early on
    if U.IsDeadOrDying //U = nil already checked earlier (above sector check)
    or (gHands.CheckAlliance(aPlayer, U.Owner) <> aAlliance) //How do WE feel about enemy, not how they feel about us
    or not U.Visible then //Inside of house
      Continue;

    //Don't check tiles farther than closest Warrior
    if aClosest and (W[0] <> nil)
    and (KMLengthSqr(aLoc, KMPoint(K,I)) >= KMLengthSqr(aLoc, W[0].Position)) then
      Continue; //Since we check left-to-right we can't exit just yet (there are possible better enemies below)

    //In KaM archers can shoot further than sight radius (shoot further into explored areas)
    //so CheckTileRevelation is required, we can't remove it to optimise.
    //But because it will not invalidate many candidates, check it late so other checks can do their work first
    if (gHands[aPlayer].FogOfWar.CheckTileRevelation(K,I) <> 255) then Continue;

    //This unit could be on a different tile next to KMPoint(k,i), so we cannot use that anymore.
    //There was a crash caused by VertexUsageCompatible checking (k,i) instead of U.CurrPosition.
    //In that case aLoc = (37,54) and k,i = (39;52) but U.CurrPosition = (38;53).
    //This shows why you can't use (k,i) in checks because it is distance >2 from aLoc! (in melee fight)
    P := U.Position;

    requiredMaxRad := MaxRad;
    if (MaxRad = 1) and KMStepIsDiag(aLoc, P) then
      requiredMaxRad := 1.42; //Use diagonal radius sqrt(2) instead

    if CanWalkDiagonaly(aLoc, P.X, P.Y)
    and ((Abs(aLoc.X - P.X) <> 1)
          or (Abs(aLoc.Y - P.Y) <> 1)
          or VertexUsageCompatible(aLoc, P)
        )
    and InRange(KMLength(KMPointF(aLoc), U.PositionF), MinRad, requiredMaxRad) //Unit's exact position must be close enough
    then
      if aClosest then
      begin
        if U is TKMUnitWarrior then
          W[0] := U
        else
          C[0] := U;
      end
      else
      begin
        if U is TKMUnitWarrior then
          Append(W, wCount, U)
        else
          Append(C, cCount, U);
      end;
  end;

  if aClosest then
  begin
    if W[0] <> nil then
      Result := W[0]
    else
      Result := C[0];
  end
  else
  begin
    if wCount > 0 then
      Result := W[KaMRandom(wCount, 'TKMTerrain.UnitsHitTestWithinRad')]
    else
      if cCount > 0 then
        Result := C[KaMRandom(cCount, 'TKMTerrain.UnitsHitTestWithinRad 2')]
      else
        Result := nil;
  end;
end;


function TKMTerrain.ObjectIsChopableTree(X,Y: Word): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsChoppableTree(Land^[Y,X].Obj);
end;


function TKMTerrain.ObjectIsChopableTree(const Loc: TKMPoint; aStage: TKMChopableAge): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsChoppableTree(Land^[Loc.Y,Loc.X].Obj, aStage);
end;


function TKMTerrain.ObjectIsChopableTree(const Loc: TKMPoint; aStages: TKMChopableAgeSet): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsChoppableTree(Land^[Loc.Y,Loc.X].Obj, aStages);
end;


function TKMTerrain.ObjectIsWine(const Loc: TKMPoint): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsWine(Land^[Loc.Y,Loc.X].Obj)
end;


function TKMTerrain.ObjectIsWine(X,Y: Word): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsWine(Land^[Y,X].Obj);
end;


function TKMTerrain.ObjectIsCorn(const Loc: TKMPoint): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsCorn(Land^[Loc.Y,Loc.X].Obj)
end;


function TKMTerrain.ObjectIsCorn(X,Y: Word): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsCorn(Land^[Y,X].Obj);
end;


{Check wherever unit can walk from A to B diagonaly}
{Return true if direction is either walkable or not diagonal}
{Maybe this can also be used later for inter-tile passability}
function TKMTerrain.CanWalkDiagonaly(const aFrom: TKMPoint; bX, bY: SmallInt): Boolean;
begin
  Result := True;

  //Tiles are not diagonal to each other
  if (Abs(aFrom.X - bX) <> 1) or (Abs(aFrom.Y - bY) <> 1) then
    Exit;
                                                               //Relative tiles locations
  if (aFrom.X < bX) and (aFrom.Y < bY) then                                   //   A
    Result := not gMapElements[Land^[bY, bX].Obj].DiagonalBlocked              //     B
  else
  if (aFrom.X < bX) and (aFrom.Y > bY) then                                   //     B
    Result := not gMapElements[Land^[bY+1, bX].Obj].DiagonalBlocked            //   A
  else
  if (aFrom.X > bX) and (aFrom.Y > bY) then                                   //   B
    Result := not gMapElements[Land^[aFrom.Y, aFrom.X].Obj].DiagonalBlocked    //     A
  else
  if (aFrom.X > bX) and (aFrom.Y < bY) then                                   //     A
    Result := not gMapElements[Land^[aFrom.Y+1, aFrom.X].Obj].DiagonalBlocked; //   B
end;


//Place lock on tile, any new TileLock replaces old one, thats okay
procedure TKMTerrain.SetTileLock(const aLoc: TKMPoint; aTileLock: TKMTileLock);
var
  R: TKMRect;
begin
  Assert(aTileLock in [tlDigged, tlRoadWork, tlFieldWork], 'We expect only these 3 locks, that affect only 1 tile an don''t change neighbours Passability');

  Land^[aLoc.Y, aLoc.X].TileLock := aTileLock;
  R := KMRect(aLoc);

  //Placing a lock on tile blocks tiles CanPlantTree
  UpdatePassability(KMRectGrow(R, 1));

  //Allowed TileLocks affect passability on this single tile
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], R, False);
end;


//Remove lock from tile
procedure TKMTerrain.UnlockTile(const aLoc: TKMPoint);
var
  R: TKMRect;
begin
  Assert(Land^[aLoc.Y, aLoc.X].TileLock in [tlDigged, tlRoadWork, tlFieldWork], 'We expect only these 3 locks, that affect only 1 tile an don''t change neighbours Passability');

  Land^[aLoc.Y, aLoc.X].TileLock := tlNone;
  R := KMRect(aLoc);

  //Removing a lock from tile unblock BR tiles CanPlantTree
  UpdatePassability(KMRectGrow(R, 1));

  //Allowed TileLocks affect passability on this single tile
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], R, False);
end;


procedure TKMTerrain.SetRoads(aList: TKMPointList; aOwner: TKMHandID; aUpdateWalkConnects: Boolean = True);
var
  I: Integer;
  Y2, X2: Integer;
  bounds: TKMRect;
  hasBounds: Boolean;
begin
  if aList.Count = 0 then Exit; //Nothing to be done

  for I := 0 to aList.Count - 1 do
  begin
    Y2 := aList[I].Y;
    X2 := aList[I].X;

    Land^[Y2, X2].TileOwner   := aOwner;
    Land^[Y2, X2].TileOverlay := toRoad;
    Land^[Y2, X2].FieldAge    := 0;

    if gMapElements[Land^[Y2, X2].Obj].WineOrCorn then
      RemoveObject(aList[I]);

    RemoveObjectsKilledByRoad(aList[I]);
    UpdateFences(aList[I]);
  end;

  hasBounds := aList.GetBounds(bounds);
  Assert(hasBounds);

  //Grow the bounds by extra tile because some passabilities
  //depend on road nearby (e.g. CanPlantTree)
  UpdatePassability(KMRectGrowBottomRight(bounds));

  //Roads don't affect wcWalk or wcFish
  if aUpdateWalkConnects then
    UpdateWalkConnect([wcRoad], bounds, False);
end;


procedure TKMTerrain.RemRoad(const Loc: TKMPoint);
begin
  Land^[Loc.Y,Loc.X].TileOwner := -1;
  Land^[Loc.Y,Loc.X].TileOverlay := toNone;
  Land^[Loc.Y,Loc.X].FieldAge  := 0;
  UpdateFences(Loc);
  UpdatePassability(KMRectGrowBottomRight(KMRect(Loc)));

  //Roads don't affect wcWalk or wcFish
  UpdateWalkConnect([wcRoad], KMRect(Loc), False);
end;


procedure TKMTerrain.RemField(const Loc: TKMPoint; aDoUpdatePass, aDoUpdateWalk, aDoUpdateFences: Boolean);
var
  updatePassRect: TKMRect;
  diagObjectChanged: Boolean;
begin
  RemField(Loc, aDoUpdatePass, aDoUpdateWalk, updatePassRect, diagObjectChanged, aDoUpdateFences);
end;


procedure TKMTerrain.RemField(const Loc: TKMPoint; aDoUpdatePass, aDoUpdateWalk: Boolean;
                              out aUpdatePassRect: TKMRect; out aDiagObjectChanged: Boolean;
                              aDoUpdateFences: Boolean);
begin
  Land^[Loc.Y,Loc.X].TileOwner := -1;
  Land^[Loc.Y,Loc.X].TileOverlay := toNone;

  if fMapEditor then
  begin
    gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWine := 0;
    gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWineTerrain := 0;
  end;

  if Land^[Loc.Y,Loc.X].Obj in [54..59] then
  begin
    Land^[Loc.Y,Loc.X].Obj := OBJ_NONE; //Remove corn/wine
    aDiagObjectChanged := True;
  end
  else
    aDiagObjectChanged := False;
    
  Land^[Loc.Y,Loc.X].FieldAge := 0;

  if aDoUpdateFences then
    UpdateFences(Loc);
    
  aUpdatePassRect := KMRectGrow(KMRect(Loc),1);

  if aDoUpdatePass then
    UpdatePassability(aUpdatePassRect);

  if aDoUpdateWalk then
    //Update affected WalkConnect's
    UpdateWalkConnect([wcWalk,wcRoad,wcWork], aUpdatePassRect, aDiagObjectChanged); //Winefields object block diagonals
end;


procedure TKMTerrain.RemField(const Loc: TKMPoint);
var
  diagObjectChanged: Boolean;
  R: TKMRect;
begin
  Land^[Loc.Y,Loc.X].TileOwner := -1;
  Land^[Loc.Y,Loc.X].TileOverlay := toNone;

  if fMapEditor then
  begin
    gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWine := 0;
    gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWineTerrain := 0;
  end;

  if Land^[Loc.Y,Loc.X].Obj in [54..59] then
  begin
    Land^[Loc.Y,Loc.X].Obj := OBJ_NONE; //Remove corn/wine
    diagObjectChanged := True;
  end
  else
    diagObjectChanged := False;
  Land^[Loc.Y,Loc.X].FieldAge := 0;
  UpdateFences(Loc);

  R := KMRectGrow(KMRect(Loc), 1);
  UpdatePassability(R);

  //Update affected WalkConnect's
  UpdateWalkConnect([wcWalk,wcRoad,wcWork], R, diagObjectChanged); //Winefields object block diagonals
end;


procedure TKMTerrain.ClearPlayerLand(aPlayer: TKMHandID);
var
  I, K: Integer;
  P: TKMPoint;
begin
  for I := 1 to fMapY do
    for K := 1 to fMapX do
      if (Land^[I, K].TileOwner = aPlayer) then
      begin
        P.X := K;
        P.Y := I;

        if (Land^[I, K].Obj <> OBJ_NONE) then
        begin
          if TileIsCornField(P) and (GetCornStage(P) in [4,5]) then
            SetField(P, Land^[I, K].TileOwner, ftCorn, 3)  // For corn, when delete corn object reduce field stage to 3
          else if TileIsWineField(P) then
            RemField(P)
          else
            SetObject(P, OBJ_NONE);
        end;

        if Land^[I, K].TileOverlay = toRoad then
          RemRoad(P);
        if TileIsCornField(P) or TileIsWineField(P) then
          RemField(P);
      end;

end;


procedure TKMTerrain.RemovePlayer(aPlayer: TKMHandID);
var
  I, K: Word;
begin
  for I := 1 to fMapY do
    for K := 1 to fMapX do
      if Land^[I, K].TileOwner > aPlayer then
        Land[I, K].TileOwner := Pred(Land^[I, K].TileOwner)
      else if Land^[I, K].TileOwner = aPlayer then
        Land^[I, K].TileOwner := -1;
end;


procedure TKMTerrain.SetField_Init(const Loc: TKMPoint; aOwner: TKMHandID; aRemoveOverlay: Boolean = True);
begin
  Land^[Loc.Y,Loc.X].TileOwner   := aOwner;
  if aRemoveOverlay then
    Land^[Loc.Y,Loc.X].TileOverlay := toNone;
  Land^[Loc.Y,Loc.X].FieldAge    := 0;
end;


procedure TKMTerrain.SetField_Complete(const Loc: TKMPoint; aFieldType: TKMFieldType);
begin
  UpdateFences(Loc);
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));
  //Walk and Road because Grapes are blocking diagonal moves
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(Loc)), (aFieldType = ftWine)); //Grape object blocks diagonal, others don't
end;


procedure TKMTerrain.SetRoad(const Loc: TKMPoint; aOwner: TKMHandID);
begin
  SetField_Init(Loc, aOwner);

  Land^[Loc.Y,Loc.X].TileOverlay := toRoad;

  SetField_Complete(Loc, ftRoad);

  gScriptEvents.ProcRoadBuilt(aOwner, Loc.X, Loc.Y);
end;


procedure TKMTerrain.SetInitWine(const Loc: TKMPoint; aOwner: TKMHandID);
begin
  SetField_Init(Loc, aOwner);

  Land^[Loc.Y,Loc.X].BaseLayer.Terrain  := 55;
  Land^[Loc.Y,Loc.X].BaseLayer.Rotation := 0;

  SetField_Complete(Loc, ftInitWine);
end;


procedure TKMTerrain.IncDigState(const Loc: TKMPoint);
begin
  case Land^[Loc.Y,Loc.X].TileOverlay of
    toDig3: Land^[Loc.Y,Loc.X].TileOverlay := toDig4;
    toDig2: Land^[Loc.Y,Loc.X].TileOverlay := toDig3;
    toDig1: Land^[Loc.Y,Loc.X].TileOverlay := toDig2;
    else     Land^[Loc.Y,Loc.X].TileOverlay := toDig1;
  end;
end;


procedure TKMTerrain.ResetDigState(const Loc: TKMPoint);
begin
  Land^[Loc.Y,Loc.X].TileOverlay:=toNone;
end;


{ Finds a winefield ready to be picked }
function TKMTerrain.FindWineField(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; out FieldPoint: TKMPointDir): Boolean;
var
  I: Integer;
  validTiles: TKMPointList;
  nearTiles, farTiles: TKMPointDirList;
  P: TKMPoint;
begin
  validTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);

  nearTiles := TKMPointDirList.Create;
  farTiles := TKMPointDirList.Create;
  for I := 0 to validTiles.Count - 1 do
  begin
    P := validTiles[I];
    if not KMSamePoint(aAvoidLoc,P) then
      if TileIsWineField(P) then
        if Land^[P.Y,P.X].FieldAge = CORN_AGE_MAX then
          if not TileIsLocked(P) then //Taken by another farmer
            if Route_CanBeMade(aLoc, P, tpWalk, 0) then
            begin
              if KMLengthSqr(aLoc, P) <= Sqr(aRadius div 2) then
                nearTiles.Add(KMPointDir(P, dirNA))
              else
                farTiles.Add(KMPointDir(P, dirNA));
            end;
  end;

  //Prefer close tiles to reduce inefficiency with shared fields
  Result := nearTiles.GetRandom(FieldPoint);
  if not Result then
    Result := farTiles.GetRandom(FieldPoint);

  nearTiles.Free;
  farTiles.Free;
  validTiles.Free;
end;


procedure TKMTerrain.FindCornFieldLocs(const aLoc: TKMPoint; aRadius: Integer; aCornLocs: TKMPointList);
var
  I: Integer;
  P: TKMPoint;
  validTiles: TKMPointList;
begin
  validTiles := TKMPointList.Create;
  try
    fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);

    for I := 0 to validTiles.Count - 1 do
    begin
      P := validTiles[I];
      if TileIsCornField(P) and Route_CanBeMade(aLoc, P, tpWalk, 0) then
        aCornLocs.Add(P);
    end;
  finally
    validTiles.Free;
  end;
end;


procedure TKMTerrain.FindWineFieldLocs(const aLoc: TKMPoint; aRadius: Integer; aCornLocs: TKMPointList);
var
  I: Integer;
  P: TKMPoint;
  validTiles: TKMPointList;
begin
  validTiles := TKMPointList.Create;
  try
    fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);

    for I := 0 to validTiles.Count - 1 do
    begin
      P := validTiles[I];
      if TileIsWineField(P) and Route_CanBeMade(aLoc, P, tpWalk, 0) then
        aCornLocs.Add(P);
    end;
  finally
    validTiles.Free;
  end;
end;


{ Finds a corn field }
function TKMTerrain.FindCornField(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                                  out PlantAct: TKMPlantAct; out FieldPoint: TKMPointDir): Boolean;
var
  I: Integer;
  validTiles, nearTiles, farTiles: TKMPointList;
  P: TKMPoint;
begin
  validTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);

  nearTiles := TKMPointList.Create;
  farTiles := TKMPointList.Create;
  for I := 0 to validTiles.Count - 1 do
  begin
    P := validTiles[i];
    if not KMSamePoint(aAvoidLoc,P) then
      if TileIsCornField(P) then
        if((aPlantAct in [taAny, taPlant]) and (Land^[P.Y,P.X].FieldAge = 0)) or
          ((aPlantAct in [taAny, taCut])   and (Land^[P.Y,P.X].FieldAge = CORN_AGE_MAX)) then
          if not TileIsLocked(P) then //Taken by another farmer
            if Route_CanBeMade(aLoc, P, tpWalk, 0) then
            begin
              if KMLengthSqr(aLoc, P) <= Sqr(aRadius div 2) then
                nearTiles.Add(P)
              else
                farTiles.Add(P);
            end;
  end;

  //Prefer close tiles to reduce inefficiency with shared fields
  Result := nearTiles.GetRandom(P);
  if not Result then
    Result := farTiles.GetRandom(P);

  FieldPoint := KMPointDir(P, dirNA);
  nearTiles.Free;
  farTiles.Free;
  validTiles.Free;
  if not Result then
    PlantAct := taAny
  else
    if Land^[FieldPoint.Loc.Y,FieldPoint.Loc.X].FieldAge = CORN_AGE_MAX then
      PlantAct := taCut
    else
      PlantAct := taPlant;
end;


procedure TKMTerrain.FindStoneLocs(const aLoc: TKMPoint; aRadius: Byte; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                                   aStoneLocs: TKMPointList);
var
  I: Integer;
  validTiles: TKMPointList;
  P: TKMPoint;
begin
  validTiles := TKMPointList.Create;
  try
    fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);

    for I := 0 to validTiles.Count - 1 do
    begin
      P := validTiles[I];
      if (P.Y >= 2) //Can't mine stone from top row of the map (don't call TileIsStone with Y=0)
        and not KMSamePoint(aAvoidLoc, P)
        and TileHasStone(P.X, P.Y - 1)
        and (aIgnoreWorkingUnits or not TileIsLocked(P)) //Already taken by another stonemason
        and Route_CanBeMade(aLoc, P, tpWalk, 0) then
        aStoneLocs.Add(P);
    end;
  finally
    validTiles.Free;
  end;
end;


{Find closest harvestable deposit of Stone}
{Return walkable tile below Stone deposit}
function TKMTerrain.FindStone(const aLoc: TKMPoint; aRadius: Byte; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                              out StonePoint: TKMPointDir): Boolean;
var
  chosenTiles: TKMPointList;
  P: TKMPoint;
begin
  chosenTiles := TKMPointList.Create;
  try
    FindStoneLocs(aLoc, aRadius, aAvoidLoc, aIgnoreWorkingUnits, chosenTiles);

    Result := chosenTiles.GetRandom(P);
    StonePoint := KMPointDir(P, dirN);
  finally
    chosenTiles.Free;
  end;
end;


function TKMTerrain.FindOre(const aLoc: TKMPoint; aRes: TKMWareType; out OrePoint: TKMPoint): Boolean;
var
  I: Integer;
  L: TKMPointListArray;
begin
  SetLength(L, ORE_MAX_TYPES_CNT);
  //Create separate list for each density, to be able to pick best one
  for I := 0 to Length(L) - 1 do
    L[I] := TKMPointList.Create;

  FindOrePoints(aLoc, aRes, L);

  //Equation elements will be evalueated one by one until True is found
  Result := False;
  for I := ORE_MAX_TYPES_CNT - 1 downto 0 do
    if not Result then
      Result := L[I].GetRandom(OrePoint)
    else
      Break;

  for I := 0 to Length(L) - 1 do
    L[I].Free;
end;


function TKMTerrain.GetMiningRect(aRes: TKMWareType): TKMRect;
begin
  case aRes of
    wtGoldOre: Result := KMRect(7, 11, 6, 2);
    wtIronOre: Result := KMRect(7, 11, 5, 2);
    wtCoal:    Result := KMRect(4,  5, 5, 2);
    else        Result := KMRECT_ZERO;
  end;
end;


procedure TKMTerrain.FindOrePointsByDistance(aLoc: TKMPoint; aRes: TKMWareType; var aPoints: TKMPointListArray);
var
  I,K: Integer;
  miningRect: TKMRect;
begin
  Assert(Length(aPoints) = 3, 'Wrong length of Points array: ' + IntToStr(Length(aPoints)));

  if not (aRes in [wtIronOre, wtGoldOre, wtCoal]) then
    raise ELocError.Create('Wrong resource as Ore', aLoc);

  miningRect := GetMiningRect(aRes);

  for I := Max(aLoc.Y - miningRect.Top, 1) to Min(aLoc.Y + miningRect.Bottom, fMapY - 1) do
    for K := Max(aLoc.X - miningRect.Left, 1) to Min(aLoc.X + miningRect.Right, fMapX - 1) do
    begin
      if ((aRes = wtIronOre)   and TileHasIron(K,I))
        or ((aRes = wtGoldOre) and TileHasGold(K,I))
        or ((aRes = wtCoal)    and TileHasCoal(K,I)) then
      begin
        //Poorest ore gets mined in range - 2
        if InRange(I - aLoc.Y, - miningRect.Top + 2, miningRect.Bottom - 2)
          and InRange(K - aLoc.X, - miningRect.Left + 2, miningRect.Right - 2) then
            aPoints[0].Add(KMPoint(K, I))
        //Second poorest ore gets mined in range - 1
        else
        if InRange(I - aLoc.Y, - miningRect.Top + 1, miningRect.Bottom - 1)
          and InRange(K - aLoc.X, - miningRect.Left + 1, miningRect.Right - 1) then
            aPoints[1].Add(KMPoint(K, I))
        else
          //Always mine second richest ore
          aPoints[2].Add(KMPoint(K, I));
      end;
    end;
end;

//Given aLoc the function return location of richest ore within predefined bounds
procedure TKMTerrain.FindOrePoints(const aLoc: TKMPoint; aRes: TKMWareType; var aPoints: TKMPointListArray);
var
  I,K: Integer;
  miningRect: TKMRect;
  R1,R2,R3,R3_2,R4,R5: Integer; //Ore densities
begin
  if not (aRes in [wtIronOre, wtGoldOre, wtCoal]) then
    raise ELocError.Create('Wrong resource as Ore', aLoc);

  Assert(Length(aPoints) = ORE_MAX_TYPES_CNT, 'Wrong length of Points array: ' + IntToStr(Length(aPoints)));

  miningRect := GetMiningRect(aRes);

  //These values have been measured from KaM
  case aRes of
    wtGoldOre: begin R1 := 144; R2 := 145; R3 := 146; R3_2 :=  -1; R4 := 147; R5 := 307; end;
    wtIronOre: begin R1 := 148; R2 := 149; R3 := 150; R3_2 := 259; R4 := 151; R5 := 260; end;
    wtCoal:    begin R1 := 152; R2 := 153; R3 := 154; R3_2 :=  -1; R4 := 155; R5 := 263; end;
    else       begin R1 :=  -1; R2 :=  -1; R3 :=  -1; R3_2 :=  -1; R4 :=  -1; R5 :=  -1; end;
  end;

  for I := Max(aLoc.Y - miningRect.Top, 1) to Min(aLoc.Y + miningRect.Bottom, fMapY - 1) do
    for K := Max(aLoc.X - miningRect.Left, 1) to Min(aLoc.X + miningRect.Right, fMapX - 1) do
    begin
      if Land^[I, K].BaseLayer.Terrain = R1 then
      begin
        //Poorest ore gets mined in range - 2
        if InRange(I - aLoc.Y, - miningRect.Top + 2, miningRect.Bottom - 2) then
          if InRange(K - aLoc.X, - miningRect.Left + 2, miningRect.Right - 2) then
            aPoints[0].Add(KMPoint(K, I));
      end
      else if Land^[I, K].BaseLayer.Terrain = R2 then
      begin
        //Second poorest ore gets mined in range - 1
        if InRange(I - aLoc.Y, - miningRect.Top + 1, miningRect.Bottom - 1) then
          if InRange(K - aLoc.X, - miningRect.Left + 1, miningRect.Right - 1) then
            aPoints[1].Add(KMPoint(K, I));
      end
      else if (Land^[I, K].BaseLayer.Terrain = R3)
        or (Land^[I, K].BaseLayer.Terrain = R3_2) then
        //Always mine second richest ore
        aPoints[2].Add(KMPoint(K, I))
      else if Land^[I, K].BaseLayer.Terrain = R4 then
        // Always mine richest ore
        aPoints[3].Add(KMPoint(K, I))
      else if Land^[I, K].BaseLayer.Terrain = R5 then
        // Always mine the most richest ore
        aPoints[4].Add(KMPoint(K, I));
    end;
end;


function TKMTerrain.ChooseCuttingDirection(const aLoc, aTree: TKMPoint; out CuttingPoint: TKMPointDir): Boolean;
var
  I, K, bestSlope, slope: Integer;
begin
  bestSlope := MaxInt;
  Result := False; //It is already tested that we can walk to the tree, but double-check

  for I:=-1 to 0 do for K:=-1 to 0 do
  if Route_CanBeMade(aLoc, KMPoint(aTree.X+K, aTree.Y+I), tpWalk, 0) then
  begin
    slope := Round(HeightAt(aTree.X+K-0.5, aTree.Y+I-0.5) * CELL_HEIGHT_DIV) - Land^[aTree.Y, aTree.X].Height;
    //Cutting trees which are higher than us from the front looks visually poor, (axe hits ground) so avoid it where possible
    if (I = 0) and (slope < 0) then slope := slope - 100; //Make it worse but not worse than initial BestSlope
    if Abs(slope) < bestSlope then
    begin
      CuttingPoint := KMPointDir(aTree.X+K, aTree.Y+I, KMGetVertexDir(K, I));
      Result := True;
      bestSlope := Abs(slope);
    end;
  end;
end;


function TKMTerrain.CanFindTree(const aLoc: TKMPoint; aRadius: Word; aOnlyAgeFull: Boolean = False): Boolean;
var
  validTiles: TKMPointList;
  I: Integer;
  T: TKMPoint;
  cuttingPoint: TKMPointDir;
begin
  Result := False;
  //Scan terrain and add all trees/spots into lists
  validTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);
  for I := 0 to validTiles.Count - 1 do
  begin
     //Store in temp variable for speed
    T := validTiles[I];

    if (KMLengthDiag(aLoc, T) <= aRadius)
    // Only full age
    and ( (aOnlyAgeFull and ObjectIsChopableTree(T, caAgeFull))
    // Any age tree will do
          or (not aOnlyAgeFull and (
            ObjectIsChopableTree(T, caAge1) or ObjectIsChopableTree(T, caAge2) or
            ObjectIsChopableTree(T, caAge3) or ObjectIsChopableTree(T, caAgeFull) )
          )
        )
    and Route_CanBeMadeToVertex(aLoc, T, tpWalk)
    and ChooseCuttingDirection(aLoc, T, cuttingPoint) then
    begin
      Result := True;
      Break;
    end;
  end;
  validTiles.Free;
end;


//Return location of a Tree or a place to plant a tree depending on TreeAct
//taChop - Woodcutter wants to get a Tree because he went from home with an axe
//        (maybe his first target was already chopped down, so he either needs a tree or will go home)
//taPlant - Woodcutter specifically wants to get an empty place to plant a Tree
//taAny - Anything will do since Woodcutter is querying from home
//Result indicates if desired TreeAct place was found successfully
procedure TKMTerrain.FindTree(const aLoc: TKMPoint; aRadius: Word; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                              Trees: TKMPointDirCenteredList; BestToPlant, SecondBestToPlant: TKMPointCenteredList);
var
  validTiles: TKMPointList;
  I: Integer;
  T: TKMPoint;
  cuttingPoint: TKMPointDir;
begin
  //Why do we use 3 lists instead of one like Corn does?
  //Because we should always prefer stumps over empty places
  //even if there's only 1 stump - we choose it

  //Scan terrain and add all trees/spots into lists
  validTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);
  for I := 0 to validTiles.Count - 1 do
  begin
     //Store in temp variable for speed
    T := validTiles[I];

    if (KMLengthDiag(aLoc, T) <= aRadius)
    and not KMSamePoint(aAvoidLoc, T) then
    begin

      //Grownup tree
      if (aPlantAct in [taCut, taAny])
      and ObjectIsChopableTree(T, caAgeFull)
      and (Land^[T.Y,T.X].TreeAge >= TREE_AGE_FULL)
      //Woodcutter could be standing on any tile surrounding this tree
      and TileIsGoodToCutTree(T)
      and ((T.X = 1) or TileIsGoodToCutTree(KMPoint(T.X - 1, T.Y))) //if K=1, K-1 will be off map
      and ((T.Y = 1) or TileIsGoodToCutTree(KMPoint(T.X, T.Y - 1)))
      and ((T.X = 1) or (T.Y = 1) or TileIsGoodToCutTree(KMPoint(T.X - 1, T.Y - 1)))
      and Route_CanBeMadeToVertex(aLoc, T, tpWalk) then
        if ChooseCuttingDirection(aLoc, T, cuttingPoint) then
          Trees.Add(cuttingPoint); //Tree

      if (aPlantAct in [taPlant, taAny])
      and TileGoodToPlantTree(T.X, T.Y)
      and Route_CanBeMade(aLoc, T, tpWalk, 0)
      and not TileIsLocked(T) then //Taken by another woodcutter
        if ObjectIsChopableTree(T, caAgeStump) then
          BestToPlant.Add(T) //Prefer to dig out and plant on stumps to avoid cluttering whole area with em
        else
          SecondBestToPlant.Add(T); //Empty space and other objects that can be dug out (e.g. mushrooms) if no other options available
    end;
  end;
  validTiles.Free;
end;


procedure TKMTerrain.FindPossibleTreePoints(const aLoc: TKMPoint; aRadius: Word; aTiles: TKMPointList);
var
  validTiles: TKMPointList;
  I: Integer;
  T: TKMPoint;
  cuttingPoint: TKMPointDir;
begin
  validTiles := TKMPointList.Create;
  try
    //Scan terrain and add all trees/spots into lists
    fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);
    for I := 0 to validTiles.Count - 1 do
    begin
       //Store in temp variable for speed
      T := validTiles[I];

      if (KMLengthDiag(aLoc, T) <= aRadius)
        and Route_CanBeMadeToVertex(aLoc, T, tpWalk)
        and ChooseCuttingDirection(aLoc, T, cuttingPoint)
        and (FindBestTreeType(T) <> ttNone) then // Check if tile is ok to plant a tree there, according to vertex terrainKind
        aTiles.Add(T);
    end;
  finally
    validTiles.Free;
  end;
end;


procedure TKMTerrain.FindFishWaterLocs(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                                       ChosenTiles: TKMPointDirList);
var
  I, J, K: Integer;
  P: TKMPoint;
  validTiles: TKMPointList;
begin
  validTiles := TKMPointList.Create;
  try
    fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, validTiles);

    for I := 0 to validTiles.Count - 1 do
    begin
      P := validTiles[I];
      //Check that this tile is valid
      if (aIgnoreWorkingUnits or not TileIsLocked(P)) //Taken by another fisherman
      and Route_CanBeMade(aLoc, P, tpWalk, 0)
      and not KMSamePoint(aAvoidLoc, P) then
        //Now find a tile around this one that is water
        for J := -1 to 1 do
          for K := -1 to 1 do
            if ((K <> 0) or (J <> 0))
            and TileInMapCoords(P.X+J, P.Y+K)
            and TileIsWater(P.X+J, P.Y+K)
            and WaterHasFish(KMPoint(P.X+J, P.Y+K)) then //Limit to only tiles which are water and have fish
              ChosenTiles.Add(KMPointDir(P, KMGetDirection(J, K)));
    end;
  finally
    validTiles.Free;
  end;
end;


{Find seaside}
{Return walkable tile nearby}
function TKMTerrain.FindFishWater(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                                  out FishPoint: TKMPointDir): Boolean;
var
  chosenTiles: TKMPointDirList;
begin
  chosenTiles := TKMPointDirList.Create;
  try
    FindFishWaterLocs(aLoc, aRadius, aAvoidLoc, aIgnoreWorkingUnits, chosenTiles);

    Result := chosenTiles.GetRandom(FishPoint);
  finally
    chosenTiles.Free;
  end;
end;


function TKMTerrain.CanFindFishingWater(const aLoc: TKMPoint; aRadius: Integer): Boolean;
var
  I, K: Integer;
begin
  Result := False;
  for I := max(aLoc.Y - aRadius, 1) to Min(aLoc.Y + aRadius, fMapY-1) do
  for K := max(aLoc.X - aRadius, 1) to Min(aLoc.X + aRadius, fMapX-1) do
    if (KMLengthDiag(aLoc, KMPoint(K,I)) <= aRadius)
    and TileIsWater(K,I) then
    begin
      Result := True;
      Exit;
    end;
end;


function TKMTerrain.FindBestTreeType(const aLoc: TKMPoint): TKMTreeType;
const
  // Dependancy found empirically
  TERKIND_TO_TREE_TYPE: array[TKMTerrainKind] of TKMTreeType = (
    ttNone,           //    tkCustom,
    ttOnGrass,        //    tkGrass,
    ttOnGrass,        //    tkMoss,
    ttOnGrass,        //    tkPaleGrass,
    ttNone,           //    tkCoastSand,
    ttOnGrass,        //    tkGrassSand1,
    ttOnYellowGrass,  //    tkGrassSand2,
    ttOnYellowGrass,  //    tkGrassSand3,
    ttOnGrass,        //    tkSand,       //8
    ttOnDirt,         //    tkGrassDirt,
    ttOnDirt,         //    tkDirt,       //10
    ttOnDirt,         //    tkCobbleStone,
    ttNone,           //    tkGrassyWater,//12
    ttNone,           //    tkSwamp,      //13
    ttNone,           //    tkIce,        //14
    ttOnGrass,        //    tkSnowOnGrass,
    ttOnDirt,         //    tkSnowOnDirt,
    ttNone,           //    tkSnow,
    ttNone,           //    tkDeepSnow,
    ttNone,           //    tkStone,
    ttNone,           //    tkGoldMount,
    ttNone,           //    tkIronMount,  //21
    ttNone,           //    tkAbyss,
    ttOnDirt,         //    tkGravel,
    ttNone,           //    tkCoal,
    ttNone,           //    tkGold,
    ttNone,           //    tkIron,
    ttNone,           //    tkWater,
    ttNone,           //    tkFastWater,
    ttNone            //    tkLava);
  );
var
  I, K: Integer;
  treeType: TKMTreeType;
  verticeCornerTKinds: TKMTerrainKindCorners;
begin
  // Find tree type to plant by vertice corner terrain kinds
  Result := ttNone;
  GetVerticeTerKinds(aLoc, verticeCornerTKinds);
  // Compare corner terKinds and find if there are at least 2 of the same tree type
  for I := 0 to 3 do
    for K := I + 1 to 3 do
    begin
      treeType := TERKIND_TO_TREE_TYPE[verticeCornerTKinds[I]];
      if    (treeType <> ttNone)
        and (treeType = TERKIND_TO_TREE_TYPE[verticeCornerTKinds[K]]) then //Pair found - we can choose this tree type
        Exit(treeType);
    end;
end;


function TKMTerrain.ChooseTreeToPlant(const aLoc: TKMPoint): Integer;
begin
  Result := ChooseTreeToPlace(aLoc, caAge1, True); // Default plant age is caAge1
end;


function TKMTerrain.ChooseTreeToPlace(const aLoc: TKMPoint; aTreeAge: TKMChopableAge; aAlwaysPlaceTree: Boolean): Integer;
var
  bestTreeType: TKMTreeType;
begin
  Result := OBJ_NONE;
  //This function randomly chooses a tree object based on the terrain type. Values matched to KaM, using all soil tiles.
  case Land^[aLoc.Y,aLoc.X].BaseLayer.Terrain of
    0..3,5,6,8,9,11,13,14,18,19,56,57,66..69,72..74,84..86,93..98,180,188: bestTreeType := ttOnGrass;
    26..28,75..80,182,190:                                                 bestTreeType := ttOnYellowGrass;
    16,17,20,21,34..39,47,49,58,64,65,87..89,183,191,220,247:              bestTreeType := ttOnDirt;
    else
      bestTreeType := FindBestTreeType(aLoc);
  end;

  case bestTreeType of
    ttNone:           if aAlwaysPlaceTree then
                        Result := ChopableTrees[1 + KaMRandom(Length(ChopableTrees), 'TKMTerrain.ChooseTreeToPlant 4'), aTreeAge]; //If it isn't one of those soil types then choose a random tree
    ttOnGrass:        Result := ChopableTrees[1 + KaMRandom(7, 'TKMTerrain.ChooseTreeToPlant'), aTreeAge]; //Grass (oaks, etc.)
    ttOnYellowGrass:  Result := ChopableTrees[7 + KaMRandom(2, 'TKMTerrain.ChooseTreeToPlant 2'), aTreeAge]; //Yellow dirt
    ttOnDirt:         Result := ChopableTrees[9 + KaMRandom(5, 'TKMTerrain.ChooseTreeToPlant 3'), aTreeAge]; //Brown dirt (pine trees)
  end;
end;


procedure TKMTerrain.GetHouseMarks(const aLoc: TKMPoint; aHouseType: TKMHouseType; aList: TKMPointTagList);

  procedure MarkPoint(aPoint: TKMPoint; aID: Integer);
  var
    I: Integer;
  begin
    for I := 0 to aList.Count - 1 do //Skip wires from comparison
      if (aList.Tag[I] <> TC_OUTLINE) and KMSamePoint(aList[I], aPoint) then
        Exit;
    aList.Add(aPoint, aID);
  end;

var
  I,K,S,T: Integer;
  P2: TKMPoint;
  allowBuild: Boolean;
  HA: THouseArea;
begin
  Assert(aList.Count = 0);
  HA := gRes.Houses[aHouseType].BuildArea;

  for I := 1 to 4 do
    for K := 1 to 4 do
      if HA[I,K] <> 0 then
      begin

        if TileInMapCoords(aLoc.X+K-3-gRes.Houses[aHouseType].EntranceOffsetX,aLoc.Y+I-4,1) then
        begin
          //This can't be done earlier since values can be off-map
          P2 := KMPoint(aLoc.X+K-3-gRes.Houses[aHouseType].EntranceOffsetX,aLoc.Y+I-4);

          //Check house-specific conditions, e.g. allow shipyards only near water and etc..
          case aHouseType of
            htIronMine: allowBuild := CanPlaceIronMine(P2.X, P2.Y);
            htGoldMine: allowBuild := CanPlaceGoldMine(P2.X, P2.Y);
            else        allowBuild := (tpBuild in Land^[P2.Y,P2.X].Passability);
          end;

          //Check surrounding tiles in +/- 1 range for other houses pressence
          if not allowBuild then
            for S := -1 to 1 do
              for T := -1 to 1 do
                if (S <> 0) or (T<>0) then  //This is a surrounding tile, not the actual tile
                  if Land^[P2.Y+T,P2.X+S].TileLock in [tlFenced,tlDigged,tlHouse] then
                  begin
                    MarkPoint(KMPoint(P2.X+S,P2.Y+T), TC_BLOCK);
                    allowBuild := false;
                  end;

          //Mark the tile according to previous check results
          if allowBuild then
          begin
            if HA[I,K] = 2 then
              MarkPoint(P2, TC_ENTRANCE)
            else
              MarkPoint(P2, TC_OUTLINE);
          end
          else
          begin
            if HA[I,K] = 2 then
              MarkPoint(P2, TC_BLOCK_ENTRANCE)
            else
              if aHouseType in [htGoldMine, htIronMine] then
                MarkPoint(P2, TC_BLOCK_MINE)
              else
                MarkPoint(P2, TC_BLOCK);
          end;
        end
        else
          if TileInMapCoords(aLoc.X+K-3-gRes.Houses[aHouseType].EntranceOffsetX,aLoc.Y+I-4, 0) then
            MarkPoint(KMPoint(aLoc.X+K-3-gRes.Houses[aHouseType].EntranceOffsetX,aLoc.Y+I-4), TC_BLOCK);
      end;
end;


function TKMTerrain.WaterHasFish(const aLoc: TKMPoint): Boolean;
begin
  Result := (gHands.PlayerAnimals.GetFishInWaterBody(Land^[aLoc.Y,aLoc.X].WalkConnect[wcFish],false) <> nil);
end;


function TKMTerrain.CatchFish(aLoc: TKMPointDir; TestOnly: Boolean = False): Boolean;
var
  myFish: TKMUnitAnimal;
begin
  //Here we are catching fish in the tile 1 in the direction
  aLoc.Loc := KMGetPointInDir(aLoc.Loc, aLoc.Dir);
  myFish := gHands.PlayerAnimals.GetFishInWaterBody(Land^[aLoc.Loc.Y, aLoc.Loc.X].WalkConnect[wcFish], not TestOnly);
  Result := (myFish <> nil);
  if (not TestOnly) and (myFish <> nil) then myFish.ReduceFish; //This will reduce the count or kill it (if they're all gone)
end;


procedure TKMTerrain.SetObject(const Loc: TKMPoint; ID: Integer);
var
  isObjectSet: Boolean;
begin
  isObjectSet := False;
  case ID of
    // Special cases for corn fields 
    58: if TileIsCornField(Loc) and (GetCornStage(Loc) <> 4) then
        begin
          SetField(Loc, Land^[Loc.Y,Loc.X].TileOwner, ftCorn, 4, False);
          isObjectSet := True;
        end;
    59: if TileIsCornField(Loc) and (GetCornStage(Loc) <> 4) then
        begin
          SetField(Loc, Land^[Loc.Y,Loc.X].TileOwner, ftCorn, 5, False);
          isObjectSet := True;
        end
  end;

  if not isObjectSet then
  begin
    Land^[Loc.Y,Loc.X].Obj := ID;
    Land^[Loc.Y,Loc.X].TreeAge := 1;

    //Add 1 tile on sides because surrounding tiles will be affected (CanPlantTrees)
    UpdatePassability(KMRectGrow(KMRect(Loc), 1));

    //Tree could have blocked the only diagonal passage
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(Loc)), True); //Trees block diagonal
  end;
end;


// Set Tile Overlay
//todo: Do not update walkConnect and passability multiple times here
procedure TKMTerrain.SetOverlay(const Loc: TKMPoint; aOverlay: TKMTileOverlay; aOverwrite: Boolean);
var
  changed: Boolean;
begin
  if not TileInMapCoords(Loc.X, Loc.Y) then Exit;

  if aOverlay = toRoad then
  begin
    SetRoad(Loc, PLAYER_NONE);
    Exit;
  end;

  changed := False;

  if aOverwrite then
  begin
    if CanAddField(Loc.X, Loc.Y, ftRoad)                       //Can we add road
      or ((Land^[Loc.Y, Loc.X].TileOverlay = toRoad)
          and (gHands.HousesHitTest(Loc.X, Loc.Y) = nil)) then //or Can we destroy road
    begin
      if Land^[Loc.Y, Loc.X].TileOverlay = toRoad then
        RemRoad(Loc);

      Land^[Loc.Y, Loc.X].TileOverlay := aOverlay;

      if fMapEditor then
        gGame.MapEditor.LandMapEd^[Loc.Y, Loc.X].CornOrWine := 0;

      UpdateFences(Loc);

      if (aOverlay in ROAD_LIKE_OVERLAYS) and gMapElements[Land^[Loc.Y, Loc.X].Obj].WineOrCorn then
        RemoveObject(Loc);

      changed := True;
    end;
  end
  else
  begin
    if CanAddField(Loc.X, Loc.Y, ftRoad)
      and not TileIsWineField(KMPoint(Loc.X, Loc.Y))
      and not TileIsCornField(KMPoint(Loc.X, Loc.Y)) then
    begin
      gTerrain.Land^[Loc.Y, Loc.X].TileOverlay := aOverlay;
      changed := True;
    end;
  end;

  if changed then
  begin
    UpdatePassability(Loc);
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(Loc)), False);
  end;
end;


{Remove the tree and place a falling tree instead}
function TKMTerrain.FallTree(const Loc: TKMPoint): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Length(ChopableTrees) do
    if ChopableTrees[I, caAgeFull] = Land^[Loc.Y,Loc.X].Obj then
    begin
      Land^[Loc.Y,Loc.X].Obj := ChopableTrees[I, caAgeStump];
      //Remember tick when tree was chopped to calc the anim length
      FallingTrees.Add(Loc, ChopableTrees[I, caAgeFall], fAnimStep);
      if gMySpectator.FogOfWar.CheckTileRevelation(Loc.X, Loc.Y) >= 255 then
        gSoundPlayer.Play(sfxTreeDown, Loc, True);

      //Update passability immidiately
      UpdatePassability(KMRectGrow(KMRect(Loc), 1));
      Exit(True);
    end;
end;


{Remove the tree and place stump instead}
procedure TKMTerrain.ChopTree(const Loc: TKMPoint);
var
  H: TKMHouse;
  removeStamp: Boolean;
begin
  Land^[Loc.Y,Loc.X].TreeAge := 0;
  FallingTrees.Remove(Loc);

  // Check if that tree was near house entrance (and stamp will block its entrance)
  //  E       entrance
  //   S      stamp
  removeStamp := False;
  H := gHands.HousesHitTest(Loc.X - 1, Loc.Y - 1);
  if (H <> nil) 
    and (H.Entrance.X = Loc.X - 1)
    and (H.Entrance.Y + 1 = Loc.Y) then
    removeStamp := True;

  if not removeStamp then
  begin
    //  E       entrance
    //  S       stamp
    H := gHands.HousesHitTest(Loc.X, Loc.Y - 1);
    if (H <> nil) 
      and (H.Entrance.X = Loc.X)
      and (H.Entrance.Y + 1 = Loc.Y) then
      removeStamp := True;
  end;

  if removeStamp then
    Land^[Loc.Y,Loc.X].Obj := OBJ_NONE;

  //Update passability after all object manipulations
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));

  //WalkConnect takes diagonal passability into account
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(Loc)), True); //Trees block diagonals
end;


procedure TKMTerrain.RemoveObject(const Loc: TKMPoint);
var
  blockedDiagonal: Boolean;
begin
  if Land^[Loc.Y,Loc.X].Obj <> OBJ_NONE then
  begin
    blockedDiagonal := gMapElements[Land^[Loc.Y,Loc.X].Obj].DiagonalBlocked;
    Land^[Loc.Y,Loc.X].Obj := OBJ_NONE;
    if blockedDiagonal then
      UpdateWalkConnect([wcWalk,wcRoad,wcWork], KMRectGrowTopLeft(KMRect(Loc)), True);
  end;
end;


procedure TKMTerrain.RemoveObjectsKilledByRoad(const Loc: TKMPoint);

  procedure RemoveIfWest(Loc: TKMPoint);
  begin
    if gMapElements[Land^[Loc.Y,Loc.X].Obj].KillByRoad = kbrWest then
      RemoveObject(Loc);
  end;

  procedure KillByRoadCorner(const Loc: TKMPoint);
  begin
    // Check object type first, cos checking roads is more expensive
    if (gMapElements[Land^[Loc.Y,Loc.X].Obj].KillByRoad = kbrNWCorner)
      and (TileHasRoad(Loc.X - 1, Loc.Y)) and (TileHasRoad(Loc.X - 1, Loc.Y - 1))
      and (TileHasRoad(Loc.X, Loc.Y - 1)) and (TileHasRoad(Loc.X, Loc.Y)) then
      RemoveObject(Loc);
  end;
begin
  // Objects killed when surrounded with road on all 4 sides
  // Check for quads this tile affects
  KillByRoadCorner(Loc);
  KillByRoadCorner(KMPoint(Loc.X + 1, Loc.Y));
  KillByRoadCorner(KMPoint(Loc.X, Loc.Y + 1));
  KillByRoadCorner(KMPoint(Loc.X + 1, Loc.Y + 1));

  // Objects killed by roads on sides only
  // Check 2 tiles this tile affects
  if TileHasRoad(Loc.X - 1, Loc.Y) then
    RemoveIfWest(Loc);
  if TileHasRoad(Loc.X + 1, Loc.Y) then
    RemoveIfWest(KMPoint(Loc.X + 1, Loc.Y));
end;


procedure TKMTerrain.SowCorn(const Loc: TKMPoint);
begin
  Land^[Loc.Y,Loc.X].FieldAge := 1;
  Land^[Loc.Y,Loc.X].BaseLayer.Terrain  := 61; //Plant it right away, don't wait for update state
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));
end;


function TKMTerrain.CutCorn(const Loc: TKMPoint): Boolean;
begin
  Result := TileIsCornField(Loc) and (GetCornStage(Loc) = 5); //todo: refactor: use enum instead of magic numbers !
  if not Result then Exit; //We have no corn here actually, nothing to cut
  
  Land^[Loc.Y,Loc.X].FieldAge := 0;
  Land^[Loc.Y,Loc.X].BaseLayer.Terrain  := 63;
  Land^[Loc.Y,Loc.X].Obj := OBJ_NONE;
end;


function TKMTerrain.CutGrapes(const Loc: TKMPoint): Boolean;
begin
  Result := TileIsWineField(Loc) and (GetWineStage(Loc) = 3);
  if not Result then Exit; //We have no wine here actually, nothing to cut
  
  Land^[Loc.Y,Loc.X].FieldAge := 1;
  Land^[Loc.Y,Loc.X].Obj := 54; //Reset the grapes
end;


procedure TKMTerrain.SetFieldNoUpdate(const Loc: TKMPoint; aOwner: TKMHandID; aFieldType: TKMFieldType; aStage: Byte = 0);
begin
  SetField(Loc, aOwner, aFieldType, aStage, False, False, True, False);
end;


procedure TKMTerrain.SetField(const Loc: TKMPoint; aOwner: TKMHandID; aFieldType: TKMFieldType; aStage: Byte = 0;
                              aRandomAge: Boolean = False; aKeepOldObject: Boolean = False; aRemoveOverlay: Boolean = True;
                              aDoUpdate: Boolean = True);

  procedure SetLand(aFieldAge: Byte; aTerrain: Byte; aObj: Integer = -1);
  begin
    Land^[Loc.Y, Loc.X].FieldAge := aFieldAge;

    if fMapEditor then
      gGame.MapEditor.LandMapEd^[Loc.Y, Loc.X].CornOrWineTerrain := aTerrain
    else begin
      Land^[Loc.Y, Loc.X].BaseLayer.Terrain := aTerrain;
      Land^[Loc.Y, Loc.X].BaseLayer.Rotation := 0;
      Land^[Loc.Y, Loc.X].LayersCnt := 0; //Do not show transitions under corn/wine field
    end;

    if aObj <> -1 then
      Land^[Loc.Y,Loc.X].Obj := aObj;
  end;

  function GetObj: Integer;
  begin
    Result := -1;
    if aFieldType = ftCorn then
    begin
      if not aKeepOldObject //Keep old object, when loading from script via old SetField command
        and ((Land[Loc.Y,Loc.X].Obj = 58) or (Land^[Loc.Y,Loc.X].Obj = 59)) then
        Result := OBJ_NONE;
    end;
  end;

var
  fieldAge: Byte;
begin
  Assert(aFieldType in [ftCorn, ftWine], 'SetField is allowed to use only for corn or wine.');

  SetField_Init(Loc, aOwner, aRemoveOverlay);

  if (aFieldType = ftCorn)
    and (InRange(aStage, 0, CORN_STAGES_COUNT - 1)) then
  begin
    if fMapEditor then
      gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWine := 1;

    case aStage of
      0:  SetLand(0, 62, GetObj); //empty field

      1:  begin //Sow corn
            fieldAge := 1 + Ord(aRandomAge) * KaMRandom((CORN_AGE_1 - 1) div 2, 'TKMTerrain.SetField');
            SetLand(fieldAge, 61, GetObj);
          end;

      2:  begin //Young seedings
            fieldAge := CORN_AGE_1 + Ord(aRandomAge) * KaMRandom((CORN_AGE_2 - CORN_AGE_1) div 2, 'TKMTerrain.SetField 2');
            SetLand(fieldAge, 59, OBJ_NONE);
          end;

      3:  begin //Seedings
            fieldAge := CORN_AGE_2 + Ord(aRandomAge) * KaMRandom((CORN_AGE_3 - CORN_AGE_2) div 2, 'TKMTerrain.SetField 3');
            SetLand(fieldAge, 60, OBJ_NONE);
          end;

      4:  begin //Smaller greenish Corn
            fieldAge := CORN_AGE_3 + Ord(aRandomAge) * KaMRandom((CORN_AGE_FULL - CORN_AGE_3) div 2, 'TKMTerrain.SetField 4');
            SetLand(fieldAge, 60, 58);
          end;

      5:  begin //Full-grown Corn
            fieldAge := CORN_AGE_FULL - 1; //-1 because it is increased in update state, otherwise it wouldn't be noticed
            SetLand(fieldAge, 60, 59);
          end;

      6:  SetLand(0, 63, OBJ_NONE); //Corn has been cut
    end;
  end;

  if (aFieldType = ftWine)
    and (InRange(aStage, 0, WINE_STAGES_COUNT - 1)) then
  begin
    if fMapEditor then
      gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWine := 2;

    case aStage of
      0:  begin //Set new fruits
            fieldAge := 1 + Ord(aRandomAge) * KaMRandom((WINE_AGE_1 - 1) div 2, 'TKMTerrain.SetField 5');
            SetLand(fieldAge, WINE_TERRAIN_ID, 54);
          end;

      1:  begin //Fruits start to grow
            fieldAge := WINE_AGE_1 + Ord(aRandomAge) * KaMRandom((WINE_AGE_1 - WINE_AGE_1) div 2, 'TKMTerrain.SetField 6');
            SetLand(fieldAge, WINE_TERRAIN_ID, 55);
          end;

      2:  begin //Fruits continue to grow
            fieldAge := WINE_AGE_2 + Ord(aRandomAge) * KaMRandom((WINE_AGE_FULL - WINE_AGE_2) div 2, 'TKMTerrain.SetField 7');
            SetLand(fieldAge, WINE_TERRAIN_ID, 56);
          end;

      3:  begin //Ready to be harvested
            fieldAge := WINE_AGE_FULL - 1; //-1 because it is increased in update state, otherwise it wouldn't be noticed
            SetLand(fieldAge, WINE_TERRAIN_ID, 57);
          end;
    end;
  end;

  if aDoUpdate then
    SetField_Complete(Loc, aFieldType);

  if (aFieldType = ftWine) then
    gScriptEvents.ProcWinefieldBuilt(aOwner, Loc.X, Loc.Y)
  else if (aFieldType = ftCorn) then
    gScriptEvents.ProcFieldBuilt(aOwner, Loc.X, Loc.Y);
end;


{Extract one unit of stone}
function TKMTerrain.DecStoneDeposit(const Loc: TKMPoint): Boolean;
type
  TStoneTransitionType = (sttNone, sttGrass, sttCoastSand, sttDirt, sttSnow, sttSnowOnDirt);

const
  TransitionsTerKinds: array[TStoneTransitionType] of TKMTerrainKind =
                                                      (tkGrass, tkGrass, tkCoastSand, tkDirt, tkSnow, tkSnowOnDirt);
  TranTiles: array[TStoneTransitionType] of array[0..6] of Word =
              ((  0, 139, 138, 140, 141, 274, 301),
               (  0, 139, 138, 140, 141, 274, 301),
               ( 32, 269, 268, 270, 271, 273, 302),
               ( 35, 278, 277, 279, 280, 282, 303),
               ( 46, 286, 285, 287, 288, 290, 304),
               ( 47, 294, 293, 295, 296, 298, 305));

  TileIDIndex: array[1..14] of Word = (1,1,2,1,3,2,4,1,2,3,4,2,4,4);
  RotID:       array[1..14] of Byte = (0,1,0,2,0,1,3,3,3,1,2,2,1,0);
  TileIDDiagIndex: array[1..15] of Word = (5,5,6,5,5,6,5,5,6,5,5,6,5,5,5);
  RotIdDiag:       array[1..15] of Byte = (3,0,0,1,3,1,3,2,3,0,0,2,0,0,0);

  NO_REPL = High(Word);
  WaterDiagRepl: array[TStoneTransitionType] of Word =
              (127, 127, 118, 105, NO_REPL, NO_REPL);

  WaterDiagReplRot: array[TStoneTransitionType] of Byte =
              (1, 1, 1, 3, 100, 100);

  MAX_STEPS = 5; //steps limit

var
  Visited: TKMPointArray;
  fVisitedCnt: Integer;

  procedure InitVisited;
  begin
    SetLength(Visited, 8);
    fVisitedCnt := 0;
  end;

  procedure AddToVisited(X,Y: Word);
  begin
    if Length(Visited) = fVisitedCnt then
      SetLength(Visited, fVisitedCnt + 8);

    Visited[fVisitedCnt] := KMPoint(X,Y);
    Inc(fVisitedCnt);
  end;

  function GetTile(aTransitionType: TStoneTransitionType; aTileIdIndex: Byte): Word;
  begin
    if aTileIdIndex = 0 then
      Result := TKMTerrainPainter.GetRandomTile(TransitionsTerKinds[aTransitionType])
    else
      Result := TranTiles[aTransitionType, aTileIdIndex];

  end;

  function GetStoneTransitionType(X, Y: Word): TStoneTransitionType;
  begin
    Result := sttNone;
    case Land^[Y,X].BaseLayer.Terrain of
      0, 138,139,140,141,142,274,301:  Result := sttGrass;
      32,268,269,270,271,272,273,302:  Result := sttCoastSand;
      35,277,278,279,280,281,282,303:  Result := sttDirt;
      46,285,286,287,288,289,290,304:  Result := sttSnow;
      47,293,294,295,296,297,298,305:  Result := sttSnowOnDirt;
    end;
  end;

  function UpdateTransition(X,Y: Integer; aStep: Byte): Boolean;

    function GetBits(aX,aY: Integer; aTransition: TStoneTransitionType; aDir: TKMDirection = dirNA): Byte;
    var
      dir: TKMDirection;
    begin
      if not TileInMapCoords(aX, aY) then Exit(0);

      dir := dirNA;
      //if tile has no other terrain types, then check if it has stone, via dirNA
      //otherwise check only tile corners, usign direction
      if not TileHasOnlyTerrainKinds(aX, aY, [tkStone, TransitionsTerKinds[aTransition]]) then
        dir := aDir;

      //Check is there anything stone-related (stone tile or corner at least)
      Result := Byte(TileHasTerrainKindPart(aX, aY, tkStone, dir));
    end;

  var
    transition: TStoneTransitionType;
    bits, bitsDiag: Byte;
    terRot, repl: Integer;
  begin
    Result := False;
    if not TileInMapCoords(X,Y) //Skip for tiles not in map coords
      or (aStep > MAX_STEPS)  //Limit for steps (no limit for now)
      or TileHasStone(X,Y)      //If tile has stone no need to change it
      or ArrayContains(KMPoint(X,Y), Visited, fVisitedCnt) //If we already changed this tile
      or ((aStep <> 0) and not TileHasTerrainKindPart(X, Y, tkStone)) //If tile has no stone parts (except initial step)
      or not TileHasOnlyTerrainKinds(X, Y, [tkStone, tkGrass, tkCoastSand, tkDirt, tkSnow, tkSnowOnDirt]) then //Do not update transitions with other terrains (mountains f.e.)
      Exit;

    transition := GetStoneTransitionType(X,Y);

    bits := GetBits(X  , Y-1, transition, dirS)*1 +
            GetBits(X+1, Y  , transition, dirW)*2 +
            GetBits(X  , Y+1, transition, dirN)*4 +
            GetBits(X-1, Y  , transition, dirE)*8;

    if bits = 0 then
    begin
      bitsDiag := GetBits(X-1, Y-1, transition, dirSE)*1 +
                  GetBits(X+1, Y-1, transition, dirSW)*2 +
                  GetBits(X+1, Y+1, transition, dirNW)*4 +
                  GetBits(X-1, Y+1, transition, dirNE)*8;

      //This part is not actually used, looks like
      case Land^[Y,X].BaseLayer.Terrain of
        142,
        143:  begin
                terRot := (Land[Y,X].BaseLayer.Terrain + Land^[Y,X].BaseLayer.Rotation) mod 4;
                case terRot of
                  0,1:  Exit;
                  2,3:  begin
                          repl := WaterDiagRepl[transition];
                          if repl <> NO_REPL then
                          begin
                            Land^[Y,X].BaseLayer.Terrain := repl;
                            Land^[Y,X].BaseLayer.Rotation := (terRot + WaterDiagReplRot[transition]) mod 4;
                          end
                          else
                          begin
                            Land^[Y,X].BaseLayer.Terrain := 192;
                            Land^[Y,X].BaseLayer.SetCorners([1]);
                            Land^[Y,X].LayersCnt := 1;
                            Land^[Y,X].Layer[0].Terrain := gGenTerrainTransitions[TransitionsTerKinds[transition],
                                                                                 mkSoft2, mt_2Diagonal, mstMain];
                            Land^[Y,X].Layer[0].Rotation := terRot;
                            Land^[Y,X].Layer[0].SetCorners([0,2,3]);
                          end;
                        end;
                end;
              end;
        else
        begin
          if bitsDiag = 0 then
          begin
            Land^[Y,X].BaseLayer.Terrain  := TKMTerrainPainter.GetRandomTile(TransitionsTerKinds[transition]);
            Land^[Y,X].BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.DecStoneDeposit.UpdateTransition'); //Randomise the direction of no-stone terrain tiles
          end else begin
            if Land^[Y,X].BaseLayer.Terrain in [142,143] then
              Exit;
            Land^[Y,X].BaseLayer.Terrain := TranTiles[transition, TileIDDiagIndex[bitsDiag]];
            Land^[Y,X].BaseLayer.Rotation := RotIdDiag[bitsDiag];
          end;
        end;
      end;
    end else
    begin
      if Land^[Y,X].BaseLayer.Terrain in [142,143] then
        Exit;
      
      //If tile is surrounded with other stone tiles no need to change it
      if bits <> 15 then
      begin
        Land^[Y,X].BaseLayer.Terrain  := TranTiles[transition, TileIDIndex[bits]];
        Land^[Y,X].BaseLayer.Rotation := RotID[bits];
      end;
    end;
    UpdatePassability(KMPoint(X,Y));
    AddToVisited(X,Y);

    //Floodfill through around tiles
    UpdateTransition(X,  Y-1, aStep + 1); //  x x x
    UpdateTransition(X+1,Y,   aStep + 1); //  x   x
    UpdateTransition(X,  Y+1, aStep + 1); //  x x x
    UpdateTransition(X-1,Y,   aStep + 1);
    UpdateTransition(X-1,Y-1, aStep + 1);
    UpdateTransition(X+1,Y-1, aStep + 1);
    UpdateTransition(X+1,Y+1, aStep + 1);
    UpdateTransition(X-1,Y+1, aStep + 1);
  end;

var
  transition: TStoneTransitionType;
begin
  transition := GetStoneTransitionType(Loc.X,Loc.Y + 1); //Check transition type by lower point (Y + 1)

  Result := True;
  //Replace with smaller ore deposit tile (there are 2 sets of tiles, we can choose random)
   case Land^[Loc.Y,Loc.X].BaseLayer.Terrain of
    132, 137: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 131 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit')*5;
    131, 136: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 130 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 2')*5;
    130, 135: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 129 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 3')*5;
    129, 134: case transition of
                sttNone,
                sttGrass:       Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 128 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 4')*5;
                sttCoastSand:   Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 266 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 5');
                sttDirt:        Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 275 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 6');
                sttSnow:        Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 283 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 7');
                sttSnowOnDirt:  Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 291 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 8');
              end;
    128, 133,
    266, 267,
    275, 276,
    283, 284,
    291, 292: begin
                Land^[Loc.Y,Loc.X].BaseLayer.Terrain  := TranTiles[transition, 0]; //Remove stone tile (so tile will have no stone)
                Land^[Loc.Y,Loc.X].BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.DecStoneDeposit 9');

                InitVisited;
                //Tile type has changed and we need to update these 5 tiles transitions:
                UpdateTransition(Loc.X,  Loc.Y, 0);
              end;
    else      Exit(False);
  end;

  FlattenTerrain(Loc, True, True); //Ignore canElevate since it can prevent stonehill from being still walkable and cause a crash
end;


{ Try to extract one unit of ore
  It may fail cos of two miners mining the same last piece of ore }
function TKMTerrain.DecOreDeposit(const Loc: TKMPoint; rt: TKMWareType): Boolean;
begin
  if not (rt in [wtIronOre,wtGoldOre,wtCoal]) then
    raise ELocError.Create('Wrong ore decrease',Loc);

  Result := true;
  case Land^[Loc.Y,Loc.X].BaseLayer.Terrain of
    144: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 157 + KaMRandom(3, 'TKMTerrain.DecOreDeposit'); //Gold
    145: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 144;
    146: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 145;
    147: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 146;
    307: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 147;
    148: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 160 + KaMRandom(4, 'TKMTerrain.DecOreDeposit 2'); //Iron
    149: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 148;
    150: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 149;
    259: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 149;
    151: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 150 + KaMRandom(2, 'TKMTerrain.DecOreDeposit 3')*(259 - 150);
    260: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 151;
    152: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 35  + KaMRandom(2, 'TKMTerrain.DecOreDeposit 4'); //Coal
    153: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 152;
    154: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 153;
    155: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 154;
    263: Land^[Loc.Y,Loc.X].BaseLayer.Terrain := 155;
    else Result := false;
  end;
  Land^[Loc.Y,Loc.X].BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.DecOreDeposit 5');
  UpdatePassability(Loc);
end;


procedure TKMTerrain.UpdatePassability(const Loc: TKMPoint);

  procedure AddPassability(aPass: TKMTerrainPassability);
  begin
    Land[Loc.Y,Loc.X].Passability := Land^[Loc.Y,Loc.X].Passability + [aPass];
  end;

var
  I, K: Integer;
  hasHousesNearTile, housesNearVertex, isBuildNoObj: Boolean;
begin
  Assert(TileInMapCoords(Loc.X, Loc.Y)); //First of all exclude all tiles outside of actual map

  Land^[Loc.Y,Loc.X].Passability := [];

  if TileIsWalkable(Loc)
    and not gMapElements[Land^[Loc.Y,Loc.X].Obj].AllBlocked
    and CheckHeightPass(Loc, hpWalking) then
    AddPassability(tpOwn);

  //For all passability types other than CanAll, houses and fenced houses are excluded
  if Land^[Loc.Y,Loc.X].TileLock in [tlNone, tlFenced, tlFieldWork, tlRoadWork] then
  begin
    if TileIsWalkable(Loc)
      and not gMapElements[Land^[Loc.Y,Loc.X].Obj].AllBlocked
      and CheckHeightPass(Loc, hpWalking) then
      AddPassability(tpWalk);

    if (Land^[Loc.Y,Loc.X].TileOverlay = toRoad)
    and (tpWalk in Land^[Loc.Y,Loc.X].Passability) then //Not all roads are walkable, they must also have CanWalk passability
      AddPassability(tpWalkRoad);

    //Check for houses around this tile/vertex
    hasHousesNearTile := False;
    for I := -1 to 1 do
      for K := -1 to 1 do
        if TileInMapCoords(Loc.X+K, Loc.Y+I)
          and (Land^[Loc.Y+I,Loc.X+K].TileLock in [tlFenced,tlDigged,tlHouse]) then
          hasHousesNearTile := True;

    isBuildNoObj := False;
    if TileIsRoadable(Loc)
      and not TileIsCornField(Loc) //Can't build houses on fields
      and not TileIsWineField(Loc)
      and (Land^[Loc.Y,Loc.X].TileLock = tlNone)
      and TileInMapCoords(Loc.X, Loc.Y, 1)
      and CheckHeightPass(Loc, hpBuilding) then
    begin
      AddPassability(tpBuildNoObj);
      isBuildNoObj := True;
    end;

    if isBuildNoObj and not hasHousesNearTile
      and((Land[Loc.Y,Loc.X].Obj = OBJ_NONE) or (gMapElements[Land^[Loc.Y,Loc.X].Obj].CanBeRemoved)) then //Only certain objects are excluded
      AddPassability(tpBuild);

    if TileIsRoadable(Loc)
      and not gMapElements[Land^[Loc.Y,Loc.X].Obj].AllBlocked
      and (Land^[Loc.Y,Loc.X].TileLock = tlNone)
      and (Land^[Loc.Y,Loc.X].TileOverlay <> toRoad)
      and CheckHeightPass(Loc, hpWalking) then
      AddPassability(tpMakeRoads);

    if ObjectIsChopableTree(Loc, [caAge1, caAge2, caAge3, caAgeFull]) then
      AddPassability(tpCutTree);

    if TileIsWater(Loc) then
      AddPassability(tpFish);

    if TileIsSand(Loc)
      and not gMapElements[Land^[Loc.Y,Loc.X].Obj].AllBlocked
      //TileLock checked in outer begin/end
      and not (Land^[Loc.Y,Loc.X].TileOverlay in ROAD_LIKE_OVERLAYS)
      and not TileIsCornField(Loc)
      and not TileIsWineField(Loc)
      and CheckHeightPass(Loc, hpWalking) then //Can't crab on houses, fields and roads (can walk on fenced house so you can't kill them by placing a house on top of them)
      AddPassability(tpCrab);

    if TileIsSoil(Loc.X,Loc.Y)
      and not gMapElements[Land^[Loc.Y,Loc.X].Obj].AllBlocked
      //TileLock checked in outer begin/end
      //Wolf are big enough to run over roads, right?
      and not TileIsCornField(Loc)
      and not TileIsWineField(Loc)
      and CheckHeightPass(Loc, hpWalking) then
      AddPassability(tpWolf);
  end;

  if TileIsWalkable(Loc)
    and not gMapElements[Land^[Loc.Y,Loc.X].Obj].AllBlocked
    and CheckHeightPass(Loc, hpWalking)
    and (Land^[Loc.Y,Loc.X].TileLock <> tlHouse) then
    AddPassability(tpWorker);

  //Check all 4 corners ter kinds around vertice 
  if VerticeIsFactorable(Loc) then
    AddPassability(tpFactor);

  //Check for houses around this vertice(!)
  //Use only with CanElevate since it's vertice-based!
  housesNearVertex := False;
  for I := -1 to 0 do
    for K := -1 to 0 do
      if TileInMapCoords(Loc.X+K, Loc.Y+I) then
        //Can't elevate built houses, can elevate fenced and dug houses though
        if (Land^[Loc.Y+I,Loc.X+K].TileLock = tlHouse) then
          housesNearVertex := True;

  if VerticeInMapCoords(Loc.X,Loc.Y)
    and not housesNearVertex then
    AddPassability(tpElevate);
end;


//Find closest passable point to TargetPoint within line segment OriginPoint <-> TargetPoint
//MaxDistance - maximum distance between finded point and origin point. MaxDistance = -1 means there is no distance restriction
function TKMTerrain.GetPassablePointWithinSegment(OriginPoint, TargetPoint: TKMPoint;
                                                  aPass: TKMTerrainPassability;
                                                  MaxDistance: Integer = -1): TKMPoint;

  function IsDistBetweenPointsAllowed(const OriginPoint, TargetPoint: TKMPoint; aMaxDistance: Integer): Boolean; inline;
  begin
    Result := (aMaxDistance = -1) or (KMDistanceSqr(OriginPoint, TargetPoint) <= Sqr(aMaxDistance));
  end;

var
  normVector: TKMPoint;
  normDistance: Integer;
begin
  if MaxDistance = -1 then
    normDistance := Floor(KMLength(OriginPoint, TargetPoint))
  else
    normDistance := Min(MaxDistance, Floor(KMLength(OriginPoint, TargetPoint)));

  while (normDistance >= 0)
    and (not IsDistBetweenPointsAllowed(OriginPoint, TargetPoint, MaxDistance)
         or not CheckPassability(TargetPoint, aPass)) do
  begin
    normVector := KMNormVector(KMPoint(TargetPoint.X - OriginPoint.X, TargetPoint.Y - OriginPoint.Y), normDistance);
    TargetPoint := KMPoint(OriginPoint.X + normVector.X, OriginPoint.Y + normVector.Y);
    Dec(normDistance);
  end;
  Result := TargetPoint;
end;


function TKMTerrain.CheckPassability(X, Y: Integer; aPass: TKMTerrainPassability): Boolean;
begin
  Result := TileInMapCoords(X, Y) and (aPass in Land^[Y, X].Passability);
end;


function TKMTerrain.CheckPassability(const Loc: TKMPoint; aPass: TKMTerrainPassability): Boolean;
begin
  Result := TileInMapCoords(Loc.X,Loc.Y) and (aPass in Land^[Loc.Y,Loc.X].Passability);
end;


function TKMTerrain.HasUnit(const Loc: TKMPoint): Boolean;
begin
  Assert(TileInMapCoords(Loc.X,Loc.Y));
  Result := Land^[Loc.Y,Loc.X].IsUnit <> nil;
end;


function TKMTerrain.HasVertexUnit(const Loc: TKMPoint): Boolean;
begin
  Assert(TileInMapCoords(Loc.X,Loc.Y));
  Result := Land^[Loc.Y,Loc.X].IsVertexUnit <> vuNone;
end;


//Check which road connect ID the tile has (to which road network does it belongs to)
function TKMTerrain.GetRoadConnectID(const Loc: TKMPoint): Byte;
begin
  Result := GetConnectID(wcRoad, Loc);
end;


//Check which walk connect ID the tile has (to which walk network does it belongs to)
function TKMTerrain.GetWalkConnectID(const Loc: TKMPoint): Byte;
begin
  Result := GetConnectID(wcWalk, Loc);
end;


function TKMTerrain.GetConnectID(aWalkConnect: TKMWalkConnect; const Loc: TKMPoint): Byte;
begin
  if TileInMapCoords(Loc.X,Loc.Y) then
    Result := Land^[Loc.Y,Loc.X].WalkConnect[aWalkConnect]
  else
    Result := 0; //No network
end;


function TKMTerrain.CheckAnimalIsStuck(const Loc: TKMPoint; aPass: TKMTerrainPassability; aCheckUnits: Boolean = True): Boolean;
var
  I,K: integer;
begin
  Result := True; //Assume we are stuck
  for I := -1 to 1 do for K := -1 to 1 do
    if (I <> 0) or (K <> 0) then
      if TileInMapCoords(Loc.X+K,Loc.Y+I) then
        if CanWalkDiagonaly(Loc, Loc.X+K, Loc.Y+I) then
          if (Land^[Loc.Y+I,Loc.X+K].IsUnit = nil) or (not aCheckUnits) then
            if aPass in Land^[Loc.Y+I,Loc.X+K].Passability then
            begin
              Result := false; //at least one tile is empty, so unit is not stuck
              exit;
            end;
end;


// Return random tile surrounding Loc with aPass property. PusherLoc is the unit that pushed us
// which is preferable to other units (otherwise we can get two units swapping places forever)
function TKMTerrain.GetOutOfTheWay(aUnit: Pointer; const PusherLoc: TKMPoint; aPass: TKMTerrainPassability; aPusherWasPushed: Boolean = False): TKMPoint;
var
  U: TKMUnit;
  loc: TKMPoint;

  function GoodForBuilder(X,Y: Word): Boolean;
  var
    DistNext: Single;
  begin
    DistNext := gHands.DistanceToEnemyTowers(KMPoint(X,Y), U.Owner);
    Result := (DistNext > RANGE_WATCHTOWER_MAX)
      or (DistNext >= gHands.DistanceToEnemyTowers(loc, U.Owner));
  end;
var
  I, K: Integer;
  tx, ty: Integer;
  isFree, isOffroad, isPushable, exchWithPushedPusher, exchWithPushedPusherChoosen: Boolean;
  newWeight, bestWeight: Single;
  tempUnit: TKMUnit;
begin
  U := TKMUnit(aUnit);
  loc := U.Position;

  Result := loc;
  bestWeight := -1e30;
  exchWithPushedPusherChoosen := False;

  // Check all available walkable positions except self
  for I := -1 to 1 do for K := -1 to 1 do
  if (I <> 0) or (K <> 0) then
    begin
      tx := loc.X + K;
      ty := loc.Y + I;

      if TileInMapCoords(tx, ty)
        and CanWalkDiagonaly(loc, tx, ty) //Check for trees that stop us walking on the diagonals!
        and (Land^[ty,tx].TileLock in [tlNone, tlFenced])
        and (aPass in Land^[ty,tx].Passability)
        and (not (U is TKMUnitWorker) or GoodForBuilder(tx, ty)) then
      begin
        // Try to be pushed to empty tiles
        isFree := Land^[ty, tx].IsUnit = nil;

        // Try to be pushed out to non-road tiles when possible
        isOffroad := False;//not TileHasRoad(tx, ty);

        // Try to be pushed to exchange with pusher or to push other non-locked units
        isPushable := False;
        exchWithPushedPusher := False;
        if Land^[ty, tx].IsUnit <> nil then
        begin
          tempUnit := UnitsHitTest(tx, ty);
          // Always include the pushers loc in the possibilities, otherwise we can get two units swapping places forever
          if (KMPoint(tx, ty) = PusherLoc) then
          begin
            //Check if we try to exchange with pusher, who was also pushed (that is non-profitable exchange)
            //We want to avoid it
            if aPusherWasPushed then
              exchWithPushedPusher := True //Mark that tile to exchange with pusher
            else
              isPushable := True;
          end
          else
            if ((tempUnit <> nil) and (tempUnit.Action is TKMUnitActionStay)
              and (not TKMUnitActionStay(tempUnit.Action).Locked)) then
              isPushable := True;
        end;
        newWeight := 40*Ord(isFree)
                      + Ord(isOffroad)
                      + Ord(isPushable)
                      - 0.3*Land^[ty,tx].JamMeter
                      + 2*KaMRandom('TKMTerrain.GetOutOfTheWay');

        if newWeight > bestWeight then
        begin
          bestWeight := newWeight;
          Result := KMPoint(tx, ty);
          exchWithPushedPusherChoosen := exchWithPushedPusher;
        end;
      end;
    end;
  //Punish very bad positions, where we decided to exchange with pushed pusher's loc
  //(non-profitable exchange was choosen as the only possibility), so we will mark this pos as very unpleasant
  if exchWithPushedPusherChoosen then
    Land^[loc.Y, loc.X].IncJamMeter(50);
end;


function TKMTerrain.FindSideStepPosition(const Loc,Loc2,Loc3: TKMPoint; aPass: TKMTerrainPassability; out SidePoint: TKMPoint; OnlyTakeBest: Boolean = False): Boolean;
var
  I, K: Integer;
  L1, L2: TKMPointList;
begin
  //List 1 holds all positions next to both Loc and Loc2
  L1 := TKMPointList.Create;
  for I := -1 to 1 do
  for K := -1 to 1 do
    if ((I <> 0) or (K <> 0))
    and TileInMapCoords(Loc.X+K,Loc.Y+I)
    and not KMSamePoint(KMPoint(Loc.X+K,Loc.Y+I), Loc2)
    and (aPass in Land^[Loc.Y+I,Loc.X+K].Passability)
    and CanWalkDiagonaly(Loc, Loc.X+K, Loc.Y+I) //Check for trees that stop us walking on the diagonals!
    and (Land^[Loc.Y+I,Loc.X+K].TileLock in [tlNone, tlFenced])
    and (KMLengthDiag(Loc.X+K, Loc.Y+I, Loc2) <= 1) //Right next to Loc2 (not diagonal)
    and not HasUnit(KMPoint(Loc.X+K,Loc.Y+I)) then //Doesn't have a unit
      L1.Add(KMPoint(Loc.X+K,Loc.Y+I));

  //List 2 holds the best positions, ones which are also next to Loc3 (next position)
  L2 := TKMPointList.Create;
  if not KMSamePoint(Loc3, KMPOINT_ZERO) then //No Loc3 was given
  for I := 0 to L1.Count - 1 do
    if KMLengthDiag(L1[I], Loc3) < 1.5 then //Next to Loc3 (diagonal is ok)
      L2.Add(L1[I]);

  Result := True;
  if not(L2.GetRandom(SidePoint)) then
  if (OnlyTakeBest) or (not(L1.GetRandom(SidePoint))) then
    Result := False; //No side step positions available

  L1.Free;
  L2.Free;
end;


//Test wherever it is possible to make the route without actually making it to save performance
function TKMTerrain.Route_CanBeMade(const LocA, LocB: TKMPoint; aPass: TKMTerrainPassability; aDistance: Single): Boolean;
var
  I, K: Integer;
  testRadius: Boolean;
  distanceSqr: Single;
  WC: TKMWalkConnect;
begin
  Result := True;

  //target has to be different point than source
  //Result:=not (KMSamePoint(LocA,LocB)); //Or maybe we don't care

  //Source point has to be walkable
  Result := Result and CheckPassability(LocA, aPass);

  if not Result then
    Exit;

  //Target has to be walkable within Distance
  testRadius := False;
  distanceSqr := Sqr(aDistance);
  for I := Max(round(LocB.Y - aDistance), 1) to Min(Round(LocB.Y + aDistance), fMapY - 1) do
    for K := Max(round(LocB.X - aDistance), 1) to Min(Round(LocB.X + aDistance), fMapX - 1) do
      if KMLengthSqr(LocB, KMPoint(K, I)) <= distanceSqr then
        testRadius := testRadius or CheckPassability(KMPoint(K, I), aPass);

  Result := Result and testRadius;

  if not Result then
    Exit;

  case aPass of
    tpWalk:      WC := wcWalk;
    tpWalkRoad:  WC := wcRoad;
    tpFish:      WC := wcFish;
    tpWorker:    WC := wcWork;
    else Exit;
  end;

  {if WC = wcWork then
  with TBitmap.Create do
  begin
    Width := fMapX;
    Height:= fMapY;
    PixelFormat := pf32bit;
    for I := 0 to Height-1 do
      for K := 0 to Width-1 do
        Canvas.Pixels[K,I] := Land^[I+1,K+1].WalkConnect[wcWork] * 32;
    SaveToFile(ExeDir + 'wcWork.bmp');
    Free;
  end;}

  //Walkable way between A and B is proved by FloodFill
  testRadius := False;
  for I := Max(Round(LocB.Y - aDistance), 1) to Min(Round(LocB.Y + aDistance), fMapY-1) do
    for K := Max(Round(LocB.X - aDistance), 1) to Min(Round(LocB.X + aDistance), fMapX-1) do
      if KMLengthSqr(LocB,KMPoint(K, I)) <= distanceSqr then
        testRadius := testRadius or (Land[LocA.Y,LocA.X].WalkConnect[WC] = Land^[i,k].WalkConnect[WC]);

  Result := Result and testRadius;
end;


//Check if a route can be made to this vertex, from any direction (used for woodcutter cutting trees)
function TKMTerrain.Route_CanBeMadeToVertex(const LocA, LocB: TKMPoint; aPass: TKMTerrainPassability): Boolean;
var
  I, K: Integer;
begin
  Result := false;
  //Check from top-left of vertex to vertex tile itself
  for I := Max(LocB.Y - 1, 1) to LocB.Y do
    for K := Max(LocB.X - 1, 1) to LocB.X do
      Result := Result or Route_CanBeMade(LocA, KMPoint(K, I), aPass, 0);
end;


//Returns the closest tile to TargetLoc with aPass and walk connect to OriginLoc
//If no tile found - return Origin location
function TKMTerrain.GetClosestTile(const TargetLoc, OriginLoc: TKMPoint; aPass: TKMTerrainPassability; aAcceptTargetLoc: Boolean): TKMPoint;
const
  testDepth = 255;
var
  I, walkConnectID: Integer;
  P: TKMPoint;
  T: TKMPoint;
  wcType: TKMWalkConnect;
begin
  case aPass of
    tpWalkRoad: wcType := wcRoad;
    tpFish:     wcType := wcFish;
    else         wcType := wcWalk; //CanWalk is default
  end;

  walkConnectID := Land^[OriginLoc.Y,OriginLoc.X].WalkConnect[wcType]; //Store WalkConnect ID of origin

  //If target is accessable then use it
  if aAcceptTargetLoc and CheckPassability(TargetLoc, aPass) and (walkConnectID = Land^[TargetLoc.Y,TargetLoc.X].WalkConnect[wcType]) then
  begin
    Result := TargetLoc;
    exit;
  end;

  //If target is not accessable then choose a tile near to the target that is accessable
  //As we Cannot reach our destination we are "low priority" so do not choose a tile with another unit on it (don't bump important units)
  for I := 0 to testDepth do begin
    P := GetPositionFromIndex(TargetLoc, I);
    if not TileInMapCoords(P.X,P.Y) then Continue;
    T := KMPoint(P.X,P.Y);
    if CheckPassability(T, aPass)
      and (walkConnectID = Land^[T.Y,T.X].WalkConnect[wcType])
      and (not HasUnit(T) or KMSamePoint(T,OriginLoc)) //Allow position we are currently on, but not ones with other units
    then
      Exit(T); //Assign if all test are passed
  end;

  Result := OriginLoc; //If we don't find one, return existing Loc
end;


function TKMTerrain.GetClosestRoad(const aFromLoc: TKMPoint; aWalkConnectIDSet: TKMByteSet; aPass: TKMTerrainPassability = tpWalkRoad): TKMPoint;
const
  depth = 255;
var
  I: Integer;
  P: TKMPoint;
  wcType: TKMWalkConnect;
begin
  Result := KMPOINT_INVALID_TILE;

  case aPass of
    tpWalkRoad: wcType := wcRoad;
    tpFish:     wcType := wcFish;
    else        wcType := wcWalk; //CanWalk is default
  end;

  for I := 0 to depth do
  begin
    P := GetPositionFromIndex(aFromLoc, I);
    if not TileInMapCoords(P.X,P.Y) then Continue;
    if CheckPassability(P, aPass)
      and (Land^[P.Y,P.X].WalkConnect[wcType] in aWalkConnectIDSet)
      and Route_CanBeMade(aFromLoc, P, tpWalk, 0)
    then
    begin
      Result := P; //Assign if all test are passed
      Exit;
    end;
  end;
end;


{Mark tile as occupied}
procedure TKMTerrain.UnitAdd(const LocTo: TKMPoint; aUnit: Pointer);
begin
  if not DO_UNIT_INTERACTION then Exit;

  Assert(Land^[LocTo.Y,LocTo.X].IsUnit = nil, 'Tile already occupied at '+TypeToString(LocTo));
  Land^[LocTo.Y,LocTo.X].IsUnit := aUnit
end;


{ Mark tile as empty }
// We have no way of knowing whether a unit is inside a house, or several units exit a house at once
// when exiting the game and destroying all units this will cause asserts.
procedure TKMTerrain.UnitRem(const LocFrom: TKMPoint);
begin
  if not DO_UNIT_INTERACTION then Exit;

  Land^[LocFrom.Y,LocFrom.X].IsUnit := nil;
end;


{Mark previous tile as empty and next one as occupied}
//We need to check both tiles since UnitWalk is called only by WalkTo where both tiles aren't houses
procedure TKMTerrain.UnitWalk(const LocFrom, LocTo: TKMPoint; aUnit: Pointer);
var
  U: TKMUnit;
begin
  if not DO_UNIT_INTERACTION then exit;
  Assert(Land^[LocFrom.Y, LocFrom.X].IsUnit = aUnit, 'Trying to remove wrong unit at '+TypeToString(LocFrom));
  Land^[LocFrom.Y, LocFrom.X].IsUnit := nil;
  Assert(Land^[LocTo.Y, LocTo.X].IsUnit = nil, 'Tile already occupied at '+TypeToString(LocTo));
  Land^[LocTo.Y, LocTo.X].IsUnit := aUnit;

  U := TKMUnit(aUnit);
  if ((U <> nil) and (U is TKMUnitWarrior)) then
    gScriptEvents.ProcWarriorWalked(U, LocTo.X, LocTo.Y);
end;


procedure TKMTerrain.UnitSwap(const LocFrom,LocTo: TKMPoint; UnitFrom: Pointer);
begin
  Assert(Land^[LocFrom.Y,LocFrom.X].IsUnit = UnitFrom, 'Trying to swap wrong unit at '+TypeToString(LocFrom));
  Land[LocFrom.Y,LocFrom.X].IsUnit := Land^[LocTo.Y,LocTo.X].IsUnit;
  Land^[LocTo.Y,LocTo.X].IsUnit := UnitFrom;
end;


{Mark vertex as occupied}
procedure TKMTerrain.UnitVertexAdd(const LocTo: TKMPoint; Usage: TKMVertexUsage);
begin
  if not DO_UNIT_INTERACTION then exit;
  assert(Usage <> vuNone, 'Invalid add vuNone at '+TypeToString(LocTo));
  assert((Land[LocTo.Y,LocTo.X].IsVertexUnit = vuNone) or (Land^[LocTo.Y,LocTo.X].IsVertexUnit = Usage),'Opposite vertex in use at '+TypeToString(LocTo));

  Land^[LocTo.Y,LocTo.X].IsVertexUnit := Usage;
end;


procedure TKMTerrain.UnitVertexAdd(const LocFrom, LocTo: TKMPoint);
begin
  Assert(KMStepIsDiag(LocFrom, LocTo), 'Add non-diagonal vertex?');
  UnitVertexAdd(KMGetDiagVertex(LocFrom, LocTo), GetVertexUsageType(LocFrom, LocTo));
end;


{Mark vertex as empty}
procedure TKMTerrain.UnitVertexRem(const LocFrom: TKMPoint);
begin
  if not DO_UNIT_INTERACTION then exit;
  Land^[LocFrom.Y,LocFrom.X].IsVertexUnit := vuNone;
end;


//This function tells whether the diagonal is "in use". (a bit like IsUnit) So if there is a unit walking on
//the oppsoite diagonal you cannot use the vertex (same diagonal is allowed for passing and fighting)
//It stops units walking diagonally through each other or walking through a diagonal that has weapons swinging through it
function TKMTerrain.VertexUsageCompatible(const LocFrom, LocTo: TKMPoint): Boolean;
var
  vert: TKMPoint;
  vertUsage: TKMVertexUsage;
begin
  Assert(KMStepIsDiag(LocFrom, LocTo));
  vert := KMGetDiagVertex(LocFrom, LocTo);
  vertUsage := GetVertexUsageType(LocFrom, LocTo);
  Result := (Land^[vert.Y, vert.X].IsVertexUnit in [vuNone, vertUsage]);
end;


function TKMTerrain.GetVertexUsageType(const LocFrom, LocTo: TKMPoint): TKMVertexUsage;
var
  dx, dy: integer;
begin
  dx := LocFrom.X - LocTo.X;
  dy := LocFrom.Y - LocTo.Y;
  Assert((abs(dx) = 1) and (abs(dy) = 1));
  if (dx*dy = 1) then Result := vuNWSE
                 else Result := vuNESW;
end;


//todo: Rewrite into controlled recursion to avoid StackOverflows
//@Krom: Stackoverflow usually occurs because keeping mountain walkable with stonemining is
//       sometimes impossible to solve when considering CanElevate (houses near stone).
//       So changing recursion to iteration would just give us an infinite loop in that case :(
//       I've added aIgnoreCanElevate for stonemining only, which means land under houses
//       gets elevated but stops crashes (tested on multiple r5503 crash reports) since
//       now it is possible to keep all tiles walkable by repeatedly flattening.
//       I can't think of a flattening algo that maintains walkability AND CanElevate constraint.
//       It needs major rethinking, rewriting recursion won't solve it.
//Interpolate between 12 vertices surrounding this tile (X and Y, no diagonals)
//Also it is FlattenTerrain duty to preserve walkability if there are units standing
//aIgnoreCanElevate ignores CanElevate constraint which prevents crashes during stonemining (hacky)
procedure TKMTerrain.DoFlattenTerrain(const Loc: TKMPoint; var aDepth: Byte; aUpdateWalkConnects: Boolean; aIgnoreCanElevate: Boolean);
const
  // Max depth of recursion for flatten algorythm to use tpElevate as a restriction
  // After depth goes beyond this value we omit tpElevate restriction and allow to change tiles height under any houses
  // Its needed, because there is still a possibility to get into infinite recursion loop EnsureRange -> DoFlattenTerrain -> EnsureRange -> ...
  FLATTEN_RECUR_USE_ELEVATE_MAX_DEPTH = 16;

  // Max depth of recursion
  // Its quite unlikely, but its possible in thory that we will get into infinite recursion even without tpElevate restriction
  // Limit max number of attempts to Flatten terrain to keep only walkable tiles, to avoid StackOverflow
  FLATTEN_RECUR_MAX_DEPTH = 32;

  //If tiles with units standing on them become unwalkable we should try to fix them
  procedure EnsureWalkable(aX,aY: Word; var aDepth: Byte);
  begin
    //We did not recalculated passability yet, hence tile has CanWalk but CheckHeightPass=False already
    if (tpWalk in Land^[aY,aX].Passability)
    //Yield in TestStone is much better if we comment this out, also general result is flatter/"friendlier"
    //and (Land^[aY,aX].IsUnit <> nil)
    and not CheckHeightPass(KMPoint(aX,aY), hpWalking)
    and not fMapEditor //Allow units to become "stuck" in MapEd, as height changing is allowed anywhere
    then
      //This recursive call should be garanteed to exit, as eventually the terrain will be flat enough
      DoFlattenTerrain(KMPoint(aX,aY), aDepth, False, aIgnoreCanElevate or (aDepth > FLATTEN_RECUR_USE_ELEVATE_MAX_DEPTH)); //WalkConnect should be done at the end
  end;

  function CanElevateAt(aX, aY: Word): Boolean;
  begin
    //Passability does not get set for the row below the bottom/right edges
    Result := aIgnoreCanElevate or (tpElevate in Land^[aY, aX].Passability) or (aX = fMapX) or (aY = fMapY);
  end;

var
  vertsFactored: Integer;

  //Note that we need to access vertices, not tiles
  function GetHeight(aX,aY: Word; Neighbour: Boolean): Byte;
  begin
    if VerticeInMapCoords(aX,aY) and (not Neighbour or (tpFactor in Land^[aY,aX].Passability)) then
    begin
      Result := Land^[aY,aX].Height;
      Inc(vertsFactored);
    end
    else
      Result := 0;
  end;

var
  I, K: Word;
  avg: Word;
begin
  Assert(TileInMapCoords(Loc.X, Loc.Y), 'Can''t flatten tile outside map coordinates');

  Inc(aDepth); //Increase depth

  // Stop flattening after a certain point.
  // Give up on flatten terrain to keep all around tiles walkable if its impossible (or we failed after number of attempts)
  if aDepth > FLATTEN_RECUR_MAX_DEPTH then
    Exit;

  if aUpdateWalkConnects then
    fBoundsWC := KMRect(Loc.X, Loc.Y, Loc.X, Loc.Y);

  //Expand fBoundsWC in case we were called by EnsureWalkable, and fBoundsWC won't know about this tile
  if fBoundsWC.Left > Loc.X - 1 then fBoundsWC.Left := Loc.X - 1;
  if fBoundsWC.Top > Loc.Y - 1 then fBoundsWC.Top := Loc.Y - 1;
  if fBoundsWC.Right < Loc.X + 1 then fBoundsWC.Right := Loc.X + 1;
  if fBoundsWC.Bottom < Loc.Y + 1 then fBoundsWC.Bottom := Loc.Y + 1;

  vertsFactored := 0; //GetHeight will add to this
  avg :=                                   GetHeight(Loc.X,Loc.Y-1,True ) + GetHeight(Loc.X+1,Loc.Y-1,True ) +
         GetHeight(Loc.X-1,Loc.Y  ,True) + GetHeight(Loc.X,Loc.Y  ,False) + GetHeight(Loc.X+1,Loc.Y  ,False) + GetHeight(Loc.X+2,Loc.Y  ,True) +
         GetHeight(Loc.X-1,Loc.Y+1,True) + GetHeight(Loc.X,Loc.Y+1,False) + GetHeight(Loc.X+1,Loc.Y+1,False) + GetHeight(Loc.X+2,Loc.Y+1,True) +
                                           GetHeight(Loc.X,Loc.Y+2,True ) + GetHeight(Loc.X+1,Loc.Y+2,True );
  Assert(vertsFactored <> 0); //Non-neighbour verts will always be factored
  avg := Round(avg / vertsFactored);

  if CanElevateAt(Loc.X  , Loc.Y  ) then
    Land[Loc.Y  ,Loc.X  ].Height := Mix(avg, Land^[Loc.Y  ,Loc.X  ].Height, 0.5);
  if CanElevateAt(Loc.X+1, Loc.Y  ) then
    Land[Loc.Y  ,Loc.X+1].Height := Mix(avg, Land^[Loc.Y  ,Loc.X+1].Height, 0.5);
  if CanElevateAt(Loc.X  , Loc.Y+1) then
    Land[Loc.Y+1,Loc.X  ].Height := Mix(avg, Land^[Loc.Y+1,Loc.X  ].Height, 0.5);
  if CanElevateAt(Loc.X+1, Loc.Y+1) then
    Land[Loc.Y+1,Loc.X+1].Height := Mix(avg, Land^[Loc.Y+1,Loc.X+1].Height, 0.5);

  //All 9 tiles around and including this one could have become unwalkable and made a unit stuck, so check them all
  for I := Max(Loc.Y-1, 1) to Min(Loc.Y+1, fMapY-1) do
    for K := Max(Loc.X-1, 1) to Min(Loc.X+1, fMapX-1) do
      EnsureWalkable(K, I, aDepth);

  UpdateLighting(KMRect(Loc.X-2, Loc.Y-2, Loc.X+3, Loc.Y+3));
  //Changing height will affect the cells around this one
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));

  if aUpdateWalkConnects then
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrow(fBoundsWC, 1), False);
end;


//Flatten terrain loc
procedure TKMTerrain.FlattenTerrain(const Loc: TKMPoint; aUpdateWalkConnects: Boolean = True; aIgnoreCanElevate: Boolean = False);
var
  depth: Byte;
begin
  depth := 0;
  DoFlattenTerrain(Loc, depth, aUpdateWalkConnects, aIgnoreCanElevate);
end;


//Flatten a list of points on mission init
procedure TKMTerrain.FlattenTerrain(LocList: TKMPointList);
var
  I: Integer;
begin
  //Flatten terrain will extend fBoundsWC as necessary, which cannot be predicted due to EnsureWalkable effecting a larger area
  if not LocList.GetBounds(fBoundsWC) then
    Exit;

  for I := 0 to LocList.Count - 1 do
    FlattenTerrain(LocList[I], False); //Rebuild the Walk Connect at the end, rather than every time

  //wcFish not affected by height
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrow(fBoundsWC, 1), False);
end;


procedure TKMTerrain.UpdateLighting;
begin
  UpdateLighting(fMapRect);
end;


//Rebuilds lighting values for given bounds.
//These values are used to draw highlights/shadows on terrain
//Note that input values may be off-map
procedure TKMTerrain.UpdateLighting(const aRect: TKMRect);
var
  I, K: Integer;
begin
  //Valid vertices are within 1..Map
  for I := Max(aRect.Top, 1) to Min(aRect.Bottom, fMapY) do
    for K := Max(aRect.Left, 1) to Min(aRect.Right, fMapX) do
      UpdateLighting(K, I);
end;


procedure TKMTerrain.UpdateLighting(X, Y: Integer);

  function ConvertLightToByte(aSLight: Single): Byte;
  begin
    Result := Round((aSLight + 1) * 127.5);
  end;

var
  x0, y2: Integer;
  sLight, sLightWater: Single;
begin
  x0 := Max(X - 1, 1);
  y2 := Min(Y + 1, fMapY);
  sLight := EnsureRange((Land^[Y,X].RenderHeight - (Land^[y2,X].RenderHeight + Land^[Y,x0].RenderHeight)/2)/22, -1, 1); // 1.33*16 ~=22.
  sLightWater := EnsureRange(sLight*WATER_LIGHT_MULTIPLIER + 0.1, -1, 1);
  Land^[Y,X].Light := ConvertLightToByte(sLight); //  1.33*16 ~=22.

  //Use more contrast lighting for Waterbeds
  if fTileset.TileIsWater(Land^[Y, X].BaseLayer.Terrain) then
    Land^[Y,X].Light := ConvertLightToByte(sLightWater);

  //Map borders always fade to black
  if (Y = 1) or (Y = fMapY) or (X = 1) or (X = fMapX) then
    Land^[Y,X].Light := 0;
end;


//Rebuilds passability for all map
procedure TKMTerrain.UpdatePassability;
begin
  UpdatePassability(fMapRect);
end;


//Rebuilds passability for given bounds
procedure TKMTerrain.UpdatePassability(const aRect: TKMRect);
var
  I, K: Integer;
begin
  for I := Max(aRect.Top, 1) to Min(aRect.Bottom, fMapY - 1) do
    for K := Max(aRect.Left, 1) to Min(aRect.Right, fMapX - 1) do
      UpdatePassability(KMPoint(K, I));
end;


//Rebuilds connected areas using flood fill algorithm
procedure TKMTerrain.UpdateWalkConnect(const aSet: TKMWalkConnectSet; aRect: TKMRect; aDiagObjectsEffected: Boolean);
var
  WC: TKMWalkConnect;
begin
  if gGameParams.IsMapEditor then Exit;
  
  aRect := KMClipRect(aRect, 1, 1, fMapX - 1, fMapY - 1);

  //Process all items from set
  for WC in aSet do
    TKMTerrainWalkConnect.DoUpdate(aRect, WC, aDiagObjectsEffected);
end;


{Place house plan on terrain and change terrain properties accordingly}
procedure TKMTerrain.SetHouse(const Loc: TKMPoint; aHouseType: TKMHouseType; aHouseStage: TKMHouseStage; aOwner: TKMHandID; const aFlattenTerrain: Boolean = False);
var
  I, K, X, Y: Word;
  toFlatten: TKMPointList;
  HA: THouseArea;
  objectsEffected: Boolean; //UpdateWalkConnect cares about this for optimisation purposes
begin
  objectsEffected := False;
  if aFlattenTerrain then //We will check aFlattenTerrain only once, otherwise there are compiler warnings
    toFlatten := TKMPointList.Create
  else
    toFlatten := nil;

  if aHouseStage = hsNone then
    SetHouseAreaOwner(Loc, aHouseType, -1)
  else
    SetHouseAreaOwner(Loc, aHouseType, aOwner);

  HA := gRes.Houses[aHouseType].BuildArea;

  for I := 1 to 4 do
  for K := 1 to 4 do
    if HA[I,K] <> 0 then
    begin
      X := Loc.X + K - 3;
      Y := Loc.Y + I - 4;
      if TileInMapCoords(X,Y) then
      begin
        case aHouseStage of
          hsNone:         Land^[Y,X].TileLock := tlNone;
          hsFence:        Land^[Y,X].TileLock := tlFenced; //Initial state, Laborer should assign NoWalk to each tile he digs
          hsBuilt:        begin
                            //Script houses are placed as built, add TileLock for them too
                            Land^[Y,X].TileLock := tlHouse;

                            //Add road for scipted houses
                            if HA[I,K] = 2 then
                              Land^[Y,X].TileOverlay := toRoad;

                            if toFlatten <> nil then
                            begin
                              //In map editor don't remove objects (remove on mission load instead)
                              if Land^[Y,X].Obj <> OBJ_NONE then
                              begin
                                objectsEffected := objectsEffected or gMapElements[Land^[Y,X].Obj].DiagonalBlocked;
                                Land^[Y,X].Obj := OBJ_NONE;
                              end;
                              //If house was set e.g. in mission file we must flatten the terrain as no one else has
                              toFlatten.Add(KMPoint(X,Y));
                            end;
                          end;
        end;
        UpdateFences(KMPoint(X,Y));
      end;
    end;

  if toFlatten <> nil then
  begin
    FlattenTerrain(toFlatten);
    toFlatten.Free;
  end;

  //Recalculate Passability for tiles around the house so that they can't be built on too
  UpdatePassability(KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1));
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1), objectsEffected);
end;


{That is mainly used for minimap now}
procedure TKMTerrain.SetHouseAreaOwner(const Loc: TKMPoint; aHouseType: TKMHouseType; aOwner: TKMHandID);
var
  I, K: Integer;
  HA: THouseArea;
begin
  HA := gRes.Houses[aHouseType].BuildArea;
  case aHouseType of
    htNone:    Land^[Loc.Y,Loc.X].TileOwner := aOwner;
    htAny:     ; //Do nothing
    else        for I := 1 to 4 do
                  for K := 1 to 4 do //If this is a house make change for whole place
                    if HA[I,K] <> 0 then
                      if TileInMapCoords(Loc.X + K - 3, Loc.Y + I - 4) then
                        Land^[Loc.Y + I - 4, Loc.X + K - 3].TileOwner := aOwner;
  end;
end;


{Check if Unit can be placed here}
//Used by MapEd, so we use AllowedTerrain which lets us place citizens off-road
function TKMTerrain.CanPlaceUnit(const Loc: TKMPoint; aUnitType: TKMUnitType): Boolean;
begin
  Result := TileInMapCoords(Loc.X, Loc.Y)
            and (Land^[Loc.Y, Loc.X].IsUnit = nil) //Check for no unit below
            and (gRes.Units[aUnitType].AllowedPassability in Land^[Loc.Y, Loc.X].Passability);
end;


function TKMTerrain.HousesNearTile(X,Y: Word): Boolean;
var
  I, K: Integer;
begin
  Result := False;
  for I := -1 to 1 do
    for K := -1 to 1 do
      if (Land^[Y + I, X + K].TileLock in [tlFenced, tlDigged, tlHouse]) then
        Result := True;
end;


function TKMTerrain.CanPlaceGoldMine(X,Y: Word): Boolean;
begin
  Result := TileGoodForGoldmine(X,Y)
    and ((Land[Y,X].Obj = OBJ_NONE) or (gMapElements[Land^[Y,X].Obj].CanBeRemoved))
    and not HousesNearTile(X,Y)
    and (Land^[Y,X].TileLock = tlNone)
    and CheckHeightPass(KMPoint(X,Y), hpBuildingMines);
end;


//Check that house can be placed on Terrain
//Other checks are performed on Hands level. Of course Terrain is not aware of that
function TKMTerrain.CanPlaceHouse(Loc: TKMPoint; aHouseType: TKMHouseType): Boolean;
var
  I,K,X,Y: Integer;
  HA: THouseArea;
begin
  Result := True;
  HA := gRes.Houses[aHouseType].BuildArea;
  Loc.X := Loc.X - gRes.Houses[aHouseType].EntranceOffsetX; //update offset
  for I := 1 to 4 do
  for K := 1 to 4 do
    if Result and (HA[I,K] <> 0) then
    begin
      X := Loc.X + k - 3;
      Y := Loc.Y + i - 4;
      //Inset one tile from map edges
      Result := Result and TileInMapCoords(X, Y, 1);

      case aHouseType of
        htIronMine: Result := Result and CanPlaceIronMine(X, Y);
        htGoldMine: Result := Result and CanPlaceGoldMine(X, Y);
        else         Result := Result and (tpBuild in Land^[Y,X].Passability);
      end;
    end;
end;


//Simple check if house could exists on terrain, with only boundaries check
//aInsetRect - insetRect for map rect
function TKMTerrain.CheckHouseBounds(aHouseType: TKMHouseType; const Loc: TKMPoint; aInsetRect: TKMRect): Boolean;
var
  I, K: Integer;
  HA: THouseArea;
  TX, TY: Integer;
  mapHouseInsetRect: TKMRect;
begin
  Result := True;
  HA := gRes.Houses[aHouseType].BuildArea;

  mapHouseInsetRect := KMRect(aInsetRect.Left + 1, aInsetRect.Top + 1, aInsetRect.Right - 1, aInsetRect.Bottom - 1);

  for I := 1 to 4 do
  for K := 1 to 4 do
  if (HA[I,K] <> 0) then
  begin
    TX := Loc.X + K - 3;
    TY := Loc.Y + I - 4;
    Result := Result and TileInMapCoords(TX, TY, mapHouseInsetRect); //Inset one tile from map edges
  end;
end;


//Simple checks when placing houses from the script:
function TKMTerrain.CanPlaceHouseFromScript(aHouseType: TKMHouseType; const Loc: TKMPoint): Boolean;
var
  I, K, L, M: Integer;
  HA: THouseArea;
  TX, TY: Integer;
begin
  Result := True;
  HA := gRes.Houses[aHouseType].BuildArea;

  for I := 1 to 4 do
  for K := 1 to 4 do
  if (HA[I,K] <> 0) then
  begin
    TX := Loc.X + K - 3;
    TY := Loc.Y + I - 4;
    Result := Result and TileInMapCoords(TX, TY, 1); //Inset one tile from map edges
    //We don't use CanBuild since you are allowed to place houses from the script over trees but not over units
    Result := Result and TileIsWalkable(KMPoint(TX, TY)); //Tile must be walkable
    Result := Result and not TileIsCornField(KMPoint(TX, TY));
    Result := Result and not TileIsWineField(KMPoint(TX, TY));

    //Mines must be on a mountain edge
    if aHouseType = htIronMine then
      Result := Result and TileGoodForIronMine(TX,TY);
    if aHouseType = htGoldMine then
      Result := Result and TileGoodForGoldMine(TX,TY);

    //Check surrounding tiles for another house that overlaps
    for L := -1 to 1 do
    for M := -1 to 1 do
    if TileInMapCoords(TX+M, TY+L) and (Land^[TY+L, TX+M].TileLock in [tlFenced,tlDigged,tlHouse]) then
      Result := False;

    //Check if there are units below placed BEFORE the house is added
    //Units added AFTER the house will be autoplaced around it
    Result := Result and (Land^[TY, TX].IsUnit = nil);

    if not Result then Exit;
  end;
end;


function TKMTerrain.CanAddField(aX, aY: Word; aFieldType: TKMFieldType): Boolean;
begin
  //Make sure it is within map, roads can be built on edge
  Result := TileInMapCoords(aX, aY);

  case aFieldType of
    ftRoad:  Result := Result and (tpMakeRoads in Land^[aY, aX].Passability);
    ftCorn,
    ftWine:  Result := Result and TileGoodForField(aX, aY);
    else      Result := False;
  end;
end;


function TKMTerrain.CheckHeightPass(const aLoc: TKMPoint; aPass: TKMHeightPass): Boolean;
  function TestHeight(aHeight: Byte): Boolean;
  var
    Points: array[1..4] of Byte;
    Y2, X2: Integer;
  begin
    Y2 := Min(aLoc.Y + 1, fMapY);
    X2 := Min(aLoc.X + 1, fMapX);

    //Put points into an array like this so it's easy to understand:
    // 1 2
    // 3 4
    //Local map boundaries test is faster
    Points[1] := Land^[aLoc.Y, aLoc.X].Height;
    Points[2] := Land^[aLoc.Y, X2].Height;
    Points[3] := Land^[Y2,     aLoc.X].Height;
    Points[4] := Land^[Y2,     X2].Height;

    {
      KaM method checks the differences between the 4 verticies around the tile.
      There is a special case that means it is more (twice) as tolerant to bottom-left to top right (2-3) and
      bottom-right to top-right (4-2) slopes. This sounds very odd, but if you don't believe me then do the tests yourself. ;)
      The reason for this probably has something to do with the fact that shaddows and stuff flow from
      the bottom-left to the top-right in KaM.
      This formula could be revised later, but for now it matches KaM perfectly.
      The biggest problem with it is backwards sloping tiles which are shown as walkable.
      But it doesn't matter that much because this system is really just a backup (it's more important for
      building than walking) and map creators should block tiles themselves with the special invisible block object.
    }

    //Sides of tile
    Result :=            (abs(Points[1] - Points[2]) < aHeight);
    Result := Result AND (abs(Points[3] - Points[4]) < aHeight);
    Result := Result AND (abs(Points[3] - Points[1]) < aHeight);
    Result := Result AND (abs(Points[4] - Points[2]) < aHeight * 2); //Bottom-right to top-right is twice as tolerant

    //Diagonals of tile
    Result := Result AND (abs(Points[1] - Points[4]) < aHeight);
    Result := Result AND (abs(Points[3] - Points[2]) < aHeight * 2); //Bottom-left to top-right is twice as tolerant
  end;
begin
  //Three types measured in KaM: >=25 - unwalkable/unroadable; >=25 - iron/gold mines unbuildable;
  //>=18 - other houses unbuildable.
  Result := true;

  if not TileInMapCoords(aLoc.X, aLoc.Y) then exit;

  case aPass of
    hpWalking:        Result := TestHeight(25);
    hpBuilding:       Result := TestHeight(18);
    hpBuildingMines:  Result := TestHeight(25);
  end;
end;


procedure TKMTerrain.AddHouseRemainder(const Loc: TKMPoint; aHouseType: TKMHouseType; aBuildState: TKMHouseBuildState);
var
  I, K: Integer;
  HA:   THouseArea;
begin
  HA := gRes.Houses[aHouseType].BuildArea;

  if aBuildState in [hbsStone, hbsDone] then //only leave rubble if the construction was well underway (stone and above)
  begin
    //Leave rubble
    for I := 2 to 4 do
      for K := 2 to 4 do
        if (HA[I - 1, K] <> 0) and (HA[I, K - 1] <> 0)
        and (HA[I - 1, K - 1] <> 0) and (HA[I, K] <> 0) then
          Land^[Loc.Y + I - 4, Loc.X + K - 3].Obj := 68 + KaMRandom(6, 'TKMTerrain.AddHouseRemainder');

    //Leave dug terrain
    for I := 1 to 4 do
      for K := 1 to 4 do
        if HA[I, K] <> 0 then
        begin
          Land^[Loc.Y + I - 4, Loc.X + K - 3].TileOverlay := toDig3;
          Land^[Loc.Y + I - 4, Loc.X + K - 3].TileLock    := tlNone;
        end;
  end else
  begin
    //For glyphs leave nothing
    for I := 1 to 4 do
      for K:=1 to 4 do
        if HA[I, K] <> 0 then
          Land^[Loc.Y + I - 4, Loc.X + K - 3].TileLock := tlNone;
  end;

  UpdatePassability(KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1));
  UpdateWalkConnect([wcWalk, wcRoad, wcWork],
                    KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1),
                    (aBuildState in [hbsStone, hbsDone])); //Rubble objects block diagonals
end;


procedure TKMTerrain.UpdateFences(aCheckSurrounding: Boolean = True);
begin
  UpdateFences(fMapRect);
end;


procedure TKMTerrain.UpdateFences(const aRect: TKMRect; aCheckSurrounding: Boolean = True);
var
  I, K: Integer;
begin
  for I := Max(aRect.Top, 1) to Min(aRect.Bottom, fMapY - 1) do
    for K := Max(aRect.Left, 1) to Min(aRect.Right, fMapX - 1) do
      UpdateFences(KMPoint(K, I), aCheckSurrounding);
end;


// Make call on DefaultLand, instead of Land, which could be replaced on smth else
procedure TKMTerrain.CallOnMainLand(aProc: TProc);
var
  tempLand: PKMLand;
begin
  tempLand := Land;
  SetMainLand;
  aProc;
  Land := tempLand;
end;


procedure TKMTerrain.UpdateAll;
begin
  UpdateAll(fMapRect);
end;


// Update all map internal data
procedure TKMTerrain.UpdateAll(const aRect: TKMRect);
begin
  UpdatePassability(aRect);
  UpdateFences(aRect);
  UpdateLighting(aRect);
end;


{Check 4 surrounding tiles, and if they are different place a fence}
procedure TKMTerrain.UpdateFences(const Loc: TKMPoint; aCheckSurrounding: Boolean = True);
  function GetFenceType: TKMFenceKind;
  begin
    if TileIsCornField(Loc) then
      Result := fncCorn
    else
    if TileIsWineField(Loc) then
      Result := fncWine
    else
    if Land^[Loc.Y,Loc.X].TileLock in [tlFenced, tlDigged] then
      Result := fncHouseFence
    else
      Result := fncNone;
  end;

  function GetFenceEnabled(X, Y: SmallInt): Boolean;
  begin
    Result := True;

    if not TileInMapCoords(X,Y) then exit;

    if (TileIsCornField(Loc) and TileIsCornField(KMPoint(X,Y))) or //Both are Corn
       (TileIsWineField(Loc) and TileIsWineField(KMPoint(X,Y))) or //Both are Wine
       ((Land^[Loc.Y, Loc.X].TileLock in [tlFenced, tlDigged]) and
        (Land^[Y, X].TileLock in [tlFenced, tlDigged])) then //Both are either house fence
      Result := False;
  end;
begin
  if not TileInMapCoords(Loc.X, Loc.Y) then Exit;

  Fences[Loc.Y,Loc.X].Kind := GetFenceType;

  if Fences[Loc.Y, Loc.X].Kind = fncNone then
    Fences[Loc.Y, Loc.X].Side := 0
  else
  begin
    Fences[Loc.Y, Loc.X].Side := Byte(GetFenceEnabled(Loc.X,     Loc.Y - 1))      + //N
                                 Byte(GetFenceEnabled(Loc.X - 1, Loc.Y))      * 2 + //E
                                 Byte(GetFenceEnabled(Loc.X + 1, Loc.Y))      * 4 + //W
                                 Byte(GetFenceEnabled(Loc.X,     Loc.Y + 1))  * 8;  //S
  end;

  if aCheckSurrounding then
  begin
    UpdateFences(KMPoint(Loc.X - 1, Loc.Y), False);
    UpdateFences(KMPoint(Loc.X + 1, Loc.Y), False);
    UpdateFences(KMPoint(Loc.X, Loc.Y - 1), False);
    UpdateFences(KMPoint(Loc.X, Loc.Y + 1), False);
  end;
end;


{Cursor position should be converted to tile-coords respecting tile heights}
function TKMTerrain.ConvertCursorToMapCoord(inX,inY: Single): Single;
var
  ii:     Integer;
  Xc, Yc: Integer;
  Tmp:    Integer;
  Ycoef:  array[-2..4] of Single;
begin
  Xc := EnsureRange(Round(inX + 0.5), 1, fMapX - 1); //Cell below cursor without height check
  Yc := EnsureRange(Round(inY + 0.5), 1, fMapY - 1);

  for ii:=-2 to 4 do //make an array of tile heights above and below cursor (-2..4)
  begin
    Tmp       := EnsureRange(Yc + ii, 1, fMapY);
    Ycoef[ii] := (Yc - 1) + ii - (Land^[Tmp, Xc].RenderHeight * (1 - frac(inX))
                          + Land^[Tmp, Xc + 1].RenderHeight * frac(inX)) / CELL_HEIGHT_DIV;
  end;

  Result := Yc; //Assign something incase following code returns nothing

  for ii := -2 to 3 do //check if cursor in a tile and adjust it there
    if InRange(inY, Ycoef[ii], Ycoef[ii + 1]) then
    begin
      Result := Yc + ii - (Ycoef[ii + 1] - inY) / (Ycoef[ii + 1] - Ycoef[ii]);
      break;
    end;

  //gLog.AssertToLog(false,'TTerrain.ConvertCursorToMapCoord - couldn''t convert')
end;


//Convert point from flat position to height position on terrain
function TKMTerrain.FlatToHeight(inX, inY: Single): Single;
var
  Xc, Yc: Integer;
  tmp1, tmp2: single;
begin
  //Valid range of tiles is 0..MapXY-2 because we check height from (Xc+1,Yc+1) to (Xc+2,Yc+2)
  //We cannot ask for height at the bottom row (MapY-1) because that row is not on the visible map,
  //and does not have a vertex below it
  Xc := EnsureRange(Trunc(inX), 0, fMapX-1);
  Yc := EnsureRange(Trunc(inY), 0, fMapY-1);

  tmp1 := Mix(Land[Yc+1, Min(Xc+2, fMapX)].Height, Land^[Yc+1, Xc+1].Height, Frac(inX));
  tmp2 := Mix(Land[Min(Yc+2, fMapY), Min(Xc+2, fMapX)].Height, Land^[Min(Yc+2, fMapY), Xc+1].Height, Frac(inX));
  Result := inY - Mix(tmp2, tmp1, Frac(inY)) / CELL_HEIGHT_DIV;
end;


//Convert point from flat position to height position on terrain
function TKMTerrain.RenderFlatToHeight(const aPoint: TKMPointF): TKMPointF;
begin
  Result.X := aPoint.X;
  Result.Y := RenderFlatToHeight(aPoint.X, aPoint.Y);
end;


//Convert point from flat position to height position on terrain
function TKMTerrain.RenderFlatToHeight(inX, inY: Single): Single;
var
  Xc, Yc: Integer;
  tmp1, tmp2: single;
begin
  //Valid range of tiles is 0..MapXY-2 because we check height from (Xc+1,Yc+1) to (Xc+2,Yc+2)
  //We cannot ask for height at the bottom row (MapY-1) because that row is not on the visible map,
  //and does not have a vertex below it
  Xc := EnsureRange(Trunc(inX), 0, fMapX-1);
  Yc := EnsureRange(Trunc(inY), 0, fMapY-1);

  tmp1 := Mix(Land[Yc+1, Min(Xc+2, fMapX)].RenderHeight, Land^[Yc+1, Xc+1].RenderHeight, Frac(inX));
  tmp2 := Mix(Land[Min(Yc+2, fMapY), Min(Xc+2, fMapX)].RenderHeight, Land^[Min(Yc+2, fMapY), Xc+1].RenderHeight, Frac(inX));
  Result := inY - Mix(tmp2, tmp1, Frac(inY)) / CELL_HEIGHT_DIV;
end;


//Convert point from flat position to height position on terrain
function TKMTerrain.FlatToHeight(const aPoint: TKMPointF): TKMPointF;
begin
  Result.X := aPoint.X;
  Result.Y := FlatToHeight(aPoint.X, aPoint.Y);
end;


//Return height within cell interpolating node heights
//Note that input parameters are 0 based
function TKMTerrain.HeightAt(inX, inY: Single): Single;
var
  Xc, Yc: Integer;
  tmp1, tmp2: single;
begin
  //Valid range of tiles is 0..MapXY-2 because we check height from (Xc+1,Yc+1) to (Xc+2,Yc+2)
  //We cannot ask for height at the bottom row (MapY-1) because that row is not on the visible map,
  //and does not have a vertex below it
  Xc := EnsureRange(Trunc(inX), 0, fMapX-1);
  Yc := EnsureRange(Trunc(inY), 0, fMapY-1);

  tmp1 := Mix(Land[Yc+1, Min(Xc+2, fMapX)].Height, Land^[Yc+1, Xc+1].Height, Frac(inX));
  tmp2 := Mix(Land[Min(Yc+2, fMapY), Min(Xc+2, fMapX)].Height, Land^[Min(Yc+2, fMapY), Xc+1].Height, Frac(inX));
  Result := Mix(tmp2, tmp1, Frac(inY)) / CELL_HEIGHT_DIV;
end;


//Return Render height within cell interpolating node heights
//Note that input parameters are 0 based
function TKMTerrain.RenderHeightAt(inX, inY: Single): Single;
var
  Xc, Yc: Integer;
  tmp1, tmp2: single;
begin
  //Valid range of tiles is 0..MapXY-2 because we check height from (Xc+1,Yc+1) to (Xc+2,Yc+2)
  //We cannot ask for height at the bottom row (MapY-1) because that row is not on the visible map,
  //and does not have a vertex below it
  Xc := EnsureRange(Trunc(inX), 0, fMapX-1);
  Yc := EnsureRange(Trunc(inY), 0, fMapY-1);

  tmp1 := Mix(Land[Yc+1, Min(Xc+2, fMapX)].RenderHeight, Land^[Yc+1, Xc+1].RenderHeight, Frac(inX));
  tmp2 := Mix(Land[Min(Yc+2, fMapY), Min(Xc+2, fMapX)].RenderHeight, Land^[Min(Yc+2, fMapY), Xc+1].RenderHeight, Frac(inX));
  Result := Mix(tmp2, tmp1, Frac(inY)) / CELL_HEIGHT_DIV;
end;


//Get highest walkable hill on a maps top row to use for viewport top bound
function TKMTerrain.TopHill: Byte;
var
  I, K: Integer;
begin
  Result := 0;
  //Check last 2 strips in case 2nd has a taller hill
  for I := 1 to 2 do
  for K := 2 to fMapX do
  if ((tpWalk in Land[I, K-1].Passability) or (tpWalk in Land^[I, K].Passability)) then
    Result := Max(Result, Land^[I, K].Height - (I-1) * CELL_SIZE_PX);
end;


procedure TKMTerrain.IncAnimStep;
begin
  Inc(fAnimStep);
end;


procedure TKMTerrain.Save(SaveStream: TKMemoryStream);
var
  I, K, L: Integer;
  isTxtStream: Boolean;
begin
  Assert(not fMapEditor, 'MapEd mode is not intended to be saved into savegame');

  SaveStream.PlaceMarker('Terrain');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
  SaveStream.Write(fMapRect);
  SaveStream.Write(fAnimStep);

  FallingTrees.SaveToStream(SaveStream);
  isTxtStream := SaveStream is TKMemoryStreamText;

  if isTxtStream then
    for I := 1 to fMapY do
      for K := 1 to fMapX do
      begin
        SaveStream.PlaceMarker(KMPoint(K,I).ToString);

        with Land^[I,K] do
        begin
          BaseLayer.Save(SaveStream);
          for L := 0 to 2 do
            Layer[L].Save(SaveStream);
          SaveStream.Write(LayersCnt);
          SaveStream.Write(Height);
          SaveStream.Write(Obj);
          SaveStream.Write(IsCustom);
          SaveStream.Write(BlendingLvl);
          SaveStream.Write(TreeAge);
          SaveStream.Write(FieldAge);
          SaveStream.Write(TileLock, SizeOf(TileLock));
          SaveStream.Write(JamMeter);
          SaveStream.Write(TileOverlay, SizeOf(TileOverlay));
          SaveStream.Write(TileOwner, SizeOf(TileOwner));
          SaveStream.Write(TKMUnit(Land^[I,K].IsUnit).UID);
          SaveStream.Write(IsVertexUnit, SizeOf(IsVertexUnit));

          SaveStream.Write(Passability, SizeOf(Passability));
          SaveStream.Write(WalkConnect, SizeOf(WalkConnect));
          SaveStream.Write(Light);
        end;
      end
  else
  begin
    // Save Unit pointer in temp array
    for I := 1 to fMapY do
      for K := 1 to fMapX do
      begin
        fUnitPointersTemp[I,K] := Land^[I,K].IsUnit;
        Land[I,K].IsUnit := Pointer(TKMUnit(Land^[I,K].IsUnit).UID);
      end;

    for I := 1 to fMapY do
      SaveStream.Write(Land[I,1], SizeOf(Land^[I,1]) * fMapX);

    // Restore unit pointers
    for I := 1 to fMapY do
      for K := 1 to fMapX do
      begin
        Land^[I,K].IsUnit := fUnitPointersTemp[I,K];
      end;
  end;
end;


procedure TKMTerrain.Load(LoadStream: TKMemoryStream);
var
  I, J: Integer;
begin
  LoadStream.CheckMarker('Terrain');
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
  LoadStream.Read(fMapRect);
  LoadStream.Read(fAnimStep);

  FallingTrees.LoadFromStream(LoadStream);

  for I := 1 to fMapY do
    LoadStream.Read(Land[I,1], SizeOf(Land^[I,1]) * fMapX);

  for I := 1 to fMapY do
    for J := 1 to fMapX do
      UpdateFences(KMPoint(J,I), False);

  fFinder := TKMTerrainFinder.Create;

  gLog.AddTime('Terrain loaded');
end;


procedure TKMTerrain.SyncLoad;
var
  I, K: Integer;
begin
  for I := 1 to fMapY do
    for K := 1 to fMapX do
      Land[I,K].IsUnit := gHands.GetUnitByUID(Cardinal(Land^[I,K].IsUnit));
end;


function TKMTerrain.GetFieldStage(const Loc: TKMPoint): Byte;
begin
  Result := 0;
  if not TileInMapCoords(Loc.X, Loc.Y) then Exit;

  if TileIsCornField(Loc) then
    Result := GetCornStage(Loc)
  else
  if TileIsWineField(Loc) then
    Result := GetWineStage(Loc);
end;


function TKMTerrain.GetCornStage(const Loc: TKMPoint): Byte;
var
  fieldAge: Byte;
begin
  Assert(TileIsCornField(Loc));
  fieldAge := Land^[Loc.Y,Loc.X].FieldAge;
  if fieldAge = 0 then
  begin
    if (fMapEditor and (gGame.MapEditor.LandMapEd^[Loc.Y,Loc.X].CornOrWineTerrain = 63))
      or (Land^[Loc.Y,Loc.X].BaseLayer.Terrain = 63) then
      Result := 6
    else
      Result := 0;
  end else if InRange(fieldAge, 1, CORN_AGE_1 - 1) then
    Result := 1
  else if InRange(fieldAge, CORN_AGE_1, CORN_AGE_2 - 1) then
    Result := 2
  else if InRange(fieldAge, CORN_AGE_2, CORN_AGE_3 - 1) then
    Result := 3
  else if InRange(fieldAge, CORN_AGE_3, CORN_AGE_FULL - 2) then
    Result := 4
  else
    Result := 5;
end;


function TKMTerrain.GetWineStage(const Loc: TKMPoint): Byte;
begin
  Result := 0;
  Assert(TileIsWineField(Loc));
  case Land^[Loc.Y, Loc.X].Obj of
    54:   Result := 0;
    55:   Result := 1;
    56:   Result := 2;
    57:   Result := 3;
  end;
end;


function TKMTerrain.GetFieldType(const Loc: TKMPoint): TKMFieldType;
begin
  Result := ftNone;
  if not TileInMapCoords(Loc.X, Loc.Y) then Exit;

  if TileHasRoad(Loc) then
    Result := ftRoad
  else
  if TileIsCornField(Loc) then
    Result := ftCorn
  else
  if TileIsWineField(Loc) then
    Result := ftWine;
end;


//This whole thing is very CPU intesive, updating whole (256*256) tiles map
//Don't use any advanced math here, only simpliest operations - + div *
procedure TKMTerrain.UpdateState;
  procedure SetLand(aTile: Word; const X, Y, aObj: Byte);
  var FloodfillNeeded: Boolean;
  begin
    Land^[Y,X].BaseLayer.Terrain := aTile;
    FloodfillNeeded   := gMapElements[Land^[Y,X].Obj].DiagonalBlocked <> gMapElements[aObj].DiagonalBlocked;
    Land^[Y,X].Obj     := aObj;
    if FloodfillNeeded then //When trees are removed by corn growing we need to update floodfill
      UpdateWalkConnect([wcWalk,wcRoad,wcWork], KMRectGrowTopLeft(KMRect(X,Y,X,Y)), True);
  end;
var
  H, I, K, A: Integer;
  J: TKMChopableAge;
  T: Integer;
begin
  if not DYNAMIC_TERRAIN then Exit;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psTerrain);
  {$ENDIF}
  try
    inc(fAnimStep);

    //Update falling trees animation
    for T := FallingTrees.Count - 1 downto 0 do
    if fAnimStep >= FallingTrees.Tag2[T] + Cardinal(gMapElements[FallingTrees.Tag[T]].Anim.Count - 1) then
      ChopTree(FallingTrees[T]); //Make the tree turn into a stump

    //Process every 200th (TERRAIN_PACE) tile, offset by fAnimStep
    A := fAnimStep mod TERRAIN_PACE;
    while A < fMapX * fMapY do
    begin
      K := (A mod fMapX) + 1;
      I := (A div fMapX) + 1;

      //Reduce JamMeter over time
      Land^[I,K].IncJamMeter(-3);

      if InRange(Land^[I,K].FieldAge, 1, CORN_AGE_MAX-1) then
      begin
        Inc(Land^[I,K].FieldAge);
        if TileIsCornField(KMPoint(K,I)) then
          case Land^[I,K].FieldAge of
            CORN_AGE_1:     SetLand(59,K,I,OBJ_NONE);
            CORN_AGE_2:     SetLand(60,K,I,OBJ_NONE);
            CORN_AGE_3:     SetLand(60,K,I,58);
            CORN_AGE_FULL:  begin
                              //Skip to the end
                              SetLand(60,K,I,59);
                              Land^[I,K].FieldAge := CORN_AGE_MAX;
                            end;
          end
        else
        if TileIsWineField(KMPoint(K,I)) then
          case Land^[I,K].FieldAge of
            WINE_AGE_1:     SetLand(WINE_TERRAIN_ID,K,I,55);
            WINE_AGE_2:     SetLand(WINE_TERRAIN_ID,K,I,56);
            WINE_AGE_FULL:  begin
                              //Skip to the end
                              SetLand(WINE_TERRAIN_ID,K,I,57);
                              Land^[I,K].FieldAge := CORN_AGE_MAX;
                            end;
          end;
      end;

      if InRange(Land^[I,K].TreeAge, 1, TREE_AGE_FULL) then
      begin
        Inc(Land^[I,K].TreeAge);
        if (Land^[I,K].TreeAge = TREE_AGE_1)
        or (Land^[I,K].TreeAge = TREE_AGE_2)
        or (Land^[I,K].TreeAge = TREE_AGE_FULL) then //Speedup
          for H := Low(ChopableTrees) to High(ChopableTrees) do
            for J := caAge1 to caAge3 do
              if Land^[I,K].Obj = ChopableTrees[H,J] then
                case Land^[I,K].TreeAge of
                  TREE_AGE_1:    Land^[I,K].Obj := ChopableTrees[H, caAge2];
                  TREE_AGE_2:    Land^[I,K].Obj := ChopableTrees[H, caAge3];
                  TREE_AGE_FULL: Land^[I,K].Obj := ChopableTrees[H, caAgeFull];
                end;
      end;

      Inc(A, TERRAIN_PACE);
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psTerrain);
    {$ENDIF}
  end;
end;


class procedure TKMTerrain.WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID; aGameSave: Boolean);
var
  mapDataSize: Cardinal;
begin
  WriteTileToStream(S, aTileBasic, aTileOwner, aGameSave, mapDataSize);
end;


class procedure TKMTerrain.WriteTileToStream(S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; aTileOwner: TKMHandID;
                                             aGameSave: Boolean; var aMapDataSize: Cardinal);

  function PackLayersCorners(const aTileBasic: TKMTerrainTileBasic): Byte;
  var
    I, L: Integer;
    layersCnt: Byte;
  begin
    Result := 0;
    //Layers corners are packed into 1 byte.
    //It contains info which layer 'owns' each corner
    //f.e. aCorners[0] contains layer number, which 'own' 0 corner.
    //0-layer means BaseLayer
    layersCnt := 0;
    for I := 3 downto 0 do  // go from 3 to 0, as we pack 3 corner to the most left
    begin
      if aTileBasic.BaseLayer.Corner[I] then
        layersCnt := 0
      else
        for L := 0 to 2 do
          if aTileBasic.Layer[L].Corner[I] then
          begin
            layersCnt := L + 1;
            Break;
          end;
      if I < 3 then //do not shl for first corner
        Result := Result shl 2;
      Result := Result or layersCnt;
    end;
  end;

  //Pack generated terrain id identification info into 2 bytes (Word)
  //6 bits are for terKind       (supports up to 64 terKinds)
  //2 bits for mask subType      (supports up to 4 mask subTypes)
  //4 bits for mask Kind         (supports up to 16 mask kinds)
  //4 bits for mask Type (MType) (supports up to 16 mask types)
  function PackTerrainGenInfo(aGenInfo: TKMGenTerrainInfo): Word;
  begin
    Result := Byte(aGenInfo.TerKind) shl 10;
    Result := Result or (Byte(aGenInfo.Mask.SubType) shl 8);
    Result := Result or (Byte(aGenInfo.Mask.Kind) shl 4);
    Result := Result or Byte(aGenInfo.Mask.MType);
  end;

var
  L: Integer;
  genInfo: TKMGenTerrainInfo;
  overlay: TKMTileOverlay;
begin
  S.Write(aTileBasic.BaseLayer.Terrain);  //1
  //Map file stores terrain, not the fields placed over it, so save OldRotation rather than Rotation
  S.Write(aTileBasic.BaseLayer.Rotation); //3
  S.Write(aTileBasic.Height);             //4
  S.Write(aTileBasic.Obj);                //5
  S.Write(aTileBasic.IsCustom);           //7

  overlay := toNone;
  // Player roads (when tile owner is specified) should not be saved as an overlay, when save .map file
  // since player roads are set for each player in the dat file
  // but they should for a game save or if they are made as an neutral road (so just simple overlay in the map file)
  if aGameSave or (aTileOwner = PLAYER_NONE) then
    overlay := aTileBasic.TileOverlay;

  S.Write(overlay, SizeOf(overlay)); //8
  S.Write(aTileBasic.LayersCnt);          //9
  Inc(aMapDataSize, 9); // obligatory 9 bytes per tile
  if aTileBasic.LayersCnt > 0 then
  begin
    S.Write(PackLayersCorners(aTileBasic));
    S.Write(aTileBasic.BlendingLvl);
    Inc(aMapDataSize, 2);
    for L := 0 to aTileBasic.LayersCnt - 1 do
    begin
      //We could add more masks and terKinds in future, so we can't stick with generated terrainId,
      //but need to save/load its generation parameters (terKind/mask types etc)
      genInfo := gRes.Sprites.GetGenTerrainInfo(aTileBasic.Layer[L].Terrain);
      S.Write(PackTerrainGenInfo(genInfo));
      S.Write(aTileBasic.Layer[L].Rotation);
      Inc(aMapDataSize, 3); // Terrain (2 bytes) + Rotation (1 byte)
    end;
  end;
end;


class procedure TKMTerrain.ReadTileFromStream(aStream: TKMemoryStream; var aTileBasic: TKMTerrainTileBasic; aGameRev: Integer = 0);

  //Unpack generated terrain id identification info from 2 bytes (Word)
  //6 bits are for terKind       (supports up to 64 terKinds)
  //2 bits for mask subType      (supports up to 4 mask subTypes)
  //4 bits for mask Kind         (supports up to 16 mask kinds)
  //4 bits for mask Type (MType) (supports up to 16 mask types)
  function UnpackTerrainGenInfo(aPackedInfo: Word): TKMGenTerrainInfo;
  begin
    Result.TerKind      := TKMTerrainKind((aPackedInfo shr 10) and 63);
    Result.Mask.SubType := TKMTileMaskSubType((aPackedInfo shr 8) and 3);
    Result.Mask.Kind    := TKMTileMaskKind((aPackedInfo shr 4) and 15);
    Result.Mask.MType   := TKMTileMaskType(aPackedInfo and 15);
  end;

var
  I: Integer;
  terrainB, objectB, rot, corners: Byte;
  layersCorners: array[0..3] of Byte;
  useKaMFormat: Boolean;
  terIdentInfo: Word;
  genInfo: TKMGenTerrainInfo;
begin
  useKaMFormat := ( aGameRev = 0 );

  if useKaMFormat then
  begin
    aStream.Read(terrainB);           //1
    aTileBasic.BaseLayer.Terrain := terrainB;
    aStream.Seek(1, soFromCurrent);
    aStream.Read(aTileBasic.Height);  //3
    aStream.Read(rot);                //4
    aTileBasic.BaseLayer.Rotation := rot mod 4; //Some original KaM maps have Rot > 3, mod 4 gives right result
    aStream.Seek(1, soFromCurrent);
    aStream.Read(objectB);     //6
    aTileBasic.Obj := objectB;
    aTileBasic.BaseLayer.SetAllCorners;
    aTileBasic.LayersCnt := 0;
    aTileBasic.IsCustom := False;
    aTileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL;
    aTileBasic.TileOverlay := toNone;
  end else begin
    aStream.Read(aTileBasic.BaseLayer.Terrain); //2
    aStream.Read(rot);                          //3
    aTileBasic.BaseLayer.Rotation := rot mod 4; //Some original KaM maps have Rot > 3, mod 4 gives right result
    aStream.Read(aTileBasic.Height);            //4
    aStream.Read(aTileBasic.Obj);               //5
    aStream.Read(aTileBasic.IsCustom);          //7
    aTileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL; //Default value;

    if aGameRev > 10968 then
      aStream.Read(aTileBasic.TileOverlay, SizeOf(aTileBasic.TileOverlay)) //8
    else
      aTileBasic.TileOverlay := toNone;

    // Load all layers info
    // First get layers count
    aStream.Read(aTileBasic.LayersCnt);         //9
    if aTileBasic.LayersCnt = 0 then            // No need to save corners, if we have no layers on that tile
      aTileBasic.BaseLayer.SetAllCorners // Set all corners then
    else begin
      // if there are some layers, then load base layer corners first
      aStream.Read(corners);

      //Layers corners are packed into 1 byte.
      //It contains info which layer 'owns' each corner
      //f.e. aCorners[0] contains layer number, which 'own' 0 corner.
      //0-layer means BaseLayer
      layersCorners[0] := corners and $3;
      layersCorners[1] := (corners shr 2) and $3;
      layersCorners[2] := (corners shr 4) and $3;
      layersCorners[3] := (corners shr 6) and $3;

      if aGameRev > 10745 then //Blending option appeared only after r10745
        aStream.Read(aTileBasic.BlendingLvl)
      else
        aTileBasic.BlendingLvl := TERRAIN_DEF_BLENDING_LVL;

      for I := 0 to aTileBasic.LayersCnt - 1 do
      begin
        if aGameRev <= 10745 then
        begin
          aStream.Read(aTileBasic.Layer[I].Terrain); //Old generated TerrainID
          //Get terrain generation info for pre 10745 maps
          genInfo := gRes.Sprites.GetGenTerrainInfoLegacy(aTileBasic.Layer[I].Terrain);
        end
        else
        begin
          aStream.Read(terIdentInfo); //Read packed info
          genInfo := UnpackTerrainGenInfo(terIdentInfo);
        end;
        //Get current generated terrain id by identification info
        //We could add more masks and terKinds in future, so we can't stick with generated terrainId,
        //but need to save/load its generation parameters (terKind/mask types etc)
        aTileBasic.Layer[I].Terrain := gGenTerrainTransitions[genInfo.TerKind, genInfo.Mask.Kind,
                                                              genInfo.Mask.MType, genInfo.Mask.SubType];
        aStream.Read(aTileBasic.Layer[I].Rotation);
      end;

      aTileBasic.BaseLayer.ClearCorners;
      for I := 0 to 2 do
        aTileBasic.Layer[I].ClearCorners;

      for I := 0 to 3 do
      begin
        case layersCorners[I] of
          0:    aTileBasic.BaseLayer.Corner[I] := True;
          else  aTileBasic.Layer[layersCorners[I]-1].Corner[I] := True;
        end;
      end;
    end;
  end;

  if useKaMFormat then
    aStream.Seek(17, soFromCurrent);
end;


end.

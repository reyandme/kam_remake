unit KM_Terrain;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils, Graphics,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils, KM_ResTileset,
  KM_ResHouses, KM_ResWares, KM_TerrainFinder, KM_ResMapElements,
  KM_CommonTypes;


type
  //Farmers/Woodcutters preferred activity
  TKMPlantAct = (taCut, taPlant, taAny);
  TKMTileOverlay = (toNone, toDig1, toDig2, toDig3, toDig4, toRoad);
  TKMVertexUsage = (vuNone=0,  //Nobody is on this vertex
                    vuNWSE,    //Vertex is used NW-SE like this: \
                    vuNESW);   //Vertex is used NE-SW like this: /
  TKMFenceType = (fncNone, fncCorn, fncWine, fncHousePlan, fncHouseFence);

  TKMTileChangeType = (tctTerrain, tctRotation, tctHeight, tctObject);

  TKMTileChangeTypeSet = set of TKMTileChangeType;

  TKMTerrainTileBrief = record
    X,Y: Byte;
    Terrain: Word;
    Rotation: Byte;
    Height: Byte;
    Obj: Word;
    UpdateTerrain, UpdateRotation, UpdateHeight, UpdateObject: Boolean;
  end;

  TKMTerrainTileBriefArray = array of TKMTerrainTileBrief;

  TKMTerrainTileChangeError = packed record
    X, Y: Byte;
    ErrorsIn: TKMTileChangeTypeSet;
  end;

  TKMTerrainTileChangeErrorArray = array of TKMTerrainTileChangeError;

  TKMTerrainLayer = record
    Terrain: Word;
    Rotation: Byte;
    Corners: TKMByteSet; //Corners, that this layer 'owns' (corners are distributed between all layers, so any layer can own 1-4 corners)
  end;

  TKMTerrainTileBasic = record
    BaseLayer: TKMTerrainLayer;
    LayersCnt: Byte;
    Layer: array [0..2] of TKMTerrainLayer;
    Height: Byte;
    Obj: Word;
    IsCustom: Boolean;
  end;

  TKMTerrainTile = record
    BaseLayer: TKMTerrainLayer;
    LayersCnt: Byte;
    Layer: array [0..2] of TKMTerrainLayer;
//    StoneLayer: TKMTerrainLayer;
    Height: Byte;
    Obj: Word;
    IsCustom: Boolean; //Custom tile (rotated tile, atm)

    //Age of tree, another independent variable since trees can grow on fields
    TreeAge: Byte; //Not init=0 .. Full=TreeAgeFull Depending on this tree gets older and thus could be chopped

    //Age of field/wine, another independent variable
    FieldAge: Byte; //Empty=0, 1, 2, 3, 4, Full=CORN_AGE_MAX  Depending on this special object maybe rendered (straw, grapes)

    //Tells us the stage of house construction or workers making a road
    TileLock: TKMTileLock;

    //Used to display half-dug road
    TileOverlay: TKMTileOverlay; //toNone toDig1, toDig2, toDig3, toDig4 + toRoad

    TileOwner: TKMHandID; //Who owns the tile by having a house/road/field on it
    IsUnit: Pointer; //Whenever there's a unit on that tile mark the tile as occupied and count the number
    IsVertexUnit: TKMVertexUsage; //Whether there are units blocking the vertex. (walking diagonally or fighting)

    //MAPEDITOR
    CornOrWine: Byte; //Indicate Corn or Wine field placed on the tile (without altering terrain)
    CornOrWineTerrain: Byte; //We use fake terrain for maped to be able delete or alter it if needed

    //DEDUCTED
    Light: Single; //KaM stores node lighting in 0..32 range (-16..16), but I want to use -1..1 range
    Passability: TKMTerrainPassabilitySet; //Meant to be set of allowed actions on the tile

    WalkConnect: array [TKMWalkConnect] of Word; //Whole map is painted into interconnected areas

    Fence: TKMFenceType; //Fences (ropes, planks, stones)
    FenceSide: Byte; //Bitfield whether the fences are enabled
  end;

  TKMTerrainTileArray = array of TKMTerrainTile;

  {Class to store all terrain data, aswell terrain routines}
  TKMTerrain = class
  private
    fAnimStep: Cardinal;
    fMapEditor: Boolean; //In MapEd mode some features behave differently
    fMapX: Word; //Terrain width
    fMapY: Word; //Terrain height
    fMapRect: TKMRect; //Terrain rect (1, 1, MapX, MapY)

    fTileset: TKMResTileset;
    fFinder: TKMTerrainFinder;

    fBoundsWC: TKMRect; //WC rebuild bounds used in FlattenTerrain (put outside to fight with recursion SO error in FlattenTerrain EnsureWalkable)

    function TileHasParameter(X,Y: Word; aCheckTileFunc: TBooleanWordFunc; aAllow2CornerTiles: Boolean = False): Boolean;

    function GetMiningRect(aRes: TKMWareType): TKMRect;

    function ChooseCuttingDirection(const aLoc, aTree: TKMPoint; out CuttingPoint: TKMPointDir): Boolean;

    procedure UpdateFences(const Loc: TKMPoint; CheckSurrounding: Boolean = True);
    procedure UpdateWalkConnect(const aSet: array of TKMWalkConnect; aRect: TKMRect; aDiagObjectsEffected: Boolean);

    procedure SetField_Init(const Loc: TKMPoint; aOwner: TKMHandID);
    procedure SetField_Complete(const Loc: TKMPoint; aFieldType: TKMFieldType);

    function TrySetTile(X, Y: Integer; aType, aRot: Integer; aUpdatePassability: Boolean = True): Boolean; overload;
    function TrySetTile(X, Y: Integer; aType, aRot: Integer; out aPassRect: TKMRect;
                        out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean; overload;
    function TrySetTileHeight(X, Y: Integer; aHeight: Byte; aUpdatePassability: Boolean = True): Boolean;
    function TrySetTileObject(X, Y: Integer; aObject: Word; aUpdatePassability: Boolean = True): Boolean; overload;
    function TrySetTileObject(X, Y: Integer; aObject: Word; out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean; overload;

    function HousesNearTile(X,Y: Word): Boolean;
  public
    Land: array [1..MAX_MAP_SIZE, 1..MAX_MAP_SIZE] of TKMTerrainTile;
    FallingTrees: TKMPointTagList;

    constructor Create;
    destructor Destroy; override;
    procedure MakeNewMap(aWidth, aHeight: Integer; aMapEditor: Boolean);
    procedure LoadFromFile(const FileName: UnicodeString; aMapEditor: Boolean);
    procedure SaveToFile(const aFile: UnicodeString); overload;
    procedure SaveToFile(const aFile: UnicodeString; const aInsetRect: TKMRect); overload;

    property MapX: Word read fMapX;
    property MapY: Word read fMapY;
    property MapRect: TKMRect read fMapRect;

    procedure SetTileLock(const aLoc: TKMPoint; aTileLock: TKMTileLock);
    procedure UnlockTile(const aLoc: TKMPoint);
    procedure SetRoads(aList: TKMPointList; aOwner: TKMHandID; aUpdateWalkConnects: Boolean = True);
    procedure SetRoad(const Loc: TKMPoint; aOwner: TKMHandID);
    procedure SetInitWine(const Loc: TKMPoint; aOwner: TKMHandID);
    procedure SetField(const Loc: TKMPoint; aOwner: TKMHandID; aFieldType: TKMFieldType; aStage: Byte = 0; aRandomAge: Boolean = False; aKeepOldObject: Boolean = False);
    procedure SetHouse(const Loc: TKMPoint; aHouseType: TKMHouseType; aHouseStage: TKMHouseStage; aOwner: TKMHandID; const aFlattenTerrain: Boolean = False);
    procedure SetHouseAreaOwner(const Loc: TKMPoint; aHouseType: TKMHouseType; aOwner: TKMHandID);

    procedure RemovePlayer(aPlayer: TKMHandID);
    procedure RemRoad(const Loc: TKMPoint);
    procedure RemField(const Loc: TKMPoint); overload;
    procedure RemField(const Loc: TKMPoint; aDoUpdatePassNWalk: Boolean; out aUpdatePassRect: TKMRect; 
                       out aDiagObjectChanged: Boolean; aDoUpdateFences: Boolean); overload;
    procedure ClearPlayerLand(aPlayer: TKMHandID);

    procedure IncDigState(const Loc: TKMPoint);
    procedure ResetDigState(const Loc: TKMPoint);

    function CanPlaceUnit(const Loc: TKMPoint; aUnitType: TKMUnitType): Boolean;
    function CanPlaceGoldMine(X, Y: Word): Boolean;
    function CanPlaceIronMine(X, Y: Word): Boolean;
    function CanPlaceHouse(Loc: TKMPoint; aHouseType: TKMHouseType): Boolean;
    function CanPlaceHouseFromScript(aHouseType: TKMHouseType; const Loc: TKMPoint): Boolean;
    function CanAddField(aX, aY: Word; aFieldType: TKMFieldType): Boolean;
    function CheckHeightPass(const aLoc: TKMPoint; aPass: TKMHeightPass): Boolean;
    procedure AddHouseRemainder(const Loc: TKMPoint; aHouseType: TKMHouseType; aBuildState: TKMHouseBuildState);

    function FindWineField(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; out FieldPoint: TKMPointDir): Boolean;
    function FindCornField(const aLoc: TKMPoint; aRadius:integer; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                           out PlantAct: TKMPlantAct; out FieldPoint: TKMPointDir): Boolean;
    function FindStone(const aLoc: TKMPoint; aRadius: Byte; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                       out StonePoint: TKMPointDir): Boolean;
    function FindOre(const aLoc: TKMPoint; aRes: TKMWareType; out OrePoint: TKMPoint): Boolean;
    procedure FindOrePoints(const aLoc: TKMPoint; aRes: TKMWareType; var aPoints: TKMPointListArray);
    procedure FindOrePointsByDistance(aLoc: TKMPoint; aRes: TKMWareType; var aPoints: TKMPointListArray);
    function CanFindTree(const aLoc: TKMPoint; aRadius: Word; aOnlyAgeFull: Boolean = False):Boolean; 
    procedure FindTree(const aLoc: TKMPoint; aRadius: Word; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                       Trees: TKMPointDirList; BestToPlant,SecondBestToPlant: TKMPointList);
    function FindFishWater(const aLoc: TKMPoint; aRadius:integer; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits:
                           Boolean; out FishPoint: TKMPointDir): Boolean;
    function CanFindFishingWater(const aLoc: TKMPoint; aRadius:integer): Boolean;
    function ChooseTreeToPlant(const aLoc: TKMPoint):integer;
    procedure GetHouseMarks(const aLoc: TKMPoint; aHouseType: TKMHouseType; aList: TKMPointTagList);

    function WaterHasFish(const aLoc: TKMPoint): Boolean;
    function CatchFish(aLoc: TKMPointDir; TestOnly: Boolean = False): Boolean;

    procedure SetObject(const Loc: TKMPoint; ID:integer);
    procedure FallTree(const Loc: TKMPoint);
    procedure ChopTree(const Loc: TKMPoint);
    procedure RemoveObject(const Loc: TKMPoint);
    procedure RemoveObjectsKilledByRoad(const Loc: TKMPoint);

    procedure SowCorn(const Loc: TKMPoint);
    procedure CutCorn(const Loc: TKMPoint);
    procedure CutGrapes(const Loc: TKMPoint);

    procedure DecStoneDeposit(const Loc: TKMPoint);
    function DecOreDeposit(const Loc: TKMPoint; rt: TKMWareType): Boolean;

    function GetPassablePointWithinSegment(OriginPoint, TargetPoint: TKMPoint; aPassability: TKMTerrainPassability; MaxDistance: Integer = -1): TKMPoint;
    function CheckPassability(const Loc: TKMPoint; aPass: TKMTerrainPassability): Boolean;
    function HasUnit(const Loc: TKMPoint): Boolean;
    function HasVertexUnit(const Loc: TKMPoint): Boolean;
    function GetRoadConnectID(const Loc: TKMPoint): Byte;
    function GetWalkConnectID(const Loc: TKMPoint): Byte;
    function GetConnectID(aWalkConnect: TKMWalkConnect; const Loc: TKMPoint): Byte;

    function CheckAnimalIsStuck(const Loc: TKMPoint; aPass: TKMTerrainPassability; aCheckUnits: Boolean = True): Boolean;
    function GetOutOfTheWay(aUnit: Pointer; const PusherLoc: TKMPoint; aPass: TKMTerrainPassability): TKMPoint;
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

    function TileInMapCoords(X, Y: Integer; Inset: Byte = 0): Boolean; overload;
    function TileInMapCoords(aCell: TKMPoint; Inset: Byte = 0): Boolean; overload;
    function VerticeInMapCoords(X, Y: Integer; Inset: Byte = 0): Boolean; overload;
    function VerticeInMapCoords(aCell: TKMPoint; Inset: Byte = 0): Boolean; overload;
    function EnsureTileInMapCoords(X, Y: Integer; Inset: Byte = 0): TKMPoint;

    function TileGoodForIronMine(X, Y: Word): Boolean;
    function TileGoodForGoldmine(X, Y: Word): Boolean;
    function TileGoodForField(X, Y: Word): Boolean;
    function TileGoodForTree(X, Y: Word): Boolean;
    function TileIsWater(const Loc: TKMPoint): Boolean; overload;
    function TileIsWater(X, Y: Word): Boolean; overload;
    function TileIsStone(X, Y: Word): Byte;
    function TileIsSnow(X, Y: Word): Boolean;
    function TileIsCoal(X, Y: Word): Byte;
    function TileIsIron(X, Y: Word): Byte;
    function TileIsGold(X, Y: Word): Byte;
    function TileIsCornField(const Loc: TKMPoint): Boolean;
    function TileIsWineField(const Loc: TKMPoint): Boolean;
    function TileIsWalkableRoad(const Loc: TKMPoint): Boolean;
    function TileIsLocked(const aLoc: TKMPoint): Boolean;

    function TileHasStone(X, Y: Word): Boolean;
    function TileHasCoal(X, Y: Word): Boolean;
    function TileHasIron(X, Y: Word): Boolean;
    function TileHasGold(X, Y: Word): Boolean;

    function TileHasStonePart(X, Y: Word): Boolean;

    function TileIsSand(const Loc: TKMPoint): Boolean;
    function TileIsSoil(X,Y: Word): Boolean; overload;
    function TileIsSoil(const Loc: TKMPoint): Boolean; overload;
    function TileIsFactorable(const Loc: TKMPoint): Boolean;
    function TileIsWalkable(const Loc: TKMPoint): Boolean;
    function TileIsRoadable(const Loc: TKMPoint): Boolean;

    function TileCornerTerrain(aX, aY: Word; aCorner: Byte): Word;
    function TileCornersTerrains(aX, aY: Word): TKMWordArray;
    function TileCornersTerKinds(aX, aY: Word): TKMTerrainKindsArray;

    function TileHasRoad(const Loc: TKMPoint): Boolean; overload;
    function TileHasRoad(X,Y: Integer): Boolean; overload;

    function UnitsHitTest(X, Y: Word): Pointer;
    function UnitsHitTestF(const aLoc: TKMPointF): Pointer;
    function UnitsHitTestWithinRad(const aLoc: TKMPoint; MinRad, MaxRad: Single; aPlayer: TKMHandID; aAlliance: TKMAllianceType;
                                   Dir: TKMDirection; const aClosest: Boolean): Pointer;

    function ScriptTrySetTile(X, Y: Integer; aType, aRot: Byte): Boolean;
    function ScriptTrySetTileHeight(X, Y: Integer; aHeight: Byte): Boolean;
    function ScriptTrySetTileObject(X, Y: Integer; aObject: Word): Boolean;
    function ScriptTrySetTilesArray(var aTiles: array of TKMTerrainTileBrief; aRevertOnFail: Boolean; var aErrors: TKMTerrainTileChangeErrorArray): Boolean;

    function ObjectIsCorn(const Loc: TKMPoint): Boolean; overload;
    function ObjectIsCorn(X,Y: Word): Boolean; overload;

    function ObjectIsWine(const Loc: TKMPoint): Boolean; overload;
    function ObjectIsWine(X,Y: Word): Boolean; overload;

    function ObjectIsChopableTree(X,Y: Word): Boolean; overload;
    function ObjectIsChopableTree(const Loc: TKMPoint; aStage: TKMChopableAge): Boolean; overload;
    function ObjectIsChopableTree(const Loc: TKMPoint; aStages: TKMChopableAgeSet): Boolean; overload;
    function CanWalkDiagonaly(const aFrom: TKMPoint; bX, bY: SmallInt): Boolean;

    function GetCornStage(const Loc: TKMPoint): Byte; overload;
    function GetWineStage(const Loc: TKMPoint): Byte;

    function TopHill: Byte;
    procedure FlattenTerrain(const Loc: TKMPoint; aUpdateWalkConnects: Boolean = True; aIgnoreCanElevate: Boolean = False); overload;
    procedure FlattenTerrain(LocList: TKMPointList); overload;

    function ConvertCursorToMapCoord(inX,inY:single): Single;
    function FlatToHeight(inX, inY: Single): Single; overload;
    function FlatToHeight(const aPoint: TKMPointF): TKMPointF; overload;
    function HeightAt(inX, inY: Single): Single;

    procedure UpdateLighting(const aRect: TKMRect);
    procedure UpdatePassability(const aRect: TKMRect); overload;
    procedure UpdatePassability(const Loc: TKMPoint); overload;

    procedure IncAnimStep; //Lite-weight UpdateState for MapEd
    property AnimStep: Cardinal read fAnimStep;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;

    procedure UpdateState;

    class procedure WriteTileToStream(var S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic); overload;
    class procedure WriteTileToStream(var S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; var aMapDataSize: Cardinal); overload;
    class procedure ReadTileFromStream(aStream: TKMemoryStream; var aTileBasic: TKMTerrainTileBasic; aUseKaMFormat: Boolean = False);
  end;

const
  OBJ_BLOCK = 61;
  OBJ_NONE = 255;


var
  //Terrain is a globally accessible resource by so many objects
  //In rare cases local terrain is used (e.g. main menu minimap)
  gTerrain: TKMTerrain;


implementation
uses
  KM_Log, KM_HandsCollection, KM_TerrainWalkConnect, KM_Resource, KM_Units,
  KM_ResSound, KM_Sound, KM_UnitActionStay, KM_UnitWarrior, KM_TerrainPainter, KM_Houses,
  KM_ResUnits, KM_ResSprites, KM_Hand, KM_Game, KM_GameTypes, KM_ScriptingEvents, KM_Utils;


{ TKMTerrain }
constructor TKMTerrain.Create;
begin
  inherited;
  fAnimStep := 0;
  FallingTrees := TKMPointTagList.Create;
  fTileset := gRes.Tileset; //Local shortcut
end;


destructor TKMTerrain.Destroy;
begin
  FreeAndNil(FallingTrees);
  FreeAndNil(fFinder);
  inherited;
end;


//Reset whole map with default values
procedure TKMTerrain.MakeNewMap(aWidth, aHeight: Integer; aMapEditor: Boolean);
var I, K: Integer;
begin
  fMapEditor := aMapEditor;
  fMapX := Min(aWidth,  MAX_MAP_SIZE);
  fMapY := Min(aHeight, MAX_MAP_SIZE);
  fMapRect := KMRect(1, 1, fMapX, fMapY);

  for I := 1 to fMapY do
    for K := 1 to fMapX do
      with Land[I, K] do
      begin
        //Apply some random tiles for artisticity
        if KaMRandom(5, 'TKMTerrain.MakeNewMap') = 0 then
          BaseLayer.Terrain := RandomTiling[tkGrass, KaMRandom(RandomTiling[tkGrass, 0], 'TKMTerrain.MakeNewMap 2') + 1]
        else
          BaseLayer.Terrain := 0;
        LayersCnt    := 0;
        BaseLayer.Corners := [0,1,2,3];
        Height       := 30 + KaMRandom(7, 'TKMTerrain.MakeNewMap 3');  //variation in Height
        BaseLayer.Rotation     := KaMRandom(4, 'TKMTerrain.MakeNewMap 4');  //Make it random
        Obj          := OBJ_NONE;             //none
        IsCustom     := False;
        //Uncomment to enable random trees, but we don't want that for the map editor by default
        //if KaMRandom(16)=0 then Obj := ChopableTrees[KaMRandom(13)+1,4];
        TileOverlay  := toNone;
        TileLock     := tlNone;
        CornOrWine   := 0;
        Passability  := []; //Gets recalculated later
        TileOwner    := -1;
        IsUnit       := nil;
        IsVertexUnit := vuNone;
        FieldAge     := 0;
        TreeAge      := IfThen(ObjectIsChopableTree(KMPoint(K, I), caAgeFull), TREE_AGE_FULL, 0);
        Fence        := fncNone;
        FenceSide    := 0;
      end;

  fFinder := TKMTerrainFinder.Create;
  UpdateLighting(MapRect);
  UpdatePassability(MapRect);

  //Everything except roads
  UpdateWalkConnect([wcWalk, wcFish, wcWork], MapRect, True);
end;


procedure TKMTerrain.LoadFromFile(const FileName: UnicodeString; aMapEditor: Boolean);
var
  I, J, L: Integer;
  S: TKMemoryStream;
  NewX, NewY: Integer;
  UseKaMFormat: Boolean;
  TileBasic: TKMTerrainTileBasic;
begin
  fMapX := 0;
  fMapY := 0;

  if not FileExists(FileName) then Exit;

  fMapEditor := aMapEditor;

  gLog.AddTime('Loading map file: ' + FileName);

  UseKaMFormat := True;
  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(FileName);

    LoadMapHeader(S, NewX, NewY, UseKaMFormat);
    fMapX := NewX;
    fMapY := NewY;

    fMapRect := KMRect(1, 1, fMapX, fMapY);

    for I := 1 to fMapY do
      for J := 1 to fMapX do
      begin
        Land[I,J].TileOverlay  := toNone;
        Land[I,J].TileLock     := tlNone;
        Land[I,J].CornOrWine   := 0;
        Land[I,J].Passability  := []; //Gets recalculated later
        Land[I,J].TileOwner    := PLAYER_NONE;
        Land[I,J].IsUnit       := nil;
        Land[I,J].IsVertexUnit := vuNone;
        Land[I,J].FieldAge     := 0;
        Land[I,J].TreeAge      := 0;
        Land[I,J].Fence        := fncNone;
        Land[I,J].FenceSide    := 0;

        ReadTileFromStream(S, TileBasic, UseKaMFormat);

        Land[I,J].BaseLayer := TileBasic.BaseLayer;
        Land[I,J].Height := TileBasic.Height;
        Land[I,J].Obj := TileBasic.Obj;
        Land[I,J].LayersCnt := TileBasic.LayersCnt;
        Land[I,J].IsCustom  := TileBasic.IsCustom;

        for L := 0 to TileBasic.LayersCnt - 1 do
          Land[I,J].Layer[L] := TileBasic.Layer[L];

        if ObjectIsChopableTree(KMPoint(J,I), caAge1) then Land[I,J].TreeAge := 1;
        if ObjectIsChopableTree(KMPoint(J,I), caAge2) then Land[I,J].TreeAge := TREE_AGE_1;
        if ObjectIsChopableTree(KMPoint(J,I), caAge3) then Land[I,J].TreeAge := TREE_AGE_2;
        if ObjectIsChopableTree(KMPoint(J,I), caAgeFull) then Land[I,J].TreeAge := TREE_AGE_FULL;
        //Everything else is default
      end;
  finally
    S.Free;
  end;

  fFinder := TKMTerrainFinder.Create;
  UpdateLighting(MapRect);
  UpdatePassability(MapRect);

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
  MapDataSize: Cardinal;

  procedure SetNewLand(var S: TKMemoryStream; aFromX, aFromY: Word; aNewGeneratedTile: Boolean);
  var
    L: Integer;
    TileBasic: TKMTerrainTileBasic;
  begin
    // new appended terrain
    if aNewGeneratedTile then
    begin
      TileBasic.BaseLayer.Terrain  := gGame.MapEditor.TerrainPainter.PickRandomTile(tkGrass);
      TileBasic.BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.SaveToFile.SetNewLand');
      TileBasic.BaseLayer.Corners := [0,1,2,3];
      //Apply some random tiles for artisticity
      TileBasic.Height    := EnsureRange(30 + KaMRandom(7, 'TKMTerrain.SaveToFile.SetNewLand 2'), 0, 100);  //variation in Height
      TileBasic.Obj       := OBJ_NONE; // No object
      TileBasic.IsCustom  := False;
      TileBasic.LayersCnt := 0;
    end
    else
    begin
      TileBasic.BaseLayer := Land[aFromY,aFromX].BaseLayer;
      TileBasic.Height    := Land[aFromY,aFromX].Height;
      TileBasic.Obj       := Land[aFromY,aFromX].Obj;
      TileBasic.LayersCnt := Land[aFromY,aFromX].LayersCnt;
      TileBasic.IsCustom  := Land[aFromY,aFromX].IsCustom;
      for L := 0 to 2 do
        TileBasic.Layer[L] := Land[aFromY,aFromX].Layer[L];
    end;
    WriteTileToStream(S, TileBasic, MapDataSize);
  end;

  procedure WriteFileHeader(S: TKMemoryStream);
  begin
    S.Write(Integer(0));     //Indicates this map has not standart KaM format, Can use 0, as we can't have maps with 0 width
    S.WriteW(UnicodeString(GAME_REVISION)); //Write KaM version, in case we will change format in future
    S.Write(MapDataSize);
  end;

var
  S: TKMemoryStream;
  //MapInnerRect: TKMRect;
  NewGeneratedTileI, NewGeneratedTileK: Boolean;
  I, K, IFrom, KFrom: Integer;
  SizeX, SizeY: Integer;
begin
  Assert(fMapEditor, 'Can save terrain to file only in MapEd');
  ForceDirectories(ExtractFilePath(aFile));

  MapDataSize := 0;
  S := TKMemoryStream.Create;
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

    for I := 1 to SizeY do
    begin
      IFrom := EnsureRange(I - aInsetRect.Top, 1, fMapY);
      NewGeneratedTileI := IFrom <> I - aInsetRect.Top; //not InRange(I, MapInnerRect.Top, MapInnerRect.Bottom);
      for K := 1 to SizeX do
      begin
        KFrom := EnsureRange(K - aInsetRect.Left, 1, fMapX);
        NewGeneratedTileK := KFrom <> K - aInsetRect.Left;
        SetNewLand(S, KFrom, IFrom, NewGeneratedTileI or NewGeneratedTileK);
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
  var U: TKMUnit;
  begin
    U := Land[CheckY, CheckX].IsUnit;
    if (U = nil) or U.IsDeadOrDying
    or (gRes.Units[U.UnitType].DesiredPassability = tpFish) then //Fish don't care about elevation
      Result := False
    else
      Result := not CheckHeightPass(KMPoint(CheckX, CheckY), hpWalking); //All other units/animals need Walkable
  end;

var
  OldHeight: Byte;
  I, K: Integer;
begin
  //To use CheckHeightPass we must apply change then roll it back if it failed
  OldHeight := aHeight;
  //Apply change
  Land[Y, X].Height := aHeight;

  //Don't check canElevate: If scripter wants to block mines that's his choice

  //Elevation affects all 4 tiles around the vertex
  for I := -1 to 0 do
    for K := -1 to 0 do
      if TileInMapCoords(X+K, Y+I) then
        //Did this change make a unit stuck?
        if UnitWillGetStuck(X+K, Y+I)
        //Did this change elevate a house?
        or (Land[Y+I, X+K].TileLock = tlHouse) then
        begin
          //Rollback change
          Land[Y, X].Height := OldHeight;
          Result := False;
          Exit;
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
  TempRect: TKMRect;
  TempBool: Boolean;
begin
  Result := TrySetTile(X, Y, aType, aRot, TempRect, TempBool, aUpdatePassability);
end;


function TKMTerrain.TrySetTile(X, Y: Integer; aType, aRot: Integer; out aPassRect: TKMRect;
                               out aDiagonalChanged: Boolean; aUpdatePassability: Boolean = True): Boolean;
  function UnitWillGetStuck: Boolean;
  var U: TKMUnit;
  begin
    U := Land[Y, X].IsUnit;
    if (U = nil) or U.IsDeadOrDying then
      Result := False
    else
      if gRes.Units[U.UnitType].DesiredPassability = tpFish then
        Result := not fTileset.TileIsWater(aType) //Fish need water
      else
        Result := not fTileset.TileIsWalkable(aType); //All other animals need Walkable
  end;
var
  Loc: TKMPoint;
  LocRect: TKMRect;
  DoRemField: Boolean;
begin
  Assert((aType <> -1) or (aRot <> -1), 'Either terrain type or rotation should be set');
 
  Loc := KMPoint(X, Y);
  LocRect := KMRect(Loc);
  aPassRect := LocRect;
  
  //First see if this change is allowed
  //Will this change make a unit stuck?
  if UnitWillGetStuck
    //Will this change block a construction site?
    or ((Land[Y, X].TileLock in [tlFenced, tlDigged, tlHouse])
      and (not fTileSet.TileIsRoadable(aType) or not fTileset.TileIsWalkable(aType))) then
  begin
    Result := False;
    Exit;
  end;

  aDiagonalChanged := False;

  DoRemField := TileIsCornField(Loc) or TileIsWineField(Loc);
  if DoRemField then
    RemField(Loc, False, aPassRect, aDiagonalChanged, False);

  //Apply change
  if aType <> -1 then // Do not update terrain, if -1 is passed as an aType parameter
    Land[Y, X].BaseLayer.Terrain := aType;
  if aRot <> -1 then // Do not update rotation, if -1 is passed as an aRot parameter
    Land[Y, X].BaseLayer.Rotation := aRot;
 

  if DoRemField then
    UpdateFences(Loc); // after update Terrain

  if aUpdatePassability then
  begin
    UpdatePassability(aPassRect);
    UpdateWalkConnect([wcWalk, wcRoad, wcFish, wcWork], aPassRect, aDiagonalChanged);
  end;

  Result := True;
end;


function TKMTerrain.TrySetTileObject(X, Y: Integer; aObject: Word; aUpdatePassability: Boolean = True): Boolean;
var DiagonalChanged: Boolean;
begin
  Result := TrySetTileObject(X, Y, aObject, DiagonalChanged, aUpdatePassability);
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
        if (Land[Y+I, X+K].TileLock in [tlFenced, tlDigged, tlHouse]) then
        begin
          Result := True;
          Exit;
        end;
  end;

  // We do not want falling trees
  function AllowableObject: Boolean;
  begin
    // Hide falling trees
    // Invisible objects like 255 can be useful to clear specified tile (since delete object = place object 255)
    Result := (gMapElements[aObject].Stump = -1) or (aObject = OBJ_NONE);
  end;
var
  Loc: TKMPoint;
  LocRect: TKMRect;
begin
  Loc := KMPoint(X,Y);
  aDiagonalChanged := False;

  //There's no need to check conditions for 255 (NO OBJECT)
  if (aObject <> OBJ_NONE) then
  begin
    //Will this change make a unit stuck?
    if ((Land[Y, X].IsUnit <> nil) and gMapElements[aObject].AllBlocked)
      //Is this object part of a wine/corn field?
      or TileIsWineField(Loc) or TileIsCornField(Loc)
      //Is there a house/site near this object?
      or HousesNearObject
      //Is this object allowed to be placed?
      or not AllowableObject then
    begin
      Result := False;
      Exit;
    end;
  end;

  //Did block diagonal property change? (hence xor) UpdateWalkConnect needs to know
  aDiagonalChanged := gMapElements[Land[Y,X].Obj].DiagonalBlocked xor gMapElements[aObject].DiagonalBlocked;

  Land[Y, X].Obj := aObject;
  Result := True;
  //Apply change
  //UpdatePassability and UpdateWalkConnect are called in SetField so that we only use it in trees and other objects
  case aObject of
    88..124,
    126..172: // Trees - 125 is mushroom
              begin
                if ObjectIsChopableTree(Loc, caAge1) then Land[Y,X].TreeAge := 1;
                if ObjectIsChopableTree(Loc, caAge2) then Land[Y,X].TreeAge := TREE_AGE_1;
                if ObjectIsChopableTree(Loc, caAge3) then Land[Y,X].TreeAge := TREE_AGE_2;
                if ObjectIsChopableTree(Loc, caAgeFull) then Land[Y,X].TreeAge := TREE_AGE_FULL;
              end
  end;
  if aUpdatePassability then
  begin
    LocRect := KMRect(Loc);
    UpdatePassability(LocRect); //When using KMRect map bounds are checked by UpdatePassability
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(LocRect), aDiagonalChanged);
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

var 
  I, J, Terr, Rot: Integer;
  T: TKMTerrainTileBrief;
  Rect, TerrRect, HeightRect: TKMRect;
  DiagonalChangedTotal, DiagChanged: Boolean;
  BackupLand: array of array of TKMTerrainTile;
  ErrCnt: Integer;
  HasErrorOnTile: Boolean;
  ErrorTypesOnTile: TKMTileChangeTypeSet;
begin
  Result := True;
  if Length(aTiles) = 0 then Exit;

  //Initialization
  DiagonalChangedTotal := False;
  Rect := KMRECT_INVALID_TILES;
  // Use separate HeightRect, because UpdateLight invoked only when Height is changed
  HeightRect := KMRECT_INVALID_TILES;
  ErrCnt := 0;

  // make backup copy of Land only if we may need revert changes
  if aRevertOnFail then
  begin
    SetLength(BackupLand, fMapY, fMapX);
    for I := 1 to fMapY do
      for J := 1 to fMapX do
        BackupLand[I-1][J-1] := Land[I, J];
  end;

  for I := 0 to High(aTiles) do
  begin
    T := aTiles[I];

    HasErrorOnTile := False;
    ErrorTypesOnTile := [];

    if TileInMapCoords(T.X, T.Y) then
    begin
      Terr := -1;
      if T.UpdateTerrain then
        Terr := T.Terrain;
        
      Rot := -1;
      if T.UpdateRotation and InRange(T.Rotation, 0, 3) then
        Rot := T.Rotation;

      if T.UpdateTerrain or T.UpdateRotation then
      begin
        if (Terr <> -1) or (Rot <> -1) then
        begin
          // Update terrain and rotation if needed
          if TrySetTile(T.X, T.Y, Terr, Rot, TerrRect, DiagChanged, False) then
          begin
            DiagonalChangedTotal := DiagonalChangedTotal or DiagChanged;
            UpdateRectWRect(Rect, TerrRect);
          end else begin
            SetErrorNSetResult(tctTerrain, HasErrorOnTile, ErrorTypesOnTile, Result);
            SetErrorNSetResult(tctRotation, HasErrorOnTile, ErrorTypesOnTile, Result);
          end;
        end else begin
          SetErrorNSetResult(tctTerrain, HasErrorOnTile, ErrorTypesOnTile, Result);
          SetErrorNSetResult(tctRotation, HasErrorOnTile, ErrorTypesOnTile, Result);
        end;
      end;

      // Update height if needed
      if T.UpdateHeight then
      begin
        if InRange(T.Height, 0, 100) then
        begin
          if TrySetTileHeight(T.X, T.Y, T.Height, False) then
            UpdateRect(HeightRect, T.X, T.Y)
          else
            SetErrorNSetResult(tctHeight, HasErrorOnTile, ErrorTypesOnTile, Result);
        end else
          SetErrorNSetResult(tctHeight, HasErrorOnTile, ErrorTypesOnTile, Result);
      end;

      //Update object if needed
      if T.UpdateObject then
      begin
        if TrySetTileObject(T.X, T.Y, T.Obj, DiagChanged, False) then
        begin
          UpdateRect(Rect, T.X, T.Y);
          DiagonalChangedTotal := DiagonalChangedTotal or DiagChanged;
        end else
          SetErrorNSetResult(tctObject, HasErrorOnTile, ErrorTypesOnTile, Result);
      end;
    end else
    begin
      HasErrorOnTile := True;
      //When tile is out of map coordinates we treat it as all operations failure
      if T.UpdateTerrain then
        Include(ErrorTypesOnTile, tctTerrain);
      if T.UpdateHeight then
        Include(ErrorTypesOnTile, tctHeight);
      if T.UpdateObject then
        Include(ErrorTypesOnTile, tctObject);
    end;

    // Save error info, if there was some error
    if HasErrorOnTile then
    begin
      if Length(aErrors) = ErrCnt then
        SetLength(aErrors, ErrCnt + 16);
      aErrors[ErrCnt].X := T.X;
      aErrors[ErrCnt].Y := T.Y;
      aErrors[ErrCnt].ErrorsIn := ErrorTypesOnTile;
      Inc(ErrCnt);
    end;

    if not Result and aRevertOnFail then
      Break;
  end;

  if not Result and aRevertOnFail then
  begin
    //Restore backup Land, when revert needed
    for I := 1 to fMapY do
      for J := 1 to fMapX do
        Land[I, J] := BackupLand[I-1][J-1];
    SetLength(BackupLand, 0); // Release dynamic array memory. This array can be huge, so we should clear it as fast as possible
  end
  else
  begin
    // Actualize terrain for map editor (brushes have array which helps them make smooth transitions)
    if (gGame.GameMode = gmMapEd) then
      for I := 1 to fMapY do
        for J := 1 to fMapX do
          gGame.MapEditor.TerrainPainter.RMG2MapEditor(J,I, Land[I, J].BaseLayer.Terrain);

    if not KMSameRect(HeightRect, KMRECT_INVALID_TILES) then
      gTerrain.UpdateLighting(KMRectGrow(HeightRect, 2)); // Update Light only when height was changed

    gTerrain.UpdatePassability(KMRectGrowTopLeft(Rect));
    gTerrain.UpdateWalkConnect([wcWalk, wcRoad, wcFish, wcWork], KMRectGrowTopLeft(Rect), DiagonalChangedTotal);
  end;

  //Cut errors array to actual size
  if Length(aErrors) <> ErrCnt then
    SetLength(aErrors, ErrCnt);
end;


// Try to set an tile (Terrain and Rotation) from the script. Failure is an option
function TKMTerrain.ScriptTrySetTile(X, Y: Integer; aType, aRot: Byte): Boolean;
begin
  Result := TileInMapCoords(X, Y) and TrySetTile(X, Y, aType, aRot);
end;


// Try to set an tile Height from the script. Failure is an option
function TKMTerrain.ScriptTrySetTileHeight(X, Y: Integer; aHeight: Byte): Boolean;
begin
  Result := TileInMapCoords(X, Y) and TrySetTileHeight(X, Y, aHeight);
end;


// Try to set an object from the script. Failure is an option
function TKMTerrain.ScriptTrySetTileObject(X, Y: Integer; aObject: Word): Boolean;
begin
  Result := TileInMapCoords(X, Y) and TrySetTileObject(X, Y, aObject);
end;


{Check if requested tile (X,Y) is within Map boundaries}
{X,Y are unsigned int, usually called from loops, hence no TKMPoint can be used}
function TKMTerrain.TileInMapCoords(X,Y: Integer; Inset: Byte = 0): Boolean;
begin
  Result := InRange(X, 1 + Inset, fMapX - 1 - Inset) and InRange(Y, 1 + Inset, fMapY - 1 - Inset);
end;


function TKMTerrain.TileInMapCoords(aCell: TKMPoint; Inset: Byte = 0): Boolean;
begin
  Result := TileInMapCoords(aCell.X, aCell.Y, Inset);
end;


{Check if requested vertice is within Map boundaries}
{X,Y are unsigned int, usually called from loops, hence no TKMPoint can be used}
function TKMTerrain.VerticeInMapCoords(X,Y: Integer; Inset: Byte = 0): Boolean;
begin
  Result := InRange(X, 1 + Inset, fMapX - Inset) and InRange(Y, 1 + Inset, fMapY - Inset);
end;


function TKMTerrain.VerticeInMapCoords(aCell: TKMPoint; Inset: Byte = 0): Boolean;
begin
  Result := VerticeInMapCoords(aCell.X, aCell.Y, Inset);
end;


{Ensure that requested tile is within Map boundaries}
{X,Y are unsigned int, usually called from loops, hence no TKMPoint can be used}
function TKMTerrain.EnsureTileInMapCoords(X,Y: Integer; Inset: Byte = 0): TKMPoint;
begin
  Result.X := EnsureRange(X, 1 + Inset, fMapX - 1 - Inset);
  Result.Y := EnsureRange(Y, 1 + Inset, fMapY - 1 - Inset);
end;


function TKMTerrain.TileGoodForIronMine(X,Y: Word): Boolean;
var
  CornersTKinds: TKMTerrainKindsArray;
begin
  Result :=
    (fTileset.TileIsGoodForIronMine(Land[Y,X].BaseLayer.Terrain)
      and (Land[Y,X].BaseLayer.Rotation mod 4 = 0)); //only horizontal mountain edges allowed
  if not Result then
  begin
    CornersTKinds := TileCornersTerKinds(X, Y);
    Result :=
          (CornersTKinds[0] in [tkIron, tkIronMount])
      and (CornersTKinds[1] in [tkIron, tkIronMount])
      and fTileset.TileIsRoadable(BASE_TERRAIN[CornersTKinds[2]])
      and fTileset.TileIsRoadable(BASE_TERRAIN[CornersTKinds[3]]);
  end;
end;


function TKMTerrain.CanPlaceIronMine(X,Y: Word): Boolean;
begin
  Result := TileGoodForIronMine(X,Y)
    and ((Land[Y,X].Obj = OBJ_NONE) or (gMapElements[Land[Y,X].Obj].CanBeRemoved))
    and TileInMapCoords(X,Y, 1)
    and not HousesNearTile(X,Y)
    and (Land[Y,X].TileLock = tlNone)
    and CheckHeightPass(KMPoint(X,Y), hpBuildingMines);
end;


function TKMTerrain.TileGoodForGoldMine(X,Y: Word): Boolean;
var
  CornersTKinds: TKMTerrainKindsArray;
begin
  Result :=
    (fTileset.TileIsGoodForGoldMine(Land[Y,X].BaseLayer.Terrain)
      and (Land[Y,X].BaseLayer.Rotation mod 4 = 0)); //only horizontal mountain edges allowed
  if not Result then
  begin
    CornersTKinds := TileCornersTerKinds(X, Y);
    Result :=
          (CornersTKinds[0] in [tkGold, tkGoldMount])
      and (CornersTKinds[1] in [tkGold, tkGoldMount])
      and fTileset.TileIsRoadable(BASE_TERRAIN[CornersTKinds[2]])
      and fTileset.TileIsRoadable(BASE_TERRAIN[CornersTKinds[3]]);
  end;
end;


function TKMTerrain.TileGoodForField(X,Y: Word): Boolean;
begin
  Result := TileIsSoil(X,Y)
    and not gMapElements[Land[Y,X].Obj].AllBlocked
    and (Land[Y,X].TileLock = tlNone)
    and (Land[Y,X].TileOverlay <> toRoad)
    and not TileIsWineField(KMPoint(X,Y))
    and not TileIsCornField(KMPoint(X,Y))
    and CheckHeightPass(KMPoint(X,Y), hpWalking);
end;


function TKMTerrain.TileGoodForTree(X,Y: Word): Boolean;
  function IsObjectsNearby: Boolean;
  var I,K: Integer; P: TKMPoint;
  begin
    Result := False;
    for I := -1 to 1 do
      for K := -1 to 1 do
        if ((I<>0) or (K<>0)) and TileInMapCoords(X+I, Y+K) then
        begin
          P := KMPoint(X+I, Y+K);

          //Tiles next to it can't be trees/stumps
          if gMapElements[Land[P.Y,P.X].Obj].DontPlantNear then
            Result := True;

          //Tiles above or to the left can't be road/field/locked
          if (I <= 0) and (K <= 0) then
            if (Land[P.Y,P.X].TileLock <> tlNone)
            or (Land[P.Y,P.X].TileOverlay = toRoad)
            or TileIsCornField(P)
            or TileIsWineField(P) then
              Result := True;

          if Result then Exit;
        end;
  end;

  function HousesNearVertex: Boolean;
  var I,K: Integer;
  begin
    Result := False;
    for I := -1 to 1 do
    for K := -1 to 1 do
      if TileInMapCoords(X+K, Y+I)
      and (Land[Y+I,X+K].TileLock in [tlFenced,tlDigged,tlHouse]) then
      begin
        if (I+1 in [0,1]) and (K+1 in [0,1]) then //Only houses above/left of the tile
          Result := True;
      end;
  end;

begin
  //todo: Optimize above functions. Recheck UpdatePass and WC if the check Rects can be made smaller

  Result := TileIsSoil(X,Y)
    and not IsObjectsNearby //This function checks surrounding tiles
    and (Land[Y,X].TileLock = tlNone)
    and (X > 1) and (Y > 1) //Not top/left of map, but bottom/right is ok
    and (Land[Y,X].TileOverlay <> toRoad)
    and not HousesNearVertex
    //Woodcutter will dig out other object in favour of his tree
    and ((Land[Y,X].Obj = OBJ_NONE) or (gMapElements[Land[Y,X].Obj].CanBeRemoved))
    and CheckHeightPass(KMPoint(X,Y), hpWalking);
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
  Result := IfThen(Land[Y, X].LayersCnt = 0, fTileset.TileIsStone(Land[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileIsCoal(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].LayersCnt = 0, fTileset.TileIsCoal(Land[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileIsIron(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].LayersCnt = 0, fTileset.TileIsIron(Land[Y, X].BaseLayer.Terrain), 0);
end;


function TKMTerrain.TileIsGold(X,Y: Word): Byte;
begin
  Result := IfThen(Land[Y, X].LayersCnt = 0, fTileset.TileIsGold(Land[Y, X].BaseLayer.Terrain), 0);
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


function TKMTerrain.TileHasStonePart(X, Y: Word): Boolean;
var
  K: Integer;
  CornersTerKinds: TKMTerrainKindsArray;
begin
  Result := False;
  CornersTerKinds := TileCornersTerKinds(X,Y);
  for K := 0 to 3 do
    if CornersTerKinds[K] = tkStone then
    begin
      Result := True;
      Exit;
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


function TKMTerrain.TileHasParameter(X,Y: Word; aCheckTileFunc: TBooleanWordFunc; aAllow2CornerTiles: Boolean = False): Boolean;
const
  PROHIBIT_TERKINDS: array[0..1] of TKMTerrainKind = (tkLava, tkAbyss);
var
  I, K, Cnt: Integer;
  Corners: TKMTerrainKindsArray;
begin
  Result := False;

  if not TileInMapCoords(X, Y) then Exit;

  if Land[Y,X].LayersCnt = 0 then
    Result := aCheckTileFunc(Land[Y, X].BaseLayer.Terrain)
  else
  begin
    Cnt := 0;
    Corners := TileCornersTerKinds(X,Y);
    for K := 0 to 3 do
    begin
      for I := 0 to High(PROHIBIT_TERKINDS) do
        if Corners[K] = PROHIBIT_TERKINDS[I] then
          Exit(False);

      if aCheckTileFunc(BASE_TERRAIN[Corners[K]]) then
        Inc(Cnt);
    end;

    //Consider tile has parameter if it has 3 corners with that parameter or if it has 2 corners and base layer has the parameter
    Result := (Cnt >= 3) or (aAllow2CornerTiles and (Cnt = 2) and aCheckTileFunc(Land[Y, X].BaseLayer.Terrain));
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
//  Result := fTileset.TileIsWalkable(Land[Loc.Y, Loc.X].BaseLayer.Terrain);
//  for L := 0 to Land[Loc.Y, Loc.X].LayersCnt - 1 do
//  begin
//    if not Result then Exit;
//
//    Ter := Land[Loc.Y, Loc.X].Layer[L].Terrain;
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
  Result := TileHasParameter(Loc.X, Loc.Y, fTileset.TileIsRoadable);
//  Result := fTileset.TileIsRoadable(Land[Loc.Y, Loc.X].BaseLayer.Terrain);
//  for L := 0 to Land[Loc.Y, Loc.X].LayersCnt - 1 do
//  begin
//    if not Result then Exit;
//
//    Ter := Land[Loc.Y, Loc.X].Layer[L].Terrain;
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
  Result := TileInMapCoords(X, Y) and (Land[Y, X].TileOverlay = toRoad);
end;


//Check if the tile is a corn field
function TKMTerrain.TileIsCornField(const Loc: TKMPoint): Boolean;
begin
  Result := False;
  if not TileInMapCoords(Loc.X,Loc.Y) then
    Exit;
  //Tile can't be used as a field if there is road or any other overlay
  if not fMapEditor then
    Result := fTileset.TileIsCornField(Land[Loc.Y, Loc.X].BaseLayer.Terrain)
              and (Land[Loc.Y,Loc.X].TileOverlay = toNone)
  else
    Result := (Land[Loc.Y,Loc.X].CornOrWine = 1);
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
    Result := fTileset.TileIsWineField(Land[Loc.Y, Loc.X].BaseLayer.Terrain)
              and (Land[Loc.Y,Loc.X].TileOverlay = toNone)
              and ObjectIsWine(Loc)
  else
    Result := (Land[Loc.Y,Loc.X].CornOrWine = 2);
end;


//Check if the tile is a walkable road
function TKMTerrain.TileIsWalkableRoad(const Loc: TKMPoint): Boolean;
begin
  Result := False;
  if not TileInMapCoords(Loc.X,Loc.Y) then
    Exit;
  // Is map editor OK with this?
  Result := (tpWalkRoad in Land[Loc.Y,Loc.X].Passability);
end;   


//Check if this tile can be factored
function TKMTerrain.TileIsFactorable(const Loc: TKMPoint): Boolean;
begin
  Result := TileInMapCoords(Loc.X,Loc.Y) and fTileset.TileIsFactorable(Land[Loc.Y, Loc.X].BaseLayer.Terrain);
end;


function TKMTerrain.TileIsLocked(const aLoc: TKMPoint): Boolean;
var
  U: TKMUnit;
begin
  U := Land[aLoc.Y,aLoc.X].IsUnit;
  //Action=nil can happen due to calling TileIsLocked during Unit.UpdateState.
  //Checks for Action=nil happen elsewhere, this is not the right place.
  if (U <> nil) and (U.Action = nil) then
    Result := False
  else
    Result := (U <> nil) and (U.Action.Locked);
end;


//Get tile corner terrain id
function TKMTerrain.TileCornerTerrain(aX, aY: Word; aCorner: Byte): Word;
const
  TOO_BIG_VALUE = 10000;
var
  L: Integer;
begin
  Assert(InRange(aCorner, 0, 3), 'aCorner = ' + IntToStr(aCorner) + ' is not in range [0-3]');
  Result := TOO_BIG_VALUE;
  with gTerrain.Land[aY,aX] do
  begin
    if aCorner in BaseLayer.Corners then
      Result := BASE_TERRAIN[TILE_CORNERS_TERRAIN_KINDS[BaseLayer.Terrain, (aCorner + 4 - BaseLayer.Rotation) mod 4]]
    else
      for L := 0 to LayersCnt - 1 do
        if aCorner in Layer[L].Corners then
          Result := BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain).TerKind];
  end;
  Assert(Result <> TOO_BIG_VALUE, Format('[TileCornerTerrain] Can''t determine tile [%d:%d] terrain at Corner [%d]', [aX, aY, aCorner]));
end;


//Get tile corners terrain id
function TKMTerrain.TileCornersTerrains(aX, aY: Word): TKMWordArray;
var
  K: Integer;
  TKinds: TKMTerrainKindsArray;
begin
  SetLength(Result, 4);
  TKinds := TileCornersTerKinds(aX, aY);
  for K := 0 to 3 do
    Result[K] := BASE_TERRAIN[TKinds[K]];
end;


//Get tile corners terrain kinds
function TKMTerrain.TileCornersTerKinds(aX, aY: Word): TKMTerrainKindsArray;
var
  K, L: Integer;
begin
  SetLength(Result, 4);
  for K := 0 to 3 do
  begin
    Result[K] := tkCustom;
    with gTerrain.Land[aY,aX] do
    begin
      if K in BaseLayer.Corners then
        Result[K] := TILE_CORNERS_TERRAIN_KINDS[BaseLayer.Terrain, (K + 4 - BaseLayer.Rotation) mod 4]
      else
        for L := 0 to LayersCnt - 1 do
          if K in Layer[L].Corners then
          begin
            Result[K] := gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain).TerKind;
            Break;
          end;
    end;
  end;
end;


//Check if there's unit on the tile
//Note that IsUnit refers to where unit started walking to, not the actual unit position
//(which is what we used in unit interaction), so check all 9 tiles to get accurate result
function TKMTerrain.UnitsHitTest(X,Y: Word): Pointer;
var
  I, K: Integer;
  U: TKMUnit;
begin
  Result := nil;
  for I := max(Y - 1, 1) to Min(Y + 1, fMapY) do
  for K := max(X - 1, 1) to Min(X + 1, fMapX) do
  begin
    U := Land[I,K].IsUnit;
    if (U <> nil) and U.HitTest(X,Y) then
      Result := Land[I,K].IsUnit;
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
    U := Land[I,K].IsUnit;
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
  BoundsRect: TKMRect;
  dX,dY: Integer;
  RequiredMaxRad: Single;
  U: TKMUnit;
  P: TKMPoint;
  WCount, CCount, InitialSize: Integer;
  W, C: TKMUnitArray;
begin
  WCount := 0;
  CCount := 0;

  if aClosest then
    InitialSize := 1 //We only need to keep 1 result
  else
    InitialSize := 32; //Should be enough most times, Append will add more if needed

  SetLength(W, InitialSize);
  SetLength(C, InitialSize);

  //This function sets LowX, LowY, HighX, HighY based on the direction
  BoundsRect := Get90DegreeSectorRect;

  for I := BoundsRect.Top to BoundsRect.Bottom do
  for K := BoundsRect.Left to BoundsRect.Right do
  begin
    U := Land[I,K].IsUnit;
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
    and (KMLengthSqr(aLoc, KMPoint(K,I)) >= KMLengthSqr(aLoc, W[0].CurrPosition)) then
      Continue; //Since we check left-to-right we can't exit just yet (there are possible better enemies below)

    //In KaM archers can shoot further than sight radius (shoot further into explored areas)
    //so CheckTileRevelation is required, we can't remove it to optimise.
    //But because it will not invalidate many candidates, check it late so other checks can do their work first
    if (gHands[aPlayer].FogOfWar.CheckTileRevelation(K,I) <> 255) then Continue;

    //This unit could be on a different tile next to KMPoint(k,i), so we cannot use that anymore.
    //There was a crash caused by VertexUsageCompatible checking (k,i) instead of U.CurrPosition.
    //In that case aLoc = (37,54) and k,i = (39;52) but U.CurrPosition = (38;53).
    //This shows why you can't use (k,i) in checks because it is distance >2 from aLoc! (in melee fight)
    P := U.CurrPosition;

    RequiredMaxRad := MaxRad;
    if (MaxRad = 1) and KMStepIsDiag(aLoc, P) then
      RequiredMaxRad := 1.42; //Use diagonal radius sqrt(2) instead

    if CanWalkDiagonaly(aLoc, P.X, P.Y)
    and ((Abs(aLoc.X - P.X) <> 1)
          or (Abs(aLoc.Y - P.Y) <> 1)
          or VertexUsageCompatible(aLoc, P)
        )
    and InRange(KMLength(KMPointF(aLoc), U.PositionF), MinRad, RequiredMaxRad) //Unit's exact position must be close enough
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
          Append(W, WCount, U)
        else
          Append(C, CCount, U);
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
    if WCount > 0 then
      Result := W[KaMRandom(WCount, 'TKMTerrain.UnitsHitTestWithinRad')]
    else
      if CCount > 0 then
        Result := C[KaMRandom(CCount, 'TKMTerrain.UnitsHitTestWithinRad 2')]
      else
        Result := nil;
  end;
end;


function TKMTerrain.ObjectIsChopableTree(X,Y: Word): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsChoppableTree(Land[Y,X].Obj);
end;


function TKMTerrain.ObjectIsChopableTree(const Loc: TKMPoint; aStage: TKMChopableAge): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsChoppableTree(Land[Loc.Y,Loc.X].Obj, aStage);
end;


function TKMTerrain.ObjectIsChopableTree(const Loc: TKMPoint; aStages: TKMChopableAgeSet): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsChoppableTree(Land[Loc.Y,Loc.X].Obj, aStages);
end;


function TKMTerrain.ObjectIsWine(const Loc: TKMPoint): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsWine(Land[Loc.Y,Loc.X].Obj)
end;


function TKMTerrain.ObjectIsWine(X,Y: Word): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsWine(Land[Y,X].Obj);
end;


function TKMTerrain.ObjectIsCorn(const Loc: TKMPoint): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsCorn(Land[Loc.Y,Loc.X].Obj)
end;


function TKMTerrain.ObjectIsCorn(X,Y: Word): Boolean;
begin
  Result := KM_ResMapElements.ObjectIsCorn(Land[Y,X].Obj);
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
    Result := not gMapElements[Land[bY, bX].Obj].DiagonalBlocked              //     B
  else
  if (aFrom.X < bX) and (aFrom.Y > bY) then                                   //     B
    Result := not gMapElements[Land[bY+1, bX].Obj].DiagonalBlocked            //   A
  else
  if (aFrom.X > bX) and (aFrom.Y > bY) then                                   //   B
    Result := not gMapElements[Land[aFrom.Y, aFrom.X].Obj].DiagonalBlocked    //     A
  else
  if (aFrom.X > bX) and (aFrom.Y < bY) then                                   //     A
    Result := not gMapElements[Land[aFrom.Y+1, aFrom.X].Obj].DiagonalBlocked; //   B
end;


//Place lock on tile, any new TileLock replaces old one, thats okay
procedure TKMTerrain.SetTileLock(const aLoc: TKMPoint; aTileLock: TKMTileLock);
var
  R: TKMRect;
begin
  Assert(aTileLock in [tlDigged, tlRoadWork, tlFieldWork], 'We expect only these 3 locks, that affect only 1 tile an don''t change neighbours Passability');

  Land[aLoc.Y, aLoc.X].TileLock := aTileLock;
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
  Assert(Land[aLoc.Y, aLoc.X].TileLock in [tlDigged, tlRoadWork, tlFieldWork], 'We expect only these 3 locks, that affect only 1 tile an don''t change neighbours Passability');

  Land[aLoc.Y, aLoc.X].TileLock := tlNone;
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
  Bounds: TKMRect;
  HasBounds: Boolean;
begin
  if aList.Count = 0 then Exit; //Nothing to be done

  for I := 0 to aList.Count - 1 do
  begin
    Y2 := aList[I].Y;
    X2 := aList[I].X;

    Land[Y2, X2].TileOwner   := aOwner;
    Land[Y2, X2].TileOverlay := toRoad;
    Land[Y2, X2].FieldAge    := 0;

    if gMapElements[Land[Y2, X2].Obj].WineOrCorn then
      RemoveObject(aList[I]);

    RemoveObjectsKilledByRoad(aList[I]);
    UpdateFences(aList[I]);
  end;

  HasBounds := aList.GetBounds(Bounds);
  Assert(HasBounds);

  //Grow the bounds by extra tile because some passabilities
  //depend on road nearby (e.g. CanPlantTree)
  UpdatePassability(KMRectGrowBottomRight(Bounds));

  //Roads don't affect wcWalk or wcFish
  if aUpdateWalkConnects then
    UpdateWalkConnect([wcRoad], Bounds, False);
end;


procedure TKMTerrain.RemRoad(const Loc: TKMPoint);
begin
  Land[Loc.Y,Loc.X].TileOwner := -1;
  Land[Loc.Y,Loc.X].TileOverlay := toNone;
  Land[Loc.Y,Loc.X].FieldAge  := 0;
  UpdateFences(Loc);
  UpdatePassability(KMRectGrowBottomRight(KMRect(Loc)));

  //Roads don't affect wcWalk or wcFish
  UpdateWalkConnect([wcRoad], KMRect(Loc), False);
end;


procedure TKMTerrain.RemField(const Loc: TKMPoint; aDoUpdatePassNWalk: Boolean;   
                              out aUpdatePassRect: TKMRect; out aDiagObjectChanged: Boolean;
                              aDoUpdateFences: Boolean);
begin
  Land[Loc.Y,Loc.X].TileOwner := -1;
  Land[Loc.Y,Loc.X].TileOverlay := toNone;

  if fMapEditor then
  begin
    Land[Loc.Y,Loc.X].CornOrWine := 0;
    Land[Loc.Y,Loc.X].CornOrWineTerrain := 0;
  end;

  if Land[Loc.Y,Loc.X].Obj in [54..59] then
  begin
    Land[Loc.Y,Loc.X].Obj := OBJ_NONE; //Remove corn/wine
    aDiagObjectChanged := True;
  end
  else
    aDiagObjectChanged := False;
    
  Land[Loc.Y,Loc.X].FieldAge := 0;

  if aDoUpdateFences then
    UpdateFences(Loc);
    
  aUpdatePassRect := KMRectGrow(KMRect(Loc),1);
  if aDoUpdatePassNWalk then
  begin
    UpdatePassability(aUpdatePassRect);

    //Update affected WalkConnect's
    UpdateWalkConnect([wcWalk,wcRoad,wcWork], aUpdatePassRect, aDiagObjectChanged); //Winefields object block diagonals
  end;
end;


procedure TKMTerrain.RemField(const Loc: TKMPoint);
var DiagObjectChanged: Boolean;
begin
  Land[Loc.Y,Loc.X].TileOwner := -1;
  Land[Loc.Y,Loc.X].TileOverlay := toNone;

  if fMapEditor then
  begin
    Land[Loc.Y,Loc.X].CornOrWine := 0;
    Land[Loc.Y,Loc.X].CornOrWineTerrain := 0;
  end;

  if Land[Loc.Y,Loc.X].Obj in [54..59] then
  begin
    Land[Loc.Y,Loc.X].Obj := OBJ_NONE; //Remove corn/wine
    DiagObjectChanged := True;
  end
  else
    DiagObjectChanged := False;
  Land[Loc.Y,Loc.X].FieldAge := 0;
  UpdateFences(Loc);
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));

  //Update affected WalkConnect's
  UpdateWalkConnect([wcWalk,wcRoad,wcWork], KMRectGrow(KMRect(Loc),1), DiagObjectChanged); //Winefields object block diagonals
end;


procedure TKMTerrain.ClearPlayerLand(aPlayer: TKMHandID);
var
  I, K: Integer;
  KMPoint: TKMPoint;
begin
  for I := 1 to fMapY do
    for K := 1 to fMapX do
      if (Land[I, K].TileOwner = aPlayer) then
      begin
        KMPoint.X := K;
        KMPoint.Y := I;

        if (Land[I, K].Obj <> OBJ_NONE) then
        begin
          if TileIsCornField(KMPoint) and (GetCornStage(KMPoint) in [4,5]) then
            SetField(KMPoint, Land[I, K].TileOwner, ftCorn, 3)  // For corn, when delete corn object reduce field stage to 3
          else if TileIsWineField(KMPoint) then
            RemField(KMPoint)
          else
            SetObject(KMPoint, OBJ_NONE);
        end;

        if Land[I, K].TileOverlay = toRoad then
          RemRoad(KMPoint);
        if TileIsCornField(KMPoint) or TileIsWineField(KMPoint) then
          RemField(KMPoint);
      end;

end;


procedure TKMTerrain.RemovePlayer(aPlayer: TKMHandID);
var
  I, K: Word;
begin
  for I := 1 to fMapY do
    for K := 1 to fMapX do
      if Land[I, K].TileOwner > aPlayer then
        Land[I, K].TileOwner := Pred(Land[I, K].TileOwner)
      else if Land[I, K].TileOwner = aPlayer then
        Land[I, K].TileOwner := -1;
end;


procedure TKMTerrain.SetField_Init(const Loc: TKMPoint; aOwner: TKMHandID);
begin
  Land[Loc.Y,Loc.X].TileOwner   := aOwner;
  Land[Loc.Y,Loc.X].TileOverlay := toNone;
  Land[Loc.Y,Loc.X].FieldAge    := 0;
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

  Land[Loc.Y,Loc.X].TileOverlay := toRoad;

  SetField_Complete(Loc, ftRoad);
  gScriptEvents.ProcRoadBuilt(aOwner, Loc.X, Loc.Y);
end;


procedure TKMTerrain.SetInitWine(const Loc: TKMPoint; aOwner: TKMHandID);
begin
  SetField_Init(Loc, aOwner);

  Land[Loc.Y,Loc.X].BaseLayer.Terrain  := 55;
  Land[Loc.Y,Loc.X].BaseLayer.Rotation := 0;

  SetField_Complete(Loc, ftInitWine);
end;


procedure TKMTerrain.IncDigState(const Loc: TKMPoint);
begin
  case Land[Loc.Y,Loc.X].TileOverlay of
    toDig3: Land[Loc.Y,Loc.X].TileOverlay := toDig4;
    toDig2: Land[Loc.Y,Loc.X].TileOverlay := toDig3;
    toDig1: Land[Loc.Y,Loc.X].TileOverlay := toDig2;
    else     Land[Loc.Y,Loc.X].TileOverlay := toDig1;
  end;
end;


procedure TKMTerrain.ResetDigState(const Loc: TKMPoint);
begin
  Land[Loc.Y,Loc.X].TileOverlay:=toNone;
end;


{ Finds a winefield ready to be picked }
function TKMTerrain.FindWineField(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; out FieldPoint: TKMPointDir): Boolean;
var
  I: Integer;
  ValidTiles: TKMPointList;
  NearTiles, FarTiles: TKMPointDirList;
  P: TKMPoint;
begin
  ValidTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, ValidTiles);

  NearTiles := TKMPointDirList.Create;
  FarTiles := TKMPointDirList.Create;
  for I := 0 to ValidTiles.Count - 1 do
  begin
    P := ValidTiles[I];
    if not KMSamePoint(aAvoidLoc,P) then
      if TileIsWineField(P) then
        if Land[P.Y,P.X].FieldAge = CORN_AGE_MAX then
          if not TileIsLocked(P) then //Taken by another farmer
            if Route_CanBeMade(aLoc, P, tpWalk, 0) then
            begin
              if KMLengthSqr(aLoc, P) <= Sqr(aRadius div 2) then
                NearTiles.Add(KMPointDir(P, dirNA))
              else
                FarTiles.Add(KMPointDir(P, dirNA));
            end;
  end;

  //Prefer close tiles to reduce inefficiency with shared fields
  Result := NearTiles.GetRandom(FieldPoint);
  if not Result then
    Result := FarTiles.GetRandom(FieldPoint);

  NearTiles.Free;
  FarTiles.Free;
  ValidTiles.Free;
end;


{ Finds a corn field }
function TKMTerrain.FindCornField(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                                  out PlantAct: TKMPlantAct; out FieldPoint: TKMPointDir): Boolean;
var
  I: Integer;
  ValidTiles, NearTiles, FarTiles: TKMPointList;
  P: TKMPoint;
begin
  ValidTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, ValidTiles);

  NearTiles := TKMPointList.Create;
  FarTiles := TKMPointList.Create;
  for I := 0 to ValidTiles.Count - 1 do
  begin
    P := ValidTiles[i];
    if not KMSamePoint(aAvoidLoc,P) then
      if TileIsCornField(P) then
        if((aPlantAct in [taAny, taPlant]) and (Land[P.Y,P.X].FieldAge = 0)) or
          ((aPlantAct in [taAny, taCut])   and (Land[P.Y,P.X].FieldAge = CORN_AGE_MAX)) then
          if not TileIsLocked(P) then //Taken by another farmer
            if Route_CanBeMade(aLoc, P, tpWalk, 0) then
            begin
              if KMLengthSqr(aLoc, P) <= Sqr(aRadius div 2) then
                NearTiles.Add(P)
              else
                FarTiles.Add(P);
            end;
  end;

  //Prefer close tiles to reduce inefficiency with shared fields
  Result := NearTiles.GetRandom(P);
  if not Result then
    Result := FarTiles.GetRandom(P);

  FieldPoint := KMPointDir(P, dirNA);
  NearTiles.Free;
  FarTiles.Free;
  ValidTiles.Free;
  if not Result then
    PlantAct := taAny
  else
    if Land[FieldPoint.Loc.Y,FieldPoint.Loc.X].FieldAge = CORN_AGE_MAX then
      PlantAct := taCut
    else
      PlantAct := taPlant;
end;


{Find closest harvestable deposit of Stone}
{Return walkable tile below Stone deposit}
function TKMTerrain.FindStone(const aLoc: TKMPoint; aRadius: Byte; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                              out StonePoint: TKMPointDir): Boolean;
var
  I: Integer;
  ValidTiles: TKMPointList;
  ChosenTiles: TKMPointList;
  P: TKMPoint;
begin
  ValidTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, ValidTiles);

  ChosenTiles := TKMPointList.Create;
  for I := 0 to ValidTiles.Count - 1 do
  begin
    P := ValidTiles[I];
    if (P.Y >= 2) //Can't mine stone from top row of the map (don't call TileIsStone with Y=0)
    and not KMSamePoint(aAvoidLoc, P)
    and TileHasStone(P.X, P.Y - 1)
    and (aIgnoreWorkingUnits or not TileIsLocked(P)) //Already taken by another stonemason
    and Route_CanBeMade(aLoc, P, tpWalk, 0) then
      ChosenTiles.Add(P);
  end;

  Result := ChosenTiles.GetRandom(P);
  StonePoint := KMPointDir(P, dirN);
  ChosenTiles.Free;
  ValidTiles.Free;
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
  MiningRect: TKMRect;

begin
  Assert(gGame.IsMapEditor, 'Its allowed to use this method only from MapEd for now...');
  Assert(Length(aPoints) = 3, 'Wrong length of Points array: ' + IntToStr(Length(aPoints)));

  if not (aRes in [wtIronOre, wtGoldOre, wtCoal]) then
    raise ELocError.Create('Wrong resource as Ore', aLoc);

  MiningRect := GetMiningRect(aRes);

  for I := Max(aLoc.Y - MiningRect.Top, 1) to Min(aLoc.Y + MiningRect.Bottom, fMapY - 1) do
    for K := Max(aLoc.X - MiningRect.Left, 1) to Min(aLoc.X + MiningRect.Right, fMapX - 1) do
    begin
      if ((aRes = wtIronOre)   and TileHasIron(K,I))
        or ((aRes = wtGoldOre) and TileHasGold(K,I))
        or ((aRes = wtCoal)    and TileHasCoal(K,I)) then
      begin
        //Poorest ore gets mined in range - 2
        if InRange(I - aLoc.Y, - MiningRect.Top + 2, MiningRect.Bottom - 2)
          and InRange(K - aLoc.X, - MiningRect.Left + 2, MiningRect.Right - 2) then
            aPoints[0].Add(KMPoint(K, I))
        //Second poorest ore gets mined in range - 1
        else
        if InRange(I - aLoc.Y, - MiningRect.Top + 1, MiningRect.Bottom - 1)
          and InRange(K - aLoc.X, - MiningRect.Left + 1, MiningRect.Right - 1) then
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
  MiningRect: TKMRect;
  R1,R2,R3,R3_2,R4,R5: Integer; //Ore densities
begin
  if not (aRes in [wtIronOre, wtGoldOre, wtCoal]) then
    raise ELocError.Create('Wrong resource as Ore', aLoc);

  Assert(Length(aPoints) = ORE_MAX_TYPES_CNT, 'Wrong length of Points array: ' + IntToStr(Length(aPoints)));

  MiningRect := GetMiningRect(aRes);

  //These values have been measured from KaM
  case aRes of
    wtGoldOre: begin R1:=144; R2:=145; R3:=146; R3_2:= -1; R4:=147; R5:= -1; end;
    wtIronOre: begin R1:=148; R2:=149; R3:=150; R3_2:=259; R4:=151; R5:=260; end;
    wtCoal:    begin R1:=152; R2:=153; R3:=154; R3_2:= -1; R4:=155; R5:=263; end;
    else        begin R1:= -1; R2:= -1; R3:= -1; R3_2:= -1; R4:= -1; R5:= -1; end;
  end;

  for I := Max(aLoc.Y - MiningRect.Top, 1) to Min(aLoc.Y + MiningRect.Bottom, fMapY - 1) do
    for K := Max(aLoc.X - MiningRect.Left, 1) to Min(aLoc.X + MiningRect.Right, fMapX - 1) do
    begin
      if Land[I, K].BaseLayer.Terrain = R1 then
      begin
        //Poorest ore gets mined in range - 2
        if InRange(I - aLoc.Y, - MiningRect.Top + 2, MiningRect.Bottom - 2) then
          if InRange(K - aLoc.X, - MiningRect.Left + 2, MiningRect.Right - 2) then
            aPoints[0].Add(KMPoint(K, I));
      end
      else if Land[I, K].BaseLayer.Terrain = R2 then
      begin
        //Second poorest ore gets mined in range - 1
        if InRange(I - aLoc.Y, - MiningRect.Top + 1, MiningRect.Bottom - 1) then
          if InRange(K - aLoc.X, - MiningRect.Left + 1, MiningRect.Right - 1) then
            aPoints[1].Add(KMPoint(K, I));
      end
      else if (Land[I, K].BaseLayer.Terrain = R3)
        or (Land[I, K].BaseLayer.Terrain = R3_2) then
        //Always mine second richest ore
        aPoints[2].Add(KMPoint(K, I))
      else if Land[I, K].BaseLayer.Terrain = R4 then
        // Always mine richest ore
        aPoints[3].Add(KMPoint(K, I))
      else if Land[I, K].BaseLayer.Terrain = R5 then
        // Always mine the most richest ore
        aPoints[4].Add(KMPoint(K, I));
    end;
end;


function TKMTerrain.ChooseCuttingDirection(const aLoc, aTree: TKMPoint; out CuttingPoint: TKMPointDir): Boolean;
var I, K, BestSlope, Slope: Integer;
begin
  BestSlope := MaxInt;
  Result := False; //It is already tested that we can walk to the tree, but double-check

  for I:=-1 to 0 do for K:=-1 to 0 do
  if Route_CanBeMade(aLoc, KMPoint(aTree.X+K, aTree.Y+I), tpWalk, 0) then
  begin
    Slope := Round(HeightAt(aTree.X+K-0.5, aTree.Y+I-0.5) * CELL_HEIGHT_DIV) - Land[aTree.Y, aTree.X].Height;
    //Cutting trees which are higher than us from the front looks visually poor, (axe hits ground) so avoid it where possible
    if (I = 0) and (Slope < 0) then Slope := Slope - 100; //Make it worse but not worse than initial BestSlope
    if Abs(Slope) < BestSlope then
    begin
      CuttingPoint := KMPointDir(aTree.X+K, aTree.Y+I, KMGetVertexDir(K, I));
      Result := True;
      BestSlope := Abs(Slope);
    end;
  end;
end;


function TKMTerrain.CanFindTree(const aLoc: TKMPoint; aRadius: Word; aOnlyAgeFull: Boolean = False): Boolean;
var
  ValidTiles: TKMPointList;
  I: Integer;
  T: TKMPoint;
  CuttingPoint: TKMPointDir;
begin
  Result := False;
  //Scan terrain and add all trees/spots into lists
  ValidTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, ValidTiles);
  for I := 0 to ValidTiles.Count - 1 do
  begin
     //Store in temp variable for speed
    T := ValidTiles[I];

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
    and ChooseCuttingDirection(aLoc, T, CuttingPoint) then
    begin
      Result := True;
      Break;
    end;
  end;
  ValidTiles.Free;
end; 


//Return location of a Tree or a place to plant a tree depending on TreeAct
//taChop - Woodcutter wants to get a Tree because he went from home with an axe
//        (maybe his first target was already chopped down, so he either needs a tree or will go home)
//taPlant - Woodcutter specifically wants to get an empty place to plant a Tree
//taAny - Anything will do since Woodcutter is querying from home
//Result indicates if desired TreeAct place was found successfully
procedure TKMTerrain.FindTree(const aLoc: TKMPoint; aRadius: Word; const aAvoidLoc: TKMPoint; aPlantAct: TKMPlantAct;
                              Trees: TKMPointDirList; BestToPlant, SecondBestToPlant: TKMPointList);
var
  ValidTiles: TKMPointList;
  I: Integer;
  T: TKMPoint;
  CuttingPoint: TKMPointDir;
begin
  //Why do we use 3 lists instead of one like Corn does?
  //Because we should always prefer stumps over empty places
  //even if there's only 1 stump - we choose it

  //Scan terrain and add all trees/spots into lists
  ValidTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, ValidTiles);
  for I := 0 to ValidTiles.Count - 1 do
  begin
     //Store in temp variable for speed
    T := ValidTiles[I];

    if (KMLengthDiag(aLoc, T) <= aRadius)
    and not KMSamePoint(aAvoidLoc, T) then
    begin

      //Grownup tree
      if (aPlantAct in [taCut, taAny])
      and ObjectIsChopableTree(T, caAgeFull)
      and (Land[T.Y,T.X].TreeAge >= TREE_AGE_FULL)
      //Woodcutter could be standing on any tile surrounding this tree
      and not TileIsLocked(T)
      and ((T.X = 1) or not TileIsLocked(KMPoint(T.X-1, T.Y))) //if K=1, K-1 will be off map
      and ((T.Y = 1) or not TileIsLocked(KMPoint(T.X, T.Y-1)))
      and ((T.X = 1) or (T.Y = 1) or not TileIsLocked(KMPoint(T.X-1, T.Y-1)))
      and Route_CanBeMadeToVertex(aLoc, T, tpWalk) then
        if ChooseCuttingDirection(aLoc, T, CuttingPoint) then
          Trees.Add(CuttingPoint); //Tree

      if (aPlantAct in [taPlant, taAny])
      and TileGoodForTree(T.X, T.Y)
      and Route_CanBeMade(aLoc, T, tpWalk, 0)
      and not TileIsLocked(T) then //Taken by another woodcutter
        if ObjectIsChopableTree(T, caAgeStump) then
          BestToPlant.Add(T) //Prefer to dig out and plant on stumps to avoid cluttering whole area with em
        else
          SecondBestToPlant.Add(T); //Empty space and other objects that can be dug out (e.g. mushrooms) if no other options available
    end;
  end;
  ValidTiles.Free;
end;


{Find seaside}
{Return walkable tile nearby}
function TKMTerrain.FindFishWater(const aLoc: TKMPoint; aRadius: Integer; const aAvoidLoc: TKMPoint; aIgnoreWorkingUnits: Boolean;
                                  out FishPoint: TKMPointDir): Boolean;
var I,J,K: Integer;
    P: TKMPoint;
    ValidTiles: TKMPointList;
    ChosenTiles: TKMPointDirList;
begin
  ValidTiles := TKMPointList.Create;
  fFinder.GetTilesWithinDistance(aLoc, aRadius, tpWalk, ValidTiles);

  ChosenTiles := TKMPointDirList.Create;
  for I := 0 to ValidTiles.Count - 1 do
  begin
    P := ValidTiles[I];
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

  Result := ChosenTiles.GetRandom(FishPoint);
  ChosenTiles.Free;
  ValidTiles.Free;
end;


function TKMTerrain.CanFindFishingWater(const aLoc: TKMPoint; aRadius: Integer): Boolean;
var I,K:integer;
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


function TKMTerrain.ChooseTreeToPlant(const aLoc: TKMPoint):integer;
begin
  //This function randomly chooses a tree object based on the terrain type. Values matched to KaM, using all soil tiles.
  case Land[aLoc.Y,aLoc.X].BaseLayer.Terrain of
    0..3,5,6,8,9,11,13,14,18,19,56,57,66..69,72..74,84..86,93..98,180,188: Result := ChopableTrees[1+KaMRandom(7, 'TKMTerrain.ChooseTreeToPlant'), caAge1]; //Grass (oaks, etc.)
    26..28,75..80,182,190:                                                 Result := ChopableTrees[7+KaMRandom(2, 'TKMTerrain.ChooseTreeToPlant 2'), caAge1]; //Yellow dirt
    16,17,20,21,34..39,47,49,58,64,65,87..89,183,191,220,247:              Result := ChopableTrees[9+KaMRandom(5, 'TKMTerrain.ChooseTreeToPlant 3'), caAge1]; //Brown dirt (pine trees)
    else Result := ChopableTrees[1+KaMRandom(Length(ChopableTrees), 'TKMTerrain.ChooseTreeToPlant 4'), caAge1]; //If it isn't one of those soil types then choose a random tree
  end;
end;


procedure TKMTerrain.GetHouseMarks(const aLoc: TKMPoint; aHouseType: TKMHouseType; aList: TKMPointTagList);
  procedure MarkPoint(aPoint: TKMPoint; aID: Integer);
  var I: Integer;
  begin
    for I := 0 to aList.Count - 1 do //Skip wires from comparison
      if (aList.Tag[I] <> TC_OUTLINE) and KMSamePoint(aList[I], aPoint) then
        Exit;
    aList.Add(aPoint, aID);
  end;

var
  I,K,S,T: Integer;
  P2: TKMPoint;
  AllowBuild: Boolean;
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
            htIronMine: AllowBuild := CanPlaceIronMine(P2.X, P2.Y);
            htGoldMine: AllowBuild := CanPlaceGoldMine(P2.X, P2.Y);
            else        AllowBuild := (tpBuild in Land[P2.Y,P2.X].Passability);
          end;

          //Check surrounding tiles in +/- 1 range for other houses pressence
          if not AllowBuild then
            for S := -1 to 1 do
              for T := -1 to 1 do
                if (S <> 0) or (T<>0) then  //This is a surrounding tile, not the actual tile
                  if Land[P2.Y+T,P2.X+S].TileLock in [tlFenced,tlDigged,tlHouse] then
                  begin
                    MarkPoint(KMPoint(P2.X+S,P2.Y+T), TC_BLOCK);
                    AllowBuild := false;
                  end;

          //Mark the tile according to previous check results
          if AllowBuild then
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
  Result := (gHands.PlayerAnimals.GetFishInWaterBody(Land[aLoc.Y,aLoc.X].WalkConnect[wcFish],false) <> nil);
end;


function TKMTerrain.CatchFish(aLoc: TKMPointDir; TestOnly: Boolean = False): Boolean;
var MyFish: TKMUnitAnimal;
begin
  //Here we are catching fish in the tile 1 in the direction
  aLoc.Loc := KMGetPointInDir(aLoc.Loc, aLoc.Dir);
  MyFish := gHands.PlayerAnimals.GetFishInWaterBody(Land[aLoc.Loc.Y, aLoc.Loc.X].WalkConnect[wcFish], not TestOnly);
  Result := (MyFish <> nil);
  if (not TestOnly) and (MyFish <> nil) then MyFish.ReduceFish; //This will reduce the count or kill it (if they're all gone)
end;


procedure TKMTerrain.SetObject(const Loc: TKMPoint; ID: Integer);
var IsObjectSet: Boolean;
begin
  IsObjectSet := False;
  case ID of
    // Special cases for corn fields 
    58: if TileIsCornField(Loc) and (GetCornStage(Loc) <> 4) then
        begin
          SetField(Loc, Land[Loc.Y,Loc.X].TileOwner, ftCorn, 4, False);
          IsObjectSet := True;
        end;
    59: if TileIsCornField(Loc) and (GetCornStage(Loc) <> 4) then
        begin
          SetField(Loc, Land[Loc.Y,Loc.X].TileOwner, ftCorn, 5, False);
          IsObjectSet := True;
        end
  end;

  if not IsObjectSet then
  begin
    Land[Loc.Y,Loc.X].Obj := ID;
    Land[Loc.Y,Loc.X].TreeAge := 1;

    //Add 1 tile on sides because surrounding tiles will be affected (CanPlantTrees)
    UpdatePassability(KMRectGrow(KMRect(Loc), 1));

    //Tree could have blocked the only diagonal passage
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(Loc)), True); //Trees block diagonal
  end;
end;


{Remove the tree and place a falling tree instead}
procedure TKMTerrain.FallTree(const Loc: TKMPoint);
var I: Integer;
begin
  for I := 1 to Length(ChopableTrees) do
    if ChopableTrees[I, caAgeFull] = Land[Loc.Y,Loc.X].Obj then
    begin
      Land[Loc.Y,Loc.X].Obj := ChopableTrees[I, caAgeStump];
      //Remember tick when tree was chopped to calc the snim length
      FallingTrees.Add(Loc, ChopableTrees[I, caAgeFall], fAnimStep);
      if gMySpectator.FogOfWar.CheckTileRevelation(Loc.X, Loc.Y) >= 255 then
        gSoundPlayer.Play(sfxTreeDown, Loc, True);
      Exit;
    end;
end;


{Remove the tree and place stump instead}
procedure TKMTerrain.ChopTree(const Loc: TKMPoint);
var
  H: TKMHouse;
  RemoveStamp: Boolean;
begin
  Land[Loc.Y,Loc.X].TreeAge := 0;
  FallingTrees.Remove(Loc);

  // Check if that tree was near house entrance (and stamp will block its entrance)
  //  E       entrance
  //   S      stamp
  RemoveStamp := False;
  H := gHands.HousesHitTest(Loc.X - 1, Loc.Y - 1);
  if (H <> nil) 
    and (H.Entrance.X = Loc.X - 1)
    and (H.Entrance.Y + 1 = Loc.Y) then
    RemoveStamp := True;

  if not RemoveStamp then
  begin
    //  E       entrance
    //  S       stamp
    H := gHands.HousesHitTest(Loc.X, Loc.Y - 1);
    if (H <> nil) 
      and (H.Entrance.X = Loc.X)
      and (H.Entrance.Y + 1 = Loc.Y) then
      RemoveStamp := True;
  end;

  if RemoveStamp then
    Land[Loc.Y,Loc.X].Obj := OBJ_NONE;

  //Update passability after all object manipulations
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));

  //WalkConnect takes diagonal passability into account
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrowTopLeft(KMRect(Loc)), True); //Trees block diagonals
end;


procedure TKMTerrain.RemoveObject(const Loc: TKMPoint);
var BlockedDiagonal: Boolean;
begin
  if Land[Loc.Y,Loc.X].Obj <> OBJ_NONE then
  begin
    BlockedDiagonal := gMapElements[Land[Loc.Y,Loc.X].Obj].DiagonalBlocked;
    Land[Loc.Y,Loc.X].Obj := OBJ_NONE;
    if BlockedDiagonal then
      UpdateWalkConnect([wcWalk,wcRoad,wcWork], KMRectGrowTopLeft(KMRect(Loc)), True);
  end;
end;


procedure TKMTerrain.RemoveObjectsKilledByRoad(const Loc: TKMPoint);
  procedure RemoveIfWest(Loc: TKMPoint);
  begin
    if gMapElements[Land[Loc.Y,Loc.X].Obj].KillByRoad = kbrWest then
      RemoveObject(Loc);
  end;

  procedure KillByRoadCorner(const Loc: TKMPoint);
  begin
    // Check object type first, cos checking roads is more expensive
    if (gMapElements[Land[Loc.Y,Loc.X].Obj].KillByRoad = kbrNWCorner)
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
  Land[Loc.Y,Loc.X].FieldAge := 1;
  Land[Loc.Y,Loc.X].BaseLayer.Terrain  := 61; //Plant it right away, don't wait for update state
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));
end;


procedure TKMTerrain.CutCorn(const Loc: TKMPoint);
begin
  Land[Loc.Y,Loc.X].FieldAge := 0;
  Land[Loc.Y,Loc.X].BaseLayer.Terrain  := 63;
  Land[Loc.Y,Loc.X].Obj := OBJ_NONE;
end;


procedure TKMTerrain.CutGrapes(const Loc: TKMPoint);
begin
  Land[Loc.Y,Loc.X].FieldAge := 1;
  Land[Loc.Y,Loc.X].Obj := 54; //Reset the grapes
end;


procedure TKMTerrain.SetField(const Loc: TKMPoint; aOwner: TKMHandID; aFieldType: TKMFieldType; aStage: Byte = 0; aRandomAge: Boolean = False; aKeepOldObject: Boolean = False);
  procedure SetLand(aFieldAge: Byte; aTerrain: Byte; aObj: Integer = -1);
  begin
    Land[Loc.Y, Loc.X].FieldAge := aFieldAge;

    if fMapEditor then
      Land[Loc.Y, Loc.X].CornOrWineTerrain := aTerrain
    else begin
      Land[Loc.Y, Loc.X].BaseLayer.Terrain := aTerrain;
      Land[Loc.Y, Loc.X].BaseLayer.Rotation := 0;
    end;

    if aObj <> -1 then
      Land[Loc.Y,Loc.X].Obj := aObj;
  end;

  function GetObj: Integer;
  begin
    Result := -1;
    if aFieldType = ftCorn then
    begin
      if not aKeepOldObject //Keep old object, when loading from script via old SetField command
        and ((Land[Loc.Y,Loc.X].Obj = 58) or (Land[Loc.Y,Loc.X].Obj = 59)) then
        Result := OBJ_NONE;
    end;
  end;

var FieldAge: Byte;
begin
  Assert(aFieldType in [ftCorn, ftWine], 'SetField is allowed to use only for corn or wine.');

  SetField_Init(Loc, aOwner);

  if (aFieldType = ftCorn)
    and (InRange(aStage, 0, CORN_STAGES_COUNT - 1)) then
  begin
    if fMapEditor then
      Land[Loc.Y,Loc.X].CornOrWine := 1;

    case aStage of
      0:  SetLand(0, 62, GetObj); //empty field

      1:  begin //Sow corn
            FieldAge := 1 + Ord(aRandomAge) * KaMRandom((CORN_AGE_1 - 1) div 2, 'TKMTerrain.SetField');
            SetLand(FieldAge, 61, GetObj);
          end;

      2:  begin //Young seedings
            FieldAge := CORN_AGE_1 + Ord(aRandomAge) * KaMRandom((CORN_AGE_2 - CORN_AGE_1) div 2, 'TKMTerrain.SetField 2');
            SetLand(FieldAge, 59, OBJ_NONE);
          end;

      3:  begin //Seedings
            FieldAge := CORN_AGE_2 + Ord(aRandomAge) * KaMRandom((CORN_AGE_3 - CORN_AGE_2) div 2, 'TKMTerrain.SetField 3');
            SetLand(FieldAge, 60, OBJ_NONE);
          end;

      4:  begin //Smaller greenish Corn
            FieldAge := CORN_AGE_3 + Ord(aRandomAge) * KaMRandom((CORN_AGE_FULL - CORN_AGE_3) div 2, 'TKMTerrain.SetField 4');
            SetLand(FieldAge, 60, 58);
          end;

      5:  begin //Full-grown Corn
            FieldAge := CORN_AGE_FULL - 1; //-1 because it is increased in update state, otherwise it wouldn't be noticed
            SetLand(FieldAge, 60, 59);
          end;

      6:  SetLand(0, 63, OBJ_NONE); //Corn has been cut
    end;
  end;

  if (aFieldType = ftWine)
    and (InRange(aStage, 0, WINE_STAGES_COUNT - 1)) then
  begin
    if fMapEditor then
      Land[Loc.Y,Loc.X].CornOrWine := 2;

    case aStage of
      0:  begin //Set new fruits
            FieldAge := 1 + Ord(aRandomAge) * KaMRandom((WINE_AGE_1 - 1) div 2, 'TKMTerrain.SetField 5');
            SetLand(FieldAge, 55, 54);
          end;

      1:  begin //Fruits start to grow
            FieldAge := WINE_AGE_1 + Ord(aRandomAge) * KaMRandom((WINE_AGE_1 - WINE_AGE_1) div 2, 'TKMTerrain.SetField 6');
            SetLand(FieldAge, 55, 55);
          end;

      2:  begin //Fruits continue to grow
            FieldAge := WINE_AGE_2 + Ord(aRandomAge) * KaMRandom((WINE_AGE_FULL - WINE_AGE_2) div 2, 'TKMTerrain.SetField 7');
            SetLand(FieldAge, 55, 56);
          end;

      3:  begin //Ready to be harvested
            FieldAge := WINE_AGE_FULL - 1; //-1 because it is increased in update state, otherwise it wouldn't be noticed
            SetLand(FieldAge, 55, 57);
          end;
    end;
  end;

  SetField_Complete(Loc, aFieldType);

  if (aFieldType = ftWine) then
    gScriptEvents.ProcWinefieldBuilt(aOwner, Loc.X, Loc.Y)
  else if (aFieldType = ftCorn) then
    gScriptEvents.ProcFieldBuilt(aOwner, Loc.X, Loc.Y);
end;


{Extract one unit of stone}
procedure TKMTerrain.DecStoneDeposit(const Loc: TKMPoint);
type
  TStoneTransitionType = (sttNone, sttGrass, sttCoastSand, sttDirt, sttSnow, sttShallowSnow);

const
  TransitionsTerKinds: array[TStoneTransitionType] of TKMTerrainKind =
                                                      (tkGrass, tkGrass, tkCoastSand, tkDirt, tkSnow, tkShallowSnow);
  TranTiles: array[TStoneTransitionType] of array[0..6] of Word =
              ((  0, 139, 138, 140, 141, 274, 301),
               (  0, 139, 138, 140, 141, 274, 301),
               ( 32, 269, 268, 270, 271, 273, 302),
               ( 35, 278, 277, 279, 280, 282, 303),
               ( 46, 286, 285, 287, 288, 290, 305),
               ( 47, 294, 293, 295, 296, 298, 306));

  TileIDIndex: array[1..14] of Word = (1,1,2,1,3,2,4,1,2,3,4,2,4,4);
  RotID:       array[1..14] of Byte = (0,1,0,2,0,1,3,3,3,1,2,2,1,0);
  TileIDDiagIndex: array[1..15] of Word = (5,5,6,5,5,6,5,5,6,5,5,6,5,5,5);
  RotIdDiag:       array[1..15] of Byte = (3,0,0,1,3,1,3,2,3,0,0,2,0,0,0);

  MAX_STEPS = 255; //No steps limit for now

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
    case Land[Y,X].BaseLayer.Terrain of
      0, 138,139,142:  Result := sttGrass;
      32,268,269,271:  Result := sttCoastSand;
      35,277,278,280:  Result := sttDirt;
      46,285,286,288:  Result := sttSnow;
      47,293,294,296:  Result := sttShallowSnow;
    end;
  end;

  function UpdateTransition(X,Y: Integer; aTransitionType: TStoneTransitionType; aStep: Byte): Boolean;

    function GetBits(aX,aY: Integer): Byte;
    begin
      Result := Byte(TileInMapCoords(aX,aY) and TileHasStone(aX,aY));
    end;

  var
    Bits, BitsDiag: Byte;
  begin
    Result := False;
    if not TileInMapCoords(X,Y) //Skip for tiles not in map coords
      //or (aStep > MAX_STEPS)    //Limit for steps (no limit for now)
      or TileHasStone(X,Y)      //If tile has stone no need to change it
      or ArrayContains(KMPoint(X,Y), Visited, fVisitedCnt) //If we already changed this tile
      or ((aStep <> 0) and not TileHasStonePart(X,Y)) then //If tile has no stone parts (except initial step)
      Exit;

    Bits := GetBits(X  ,Y-1)*1 +
            GetBits(X+1,Y  )*2 +
            GetBits(X  ,Y+1)*4 +
            GetBits(X-1,Y  )*8;

    if Bits = 0 then
    begin
      BitsDiag := GetBits(X-1,Y-1)*1 +
                  GetBits(X+1,Y-1)*2 +
                  GetBits(X+1,Y+1)*4 +
                  GetBits(X-1,Y+1)*8;

      if BitsDiag = 0 then
      begin
        Land[Y,X].BaseLayer.Terrain  := TKMTerrainPainter.GetRandomTile(TransitionsTerKinds[aTransitionType]);
        Land[Y,X].BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.DecStoneDeposit.UpdateTransition'); //Randomise the direction of no-stone terrain tiles
      end else begin
        Land[Y,X].BaseLayer.Terrain := TranTiles[aTransitionType, TileIDDiagIndex[BitsDiag]];
        Land[Y,X].BaseLayer.Rotation := RotIdDiag[BitsDiag];
      end;
    end else
    begin
      //If tile is surrounded with other stone tiles no need to change it
      if Bits <> 15 then
      begin
        Land[Y,X].BaseLayer.Terrain  := TranTiles[aTransitionType,TileIDIndex[Bits]];
        Land[Y,X].BaseLayer.Rotation := RotID[Bits];
      end;
    end;
    UpdatePassability(KMPoint(X,Y));
    AddToVisited(X,Y);

    //Floodfill through around tiles
    UpdateTransition(X,  Y-1, aTransitionType, aStep + 1); //  x x x
    UpdateTransition(X+1,Y,   aTransitionType, aStep + 1); //  x   x
    UpdateTransition(X,  Y+1, aTransitionType, aStep + 1); //  x x x
    UpdateTransition(X-1,Y,   aTransitionType, aStep + 1);
    UpdateTransition(X-1,Y-1, aTransitionType, aStep + 1);
    UpdateTransition(X+1,Y-1, aTransitionType, aStep + 1);
    UpdateTransition(X+1,Y+1, aTransitionType, aStep + 1);
    UpdateTransition(X-1,Y+1, aTransitionType, aStep + 1);
  end;

var
  Transition: TStoneTransitionType;
begin
  Transition := GetStoneTransitionType(Loc.X,Loc.Y + 1); //Check transition type by lower point (Y + 1)

  //Replace with smaller ore deposit tile (there are 2 sets of tiles, we can choose random)
   case Land[Loc.Y,Loc.X].BaseLayer.Terrain of
    132, 137: Land[Loc.Y,Loc.X].BaseLayer.Terrain := 131 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit')*5;
    131, 136: Land[Loc.Y,Loc.X].BaseLayer.Terrain := 130 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 2')*5;
    130, 135: Land[Loc.Y,Loc.X].BaseLayer.Terrain := 129 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 3')*5;
    129, 134: case Transition of
                sttNone,
                sttGrass:       Land[Loc.Y,Loc.X].BaseLayer.Terrain := 128 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 4')*5;
                sttCoastSand:   Land[Loc.Y,Loc.X].BaseLayer.Terrain := 266 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 5');
                sttDirt:        Land[Loc.Y,Loc.X].BaseLayer.Terrain := 275 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 6');
                sttSnow:        Land[Loc.Y,Loc.X].BaseLayer.Terrain := 283 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 7');
                sttShallowSnow: Land[Loc.Y,Loc.X].BaseLayer.Terrain := 291 + KaMRandom(2, 'TKMTerrain.DecStoneDeposit 8');
              end;
    128, 133,
    266, 267,
    275, 276,
    283, 284,
    291, 292: begin
                Land[Loc.Y,Loc.X].BaseLayer.Terrain  := TranTiles[Transition, 0]; //Remove stone tile (so tile will have no stone)
                Land[Loc.Y,Loc.X].BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.DecStoneDeposit 9');

                InitVisited;
                //Tile type has changed and we need to update these 5 tiles transitions:
                UpdateTransition(Loc.X,  Loc.Y,   Transition, 0);
              end;
    else      Exit;
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
  case Land[Loc.Y,Loc.X].BaseLayer.Terrain of
    144: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=157+KaMRandom(3, 'TKMTerrain.DecOreDeposit'); //Gold
    145: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=144;
    146: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=145;
    147: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=146;
    148: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=160+KaMRandom(4, 'TKMTerrain.DecOreDeposit 2'); //Iron
    149: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=148;
    150: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=149;
    259: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=149;
    151: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=150+KaMRandom(2, 'TKMTerrain.DecOreDeposit 3')*(259-150);
    260: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=151;
    152: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=35 +KaMRandom(2, 'TKMTerrain.DecOreDeposit 4'); //Coal
    153: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=152;
    154: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=153;
    155: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=154;
    263: Land[Loc.Y,Loc.X].BaseLayer.Terrain:=155;
    else Result := false;
  end;
  Land[Loc.Y,Loc.X].BaseLayer.Rotation := KaMRandom(4, 'TKMTerrain.DecOreDeposit 5');
  UpdatePassability(Loc);
end;


procedure TKMTerrain.UpdatePassability(const Loc: TKMPoint);
  procedure AddPassability(aPass: TKMTerrainPassability);
  begin
    Land[Loc.Y,Loc.X].Passability := Land[Loc.Y,Loc.X].Passability + [aPass];
  end;
var
  I, K: Integer;
  HasHousesNearTile, HousesNearVertex, IsBuildNoObj: Boolean;
begin
  Assert(TileInMapCoords(Loc.X, Loc.Y)); //First of all exclude all tiles outside of actual map

  Land[Loc.Y,Loc.X].Passability := [];

  if TileIsWalkable(Loc)
    and not gMapElements[Land[Loc.Y,Loc.X].Obj].AllBlocked
    and CheckHeightPass(Loc, hpWalking) then
    AddPassability(tpOwn);

  //For all passability types other than CanAll, houses and fenced houses are excluded
  if Land[Loc.Y,Loc.X].TileLock in [tlNone, tlFenced, tlFieldWork, tlRoadWork] then
  begin
    if TileIsWalkable(Loc)
      and not gMapElements[Land[Loc.Y,Loc.X].Obj].AllBlocked
      and CheckHeightPass(Loc, hpWalking) then
      AddPassability(tpWalk);

    if (Land[Loc.Y,Loc.X].TileOverlay = toRoad)
    and (tpWalk in Land[Loc.Y,Loc.X].Passability) then //Not all roads are walkable, they must also have CanWalk passability
      AddPassability(tpWalkRoad);

    //Check for houses around this tile/vertex
    HasHousesNearTile := False;
    for I := -1 to 1 do
      for K := -1 to 1 do
        if TileInMapCoords(Loc.X+K, Loc.Y+I)
          and (Land[Loc.Y+I,Loc.X+K].TileLock in [tlFenced,tlDigged,tlHouse]) then
          HasHousesNearTile := True;

    IsBuildNoObj := False;
    if TileIsRoadable(Loc)
      and not TileIsCornField(Loc) //Can't build houses on fields
      and not TileIsWineField(Loc)
      and (Land[Loc.Y,Loc.X].TileLock = tlNone)
      and TileInMapCoords(Loc.X, Loc.Y, 1)
      and CheckHeightPass(Loc, hpBuilding) then
    begin
      AddPassability(tpBuildNoObj);
      IsBuildNoObj := True;
    end;

    if IsBuildNoObj and not HasHousesNearTile
      and((Land[Loc.Y,Loc.X].Obj = OBJ_NONE) or (gMapElements[Land[Loc.Y,Loc.X].Obj].CanBeRemoved)) then //Only certain objects are excluded
      AddPassability(tpBuild);

    if TileIsRoadable(Loc)
      and not gMapElements[Land[Loc.Y,Loc.X].Obj].AllBlocked
      and (Land[Loc.Y,Loc.X].TileLock = tlNone)
      and (Land[Loc.Y,Loc.X].TileOverlay <> toRoad)
      and CheckHeightPass(Loc, hpWalking) then
      AddPassability(tpMakeRoads);

    if ObjectIsChopableTree(Loc, [caAge1, caAge2, caAge3, caAgeFull]) then
      AddPassability(tpCutTree);

    if TileIsWater(Loc) then
      AddPassability(tpFish);

    if TileIsSand(Loc)
      and not gMapElements[Land[Loc.Y,Loc.X].Obj].AllBlocked
      //TileLock checked in outer begin/end
      and (Land[Loc.Y,Loc.X].TileOverlay <> toRoad)
      and not TileIsCornField(Loc)
      and not TileIsWineField(Loc)
      and CheckHeightPass(Loc, hpWalking) then //Can't crab on houses, fields and roads (can walk on fenced house so you can't kill them by placing a house on top of them)
      AddPassability(tpCrab);

    if TileIsSoil(Loc.X,Loc.Y)
      and not gMapElements[Land[Loc.Y,Loc.X].Obj].AllBlocked
      //TileLock checked in outer begin/end
      //Wolf are big enough to run over roads, right?
      and not TileIsCornField(Loc)
      and not TileIsWineField(Loc)
      and CheckHeightPass(Loc, hpWalking) then
      AddPassability(tpWolf);
  end;

  if TileIsWalkable(Loc)
    and not gMapElements[Land[Loc.Y,Loc.X].Obj].AllBlocked
    and CheckHeightPass(Loc, hpWalking)
    and (Land[Loc.Y,Loc.X].TileLock <> tlHouse) then
    AddPassability(tpWorker);

  //Check all 4 tiles that border with this vertex
  if TileIsFactorable(KMPoint(Loc.X  ,Loc.Y))
    and TileIsFactorable(KMPoint(Loc.X-1,Loc.Y))
    and TileIsFactorable(KMPoint(Loc.X  ,Loc.Y-1))
    and TileIsFactorable(KMPoint(Loc.X-1,Loc.Y-1)) then
    AddPassability(tpFactor);

  //Check for houses around this vertice(!)
  //Use only with CanElevate since it's vertice-based!
  HousesNearVertex := False;
  for I := -1 to 0 do
    for K := -1 to 0 do
      if TileInMapCoords(Loc.X+K, Loc.Y+I) then
        //Can't elevate built houses, can elevate fenced and dug houses though
        if (Land[Loc.Y+I,Loc.X+K].TileLock = tlHouse) then
          HousesNearVertex := True;

  if VerticeInMapCoords(Loc.X,Loc.Y)
    and not HousesNearVertex then
    AddPassability(tpElevate);
end;


//Find closest passable point to TargetPoint within line segment OriginPoint <-> TargetPoint
//MaxDistance - maximum distance between finded point and origin point. MaxDistance = -1 means there is no distance restriction
function TKMTerrain.GetPassablePointWithinSegment(OriginPoint, TargetPoint: TKMPoint;
                                                  aPassability: TKMTerrainPassability;
                                                  MaxDistance: Integer = -1): TKMPoint;
  function IsDistanceBetweenPointsAllowed(const OriginPoint, TargetPoint: TKMPoint): Boolean;
  begin
    Result := (MaxDistance = -1) or (KMDistanceSqr(OriginPoint, TargetPoint) <= Sqr(MaxDistance));
  end;
var
  NormVector: TKMPoint;
  NormDistance: Integer;
begin
  if MaxDistance = -1 then
    NormDistance := Floor(KMLength(OriginPoint, TargetPoint))
  else
    NormDistance := Min(MaxDistance, Floor(KMLength(OriginPoint, TargetPoint)));

  while (NormDistance >= 0)
    and (not IsDistanceBetweenPointsAllowed(OriginPoint, TargetPoint)
         or not CheckPassability(TargetPoint, aPassability)) do
  begin
    NormVector := KMNormVector(KMPoint(TargetPoint.X - OriginPoint.X, TargetPoint.Y - OriginPoint.Y), NormDistance);
    TargetPoint := KMPoint(OriginPoint.X + NormVector.X, OriginPoint.Y + NormVector.Y);
    Dec(NormDistance);
  end;
  Result := TargetPoint;
end;


function TKMTerrain.CheckPassability(const Loc: TKMPoint; aPass: TKMTerrainPassability): Boolean;
begin
  Result := TileInMapCoords(Loc.X,Loc.Y) and (aPass in Land[Loc.Y,Loc.X].Passability);
end;


function TKMTerrain.HasUnit(const Loc: TKMPoint): Boolean;
begin
  Assert(TileInMapCoords(Loc.X,Loc.Y));
  Result := Land[Loc.Y,Loc.X].IsUnit <> nil;
end;


function TKMTerrain.HasVertexUnit(const Loc: TKMPoint): Boolean;
begin
  Assert(TileInMapCoords(Loc.X,Loc.Y));
  Result := Land[Loc.Y,Loc.X].IsVertexUnit <> vuNone;
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
    Result := Land[Loc.Y,Loc.X].WalkConnect[aWalkConnect]
  else
    Result := 0; //No network
end;


function TKMTerrain.CheckAnimalIsStuck(const Loc: TKMPoint; aPass: TKMTerrainPassability; aCheckUnits: Boolean = True): Boolean;
var I,K: integer;
begin
  Result := True; //Assume we are stuck
  for I := -1 to 1 do for K := -1 to 1 do
    if (I <> 0) or (K <> 0) then
      if TileInMapCoords(Loc.X+K,Loc.Y+I) then
        if CanWalkDiagonaly(Loc, Loc.X+K, Loc.Y+I) then
          if (Land[Loc.Y+I,Loc.X+K].IsUnit = nil) or (not aCheckUnits) then
            if aPass in Land[Loc.Y+I,Loc.X+K].Passability then
            begin
              Result := false; //at least one tile is empty, so unit is not stuck
              exit;
            end;
end;


//Return random tile surrounding Loc with aPass property. PusherLoc is the unit that pushed us
//which is preferable to other units (otherwise we can get two units swapping places forever)
function TKMTerrain.GetOutOfTheWay(aUnit: Pointer; const PusherLoc: TKMPoint; aPass: TKMTerrainPassability): TKMPoint;
var
  U: TKMUnit;
  Loc: TKMPoint;

  function GoodForWorker(X,Y: Word): Boolean;
  var
    DistNext: Single;
  begin
    DistNext := gHands.DistanceToEnemyTowers(KMPoint(X,Y), U.Owner);
    Result := (DistNext > RANGE_WATCHTOWER_MAX)
    or (DistNext >= gHands.DistanceToEnemyTowers(Loc, U.Owner));
  end;
var
  I, K: Integer;
  L1, L2, L3: TKMPointList;
  TempUnit: TKMUnit;
begin
  U := TKMUnit(aUnit);
  Loc := U.CurrPosition;

  //List 1 holds all available walkable positions except self
  L1 := TKMPointList.Create;
  for I:=-1 to 1 do for K:=-1 to 1 do
    if ((I<>0) or (K<>0))
    and TileInMapCoords(Loc.X+K, Loc.Y+I)
    and CanWalkDiagonaly(Loc, Loc.X + K, Loc.Y + I) //Check for trees that stop us walking on the diagonals!
    and (Land[Loc.Y+I,Loc.X+K].TileLock in [tlNone, tlFenced])
    and (aPass in Land[Loc.Y+I,Loc.X+K].Passability)
    and (not (U is TKMUnitWorker) or GoodForWorker(Loc.X+K, Loc.Y+I)) then
      L1.Add(KMPoint(Loc.X+K, Loc.Y+I));

  //List 2 holds the best positions, ones which are not occupied
  L2 := TKMPointList.Create;
  for I := 0 to L1.Count - 1 do
    if Land[L1[I].Y, L1[I].X].IsUnit = nil then
      L2.Add(L1[I]);

  //List 3 holds the second best positions, ones which are occupied with an idle units
  L3 := TKMPointList.Create;
  for I := 0 to L1.Count - 1 do
    if Land[L1[I].Y, L1[I].X].IsUnit <> nil then
    begin
      TempUnit := UnitsHitTest(L1[I].X, L1[I].Y);
      //Always include the pushers loc in the possibilities, otherwise we can get two units swapping places forever
      if KMSamePoint(L1[I],PusherLoc)
      or ((TempUnit <> nil) and (TempUnit.Action is TKMUnitActionStay)
          and (not TKMUnitActionStay(TempUnit.Action).Locked)) then
        L3.Add(L1[I]);
    end;

  if not(L2.GetRandom(Result)) then
    if not(L3.GetRandom(Result)) then
      if not(L1.GetRandom(Result)) then
        Result := Loc;

  L1.Free;
  L2.Free;
  L3.Free;
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
    and (aPass in Land[Loc.Y+I,Loc.X+K].Passability)
    and CanWalkDiagonaly(Loc, Loc.X+K, Loc.Y+I) //Check for trees that stop us walking on the diagonals!
    and (Land[Loc.Y+I,Loc.X+K].TileLock in [tlNone, tlFenced])
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
  TestRadius: Boolean;
  I,K: integer;
  DistanceSqr: Single;
  WC: TKMWalkConnect;
begin
  Result := True;

  //target has to be different point than source
  //Result:=not (KMSamePoint(LocA,LocB)); //Or maybe we don't care

  //Source point has to be walkable
  Result := Result and CheckPassability(LocA, aPass);

  //Target has to be walkable within Distance
  TestRadius := False;
  DistanceSqr := Sqr(aDistance);
  for i:=max(round(LocB.Y-aDistance),1) to min(round(LocB.Y+aDistance),fMapY-1) do
  for k:=max(round(LocB.X-aDistance),1) to min(round(LocB.X+aDistance),fMapX-1) do
  if KMLengthSqr(LocB,KMPoint(k,i)) <= DistanceSqr then
    TestRadius := TestRadius or CheckPassability(KMPoint(k,i),aPass);
  Result := Result and TestRadius;

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
        Canvas.Pixels[K,I] := Land[I+1,K+1].WalkConnect[wcWork] * 32;
    SaveToFile(ExeDir + 'wcWork.bmp');
    Free;
  end;}

  //Walkable way between A and B is proved by FloodFill
  TestRadius := False;
  for i:=max(round(LocB.Y-aDistance),1) to min(round(LocB.Y+aDistance),fMapY-1) do
  for k:=max(round(LocB.X-aDistance),1) to min(round(LocB.X+aDistance),fMapX-1) do
  if KMLengthSqr(LocB,KMPoint(k,i)) <= DistanceSqr then
    TestRadius := TestRadius or (Land[LocA.Y,LocA.X].WalkConnect[WC] = Land[i,k].WalkConnect[WC]);
  Result := Result and TestRadius;
end;


//Check if a route can be made to this vertex, from any direction (used for woodcutter cutting trees)
function TKMTerrain.Route_CanBeMadeToVertex(const LocA, LocB: TKMPoint; aPass: TKMTerrainPassability): Boolean;
var i,k:integer;
begin
  Result := false;
  //Check from top-left of vertex to vertex tile itself
  for i := Max(LocB.Y-1,1) to LocB.Y do
    for k := Max(LocB.X-1,1) to LocB.X do
      Result := Result or Route_CanBeMade(LocA,KMPoint(k,i),aPass,0);
end;


//Returns the closest tile to TargetLoc with aPass and walk connect to OriginLoc
//If no tile found - return Origin location
function TKMTerrain.GetClosestTile(const TargetLoc, OriginLoc: TKMPoint; aPass: TKMTerrainPassability; aAcceptTargetLoc: Boolean): TKMPoint;
const TestDepth = 255;
var
  i:integer;
  P: TKMPoint;
  T: TKMPoint;
  WalkConnectID: integer;
  wcType: TKMWalkConnect;
begin
  case aPass of
    tpWalkRoad: wcType := wcRoad;
    tpFish:     wcType := wcFish;
    else         wcType := wcWalk; //CanWalk is default
  end;

  WalkConnectID := Land[OriginLoc.Y,OriginLoc.X].WalkConnect[wcType]; //Store WalkConnect ID of origin

  //If target is accessable then use it
  if aAcceptTargetLoc and CheckPassability(TargetLoc, aPass) and (WalkConnectID = Land[TargetLoc.Y,TargetLoc.X].WalkConnect[wcType]) then
  begin
    Result := TargetLoc;
    exit;
  end;

  //If target is not accessable then choose a tile near to the target that is accessable
  //As we Cannot reach our destination we are "low priority" so do not choose a tile with another unit on it (don't bump important units)
  for i:=0 to TestDepth do begin
    P := GetPositionFromIndex(TargetLoc, i);
    if not TileInMapCoords(P.X,P.Y) then continue;
    T := KMPoint(P.X,P.Y);
    if CheckPassability(T, aPass)
      and (WalkConnectID = Land[T.Y,T.X].WalkConnect[wcType])
      and (not HasUnit(T) or KMSamePoint(T,OriginLoc)) //Allow position we are currently on, but not ones with other units
    then
    begin
      Result := T; //Assign if all test are passed
      Exit;
    end;
  end;

  Result := OriginLoc; //If we don't find one, return existing Loc
end;


function TKMTerrain.GetClosestRoad(const aFromLoc: TKMPoint; aWalkConnectIDSet: TKMByteSet; aPass: TKMTerrainPassability = tpWalkRoad): TKMPoint;
const Depth = 255;
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

  for I := 0 to Depth do
  begin
    P := GetPositionFromIndex(aFromLoc, I);
    if not TileInMapCoords(P.X,P.Y) then Continue;
    if CheckPassability(P, aPass)
      and (Land[P.Y,P.X].WalkConnect[wcType] in aWalkConnectIDSet)
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
  if not DO_UNIT_INTERACTION then exit;
  Assert(Land[LocTo.Y,LocTo.X].IsUnit = nil, 'Tile already occupied at '+TypeToString(LocTo));
  Land[LocTo.Y,LocTo.X].IsUnit := aUnit
end;


{ Mark tile as empty }
// We have no way of knowing whether a unit is inside a house, or several units exit a house at once
// when exiting the game and destroying all units this will cause asserts.
procedure TKMTerrain.UnitRem(const LocFrom: TKMPoint);
begin
  if not DO_UNIT_INTERACTION then exit;
  Land[LocFrom.Y,LocFrom.X].IsUnit := nil;
end;


{Mark previous tile as empty and next one as occupied}
//We need to check both tiles since UnitWalk is called only by WalkTo where both tiles aren't houses
procedure TKMTerrain.UnitWalk(const LocFrom,LocTo: TKMPoint; aUnit: Pointer);
var
  aU: TKMUnit;
begin
  if not DO_UNIT_INTERACTION then exit;
  Assert(Land[LocFrom.Y, LocFrom.X].IsUnit = aUnit, 'Trying to remove wrong unit at '+TypeToString(LocFrom));
  Land[LocFrom.Y, LocFrom.X].IsUnit := nil;
  Assert(Land[LocTo.Y, LocTo.X].IsUnit = nil, 'Tile already occupied at '+TypeToString(LocTo));
  Land[LocTo.Y, LocTo.X].IsUnit := aUnit;

  aU := TKMUnit(aUnit);
  if ((aU <> nil) and (aU is TKMUnitWarrior)) then
    gScriptEvents.ProcWarriorWalked(aU, LocTo.X, LocTo.Y);
end;


procedure TKMTerrain.UnitSwap(const LocFrom,LocTo: TKMPoint; UnitFrom: Pointer);
begin
  Assert(Land[LocFrom.Y,LocFrom.X].IsUnit = UnitFrom, 'Trying to swap wrong unit at '+TypeToString(LocFrom));
  Land[LocFrom.Y,LocFrom.X].IsUnit := Land[LocTo.Y,LocTo.X].IsUnit;
  Land[LocTo.Y,LocTo.X].IsUnit := UnitFrom;
end;


{Mark vertex as occupied}
procedure TKMTerrain.UnitVertexAdd(const LocTo: TKMPoint; Usage: TKMVertexUsage);
begin
  if not DO_UNIT_INTERACTION then exit;
  assert(Usage <> vuNone, 'Invalid add vuNone at '+TypeToString(LocTo));
  assert((Land[LocTo.Y,LocTo.X].IsVertexUnit = vuNone) or (Land[LocTo.Y,LocTo.X].IsVertexUnit = Usage),'Opposite vertex in use at '+TypeToString(LocTo));

  Land[LocTo.Y,LocTo.X].IsVertexUnit := Usage;
end;


procedure TKMTerrain.UnitVertexAdd(const LocFrom, LocTo: TKMPoint);
begin
  assert(KMStepIsDiag(LocFrom, LocTo), 'Add non-diagonal vertex?');
  UnitVertexAdd(KMGetDiagVertex(LocFrom, LocTo), GetVertexUsageType(LocFrom, LocTo));
end;


{Mark vertex as empty}
procedure TKMTerrain.UnitVertexRem(const LocFrom: TKMPoint);
begin
  if not DO_UNIT_INTERACTION then exit;
  Land[LocFrom.Y,LocFrom.X].IsVertexUnit := vuNone;
end;


//This function tells whether the diagonal is "in use". (a bit like IsUnit) So if there is a unit walking on
//the oppsoite diagonal you cannot use the vertex (same diagonal is allowed for passing and fighting)
//It stops units walking diagonally through each other or walking through a diagonal that has weapons swinging through it
function TKMTerrain.VertexUsageCompatible(const LocFrom, LocTo: TKMPoint): Boolean;
var
  Vert: TKMPoint;
  VertUsage: TKMVertexUsage;
begin
  Assert(KMStepIsDiag(LocFrom, LocTo));
  Vert := KMGetDiagVertex(LocFrom, LocTo);
  VertUsage := GetVertexUsageType(LocFrom, LocTo);
  Result := (Land[Vert.Y, Vert.X].IsVertexUnit in [vuNone, VertUsage]);
end;


function TKMTerrain.GetVertexUsageType(const LocFrom, LocTo: TKMPoint): TKMVertexUsage;
var dx, dy: integer;
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
procedure TKMTerrain.FlattenTerrain(const Loc: TKMPoint; aUpdateWalkConnects: Boolean = True; aIgnoreCanElevate: Boolean = False);
  //If tiles with units standing on them become unwalkable we should try to fix them
  procedure EnsureWalkable(aX,aY: Word);
  begin
    //We did not recalculated passability yet, hence tile has CanWalk but CheckHeightPass=False already
    if (tpWalk in Land[aY,aX].Passability)
    //Yield in TestStone is much better if we comment this out, also general result is flatter/"friendlier"
    //and (Land[aY,aX].IsUnit <> nil)
    and not CheckHeightPass(KMPoint(aX,aY), hpWalking)
    and not fMapEditor //Allow units to become "stuck" in MapEd, as height changing is allowed anywhere
    then
      //This recursive call should be garanteed to exit, as eventually the terrain will be flat enough
      FlattenTerrain(KMPoint(aX,aY), False, aIgnoreCanElevate); //WalkConnect should be done at the end
  end;

  function CanElevateAt(aX, aY: Word): Boolean;
  begin
    //Passability does not get set for the row below the bottom/right edges
    Result := aIgnoreCanElevate or (tpElevate in Land[aY, aX].Passability) or (aX = fMapX) or (aY = fMapY);
  end;

var
  VertsFactored: Integer;

  //Note that we need to access vertices, not tiles
  function GetHeight(aX,aY: Word; Neighbour: Boolean): Byte;
  begin
    if VerticeInMapCoords(aX,aY) and (not Neighbour or (tpFactor in Land[aY,aX].Passability)) then
    begin
      Result := Land[aY,aX].Height;
      Inc(VertsFactored);
    end
    else
      Result := 0;
  end;

var
  I, K: Word;
  Avg: Word;
begin
  Assert(TileInMapCoords(Loc.X, Loc.Y), 'Can''t flatten tile outside map coordinates');

  if aUpdateWalkConnects then
    fBoundsWC := KMRect(Loc.X, Loc.Y, Loc.X, Loc.Y);

  //Expand fBoundsWC in case we were called by EnsureWalkable, and fBoundsWC won't know about this tile
  if fBoundsWC.Left > Loc.X - 1 then fBoundsWC.Left := Loc.X - 1;
  if fBoundsWC.Top > Loc.Y - 1 then fBoundsWC.Top := Loc.Y - 1;
  if fBoundsWC.Right < Loc.X + 1 then fBoundsWC.Right := Loc.X + 1;
  if fBoundsWC.Bottom < Loc.Y + 1 then fBoundsWC.Bottom := Loc.Y + 1;

  VertsFactored := 0; //GetHeight will add to this
  Avg :=                                   GetHeight(Loc.X,Loc.Y-1,True ) + GetHeight(Loc.X+1,Loc.Y-1,True ) +
         GetHeight(Loc.X-1,Loc.Y  ,True) + GetHeight(Loc.X,Loc.Y  ,False) + GetHeight(Loc.X+1,Loc.Y  ,False) + GetHeight(Loc.X+2,Loc.Y  ,True) +
         GetHeight(Loc.X-1,Loc.Y+1,True) + GetHeight(Loc.X,Loc.Y+1,False) + GetHeight(Loc.X+1,Loc.Y+1,False) + GetHeight(Loc.X+2,Loc.Y+1,True) +
                                           GetHeight(Loc.X,Loc.Y+2,True ) + GetHeight(Loc.X+1,Loc.Y+2,True );
  Assert(VertsFactored <> 0); //Non-neighbour verts will always be factored
  Avg := Round(Avg / VertsFactored);

  if CanElevateAt(Loc.X  , Loc.Y  ) then Land[Loc.Y  ,Loc.X  ].Height := Mix(Avg, Land[Loc.Y  ,Loc.X  ].Height, 0.5);
  if CanElevateAt(Loc.X+1, Loc.Y  ) then Land[Loc.Y  ,Loc.X+1].Height := Mix(Avg, Land[Loc.Y  ,Loc.X+1].Height, 0.5);
  if CanElevateAt(Loc.X  , Loc.Y+1) then Land[Loc.Y+1,Loc.X  ].Height := Mix(Avg, Land[Loc.Y+1,Loc.X  ].Height, 0.5);
  if CanElevateAt(Loc.X+1, Loc.Y+1) then Land[Loc.Y+1,Loc.X+1].Height := Mix(Avg, Land[Loc.Y+1,Loc.X+1].Height, 0.5);

  //All 9 tiles around and including this one could have become unwalkable and made a unit stuck, so check them all
  for I := Max(Loc.Y-1, 1) to Min(Loc.Y+1, fMapY-1) do
    for K := Max(Loc.X-1, 1) to Min(Loc.X+1, fMapX-1) do
      EnsureWalkable(K, I);

  UpdateLighting(KMRect(Loc.X-2, Loc.Y-2, Loc.X+3, Loc.Y+3));
  //Changing height will affect the cells around this one
  UpdatePassability(KMRectGrow(KMRect(Loc), 1));

  if aUpdateWalkConnects then
    UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRectGrow(fBoundsWC, 1), False);
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


//Rebuilds lighting values for given bounds.
//These values are used to draw highlights/shadows on terrain
//Note that input values may be off-map
procedure TKMTerrain.UpdateLighting(const aRect: TKMRect);
var
  I, K: Integer;
  x0, y2: Integer;
begin
  //Valid vertices are within 1..Map
  for I := Max(aRect.Top, 1) to Min(aRect.Bottom, fMapY) do
  for K := Max(aRect.Left, 1) to Min(aRect.Right, fMapX) do
  begin
    x0 := Max(K-1, 1);
    y2 := Min(I+1, fMapY);
    Land[I,K].Light := EnsureRange((Land[I,K].Height-(Land[y2,K].Height+Land[I,x0].Height)/2)/22,-1,1); //  1.33*16 ~=22

    //Use more contrast lighting for Waterbeds
    if fTileset.TileIsWater(Land[I, K].BaseLayer.Terrain) then
      Land[I,K].Light := EnsureRange(Land[I,K].Light * 1.3 + 0.1, -1, 1);

    //Map borders always fade to black
    if (I = 1) or (I = fMapY) or (K = 1) or (K = fMapX) then
      Land[I,K].Light := -1;
  end;
end;


//Rebuilds passability for given bounds
procedure TKMTerrain.UpdatePassability(const aRect: TKMRect);
var I, K: Integer;
begin
  for I := Max(aRect.Top, 1) to Min(aRect.Bottom, fMapY - 1) do
    for K := Max(aRect.Left, 1) to Min(aRect.Right, fMapX - 1) do
      UpdatePassability(KMPoint(K, I));
end;


//Rebuilds connected areas using flood fill algorithm
procedure TKMTerrain.UpdateWalkConnect(const aSet: array of TKMWalkConnect; aRect: TKMRect; aDiagObjectsEffected:Boolean);
const
  WC_PASS: array [TKMWalkConnect] of TKMTerrainPassability = (
    tpWalk, tpWalkRoad, tpFish, tpWorker);
var
  J: Integer;
  WC: TKMWalkConnect;
  AllowDiag: Boolean;
begin
  aRect := KMClipRect(aRect, 1, 1, fMapX-1, fMapY-1);

  //Process all items from set
  for J := Low(aSet) to High(aSet) do
  begin
    WC := aSet[J];
    AllowDiag := (WC <> wcRoad); //Do not consider diagonals "connected" for roads
    TKMTerrainWalkConnect.DoUpdate(aRect, WC, WC_PASS[WC], AllowDiag, aDiagObjectsEffected);
  end;
end;


{Place house plan on terrain and change terrain properties accordingly}
procedure TKMTerrain.SetHouse(const Loc: TKMPoint; aHouseType: TKMHouseType; aHouseStage: TKMHouseStage; aOwner: TKMHandID; const aFlattenTerrain: Boolean = False);
var
  I, K, X, Y: Word;
  ToFlatten: TKMPointList;
  HA: THouseArea;
  ObjectsEffected: Boolean; //UpdateWalkConnect cares about this for optimisation purposes
begin
  ObjectsEffected := False;
  if aFlattenTerrain then //We will check aFlattenTerrain only once, otherwise there are compiler warnings
    ToFlatten := TKMPointList.Create
  else
    ToFlatten := nil;

  if aHouseStage = hsNone then
    SetHouseAreaOwner(Loc, aHouseType, -1)
  else
    SetHouseAreaOwner(Loc, aHouseType, aOwner);

  HA := gRes.Houses[aHouseType].BuildArea;

  for i:=1 to 4 do
  for k:=1 to 4 do
    if HA[i,k] <> 0 then
    begin
      x := Loc.X + k - 3;
      y := Loc.Y + i - 4;
      if TileInMapCoords(x,y) then
      begin
        case aHouseStage of
          hsNone:         Land[y,x].TileLock := tlNone;
          hsFence:        Land[y,x].TileLock := tlFenced; //Initial state, Laborer should assign NoWalk to each tile he digs
          hsBuilt:        begin
                            //Script houses are placed as built, add TileLock for them too
                            Land[y,x].TileLock := tlHouse;

                            //Add road for scipted houses
                            if HA[i,k] = 2 then
                              Land[y,x].TileOverlay := toRoad;

                            if ToFlatten <> nil then
                            begin
                              //In map editor don't remove objects (remove on mission load instead)
                              if Land[y,x].Obj <> OBJ_NONE then
                              begin
                                ObjectsEffected := ObjectsEffected or gMapElements[Land[y,x].Obj].DiagonalBlocked;
                                Land[y,x].Obj := OBJ_NONE;
                              end;
                              //If house was set e.g. in mission file we must flatten the terrain as no one else has
                              ToFlatten.Add(KMPoint(x,y));
                            end;
                          end;
        end;
        UpdateFences(KMPoint(x,y));
      end;
    end;

  if ToFlatten <> nil then
  begin
    FlattenTerrain(ToFlatten);
    ToFlatten.Free;
  end;

  //Recalculate Passability for tiles around the house so that they can't be built on too
  UpdatePassability(KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1));
  UpdateWalkConnect([wcWalk, wcRoad, wcWork], KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1), ObjectsEffected);
end;


{That is mainly used for minimap now}
procedure TKMTerrain.SetHouseAreaOwner(const Loc: TKMPoint; aHouseType: TKMHouseType; aOwner: TKMHandID);
var i,k:integer; HA: THouseArea;
begin
  HA := gRes.Houses[aHouseType].BuildArea;
  case aHouseType of
    htNone:    Land[Loc.Y,Loc.X].TileOwner := aOwner;
    htAny:     ; //Do nothing
    else        for i:=1 to 4 do for k:=1 to 4 do //If this is a house make change for whole place
                  if HA[i,k]<>0 then
                    if TileInMapCoords(Loc.X+k-3,Loc.Y+i-4) then
                      Land[Loc.Y+i-4,Loc.X+k-3].TileOwner := aOwner;
  end;
end;


{Check if Unit can be placed here}
//Used by MapEd, so we use AllowedTerrain which lets us place citizens off-road
function TKMTerrain.CanPlaceUnit(const Loc: TKMPoint; aUnitType: TKMUnitType): Boolean;
begin
  Result := TileInMapCoords(Loc.X, Loc.Y)
            and (Land[Loc.Y, Loc.X].IsUnit = nil) //Check for no unit below
            and (gRes.Units[aUnitType].AllowedPassability in Land[Loc.Y, Loc.X].Passability);
end;


function TKMTerrain.HousesNearTile(X,Y: Word): Boolean;
var
  I,K: Integer;
begin
  Result := False;
  for I := -1 to 1 do
    for K := -1 to 1 do
      if (Land[Y+I,X+K].TileLock in [tlFenced,tlDigged,tlHouse]) then
        Result := True;
end;


function TKMTerrain.CanPlaceGoldMine(X,Y: Word): Boolean;
begin
  Result := TileGoodForGoldmine(X,Y)
    and ((Land[Y,X].Obj = OBJ_NONE) or (gMapElements[Land[Y,X].Obj].CanBeRemoved))
    and not HousesNearTile(X,Y)
    and (Land[Y,X].TileLock = tlNone)
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
        else         Result := Result and (tpBuild in Land[Y,X].Passability);
      end;
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
    if TileInMapCoords(TX+M, TY+L) and (Land[TY+L, TX+M].TileLock in [tlFenced,tlDigged,tlHouse]) then
      Result := False;

    //Check if there are units below placed BEFORE the house is added
    //Units added AFTER the house will be autoplaced around it
    Result := Result and (Land[TY, TX].IsUnit = nil);

    if not Result then Exit;
  end;
end;


function TKMTerrain.CanAddField(aX, aY: Word; aFieldType: TKMFieldType): Boolean;
begin
  //Make sure it is within map, roads can be built on edge
  Result := TileInMapCoords(aX, aY);

  case aFieldType of
    ftRoad:  Result := Result and (tpMakeRoads in Land[aY, aX].Passability);
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
    Points[1] := Land[aLoc.Y, aLoc.X].Height;
    Points[2] := Land[aLoc.Y, X2].Height;
    Points[3] := Land[Y2,     aLoc.X].Height;
    Points[4] := Land[Y2,     X2].Height;

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
          Land[Loc.Y + I - 4, Loc.X + K - 3].Obj := 68 + KaMRandom(6, 'TKMTerrain.AddHouseRemainder');

    //Leave dug terrain
    for I := 1 to 4 do
      for K := 1 to 4 do
        if HA[I, K] <> 0 then
        begin
          Land[Loc.Y + I - 4, Loc.X + K - 3].TileOverlay := toDig3;
          Land[Loc.Y + I - 4, Loc.X + K - 3].TileLock    := tlNone;
        end;
  end else
  begin
    //For glyphs leave nothing
    for I := 1 to 4 do
      for K:=1 to 4 do
        if HA[I, K] <> 0 then
          Land[Loc.Y + I - 4, Loc.X + K - 3].TileLock := tlNone;
  end;

  UpdatePassability(KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1));
  UpdateWalkConnect([wcWalk, wcRoad, wcWork],
                    KMRect(Loc.X - 3, Loc.Y - 4, Loc.X + 2, Loc.Y + 1),
                    (aBuildState in [hbsStone, hbsDone])); //Rubble objects block diagonals
end;


{Check 4 surrounding tiles, and if they are different place a fence}
procedure TKMTerrain.UpdateFences(const Loc: TKMPoint; CheckSurrounding: Boolean = True);
  function GetFenceType: TKMFenceType;
  begin
    if TileIsCornField(Loc) then
      Result := fncCorn
    else
    if TileIsWineField(Loc) then
      Result := fncWine
    else
    if Land[Loc.Y,Loc.X].TileLock in [tlFenced, tlDigged] then
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
       ((Land[Loc.Y, Loc.X].TileLock in [tlFenced, tlDigged]) and
        (Land[Y, X].TileLock in [tlFenced, tlDigged])) then //Both are either house fence
      Result := False;
  end;
begin
 if not TileInMapCoords(Loc.X, Loc.Y) then exit;

  Land[Loc.Y,Loc.X].Fence := GetFenceType;

  if Land[Loc.Y, Loc.X].Fence = fncNone then
    Land[Loc.Y, Loc.X].FenceSide := 0
  else
  begin
    Land[Loc.Y, Loc.X].FenceSide := Byte(GetFenceEnabled(Loc.X,   Loc.Y - 1)) + //N
                                    Byte(GetFenceEnabled(Loc.X - 1, Loc.Y)) * 2 + //E
                                    Byte(GetFenceEnabled(Loc.X + 1, Loc.Y)) * 4 + //W
                                    Byte(GetFenceEnabled(Loc.X,   Loc.Y + 1)) * 8; //S
  end;

  if CheckSurrounding then
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
    Ycoef[ii] := (Yc - 1) + ii - (Land[Tmp, Xc].Height * (1 - frac(inX))
                          + Land[Tmp, Xc + 1].Height * frac(inX)) / CELL_HEIGHT_DIV;
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
  Tmp1, Tmp2: single;
begin
  //Valid range of tiles is 0..MapXY-2 because we check height from (Xc+1,Yc+1) to (Xc+2,Yc+2)
  //We cannot ask for height at the bottom row (MapY-1) because that row is not on the visible map,
  //and does not have a vertex below it
  Xc := EnsureRange(Trunc(inX), 0, fMapX-2);
  Yc := EnsureRange(Trunc(inY), 0, fMapY-2);

  Tmp1 := Mix(Land[Yc+1, Xc+2].Height, Land[Yc+1, Xc+1].Height, Frac(inX));
  Tmp2 := Mix(Land[Yc+2, Xc+2].Height, Land[Yc+2, Xc+1].Height, Frac(inX));
  Result := inY - Mix(Tmp2, Tmp1, Frac(inY)) / CELL_HEIGHT_DIV;
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
  Tmp1, Tmp2: single;
begin
  //Valid range of tiles is 0..MapXY-2 because we check height from (Xc+1,Yc+1) to (Xc+2,Yc+2)
  //We cannot ask for height at the bottom row (MapY-1) because that row is not on the visible map,
  //and does not have a vertex below it
  Xc := EnsureRange(Trunc(inX), 0, fMapX-2);
  Yc := EnsureRange(Trunc(inY), 0, fMapY-2);

  Tmp1 := Mix(Land[Yc+1, Xc+2].Height, Land[Yc+1, Xc+1].Height, Frac(inX));
  Tmp2 := Mix(Land[Yc+2, Xc+2].Height, Land[Yc+2, Xc+1].Height, Frac(inX));
  Result := Mix(Tmp2, Tmp1, Frac(inY)) / CELL_HEIGHT_DIV;
end;


//Get highest walkable hill on a maps top row to use for viewport top bound
function TKMTerrain.TopHill: Byte;
var
  I,K: Integer;
begin
  Result := 0;
  //Check last 2 strips in case 2nd has a taller hill
  for I := 1 to 2 do
  for K := 2 to fMapX do
  if ((tpWalk in Land[I, K-1].Passability) or (tpWalk in Land[I, K].Passability)) then
    Result := Max(Result, Land[I, K].Height - (I-1) * CELL_SIZE_PX);
end;


procedure TKMTerrain.IncAnimStep;
begin
  Inc(fAnimStep);
end;


procedure TKMTerrain.Save(SaveStream: TKMemoryStream);
var
  I,K,L: Integer;
  TileBasic: TKMTerrainTileBasic;
begin
  Assert(not fMapEditor, 'MapEd mode is not intended to be saved into savegame');

  SaveStream.WriteA('Terrain');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
  SaveStream.Write(fMapRect);
  SaveStream.Write(fAnimStep);

  FallingTrees.SaveToStream(SaveStream);

  for I := 1 to fMapY do
    for K := 1 to fMapX do
    begin
      //Only save fields that cannot be recalculated after loading
      TileBasic.BaseLayer := Land[I,K].BaseLayer;
      TileBasic.Height    := Land[I,K].Height;
      TileBasic.Obj       := Land[I,K].Obj;
      TileBasic.IsCustom  := Land[I,K].IsCustom;
      TileBasic.LayersCnt := Land[I,K].LayersCnt;
      for L := 0 to 2 do
        TileBasic.Layer[L] := Land[I,K].Layer[L];

      WriteTileToStream(SaveStream, TileBasic);

      SaveStream.Write(Land[I,K].TreeAge);
      SaveStream.Write(Land[I,K].FieldAge);
      SaveStream.Write(Land[I,K].TileLock, SizeOf(Land[I,K].TileLock));
      SaveStream.Write(Land[I,K].TileOverlay, SizeOf(Land[I,K].TileOverlay));
      SaveStream.Write(Land[I,K].TileOwner, SizeOf(Land[I,K].TileOwner));
      if Land[I,K].IsUnit <> nil then
        SaveStream.Write(TKMUnit(Land[I,K].IsUnit).UID) //Store ID, then substitute it with reference on SyncLoad
      else
        SaveStream.Write(Integer(0));
      SaveStream.Write(Land[I,K].IsVertexUnit, SizeOf(Land[I,K].IsVertexUnit));
    end;
end;


procedure TKMTerrain.Load(LoadStream: TKMemoryStream);
var
  I,J,L: Integer;
  TileBasic: TKMTerrainTileBasic;
begin
  LoadStream.ReadAssert('Terrain');
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
  LoadStream.Read(fMapRect);
  LoadStream.Read(fAnimStep);

  FallingTrees.LoadFromStream(LoadStream);

  for I := 1 to fMapY do
    for J := 1 to fMapX do
    begin
      ReadTileFromStream(LoadStream, TileBasic);
      Land[I,J].BaseLayer := TileBasic.BaseLayer;
      Land[I,J].Height := TileBasic.Height;
      Land[I,J].Obj := TileBasic.Obj;
      Land[I,J].LayersCnt := TileBasic.LayersCnt;

      for L := 0 to 2 do
        Land[I,J].Layer[L] := TileBasic.Layer[L];

      LoadStream.Read(Land[I,J].TreeAge);
      LoadStream.Read(Land[I,J].FieldAge);
      LoadStream.Read(Land[I,J].TileLock,SizeOf(Land[I,J].TileLock));
      LoadStream.Read(Land[I,J].TileOverlay,SizeOf(Land[I,J].TileOverlay));
      LoadStream.Read(Land[I,J].TileOwner,SizeOf(Land[I,J].TileOwner));
      LoadStream.Read(Land[I,J].IsUnit, 4);
      LoadStream.Read(Land[I,J].IsVertexUnit,SizeOf(Land[I,J].IsVertexUnit));
    end;

  for I := 1 to fMapY do
    for J := 1 to fMapX do
      UpdateFences(KMPoint(J,I), False);

  fFinder := TKMTerrainFinder.Create;

  UpdateLighting(MapRect);
  UpdatePassability(MapRect);

  UpdateWalkConnect([wcWalk, wcRoad, wcFish, wcWork], MapRect, True);

  gLog.AddTime('Terrain loaded');
end;


procedure TKMTerrain.SyncLoad;
var
  I, K: Integer;
begin
  for I := 1 to fMapY do
    for K := 1 to fMapX do
      Land[I,K].IsUnit := gHands.GetUnitByUID(Cardinal(Land[I,K].IsUnit));
end;


function TKMTerrain.GetCornStage(const Loc: TKMPoint): Byte;
var FieldAge: Byte;
begin
  Assert(TileIsCornField(Loc));
  FieldAge := Land[Loc.Y,Loc.X].FieldAge;
  if FieldAge = 0 then
  begin
    if (fMapEditor and (Land[Loc.Y,Loc.X].CornOrWineTerrain = 63))
      or (Land[Loc.Y,Loc.X].BaseLayer.Terrain = 63) then
      Result := 6
    else
      Result := 0;
  end else if InRange(FieldAge, 1, CORN_AGE_1 - 1) then
    Result := 1
  else if InRange(FieldAge, CORN_AGE_1, CORN_AGE_2 - 1) then
    Result := 2
  else if InRange(FieldAge, CORN_AGE_2, CORN_AGE_3 - 1) then
    Result := 3
  else if InRange(FieldAge, CORN_AGE_3, CORN_AGE_FULL - 2) then
    Result := 4
  else
    Result := 5;
end;


function TKMTerrain.GetWineStage(const Loc: TKMPoint): Byte;
begin
  Result := 0;
  Assert(TileIsWineField(Loc));
  case Land[Loc.Y, Loc.X].Obj of
    54:   Result := 0;
    55:   Result := 1;
    56:   Result := 2;
    57:   Result := 3;
  end;
end;


//This whole thing is very CPU intesive, updating whole (256*256) tiles map
//Don't use any advanced math here, only simpliest operations - + div *
procedure TKMTerrain.UpdateState;
  procedure SetLand(aTile: Word; const X, Y, aObj: Byte);
  var FloodfillNeeded: Boolean;
  begin
    Land[Y,X].BaseLayer.Terrain := aTile;
    FloodfillNeeded   := gMapElements[Land[Y,X].Obj].DiagonalBlocked <> gMapElements[aObj].DiagonalBlocked;
    Land[Y,X].Obj     := aObj;
    if FloodfillNeeded then //When trees are removed by corn growing we need to update floodfill
      UpdateWalkConnect([wcWalk,wcRoad,wcWork], KMRectGrowTopLeft(KMRect(X,Y,X,Y)), True);
  end;
var
  H, I, K, A: Integer;
  J: TKMChopableAge;
  T: Integer;
begin
  if not DYNAMIC_TERRAIN then Exit;

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

    if InRange(Land[I,K].FieldAge, 1, CORN_AGE_MAX-1) then
    begin
      Inc(Land[I,K].FieldAge);
      if TileIsCornField(KMPoint(K,I)) then
        case Land[I,K].FieldAge of
          CORN_AGE_1:     SetLand(59,K,I,OBJ_NONE);
          CORN_AGE_2:     SetLand(60,K,I,OBJ_NONE);
          CORN_AGE_3:     SetLand(60,K,I,58);
          CORN_AGE_FULL:  begin
                            //Skip to the end
                            SetLand(60,K,I,59);
                            Land[I,K].FieldAge := CORN_AGE_MAX;
                          end;
        end
      else
      if TileIsWineField(KMPoint(K,I)) then
        case Land[I,K].FieldAge of
          WINE_AGE_1:     SetLand(55,K,I,55);
          WINE_AGE_2:     SetLand(55,K,I,56);
          WINE_AGE_FULL:  begin
                            //Skip to the end
                            SetLand(55,K,I,57);
                            Land[I,K].FieldAge := CORN_AGE_MAX;
                          end;
        end;
    end;

    if InRange(Land[I,K].TreeAge, 1, TREE_AGE_FULL) then
    begin
      Inc(Land[I,K].TreeAge);
      if (Land[I,K].TreeAge = TREE_AGE_1)
      or (Land[I,K].TreeAge = TREE_AGE_2)
      or (Land[I,K].TreeAge = TREE_AGE_FULL) then //Speedup
        for H := Low(ChopableTrees) to High(ChopableTrees) do
          for J := caAge1 to caAge3 do
            if Land[I,K].Obj = ChopableTrees[H,J] then
              case Land[I,K].TreeAge of
                TREE_AGE_1:    Land[I,K].Obj := ChopableTrees[H, caAge2];
                TREE_AGE_2:    Land[I,K].Obj := ChopableTrees[H, caAge3];
                TREE_AGE_FULL: Land[I,K].Obj := ChopableTrees[H, caAgeFull];
              end;
    end;

    Inc(A, TERRAIN_PACE);
  end;
end;


class procedure TKMTerrain.WriteTileToStream(var S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic);
var
  MapDataSize: Cardinal;
begin
  WriteTileToStream(S, aTileBasic, MapDataSize);
end;


class procedure TKMTerrain.WriteTileToStream(var S: TKMemoryStream; const aTileBasic: TKMTerrainTileBasic; var aMapDataSize: Cardinal);

  function PackLayersCorners(const aTileBasic: TKMTerrainTileBasic): Byte;
  var
    I, L: Integer;
    LayerNumber: Byte;
  begin
    Result := 0;
    //Layers corners are packed into 1 byte.
    //It contains info which layer 'owns' each corner
    //f.e. aCorners[0] contains layer number, which 'own' 0 corner.
    //0-layer means BaseLayer
    LayerNumber := 0;
    for I := 3 downto 0 do  // go from 3 to 0, as we pack 3 corner to the most left
    begin
      if I in aTileBasic.BaseLayer.Corners then
        LayerNumber := 0
      else
        for L := 0 to 2 do
          if I in aTileBasic.Layer[L].Corners then
          begin
            LayerNumber := L + 1;
            Break;
          end;
      if I < 3 then //do not shl for first corner
        Result := Result shl 2;
      Result := Result or LayerNumber;
    end;
  end;

var
  L: Integer;
begin
  S.Write(aTileBasic.BaseLayer.Terrain);  //1
  //Map file stores terrain, not the fields placed over it, so save OldRotation rather than Rotation
  S.Write(aTileBasic.BaseLayer.Rotation); //3
  S.Write(aTileBasic.Height);             //4
  S.Write(aTileBasic.Obj);                //5
  S.Write(aTileBasic.IsCustom);           //7
  S.Write(aTileBasic.LayersCnt);          //8
  Inc(aMapDataSize, 8); // obligatory 8 bytes per tile
  if aTileBasic.LayersCnt > 0 then
  begin
    S.Write(PackLayersCorners(aTileBasic));
    Inc(aMapDataSize);
    for L := 0 to aTileBasic.LayersCnt - 1 do
    begin
      S.Write(aTileBasic.Layer[L].Terrain);
      S.Write(aTileBasic.Layer[L].Rotation);
      Inc(aMapDataSize, 3); // Terrain (2 bytes) + Rotation (1 byte)
    end;
  end;
end;


class procedure TKMTerrain.ReadTileFromStream(aStream: TKMemoryStream; var aTileBasic: TKMTerrainTileBasic; aUseKaMFormat: Boolean = False);
var
  I: Integer;
  TerrainB, ObjectB, Rot, Corners: Byte;
  LayersCorners: array[0..3] of Byte;
begin
  if aUseKaMFormat then
  begin
    aStream.Read(TerrainB);           //1
    aTileBasic.BaseLayer.Terrain := TerrainB;
    aStream.Seek(1, soFromCurrent);
    aStream.Read(aTileBasic.Height);  //3
    aStream.Read(Rot);                //4
    aTileBasic.BaseLayer.Rotation := Rot mod 4; //Some original KaM maps have Rot > 3, mod 4 gives right result
    aStream.Seek(1, soFromCurrent);
    aStream.Read(ObjectB);     //6
    aTileBasic.Obj := ObjectB;
    aTileBasic.BaseLayer.Corners := [0,1,2,3];
    aTileBasic.LayersCnt := 0;
    aTileBasic.IsCustom := False;
  end else begin
    aStream.Read(aTileBasic.BaseLayer.Terrain); //2
    aStream.Read(Rot);                          //3
    aTileBasic.BaseLayer.Rotation := Rot mod 4; //Some original KaM maps have Rot > 3, mod 4 gives right result
    aStream.Read(aTileBasic.Height);            //4
    aStream.Read(aTileBasic.Obj);               //5
    aStream.Read(aTileBasic.IsCustom);          //7

    // Load all layers info
    // First get layers count
    aStream.Read(aTileBasic.LayersCnt);         //8
    if aTileBasic.LayersCnt = 0 then            // No need to save corners, if we have no layers on that tile
      aTileBasic.BaseLayer.Corners := [0,1,2,3] // Set all corners then
    else begin
      // if there are some layers, then load base layer corners first
      aStream.Read(Corners);

      //Layers corners are packed into 1 byte.
      //It contains info which layer 'owns' each corner
      //f.e. aCorners[0] contains layer number, which 'own' 0 corner.
      //0-layer means BaseLayer
      LayersCorners[0] := Corners and $3;
      LayersCorners[1] := (Corners shr 2) and $3;
      LayersCorners[2] := (Corners shr 4) and $3;
      LayersCorners[3] := (Corners shr 6) and $3;

      aTileBasic.BaseLayer.Corners := [];
      for I := 0 to aTileBasic.LayersCnt - 1 do
      begin
        aStream.Read(aTileBasic.Layer[I].Terrain);
        aStream.Read(aTileBasic.Layer[I].Rotation);
        aTileBasic.Layer[I].Corners := [];
      end;

      for I := 0 to 3 do
      begin
        case LayersCorners[I] of
          0:    Include(aTileBasic.BaseLayer.Corners, I);
          else  Include(aTileBasic.Layer[LayersCorners[I]-1].Corners, I);
        end;
      end;
    end;
  end;

  if aUseKaMFormat then
    aStream.Seek(17, soFromCurrent);
end;

end.

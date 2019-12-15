{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_CityPlanner;
{$I KaM_Remake.inc}
interface
uses
  Classes, Graphics, KromUtils, Math, SysUtils, Contnrs,
  KM_Defaults, KM_Points, KM_CommonClasses, KM_CommonTypes, KM_CommonUtils,
  KM_TerrainFinder, KM_PerfLog, KM_Houses, KM_ResHouses, KM_ResWares, KM_Sort,
  KM_PathFindingRoad, KM_PathFindingAStarNew, KM_CityPredictor, KM_Eye, KM_AIParameters,
  KM_AIInfluences, KM_NavMeshDefences;

const
  FARM_RADIUS = 11;
  FIELDS_PER_FARM = 14;
  FIELDS_PER_WINE = 9;

type
  THousePlan = record
    Placed, ShortcutsCompleted, RemoveTreeInPlanProcedure, HouseReservation, ChopOnly: Boolean;
    House: TKMHouse;
    Loc, SpecPoint: TKMPoint;
  end;
  THousePlanArray = record
    Count, Completed, UnderConstruction, Planned: Word;
    Plans: array of THousePlan;
  end;
  TPlannedHousesArray = array [HOUSE_MIN..HOUSE_MAX] of THousePlanArray;

  TFieldEval = (feUnvisitedTile = 0, feFertileTile = 1, feExistingField = 2, feObstacle = 3);
  TFieldPrice = array[-FARM_RADIUS..FARM_RADIUS,-FARM_RADIUS..FARM_RADIUS] of Integer;
  TFieldMemory = record
    Count, UpdateIdx: Word;
    Farms: array of record
      FieldAvailable: Boolean;
      Center: TKMPoint;
      FieldType: TKMFieldType;
      Points: array[0..FIELDS_PER_FARM-1] of TKMPoint;
    end;
  end;

  TPathFindingCityPlanner = class(TPathFindingRoad)
  private
  protected
    function IsWalkableTile(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Word; override;
  public
    {$IFDEF DEBUG_NewAI}
      Ctr: Word;
      Price: array[0..256,0..256] of Word;
      Order: array[0..256,0..256] of Word;
      function Route_Make(const aLocA, aLocB: TKMPoint; NodeList: TKMPointList): Boolean; reintroduce;
    {$ENDIF}
  end;

  TPathFindingShortcutsCityPlanner = class(TPathFindingCityPlanner)
  private
  protected
    function DestinationReached(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Word; override;
  public
  end;


  TKMFieldEvaluation = class
  private
    fMapX, fMapY: Word;
    fOwner: TKMHandID;
    fInitPoint: TKMPoint;
    fQueue: TQueue;
    fFieldType: TKMFieldType;

    function CanBeVisited(const aX,aY, aDistance: Word): Boolean;
    procedure MarkAsVisited(const aX,aY, aDistance: Word);
    procedure InsertInQueue(const aX,aY, aDistance: Word);
    function RemoveFromQueue(var aX,aY, aDistance: Word): Boolean;
  public
    FieldEval: array[-FARM_RADIUS..FARM_RADIUS,-FARM_RADIUS..FARM_RADIUS] of TFieldEval;
    FieldPrice: TFieldPrice;

    constructor Create(aMapX, aMapY: Word; aOwner: TKMHandID);
    destructor Destroy(); override;

    procedure EvalField(aMaxDist: Word; aInitPoint: TKMPoint; aFieldType: TKMFieldType);
    procedure OwnerUpdate(aPlayer: TKMHandID);
  end;


  // Create plan of city AfterMissionInit and update it during game (if it is required)
  TKMCityPlanner = class
  private
    fDebugText: UnicodeString;
    {$IFDEF DEBUG_NewAI}
      fTimeSumSearchHouse: array[HOUSE_MIN..HOUSE_MAX] of Cardinal;
      fTimePeakSearchHouse: array[HOUSE_MIN..HOUSE_MAX] of Cardinal;
      fTimeSumSearchForest: Cardinal;
      fTimePeakSearchForest: Cardinal;
      fTimeSumPlanFields: Cardinal;
      fTimePeakPlanFields: Cardinal;
      fPlaceHouseDebugText: UnicodeString;
      fPlaceFarmDebugText: UnicodeString;
      fBestHouseLocs: TKMPointArray;
      fBestHouseVal: TKMByteArray;
      fForestDebugText: UnicodeString;
      fFieldPrice: TFieldPrice;

      DA1: array [0..256,0..256] of Integer;
      DA2: array [0..256,0..256] of Integer;
      DA3: array [0..256,0..256] of Integer;
      DA4: array [0..256,0..256] of Integer;
    {$ENDIF}

    fOwner: TKMHandID;
    fConstructedHouses: Word;
    fDefenceTowersPlanned: Boolean;
    fPlannedHouses: TPlannedHousesArray;
    fForestsInfo: TKMForestsInfo;
    fFields: TFieldMemory;

    fRoadPlanner: TPathFindingCityPlanner;
    fRoadShortcutPlanner: TPathFindingShortcutsCityPlanner;
    fFieldEval: TKMFieldEvaluation;

    procedure AddPlan(aHT: TKMHouseType; aLoc: TKMPoint); overload;
    procedure AddPlan(aHT: TKMHouseType; aLoc: TKMPoint; aSpecPoint: TKMPoint; aChopOnly: Boolean = False); overload;
    function GetPlan(aHT: TKMHouseType; aOnlyLatest: Boolean; out aLoc: TKMPoint; out aIdx: Integer): Boolean;

    function ObstaclesInHousePlan(aHT: TKMHouseType; aLoc: TKMPoint): Single;
    function FieldCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
    function SnapCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
    function DistCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;

    //procedure PlanWineFields(aLoc: TKMPoint; var aNodeList: TKMPointList);
    //procedure PlanFarmFields(aLoc: TKMPoint; var aNodeList: TKMPointList);
    procedure PlanFields(aCnt: Word; aLoc: TKMPoint; aFieldType: TKMFieldType; var aNodeList: TKMPointList; aReplaceFarmIdx: Integer = -1; aReplaceFieldIdx: Word = 0);
    function FindPlaceForHouse(aIgnoreTrees: Boolean; aHT: TKMHouseType; out aBestLocs: TKMPointArray): Byte;
    function FindPlaceForMines(aHT: TKMHouseType; var aLoc: TKMPoint): Boolean;
    function FindPlaceForQuary(var StoneLocs: TKMPointTagList): Boolean;
    function FindPlaceForWoodcutter(aCenter: TKMPoint; aChopOnly: Boolean = False): Boolean;
    function FindForestAndWoodcutter(): Boolean;
    function PlanDefenceTowers(): Boolean;

  public
    constructor Create(aPlayer: TKMHandID);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();

    procedure AfterMissionInit();
    procedure OwnerUpdate(aPlayer: TKMHandID);
    procedure UpdateState(aTick: Cardinal);

    // Properties for GA (in Runner)
    property ConstructedHouses: Word read fConstructedHouses;
    property PlannedHouses: TPlannedHousesArray read fPlannedHouses write fPlannedHouses;
    property DefenceTowersPlanned: Boolean read fDefenceTowersPlanned;

    procedure MarkAsExhausted(aHT: TKMHouseType; aLoc: TKMPoint);

    procedure RemoveHouseType(aHT: TKMHouseType);
    procedure RemovePlan(aHT: TKMHouseType; aLoc: TKMPoint); overload;
    procedure RemovePlan(aHT: TKMHouseType; aIdx: Integer); overload;

    function GetHousePlan(aIgnoreTrees, aIgnoreExistingPlans: Boolean; aHT: TKMHouseType; var aLoc: TKMPoint; var aIdx: Integer): Boolean;
    function GetRoadBetweenPoints(aStart, aEnd: TKMPoint; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
    function GetRoadToHouse(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
    function GetFieldToHouse(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
    function GetTreesInHousePlan(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList): Byte;
    function FindForestAround(const aPoint: TKMPoint; aCountByInfluence: Boolean = False): Boolean;
    procedure CheckStoneReserves(aForceToPlaceQuarry: Boolean; aReqQuarryCnt: Integer);
    function CheckFields(var aFieldType: TKMFieldType; var aNodeList: TKMPointList): Boolean;

    procedure LogStatus(var aBalanceText: UnicodeString);
    procedure Paint();
  end;


const
  HOUSE_DEPENDENCE: array[HOUSE_MIN..HOUSE_MAX] of set of TKMHouseType = (  // This array is sorted by priority
    {htArmorSmithy}    [ htCoalMine,       htIronMine,       htIronSmithy,     htBarracks                       ],
    {htArmorWorkshop}  [ htSawmill,        htTannery,        htArmorWorkshop,  htBarracks                       ],
    {htBakery}         [ htInn,            htMill,           htStore,          htBakery                         ],
    {htBarracks}       [ htArmorWorkshop,  htArmorSmithy,    htWeaponSmithy,   htWeaponWorkshop                 ],
    {htButchers}       [ htInn,            htSwine,          htStore,          htButchers                       ],
    {htCoalMine}       [ htCoalMine,       htGoldMine,       htIronMine,       htStore,         htMetallurgists ],
    {htFarm}           [ htFarm,           htSwine,          htMill,           htStables                        ],
    {htFisherHut}      [ htStore                                                                                ],
    {htGoldMine}       [ htMetallurgists,  htStore                                                              ],
    {htInn}            [ htButchers,       htBakery,         htStore,          htWineyard                       ],
    {htIronMine}       [ htStore                                                                                ],
    {htIronSmithy}     [ htCoalMine,       htIronMine,       htWeaponSmithy,   htIronSmithy                     ],
    {htMarketplace}    [ htStore,          htMetallurgists,  htMarketplace,    htBarracks                       ],
    // Metallurgist must be only close to coal / gold because serfs are not able to support this extremely critical resources
    {htMetallurgists}  [ htCoalMine,       htGoldMine                                                           ],// htSchool, htStore
    {htMill}           [ htBakery,         htInn,            htMill                                             ],
    {htQuary}          [ htStore                                                                                ],
    {htSawmill}        [ htArmorWorkshop,  htSawmill,        htWeaponWorkshop                                   ],
    {htSchool}         [ htMetallurgists,  htStore,          htSchool                                           ],
    {htSiegeWorkshop}  [ htIronSmithy,     htSawmill,        htStore,          htSiegeWorkshop                  ],
    {htStables}        [ htFarm,           htStables,        htBarracks                                         ],
    {htStore}          [ htInn,            htSchool,         htBarracks                                         ],
    {htSwine}          [ htFarm,           htButchers,       htSwine                                            ],
    {htTannery}        [ htArmorWorkshop,  htTannery,        htBarracks                                         ],
    {htTownHall}       [ htMetallurgists,  htStore,          htTownHall                                         ],
    {htWatchTower}     [ htStore                                                                                ],
    {htWeaponSmithy}   [ htIronSmithy,     htCoalMine,       htBarracks,       htIronMine                       ],
    {htWeaponWorkshop} [ htSawmill,        htWeaponWorkshop, htBarracks                                         ],
    {htWineyard}       [ htInn,            htQuary,          htCoalMine                                         ],
    {htWoodcutters}    [ htStore                                                                                ]
  );

implementation
uses
  KM_Game, KM_HouseCollection, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Terrain, KM_Resource,
  KM_AIFields, KM_Units, KM_UnitTaskDelivery, KM_UnitActionWalkTo, KM_UnitTaskGoEat, KM_UnitsCollection,
  KM_NavMesh, KM_HouseMarket, KM_HouseWoodcutters, KM_ResUnits,
  KM_RenderAux, KM_ResMapElements;



{ Procedural functions }
function CompareForests(const aElem1, aElem2): Integer;
var
  val1 : TKMForestInfo absolute aElem1;
  val2 : TKMForestInfo absolute aElem2;
begin
  if      (val1.Bid = val2.Bid) then Result :=  0
  else if (val1.Bid < val2.Bid) then Result := -1
  else                               Result := +1;
end;



{ TKMCityPlanner }
constructor TKMCityPlanner.Create(aPlayer: TKMHandID);
var
  HT: TKMHouseType;
begin
  for HT := HOUSE_MIN to HOUSE_MAX do
    with fPlannedHouses[HT] do
    begin
      Count := 0;
      Completed := 0;
      UnderConstruction := 0;
      Planned := 0;
    end;
  fDebugText := '';
  {$IFDEF DEBUG_NewAI}
    FillChar(fTimeSumSearchHouse, SizeOf(fTimeSumSearchHouse), #0);
    FillChar(fTimePeakSearchHouse, SizeOf(fTimePeakSearchHouse), #0);
    fTimeSumPlanFields := 0;
    fTimePeakPlanFields := 0;
    fTimeSumSearchForest := 0;
    fTimePeakSearchForest := 0;
  {$ENDIF}
  fConstructedHouses := 0;
  fOwner := aPlayer;
  fDefenceTowersPlanned := False;
  fForestsInfo.Count := 0;
  SetLength(fForestsInfo.Forests,0);
  fFields.Count := 0;
  fFields.UpdateIdx := 0;
  SetLength(fFields.Farms,0);
  fRoadPlanner := TPathFindingCityPlanner.Create(fOwner);
  fRoadShortcutPlanner := TPathFindingShortcutsCityPlanner.Create(fOwner);
  fFieldEval := TKMFieldEvaluation.Create(gTerrain.MapX, gTerrain.MapY, fOwner);
end;


destructor TKMCityPlanner.Destroy();
var
  HT: TKMHouseType;
  I: Integer;
begin
  for HT := HOUSE_MIN to HOUSE_MAX do
    for I := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[I] do
        if (House <> nil) then
          gHands.CleanUpHousePointer(House);
  fRoadPlanner.Free;
  fRoadShortcutPlanner.Free;
  fFieldEval.Free;
  inherited;
end;


procedure TKMCityPlanner.Save(SaveStream: TKMemoryStream);
var
  HT: TKMHouseType;
  K, Len: Integer;
begin
  SaveStream.PlaceMarker('CityPlanner');
  SaveStream.Write(fOwner);
  SaveStream.Write(fConstructedHouses);
  SaveStream.Write(fDefenceTowersPlanned);
  SaveStream.Write(fForestsInfo.Count);
  if (fForestsInfo.Count > 0) then
    SaveStream.Write(fForestsInfo.Forests[0], SizeOf(TKMForestInfo) * fForestsInfo.Count);
  SaveStream.Write(fFields.Count);
  SaveStream.Write(fFields.UpdateIdx);
  if (fFields.Count > 0) then
    SaveStream.Write(fFields.Farms[0], SizeOf(fFields.Farms[0]) * fFields.Count);

  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    SaveStream.Write(fPlannedHouses[HT].Count);
    SaveStream.Write(fPlannedHouses[HT].Completed);
    SaveStream.Write(fPlannedHouses[HT].UnderConstruction);
    SaveStream.Write(fPlannedHouses[HT].Planned);
    Len := Length(fPlannedHouses[HT].Plans);
    SaveStream.Write( Len );
    for K := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[K] do
      begin
        SaveStream.Write(Placed);
        SaveStream.Write(ShortcutsCompleted);
        SaveStream.Write(RemoveTreeInPlanProcedure);
        SaveStream.Write(HouseReservation);
        SaveStream.Write(ChopOnly);
        if (House <> nil) then
          SaveStream.Write(House.UID) // Store ID
        else
          SaveStream.Write(Integer(0));
        SaveStream.Write(Loc, SizeOf(Loc));
        SaveStream.Write(SpecPoint, SizeOf(SpecPoint));
      end;
  end;

  fRoadPlanner.Save(SaveStream);
  fRoadShortcutPlanner.Save(SaveStream);
end;


procedure TKMCityPlanner.Load(LoadStream: TKMemoryStream);
var
  HT: TKMHouseType;
  K, Len: Integer;
begin
  LoadStream.CheckMarker('CityPlanner');
  LoadStream.Read(fOwner);
  LoadStream.Read(fConstructedHouses);
  LoadStream.Read(fDefenceTowersPlanned);
  LoadStream.Read(fForestsInfo.Count);
  SetLength(fForestsInfo.Forests,fForestsInfo.Count);
  if (fForestsInfo.Count > 0) then
    LoadStream.Read(fForestsInfo.Forests[0],SizeOf(TKMForestInfo) * fForestsInfo.Count);
  LoadStream.Read(fFields.Count);
  LoadStream.Read(fFields.UpdateIdx);
  SetLength(fFields.Farms,fFields.Count);
  if (fFields.Count > 0) then
    LoadStream.Read(fFields.Farms[0],SizeOf(fFields.Farms[0]) * fFields.Count);

  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    LoadStream.Read(fPlannedHouses[HT].Count);
    LoadStream.Read(fPlannedHouses[HT].Completed);
    LoadStream.Read(fPlannedHouses[HT].UnderConstruction);
    LoadStream.Read(fPlannedHouses[HT].Planned);
    LoadStream.Read(Len);
    SetLength(fPlannedHouses[HT].Plans, Len);
    for K := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[K] do
      begin
        LoadStream.Read(Placed);
        LoadStream.Read(ShortcutsCompleted);
        LoadStream.Read(RemoveTreeInPlanProcedure);
        LoadStream.Read(HouseReservation);
        LoadStream.Read(ChopOnly);
        LoadStream.Read(House, 4); // Load ID
        LoadStream.Read(Loc, SizeOf(Loc));
        LoadStream.Read(SpecPoint, SizeOf(SpecPoint));
      end;
  end;

  fRoadPlanner.Load(LoadStream);
  fRoadShortcutPlanner.Load(LoadStream);
end;


procedure TKMCityPlanner.SyncLoad();
var
  HT: TKMHouseType;
  K: Integer;
begin
  for HT := HOUSE_MIN to HOUSE_MAX do
    for K := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[K] do
        House := gHands.GetHouseByUID( Cardinal(House) );
end;



procedure TKMCityPlanner.AfterMissionInit();
begin
  // Actual houses will be added in UpdateState (script may remove / add something after mission init ...)
  UpdateState(0);
end;

procedure TKMCityPlanner.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fRoadPlanner.OwnerUpdate(aPlayer);
  fRoadShortcutPlanner.OwnerUpdate(aPlayer);
  fFieldEval.OwnerUpdate(aPlayer);
end;




procedure TKMCityPlanner.UpdateState(aTick: Cardinal);
  procedure ScanChopOnly(aW: TKMHouseWoodcutters);
  begin
    if (aW.CheckResOut(wtAll) <> 0) then // There is still trunk
      Exit;
    if not gTerrain.CanFindTree(aW.FlagPoint, gRes.Units[utWoodcutter].MiningRange, True) then
    begin
      RemovePlan(htWoodcutters, aW.Entrance);
      aW.DemolishHouse(fOwner);
    end;
  end;

  procedure CheckWoodcutter(aHousePlan: THousePlan; aCheckChopOnly: Boolean);
  var
    Point: TKMPoint;
    W: TKMHouseWoodcutters;
  begin
    // Make sure that this house is woodcutter
    if (aHousePlan.House.HouseType <> htWoodcutters) then
      Exit;
    W := TKMHouseWoodcutters(aHousePlan.House);
    // Check if is cutting point required (compare with default cutting point)
    if not KMSamePoint(aHousePlan.SpecPoint, KMPOINT_ZERO) AND not W.IsFlagPointSet then
    // Set the cutting point - do it only once because it reset empty message (woodcutters in chop only mode will not be destroyed)
      W.FlagPoint := aHousePlan.SpecPoint;
    // Check chop-only mode
    Point := W.FlagPoint;
    if aHousePlan.ChopOnly AND (gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] < AVOID_BUILDING_FOREST_MINIMUM) then
    begin
      if aCheckChopOnly then
        ScanChopOnly(W);
      if (W.WoodcutterMode <> wcmChop) then // Center of forest is not in protected area => chop only mode
        W.WoodcutterMode := wcmChop
    end
    else if (W.WoodcutterMode <> wcmChopAndPlant) then
      W.WoodcutterMode := wcmChopAndPlant;
  end;

const
  WOODCUT_CHOP_ONLY_CHECK = MAX_HANDS * 100;
var
  CheckChopOnly, CheckExistHouse, HouseExist: Boolean;
  CompletedHouses,HousesUnderConstruction, PlannedHouses: Word;
  I,K: Integer;
  HT: TKMHouseType;
  H: TKMHouse;
begin
  // Priority: function is called from CityBuilder only in right time
  CheckChopOnly := (aTick mod WOODCUT_CHOP_ONLY_CHECK = fOwner);
  // Find new houses which are added by player / script / at the start of mission etc. and connect them with city plan
  for I := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[I];
    if (H <> nil) AND not H.IsDestroyed then
    begin
      HT := H.HouseType;
      CheckExistHouse := False;
      for K := 0 to fPlannedHouses[HT].Count - 1 do
        if KMSamePoint(fPlannedHouses[HT].Plans[K].Loc, H.Entrance) then
        begin
          if (fPlannedHouses[HT].Plans[K].House <> H) then
          begin
            // Make sure that reservation is no longer used
            gHands[fOwner].AI.CityManagement.Builder.UnlockHouseLoc(HT, H.Entrance);
            if (fPlannedHouses[HT].Plans[K].House <> nil) then
              gHands.CleanUpHousePointer(fPlannedHouses[HT].Plans[K].House);
            fPlannedHouses[HT].Plans[K].House := H.GetHousePointer;
          end;
          CheckExistHouse := True;
          break;
        end;
      if not CheckExistHouse then // House was added by script / spectator in debug mode
      begin
        if (HT = htWoodcutters) then
          AddPlan(HT, H.Entrance, TKMHouseWoodcutters(H).FlagPoint, TKMHouseWoodcutters(H).WoodcutterMode = wcmChop)
        else
          AddPlan(HT, H.Entrance);
      end;
    end;
  end;
  // Check if are existing houses completed / destroyed
  fConstructedHouses := 0;
  for HT := Low(fPlannedHouses) to High(fPlannedHouses) do
  begin
    CompletedHouses := 0;
    HousesUnderConstruction := 0;
    PlannedHouses := 0;
    for I := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[I] do
      begin
        HouseExist := ((House <> nil) AND not House.IsDestroyed);
        Placed := HouseExist OR gHands[fOwner].BuildList.HousePlanList.ExistPlan(Loc, HT);
        if Placed then // House was placed
        begin
          if (HouseExist AND House.IsComplete) then
            CompletedHouses := CompletedHouses + 1
          else
          begin
            fConstructedHouses := fConstructedHouses + 1;
            HousesUnderConstruction := HousesUnderConstruction + 1;
          end;
          if (HT = htWoodcutters) then // Another exception for woodcutters
          begin
            if ChopOnly AND HouseExist AND House.IsComplete then // Dont consider choponly woodcutters
              CompletedHouses := CompletedHouses - 1;
            if (House <> nil) AND (House.IsComplete) then
              CheckWoodcutter(fPlannedHouses[HT].Plans[I], CheckChopOnly);
          end;
        end
        else if (HouseReservation OR RemoveTreeInPlanProcedure) then // House was reserved
        begin
          PlannedHouses := PlannedHouses + 1;
        end
        else // House was destroyed
        begin
          if (House <> nil) then
            gHands.CleanUpHousePointer(House);
        end;
      end;
    with fPlannedHouses[HT] do
    begin
      Completed := CompletedHouses;
      UnderConstruction := HousesUnderConstruction;
      Planned := PlannedHouses;
    end;
  end;
end;


procedure TKMCityPlanner.AddPlan(aHT: TKMHouseType; aLoc: TKMPoint);
begin
  AddPlan(aHT, aLoc, KMPOINT_ZERO); // Cannot declare KMPOINT_ZERO as a default value so overload method is used instead
end;

procedure TKMCityPlanner.AddPlan(aHT: TKMHouseType; aLoc: TKMPoint; aSpecPoint: TKMPoint; aChopOnly: Boolean = False);
const
  ADD_VALUE = 8;
begin
  // Check size of array
  if (fPlannedHouses[aHT].Count >= Length(fPlannedHouses[aHT].Plans)) then
    SetLength(fPlannedHouses[aHT].Plans, fPlannedHouses[aHT].Count + ADD_VALUE);
  // Add plan
  with fPlannedHouses[aHT].Plans[ fPlannedHouses[aHT].Count ] do
  begin
    Placed := False;
    ShortcutsCompleted := False;
    RemoveTreeInPlanProcedure := False;
    HouseReservation := False;
    ChopOnly := aChopOnly;
    Loc := aLoc;
    SpecPoint := aSpecPoint;
    House := nil;
  end;
  fPlannedHouses[aHT].Count := fPlannedHouses[aHT].Count + 1;
end;


function TKMCityPlanner.GetPlan(aHT: TKMHouseType; aOnlyLatest: Boolean; out aLoc: TKMPoint; out aIdx: Integer): Boolean;
const
  MAX_BID = 1000000;
  CHOP_ONLY_ADVANTAGE = 200;

  // Try find gold / iron in range of mine
  function IsExhaustedMine(aMineLoc: TKMPoint; aIsGold: Boolean): Boolean;
  var
    Y, X: Integer;
  begin
    Result := False;
    for X := Max(aMineLoc.X-4, 1) to Min(aMineLoc.X+3, gTerrain.MapX-1) do
    for Y := Max(aMineLoc.Y-8, 1) to aMineLoc.Y do
      if ( not aIsGold AND gTerrain.TileHasIron(X, Y) )
          OR ( aIsGold AND gTerrain.TileHasGold(X, Y) ) then
      Exit;
    Result := True;
  end;

  function IsExhaustedQuary(aQuaryLoc: TKMPoint): Boolean;
  var
    Y, X: Integer;
  const
    RADIUS = 15;
  begin
    Result := False;
    for Y := Max(aQuaryLoc.Y-RADIUS, 1) to Min(aQuaryLoc.Y+RADIUS, gTerrain.MapY-1) do
    for X := Max(aQuaryLoc.X-RADIUS, 1) to Min(aQuaryLoc.X+RADIUS, gTerrain.MapX-1) do
      if gTerrain.TileHasStone(X, Y) then
        Exit;
    Result := True;
  end;

  function IsExhaustedCoalMine(aCoalLoc: TKMPoint): Boolean;
  var
    X,Y,I: Integer;
    HMA: THouseMappingArray;
  begin
    Result := False;
    HMA := gAIFields.Eye.HousesMapping;
    for I := Low(HMA[htCoalMine].Tiles) to High(HMA[htCoalMine].Tiles) do
    begin
      X := aCoalLoc.X + HMA[htCoalMine].Tiles[I].X;
      Y := aCoalLoc.Y + HMA[htCoalMine].Tiles[I].Y;
      if gTerrain.TileHasCoal(X, Y) then
        Exit;
    end;
    Result := True;
  end;

  function CheckMine(aIdx: Integer): Boolean;
  var
    Exhausted: Boolean;
  begin
    Exhausted := False;
    with fPlannedHouses[aHT].Plans[aIdx] do
    begin
      case aHT of
        htGoldMine: Exhausted := IsExhaustedMine(Loc, True);
        htIronMine: Exhausted := IsExhaustedMine(Loc, False);
        htCoalMine: Exhausted := IsExhaustedCoalMine(Loc);
        htQuary:    Exhausted := IsExhaustedQuary(Loc);
        else
          begin
          end;
      end;
      if Exhausted then
        RemovePlan(aHT, aIdx);
      Result := Exhausted;
    end
  end;

  function DistFromStore(aLoc: TKMPoint): Single;
  var
    I: Integer;
    Output, Bid: Single;
  begin
    Output := MAX_BID;
    for I := 0 to fPlannedHouses[htStore].Count - 1 do
    begin
      Bid := KMDistanceAbs(aLoc, fPlannedHouses[htStore].Plans[I].Loc);
      if (Bid < Output) then
        Output := Bid;
    end;
    if (Output = MAX_BID) then
      Output := 0;
    Result := Output;
  end;
var
  Output: Boolean;
  I, BestIdx: Integer;
  Bid, BestBid: Single;
begin
  Output := False;
  BestBid := MAX_BID;
  BestIdx := 0; // For compiler
  for I := fPlannedHouses[aHT].Count - 1 downto 0 do
    with fPlannedHouses[aHT].Plans[I] do
      if not Placed then
      begin
        if RemoveTreeInPlanProcedure OR gAIFields.Eye.CanAddHousePlan(Loc, aHT, True, True) then
        begin
          if (aHT in [htGoldMine, htIronMine, htCoalMine, htQuary]) AND CheckMine(I) then // Filter mines / chop-only woodcutters
            continue;
          Bid := //+ DistFromStore(Loc)
                 + ObstaclesInHousePlan(aHT, Loc)
                 - gAIFields.Influences.Ownership[ fOwner, Loc.Y, Loc.X ]
                 - Byte((aHT = htWoodcutters) AND ChopOnly) * CHOP_ONLY_ADVANTAGE; // Chop only mode
          if (Bid < BestBid) then
          begin
            BestBid := Bid;
            BestIdx := I;
          end;
          if aOnlyLatest then
            break;
        end
        else
          RemovePlan(aHT, I);
      end;
  if (BestBid <> MAX_BID) then
  begin
    aLoc := fPlannedHouses[aHT].Plans[BestIdx].Loc;
    aIdx := BestIdx;
    Output := True;
  end;
  Result := Output;
end;


procedure TKMCityPlanner.MarkAsExhausted(aHT: TKMHouseType; aLoc: TKMPoint);
begin
  RemovePlan(aHT, aLoc);
end;


// Remove one of placed houses
procedure TKMCityPlanner.RemoveHouseType(aHT: TKMHouseType);
const
  INIT_BID = 10000;
  RESOURCE_PRICE = 1;
  PRODUCT_PRICE = 5;
  MAX_BID = 8;
var
  Idx, BestIdx: Integer;
  Bid, BestBid: Single;
  H: TKMHouse;
begin
  BestBid := INIT_BID;
  BestIdx := 0;
  for Idx := 0 to fPlannedHouses[aHT].Count - 1 do
    with fPlannedHouses[aHT].Plans[Idx] do
    begin
      if not Placed then // Only plan -> remove it have high priority
      begin
        BestBid := 0;
        BestIdx := Idx;
        break;
      end
      else // Plan was placed or there is already house
      begin
        if (fPlannedHouses[aHT].Plans[Idx].House = nil) then // Plan was placed
        begin
          BestBid := 0;
          BestIdx := Idx;
          // Dont break for cycle - maybe there is unplaced plan
        end
        else // There is house
        begin
          H := fPlannedHouses[aHT].Plans[Idx].House;
          Bid := H.CheckResIn(wtAll) * RESOURCE_PRICE + H.CheckResOut(wtAll) * PRODUCT_PRICE;
          if (Bid < BestBid) then // Select house with lowest amount of resources
          begin
            BestBid := Bid;
            BestIdx := Idx;
          end;
        end;
      end;
    end;
  if (BestBid < MAX_BID) then
    with fPlannedHouses[aHT].Plans[BestIdx] do
    begin
      if Placed then
      begin
        if (House = nil) then
          gHands[fOwner].RemHousePlan(Loc)
        else
          House.DemolishHouse(fOwner);
      end;
      RemovePlan(aHT, BestIdx);
    end;
end;

procedure TKMCityPlanner.RemovePlan(aHT: TKMHouseType; aLoc: TKMPoint);
var
  I: Integer;
begin
  for I := 0 to fPlannedHouses[aHT].Count - 1 do
    if KMSamePoint(fPlannedHouses[aHT].Plans[I].Loc,aLoc) then
    begin
      RemovePlan(aHT, I);
      Exit;
    end;
end;

procedure TKMCityPlanner.RemovePlan(aHT: TKMHouseType; aIdx: Integer);
begin
  with fPlannedHouses[aHT] do
  begin
    if (aIdx >= Count) then
      Exit;
    if (Plans[aIdx].House = nil) then // Unlock house plan
      gHands[fOwner].AI.CityManagement.Builder.UnLockHouseLoc(aHT, Plans[aIdx].Loc);
    Count := Count - 1;
    Plans[aIdx] := Plans[Count];
  end;
end;


function TKMCityPlanner.GetHousePlan(aIgnoreTrees, aIgnoreExistingPlans: Boolean; aHT: TKMHouseType; var aLoc: TKMPoint; var aIdx: Integer): Boolean;
var
  Output: Boolean;
  Cnt: Byte;
  BestLocs: TKMPointArray;
begin
  if not aIgnoreExistingPlans AND GetPlan(aHT, False, aLoc, aIdx) then
    Output := True
  else
  begin
    case aHT of
      htWoodcutters: FindForestAndWoodcutter();
      htGoldMine, htIronMine: FindPlaceForMines(aHT, aLoc);
      htCoalMine:
      begin
        if FindPlaceForMines(aHT, aLoc) then
          gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(htCoalMine, aLoc);
      end;
      htQuary:
      begin
        CheckStoneReserves(True,0);
      end;
      htWatchTower:
      begin
        if not fDefenceTowersPlanned then
        begin
          fDefenceTowersPlanned := True;
          PlanDefenceTowers();
        end;
      end;
      else
      begin
        Cnt := FindPlaceForHouse(aIgnoreTrees, aHT, BestLocs);
        if (Cnt > 0) then
        begin
          aLoc := BestLocs[0];
          AddPlan(aHT, aLoc);
          gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(aHT, aLoc);
          FindForestAround(aLoc, False);
        end;
      end;
    end;
    Output := GetPlan(aHT, True, aLoc, aIdx);
  end;
  Result := Output;
end;


function TKMCityPlanner.GetRoadToHouse(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
  function IsRoad(aP: TKMPoint): Boolean;
  begin
    Result := (gAIFields.Influences.AvoidBuilding[aP.Y, aP.X] = AVOID_BUILDING_NODE_LOCK_ROAD) // Reserved road plan
              OR (tpWalkRoad in gTerrain.Land[aP.Y, aP.X].Passability)                         // Completed road
              OR (gHands[fOwner].BuildList.FieldworksList.HasField(aP) = ftRoad)               // Placed road plan
              OR (gTerrain.Land[aP.Y, aP.X].TileLock = tlRoadWork);                            // Road under construction
  end;
// New house plan may overlap existing road -> new road must be done (new road will extend aField list)
  procedure ReplaceOverlappingRoad(aLoc: TKMPoint);
  const
    VECTOR_ARR: array[0..3] of TKMPoint = (  (X:0; Y:1), (X:1; Y:0), (X:0; Y:-1), (X:-1; Y:0)  ); // Move actual position to left, top, right and down
  var
    I,K,RoadsInsidePlanIdx: Integer;
    Point: TKMPoint;
    Road, Path: TKMPointList;
    HMA: THouseMappingArray;
  begin
    HMA := gAIFields.Eye.HousesMapping;
    Road := TKMPointList.Create();
    Path := TKMPointList.Create();
    try
      // Find all road inside of newly placed house plan
      for I := Low(HMA[aHT].Tiles) to High(HMA[aHT].Tiles) do
      begin
        Point := KMPointAdd(aLoc, HMA[aHT].Tiles[I]);
        if IsRoad(Point) then
          Road.Add(Point);
      end;
      // Get outside roads which are connected to road plans inside of the house
      RoadsInsidePlanIdx := Road.Count - 1; // Use Road list for those points
      if RoadsInsidePlanIdx >= 0 then
      begin
        for I := RoadsInsidePlanIdx downto 0 do
          for K := Low(VECTOR_ARR) to High(VECTOR_ARR) do
          begin
            Point := KMPointAdd(Road.Items[I], VECTOR_ARR[K]);
            if IsRoad(Point) AND not Road.Contains(Point) then
              Road.Add(Point);
          end;
        Point := Road.Items[RoadsInsidePlanIdx + 1];
        for I := RoadsInsidePlanIdx + 2 to Road.Count - 1 do
        begin
          Path.Clear;
          if fRoadShortcutPlanner.Route_Make(Road.Items[I], Point, Path) then
            for K := 0 to Path.Count - 1 do
              aField.Add(Path.Items[K]);
        end;
      end;
    finally
      Road.Free;
      Path.Free;
    end;
  end;
  function FindClosestHouseEntrance(var aNewLoc, aExistLoc: TKMPoint): Boolean;
  const
    INIT_DIST = 1000000;
    MAX_WATCHTOWER_DIST = 10;
  var
    K: Integer;
    Dist, BestDist: Single;
    Loc: TKMPoint;
    HT: TKMHouseType;
  begin
    BestDist := INIT_DIST;
    for HT := HOUSE_MIN to HOUSE_MAX do
      for K := 0 to fPlannedHouses[HT].Count - 1 do
        //if ((HT <> htWatchTower) OR (fPlannedHouses[HT].Plans[K].Placed))// Only placed houses in case of WatchTower
        if (fPlannedHouses[HT].Plans[K].Placed)// Only placed houses in case of WatchTower
           AND not fPlannedHouses[HT].Plans[K].RemoveTreeInPlanProcedure // Ignore Remove tree in plan procedure because there is not builded road
           AND not KMSamePoint(fPlannedHouses[HT].Plans[K].Loc, aNewLoc) // Ignore itself
           AND ((HT <> htWoodcutters) OR not fPlannedHouses[HT].Plans[K].ChopOnly) // Chop only woodcutters are planned without road connection so skip it
           AND ((aHT <> htSchool) OR not fPlannedHouses[HT].Plans[K].HouseReservation) then // Dont connect first school with house plan
        begin
          Loc := fPlannedHouses[HT].Plans[K].Loc;
          Dist := abs(Loc.X - aNewLoc.X) + abs(Loc.Y - aNewLoc.Y) * 1.5; // Prefer to connect road in X axis
          // Watchtowers may be far from the city and path may leads out of protected area
          // so if is distance from closest watchtower too far away better select other house type
          // -> secure that path will lead directly to the city
          if (Dist < BestDist) AND ( (aHT <> htWatchTower) OR (HT <> htWatchTower) OR (Dist < MAX_WATCHTOWER_DIST) ) then
          begin
            BestDist := Dist;
            aExistLoc := Loc;
          end;
        end;
    Result := BestDist <> INIT_DIST;
  end;

  function CheckRoadToTowers(): Boolean;
  const
    MAX_ENEMY_INFLUENCE = 150;
  var
    PolygonIdx: Word;
    K: Integer;
  begin
    Result := False;
    // Check road and if it goes to enemy influence remove house plan
    K := 0;
    while (K < aField.Count) do
    begin
      PolygonIdx := gAIFields.NavMesh.KMPoint2Polygon[ aField[K] ];
      if (gAIFields.Influences.GetBestAllianceOwnership(fOwner, PolygonIdx, atEnemy) > MAX_ENEMY_INFLUENCE) then
        Exit;
      K := K + 5;
    end;
    Result := True;
  end;

var
  Output: Boolean;
  NewLoc, ExistLoc: TKMPoint;
  //H: TKMHouse;
begin
  aFieldType := ftRoad;
  ExistLoc := KMPOINT_ZERO;
  NewLoc := fPlannedHouses[aHT].Plans[aIdx].Loc;
  Output := FindClosestHouseEntrance(NewLoc, ExistLoc); // Only placed in case of htWatchTower (htWatchTower are planned at once)
  //H := gHands[fOwner].Houses.FindHouse(htAny, NewLoc.X, NewLoc.Y, 1, False); // True = complete house, False = house plan
  //if (H <> nil) then
  //begin
  //  Output := true;
  //  ExistLoc := H.PointBelowEntrance;
  //end;
  if Output AND fRoadPlanner.Route_Make(KMPointBelow(NewLoc), KMPointBelow(ExistLoc), aField) then
  begin
    Output := True;
    ReplaceOverlappingRoad( fPlannedHouses[aHT].Plans[aIdx].Loc );

    if (aHT = htWatchtower) AND not CheckRoadToTowers() then
    begin
      Output := False;
      RemovePlan(aHT,aIdx);
    end;
  end
  else
    RemovePlan(aHT,aIdx);
  Result := Output;
end;


function TKMCityPlanner.GetRoadBetweenPoints(aStart, aEnd: TKMPoint; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
var
  Output: Boolean;
begin
  Output := False;
  aFieldType := ftRoad;
  if fRoadShortcutPlanner.Route_Make(aEnd, aStart, aField) then
    Output := True;
  Result := Output;
end;


function TKMCityPlanner.GetFieldToHouse(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
begin
  Result := (aHT in [htFarm, htWineyard]);
  if not Result then
    Exit;

  aFieldType := ftCorn;
  if (aHT = htWineyard) then
    aFieldType := ftWine;
  aField.Clear;
  PlanFields( ifthen(aHT = htWineyard,FIELDS_PER_WINE,FIELDS_PER_FARM), fPlannedHouses[aHT].Plans[aIdx].Loc, aFieldType, aField );
end;


function TKMCityPlanner.GetTreesInHousePlan(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList): Byte;
var
  I: Integer;
  Point: TKMPoint;
  HMA: THouseMappingArray;
begin
  aField.Clear;
  HMA := gAIFields.Eye.HousesMapping;
  for I := Low(HMA[aHT].Tiles) to High(HMA[aHT].Tiles) do
  begin
    Point := KMPointAdd( fPlannedHouses[aHT].Plans[aIdx].Loc, HMA[aHT].Tiles[I] );
    if gTerrain.ObjectIsChopableTree(Point, [caAge1,caAge2,caAge3,caAgeFull]) then
      aField.Add(Point);
  end;
  if (aField.Count > 0) then
    for I := Low(HMA[aHT].Tiles) to High(HMA[aHT].Tiles) do
    begin
      Point := KMPointAdd( fPlannedHouses[aHT].Plans[aIdx].Loc, HMA[aHT].Tiles[I] );
      if (gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] = 0) then
        gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] := 10;
    end;
  Result := aField.Count;
end;


{
procedure TKMCityPlanner.PlanWineFields(aLoc: TKMPoint; var aNodeList: TKMPointList);
const
  MAX_VINE = 10;
var
  I,Dist: Integer;
  Dir: TDirection;
  HT: TKMHouseType;
  FieldLoc: TKMPoint;
  HMA: THouseMappingArray;
begin
  HT := htWineyard;
  HMA := gAIFields.Eye.HousesMapping;
  for Dist := 1 to 4 do
  begin
    for Dir := Low(HMA[HT].Surroundings[Dist]) to High(HMA[HT].Surroundings[Dist]) do
    for I := Low(HMA[HT].Surroundings[Dist,Dir]) to High(HMA[HT].Surroundings[Dist,Dir]) do
    begin
      FieldLoc := KMPointAdd(aLoc, HMA[HT].Surroundings[Dist,Dir,I]);
      if gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y)                         // Tile must be in map
        AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ftWine)                     // Plan can be placed
        AND (gAIFields.Influences.AvoidBuilding[FieldLoc.Y, FieldLoc.X] <= AVOID_BUILDING_HOUSE_OUTSIDE_LOCK) then // Tile is not reserved
      begin
        aNodeList.Add(FieldLoc);
        gAIFields.Influences.AvoidBuilding[FieldLoc.Y, FieldLoc.X] := AVOID_BUILDING_NODE_LOCK_FIELD;
      end;
      if (aNodeList.Count >= MAX_VINE) then
        Exit;
    end;
  end;
end;


procedure TKMCityPlanner.PlanFarmFields(aLoc: TKMPoint; var aNodeList: TKMPointList);
type
  TDirArrInt = array[TDirection] of Integer;
  TDirArrByte = array[TDirection] of Byte;
const
  MAX_FIELDS = 15;
  SNAP_TO_EDGE = 5;
  FIELD_PRICE = 1;
  DIR_PRICE: array[TDirection] of Byte = (5,15,20,15); //(dirN,dirE,dirS,dirW);
  PRICE_ARR_CONST: TDirArrInt = (0,0,0,0);
  CNT_ARR_CONST: TDirArrByte = (0,0,0,0);
var
  I,Dist: Integer;
  Dir, BestDir: TDirection;
  HT: TKMHouseType;
  FieldLoc: TKMPoint;
  HMA: THouseMappingArray;
  PriceArr: TDirArrInt;
  CntArr: TDirArrByte;
begin
  PriceArr := PRICE_ARR_CONST;
  CntArr := CNT_ARR_CONST;
  HT := htFarm;
  HMA := gAIFields.Eye.HousesMapping;
  // Get best edge of current loc (try build field in edges)
  Dist := 5;
  for Dir := Low(HMA[HT].Surroundings[Dist]) to High(HMA[HT].Surroundings[Dist]) do
    for I := Low(HMA[HT].Surroundings[Dist,Dir]) + Dist to High(HMA[HT].Surroundings[Dist,Dir]) - Dist + 1 do
    begin
      FieldLoc := KMPointAdd(aLoc, HMA[HT].Surroundings[Dist,Dir,I]);
      if not gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y)
        OR not gTerrain.TileIsRoadable( FieldLoc ) then
        PriceArr[Dir] := PriceArr[Dir] + SNAP_TO_EDGE;
    end;
  // Get count of possible fields
  for Dist := 1 to 4 do
    for Dir := Low(HMA[HT].Surroundings[Dist]) to High(HMA[HT].Surroundings[Dist]) do
      for I := Low(HMA[HT].Surroundings[Dist,Dir]) + Dist to High(HMA[HT].Surroundings[Dist,Dir]) - Dist + 1 do
      begin
        FieldLoc := KMPointAdd(aLoc, HMA[HT].Surroundings[Dist,Dir,I]);
        if gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y)                          // Tile must be in map
          AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ftCorn)                      // Plan can be placed
          AND (gAIFields.Influences.AvoidBuilding[FieldLoc.Y, FieldLoc.X] <= AVOID_BUILDING_HOUSE_OUTSIDE_LOCK) then  // Tile is not reserved
          CntArr[Dir] := CntArr[Dir] + FIELD_PRICE;
      end;
  // Compute price of each direction
  for Dir := Low(PriceArr) to High(PriceArr) do
    PriceArr[Dir] := PriceArr[Dir] + CntArr[Dir] + DIR_PRICE[Dir];
  // Pic the best fields
  while (aNodeList.Count < MAX_FIELDS) do
  begin
    // Find best direction
    BestDir := Low(PriceArr);
    for Dir := Low(PriceArr) to High(PriceArr) do
      if (PriceArr[Dir] > PriceArr[BestDir]) then
        BestDir := Dir;
    // Anti-overload condition
    if (PriceArr[BestDir] = -1) then
      Break;
    PriceArr[BestDir] := -1;
    // Add best fields to aNodeList
    Dir := BestDir;
    for Dist := 1 to 4 do
    begin
      for I := Low(HMA[HT].Surroundings[Dist,Dir]) + Dist to High(HMA[HT].Surroundings[Dist,Dir]) - Dist + 1 do
      begin
        FieldLoc := KMPointAdd(aLoc, HMA[HT].Surroundings[Dist,Dir,I]);
        if gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y)
          AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ftCorn)
          AND (gAIFields.Influences.AvoidBuilding[FieldLoc.Y, FieldLoc.X] <= AVOID_BUILDING_HOUSE_OUTSIDE_LOCK) then
          aNodeList.Add(FieldLoc);
      end;
      if (aNodeList.Count > MAX_FIELDS) then
        Break;
    end;
  end;
end;
}


function TKMCityPlanner.CheckFields(var aFieldType: TKMFieldType; var aNodeList: TKMPointList): Boolean;
  function IsWine(aP: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsWineField(aP)
              OR (gHands[fOwner].BuildList.FieldworksList.HasField(aP) = ftWine)
              OR (gTerrain.Land[aP.Y, aP.X].TileLock = tlFieldWork)
              OR ((gAIFields.Influences.AvoidBuilding[aP.Y, aP.X] = AVOID_BUILDING_NODE_LOCK_FIELD) AND (gHands[fOwner].CanAddFieldPlan(aP, ftWine)));
  end;
  function IsField(aP: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsCornField(aP)
              OR (gHands[fOwner].BuildList.FieldworksList.HasField(aP) = ftCorn)
              OR (gTerrain.Land[aP.Y, aP.X].TileLock = tlFieldWork)
              OR ((gAIFields.Influences.AvoidBuilding[aP.Y, aP.X] = AVOID_BUILDING_NODE_LOCK_FIELD) AND (gHands[fOwner].CanAddFieldPlan(aP, ftCorn)));
  end;
var
  K,Cnt,ExpectedCnt: Integer;
begin
  Result := False;
  if (fFields.Count <= 0) then
    Exit;

  fFields.UpdateIdx := (fFields.UpdateIdx + 1) mod fFields.Count;
  with fFields.Farms[ fFields.UpdateIdx ] do
  begin
    if not FieldAvailable then
      Exit;
    ExpectedCnt := FIELDS_PER_FARM * Byte(FieldType = ftCorn) + FIELDS_PER_WINE * Byte(FieldType = ftWine);
    Cnt := ExpectedCnt;
    for K := ExpectedCnt - 1 downto Low(Points) do
      if KMSamePoint(Points[K],KMPoint_ZERO) OR ((FieldType = ftWine) AND not IsWine(Points[K])) OR ((FieldType = ftCorn) AND not IsField(Points[K])) then
      begin
        Cnt := Cnt - 1;
        Points[K] := Points[Cnt];
        Points[Cnt] := KMPoint_ZERO;
      end;
    if (ExpectedCnt - Cnt > 1) then
    begin
      PlanFields(ExpectedCnt-Cnt, Center, FieldType, aNodeList, fFields.UpdateIdx, Cnt);
      aFieldType := FieldType;
    end;
  end;

  Result := aNodeList.Count > 0;
end;


procedure TKMCityPlanner.PlanFields(aCnt: Word; aLoc: TKMPoint; aFieldType: TKMFieldType; var aNodeList: TKMPointList; aReplaceFarmIdx: Integer = -1; aReplaceFieldIdx: Word = 0);
var
  Check: Boolean;
  X,Y, X2,Y2: Integer;
  BelowLoc, P, P2: TKMPoint;
  Build: array[-FARM_RADIUS..FARM_RADIUS,-FARM_RADIUS..FARM_RADIUS] of Boolean;
  Price: TFieldPrice;
  TagList: TKMPointTagList;
  BuildFF: TKMBuildFF;
  {$IFDEF DEBUG_NewAI}
  Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
  Time := TimeGet();
  FillChar(DA1, SizeOf(DA1), #0);
  FillChar(DA2, SizeOf(DA2), #0);
  FillChar(DA3, SizeOf(DA3), #0);
  FillChar(DA4, SizeOf(DA4), #0);
  {$ENDIF}
  FillChar(Price, SizeOf(Price), #0);


  BuildFF := gAIFields.Eye.BuildFF;
  BuildFF.UpdateState(); // BuildFF is already updated if Fields are requested in same tick like Farm
  BelowLoc := KMPointBelow(aLoc);

  fFieldEval.EvalField(FARM_RADIUS, BelowLoc, aFieldType);

  // Find build areas (11*11 = 121)
  for Y := -FARM_RADIUS to +FARM_RADIUS do
  for X := -FARM_RADIUS to +FARM_RADIUS do
    Build[Y,X] := gTerrain.TileInMapCoords(BelowLoc.X+X, BelowLoc.Y+Y) AND (BuildFF.State[BelowLoc.Y+Y,BelowLoc.X+X] in [bsBuild, bsTree] );

  // Evaluate fields
  for Y := -FARM_RADIUS+1 to +FARM_RADIUS-1 do
  for X := -FARM_RADIUS+1 to +FARM_RADIUS-1 do
    with fFieldEval do
    begin
      // Evaluate tbBuild
      Check := True;
      for Y2 := -1 to +1 do
      for X2 := -1 to +1 do
        if not Check OR not Build[Y+Y2,X+X2] then
        begin
          Check := False;
          break;
        end;
      if Check then
        for Y2 := -1 to +1 do
        for X2 := -1 to +1 do
        begin
          Dec(Price[Y+Y2,X+X2], GA_PLANNER_PlanFields_CanBuild);
        {$IFDEF DEBUG_NewAI}
          P := KMPointAdd(KMPoint(X,Y),BelowLoc);
          if gTerrain.TileInMapCoords(P.X-1, P.Y-1) AND gTerrain.TileInMapCoords(P.X+1, P.Y+1) then
            Inc(DA3[P.Y+Y2,P.X+X2], 40);
        {$ENDIF}
        end;
      // Evaluate fertile tiles
      P := KMPointAdd(KMPoint(X,Y),BelowLoc);
      if gTerrain.TileInMapCoords(P.X, P.Y) then
        case FieldEval[Y,X] of
          {$IFDEF DEBUG_NewAI}
          feUnvisitedTile:
          begin
            DA4[P.Y,P.X] := 50;
          end;
          {$ENDIF}
          feExistingField:
          begin
            if (Y > -FARM_RADIUS+2) AND (Y < FARM_RADIUS-2) AND (X > -FARM_RADIUS+2) AND (X < FARM_RADIUS-2) then
              for Y2 := -2 to +2 do
              for X2 := -2 to +2 do
                Price[Y2,X2] := Price[Y2,X2] + Round(GA_PLANNER_PlanFields_ExistField * (1 - 0.2 * (abs(Y2) + abs(X2))));
          {$IFDEF DEBUG_NewAI}
            DA2[P.Y,P.X] := 100;
          {$ENDIF}
          end;
          feFertileTile:
          begin
            Price[Y,X] := Price[Y,X] + GA_PLANNER_PlanFields_Dist * (FARM_RADIUS - FieldPrice[Y,X]);
          end;
          feObstacle: begin end;
        end;
    end;

  if (Length(fFields.Farms) <= fFields.Count) then
    SetLength(fFields.Farms,fFields.Count + 6);
  TagList := TKMPointTagList.Create();
  try
    for Y := -FARM_RADIUS to +FARM_RADIUS do
    for X := -FARM_RADIUS to +FARM_RADIUS do
      if (fFieldEval.FieldEval[Y,X] = feFertileTile) then
      begin
        P := KMPointAdd(KMPoint(X,Y),BelowLoc);
        TagList.Add(P, 2000 + Price[Y,X]);
        {$IFDEF DEBUG_NewAI}
        DA1[P.Y,P.X] := Price[Y,X];
        {$ENDIF}
      end;
    TagList.SortByTag;
    with fFields.Farms[ ifthen(aReplaceFarmIdx <> -1, aReplaceFarmIdx, fFields.Count) ] do
    begin
      X2 := aReplaceFieldIdx;
      for X := TagList.Count - 1 downto Max(0, TagList.Count - aCnt) do
      begin
        Points[X2] := TagList.Items[X];
        Inc(X2);
        aNodeList.Add(TagList.Items[X]);
      end;
      Center := aLoc;
      FieldType := aFieldType;
      FieldAvailable := TagList.Count > aCnt;
    end;
    fFields.Count := fFields.Count + Byte(aReplaceFarmIdx = -1);
  finally
    TagList.Free;
  end;
  {$IFDEF DEBUG_NewAI}
  fFieldPrice := Price;
  Time := TimeGet() - Time;
  fTimeSumPlanFields := fTimeSumPlanFields + Time;
  if (Time > fTimePeakPlanFields) then
    fTimePeakPlanFields := Time;
  {$ENDIF}
end;


function TKMCityPlanner.ObstaclesInHousePlan(aHT: TKMHouseType; aLoc: TKMPoint): Single;
var
  I,X,Y,Road,Tree: Integer;
  HMA: THouseMappingArray;
begin
  Road := 0;
  Tree := 0;
  HMA := gAIFields.Eye.HousesMapping;
  for I := Low(HMA[aHT].Tiles) to High(HMA[aHT].Tiles) do
  begin
    X := aLoc.X + HMA[aHT].Tiles[I].X;
    Y := aLoc.Y + HMA[aHT].Tiles[I].Y;
    Tree := Tree + Byte(gTerrain.ObjectIsChopableTree(KMPoint(X,Y), [caAge1,caAge2,caAge3,caAgeFull]));
    Road := Road + Byte(tpWalkRoad in gTerrain.Land[Y, X].Passability);
  end;
  Result := Tree * GA_PLANNER_ObstaclesInHousePlan_Tree + Road * GA_PLANNER_ObstaclesInHousePlan_Road;
end;


function TKMCityPlanner.FieldCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
const
  MIN_CORN_FIELDS = 15;
  MIN_WINE_FIELDS = 9;
  DECREASE_CRIT = 1000;
var
  X,Y,I,Dist,Fields: Integer;
  Dir: TDirection;
  HMA: THouseMappingArray;
begin
  HMA := gAIFields.Eye.HousesMapping;
  Fields := 0;
  for Dist := 1 to (Byte(aHT = htWineyard) * 2) + (Byte(aHT = htFarm) * 5) do
    for Dir := Low(HMA[aHT].Surroundings[Dist]) to High(HMA[aHT].Surroundings[Dist]) do
      for I := Low(HMA[aHT].Surroundings[Dist,Dir]) + Dist to High(HMA[aHT].Surroundings[Dist,Dir]) - Dist + 1 do
      begin
        X := aLoc.X + HMA[aHT].Surroundings[Dist,Dir,I].X;
        Y := aLoc.Y + HMA[aHT].Surroundings[Dist,Dir,I].Y;
        if gTerrain.TileInMapCoords(X,Y)
          AND (gAIFields.Influences.AvoidBuilding[Y,X] = 0) // Tile is not reserved (house / road / field / forest)
          AND gHands[fOwner].CanAddFieldPlan(KMPoint(X,Y), ftCorn) then
            Fields := Fields + 1;
      end;
  Result := - (
              + Max(0, MIN_WINE_FIELDS - Fields) * Byte(aHT = htWineyard) * DECREASE_CRIT
              + Max(0, MIN_CORN_FIELDS - Fields) * Byte(aHT = htFarm) * DECREASE_CRIT
            )
            - gAIFields.Eye.Routes[aLoc.Y, aLoc.X] * GA_PLANNER_FieldCrit_PolyRoute
            - gAIFields.Eye.FlatArea[aLoc.Y, aLoc.X] * GA_PLANNER_FieldCrit_FlatArea
            + gAIFields.Eye.Soil[aLoc.Y, aLoc.X] * GA_PLANNER_FieldCrit_Soil;
end;


function TKMCityPlanner.SnapCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
  function IsPlan(aPoint: TKMPoint; aLock: TKMTileLock; aField: TKMFieldType): Boolean;
  begin
    Result := (gHands[fOwner].BuildList.FieldworksList.HasField(aPoint) = aField) // Placed plan
              OR (gTerrain.Land[aPoint.Y, aPoint.X].TileLock = aLock);            // Plan under construction
  end;
  function IsRoad(aAvoidBuilding: Byte; aPoint: TKMPoint): Boolean; inline;
  begin
    Result := (aAvoidBuilding = AVOID_BUILDING_NODE_LOCK_ROAD) // Reserved road plan
              OR gTerrain.TileIsWalkableRoad(aPoint)           // Completed road
              OR IsPlan(aPoint, tlRoadWork, ftRoad);           // Check plan
  end;
  function IsCornField(aPoint: TKMPoint): Boolean; inline;
  begin
    Result := gTerrain.TileIsCornField(aPoint) OR IsPlan(aPoint, tlFieldWork, ftCorn);
  end;
  function IsWineField(aPoint: TKMPoint): Boolean; inline;
  begin
    Result := gTerrain.TileIsWineField(aPoint) OR IsPlan(aPoint, tlFieldWork, ftWine);
  end;
  function IsNearHouse(aAvoidBuilding: Byte; aPoint: TKMPoint): Boolean; inline;
  begin
    Result := (aAvoidBuilding = AVOID_BUILDING_HOUSE_OUTSIDE_LOCK)
              OR not (tpBuild in gTerrain.Land[aPoint.Y,aPoint.X].Passability);
  end;
  function IsReservedField(aAvoidBuilding: Byte): Boolean; inline;
  begin
    Result := (aAvoidBuilding = AVOID_BUILDING_NODE_LOCK_FIELD);
  end;
const
  DIST = 1;
var
  AvoidBuilding: Byte;
  K: Integer;
  Output: Single;
  Point: TKMPoint;
  Dir: TDirection;
  HMA: THouseMappingArray;
begin
  Output := 0;
  HMA := gAIFields.Eye.HousesMapping;
  for Dir := Low(HMA[aHT].Surroundings[DIST]) to High(HMA[aHT].Surroundings[DIST]) do
    // Skip edges in specific direction (these points are shared in 2 directions)
    for K := Low(HMA[aHT].Surroundings[DIST,Dir]) + Byte((Dir = dirE) OR (Dir = dirW)) to High(HMA[aHT].Surroundings[DIST,Dir]) - Byte((Dir = dirE) OR (Dir = dirW)) do
    begin
      Point := KMPointAdd(aLoc, HMA[aHT].Surroundings[DIST,Dir,K]);
      AvoidBuilding := gAIFields.Influences.AvoidBuilding[Point.Y, Point.X];
      Output := Output
                + Byte(IsNearHouse(AvoidBuilding,Point)) * GA_PLANNER_SnapCrit_SnapToHouse
                + Byte(IsReservedField(AvoidBuilding)) * GA_PLANNER_SnapCrit_SnapToFields // OR IsCornField(Point) OR IsWineField(Point)
                + Byte(IsRoad(AvoidBuilding,Point)) * GA_PLANNER_SnapCrit_SnapToRoads;
    end;
  Output := Output
            - Byte(IsReservedField( gAIFields.Influences.AvoidBuilding[aLoc.Y+1,aLoc.X] )) * GA_PLANNER_SnapCrit_ObstacleInEntrance
            + Byte(IsRoad( gAIFields.Influences.AvoidBuilding[aLoc.Y+1,aLoc.X], aLoc )) * GA_PLANNER_SnapCrit_RoadInEntrance;
  Result := Output;
end;


function TKMCityPlanner.DistCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
  function ClosestDistance(): Single;
  const
    MAX_DIST = 1000;
  var
    I: Integer;
    Output, Bid: Single;
    HT: TKMHouseType;
  begin
    Output := MAX_DIST;
    for HT in HOUSE_DEPENDENCE[aHT] do
      for I := 0 to fPlannedHouses[HT].Count - 1 do
      begin
        with fPlannedHouses[HT].Plans[I].Loc do
          Bid := abs(aLoc.X - X) + abs(aLoc.Y - Y) * 1.5;
        if (Bid < Output) then
          Output := Bid;
      end;
    if (Output = MAX_DIST) then
      Output := 0;
    Result := Output;
  end;
  function AllDistances(): Single;
  var
    I: Integer;
    HT: TKMHouseType;
  begin
    Result := 0;
    for HT in HOUSE_DEPENDENCE[aHT] do
      for I := 0 to fPlannedHouses[HT].Count - 1 do
        Result := Result + KMDistanceAbs(aLoc, fPlannedHouses[HT].Plans[I].Loc);
  end;
begin
  if (aHT = htBarracks) then
    Result := - AllDistances()
  else
    Result := - ClosestDistance();
end;


// So far the fastest method for placing houses
function TKMCityPlanner.FindPlaceForHouse(aIgnoreTrees: Boolean; aHT: TKMHouseType; out aBestLocs: TKMPointArray): Byte;
const
  BEST_PLANS_CNT = 8;
  INIT_BEST_GAIN = -1E20;
var
  CityCenter: TKMPoint;
  BestGainArr: array[0..BEST_PLANS_CNT-1] of Double;

  function EvalFreeEntrance(aLoc: TKMPoint): Single;
  const
    OBSTACLE_COEF = 1000;
  var
    K: Integer;
  begin
    Result := 0;
    if (aLoc.Y+2 >= gTerrain.MapY) then
    begin
      Result := OBSTACLE_COEF * 3;
      Exit;
    end;
    for K := -1 to 1 do
      Result := Result + Byte(tpWalk in gTerrain.Land[aLoc.Y+2,aLoc.X+K].Passability) * OBSTACLE_COEF;
  end;

  {$IFDEF DEBUG_NewAI}
  procedure CommentFarmLoc(aLoc: TKMPoint; aObstacles, aSnap, aSeedDist, aHouseDist, aCenterDist, aRoutes, aFlatArea, aAllyInf, aEnemyInfl, aFieldCrit, aSum: Double);
  var
    Coef: Double;
  begin
    if KMSamePoint(aLoc, aBestLocs[0]) then
      fPlaceFarmDebugText := Format('New farm; Time sum: %d, peak:  %d'
        + '|Perc'
        + #9 + '[X,Y]'
        + #9#9 + 'Obstac'
        + #9#9 + 'Snap'
        + #9#9 + 'SeedD'
        + #9#9 + 'HouseD'
        + #9#9 + 'CntrD'
        + #9#9 + 'Routes'
        + #9#9 + 'FlatAr'
        + #9#9 + 'AllInf'
        + #9#9 + 'EnmInf'
        + #9#9 + 'FieldCrtit',[fTimeSumSearchHouse[htFarm],fTimePeakSearchHouse[htFarm]]);
    Coef := 1;
    if (BestGainArr[0] <> 0) then
      Coef := (-100 / BestGainArr[0]);
    fPlaceFarmDebugText := fPlaceFarmDebugText + Format(
      '|%3.1f' + #9 + '[%d,%d]' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f',
      [aSum * Coef, aLoc.X, aLoc.Y,
        Coef * aObstacles,
        Coef * aSnap,
        Coef * aSeedDist,
        Coef * aHouseDist,
        Coef * aCenterDist,
        Coef * aRoutes,
        Coef * aFlatArea,
        Coef * aAllyInf,
        Coef * aEnemyInfl,
        Coef * aFieldCrit
      ]);
  end;
  procedure CommentHouseLoc(aLoc: TKMPoint; aObstacles, aSnap, aSeedDist, aHouseDist, aCenterDist, aRoutes, aFlatArea, aAllyInf, aEnemyInfl, aFreeEntr, aSum: Double);
  var
    Coef: Double;
    Sum, Peak: Cardinal;
    HT: TKMHouseType;
  begin
    Sum := 0;
    Peak := 0;
    for HT := Low(fTimeSumSearchHouse) to High(fTimeSumSearchHouse) do
    begin
      if (HT <> htFarm) then
        Sum := Sum + fTimeSumSearchHouse[HT];
      if (Peak < fTimePeakSearchHouse[HT]) then
        Peak := fTimePeakSearchHouse[HT];
    end;
    if KMSamePoint(aLoc, aBestLocs[0]) then
      fPlaceHouseDebugText := Format('New house: %s; Time sum: %d, peak: %d'
        + '|Perc'
        + #9 + '[X,Y]'
        + #9#9 + 'Obstac'
        + #9#9 + 'Snap'
        + #9#9 + 'SeedD'
        + #9#9 + 'HouseD'
        + #9#9 + 'CntrD'
        + #9#9 + 'Routes'
        + #9#9 + 'FlatAr'
        + #9#9 + 'AllInf'
        + #9#9 + 'EnmInf'
        + #9#9 + 'FreeEntr',[gRes.Houses[aHT].HouseName, Sum, Peak]);
    Coef := 1;
    if (BestGainArr[0] <> 0) then
      Coef := (100 / BestGainArr[0]);
    fPlaceHouseDebugText := fPlaceHouseDebugText + Format(
      '|%3.1f' + #9 + '[%d,%d]'+ #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f',
      [aSum * Coef, aLoc.X, aLoc.Y,
        Coef * aObstacles,
        Coef * aSnap,
        Coef * aSeedDist,
        Coef * aHouseDist,
        Coef * aCenterDist,
        Coef * aRoutes,
        Coef * aFlatArea,
        Coef * aAllyInf,
        Coef * aEnemyInfl,
        Coef * aFreeEntr
      ]);
  end;
  {$ENDIF}

  procedure EvaluateLoc(aLoc: TKMPoint; aDebugLog: Boolean = False);
  var
    L: Integer;
    Gain, Obstacles, Snap, SeedDist, HouseDist, CenterDist, Routes, FlatArea, FreeEntrance, AllyInf, EnemyInfl, Field: Double;
  begin
    // Evaluate loc
    if (aHT = htFarm) OR (aHT = htWineyard) then
    begin
      Obstacles :=    - ObstaclesInHousePlan(aHT, aLoc);
      Snap :=         + SnapCrit(aHT, aLoc)                    * GA_PLANNER_FindPlaceForHouse_SnapCrit;
      SeedDist :=     - gAIFields.Eye.BuildFF.Distance[aLoc]   * GA_PLANNER_FindPlaceForHouse_SeedDist;
      HouseDist :=    + DistCrit(aHT, aLoc)                    * GA_PLANNER_FindPlaceForHouse_HouseDistFarm;
      CenterDist :=   - KMDistanceAbs(CityCenter, aLoc)        * GA_PLANNER_FindPlaceForHouse_CityCenterFarm;
      Routes :=       + gAIFields.Eye.Routes[aLoc.Y, aLoc.X]   * GA_PLANNER_FindPlaceForHouse_RouteFarm;
      FlatArea :=     + gAIFields.Eye.FlatArea[aLoc.Y, aLoc.X] * GA_PLANNER_FindPlaceForHouse_FlatAreaFarm;
      AllyInf :=      - gAIFields.Influences.GetBestAllianceOwnership(fOwner, aLoc.X, aLoc.Y, atAlly)  * GA_PLANNER_FindPlaceForHouse_AllyInfluence;
      EnemyInfl :=    - gAIFields.Influences.GetBestAllianceOwnership(fOwner, aLoc.X, aLoc.Y, atEnemy) * GA_PLANNER_FindPlaceForHouse_EnemyInfluence;
      Field :=    + FieldCrit(aHT, aLoc);
      Gain := Snap + HouseDist + CenterDist + SeedDist + Routes + FlatArea + Obstacles + AllyInf + EnemyInfl + Field;
      {$IFDEF DEBUG_NewAI}
      if aDebugLog then
        CommentFarmLoc(aLoc, Obstacles, Snap, SeedDist, HouseDist, CenterDist, Routes, FlatArea, AllyInf, EnemyInfl, Field, Gain);
      {$ENDIF}
    end
    else
    begin
      Obstacles :=    - ObstaclesInHousePlan(aHT, aLoc);
      Snap :=         + SnapCrit(aHT, aLoc)                    * GA_PLANNER_FindPlaceForHouse_SnapCrit;
      SeedDist :=     - gAIFields.Eye.BuildFF.Distance[aLoc]   * GA_PLANNER_FindPlaceForHouse_SeedDist;
      HouseDist :=    + DistCrit(aHT, aLoc)                    * GA_PLANNER_FindPlaceForHouse_HouseDist;
      CenterDist :=   - KMDistanceAbs(CityCenter, aLoc)        * GA_PLANNER_FindPlaceForHouse_CityCenter;
      Routes :=       + gAIFields.Eye.Routes[aLoc.Y, aLoc.X]   * GA_PLANNER_FindPlaceForHouse_Route;
      FlatArea :=     + gAIFields.Eye.FlatArea[aLoc.Y, aLoc.X] * GA_PLANNER_FindPlaceForHouse_FlatArea;
      AllyInf :=      - gAIFields.Influences.GetBestAllianceOwnership(fOwner, aLoc.X, aLoc.Y, atAlly)  * GA_PLANNER_FindPlaceForHouse_AllyInfluence;
      EnemyInfl :=    - gAIFields.Influences.GetBestAllianceOwnership(fOwner, aLoc.X, aLoc.Y, atEnemy) * GA_PLANNER_FindPlaceForHouse_EnemyInfluence;
      FreeEntrance := 0;
      if (aHT = htStore) OR (aHT = htBarracks) then
        FreeEntrance := EvalFreeEntrance(aLoc);
      Gain := Snap + HouseDist + CenterDist + SeedDist + Routes + FlatArea + Obstacles + AllyInf + EnemyInfl + FreeEntrance;
      {$IFDEF DEBUG_NewAI}
      if aDebugLog then
        CommentHouseLoc(aLoc, Obstacles, Snap, SeedDist, HouseDist, CenterDist, Routes, FlatArea, AllyInf, EnemyInfl, FreeEntrance, Gain);
      {$ENDIF}
    end;
    // Sort loc
    if not aDebugLog then
      for L := 0 to BEST_PLANS_CNT - 1 do
        if KMSamePoint(aLoc, aBestLocs[L]) then // Just to be sure
          break
        else if (Gain > BestGainArr[L]) then // Insert sort for BEST_PLANS_CNT elements ...
        begin
          KMSwapPoints(aLoc, aBestLocs[L]);
          KMSwapFloat(Gain, BestGainArr[L]);
        end;
  end;

const
  PROBABILITY = 0.3;
  MAX_RND_HOUSES = 10;
var
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
    Coef: Single;
  {$ENDIF}
  L, HouseCnt: Integer;
  HT: TKMHouseType;
  InitPointsArr: TKMPointArray;
  HouseReq: TKMHouseRequirements;
  BuildFF: TKMBuildFF;
  CCPArr: TKMPointArray;
begin
  Result := 0;

  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}

  CCPArr := gAIFields.Eye.GetCityCenterPoints(False);
  if (Length(CCPArr) <= 0) then
    Exit;
  CityCenter := CCPArr[0];

  with HouseReq do
  begin
    HouseType := aHT;
    IgnoreTrees := aIgnoreTrees;
    IgnoreAvoidBuilding := False;
    //MaxCnt := 40; // Huge performance impact (with 10 plans needs 40 ms to build city; 100 needs 320 ms)
    MaxDist := 30 - 20 * Byte(aHT = htMetallurgists);
    MaxCnt := 100; // Huge performance impact (with 10 plans needs 40 ms to build city; 100 needs 320 ms)
  end;

  BuildFF := gAIFields.Eye.BuildFF;

  SetLength(aBestLocs, BEST_PLANS_CNT);
  for L := 0 to BEST_PLANS_CNT - 1 do
    BestGainArr[L] := INIT_BEST_GAIN;

  if SP_BOOST_AI_BUILD then
  begin
    HouseCnt := 0;
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      if not (HT in [htWatchTower, htWoodcutters, htCoalMine, htIronMine, htGoldMine]) then
        for L := fPlannedHouses[HT].Count - 1 downto 0 do
        begin
          if (Length(InitPointsArr) <= HouseCnt) then
            SetLength(InitPointsArr, Length(InitPointsArr) + 32);
          InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[L].Loc); // Place for mines can be problematic
          HouseCnt := HouseCnt + 1;
        end;
    end;
    SetLength(InitPointsArr,HouseCnt);
    BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, True);
  end
  else
  begin
    HouseCnt := 0;
    for HT in HOUSE_DEPENDENCE[aHT] do
      HouseCnt := HouseCnt + fPlannedHouses[HT].Count;
    SetLength(InitPointsArr, HouseCnt);

    HouseCnt := 0;
    for HT in HOUSE_DEPENDENCE[aHT] do
      for L := 0 to fPlannedHouses[HT].Count - 1 do
      begin
        InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[L].Loc); // Place for mines can be problematic
        HouseCnt := HouseCnt + 1;
      end;
    BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, True);

    if (BuildFF.Locs.Count < 10) then
    begin
      if (Length(InitPointsArr) < MAX_RND_HOUSES) then
        SetLength(InitPointsArr, MAX_RND_HOUSES);
      HouseCnt := 0;
      for HT := HOUSE_MIN to HOUSE_MAX do
      begin
        if not (HT in [htWatchTower, htWoodcutters, htCoalMine, htIronMine, htGoldMine])
          AND not (HT in HOUSE_DEPENDENCE[aHT]) then
          for L := fPlannedHouses[HT].Count - 1 downto 0 do
            if (HouseCnt = 0) OR (KaMRandom('TKMCityPlanner.FindPlaceForHouse') < PROBABILITY) then
            begin
              if (HouseCnt >= MAX_RND_HOUSES) then
                break;
              InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[L].Loc); // Place for mines can be problematic
              HouseCnt := HouseCnt + 1;
            end;
        if (HouseCnt >= MAX_RND_HOUSES) then
          break;
      end;
      SetLength(InitPointsArr,HouseCnt);
      BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, False);
    end;
  end;

  with BuildFF.Locs do
    for L := 0 to Count - 1 do
      EvaluateLoc(Items[L]);

  Result := Byte(INIT_BEST_GAIN <> BestGainArr[0] );


  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchHouse[aHT] := fTimeSumSearchHouse[aHT] + Time;
    if (fTimePeakSearchHouse[aHT] < Time) then
      fTimePeakSearchHouse[aHT] := Time;

    SetLength(fBestHouseLocs,Min(BEST_PLANS_CNT-1,5)+1);
    SetLength(fBestHouseVal,Length(fBestHouseLocs));
    Coef := Max(0.0000001, 100 / Max(0.00001,BestGainArr[0]));
    for L := 0 to Min(BEST_PLANS_CNT-1,5) do
    begin
      if (INIT_BEST_GAIN = BestGainArr[L]) then
        break;
      fBestHouseLocs[L] := aBestLocs[L];
      fBestHouseVal[L] := Max(0, Min(250, Round(BestGainArr[L] * Coef) + 100 ));
      EvaluateLoc(aBestLocs[L], True);
    end;
  {$ENDIF}
end;


function TKMCityPlanner.FindPlaceForMines(aHT: TKMHouseType; var aLoc: TKMPoint): Boolean;
const
  MAX_LOCS = 5;

  // Get closest mine
  function FindPlaceForMine(aMine: TKMHouseType): Boolean;
  const
    BEST_GAIN = -10000;
  var
    Output, Check: Boolean;
    I, K, BestIdx: Integer;
    Gain, BestGain: Single;
    Loc: TKMPoint;
    Locs: TKMPointTagList;
    BuildFF: TKMBuildFF;
  begin
    Output := False;
    BuildFF := gAIFields.Eye.BuildFF;

    Locs := gAIFields.Eye.GetMineLocs(aMine);
    try
      if (Locs.Count > 0) then
      begin
        BuildFF.UpdateState(); // Mark walkable area in owner's city
        for I := 0 to Locs.Count - 1 do
          if (BuildFF.VisitIdx = BuildFF.Visited[ Locs.Items[I].Y+1, Locs.Items[I].X ]) then // Prefer mines in walkable area
            Locs.Tag[I] := 10000 + Locs.Tag[I] - BuildFF.Distance[ Locs.Items[I] ]*10 - gAIFields.Influences.GetOtherOwnerships(fOwner, Locs.Items[I].X, Locs.Items[I].Y);
        Locs.SortByTag();
        BestGain := BEST_GAIN;
        BestIdx := 0; // For compiler
        for I := Locs.Count-1 downto 0 do
        begin
          // Check reserved mines
          Check := True;
          for K := 0 to fPlannedHouses[aMine].Count - 1 do
          begin
            Loc := fPlannedHouses[aMine].Plans[K].Loc;
            if KMSamePoint(Loc, Locs.Items[I])
              AND not ( (Loc.Y <> Locs.Items[I].Y) OR (Abs(Loc.X - Locs.Items[I].X) > (3 + Byte(aMine = htIronMine))) ) then
            begin
              Check := False;
              continue;
            end;
          end;
          if not Check then
            continue;
          Gain := Locs.Tag[I] + DistCrit(aMine, Locs.Items[I]) * 4;
          if (Gain > BestGain) then
          begin
            BestIdx := I;
            BestGain := Gain;
          end;
        end;
        if (BestGain <> BEST_GAIN) then
        begin
          AddPlan(aHT, Locs.Items[BestIdx]);
          aLoc := Locs.Items[BestIdx];
          Output := True;
        end;
      end;
    finally
      Locs.Free;
    end;
    Result := Output;
  end;

  // Coal mine planner
  function FindPlaceForCoalMine(): Boolean;
  const
    INIT_GAIN = -10000;
  var
    I, BestIdx, HouseCnt: Integer;
    Gain, BestGain: Single;
    HT: TKMHouseType;
    InitPointsArr: TKMPointArray;
    HouseReq: TKMHouseRequirements;
    BuildFF: TKMBuildFF;
  begin
    BuildFF := gAIFields.Eye.BuildFF;

    HouseCnt := 0;
    for HT := Low(fPlannedHouses) to High(fPlannedHouses) do
      HouseCnt := HouseCnt + fPlannedHouses[HT].Count;

    SetLength(InitPointsArr, HouseCnt);
    HouseCnt := 0;
    for HT := Low(fPlannedHouses) to High(fPlannedHouses) do
      for I := 0 to fPlannedHouses[HT].Count - 1 do
      begin
        InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[I].Loc); // Place under mines can be problematic
        HouseCnt := HouseCnt + 1;
      end;

    with HouseReq do
    begin
      HouseType := aHT;
      IgnoreTrees := False;
      IgnoreAvoidBuilding := True;
      MaxCnt := 20; // Huge performance impact (with 10 plans needs 40 ms to build city; 100 needs 320 ms)
      MaxDist := 30;
    end;
    BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, True);

    BestGain := INIT_GAIN;
    BestIdx := -1;
    with BuildFF.Locs do
    begin
      for I := 0 to Count - 1 do
      begin
        Gain := - BuildFF.Distance[ Items[I] ] * 10
                + SnapCrit(htCoalMine, Items[I])
                - ObstaclesInHousePlan(htCoalMine, Items[I])
                - gAIFields.Influences.GetOtherOwnerships(fOwner, Items[I].X, Items[I].Y);
        if (Gain > BestGain) then
        begin
          BestIdx := I;
          aLoc := Items[BestIdx];
          BestGain := Gain;
        end;
      end;
      if (BestIdx <> -1) then
        AddPlan(aHT, Items[BestIdx]);
    end;
    Result := (BestIdx <> -1);
  end;
var
  Output: Boolean;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}
  case aHT of
    htGoldMine:  Output := FindPlaceForMine(htGoldMine);
    htIronMine:  Output := FindPlaceForMine(htIronMine);
    htCoalMine:  Output := FindPlaceForCoalMine();
    else         Output := False;
  end;
  Result := Output;
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchHouse[aHT] := fTimeSumSearchHouse[aHT] + Time;
    if (fTimePeakSearchHouse[aHT] < Time) then
      fTimePeakSearchHouse[aHT] := Time;
  {$ENDIF}
end;


procedure TKMCityPlanner.CheckStoneReserves(aForceToPlaceQuarry: Boolean; aReqQuarryCnt: Integer);
const
  HT = htQuary;
  MAX_DIST = 15;
  MIN_CNT = 60; // possible to mine X layers of stone tile = X * 3 stones
var
  CanBeReplaced: Boolean;
  I,K, LowestIdx: Integer;
  StoneLocs, CopySL: TKMPointTagList;
  CanMineCnt: TKMWordArray;
begin
  // Exit if we dont need new quarry and there is not completed quarry or quarry is already builded
  if not aForceToPlaceQuarry AND ((fPlannedHouses[HT].Completed = 0) OR (fPlannedHouses[HT].Count > fPlannedHouses[HT].Completed)) then
    Exit;
  StoneLocs := gAIFields.Eye.GetStoneLocs(); // Find stone locs
  CopySL := nil;
  try
    if (StoneLocs.Count > 0) then
    begin
      if (fPlannedHouses[HT].Count > 0) then
      begin
        // Calculate usage of each mine and each stone tile
        SetLength(CanMineCnt, fPlannedHouses[HT].Count);
        FillChar(CanMineCnt[0], SizeOf(CanMineCnt[0]) * Length(CanMineCnt), #0);
        FillChar(StoneLocs.Tag2[0], SizeOf(StoneLocs.Tag2[0]) * Length(StoneLocs.Tag2), #0);
        for I := Low(CanMineCnt) to High(CanMineCnt) do
          with fPlannedHouses[HT].Plans[I] do
            for K := 0 to StoneLocs.Count - 1 do
              if (KMDistanceAbs(Loc,StoneLocs.Items[K]) < MAX_DIST) then
              begin
                Inc(CanMineCnt[I],StoneLocs.Tag[K]);
                Inc(StoneLocs.Tag2[K]);
              end;
        // Find the most depleted house
        LowestIdx := 0;
        for I := High(CanMineCnt) downto Low(CanMineCnt) do
          if (CanMineCnt[LowestIdx] >= CanMineCnt[I])
            AND (fPlannedHouses[HT].Plans[I].House <> nil)
            AND not fPlannedHouses[HT].Plans[I].House.IsDestroyed then
              LowestIdx := I;
        // Try to remove 1 quarry
        if (CanMineCnt[LowestIdx] < MIN_CNT) then
        begin
          // Find again all possible places where quarry can mine and check if every tile can be mined by another 2 mines
          CanBeReplaced := True;
          with fPlannedHouses[HT].Plans[LowestIdx] do
            for I := StoneLocs.Count - 1 downto 0 do
              if (StoneLocs.Tag2[I] < 3) AND (KMDistanceAbs(Loc,StoneLocs.Items[I]) < MAX_DIST) then
              begin
                CanBeReplaced := False;
                break;
              end
              else if (not aForceToPlaceQuarry AND (StoneLocs.Tag2[I] > 1)) OR (StoneLocs.Tag2[I] > 3) then // Allow lower tolerance in case of aForceToPlaceQuarry
                StoneLocs.Delete(I);
          if CanBeReplaced then
          begin
            // Copy stone locs
            CopySL := TKMPointTagList.Create();
            for I := 0 to StoneLocs.Count - 1 do
              CopySL.Add(StoneLocs.Items[I], StoneLocs.Tag[I]);
            // Try to place new quarry
            if (aReqQuarryCnt >= 0) AND FindPlaceForQuary(CopySL) then
              with fPlannedHouses[HT] do
                Plans[ Count-1 ].HouseReservation := True; // Reserve houses so builder will init road
            // Demolish old quarry (in case that alternative is completed)
            if not aForceToPlaceQuarry AND (aReqQuarryCnt < 0) then
              with fPlannedHouses[HT] do
              begin
                if (Plans[LowestIdx].House <> nil) then
                  Plans[LowestIdx].House.DemolishHouse(fOwner);
                RemovePlan(HT, LowestIdx);
              end;
          end
          else if aForceToPlaceQuarry then
            FindPlaceForQuary(StoneLocs);
        end
        else if aForceToPlaceQuarry then
          FindPlaceForQuary(StoneLocs);
      end
      else if aForceToPlaceQuarry then
        FindPlaceForQuary(StoneLocs);
    end;
  finally
    if (StoneLocs <> nil) then
      StoneLocs.Free;
    if (CopySL <> nil) then
      CopySL.Free;
  end;
end;


// Quarry planner (constants in this function are critical and will not be set by CA)
function TKMCityPlanner.FindPlaceForQuary(var StoneLocs: TKMPointTagList): Boolean;
const
  HT = htQuary;
  MAX_DERIVATION = 75;
  MAX_SCAN_DIST = 3;
var
  Output, IsWalkable: Boolean;
  I, Y, MinIdx, MaxIdx: Integer;
  Gain, BestGain: Single;
  Loc, BestLoc: TKMPoint;
  HouseReq: TKMHouseRequirements;
  InitPointsArr: TKMPointArray;
  BuildFF: TKMBuildFF;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}
  Result := False;
  Output := False;
  BuildFF := gAIFields.Eye.BuildFF;
  if (StoneLocs = nil) then
    Exit; // Find stone locs

  with HouseReq do
  begin
    HouseType := HT;
    IgnoreTrees := False;
    IgnoreAvoidBuilding := True;
    MaxCnt := 150; // Placing quarry is CRITICAL, pick up the best if possible
    MaxDist := 11;
  end;
  if (StoneLocs.Count > 0) then
  begin
    BuildFF.UpdateState(); // Mark walkable area in owner's city
    // Consider Ownership in picking stone locs
    with StoneLocs do
      for I := Count - 1 downto 0 do
      begin
        IsWalkable := False;
        for Y := Items[I].Y to Min(Items[I].Y + MAX_SCAN_DIST, gTerrain.MapY - 1) do
        begin
          // Set stone loc to closest walkable point (which is bellow actual point)
          if (BuildFF.VisitIdx = BuildFF.Visited[ Y, Items[I].X ]) then
            Items[I] := KMPoint(Items[I].X,Y)
          else if (BuildFF.VisitIdx = BuildFF.Visited[ Y, Max(Items[I].X-1,1) ]) then
            Items[I] := KMPoint( Max(Items[I].X-1,1), Y)
          else if (BuildFF.VisitIdx = BuildFF.Visited[ Y, Min(Items[I].X+1,gTerrain.MapX-1) ]) then
            Items[I] := KMPoint( Min(Items[I].X+1,gTerrain.MapX-1), Y)
          else
            continue;
          // Update tag
          Tag[I] := Max(0, 10000
                           + gAIFields.Influences.Ownership[fOwner, Items[I].Y, Items[I].X]
                           - gAIFields.Influences.GetOtherOwnerships(fOwner,Items[I].X,Items[I].Y)
                           - BuildFF.Distance[ Items[I] ]) * 10;
          IsWalkable := True;
          break;
        end;
        if not IsWalkable then // Remove stone locs without walkable tiles (under the loc)
          Delete(I);
      end;
    StoneLocs.SortByTag();
    MaxIdx := StoneLocs.Count - 1;
    // Try find place for quarry
    while not Output AND (MaxIdx > 0) do
    begin
      // Try find cluster of stone locs by influence
      for MinIdx := MaxIdx - 1 downto 0 do
        if (StoneLocs.Tag[MinIdx + 1] - StoneLocs.Tag[MinIdx] > MAX_DERIVATION) then
          break;
      // Copy points in stone mountain in specific influence (it can be multiple stone mountains but in same influence area)
      SetLength(InitPointsArr, MaxIdx - MinIdx);
      for I := MaxIdx downto MinIdx + 1 do
        InitPointsArr[MaxIdx - I] := StoneLocs.Items[I];
      MaxIdx := MinIdx;
      // Try to find stone locs -> array will be automatically filtered by walkable areas inside of BuildFF
      BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, True);
      // Evaluate new locs
      BestGain := -10000000;
      for I := 0 to BuildFF.Locs.Count - 1 do
      begin
        Loc := BuildFF.Locs.Items[I];
        Gain := - ObstaclesInHousePlan(HT,Loc) * GA_PLANNER_FindPlaceForQuary_Obstacle
                - BuildFF.Distance[Loc] * GA_PLANNER_FindPlaceForQuary_DistCity * Max(1, GA_PLANNER_FindPlaceForQuary_DistTimer - gGame.GameTick)
                - BuildFF.DistanceInitPoint[Loc] * GA_PLANNER_FindPlaceForQuary_DistStone
                + SnapCrit(HT, Loc) * GA_PLANNER_FindPlaceForQuary_SnapCrit;
        if (Gain > BestGain) then
        begin
          BestGain := Gain;
          BestLoc := Loc;
          Output := True;
        end;
      end;
    end;
    if Output then
    begin
      AddPlan(HT, BestLoc);
      gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(htQuary, BestLoc);
    end;
  end;
  Result := Output;
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchHouse[htQuary] := fTimeSumSearchHouse[htQuary] + Time;
    if (fTimePeakSearchHouse[htQuary] < Time) then
      fTimePeakSearchHouse[htQuary] := Time;
  {$ENDIF}
end;


// Find place for woodcutter
function TKMCityPlanner.FindPlaceForWoodcutter(aCenter: TKMPoint; aChopOnly: Boolean = False): Boolean;
const
  RADIUS = 8;
  COAL_PENALIZATON = 5;
var
  Output: Boolean;
  I,K, CoalTiles: Integer;
  Gain, BestGain: Single;
  Loc, BestLoc: TKMPoint;
  HouseReq: TKMHouseRequirements;
  InitPointsArr: TKMPointArray;
  HMA: THouseMappingArray;
  BuildFF: TKMBuildFF;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}
  Output := False;
  BuildFF := gAIFields.Eye.BuildFF;
  HMA := gAIFields.Eye.HousesMapping;
  with HouseReq do
  begin
    HouseType := htWoodcutters;
    IgnoreTrees := False;
    IgnoreAvoidBuilding := not aChopOnly;
    MaxCnt := 20;
    MaxDist := RADIUS;
  end;

  SetLength(InitPointsArr, 1);
  InitPointsArr[0] := aCenter;
  BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, True);

  BestGain := -1E10;
  BestLoc := KMPOINT_ZERO;
  for I := 0 to BuildFF.Locs.Count - 1 do
  begin
    Loc := BuildFF.Locs.Items[I];
    Gain := - GA_PLANNER_PlaceWoodcutter_DistFromForest * BuildFF.DistanceInitPoint[Loc]
            + DistCrit(htWoodcutters, Loc)
            + SnapCrit(htWoodcutters, Loc);
    if (Gain > BestGain) then // No need to check for coal tiles everything
    begin
      CoalTiles := 0;
      for K := Low(HMA[htWoodcutters].Tiles) to High(HMA[htWoodcutters].Tiles) do
        CoalTiles := CoalTiles + gTerrain.TileIsCoal(Loc.X + HMA[htWoodcutters].Tiles[K].X, Loc.Y + HMA[htWoodcutters].Tiles[K].Y);
      Gain := Gain - CoalTiles * COAL_PENALIZATON;
      if (Gain > BestGain) then
      begin
        BestGain := Gain;
        BestLoc := Loc;
      end;
    end;
  end;

  if (BestGain <> -1E10) then
  begin
    Output := True;
    // Check whether is cutting point (center of forest) inside of house plan and in this case set it 1 point on left from house entrance
    if ((aCenter.Y <= BestLoc.Y) AND (aCenter.Y >= BestLoc.Y-1)) AND ((aCenter.X <= BestLoc.X) AND (aCenter.X >= BestLoc.X-2)) then
      aCenter := KMPoint(BestLoc.X-1, BestLoc.Y+1);
    AddPlan(htWoodcutters, BestLoc, aCenter, aChopOnly);
    gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(htWoodcutters, BestLoc);
  end;
  Result := Output;
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchHouse[htWoodcutters] := fTimeSumSearchHouse[htWoodcutters] + Time;
    if (fTimePeakSearchHouse[htWoodcutters] < Time) then
      fTimePeakSearchHouse[htWoodcutters] := Time;
  {$ENDIF}
end;


function TKMCityPlanner.FindForestAndWoodcutter(): Boolean;
var
  FI: TKMForestsInfo;

  function GetFreeTiles(aLoc: TKMPoint): Integer;
  const
    RADIUS = 4;
  var
    X,Y: Integer;
    State: TKMBuildState;
  begin
    Result := 0;
    for Y := Max(1,aLoc.Y-RADIUS) to Min(gTerrain.MapY-1, aLoc.Y+RADIUS) do
    for X := Max(1,aLoc.X-RADIUS) to Min(gTerrain.MapX-1, aLoc.X+RADIUS) do
    begin
      State := gAIFields.Eye.BuildFF.State[Y,X];
      Result := Result + Byte( (State >= bsBuild) AND (State <= bsForest) );
    end;
  end;

  {$IFDEF DEBUG_NewAI}
  procedure LogForest(aIdx: Integer; aTreeCnt,aExistFrs,aRoutes,aFlatArea,aSoil,aDistCrit,aFreeTiles,aAllyInf,aEnemyInfl: Single);
  var
    Coef: Single;
  begin
     if (aIdx = FI.Count-1) then
        fForestDebugText := Format('Forest - Time: %d; Peak: %d'
          + '|Perc'
          + #9 + '[X,Y]'
          + #9#9 + 'TreeCnt'
          + #9 + 'ExistFor'
          + #9 + 'Routes'
          + #9#9 + 'FltAr'
          + #9#9 + 'Soil'
          + #9#9 + 'Distance'
          + #9#9 + 'FreeTiles'
          + #9#9 + 'AllInf'
          + #9#9 + 'EnmInfl',[fTimeSumSearchForest, fTimePeakSearchForest]);
    Coef := Max(0.0000001, 100 / Max(0.0001,(FI.Forests[FI.Count-1].Bid)));
    fForestDebugText := fForestDebugText + Format(
      '|%3.1f' + #9 + '[%d,%d]' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f',
      [ FI.Forests[aIdx].Bid * Coef, FI.Forests[aIdx].Loc.X, FI.Forests[aIdx].Loc.Y,
        Coef * aTreeCnt,
        Coef * aExistFrs,
        Coef * aRoutes,
        Coef * aFlatArea,
        Coef * aSoil,
        Coef * aDistCrit,
        Coef * aFreeTiles,
        Coef * aAllyInf,
        Coef * aEnemyInfl
      ]);
  end;
  {$ENDIF}

  procedure EvalForest(aIdx: Integer; aLogResult: Boolean);
  var
    TreeCnt,ExistFrs,Routes,FlatArea,Soil,DistCrit,FreeTiles,AllyInf,EnemyInfl: Single;
    P: TKMPoint;
  begin
    P := FI.Forests[aIdx].Loc;
    TreeCnt   := + FI.Forests[aIdx].TreeCout           * GA_PLANNER_FindPlaceForWoodcutter_TreeCnt * Max(1, GA_PLANNER_FindPlaceForWoodcutter_TreeCntTimer - gGame.GameTick);
    DistCrit  := - FI.Forests[aIdx].Distance           * GA_PLANNER_FindPlaceForWoodcutter_DistCrit * Max(1, GA_PLANNER_FindPlaceForWoodcutter_DistTimer - gGame.GameTick);
    ExistFrs  := + Byte(FI.Forests[aIdx].PartOfForest) * GA_PLANNER_FindPlaceForWoodcutter_ExistForest;
    Routes    := + gAIFields.Eye.Routes[P.Y, P.X]      * GA_PLANNER_FindPlaceForWoodcutter_Routes;
    FlatArea  := + gAIFields.Eye.FlatArea[P.Y, P.X]    * GA_PLANNER_FindPlaceForWoodcutter_FlatArea;
    Soil      := + gAIFields.Eye.Soil[P.Y, P.X]        * GA_PLANNER_FindPlaceForWoodcutter_Soil;
    FreeTiles := + GetFreeTiles(P)                     * GA_PLANNER_FindPlaceForWoodcutter_FreeTiles;
    AllyInf   := - gAIFields.Influences.GetBestAllianceOwnership(fOwner, P.X, P.Y, atAlly)  * GA_PLANNER_FindForestAndWoodcutter_AllyInfluence;
    EnemyInfl := - gAIFields.Influences.GetBestAllianceOwnership(fOwner, P.X, P.Y, atEnemy) * GA_PLANNER_FindForestAndWoodcutter_EnemyInfluence;
    FI.Forests[aIdx].Bid := TreeCnt + DistCrit + ExistFrs + Routes + FlatArea + Soil + FreeTiles + AllyInf + EnemyInfl;
    {$IFDEF DEBUG_NewAI}
    if aLogResult then
      LogForest(aIdx, TreeCnt, ExistFrs, Routes, FlatArea, Soil, DistCrit, FreeTiles, AllyInf, EnemyInfl);
    {$ENDIF}
  end;

const
  SQR_MIN_DIST_FROM_CHOP_ONLY = 12*12;
var
  Output: Boolean;
  K,L: Integer;
  DecreaseSpeed: Single;
  P: TKMPoint;
  FIRnd: TKMForestsInfo;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}

  FI := gAIFields.Eye.GetForests();
  //{
  FIRnd := gAIFields.Eye.GetPotentialForests(500);
  if (FI.Count + FIRnd.Count > Length(FI.Forests)) then
    SetLength(FI.Forests,FI.Count + FIRnd.Count);

  for K := 0 to FIRnd.Count - 1 do
  begin
    FI.Forests[ FI.Count ] := FIRnd.Forests[K];
    Inc(FI.Count);
  end;
  //}

  for K := FI.Count - 1 downto 0 do
  begin
    // Check influence
    if (gAIFields.Influences.GetBestAllianceOwner(fOwner, FI.Forests[K].Loc, atEnemy) > 10)
      OR (gAIFields.Influences.GetBestOwner(FI.Forests[K].Loc.X, FI.Forests[K].Loc.Y) <> fOwner) then
    begin
      FI.Forests[K] := FI.Forests[ FI.Count-1 ];
      Dec(FI.Count);
      continue;
    end;
    // Delete forests around chop-only woodcutters
    for L := 0 to fPlannedHouses[htWoodcutters].Count - 1 do
      with fPlannedHouses[htWoodcutters].Plans[L] do
        if ChopOnly AND (KMDistanceSqr(FI.Forests[K].Loc, SpecPoint) < SQR_MIN_DIST_FROM_CHOP_ONLY) then
        begin
          FI.Forests[K] := FI.Forests[ FI.Count-1 ];
          Dec(FI.Count);
          continue;
        end;
  end;

  // Evaluate clusters of trees (tree cnt + relative position [influence])
  for K := 0 to FI.Count - 1 do
    EvalForest(K, False);
  if (FI.Count > 1) then
    Sort(FI.Forests[0], 0, FI.Count-1, sizeof(FI.Forests[0]), CompareForests);

  {$IFDEF DEBUG_NewAI}
    for K := FI.Count - 1 downto Max(0,FI.Count - 5) do
      EvalForest(K, True);
  {$ENDIF}

  K := FI.Count;
  Output := False;
  while not Output AND (K > 0) do
  begin
    K := K - 1;
    P := FI.Forests[K].Loc; // Get the best forest
    Output := FindPlaceForWoodcutter(P,False);
    // Mark forest by protected radius
    if Output then
    begin
      // Rounding of paramters from GA may change border limit for forest +- 1 so substract it
      DecreaseSpeed := Min(GA_PLANNER_FindPlaceForWoodcutter_ABRange,AVOID_BUILDING_FOREST_RANGE-1) / sqr(GA_PLANNER_FindPlaceForWoodcutter_Radius);
      gAIFields.Influences.MarkForest(P, GA_PLANNER_FindPlaceForWoodcutter_Radius, DecreaseSpeed);
    end;
  end;
  Result := Output;
  fForestsInfo := FI;

  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchForest := fTimeSumSearchForest + Time;
    if (fTimePeakSearchForest < Time) then
      fTimePeakSearchForest := Time;
  {$ENDIF}
end;


// This function have 2 purposes: detect forest in case of wood shortage and find forest for chop-only mode
function TKMCityPlanner.FindForestAround(const aPoint: TKMPoint; aCountByInfluence: Boolean = False): Boolean;
const
  MIN_TREES = 3;
  //SQR_MAX_DIST_FROM_HOUSE = 7*7;
  SQR_MIN_DIST_FROM_ACTIVE_FORESTS = 10*10;
  SQR_MIN_DIST_FROM_CHOP_ONLY = 12*12;
var
  Output, Check: Boolean;
  K,L: Integer;
  Gain, BestGain: Byte;
  Loc, BestLoc: TKMPoint;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}
  Output := False;
  if (fForestsInfo.Count > 0) then
  begin
    BestGain := 0;
    BestLoc := KMPOINT_ZERO;
    for K := fForestsInfo.Count-1 downto 0 do
    begin
      Loc := fForestsInfo.Forests[K].Loc;
      if (aCountByInfluence OR (KMDistanceSqr(aPoint, Loc) < GA_PLANNER_FindForestAround_MaxDist * GA_PLANNER_FindForestAround_MaxDist))
        AND (fForestsInfo.Forests[K].TreeCout >= MIN_TREES)
        AND (gAIFields.Influences.GetBestAllianceOwnership(fOwner, Loc.X, Loc.Y, atEnemy) < 20) then
      begin
        Gain := gAIFields.Influences.Ownership[ fOwner, Loc.Y, Loc.X ]; // This is equivalent of distance
        if (Gain > BestGain) then
        begin
          Check := True;
          for L := 0 to fPlannedHouses[htWoodcutters].Count - 1 do
            if (KMDistanceSqr(Loc, fPlannedHouses[htWoodcutters].Plans[L].SpecPoint) < SQR_MIN_DIST_FROM_ACTIVE_FORESTS) then
            begin
              Check := False;
              break;
            end;
          if Check then
          begin
            BestGain := Gain;
            BestLoc := Loc;
            Output := True;
          end;
        end;
      end;
    end;
    if Output then
    begin
      Output := FindPlaceForWoodcutter(BestLoc, True);
      // fForests is not updated so remove points around new chop only forest
      if Output then
        with fForestsInfo do
          for K := Count-1 downto 0 do
            if (KMDistanceSqr(Forests[K].Loc, BestLoc) < SQR_MIN_DIST_FROM_CHOP_ONLY) then
            begin
              Forests[K] := Forests[ fForestsInfo.Count-1 ];
              Dec(Count);
            end;
    end;
  end;

  Result := Output;
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchForest := fTimeSumSearchForest + Time;
    if (fTimePeakSearchForest < Time) then
      fTimePeakSearchForest := Time;
  {$ENDIF}
end;


function TKMCityPlanner.PlanDefenceTowers(): Boolean;

  procedure FindPlaceForTowers(aCenter: TKMPoint);
  const
    RADIUS = 3;
    MAX_BID = 100000;
    MAX_ENEMY_INFLUENCE = 100;
  var
    PL: TKMHandID;
    X,Y: Integer;
    Bid, BestBid: Single;
    Loc, BestLoc: TKMPoint;
  begin
    // Filter defence positions, build towers only at the closest
    PL := gAIFields.Influences.GetBestAllianceOwner(fOwner, aCenter, atAlly);
    if (PL <> fOwner) AND (PL <> PLAYER_NONE) then
      Exit;
    if (gAIFields.Influences.GetBestAllianceOwnership(fOwner, gAIFields.NavMesh.Point2Polygon[aCenter.Y,aCenter.X], atEnemy) > MAX_ENEMY_INFLUENCE) then
      Exit;

    BestBid := MAX_BID;
    BestLoc := KMPOINT_ZERO;
    for Y := Max(1, aCenter.Y - RADIUS) to Min(gTerrain.MapY, aCenter.Y + RADIUS) do
    for X := Max(1, aCenter.X - RADIUS) to Min(gTerrain.MapX, aCenter.X + RADIUS) do
    begin
      Loc := KMPoint(X,Y);
      if gAIFields.Eye.CanAddHousePlan(Loc, htWatchTower, True, False, False) then
      begin
        Bid := KMDistanceAbs(aCenter, Loc);
        if (Bid < BestBid) then
        begin
          BestBid := Bid;
          BestLoc := Loc;
        end;
      end;
    end;
    if (BestBid <> MAX_BID) then
    begin
      AddPlan(htWatchTower, BestLoc);
      gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(htWatchTower, BestLoc);
    end;
  end;

const
  DISTANCE_BETWEEN_TOWERS = 8;
var
  I, K, DefCount: Integer;
  P1,P2: TKMPoint;
  Ratio: Single;
  DefLines: TKMDefenceLines;
  BuildFF: TKMBuildFF;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet();
  {$ENDIF}
  Result := False;

  if not gHands[fOwner].Locks.HouseCanBuild(htWatchTower)
    OR not gAIFields.NavMesh.Defences.FindDefenceLines(fOwner, DefLines)
    OR (DefLines.Count < 1) then
    Exit;

  // Mark walkable area in owner's city
  BuildFF := gAIFields.Eye.BuildFF;
  BuildFF.UpdateState(60);

  //Make list of defence positions
  for I := 0 to DefLines.Count-1 do
  begin
    P1 := gAIFields.NavMesh.Nodes[ DefLines.Lines[I].Nodes[0] ];
    P2 := gAIFields.NavMesh.Nodes[ DefLines.Lines[I].Nodes[1] ];
    // Check if defensive position is visible by eye (sometimes edges are not passable so eye does not see them)
    if not (BuildFF.VisitIdx = BuildFF.Visited[ round(abs(P1.Y+P2.Y)/2), round(abs(P1.X+P2.X)/2) ])
      AND not (BuildFF.VisitIdx = BuildFF.Visited[ P1.Y, P1.X ])
      AND not (BuildFF.VisitIdx = BuildFF.Visited[ P2.Y, P2.X ]) then
      continue;
    DefCount := Ceil( KMLength(P1,P2) / DISTANCE_BETWEEN_TOWERS );
    for K := 0 to DefCount - 1 do
    begin
      Ratio := (K + 1) / (DefCount + 1);
      FindPlaceForTowers( KMPointRound(KMLerp(P1, P2, Ratio)) );
    end;
  end;
  Result := True;
  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeSumSearchHouse[htWatchTower] := fTimeSumSearchHouse[htWatchTower] + Time;
  {$ENDIF}
end;


procedure TKMCityPlanner.LogStatus(var aBalanceText: UnicodeString);
begin
  {$IFDEF DEBUG_NewAI}
    aBalanceText := Format('%s||CityPlanner: |%s|%s|%s',[aBalanceText,fPlaceHouseDebugText,fPlaceFarmDebugText,fForestDebugText]);
  {$ENDIF}
end;


procedure TKMCityPlanner.Paint();
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $0000FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
var
  K,L: Integer;
  Division: Single;
  H: TKMHouse;
  HT: TKMHouseType;
  Loc: TKMPoint;
  Color: Cardinal;
  HMA: THouseMappingArray;
  {$IFDEF DEBUG_NewAI}
  X,Y: Integer;
  Val: Cardinal;
  {$ENDIF}
begin

  {$IFDEF DEBUG_NewAI}
    //fPrice[aToY,aTox] := Result;
    with fRoadPlanner do
      for Y := Low(Price) to High(Price) do
      for X := Low(Price[Y]) to High(Price[Y]) do
      begin
        //Val := GA_PATHFINDING_BasePrice + Max(Max(GA_PATHFINDING_noBuildArea,GA_PATHFINDING_Field),Max(Max(GA_PATHFINDING_Coal,GA_PATHFINDING_Forest),GA_PATHFINDING_OtherCase));
        //Val := Cardinal(Max(0, Min(250, Round(Price[Y,X]/Single(Val)*250))));
        //gRenderAux.Quad(X, Y, (Val shl 24) OR COLOR_RED);
        //gRenderAux.Text(X, Y, IntToStr(Order[Y,X]), $FF000000);
      end;
    //fRoadPlanner: TPathFindingCityPlanner;
    //fRoadShortcutPlanner:
  {$ENDIF}

  {$IFDEF DEBUG_NewAI}
  Division := 1;
  for Y := Low(DA1) to High(DA1) do
  for X := Low(DA1[0]) to High(DA1[0]) do
    if (Division < DA1[Y,X]) then
      Division := DA1[Y,X];
  for Y := Low(DA1) to High(DA1) do
  for X := Low(DA1[0]) to High(DA1[0]) do
    if gTerrain.TileInMapCoords(X,Y) then
    begin
      Val := Cardinal(Max(0, Min(250, Round(DA1[Y,X]/Division*250))));
      gRenderAux.Quad(X, Y, (Val shl 24) OR COLOR_YELLOW);
      //gRenderAux.Text(X, Y, IntToStr(Round(DA1[Y,X])), $FF000000);
      //gRenderAux.Quad(X, Y, (Cardinal(Max(0, Min(127, DA2[Y,X]))) shl 24) OR COLOR_WHITE);
      //gRenderAux.Quad(X, Y, (Cardinal(Max(0, Min(127, DA3[Y,X]))) shl 24) OR COLOR_BLUE);
      //gRenderAux.Quad(X, Y, (Cardinal(Max(0, Min(127, DA4[Y,X]))) shl 24) OR COLOR_BLACK);
    end;
  {$ENDIF}

  HMA := gAIFields.Eye.HousesMapping;

  {$IFDEF DEBUG_NewAI}
  // Paint best places for last house
  for K := 0 to Length(fBestHouseLocs) - 1 do
    gRenderAux.Quad(fBestHouseLocs[K].X, fBestHouseLocs[K].Y, (fBestHouseVal[K] shl 24) OR COLOR_BLACK);
  {$ENDIF}

  // Paint houses
  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    case HT of
      htStore,htSchool,htInn,htMarketplace: Color := COLOR_BLACK;
      htQuary,htWoodcutters,htSawmill: Color := COLOR_BLUE;
      htGoldMine,htCoalMine,htIronMine,htMetallurgists: Color := COLOR_YELLOW;
      htIronSmithy,htArmorSmithy,htWeaponSmithy,htTannery,htArmorWorkshop,htWeaponWorkshop,htBarracks: Color := COLOR_RED;
      htBakery,htButchers,htMill,htSwine,htStables,htFarm,htWineyard: Color := COLOR_GREEN;
      else Color := COLOR_WHITE;
    end;
    Color := $80000000 OR Color;
    for K := 0 to fPlannedHouses[HT].Count - 1 do
    begin
      for L := 0 to Length(HMA[HT].Tiles) - 1 do
      begin
        Loc := KMPointAdd(fPlannedHouses[HT].Plans[K].Loc, HMA[HT].Tiles[L]);
        gRenderAux.Quad(Loc.X, Loc.Y, Color);
      end;
    end;
  end;

  // Paint potential forests
  if (fForestsInfo.Count > 0) then
  begin
    // Forests are sorted
    Division := 255 / (fForestsInfo.Forests[fForestsInfo.Count - 1].Bid - fForestsInfo.Forests[0].Bid);
    for K := 0 to fForestsInfo.Count - 1 do
    begin
      Loc := fForestsInfo.Forests[K].Loc;
      Color := (Min(255,Max(50,Round((fForestsInfo.Forests[K].Bid - fForestsInfo.Forests[0].Bid) * Division))) shl 24) OR $000000FF;
      gRenderAux.Quad(Loc.X, Loc.Y, Color);
    end;
  end;

  // Paint field of specific farm
  if (gMySpectator.Selected is TKMHouse) then
  begin
    H := TKMHouse(gMySpectator.Selected);
    if (H.HouseType in [htFarm, htWineyard]) then
      for K := 0 to fFields.Count - 1 do
        if KMSamePoint(H.Entrance,fFields.Farms[K].Center) then
          with fFields.Farms[K] do
            for L := Low(Points) to High(Points) do
              if not KMSamePoint(Points[L],KMPOINT_ZERO) then
                gRenderAux.Quad(Points[L].X, Points[L].Y, $AA000000 OR COLOR_RED);
  end;

  {
  for K := 0 to fFields.Count - 1 do
    with fFields.Farms[K] do
      if FieldAvailable then
        for L := Low(Points) to Min(High(Points), Byte(FieldType=ftWine)*8 + Byte(FieldType=ftCorn)*High(Points)) do
          for X := Low(Points) to Min(High(Points), Byte(FieldType=ftWine)*8 + Byte(FieldType=ftCorn)*High(Points)) do
            if (L<>X) AND KMSamePoint(Points[L],Points[X]) then
            begin
              gRenderAux.Quad(Points[L].X, Points[L].Y, $FF000000 OR COLOR_RED);
            end;
  //}
end;







{ TPathFindingCityPlanner }
{$IFDEF DEBUG_NewAI}
function TPathFindingCityPlanner.Route_Make(const aLocA, aLocB: TKMPoint; NodeList: TKMPointList): Boolean;
begin
  //FillChar(Price,SizeOf(Price),#0);
  //FillChar(Order,SizeOf(Order),#0);
  Result := inherited Route_Make(aLocA, aLocB, NodeList);
end;
{$ENDIF}


function TPathFindingCityPlanner.IsWalkableTile(aX, aY: Word): Boolean;
begin
  // Just in case that worker will die while digging house plan or when you plan road near ally
  Result := ( ([tpMakeRoads, tpWalkRoad] * gTerrain.Land[aY,aX].Passability <> []) OR (gTerrain.Land[aY, aX].TileLock in [tlRoadWork, tlFieldWork]) ) // Existing road / road construction
             //AND (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(aX, aY)) in [ftNone, ftRoad]) // AI can handle plans
             //AND not gHands[fOwner].BuildList.HousePlanList.HasPlan(KMPoint(aX, aY)) // Use avoid building instead so plans are also considered
             AND (gAIFields.Influences.AvoidBuilding[aY, aX] <> AVOID_BUILDING_HOUSE_INSIDE_LOCK);
end;


function TPathFindingCityPlanner.MovementCost(aFromX, aFromY, aToX, aToY: Word): Word;
var
  IsRoad: Boolean;
  AvoidBuilding: Byte;
  Node: TANode;
begin
  Result := GA_PATHFINDING_BasePrice;

  Node := GetNodeAt(aFromX, aFromY);
  if (Node <> nil) AND (Node.Parent <> nil) AND (Node.Parent.X <> aToX) AND (Node.Parent.Y <> aToY) then
    Inc(Result, GA_PATHFINDING_TurnPenalization);

  AvoidBuilding := gAIFields.Influences.AvoidBuilding[aToY, aToX];
  IsRoad := (AvoidBuilding = AVOID_BUILDING_NODE_LOCK_ROAD)                                     // Reserved road plan
            OR (tpWalkRoad in gTerrain.Land[aToY, aToX].Passability)                            // Completed road
            OR (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(aToX, aToY)) = ftRoad) // Placed road plan
            OR (gTerrain.Land[aToY, aToX].TileLock = tlRoadWork);                               // Road under construction

  // Improve cost if tile is or will be road
  if IsRoad                                                     then Dec(Result, GA_PATHFINDING_Road)
  // 1 tile from future house
  else if (AvoidBuilding = AVOID_BUILDING_HOUSE_OUTSIDE_LOCK)   then Inc(Result, GA_PATHFINDING_noBuildArea)
  // 1 tile form mine
  else if (AvoidBuilding = AVOID_BUILDING_MINE_TILE)            then Inc(Result, GA_PATHFINDING_noBuildArea)
  // Corn / wine field
  else if (AvoidBuilding = AVOID_BUILDING_NODE_LOCK_FIELD)      then Inc(Result, GA_PATHFINDING_Field)
  // Coal field
  else if (AvoidBuilding = AVOID_BUILDING_COAL_TILE)            then Inc(Result, GA_PATHFINDING_Coal)
  // Forest or blocking tile before house entrance
  else if (AvoidBuilding > AVOID_BUILDING_FOREST_MINIMUM)       then Inc(Result, GA_PATHFINDING_Forest)
  // Snap to no-build areas (1 tile from house)
  else if not (tpBuild in gTerrain.Land[aToY,aToX].Passability) then Inc(Result, GA_PATHFINDING_noBuildArea)
  // Other case
  else                                                               Inc(Result, GA_PATHFINDING_OtherCase);
  {$IFDEF DEBUG_NewAI}
    Price[aToY,aTox] := Result;
    if (Ctr >= High(Word)) then
      Ctr := 0;
    Inc(Ctr);
    Order[aToY,aTox] := Ctr;
  {$ENDIF}
end;


{ TPathFindingShortcutsCityPlanner }
function TPathFindingShortcutsCityPlanner.MovementCost(aFromX, aFromY, aToX, aToY: Word): Word;
var
  IsRoad: Boolean;
  AvoidBuilding: Byte;
  Node: TANode;
begin
  Result := GA_SHORTCUTS_BasePrice;

  Node := GetNodeAt(aFromX, aFromY);
  if (Node <> nil) AND (Node.Parent <> nil) AND (Node.Parent.X <> aToX) AND (Node.Parent.Y <> aToY) then
    Inc(Result, GA_SHORTCUTS_TurnPenalization);

  AvoidBuilding := gAIFields.Influences.AvoidBuilding[aToY, aToX];
  IsRoad := (AvoidBuilding = AVOID_BUILDING_NODE_LOCK_ROAD)                                     // Reserved road plan
            OR (tpWalkRoad in gTerrain.Land[aToY, aToX].Passability)                            // Completed road
            OR (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(aToX, aToY)) = ftRoad) // Placed road plan
            OR (gTerrain.Land[aToY, aToX].TileLock = tlRoadWork);                               // Road under construction

  // Improve cost if tile is or will be road
  if IsRoad                                                     then Dec(Result, GA_SHORTCUTS_Road)
  // 1 tile from future house
  else if (AvoidBuilding = AVOID_BUILDING_HOUSE_OUTSIDE_LOCK)   then Inc(Result, GA_SHORTCUTS_noBuildArea)
  // 1 tile form mine
  else if (AvoidBuilding = AVOID_BUILDING_MINE_TILE)            then Inc(Result, GA_SHORTCUTS_noBuildArea)
  // Corn / wine field
  else if (AvoidBuilding = AVOID_BUILDING_NODE_LOCK_FIELD)      then Inc(Result, GA_SHORTCUTS_Field)
  // Coal field
  else if (AvoidBuilding = AVOID_BUILDING_COAL_TILE)            then Inc(Result, GA_SHORTCUTS_Coal)
  // Forest or blocking tile before house entrance
  else if (AvoidBuilding > AVOID_BUILDING_FOREST_MINIMUM)       then Inc(Result, GA_SHORTCUTS_Forest)
  // Snap to no-build areas (1 tile from house or special tiles)
  else if not (tpBuild in gTerrain.Land[aToY,aToX].Passability) then Inc(Result, GA_SHORTCUTS_noBuildArea)
  // Other case
  else                                                               Inc(Result, GA_SHORTCUTS_OtherCase);
  {$IFDEF DEBUG_NewAI}
    Price[aToY,aTox] := Result;
    if (Ctr >= High(Word)) then
      Ctr := 0;
    Inc(Ctr);
    Order[aToY,aTox] := Ctr;
  {$ENDIF}
end;


function TPathFindingShortcutsCityPlanner.DestinationReached(aX, aY: Word): Boolean;
begin
  Result := ((aX = fLocB.X) and (aY = fLocB.Y)); //We reached destination point
end;




{ TKMFieldEvaluation }
constructor TKMFieldEvaluation.Create(aMapX, aMapY: Word; aOwner: TKMHandID);
begin
  fMapX := aMapX;
  fMapY := aMapY;
  fOwner := aOwner;
  fQueue := TQueue.Create();
end;


destructor TKMFieldEvaluation.Destroy();
begin
  fQueue.Free();
  inherited;
end;


function TKMFieldEvaluation.CanBeVisited(const aX,aY, aDistance: Word): Boolean;
var
  K,L: Integer;
begin
  K := aX - fInitPoint.X;
  L := aY - fInitPoint.Y;
  Result := (K >= - FARM_RADIUS) AND (L >= - FARM_RADIUS) AND (K <= + FARM_RADIUS) AND (L <= + FARM_RADIUS) AND (FieldPrice[L,K] = 0)
            AND gTerrain.TileInMapCoords(aX, aY) AND (tpWalk in gTerrain.Land[aY,aX].Passability) AND (gAIFields.Influences.AvoidBuilding[aY, aX] <> AVOID_BUILDING_HOUSE_INSIDE_LOCK);
end;


procedure TKMFieldEvaluation.MarkAsVisited(const aX,aY, aDistance: Word);
var
  K,L: Integer;
  P: TKMPoint;
begin
  K := aX - fInitPoint.X;
  L := aY - fInitPoint.Y;

  FieldPrice[L,K] := aDistance;
  P := KMPoint(aX,aY);
  case gAIFields.Influences.AvoidBuilding[aY, aX] of
    AVOID_BUILDING_UNLOCK, AVOID_BUILDING_HOUSE_OUTSIDE_LOCK:
    begin
      if gTerrain.TileIsCornField(P) then
        FieldEval[L,K] := feExistingField
      else if gHands[fOwner].CanAddFieldPlan(P, fFieldType) then
        FieldEval[L,K] := feFertileTile
      else
        FieldEval[L,K] := feObstacle;
    end;
    AVOID_BUILDING_NODE_LOCK_FIELD:
      FieldEval[L,K] := feExistingField;
    else begin end;
  end;
end;


procedure TKMFieldEvaluation.InsertInQueue(const aX,aY, aDistance: Word);
var
  DE: PDistElement;
begin
  MarkAsVisited(aX,aY,aDistance);
  New(DE);
  DE^.X := aX;
  DE^.Y := aY;
  DE^.Distance := aDistance;
  fQueue.Push(DE);
end;


function TKMFieldEvaluation.RemoveFromQueue(var aX,aY, aDistance: Word): Boolean;
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


procedure TKMFieldEvaluation.EvalField(aMaxDist: Word; aInitPoint: TKMPoint; aFieldType: TKMFieldType);
var
  X,Y,Distance: Word;
begin
  FillChar(FieldEval, SizeOf(FieldEval), #0);
  FillChar(FieldPrice, SizeOf(FieldPrice), #0);

  fInitPoint := aInitPoint;
  fFieldType := aFieldType;
  if CanBeVisited(aInitPoint.X, aInitPoint.Y, 1) then
    InsertInQueue(aInitPoint.X, aInitPoint.Y, 1);

  while RemoveFromQueue(X,Y,Distance) do
    if (Distance < aMaxDist) then
    begin
      Distance := Distance + 1;
      if (X > 0)       AND CanBeVisited(X-1,Y,Distance) then InsertInQueue(X-1,Y,Distance);
      if (X < fMapX-1) AND CanBeVisited(X+1,Y,Distance) then InsertInQueue(X+1,Y,Distance);
      if (Y > 0)       AND CanBeVisited(X,Y-1,Distance) then InsertInQueue(X,Y-1,Distance);
      if (Y < fMapY-1) AND CanBeVisited(X,Y+1,Distance) then InsertInQueue(X,Y+1,Distance);
    end;
end;


procedure TKMFieldEvaluation.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
end;



{ JUNK:


{
GA_PLANNER_DistCrit_CenterStore                   : Single = 3.870659351;
GA_PLANNER_DistCrit_Store                         : Single = 0.1000000015;
GA_PLANNER_DistCrit_School                        : Single = 39.48722076;
GA_PLANNER_DistCrit_Inn_Store                     : Single = 50;
GA_PLANNER_DistCrit_Inn_Inn                       : Single = 32.82717896;
GA_PLANNER_DistCrit_Marketplace                   : Single = 35.4796524;
GA_PLANNER_DistCrit_IronSmithy_Self               : Single = 3.963907719;
GA_PLANNER_DistCrit_IronSmithy_Res                : Single = 28.90864563;
GA_PLANNER_DistCrit_ArmorSmithy_Set               : Single = 1.426353335;
GA_PLANNER_DistCrit_ArmorSmithy_Res               : Single = 7.746329784;
GA_PLANNER_DistCrit_WeaponSmithy_Set              : Single = 4.051534653;
GA_PLANNER_DistCrit_WeaponSmithy_Res              : Single = 11.29830551;
GA_PLANNER_DistCrit_Tannery_Set                   : Single = 49.24342728;
GA_PLANNER_DistCrit_ArmorWorkshop_Set             : Single = 4.114400864;
GA_PLANNER_DistCrit_WeaponWorkshop_Set            : Single = 4.108706474;
GA_PLANNER_DistCrit_Barracks_Set                  : Single = 13.32427883;
GA_PLANNER_DistCrit_Bakery_Set                    : Single = 0.1000000015;
GA_PLANNER_DistCrit_Bakery_Res                    : Single = 47.20677948;
GA_PLANNER_DistCrit_Butchers_Set                  : Single = 50;
GA_PLANNER_DistCrit_Butchers_Res                  : Single = 31.10999107;
GA_PLANNER_DistCrit_Mill_Set                      : Single = 18.05562401;
GA_PLANNER_DistCrit_Mill_Res                      : Single = 50;
GA_PLANNER_DistCrit_Swine_Set                     : Single = 22.83971596;
GA_PLANNER_DistCrit_Swine_Res                     : Single = 11.5138216;
GA_PLANNER_DistCrit_Stables_Set                   : Single = 30.27074623;
GA_PLANNER_DistCrit_Stables_Res                   : Single = 31.47228622;
GA_PLANNER_DistCrit_Farm_Set                      : Single = 24.62744522;
GA_PLANNER_DistCrit_Farm_Res                      : Single = 33.97316742;
GA_PLANNER_DistCrit_Wineyard_Set                  : Single = 45.15957642;
GA_PLANNER_DistCrit_Wineyard_Res                  : Single = 50;
GA_PLANNER_DistCrit_Metallurgists_Set             : Single = 50;
GA_PLANNER_DistCrit_Metallurgists_Res             : Single = 7.292239189;
GA_PLANNER_DistCrit_GoldMine_Set                  : Single = 35.09430313;
GA_PLANNER_DistCrit_CoalMine_Set                  : Single = 29.58112717;
GA_PLANNER_DistCrit_IronMine_Set                  : Single = 29.57572556;
GA_PLANNER_DistCrit_Quary_Set                     : Single = 17.80814362;
GA_PLANNER_DistCrit_Woodcutters_Set               : Single = 38.6776886;
GA_PLANNER_DistCrit_Sawmill_Set                   : Single = 10.2895546;
//}

{
function TKMCityPlanner.DistCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
const
  MAX_BID = 1000000;

  function DistFromHouses(aHTs: array of TKMHouseType): Single;
  var
    I,K: Integer;
    Output: Single;
  begin
    Output := 0;
    for I := Low(aHTs) to High(aHTs) do
    for K := 0 to Min(2, fPlannedHouses[ aHTs[I] ].Count - 1) do
      Output := Output + KMDistanceAbs(aLoc, fPlannedHouses[ aHTs[I] ].Plans[K].Loc);
    Result := Output;
  end;

  function DistFromHouse(aHTs: array of TKMHouseType): Single;
  var
    I,K: Integer;
    Output, Bid: Single;
  begin
    Output := MAX_BID;
    for I := Low(aHTs) to High(aHTs) do
    for K := 0 to Min(2, fPlannedHouses[ aHTs[I] ].Count - 1) do
    begin
      Bid := KMDistanceAbs(aLoc, fPlannedHouses[ aHTs[I] ].Plans[K].Loc);
      if (Bid < Output) then
        Output := Bid;
    end;
    if (Output = MAX_BID) then
      Output := 0;
    Result := Output;
  end;

var
  Output: Single;
begin
  case aHT of
    htStore:          Output := + GA_PLANNER_DistCrit_Store * DistFromHouse([htStore]);
    htSchool:         Output := - GA_PLANNER_DistCrit_School * DistFromHouse([htStore,htMetallurgists]);
    htInn:            Output := - GA_PLANNER_DistCrit_Inn_Store * DistFromHouse([htStore]) + GA_PLANNER_DistCrit_Inn_Inn * DistFromHouse([htInn]);
    htMarketplace:    Output := - GA_PLANNER_DistCrit_Marketplace * DistFromHouse([htStore]);

    htIronSmithy:     Output := - GA_PLANNER_DistCrit_IronSmithy_Self * DistFromHouse([htIronSmithy]) - GA_PLANNER_DistCrit_IronSmithy_Res * DistFromHouse([htCoalMine, htIronMine]);
    htArmorSmithy:    Output := - GA_PLANNER_DistCrit_ArmorSmithy_Set * DistFromHouse([htIronSmithy]) - GA_PLANNER_DistCrit_ArmorSmithy_Res * DistFromHouse([htCoalMine, htIronMine]);
    htWeaponSmithy:   Output := - GA_PLANNER_DistCrit_WeaponSmithy_Set * DistFromHouse([htIronSmithy]) - GA_PLANNER_DistCrit_WeaponSmithy_Res * DistFromHouse([htCoalMine, htIronMine]);
    htTannery:        Output := - GA_PLANNER_DistCrit_Tannery_Set * DistFromHouse([htSwine, htWeaponWorkshop]);
    htArmorWorkshop:  Output := - GA_PLANNER_DistCrit_ArmorWorkshop_Set * DistFromHouse([htSawmill, htBarracks]);
    htWeaponWorkshop: Output := - GA_PLANNER_DistCrit_WeaponWorkshop_Set * DistFromHouse([htTannery, htBarracks]);
    htBarracks:       Output := - GA_PLANNER_DistCrit_Barracks_Set * DistFromHouses([htArmorSmithy, htArmorWorkshop, htWeaponSmithy, htWeaponWorkshop]);

    htBakery:         Output := - GA_PLANNER_DistCrit_Bakery_Set * DistFromHouses([htStore, htInn, htMill]) + GA_PLANNER_DistCrit_Bakery_Res * DistFromHouse([htIronMine, htGoldMine]);
    htButchers:       Output := - GA_PLANNER_DistCrit_Butchers_Set * DistFromHouses([htStore, htInn, htSwine]) + GA_PLANNER_DistCrit_Butchers_Res * DistFromHouse([htIronMine, htGoldMine]);
    htMill:           Output := - GA_PLANNER_DistCrit_Mill_Set * DistFromHouses([htFarm, htBakery]) + GA_PLANNER_DistCrit_Mill_Res * DistFromHouse([htIronMine, htGoldMine]);
    htSwine:          Output := - GA_PLANNER_DistCrit_Swine_Set * DistFromHouses([htFarm]) + GA_PLANNER_DistCrit_Swine_Res * DistFromHouse([htIronMine, htGoldMine]);
    htStables:        Output := - GA_PLANNER_DistCrit_Stables_Set * DistFromHouses([htFarm]) + GA_PLANNER_DistCrit_Stables_Res * DistFromHouse([htIronMine, htGoldMine]);
    htFarm:           Output := - GA_PLANNER_DistCrit_Farm_Set * DistFromHouse([htFarm]) + GA_PLANNER_DistCrit_Farm_Res * DistFromHouse([htIronMine, htGoldMine]);
    htWineyard:       Output := - GA_PLANNER_DistCrit_Wineyard_Set * DistFromHouse([htInn]) + GA_PLANNER_DistCrit_Wineyard_Res * DistFromHouse([htIronMine, htGoldMine]);

    htMetallurgists:  Output := - GA_PLANNER_DistCrit_Metallurgists_Set * DistFromHouse([htSchool, htStore, htMetallurgists]) - GA_PLANNER_DistCrit_Metallurgists_Res * DistFromHouse([htGoldMine]);
    htGoldMine:       Output := - GA_PLANNER_DistCrit_GoldMine_Set * DistFromHouse([htMetallurgists]);
    htCoalMine:       Output := - GA_PLANNER_DistCrit_CoalMine_Set * DistFromHouse([htMetallurgists, htIronSmithy, htArmorSmithy, htArmorWorkshop]);
    htIronMine:       Output := - GA_PLANNER_DistCrit_IronMine_Set * DistFromHouse([htIronSmithy]);

    htQuary:          Output := - GA_PLANNER_DistCrit_Quary_Set * DistFromHouse([htStore]);
    htWoodcutters:    Output := - GA_PLANNER_DistCrit_Woodcutters_Set * DistFromHouse([htStore]); // maybe ownership for first woodcutters? gAIFields.Influences.Ownership[fOwner, Mines.Items[I].Y, Mines.Items[I].X]
    htSawmill:        Output := - GA_PLANNER_DistCrit_Sawmill_Set * DistFromHouse([htWoodcutters, htWeaponWorkshop]);
    else
      Output := 0;
  end;
  Result := Output - GA_PLANNER_DistCrit_CenterStore * DistFromHouse([htStore]);
end;
//}





// Faster method for placing house
{
function TKMCityPlanner.FindPlaceForHouse(aUnlockProcedure: Boolean; aHT: TKMHouseType; out aBestLocs: TKMPointArray): Byte;
const
  BEST_PLANS_CNT = 8;
  INIT_BEST_BID = -1E20;
var
  Count: Word;
  CityCenter: TKMPoint;
  BestBidArr: array[0..BEST_PLANS_CNT-1] of Double;

  function EvalFreeEntrance(aLoc: TKMPoint): Single;
  const
    OBSTACLE_COEF = 1000;
  var
    I: Integer;
  begin
    Result := 0;
    if (aLoc.Y+2 >= gTerrain.MapY) then
    begin
      Result := OBSTACLE_COEF * 3;
      Exit;
    end;
    for I := -1 to 1 do
      Result := Result + Byte(tpWalk in gTerrain.Land[aLoc.Y+2,aLoc.X+I].Passability) * OBSTACLE_COEF;
  end;

  procedure EvaluateLoc(aLoc: TKMPoint; InitBid: Single);
  var
    L: Integer;
    Bid: Double;
  begin
    Count := Count + 1;
    Bid := - InitBid * GA_PLANNER_FindPlaceForHouse_CloseWorker
           + SnapCrit(aHT, aLoc) * GA_PLANNER_FindPlaceForHouse_SnapCrit
           + DistCrit(aHT, aLoc) * GA_PLANNER_FindPlaceForHouse_DistCrit
           - KMDistanceSqr(CityCenter, aLoc) * GA_PLANNER_FindPlaceForHouse_CityCenter
           - ObstaclesInHousePlan(aHT, aLoc)
           - gAIFields.Influences.GetOtherOwnerships(fOwner, aLoc.X, aLoc.Y) * GA_PLANNER_FindPlaceForHouse_Influence
           + gAIFields.Influences.EvalArea[aLoc.Y, aLoc.X] * GA_PLANNER_FindPlaceForHouse_EvalArea;
    if (aHT = htFarm) OR (aHT = htWineyard) then
      Bid := Bid + FieldCrit(aHT, aLoc)
    else if (aHT = htStore) OR (aHT = htBarracks) then
      Bid := Bid + EvalFreeEntrance(aLoc);
    for L := 0 to BEST_PLANS_CNT - 1 do
      if KMSamePoint(aLoc, aBestLocs[L]) then
        break
      else if (Bid > BestBidArr[L]) then // Insert sort for BEST_PLANS_CNT elements ...
      begin
        KMSwapPoints(aLoc, aBestLocs[L]);
        KMSwapFloat(Bid, BestBidArr[L]);
      end;
  end;

  procedure FindPlaceAroundHType(aHT_HMA: TKMHouseType);
  const
    INFLUENCE_LIMIT = 100;
  var
    I,K, Dist: Integer;
    Bid: Single;
    Dir: TDirection;
    Loc: TKMPoint;
    WorkersPos: TKMPointArray;
    HMA: THouseMappingArray;
    InitBids: TSingleArray;
  begin
    WorkersPos := gHands[fOwner].AI.CityManagement.Builder.WorkersPos;
    HMA := gAIFields.Eye.HousesMapping;
    // Calculate distance of house from closest free workers
    SetLength(InitBids, fPlannedHouses[aHT_HMA].Count);
    for I := 0 to fPlannedHouses[aHT_HMA].Count - 1 do
    begin
      InitBids[I] := 1000000;
      for K := 0 to Length(WorkersPos) - 1 do
      begin
        Bid := KMDistanceSqr(WorkersPos[K], fPlannedHouses[aHT_HMA].Plans[I].Loc);
        if (Bid < InitBids[I]) then
          InitBids[I] := Bid;
      end;
    end;
    for Dist := 2 to MAX_SCAN_DIST_FROM_HOUSE do
    begin
      if (Dist > 2) AND (BestBidArr[BEST_PLANS_CNT-1] <> INIT_BEST_BID) then // When we have full array of possible houses break searching and save time
        break;
      for I := fPlannedHouses[aHT_HMA].Count - 1 downto 0 do // The newest houses have the highest chance that we can place something here so start from newest
        for Dir := Low(HMA[aHT_HMA].Surroundings[Dist]) to High(HMA[aHT_HMA].Surroundings[Dist]) do
          for K := Low(HMA[aHT_HMA].Surroundings[Dist,Dir]) to High(HMA[aHT_HMA].Surroundings[Dist,Dir]) do
          begin
            Loc := KMPointAdd(fPlannedHouses[aHT_HMA].Plans[I].Loc, HMA[aHT_HMA].Surroundings[Dist,Dir,K], HMA[aHT].MoveToEntrance[Dir]);

            if not (gTerrain.TileInMapCoords(Loc.X, Loc.Y, 1))
              OR (fPerfArr[Loc.Y,Loc.X] >= fPerfIdx)
              OR (Dist > 4) AND (gAIFields.Influences.Ownership[fOwner, Loc.Y, Loc.X] < INFLUENCE_LIMIT) then
              continue;

            fPerfArr[Loc.Y,Loc.X] := fPerfIdx;
            if gAIFields.Eye.CanAddHousePlan(Loc, aHT, False, not aUnlockProcedure) then
              EvaluateLoc(Loc, InitBids[I]);
          end;
    end;
  end;

var
  Time: Cardinal;

  I, EditedCount: Integer;
  Probability: Single;
  HT: TKMHouseType;
  CCPArr: TKMPointArray;
begin

  Time := TimeGet();

  Result := 0;
  CCPArr := gAIFields.Eye.GetCityCenterPoints(False);
  if (Length(CCPArr) <= 0) then
    Exit;
  CityCenter := CCPArr[0];

  if (fPerfIdx >= 255) then
    ClearPerfArr();
  fPerfIdx := fPerfIdx + 1;

  Count := 0;
  SetLength(aBestLocs, BEST_PLANS_CNT);
  for I := 0 to BEST_PLANS_CNT - 1 do
    BestBidArr[I] := INIT_BEST_BID;

  for HT in HOUSE_DEPENDENCE[aHT] do
    FindPlaceAroundHType(HT);

  // In case that we have plans but criterium is not positive try to find better place everywhere
  EditedCount := Count * Byte(BestBidArr[0] > 0);
  // Probability will change in dependence on count of available plans
  Probability := (BEST_PLANS_CNT - Min(EditedCount, BEST_PLANS_CNT-1)) / (BEST_PLANS_CNT*1.0); // 1 <> 0.125
  for HT := HOUSE_MIN to HOUSE_MAX do
    if (HT <> htWatchTower)
      AND (fPlannedHouses[HT].Count > 0)
      AND (KaMRandom() < Probability)
      AND not (HT in HOUSE_DEPENDENCE[aHT]) then
      FindPlaceAroundHType(HT);

  Result := Min(Count, BEST_PLANS_CNT);


  Time := TimeGet() - Time;
  fTimeMeasure := fTimeMeasure + Time;

end;
//}


// Original method (no optimalization)
{
function TKMCityPlanner.FindPlaceForHouse(aUnlockProcedure: Boolean; aHT: TKMHouseType; out aBestLocs: TKMPointArray): Byte;
const
  BEST_PLANS_CNT = 5;
  INIT_BEST_BID = -1000000;
var
  I,K,L,Dist: Integer;
  Dir: TDirection;
  HType: TKMHouseType;
  Loc: TKMPoint;
  Bid, POMBid: Single;
  HMA: THouseMappingArray;
  BestBidArr: array[0..BEST_PLANS_CNT-1] of Single;
begin
  SetLength(aBestLocs, BEST_PLANS_CNT);
  for I := Low(BestBidArr) to High(BestBidArr) do
    BestBidArr[I] := INIT_BEST_BID;

  HMA := gAIFields.Eye.HousesMapping;
  for HType := HOUSE_MIN to HOUSE_MAX do
  for I := fPlannedHouses[HType].Count - 1 downto 0 do
  begin
    for Dist := 2 to MAX_SCAN_DIST_FROM_HOUSE do
    begin
      for Dir := Low(HMA[HType].Surroundings[Dist]) to High(HMA[HType].Surroundings[Dist]) do
      for K := Low(HMA[HType].Surroundings[Dist,Dir]) to High(HMA[HType].Surroundings[Dist,Dir]) do
      begin
        Loc := KMPointAdd(fPlannedHouses[HType].Plans[I].Loc, HMA[HType].Surroundings[Dist,Dir,K], HMA[aHT].MoveToEntrance[Dir]);
        if gAIFields.Eye.CanAddHousePlan(Loc, aHT, False, not aUnlockProcedure) then
        begin
          Bid := + SnapCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_SnapCrit
                 + DistCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_DistCrit
                 - GetTreesInHousePlanCnt(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_TreeInPlan
                 //+ Abs(fPlannedHouses[HType,I].Loc.Y - Loc.Y) * 3 // Prefer to build houses on left / right side
                 //+ Abs(fPlannedHouses[HType,I].Loc.X - Loc.X) * 2
                 - gAIFields.Influences.GetOtherOwnerships(fOwner,Loc.X,Loc.Y) * ManTune_PLANNER_FindPlaceForHouse_Influence;
          if (aHT = htFarm) OR (aHT = htWineyard) then
            Bid := Bid + FieldCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_FarmCrit;
          for L := Low(BestBidArr) to High(BestBidArr) do
            if KMSamePoint(Loc, aBestLocs[L]) then
              break
            else if (Bid > BestBidArr[L]) then
            begin
              KMSwapPoints(Loc, aBestLocs[L]);
              POMBid := BestBidArr[L];
              BestBidArr[L] := Bid;
              Bid := POMBid;
            end;
        end;
      end;
      if (Dist > 2) AND (BestBidArr[0] <> INIT_BEST_BID) then
        break;
    end;
  end;
  for I := High(BestBidArr) downto Low(BestBidArr) do
    if (BestBidArr[I] <> INIT_BEST_BID) then
      break;
  Result := I;
end;
//}

{
function GetBlockingTrees(aHT: TKMHouseType; aLoc: TKMPoint; var aTrees: TKMPointArray): Boolean;
function GetBlockingFields(aHT: TKMHouseType; aLoc: TKMPoint; var aFields: TKMPointArray): Boolean;

function TKMCityPlanner.GetBlockingTrees(aHT: TKMHouseType; aLoc: TKMPoint; var aTrees: TKMPointArray): Boolean;
var
  Output: Boolean;
  I,X,Y, TreeCnt: Integer;
  HMA: THouseMappingArray;
begin
  Result := True;
  if (aHT in [htIronMine, htGoldMine, htCoalMine]) then
    Exit;

  HMA := gAIFields.Eye.HousesMapping;
  SetLength(aTrees, Length(HMA[aHT].Tiles));
  for I := Low(aTrees) to High(aTrees) do
    aTrees[I] := KMPOINT_ZERO;

  Output := True;
  TreeCnt := 0;
  for I := Low(HMA[aHT].Tiles) to High(HMA[aHT].Tiles) do
  begin
    X := aLoc.X + HMA[aHT].Tiles[I].X;
    Y := aLoc.Y + HMA[aHT].Tiles[I].Y;
    Output := Output AND (tpBuild in gTerrain.Land[Y,X].Passability);
    if gTerrain.ObjectIsChopableTree(KMPoint(X,Y), [caAge1,caAge2,caAge3,caAgeFull]) then
    begin
      aTrees[TreeCnt] := KMPoint(X,Y);
      TreeCnt := TreeCnt + 1;
    end;
    if not Output then
      break;
  end;
  Result := Output;
end;


function TKMCityPlanner.GetBlockingFields(aHT: TKMHouseType; aLoc: TKMPoint; var aFields: TKMPointArray): Boolean;
var
  I,X,Y, FieldCnt: Integer;
  HMA: THouseMappingArray;
begin
  Result := True;
  if (aHT in [htIronMine, htGoldMine, htCoalMine]) then
    Exit;

  HMA := gAIFields.Eye.HousesMapping;
  SetLength(aFields, Length(HMA[aHT].Tiles));
  for I := Low(aFields) to High(aFields) do
    aFields[I] := KMPOINT_ZERO;

  FieldCnt := 0;
  for I := Low(HMA[aHT].Tiles) to High(HMA[aHT].Tiles) do
  begin
    X := aLoc.X + HMA[aHT].Tiles[I].X;
    Y := aLoc.Y + HMA[aHT].Tiles[I].Y;
    aFields[FieldCnt] := KMPoint(X,Y);
    if     (gHands[fOwner].BuildList.FieldworksList.HasField(aFields[FieldCnt]) = ftWine)
        OR (gHands[fOwner].BuildList.FieldworksList.HasField(aFields[FieldCnt]) = ftCorn) then
      FieldCnt := FieldCnt + 1;
  end;
  Result := (FieldCnt > 0);
end;


procedure TKMCityPlanner.PlanFarmFields(aLoc: TKMPoint; var aNodeTagList: TKMPointTagList);
const
  NORTH_PENALIZATION = 10;
  MAX_FIELDS = 16;
  NOT_IN_AVOID_BUILDING = 5;
  NOT_IN_FIELD = 8;
  SUM_COEF = 1;
var
  I,K,X,Y,I2,K2,Dist: Integer;
  Price: Cardinal;
  MaxP, MinP, Point: TKMPoint;
  Weight: Cardinal;
  Dir: TDirection;
  HT: TKMHouseType;
  FieldLoc: TKMPoint;
  HMA: THouseMappingArray;
  PriceArr: array of array of Word;
begin
  HT := htFarm;
  HMA := gAIFields.Eye.HousesMapping;

  MaxP := KMPoint(Min(aLoc.X + 2 + 4, gTerrain.MapX - 1), Min(aLoc.Y + 0 + 5, gTerrain.MapY - 1));
  MinP := KMPoint(Min(aLoc.X - 1 - 4, 1),                 Min(aLoc.Y - 2 - 4, 1));
  SetLength(PriceArr, MaxP.Y - MinP.Y, MaxP.X - MinP.X);
  for I := Low(PriceArr) to High(PriceArr) do
  begin
    Y := MinP.Y + I;
    for K := Low(PriceArr[I]) to High(PriceArr[I]) do
    begin
      X := MinP.X + K;
      Point := KMPoint(X,Y);
      if (gAIFields.Influences.AvoidBuilding[Y,X] > 0) OR not gHands[fOwner].CanAddFieldPlan(Point, ftCorn) then
        PriceArr[I,K] := 0
      else
        PriceArr[I,K] := + KMDistanceAbs(Point, aLoc)
                         + NOT_IN_AVOID_BUILDING * Byte(not (tpBuild in gTerrain.Land[Y,X].Passability) )
                         + NOT_IN_FIELD * Byte(not gTerrain.TileIsCornField(Point))
                         + NORTH_PENALIZATION * Byte(Y < aLoc.Y - 2);
    end;
  end;
  for I := Low(PriceArr) to High(PriceArr) do
  begin
    Y := MinP.Y + I;
    for K := Low(PriceArr[I]) to High(PriceArr[I]) do
      if (PriceArr[I,K] > 0) then
      begin
        X := MinP.X + K;
        Price := 0;
        for I2 := Max(Low(PriceArr),I-SUM_COEF) to Min(High(PriceArr),I+SUM_COEF) do
        for K2 := Max(Low(PriceArr[I]),K-SUM_COEF) to Min(High(PriceArr[I]),K+SUM_COEF) do
          Price := Price + PriceArr[I2,K2];
        aNodeTagList.Add(KMPoint(X,Y), Price);
      end;
  end;
  aNodeTagList.SortByTag;
end;
//}

{
procedure TKMCityPlanner.PlanFarmFields(aLoc: TKMPoint; var aNodeTagList: TKMPointTagList);
const
  NORTH_PENALIZATION = 10;
  MAX_FIELDS = 16;
  NOT_IN_AVOID_BUILDING = 3;
  NOT_IN_FIELD = 5;
var
  I,K,X,Y,I2,K2,Dist: Integer;
  Price: Cardinal;
  MaxP, MinP, Point: TKMPoint;
  Weight: Cardinal;
  Dir: TDirection;
  HT: TKMHouseType;
  FieldLoc: TKMPoint;
  HMA: THouseMappingArray;
  //PriceArr: array of array of Word;
  PriceArr: array[TDirection] of Integer;
begin
  HT := htFarm;
  HMA := gAIFields.Eye.HousesMapping;
  // Try find something to snap

  Dist := 5;
  for Dir := Low(HMA[HT].Surroundings[Dist]) to High(HMA[HT].Surroundings[Dist]) do
  begin
    PriceArr[Dir] := 500;
    for I := Low(HMA[HT].Surroundings[Dist,Dir]) to High(HMA[HT].Surroundings[Dist,Dir]) do
    begin
      FieldLoc := KMPointAdd(aLoc, HMA[HT].Surroundings[Dist,Dir,I]);
      if not (gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y) AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ftCorn)) then
        PriceArr[Dir] := PriceArr[Dir] - 5;
    end;
  end;
  PriceArr[dirN] := Max(0, PriceArr[dirN] + NORTH_PENALIZATION);
  // Find all possible places to build field
  for Dist := 1 to 4 do
  begin
    for Dir := Low(HMA[HT].Surroundings[Dist]) to High(HMA[HT].Surroundings[Dist]) do
    begin
      if (Dist = 1) AND (Dir = dirS) then // Don't plan fields 1 tile under farm plan
        continue;
      for I := Low(HMA[HT].Surroundings[Dist,Dir]) to High(HMA[HT].Surroundings[Dist,Dir]) do
      begin
        FieldLoc := KMPointAdd(aLoc, HMA[HT].Surroundings[Dist,Dir,I]);
        if gTerrain.TileInMapCoords(FieldLoc.X, FieldLoc.Y) AND gHands[fOwner].CanAddFieldPlan(FieldLoc, ftCorn) then
        begin
          Weight := KMDistanceAbs(FieldLoc, aLoc) + PriceArr[Dir];
          aNodeTagList.Add(FieldLoc, Weight);
        end;
      end;
      //if (aNodeTagList.Count >= MAX_FIELDS) then
      //  break;
    end;
  end;

  aNodeTagList.SortByTag;
end;
//}


end.


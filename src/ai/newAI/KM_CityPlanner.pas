unit KM_CityPlanner;
{$I KaM_Remake.inc}
interface
uses
  Classes, Graphics, KromUtils, Math, SysUtils,
  KM_Defaults, KM_Points, KM_CommonClasses, KM_CommonTypes, KM_CommonUtils,
  KM_TerrainFinder, KM_PerfLog, KM_Houses, KM_ResHouses, KM_ResWares,
  KM_PathFindingRoad, KM_CityPredictor,
  KM_AIInfluences, KM_NavMeshDefences;


var
  GA_PLANNER_FindPlaceForHouse_AllyInfluence          : Single = 10; // 0..XXX
  GA_PLANNER_FindPlaceForHouse_EnemyInfluence         : Single = 60; // 0..XXX
  GA_PLANNER_FindPlaceForWoodcutter_Influence         : Single = 40; // 0..255

  GA_PLANNER_ObstaclesInHousePlan_Tree                : Single = 124.624;
  GA_PLANNER_ObstaclesInHousePlan_Road                : Single = 137.4697;
  GA_PLANNER_FieldCrit_PolyRoute                      : Single =  35.929;
  GA_PLANNER_FieldCrit_FlatArea                       : Single =  40.450;
  GA_PLANNER_FieldCrit_Soil                           : Single =  57.084;
  GA_PLANNER_SnapCrit_SnapToHouse                     : Single =  20.604;
  GA_PLANNER_SnapCrit_SnapToFields                    : Single =   2.291;
  GA_PLANNER_SnapCrit_SnapToRoads                     : Single =  79.585;
  GA_PLANNER_SnapCrit_ClearEntrance                   : Single =  57.568;
  GA_PLANNER_FindPlaceForHouse_SnapCrit               : Single =   4.843;
  GA_PLANNER_FindPlaceForHouse_HouseDist              : Single =  59.141;
  GA_PLANNER_FindPlaceForHouse_SeedDist               : Single =   1.000;
  GA_PLANNER_FindPlaceForHouse_CityCenter             : Single =  14.352;
  GA_PLANNER_FindPlaceForHouse_Route                  : Single =  10.000;
  GA_PLANNER_FindPlaceForHouse_FlatArea               : Single =  93.710;

  GA_PLANNER_PlaceWoodcutter_DistFromForest           : Single =  66.286;
  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt           : Single =   1.845; // 0-~20
  GA_PLANNER_FindPlaceForWoodcutter_ExistForest       : Single = 490.972; // 0-1
  GA_PLANNER_FindPlaceForWoodcutter_Routes            : Single =   4.835; // 0-255
  GA_PLANNER_FindPlaceForWoodcutter_FlatArea          : Single =  19.104; // 0-81
  GA_PLANNER_FindPlaceForWoodcutter_Soil              : Single =  95.440; // 0-81
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit          : Single =  78.487; // 0-40
  GA_PLANNER_FindPlaceForWoodcutter_ABRange           : Single =  99.190;
  GA_PLANNER_FindPlaceForWoodcutter_Radius            : Single =   5.028;


  GA_PATHFINDING_BasePrice    : Word = 16;
  GA_PATHFINDING_HouseOutside : Word = 1;
  GA_PATHFINDING_Field        : Word = 33;
  GA_PATHFINDING_noBuildArea  : Word = 16;
  GA_PATHFINDING_Coal         : Word = 13;
  GA_PATHFINDING_Forest       : Word = 21;
  GA_PATHFINDING_OtherCase    : Word = 19;

  GA_SHORTCUTS_BasePrice      : Word = 7;
  GA_SHORTCUTS_HouseOutside   : Word = 10;
  GA_SHORTCUTS_Field          : Word = 22;
  GA_SHORTCUTS_noBuildArea    : Word = 1;
  GA_SHORTCUTS_Coal           : Word = 16;
  GA_SHORTCUTS_Forest         : Word = 23;
  GA_SHORTCUTS_OtherCase      : Word = 15;
  // Note: it is interesting to see different GA strategy for pathfinding
  // of first road to new house and pathfinding of shortcuts

type
  THousePlan = record
    Placed, ShortcutsCompleted, RemoveTreeInPlanProcedure, HouseReservation, ChopOnly: Boolean;
    House: TKMHouse;
    Loc, SpecPoint: TKMPoint;
  end;
  THousePlanArray = record
    Count, Completed, UnderConstruction: Word;
    Plans: array of THousePlan;
  end;
  TPlannedHousesArray = array [HOUSE_MIN..HOUSE_MAX] of THousePlanArray;


  TPathFindingCityPlanner = class(TPathFindingRoad)
  private
  protected
    function IsWalkableTile(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Word; override;
  public
  end;

  TPathFindingShortcutsCityPlanner = class(TPathFindingCityPlanner)
  private
  protected
    function DestinationReached(aX, aY: Word): Boolean; override;
    function MovementCost(aFromX, aFromY, aToX, aToY: Word): Word; override;
  public
  end;

  // Create plan of city AfterMissionInit and update it during game (if it is required)
  TKMCityPlanner = class
  private
    fDebugText: UnicodeString;
    {$IFDEF DEBUG_NewAI}
      fTimeMeasure: Cardinal;
      fBestHouseLocs: TKMPointArray;
      fBestHouseVal: TKMByteArray;
    {$ENDIF}

    fOwner: TKMHandID;
    fConstructedHouses: Word;
    fDefenceTowersPlanned: Boolean;
    fPlannedHouses: TPlannedHousesArray;
    fForestsNearby: TKMPointTagList;

    fRoadPlanner: TPathFindingCityPlanner;
    fRoadShortcutPlanner: TPathFindingShortcutsCityPlanner;

    procedure AddPlan(aHT: TKMHouseType; aLoc: TKMPoint); overload;
    procedure AddPlan(aHT: TKMHouseType; aLoc: TKMPoint; aSpecPoint: TKMPoint; aChopOnly: Boolean = False); overload;
    function GetPlan(aHT: TKMHouseType; aOnlyLatest: Boolean; out aLoc: TKMPoint; out aIdx: Integer): Boolean;

    function ObstaclesInHousePlan(aHT: TKMHouseType; aLoc: TKMPoint): Single;
    function FieldCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
    function SnapCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;
    function DistCrit(aHT: TKMHouseType; aLoc: TKMPoint): Single;

    procedure PlanWineFields(aLoc: TKMPoint; var aNodeList: TKMPointList);
    procedure PlanFarmFields(aLoc: TKMPoint; var aNodeList: TKMPointList);
    function FindPlaceForHouse(aUnlockProcedure: Boolean; aHT: TKMHouseType; out aBestLocs: TKMPointArray): Byte;
    function FindPlaceForMines(aHT: TKMHouseType): Boolean;
    function FindPlaceForQuary(StoneLocs: TKMPointTagList = nil): Boolean;
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

    function GetHousePlan(aUnlockProcedure, aIgnoreExistingPlans: Boolean; aHT: TKMHouseType; var aLoc: TKMPoint; var aIdx: Integer): Boolean;
    function GetRoadBetweenPoints(aStart, aEnd: TKMPoint; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
    function GetRoadToHouse(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
    function GetFieldToHouse(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList; var aFieldType: TKMFieldType): Boolean;
    function GetTreesInHousePlan(aHT: TKMHouseType; aIdx: Integer; var aField: TKMPointList): Byte;
    function FindForestAround(const aPoint: TKMPoint; aCountByInfluence: Boolean = False): Boolean;
    procedure CheckStoneReserves();

    procedure LogStatus(var aBalanceText: UnicodeString);
    procedure Paint();
  end;


const
  HOUSE_DEPENDENCE: array[HOUSE_MIN..HOUSE_MAX] of set of TKMHouseType = (  // This array is sorted by priority
    {htArmorSmithy}    [ htIronSmithy,     htCoalMine,       htBarracks,       htIronMine       ],
    {htArmorWorkshop}  [ htTannery,        htBarracks,       htSawmill,        htArmorWorkshop  ],
    {htBakery}         [ htInn,            htMill,           htStore,          htBakery         ],
    {htBarracks}       [ htArmorWorkshop,  htArmorSmithy,    htWeaponSmithy,   htWeaponWorkshop ],
    {htButchers}       [ htInn,            htSwine,          htStore,          htButchers       ],
    {htCoalMine}       [ htCoalMine,       htGoldMine,       htIronMine,       htStore          ],
    {htFarm}           [ htFarm,           htSwine,          htMill,           htStables        ],
    {htFisherHut}      [ htStore                                                                ],
    {htGoldMine}       [ htMetallurgists,  htStore                                              ],
    {htInn}            [ htButchers,       htBakery,         htStore,          htWineyard       ],
    {htIronMine}       [ htStore                                                                ],
    {htIronSmithy}     [ htCoalMine,       htIronMine,       htWeaponSmithy,   htIronSmithy     ],
    {htMarketplace}    [ htStore,          htMetallurgists,  htBarracks,       htMarketplace    ],
    // Metallurgist must be only close to coal / gold because serfs are not able to support this extremely critical resources
    {htMetallurgists}  [ htCoalMine,       htGoldMine                                           ],// htSchool, htStore
    {htMill}           [ htBakery,         htInn,            htMill                             ],
    {htQuary}          [ htStore                                                                ],
    {htSawmill}        [ htArmorWorkshop,  htSawmill,        htWeaponWorkshop                   ],
    {htSchool}         [ htMetallurgists,  htStore,          htSchool                           ],
    {htSiegeWorkshop}  [ htIronSmithy,     htSawmill,        htStore,          htSiegeWorkshop  ],
    {htStables}        [ htFarm,           htBarracks,       htStables                          ],
    {htStore}          [ htInn,            htBarracks,       htSchool                           ],
    {htSwine}          [ htFarm,           htButchers,       htSwine                            ],
    {htTannery}        [ htArmorWorkshop,  htTannery,        htBarracks                         ],
    {htTownHall}       [ htMetallurgists,  htStore,          htTownHall                         ],
    {htWatchTower}     [ htStore                                                                ],
    {htWeaponSmithy}   [ htIronSmithy,     htCoalMine,       htBarracks,       htIronMine       ],
    {htWeaponWorkshop} [ htSawmill,        htBarracks,       htWeaponWorkshop                   ],
    {htWineyard}       [ htInn,            htQuary                                              ],
    {htWoodcutters}    [ htStore                                                                ]
  );

implementation
uses
  KM_Game, KM_HouseCollection, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Terrain, KM_Resource,
  KM_AIFields, KM_Units, KM_UnitTaskDelivery, KM_UnitActionWalkTo, KM_UnitTaskGoEat, KM_UnitsCollection,
  KM_NavMesh, KM_HouseMarket, KM_HouseWoodcutters, KM_Eye, KM_ResUnits,
  KM_RenderAux, KM_ResMapElements;






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
    end;
  fDebugText := '';
  {$IFDEF DEBUG_NewAI}
    fTimeMeasure := 0;
  {$ENDIF}
  fConstructedHouses := 0;
  fOwner := aPlayer;
  fDefenceTowersPlanned := False;
  fForestsNearby := TKMPointTagList.Create();
  fRoadPlanner := TPathFindingCityPlanner.Create(fOwner);
  fRoadShortcutPlanner := TPathFindingShortcutsCityPlanner.Create(fOwner);
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
  fForestsNearby.Free;
  fRoadShortcutPlanner.Free;
  inherited;
end;


procedure TKMCityPlanner.Save(SaveStream: TKMemoryStream);
var
  HT: TKMHouseType;
  I, Len: Integer;
begin
  SaveStream.WriteA('CityPlanner');
  SaveStream.Write(fOwner);
  SaveStream.Write(fConstructedHouses);
  SaveStream.Write(fDefenceTowersPlanned);
  fForestsNearby.SaveToStream(SaveStream);

  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    SaveStream.Write(fPlannedHouses[HT].Count);
    SaveStream.Write(fPlannedHouses[HT].Completed);
    SaveStream.Write(fPlannedHouses[HT].UnderConstruction);
    Len := Length(fPlannedHouses[HT].Plans);
    SaveStream.Write( Len );
    for I := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[I] do
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
  I, Len: Integer;
begin
  LoadStream.ReadAssert('CityPlanner');
  LoadStream.Read(fOwner);
  LoadStream.Read(fConstructedHouses);
  LoadStream.Read(fDefenceTowersPlanned);
  fForestsNearby.LoadFromStream(LoadStream);

  for HT := HOUSE_MIN to HOUSE_MAX do
  begin
    LoadStream.Read(fPlannedHouses[HT].Count);
    LoadStream.Read(fPlannedHouses[HT].Completed);
    LoadStream.Read(fPlannedHouses[HT].UnderConstruction);
    LoadStream.Read(Len);
    SetLength(fPlannedHouses[HT].Plans, Len);
    for I := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[I] do
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
  I: Integer;
begin
  for HT := HOUSE_MIN to HOUSE_MAX do
    for I := 0 to fPlannedHouses[HT].Count - 1 do
      with fPlannedHouses[HT].Plans[I] do
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
  CompletedHouses,HousesUnderConstruction: Word;
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
          HousesUnderConstruction := HousesUnderConstruction + 1;
        end
        else // House was destroyed
        begin
          if (House <> nil) then
            gHands.CleanUpHousePointer(House);
        end;
      end;
    fPlannedHouses[HT].Completed := CompletedHouses;
    fPlannedHouses[HT].UnderConstruction := HousesUnderConstruction;
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


function TKMCityPlanner.GetHousePlan(aUnlockProcedure, aIgnoreExistingPlans: Boolean; aHT: TKMHouseType; var aLoc: TKMPoint; var aIdx: Integer): Boolean;
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
      htGoldMine, htCoalMine, htIronMine: FindPlaceForMines(aHT);
      htQuary: FindPlaceForQuary();
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
        Cnt := FindPlaceForHouse(aUnlockProcedure, aHT, BestLocs);
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
              OR (gHands[fOwner].BuildList.FieldworksList.HasField(aP) = ftRoad)              // Placed road plan
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
    I: Integer;
    Dist, BestDist: Single;
    Loc: TKMPoint;
    HT: TKMHouseType;
  begin
    BestDist := INIT_DIST;
    for HT := HOUSE_MIN to HOUSE_MAX do
      for I := 0 to fPlannedHouses[HT].Count - 1 do
        if ((HT <> htWatchTower) OR (fPlannedHouses[HT].Plans[I].Placed))// Only placed houses in case of WatchTower
           AND not fPlannedHouses[HT].Plans[I].RemoveTreeInPlanProcedure // Ignore Remove tree in plan procedure because there is not builded road
           AND not KMSamePoint(fPlannedHouses[HT].Plans[I].Loc, aNewLoc) // Ignore itself
           AND (not (HT = htWoodcutters) OR not fPlannedHouses[HT].Plans[I].ChopOnly) then // Chop only woodcutters are planned without road connection so skip it
        begin
          Loc := fPlannedHouses[HT].Plans[I].Loc;
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
    I: Integer;
  begin
    Result := False;
    // Check road and if it goes to enemy influence remove house plan
    I := 0;
    while (I < aField.Count) do
    begin
      PolygonIdx := gAIFields.NavMesh.KMPoint2Polygon[ aField[I] ];
      if (gAIFields.Influences.GetBestAllianceOwnership(fOwner, PolygonIdx, atEnemy) > MAX_ENEMY_INFLUENCE) then
        Exit;
      I := I + 5;
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
  Result := True;
  aField.Clear;
  if (aHT = htFarm) then
  begin
    aFieldType := ftCorn;
    PlanFarmFields( fPlannedHouses[aHT].Plans[aIdx].Loc, aField );
  end
  else if (aHT = htWineyard) then
  begin
    aFieldType := ftWine;
    PlanWineFields( fPlannedHouses[aHT].Plans[aIdx].Loc, aField );
  end
  else
    Result := False;
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
    Result := (gHands[fOwner].BuildList.FieldworksList.HasField(aPoint) = aField)
              OR (gTerrain.Land[aPoint.Y, aPoint.X].TileLock = aLock);
  end;
  function IsRoad(aAvoidBuilding: Byte; aPoint: TKMPoint): Boolean; inline;
  begin
    Result := (aAvoidBuilding = AVOID_BUILDING_NODE_LOCK_ROAD)
              OR gTerrain.TileIsWalkableRoad(aPoint)
              OR IsPlan(aPoint, tlRoadWork, ftRoad);
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
  I: Integer;
  Output: Single;
  Point: TKMPoint;
  Dir: TDirection;
  HMA: THouseMappingArray;
begin
  Output := 0;
  HMA := gAIFields.Eye.HousesMapping;
  for Dir := Low(HMA[aHT].Surroundings[DIST]) to High(HMA[aHT].Surroundings[DIST]) do
    for I := Low(HMA[aHT].Surroundings[DIST,Dir]) to High(HMA[aHT].Surroundings[DIST,Dir]) do
    begin
      Point := KMPointAdd(aLoc, HMA[aHT].Surroundings[DIST,Dir,I]);
      AvoidBuilding := gAIFields.Influences.AvoidBuilding[Point.Y, Point.X];
      Output := Output
                + Byte(IsNearHouse(AvoidBuilding,Point)) * GA_PLANNER_SnapCrit_SnapToHouse
                + Byte(IsReservedField(AvoidBuilding)) * GA_PLANNER_SnapCrit_SnapToFields // OR IsCornField(Point) OR IsWineField(Point)
                + Byte(IsRoad(AvoidBuilding,Point)) * GA_PLANNER_SnapCrit_SnapToRoads
                - Byte((Dir = dirS) AND IsReservedField(AvoidBuilding)) * GA_PLANNER_SnapCrit_ClearEntrance;
    end;
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
function TKMCityPlanner.FindPlaceForHouse(aUnlockProcedure: Boolean; aHT: TKMHouseType; out aBestLocs: TKMPointArray): Byte;
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

  {$IFDEF DEBUG_NewAI}
  procedure EvaluateLocWithComment();
  const
    Enum2House: array[TKMHouseType] of String = ('htNone', 'htAny',
    'ArmorSmithy',     'ArmorWorkshop',   'Bakery',        'Barracks',      'Butchers',
    'CoalMine',        'Farm',            'FisherHut',     'GoldMine',      'Inn',
    'IronMine',        'IronSmithy',      'Marketplace',   'Metallurgists', 'Mill',
    'Quary',           'Sawmill',         'School',        'SiegeWorkshop', 'Stables',
    'Store',           'Swine',           'Tannery',       'TownHall',      'WatchTower',
	'WeaponSmithy',    'WeaponWorkshop',  'Wineyard',      'Woodcutters'    );
  var
    K: Integer;
    Coef: Single;
    Loc: TKMPoint;
  begin
    fDebugText := Format('New house:' + Enum2House[aHT] + '|Perc'
      + #9 + '[X,Y]'
      + #9#9 + 'Snap'
      + #9#9 + 'Routes'
      + #9#9 + 'FltAr'
      + #9#9 + 'Center'
      + #9#9 + 'DistCC'
      + #9#9 + 'AllInfl'
      + #9#9 + 'EnmInfl'
      + #9#9 + 'Obstac'
      + #9#9 + 'DistSeed'
      + #9#9 + 'FarmCrit',[]);

    SetLength(fBestHouseLocs,Min(BEST_PLANS_CNT-1,5)+1);
    SetLength(fBestHouseVal,Length(fBestHouseLocs));
    Coef := Max(0.0000001, 100 / BestGainArr[0]);
    for K := 0 to Min(BEST_PLANS_CNT-1,5) do
    begin
      if (INIT_BEST_GAIN = BestGainArr[K]) then
        break;
      Loc := aBestLocs[K];
      fBestHouseLocs[K] := Loc;
      fBestHouseVal[K] := Max(0, Min(250, Round(BestGainArr[K] * Coef) + 100 ));
      fDebugText := fDebugText + Format(
        '|%3.1f' + #9 + '[%d,%d]' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f' + #9#9 + '%5.1f',
        [BestGainArr[K] * Coef,Loc.X,Loc.Y,
         + SnapCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_SnapCrit * Coef,
         + gAIFields.Eye.Routes[Loc.Y, Loc.X] * GA_PLANNER_FindPlaceForHouse_Route * Coef,
         + gAIFields.Eye.FlatArea[Loc.Y, Loc.X] * GA_PLANNER_FindPlaceForHouse_FlatArea * Coef,
         - KMDistanceSqr(CityCenter, Loc) * GA_PLANNER_FindPlaceForHouse_CityCenter * Coef,
         + DistCrit(aHT, Loc) * GA_PLANNER_FindPlaceForHouse_HouseDist * Coef,
         - gAIFields.Influences.GetBestAllianceOwnership(fOwner, Loc.X, Loc.Y, atAlly) * GA_PLANNER_FindPlaceForHouse_AllyInfluence,
         - gAIFields.Influences.GetBestAllianceOwnership(fOwner, Loc.X, Loc.Y, atEnemy) * GA_PLANNER_FindPlaceForHouse_EnemyInfluence,
         - ObstaclesInHousePlan(aHT, Loc) * Coef,
         - gAIFields.Eye.BuildFF.Distance[Loc] * GA_PLANNER_FindPlaceForHouse_SeedDist * Coef
        ]);
      if (aHT = htFarm) OR (aHT = htWineyard) then
        fDebugText := fDebugText + Format(#9#9 + ' %5.1f', [FieldCrit(aHT, Loc)]);
    end;
  end;
  {$ENDIF}

  procedure EvaluateLoc(aLoc: TKMPoint);
  var
    L: Integer;
    Gain: Double;
  begin
    Gain := + SnapCrit(aHT, aLoc) * GA_PLANNER_FindPlaceForHouse_SnapCrit
            + DistCrit(aHT, aLoc) * GA_PLANNER_FindPlaceForHouse_HouseDist
            - KMDistanceSqr(CityCenter, aLoc) * GA_PLANNER_FindPlaceForHouse_CityCenter
            - ObstaclesInHousePlan(aHT, aLoc)
            - gAIFields.Influences.GetBestAllianceOwnership(fOwner, aLoc.X, aLoc.Y, atAlly) * GA_PLANNER_FindPlaceForHouse_AllyInfluence
            - gAIFields.Influences.GetBestAllianceOwnership(fOwner, aLoc.X, aLoc.Y, atEnemy) * GA_PLANNER_FindPlaceForHouse_EnemyInfluence
            - gAIFields.Eye.BuildFF.Distance[aLoc] * GA_PLANNER_FindPlaceForHouse_SeedDist
            + gAIFields.Eye.Routes[aLoc.Y, aLoc.X] * GA_PLANNER_FindPlaceForHouse_Route
            + gAIFields.Eye.FlatArea[aLoc.Y, aLoc.X] * GA_PLANNER_FindPlaceForHouse_FlatArea;
    if (aHT = htFarm) OR (aHT = htWineyard) then
      Gain := Gain + FieldCrit(aHT, aLoc)
    else if (aHT = htStore) OR (aHT = htBarracks) then
      Gain := Gain + EvalFreeEntrance(aLoc);
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
  {$ENDIF}

  I, HouseCnt: Integer;
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
    IgnoreTrees := not aUnlockProcedure;
    IgnoreAvoidBuilding := False;
    MaxCnt := 40; // Huge performance impact (with 10 plans needs 40 ms to build city; 100 needs 320 ms)
    MaxDist := 30;
  end;

  BuildFF := gAIFields.Eye.BuildFF;

  SetLength(aBestLocs, BEST_PLANS_CNT);
  for I := 0 to BEST_PLANS_CNT - 1 do
    BestGainArr[I] := INIT_BEST_GAIN;

  HouseCnt := 0;
  for HT in HOUSE_DEPENDENCE[aHT] do
    HouseCnt := HouseCnt + fPlannedHouses[HT].Count;

  SetLength(InitPointsArr, HouseCnt);
  HouseCnt := 0;
  for HT in HOUSE_DEPENDENCE[aHT] do
    for I := 0 to fPlannedHouses[HT].Count - 1 do
    begin
      InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[I].Loc); // Place for mines can be problematic
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
        for I := fPlannedHouses[HT].Count - 1 downto 0 do
          if (HouseCnt = 0) OR (KaMRandom('TKMCityPlanner.FindPlaceForHouse') < PROBABILITY) then
          begin
            if (HouseCnt >= MAX_RND_HOUSES) then
              break;
            InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[I].Loc); // Place for mines can be problematic
            HouseCnt := HouseCnt + 1;
          end;
      if (HouseCnt >= MAX_RND_HOUSES) then
        break;
    end;
    SetLength(InitPointsArr,HouseCnt);
    BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, False);
  end;

  with BuildFF.Locs do
    for I := 0 to Count - 1 do
      EvaluateLoc(Items[I]);

  Result := Byte(INIT_BEST_GAIN <> BestGainArr[0] );


  {$IFDEF DEBUG_NewAI}
    Time := TimeGet() - Time;
    fTimeMeasure := fTimeMeasure + Time;
    EvaluateLocWithComment();
  {$ENDIF}
end;


function TKMCityPlanner.FindPlaceForMines(aHT: TKMHouseType): Boolean;
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
    for HT in HOUSE_DEPENDENCE[aHT] do
      HouseCnt := HouseCnt + fPlannedHouses[HT].Count;

    SetLength(InitPointsArr, HouseCnt);
    HouseCnt := 0;
    for HT in HOUSE_DEPENDENCE[aHT] do
      for I := 0 to fPlannedHouses[HT].Count - 1 do
      begin
        InitPointsArr[HouseCnt] := KMPointBelow(fPlannedHouses[HT].Plans[I].Loc); // Place for mines can be problematic
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
begin
  case aHT of
    htGoldMine:  Output := FindPlaceForMine(htGoldMine);
    htIronMine:  Output := FindPlaceForMine(htIronMine);
    htCoalMine:  Output := FindPlaceForCoalMine();
    else         Output := False;
  end;
  Result := Output;
end;


procedure TKMCityPlanner.CheckStoneReserves();
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
  // Exit if there is not completed quarry or quarry is already builded
  if (fPlannedHouses[HT].Completed = 0) OR (fPlannedHouses[HT].Count > fPlannedHouses[HT].Completed) then
    Exit;
  StoneLocs := gAIFields.Eye.GetStoneLocs(); // Find stone locs
  try
    if (StoneLocs.Count > 0) then
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
      for I := Low(CanMineCnt) to High(CanMineCnt) do
        if (CanMineCnt[LowestIdx] > CanMineCnt[I])
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
            else if (StoneLocs.Tag2[I] > 1) then
              StoneLocs.Delete(I);
        if CanBeReplaced then
        begin
          CopySL := TKMPointTagList.Create();
          for I := 0 to StoneLocs.Count - 1 do
            CopySL.Add(StoneLocs.Items[I], StoneLocs.Tag[I]);
          K := fPlannedHouses[HT].Count;
          FindPlaceForQuary(CopySL);
          // Demolish quarry only in case that new can be placed
          with fPlannedHouses[HT] do
            if (K < Count) then
            begin
              Plans[ Count-1 ].HouseReservation := True; // Reserve houses so it builder will init road
              if (Plans[LowestIdx].House <> nil) then
                Plans[LowestIdx].House.DemolishHouse(fOwner);
              RemovePlan(HT, LowestIdx);
            end;
        end;
      end;
    end;
  finally
    StoneLocs.Free;
  end;
end;


// Quarry planner (constants in this function are critical and will not be set by CA)
function TKMCityPlanner.FindPlaceForQuary(StoneLocs: TKMPointTagList = nil): Boolean;
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
begin
  Output := False;
  BuildFF := gAIFields.Eye.BuildFF;

  with HouseReq do
  begin
    HouseType := HT;
    IgnoreTrees := False;
    IgnoreAvoidBuilding := True;
    MaxCnt := 20;
    MaxDist := 11;
  end;
  if (StoneLocs = nil) then
    StoneLocs := gAIFields.Eye.GetStoneLocs(); // Find stone locs
  try
    if (StoneLocs.Count > 0) then
    begin
      BuildFF.UpdateState(); // Mark walkable area in owner's city
      // Consider Ownership in picking stone locs
      with StoneLocs do
        for I := Count - 1 downto 0 do
        begin
          IsWalkable := False;
          for Y := Items[I].Y to Min(Items[I].Y + MAX_SCAN_DIST, gTerrain.MapY - 1) do
            if (BuildFF.VisitIdx = BuildFF.Visited[Y,Items[I].X]) then
            begin
              Items[I] := KMPoint(Items[I].X,Y);// Set stone loc to closest walkable point (which is bellow actual point)
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
          Gain := - ObstaclesInHousePlan(htQuary,Loc) * 10
                  - BuildFF.Distance[Loc] * 20 // Snap crit is aggressive
                  - BuildFF.DistanceInitPoint[Loc] * 5
                  + SnapCrit(HT, Loc);
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
        gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(HT, BestLoc);
      end;
    end;
  finally
    StoneLocs.Free;
  end;
  Result := Output;
end;


// Find place for woodcutter
function TKMCityPlanner.FindPlaceForWoodcutter(aCenter: TKMPoint; aChopOnly: Boolean = False): Boolean;
const
  RADIUS = 8;
  COAL_PENALIZATON = 5;
  MIN_GAIN = -100000;
var
  Output: Boolean;
  I,K, CoalTiles: Integer;
  Gain, BestGain: Single;
  Loc, BestLoc: TKMPoint;
  HouseReq: TKMHouseRequirements;
  InitPointsArr: TKMPointArray;
  HMA: THouseMappingArray;
  BuildFF: TKMBuildFF;
begin
  Output := False;
  BuildFF := gAIFields.Eye.BuildFF;
  HMA := gAIFields.Eye.HousesMapping;
  with HouseReq do
  begin
    HouseType := htWoodcutters;
    IgnoreTrees := False;
    IgnoreAvoidBuilding := not aChopOnly;
    MaxCnt := 15;
    MaxDist := RADIUS;
  end;

  SetLength(InitPointsArr, 1);
  InitPointsArr[0] := aCenter;
  BuildFF.FindPlaceForHouse(HouseReq, InitPointsArr, True);

  BestGain := MIN_GAIN;
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

  if (BestGain <> MIN_GAIN) then
  begin
    Output := True;
    // Check whether is cutting point (center of forest) inside of house plan and in this case set it 1 point on left from house entrance
    if ((aCenter.Y <= BestLoc.Y) AND (aCenter.Y >= BestLoc.Y-1)) AND ((aCenter.X <= BestLoc.X) AND (aCenter.X >= BestLoc.X-2)) then
      aCenter := KMPoint(BestLoc.X-1, BestLoc.Y+1);
    AddPlan(htWoodcutters, BestLoc, aCenter, aChopOnly);
    gHands[fOwner].AI.CityManagement.Builder.LockHouseLoc(htWoodcutters, BestLoc);
  end;
  Result := Output;
end;


function TKMCityPlanner.FindForestAndWoodcutter(): Boolean;

  function EnoughTreeSeedTiles(aLoc: TKMPoint): Boolean;
  const
    RADIUS = 3;
    MIN_TREES_TILES = 15;
  var
    X,Y,Cnt: Integer;
  begin
    Cnt := 0;
    for Y := Max(1,aLoc.Y-RADIUS) to Min(gTerrain.MapY-1, aLoc.Y+RADIUS) do
    for X := Max(1,aLoc.X-RADIUS) to Min(gTerrain.MapX-1, aLoc.X+RADIUS) do
      if gTerrain.TileIsSoil( X, Y ) then
        Cnt := Cnt + 1;
    Result := Cnt >= MIN_TREES_TILES;
  end;

const
  SQR_MIN_DIST_FROM_CHOP_ONLY = 12*12;
var
  Time: Cardinal;
  Output, PartOfForest: Boolean;
  K,L, Cnt: Integer;
  DecreaseSpeed: Single;
  Point: TKMPoint;
begin
  Time := TimeGet();

  Output := False;

  gAIFields.Eye.GetForests(fForestsNearby);
  // Delete used forests (used by woodcutter - no matter if in chop only or chop and plant mode)
  for K := fForestsNearby.Count - 1 downto 0 do
    if not (fForestsNearby.Tag2[K] > 0) AND ( // Skip detection of exist forest (map maker should be able to produce good forest)
        (gAIFields.Influences.AvoidBuilding[  fForestsNearby.Items[K].Y, fForestsNearby.Items[K].X  ] >= 250) // Skip center point inside of exist forest
         OR not EnoughTreeSeedTiles( fForestsNearby.Items[K] ) // Check count of good terrain
      ) OR (gAIFields.Influences.GetBestAllianceOwner(fOwner, fForestsNearby.Items[K], atEnemy) > 10) then
    begin
      // Delete will remove element and move all others to left -> this array is not sorted yet so just switch actual and last
      Cnt := fForestsNearby.Count - 1;
      fForestsNearby.Items[K] := fForestsNearby.Items[Cnt];
      fForestsNearby.Tag[K] := fForestsNearby.Tag[Cnt];
      fForestsNearby.Tag2[K] := fForestsNearby.Tag2[Cnt];
      fForestsNearby.Delete(Cnt);
    end
    else // Remove potential forests around chop only woodcutters
      for L := 0 to fPlannedHouses[htWoodcutters].Count - 1 do
      begin
        Point := fPlannedHouses[htWoodcutters].Plans[L].SpecPoint;
        if (fPlannedHouses[htWoodcutters].Plans[L].ChopOnly) // Chop-only mode
          AND (KMDistanceSqr(fForestsNearby.Items[K], Point) < SQR_MIN_DIST_FROM_CHOP_ONLY) then
        begin
          Cnt := fForestsNearby.Count - 1;
          fForestsNearby.Items[K] := fForestsNearby.Items[Cnt];
          fForestsNearby.Tag[K] := fForestsNearby.Tag[Cnt];
          fForestsNearby.Tag2[K] := fForestsNearby.Tag2[Cnt];
          fForestsNearby.Delete(Cnt);
          break;
        end;
      end;

  // Evaluate clusters of trees (tree cnt + relative position [influence])
  for K := fForestsNearby.Count-1 downto 0 do
  begin
    Point := fForestsNearby.Items[K];
    PartOfForest := Boolean(fForestsNearby.Tag[K]);
    fForestsNearby.Tag[K] := Max(0, Round(
                                  + 1000000 // Base price
                                  + fForestsNearby.Tag2[K] * GA_PLANNER_FindPlaceForWoodcutter_TreeCnt
                                  + Byte(PartOfForest) * GA_PLANNER_FindPlaceForWoodcutter_ExistForest
                                  - gAIFields.Eye.Routes[Point.Y, Point.X] * GA_PLANNER_FindPlaceForWoodcutter_Routes
                                  - gAIFields.Eye.FlatArea[Point.Y, Point.X] * GA_PLANNER_FindPlaceForWoodcutter_FlatArea
                                  + gAIFields.Eye.Soil[Point.Y, Point.X] * GA_PLANNER_FindPlaceForWoodcutter_Soil
                                  - gAIFields.Eye.BuildFF.Distance[Point] * GA_PLANNER_FindPlaceForWoodcutter_DistCrit
                                  - gAIFields.Influences.GetOtherOwnerships(fOwner, Point.X, Point.Y) * GA_PLANNER_FindPlaceForWoodcutter_Influence
                                ));
  end;

  fForestsNearby.SortByTag();

  K := fForestsNearby.Count;
  while not Output AND (K > 0) do
  begin
    K := K - 1;
    Point := fForestsNearby.Items[K]; // Get the best forest
    Output := FindPlaceForWoodcutter(Point);
    // Mark forest by protected radius
    if Output then
    begin
      // Rounding of paramters from GA may change border limit for forest +- 1 so substract it
      DecreaseSpeed := Min(GA_PLANNER_FindPlaceForWoodcutter_ABRange,AVOID_BUILDING_FOREST_RANGE-1) / sqr(GA_PLANNER_FindPlaceForWoodcutter_Radius);
      gAIFields.Influences.MarkForest(Point, GA_PLANNER_FindPlaceForWoodcutter_Radius, DecreaseSpeed);
    end;
  end;
  Result := Output;

  Time := TimeGet() - Time;
end;


function TKMCityPlanner.FindForestAround(const aPoint: TKMPoint; aCountByInfluence: Boolean = False): Boolean;
const
  MIN_TREES = 3;
  SQR_MAX_DIST_FROM_HOUSE = 5*5;
  SQR_MIN_DIST_FROM_ACTIVE_FORESTS = 10*10;
  SQR_MIN_DIST_FROM_CHOP_ONLY = 12*12;
var
  Output, Check: Boolean;
  K,L: Integer;
  Gain, BestGain: Byte;
  Loc, BestLoc: TKMPoint;
begin
  Output := False;

  if (fForestsNearby <> nil) then
  begin
    BestGain := 0;
    BestLoc := KMPOINT_ZERO;
    for K := fForestsNearby.Count-1 downto 0 do
    begin
      Loc := fForestsNearby.Items[K];
      if (aCountByInfluence OR (KMDistanceSqr(aPoint, Loc) < SQR_MAX_DIST_FROM_HOUSE))
        AND (fForestsNearby.Tag2[K] >= MIN_TREES)
        AND (gAIFields.Influences.GetBestAllianceOwnership(fOwner, Loc.X, Loc.Y, atEnemy) < 50) then
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
            BestLoc := fForestsNearby.Items[K];
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
      begin
        for K := fForestsNearby.Count-1 downto 0 do
          if (KMDistanceSqr(fForestsNearby.Items[K], BestLoc) < SQR_MIN_DIST_FROM_CHOP_ONLY) then
            fForestsNearby.Delete(K);
      end;
    end;
  end;

  Result := Output;
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
  DISTANCE_BETWEEN_TOWERS = 10;
var
  I, K, DefCount: Integer;
  P1,P2: TKMPoint;
  Ratio: Single;
  DefLines: TKMDefenceLines;
  BuildFF: TKMBuildFF;
begin
  Result := False;

  if not gHands[fOwner].Locks.HouseCanBuild(htWatchTower)
    OR not gAIFields.NavMesh.Defences.FindDefenceLines(fOwner, DefLines)
    OR (DefLines.Count < 1) then
    Exit;

  // Mark walkable area in owner's city
  BuildFF := gAIFields.Eye.BuildFF;
  BuildFF.UpdateState();

  //Make list of defence positions
  for I := 0 to DefLines.Count-1 do
  begin
    P1 := gAIFields.NavMesh.Nodes[ DefLines.Lines[I].Nodes[0] ];
    P2 := gAIFields.NavMesh.Nodes[ DefLines.Lines[I].Nodes[1] ];
    if not (BuildFF.VisitIdx = BuildFF.Visited[ P1.Y, P1.X ])
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
end;


procedure TKMCityPlanner.LogStatus(var aBalanceText: UnicodeString);
begin
  {$IFDEF DEBUG_NewAI}
    aBalanceText := aBalanceText + '||CityPlanner: |' + fDebugText;
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
  HT: TKMHouseType;
  Loc: TKMPoint;
  Color: Cardinal;
  HMA: THouseMappingArray;
begin
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
  if (fForestsNearby <> nil) AND (fForestsNearby.Count > 0) then
  begin
    Division := 1 / (fForestsNearby.Tag[fForestsNearby.Count - 1] - fForestsNearby.Tag[0]) * 255.0;
    for K := 0 to fForestsNearby.Count - 1 do
    begin
      Loc := fForestsNearby.Items[K];
      Color := (Max(50,Round((fForestsNearby.Tag[K] - fForestsNearby.Tag[0]) * Division)) shl 24) OR $000000FF;
      gRenderAux.Quad(Loc.X, Loc.Y, Color);
    end;
  end;
end;







{ TPathFindingCityPlanner }
function TPathFindingCityPlanner.IsWalkableTile(aX, aY: Word): Boolean;
begin
  // Just in case that worker will die while digging house plan or when you plan road near ally
  Result := inherited AND (gAIFields.Influences.AvoidBuilding[aY, aX] <> AVOID_BUILDING_HOUSE_INSIDE_LOCK);
end;


function TPathFindingCityPlanner.MovementCost(aFromX, aFromY, aToX, aToY: Word): Word;
var
  IsRoad: Boolean;
  AvoidBuilding: Byte;
begin
  Result := GA_PATHFINDING_BasePrice;
  AvoidBuilding := gAIFields.Influences.AvoidBuilding[aToY, aToX];
  IsRoad := (AvoidBuilding = AVOID_BUILDING_NODE_LOCK_ROAD)                                      // Reserved road plan
            OR (tpWalkRoad in gTerrain.Land[aToY, aToX].Passability)                             // Completed road
            OR (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(aToX, aToY)) = ftRoad) // Placed road plan
            OR (gTerrain.Land[aToY, aToX].TileLock = tlRoadWork);                                // Road under construction

  if not IsRoad then
    //Building roads over fields is discouraged unless unavoidable
    case AvoidBuilding of
      AVOID_BUILDING_HOUSE_OUTSIDE_LOCK: begin Inc(Result, GA_PATHFINDING_HouseOutside); end; // 1 tile from future house
      AVOID_BUILDING_NODE_LOCK_FIELD: Inc(Result, GA_PATHFINDING_Field); // Corn / wine field
      AVOID_BUILDING_COAL_TILE: Inc(Result, GA_PATHFINDING_Coal);
      //AVOID_BUILDING_HOUSE_INSIDE_LOCK: begin end; // Tiles inside future house (forbiden)
      //AVOID_BUILDING_NODE_LOCK_ROAD: begin end; // This will not occur
      //AVOID_BUILDING_FOREST_MINIMUM: begin end;
      else
      begin
        // Snap to no-build areas (1 tile from house)
        if not (tpBuild in gTerrain.Land[aToY,aToX].Passability) then
          Inc(Result, GA_PATHFINDING_noBuildArea)
        else if (AvoidBuilding > AVOID_BUILDING_FOREST_MINIMUM) then // Forest or coal etc.
          Inc(Result, GA_PATHFINDING_Forest)
        else
          Inc(Result, GA_PATHFINDING_OtherCase);
      end;
    end;
end;


{ TPathFindingShortcutsCityPlanner }
function TPathFindingShortcutsCityPlanner.MovementCost(aFromX, aFromY, aToX, aToY: Word): Word;
var
  IsRoad: Boolean;
  AvoidBuilding: Byte;
begin
  Result := GA_SHORTCUTS_BasePrice;
  AvoidBuilding := gAIFields.Influences.AvoidBuilding[aToY, aToX];
  IsRoad := (AvoidBuilding = AVOID_BUILDING_NODE_LOCK_ROAD)                                     // Reserved road plan
            OR (tpWalkRoad in gTerrain.Land[aToY, aToX].Passability)                            // Completed road
            OR (gHands[fOwner].BuildList.FieldworksList.HasField(KMPoint(aToX, aToY)) = ftRoad) // Placed road plan
            OR (gTerrain.Land[aToY, aToX].TileLock = tlRoadWork);                               // Road under construction

  if not IsRoad then
    //Building roads over fields is discouraged unless unavoidable
    case AvoidBuilding of
      AVOID_BUILDING_HOUSE_OUTSIDE_LOCK: begin Inc(Result, GA_SHORTCUTS_HouseOutside); end; // 1 tile from future house
      AVOID_BUILDING_NODE_LOCK_FIELD: Inc(Result, GA_SHORTCUTS_Field); // Corn / wine field
      AVOID_BUILDING_COAL_TILE: Inc(Result, GA_SHORTCUTS_Coal);
      //AVOID_BUILDING_HOUSE_INSIDE_LOCK: begin end; // Tiles inside future house (forbiden)
      //AVOID_BUILDING_NODE_LOCK_ROAD: begin end; // This will not occur
      //AVOID_BUILDING_FOREST_MINIMUM: begin end;
      else
      begin
        // Snap to no-build areas (1 tile from house)
        if not (tpBuild in gTerrain.Land[aToY,aToX].Passability) then
          Inc(Result, GA_SHORTCUTS_noBuildArea)
        else if (AvoidBuilding > AVOID_BUILDING_FOREST_MINIMUM) then // Forest or coal etc.
          Inc(Result, GA_SHORTCUTS_Forest)
        else
          Inc(Result, GA_PATHFINDING_OtherCase);
      end;
    end;
end;


function TPathFindingShortcutsCityPlanner.DestinationReached(aX, aY: Word): Boolean;
begin
  Result := ((aX = fLocB.X) and (aY = fLocB.Y)); //We reached destination point
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


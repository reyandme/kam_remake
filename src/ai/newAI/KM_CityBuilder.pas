{
Artificial intelligence
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_CityBuilder;
{$I KaM_Remake.inc}
interface
uses
  KromUtils, Math, SysUtils,
  KM_Defaults, KM_CommonClasses, KM_Points, KM_Sort,
  KM_ResHouses, KM_ResWares, KM_BuildList, KM_Houses,
  KM_AIInfluences, KM_CityPlanner, KM_CityPredictor, KM_Eye, KM_AIParameters;

const
  NODE_PRIO_RoadsUnlockHouse = 1;
  NODE_PRIO_Roads = 2;
  NODE_PRIO_RoadsReservation = 3;
  NODE_PRIO_RemoveTreeInPlan = 3;
  NODE_PRIO_Fields = 4;
  NODE_PRIO_FieldsReservation = 4;
  NODE_PRIO_Shortcuts = 3;
  NODE_PRIO_Default = 255;

type

  TBuildNode = record
    Active, RemoveTreesMode, ShortcutMode: Boolean;
    Priority: Byte;
    FreeWorkers, RequiredWorkers, MaxReqWorkers: Integer;
    CenterPoint: TKMPoint;
    FieldType: TKMFieldType; //ftCorn, ftWine, ftRoad
    FieldList: TKMPointList;
  end;

  TConstructionState = (csNoNodeAvailable, csNoPlaceCanBeFound, csHousePlaced, csCannotPlaceHouse, csHouseReservation, csRemoveTreeProcedure);

  // City builder (build nodes, selection from required houses)
  TKMCityBuilder = class
  private
    fStoneCrisis, fStoneShortage, fWoodShortage, fTrunkShortage, fGoldShortage: Boolean;
    fFreeWorkersCnt: Integer;
    fOwner: TKMHandID;
    fBuildNodes: array of TBuildNode;
    fWorkersPos: TKMPointArray;

    fPlanner: TKMCityPlanner;
    fPredictor: TKMCityPredictor;

    {$IFDEF DEBUG_NewAI}
      fTimePlanRoads: Cardinal;
    {$ENDIF}

    procedure UpdateBuildNodes();
    procedure UpdateBuildNode(var aNode: TBuildNode);

    function BuildHouse(aIgnoreTrees, aHouseReservation, aIgnoreExistingPlans: Boolean; aHT: TKMHouseType; aRoadNodePrio: Byte = NODE_PRIO_Default): TConstructionState;
    procedure LockNode(var aNode: TBuildNode);
    procedure UnlockPointOfNode(aPoint: TKMPoint; aCheckHousePlan: Boolean = False);
    procedure UnlockNode(var aNode: TBuildNode; aCheckHousePlan: Boolean = False);

    procedure CheckBasicMaterials(var aMaxPlans, aMaxPlace: Integer; var aTrunkBalance: Single; aTick: Cardinal);
    procedure CreateShortcuts();
  public
    constructor Create(aPlayer: TKMHandID; aPredictor: TKMCityPredictor);
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad();

    property Planner: TKMCityPlanner read fPlanner;
    property WorkersPos: TKMPointArray read fWorkersPos;
    property StoneShortage: Boolean read fStoneShortage;
    property StoneCrisis: Boolean read fStoneCrisis;
    property WoodShortage: Boolean read fWoodShortage;
    property TrunkShortage: Boolean read fTrunkShortage;
    property GoldShortage: Boolean read fGoldShortage;

    procedure AfterMissionInit();
    procedure OwnerUpdate(aPlayer: TKMHandID);

    procedure UpdateState(aTick: Cardinal);
    procedure ChooseHousesToBuild(aTick: Cardinal);

    procedure LockHouseLoc(aHT: TKMHouseType; aLoc: TKMPoint);
    procedure UnlockHouseLoc(aHT: TKMHouseType; aLoc: TKMPoint);

    procedure LogStatus(var aBalanceText: UnicodeString);
    procedure Paint();
  end;


implementation
uses
  Classes, KM_Game, KM_Hand, KM_HandsCollection, KM_Terrain, KM_Resource,
  KM_AIFields, KM_Units, KM_UnitsCollection, KM_UnitTaskBuild,
  KM_RenderAux, KM_ResMapElements, KM_CommonUtils;

{ Procedural functions }
function CompareBuildNode(const aElem1, aElem2): Integer;
var
  val1 : TBuildNode absolute aElem1;
  val2 : TBuildNode absolute aElem2;
begin
  if val1.Active AND val2.Active then
  begin
    if      (val1.Priority = val2.Priority) then Result :=  0
    else if (val1.Priority < val2.Priority) then Result := -1
    else                                         Result := +1;
  end
  else if val1.Active then Result := -1
  else if val2.Active then Result := +1
  else                     Result :=  0;
end;


{ TKMCityBuilder }
constructor TKMCityBuilder.Create(aPlayer: TKMHandID; aPredictor: TKMCityPredictor);
begin
  inherited Create;

  fOwner := aPlayer;
  fPredictor := aPredictor;
  fPlanner := TKMCityPlanner.Create(aPlayer);

  {$IFDEF DEBUG_NewAI}
    fTimePlanRoads := 0;
  {$ENDIF}
end;


destructor TKMCityBuilder.Destroy;
var
  I: Integer;
begin
  fPlanner.Free;
  for I := Low(fBuildNodes) to High(fBuildNodes) do
    fBuildNodes[I].FieldList.Free;
  inherited;
end;


procedure TKMCityBuilder.Save(SaveStream: TKMemoryStream);
var
  I, Cnt: Integer;
begin
  SaveStream.PlaceMarker('CityBuilder');
  SaveStream.Write(fFreeWorkersCnt);
  SaveStream.Write(fStoneCrisis);
  SaveStream.Write(fStoneShortage);
  SaveStream.Write(fWoodShortage);
  SaveStream.Write(fTrunkShortage);
  SaveStream.Write(fGoldShortage);
  SaveStream.Write(fOwner);

  Cnt := Length(fWorkersPos);
  SaveStream.Write(Cnt);
  if (Cnt > 0) then
    SaveStream.Write(fWorkersPos[0], SizeOf(fWorkersPos[0]) * Cnt);

  Cnt := Length(fBuildNodes);
  SaveStream.Write(Cnt);
  for I := 0 to Cnt - 1 do
    with fBuildNodes[I] do
    begin
      SaveStream.Write(Active);
      SaveStream.Write(RemoveTreesMode);
      SaveStream.Write(ShortcutMode);
      SaveStream.Write(Priority);
      SaveStream.Write(FreeWorkers);
      SaveStream.Write(RequiredWorkers);
      SaveStream.Write(MaxReqWorkers);
      SaveStream.Write(CenterPoint, SizeOf(CenterPoint));
      SaveStream.Write(FieldType, SizeOf(TKMFieldType));
      FieldList.SaveToStream(SaveStream);
    end;

  fPlanner.Save(SaveStream);
end;


procedure TKMCityBuilder.Load(LoadStream: TKMemoryStream);
var
  I, Cnt: Integer;
begin
  LoadStream.CheckMarker('CityBuilder');
  LoadStream.Read(fFreeWorkersCnt);
  LoadStream.Read(fStoneCrisis);
  LoadStream.Read(fStoneShortage);
  LoadStream.Read(fWoodShortage);
  LoadStream.Read(fTrunkShortage);
  LoadStream.Read(fGoldShortage);
  LoadStream.Read(fOwner);

  LoadStream.Read(Cnt);
  SetLength(fWorkersPos, Cnt);
  if (Cnt > 0) then
    LoadStream.Read(fWorkersPos[0], SizeOf(fWorkersPos[0]) * Cnt);

  LoadStream.Read(Cnt);
  SetLength(fBuildNodes, Cnt);
  for I := 0 to Cnt - 1 do
    with fBuildNodes[I] do
    begin
      LoadStream.Read(Active);
      LoadStream.Read(RemoveTreesMode);
      LoadStream.Read(ShortcutMode);
      LoadStream.Read(Priority);
      LoadStream.Read(FreeWorkers);
      LoadStream.Read(RequiredWorkers);
      LoadStream.Read(MaxReqWorkers);
      LoadStream.Read(CenterPoint, SizeOf(CenterPoint));
      LoadStream.Read(FieldType, SizeOf(TKMFieldType));
      FieldList := TKMPointList.Create();
      FieldList.LoadFromStream(LoadStream);
    end;

  fPlanner.Load(LoadStream);
end;


procedure TKMCityBuilder.SyncLoad();
begin
  fPlanner.SyncLoad();
end;


procedure TKMCityBuilder.AfterMissionInit();
var
  I: Integer;
begin
  fPlanner.AfterMissionInit();
  SetLength(fBuildNodes, gHands[fOwner].AI.CityManagement.Predictor.WorkerCount);
  for I := Low(fBuildNodes) to High(fBuildNodes) do
  begin
    fBuildNodes[I].FieldList := TKMPointList.Create();
    fBuildNodes[I].Active := False;
  end;
end;


procedure TKMCityBuilder.OwnerUpdate(aPlayer: TKMHandID);
begin
  fOwner := aPlayer;
  fPlanner.OwnerUpdate(aPlayer);
end;


procedure TKMCityBuilder.UpdateState(aTick: Cardinal);
const
  CHECK_STONE_RESERVES = 3 * 60 * MAX_HANDS; // Every 3 min check stone reserves
  CHECK_FIELDS = 1 * 30 * MAX_HANDS; // Every 30 sec 1 Farm
var
  K: Integer;
begin
  if (aTick mod MAX_HANDS = fOwner) then
  begin
    fPlanner.UpdateState(aTick); // Planner must be updated as first to secure that completed houses are actualized
    UpdateBuildNodes();
    if (fPredictor.RequiredHouses[htQuary] <= 0) AND (aTick mod CHECK_STONE_RESERVES = fOwner) then // First update stone reserves
      Planner.CheckStoneReserves(False, fPredictor.RequiredHouses[htQuary])
    else if (aTick mod CHECK_FIELDS = fOwner) then
      for K := Low(fBuildNodes) to High(fBuildNodes) do
        with fBuildNodes[K] do
          if not Active AND Planner.CheckFields(FieldType, FieldList) then
          begin
            LockNode(fBuildNodes[K]);
            Active := True;
            Priority := NODE_PRIO_Fields;
            RemoveTreesMode := False;
            ShortcutMode := False;
            MaxReqWorkers := 1;
            RequiredWorkers := Min(MaxReqWorkers, FieldList.Count); // Real count will be updated during building process
            CenterPoint := FieldList[0];

            break;
          end;
  end;
end;


procedure TKMCityBuilder.LockHouseLoc(aHT: TKMHouseType; aLoc: TKMPoint);
var
  I,Dist: Integer;
  Point: TKMPoint;
  Dir: TDirection;
begin
  // Reserve all tiles inside house plan
  //if (aHT <> htCoalMine) then

    for I := Low(gAIFields.Eye.HousesMapping[aHT].Tiles) to High(gAIFields.Eye.HousesMapping[aHT].Tiles) do
    begin
      Point := KMPointAdd(aLoc, gAIFields.Eye.HousesMapping[aHT].Tiles[I]);
      gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] := AVOID_BUILDING_HOUSE_INSIDE_LOCK;
      gAIFields.Eye.BuildFF.ActualizeTile(Point.X, Point.Y);
    end;
  // Reserve all tiles in distance 1 from house plan
  Dist := 1;
  for Dir := Low(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist]) to High(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist]) do
    for I := Low(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist,Dir]) to High(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist,Dir]) do
    begin
      Point := KMPointAdd(aLoc, gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist,Dir,I]);
      // Skip coal tiles, forests and other reserved tiles
      if (gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] < AVOID_BUILDING_HOUSE_INSIDE_LOCK) then
      begin
        gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] := AVOID_BUILDING_HOUSE_OUTSIDE_LOCK;
        gAIFields.Eye.BuildFF.ActualizeTile(Point.X, Point.Y);
      end;
    end;
end;


procedure TKMCityBuilder.UnlockHouseLoc(aHT: TKMHouseType; aLoc: TKMPoint);
var
  I,Dist: Integer;
  Point: TKMPoint;
  Dir: TDirection;
begin
  if (aHT in [htGoldMine, htIronMine]) then
    Exit;
  // Free all tiles inside house plan
  //if (aHT <> htCoalMine) then
    for I := Low(gAIFields.Eye.HousesMapping[aHT].Tiles) to High(gAIFields.Eye.HousesMapping[aHT].Tiles) do
    begin
      Point := KMPointAdd(aLoc, gAIFields.Eye.HousesMapping[aHT].Tiles[I]);
      gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] := AVOID_BUILDING_UNLOCK;
    end;
  // Free all tiles in distance 1 from house plan
  Dist := 1;
  for Dir := Low(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist]) to High(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist]) do
    for I := Low(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist,Dir]) to High(gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist,Dir]) do
    begin
      Point := KMPointAdd(aLoc, gAIFields.Eye.HousesMapping[aHT].Surroundings[Dist,Dir,I]);
      if (gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] = AVOID_BUILDING_HOUSE_OUTSIDE_LOCK) then
        gAIFields.Influences.AvoidBuilding[Point.Y, Point.X] := AVOID_BUILDING_UNLOCK;
    end;
end;


procedure TKMCityBuilder.LockNode(var aNode: TBuildNode);
var
  NODE_TYPE: Byte;
  I: Integer;
begin
  case aNode.FieldType of
    ftRoad: NODE_TYPE := AVOID_BUILDING_NODE_LOCK_ROAD;
    else    NODE_TYPE := AVOID_BUILDING_NODE_LOCK_FIELD;
  end;
  with aNode.FieldList do
    for I := 0 to Count-1 do
      if (gAIFields.Influences.AvoidBuilding[Items[I].Y, Items[I].X] < NODE_TYPE) then
      begin
        gAIFields.Influences.AvoidBuilding[Items[I].Y, Items[I].X] := NODE_TYPE;
        gAIFields.Eye.BuildFF.ActualizeTile(Items[I].X, Items[I].Y);
      end;
end;


procedure TKMCityBuilder.UnlockPointOfNode(aPoint: TKMPoint; aCheckHousePlan: Boolean = False);
var
  AB: Byte;
  X,Y: Integer;
begin
  if aCheckHousePlan then
    for Y := Max(1,aPoint.Y-1) to Min(aPoint.Y+1, gTerrain.MapY-1) do
    for X := Max(1,aPoint.X-1) to Min(aPoint.X+1, gTerrain.MapX-1) do
      if (gAIFields.Influences.AvoidBuilding[Y,X] = AVOID_BUILDING_HOUSE_INSIDE_LOCK) then
      begin
        gAIFields.Influences.AvoidBuilding[aPoint.Y, aPoint.X] := AVOID_BUILDING_HOUSE_OUTSIDE_LOCK;
        Exit;
      end;
  AB := gAIFields.Influences.AvoidBuilding[aPoint.Y, aPoint.X];
  if (aCheckHousePlan AND not (AB in [AVOID_BUILDING_MINE_TILE, High(Byte)])) OR (AB = AVOID_BUILDING_NODE_LOCK_ROAD) then // Only roads are unlocked = aCheckHousePlan
    gAIFields.Influences.AvoidBuilding[aPoint.Y, aPoint.X] := AVOID_BUILDING_UNLOCK;
end;


procedure TKMCityBuilder.UnlockNode(var aNode: TBuildNode; aCheckHousePlan: Boolean = False);
var
  I: Integer;
begin
  with aNode.FieldList do
    for I := 0 to Count-1 do
      UnlockPointOfNode(Items[I], aCheckHousePlan);
end;


procedure TKMCityBuilder.UpdateBuildNodes();
  function BuildingFirstSchool(): Boolean;
  var
    K: Integer;
    Worker: TKMUnitWorker;
    pomP : TKMPoint;
    UnitTask: TKMTaskBuildHouseArea;
  begin
    with fPlanner.PlannedHouses[htSchool] do
    begin
      Result := (UnderConstruction = 1) AND (Completed = 0) AND (Plans[0].Placed) AND (Plans[0].House <> nil);
      if Result then
      begin
        for K := Low(fBuildNodes) to High(fBuildNodes) do
          if fBuildNodes[K].Active then
            if KMSamePoint(KMPointBelow(Plans[0].Loc), fBuildNodes[K].FieldList[0]) then
              Exit(False);
        for K := 0 to gHands[fOwner].Units.Count - 1 do
          if not gHands[fOwner].Units[K].IsDeadOrDying
             AND (gHands[fOwner].Units[K] is TKMUnitWorker) then
          begin
            pomP.X := pomP.X*1;
            Worker := TKMUnitWorker(gHands[fOwner].Units[K]);
            if (Worker.Task <> nil) AND (Worker.Task.TaskType = uttBuildHouseArea) then
            begin
              UnitTask := TKMTaskBuildHouseArea(Worker.Task);
              if (UnitTask.DigState > 1) then
                Exit(False);
            end;
          end;
      end;
    end;
  end;
//Worker tasks:
//  Common phase of tasks
//    0: None (Think about plans)
//    1: Go to plan
//    2,3: Dig
//  TTaskBuildRoad:
//    4: Wait for stone
//    5,6,7: Get stone, Build road, Build road + change tile
//    8: Complete road
//    9: End task
//  TTaskBuildField
//    4: End task
//  TTaskBuildWine
//    4: Dig + change tile
//    5: Wait for a wood
//    6,7: receive wood, build wine
//    8: End task
var
  Check: Boolean;
  K,L, Prio, ClosestIdx, ClosestDist, Dist, ReqWorkerCnt: Integer;
  H: TKMHouse;
  WorkersPos: TKMPointArray;
  BuildNode: TBuildNode;
begin
  // Dont update nodes when first school needs to be build
  if BuildingFirstSchool() then
    Exit;

  // Reset count of free workers in each node
  for K := Low(fBuildNodes) to High(fBuildNodes) do
    fBuildNodes[K].FreeWorkers := 0;

  // Get positions of workes with nil task (no task)
  fFreeWorkersCnt := 0;
  SetLength(WorkersPos, gHands[fOwner].Stats.GetUnitQty(utWorker));
  for K := 0 to gHands[fOwner].Units.Count - 1 do
    if not gHands[fOwner].Units[K].IsDeadOrDying
       AND (gHands[fOwner].Units[K] is TKMUnitWorker) then
      with gHands[fOwner].Units[K] do
      begin
        if ( (Task = nil)
            //OR ( (UnitTask.TaskName = uttBuildRoad)  AND (UnitTask.Phase > 8) ) // This actualy have big impact
            //OR ( (UnitTask.TaskName = uttBuildField) AND (UnitTask.Phase > 3) ) // GA set fields max 1 worker so it have no sense to check it
            //OR ( (UnitTask.TaskName = uttBuildWine)  AND (UnitTask.Phase > 6) ) // GA set fields max 1 worker so it have no sense to check it
            //OR (UnitTask.TaskName = uttBuildHouse)
           ) then
        //if (gHands[fOwner].Units[I].IsIdle) then
        begin
          WorkersPos[fFreeWorkersCnt] := CurrPosition;
          fFreeWorkersCnt := fFreeWorkersCnt + 1;
        end;
      end;

  // Check that all houses with resources are under construction
  for K := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[K];
    if (H <> nil) AND not H.IsComplete AND (H.GetBuildResDeliveredPercent = 1) then
    begin
      Check := False;
      for L := 0 to gHands[fOwner].Units.Count - 1 do
        if not gHands[fOwner].Units[L].IsDeadOrDying AND (gHands[fOwner].Units[L] is TKMUnitWorker) then
          with gHands[fOwner].Units[L] do
            if (Task <> nil) AND (Task.TaskType = uttBuildHouse) AND (TKMTaskBuildHouse(Task).House = H) then
              Check := True;
      fFreeWorkersCnt := fFreeWorkersCnt - Byte(not Check);
    end;
  end;
  fFreeWorkersCnt := fFreeWorkersCnt * Byte(fFreeWorkersCnt > 0);
  SetLength(WorkersPos, fFreeWorkersCnt);

  // Sort buildNodes by priority and active state
  Sort(fBuildNodes[0], Low(fBuildNodes), High(fBuildNodes), sizeof(fBuildNodes[0]), CompareBuildNode);

  // Find closest build-node to each free worker and allow to expand it in next update + consider priority of node
  K := 0;
  L := 0;
  ClosestIdx := 0;
  while (fFreeWorkersCnt > 0) AND (K < Length(fBuildNodes)) AND (fBuildNodes[K].Active) do
  begin
    // Get best distance and assign worker
    while (fFreeWorkersCnt > 0) do
    begin
      ClosestDist := High(Integer);
      for L := K to High(fBuildNodes) do
        if (fBuildNodes[K].Priority = fBuildNodes[L].Priority) AND (fBuildNodes[L].Active) then
        begin
          if (fBuildNodes[L].RequiredWorkers > 0) then
          begin
            Dist := KMDistanceAbs(WorkersPos[fFreeWorkersCnt - 1], fBuildNodes[L].CenterPoint);
            if (Dist < ClosestDist) then
            begin
              ClosestDist := Dist;
              ClosestIdx := L;
            end;
          end;
        end
        else
          break;
      if (ClosestDist <> High(Integer)) then
      begin
        fFreeWorkersCnt := fFreeWorkersCnt - 1;
        with fBuildNodes[ClosestIdx] do
        begin
          RequiredWorkers := RequiredWorkers - 1;
          FreeWorkers := FreeWorkers + 1;
        end;
      end
      else
        break;
    end;
    K := L;
  end;

  //if (fFreeWorkersCnt > 0) then // Delete if?
    CreateShortcuts();

  // Update nodes
  ReqWorkerCnt := 0;
  for K := Low(fBuildNodes) to High(fBuildNodes) do
    if fBuildNodes[K].Active then
    begin
      UpdateBuildNode(fBuildNodes[K]);
      if fBuildNodes[K].Active then
        ReqWorkerCnt := ReqWorkerCnt + fBuildNodes[K].RequiredWorkers;
    end;
  if (gHands[fOwner].Stats.GetHouseQty(htAny) > 15) then
    fFreeWorkersCnt := Max(fFreeWorkersCnt, Byte(ReqWorkerCnt < 5));

  fWorkersPos := WorkersPos;
end;


procedure TKMCityBuilder.UpdateBuildNode(var aNode: TBuildNode);
  function IsPlan(aPoint: TKMPoint; aField: TKMFieldType): Boolean; overload;
  begin
    Result := gHands[fOwner].BuildList.FieldworksList.HasField(aPoint) = aField;
  end;
  function IsPlan(aPoint: TKMPoint; aLock: TKMTileLock): Boolean; overload;
  begin
    Result := gTerrain.Land[aPoint.Y, aPoint.X].TileLock = aLock;
  end;
  function IsPlan(aPoint: TKMPoint; aLock: TKMTileLock; aField: TKMFieldType): Boolean; overload;
  begin
    Result := IsPlan(aPoint, aField) OR IsPlan(aPoint, aLock);
  end;
  function IsCompletedRoad(aPoint: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsWalkableRoad(aPoint);
  end;
  function IsCompletedField(aPoint: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsCornField(aPoint);
  end;
  function IsCompletedWine(aPoint: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsWineField(aPoint);
  end;
  function IsRoad(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedRoad(aPoint) OR IsPlan(aPoint, tlRoadWork, ftRoad);
  end;
  function IsCornField(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedField(aPoint) OR IsPlan(aPoint, tlFieldWork, ftCorn);
  end;
  function IsWineField(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedWine(aPoint) OR IsPlan(aPoint, tlFieldWork, ftWine);
  end;

  function BuildField(aIdx: Integer; aFieldType: TKMFieldType): Boolean;
  var
    Output: Boolean;
  begin
    Output := False;
    if gHands[fOwner].CanAddFieldPlan(aNode.FieldList.Items[aIdx], aFieldType) then
    begin
      gHands[fOwner].BuildList.FieldworksList.AddField(aNode.FieldList.Items[aIdx], aFieldType);
      aNode.FreeWorkers := aNode.FreeWorkers - 1;
      aNode.RequiredWorkers := aNode.RequiredWorkers - 1;
      Output := True;
    end;
    Result := Output;
  end;

  // Build roads
  procedure BuildRoad();
  var
    K, ActiveWorkers: Integer;
  begin
    ActiveWorkers := 0;
    with aNode do
    begin
      // Remove elements of exist road from list
      for K := FieldList.Count - 1 downto 0 do
        if IsCompletedRoad(FieldList.Items[K]) then
        begin
          UnlockPointOfNode(FieldList.Items[K], True);
          FieldList.Delete(K);
        end
        else if not ShortcutMode then
          break;
      if (FieldList.Count = 0) then
      begin
        Active := False;
        Exit;
      end;
      // Build road / check road plans / replace missing parts / reconnect road when is no more possible to place plan
      RequiredWorkers := FieldList.Count;
      for K := FieldList.Count - 1 downto 0 do
      begin
        // Is there field / wine plan in progress?
        if IsPlan(FieldList.Items[K], ftWine) OR IsPlan(FieldList.Items[K], ftCorn) then
          gHands[fOwner].BuildList.FieldworksList.RemFieldPlan( FieldList.Items[K] );
        // Is there road plan / work in progress?
        if IsPlan(FieldList.Items[K], tlRoadWork, ftRoad) then
        begin
          ActiveWorkers := ActiveWorkers + 1;
          RequiredWorkers := RequiredWorkers - 1;
        end
        else if IsPlan(FieldList.Items[K], tlFieldWork) AND ( IsPlan(FieldList.Items[K], ftCorn) OR IsPlan(FieldList.Items[K], ftCorn) ) then
        begin
          // Wait for worker to finish the corn
        end
        // Is there completed road?
        else if IsCompletedRoad(FieldList.Items[K]) then
        begin
          RequiredWorkers := RequiredWorkers - 1;
          CenterPoint := FieldList.Items[K]; // Actualize center point (distribution of workers by distance)
        end
        // When cannot place new plan try find another way by calling pathfinding
        else
        begin
          // Does we have free workers? (this condition cannot be earlier because we need detection of ActiveWorkers)
          if (FreeWorkers <= 0) then
            break;
          if not BuildField(K, ftRoad) then
          begin
            if ShortcutMode then
            begin
              UnlockPointOfNode(FieldList.Items[K], True);
              FieldList.Delete(K);
            end
            else
            begin
              UnlockNode(aNode, True);
              // If is not possible to connect 2 points by road destroy node
              if not fPlanner.GetRoadBetweenPoints(CenterPoint, FieldList.Items[0], FieldList, FieldType) then
              begin
                FieldList.Clear;
                Active := False;
              end;
              LockNode(aNode);
              RequiredWorkers := Min(MaxReqWorkers, FieldList.Count);
              Exit; // Node will be updated in next calling
            end;
          end;
        end;
      end;
      // Restrict max required workers
      RequiredWorkers := Min(Max(0, MaxReqWorkers - ActiveWorkers), RequiredWorkers);
    end;
  end;

  // Build Wine or Corn fields
  procedure BuildFields();
  var
    K, ActiveWorkers: Integer;
  begin
    ActiveWorkers := 0;
    with aNode do
    begin
      RequiredWorkers := FieldList.Count;
      for K := 0 to FieldList.Count - 1 do
      begin
        // Check if field was replaced by road
        if (gAIFields.Influences.AvoidBuilding[FieldList.Items[K].Y, FieldList.Items[K].X] <> AVOID_BUILDING_NODE_LOCK_FIELD) then
        begin
          RequiredWorkers := RequiredWorkers - 1;
        end
        // Check if field already exists ...
        else if ((FieldType = ftWine) AND IsCompletedWine(FieldList.Items[K]))
             OR ((FieldType = ftCorn) AND IsCompletedField(FieldList.Items[K])) then
        begin
          RequiredWorkers := RequiredWorkers - 1;
        end
        else if ((FieldType = ftWine) AND IsPlan(FieldList.Items[K], tlFieldWork, ftWine))
             OR ((FieldType = ftCorn) AND IsPlan(FieldList.Items[K], tlFieldWork, ftCorn)) then
        begin
          ActiveWorkers := ActiveWorkers + 1;
          if (MaxReqWorkers <= ActiveWorkers) then
            break;
        end
        // ... else try build it
        else
        begin
          BuildField(K, FieldType);
          if (FreeWorkers <= 0) then
            break;
        end;
        // When node reached all plans disable it
        if (RequiredWorkers <= 0) OR (K = FieldList.Count-1) then
        begin
          // Only roads are unlocked
          //for K := 0 to FieldList.Count-1 do
          //  if   ((FieldType = ftWine) AND (IsCornField(FieldList.Items[K])))
          //    OR ((FieldType = ftCorn) AND (IsWineField(FieldList.Items[K]))) then
          //    UnlockPointOfNode(FieldList.Items[K]);
          FieldList.Clear;
          Active := False;
        end;
      end;
      // Restrict max required workers
      RequiredWorkers := Min(Max(0, MaxReqWorkers - ActiveWorkers), RequiredWorkers);
    end;
  end;

  // Remove trees or Wine / Corn fields which block placing house plan
  procedure RemoveObstaclesInPlan();
  var
    K: Integer;
  begin
    with aNode do
    begin
      if (FieldList.Count = 0) then
      begin
        Active := False;
        Exit;
      end;
      RequiredWorkers := FieldList.Count;
      for K := FieldList.Count - 1 downto 0 do
      begin
        //if (FreeWorkers <= 0) then // Ignore FreeWorkers distribution system
        //  Exit;
        // Detect obstacles in house plan
        if gTerrain.ObjectIsChopableTree(FieldList.Items[K], [caAge1,caAge2,caAge3,caAgeFull]) then
        begin
          // Check if is wine plan already placed
          if IsPlan(FieldList.Items[K], tlFieldWork, ftWine) then
          begin
            RequiredWorkers := RequiredWorkers - 1;
          end
          // If we cannot remove tree by placing wineyard remove point from list
          else if not BuildField(K, ftWine) then
            FieldList.Delete(K);
        end
        // If is plan blocked by fields which could be compensated by road do it
        else if IsCompletedWine(FieldList.Items[K]) OR IsCompletedField(FieldList.Items[K]) OR IsRoad(FieldList.Items[K]) then
        begin
          if IsCompletedRoad(FieldList.Items[K]) then
            FieldList.Delete(K) // Now can be item [K] deleted
          // Else try place road plan or delete point
          else if not IsPlan(FieldList.Items[K], tlRoadWork, ftRoad) then
          begin
            // Delete item [K] only in case that we cannot place road plan (point must be removed only in moment when is road completed)
            if not BuildField(K, ftRoad) then
              FieldList.Delete(K);
          end;
        end
        // Tree was destroyed while worker is going to do it -> remove wine or corn plan and remove point from build node
        else if (gHands[fOwner].BuildList.FieldworksList.HasField(FieldList.Items[K]) <> ftNone) then // ftNone is fine, road was checked before
        begin
          gHands[fOwner].BuildList.FieldworksList.RemFieldPlan(FieldList.Items[K]);
          FieldList.Delete(K);
        end
        // There is digged wine / field
        else if (gTerrain.Land[FieldList.Items[K].Y, FieldList.Items[K].X].TileLock = tlFieldWork) then
        begin
          // do nothing (wait till worker finish tile and place road
        end
        // Tree was destroyed for example by script
        else
        begin
          FieldList.Delete(K);
          RequiredWorkers := RequiredWorkers - 1;
        end;
      end;
      // Restrict max required workers
      RequiredWorkers := Min(MaxReqWorkers, RequiredWorkers);
    end;
  end;

begin
  // Build procedures are split because of quite complex algorithm (or can be merged into mess)
  if aNode.RemoveTreesMode then
    RemoveObstaclesInPlan()
  else
  begin
    case aNode.FieldType of
      ftRoad: BuildRoad();
      ftWine, ftCorn: BuildFields();
      else begin end;
    end;
  end;
end;


procedure TKMCityBuilder.CheckBasicMaterials(var aMaxPlans, aMaxPlace: Integer; var aTrunkBalance: Single; aTick: Cardinal);
var
  K, RequiredStones, RequiredWood, WoodReserves, Wood, Trunk: Integer;
  H: TKMHouse;
begin
  // Analyze basic force stats (max possible plans, construction ware, gold)
  aMaxPlans := Ceil(fFreeWorkersCnt / GA_BUILDER_ChHTB_FreeWorkerCoef);
  // Use "rapid construction" in case that we have resources
  if   (fPredictor.WareBalance[wtStone].Exhaustion > 60) then // Some stone mines are too far so AI must slow down with expansion
    //AND (fPredictor.WareBalance[wtWood].Exhaustion > 60)
    //AND (fPredictor.WareBalance[wtGold].Exhaustion > 60) then
    aMaxPlans := Max(aMaxPlans, Ceil(gHands[fOwner].Stats.GetUnitQty(utWorker) / GA_BUILDER_ChHTB_AllWorkerCoef) - fPlanner.ConstructedHouses);

  // Quarries have minimal delay + stones use only workers (towers after peace time) -> exhaustion for wtStone is OK
  fStoneShortage := (fPredictor.WareBalance[wtStone].Exhaustion < GA_BUILDER_Shortage_Stone);

  // Make sure that gold will be produced ASAP -> minimal delay, exhaustion is OK
  fGoldShortage := (fPredictor.WareBalance[wtGold].Exhaustion < GA_BUILDER_Shortage_Gold);

  // Woodcutters have huge delay (8 min) + trunk is used only to produce wood -> decide shortage based on actual consumption and reserves
  Trunk := gHands[fOwner].Stats.GetWareBalance(wtTrunk);
  Wood := gHands[fOwner].Stats.GetWareBalance(wtWood);
  WoodReserves := Trunk * 2 + Wood;
  aTrunkBalance := WoodReserves / (2 * Max(0.1, fPredictor.WareBalance[wtTrunk].ActualConsumption));
  fTrunkShortage := (aTrunkBalance < GA_BUILDER_Shortage_Trunk);

  // Compute building materials
  RequiredStones := gHands[fOwner].BuildList.HousePlanList.GetPlansStoneDemands();
  RequiredWood := gHands[fOwner].BuildList.HousePlanList.GetPlansWoodDemands();
  for K := 0 to gHands[fOwner].Houses.Count - 1 do
  begin
    H := gHands[fOwner].Houses[K];
    if (H <> nil) AND not H.IsDestroyed AND not H.IsComplete then
    begin
      RequiredStones := RequiredStones + gRes.Houses[H.HouseType].StoneCost - H.GetBuildStoneDelivered;
      RequiredWood := RequiredWood + gRes.Houses[H.HouseType].WoodCost - H.GetBuildWoodDelivered;
    end;
  end;
  // Compute road demands
  for K := Low(fBuildNodes) to High(fBuildNodes) do
    if fBuildNodes[K].Active AND (fBuildNodes[K].FieldType = ftRoad) then
      RequiredStones := RequiredStones + fBuildNodes[K].FieldList.Count - 1;
  // Determine stone crisis (based on material)
  fStoneCrisis := (fPlanner.PlannedHouses[htQuary].Completed < 3) AND (gHands[fOwner].Stats.GetWareBalance(wtStone) < RequiredStones + GA_BUILDER_Shortage_StoneReserve);
  fStoneShortage := fStoneShortage OR fStoneCrisis; // Make sure that we have also shortage
  // Determine wood shortage (based on material)
  fTrunkShortage := fTrunkShortage OR (WoodReserves < RequiredWood);
  aMaxPlace := Round((Wood // Available wood
                     + Min(Trunk * 2 , gHands[fOwner].Stats.GetHouseQty(htSawmill) * 4) // Trunk which can be turned into wood while the house is digged
                     - RequiredWood) / 3.5 // Consideration of required wood per a plan (approx 3.5)
               );

  // Secure wood production: only process trunk -> wood => minimal delay
  fWoodShortage :=
    (fPredictor.WareBalance[wtWood].Exhaustion < GA_BUILDER_Shortage_Wood)
    OR
    (
      (
        (fPredictor.RequiredHouses[htSawmill] > 0)
         OR
        (fPlanner.PlannedHouses[htSawmill].Planned > 0)
      )
      AND
      (RequiredWood > Wood)
      AND
      (RequiredWood < WoodReserves)
    );
end;


// Build house in standard game
// aIgnoreTrees: Boolean = allow remove trees in house plan mode
// aHouseReservation: Boolean = plan house plan and create reservation but dont place it (roads and fields will be constructed)
// aIgnoreExistingPlans: Boolean = planner will ignore existing plans and find new place for house (-> allow to plan multiple houses of 1 type)
// aHT: TKMHouseType = type of house
// Result: TConstructionState = state of construction
function TKMCityBuilder.BuildHouse(aIgnoreTrees, aHouseReservation, aIgnoreExistingPlans: Boolean; aHT: TKMHouseType; aRoadNodePrio: Byte = NODE_PRIO_Default): TConstructionState;
var
  Output: TConstructionState;
  FieldsComplete, Check: Boolean;
  K, Node1Idx, Node2Idx, HouseIdx: Integer;
  Loc: TKMPoint;
  {$IFDEF DEBUG_NewAI}
    Time: Cardinal;
  {$ENDIF}
begin
  Result := csNoNodeAvailable;
  FieldsComplete := False;
  // Find at least 2 non active build nodes
  Node1Idx := -1;
  Node2Idx := -1;
  for K := Low(fBuildNodes) to High(fBuildNodes) do
    if not fBuildNodes[K].Active then
      if (Node1Idx = -1) then
        Node1Idx := K
      else
      begin
        Node2Idx := K;
        break;
      end;

  // We need min 2 free nodes (1 for road and second for field or 1 for wine and second for road to remove trees in plan)
  if (Node1Idx = -1) OR (Node2Idx = -1) then
    Exit;

  Output := csNoPlaceCanBeFound;
  if fPlanner.GetHousePlan(aIgnoreTrees, aIgnoreExistingPlans, aHT, Loc, HouseIdx) then
  begin
    // Check if we can place house by default KaM function
    if gHands[fOwner].CanAddHousePlan(Loc, aHT) then
    begin

      // Update reservation status
      if fPlanner.PlannedHouses[aHT].Plans[HouseIdx].HouseReservation then
      begin
        Output := csHouseReservation; // House is already reserved -> no nodes will be updated and workers still have nothing to do so we can build another house
        if not aHouseReservation then
        begin
          fPlanner.PlannedHouses[aHT].Plans[HouseIdx].HouseReservation := False;
          FieldsComplete := True; // Fields was completed in reservation (only for farm and wine)
        end;
      end;

      // if house is not reserved (or will be reserved in this tick)
      if not fPlanner.PlannedHouses[aHT].Plans[HouseIdx].HouseReservation then
      begin
        Output := csHousePlaced; // Nodes will be updated -> workers will have something to do
        gHands[fOwner].AddHousePlan(aHT, Loc); // Place house
        // Add avoid building for Barracks and Store (road will be build later in shortcut procedure)
        if ((aHT = htStore) OR (aHT = htBarracks)) AND (Loc.Y+2 < gTerrain.MapY) then
          for K := Loc.X-1 to Loc.X+1 do
            gAIFields.Influences.AvoidBuilding[Loc.Y+2, K] := AVOID_BUILDING_HOUSE_ENTRANCE;
        // Add road to node
        {$IFDEF DEBUG_NewAI}
          Time := TimeGet();
        {$ENDIF}
        if fPlanner.GetRoadToHouse(aHT, HouseIdx, fBuildNodes[Node1Idx].FieldList, fBuildNodes[Node1Idx].FieldType)
           AND (fBuildNodes[Node1Idx].FieldList.Count > 0) then
        begin
          with fBuildNodes[Node1Idx] do
          begin
            LockNode(fBuildNodes[Node1Idx]);
            Active := True;
            Priority := aRoadNodePrio;
            RemoveTreesMode := False;
            ShortcutMode := False;
            MaxReqWorkers := Round(GA_BUILDER_BuildHouse_RoadMaxWork) + Byte(NODE_PRIO_RoadsUnlockHouse = aRoadNodePrio) * 20;
            RequiredWorkers := Min(MaxReqWorkers, FieldList.Count);
            CenterPoint := FieldList[ FieldList.Count-1 ]; // Road node must start from exist house
          end;
          // Add field to node (if is required [htFarm, htWineyard])
          if not FieldsComplete AND fPlanner.GetFieldToHouse(aHT, HouseIdx, fBuildNodes[Node2Idx].FieldList, fBuildNodes[Node2Idx].FieldType) then
          begin
            LockNode(fBuildNodes[Node2Idx]);
            with fBuildNodes[Node2Idx] do
            begin
              Active := True;
              Priority := Byte(aHouseReservation) * NODE_PRIO_FieldsReservation + Byte(not aHouseReservation) * NODE_PRIO_Fields;
              RemoveTreesMode := False;
              ShortcutMode := False;
              MaxReqWorkers := Round(GA_BUILDER_BuildHouse_FieldMaxWork);
              RequiredWorkers := Min(MaxReqWorkers, FieldList.Count);
              CenterPoint := Loc;
            end;
          end;
        end
        else
        begin
          gHands[fOwner].RemHousePlan(Loc);
          {$IFDEF DEBUG_NewAI}
            fTimePlanRoads := fTimePlanRoads + TimeGet() - Time;
          {$ENDIF}
          Exit;
        end;
        {$IFDEF DEBUG_NewAI}
          fTimePlanRoads := fTimePlanRoads + TimeGet() - Time;
        {$ENDIF}
        // Reserve house place
        if aHouseReservation then
        begin
          fPlanner.PlannedHouses[aHT].Plans[HouseIdx].HouseReservation := True;
          gHands[fOwner].RemHousePlan(Loc);
        end
        else
          with fPlanner.PlannedHouses[aHT].Plans[HouseIdx] do
          begin
            HouseReservation := False;
            RemoveTreeInPlanProcedure := False;
            Placed := True;
          end;
      end;
    end
    else if gAIFields.Eye.CanPlaceHouse(Loc, aHT, True) then
    begin
      Output := csRemoveTreeProcedure; // Remove tree procedure does not require significant count of workers so there is not need for separate mark
      // Remove tree procedure is already active
      Check := False;
      // Wait till is tree removed and check if there exist node with remove tree mode
      if (fPlanner.PlannedHouses[aHT].Plans[HouseIdx].RemoveTreeInPlanProcedure) then
        for K := Low(fBuildNodes) to High(fBuildNodes) do
          if fBuildNodes[K].Active AND fBuildNodes[K].RemoveTreesMode then
          begin
            Check := True;
            break;
          end;
      // House plan cannot be placed because of existing tree -> remove it by placing wine and road at specific tiles
      if not Check then
      begin
        if (fPlanner.GetTreesInHousePlan(aHT, HouseIdx, fBuildNodes[Node1Idx].FieldList) > 0) then
        begin
          fPlanner.PlannedHouses[aHT].Plans[HouseIdx].RemoveTreeInPlanProcedure := True;
          for K := Low(fBuildNodes) to High(fBuildNodes) do
            if fBuildNodes[K].Active
              AND fBuildNodes[K].RemoveTreesMode
              AND (fBuildNodes[K].FieldList.Count > 0)
              AND KMSamePoint(fBuildNodes[Node1Idx].FieldList.Items[0], fBuildNodes[K].FieldList.Items[0]) then
            begin
              fBuildNodes[Node1Idx].FieldList.Clear;
              Exit;
            end;
          with fBuildNodes[Node1Idx] do
          begin
            Active := True;
            Priority := NODE_PRIO_RemoveTreeInPlan;
            RemoveTreesMode := True;
            ShortcutMode := False;
            MaxReqWorkers := Round(GA_BUILDER_BuildHouse_RTPMaxWork);
            RequiredWorkers := Min(MaxReqWorkers, FieldList.Count); // Real count will be updated during building process
            CenterPoint := Loc;
          end;
        end
        // There is another problem...
        else
          Planner.RemovePlan(aHT, Loc);
      end;
    end
    else
    begin
      // Plan cannot be placed - maybe because of terrain changes -> find build node with remove tree procedure and check if is active
      for K := Low(fBuildNodes) to High(fBuildNodes) do
        if fBuildNodes[K].Active AND fBuildNodes[K].RemoveTreesMode AND KMSamePoint(Loc,fBuildNodes[K].CenterPoint) then
        begin
          Output := csRemoveTreeProcedure; // Remove tree procedure is active
          break;
        end;
      if (Output = csNoPlaceCanBeFound) then // Remove tree procedure is not active plan cannot be placed
        Planner.RemovePlan(aHT, Loc);
    end;
  end
  else
  begin
    Output := csNoPlaceCanBeFound;
  end;
  Result := Output;
end;


procedure TKMCityBuilder.ChooseHousesToBuild(aTick: Cardinal);
type
  TSetOfWare = set of TKMWareType;
  TSetOfHouseType = set of TKMHouseType;
const

  //htWoodcutters,    htQuary,         htSawmill,        htIronMine,      htGoldMine,
  //htCoalMine,       htIronSmithy,    htMetallurgists,  htWineyard,      htFarm,
  //htBakery,         htMill,          htTannery,        htButchers,      htSwine,
  //htSwine,          htArmorWorkshop, htArmorSmithy,    htArmorWorkshop, htArmorSmithy,
  //htWeaponWorkshop, htWeaponSmithy,  htWeaponWorkshop, htWeaponSmithy,  htWeaponWorkshop,
  //htWeaponSmithy,   htStables,       htFisherHut


  BASIC_HOUSES: TSetOfHouseType = [htSchool, htBarracks, htInn, htMarketplace, htStore];
  //BUILD_WARE: TSetOfWare = [wtGoldOre, wtCoal, wtGold, wtStone, wtTrunk, wtWood];
  //FOOD_WARE: TSetOfWare = [wtCorn, wtFlour, wtBread, wtPig, wtSausages, wtWine, wtFish, wtWood];
  //WEAPON_WARE: TSetOfWare = [wtSkin, wtLeather, wtHorse, wtIronOre, wtCoal, wtSteel, wtAxe, wtBow, wtPike, wtArmor, wtShield, wtSword, wtArbalet, wtHallebard, wtMetalShield, wtMetalArmor];
  // All considerable ware (from weapons / armors just 1 piece of ware type because it is produced in same house)
  ALL_WARE: TSetOfWare = [wtCorn, wtPig, wtSausages, wtWine, wtFish, wtStone, wtTrunk, wtWood, wtSkin, wtLeather, wtHorse, wtIronOre, wtCoal, wtSteel, wtAxe, wtArmor, wtSword, wtMetalArmor, wtFlour, wtBread];
  //BUILD_ORDER_WARE: array[0..8] of TKMWareType = (wtStone, wtGold, wtGoldOre, wtCoal, wtTrunk, wtWood, wtCorn, wtPig, wtSausages);
  BUILD_ORDER_WARE: array[0..5] of TKMWareType = (wtStone, wtGoldOre, wtCoal, wtGold, wtTrunk, wtWood);
var
  MaxPlans, MaxPlace: Integer;
  RequiredHouses: TRequiredHousesArray;


  function TryUnlockByRnd(var aHT: TKMHouseType): Boolean;
  const
    FORBIDDEN_HOUSES = [htIronMine, htGoldMine, htCoalMine, htWineyard, htStables, htFisherHut, htTownHall, htSiegeWorkshop, htIronSmithy, htArmorSmithy, htWeaponSmithy];
  var
    HT: TKMHouseType;
  begin
    Result := False;
    for HT := HOUSE_MIN to HOUSE_MAX do
      if not gHands[fOwner].Locks.HouseBlocked[HT]
        AND gHands[fOwner].Locks.HouseCanBuild(HT)
        AND (gHands[fOwner].Stats.GetHouseTotal(HT) = 0)
        AND not (HT in FORBIDDEN_HOUSES) then
      begin
        aHT := HT;
        Result := True;
        Exit;
      end;
  end;

  function GetHousesToUnlock(aHT: TKMHouseType; var aHTArr: TKMHouseTypeArray): Boolean;
  begin
    Result := True;
    // Repeat until it finds an available house (to unlock target house)
    SetLength(aHTArr,1);
    aHTArr[ High(aHTArr) ] := aHT;
    while not gHands[fOwner].Locks.HouseCanBuild(aHT) do
    begin
      if gHands[fOwner].Locks.HouseBlocked[aHT] then // House is blocked -> unlock is impossible
      begin
        // Try to guess old unlock order
        if (aHT = htQuary) AND not gHands[fOwner].Locks.HouseBlocked[htSchool] then
        begin
          if (fPlanner.PlannedHouses[htSchool].Completed > 0) then
            SetLength(aHTArr, 2)
          else
          begin
            SetLength(aHTArr, 3);
            aHTArr[2] := htSchool;
          end;
          aHTArr[1] := htInn;
          Exit(True);
        end;
        Exit(False);
      end;
      aHT := gRes.Houses[aHT].ReleasedBy; // House have to be unlocked by this house
      SetLength(aHTArr, Length(aHTArr)+1 ); // Just few interaction
      aHTArr[ High(aHTArr) ] := aHT;
    end;
  end;


  function AddToConstruction(aHT: TKMHouseType; aUnlockProcedureAllowed: Boolean = False; aIgnoreWareReserves: Boolean = False): TConstructionState;
  var
    IgnoreTreesInPlan, HouseReservation, IgnoreExistingPlans, MaterialShortage: Boolean;
    NodePrio: Byte;
    K: Integer;
    HTArr: TKMHouseTypeArray;
  begin
    Result := csCannotPlaceHouse;
    if fStoneCrisis AND not (aHT in [htQuary, htSchool, htInn]) then
      Exit;
    // Check if AI can build house (if is house blocked [by script] ignore it)
    if GetHousesToUnlock(aHT, HTArr) AND ((aUnlockProcedureAllowed) OR (Length(HTArr) = 1)) then
    begin
      MaterialShortage := (MaxPlace <= 0) OR (not aIgnoreWareReserves AND (fWoodShortage OR fTrunkShortage OR fStoneShortage OR fGoldShortage));
      IgnoreTreesInPlan := not ((Length(HTArr) > 1) OR MaterialShortage);
      for K := Low(HTArr) to High(HTArr) do
        if (K <> High(HTArr)) OR (Length(HTArr) = 1) OR (fPlanner.PlannedHouses[ HTArr[K] ].Count = 0) then
        begin
          HouseReservation := MaterialShortage OR (K <> High(HTArr));
          IgnoreExistingPlans := (Length(HTArr) = 1) AND MaterialShortage AND not (aHT in [htWoodcutters, htGoldMine, htIronMine, htCoalMine]);
          if (K <> High(HTArr)) then
            NodePrio := NODE_PRIO_RoadsReservation // House is blocked, prio is low
          else if (Length(HTArr) = 1) then
            NodePrio := NODE_PRIO_Roads // House is unlocked, prio is high
          else
            NodePrio := NODE_PRIO_RoadsUnlockHouse; // House is unlocked and its construction will unlock another house, prio is TOP
          Result := BuildHouse(IgnoreTreesInPlan, HouseReservation, IgnoreExistingPlans, HTArr[K], NodePrio);
          RequiredHouses[ HTArr[K] ] := 0;
        end;
    end
    else if aUnlockProcedureAllowed AND TryUnlockByRnd(aHT) then // There is scripted unlock order -> try to place random house (it works 100% for any crazy combinations which will scripters bring)
    begin
      Result := BuildHouse(False, False, False, aHT);
      RequiredHouses[aHT] := 0;
    end;
  end;


  function SelectHouse(const aSetOfWare: TSetOfWare): Boolean;
  const
    FRACTION_COEF = 20.0;
  var
    Output: Boolean;
    K: Integer;
    Priority: Single;
    HT: TKMHouseType;
    Ware, WT, POM_WT: TKMWareType;
    WareOrder: array[0..10] of TKMWareType;
    WarePriority: array[0..10] of Single;
  begin
    Output := False;
    // Basic producing houses (secure resources for building)
    for K := Low(WareOrder) to High(WareOrder) do
    begin
      WareOrder[K] := wtNone;
      WarePriority[K] := 1000000; // Doesn't have to be initialized but in this case compilation throws warning
    end;
    // Find the most required house to be build
    for Ware in aSetOfWare do
    begin
      WT := Ware;
      if (RequiredHouses[ PRODUCTION_WARE2HOUSE[WT] ] > 0) then
      begin
        Priority := fPredictor.WareBalance[WT].Exhaustion - fPredictor.WareBalance[WT].Fraction * GA_BUILDER_ChHTB_FractionCoef
                    - Byte(PRODUCTION_WARE2HOUSE[WT] = htBakery) * 1000;
        for K := Low(WareOrder) to High(WareOrder) do
          if (WT = wtNone) then
            break
          else if (WareOrder[K] = wtNone) OR (Priority < WarePriority[K]) then // Buble sort is best for few elements
          begin
            POM_WT := WT;
            WT := WareOrder[K];
            WareOrder[K] := POM_WT;
            SwapFloat(Priority, WarePriority[K]);
          end;
      end;
    end;
    // Try build required houses
    for K := Low(WareOrder) to High(WareOrder) do
    begin
      if (WareOrder[K] = wtNone) then
        break;
      HT := PRODUCTION_WARE2HOUSE[ WareOrder[K] ];
      if (RequiredHouses[HT] <= 0) then // wtLeather and wtPig require the same building so avoid to place 2 houses at once
        continue;
      // Farms and wineyards should be placed ASAP because fields may change evaluation of terrain and change tpBuild status of surrouding tiles!
      case AddToConstruction(HT, HT in [htFarm, htWineyard], False) of
        csNoNodeAvailable: break;
        csHouseReservation, csRemoveTreeProcedure: Output := True;
        csHousePlaced:
        begin
          Output := True;
          MaxPlans := MaxPlans - 1;
          MaxPlace := MaxPlace - 1;
          if (MaxPlans <= 0) then
            break;
        end;
        csNoPlaceCanBeFound:
        begin
          if (HT in [htIronMine, htGoldMine, htCoalMine]) then
            fPredictor.MarkExhaustedMine(HT);
        end
        //csCannotPlaceHouse:
        else
          begin

          end;
      end;
      RequiredHouses[HT] := 0; // Make sure that next node will not scan this house in this tick
    end;
    Result := Output;
  end;

  procedure SelectHouseBySetOrder();
  var
    AllowStoneReservation: Boolean;
    WT: TKMWareType;
    HT: TKMHouseType;
  begin
    // Find the most required house to be build - use specific order
    for WT in BUILD_ORDER_WARE do
    begin
      HT := PRODUCTION_WARE2HOUSE[WT];
      if (RequiredHouses[HT] > 0) AND (fPredictor.WareBalance[WT].Exhaustion < 30) then
      begin
        // Make sure that next cycle will not scan this house in this tick
        RequiredHouses[HT] := 0;

        AllowStoneReservation := not fStoneShortage OR ( (WT = wtStone) AND (fPlanner.PlannedHouses[htSchool].Completed = 0) );
        // Try build required houses
        case AddToConstruction(HT, AllowStoneReservation, AllowStoneReservation) of
          csHousePlaced:
            begin
              MaxPlans := 0; // This house is critical so dont plan anything else
              Exit;
            end;
          csNoPlaceCanBeFound:
            begin
              if (HT in [htIronMine, htGoldMine, htCoalMine]) then
                fPredictor.MarkExhaustedMine(HT);
            end
        end;
      end;
    end;
  end;

  procedure CheckHouseReservation();
  const
    // Reservation sets must be able to unlock specific houses!!!
    RESERVATION_FullSet: array[0..28] of TKMHouseType = (
      htSchool, htInn, htQuary, htMarketplace, htWoodcutters, htSawmill, // Inn because of old unlock order
      htGoldMine, htCoalMine, htMetallurgists, htBarracks,
      htFarm, htMill, htBakery, htSwine, htButchers, htStables, htFisherHut,
      htIronMine, htIronSmithy, htArmorSmithy, htWeaponSmithy,
      htTannery, htArmorWorkshop, htWeaponWorkshop,
      htSiegeWorkshop, htTownHall, htWineyard, htStore, htWatchTower
    );
    // If RESERVATION_FullSet was changed, then the following indexes must be changed too!
    STONE_SHORTAGE_IDX = 2;
    TRUNK_SHORTAGE_IDX = 4;
    WOOD_SHORTAGE_IDX = 8;
    GOLD_SHORTAGE_IDX = 8;
    FULL_SET = 28;
  var
    K,L, MinIdx, MaxIdx, Overflow: Integer;
    Gain, BestGain: Single;
    HT, BestHT: TKMHouseType;
    ReservationsCntArr: array[HOUSE_MIN..HOUSE_MAX] of Word;
  begin
    MinIdx := 0;
    FillChar(ReservationsCntArr, SizeOf(ReservationsCntArr), #0);
    if fStoneShortage then
      MaxIdx := STONE_SHORTAGE_IDX
    else if fWoodShortage then
    begin
      MaxIdx := WOOD_SHORTAGE_IDX;
      if (fPlanner.PlannedHouses[htSawmill].Completed = 0) then
        MinIdx := TRUNK_SHORTAGE_IDX+1;
    end
    else if fTrunkShortage AND (MaxPlace < 3) then // Allow to place something if MaxPlace is higher
      MaxIdx := TRUNK_SHORTAGE_IDX
    else if fGoldShortage then
      MaxIdx := GOLD_SHORTAGE_IDX
    else
      MaxIdx := FULL_SET;

    for K := MinIdx to MaxIdx do
    begin
      HT := RESERVATION_FullSet[K];
      for L := 0 to fPlanner.PlannedHouses[HT].Count - 1 do
        with fPlanner.PlannedHouses[HT].Plans[L] do
          if not Placed AND (HouseReservation OR RemoveTreeInPlanProcedure) then
            Inc(ReservationsCntArr[HT], 1);
    end;

    Overflow := 0;
    while (MaxPlace > 0) AND (Overflow <= MaxIdx) do
    begin
      Overflow := Overflow + 1;
      BestHT := htNone;
      BestGain := -1e10;
      for K := MinIdx to MaxIdx do
        if (ReservationsCntArr[ RESERVATION_FullSet[K] ] > 0) then
        begin
          HT := RESERVATION_FullSet[K];
          // Build first house with highest prio
          //if (K <= GOLD_SHORTAGE_IDX) AND (fPlanner.PlannedHouses[HT].Completed = 0) AND (fPlanner.PlannedHouses[HT].UnderConstruction = 0) then
          if (fPlanner.PlannedHouses[HT].Completed = 0) AND (fPlanner.PlannedHouses[HT].UnderConstruction = 0) then
          begin
            BestHT := HT;
            break;
          end;
          // Otherwise ignore houses
          Gain := ReservationsCntArr[HT] * 2 - K;
          if (Gain > BestGain) then
          begin
            BestHT := HT;
            BestGain := Gain;
          end;
        end;
      if (BestHT = htNone) then
        Exit;
      if (csHousePlaced = AddToConstruction(BestHT,False,True)) then
      begin
        MaxPlace := MaxPlace - 1;
        RequiredHouses[BestHT] := 0;
      end;
      ReservationsCntArr[BestHT] := 0; // Dont place more than 1 reserved house type in 1 tick
    end;
  end;

  function GetChopOnlyCnt(): Word;
  var
    K: Integer;
  begin
    Result := 0;
    for K := 0 to fPlanner.PlannedHouses[htWoodcutters].Count - 1 do
      if fPlanner.PlannedHouses[htWoodcutters].Plans[K].ChopOnly then
        Result := Result + 1;
  end;

const
  BUILD_TOWER_DELAY = 17 * 60 * 10; // 17 minutes before end of peace
  MINIMAL_TOWER_DELAY = 50 * 60 * 10; // Towers will not be build before 50 minute
var
  TrunkBalance: Single;
  HT: TKMHouseType;
begin
  // Get shortage info
  CheckBasicMaterials(MaxPlans, MaxPlace, TrunkBalance, aTick);

  RequiredHouses := fPredictor.RequiredHouses;

  // Dont build more than 3 quarry at once if there is not quarry and stone shortage is possible
  RequiredHouses[htQuary] := RequiredHouses[htQuary] * Byte(not (fStoneShortage AND (fPlanner.PlannedHouses[htQuary].Completed < 3) AND (fPlanner.PlannedHouses[htQuary].UnderConstruction > 2)));
  if fStoneShortage AND (RequiredHouses[htQuary] > 0) AND (fPlanner.PlannedHouses[htSchool].Completed > 0) then
  begin
    RequiredHouses[htQuary] := 0;
    if (AddToConstruction(htQuary, True, True) = csHousePlaced) then
      MaxPlans := MaxPlans - 1;
  end;

  // Dont try to place wine if we are out of wood
  RequiredHouses[htWineyard] := RequiredHouses[htWineyard] * Byte(not(fTrunkShortage OR (MaxPlace < 3)));

  // Find place for chop-only woodcutters when we start to be out of wood
  if ((GA_BUILDER_ChHTB_TrunkBalance - TrunkBalance) / GA_BUILDER_ChHTB_TrunkFactor - GetChopOnlyCnt() > 0) then
    fPlanner.FindForestAround(KMPOINT_ZERO, True);

  // Build woodcutter when is forest near new house (or when is woodcutter destroyed but this is not primarly intended)
  HT := htWoodcutters;
  if (gHands[fOwner].Stats.GetHouseTotal(HT) < fPlanner.PlannedHouses[HT].Count)
    AND not fStoneShortage
    AND ((fTrunkShortage OR not fGoldShortage) AND not fWoodShortage)
    AND (AddToConstruction(HT, True, True) = csHousePlaced) then
  begin
    MaxPlans := MaxPlans - 1;
    RequiredHouses[htWoodcutters] := 0;
  end;

  if (MaxPlace > 0) then
    CheckHouseReservation();
  if (MaxPlans <= 0) then
    Exit;

  // Basic houses (for city management)
  for HT in BASIC_HOUSES do
    if (RequiredHouses[HT] > 0) AND (AddToConstruction(HT, True, True) = csHousePlaced) then
    begin
      MaxPlans := MaxPlans - 1;
      if (MaxPlans <= 0) then
        Exit;
    end;

  // The most important houses for city production which will be soon depleted
  SelectHouseBySetOrder();
  if (MaxPlans <= 0) then
    Exit;

  // Watchtowers
  HT := htWatchTower;
  if (not Planner.DefenceTowersPlanned OR (gHands[fOwner].Stats.GetHouseTotal(HT) < Planner.PlannedHouses[HT].Count))
    AND (aTick + BUILD_TOWER_DELAY > gGame.GameOptions.Peacetime * 600)
    AND (aTick > MINIMAL_TOWER_DELAY)
    AND (AddToConstruction(HT, True, True) = csHousePlaced) then
    begin
      MaxPlans := MaxPlans - 1;
      if (MaxPlans <= 0) then
        Exit;
    end;

  // All other houses (food and weapon production) + houses which will be required in final city size
  SelectHouse(ALL_WARE);
end;




procedure TKMCityBuilder.CreateShortcuts();
const
  MAX_SHORTCUTS_PER_HOUSE_TYPE = 2;
  MAX_DISTANCE_TO_ALL_HOUSES = 10;
  MAX_WORKERS_FOR_NODE = 4;
  HOUSE_CONNECTION: array[HOUSE_MIN..HOUSE_MAX] of set of TKMHouseType = (
    {htArmorSmithy}    [ htIronSmithy,    htCoalMine,     htBarracks     ],
    {htArmorWorkshop}  [ htTannery,       htBarracks                     ],
    {htBakery}         [ htInn,           htStore,        htMill         ],
    {htBarracks}       [ htSchool                                        ],
    {htButchers}       [ htInn,           htStore,        htSwine        ],
    {htCoalMine}       [ htNone                                          ],
    {htFarm}           [ htNone                                          ],
    {htFisherHut}      [ htNone                                          ],
    {htGoldMine}       [ htMetallurgists                                 ],
    {htInn}            [ htStore,         htInn                          ],
    {htIronMine}       [ htIronSmithy                                    ],
    {htIronSmithy}     [ htCoalMine,      htWeaponSmithy, htArmorSmithy  ],
    {htMarketplace}    [ htStore                                         ],
    {htMetallurgists}  [ htSchool,        htGoldMine,     htCoalMine     ],
    {htMill}           [ htFarm,          htBakery                       ],
    {htQuary}          [ htStore                                         ],
    {htSawmill}        [ htArmorWorkshop, htStore                        ],
    {htSchool}         [ htMetallurgists, htStore,        htBarracks     ],
    {htSiegeWorkshop}  [ htIronSmithy,    htSawmill,      htStore        ],
    {htStables}        [ htFarm,          htBarracks                     ],
    {htStore}          [ htInn,           htBarracks,     htSchool       ],
    {htSwine}          [ htFarm,          htButchers                     ],
    {htTannery}        [ htArmorWorkshop, htSwine                        ],
    {htTownHall}       [ htMetallurgists, htStore                        ],
    {htWatchTower}     [ htNone                                          ],
    {htWeaponSmithy}   [ htIronSmithy,    htCoalMine,     htBarracks     ],
    {htWeaponWorkshop} [ htSawmill,       htBarracks                     ],
    {htWineyard}       [ htInn                                           ],
    {htWoodcutters}    [ htNone                                          ]
  );

  function FindAndMarkNewHouse(var aHT: TKMHouseType; var aLoc: TKMPoint): Boolean;
  var
    K: Integer;
    HT: TKMHouseType;
  begin
    Result := True;
    for HT := Low(fPlanner.PlannedHouses) to High(fPlanner.PlannedHouses) do
    begin
      if (HT = htWoodcutters) then
        continue;
      with fPlanner.PlannedHouses[HT] do
        for K := 0 to Count - 1 do
          if Plans[K].Placed AND not Plans[K].ShortcutsCompleted then
          begin
            Plans[K].ShortcutsCompleted := True;
            aLoc := KMPointBelow(Plans[K].Loc);
            aHT := HT;
            Exit;
          end;
    end;
    Result := False;
  end;

  // Plan road from aBaseLoc to points in aLocs
  procedure PlanRoad(var aNode: TBuildNode; aBaseLoc: TKMPoint; var aLocs: TKMPointTagList; aAllLocs: Boolean = False);
  var
    K, L, cnt: Integer;
    Road: TKMPointList;
  begin
    if (aLocs.Count > 0) then
    begin
      if not aAllLocs then // Sort in case that we want to pick just the closest points
        aLocs.SortByTag();
      Road := TKMPointList.Create();
      try
        cnt := 0;
        for K := 0 to aLocs.Count-1 do
        begin
          Road.Clear();
          // Plan road
          if fPlanner.GetRoadBetweenPoints(aLocs.Items[K], aBaseLoc, Road, aNode.FieldType) then
          begin
            // Copy new road to build node (1 node will have all roads -> shortcuts will not take
            for L := 0 to Road.Count - 1 do
              aNode.FieldList.Add(Road.Items[L]);
            cnt := cnt + 1;
            LockNode(aNode); // Lock must be here because next shortcut will see road reservation -> avoid to build 2 road next to each other
            if not aAllLocs AND (cnt = MAX_SHORTCUTS_PER_HOUSE_TYPE) then
              break;
          end;
        end;
      finally
        Road.Free;
      end;
      with aNode do
        if (FieldList.Count > 0) then
        begin
          Active := True;
          Priority := NODE_PRIO_Shortcuts;
          RemoveTreesMode := False;
          ShortcutMode := True;
          MaxReqWorkers := Round(GA_BUILDER_CreateShortcuts_MaxWork);//MAX_WORKERS_FOR_NODE;
          RequiredWorkers := Min(MaxReqWorkers, FieldList.Count);
          CenterPoint := FieldList.Items[0];
        end;
    end;
  end;

var
  K,L,NodeIdx, Dist: Integer;
  HT, BaseHT: TKMHouseType;
  BaseLoc: TKMPoint;
  PlannedHouses: TPlannedHousesArray;
  Locs: TKMPointTagList;
begin
  // Don't build shortcuts with low Exhaustion
  if   (fPredictor.WareBalance[wtStone].Exhaustion < 60)
    //OR (fPredictor.WareBalance[wtWood].Exhaustion < 60)
    OR (fPredictor.WareBalance[wtGold].Exhaustion < 60)
    OR (gHands[fOwner].Stats.GetHouseQty(htSchool) = 0)
    OR (gHands[fOwner].Stats.GetUnitQty(utWorker) = 0) then
    Exit;

  // Check if there is free build node
  for NodeIdx := Low(fBuildNodes) to High(fBuildNodes) do
    if not fBuildNodes[NodeIdx].Active then
      Break;
  if fBuildNodes[ Min(High(fBuildNodes),NodeIdx) ].Active then
    Exit;

  // Find house which was not checked for shortcuts
  if not FindAndMarkNewHouse(BaseHT, BaseLoc) then
    Exit;

  // Special case for entrance of Store and Barrack
  if (BaseHT = htStore) OR (BaseHT = htBarracks) then
    if (BaseLoc.Y < gTerrain.MapY - 1) then
      for K := BaseLoc.X-1 to BaseLoc.X+1 do
      begin
        gAIFields.Influences.AvoidBuilding[BaseLoc.Y+1, K] := 255;
        if gHands[fOwner].CanAddFieldPlan(KMPoint(K, BaseLoc.Y+1) , ftRoad) then
          gHands[fOwner].BuildList.FieldworksList.AddField(KMPoint(K, BaseLoc.Y+1) , ftRoad);
      end;

  // Find houses which should be connected
  PlannedHouses := fPlanner.PlannedHouses;
  Locs := TKMPointTagList.Create();
  HT := htNone; // For compiler
  try
    // Create basic connection to houses which are part of specific distribution network
    for HT in HOUSE_CONNECTION[BaseHT] do
    begin
      if (HT = htNone) then
        break;

      Locs.Clear();
      for L := 0 to PlannedHouses[HT].Count - 1 do
        with PlannedHouses[HT].Plans[L] do
          if Placed then
            Locs.Add( KMPointBelow(Loc), KMDistanceAbs(Loc, BaseLoc) );
      PlanRoad(fBuildNodes[NodeIdx], BaseLoc, Locs, False);
    end;

    // Create additional shortcuts to closest houses
    Locs.Clear();
    if (HT <> htNone) then
      for HT := Low(PlannedHouses) to High(PlannedHouses) do
      begin
        if (HT = htWoodcutters) then
          continue;
        for K := 0 to PlannedHouses[HT].Count - 1 do
          with PlannedHouses[HT].Plans[K] do
            if Placed then
            begin
              Dist := KMDistanceAbs(BaseLoc, KMPointBelow(Loc));
              if (Dist <> 0) AND (Dist < MAX_DISTANCE_TO_ALL_HOUSES) then
                Locs.Add( KMPointBelow(Loc), Dist );
            end;
      end;
    PlanRoad(fBuildNodes[NodeIdx], BaseLoc, Locs, True);
  finally
    Locs.Free;
  end;
end;


procedure TKMCityBuilder.LogStatus(var aBalanceText: UnicodeString);
const
  COLOR_WHITE = '[$FFFFFF]';
  COLOR_RED = '[$0000FF]';
  COLOR_YELLOW = '[$00FFFF]';
  COLOR_GREEN = '[$00FF00]';
var
  K, cnt, Reservation, RemoveTrees, PlanPlaced, Construction: Integer;
  HT: TKMHouseType;
  Text: String;
begin
  // Construction
  aBalanceText := aBalanceText + '|Construction: ';
  cnt := 1;
  for HT := Low(fPlanner.PlannedHouses) to High(fPlanner.PlannedHouses) do
  begin
    Reservation := 0;
    RemoveTrees := 0;
    PlanPlaced := 0;
    Construction := 0;
    for K := 0 to fPlanner.PlannedHouses[HT].Count - 1 do
      with fPlanner.PlannedHouses[HT].Plans[K] do
      begin
        if not Placed then
        begin
          Inc(Reservation, Byte(HouseReservation));
          Inc(Reservation, Byte(RemoveTreeInPlanProcedure));
          Inc(Reservation, Byte(not HouseReservation AND not RemoveTreeInPlanProcedure));
        end
        else if (House <> nil) AND not (House.IsComplete) then
          Inc(Construction,1);
      end;
    if ((Reservation + RemoveTrees + PlanPlaced + Construction) > 0) then
    begin
      Cnt := (Cnt + 1) mod 6;
      if (Cnt = 0) then
        aBalanceText := aBalanceText + '|';
      Text := '';
      if (Reservation  > 0) then Text := Format('%s%dx Reservation ' ,[Text, Reservation]);
      if (RemoveTrees  > 0) then Text := Format('%s%dx RemoveTrees ' ,[Text, RemoveTrees]);
      if (PlanPlaced   > 0) then Text := Format('%s%dx PlanPlaced '  ,[Text, PlanPlaced]);
      if (Construction > 0) then Text := Format('%s%dx Construction ',[Text, Construction]);
      aBalanceText := Format( '%s %s (%s),', [aBalanceText, gRes.Houses[HT].HouseName, Text.SubString(0,Length(Text)-1)] );
    end;
  end;
  // Active nodes
  cnt := 0;
  for K := Low(fBuildNodes) to High(fBuildNodes) do
    Inc(cnt, Byte(fBuildNodes[K].Active));
  aBalanceText := Format('%s|Active nodes: %d',[aBalanceText,cnt]);
  // Material shortage
  Text := '';
  if fStoneShortage then Text := Text + ' Stone,';
  if fTrunkShortage then Text := Text + ' Trunk,';
  if fWoodShortage  then Text := Text + ' Wood,';
  if fGoldShortage  then Text := Text + ' Gold,';
  if (Length(Text) > 0) then
    aBalanceText := Format('%s|Shortage:%s%s[]',[aBalanceText,COLOR_RED,Text.SubString(0,Length(Text)-1)]);
  {$IFDEF DEBUG_NewAI}
    aBalanceText := Format('%s|Time Plan Roads: %d',[aBalanceText,fTimePlanRoads]);
  {$ENDIF}
  // Planner
  fPlanner.LogStatus(aBalanceText);
end;


procedure TKMCityBuilder.Paint();
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $0000FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
  COLOR_NEW = $FFFF00;
  COLOR_NEW2 = $FF00FF;
var
  K,L: Integer;
  Color: Cardinal;
  Point: TKMPoint;
begin
//{
  for K := 0 to gHands[fOwner].Units.Count - 1 do
    with gHands[fOwner].Units[K] do
      if not IsDeadOrDying then
      begin
        if (gHands[fOwner].Units[K] is TKMUnitSerf) AND IsIdle then
          gRenderAux.Quad(CurrPosition.X, CurrPosition.Y, $44000000 OR COLOR_BLUE)
        else if (gHands[fOwner].Units[K] is TKMUnitWorker) AND IsIdle then
          gRenderAux.Quad(CurrPosition.X, CurrPosition.Y, $44000000 OR COLOR_NEW2);
      end;

  Color := 0; // For compiler
  for K := Low(fBuildNodes) to High(fBuildNodes) do
    with fBuildNodes[K] do
      if Active then
      begin
        case FieldType of
          ftCorn: Color := $40000000 OR COLOR_GREEN;
          ftWine: Color := $88000000 OR COLOR_GREEN;
          ftRoad: Color := $80000000 OR COLOR_NEW;//COLOR_YELLOW;
        end;
        if RemoveTreesMode then
          Color := $60000000 OR COLOR_BLUE;
        if ShortcutMode then
          Color := $20000000 OR COLOR_BLACK;
        for L := 0 to FieldList.Count - 1 do
        begin
          Point := FieldList.Items[L];
          gRenderAux.Quad(Point.X, Point.Y, Color);
        end;
      end;
//}
end;


{



// Remove units when is game in GA mode (avoid to place houses at unit)
if GA_PLANNER then
  for I := 0 to gHands[fOwner].Units.Count - 1 do
  begin
    U := gHands[fOwner].Units[I];
    if (U <> nil) then
      U.KillUnit(fOwner, False, False);
  end;

function BuildHouse_GA_MODE(aHT: TKMHouseType): TConstructionState;

// Build house na GA mode (for Runner)
// aHT: TKMHouseType = type of house
// Result: TConstructionState = state of construction
function TKMCityBuilder.BuildHouse_GA_MODE(aHT: TKMHouseType): TConstructionState;
var
  FieldType: TKMFieldType;
  FieldList: TKMPointList;

  procedure AddField();
  var
    I: Integer;
  begin
    for I := FieldList.Count - 1 downto 0 do
      case FieldType of
        ftRoad:
          begin
            gTerrain.SetRoad(FieldList.Items[I], fOwner);
            gTerrain.FlattenTerrain(FieldList.Items[I]);
            if gMapElements[  gTerrain.Land[ FieldList.Items[I].Y,FieldList.Items[I].X ].Obj  ].WineOrCorn then
              gTerrain.RemoveObject(FieldList.Items[I]);
          end;
        ftCorn,ftWine:
        begin
          gTerrain.SetField(FieldList.Items[I], fOwner, FieldType);
          gAIFields.Influences.AvoidBuilding[FieldList.Items[I].Y, FieldList.Items[I].X] := AVOID_BUILDING_NODE_LOCK_FIELD;
        end;
      end;
  end;

var
  Output: Boolean;
  HouseIdx: Integer;
  Loc: TKMPoint;
  HPlan: TKMHousePlan;
begin
  Result := csCannotPlaceHouse;
  Output := False;
  FieldList := TKMPointList.Create;
  try
    if fPlanner.GetHousePlan(False, False, aHT, Loc, HouseIdx) then
    begin
      Output := True;
      gHands[fOwner].AddHousePlan(aHT, Loc); // Place house plan
      if fPlanner.GetRoadToHouse(aHT, HouseIdx, FieldList, FieldType) then // Place roads
        AddField();
      if fPlanner.GetFieldToHouse(aHT, HouseIdx, FieldList, FieldType) then // Place fields
        AddField();
      if gHands[fOwner].BuildList.HousePlanList.TryGetPlan(Loc, HPlan) then // Remove house plan (it must be done because of road planning)
      begin
        gHands[fOwner].BuildList.HousePlanList.RemPlan(Loc);
        gHands[fOwner].Stats.HousePlanRemoved(aHT);
      end;
      gHands[fOwner].AddHouse(aHT, Loc.X, Loc.Y, True); // Place house
    end;
  finally
    FieldList.Free;
  end;
  if Output then
    Result := csHousePlaced;
end;


var
  GA_BUILDER_WORKER_COEF : Single = 8.516485214;
  GA_BUILDER_EXHAUSTION_ARR: array[WARE_MIN..WARE_MAX] of Single = (
    1.597312808, 2.605776548, 6.652187347, 4.734027863, 4.655752659, 2.305694342, 3.052431107, 2.866589546, 0.3297367692, 4.905310631, 4.637497902, 1.792099953, 1.758574486, 8.000164986, 4.496774197, 9.744778633, 8.297982216, 7.661552429, 1.597817659, 4.179779053, 1.837774515, 9.829838753, 5.807341576, 1.473491907, 5.093095303, 0.7045341134, 2.986746073, 1.279728413
  );
  GA_BUILDER_FRACTION_ARR: array[WARE_MIN..WARE_MAX] of Single = (
    52.44208145, 97.94073486, 81.27591705, 14.42814064, 39.30894089, 23.50471687, 3.592087984, 90.95751953, 5.030199528, 14.30461979, 15.02885342, 23.04277039, 38.70484161, 34.08721161, 46.43330002, 36.89776611, 36.55716705, 61.80127335, 52.2832222, 64.24739075, 1.925330043, 89.33174133, 29.77691841, 100, 38.04268646, 88.26511383, 46.45424652, 85.67434692
  );
  // Length 30
  //GA_BUILDER_HOUSE_ARR: array[HOUSE_MIN..HOUSE_MAX] of Single = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29);

  //function ChooseHousesToBuildGA(aWorkerCnt: Integer): Boolean;


function TKMCityBuilder.ChooseHousesToBuildGA(aWorkerCnt: Integer): Boolean;
const
  BASIC_HOUSES: set of TKMHouseType = [htSchool, htBarracks, htInn, htMarketPlace, htStore];
var
  MaxPlans: Integer;
  RequiredHouses: TRequiredHousesArray;
  WareBalance: TWareBalanceArray;


  function GetHouseToUnlock(var aUnlockProcedure: Boolean; var aHT, aFollowingHouse: TKMHouseType): Boolean;
  var
    Output: Boolean;
    initHT: TKMHouseType;
  begin
    Output := True;
    // Repeat until is available house finded (to unlock target house)
    initHT := aHT;
    aFollowingHouse := htNone;
    while Output AND not gHands[fOwner].Locks.HouseCanBuild(aHT) do
    begin
      aUnlockProcedure := True;
      if gHands[fOwner].Locks.HouseBlocked[aHT] then // House is blocked -> unlock impossible
        Output := False
      else
      begin
        aFollowingHouse := aHT;
        aHT := gRes.Houses[aHT].ReleasedBy; // House have to be unlocked by this house
      end;
    end;
    // Output = false only in case that house is already under construction OR is blocked by script / settings from the map editor
    Result := Output AND ( (initHT = aHT) OR (gHands[fOwner].Stats.GetHouseTotal(aHT) = 0) );
  end;


  function AddToConstruction(aHT: TKMHouseType; aUnlockProcedureRequired: Boolean = False): TConstructionState;
  var
    UnlockProcedure: Boolean;
    FollowingHouse: TKMHouseType;
    Output: TConstructionState;
  begin
    Output := csCannotPlaceHouse;
    UnlockProcedure := aUnlockProcedureRequired; // Unlock procedure = build house as soon as possible -> avoid to build house plan inside of tree (remove tree will take time)
    // Check if AI can build house (if is house blocked [by script] ignore it)
    if GetHouseToUnlock(UnlockProcedure, aHT, FollowingHouse) then
    begin
      if GA_PLANNER then
        Output := BuildHouse_GA_MODE(aHT)
      else
        Output := BuildHouse(UnlockProcedure OR (aHT = htFarm), False, False, aHT); // Farms should be build as soon as possible
    end
    else if (FollowingHouse <> ht_None) AND (gHands[fOwner].Stats.GetHouseQty(htSchool) > 0) then // Activate house reservation (only when is first school completed)
    begin
      Output := BuildHouse(True, True, False, FollowingHouse);
    end;
    Result := Output;
  end;

  procedure SelectBestHouses();
  var
    I: Integer;
    WT, HighWT: TKMWareType;
    HighPriority: Single;
    WarePriorityArr: array[WARE_MIN..WARE_MAX] of Single;
  begin
    for WT := Low(WarePriorityArr) to High(WarePriorityArr) do
      WarePriorityArr[WT] := ( + WareBalance[WT].Fraction * GA_BUILDER_FRACTION_ARR[WT] *1000
                               - WareBalance[WT].Exhaustion * GA_BUILDER_EXHAUSTION_ARR[WT]
                             ) * RequiredHouses[ PRODUCTION[WT] ];

    for I := 0 to 4 do
    begin
      if (MaxPlans <= 0) then
        Exit;
      HighPriority := 0;
      for WT := Low(WarePriorityArr) to High(WarePriorityArr) do
        if (HighPriority < WarePriorityArr[WT]) then
        begin
          HighPriority := WarePriorityArr[WT];
          HighWT := WT;
        end;
      if (HighPriority = 0) then
        Exit;
      WarePriorityArr[HighWT] := 0;
      // Try build required houses
      case AddToConstruction( PRODUCTION[HighWT] ) of
        csNoNodeAvailable: Exit;
        csHouseReservation, csRemoveTreeProcedure: begin end;
        csHousePlaced:
        begin
          MaxPlans := MaxPlans - 1;
          RequiredHouses[  PRODUCTION[HighWT]  ] := 0; // Make sure that next node will not scan this house in this tick
        end;
        csCannotPlaceHouse:
        begin
          RequiredHouses[  PRODUCTION[HighWT]  ] := 0; // Make sure that next node will not scan this house in this tick
        end;
      end;

    end;
  end;

  procedure CheckHouseReservation();
  var
    I: Integer;
    HT: TKMHouseType;
  begin
    for HT := Low(fPlanner.PlannedHouses) to High(fPlanner.PlannedHouses) do
      for I := 0 to fPlanner.PlannedHouses[HT].Count - 1 do
        with fPlanner.PlannedHouses[HT].Plans[I] do
          if not Placed AND (HouseReservation OR RemoveTreeInPlanProcedure)
             AND (csHousePlaced = AddToConstruction(HT)) then
          begin
            MaxPlans := MaxPlans - 1;
            RequiredHouses[HT] := 0;
          end;
  end;
var
  HT: TKMHouseType;
begin
  RequiredHouses := fPredictor.RequiredHouses;
  WareBalance := fPredictor.WareBalance;

  CheckHouseReservation();
  MaxPlans := Ceil(aWorkerCnt / GA_BUILDER_WORKER_COEF);
  if (MaxPlans <= 0) then
    Exit;

  // Basic houses (for city management)
  for HT in BASIC_HOUSES do
    if (RequiredHouses[HT] > 0) AND (AddToConstruction(HT, True) = csHousePlaced) then
      if (MaxPlans <= 0) then
        break;

  SelectBestHouses();

end;


function TKMCityBuilder.ChooseHousesToBuild(aMaxCnt: Integer): Boolean;
type
  TSetOfWare = set of TKMWareType;
const
  BASIC_HOUSES: set of TKMHouseType = [htSchool, htBarracks, htInn, htMarketPlace, htStore];
  BUILD_WARE: TSetOfWare = [wtGoldOre, wtCoal, wtGold, wtStone, wtTrunk, wtWood];
  FOOD_WARE: TSetOfWare = [wtCorn, wtFlour, wtBread, wtPig, wtSausages, wtWine, wtFish];
  WEAPON_WARE: TSetOfWare = [wtSkin, wtLeather, wtHorse, wtIronOre, wtCoal, wtSteel, wtAxe, wtBow, wtPike, wtArmor, wtShield, wtSword, wtArbalet, wtHallebard, wtMetalShield, wtMetalArmor];
var
  RequiredHouses: TRequiredHousesArray;
  WareBalance: TWareBalanceArray;


  function GetHouseToUnlock(var aUnlockProcedure: Boolean; var aHT, aFollowingHouse: TKMHouseType): Boolean;
  var
    Output: Boolean;
    initHT: TKMHouseType;
  begin
    Output := True;
    // Repeat until is available house finded (to unlock target house)
    initHT := aHT;
    aFollowingHouse := htNone;
    while Output AND not gHands[fOwner].Locks.HouseCanBuild(aHT) do
    begin
      aUnlockProcedure := True;
      if gHands[fOwner].Locks.HouseBlocked[aHT] then // House is blocked -> unlock impossible
        Output := False
      else
      begin
        aFollowingHouse := aHT;
        aHT := gRes.Houses[aHT].ReleasedBy; // House have to be unlocked by this house
      end;
    end;
    // Output = false only in case that house is already under construction OR is blocked by script / settings from the map editor
    Result := Output AND ( (initHT = aHT) OR (gHands[fOwner].Stats.GetHouseTotal(aHT) = 0) );
  end;


  function AddToConstruction(aHT: TKMHouseType; aUnlockProcedureRequired: Boolean = False): TConstructionState;
  var
    UnlockProcedure: Boolean;
    FollowingHouse: TKMHouseType;
    Output: TConstructionState;
  begin
    Output := csCannotPlaceHouse;
    UnlockProcedure := aUnlockProcedureRequired; // Unlock procedure = build house as soon as possible -> avoid to build house plan inside of tree (remove tree will take time)
    // Check if AI can build house (if is house blocked [by script] ignore it)
    if GetHouseToUnlock(UnlockProcedure, aHT, FollowingHouse) then
    begin
      aMaxCnt := aMaxCnt - 1;
      if GA_PLANNER then
        Output := BuildHouse_GA_MODE(aHT)
      else
        Output := BuildHouse(UnlockProcedure, False, aHT);
    end
    else if (FollowingHouse <> ht_None) AND (gHands[fOwner].Stats.GetHouseQty(htSchool) > 0) then // Activate house reservation
    begin
      Output := BuildHouse(True, True, FollowingHouse);
    end;
    Result := Output;
  end;

  function SelectHouse(const aSetOfWare: TSetOfWare): Boolean;
  const
    FRACTION_COEF = 3.0;
  var
    Output: Boolean;
    I: Integer;
    Priority, POM_Priority: Single;
    Ware, WT, POM_WT: TKMWareType;
    WareOrder: array[0..5] of TKMWareType;
    WarePriority: array[0..5] of Single;
  begin
    Output := False;
    // Basic producing houses (secure resources for building)
    for I := Low(WareOrder) to High(WareOrder) do
    begin
      WareOrder[I] := wtNone;
      WarePriority[I] := 0; // Doesn't have to be initialized but in this case compilation throws warning
    end;
    // Find the most required house to be build
    for Ware in aSetOfWare do
    begin
      WT := Ware;
      if (RequiredHouses[ PRODUCTION[WT] ] > 0) then
      begin
        Priority := WareBalance[WT].Exhaustion - WareBalance[WT].Fraction * FRACTION_COEF;
        for I := Low(WareOrder) to High(WareOrder) do
          if (WT = wtNone) then
            break
          else if (WareOrder[I] = wtNone) OR (Priority < WarePriority[I]) then // Buble sort is best for few elements
          begin
            POM_WT := WT;
            WT := WareOrder[I];
            WareOrder[I] := POM_WT;
            POM_Priority := Priority;
            Priority := WarePriority[I];
            WarePriority[I] := POM_Priority;
          end;
      end;
    end;
    // Try build required houses
    for I := Low(WareOrder) to High(WareOrder) do
    begin
      if (WareOrder[I] = wtNone) then
        break;
      case AddToConstruction(PRODUCTION[ WareOrder[I] ]) of
        csNoNodeAvailable: break;
        csHouseReservation, csRemoveTreeProcedure: Output := True;
        csHousePlaced:
        begin
          Output := True;
          aMaxCnt := aMaxCnt - 1;
          if (aMaxCnt <= 0) then
            break;
          RequiredHouses[  PRODUCTION[ WareOrder[I] ]  ] := 0; // Make sure that next node will not scan this house in this tick
        end;
        csCannotPlaceHouse:
        begin
          RequiredHouses[  PRODUCTION[ WareOrder[I] ]  ] := 0; // Make sure that next node will not scan this house in this tick
          //Dec(aRequiredHouses[  PRODUCTION[ WareOrder[I] ]  ]);
        end;
      end;
    end;
    Result := Output;
  end;

  procedure CheckHouseReservation();
  var
    I: Integer;
    HT: TKMHouseType;
  begin
    for HT := Low(fPlanner.PlannedHouses) to High(fPlanner.PlannedHouses) do
      for I := 0 to fPlanner.PlannedHouses[HT].Count - 1 do
        with fPlanner.PlannedHouses[HT].Plans[I] do
          if not Placed AND (HouseReservation OR RemoveTreeInPlanProcedure)
             AND (csHousePlaced = AddToConstruction(HT)) then
          begin
            aMaxCnt := aMaxCnt - 1;
            RequiredHouses[HT] := 0;
          end;
  end;
var
  Output: Boolean;
  POMCoal: Integer;
  HT: TKMHouseType;
begin
  Output := False;
  RequiredHouses := fPredictor.RequiredHouses;
  WareBalance := fPredictor.WareBalance;

  CheckHouseReservation();
  if (aMaxCnt <= 0) then
    Exit;

  // Basic houses (for city management)
  for HT in BASIC_HOUSES do
    if (RequiredHouses[HT] > 0) AND (AddToConstruction(HT, True) = csHousePlaced) then
    begin
      Output := True;
      if (aMaxCnt <= 0) then
        break;
    end;

  WareBalance[wtTrunk].Fraction := Max(0, RequiredHouses[htWoodcutters] - gHands[fOwner].Stats.GetHouseQty(htWoodcutters) - 4);
  POMCoal := RequiredHouses[htCoalMine]; // Coal is used by resource (Gold) and by weapon division -> extract just Gold requirements
  RequiredHouses[htCoalMine] := Max(0,gHands[fOwner].Stats.GetHouseTotal(htGoldMine)-gHands[fOwner].Stats.GetHouseTotal(htCoalMine));
  RequiredHouses[htWoodcutters] := Max(0,RequiredHouses[htWoodcutters] - Round(Byte(WareBalance[wtGold].Exhaustion < 20) * RequiredHouses[htWoodcutters] * 0.5));
  if (aMaxCnt > 0) AND SelectHouse(BUILD_WARE) then
    Output := True;

  // Make sure that gold will be produced (stones and wood are fines because of initial influence and order of construction)
  //if (gHands[fOwner].Stats.GetWareBalance(wtWood) < 10) AND (WareBalance[wtGold].Exhaustion < 20) then
  if (gHands[fOwner].Stats.GetWareBalance(wtWood) < 10) then
    Exit;

  // Now return coal count back to original values
  WareBalance[wtCoal].Fraction := (gHands[fOwner].Stats.GetHouseTotal(htCoalMine) - RequiredHouses[htCoalMine]) / POMCoal;
  RequiredHouses[htCoalMine] := POMCoal;
  if (aMaxCnt > 0) then
  begin
    Output := SelectHouse(FOOD_WARE);
    SelectHouse(WEAPON_WARE);
    SelectHouse(FOOD_WARE);
  end;

  Result := Output;
end;

procedure TKMCityBuilder.UpdateBuildNode(var aNode: TBuildNode);
  function IsPlan(aPoint: TKMPoint; aLock: TKMTileLock; aField: TKMFieldType): Boolean;
  begin
    Result := (gHands[fOwner].BuildList.FieldworksList.HasField(aPoint) = aField)
              OR (gTerrain.Land[aPoint.Y, aPoint.X].TileLock = aLock);
  end;
  function IsCompletedRoad(aPoint: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsWalkableRoad(aPoint);
  end;
  function IsCompletedField(aPoint: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsCornField(aPoint);
  end;
  function IsCompletedWine(aPoint: TKMPoint): Boolean;
  begin
    Result := gTerrain.TileIsWineField(aPoint);
  end;
  function IsRoad(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedRoad(aPoint) OR IsPlan(aPoint, tlRoadWork, ftRoad);
  end;
  function IsCornField(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedField(aPoint) OR IsPlan(aPoint, tlFieldWork, ftCorn);
  end;
  function IsWineField(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedWine(aPoint) OR IsPlan(aPoint, tlFieldWork, ftWine);
  end;

  function BuildField(aIdx: Integer; aFieldType: TKMFieldType): Boolean;
  var
    Output: Boolean;
  begin
    Output := False;
    if gHands[fOwner].CanAddFieldPlan(aNode.FieldList.Items[aIdx], aFieldType) then
    begin
      gHands[fOwner].BuildList.FieldworksList.AddField(aNode.FieldList.Items[aIdx], aFieldType);
      aNode.FreeWorkers := aNode.FreeWorkers - 1;
      Output := True;
    end;
    Result := Output;
  end;

  // Build roads
  procedure BuildRoad();
  var
    I: Integer;
  begin
    with aNode do
    begin
      // Remove elements of exist road from list
      for I := FieldList.Count - 1 downto 0 do
        if IsCompletedRoad(FieldList.Items[I]) then
        begin
          UnlockPointOfNode(FieldList.Items[I]);
          FieldList.Delete(I);
        end
        else
          break;
      if (FieldList.Count = 0) then
      begin
        Active := False;
        Exit;
      end;
      RequiredWorkers := FieldList.Count;
      // Build road / check road plans / replace missing parts / reconnect road when is no more possible to place plan
      for I := FieldList.Count - 1 downto 0 do
      begin
        // Does we have free workers?
        if (FreeWorkers <= 0) then
          break;
        // Is there already road / plan / work in progress?
        if IsRoad(FieldList.Items[I]) then
        begin
          FreeWorkers := FreeWorkers - 1;
          CenterPoint := FieldList.Items[I]; // Actualize center point (distribution of workers by distance)
        end
        // When cannot place new plan try find another way by calling pathfinding
        else if not BuildField(I, ftRoad) then
        begin
          // If is not possible to connect 2 points by road destroy node
          if not fPlanner.GetRoadBetweenPoints(CenterPoint, FieldList.Items[0], FieldList, FieldType) then
          begin
            FieldList.Clear;
            Active := False;
          end;
          LockNode(aNode);
          RequiredWorkers := FieldList.Count;
          Exit; // Node will be updated in next calling
        end;
      end;
    end;
  end;

  // Build Wine or Corn fields
  procedure BuildFields();
  var
    I,K: Integer;
  begin
    with aNode do
    begin
      RequiredWorkers := FieldList.Count;
      for I := 0 to FieldList.Count - 1 do
      begin
        if (FreeWorkers <= 0) then
          Exit;
        // Check if field already exists ...
        if   ((FieldType = ftWine) AND (IsCompletedField(FieldList.Items[I])))
          OR ((FieldType = ftCorn) AND (IsCompletedWine(FieldList.Items[I]))) then
        begin
          RequiredWorkers := RequiredWorkers - 1;
        end
        // ... or if is plan placed
        else if (IsPlan(FieldList.Items[I], tlFieldWork, FieldType)) then
          FreeWorkers := FreeWorkers - 1
        // ... else try build it
        else
          BuildField(I, FieldType);
        // When node reached all plans disable it
        if (RequiredWorkers <= 0) OR (I = FieldList.Count-1) then
        begin
          for K := 0 to FieldList.Count-1 do
            if   ((FieldType = ftWine) AND (IsCornField(FieldList.Items[I])))
              OR ((FieldType = ftCorn) AND (IsWineField(FieldList.Items[I]))) then
              UnlockPointOfNode(FieldList.Items[K]);
          FieldList.Clear;
          Active := False;
        end;
      end;
    end;
  end;

  // Remove trees or Wine / Corn fields which block placing house plan
  procedure RemoveObstaclesInPlan();
  var
    I: Integer;
  begin
    with aNode do
    begin
      // Finish node
      if (FieldList.Count = 0) then
      begin
        Active := False;
        fPlanner.PlannedHouses[ResponsibleHouseType,ResponsibleHouseIdx].RemoveTreeInPlanProcedure := False;
        UnlockHouseLoc(ResponsibleHouseType, fPlanner.PlannedHouses[ResponsibleHouseType,ResponsibleHouseIdx].Loc);
        Exit;
      end;
      RequiredWorkers := FieldList.Count;
      for I := FieldList.Count - 1 downto 0 do
      begin
        if (FreeWorkers <= 0) then
          Exit;
        // Detect obstacles in house plan
        if gTerrain.ObjectIsChopableTree(FieldList.Items[I], [caAge1,caAge2,caAge3,caAgeFull]) then
        begin
          // Check if is wine plan already placed
          if IsPlan(FieldList.Items[I], tlFieldWork, ftWine) then
          begin
          end
          // If we cannot remove tree by placing wineyard remove point from list
          else if not BuildField(I, ftWine) then
            FieldList.Delete(I);
        end
        // If is plan blocked by fields which could be compensated by road do it
        else if IsCompletedWine(FieldList.Items[I]) OR IsCompletedField(FieldList.Items[I]) OR IsRoad(FieldList.Items[I]) then
        begin
          if IsCompletedRoad(FieldList.Items[I]) then
            FieldList.Delete(I) // Now can be item [I] deleted
          // Else try place road plan or delete point
          else if not IsPlan(FieldList.Items[I], tlRoadWork, ftRoad) then
          begin
            // Delete item [I] only in case that we cannot place road plan (point must be removed only in moment when is road completed)
            if not BuildField(I, ftRoad) then
              FieldList.Delete(I);
          end;
        end
        // Tree could not be cutted down
        else
        begin
          FieldList.Delete(I);
          RequiredWorkers := RequiredWorkers - 1;
        end;
      end;
    end;
  end;

begin
  // Build procedures are split because of quite complex algorithm (or can be merged into mess)
  if aNode.RemoveTreesMode then
    RemoveObstaclesInPlan()
  else
    case aNode.FieldType of
      ftRoad: BuildRoad();
      ftWine, ftCorn: BuildFields();
      else
        begin
        end;
    end;
    if aNode.Active then
      aNode.RequiredWorkers := Min(aNode.MaxReqWorkers, aNode.RequiredWorkers);
end;
//}


end.


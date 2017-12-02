unit KM_CityBuilder;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils,
  KM_Defaults, KM_CommonClasses, KM_CommonUtils, KM_Points,
  KM_PathfindingRoad, //KM_AISetup,
  KM_ResHouses,
  KM_CityPlanner, KM_CityPredictor;

type

  TWoodcuttersManagement = record
    Loc, ForestCenterPoint: TKMPoint;
    ChopOnly: Boolean;
  end;

  TBuildNode = record
    Active, RemoveTreesMode: Boolean;
    FreeWorkers, RequiredWorkers: Integer;
    CenterPoint: TKMPoint;
    FieldType: TFieldType; //ft_Corn,ft_Wine  ft_Road
    FieldList: TKMPointList;
  end;

  //
  TKMCityBuilder = class
  private
    fOwner: TKMHandIndex;
    fBuildNodes: array of TBuildNode;

    fPlanner: TKMCityPlanner;

    procedure UpdateBuildNode(var aNode: TBuildNode);

    procedure BuildHouse(aHT: THouseType);
    procedure BuildHouse_DEBUG_MODE(aHT: THouseType);
  public
    constructor Create(aPlayer: TKMHandIndex);
    destructor Destroy(); override;

    property Planner: TKMCityPlanner read fPlanner write fPlanner;

    procedure AfterMissionInit(out aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt: Integer);
    procedure OwnerUpdate(aPlayer: TKMHandIndex);

    procedure UpdateState(aTick: Cardinal; out aFreeWorkersCnt: Integer);
    procedure UpdateBuildNodes(out aFreeWorkersCnt: Integer);
    procedure ChooseHousesToBuild(aMaxCnt: Integer; var aRequiredHouses: TRequiredHousesArray; const aWareBalance: TWareBalanceArray);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure LogStatus(var aBalanceText: UnicodeString);
  end;


implementation
uses
  KM_Game, KM_Houses, KM_HouseCollection, KM_HouseSchool, KM_HandsCollection, KM_Hand, KM_Terrain, KM_Resource,
  KM_ResWares, KM_AIFields, KM_Units, KM_UnitTaskDelivery, KM_UnitActionWalkTo, KM_UnitTaskGoEat, KM_UnitsCollection,
  KM_NavMesh, KM_HouseMarket;


{ TKMCityBuilder }
constructor TKMCityBuilder.Create(aPlayer: TKMHandIndex);
begin
  inherited Create;

  fOwner := aPlayer;
  fPlanner := TKMCityPlanner.Create(aPlayer);

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


procedure TKMCityBuilder.AfterMissionInit(out aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt: Integer);
const
  WORKER_COEF = 100.0;
var
  I: Integer;
begin
  fPlanner.AfterMissionInit();
  // Find resources around Loc and compute expectations about
  fPlanner.ScanLocResources(aGoldMineCnt, aIronMineCnt, aFieldCnt, aBuildCnt);
  gHands[fOwner].AI.Setup.WorkerCount := Min(50, Round(aBuildCnt / WORKER_COEF));
  SetLength(fBuildNodes, gHands[fOwner].AI.Setup.WorkerCount shr 1);
  for I := Low(fBuildNodes) to High(fBuildNodes) do
  begin
    fBuildNodes[I].FieldList := TKMPointList.Create();
    fBuildNodes[I].Active := False;
    fBuildNodes[I].RemoveTreesMode := False;
  end;
end;


procedure TKMCityBuilder.OwnerUpdate(aPlayer: TKMHandIndex);
begin
  fOwner := aPlayer;
  fPlanner.OwnerUpdate(aPlayer);
end;


procedure TKMCityBuilder.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(fOwner);
  fPlanner.Save(SaveStream);
end;


procedure TKMCityBuilder.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(fOwner);
  fPlanner.Load(LoadStream);
end;


procedure TKMCityBuilder.UpdateState(aTick: Cardinal; out aFreeWorkersCnt: Integer);
begin
  fPlanner.UpdateState(aTick);

  if (aTick = 20) then
  begin

  end;
  //{
  if (aTick mod 10 = 0) then
  begin
    UpdateBuildNodes(aFreeWorkersCnt);
  end
  //}
end;


procedure TKMCityBuilder.UpdateBuildNodes(out aFreeWorkersCnt: Integer);
var
  I, K, ClosestIdx, ClosestDist, Dist: Integer;
  WorkersPos: TKMPointArray;
begin
  // Reset count of free workers in each node
  for I := Low(fBuildNodes) to High(fBuildNodes) do
    fBuildNodes[I].FreeWorkers := 0;

  // Get positions of workes with nil task (no task)
  aFreeWorkersCnt := 0;
  SetLength(WorkersPos, gHands[fOwner].Stats.GetUnitQty(ut_Worker));
  for I := 0 to gHands[fOwner].Units.Count - 1 do
    if not gHands[fOwner].Units[I].IsDeadOrDying
       AND (gHands[fOwner].Units[I] is TKMUnitWorker)
       AND (gHands[fOwner].Units[I].UnitTask = nil) then
    begin
      WorkersPos[aFreeWorkersCnt] := gHands[fOwner].Units[I].GetPosition;
      aFreeWorkersCnt := aFreeWorkersCnt + 1;
    end;

  // Find closest build-node to each free worker and allow to expand it in next update
  while (aFreeWorkersCnt > 0) do
  begin
    ClosestDist := High(Integer);
    for K := Low(fBuildNodes) to High(fBuildNodes) do
      if (fBuildNodes[K].RequiredWorkers > 0) then
      begin
        Dist := KMDistanceAbs(WorkersPos[aFreeWorkersCnt - 1], fBuildNodes[K].CenterPoint);
        if (Dist < ClosestDist) then
        begin
          ClosestDist := Dist;
          ClosestIdx := K;
        end;
      end;
    if (ClosestDist <> High(Integer)) then
    begin
      with fBuildNodes[ClosestIdx] do
      begin
        aFreeWorkersCnt := aFreeWorkersCnt - 1;
        RequiredWorkers := RequiredWorkers - 1;
        FreeWorkers := FreeWorkers + 1;
      end;
    end
    else
      break;
  end;
  // Update nodes
  for I := Low(fBuildNodes) to High(fBuildNodes) do
    if fBuildNodes[I].Active then
      UpdateBuildNode(fBuildNodes[I]);
end;


procedure TKMCityBuilder.UpdateBuildNode(var aNode: TBuildNode);
  function IsPlan(aPoint: TKMPoint; aLock: TTileLock; aField: TFieldType): Boolean;
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
    Result := IsCompletedRoad(aPoint) OR IsPlan(aPoint, tlRoadWork, ft_Road);
  end;
  function IsCornField(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedField(aPoint) OR IsPlan(aPoint, tlFieldWork, ft_Corn);
  end;
  function IsWineField(aPoint: TKMPoint): Boolean;
  begin
    Result := IsCompletedWine(aPoint) OR IsPlan(aPoint, tlFieldWork, ft_Wine);
  end;

  function BuildField(aIdx: Integer; aFieldType: TFieldType): Boolean;
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
    I: Integer;
  begin
    with aNode do
    begin
      // Remove elements of exist road from list
      for I := FieldList.Count - 1 downto 0 do
        if IsCompletedRoad(FieldList.Items[I]) then
          FieldList.Delete(I)
        else
          break;
      if (FieldList.Count = 0) then
      begin
        Active := False;
        Exit;
      end;
      // Build road / check road plans / replace missing parts / reconnect road when is no more possible to place plan
      RequiredWorkers := FieldList.Count;
      for I := FieldList.Count - 1 downto 0 do
      begin
        // Does we have free workers?
        if (FreeWorkers <= 0) then
        begin
          CenterPoint := FieldList.Items[I]; // Actualize center point (distribution of workers by distance)
          break;
        end;
        // Is there already road / plan / work in progress?
        if IsRoad(FieldList.Items[I]) then
          RequiredWorkers := RequiredWorkers - 1
        // When cannot place new plan try find another way by calling pathfinding
        else if not BuildField(I, ft_Road) then
        begin
          // If is not possible to connect 2 points by road destroy node
          if not fPlanner.GetRoadBetweenPoints(CenterPoint, FieldList.Items[0], FieldList, FieldType) then
          begin
            FieldList.Clear;
            Active := False;
          end;
          RequiredWorkers := FieldList.Count;
          Exit; // Node will be updated in next calling
        end;
      end;
    end;
  end;

  // Build Wine or Corn fields
  procedure BuildFields();
  const
    MAX_WINE = 10;
    MAX_FIELD = 16;
  var
    I: Integer;
  begin
    with aNode do
    begin
      RequiredWorkers := Min(Byte(FieldType = ft_Wine) * MAX_WINE + Byte(FieldType = ft_Corn) * MAX_FIELD, FieldList.Count);
      for I := 0 to FieldList.Count - 1 do
      begin
        if (FreeWorkers <= 0) then
          Exit;
        // Check if field already exists ...
        if   ((FieldType = ft_Wine) AND (IsCornField(FieldList.Items[I])))
          OR ((FieldType = ft_Corn) AND (IsWineField(FieldList.Items[I]))) then
        begin
          RequiredWorkers := RequiredWorkers - 1;
        end
        // ... else try build it
        else
          BuildField(I, FieldType);
        // When node reached all plans disable it
        if (RequiredWorkers <= 0) OR (I = FieldList.Count-1) then
        begin
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
      if (FieldList.Count = 0) then
      begin
        Active := False;
        Exit;
      end;
      RequiredWorkers := FieldList.Count;
      for I := FieldList.Count - 1 downto 0 do
      begin
        if (FreeWorkers <= 0) then
          Exit;
        // Detect obstacles in house plan
        if gTerrain.ObjectIsChopableTree(FieldList.Items[I].X, FieldList.Items[I].Y) then
        begin
          // Check if is wine plan already placed
          if IsPlan(FieldList.Items[I], tlFieldWork, ft_Wine) then
          begin
          end
          // If we cannot remove tree by placing wineyard remove point from list
          else if not BuildField(I, ft_Wine) then
            FieldList.Delete(I);
        end
        // If is plan blocked by fields which could be compensated by road do it
        else if IsCompletedWine(FieldList.Items[I]) OR IsCompletedField(FieldList.Items[I]) then
        begin
          // Check if is road plan already placed
          if IsPlan(FieldList.Items[I], tlRoadWork, ft_Road) then
          begin
          end
          // Else try place road plan or delete point
          else
          begin
            BuildField(I, ft_Road);
            FieldList.Delete(I);
          end;
        end
        // Tree could be cut down
        else
          FieldList.Delete(I);
      end;
    end;
  end;

begin
  // Build procedures are split because of quite complex algorithm (or can be merged into mess)
  if aNode.RemoveTreesMode then
    RemoveObstaclesInPlan()
  else
    case aNode.FieldType of
      ft_Road: BuildRoad();
      ft_Wine, ft_Corn: BuildFields();
      else
        begin
        end;
    end;
end;


procedure TKMCityBuilder.BuildHouse(aHT: THouseType);
var
  I, Node1Idx, Node2Idx, HouseIdx: Integer;
  Loc: TKMPoint;
begin
  // Find at least 2 non active build nodes
  Node1Idx := -1;
  Node2Idx := -1;
  for I := Low(fBuildNodes) to High(fBuildNodes) do
    if not fBuildNodes[I].Active then
      if (Node1Idx = -1) then
        Node1Idx := I
      else
      begin
        Node2Idx := I;
        break;
      end;

  // We need min 2 free nodes (1 for road and second for field or 1 for wine and second for road to remove trees in plan)
  if (Node1Idx = -1) OR (Node2Idx = -1) then
    Exit;

  if fPlanner.GetHousePlan(aHT, Loc, HouseIdx) then
  begin
    // Check if we can place house
    if gHands[fOwner].CanAddHousePlan(Loc, aHT) then
    begin
      gHands[fOwner].AddHousePlan(aHT, Loc); // Place house
      // Add road to node
      if fPlanner.GetRoadToHouse(aHT, HouseIdx, fBuildNodes[Node1Idx].FieldList, fBuildNodes[Node1Idx].FieldType) then
      begin
        fBuildNodes[Node1Idx].Active := True;
        fBuildNodes[Node1Idx].RemoveTreesMode := False;
        fBuildNodes[Node1Idx].RequiredWorkers := fBuildNodes[Node1Idx].FieldList.Count;
        fBuildNodes[Node1Idx].CenterPoint := fBuildNodes[Node1Idx].FieldList[0];
      end;
      // Add field to node (if is required [ht_Farm, ht_Wineyard])
      if fPlanner.GetFieldToHouse(aHT, HouseIdx, fBuildNodes[Node2Idx].FieldList, fBuildNodes[Node2Idx].FieldType) then
      begin
        fBuildNodes[Node2Idx].Active := True;
        fBuildNodes[Node2Idx].RemoveTreesMode := False;
        fBuildNodes[Node2Idx].RequiredWorkers := fBuildNodes[Node2Idx].FieldList.Count;
        fBuildNodes[Node2Idx].CenterPoint := Loc;
      end;
    end
    // House plan cannot be placed by existing tree -> remove it by placing wine and road at specific tiles
    else
    begin
      if fPlanner.GetTreesInHousePlan(aHT, Loc, fBuildNodes[Node1Idx].FieldList) then
      begin
        for I := Low(fBuildNodes) to High(fBuildNodes) do
          if fBuildNodes[I].Active
            AND fBuildNodes[I].RemoveTreesMode
            AND (fBuildNodes[I].FieldList.Count > 0)
            AND KMSamePoint(fBuildNodes[Node1Idx].FieldList.Items[0], fBuildNodes[I].FieldList.Items[0]) then
          begin
            fBuildNodes[Node1Idx].FieldList.Clear;
            Exit;
          end;
        fBuildNodes[Node1Idx].Active := True;
        fBuildNodes[Node1Idx].RemoveTreesMode := True;
        fBuildNodes[Node1Idx].RequiredWorkers := fBuildNodes[Node1Idx].FieldList.Count; // Real count will be updated during building process
        fBuildNodes[Node1Idx].CenterPoint := Loc;
      end
      else
      begin
        // Remove house plan from city planner
      end;
    end;
  end
  else
  begin
    // add house to plan
  end;
end;


procedure TKMCityBuilder.BuildHouse_DEBUG_MODE(aHT: THouseType);
var
  I, HouseIdx: Integer;
  Loc: TKMPoint;
  FieldType: TFieldType;
  FieldList: TKMPointList;
begin
  FieldList := TKMPointList.Create();
  if fPlanner.GetHousePlan(aHT, Loc, HouseIdx) then
  begin
    gHands[fOwner].AddHouse(aHT, Loc.X, Loc.Y, True);
    {
    FieldList.Clear;
    if fPlanner.GetRoadToHouse(aHT, HouseIdx, FieldList, FieldType) then
      for I := FieldList.Count - 1 downto 0 do
      begin
        gTerrain.SetRoad(FieldList.Items[I], fOwner);
        gTerrain.FlattenTerrain(FieldList.Items[I]);
        //if gMapElements[gTerrain.Land[FieldList.Items[I].Y,FieldList.Items[I].X].Obj].WineOrCorn then
        //  gTerrain.RemoveObject(FieldList.Items[I]);
      end;
    }
    FieldList.Clear;
    if fPlanner.GetFieldToHouse(aHT, HouseIdx, FieldList, FieldType) then
      for I := 0 to FieldList.Count - 1 do
        gTerrain.SetField(FieldList.Items[I], fOwner, FieldType);
  end;
  FieldList.Free;
end;


procedure TKMCityBuilder.ChooseHousesToBuild(aMaxCnt: Integer; var aRequiredHouses: TRequiredHousesArray; const aWareBalance: TWareBalanceArray);
  function GetHouseToUnlock(var aHT: THouseType): Boolean;
  var
    Output: Boolean;
    POM_HT: THouseType;
  begin
    Output := True;
    // Repeat until is avaiable house finded (to unlock target house)
    POM_HT := aHT;
    while Output AND not gHands[fOwner].Locks.HouseCanBuild(aHT) do
    begin
      if gHands[fOwner].Locks.HouseBlocked[aHT] then // House is blocked -> unlock impossible
        Output := False
      else
        aHT := gRes.Houses[aHT].ReleasedBy; // House have to be unlocked by this house
    end;
    // Output = false only in case that house is already under construction OR is blocked by script / settings from the map editor
    Result := Output AND ( (POM_HT = aHT) OR (gHands[fOwner].Stats.GetHouseTotal(aHT) = 0));
  end;
  //gHands[fOwner].Locks.HouseCanBuild(aHouse)
  //gHands[fOwner].Locks.HouseBlocked[ht_Quary]
  function AddToConstruction(aHT: THouseType): Boolean;
  begin
    // Check if AI can build house (if is house blocked [by script] ignore it)
    if GetHouseToUnlock(aHT) then
      repeat
        BuildHouse(aHT);
        //BuildHouse_DEBUG_MODE(aHT);
        aRequiredHouses[aHT] := aRequiredHouses[aHT] - 1;
        aMaxCnt := aMaxCnt - 1;
      until (aMaxCnt <= 0) OR (aRequiredHouses[aHT] = 0);
    aRequiredHouses[aHT] := 0; // Make sure than next node will not scan this house in this tick
    Result := (aMaxCnt > 0);
  end;

var
  I: Integer;
  BestDerivation: Single;
  WT, BestWT: TWareType;
const
  BASIC_HOUSES: array[0..4] of THouseType = (ht_School, ht_Barracks, ht_Inn, ht_Store, ht_MarketPlace);
  BASIC_WARE: array[0..5] of TWareType = (wt_Gold, wt_GoldOre, wt_Stone, wt_Trunk, wt_Wood, wt_Coal);
  {
    wt_Trunk,          wt_Stone,         wt_Wood,           wt_IronOre,      wt_GoldOre,
    wt_Coal,           wt_Steel,         wt_Gold,           wt_Wine,         wt_Corn,
    wt_Bread,          wt_Flour,         wt_Leather,        wt_Sausages,     wt_Pig,
    wt_Skin,
  }
begin
  for I := Low(BASIC_HOUSES) to High(BASIC_HOUSES) do
    if (aRequiredHouses[ BASIC_HOUSES[I] ] > 0) then
      AddToConstruction(BASIC_HOUSES[I]);

  BestDerivation := 0;
  for I := Low(BASIC_WARE) to High(BASIC_WARE) do
    if (aRequiredHouses[  PRODUCTION[ BASIC_WARE[I] ]  ] > 0) then
      AddToConstruction(PRODUCTION[ BASIC_WARE[I] ]);
  {
      if (aWareBalance[BASIC_WARE[I]].Derivation < BestDerivation) then
      begin
        BestWT := BASIC_WARE[I];
        BestDerivation := aWareBalance[BASIC_WARE[I]].Derivation;
      end;
  if (BestDerivation < 0) then
    if not AddToConstruction(PRODUCTION[BestWT]) then
      Exit;
  //}
  BestDerivation := 0;
  for WT := Low(aWareBalance) to High(aWareBalance) do
    if (aWareBalance[WT].Derivation < BestDerivation) then
    begin
      BestWT := WT;
      BestDerivation := aWareBalance[WT].Derivation;
    end;
  if (BestDerivation < 0) then
    if not AddToConstruction(PRODUCTION[BestWT]) then
      Exit;
end;


procedure TKMCityBuilder.LogStatus(var aBalanceText: UnicodeString);
var
  I, cnt: Integer;
begin
  cnt := 0;
  for I := Low(fBuildNodes) to High(fBuildNodes) do
    if fBuildNodes[I].Active then
      cnt := cnt + 1;
  aBalanceText := aBalanceText + '|| Active nodes:' + IntToStr(cnt);
end;



{
procedure TKMCityBuilder.PlanDefenceTowers;
const
  DISTANCE_BETWEEN_TOWERS = 10;
var
  P: TKMHand;
  Outline1, Outline2: TKMWeightSegments;
  I, K, DefCount: Integer;
  Loc: TKMPoint;
  SegLength, Ratio: Single;
begin
  if fDefenceTowersPlanned then Exit;
  fDefenceTowersPlanned := True;
  P := gHands[fOwner];
  if not P.Locks.HouseCanBuild(ht_WatchTower) then Exit;

  //Get defence Outline with weights representing how important each segment is
  gAIFields.NavMesh.GetDefenceOutline(fOwner, Outline1, Outline2);
  //Make list of defence positions
  for I := 0 to High(Outline2) do
  begin
    //Longer segments will get several towers
    SegLength := KMLength(Outline2[I].A, Outline2[I].B);
    DefCount := Max(Trunc(SegLength / DISTANCE_BETWEEN_TOWERS), 1);
    for K := 0 to DefCount - 1 do
    begin
      Ratio := (K + 1) / (DefCount + 1);
      Loc := KMPointRound(KMLerp(Outline2[I].A, Outline2[I].B, Ratio));
      fDefenceTowers.Add(Loc, Trunc(1000*Outline2[I].Weight));
    end;
  end;
  fDefenceTowers.SortByTag;
  fDefenceTowers.Inverse; //So highest weight is first
end;


procedure TKMCityBuilder.TryBuildDefenceTower;
const
  SEARCH_RAD = 6;
  MAX_ROAD_DISTANCE = 25;
var
  P: TKMHand;
  IY, IX: Integer;
  Loc: TKMPoint;
  DistSqr, BestDistSqr: Integer;
  BestLoc: TKMPoint;

  NodeList: TKMPointList;
  H: TKMHouse;
  LocTo: TKMPoint;
  RoadConnectID: Byte;
  RoadExists: Boolean;
begin
  P := gHands[fOwner];
  //Take the first tower from the list
  Loc := fDefenceTowers[0];
  fDefenceTowers.Delete(0);
  //Look for a place for the tower
  BestDistSqr := High(BestDistSqr);
  BestLoc := KMPOINT_ZERO;
  for IY := Max(1, Loc.Y-SEARCH_RAD) to Min(gTerrain.MapY, Loc.Y+SEARCH_RAD) do
    for IX := Max(1, Loc.X-SEARCH_RAD) to Min(gTerrain.MapX, Loc.X+SEARCH_RAD) do
    begin
      DistSqr := KMLengthSqr(Loc, KMPoint(IX, IY));
      if (DistSqr < BestDistSqr) and P.CanAddHousePlanAI(IX, IY, ht_WatchTower, False) then
      begin
        BestLoc := KMPoint(IX, IY);
        BestDistSqr := DistSqr;
      end;
    end;
  if (BestLoc.X > 0) then
  begin
    //See if the road required is too long (tower might be across unwalkable terrain)
    H := P.Houses.FindHouse(ht_Any, BestLoc.X, BestLoc.Y, 1, False);
    if H = nil then Exit; //We are screwed, no houses left
    LocTo := H.PointBelowEntrance;

    //Find nearest complete house to get the road connect ID
    H := P.Houses.FindHouse(ht_Any, BestLoc.X, BestLoc.Y, 1, True);
    if H = nil then Exit; //We are screwed, no houses left
    RoadConnectID := gTerrain.GetRoadConnectID(H.PointBelowEntrance);

    NodeList := TKMPointList.Create;
    RoadExists := fPathFindingRoad.Route_ReturnToWalkable(BestLoc, LocTo, RoadConnectID, NodeList);
    //If length of road is short enough, build the tower
    if RoadExists and (NodeList.Count <= MAX_ROAD_DISTANCE) then
    begin
      gHands[fOwner].AddHousePlan(ht_WatchTower, BestLoc);
      TryConnectToRoad(KMPointBelow(BestLoc));
    end;
    NodeList.Free;
  end;
end;


//Try to place a building plan for requested house
//Report back if failed to do so (that will allow requester to choose different action)
function TKMCityBuilder.TryBuildHouse(aHouse: THouseType): Boolean;

procedure AddWoodcutter(aLoc, aCenterPoint: TKMPoint; aChopOnly: Boolean = False);
const
  WOOD_BLOCK_RAD = 5.5;
begin
  SetLength(fWoodcuttersManagement, Length(fWoodcuttersManagement) + 1);
  fWoodcuttersManagement[ High(fWoodcuttersManagement) ].Loc := aLoc;
  fWoodcuttersManagement[ High(fWoodcuttersManagement) ].ForestCenterPoint := aCenterPoint;
  fWoodcuttersManagement[ High(fWoodcuttersManagement) ].ChopOnly := aChopOnly;
  if not aChopOnly then
  begin
    //MAX_WOODCUTTER_CUT_PNT_DISTANCE
    gAIFields.Influences.AddAvoidBuilding(aCenterPoint.X, aCenterPoint.Y, WOOD_BLOCK_RAD, 150);
  end;
end;

var
  I, K: Integer;
  Loc, WoodcutLoc: TKMPoint;
  P: TKMHand;
begin
  Result := False;
  P := gHands[fOwner];

  //Skip disabled houses
  if not P.Locks.HouseCanBuild(aHouse) then Exit;

  //Number of simultaneous WIP houses is limited
  //if (P.Stats.GetHouseWip(ht_Any) > GetMaxPlans) then Exit;

  //Maybe we get more lucky next tick
  //todo: That only works if FindPlaceForHouse is quick, right now it takes ~11ms for iron/gold/coal mines (to decide that they can't be placed).
  //      If there's no place for the house we try again and again and again every update, so it's very inefficient
  //      I think the best solution would be to make FindPlaceForHouse only take a long time if we succeed in finding a place for the house, if we
  //      fail it should be quick. Doing a flood fill with radius=40 should really be avoided anyway, 11ms is a long time for placing 1 house.
  //      We could also make it not try to place houses again each update if it failed the first time, if we can't make FindPlaceForHouse quick when it fails.
  if not fCityPlanner.FindPlaceForHouse(aHouse, Loc) then Exit;

  //Place house before road, so that road is made around it
  P.AddHousePlan(aHouse, Loc);

  //Try to connect newly planned house to road network
  //if it is not possible - scrap the plan
  if not TryConnectToRoad(KMPointBelow(Loc)) then
  begin
    P.RemHousePlan(Loc);
    Exit;
  end;

  //Build fields for Farm
  if aHouse = ht_Farm then
    fCityPlanner.BuildFarmFields(Loc);

  //Build fields for Wineyard
  if aHouse = ht_Wineyard then
    fCityPlanner.BuildWineFields(Loc);

  //Build more roads around 2nd Store / Barracks
  if (aHouse = ht_Store) OR (aHouse = ht_Barracks) then
    //for I := Max(Loc.Y - 3, 1) to Min(Loc.Y + 2, gTerrain.MapY - 1) do   // When someone destroy your storehouse AI will not be able to replace it
    for I := Min(Loc.Y + 1, gTerrain.MapY - 1) to Min(Loc.Y + 2, gTerrain.MapY - 1) do
      for K := Max(Loc.X - 1, 1) to Min(Loc.X + 1, gTerrain.MapY - 1) do
      begin
        if P.CanAddFieldPlan(KMPoint(K, I), ft_Road) then
          P.BuildList.FieldworksList.AddField(KMPoint(K, I), ft_Road);
        gAIFields.Influences.AvoidBuilding[I,K] := $FF;
      end;

  //Block any buildings nearby
  if aHouse = ht_Woodcutters then
    AddWoodcutter(Loc, fCityPlanner.fForestCenterPoint, False);

  if gHands[fOwner].Locks.HouseCanBuild(ht_Woodcutters) then
  begin
    WoodcutLoc := Loc;
    Dec(WoodcutLoc.Y, 1);
    if fCityPlanner.CheckForChopOnlyWoodcutter(aHouse, WoodcutLoc) then
    begin
      P.AddHousePlan(ht_Woodcutters, WoodcutLoc);
      if TryConnectToRoad(KMPointBelow(WoodcutLoc)) then
        AddWoodcutter(WoodcutLoc, fCityPlanner.fForestCenterPoint, True)
      else
        P.RemHousePlan(WoodcutLoc);
    end;
  end;
  Result := True;
end;



//Demolish any exhausted mines, they will be rebuilt if needed
procedure TKMCityBuilder.CheckExhaustedMines;
var
  I: Integer;
  Houses: TKMHousesCollection;
  Loc: TKMPoint;
begin
  Houses := gHands[fOwner].Houses;

  //Wait until resource is depleted and output is empty
  for I := 0 to Houses.Count - 1 do
  if not Houses[I].IsDestroyed
  and Houses[I].ResourceDepletedMsgIssued
  and (Houses[I].CheckResOut(wt_All) = 0) then
  begin
    //Set it so we can build over coal that was removed
    if Houses[I].HouseType = ht_CoalMine then
    begin
      Loc := Houses[I].Entrance;
      gAIFields.Influences.RemAvoidBuilding(KMRect(Loc.X-3, Loc.Y-3, Loc.X+4, Loc.Y+2));
    end;
    Houses[I].DemolishHouse(fOwner);
  end;
end;

//Check if specific woodcutters are in Fell only mode
procedure TKMCityBuilder.CheckWoodcutters;
var
  I, J: Integer;
  Houses: TKMHousesCollection;
  H: TKMPoint;
  W: TKMHouseWoodcutters;
begin
  if Length(fWoodcuttersManagement) > 0 then
  begin
    Houses := gHands[fOwner].Houses;

    for J := 0 to Houses.Count - 1 do
      if (Houses[J].HouseType = ht_Woodcutters)
      and Houses[J].IsComplete
      and not Houses[J].IsDestroyed then
      begin
        H := Houses[J].GetPosition;
        I := 0;
        while I < Length(fWoodcuttersManagement) do
        begin
          if (H.X = fWoodcuttersManagement[I].Loc.X) AND (H.Y = fWoodcuttersManagement[I].Loc.Y) then
          begin
            W := TKMHouseWoodcutters(Houses[J]);
            W.CuttingPoint := fWoodcuttersManagement[I].ForestCenterPoint;
            W.ValidateCuttingPoint;
            if fWoodcuttersManagement[I].ChopOnly then
              W.WoodcutterMode := wcm_Chop;
            fWoodcuttersManagement[I] := fWoodcuttersManagement[ High(fWoodcuttersManagement) ];
            SetLength(fWoodcuttersManagement, Length(fWoodcuttersManagement) - 1);
            break;
          end;
          Inc(I);
        end;
      end;
  end;
end;

procedure TKMCityBuilder.CheckHouseCount;
var
  P: TKMHand;

  function MaxPlansForTowers: Integer;
  begin
    Result := GetMaxPlans;
    //Once there are 2 towers wip then allow balance to build something
    if (fBalance.Peek <> ht_None) and (P.Stats.GetHouseWip(ht_WatchTower) >= 2) then
      Result := Result - 1;
    Result := Max(1, Result);
  end;

var
  count: Byte;
  H: THouseType;
begin
  P := gHands[fOwner];

  //Try to express needs in terms of Balance = Production - Demand
  fBalance.Refresh;

  //Peek - see if we can build this house
  //Take - take this house into building
  //Reject - we can't build this house (that could affect other houses in queue)

  //Build towers if village is done, or peacetime is nearly over
  if P.Locks.HouseCanBuild(ht_WatchTower) then
    if ((fBalance.Peek = ht_None) and (P.Stats.GetHouseWip(ht_Any) = 0)) //Finished building
    or ((gGame.GameOptions.Peacetime <> 0) and gGame.CheckTime(600 * Max(0, gGame.GameOptions.Peacetime - 15))) then
      PlanDefenceTowers;

  if fDefenceTowersPlanned then
    while (fDefenceTowers.Count > 0) and (P.Stats.GetHouseWip(ht_Any) < MaxPlansForTowers) do
      TryBuildDefenceTower;

  count := GetMaxPlans;
  while count > 0 do
  begin
    H := fBalance.Peek;

    //There are no more suggestions
    if H = ht_None then
      Break;

    // Gold as soon as possible
    if (P.Stats.GetWareBalance(wt_Gold) < LACK_OF_GOLD + 5)
      AND (P.Stats.GetHouseQty(ht_Metallurgists) = 0)
      AND not (H in [ht_GoldMine, ht_Metallurgists, ht_CoalMine]) then
    begin
      fBalance.Reject;
      Continue;
    end;

    //See if we can build that
    if TryBuildHouse(H) then
    begin
      Dec(count, 1);
      fBalance.Take;
      fBalance.Refresh; //Balance will be changed by the construction of this house
    end
    else
      fBalance.Reject;
  end;

  //Check if we need to demolish depleted houses
  CheckExhaustedMines;

  //Check finished woodcuters to switch them into Fell only mode
  CheckWoodcutters;

  //Verify all plans are being connected with roads
  CheckHousePlans;

  //Try trade when we have not enought resources
  CheckMarketplaces;
end;


procedure TKMCityBuilder.CheckRoadsCount;
const
  SHORTCUT_CHECKS_PER_UPDATE = 10;
var
  P: TKMHand;
  Store: TKMHouse;
  StoreLoc: TKMPoint;
  I, K: Integer;
  FromLoc, ToLoc: TKMPoint;
  NodeList: TKMPointList;
  RoadExists: Boolean;
begin
  P := gHands[fOwner];

  //This is one time task to build roads around Store
  //When town becomes larger add road around Store to make traffic smoother
  if not fRoadBelowStore and (P.Stats.GetHouseQty(ht_Any) > 14) then
  begin
    fRoadBelowStore := True;

    Store := P.Houses.FindHouse(ht_Store, 0, 0, 1);
    if Store = nil then Exit;
    StoreLoc := Store.Entrance;

    for I := Max(StoreLoc.Y - 3, 1) to Min(StoreLoc.Y + 2, gTerrain.MapY - 1) do
    for K := StoreLoc.X - 2 to StoreLoc.X + 2 do
    if P.CanAddFieldPlan(KMPoint(K, I), ft_Road) then
      P.BuildList.FieldworksList.AddField(KMPoint(K, I), ft_Road);
  end;

  //Check if we need to connect separate branches of road network
  //Town has no plan and usually roadnetwork looks like a tree,
  //where we can improve it by connecting near branches with shortcuts.
  NodeList := TKMPointList.Create;
  try
    //See where our citizens are walking and build shortcuts where possible
    for I := 0 to gHands[fOwner].Units.Count - 1 do
    begin
      //Checking for shortcuts is slow, so skip some units randomly each update
      if KaMRandom(gHands[fOwner].Stats.GetUnitQty(ut_Serf)) >= SHORTCUT_CHECKS_PER_UPDATE then
        Continue;
      if not gHands[fOwner].Units[I].IsDeadOrDying
      and (gHands[fOwner].Units[I].GetUnitAction is TUnitActionWalkTo) then
        if ((gHands[fOwner].Units[I] is TKMUnitSerf) and (gHands[fOwner].Units[I].UnitTask is TTaskDeliver)
                                                     and (TTaskDeliver(gHands[fOwner].Units[I].UnitTask).DeliverKind <> dk_ToUnit))
        or ((gHands[fOwner].Units[I] is TKMUnitCitizen) and (gHands[fOwner].Units[I].UnitTask is TTaskGoEat)) then
        begin
          FromLoc := TUnitActionWalkTo(gHands[fOwner].Units[I].GetUnitAction).WalkFrom;
          ToLoc := TUnitActionWalkTo(gHands[fOwner].Units[I].GetUnitAction).WalkTo;
          //Unit's route must be using road network, not f.e. delivering to soldiers
          if gTerrain.Route_CanBeMade(FromLoc, ToLoc, tpWalkRoad, 0) then
          begin
            //Check for shortcuts we could build
            NodeList.Clear;
            RoadExists := fPathFindingRoadShortcuts.Route_Make(FromLoc, ToLoc, NodeList);

            if not RoadExists then
              Break;

            for K := 0 to NodeList.Count - 1 do
              //We must check if we can add the plan ontop of plans placed earlier in this turn
              if P.CanAddFieldPlan(NodeList[K], ft_Road) then
                P.BuildList.FieldworksList.AddField(NodeList[K], ft_Road);
          end;
        end;
    end;
  finally
    NodeList.Free;
  end;
end;
//}

end.

{
NavMesh - army vector field
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_NavMeshArmyVectorField;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_Defaults, KM_CommonTypes,
  KM_Points, KM_UnitGroup, KM_Houses,
  KM_NavMeshFloodFill, KM_ArmyAttackNew;

type
  TKMCombatStatus = (csNeutral = 0, csDefending, csCounterattack, csAttackingCity, csAttackingEverything);
  TKMCombatStatusArray = array[0..MAX_HANDS] of TKMCombatStatus;
  TKMArmyVectorFFType = (ffEnemy, ffRally, ffSearch);

  TKMAllianceAsset = record
    // GroupsNumber = real number of groups, GroupsCount = count of groups in arrays
    GroupsCount, HousesCount, GroupsNumber, OwnersCount: Word;
    Groups: TKMUnitGroupArray;
    Houses: TKMHouseArray;
    GroupsPoly, HousesPoly: TKMWordArray;
  end;

  // Combat cluster
  TKMCombatCluster = record
    ReferenceID, GroupsCount, HousesCount: Word;
    Groups, Houses: TKMWordArray;
  end;
  TKMCombatClusters = record
    Count, UnreferencedCount: Word;
    Clusters: array of TKMCombatCluster;
  end;
  pTKMCombatCluster = ^TKMCombatCluster;
  // Evaluation of cluster (it is separated from TKMCombatCluster because of merging clusters in Flood Fill)
  TKMGroupCounterWeight = record
    Idx: Word;
    Group: TKMUnitGroup;
    TargetPosition: TKMPointDir;
    Status: Boolean;
    CG: TKMCombatGroup;
  end;
  pTKMGroupCounterWeight = ^TKMGroupCounterWeight;
  TKMGroupCounterWeightArray = array of TKMGroupCounterWeight;
  pTKMGroupCounterWeightArray = array of pTKMGroupCounterWeight;
  TKMCombatClusterThreat = record
    AttackingCity: Boolean;
    ClusterIdx: Word;
    BestDist, Threat, ThreatNearby: Single;
    Cluster: pTKMCombatCluster;
    CenterPoint: TKMPoint;
    Owners: TKMHandIDArray;
    CounterWeight: record
      InPlace, AtAdvantage, Ambushed: Boolean;
      GroupsCount, CGCount, InPositionCnt, InClusterCnt, NearEnemyCnt: Word;
      Opportunity, InPositionStrength: Single;
      WeightedCount: array[GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Word;
      Groups: TKMGroupCounterWeightArray;
    end;
  end;
  TKMCombatClusterThreatArray = array of TKMCombatClusterThreat;

  TKMVectorField = array of record
    Enemy, RallyPoint: Word;
    //AvoidTraffic: Word;
  end;
  {$IFDEF DEBUG_ArmyVectorField}
    TDebugArmyVectorField = array of record
      Enemy: TKMAllianceAsset;
      Ally: TKMAllianceAsset;
      Alliance: TKMHandIDArray;
      Clusters: TKMCombatClusters;
      CCT: TKMCombatClusterThreatArray;
      ClustersMapp: TKMWordArray;
      VectorFields: array of TKMVectorField;
    end;
  {$ENDIF}

  TKMCalculateDistance = function(const aNavMeshIdx, aNearbyIdx: Word): Word of object;
  TKMAssignDistance = procedure(const aIdx, aDistance: Word) of object;

  TKMFindClusters = class;
  TKMArmyVectorField = class;

  TKMFindClusters = class(TNavMeshFloodFill)
  private
  protected
    fClusters: TKMCombatClusters;
    fClusterMapping: TKMWordArray;

    procedure InitQueue(var aEnemy: TKMAllianceAsset); reintroduce;
    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aClusterID: Word; const aDistance: Cardinal; const aPoint: TKMPoint); reintroduce;
    procedure ExpandPolygon(aIdx: Word; aCanBeExpanded: Boolean);
    procedure Flood(var aEnemy: TKMAllianceAsset); reintroduce;
  public
    function FindClusters(var aClusters: TKMCombatClusters; var aAllianceInfo: TKMAllianceAsset; var aClusterMapping: TKMWordArray; var aQueueArray: TPolygonsQueueArr): Word;
  end;


  TKMArmyVectorField = class(TNavMeshFloodFill)
  private
  protected
    fOwner: TKMHandID;
    fOwners: TKMHandIDArray;
    fPolygonsCnt, fCntAllyPoly, fCntEnemyPoly: Word;
    fClusterMapping: TKMWordArray;
    fVectorField: TKMVectorField;
    fFindClusters: TKMFindClusters;
    fClusters: TKMCombatClusters;
    {$IFDEF DEBUG_ArmyVectorField}
      fTimeAvrgEnemyPresence, fTimeAvrgDivideForces, fTimeAvrgFindPositions: Int64;
      fTimePeakEnemyPresence, fTimePeakDivideForces, fTimePeakFindPositions: Int64;
      fDbgVector: TDebugArmyVectorField;
    {$ENDIF}

    procedure MakeNewQueue(aClearVectorField: Boolean = True); reintroduce;
    procedure AddPolyToQueue(aFFType: TKMArmyVectorFFType; aIdx: Word);
    procedure InitQueue(const aCluster: pTKMCombatCluster); reintroduce; overload;
    procedure InitQueue(const aGroupsPoly: TKMWordArray; aCnt: Word); reintroduce; overload;
    procedure InitQueue(const aGroupPoly: Word); reintroduce; overload;
    function CalculateDistanceRallyPoint(const aNavMeshIdx, aNearbyIdx: Word): Word;
    function CalculateDistanceEnemy(const aNavMeshIdx, aNearbyIdx: Word): Word;
    procedure AssignDistanceRallyPoint(const aIdx, aDistance: Word);
    procedure AssignDistanceEnemy(const aIdx, aDistance: Word);
    procedure Flood(aCalulateDistance: TKMCalculateDistance; aAssignDistance: TKMAssignDistance); reintroduce;
    function CanBeExpanded(const aIdx: Word): Boolean; override;
    function SearchFlood(): Word;

    function GetInitPolygonsGroups(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceAsset): Boolean;
    function GetInitPolygonsHouses(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceAsset; aOnlyCompleted: Boolean = True): Boolean;

    procedure InitClusterEvaluation();

    {$IFDEF DEBUG_ArmyVectorField}
      function GetAllianceIdxFromDebugArray(): Integer;
      procedure CopyVectorFieldForDebug(aIdx: Word);
      procedure CopyVariablesForDebug1();
      procedure CopyVariablesForDebug2();
      function GenerateColorWSeed(aIdx: Integer): Cardinal;
      function GetCCTIdxFromGroup(aG: TKMUnitGroup): Integer;
    {$ENDIF}
  public
    Enemy: TKMAllianceAsset;
    Ally: TKMAllianceAsset;
    CCT: TKMCombatClusterThreatArray;

    constructor Create(aSorted: Boolean = True); override;
    destructor Destroy; override;

    property Clusters: TKMCombatClusters read fClusters;
    property QueueArray: TPolygonsQueueArr read fQueueArray;
    property ClusterMapping: TKMWordArray read fClusterMapping;

    function DetectEnemyPresence(var aOwners: TKMHandIDArray): Boolean;
    procedure DivideForces(aCS: TKMCombatStatus; var aCSA: TKMCombatStatusArray);
    procedure FindPositions();

    function LogStatus(): UnicodeString;
    procedure Paint();
  end;


const
  MAX_CLUSTER_DISTANCE = 10;


implementation
uses
  SysUtils,
  KM_Hand, KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_Terrain,
  KM_AIFields, KM_NavMesh, KM_AIParameters,
  {$IFDEF DEBUG_ArmyVectorField}
  DateUtils, KM_CommonUtils,
  {$ENDIF}
  KM_RenderAux,
  KM_ResTypes;


{ TKMFindClusters }
function TKMFindClusters.CanBeExpanded(const aIdx: Word): Boolean;
begin
  Result := fQueueArray[aIdx].Distance < MAX_CLUSTER_DISTANCE;
end;


procedure TKMFindClusters.MarkAsVisited(const aIdx, aClusterID: Word; const aDistance: Cardinal; const aPoint: TKMPoint);
begin
  inherited MarkAsVisited(aIdx, aDistance, aPoint);
  fClusterMapping[aIdx] := aClusterID;
end;


procedure TKMFindClusters.InitQueue(var aEnemy: TKMAllianceAsset);
  function CreateNewCluster(aPolyIdx: Word): Integer;
  begin
    Result := fClusters.Count;
    MarkAsVisited(aPolyIdx, Result, 0, gAIFields.NavMesh.Polygons[aPolyIdx].CenterPoint);
    InsertAndSort(aPolyIdx);
    with fClusters.Clusters[Result] do
    begin
      ReferenceID := Result; // Reference to itself
      GroupsCount := 0;
      HousesCount := 0;
      SetLength(Groups,4); // Create new array
      SetLength(Houses,4); // Create new array
    end;
    Inc(fClusters.Count);
  end;
  procedure AddWordField(aFied: Integer; var aCount: Word; var aArr: TKMWordArray); inline;
  begin
    if (Length(aArr) <= aCount) then
      SetLength(aArr,Length(aArr) + 4);
    aArr[ aCount ] := aFied;
    aCount := aCount + 1;
  end;
var
  K, PolyIdx, ClusterIdx: Integer;
begin
  fVisitedIdx := 1;
  fQueueCnt := 0;
  fClusters.Count := 1; // 0. index is reserved
  if (Length(fClusters.Clusters) < aEnemy.GroupsCount + aEnemy.HousesCount + 1) then // +1 because 0. index is reserved
    SetLength(fClusters.Clusters, aEnemy.GroupsCount + aEnemy.HousesCount + 1);
  // Copy groups
  for K := 0 to aEnemy.GroupsCount - 1 do
  begin
    PolyIdx := aEnemy.GroupsPoly[K];
    if IsVisited(PolyIdx) then
      ClusterIdx := fClusterMapping[PolyIdx]
    else
      ClusterIdx := CreateNewCluster(PolyIdx);
    with fClusters.Clusters[ClusterIdx] do
      AddWordField(K, GroupsCount, Groups);
  end;
  // Copy houses
  for K := 0 to aEnemy.HousesCount - 1 do
  begin
    PolyIdx := aEnemy.HousesPoly[K];
    if IsVisited(PolyIdx) then
      ClusterIdx := fClusterMapping[PolyIdx]
    else
      ClusterIdx := CreateNewCluster(PolyIdx);
    with fClusters.Clusters[ClusterIdx] do
      AddWordField(K, HousesCount, Houses);
  end;
end;


procedure TKMFindClusters.ExpandPolygon(aIdx: Word; aCanBeExpanded: Boolean);
var
  K, L, NearbyIdx, RefID, NearbyRefID: Integer;
begin
  RefID := fClusters.Clusters[ fClusterMapping[aIdx] ].ReferenceID;
  for K := 0 to gAIFields.NavMesh.Polygons[aIdx].NearbyCount-1 do
  begin
    NearbyIdx := gAIFields.NavMesh.Polygons[aIdx].Nearby[K];
    // Expand polygon
    if not IsVisited(NearbyIdx) then
    begin
      if aCanBeExpanded then
      begin
        MarkAsVisited( NearbyIdx, RefID,
                       fQueueArray[aIdx].Distance + KMDistanceWalk(fQueueArray[aIdx].DistPoint, gAIFields.NavMesh.Polygons[aIdx].NearbyPoints[K]),
                       gAIFields.NavMesh.Polygons[aIdx].NearbyPoints[K]);
        InsertAndSort(NearbyIdx);
      end;
    end
    // Merge clusters by changing reference (faster than copying arrays)
    else
    begin
      NearbyRefID := fClusters.Clusters[ fClusterMapping[NearbyIdx] ].ReferenceID;
      if (RefID <> NearbyRefID) then
        for L := 1 to fClusters.Count - 1 do
          if (fClusters.Clusters[L].ReferenceID = NearbyRefID) then
            fClusters.Clusters[L].ReferenceID := RefID;
    end;
  end;
end;


procedure TKMFindClusters.Flood(var aEnemy: TKMAllianceAsset);
var
  Idx: Word;
begin
  InitQueue(aEnemy);
  if (fQueueCnt <= 0) then
    Exit;

  // Start merging clusters
  Idx := fStartQueue;
  while RemoveFromQueue(Idx) do
    ExpandPolygon(Idx, CanBeExpanded(Idx));
end;


function TKMFindClusters.FindClusters(var aClusters: TKMCombatClusters; var aAllianceInfo: TKMAllianceAsset; var aClusterMapping: TKMWordArray; var aQueueArray: TPolygonsQueueArr): Word;
var
  K,L,Cnt: Integer;
begin
  // Check groups and houses
  if (aAllianceInfo.GroupsCount = 0) AND (aAllianceInfo.HousesCount = 0) then
    Exit(1);
  // Copy variables
  fClusterMapping := aClusterMapping;
  fQueueArray := aQueueArray; // This is clear array with zeros
  // Find clusters
  Flood(aAllianceInfo);
  // Merge clusters (do it just once instead in every polygon)
  fClusters.UnreferencedCount := 0;
  for K := 1 to fClusters.Count - 1 do
    if (K = fClusters.Clusters[K].ReferenceID) then
    begin
      Inc(fClusters.UnreferencedCount);
      for L := 1 to fClusters.Count - 1 do
        if (K <> L) AND (fClusters.Clusters[L].ReferenceID = fClusters.Clusters[K].ReferenceID) then
        begin
          // Copy groups
          Cnt := fClusters.Clusters[K].GroupsCount;
          if (fClusters.Clusters[L].GroupsCount > 0) then
          begin
            Inc(fClusters.Clusters[K].GroupsCount, fClusters.Clusters[L].GroupsCount);
            if (Length(fClusters.Clusters[K].Groups) < fClusters.Clusters[K].GroupsCount) then
              SetLength(fClusters.Clusters[K].Groups, fClusters.Clusters[K].GroupsCount + 16);
            Move(fClusters.Clusters[L].Groups[0], fClusters.Clusters[K].Groups[Cnt], SizeOf(fClusters.Clusters[K].Groups[0]) * fClusters.Clusters[L].GroupsCount);
          end;
          // Copy houses
          Cnt := fClusters.Clusters[K].HousesCount;
          if (fClusters.Clusters[L].HousesCount > 0) then
          begin
            Inc(fClusters.Clusters[K].HousesCount, fClusters.Clusters[L].HousesCount);
            if (Length(fClusters.Clusters[K].Houses) < fClusters.Clusters[K].HousesCount) then
              SetLength(fClusters.Clusters[K].Houses, fClusters.Clusters[K].HousesCount + 8);
            Move(fClusters.Clusters[L].Houses[0], fClusters.Clusters[K].Houses[Cnt], SizeOf(fClusters.Clusters[K].Houses[0]) * fClusters.Clusters[L].HousesCount);
          end;
        end;
    end;

  aClusters := fClusters;
  Result := fVisitedIdx;
end;




{ TKMArmyVectorField }
constructor TKMArmyVectorField.Create(aSorted: Boolean = True);
begin
  inherited Create(aSorted);

  fFindClusters := TKMFindClusters.Create(aSorted);
  {$IFDEF DEBUG_ArmyVectorField}
  SetLength(fDbgVector, 0);
  fTimeAvrgEnemyPresence := 0;
  fTimeAvrgDivideForces := 0;
  fTimeAvrgFindPositions := 0;
  fTimePeakEnemyPresence := 0;
  fTimePeakDivideForces := 0;
  fTimePeakFindPositions := 0;
  {$ENDIF}
end;


destructor TKMArmyVectorField.Destroy();
begin
  fFindClusters.Free;

  inherited;
end;


function TKMArmyVectorField.GetInitPolygonsGroups(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceAsset): Boolean;
  // Dont add the same polygon for 1 group twice
  function CheckIdenticalPolygons(aStartIdx: Integer): Word;
  var
    K: Integer;
  begin
    with aAlliance do
      for K := aStartIdx to GroupsCount - 1 do
        if (GroupsPoly[K] = GroupsPoly[GroupsCount]) then
          Exit(0);
    Result := 1;
  end;
var
  PL: TKMHandID;
  K, L, StartIdx: Integer;
  G: TKMUnitGroup;
begin
  with aAlliance do
  begin
    OwnersCount := 0;
    GroupsCount := 0;
    GroupsNumber := 0;
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = aAllianceType) AND ((aAllianceType <> atAlly) OR gHands[PL].AI.Setup.NewAI) then
      begin
        Inc(OwnersCount);
        for K := 0 to gHands[PL].UnitGroups.Count - 1 do
        begin
          G := gHands[PL].UnitGroups.Groups[K];
          if (G <> nil) AND not G.IsDead AND not KMSamePoint(KMPOINT_ZERO,G.Position) then
            //AND ((aAllianceType <> atAlly) OR gHands[PL].AI.ArmyManagement.AttackNew.IsGroupInAction(G)) then // Select only combat groups
          begin
            Inc(GroupsNumber);
            L := 0;
            StartIdx := GroupsCount;
            while (L < G.Count) do
            begin
              if (G.Members[L] <> nil) AND not G.Members[L].IsDeadOrDying then
              begin
                if (Length(GroupsPoly) <= GroupsCount) then
                begin
                  SetLength(GroupsPoly, GroupsCount + 20);
                  SetLength(Groups, Length(GroupsPoly));
                end;
                GroupsPoly[GroupsCount] := gAIFields.NavMesh.KMPoint2Polygon[ G.Members[L].Position ];
                Groups[GroupsCount] := G;
                Inc(GroupsCount,CheckIdenticalPolygons(StartIdx));
                L := L + 5;
              end
              else
                L := L + 1;
            end;
          end;
        end;
      end;
    SetLength(GroupsPoly, GroupsCount);
    SetLength(Groups, GroupsCount);
    Result := GroupsCount > 0;
  end;
end;


function TKMArmyVectorField.GetInitPolygonsHouses(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceAsset; aOnlyCompleted: Boolean = True): Boolean;
var
  PL: TKMHandID;
  K: Integer;
  H: TKMHouse;
begin
  with aAlliance do
  begin
    OwnersCount := 0;
    HousesCount := 0;
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = aAllianceType) then
      begin
        Inc(OwnersCount);
        for K := 0 to gHands[PL].Houses.Count - 1 do
        begin
          H := gHands[PL].Houses[K];
          if (H <> nil)
            AND not H.IsDestroyed
            AND ((H.HouseType in gHands[fOwner].AI.ArmyManagement.ArmyVectorFieldScanHouses)
                    or (htAny in gHands[fOwner].AI.ArmyManagement.ArmyVectorFieldScanHouses))
            AND (not aOnlyCompleted OR H.IsComplete) then
          begin
            if (Length(Houses) <= HousesCount) then
            begin
              SetLength(HousesPoly, HousesCount + 10);
              SetLength(Houses, Length(HousesPoly));
            end;
            HousesPoly[HousesCount] := gAIFields.NavMesh.KMPoint2Polygon[ H.Entrance ];
            Houses[HousesCount] := H;
            Inc(HousesCount);
          end;
        end;
      end;
    SetLength(HousesPoly, HousesCount);
    SetLength(Houses, HousesCount);
    Result := HousesCount > 0;
  end;
end;


function TKMArmyVectorField.DetectEnemyPresence(var aOwners: TKMHandIDArray): Boolean;
{$IFDEF DEBUG_ArmyVectorField}
var
  Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_ArmyVectorField}
    Time := TimeGetUsec();
  {$ENDIF}
  fOwners := aOwners;
  fOwner := aOwners[0];
  GetInitPolygonsGroups(atEnemy, Enemy);
  GetInitPolygonsHouses(atEnemy, Enemy);
  Result := (Enemy.GroupsCount > 0) OR (Enemy.HousesCount > 0);
  if Result then
  begin
    MakeNewQueue();
    fVisitedIdx := fFindClusters.FindClusters(fClusters, Enemy, fClusterMapping, fQueueArray);
    GetInitPolygonsGroups(atAlly, Ally);
    InitClusterEvaluation();
  end;
  {$IFDEF DEBUG_ArmyVectorField}
    Time := TimeGetUsec() - Time;
    fTimeAvrgEnemyPresence := Round((fTimeAvrgEnemyPresence * 5 + Time) / 6);
    fTimePeakEnemyPresence := Max(fTimePeakEnemyPresence, Time);
  {$ENDIF}
end;


procedure TKMArmyVectorField.InitClusterEvaluation();
var
  OwnerDetected, GroupCheck: Boolean;
  K, L, M, Cnt, OwnersCnt: Integer;
  G: TKMUnitGroup;
begin
  // Clear mess before FillChar
  for K := Low(CCT) to High(CCT) do
    with CCT[K] do
    begin
      SetLength(Owners,0);
      SetLength(CounterWeight.Groups,0);
    end;

  SetLength(CCT, fClusters.UnreferencedCount);
  if (Length(CCT) <= 0) then
    Exit;
  FillChar(CCT[0], Length(CCT) * SizeOf(CCT[0]), #0);

  // Init CCT + check if clusters are in the hostile city
  Cnt := 0;
  for K := 1 to fClusters.Count - 1 do
    if (fClusters.Clusters[K].ReferenceID = K) then // Skip unreferenced clusters
    begin
      CCT[Cnt].ClusterIdx := K;
      CCT[Cnt].BestDist := 1E10;
      CCT[Cnt].Cluster := @fClusters.Clusters[K];
      SetLength(CCT[Cnt].Owners, Enemy.OwnersCount);
      OwnersCnt := 0;
      // Filter duplicates (group with 100 soldiers has multiple fields in the array)
      L := 1;
      while (L < fClusters.Clusters[K].GroupsCount) do
      begin
        GroupCheck := True;
        for M := 0 to L - 1 do
          if (Enemy.Groups[ fClusters.Clusters[K].Groups[L] ] = Enemy.Groups[ fClusters.Clusters[K].Groups[M] ]) then
          begin
            GroupCheck := False;
            break;
          end;
        if not GroupCheck then
        begin
          Dec(fClusters.Clusters[K].GroupsCount);
          // Use the first polygon
          fClusters.Clusters[K].Groups[M] :=  min(fClusters.Clusters[K].Groups[M], fClusters.Clusters[K].Groups[L]);
          fClusters.Clusters[K].Groups[L] := fClusters.Clusters[K].Groups[ fClusters.Clusters[K].GroupsCount ];
        end
        else
          Inc(L);
      end;
      // Evaluate groups
      for L := 0 to fClusters.Clusters[K].GroupsCount - 1 do
      begin
        G := Enemy.Groups[ fClusters.Clusters[K].Groups[L] ];
        CCT[Cnt].CenterPoint := KMPointAdd(CCT[Cnt].CenterPoint,G.Position);
        CCT[Cnt].Threat := CCT[Cnt].Threat + G.Count;
        OwnerDetected := False;
        for M := 0 to OwnersCnt - 1 do
          OwnerDetected := OwnerDetected OR (CCT[Cnt].Owners[M] = G.Owner);
        if not OwnerDetected then
        begin
          CCT[Cnt].Owners[OwnersCnt] := G.Owner;
          Inc(OwnersCnt);
        end;
      end;
      for L := 0 to fClusters.Clusters[K].HousesCount - 1 do
        CCT[Cnt].CenterPoint := KMPointAdd(CCT[Cnt].CenterPoint,Enemy.Houses[ fClusters.Clusters[K].Houses[L] ].Position);
      SetLength(CCT[Cnt].Owners, OwnersCnt);
      CCT[Cnt].CenterPoint.X := Round(CCT[Cnt].CenterPoint.X / Max(1,fClusters.Clusters[K].GroupsCount + fClusters.Clusters[K].HousesCount));
      CCT[Cnt].CenterPoint.Y := Round(CCT[Cnt].CenterPoint.Y / Max(1,fClusters.Clusters[K].GroupsCount + fClusters.Clusters[K].HousesCount));
      Inc(Cnt);
    end;
end;


procedure TKMArmyVectorField.DivideForces(aCS: TKMCombatStatus; var aCSA: TKMCombatStatusArray);
var
  PowerLeft: Single;
  AssignedGroups: TBooleanArray;

  procedure AddGroup(aGroupIdx, aCCTIdx: Integer);
  var
    K: Integer;
  begin
    // Mark as assigned
    for K := aGroupIdx to Ally.GroupsCount - 1 do
    begin
      AssignedGroups[K] := True;
      if (K < Ally.GroupsCount - 1) AND (Ally.Groups[K] <> Ally.Groups[K + 1]) then
        Break;
    end;
    // Negative index = no cluster was found => Exit
    if (aCCTIdx < 0) then
      Exit;
    // Add group to array
    with CCT[aCCTIdx].CounterWeight do
    begin
      if (Length(Groups) <= GroupsCount) then
        SetLength(Groups, GroupsCount + 16);
      Groups[ GroupsCount ].Idx := aGroupIdx;
      Groups[ GroupsCount ].Group := Ally.Groups[aGroupIdx];
      Inc(GroupsCount);
    end;
    PowerLeft := PowerLeft - Ally.Groups[aGroupIdx].Count;
    CCT[aCCTIdx].CounterWeight.Opportunity := CCT[aCCTIdx].CounterWeight.Opportunity + Ally.Groups[aGroupIdx].Count;
  end;
const
  PRIO_1_MIN_DISTANCE = 20;
  GAIN_GROUPS_PER_A_HOUSE = 3;
  PENALIZATION_GROUPS_CNT = 100;
  OpportunityArr: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX, GROUP_TYPE_MIN..GROUP_TYPE_MAX] of Single = (
  // gtMelee, gtAntiHorse, gtRanged, gtMounted
    (    1.0,         2.0,      3.0,       0.5), // gtMelee
    (    0.5,         1.0,      2.0,       4.0), // gtAntiHorse
    (    1.0,         2.0,      3.0,       0.5), // gtRanged
    (    1.0,         0.2,      5.0,       1.0)  // gtMounted
  );
var
  WalkableID: Byte;
  K, L, M, BestCCTIdx, BestGIdx, Overflow, Overflow2: Integer;
  Distance, BestDistance, SoldiersCnt: Single;
  P, HouseEntrance: TKMPoint;
  CenterPoints: TKMPointArray;
  Pf: TKMPointF;
  PL: TKMHandID;
  Distances: TSingleArray;
  G: TKMUnitGroup;
{$IFDEF DEBUG_ArmyVectorField}
  Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_ArmyVectorField}
    Time := TimeGetUsec();
  {$ENDIF}
  if (Ally.GroupsCount <= 0) then
    Exit;

  // 1. Prio = distance from enemy cluster
  SetLength(AssignedGroups, Ally.GroupsCount);
  FillChar(AssignedGroups[0], SizeOf(AssignedGroups[0]) * Length(AssignedGroups), #0);
  G := nil;
  PowerLeft := 0; // It will be filled within following loop
  for K := 0 to Ally.GroupsCount - 1 do
  begin
    PowerLeft := PowerLeft + Ally.Groups[K].Count;
    if (G <> Ally.Groups[K]) AND (fQueueArray[ Ally.GroupsPoly[K] ].Visited > 0) AND (fQueueArray[ Ally.GroupsPoly[K] ].Distance <= PRIO_1_MIN_DISTANCE) then // Ignore threat at this distance
    begin
      BestCCTIdx := fClusters.Clusters[ fClusterMapping[ Ally.GroupsPoly[K] ] ].ReferenceID;
      for L := Low(CCT) to High(CCT) do
        if (CCT[L].Cluster = @fClusters.Clusters[BestCCTIdx]) then
        begin
          AddGroup(K, L);
          Break;
        end;
    end;
    G := Ally.Groups[K]; // Skip following group if it is the same group
  end;

  if (PowerLeft <= 0) then
    Exit;

  // 2. Prio = defend city
  Overflow := 0;
  repeat
    Inc(Overflow);
    // Loop over the cluster to find the worst threat (faster than sorting it)
    BestGIdx := -1;
    BestCCTIdx := -1;
    for K := 0 to Length(CCT) - 1 do
      if (CCT[K].AttackingCity) AND ((BestCCTIdx < 0)
        OR (CCT[BestCCTIdx].ThreatNearby - CCT[BestCCTIdx].CounterWeight.Opportunity * AI_Par[ATTACK_ArmyVectorField_DivideForces_DefendCityAdv] < CCT[K].ThreatNearby - CCT[K].CounterWeight.Opportunity * AI_Par[ATTACK_ArmyVectorField_DivideForces_DefendCityAdv])) then
        BestCCTIdx := K;
    // Find closest groups
    if (BestCCTIdx >= 0) AND (CCT[BestCCTIdx].AttackingCity) AND (CCT[BestCCTIdx].ThreatNearby > 0) then
    begin
      if (Length(Distances) < Ally.GroupsCount) then
        SetLength(Distances,Ally.GroupsCount);
      for K := 0 to Ally.GroupsCount - 1 do
        Distances[K] := KMDistanceSqr(CCT[BestCCTIdx].CenterPoint,Ally.Groups[K].Position);

      Overflow2 := 0;
      while (Overflow2 < 1000) AND (CCT[BestCCTIdx].ThreatNearby > CCT[BestCCTIdx].CounterWeight.Opportunity * AI_Par[ATTACK_ArmyVectorField_DivideForces_DefendCityAdv]) do
      begin
        Inc(Overflow2);
        BestGIdx := -1;
        for K := 0 to Ally.GroupsCount - 1 do
          if not AssignedGroups[K] AND ((BestGIdx < 0) OR (Distances[K] < Distances[BestGIdx])) then
            BestGIdx := K;
        if (BestGIdx < 0) then
          Break;
        AddGroup(BestGIdx, BestCCTIdx);
      end;
    end;
  until (Overflow > 100) OR (BestCCTIdx = -1) OR (BestGIdx = -1);

  if (PowerLeft <= 0) then
    Exit;

  // 3. Prio - support ally in fight
  Overflow := 0;
  repeat
    Inc(Overflow);
    // Loop over the cluster to find the worst threat (faster than sorting it)
    BestGIdx := -1;
    BestCCTIdx := -1;
    for K := 0 to Length(CCT) - 1 do
      if (CCT[K].CounterWeight.Opportunity > 0) AND ((BestCCTIdx < 0) OR (CCT[BestCCTIdx].ThreatNearby - CCT[BestCCTIdx].CounterWeight.Opportunity * AI_Par[ATTACK_ArmyVectorField_DivideForces_SupportAllyAdv] < CCT[K].ThreatNearby - CCT[K].CounterWeight.Opportunity * AI_Par[ATTACK_ArmyVectorField_DivideForces_SupportAllyAdv])) then
        BestCCTIdx := K;
    // Find closest groups
    if (BestCCTIdx >= 0) then
    begin
      if (Length(Distances) < Ally.GroupsCount) then
        SetLength(Distances,Ally.GroupsCount);
      for K := 0 to Ally.GroupsCount - 1 do
        Distances[K] := KMDistanceSqr(CCT[BestCCTIdx].CenterPoint,Ally.Groups[K].Position);

      Overflow2 := 0;
      while (Overflow2 < 1000) AND (CCT[BestCCTIdx].ThreatNearby > CCT[BestCCTIdx].CounterWeight.Opportunity * AI_Par[ATTACK_ArmyVectorField_DivideForces_SupportAllyAdv]) do
      begin
        Inc(Overflow2);
        BestGIdx := -1;
        for K := 0 to Ally.GroupsCount - 1 do
          if not AssignedGroups[K] AND ((BestGIdx < 0) OR (Distances[K] < Distances[BestGIdx])) then
            BestGIdx := K;
        if (BestGIdx < 0) then
          Break;
        AddGroup(BestGIdx, BestCCTIdx);
      end;
    end;
  until (Overflow > 100) OR (BestCCTIdx = -1) OR (BestGIdx = -1);;

  if (PowerLeft <= 0) then
    Exit;

  // Find common enemy
  if (aCS in [csCounterattack, csAttackingCity, csAttackingEverything]) then
  begin
    // Get center points of players
    SetLength(CenterPoints, length(fOwners));
    for K := Low(fOwners) to High(fOwners) do
    begin
      PL := fOwners[K];
      // Get center point of 1 player
      SoldiersCnt := 0;
      Pf := KMPOINTF_ZERO;
      for L := 0 to Ally.GroupsCount - 1 do
        with Ally.Groups[L] do
          if (Owner = PL) then
          begin
            SoldiersCnt := SoldiersCnt + Count; // Weighted average
            Pf.X := Pf.X + Position.X * Count;
            Pf.Y := Pf.Y + Position.Y * Count;
          end;
      CenterPoints[K] := KMPOINT_ZERO;
      if (SoldiersCnt = 0) then
        Continue;
      CenterPoints[K] := KMPoint(  Round(Pf.X / SoldiersCnt), Round(Pf.Y / SoldiersCnt)  );
    end;

    // Check 250 areas (in reality only 2 loops should be required)
    for K := 0 to 250 do
    begin
      // Get WalkConnectID
      WalkableID := High(Byte);
      for L := 0 to Ally.GroupsCount - 1 do
        if not AssignedGroups[L] then
        begin
          WalkableID := gTerrain.GetWalkConnectID(Ally.Groups[L].Position);
          break;
        end;
      // Return if all groups are assigned
      if (WalkableID = High(Byte)) then
        break;
      // Compute distance
      BestDistance := 1E10;
      for L := Low(fOwners) to High(fOwners) do
      begin
        // Target = city (clusters with houses) OR every cluster if there are no houses
        for M := Low(CCT) to High(CCT) do
          if ((CCT[M].Cluster.HousesCount > 0) AND (WalkableID = gTerrain.GetWalkConnectID(KMPointBelow(Enemy.Houses[ CCT[M].Cluster.Houses[0] ].Entrance))))
            OR ((Enemy.HousesCount = 0)        AND (WalkableID = gTerrain.GetWalkConnectID(             Enemy.Groups[ CCT[M].Cluster.Groups[0] ].Position ))) then
          begin
            Distance := KMDistanceSqr(CCT[M].CenterPoint, CenterPoints[L]);
            if (Distance < BestDistance) then
            begin
              BestDistance := Distance;
              BestCCTIdx := M;
            end;
          end;
      end;
      // Exit if no cluster has been found
      if (BestDistance = 1E10) then
        BestCCTIdx := -1;
      // Assign groups
      for L := 0 to Ally.GroupsCount - 1 do
        if not AssignedGroups[L] AND (gTerrain.GetWalkConnectID(Ally.Groups[L].Position) = WalkableID) then
          AddGroup(L, BestCCTIdx);
    end;
  end
  else
  begin
    // 4. Prio - Defend city
    for K := 0 to Ally.GroupsCount - 1 do
      if not AssignedGroups[K] then
      begin
        BestCCTIdx := 0;
        BestDistance := 1E10;
        P := Ally.Groups[K].Position;
        for L := 1 to Length(CCT) - 1 do
          if (CCT[L].AttackingCity) then
          begin
            Distance := KMDistanceSqr(CCT[L].CenterPoint,P);
            if (BestDistance > Distance) then
            begin
              BestDistance := Distance;
              BestCCTIdx := L;
            end;
          end;
        if (BestDistance < 1E10) then
          AddGroup(K, BestCCTIdx);
      end;
  end;
  {$IFDEF DEBUG_ArmyVectorField}
    Time := TimeGetUsec() - Time;
    fTimeAvrgDivideForces := Round((fTimeAvrgDivideForces * 5 + Time) / 6);
    fTimePeakDivideForces := Max(fTimePeakDivideForces, Time);
  {$ENDIF}
end;


// Prepare new Queue
procedure TKMArmyVectorField.MakeNewQueue(aClearVectorField: Boolean = True);
begin
  // Check length
  fPolygonsCnt := gAIFields.NavMesh.PolygonsCnt;
  if (Length(fQueueArray) < fPolygonsCnt) then
  begin
    SetLength(fQueueArray, fPolygonsCnt);
    SetLength(fClusterMapping, fPolygonsCnt);
    SetLength(fVectorField, fPolygonsCnt);
    FillChar(fVectorField[0], SizeOf(fVectorField[0]) * Length(fVectorField), #0);
  end;
  // Clear queue
  fQueueCnt := 0;
  ClearVisitIdx();
  // Distance will be changed so clear array
  if aClearVectorField then
    FillChar(fClusterMapping[0], SizeOf(fClusterMapping[0]) * Length(fClusterMapping), #0);
end;


procedure TKMArmyVectorField.AddPolyToQueue(aFFType: TKMArmyVectorFFType; aIdx: Word);
const
  INIT_DISTANCE_QUEUE = 0;
begin
  if not IsVisited(aIdx) then
  begin
    MarkAsVisited(aIdx, INIT_DISTANCE_QUEUE, gAIFields.NavMesh.Polygons[ aIdx ].CenterPoint);
    InsertInQueue(aIdx);
    case aFFType of
      ffEnemy: fVectorField[aIdx].Enemy      := INIT_DISTANCE_QUEUE;
      ffRally: fVectorField[aIdx].RallyPoint := fVectorField[aIdx].RallyPoint;
      ffSearch: begin end;
    end;
  end;
end;


procedure TKMArmyVectorField.InitQueue(const aCluster: pTKMCombatCluster);
var
  K, L, Poly: Integer;
begin
  Inc(fVisitedIdx);
  for K := 0 to aCluster.GroupsCount - 1 do
  begin
    L := aCluster.Groups[K];
    Poly := Enemy.GroupsPoly[L];
    while (L < Enemy.GroupsCount) AND (Poly = Enemy.GroupsPoly[L]) do
    begin
      AddPolyToQueue(ffEnemy, Enemy.GroupsPoly[L]);
      Inc(L);
    end;
  end;
  for K := 0 to aCluster.HousesCount - 1 do
    AddPolyToQueue(ffEnemy, Enemy.HousesPoly[ aCluster.Houses[K] ]);
end;


procedure TKMArmyVectorField.InitQueue(const aGroupsPoly: TKMWordArray; aCnt: Word);
var
  K: Integer;
begin
  Inc(fVisitedIdx);
  for K := 0 to aCnt - 1 do
    AddPolyToQueue(ffRally, aGroupsPoly[K]);
end;


procedure TKMArmyVectorField.InitQueue(const aGroupPoly: Word);
begin
  if (fVisitedIdx = High(Byte)) then
    MakeNewQueue(False);
  Inc(fVisitedIdx);
  AddPolyToQueue(ffSearch, aGroupPoly);
end;


// Maybe in future the following 2 computations will be different so keep it as 2 methods
function TKMArmyVectorField.CalculateDistanceRallyPoint(const aNavMeshIdx, aNearbyIdx: Word): Word;
const
  NARROW_COEF = 4;
begin
  Result := fVectorField[ gAIFields.NavMesh.Polygons[aNavMeshIdx].Nearby[aNearbyIdx] ].RallyPoint
    + fQueueArray[aNavMeshIdx].Distance
    + KMDistanceWalk(fQueueArray[aNavMeshIdx].DistPoint, gAIFields.NavMesh.Polygons[aNavMeshIdx].NearbyPoints[aNearbyIdx])
    + (MAX_LINE_LENGTH - gAIFields.NavMesh.Polygons[aNavMeshIdx].NearbyLineLength[aNearbyIdx]) * NARROW_COEF;
end;

function TKMArmyVectorField.CalculateDistanceEnemy(const aNavMeshIdx, aNearbyIdx: Word): Word;
const
  NARROW_COEF = 4;
begin
  Result :=
    + fQueueArray[aNavMeshIdx].Distance
    + KMDistanceWalk(fQueueArray[aNavMeshIdx].DistPoint, gAIFields.NavMesh.Polygons[aNavMeshIdx].NearbyPoints[aNearbyIdx])
    + (MAX_LINE_LENGTH - gAIFields.NavMesh.Polygons[aNavMeshIdx].NearbyLineLength[aNearbyIdx]) * NARROW_COEF;
end;

procedure TKMArmyVectorField.AssignDistanceRallyPoint(const aIdx, aDistance: Word);
begin
  fVectorField[aIdx].RallyPoint := aDistance;
end;

procedure TKMArmyVectorField.AssignDistanceEnemy(const aIdx, aDistance: Word);
begin
  fVectorField[aIdx].Enemy := aDistance;
end;


procedure TKMArmyVectorField.Flood(aCalulateDistance: TKMCalculateDistance; aAssignDistance: TKMAssignDistance);
var
  K: Integer;
  Idx, Dist: Word;
begin
  while RemoveFromQueue(Idx) do
    //if CanBeExpanded(Idx) then
      with gAIFields.NavMesh.Polygons[Idx] do
        for K := 0 to NearbyCount - 1 do
          if not IsVisited(Nearby[K]) then
          begin
            Dist := aCalulateDistance(Idx, K);
            MarkAsVisited(Nearby[K], Dist, NearbyPoints[K]);
            InsertAndSort(Nearby[K]);
            aAssignDistance(Nearby[K],Dist);
          end;
end;


function TKMArmyVectorField.CanBeExpanded(const aIdx: Word): Boolean;
const
  MAX_SEARCH_DISTANCE = 10;
begin
  Result := fQueueArray[aIdx].Distance < MAX_SEARCH_DISTANCE;
end;


function TKMArmyVectorField.SearchFlood(): Word;
var
  K: Integer;
  Idx, BestIdx: Word;
  Dist, BestDist: Single;
begin
  BestDist := 1E10;
  BestIdx := fStartQueue;
  while RemoveFromQueue(Idx) do
    if CanBeExpanded(Idx) then
      with gAIFields.NavMesh.Polygons[Idx] do
        for K := 0 to NearbyCount - 1 do
          if not IsVisited(Nearby[K]) then
          begin
            MarkAsVisited(
              Nearby[K],
              fQueueArray[Idx].Distance + KMDistanceWalk(fQueueArray[Idx].DistPoint, gAIFields.NavMesh.Polygons[Idx].NearbyPoints[K]),
              NearbyPoints[K]
            );
            InsertAndSort(Nearby[K]);
            Dist := fVectorField[Nearby[K]].RallyPoint
              + abs(fVectorField[Nearby[K]].Enemy - AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyOffsetFF]) * AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyGainFF];
            if (Dist < BestDist) then
            begin
              BestDist := Dist;
              BestIdx := Nearby[K];
            end;
          end;
  Result := BestIdx;
end;


procedure TKMArmyVectorField.FindPositions();

  function FindNewPosition(aInitIdx: Integer; aUseEnemyVectorField: Boolean): Integer;
    function ComputePrice(const aPolyIdx: Integer): Single;
    begin
      if (aUseEnemyVectorField) then
        Result := abs(fVectorField[aPolyIdx].Enemy - AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyOffset])
      else
        Result := fVectorField[aPolyIdx].RallyPoint;
    end;
  const
    MAX_WALKING_DISTANCE = 10;
  var
    K,L, PolyIdx, BestIdx, NearbyIdx: Integer;
    PosPrice, BestPrice: Single;
  begin
    PolyIdx := aInitIdx;
    BestIdx := aInitIdx;
    BestPrice := ComputePrice(BestIdx);
    for K := 0 to 7 do
    begin
      for L := 0 to gAIFields.NavMesh.Polygons[PolyIdx].NearbyCount - 1 do
      begin
        NearbyIdx := gAIFields.NavMesh.Polygons[PolyIdx].Nearby[L];
        PosPrice := ComputePrice(NearbyIdx);
        if (BestPrice >= PosPrice) then // keep <= for case of small plygons with the same center point
        begin
          BestIdx := NearbyIdx;
          BestPrice := PosPrice;
        end;
      end;
      if (Integer(fVectorField[aInitIdx].Enemy) - Integer(fVectorField[BestIdx].Enemy) > MAX_WALKING_DISTANCE) OR (BestIdx = PolyIdx) then
        Break;
      PolyIdx := BestIdx;
    end;
    Result := BestIdx;
  end;

  function FindNewPositionFF(aIdx: Integer): Integer;
  begin
    InitQueue(aIdx);
    Result := SearchFlood();
  end;

  procedure AssignPositions(aIdx: Integer);
  const
    ENEMY_NEARBY_COMBAT_DISTANCE = 4;
    ENEMY_NEARBY_CG_DISTANCE = 12;
    VF_ENEMY_UTH = 10;
    VF_RALLY_UTH = 15;
    USE_FF_TO_FIND_POSITION = True;
  var
    MinDist: Word;
    K, InitIdx, TargetIdx, SoldiersCnt: Integer;
    InitP: TKMPoint;
  begin
    MinDist := High(Word);
    with CCT[aIdx].CounterWeight do
      for K := 0 to GroupsCount - 1 do
      begin
        InitIdx := Ally.GroupsPoly[ Groups[K].Idx ];
        InitP := gAIFields.NavMesh.Polygons[InitIdx].CenterPoint;
        SoldiersCnt := Groups[K].Group.Count;

        // Decide which vector field should be used for navigation
        if USE_FF_TO_FIND_POSITION then
          TargetIdx := FindNewPositionFF(InitIdx)
        else
          TargetIdx := FindNewPosition(
              InitIdx,
              (fVectorField[InitIdx].Enemy < AI_Par[ATTACK_ArmyVectorField_FindPositions_FollowEnemyVectorFieldUth])
              OR (fVectorField[InitIdx].RallyPoint < AI_Par[ATTACK_ArmyVectorField_FindPositions_FollowEnemyVectorFieldUth])
            );

        // Get target position
        Groups[K].TargetPosition.Loc := gAIFields.NavMesh.Polygons[ TargetIdx ].CenterPoint;
        Groups[K].TargetPosition.Dir := KMGetDirection(InitP, Groups[K].TargetPosition.Loc );
        Groups[K].CG := gHands[ Groups[K].Group.Owner ].AI.ArmyManagement.AttackNew.CombatGroup[ Groups[K].Group ];
        if (Groups[K].CG = nil) then
          MinDist := min(MinDist, fVectorField[InitIdx].Enemy)
        else
          Inc(CGCount);
        Inc(InClusterCnt, SoldiersCnt);
        // Check if group is in the place
        InPlace := False;
        if (fVectorField[InitIdx].Enemy < AI_Par[ATTACK_ArmyVectorField_FindPositions_DistCloseToEnemy]) // Close to enemy
          OR (fVectorField[TargetIdx].Enemy < AI_Par[ATTACK_ArmyVectorField_FindPositions_DistCloseToEnemy]) // Close to enemy
          OR (Integer(fVectorField[InitIdx].Enemy) - Integer(fVectorField[TargetIdx].Enemy) < AI_Par[ATTACK_ArmyVectorField_FindPositions_DistMaxWalk]) // Distance from target point
          OR ((Groups[K].CG <> nil) AND (Groups[K].CG.StuckInTraffic)) then
        begin
          Inc(InPositionCnt, SoldiersCnt);
          InPlace := True;
        end;
        if not Groups[K].Group.CanTakePlayerOrders OR (fVectorField[InitIdx].Enemy < ENEMY_NEARBY_COMBAT_DISTANCE) then // Group in combat
        begin
          Inc(NearEnemyCnt, SoldiersCnt);
          InPlace := True;
        end;
        if InPlace then
        begin
          InPositionStrength := InPositionStrength + Groups[K].Group.Count;
          Groups[K].Status := InPlace;
        end;
      end;
    // Create combat group if enemy is nearby
    if (MinDist < ENEMY_NEARBY_CG_DISTANCE) then
      with CCT[aIdx].CounterWeight do
        for K := 0 to GroupsCount - 1 do
          if (Groups[K].CG = nil) then
            Groups[K].CG := gHands[ Groups[K].Group.Owner ].AI.ArmyManagement.AttackNew.AddGroup( Groups[K].Group );

  end;


  procedure EstimateCombatLine(const aGroups: TKMGroupCounterWeightArray; aCnt: Word);
  const
    SCALE_AVOID_TRAFFIC = 40;
  var
    K, L, Idx, Cnt, Increase: Integer;
    BestDistance: Single;
    GroupsPoly: TKMWordArray;
  begin
    // Find index of group closest to the combat line
    BestDistance := 1E10;
    for K := 0 to aCnt - 1 do
      BestDistance := min(BestDistance, abs(fVectorField[  Ally.GroupsPoly[ aGroups[K].Idx ]  ].Enemy - AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyOffsetFF]));

    // Add groups close to combat line as rally point
    Cnt := 0;
    Increase := Round(AI_Par[ATTACK_ArmyVectorField_FindPositions_AvoidTraffic] * min(1,aCnt / SCALE_AVOID_TRAFFIC));
    SetLength(GroupsPoly, aCnt);
    for K := 0 to aCnt - 1 do
    begin
      Idx := Ally.GroupsPoly[ aGroups[K].Idx ];
      // Determine rally point
      if (abs(fVectorField[Idx].Enemy - AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyOffsetFF]) < BestDistance + AI_Par[ATTACK_ArmyVectorField_FindPositions_RallyPointOffset]) then
      begin
        GroupsPoly[Cnt] := Idx;
        Inc(Cnt);
      end;
      // Mark group in vector field (avoid traffic)
      fVectorField[Idx].RallyPoint := fVectorField[Idx].RallyPoint + Increase;
      with gAIFields.NavMesh.Polygons[Idx] do
        for L := 0 to NearbyCount - 1 do
          fVectorField[Nearby[L]].RallyPoint := fVectorField[Nearby[L]].RallyPoint + (Increase shr 1);

    end;

    // Create rally point from the groups close to the combat line
    InitQueue(GroupsPoly, Cnt);
    Flood(CalculateDistanceRallyPoint, AssignDistanceRallyPoint);
  end;


var
  K: Integer;
{$IFDEF DEBUG_ArmyVectorField}
  Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_ArmyVectorField}
  // Array will be filled by Flood fill so debug must be saved now
  CopyVariablesForDebug1();
  Time := TimeGetUsec();
  {$ENDIF}

  if (Enemy.GroupsCount = 0) AND (Enemy.HousesCount = 0) then
    Exit;

  for K := Low(CCT) to High(CCT) do
    if (CCT[K].CounterWeight.GroupsCount > 0) then
    begin
      // EXPERIMENT
      FillChar(fVectorField[0], SizeOf(fVectorField[0]) * Length(fVectorField), #0);
      InitQueue(CCT[K].Cluster);
      Flood(CalculateDistanceEnemy, AssignDistanceEnemy);
      EstimateCombatLine(CCT[K].CounterWeight.Groups, CCT[K].CounterWeight.GroupsCount);
      AssignPositions(K);
      {$IFDEF DEBUG_ArmyVectorField}
        CopyVectorFieldForDebug(K);
      {$ENDIF}
    end;

  for K := Low(CCT) to High(CCT) do
    with CCT[K].CounterWeight do
    begin
      InPlace     := InPositionCnt      > InClusterCnt        * AI_Par[ATTACK_ArmyVectorField_EvalClusters_InPlace];
      AtAdvantage := InPositionStrength > CCT[K].ThreatNearby * AI_Par[ATTACK_ArmyVectorField_EvalClusters_AtAdvantage];
      Ambushed    := NearEnemyCnt       > InClusterCnt        * AI_Par[ATTACK_ArmyVectorField_EvalClusters_Ambushed];
    end;

  {$IFDEF DEBUG_ArmyVectorField}
  Time := TimeGetUsec() - Time;
  fTimeAvrgFindPositions := Round((fTimeAvrgFindPositions * 5 + Time) / 6);
  fTimePeakFindPositions := Max(fTimePeakFindPositions, Time);
  CopyVariablesForDebug2();
  {$ENDIF}
end;


{$IFDEF DEBUG_ArmyVectorField}
function TKMArmyVectorField.GetAllianceIdxFromDebugArray(): Integer;
var
  K, L: Integer;
begin
  Result := -1;
  if (Length(fOwners) <= 0) then
    Exit;

  for K := 0 to Length(fDbgVector) - 1 do
    for L := 0 to Length(fDbgVector[K].Alliance) - 1 do
      if (fOwner = fDbgVector[K].Alliance[L]) then
        Result := K;

  if (Result = -1) then
  begin
    Result := Length(fDbgVector);
    SetLength(fDbgVector, Length(fDbgVector) + 1);
    SetLength(fDbgVector[Result].Alliance, Length(fOwners));
    Move(fOwners[0], fDbgVector[Result].Alliance[0], SizeOf(fOwners[0])*Length(fOwners));
  end;
end;


procedure TKMArmyVectorField.CopyVectorFieldForDebug(aIdx: Word);
var
  Team, K: Integer;
begin
  Team := GetAllianceIdxFromDebugArray();
  if (Team = -1) OR (Length(CCT) <= aIdx) then
    Exit;
  if (Length(fDbgVector[Team].VectorFields) < Length(CCT)) then
    SetLength(fDbgVector[Team].VectorFields, Length(CCT));
  if (Length(fDbgVector[Team].VectorFields[aIdx]) < Length(fVectorField)) then
    SetLength(fDbgVector[Team].VectorFields[aIdx], Length(fVectorField));
  for K := Low(fVectorField) to High(fVectorField) do
    fDbgVector[Team].VectorFields[aIdx,K] := fVectorField[K];
end;


procedure TKMArmyVectorField.CopyVariablesForDebug1();
var
  K, Team: Integer;
begin
  Team := GetAllianceIdxFromDebugArray();
  if (Team = -1) then
    Exit;

  with fDbgVector[Team] do
  begin
    if (Length(ClustersMapp) <> Length(fClusterMapping)) then
      SetLength(ClustersMapp, Length(fClusterMapping));
    for K := Low(ClustersMapp) to High(ClustersMapp) do
      if (fQueueArray[K].Visited = 1) then
        ClustersMapp[K] := fClusterMapping[K]
      else
        ClustersMapp[K] := High(Word);
  end;
end;


procedure TKMArmyVectorField.CopyVariablesForDebug2();
  procedure CopyAlliance(var aFrom: TKMAllianceAsset; var aTo: TKMAllianceAsset);
  begin
    aTo.GroupsCount  := aFrom.GroupsCount;
    aTo.HousesCount  := aFrom.HousesCount;
    aTo.GroupsNumber := aFrom.GroupsNumber;
    aTo.OwnersCount  := aFrom.OwnersCount;
    SetLength(aTo.Groups,     aTo.GroupsCount);
    SetLength(aTo.Houses,     aTo.HousesCount);
    SetLength(aTo.GroupsPoly, aTo.GroupsCount);
    SetLength(aTo.HousesPoly, aTo.HousesCount);
    if (aTo.GroupsCount > 0) then Move(aFrom.Groups[0],     aTo.Groups[0],     SizeOf(aTo.Groups[0])     * aTo.GroupsCount);
    if (aTo.HousesCount > 0) then Move(aFrom.Houses[0],     aTo.Houses[0],     SizeOf(aTo.Houses[0])     * aTo.HousesCount);
    if (aTo.GroupsCount > 0) then Move(aFrom.GroupsPoly[0], aTo.GroupsPoly[0], SizeOf(aTo.GroupsPoly[0]) * aTo.GroupsCount);
    if (aTo.HousesCount > 0) then Move(aFrom.HousesPoly[0], aTo.HousesPoly[0], SizeOf(aTo.HousesPoly[0]) * aTo.HousesCount);
  end;
var
  K, Team: Integer;
  GT: TKMGroupType;
begin
  Team := GetAllianceIdxFromDebugArray();
  if (Team = -1) then
    Exit;

  CopyAlliance(Ally,  fDbgVector[Team].Ally);
  CopyAlliance(Enemy, fDbgVector[Team].Enemy);

  fDbgVector[Team].Clusters.Count := fClusters.Count;
  fDbgVector[Team].Clusters.UnreferencedCount := fClusters.UnreferencedCount;
  SetLength(fDbgVector[Team].Clusters.Clusters, fClusters.Count);
  for K := 0 to fClusters.Count - 1 do
    with fDbgVector[Team].Clusters.Clusters[K] do
    begin
      ReferenceID := fClusters.Clusters[K].ReferenceID;
      GroupsCount := fClusters.Clusters[K].GroupsCount;
      HousesCount := fClusters.Clusters[K].HousesCount;
      SetLength(Groups,GroupsCount);
      SetLength(Houses,HousesCount);
      if (GroupsCount > 0) then Move(fClusters.Clusters[K].Groups[0], Groups[0], SizeOf(Groups[0])*GroupsCount);
      if (HousesCount > 0) then Move(fClusters.Clusters[K].Houses[0], Houses[0], SizeOf(Houses[0])*HousesCount);
    end;

  SetLength(fDbgVector[Team].CCT, Length(CCT));
  for K := Low(CCT) to High(CCT) do
    with fDbgVector[Team].CCT[K] do
    begin
      AttackingCity      := CCT[K].AttackingCity;
      ClusterIdx         := CCT[K].ClusterIdx;
      Cluster            := @fDbgVector[Team].Clusters.Clusters[ClusterIdx];
      BestDist           := CCT[K].BestDist;
      Threat             := CCT[K].Threat;
      ThreatNearby       := CCT[K].ThreatNearby;
      CenterPoint        := CCT[K].CenterPoint;
      SetLength(Owners, Length(CCT[K].Owners));
      if (Length(Owners) > 0) then
        Move(CCT[K].Owners[0], Owners[0], SizeOf(Owners[0]) * Length(Owners));
      CounterWeight.InPlace            := CCT[K].CounterWeight.InPlace;
      CounterWeight.AtAdvantage        := CCT[K].CounterWeight.AtAdvantage;
      CounterWeight.Ambushed           := CCT[K].CounterWeight.Ambushed;
      CounterWeight.GroupsCount        := CCT[K].CounterWeight.GroupsCount;
      CounterWeight.CGCount            := CCT[K].CounterWeight.CGCount;
      CounterWeight.InPositionCnt      := CCT[K].CounterWeight.InPositionCnt;
      CounterWeight.InClusterCnt       := CCT[K].CounterWeight.InClusterCnt;
      CounterWeight.NearEnemyCnt       := CCT[K].CounterWeight.NearEnemyCnt;
      CounterWeight.Opportunity        := CCT[K].CounterWeight.Opportunity;
      CounterWeight.InPositionStrength := CCT[K].CounterWeight.InPositionStrength;
      for GT := GROUP_TYPE_MIN to GROUP_TYPE_MAX do
        CounterWeight.WeightedCount[GT] := CCT[K].CounterWeight.WeightedCount[GT];
      SetLength(CounterWeight.Groups, CounterWeight.GroupsCount);
      if (CounterWeight.GroupsCount > 0) then
        Move(CCT[K].CounterWeight.Groups[0], CounterWeight.Groups[0], SizeOf(TKMGroupCounterWeight) * CounterWeight.GroupsCount);
    end;
end;


function TKMArmyVectorField.GenerateColorWSeed(aIdx: Integer): Cardinal;
begin
  aIdx := Max(aIdx,0) + 1; // Seed > 0
  Result := GetRandomColorWSeed( KaMRandomWSeed(aIdx,High(Integer)) ); // Use random number so colors are more different if indexes are close to each other
end;


function TKMArmyVectorField.GetCCTIdxFromGroup(aG: TKMUnitGroup): Integer;
  function IsGroupInAlliance(const A: TKMAllianceAsset): Boolean;
  var
    K: Integer;
  begin
    Result := False;
    for K := 0 to A.GroupsCount - 1 do
      if (aG = A.Groups[K]) then
        Exit(True);
  end;
  function FindGroupInCCT(const aCCT: TKMCombatClusterThreatArray; var aIdx: Integer): Boolean;
  var
    K,L: Integer;
  begin
    Result := False;
    for K := Low(aCCT) to High(aCCT) do
      for L := 0 to aCCT[K].CounterWeight.GroupsCount - 1 do
        if (aCCT[K].CounterWeight.Groups[L].Group = aG) then
        begin
          aIdx := K;
          Exit(True);
        end;
  end;
  function FindGroupInCluster(const aCCT: TKMCombatClusterThreatArray; const A: TKMAllianceAsset; var aIdx: Integer): Boolean;
  var
    K,L: Integer;
  begin
    Result := False;
    for K := Low(aCCT) to High(aCCT) do
      for L := 0 to aCCT[K].Cluster.GroupsCount - 1 do
        if (A.Groups[ aCCT[K].Cluster.Groups[L] ] = aG) then
        begin
          aIdx := K;
          Exit(True);
        end;
  end;
var
  Team: Integer;
begin
  Result := -1;
  fOwner := gMySpectator.HandID;
  Team := GetAllianceIdxFromDebugArray();
  if IsGroupInAlliance(fDbgVector[Team].Ally) then
    FindGroupInCCT(fDbgVector[Team].CCT, Result)
  else if IsGroupInAlliance(fDbgVector[Team].Enemy) then
    FindGroupInCluster(fDbgVector[Team].CCT, fDbgVector[Team].Enemy, Result);
end;
{$ENDIF}


function TKMArmyVectorField.LogStatus(): UnicodeString;
{$IFDEF DEBUG_ArmyVectorField}
const
  STR_COLOR_WHITE = '[$FFFFFF]';
var
  Team, K, Idx: Integer;
  Color: Cardinal;
{$ENDIF}
begin
  {$IFDEF DEBUG_ArmyVectorField}
  fOwner := gMySpectator.HandID;
  Team := GetAllianceIdxFromDebugArray();
  if (Team = -1) OR (Length(CCT) = 0) then
    Exit('');

  Result := '|Army vector field:';

  Idx := -1;
  if (gMySpectator.Selected is TKMUnitGroup) then
    Idx := GetCCTIdxFromGroup(TKMUnitGroup(gMySpectator.Selected));

  for K := Low(fDbgVector[Team].CCT) to High(fDbgVector[Team].CCT) do
    with fDbgVector[Team].CCT[K] do
    begin
      Color := GenerateColorWSeed(ClusterIdx) AND $FFFFFF;
      Result := Format('%s|%2d. [$%s]###%s:',[Result, K, IntToHex(Color,6), STR_COLOR_WHITE]);
      Result := Format('%s Threat %4.0f/%4.0f..%3d%%;',[Result, ThreatNearby, Threat, Round(ThreatNearby/Max(1,Threat)*100)]);
      Result := Format('%s Opportunity (%2d): %4.0f/%4.0f..%3d%%;',[Result, CounterWeight.InPositionCnt, CounterWeight.InPositionStrength, CounterWeight.Opportunity, Round(CounterWeight.InPositionStrength / Max(1,CounterWeight.Opportunity)*100)]);
      Result := Format('%s [$%s]Attacking City%s,',[Result, IntToHex(tcRed * Byte(AttackingCity            ) + $FFFFFF * Byte(not AttackingCity            ),6), STR_COLOR_WHITE]);
      Result := Format('%s [$%s]Place%s,',         [Result, IntToHex(tcRed * Byte(CounterWeight.InPlace    ) + $FFFFFF * Byte(not CounterWeight.InPlace    ),6), STR_COLOR_WHITE]);
      Result := Format('%s [$%s]Advantage%s,',     [Result, IntToHex(tcRed * Byte(CounterWeight.AtAdvantage) + $FFFFFF * Byte(not CounterWeight.AtAdvantage),6), STR_COLOR_WHITE]);
      Result := Format('%s [$%s]Ambush%s',         [Result, IntToHex(tcRed * Byte(CounterWeight.Ambushed   ) + $FFFFFF * Byte(not CounterWeight.Ambushed   ),6), STR_COLOR_WHITE]);
      if (K = Idx) then
        Result := Format('%s <<<<<<',[Result]);
    end;

  Result := Format('%s|PerfLog (avrg/peak): EnemyPresence %d/%d; DivideForces %d/%d; FindPositions %d/%d;',[Result,fTimeAvrgEnemyPresence,fTimePeakEnemyPresence,fTimeAvrgDivideForces,fTimePeakDivideForces,fTimeAvrgFindPositions,fTimePeakFindPositions]);

  {$ELSE}
  Result := '';
  {$ENDIF}
end;


procedure TKMArmyVectorField.Paint();
{$IFDEF DEBUG_ArmyVectorField}
type
  TKMGetVectorItem = reference to function(const aIdx: Word): Word;


  function FindGroup(aG: TKMUnitGroup): Boolean;
  var
    K: Integer;
    PL: TKMHandID;
  begin
    for PL := 0 to gHands.Count - 1 do
      for K := 0 to gHands[PL].UnitGroups.Count - 1 do
        if (aG = gHands[PL].UnitGroups.Groups[K]) then
          Exit(True);
    Result := False;
  end;
  function FindHouse(aH: TKMHouse): Boolean;
  var
    K: Integer;
    PL: TKMHandID;
  begin
    for PL := 0 to gHands.Count - 1 do
      for K := 0 to gHands[PL].Houses.Count - 1 do
        if (aH = gHands[PL].Houses[K]) then
          Exit(True);
    Result := False;
  end;
var
  K, L, Team, SelectedIdx, BestIdx, NearbyIdx: Integer;
  Color, Opacity: Cardinal;
  Dist: Single;
  P1,P2,P3,P4: TKMPoint;
  G: TKMUnitGroup;
  H: TKMHouse;
  getVecItem: TKMGetVectorItem;
{$ENDIF}
begin
  {$IFDEF DEBUG_ArmyVectorField}
  fOwner := gMySpectator.HandID;
  Team := GetAllianceIdxFromDebugArray();

  // Exit if team is not selected or NavMesh was refreshed
  if (Team = -1) OR (gAIFields.NavMesh.PolygonsCnt <> fPolygonsCnt) then
    Exit;

  SelectedIdx := -1;
  if (gMySpectator.Selected is TKMUnitGroup) then
    SelectedIdx := GetCCTIdxFromGroup(TKMUnitGroup(gMySpectator.Selected));

  // Groups and houses in cluster
  {
  for K := 0 to fDbgVector[Team].Clusters.Count - 1 do
    if (fDbgVector[Team].Clusters.Clusters[K].ReferenceID = K) then
    begin
      Color := $99000000 OR ($00FFFFFF AND GenerateColorWSeed(K));
      for L := 0 to fDbgVector[Team].Clusters.Clusters[K].GroupsCount - 1 do
      begin
        G := fDbgVector[Team].Enemy.Groups[ fDbgVector[Team].Clusters.Clusters[K].Groups[L] ];
        if FindGroup(G) then
          gRenderAux.CircleOnTerrain(G.Position.X, G.Position.Y, 1, Color, Color);
      end;
      for L := 0 to fDbgVector[Team].Clusters.Clusters[K].HousesCount - 1 do
      begin
        H := fDbgVector[Team].Enemy.Houses[ fDbgVector[Team].Clusters.Clusters[K].Houses[L] ];
        if FindHouse(H) then
          gRenderAux.CircleOnTerrain(H.Position.X, H.Position.Y, 1, Color, Color);
      end;
    end;
  //}
  // Vector field
  if (OVERLAY_AI_VEC_FLD_ENEM AND OVERLAY_AI_VEC_FLD_ALLY) AND (SelectedIdx > -1) AND (length(fDbgVector[Team].CCT) > SelectedIdx) then
  begin
    with fDbgVector[Team] do
    begin
      for K := 0 to fPolygonsCnt - 1 do
      begin
        Dist := (fDbgVector[Team].VectorFields[SelectedIdx,K].RallyPoint
          + abs(fDbgVector[Team].VectorFields[SelectedIdx,K].Enemy - AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyOffsetFF]) * AI_Par[ATTACK_ArmyVectorField_FindPositions_DistEnemyGainFF]);
        if (7*Dist < 250) then
          gAIFields.NavMesh.DrawPolygon(K, 250-round(7*Dist), tcRed, 0, IntToStr(Round(Dist)));
      end;
    end;

  end
  else if (OVERLAY_AI_VEC_FLD_ENEM OR OVERLAY_AI_VEC_FLD_ALLY) AND (SelectedIdx > -1) AND (length(fDbgVector[Team].CCT) > SelectedIdx) then
  begin
    getVecItem := function(const aIdx: Word): Word
    begin
      Result := fDbgVector[Team].VectorFields[SelectedIdx,aIdx].RallyPoint;
    end;

    if OVERLAY_AI_VEC_FLD_ENEM then
    begin
      getVecItem := function(const aIdx: Word): Word
      begin
        Result := fDbgVector[Team].VectorFields[SelectedIdx,aIdx].Enemy;
      end;
    end;

    with fDbgVector[Team] do
    begin
      //Opacity := 0;
      //for K := 0 to fPolygonsCnt - 1 do
      //  Opacity := max(Opacity, getVecItem(K));

      for K := 0 to fPolygonsCnt - 1 do
        if (getVecItem(K) > 0) then
        begin
          gAIFields.NavMesh.DrawPolygon(K, (5*getVecItem(K)) mod 250, tcWhite, 0, IntToStr(getVecItem(K)));
          BestIdx := gAIFields.NavMesh.Polygons[K].Nearby[0];
          for L := 1 to gAIFields.NavMesh.Polygons[K].NearbyCount - 1 do
          begin
            NearbyIdx := gAIFields.NavMesh.Polygons[K].Nearby[L];
            if (getVecItem(BestIdx) > getVecItem(NearbyIdx)) then
              BestIdx := NearbyIdx;
          end;
          if (getVecItem(K) < getVecItem(BestIdx)) then
          begin
            //gAIFields.NavMesh.DrawPolygon(K, $22, $44000000 OR tcWhite);
          end
          else
          begin
            P1 := gAIFields.NavMesh.Polygons[K].CenterPoint;
            P4 := gAIFields.NavMesh.Polygons[BestIdx].CenterPoint;
            P2 := KMPointAverage(P1,KMPointAverage(P1,P4));
            P3 := KMPointAverage(P2,KMPointAverage(P1,P4));
            gRenderAux.LineOnTerrain(P4, P3, $FF000000 OR tcRed);
            gRenderAux.LineOnTerrain(P3, P2, $FF000000 OR tcPurple);
            gRenderAux.LineOnTerrain(P2, P1, $FF000000 OR tcBlue);
          end;
        end;
    end;
  end;

  // Polygon in cluster
  if OVERLAY_AI_CLUSTERS then
    with fDbgVector[Team] do
      for K := 0 to Min(High(ClustersMapp),fPolygonsCnt - 1) do
        if (ClustersMapp[K] <> High(Word)) then
        begin
          L := Clusters.Clusters[ ClustersMapp[K] ].ReferenceID;
          Color := $00FFFFFF AND GenerateColorWSeed(L);
          gAIFields.NavMesh.DrawPolygon(K, $22, $44000000 OR Color);
        end;

  // Target of cluster
  for K := Low(fDbgVector[Team].CCT) to High(fDbgVector[Team].CCT) do
  begin
    Color := $00FFFFFF AND GenerateColorWSeed(fDbgVector[Team].CCT[K].ClusterIdx);
    Opacity := $88000000;
    if OVERLAY_AI_CLUSTERS then
    begin
      if (K = SelectedIdx) then
      begin
        Opacity := $BB000000;
        with fDbgVector[Team].CCT[K] do
          gRenderAux.CircleOnTerrain(CenterPoint.X, CenterPoint.Y, 1, Opacity OR Color, $FF000000 OR tcBlack);
      end;
      // Enemies
      with fDbgVector[Team].CCT[K].Cluster^ do
      begin
        for L := 0 to GroupsCount - 1 do
        begin
          G := fDbgVector[Team].Enemy.Groups[ Groups[L] ];
          if FindGroup(G) then
            gRenderAux.CircleOnTerrain(G.Position.X, G.Position.Y, 1, Opacity OR Color, $FF000000 OR tcRed);
        end;
        for L := 0 to HousesCount - 1 do
        begin
          H := fDbgVector[Team].Enemy.Houses[ Houses[L] ];
          if FindHouse(H) then
            gRenderAux.CircleOnTerrain(H.Position.X, H.Position.Y, 1, Opacity OR Color, $FF000000 OR tcBlue);
        end;
      end;
    end;
    // Allied groups
    if OVERLAY_AI_ALLIEDGROUPS then
    begin
      with fDbgVector[Team].CCT[K].CounterWeight do
        for L := 0 to GroupsCount - 1 do
        begin
          gRenderAux.Quad(Groups[L].TargetPosition.Loc.X, Groups[L].TargetPosition.Loc.Y, ($99000000 - Byte(Groups[L].Status)*$44000000) OR Color);
          G := Groups[L].Group;
          if FindGroup(G) then
          begin
            gRenderAux.Line(G.Position.X, G.Position.Y, Groups[L].TargetPosition.Loc.X, Groups[L].TargetPosition.Loc.Y, $FF000000 OR Color);
            gRenderAux.CircleOnTerrain(G.Position.X, G.Position.Y, 1, Opacity OR Color, $FF000000 OR tcGreen * Byte(Groups[L].Status) OR tcBlue * Byte(not Groups[L].Status));
          end;
        end;
    end;
  end;
  {$ENDIF}
end;


end.


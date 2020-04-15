{
NavMesh - army positioning
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_NavMeshArmyPositioning;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_Defaults, KM_CommonTypes,
  KM_Points, KM_UnitGroup, KM_Houses, KM_ResHouses,
  KM_NavMeshFloodFill;

type

  TKMInfluenceInfo = record
    AllyInfluence, EnemyInfluence: Byte;
    Distance, Mark: Word;
  end;
  TKMInflInfoArray = array of TKMInfluenceInfo;

  TKMAllianceInfo = record
    // GroupsNumber = real number of groups, GroupsCount = count of groups in arrays
    GroupsCount, HousesCount, GroupsNumber: Word;
    Groups: TKMUnitGroupArray;
    Houses: TKMHouseArray;
    GroupsPoly, HousesPoly: TKMWordArray;
  end;

  TKMBattleLine = record
    GroupsCount, HousesCount, PolygonsCount: Word;
    Groups, Houses, Polygons: TKMWordArray;
  end;
  TKMBattleLines = record
    Count: Word;
    Price: Single;
    Lines: array of TKMBattleLine;
  end;
  {$IFDEF DEBUG_BattleLines}
  TKMDebugBattleLines = record
    Count, LineStartIdx: Word;
    DBLs: array of TKMBattleLines;
  end;
  {$ENDIF}

  TDistancePenalization = class;
  TArmyForwardFF = class;
  TArmyBackwardFF = class;

  TDistancePenalization = class(TNavMeshFloodFill)
  private
  protected
    fMaxDistance: Word;
    fInflInfo: TKMInflInfoArray;

    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); override;
  public
    function PrefillDistances(var aAlliance: TKMAllianceInfo; var aDefInfo: TKMInflInfoArray; var aQueueArray: TPolygonsQueueArr): Boolean;
  end;


  TArmyForwardFF = class(TNavMeshFloodFill)
  private
  protected
    fOwner: TKMHandID;
    fDistancePenalization: TDistancePenalization;
    fBackwardFF: TArmyBackwardFF;
    fCntAllyPoly, fCntEnemyPoly: Word;

    procedure MakeNewQueue(); override;
    function IsVisited(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); override;
    procedure InitQueue(const aMaxIdx: Integer; var aInitIdxArray: TKMWordArray); override;
    function ForwardFF(): Boolean;

    procedure AssignDefencePositions();

    function GetInitPolygonsGroups(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceInfo): Boolean;
    function GetInitPolygonsHouses(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceInfo): Boolean;
  public
    fInflInfo: TKMInflInfoArray;
    Enemy: TKMAllianceInfo;
    TargetEnemy: TKMAllianceInfo;
    Ally: TKMAllianceInfo;
    BattleLines: TKMBattleLines;
    TargetPositions: TKMPointDirArray;
    TargetLines: TKMWordArray;
    InCombatLine: TBooleanArray;

    constructor Create(aSorted: Boolean = False); override;
    destructor Destroy; override;

    function FindArmyPosition(var aOwners: TKMHandIDArray; var aTargetGroups: TKMUnitGroupArray; var aTargetHouses: TKMHouseArray): Boolean;
    procedure Paint();
  end;


  TArmyBackwardFF = class(TNavMeshFloodFill)
  private
  protected
    fOwner: TKMHandID;
    fExpandedPolygonsCnt: Word;
    fInflInfo: TKMInflInfoArray;
    fBattleLines: TKMBattleLines;
    fBestBattleLines: TKMBattleLines;
    {$IFDEF DEBUG_BattleLines}
    fDebugLines: TKMDebugBattleLines;
    procedure SaveDebugLine();
    {$ENDIF}

    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx: Word); reintroduce;
    //procedure InitQueue(const aMaxIdx: Integer; var aInitIdxArray: TKMWordArray; aInitPolyGroups: TKMUnitGroupArray); reintroduce;
    procedure InitQueue(var aEnemy: TKMAllianceInfo); reintroduce;
    procedure BackwardFlood(var aEnemy: TKMAllianceInfo);
    procedure EvaluateLine(const aIdx: Word);
    procedure ExpandPolygon(aIdx: Word; aLineIdx1: Integer = -1; aPolyIdx1: Integer = -1);
    procedure ComputeWeightedDistance(const aIdx: Word);
  public
    constructor Create(aSorted: Boolean = False); override;

    function FindTeamBattleLine(var aEnemy: TKMAllianceInfo; var aOwners: TKMHandIDArray; var aDefInfo: TKMInflInfoArray; var aQueueArray: TPolygonsQueueArr): TKMBattleLines;

    procedure Paint();
  end;



implementation
uses
  SysUtils,
  KM_Hand, KM_HandsCollection,
  KM_AIFields, KM_NavMesh, KM_AIParameters,
  {$IFDEF DEBUG_BattleLines}
  DateUtils,
  {$ENDIF}
  KM_RenderAux;


{ TDistancePenalization }
function TDistancePenalization.CanBeExpanded(const aIdx: Word): Boolean;
begin
  //Result := fInflInfo[aIdx].Distance > 0;
  Result := fInflInfo[aIdx].EnemyInfluence > 0;
end;


procedure TDistancePenalization.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
begin
  inherited MarkAsVisited(aIdx, aDistance, aPoint);
  //fInflInfo[aIdx].Distance := Max(0,PREFILL_MAX_DISTANCE - aDistance) * 4;
  fInflInfo[aIdx].EnemyInfluence := Min(255,Max(0,fMaxDistance - aDistance));
end;


function TDistancePenalization.PrefillDistances(var aAlliance: TKMAllianceInfo; var aDefInfo: TKMInflInfoArray; var aQueueArray: TPolygonsQueueArr): Boolean;
begin
  Result := (aAlliance.GroupsCount > 0) OR (aAlliance.HousesCount > 0);
  if not Result then
    Exit;
  fInflInfo := aDefInfo;
  fQueueArray := aQueueArray; // This is clear array with zeros
  fVisitedIdx := 0; // It will be updated to 1 after FillPolygons are called
  fMaxDistance := GA_ATTACK_NMAP_PrefillDistances_Houses;
  FillPolygons(aAlliance.HousesCount, aAlliance.HousesPoly);
  fMaxDistance := GA_ATTACK_NMAP_PrefillDistances_Groups;
  FillPolygons(aAlliance.GroupsCount, aAlliance.GroupsPoly);
end;




{ TArmyForwardFF }
constructor TArmyForwardFF.Create(aSorted: Boolean = False);
begin
  inherited Create(aSorted);

  fDistancePenalization := TDistancePenalization.Create(aSorted);
  fBackwardFF := TArmyBackwardFF.Create(aSorted);
end;


destructor TArmyForwardFF.Destroy();
begin
  fDistancePenalization.Free;
  fBackwardFF.Free;

  inherited;
end;


// Prepare new Queue
procedure TArmyForwardFF.MakeNewQueue();
begin
  // Check length
  if (Length(fQueueArray) < gAIFields.NavMesh.PolygonsCnt) then
  begin
    SetLength(fQueueArray, gAIFields.NavMesh.PolygonsCnt);
    SetLength(fInflInfo, gAIFields.NavMesh.PolygonsCnt);
  end;
  // Clear queue
  fQueueCnt := 0;
  ClearVisitIdx();
  // Distance will be changed so clear array
  FillChar(fInflInfo[0], SizeOf(fInflInfo[0]) * Length(fInflInfo), #0);
end;


function TArmyForwardFF.IsVisited(const aIdx: Word): Boolean;
begin
  Result := (fQueueArray[aIdx].Visited >= fVisitedIdx); // Arrays are common so >= must be here
end;


procedure TArmyForwardFF.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
begin
  //fInflInfo[aIdx].EnemyInfluence := Min(250,fInflInfo[aIdx].Distance);
  //fInflInfo[aIdx].AllyInfluence := gAIFields.Influences.GetAlliancePresence(fOwner, aIdx, atAlly);
  //Inc(fInflInfo[aIdx].Distance,aDistance);
  fInflInfo[aIdx].Distance := aDistance;
  inherited MarkAsVisited(aIdx, aDistance, aPoint);
end;


procedure TArmyForwardFF.InitQueue(const aMaxIdx: Integer; var aInitIdxArray: TKMWordArray);
const
  INIT_DISTANCE = 0;
var
  I, Idx: Word;
begin
  fVisitedIdx := 4;
  if (aMaxIdx >= 0) then
    for I := 0 to aMaxIdx do
    begin
      Idx := aInitIdxArray[I];
      if not IsVisited(Idx) then
      begin
        MarkAsVisited(Idx, INIT_DISTANCE, gAIFields.NavMesh.Polygons[ Idx ].CenterPoint);
        InsertInQueue(Idx);
      end;
    end;
end;


function TArmyForwardFF.GetInitPolygonsGroups(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceInfo): Boolean;
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
    GroupsCount := 0;
    GroupsNumber := 0;
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = aAllianceType) then
      begin
        GroupsNumber := GroupsNumber + gHands[PL].UnitGroups.Count;
        for K := 0 to gHands[PL].UnitGroups.Count - 1 do
        begin
          G := gHands[PL].UnitGroups.Groups[K];
          if (G <> nil) AND not G.IsDead AND not KMSamePoint(KMPOINT_ZERO,G.Position) then
          begin
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
                GroupsPoly[GroupsCount] := gAIFields.NavMesh.KMPoint2Polygon[ G.Members[L].CurrPosition ];
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


function TArmyForwardFF.GetInitPolygonsHouses(aAllianceType: TKMAllianceType; var aAlliance: TKMAllianceInfo): Boolean;
const
  SCAN_HOUSES: THouseTypeSet = [htBarracks, htStore, htSchool, htTownhall]; // htWatchTower
var
  PL: TKMHandID;
  K: Integer;
  H: TKMHouse;
begin
  with aAlliance do
  begin
    HousesCount := 0;
    for PL := 0 to gHands.Count - 1 do
      if (gHands[fOwner].Alliances[PL] = aAllianceType) then
        for K := 0 to gHands[PL].Houses.Count - 1 do
        begin
          H := gHands[PL].Houses[K];
          if (H <> nil) AND not H.IsDestroyed AND (H.HouseType in SCAN_HOUSES) then
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
    SetLength(HousesPoly, HousesCount);
    SetLength(Houses, HousesCount);
    Result := HousesCount > 0;
  end;
end;



function TArmyForwardFF.ForwardFF(): Boolean;
begin
  Result := False;
  // Check allied units
  GetInitPolygonsGroups(atAlly, Ally);
  if (Ally.GroupsCount = 0) then
    Exit;
  // Check enemy units
  GetInitPolygonsGroups(atEnemy,Enemy);
  //GetInitPolygonsHouses(atEnemy,Enemy); // Houses are overtaken from Supervisor
  if (Enemy.GroupsCount = 0) AND (Enemy.HousesCount = 0) then
    Exit;
  // Mark enemy units and houses
  MakeNewQueue();
  fDistancePenalization.PrefillDistances(Enemy, fInflInfo, fQueueArray);
  // Flood fill
  Result := FillPolygons(Ally.GroupsCount-1, Ally.GroupsPoly);
end;


function TArmyForwardFF.FindArmyPosition(var aOwners: TKMHandIDArray; var aTargetGroups: TKMUnitGroupArray; var aTargetHouses: TKMHouseArray): Boolean;
var
  K,L: Integer;
begin
  Result := False;
  fOwner := aOwners[0];

  Enemy.HousesCount := 0;
  SetLength(Enemy.Houses, Length(aTargetHouses));
  SetLength(Enemy.HousesPoly, Length(aTargetHouses));
  for K := 0 to Length(aTargetHouses) - 1 do
  begin
    Enemy.Houses[Enemy.HousesCount] := aTargetHouses[K];
    Enemy.HousesPoly[Enemy.HousesCount] := gAIFields.NavMesh.KMPoint2Polygon[ aTargetHouses[K].Entrance ];
    Inc(Enemy.HousesCount);
  end;

  if ForwardFF() then
  begin
    TargetEnemy.GroupsCount := 0;
    TargetEnemy.HousesCount := 0;
    SetLength(TargetEnemy.Groups, Enemy.GroupsCount);
    SetLength(TargetEnemy.Houses, Enemy.HousesCount);
    SetLength(TargetEnemy.GroupsPoly, Enemy.GroupsCount);
    SetLength(TargetEnemy.HousesPoly, Enemy.HousesCount);
    for K := 0 to Enemy.GroupsCount - 1 do
      for L := Low(aTargetGroups) to High(aTargetGroups) do
        if (aTargetGroups[L] = Enemy.Groups[K]) then
        begin
          TargetEnemy.Groups[TargetEnemy.GroupsCount] := Enemy.Groups[K];
          TargetEnemy.GroupsPoly[TargetEnemy.GroupsCount] := Enemy.GroupsPoly[K];
          Inc(TargetEnemy.GroupsCount);
        end;
    for K := 0 to Enemy.HousesCount - 1 do
    //  for L := Low(aTargetHouses) to High(aTargetHouses) do
    //    if (aTargetHouses[L] = Enemy.Houses[K]) then
        begin
          TargetEnemy.Houses[TargetEnemy.HousesCount] := Enemy.Houses[K];
          TargetEnemy.HousesPoly[TargetEnemy.HousesCount] := Enemy.HousesPoly[K];
          Inc(TargetEnemy.HousesCount);
        end;
    BattleLines := fBackwardFF.FindTeamBattleLine(TargetEnemy, aOwners, fInflInfo, fQueueArray);
    Result := BattleLines.Count > 0;
    if Result then
      AssignDefencePositions();
  end;
end;


procedure TArmyForwardFF.AssignDefencePositions();

  function FindPosition(aIdx: Word): TKMPointDir;
  var
    K, Idx, NearbyIdx: Word;
    Dir: TKMDirection;
  begin
    Result := KMPointDir(KMPOINT_ZERO,dirN);
    fQueueCnt := 0;
    fVisitedIdx := fVisitedIdx + 1;
    InsertInQueue(aIdx);
    while RemoveFromQueue(Idx) do
    begin
      for K := 0 to gAIFields.NavMesh.Polygons[Idx].NearbyCount - 1 do
      begin
        NearbyIdx := gAIFields.NavMesh.Polygons[Idx].Nearby[K];
        if (fInflInfo[Idx].Mark >= fInflInfo[NearbyIdx].Mark) then
        begin
          if (fQueueArray[NearbyIdx].Visited < fVisitedIdx) then
            InsertInQueue(NearbyIdx);
          if (fQueueArray[NearbyIdx].Visited < 10) then
          begin
            fQueueArray[NearbyIdx].Visited := fVisitedIdx;
            if (fQueueArray[NearbyIdx].Distance < fQueueArray[Idx].Distance) then
              Dir := KMGetDirection(gAIFields.NavMesh.Polygons[ Idx ].CenterPoint,gAIFields.NavMesh.Polygons[ NearbyIdx ].CenterPoint)
            else
              Dir := KMGetDirection(gAIFields.NavMesh.Polygons[ NearbyIdx ].CenterPoint,gAIFields.NavMesh.Polygons[ Idx ].CenterPoint);
            Exit( KMPointDir(gAIFields.NavMesh.Polygons[ Idx ].NearbyPoints[K], Dir) );
          end;
          fQueueArray[NearbyIdx].Visited := fVisitedIdx;
        end;
      end;
    end;
  end;

  function FindPositions(aLineIdx: Integer; aCnt: Word): TKMPointDirArray;
  var
    Overflow, Idx, NearbyIdx: Word;
    MinMark, K, L, Cnt, QueueCntBackup: Integer;
    Dir: TKMDirection;
  begin
    SetLength(Result, aCnt);
    with BattleLines.Lines[aLineIdx] do
    begin
      // Find best mark
      MinMark := 0;
      for K := 0 to PolygonsCount - 1 do
        MinMark := Max(MinMark, fInflInfo[ Polygons[K] ].Mark);

      // Find positions
      Cnt := 0;
      fQueueCnt := 0;
      Overflow := 0;
      fVisitedIdx := fVisitedIdx + 1;
      while (aCnt > Cnt) AND (Overflow < 100) do
      begin
        Inc(Overflow);
        // Add all marks of specific level to queue
        for K := 0 to PolygonsCount - 1 do
          if (MinMark <= fInflInfo[ Polygons[K] ].Mark) AND not IsVisited(Polygons[K]) then
            InsertInQueue(Polygons[K]);

        // Loop over queue but dont process the children
        QueueCntBackup := fQueueCnt;
        for K := 1 to QueueCntBackup do
        begin
          RemoveFromQueue(Idx);
          for L := 0 to gAIFields.NavMesh.Polygons[Idx].NearbyCount - 1 do
          begin
            NearbyIdx := gAIFields.NavMesh.Polygons[Idx].Nearby[L];
            if (fInflInfo[Idx].Mark >= fInflInfo[NearbyIdx].Mark) AND (fQueueArray[NearbyIdx].Visited < fVisitedIdx) then
            begin
              InsertInQueue(NearbyIdx);
              if (fQueueArray[NearbyIdx].Visited < 10) then // Polygon is not used
              begin
                fQueueArray[NearbyIdx].Visited := fVisitedIdx;
                if (fQueueArray[NearbyIdx].Distance < fQueueArray[Idx].Distance) then
                  Dir := KMGetDirection(gAIFields.NavMesh.Polygons[ Idx ].CenterPoint,gAIFields.NavMesh.Polygons[ NearbyIdx ].CenterPoint)
                else
                  Dir := KMGetDirection(gAIFields.NavMesh.Polygons[ NearbyIdx ].CenterPoint,gAIFields.NavMesh.Polygons[ Idx ].CenterPoint);
                Result[Cnt] := KMPointDir(gAIFields.NavMesh.Polygons[ Idx ].NearbyPoints[L], Dir);
                Inc(Cnt);
                if (Cnt >= aCnt) then
                  Exit;
              end;
              fQueueArray[NearbyIdx].Visited := fVisitedIdx;
            end;
          end;
        end;

        MinMark := MinMark - 2;
      end;
    end;
    SetLength(Result, Cnt);
  end;

var
  K, L, M, Idx, BestIdx: Integer;
  Price, BestPrice: Single;
  GroupPoint, LinePoint: TKMPoint;
  G: TKMUnitGroup;
  PositionAssigned: TBooleanArray;
  LineEval: array of array[TKMGroupType] of Word;
  PosReq: array of Word;
  Positions: TKMPointDirArray;
begin
  fVisitedIdx := 10;
  // Clear array
  SetLength(LineEval, BattleLines.Count);
  for K := Low(LineEval) to High(LineEval) do
    FillChar(LineEval[0], SizeOf(LineEval[0]), #0);
  // Evaluate battle lines
  for K := 0 to BattleLines.Count - 1 do
    for L := 0 to BattleLines.Lines[K].GroupsCount - 1 do
    begin
      G := Enemy.Groups[ BattleLines.Lines[K].Groups[L] ];
      Inc(LineEval[K,G.GroupType], G.Count);
    end;
  // Get count of required positions in a combat line
  SetLength(TargetLines, Ally.GroupsCount);
  FillChar(TargetLines[0], Length(TargetLines) * SizeOf(TargetLines[0]), #0);
  SetLength(PosReq,BattleLines.Count);
  if (BattleLines.Count = 1) then
    PosReq[0] := Ally.GroupsCount
  else
  begin
    FillChar(PosReq[0], Length(PosReq) * SizeOf(PosReq[0]), #0);
    for K := 0 to Ally.GroupsCount - 1 do
    begin
      if (K > 0) AND (Ally.Groups[K-1] = Ally.Groups[K]) then
        continue;
      BestPrice := 1E10;
      GroupPoint := Ally.Groups[K].Position;
      for L := 0 to BattleLines.Count - 1 do
      begin
        M := 0;
        while (M < BattleLines.Lines[L].PolygonsCount) do
        begin
          Idx := BattleLines.Lines[L].Polygons[M];
          LinePoint := gAIFields.NavMesh.Polygons[ Idx ].CenterPoint;
          Price := KMDistanceSqr(LinePoint, GroupPoint) - fInflInfo[Idx].Mark * 32;
          if (Price < BestPrice) then
          begin
            BestPrice := Price;
            TargetLines[K] := L;
          end;
          M := M + 5; // Skip some polygons (raw estimation is ok)
        end;
      end;
      Inc(PosReq[ TargetLines[K] ]);
    end;
  end;
  // Clear array
  SetLength(PositionAssigned, Ally.GroupsCount);
  for K := Low(PositionAssigned) to High(PositionAssigned) do
    PositionAssigned[K] := False;
  // Find positions in Combat line and assign them
  SetLength(TargetPositions, Ally.GroupsCount);   // GroupsNumber
  SetLength(InCombatLine, Ally.GroupsCount);
  FillChar(TargetPositions[0],Length(TargetPositions) * SizeOf(TargetPositions[0]), #0);
  FillChar(InCombatLine[0],Length(InCombatLine) * SizeOf(InCombatLine[0]), #0);
  BestIdx := 0;
  for K := 0 to BattleLines.Count - 1 do
    if (PosReq[K] > 0) then
    begin
      Positions := FindPositions(K, PosReq[K]);
      for L := 0 to Length(Positions) - 1 do
      begin
        BestPrice := 1E10;
        for M := 0 to Ally.GroupsCount - 1 do
          if not PositionAssigned[M] AND (TargetLines[M] = K) AND not ((M > 0) AND (Ally.Groups[M-1] = Ally.Groups[M])) then // Avoid duplicates
          begin
            GroupPoint := Ally.Groups[M].Position;
            Price := KMDistanceSqr(Positions[L].Loc, GroupPoint);
            InCombatLine[M] := InCombatLine[M] OR (Price < 10*10);
            if (Price < BestPrice) then
            begin
              BestPrice := Price;
              BestIdx := M;
            end;
          end;
        TargetPositions[BestIdx] := Positions[L];
        PositionAssigned[BestIdx] := True;
      end;
    end;
end;


procedure TArmyForwardFF.Paint();
  procedure DrawPolygon(aIdx: Integer; const Opacity: Byte; aFillColor: Cardinal; aText: String = '');
  var
    P0,P1,P2: TKMPoint;
  begin
    if (Opacity = 0) then
      Exit;
    aFillColor := aFillColor OR (Opacity shl 24);
    with gAIFields.NavMesh do
    begin
      P0 := Nodes[ Polygons[aIdx].Indices[0] ];
      P1 := Nodes[ Polygons[aIdx].Indices[1] ];
      P2 := Nodes[ Polygons[aIdx].Indices[2] ];
      gRenderAux.TriangleOnTerrain(P0.X,P0.Y, P1.X,P1.Y, P2.X,P2.Y, aFillColor);
      if (Length(aText) > 0) then
        gRenderAux.Text(Polygons[aIdx].CenterPoint.X, Polygons[aIdx].CenterPoint.Y, aText, $FFFFFFFF);
    end;
  end;
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $7700FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
var
  K: Integer;
  //PL: TKMHandID;
begin
  //PL := gMySpectator.HandID;

  fBackwardFF.Paint();
  for K := 0 to fCntEnemyPoly - 1 do
    DrawPolygon(Enemy.GroupsPoly[K], 20, COLOR_RED);

  for K := 0 to Length(TargetPositions) - 1 do
    with TargetPositions[K].Loc do
      gRenderAux.Quad(X, Y, ($77 shl 24) OR COLOR_WHITE);
end;







{ TArmyBackwardFF }
constructor TArmyBackwardFF.Create(aSorted: Boolean = False);
begin
  inherited Create(aSorted);
end;


function TArmyBackwardFF.CanBeExpanded(const aIdx: Word): Boolean;
begin
  Result := True;

  EvaluateLine(aIdx);
end;


procedure TArmyBackwardFF.MarkAsVisited(const aIdx: Word);
begin
  fQueueArray[aIdx].Visited := fVisitedIdx;
end;


procedure TArmyBackwardFF.ComputeWeightedDistance(const aIdx: Word);
begin
  fQueueArray[aIdx].Distance := High(Word) - fInflInfo[aIdx].Distance - fInflInfo[aIdx].EnemyInfluence * GA_ATTACK_NMAP_TArmyBackwardFF_EnemyInfluence;
end;


//procedure TArmyBackwardFF.InitQueue(const aMaxIdx: Integer; var aInitIdxArray: TKMWordArray; aInitPolyGroups: TKMUnitGroupArray);
procedure TArmyBackwardFF.InitQueue(var aEnemy: TKMAllianceInfo);
  function FindPolyIdx(aPoly: Integer): Integer;
  var
    K: Integer;
  begin
    Result := fBattleLines.Count;
    for K := 0 to Result - 1 do
      if (aPoly = fBattleLines.Lines[K].Polygons[0]) then
        Exit(K);
  end;
  procedure CheckNewBattleLine(aPolygon: Word; aBattleLineIdx, aPolyIdx: Integer);
  begin
    with fBattleLines.Lines[aBattleLineIdx] do
      if (fBattleLines.Count = aBattleLineIdx) then
      begin
        GroupsCount := 0;
        HousesCount := 0;
        PolygonsCount := 1;
        SetLength(Groups,4); // Create new array
        SetLength(Houses,4); // Create new array
        SetLength(Polygons,8); // Create new array
        Polygons[0] := aPolygon;
      end;
  end;
  procedure AddWordField(aFied: Integer; var aCount: Word; var aArr: TKMWordArray); inline;
  begin
    if (Length(aArr) <= aCount) then
      SetLength(aArr,Length(aArr) + 4);
    aArr[ aCount ] := aFied;
    aCount := aCount + 1;
  end;
var
  K, Idx: Integer;
begin
  {$IFDEF DEBUG_BattleLines}
    fDebugLines.Count := 0;
  {$ENDIF}
  fQueueCnt := 0;
  fExpandedPolygonsCnt := 0;
  // Mark init points and create lines
  fBattleLines.Count := 0;
  fBattleLines.Price := 0;
  SetLength(fBattleLines.Lines, aEnemy.GroupsCount + aEnemy.HousesCount);
  // Copy groups
  for K := 0 to aEnemy.GroupsCount - 1 do
  begin
    Idx := FindPolyIdx(aEnemy.GroupsPoly[K]);
    CheckNewBattleLine(aEnemy.GroupsPoly[K], Idx, K);
    with fBattleLines.Lines[Idx] do
      AddWordField(K, GroupsCount, Groups);
    Inc(fBattleLines.Count,Byte(Idx = fBattleLines.Count));
  end;
  // Copy houses
  for K := 0 to aEnemy.HousesCount - 1 do
  begin
    Idx := FindPolyIdx(aEnemy.HousesPoly[K]);
    CheckNewBattleLine(aEnemy.HousesPoly[K], Idx, K);
    with fBattleLines.Lines[Idx] do
      AddWordField(K, HousesCount, Houses);
    Inc(fBattleLines.Count,Byte(Idx = fBattleLines.Count));
  end;
  // Add to queue
  fVisitedIdx := 5;
  for K := 0 to fBattleLines.Count - 1 do
  begin
    Idx := fBattleLines.Lines[K].Polygons[0];
    if not IsVisited(Idx) then
    begin
      MarkAsVisited(Idx);
      ComputeWeightedDistance(Idx);
      InsertAndSort(Idx);
      fInflInfo[Idx].Mark := High(Word);
    end;
  end;
end;


procedure TArmyBackwardFF.ExpandPolygon(aIdx: Word; aLineIdx1: Integer = -1; aPolyIdx1: Integer = -1);
  function FindPolygonInLines(aIdx: Integer; var aLineIdx, aPolyIdx: Integer): Boolean;
  var
    K, L: Integer;
  begin
    Result := False;
    for K := 0 to fBattleLines.Count - 1 do
      for L := 0 to fBattleLines.Lines[K].PolygonsCount - 1 do
        if (aIdx = fBattleLines.Lines[K].Polygons[L]) then
        begin
          aLineIdx := K;
          aPolyIdx := L;
          Exit(True);
        end;
  end;
var
  K, NearbyIdx, LineIdx1, LineIdx2, PolyIdx1, PolyIdx2, Cnt: Integer;
begin
  fExpandedPolygonsCnt := fExpandedPolygonsCnt + 1;
  if (aLineIdx1 <> -1) then
  begin
    LineIdx1 := aLineIdx1;
    PolyIdx1 := aPolyIdx1;
  end
  else if FindPolygonInLines(aIdx, LineIdx1, PolyIdx1) then
  begin
    Dec(fBattleLines.Lines[LineIdx1].PolygonsCount);
    fBattleLines.Lines[LineIdx1].Polygons[PolyIdx1] := fBattleLines.Lines[LineIdx1].Polygons[ fBattleLines.Lines[LineIdx1].PolygonsCount ];
  end
  else
    Exit;

  for K := 0 to gAIFields.NavMesh.Polygons[aIdx].NearbyCount-1 do
  begin
    NearbyIdx := gAIFields.NavMesh.Polygons[aIdx].Nearby[K];
    // Expand polygon
    if not IsVisited(NearbyIdx) then
    begin
      MarkAsVisited(NearbyIdx);
      fInflInfo[NearbyIdx].Mark := fInflInfo[aIdx].Mark - 1;
      if (gAIFields.NavMesh.Polygons[NearbyIdx].NearbyCount = 3) then // New combat lines are created only from polygons with 3 surrounding polygons
      begin
        ComputeWeightedDistance(NearbyIdx);
        //if (fInflInfo[aIdx].Distance + 3 > fInflInfo[NearbyIdx].Distance) then
        //begin
          InsertAndSort(NearbyIdx);
          Inc(fBattleLines.Lines[LineIdx1].PolygonsCount);
          if (fBattleLines.Lines[LineIdx1].PolygonsCount > Length(fBattleLines.Lines[LineIdx1].Polygons)) then
            SetLength(fBattleLines.Lines[LineIdx1].Polygons, fBattleLines.Lines[LineIdx1].PolygonsCount + 16);
          fBattleLines.Lines[LineIdx1].Polygons[ fBattleLines.Lines[LineIdx1].PolygonsCount-1 ] := NearbyIdx;
        //end;
      end
      else
        ExpandPolygon(NearbyIdx, LineIdx1, PolyIdx1);
    end
    // Merge lines
    else if (fBattleLines.Count > 1) AND FindPolygonInLines(NearbyIdx, LineIdx2, PolyIdx2) AND (LineIdx1 <> LineIdx2) then
    begin
      Cnt := fBattleLines.Lines[LineIdx1].GroupsCount;
      if (fBattleLines.Lines[LineIdx2].GroupsCount > 0) then
      begin
        Inc(fBattleLines.Lines[LineIdx1].GroupsCount, fBattleLines.Lines[LineIdx2].GroupsCount);
        if (Length(fBattleLines.Lines[LineIdx1].Groups) < fBattleLines.Lines[LineIdx1].GroupsCount) then
          SetLength(fBattleLines.Lines[LineIdx1].Groups, fBattleLines.Lines[LineIdx1].GroupsCount + 8);
        Move(fBattleLines.Lines[LineIdx2].Groups[0], fBattleLines.Lines[LineIdx1].Groups[Cnt], SizeOf(fBattleLines.Lines[LineIdx1].Groups[0]) * fBattleLines.Lines[LineIdx2].GroupsCount);
      end;

      Cnt := fBattleLines.Lines[LineIdx1].PolygonsCount;
      if (fBattleLines.Lines[LineIdx2].PolygonsCount > 0) then
      begin
        Inc(fBattleLines.Lines[LineIdx1].PolygonsCount, fBattleLines.Lines[LineIdx2].PolygonsCount);
        if (Length(fBattleLines.Lines[LineIdx1].Polygons) < fBattleLines.Lines[LineIdx1].PolygonsCount) then
          SetLength(fBattleLines.Lines[LineIdx1].Polygons, fBattleLines.Lines[LineIdx1].PolygonsCount + 16);
        Move(fBattleLines.Lines[LineIdx2].Polygons[0], fBattleLines.Lines[LineIdx1].Polygons[Cnt], SizeOf(fBattleLines.Lines[LineIdx1].Polygons[0]) * fBattleLines.Lines[LineIdx2].PolygonsCount);
      end;

      Cnt := fBattleLines.Lines[LineIdx1].HousesCount;
      if (fBattleLines.Lines[LineIdx2].HousesCount > 0) then
      begin
        Inc(fBattleLines.Lines[LineIdx1].HousesCount, fBattleLines.Lines[LineIdx2].HousesCount);
        if (Length(fBattleLines.Lines[LineIdx1].Houses) < fBattleLines.Lines[LineIdx1].HousesCount) then
          SetLength(fBattleLines.Lines[LineIdx1].Houses, fBattleLines.Lines[LineIdx1].HousesCount + 8);
        Move(fBattleLines.Lines[LineIdx2].Houses[0], fBattleLines.Lines[LineIdx1].Houses[Cnt], SizeOf(fBattleLines.Lines[LineIdx1].Houses[0]) * fBattleLines.Lines[LineIdx2].HousesCount);
      end;

      Dec(fBattleLines.Count);
      fBattleLines.Lines[LineIdx2] := fBattleLines.Lines[ fBattleLines.Count ];
      if (LineIdx1 = fBattleLines.Count) then
        LineIdx1 := LineIdx2;
    end;
  end;
end;


procedure TArmyBackwardFF.BackwardFlood(var aEnemy: TKMAllianceInfo);
var
  InEnemyInfluence: Boolean;
  Idx, OldIdx, Overflow, Overflow2: Word;
begin
  //InitQueue(aInitPolyCnt - 1, aInitPolyArr, aInitPolyGroups);
  InitQueue(aEnemy);
  if (fQueueCnt <= 0) then
    Exit;

  // Expand enemy influence
  InEnemyInfluence := True;
  Overflow := 0;
  while InEnemyInfluence AND (Overflow < 5000) AND (fQueueCnt > 0) do
  begin
    InEnemyInfluence := False;
    Inc(Overflow);

    OldIdx := fStartQueue;
    Idx := fStartQueue;
    Overflow2 := 0;
    repeat
      Inc(Overflow2);
      if (fInflInfo[Idx].EnemyInfluence > GA_ATTACK_NMAP_BackwardFlood_MaxEnemyInfluence) then
      begin
        fQueueArray[OldIdx].Next := fQueueArray[Idx].Next;
        if (Idx = fStartQueue) then fStartQueue := fQueueArray[Idx].Next;
        if (Idx = fEndQueue)   then fEndQueue := OldIdx;
        Dec(fQueueCnt);
        ExpandPolygon(Idx);
        {$IFDEF DEBUG_BattleLines}
        //SaveDebugLine();
        {$ENDIF}
        InEnemyInfluence := True;
        break;
      end;
      OldIdx := Idx;
      Idx := fQueueArray[Idx].Next;
    until (OldIdx <> fEndQueue) OR (Overflow2 < 1000) OR (fQueueCnt <= 0);
  end;
  {$IFDEF DEBUG_BattleLines}
  fDebugLines.LineStartIdx := fDebugLines.Count;
  {$ENDIF}

  // Start searching for defense line
  Idx := fStartQueue;
  while RemoveFromQueue(Idx) AND (fQueueArray[Idx].Distance < High(Word) - GA_ATTACK_NMAP_BackwardFlood_MaxAllyInfluence) do
  begin
    if CanBeExpanded(Idx) then
      ExpandPolygon(Idx);
    {$IFDEF DEBUG_BattleLines}
    //SaveDebugLine();
    {$ENDIF}
  end;
end;


procedure TArmyBackwardFF.EvaluateLine(const aIdx: Word);
var
  K, L, Idx, MinMark, MaxMark, MinDist, MaxDist: Integer;
  Evaluation: Single;
begin
  // Calculate evaluation of actual defensive position
  MaxDist := 0;
  MinDist := High(Word);
  MaxMark := 0;
  MinMark := High(Word);
  for K := 0 to fBattleLines.Count - 1 do
    for L := 0 to fBattleLines.Lines[K].PolygonsCount - 1 do
    begin
      Idx := fBattleLines.Lines[K].Polygons[L];
      MaxDist := Max(MaxDist,fQueueArray[Idx].Distance);
      MinDist := Min(MinDist,fQueueArray[Idx].Distance);
      MaxMark := Max(MaxMark,fInflInfo[Idx].Mark);
      MinMark := Min(MinMark,fInflInfo[Idx].Mark);
      //Evaluation := + Evaluation + fQueueArray[Idx].Distance * 10;
    end;
  //MaxMark := High(Word) - MaxMark;
  //MinMark := High(Word) - MinMark;
  //Evaluation := fQueueCnt * 8 - abs(High(Word) - MaxDist) * 2 - abs(High(Word) - MinDist) * 2;
  Evaluation := fQueueCnt * GA_ATTACK_NMAP_EvaluateLine_QueueCnt + abs(High(Word) - MinDist) * GA_ATTACK_NMAP_EvaluateLine_MinDist;


  // If is evaluation better save polygons
  if (Evaluation < fBestBattleLines.Price) then
  begin
    fBestBattleLines.Count := fBattleLines.Count;
    fBestBattleLines.Price := Evaluation;
    if (Length(fBestBattleLines.Lines) < fBattleLines.Count) then
      SetLength(fBestBattleLines.Lines, fBattleLines.Count + 16);
    for K := 0 to fBattleLines.Count - 1 do
    begin
      fBestBattleLines.Lines[K].GroupsCount   := fBattleLines.Lines[K].GroupsCount;
      fBestBattleLines.Lines[K].HousesCount   := fBattleLines.Lines[K].HousesCount;
      fBestBattleLines.Lines[K].PolygonsCount := fBattleLines.Lines[K].PolygonsCount;
      SetLength(fBestBattleLines.Lines[K].Groups,   fBattleLines.Lines[K].GroupsCount);
      SetLength(fBestBattleLines.Lines[K].Houses,   fBattleLines.Lines[K].HousesCount);
      SetLength(fBestBattleLines.Lines[K].Polygons, fBattleLines.Lines[K].PolygonsCount);
      if (fBattleLines.Lines[K].PolygonsCount > 0) then Move(fBattleLines.Lines[K].Polygons[0], fBestBattleLines.Lines[K].Polygons[0], SizeOf(fBattleLines.Lines[K].Polygons[0]) * fBattleLines.Lines[K].PolygonsCount);
      if (fBattleLines.Lines[K].GroupsCount   > 0) then Move(fBattleLines.Lines[K].Groups[0],   fBestBattleLines.Lines[K].Groups[0],   SizeOf(fBattleLines.Lines[K].Groups[0])   * fBattleLines.Lines[K].GroupsCount);
      if (fBattleLines.Lines[K].HousesCount   > 0) then Move(fBattleLines.Lines[K].Houses[0],   fBestBattleLines.Lines[K].Houses[0],   SizeOf(fBattleLines.Lines[K].Houses[0])   * fBattleLines.Lines[K].HousesCount);
    end;
  end;
end;


{$IFDEF DEBUG_BattleLines}
procedure TArmyBackwardFF.SaveDebugLine();
var
  K,L: Integer;
begin
  if (fBattleLines.Count <= 0) OR (Length(fBattleLines.Lines) <= 0) then
    Exit;
  if (fDebugLines.Count <= Length(fDebugLines.DBLs)) then
    SetLength(fDebugLines.DBLs, Length(fDebugLines.DBLs) + 64);
  L := fDebugLines.Count;
  Inc(fDebugLines.Count);

  fDebugLines.DBLs[L].Count := fBattleLines.Count;
  fDebugLines.DBLs[L].Price := 0;
  if (Length(fDebugLines.DBLs[L].Lines) <= fBattleLines.Count) then
    SetLength(fDebugLines.DBLs[L].Lines, fBattleLines.Count + 16);
  for K := 0 to fBattleLines.Count - 1 do
    if (fBattleLines.Lines[K].PolygonsCount > 0) then
    begin
      fDebugLines.DBLs[L].Lines[K].GroupsCount   := fBattleLines.Lines[K].GroupsCount;
      fDebugLines.DBLs[L].Lines[K].PolygonsCount := fBattleLines.Lines[K].PolygonsCount;
      SetLength(fDebugLines.DBLs[L].Lines[K].Groups,   fBattleLines.Lines[K].GroupsCount);
      SetLength(fDebugLines.DBLs[L].Lines[K].Polygons, fBattleLines.Lines[K].PolygonsCount);
      if (fBattleLines.Lines[K].GroupsCount   > 0) then Move(fBattleLines.Lines[K].Groups[0],   fDebugLines.DBLs[L].Lines[K].Groups[0],   SizeOf(fBattleLines.Lines[K].Groups[0])   * fBattleLines.Lines[K].GroupsCount);
      if (fBattleLines.Lines[K].PolygonsCount > 0) then Move(fBattleLines.Lines[K].Polygons[0], fDebugLines.DBLs[L].Lines[K].Polygons[0], SizeOf(fBattleLines.Lines[K].Polygons[0]) * fBattleLines.Lines[K].PolygonsCount);
    end;
end;
{$ENDIF}


function TArmyBackwardFF.FindTeamBattleLine(var aEnemy: TKMAllianceInfo; var aOwners: TKMHandIDArray; var aDefInfo: TKMInflInfoArray; var aQueueArray: TPolygonsQueueArr): TKMBattleLines;
begin
  fOwner := aOwners[0];
  fInflInfo := aDefInfo;
  fQueueArray := aQueueArray;
  fBestBattleLines.Count := 0;
  fBestBattleLines.Price := +1E10;
  if (aEnemy.GroupsCount > 0) OR (aEnemy.HousesCount > 0) then
    BackwardFlood(aEnemy);
  Result := fBestBattleLines;
end;


procedure TArmyBackwardFF.Paint();
  procedure DrawPolygon(aIdx: Integer; aOffset: Single; aOpacity: Byte; aFillColor: Cardinal; aText: String = '');
  var
    P0,P1,P2: TKMPoint;
  begin
    if (aOpacity = 0) then
      Exit;
    with gAIFields.NavMesh do
    begin
      P0 := Nodes[ Polygons[aIdx].Indices[0] ];
      P1 := Nodes[ Polygons[aIdx].Indices[1] ];
      P2 := Nodes[ Polygons[aIdx].Indices[2] ];
      gRenderAux.TriangleOnTerrain(P0.X,P0.Y, P1.X,P1.Y, P2.X,P2.Y, aFillColor OR (aOpacity shl 24));
      if (Length(aText) > 0) then
        gRenderAux.Text(Polygons[aIdx].CenterPoint.X, Polygons[aIdx].CenterPoint.Y + aOffset, aText, $FFFFFFFF);
    end;
  end;
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $7700FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
{$IFDEF DEBUG_BattleLines}
var
  K,L,Idx: Integer;
  Color, TickIdx: Cardinal;
{$ENDIF}
begin
  {$IFDEF DEBUG_BattleLines}

  { DISTANCE
  for K := 0 to Length(fQueueArray) - 1 do
    if (gAIFields.NavMesh.Polygons[K].NearbyCount = 3) then
      DrawPolygon(K, 0, 1+100*Byte(fQueueArray[K].Distance = High(Word)), COLOR_BLUE, IntToStr(High(Word) - fQueueArray[K].Distance));
  //}

  { MARK
  for K := 0 to Length(fQueueArray) - 1 do
    DrawPolygon(K, 0, 1, COLOR_WHITE, IntToStr(High(Word) - fInflInfo[K].Mark));
  //}

  //{ BEST BATTLE LINE: MARK
  for K := 0 to fBestBattleLines.Count - 1 do
    for L := 0 to fBestBattleLines.Lines[K].PolygonsCount - 1 do
      with fBestBattleLines.Lines[K] do
      begin
        DrawPolygon(Polygons[L], -2, 25, COLOR_GREEN, IntToStr(High(Word) - fInflInfo[ Polygons[L] ].Mark));
        DrawPolygon(Polygons[L], -1, 25, COLOR_GREEN, IntToStr(High(Word) - fQueueArray[ Polygons[L] ].Distance));
      end;
  //}

  { DEBUG LINE
  if fDebugLines.Count > 0 then
  begin
    TickIdx := Round(DateUtils.MilliSecondsBetween(Now, 0) * 0.01) mod fDebugLines.Count;
    Color := COLOR_WHITE;
    if (fDebugLines.LineStartIdx >= TickIdx) then
      Color := COLOR_RED;
    with fDebugLines.DBLs[TickIdx] do
      for K := 0 to Count - 1 do
        for L := 0 to Lines[K].PolygonsCount - 1 do
        begin
          Idx := Lines[K].Polygons[L];
          DrawPolygon(Idx, 0, 50, Color, IntToStr(fQueueArray[Idx].Distance));
        end;
  end;
  //}

  {$ENDIF}
end;



end.

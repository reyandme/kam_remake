unit KM_NavMeshInfluences;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_Defaults, KM_CommonTypes,
  KM_Points, KM_NavMeshFloodFill;

type
  TKMEnemyStatistics = record
    Player: TKMHandID;
    Distance: Word;
    ClosestPoint: TKMPoint;
  end;
  TKMEnemyStatisticsArray = array of TKMEnemyStatistics;

  // 1 universal class for city and army influence search
  TNavMeshInfluenceSearch = class(TNavMeshFloodFill)
  private
    fEnemies: TKMHandIDArray;
  protected
    fOwner: TKMHandID;
    fHouseInfluence: Boolean;
    fHighEnemiesIdx, fHighStatsIdx, fMaxEnemiesCnt: Integer;
    fEnemiesStats: TKMEnemyStatisticsArray;

    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); override;
  public
    function FindClosestEnemies(const aOwner: TKMHandID; aCenterPoints: TKMPointArray; var aEnemiesStats: TKMEnemyStatisticsArray; aHouseInfluence: Boolean = True): Boolean;
  end;

  // 1 universal class for city and army influence flood fill
  TKMInfluenceFloodFill = class(TNavMeshFloodFill)
  private
    fCityFlood: Boolean;
    fDecreaseCoef: Word;
    fUnitStrength, fMaxDistance, fHouseInfluence: Word;
    fGroupType: TKMGroupType;
  protected
    fOwner: TKMHandID;
    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); override;
  public
    function MilitaryPresence(aPlayer: TKMHandID; aUnitStrength, aMaxDistance, aMaximalIdx: Word; aGroupType: TKMGroupType; aInitIdxArray: TKMWordArray): Boolean;
    function HouseInfluence(aPlayer: TKMHandID; aHouseInfluence, aMaxDistance, aMaximalIdx: Word; aInitIdxArray: TKMWordArray): Boolean;
  end;

  // Evaluation of terrain (finds large areas without borders)
  TKMWalkableAreasDetector = class(TNavMeshFloodFill)
  private
  protected
    fMaxDistance: Word;
    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); override;
  public
    WalkableAreas: TKMByteArray;
    procedure MarkPolygons();
  end;

implementation
uses
  KM_AIFields, KM_AIInfluences, KM_NavMesh, KM_Hand, KM_HandsCollection, KM_ResHouses, KM_ArmyAttack;


{ TNavMeshInfluenceSearch }
function TNavMeshInfluenceSearch.CanBeExpanded(const aIdx: Word): Boolean;
begin
  // Can be visited only in case that we have space in array (and we are not out of enemies)
  Result := (fHighEnemiesIdx >= 0) AND (fHighStatsIdx < fMaxEnemiesCnt);
end;


procedure TNavMeshInfluenceSearch.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
const
  HOUSE_INFLUENCE_LIMIT = 200;
  ARMY_INFLUENCE_LIMIT = 1;
var
  I: Integer;
begin
  inherited MarkAsVisited(aIdx, aDistance, aPoint);

  // Scan current polygon and try find enemies presence
  for I := 0 to fHighEnemiesIdx do
    if    (      fHouseInfluence AND (gAIFields.Influences.Ownership[  fEnemies[I], aPoint.Y, aPoint.X  ] > HOUSE_INFLUENCE_LIMIT)  )
       OR (  not fHouseInfluence AND (gAIFields.Influences.PresenceAllGroups[  fEnemies[I], aIdx  ] > ARMY_INFLUENCE_LIMIT) ) then
    begin
      // Mark presence
      with fEnemiesStats[fHighStatsIdx] do
      begin
        Player := fEnemies[I];
        Distance := fQueueArray[aIdx].Distance;
        ClosestPoint := aPoint;
      end;
      fEnemies[I] := fEnemies[ fHighEnemiesIdx ];
      fHighEnemiesIdx := fHighEnemiesIdx - 1;
      fHighStatsIdx := fHighStatsIdx + 1;
      if not CanBeExpanded(aIdx) then
        break;
    end;
end;


function TNavMeshInfluenceSearch.FindClosestEnemies(const aOwner: TKMHandID; aCenterPoints: TKMPointArray; var aEnemiesStats: TKMEnemyStatisticsArray; aHouseInfluence: Boolean = True): Boolean;
  // Check if player is active in the meaning of threat for new AI
  function PlayerActive(aPL: TKMHandID): Boolean;
  var
    HT: TKMHouseType;
  begin
    if not gHands[aPL].Enabled OR gHands[aPL].AI.HasLost then
      Exit(False);
    for HT in TARGET_HOUSES do
      if (gHands[aPL].Stats.GetHouseQty(HT) > 0) then
        Exit(True);
    Result := (gHands[aPL].Stats.GetArmyCount > 0);
  end;
const
  MAX_ENEMIES_AT_ONCE = 11;
var
  PL: TKMHandID;
  I, Cnt: Integer;
  InitIdxArray: TKMWordArray;
begin
  Result := False;
  fOwner := aOwner;
  fHouseInfluence := aHouseInfluence;

  // Find center points of polygons
  Cnt := Length(aCenterPoints);
  SetLength(InitIdxArray, Cnt);
  for I := 0 to Cnt - 1 do
    InitIdxArray[I] := gAIFields.NavMesh.KMPoint2Polygon[ aCenterPoints[I] ];

  // Find enemies (indexes)
  SetLength(fEnemies, gHands.Count - 1);
  Cnt := 0;
  for PL := 0 to gHands.Count - 1 do
    if (gHands[aOwner].Alliances[PL] = atEnemy) AND PlayerActive(PL) then
    begin
      fEnemies[Cnt] := PL;
      Cnt := Cnt + 1;
    end;
  if (Cnt = 0) then // No enemy left
    Exit;

  // Init variables
  fMaxEnemiesCnt := Min(Cnt, MAX_ENEMIES_AT_ONCE);
  fHighEnemiesIdx := fMaxEnemiesCnt - 1;
  SetLength(fEnemiesStats, fMaxEnemiesCnt);
  fHighStatsIdx := 0;

  // Flood fill
  FillPolygons(High(InitIdxArray), InitIdxArray);
  Result := (fHighStatsIdx > 0);

  // Set Result length
  SetLength(fEnemiesStats, fHighStatsIdx);
  aEnemiesStats := fEnemiesStats;
end;




{ TKMInfluenceFloodFill }
function TKMInfluenceFloodFill.CanBeExpanded(const aIdx: Word): Boolean;
begin
  Result := (fQueueArray[aIdx].Distance < fMaxDistance);
end;


procedure TKMInfluenceFloodFill.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
const
  HOUSE_COEF = 2;
begin
  if fCityFlood then
    gAIFields.Influences.OwnPoly[fOwner,aIdx] := Max(0, fHouseInfluence - (aDistance shl HOUSE_COEF))
  else
    gAIFields.Influences.IncPresence[fOwner,aIdx,fGroupType] := Max(0, fUnitStrength - aDistance * fDecreaseCoef );
  inherited MarkAsVisited(aIdx, aDistance, aPoint);
end;


function TKMInfluenceFloodFill.MilitaryPresence(aPlayer: TKMHandID; aUnitStrength, aMaxDistance, aMaximalIdx: Word; aGroupType: TKMGroupType; aInitIdxArray: TKMWordArray): Boolean;
begin
  fCityFlood := False;
  fOwner := aPlayer;
  fUnitStrength := aUnitStrength;
  fMaxDistance := aMaxDistance;
  fGroupType := aGroupType;
  fDecreaseCoef := Max( 1, Round(aUnitStrength / (aMaxDistance * 1.0)) );
  Result := inherited FillPolygons(aMaximalIdx, aInitIdxArray);
end;


function TKMInfluenceFloodFill.HouseInfluence(aPlayer: TKMHandID; aHouseInfluence, aMaxDistance, aMaximalIdx: Word; aInitIdxArray: TKMWordArray): Boolean;
begin
  fCityFlood := True;
  fOwner := aPlayer;
  fHouseInfluence := aHouseInfluence;
  fMaxDistance := aMaxDistance;
  Result := inherited FillPolygons(aMaximalIdx, aInitIdxArray);
end;




{ TKMWalkableAreasDetector }
function TKMWalkableAreasDetector.CanBeExpanded(const aIdx: Word): Boolean;
begin
  Result := fQueueArray[aIdx].Distance < fMaxDistance;
end;


procedure TKMWalkableAreasDetector.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
begin
  with fQueueArray[aIdx] do
  begin
    Visited := fVisitedIdx;
    DistPoint := aPoint;
    Distance := aDistance;
  end;
  WalkableAreas[aIdx] := WalkableAreas[aIdx] + 1;
end;


procedure TKMWalkableAreasDetector.MarkPolygons();
const
  CENTER_POLYGON = 15;
  BORDER_POLYGON = CENTER_POLYGON - 10;
var
  I: Integer;
  InitIdxArray: TKMWordArray;
begin
  SetLength(WalkableAreas, Length(gAIFields.NavMesh.Polygons));
  SetLength(InitIdxArray, 1);
  for I := 0 to Length(gAIFields.NavMesh.Polygons) - 1 do
    WalkableAreas[I] := 0;
  for I := 0 to Length(gAIFields.NavMesh.Polygons) - 1 do
  begin
    if (gAIFields.NavMesh.Polygons[I].NearbyCount = 3) then
    begin
      fMaxDistance := CENTER_POLYGON;
      //   ...
    end
    else
    begin
      fMaxDistance := BORDER_POLYGON;
      //   ...
    end;
    InitIdxArray[0] := I;
    FillPolygons(0, InitIdxArray);
  end;
end;


end.

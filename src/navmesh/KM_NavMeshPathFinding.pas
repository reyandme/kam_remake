{
NavMesh - pathfinding
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_NavMeshPathFinding;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_CommonTypes, KM_Points,
  BinaryHeap, KM_Defaults;


type
  TPathfindingMode = ( pmShortestWay,   // Find shortest way in NavMesh
                       pmAvoidTraffic,  // Try avoid traffic
                       pmAvoidSpecEnemy // Try avoid anti type units (cav will keep distance form spears etc)
                     );

  TNavMeshNode = class
    Idx,Estim: Word; // Index of navMeshNode in navmesh, estimated cost from navMeshNode to end
    CostTo: Cardinal; // Cost to Idx navMeshNode
    Point: TKMPoint; // Point in navMeshNode of navmesh (each triangle [created by points in navMeshNode] have its point -> multiple poits will create path)
    Parent: TNavMeshNode; // Parent navMeshNode
  end;

  TNavMeshPathFinding = class
  private
    fStart, fEnd: Word;
    fHeap: TBinaryHeap;
    fMinN: TNavMeshNode;
    fUsedNodes: array of TNavMeshNode;

    fOwner: TKMHandID;
    fGroupType: TKMGroupType;
    fMode: TPathfindingMode;

    function HeapCmp(A,B: Pointer): Boolean;
    procedure Flush(aDestroy: Boolean = False);
  protected
    function GetNodeAt(aIdx: Word): TNavMeshNode;
    function MovementCost(aFrom, aTo: Word; var aSPoint, aEPoint: TKMPoint): Cardinal;
    function EstimateToFinish(aIdx: Word): Word;

    function InitPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
    function InitRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
    function MakeRoute(): Boolean;
    procedure ReturnPolygonRoute(out aDistance: Word; out aRoutePolygonArray: TKMWordArray);
    procedure ReturnRoute(out aDistance: Word; out aRoutePointArray: TKMPointArray);
  public
    constructor Create();
    destructor Destroy(); override;


    //function WalkableDistance(aStart, aEnd: TKMPoint; out aDistance: Word): Boolean;
    function ShortestPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
    function ShortestRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
    function AvoidTrafficRoute(aOwner: TKMHandID; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
    function AvoidEnemyRoute(aOwner: TKMHandID; aGroup: TKMGroupType; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
  end;


implementation
uses
   KM_AIFields, KM_NavMesh, KM_NavMeshGenerator, KM_AIParameters;


{ TNavMeshPathFinding }
constructor TNavMeshPathFinding.Create;
begin
  inherited;
  fHeap := TBinaryHeap.Create(High(Word));
  fHeap.Cmp := HeapCmp;
end;


destructor TNavMeshPathFinding.Destroy;
begin
  Flush(true);
  fHeap.Free;
  inherited;
end;


function TNavMeshPathFinding.HeapCmp(A,B: Pointer): Boolean;
begin
  if (A = nil) then
    Result := True
  else
    Result := (B = nil) OR (TNavMeshNode(A).Estim + TNavMeshNode(A).CostTo < TNavMeshNode(B).Estim + TNavMeshNode(B).CostTo);
end;


procedure TNavMeshPathFinding.Flush(aDestroy: Boolean = False);
var
  I: Integer;
begin
  if not aDestroy AND (Length(fUsedNodes) <> Length(gAIFields.NavMesh.Polygons)) then
    SetLength(fUsedNodes, Length(gAIFields.NavMesh.Polygons));
  for I := Length(fUsedNodes)-1 downto 0 do
  begin
    fUsedNodes[I].Free;
    fUsedNodes[I] := nil;
  end;
end;


function TNavMeshPathFinding.GetNodeAt(aIdx: Word): TNavMeshNode;
begin
  if (fUsedNodes[aIdx] = nil) then
  begin
    fUsedNodes[aIdx] := TNavMeshNode.Create;
    fUsedNodes[aIdx].Idx := aIdx;
    fUsedNodes[aIdx].Estim := EstimateToFinish(aIdx);
    //fUsedNodes[aIdx].CostTo := 0;
    //fUsedNodes[aIdx].Parent := nil;
    //fUsedNodes[aIdx].Point := TKMPOINT_ZERO;
  end;
  Result := fUsedNodes[aIdx];
end;


function TNavMeshPathFinding.MovementCost(aFrom, aTo: Word; var aSPoint, aEPoint: TKMPoint): Cardinal;

  function AvoidTraffic(): Cardinal;
  begin
    Result := Round(gAIFields.Influences.ArmyTraffic[fOwner, aTo] * GA_PATHFINDING_AvoidTraffic);
  end;

  function AvoidSpecEnemy(): Word;
  const
    CHANCES: array[TKMGroupType] of array[TKMGroupType] of Single = (
    // gtMelee gtAntiHorse gtRanged gtMounted
      (   5,          1,          1,        10   ), // gtMelee
      (  10,          5,          1,         1   ), // gtAntiHorse
      (  10,          5,          1,        20   ), // gtRanged
      (   5,         15,          1,         5   )  // gtMounted
    );
  var
    GT: TKMGroupType;
    Weight: Single;
  begin
    Weight := 0;
    for GT := Low(TKMGroupType) to High(TKMGroupType) do
      Weight := Weight + CHANCES[fGroupType,GT] * gAIFields.Influences.EnemyGroupPresence[fOwner, aTo, GT] * GA_PATHFINDING_AvoidSpecEnemy;
    Result := Round(Weight);
  end;

var
  DX,DY: Word;
  Output: Cardinal;
begin
  Output := 0;
  //Do not add extra cost if the tile is the target, as it can cause a longer route to be chosen
  if (aTo <> fEnd) then
  begin
    DX := Abs(aSPoint.X - aEPoint.X);
    DY := Abs(aSPoint.Y - aEPoint.Y);
    if (DX > DY) then
      Output := (DX * 10) + (DY * 4)
    else
      Output := (DY * 10) + (DX * 4);
    end;
  case fMode of
    pmShortestWay: begin end;
    pmAvoidTraffic: Output := Output + AvoidTraffic();
    pmAvoidSpecEnemy: Output := Output + AvoidSpecEnemy();
  end;
  Result := Output;
end;


function TNavMeshPathFinding.EstimateToFinish(aIdx: Word): Word;
var
  DX, DY, Output: Word;
  SPoint, EPoint: TKMPoint;
begin
  SPoint := gAIFields.NavMesh.Polygons[aIdx].CenterPoint;
  EPoint := gAIFields.NavMesh.Polygons[fEnd].CenterPoint;
  // Output := KMDistanceAbs(SPoint, EPoint); // in test map it throws +1 cycle (109 vs 110 interactions)
  DX := Abs(SPoint.X - EPoint.X);
  DY := Abs(SPoint.Y - EPoint.Y);
  if (DX > DY) then
    Output := (DX * 10) + (DY * 4)
  else
    Output := (DY * 10) + (DX * 4);
  Result := Output;
end;


function TNavMeshPathFinding.MakeRoute(): Boolean;
const
  c_closed = 65535; // High(Word)
var
  N: TNavMeshNode;
  I: Integer;
  Idx: Word;
  NewCost: Cardinal;
  POMPoint: TKMPoint;
  PolyArr: TPolygonArray;
begin
  Flush();
  PolyArr := gAIFields.NavMesh.Polygons;

  //Initialize first element
  N := GetNodeAt(fStart);
  N.Parent := nil;

  //Seed
  fMinN := N;
  while (fMinN <> nil) and (fMinN.Idx <> fEnd) do
  begin
    fMinN.Estim := c_closed;
    //Check all surrounding polygons and issue costs to them
    for I := 0 to PolyArr[fMinN.Idx].NearbyCount-1 do
    begin
      Idx := PolyArr[ fMinN.Idx ].Nearby[I];
      // New polygon
      if (fUsedNodes[Idx] = nil) then
      begin
        N := GetNodeAt(Idx);
        N.Parent := fMinN;
        N.Point := PolyArr[ fMinN.Idx ].NearbyPoints[I];
        N.CostTo := fMinN.CostTo + MovementCost(fMinN.Idx, Idx, fMinN.Point, N.Point);
        fHeap.Push(N);
      end
      // Visited polygon (recalculate estimation and actualize better result)
      else if (fUsedNodes[Idx].Estim <> c_closed) then
      begin
        POMPoint := PolyArr[ fMinN.Idx ].NearbyPoints[I];
        NewCost := fMinN.CostTo + MovementCost(fMinN.Idx, Idx, fMinN.Point, POMPoint);
        if (NewCost < fUsedNodes[Idx].CostTo) then
        begin
          fUsedNodes[Idx].Parent := fMinN;
          fUsedNodes[Idx].CostTo := NewCost;
          fUsedNodes[Idx].Point := POMPoint;
        end;
      end;
    end;
    //Find next cell with least (Estim+CostTo)
    if fHeap.IsEmpty then
      Break;
    fMinN := fHeap.Pop;
  end;
  //Route found, no longer need the lookups
  fHeap.Clear;
  Result := (fMinN.Idx = fEnd);
end;


procedure TNavMeshPathFinding.ReturnPolygonRoute(out aDistance: Word; out aRoutePolygonArray: TKMWordArray);
var
  Count: Word;
  N, FinalN: TNavMeshNode;
begin
  aDistance := 0;
  if (fMinN = nil) then
    Exit;
  FinalN := fMinN;
  N := fMinN.Parent;
  Count := 1;
  while (N <> nil) do
  begin
    aDistance := aDistance + KMDistanceAbs(N.Point, FinalN.Point); // DistanceAbs is very rough but when is result different from actual distance there are probably obstacles in path and it is better to count with higher distance
    FinalN := N;
    N := N.Parent;
    Inc(Count,1);
  end;

  SetLength(aRoutePolygonArray, Count+1);
  N := fMinN;
  Count := 0;
  while (N <> nil) do
  begin
    aRoutePolygonArray[Count+1] := N.Idx;
    N := N.Parent;
    Inc(Count,1);
  end;
  aRoutePolygonArray[Count] := FinalN.Idx;
  aRoutePolygonArray[0] := fMinN.Idx;
end;


procedure TNavMeshPathFinding.ReturnRoute(out aDistance: Word; out aRoutePointArray: TKMPointArray);
var
  Count: Word;
  N, FinalN: TNavMeshNode;
begin
  aDistance := 0;
  if (fMinN = nil) then
    Exit;
  FinalN := fMinN;
  N := fMinN.Parent;
  Count := 1;
  while (N <> nil) do
  begin
    aDistance := aDistance + KMDistanceAbs(N.Point, FinalN.Point); // DistanceAbs is very rough but when is result different from actual distance there are probably obstacles in path and it is better to count with higher distance
    FinalN := N;
    N := N.Parent;
    Inc(Count,1);
  end;

  SetLength(aRoutePointArray, Count+1);
  N := fMinN;
  Count := 0;
  while (N <> nil) do
  begin
    aRoutePointArray[Count+1] := N.Point;
    N := N.Parent;
    Inc(Count,1);
  end;
  aRoutePointArray[Count] := gAIFields.NavMesh.Polygons[ FinalN.Idx ].CenterPoint;
  aRoutePointArray[0] := gAIFields.NavMesh.Polygons[fMinN.Idx].CenterPoint;
end;


function TNavMeshPathFinding.InitPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
var
  Output: Boolean;
begin
  Result := False;
  fStart := aStart;
  fEnd := aEnd;
  if (fStart = High(Word)) OR (fEnd = High(Word))
    OR (fStart >= Length(gAIFields.NavMesh.Polygons))
    OR (fEnd >= Length(gAIFields.NavMesh.Polygons)) then  // Non-Existing polygon
    Exit;
  Output := MakeRoute();
  if Output then
  begin
    ReturnPolygonRoute(aDistance, aRoutePolygonArray);
    aRoutePolygonArray[0] := aEnd;
  end;
  Result := Output;
end;


function TNavMeshPathFinding.InitRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
var
  Output: Boolean;
begin
  Result := False;
  fStart := gAIFields.NavMesh.KMPoint2Polygon[ aStart ];
  fEnd := gAIFields.NavMesh.KMPoint2Polygon[ aEnd ];
  if (fStart = High(Word)) OR (fEnd = High(Word)) then  // Non-Existing polygon
    Exit;
  Output := MakeRoute();
  if Output then
  begin
    ReturnRoute(aDistance, aRoutePointArray);
    aRoutePointArray[0] := aEnd;
  end;
  Result := Output;
end;


function TNavMeshPathFinding.ShortestPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
begin
  fMode := pmShortestWay;
  Result := InitPolygonRoute(aStart, aEnd, aDistance, aRoutePolygonArray);
end;


function TNavMeshPathFinding.ShortestRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
begin
  fMode := pmShortestWay;
  Result := InitRoute(aStart, aEnd, aDistance, aRoutePointArray);
end;


function TNavMeshPathFinding.AvoidTrafficRoute(aOwner: TKMHandID; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
begin
  fOwner := aOwner;
  fMode := pmAvoidTraffic;
  Result := InitRoute(aStart, aEnd, aDistance, aRoutePointArray);
end;


function TNavMeshPathFinding.AvoidEnemyRoute(aOwner: TKMHandID; aGroup: TKMGroupType; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
begin
  fOwner := aOwner;
  fMode := pmAvoidSpecEnemy;
  fGroupType := aGroup;
  Result := InitRoute(aStart, aEnd, aDistance, aRoutePointArray);
end;

end.

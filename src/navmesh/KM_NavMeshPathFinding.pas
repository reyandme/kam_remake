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
  TPathfindingMode = (
    pmShortestWay,   // Find shortest way in NavMesh
    pmAvoidTraffic,  // Try avoid traffic
    pmAvoidSpecEnemy // Try avoid anti type units (cav will keep distance form spears etc)
  );

  TNavMeshNode = record
    Idx: Word; // Index of NavMeshNode in NavMesh
    Estim: Word; // Estimated cost from NavMeshNode to fEnd
    CostTo: Cardinal; // Cost from fStart to Idx NavMeshNode
    RouteID: Cardinal; // ID of the route
    Point: TKMPoint; // Point in NavMeshNode of NavMesh (each triangle [created by points in NavMeshNode] have its point -> multiple poits will create path)
    Parent: Pointer; // Parent NavMeshNode
  end;
  PNavMeshNode = ^TNavMeshNode;

  TNavMeshPathFinding = class
  private
    fStart, fEnd: Word;
    fHeap: TBinaryHeap;
    fMinN: PNavMeshNode;
    fUsedNodes: array of TNavMeshNode;
    fRouteID: Cardinal;

    fAllianceIdx: Integer;
    //fOwner: TKMHandID;
    fGroupType: TKMGroupType;
    fMode: TPathfindingMode;

    {$IFDEF DEBUG_NavMeshPathFinding}
    fTimeSumShortest, fTimeSumShortestPoly, fTimeSumTraffic, fTimeSumEnemy: Int64;
    fTimePeakShortest, fTimePeakShortestPoly, fTimePeakTraffic, fTimePeakEnemy: Int64;
    {$ENDIF}

    function HeapCmp(A,B: Pointer): Boolean;
  protected
    function MovementCost(aIdx, aFrom, aTo: Word; var aSPoint, aEPoint: TKMPoint): Cardinal;

    function InitPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
    function InitRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
    function MakeRoute(): Boolean;
    procedure GetRouteInfo(out aDistance, aCount: Word; out aLastN: PNavMeshNode);
    procedure ReturnPolygonRoute(out aDistance: Word; out aRoutePolygonArray: TKMWordArray);
    procedure ReturnRoute(out aDistance: Word; out aRoutePointArray: TKMPointArray);
  public
    constructor Create();
    destructor Destroy; override;

    //function WalkableDistance(aStart, aEnd: TKMPoint; out aDistance: Word): Boolean;
    function ShortestPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
    function ShortestRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
    function AvoidTrafficRoute(aOwner: TKMHandID; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
    function AvoidEnemyRoute(aOwner: TKMHandID; aGroup: TKMGroupType; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;

    {$IFDEF DEBUG_NavMeshPathFinding}
    procedure Paint();
    {$ENDIF}
  end;


implementation
uses
   KM_AIFields, KM_NavMesh, KM_NavMeshGenerator
   {$IFDEF DEBUG_NavMeshPathFinding}
   ,KM_RenderAux, KM_CommonUtils
   {$ENDIF}
   ;

{ TNavMeshPathFinding }
constructor TNavMeshPathFinding.Create;
begin
  inherited;
  fHeap := TBinaryHeap.Create(MAX_POLYGONS);
  fHeap.Cmp := HeapCmp;
  {$IFDEF DEBUG_NavMeshPathFinding}
  fTimeSumShortest := 0;
  fTimeSumShortestPoly := 0;
  fTimeSumTraffic := 0;
  fTimeSumEnemy := 0;
  fTimePeakShortest := 0;
  fTimePeakShortestPoly := 0;
  fTimePeakTraffic := 0;
  fTimePeakEnemy := 0;
  {$ENDIF}
end;


destructor TNavMeshPathFinding.Destroy;
begin
  fHeap.Free;
  inherited;
end;


function TNavMeshPathFinding.HeapCmp(A,B: Pointer): Boolean;
begin
  Result := (A = nil) OR (B = nil) OR (PNavMeshNode(A).Estim + PNavMeshNode(A).CostTo < PNavMeshNode(B).Estim + PNavMeshNode(B).CostTo);
end;


function TNavMeshPathFinding.MovementCost(aIdx, aFrom, aTo: Word; var aSPoint, aEPoint: TKMPoint): Cardinal;

  function AvoidTraffic(): Cardinal;
  begin
    Result := + gAIFields.Influences.GetArmyTraffic(fAllianceIdx, aTo)
              + (MAX_LINE_LENGTH - gAIFields.NavMesh.Polygons[aFrom].NearbyLineLength[aIdx]) * 2;
  end;

  function AvoidSpecEnemy(): Cardinal;
  begin
    Result := AvoidTraffic() + gAIFields.Influences.Presence[fAllianceIdx, aTo, fGroupType];
  end;

begin
  //Do not add extra cost if the tile is the target, as it can cause a longer route to be chosen
  if (aTo = fEnd) then
    Exit(0);
  Result := KMDistanceWalk(aSPoint, aEPoint); // Combo KMDistanceWalk in MovementCost and KMDistanceAbs in Estimation is the fastest
  //Result := KMDistanceAbs(aSPoint, aEPoint);
  if      (fMode = pmAvoidTraffic  ) then Inc(Result, AvoidTraffic())
  else if (fMode = pmAvoidSpecEnemy) then Inc(Result, AvoidSpecEnemy());
  //else if (fMode = pmShortestWay   ) then begin end;
end;


function TNavMeshPathFinding.MakeRoute(): Boolean;

  //{
	function EstimateToFinish(aIdx: Word): Word;
	begin
    with gAIFields.NavMesh do
	    Result := KMDistanceAbs(Polygons[aIdx].CenterPoint, Polygons[fEnd].CenterPoint); // ~ 135
	    //Result := KMDistanceWalk(Polygons[aIdx].CenterPoint, Polygons[fEnd].CenterPoint); // ~ 200
      //Result := Round(Sqrt(KMDistanceSqr(Polygons[aIdx].CenterPoint, Polygons[fEnd].CenterPoint))); // ~ 165
	end;
  //}
  { ~ 180
	function EstimateToFinish(aIdx: Word): Word;
  var
    DX, DY: Word;
	begin
    with gAIFields.NavMesh do
    begin
      DX := Abs(Polygons[aIdx].CenterPoint.X - Polygons[fEnd].CenterPoint.X);
      DY := Abs(Polygons[aIdx].CenterPoint.Y - Polygons[fEnd].CenterPoint.Y);
      Result := Byte(DX > DY) * (DX * 10 + DY * 4) + Byte(DX <= DY) * (DY * 10 + DX * 4);
    end;
  end;
  //}

const
  C_CLOSED = 65535; // High(Word)
var
  N: PNavMeshNode;
  K: Integer;
  Idx: Word;
  NewCost: Cardinal;
begin
  // Check length
  if (Length(fUsedNodes) <> gAIFields.NavMesh.PolygonsCnt) then
  begin
    fRouteID := High(fRouteID);
    SetLength(fUsedNodes, gAIFields.NavMesh.PolygonsCnt);
    for K := Low(fUsedNodes) to High(fUsedNodes) do
      fUsedNodes[K].Idx := K;
  end;
  // Update current route ID
  if (fRouteID = High(fRouteID)) then
  begin
    fRouteID := 0;
    for K := Low(fUsedNodes) to High(fUsedNodes) do
      fUsedNodes[K].RouteID := 0;
  end;
  Inc(fRouteID);

  //Initialize first element
  N := @fUsedNodes[fStart];
  N.RouteID := fRouteID;
  N.Parent := nil;
  N.Point := gAIFields.NavMesh.Polygons[fStart].CenterPoint;
  N.CostTo := 0;
  N.Estim := EstimateToFinish(N.Idx);

  //Seed
  fMinN := N;
  while (fMinN <> nil) AND (fMinN.Idx <> fEnd) do
  begin
    fMinN.Estim := C_CLOSED;
    //Check all surrounding polygons and issue costs to them
    with gAIFields.NavMesh.Polygons[fMinN.Idx] do
      for K := 0 to NearbyCount - 1 do
      begin
        Idx := Nearby[K];
        // New polygon
        if (fUsedNodes[Idx].RouteID <> fRouteID) then
        begin
          N := @fUsedNodes[Idx];
          N.RouteID := fRouteID;
          N.Parent := fMinN;
          N.Point := NearbyPoints[K];
          N.CostTo := fMinN.CostTo + MovementCost(K, fMinN.Idx, Idx, fMinN.Point, N.Point);
          N.Estim := EstimateToFinish(Idx);
          fHeap.Push(N);
        end
        // Visited polygon (recalculate estimation and update result if it is better)
        else if (fUsedNodes[Idx].Estim <> C_CLOSED) then
        begin
          NewCost := fMinN.CostTo + MovementCost(K, fMinN.Idx, Idx, fMinN.Point, NearbyPoints[K]);
          if (NewCost < fUsedNodes[Idx].CostTo) then
          begin
            fUsedNodes[Idx].Parent := fMinN;
            fUsedNodes[Idx].Point := NearbyPoints[K];
            fUsedNodes[Idx].CostTo := NewCost;
          end;
        end;
      end;
    // Find next record with best cost (Estim + CostTo)
    if fHeap.IsEmpty then
      Break;
    fMinN := fHeap.Pop;
  end;
  // Route found, no longer need the lookups
  fHeap.Clear;

  Result := (fMinN.Idx = fEnd);
end;


procedure TNavMeshPathFinding.GetRouteInfo(out aDistance, aCount: Word; out aLastN: PNavMeshNode);
var
  N: PNavMeshNode;
begin
  aDistance := 0;
  aCount := Byte(fMinN <> nil);
  aLastN := fMinN;
  if (aCount = 0) OR (fMinN.Parent = nil) then
    Exit;

  N := aLastN.Parent;
  while (N <> nil) do
  begin
    aDistance := aDistance + KMDistanceAbs(N.Point, aLastN.Point);
    aLastN := N;
    N := N.Parent;
    Inc(aCount);
  end;
end;


procedure TNavMeshPathFinding.ReturnPolygonRoute(out aDistance: Word; out aRoutePolygonArray: TKMWordArray);
var
  Count: Word;
  K: Integer;
  N: PNavMeshNode;
begin
  GetRouteInfo(aDistance, Count, N);
  SetLength(aRoutePolygonArray, Count+1);
  aRoutePolygonArray[Count] := N.Idx;
  N := fMinN;
  for K := 0 to Count - 1 do
  begin
    aRoutePolygonArray[K] := N.Idx;
    N := N.Parent;
  end;
  aRoutePolygonArray[0] := fMinN.Idx;
end;


procedure TNavMeshPathFinding.ReturnRoute(out aDistance: Word; out aRoutePointArray: TKMPointArray);
var
  Count: Word;
  K: Integer;
  N: PNavMeshNode;
begin
  GetRouteInfo(aDistance, Count, N);
  SetLength(aRoutePointArray, Count+1);
  aRoutePointArray[Count] := gAIFields.NavMesh.Polygons[ N.Idx ].CenterPoint;
  N := fMinN;
  for K := 0 to Count - 1 do
  begin
    aRoutePointArray[K] := N.Point;
    N := N.Parent;
  end;
  aRoutePointArray[0] := gAIFields.NavMesh.Polygons[ fMinN.Idx ].CenterPoint;
end;


function TNavMeshPathFinding.InitPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
begin
  Result := False;
  fStart := aStart;
  fEnd := aEnd;
  if (fStart = 0) OR (fEnd = 0)
    OR (fStart >= gAIFields.NavMesh.PolygonsCnt)
    OR (fEnd >= gAIFields.NavMesh.PolygonsCnt) then  // Non-Existing polygon
    Exit;
  Result := MakeRoute();
  if Result then
  begin
    ReturnPolygonRoute(aDistance, aRoutePolygonArray);
    aRoutePolygonArray[0] := aEnd;
  end;
end;


function TNavMeshPathFinding.InitRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
begin
  Result := False;
  fStart := gAIFields.NavMesh.KMPoint2Polygon[ aStart ];
  fEnd := gAIFields.NavMesh.KMPoint2Polygon[ aEnd ];
  if (fStart = 0) OR (fEnd = 0)
    OR (fStart >= gAIFields.NavMesh.PolygonsCnt)
    OR (fEnd >= gAIFields.NavMesh.PolygonsCnt) then  // Non-Existing polygon
    Exit;
  Result := MakeRoute();
  if Result then
  begin
    ReturnRoute(aDistance, aRoutePointArray);
    aRoutePointArray[0] := aEnd;
  end;
end;


function TNavMeshPathFinding.ShortestPolygonRoute(aStart, aEnd: Word; out aDistance: Word; out aRoutePolygonArray: TKMWordArray): Boolean;
{$IFDEF DEBUG_NavMeshPathFinding}
var Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec();
  {$ENDIF}
  fMode := pmShortestWay;
  Result := InitPolygonRoute(aStart, aEnd, aDistance, aRoutePolygonArray);
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec() - Time;
  fTimeSumShortestPoly := fTimeSumShortestPoly + Time;
  fTimePeakShortestPoly := Max(fTimePeakShortestPoly,Time);
  {$ENDIF}
end;


function TNavMeshPathFinding.ShortestRoute(aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
{$IFDEF DEBUG_NavMeshPathFinding}
var Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec();
  {$ENDIF}
  fMode := pmShortestWay;
  Result := InitRoute(aStart, aEnd, aDistance, aRoutePointArray);
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec() - Time;
  fTimeSumShortest := fTimeSumShortest + Time;
  fTimePeakShortest := Max(fTimePeakShortest,Time);
  {$ENDIF}
end;


function TNavMeshPathFinding.AvoidTrafficRoute(aOwner: TKMHandID; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
{$IFDEF DEBUG_NavMeshPathFinding}
var Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec();
  {$ENDIF}
  //fOwner := aOwner;
  if not gAIFields.Influences.GetAllianceIdx(aOwner,fAllianceIdx) then
    Exit(False);
  fMode := pmAvoidTraffic;
  Result := InitRoute(aStart, aEnd, aDistance, aRoutePointArray);
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec() - Time;
  fTimeSumTraffic := fTimeSumTraffic + Time;
  fTimePeakTraffic := Max(fTimePeakTraffic,Time);
  {$ENDIF}
end;


function TNavMeshPathFinding.AvoidEnemyRoute(aOwner: TKMHandID; aGroup: TKMGroupType; aStart, aEnd: TKMPoint; out aDistance: Word; out aRoutePointArray: TKMPointArray): Boolean;
{$IFDEF DEBUG_NavMeshPathFinding}
var Time: Int64;
{$ENDIF}
begin
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec();
  {$ENDIF}
  //fOwner := aOwner;
  if not gAIFields.Influences.GetAllianceIdx(aOwner,fAllianceIdx) then
    Exit(False);
  fMode := pmAvoidSpecEnemy;
  fGroupType := aGroup;
  Result := InitRoute(aStart, aEnd, aDistance, aRoutePointArray);
  {$IFDEF DEBUG_NavMeshPathFinding}
  Time := TimeGetUsec() - Time;
  fTimeSumEnemy := fTimeSumEnemy + Time;
  fTimePeakEnemy := Max(fTimePeakEnemy,Time);
  {$ENDIF}
end;


{$IFDEF DEBUG_NavMeshPathFinding}
procedure TNavMeshPathFinding.Paint();
var
  K: Integer;
  P1,P2,P3: TKMPoint;
  NMNode: PNavMeshNode;
begin
  if (Length(fUsedNodes) < gAIFields.NavMesh.PolygonsCnt) OR not OVERLAY_AI_PATHFINDING then
    Exit;

  // Draw polygon
  for K := 0 to gAIFields.NavMesh.PolygonsCnt - 1 do
    if (fUsedNodes[K].RouteID = fRouteID) then
      with gAIFields.NavMesh do
        gRenderAux.TriangleOnTerrain(
          Nodes[ Polygons[K].Indices[0] ].X,
          Nodes[ Polygons[K].Indices[0] ].Y,
          Nodes[ Polygons[K].Indices[1] ].X,
          Nodes[ Polygons[K].Indices[1] ].Y,
          Nodes[ Polygons[K].Indices[2] ].X,
          Nodes[ Polygons[K].Indices[2] ].Y, $90000000 OR tcWhite);

  // Draw parent child relation
  for K := 0 to gAIFields.NavMesh.PolygonsCnt - 1 do
    if (fUsedNodes[K].RouteID = fRouteID) then
      with gAIFields.NavMesh do
      begin
        NMNode := fUsedNodes[K].Parent;
        if (NMNode = nil) then
          Continue;
        P1 := Polygons[K].CenterPoint;
        P2 := Polygons[ NMNode.Idx ].CenterPoint;
        P3 := KMPointAverage(P1,P2);
        gRenderAux.LineOnTerrain(P3, P2, $99000000 OR tcRed);
        gRenderAux.LineOnTerrain(P3, P1, $99000000 OR tcBlue);
      end;
end;
{$ENDIF}


end.

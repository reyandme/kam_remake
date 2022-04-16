unit KM_PathFindingAStarNew;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, Math, KM_PathFinding,
  KM_CommonClasses, KM_Defaults, KM_Terrain, KM_Points, BinaryHeap;


type
  PANodeRec = ^TANodeRec; // Delphi allows forward declaration for record pointers
  TANodeRec = record
    RouteID: Cardinal;
    X,Y: SmallInt;
    CostTo: Cardinal;
    Estim: Cardinal;
    Parent: PANodeRec;
  end;

  // This is a helper class for TKMTerrain
  // Here should be pathfinding and all associated stuff
  // I think we should refactor this unit and move some TKMTerrain methods here
  TKMPathFindingAStarNew = class(TKMPathFinding)
  private
    fHeap: TBinaryHeap;
    fMinN: PANodeRec;
    fOpenRef: array [0..MAX_MAP_SIZE, 0..MAX_MAP_SIZE] of TANodeRec; //References to OpenList, Sized as map
    fRouteID: Cardinal;
    function HeapCmp(A,B: Pointer): Boolean;
  protected
    function GetNodeAt(X,Y: SmallInt): PANodeRec;
    function MakeRoute: Boolean; override;
    procedure ReturnRoute(NodeList: TKMPointList); override;
  public
    constructor Create;
    destructor Destroy; override;
  end;


implementation


{ TKMPathFindingAStarNew }
constructor TKMPathFindingAStarNew.Create;
var
  X, Y: Integer;
begin
  inherited;

  fHeap := TBinaryHeap.Create(High(Word));
  fHeap.Cmp := HeapCmp;

  for Y := 0 to MAX_MAP_SIZE do
    for X := 0 to MAX_MAP_SIZE do
    begin
      fOpenRef[Y, X].X := X;
      fOpenRef[Y, X].Y := Y;
    end;
end;


destructor TKMPathFindingAStarNew.Destroy;
begin
  fHeap.Free;

  inherited;
end;


function TKMPathFindingAStarNew.GetNodeAt(X, Y: SmallInt): PANodeRec;
begin
  Result := @fOpenRef[Y, X];
  if Result.RouteID <> fRouteID then
    Result := nil;
end;


function TKMPathFindingAStarNew.HeapCmp(A, B: Pointer): Boolean;
begin
  Result := (A = nil) or (B = nil) or (PANodeRec(A).Estim + PANodeRec(A).CostTo < PANodeRec(B).Estim + PANodeRec(B).CostTo);
end;


function TKMPathFindingAStarNew.MakeRoute: Boolean;
const
  C_CLOSED = High(Cardinal);
var
  N: PANodeRec;
  X, Y: Word;
  newCost: Word;
begin
  // Do not build the route in case destination is not walkable
  if not IsWalkableTile(fLocA.X, fLocA.Y) then Exit(False);

  //Use a unique RouteID each run to track whether nodes are valid
  //Before it overflows we need to reset, which is still very fast (<1ms)
  //and only needs doing once every 4.2 billion paths
  if fRouteID = High(fRouteID) then
  begin
    fRouteID := 0;
    for Y := 0 to MAX_MAP_SIZE do
      for X := 0 to MAX_MAP_SIZE do
        fOpenRef[Y, X].RouteID := 0;
  end;
  Inc(fRouteID);

  //Initialize first element
  N := @fOpenRef[fLocA.Y, fLocA.X];
  N.RouteID := fRouteID;
  N.CostTo := 0;
  N.Estim := EstimateToFinish(fLocA.X, fLocA.Y);
  N.Parent := nil;

  //Seed
  fMinN := N;

  while (fMinN <> nil) and not DestinationReached(fMinN.X, fMinN.Y) do
  begin
    fMinN.Estim := C_CLOSED;

    //Check all surrounding cells and issue costs to them
    for Y := Max(fMinN.Y-1,1) to Min(fMinN.Y+1, gTerrain.MapY-1) do
    for X := Max(fMinN.X-1,1) to Min(fMinN.X+1, gTerrain.MapX-1) do
    begin
      N := @fOpenRef[Y,X];
      if N.RouteID <> fRouteID then //Cell is new
      begin
        if CanWalkTo(KMPoint(fMinN.X, fMinN.Y), X, Y) then
        begin
          N.RouteID := fRouteID;
          N.Parent := fMinN;

          if IsWalkableTile(X, Y) then
          begin
            N.CostTo := fMinN.CostTo + MovementCost(fMinN.X, fMinN.Y, X, Y);
            N.Estim := EstimateToFinish(X,Y);
            fHeap.Push(N);
          end
          else //If cell doesn't meets Passability then mark it as Closed
            N.Estim := C_CLOSED;
        end;
      end
      else //Else cell is old
      begin
        //Node N is valid. If route through new cell is shorter than previous
        if N.Estim <> C_CLOSED then
        if CanWalkTo(KMPoint(fMinN.X, fMinN.Y), X, Y) then
        begin
          newCost := MovementCost(fMinN.X, fMinN.Y, X, Y);
          if fMinN.CostTo + newCost < N.CostTo then
          begin
            N.Parent := fMinN;
            N.CostTo := fMinN.CostTo + newCost;
            //todo: Cost has changed and the location in the queue needs to change too
            //fHeap.UpdateItem(N);
          end;
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

  Result := DestinationReached(fMinN.X, fMinN.Y);
end;


procedure TKMPathFindingAStarNew.ReturnRoute(NodeList: TKMPointList);
var
  N: PANodeRec;
begin
  NodeList.Clear;

  //Assemble the route
  N := fMinN;
  while N <> nil do
  begin
    NodeList.Add(KMPoint(N.X, N.Y));
    N := N.Parent;
  end;

  //Reverse the list, since path is assembled LocB > LocA
  NodeList.Inverse;

  //Cache long paths
  if CACHE_PATHFINDING and (NodeList.Count > PATH_CACHE_NODES_MIN_CNT) then
    AddToCache(NodeList);
end;


end.

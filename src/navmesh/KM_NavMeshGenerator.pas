{
NavMesh generator
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_NavMeshGenerator;
{$I KaM_Remake.inc}
//{$DEFINE DEBUG_NavMesh}
interface
uses
  {$IFDEF MSWINDOWS AND DEBUG_NavMesh}
    Windows,
  {$ENDIF}
  // System.Diagnostics, System.TimeSpan,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KromUtils, KM_CommonUtils;

type

  TKMNavMeshByteArray = array[-1..257,-1..257] of Byte;

  // Borders
  TKMBord = record
    Node, Prev, Next, NextY: Word;
  end;
  TKMBordInfo = record
    Count: Word;
    Borders: array[0..10000] of TKMBord;
  end;
  {$IFDEF DEBUG_NavMesh}
  TDebugLines = record // Only for debug
    Count: Word;
    Lines: array[0..15000] of record
      P1,P2: TKMPoint;
      Color: Cardinal;
    end;
  end;
  {$ENDIF}

  TPolygon = record
      CenterPoint: TKMPoint;
      NearbyCount: Byte; //could be 0 .. 3
      Poly2PointStart, Poly2PointCnt: Word; // Indexes of fPolygon2PointArr (points which are part of this polygon)
      Indices: array [0..2] of Word; //Neighbour nodes
      Nearby: array [0..2] of Word; //Neighbour polygons
      NearbyPoints: array [0..2] of TKMPoint; // Center points
    end;
  TPolygonArray = array of TPolygon;

  // NavMeshGenerator create Navigation mesh
  TKMNavMeshGenerator = class
  private
    fMapX, fMapY: Word; // Limits of arrays
    //Keep a copy of these temp arrays for debug rendering
    fInnerPointStartIdx, fInnerPointEndIdx: Word;
    fBordByY, fIdxArr: array[0..256] of Word;
    fBord: TKMBordInfo;
    {$IFDEF DEBUG_NavMesh}
    fBorderNodeCount: Integer;
    fDL: TDebugLines;
    fBorderNodes: TKMPointArray;
    {$ENDIF}

    //Working data
    fNodeCount, fPolyCount: Integer;
    fNodes: TKMPointArray;            // Nodes
    fPolygons: TPolygonArray;         // Polygons

    //Building the navmesh from terrain
    function Intersect(aX1, aY1, aX2, aY2: Word): Boolean; overload;
    function Intersect(aX1, aY1, aX2, aY2: TKMPoint): Boolean; overload;
    function ExtractNodes(): TKMNavMeshByteArray;
    procedure AddInnerNodes(aW: TKMNavMeshByteArray);
    procedure PolygonTriangulation();
    procedure PrettyPoly();

    // Measure performance
    {$IFDEF DEBUG_NavMesh}
    function TimeGetUsec(): Int64;
    {$ENDIF}
  public
    // Use properties to access new NavMesh so the generation may be independent on the existing NavMesh
    property NodeCount: Integer read fNodeCount;
    property PolygonCount: Integer read fPolyCount;
    property Nodes: TKMPointArray read fNodes;
    property Polygons: TPolygonArray read fPolygons;

    constructor Create();
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure GenerateNewNavMesh();
    function Paint(const aRect: TKMRect): Boolean;
  end;


implementation
uses
  SysUtils, Math,
  KM_Terrain, KM_HandsCollection, KM_RenderAux,
  KM_NavMesh,
  Dialogs;


const
  MAX_NODES = 10000; // Max nodes in NavMesh array
  MAX_POLYGONS = 10000;
  UNVISITED_OBSTACLE = 255;
  VISITED_OBSTACLE = UNVISITED_OBSTACLE - 1;
  NODE_IN_WALKABLE_AREA = 1;
  NODE_IN_OBSTACLE = VISITED_OBSTACLE - 1;
  FILTER_EDGES_MAX_EDGE_DISTANCE = 5;
  FILTER_EDGES_MAX_TOLERANCE = 0.5;
  INNER_EDGE_BORDER_STEP = 3;
  INNER_EDGE_STEP = 4;
  SQR_MAX_RADIUS_TryConnect = 20*20;


{ TKMNavMeshGenerator }
constructor TKMNavMeshGenerator.Create();
begin
  inherited Create;
end;


destructor TKMNavMeshGenerator.Destroy();
begin
  inherited;
end;


procedure TKMNavMeshGenerator.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('KMNavMeshGenerator');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);
end;


procedure TKMNavMeshGenerator.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker('KMNavMeshGenerator');
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);
end;


procedure TKMNavMeshGenerator.GenerateNewNavMesh();
var
  W: TKMNavMeshByteArray;
{$IFDEF DEBUG_NavMesh}
  tStart,tExtrNodes,tAddInNodes,tPolyTrian,tPrettyPoly, tSum: UInt64;
{$ENDIF}
begin
    {$IFDEF DEBUG_NavMesh}
    tStart := TimeGetUsec();
    {$ENDIF}

  W := ExtractNodes();
    {$IFDEF DEBUG_NavMesh}
    tExtrNodes := TimeGetUsec() - tStart;
    {$ENDIF}
  AddInnerNodes(W);
    {$IFDEF DEBUG_NavMesh}
    tAddInNodes := TimeGetUsec() - tStart - tExtrNodes;
    {$ENDIF}
  PolygonTriangulation();
    {$IFDEF DEBUG_NavMesh}
    tPolyTrian := TimeGetUsec() - tStart - tAddInNodes;
    {$ENDIF}
  PrettyPoly();
    {$IFDEF DEBUG_NavMesh}
    tPrettyPoly := TimeGetUsec() - tStart - tPolyTrian;
    {$ENDIF}

    {$IFDEF DEBUG_NavMesh}
    tSum := tExtrNodes + tAddInNodes + tPolyTrian + tPrettyPoly;
    if (tSum > 0) then tSum := tSum * 1; // Make sure that compiler does not f--ck up the variable TimeDiff
    {$ENDIF}
end;



{$IFDEF DEBUG_NavMesh}
function TKMNavMeshGenerator.TimeGetUsec(): Int64;
var
  freq: Int64;
  newTime: Int64;
  factor: Double;
begin
  QueryPerformanceFrequency(freq);
  QueryPerformanceCounter(newTime);
  factor := 1000000 / freq; // Separate calculation to avoid "big Int64 * 1 000 000" overflow
  Result := Round(newTime * factor);
end;
{$ENDIF}


function TKMNavMeshGenerator.Intersect(aX1, aY1, aX2, aY2: Word): Boolean;
begin
  Result := Intersect(fNodes[aX1], fNodes[aY1], fNodes[aX2], fNodes[aY2]);
end;

function TKMNavMeshGenerator.Intersect(aX1, aY1, aX2, aY2: TKMPoint): Boolean;
  // Check if points are on segment
  function OnSegment(aP1,aP2,aP3: TKMPoint): Boolean;
  begin
    Result := (aP2.x <= max(aP1.x, aP3.x)) AND
              (aP2.x >= min(aP1.x, aP3.x)) AND
              (aP2.y <= max(aP1.y, aP3.y)) AND
              (aP2.y >= min(aP1.y, aP3.y));
  end;
  // Check orientation of the points
  function Orientation(aP1,aP2,aP3: TKMPoint): Integer;
  begin
    Result := (aP2.y - aP1.y) * (aP3.x - aP2.x) - (aP2.x - aP1.x) * (aP3.y - aP2.y);
    if (Result > 0) then
      Result := 1 // Clockwise
    else if (Result < 0) then
      Result := 2; // Counterclockwise
  end;
var
  o1,o2,o3,o4: Integer;
begin
  // Find the four orientations needed for general and special cases
  o1 := Orientation(aX1, aY1, aX2);
  o2 := Orientation(aX1, aY1, aY2);
  o3 := Orientation(aX2, aY2, aX1);
  o4 := Orientation(aX2, aY2, aY1);
  // General case
  Result := (o1 <> o2) AND (o3 <> o4);
  // Special Cases
  if not Result then
  begin
    // P1, Q1 and P2 are colinear and P2 lies on segment p1q1
    if      (o1 = 0) AND OnSegment(aX1, aX2, aY1) then
      Result := True
    // P1, Q1 and Q2 are colinear and Q2 lies on segment p1q1
    else if (o2 = 0) AND OnSegment(aX1, aY2, aY1) then
      Result := True
    // P2, Q2 and P1 are colinear and P1 lies on segment p2q2
    else if (o3 = 0) AND OnSegment(aX2, aX1, aY2) then
      Result := True
    // P2, Q2 and Q1 are colinear and Q1 lies on segment p2q2
    else if (o4 = 0) AND OnSegment(aX2, aY1, aY2) then
      Result := True;
  end;
end;




function TKMNavMeshGenerator.ExtractNodes(): TKMNavMeshByteArray;
  type
    TStartEndIdxs = record
      SIdx: Word;
      EIdx: Word;
    end;
var
  ShapeCnt,BordNodeCnt: Integer;
  ShapeIdxArr: array[0..256*64] of TStartEndIdxs;
  NodeMap: array[0..256,0..256] of Word;
  W: TKMNavMeshByteArray;
  BordNodes: TKMPointArray;

  // Use relative coordinate system: visit surounding tiles and rotate coordinate system around walkable area
  procedure ScanObstacle(aStartPoint, aEndPoint, aInitDir: TKMPoint);
  const
    // Correct position of the point according to direction of move in the obstacle
    // It is necessary to have just 1 border point for 1 tile (example: we move on obstacle with width 1 tile)
    DirCorrArr:          array[-2..2] of TKMPoint = ( (X:-1;Y:0),  (X:0;Y:0),  (X:0;Y:0), (X:-1;Y:-1), (X:0;Y:-1) );
    DirCorrInnerTileArr: array[-2..2] of TKMPoint = ( (X:-1;Y:-1), (X:-1;Y:0), (X:0;Y:0), (X:0;Y:-1),  (X:0;Y:0) );
  var
    InnerTile, FinPointReached: Boolean;
    X,Y,{Dir,} Overflow: Integer;
    v, CorrP, FinPoint: TKMPoint;
  begin
    X := aStartPoint.X;
    Y := aStartPoint.Y;
    v := aInitDir; // Init vector
    // Specify final point (for special case when W[Y,X+2] is walkable tile we have to visit also W[Y+1,X])
    if (W[Y+1,X] = UNVISITED_OBSTACLE) then
      FinPoint := KMPoint(X,Y+1)
    else
      FinPoint := aStartPoint;
    FinPointReached := False;
    Overflow := 0;
    repeat
      Overflow := Overflow + 1;
      InnerTile := False;
      // Find next CanBeVisited tile and rotate vector
      if (W[ Y-v.X, X+v.Y ] > NODE_IN_WALKABLE_AREA) then // Left
      begin
        InnerTile := True; // This tiles have neighbor tiles unwalkable
        v := KMPoint(+v.Y,-v.X);
      end
      else if (W[ Y+v.Y, X+v.X ] > NODE_IN_WALKABLE_AREA) then // Forward
      begin
        //v := KMPoint(+v.X,+v.Y);
      end
      else if (W[ Y+v.X, X-v.Y ] > NODE_IN_WALKABLE_AREA) then // Right
      begin
        v := KMPoint(-v.Y,+v.X);
      end
      else if (W[ Y-v.Y, X-v.X ] > NODE_IN_WALKABLE_AREA) then // Backward
      begin
        v := KMPoint(-v.X,-v.Y);
      end
      else
        break;
      // Add corrected point (correction secure that point have unique coords)
      if InnerTile then
        CorrP := KMPointAdd( KMPoint(X,Y), DirCorrInnerTileArr[v.X+v.Y*2] )
      else
        CorrP := KMPointAdd( KMPoint(X,Y), DirCorrArr[v.X+v.Y*2] );
      if ((W[CorrP.Y,CorrP.X] <> NODE_IN_WALKABLE_AREA) AND (W[CorrP.Y,CorrP.X] <> NODE_IN_OBSTACLE)) then
      begin
        if (W[CorrP.Y,CorrP.X] = 0) then
          W[CorrP.Y,CorrP.X] := NODE_IN_WALKABLE_AREA
        else
          W[CorrP.Y,CorrP.X] := NODE_IN_OBSTACLE;
        BordNodes[BordNodeCnt] := CorrP;
        NodeMap[CorrP.Y,CorrP.X] := BordNodeCnt;
        Inc(BordNodeCnt);
      end;
      // Mark visited obstacle and move into next point
      if (W[Y,X] = UNVISITED_OBSTACLE) then
        W[Y,X] := VISITED_OBSTACLE;
      X := X + v.X;
      Y := Y + v.Y;
      FinPointReached := FinPointReached OR KMSamePoint(KMPoint(X,Y),FinPoint);
    until (FinPointReached AND KMSamePoint(KMPoint(X,Y),aStartPoint)) OR (Overflow > 65536);
  end;

  procedure AddBorderPoint(aPoint: TKMPoint);
  var
    X,Y,K,PrevK: Integer;
  begin
    fNodes[fNodeCount] := aPoint;
    with fBord.Borders[fBord.Count] do
    begin
      Node := fNodeCount;
      Prev := fBord.Count - 1;
      Next := fBord.Count + 1;
      // Sort and store new border line into array
      Y := aPoint.Y;
      X := aPoint.X;
      PrevK := 0;
      K := fBordByY[Y];
      while (K > 0) AND (X > fNodes[ fBord.Borders[K].Node ].X) do
      begin // Insertion sort - in real 10-15 points; in borders max 50 => no need for quick sort
        PrevK := K;
        K := fBord.Borders[K].NextY;
      end;
      if (PrevK = 0) then
        fBordByY[Y] := fBord.Count
      else
        fBord.Borders[PrevK].NextY := fBord.Count;
      NextY := K;
    end;
    Inc(fBord.Count);
    Inc(fNodeCount);
  end;

  // Filter number of lines in all shapes
  procedure FilterEdges();
  var
    ShapeCheck: Boolean;
    K,L,M,X,Y, StartIdx, EndIdx, StartBorderIdx, Overflow1, Overflow2: Integer;
    InvDenominator, a,b,c: Single;
    StrP,EndP: TKMPoint;
  begin
    FillChar(fBordByY, SizeOf(fBordByY), #0);
    fNodeCount := 1;
    fBord.Count := 1;
    // For all shapes
    for K := 0 to ShapeCnt-1 do
    begin
      StartIdx := ShapeIdxArr[K].SIdx;
      StartBorderIdx := fBord.Count;
      AddBorderPoint( BordNodes[StartIdx] );
      // Check all nodes in every shape
      Overflow1 := 0;
      while (StartIdx < ShapeIdxArr[K].EIdx) AND (Overflow1 < 65536) do
      begin
        Overflow1 := Overflow1 + 1;
        Overflow2:= 0;
        EndIdx := Min(StartIdx + FILTER_EDGES_MAX_EDGE_DISTANCE, ShapeIdxArr[K].EIdx);
        repeat
          Overflow2 := Overflow2 + 1;
          ShapeCheck := True;
          // Check if removed points are not too far from the new line
          a := - BordNodes[StartIdx].Y     + BordNodes[EndIdx-1].Y;
          b := + BordNodes[StartIdx].X     - BordNodes[EndIdx-1].X;
          c := - BordNodes[StartIdx].X * a - BordNodes[StartIdx].Y * b;
          InvDenominator := 1 / (a*a + b*b);
          for L := EndIdx-1 downto StartIdx+1 do
            if (  ( sqr(a*BordNodes[L].X + b*BordNodes[L].Y + c) * InvDenominator ) > FILTER_EDGES_MAX_TOLERANCE  ) then
            begin
              ShapeCheck := False;
              Dec(EndIdx);
              break;
            end;
          // Check if new line does not intersect with existing line
          if ShapeCheck then
          begin
            StrP := BordNodes[StartIdx];
            EndP := BordNodes[EndIdx];
            for X := Min(StrP.X,EndP.X) to Max(StrP.X,EndP.X) do
            begin
              for Y := Min(StrP.Y,EndP.Y) to Max(StrP.Y,EndP.Y) do
                if (NodeMap[Y,X] > 0) AND ((NodeMap[Y,X] < StartIdx - 1) OR (NodeMap[Y,X] > EndIdx + 1)) then
                //if (NodeMap[Y,X] > 0) then
                begin
                  // Make sure that the selection does not colide with starting point
                  if   (not KMSamePoint(BordNodes[ NodeMap[Y,X]+1 ], StrP) AND Intersect(StrP, EndP, KMPoint(X,Y), BordNodes[ NodeMap[Y,X]+1 ]))
                    OR (not KMSamePoint(BordNodes[ NodeMap[Y,X]-1 ], EndP) AND Intersect(StrP, EndP, KMPoint(X,Y), BordNodes[ NodeMap[Y,X]-1 ])) then
                  begin
                    ShapeCheck := False;
                    Dec(EndIdx);
                    break;
                  end;
                end;
              if not ShapeCheck then
                break;
            end;
          end;
        until ShapeCheck OR (Overflow2 > 65536);

        // Emergency function (prevents crashes in case of bugs)
        if (StartIdx = EndIdx) then
        begin
          Inc(EndIdx);
        end;

        // Create clean borders
        AddBorderPoint( BordNodes[EndIdx] );
        StartIdx := EndIdx;
      end;
      // Mark end of shape
      //if (fBord.Count - StartBorderIdx - 1 < 3) then
      //  fBord.Count := StartBorderIdx
      //else
      begin
        fBord.Borders[StartBorderIdx].Prev := fBord.Count - 1;
        fBord.Borders[fBord.Count - 1].Next := StartBorderIdx;
      end;
    end;
  end;


  // Mark all edges
  procedure MarkEdges();
  const
    MIN_BORDERS_IN_NEW_OBSTACLE = 3;
  var
    Walkable: Boolean;
    X,Y,Cnt: Integer;
  begin
    // Mark edges in the map
    FillChar(ShapeIdxArr, SizeOf(ShapeIdxArr), #0);
    FillChar(NodeMap, SizeOf(NodeMap), #0);
    BordNodeCnt := 2; // Start at index 2 -> 0. is reserved and 1. will be the end point so circle is complete
    ShapeCnt := 0;
    Walkable := False;
    for Y := 1 to fMapY - 1 do
    for X := 1 to fMapX do // -1 cannot be here
    begin
      if Walkable AND (W[Y,X] = UNVISITED_OBSTACLE) then
      begin
        Cnt := BordNodeCnt;
        ScanObstacle(KMPoint(X,Y), KMPoint(X,Y), KMPoint(0,-1));
        // Check the number of borders in the new obstacle
        if (BordNodeCnt - Cnt < MIN_BORDERS_IN_NEW_OBSTACLE) then
          BordNodeCnt := Cnt // Remove borders / ignore them
        else
        begin
          // Mark start and end index of new obstacle
          ShapeIdxArr[ShapeCnt].SIdx := Cnt;
          ShapeIdxArr[ShapeCnt].EIdx := BordNodeCnt-1;
          Inc(ShapeCnt);
          // Add end point before the start point and vice versa so points in ShapeIdxArr are interconnected by indexes
          BordNodes[Cnt-1] := BordNodes[BordNodeCnt-1];
          BordNodes[BordNodeCnt] := BordNodes[Cnt];
          Inc(BordNodeCnt);
          Inc(BordNodeCnt); // Reserve first index of next node for end point of the node
        end;
      end;
      Walkable := (W[Y,X] = 0);
    end;
    // Filter edges
    FilterEdges();
  end;

var
  X,Y: Integer;
begin
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
  // Init node array
  fNodeCount := 1; // First index is reserved
  SetLength(fNodes, MAX_NODES);
  FillChar(fNodes[0], SizeOf(fNodes[0]) * Length(fNodes), #0);
  // Init array of borders
  BordNodeCnt := 1;
  SetLength(BordNodes, 255*255);
  FillChar(BordNodes[0], SizeOf(BordNodes[0]) * Length(BordNodes), #0);
  // Get obstacles in the map
  FillChar(W, SizeOf(W), #0);
  for Y := 1 to fMapY - 1 do
  for X := 1 to fMapX - 1 do
    if not (tpOwn in gTerrain.Land[Y,X].Passability) then
      W[Y,X] := UNVISITED_OBSTACLE;
  // Fill borders
  for Y := 0 to fMapY do
  begin
    W[Y,0] := UNVISITED_OBSTACLE;
    W[Y,fMapX] := UNVISITED_OBSTACLE;
  end;
  for X := 0 to fMapX do
  begin
    W[0,X] := UNVISITED_OBSTACLE;
    W[fMapY,X] := UNVISITED_OBSTACLE;
  end;
  // Detect edges
  MarkEdges();
  // Return array of obstacles
  Result := W;
  {$IFDEF DEBUG_NavMesh}
  fBorderNodeCount := BordNodeCnt;
  fBorderNodes := BordNodes;
  {$ENDIF}
end;




procedure TKMNavMeshGenerator.AddInnerNodes(aW: TKMNavMeshByteArray);
var
  E: TKMNavMeshByteArray;
  procedure FillArea(aStep: Word; aInitPoint: TKMPoint);
  var
    X,Y: Integer;
  begin
    for Y := Max(1, aInitPoint.Y - aStep) to Min(fMapY - 1, aInitPoint.Y + aStep) do
    for X := Max(1, aInitPoint.X - aStep) to Min(fMapX - 1, aInitPoint.X + aStep) do
      E[Y,X] := 1;//Max(  E[Y,X], Min( abs(aInitPoint.Y - Y), abs(aInitPoint.X - X) )  );
  end;
var
  K,X,Y: Integer;
begin
  // Mark radius around border points
  FillChar(E, SizeOf(E), #0);
  fInnerPointStartIdx := fNodeCount;
  for K := 1 to fBord.Count - 1 do
    FillArea( INNER_EDGE_BORDER_STEP+1, fNodes[ fBord.Borders[K].Node ] );
  // Find untouched tiles and add inner points there
  for Y := 1 to fMapY - 1 do
  for X := 1 to fMapX - 1 do
    if (E[Y,X] = 0) AND (aW[Y,X] < VISITED_OBSTACLE) then
    begin
      fNodes[fNodeCount] := KMPoint(X,Y);
      Inc(fNodeCount);
      FillArea( INNER_EDGE_STEP+1, KMPoint(X,Y) );
    end;
  fInnerPointEndIdx := fNodeCount;
  // Sort inner points according to Y
  FillChar(fIdxArr, SizeOf(fIdxArr), #0);
  Y := 0;
  K := fInnerPointStartIdx;
  while (K < fInnerPointEndIdx) do
    if (fNodes[K].Y > Y) then
    begin
      fIdxArr[Y] := K;
      Y := Y + 1;
    end
    else
      K := K + 1;
  // Fill the end of array with maximum index
  for Y := Y to High(fIdxArr) do
    fIdxArr[Y] := fInnerPointEndIdx;
end;




procedure TKMNavMeshGenerator.PolygonTriangulation();
type
  // PolyLines
  PPolyLine = ^TKMPolyLine;
  TKMPolyLine = record
    Node,Polygon: Word;
    Next: PPolyLine;
  end;
  PPolyLines = ^TKMPolyLines;
  TKMPolyLines = record
  	LeftEdge, RightEdge, FutureLeftEdge, FutureRightEdge: Word;
    FirstLine, LastLine: PPolyLine;
  end;
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $7700FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
var
  LineArrayCnt: Word;
  LineArray: array of PPolyLines;

  {$IFDEF DEBUG_NavMesh}
  procedure AddLine(aP1,aP2: TKMPoint; aColor: Cardinal = COLOR_BLACK);
  begin
    with fDL.Lines[fDL.Count] do
    begin
      P1 := aP1;
      P2 := aP2;
      Color := aColor;
    end;
    Inc(fDL.Count);
  end;
  procedure ConfirmLine(aIdx1, aIdx2: Word; aColor: Cardinal = COLOR_BLACK);
  begin
    AddLine(fNodes[ fBord.Borders[aIdx1].Node ], fNodes[ fBord.Borders[aIdx2].Node ], aColor);
  end;
  {$ENDIF}
  // Mark connection between 2 polygons
  procedure ConnectPolygons(aNewPoly1, aPossiblePoly2: Word);
  begin
    if (aPossiblePoly2 = 0) then
      Exit;
    with fPolygons[aNewPoly1] do
      if (NearbyCount < 3) then
      begin
        Nearby[NearbyCount] := aPossiblePoly2;
        Inc(NearbyCount);
      end;
    with fPolygons[aPossiblePoly2] do
      if (NearbyCount < 3) then
      begin
        Nearby[NearbyCount] := aNewPoly1;
        Inc(NearbyCount);
      end;
  end;
  // Add new polygon from pointers to PolyLine
  procedure AddPolygon(var aPPL1, aPPL2: PPolyLine); overload;
  begin
    with fPolygons[fPolyCount] do
    begin
      Indices[0] := aPPL1^.Node;
      Indices[1] := aPPL2^.Node;
      Indices[2] := aPPL2^.Next^.Node;
      ConnectPolygons(fPolyCount, aPPL1^.Polygon);
      ConnectPolygons(fPolyCount, aPPL2^.Polygon);
    end;
    aPPL1^.Polygon := fPolyCount;
    aPPL2^.Polygon := fPolyCount; // Maybe unused (by: NewLine)
    Inc(fPolyCount);
  end;
  // Add new polygon from index of Node and pointer to PolyLine
  function AddPolygon(aIdx: Word; var aPPL: PPolyLine): Word; overload;
  begin
    with fPolygons[fPolyCount] do
    begin
      Indices[0] := aPPL^.Node;
      Indices[1] := aPPL^.Next^.Node;
      Indices[2] := aIdx;
      ConnectPolygons(fPolyCount, aPPL^.Polygon);
    end;
    aPPL^.Polygon := fPolyCount;
    Result := fPolyCount;
    Inc(fPolyCount);
  end;
  // Create new line which is related to one node and points to another line on right side
  function NewLine(aNode: Word; aNext: PPolyLine; aPolygon: Word = 0): PPolyLine;
  begin
    New(Result);
    Result^.Node := aNode;
    Result^.Polygon := aPolygon;
    Result^.Next := aNext;
  end;
  // Check Point is on the right side of line made by P1 and P2
  function IsRightSide(P1,P2,Point: TKMPoint): Boolean;
  begin
    Result := ((P2.X - P1.X) * (Point.Y - P1.Y) > (P2.Y - P1.Y) * (Point.X - P1.X));
  end;
  // Try to find triangles in existing area
  procedure TryConnect(aRemovedNode, aLineIdx: Word; aLeftDirection: Boolean; aBorderPoly: Boolean = False; aCloseArea: Boolean = False);
  var
    PPoly1, PPoly2, PPoly3: PPolyLine;
  begin
    with LineArray[aLineIdx]^ do
    begin
      if (FirstLine = LastLine) OR (FirstLine^.Next = LastLine) // Only 2 vertices
        OR (FirstLine^.Node = aRemovedNode) OR (LastLine^.Node = aRemovedNode) then // Border node connot be removed
        Exit;
      // Find all 3 vertices which will be used for triangulation
      PPoly3 := FirstLine;
      PPoly2 := PPoly3^.Next;
      PPoly1 := PPoly2^.Next;
      while (PPoly2.Node <> aRemovedNode) do
      begin
        PPoly3 := PPoly2;
        PPoly2 := PPoly1;
        PPoly1 := PPoly1^.Next;
      end;
      // Check max distance (it is possible to ignore this condition, but then PrettyPoly increase its computation time)
      if not aCloseArea AND (KMDistanceSqr(fNodes[ PPoly1^.Node ],fNodes[ PPoly3^.Node ]) > SQR_MAX_RADIUS_TryConnect) then
        Exit;
      // Check rules for creation of new polygon
      if (aBorderPoly AND ( // Force to create polygon in case that it is border point
           (aLeftDirection     AND (fNodes[ PPoly3^.Node ].X > fNodes[ PPoly1^.Node ].X)) OR
           (not aLeftDirection AND (fNodes[ PPoly1^.Node ].X < fNodes[ PPoly3^.Node ].X))
         )) OR IsRightSide(fNodes[ PPoly3^.Node ],fNodes[ PPoly2^.Node ],fNodes[ PPoly1^.Node ])
         OR aCloseArea then // Force to create polygon in case that area will be closed
      begin
        {$IFDEF DEBUG_NavMesh} AddLine(fNodes[ PPoly3^.Node ],fNodes[ PPoly1^.Node ],COLOR_GREEN); {$ENDIF}
        AddPolygon(PPoly3, PPoly2);
        PPoly3^.Next := PPoly1;
        Dispose(PPoly2); // Remove verticle from memory
        TryConnect( ifthen(aLeftDirection, PPoly1^.Node, PPoly3^.Node), aLineIdx, aLeftDirection, aBorderPoly, aCloseArea)
      end;
    end;
  end;
  // Add new border point
  procedure AddNewBorder(aIdx, aFutureIdx, aLineIdx: Word; aLeftDirection: Boolean; aTryConnect: Boolean = True; aCloseArea: Boolean = False);
  begin
    {$IFDEF DEBUG_NavMesh} ConfirmLine(aIdx, aFutureIdx,COLOR_BLACK); {$ENDIF}
    with LineArray[aLineIdx]^ do
    begin
      if aLeftDirection then
      begin
        FirstLine := NewLine( fBord.Borders[aIdx].Node, FirstLine );
        if aTryConnect then
          TryConnect(fBord.Borders[LeftEdge].Node, aLineIdx, aLeftDirection, True, aCloseArea);
        LeftEdge := aIdx;
        FutureLeftEdge := aFutureIdx;
      end
      else
      begin
        LastLine^.Next := NewLine( fBord.Borders[aIdx].Node, nil );
        LastLine := LastLine^.Next;
        if aTryConnect then
          TryConnect(fBord.Borders[RightEdge].Node, aLineIdx, aLeftDirection, True, aCloseArea);
        RightEdge := aIdx;
        FutureRightEdge := aFutureIdx;
      end;
    end;
  end;
  // Remove area from memory
  procedure DisposeArea(aIdx: Word; aSkipPolyLine: Boolean = False);
  var
    PolyLine, OldPL: PPolyLine;
  begin
    if not aSkipPolyLine then
    begin
      PolyLine := LineArray[aIdx]^.FirstLine;
      while (PolyLine <> LineArray[aIdx]^.LastLine) AND (PolyLine <> nil) do
      begin
        OldPL := PolyLine;
        PolyLine := PolyLine^.Next;
        Dispose(OldPL);
      end;
      Dispose(PolyLine);
    end;
    // Free memory of second line and update LineArray
    Dispose(LineArray[aIdx]);
    Dec(LineArrayCnt);
    LineArray[aIdx] := LineArray[LineArrayCnt];
  end;
  // Init new walkable area
  procedure AddNewWalkableArea(aIdx: Word);
  begin
    // Add new area
    if (Length(LineArray) <= LineArrayCnt) then
      SetLength(LineArray, LineArrayCnt + 20);
    New(LineArray[LineArrayCnt]);
    with LineArray[LineArrayCnt]^ do
    begin
      FirstLine := NewLine(fBord.Borders[aIdx].Node, nil);
      LastLine := FirstLine;
      LeftEdge := aIdx;
      RightEdge := aIdx;
      FutureLeftEdge := fBord.Borders[aIdx].Next;
      FutureRightEdge := fBord.Borders[aIdx].Prev;
      {$IFDEF DEBUG_NavMesh}
        ConfirmLine(aIdx, FutureLeftEdge, COLOR_YELLOW);
        ConfirmLine(aIdx, FutureRightEdge, COLOR_YELLOW);
      {$ENDIF}
    end;
    Inc(LineArrayCnt);
  end;
  // Remove walkable area
  procedure RemoveWalkableArea(aIdx, ConIdx: Word);
  begin
    {$IFDEF DEBUG_NavMesh}
      ConfirmLine(aIdx, LineArray[ConIdx]^.LeftEdge, COLOR_RED);
      ConfirmLine(aIdx, LineArray[ConIdx]^.RightEdge, COLOR_RED);
    {$ENDIF}
    AddNewBorder(aIdx, fBord.Borders[aIdx].Prev, ConIdx, False, True, True); // Add new border which leads to add new polygon
    DisposeArea(ConIdx);
  end;
  // Merge 2 walkable areas
  procedure MergeWalkableAreas(aIdx, aLeftEdgeLineIdx, aRightEdgeLineIdx: Word);
  begin
    {$IFDEF DEBUG_NavMesh}
      ConfirmLine(aIdx, LineArray[aLeftEdgeLineIdx]^.LeftEdge, COLOR_RED);
      ConfirmLine(aIdx, LineArray[aRightEdgeLineIdx]^.RightEdge, COLOR_RED);
    {$ENDIF}
    // Add border points and everything around it
    AddNewBorder(aIdx, aIdx, aLeftEdgeLineIdx, True); // aIdx in second parameter is OK
    AddNewBorder(aIdx, aIdx, aRightEdgeLineIdx, False);
    // Copy border properties
    LineArray[aRightEdgeLineIdx]^.LastLine^.Polygon := LineArray[aLeftEdgeLineIdx]^.FirstLine^.Polygon;
    LineArray[aRightEdgeLineIdx]^.LastLine^.Next :=    LineArray[aLeftEdgeLineIdx]^.FirstLine^.Next; // Next because first point is new border
    LineArray[aRightEdgeLineIdx]^.LastLine :=          LineArray[aLeftEdgeLineIdx]^.LastLine;
    LineArray[aRightEdgeLineIdx]^.RightEdge :=         LineArray[aLeftEdgeLineIdx]^.RightEdge;
    LineArray[aRightEdgeLineIdx]^.FutureRightEdge :=   LineArray[aLeftEdgeLineIdx]^.FutureRightEdge;
    // Free memory of second lines and update LineArray
    Dispose(LineArray[aLeftEdgeLineIdx]^.FirstLine); // Other elements will be copied
    DisposeArea(aLeftEdgeLineIdx, True);
  end;
  // Divide walkable area because of obstacle
  procedure DivideWalkableArea(aIdx, aLineIdx: Word; aPPrevLine, aPActLine: PPolyLine);
  var
    NewPolyIdx, Overflow: Word;
    pPL: PPolyLine;
  begin
    // Reserve space in memory (point is not known yet so AddNewWalkableArea cannot be used)
    if (Length(LineArray) <= LineArrayCnt) then
      SetLength(LineArray, LineArrayCnt + 20);
    New(LineArray[LineArrayCnt]);
    // Copy left border from old line
    LineArray[LineArrayCnt]^.FirstLine := LineArray[aLineIdx]^.FirstLine;
    LineArray[LineArrayCnt]^.LeftEdge := LineArray[aLineIdx]^.LeftEdge;
    LineArray[LineArrayCnt]^.FutureLeftEdge := LineArray[aLineIdx]^.FutureLeftEdge;
    if (aPPrevLine = nil) then // Create left border of NEW line if does not exist
    begin
      aPPrevLine := NewLine( aPActLine^.Node, nil );
      LineArray[LineArrayCnt]^.FirstLine := aPPrevLine;
    end
    else if (aPActLine = nil) then // Create right border of OLD line if does not exist
    begin
      aPActLine := NewLine( aPPrevLine^.Node, nil );
      LineArray[aLineIdx]^.LastLine := aPActLine;
    end
    else // Copy the line for the first area + secure connection
    begin
      aPPrevLine^.Next := NewLine( aPActLine^.Node, nil );
      aPPrevLine := aPPrevLine^.Next;
    end;
    // Mark left side
    {$IFDEF DEBUG_NavMesh} AddLine(fNodes[  fBord.Borders[ aIdx ].Node  ], fNodes[ aPPrevLine^.Node ], COLOR_RED ); {$ENDIF}
    LineArray[LineArrayCnt]^.LastLine := aPPrevLine;
    AddNewBorder(aIdx, fBord.Borders[aIdx].Prev, LineArrayCnt, False, False);
    NewPolyIdx := fPolyCount; // Polygon with this index does not exist yet
    TryConnect(aPPrevLine.Node, LineArrayCnt, False); // Now new polygons may be created (first one will be connected with second side)
    // Mark right side
    {$IFDEF DEBUG_NavMesh} AddLine(fNodes[  fBord.Borders[ aIdx ].Node  ], fNodes[ aPActLine^.Node ], COLOR_RED ); {$ENDIF}
    LineArray[aLineIdx]^.FirstLine := aPActLine;
    AddNewBorder(aIdx, fBord.Borders[aIdx].Next, aLineIdx, True, False);
    // New polygon was created -> copy information to the second area so it will be connected automatically
    pPL := nil;
    if (NewPolyIdx < fPolyCount) then
      LineArray[aLineIdx]^.FirstLine^.Polygon := NewPolyIdx
    else // The polygon was not created -> it should be created from this side -> secure transition
    begin
      Overflow := 0;
      pPL := LineArray[LineArrayCnt]^.FirstLine;
      while (Overflow < 255) AND (pPL^.Next^.Next <> nil) do
      begin
        pPL := pPL^.Next;
        Inc(Overflow);
      end;
      pPL^.Polygon := NewPolyIdx;
    end;
    TryConnect(aPActLine.Node, aLineIdx, True);
    if (NewPolyIdx >= fPolyCount) AND (pPL <> nil) then // The polygon was not created - special case when divide area is second point in a shape
      pPL^.Polygon := 0;
    Inc(LineArrayCnt);
  end;
  // Try to insert point into existing area
  function InsertPoint(aIdx, aLineIdx: Word; aBorder: Boolean): Boolean;
  var
    Point: TKMPoint;
    PPrevLine, PActLine: PPolyLine;
  begin
    // Find relative position of point in stack
    Point := fNodes[ ifthen(aBorder, fBord.Borders[aIdx].Node, aIdx) ];
    PPrevLine := nil;
    PActLine := LineArray[aLineIdx]^.FirstLine;
    repeat
      if (fNodes[ PActLine^.Node ].X >= Point.X ) then
        break;
      PPrevLine := PActLine;
      PActLine := PActLine^.Next;
    until (PActLine = nil);
    // Select the right method -> in case of border point divide area
    if aBorder then
      DivideWalkableArea(aIdx, aLIneIdx, PPrevLine, PActLine)
    else if (PPrevLine <> nil) AND (PActLine <> nil) then // In case of ordinary point just add new element + ignore border points
    begin
      {$IFDEF DEBUG_NavMesh}
        AddLine(fNodes[ aIdx ], fNodes[ PPrevLine^.Node ], COLOR_WHITE );
        AddLine(fNodes[ aIdx ], fNodes[ PActLine^.Node ], COLOR_WHITE );
      {$ENDIF}
      PPrevLine^.Next := NewLine(aIdx, PActLine, AddPolygon(aIdx, PPrevLine)); // Add line
      // Try to connect point into new triangles
      TryConnect(PActLine.Node, aLineIdx, False);
      TryConnect(PPrevLine.Node, aLineIdx, True);
    end;
    Result := True;
  end;
  // Check area and try to insert point
  procedure CheckArea(aIdx: Word; aBorder: Boolean);
  var
    Inserted: Boolean;
    I: Integer;
    Point, LeftP, FutureLeftP, RightP, FutureRightP: TKMPoint;
  begin
    Inserted := False;
    Point := fNodes[ ifthen(aBorder, fBord.Borders[aIdx].Node, aIdx) ];
    // Check position of point in area
    for I := 0 to LineArrayCnt - 1 do
    begin
      LeftP :=  fNodes[  fBord.Borders[ LineArray[I]^.LeftEdge ].Node  ];
      RightP := fNodes[  fBord.Borders[ LineArray[I]^.RightEdge ].Node  ];
      FutureLeftP :=  fNodes[  fBord.Borders[ LineArray[I]^.FutureLeftEdge ].Node  ];
      FutureRightP := fNodes[  fBord.Borders[ LineArray[I]^.FutureRightEdge ].Node  ];
      // Make sure that point is inside the shape
      if (  ( Min(RightP.X, FutureRightP.X) >= Point.X ) AND ( Max(LeftP.X, FutureLeftP.X) <= Point.X )  )
        OR (  IsRightSide(FutureLeftP,LeftP,Point) AND IsRightSide(RightP,FutureRightP,Point)  ) then
      begin
        Inserted := InsertPoint(aIdx, I, aBorder);
        break;
      end;
    end;
    if not Inserted AND aBorder then // This must be border point or the point will be ignored
      AddNewWalkableArea(aIdx);
  end;
var
  Y,Idx,K, PrevY, LeftEdgeLineIdx, RightEdgeLineIdx: Integer;
  BorderPoint: TKMPoint;
begin
  fPolyCount := 1; // First index is reserved
  SetLength(fPolygons, MAX_POLYGONS);
  FillChar(fPolygons[0], SizeOf(fPolygons[0]) * Length(fPolygons), #0);
  {$IFDEF DEBUG_NavMesh}
    fDL.Count := 0;
  {$ENDIF}
  LineArrayCnt := 0;
  PrevY := 0;
  // For Y coord in map
  for Y := Low(fBordByY) to High(fBordByY) do
  begin
    // Get index of first border node in Y row
    Idx := fBordByY[Y];
    while (Idx > 0) do
      with fBord.Borders[Idx] do
      begin
        BorderPoint := fNodes[Node];
        // Add all middle points which are between new and old Y coord
        if (PrevY < BorderPoint.Y-1) then
        begin
          for K := fIdxArr[PrevY] to fIdxArr[BorderPoint.Y - 1] - 1 do
            CheckArea(K, False);
          PrevY := BorderPoint.Y-1;
        end;
        // Check connection with existing lines
        LeftEdgeLineIdx := -1;
        RightEdgeLineIdx := -1;
        for K := 0 to LineArrayCnt - 1 do
        begin
          if (LineArray[K]^.FutureLeftEdge = Idx) then
            LeftEdgeLineIdx := K;
          if (LineArray[K]^.FutureRightEdge = Idx) then
            RightEdgeLineIdx := K;
        end;
        // Select the right action and add the point
        if (LeftEdgeLineIdx > -1) AND (RightEdgeLineIdx > -1) then // Left and right side border
        begin
          if (LeftEdgeLineIdx = RightEdgeLineIdx) then
            RemoveWalkableArea(Idx, LeftEdgeLineIdx)
          else
            MergeWalkableAreas(Idx, LeftEdgeLineIdx, RightEdgeLineIdx)
        end
        else if (LeftEdgeLineIdx > -1) then // Left border is expanded
          AddNewBorder(Idx, Next, LeftEdgeLineIdx, True)
        else if (RightEdgeLineIdx > -1) then // Right border is expanded
          AddNewBorder(Idx, Prev, RightEdgeLineIdx, False)
        else // Create new area
          CheckArea(Idx, True);
        Idx := NextY; // Move to next Idx in row Y
      end;
  end;
  // Clean mess (only for debug, in normal case it should not be required)
  while (LineArrayCnt > 0) do
    DisposeArea(LineArrayCnt - 1);
end;




// Polygon optimalization
procedure TKMNavMeshGenerator.PrettyPoly();
var
  Chck: array of boolean;

  function AnalyzePoints(aNode1, aNode2: Word; var CP1,CP2,DP1,DP2: Word): Boolean;
  var
    K,L: Integer;
  begin
    CP1 := 0; // 0. index is reserved and it is not used in triangulation
    CP2 := 0;
    DP1 := 0;
    DP2 := 0;
    for K := 0 to 2 do
    for L := 0 to 2 do
      with fPolygons[aNode2] do
        if (fPolygons[aNode1].Indices[K] = Indices[L]) then
        begin
          if (CP1 = 0) then
            CP1 := Indices[L]
          else
          begin
            CP2 := Indices[L];
            break;
          end;
        end;
    with fPolygons[aNode1] do
      if      (CP1 <> Indices[0]) AND (CP2 <> Indices[0]) then DP1 := Indices[0]
      else if (CP1 <> Indices[1]) AND (CP2 <> Indices[1]) then DP1 := Indices[1]
      else if (CP1 <> Indices[2]) AND (CP2 <> Indices[2]) then DP1 := Indices[2];
    with fPolygons[aNode2] do
      if      (CP1 <> Indices[0]) AND (CP2 <> Indices[0]) then DP2 := Indices[0]
      else if (CP1 <> Indices[1]) AND (CP2 <> Indices[1]) then DP2 := Indices[1]
      else if (CP1 <> Indices[2]) AND (CP2 <> Indices[2]) then DP2 := Indices[2];
    Result := (CP2 > 0) AND (DP2 > 0);
  end;

  function HaveIndices(aPolyIdx,aIndice1,aIndice2: Word): Boolean;
  begin
    with fPolygons[aPolyIdx] do
      Result := (+ Byte( (Indices[0] = aIndice1) OR (Indices[0] = aIndice2) )
                 + Byte( (Indices[1] = aIndice1) OR (Indices[1] = aIndice2) )
                 + Byte( (Indices[2] = aIndice1) OR (Indices[2] = aIndice2) )) = 2;
  end;

  function BeautifyPoly(ActIdx: Integer): Boolean;
  var
    CP1,CP2,DP1,DP2, BestCP1,BestCP2,BestDP1,BestDP2, SwapPoly1, SwapPoly2: Word;
    K, BestIdx, Idx1, Idx2: Integer;
    SqrBestDist, SqrDist: Single;
  begin
    BestCP1 := 0;
    BestCP2 := 0;
    BestDP1 := 0;
    BestDP2 := 0;
    BestIdx := 0;
// Pick up the longest line of triangle which have nearby polygon
    SqrBestDist := 0;
    for K := 0 to fPolygons[ActIdx].NearbyCount - 1 do
      if AnalyzePoints(ActIdx,fPolygons[ActIdx].Nearby[K],CP1,CP2,DP1,DP2) then
      begin
        SqrDist := KMDistanceSqr(fNodes[ CP1 ],fNodes[ CP2 ]) - KMDistanceSqr(fNodes[ DP1 ],fNodes[ DP2 ]);
        if (SqrDist > SqrBestDist) AND Intersect(CP1,CP2,DP1,DP2) then
        begin
          SqrBestDist := SqrDist;
          BestCP1 := CP1;
          BestCP2 := CP2;
          BestDP1 := DP1;
          BestDP2 := DP2;
          BestIdx := fPolygons[ActIdx].Nearby[K];
        end;
      end;
    Result := (SqrBestDist > 0);
    if Result then
    begin
      // Find indexes of nearby polygons which must be swaped to secure connection
      with fPolygons[ ActIdx ] do
        if      (Nearby[0] = 0) OR ((Nearby[0] <> BestIdx) AND HaveIndices(Nearby[0], BestCP1, BestDP1)) then Idx1 := 0
        else if (Nearby[1] = 0) OR ((Nearby[1] <> BestIdx) AND HaveIndices(Nearby[1], BestCP1, BestDP1)) then Idx1 := 1
        else{if (Nearby[2] = 0) OR ((Nearby[2] <> BestIdx) AND HaveIndices(Nearby[2], BestCP1, BestDP1)) then}Idx1 := 2;
      with fPolygons[ BestIdx ] do
        if      (Nearby[0] = 0) OR ((Nearby[0] <> BestIdx) AND HaveIndices(Nearby[0], BestCP2, BestDP2)) then Idx2 := 0
        else if (Nearby[1] = 0) OR ((Nearby[1] <> BestIdx) AND HaveIndices(Nearby[1], BestCP2, BestDP2)) then Idx2 := 1
        else{if (Nearby[2] = 0) OR ((Nearby[2] <> BestIdx) AND HaveIndices(Nearby[2], BestCP2, BestDP2)) then}Idx2 := 2;
      SwapPoly1 := fPolygons[ActIdx].Nearby[Idx1];
      SwapPoly2 := fPolygons[BestIdx].Nearby[Idx2];

      // Actualize connection of nearby polygons
      if (SwapPoly1 > 0) then
        with fPolygons[ SwapPoly1 ] do
          if      (Nearby[0] = ActIdx) then Nearby[0] := BestIdx
          else if (Nearby[1] = ActIdx) then Nearby[1] := BestIdx
          else if (Nearby[2] = ActIdx) then Nearby[2] := BestIdx;
      if (SwapPoly2 > 0) then
        with fPolygons[ SwapPoly2 ] do
          if      (Nearby[0] = BestIdx) then Nearby[0] := ActIdx
          else if (Nearby[1] = BestIdx) then Nearby[1] := ActIdx
          else if (Nearby[2] = BestIdx) then Nearby[2] := ActIdx;

      // Actualize connection of changed polygons
      with fPolygons[BestIdx] do
        if (SwapPoly1 > 0) then
        begin
          Nearby[Idx2] := SwapPoly1;
          NearbyCount := NearbyCount + Byte(SwapPoly2 = 0);
        end
        else
        begin
          NearbyCount := NearbyCount - Byte(SwapPoly2 > 0);
          Nearby[Idx2] := Nearby[NearbyCount];
          Nearby[NearbyCount] := 0; // Zero must be here
        end;
      with fPolygons[ActIdx] do
        if (SwapPoly2 > 0) then
        begin
          Nearby[Idx1] := SwapPoly2;
          NearbyCount := NearbyCount + Byte(SwapPoly1 = 0);
        end
        else
        begin
          NearbyCount := NearbyCount - Byte(SwapPoly1 > 0);
          Nearby[Idx1] := Nearby[NearbyCount];
          Nearby[NearbyCount] := 0; // Zero must be here
        end;

      // Change indices
      with fPolygons[ActIdx] do
        if      (BestCP1 = Indices[0]) then Indices[0] := BestDP2
        else if (BestCP1 = Indices[1]) then Indices[1] := BestDP2
        else{if (BestCP1 = Indices[2]) then}Indices[2] := BestDP2;
      with fPolygons[BestIdx] do
        if      (BestCP2 = Indices[0]) then Indices[0] := BestDP1
        else if (BestCP2 = Indices[1]) then Indices[1] := BestDP1
        else{if (BestCP2 = Indices[2]) then}Indices[2] := BestDP1;

      BeautifyPoly(ActIdx);
      BeautifyPoly(BestIdx);
    end;
    Chck[ActIdx] := True;
  end;

var
  ActIdx: Integer;
begin
  SetLength(Chck,fPolyCount);
  FillChar(Chck[0], SizeOf(Chck[0])*Length(Chck),False);
  for ActIdx := 1 to fPolyCount - 1 do
    if not Chck[ActIdx] then
        BeautifyPoly(ActIdx);
end;




function TKMNavMeshGenerator.Paint(const aRect: TKMRect): Boolean;
const
  COLOR_WHITE = $FFFFFF;
  COLOR_BLACK = $000000;
  COLOR_GREEN = $00FF00;
  COLOR_RED = $7700FF;
  COLOR_YELLOW = $00FFFF;
  COLOR_BLUE = $FF0000;
{$IFDEF DEBUG_NavMesh}
var
  X,Y,K: Integer;
  p1,p2,p3: TKMPoint;
{$ENDIF}
begin
  Result := False;
  if not AI_GEN_NAVMESH OR not OVERLAY_NAVMESH then
    Exit;

  {$IFDEF DEBUG_NavMesh}
  Result := True; // Block standard NavMesh Paint procedure

  //GenerateNewNavMesh();

  //{ Border Nodes
  for X := 1 to fBorderNodeCount-1 do
    gRenderAux.Text(fBorderNodes[X].X+0.25, fBorderNodes[X].Y+0.4, IntToStr(X), $FF000000 OR COLOR_GREEN);
  //}
  //{ Nodes
  for K := 1 to fNodeCount - 1 do
      gRenderAux.Text(fNodes[K].X+0.25, fNodes[K].Y+0.4, IntToStr(K), $FF000000 OR COLOR_RED);
  for K := fInnerPointStartIdx to fInnerPointEndIdx do
      gRenderAux.Text(fNodes[K].X+0.25, fNodes[K].Y+0.4, IntToStr(K), $FF000000 OR COLOR_GREEN);
  //}
  //{ Border Lines
  for K := 0 to fBord.Count - 1 do
    with fBord.Borders[K] do
    begin
      p1 := fNodes[ Node ];
      p2 := fNodes[ fBord.Borders[Next].Node ];
      p3 := fNodes[ fBord.Borders[Prev].Node ];
      gRenderAux.LineOnTerrain(p1, p2, $70000000 OR COLOR_RED);
      gRenderAux.LineOnTerrain(p1, p3, $70000000 OR COLOR_RED);
    end;
  //}
  //{ Debug lines of triangulation
  for K := 0 to fDL.Count - 1 do
  begin
      p1 := fDL.Lines[K].p1;
      p2 := fDL.Lines[K].p2;
      gRenderAux.LineOnTerrain(p1, p2, $99000000 OR fDL.Lines[K].Color);
      gRenderAux.Text((p1.X+p2.X)/2, (p1.Y+p2.Y)/2, IntToStr(K), $FF000000 OR fDL.Lines[K].Color);
  end;
  //}
  {$ENDIF}
end;

end.

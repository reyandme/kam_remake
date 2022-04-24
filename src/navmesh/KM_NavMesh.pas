unit KM_NavMesh;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points, Contnrs,
  KM_NavMeshDefences,
  KromUtils, KM_CommonUtils,
  KM_NavMeshGenerator, KM_NavMeshFloodPositioning, KM_NavMeshPathFinding;// TimeGet


type
  // NavMesh is used to acess the map on a higher level than tiles
  // terrain is represented as a mesh of interconnected polygons
  TKMNavMesh = class
  private
    fMapX, fMapY: Word;               // Limits of arrays
    fInnerNodesStartIdx: Word;        // Inner nodes starts at this index
    fNodeCount, fPolyCount: Integer;  // Thresholds
    fNodes: TKMPointArray;            // Nodes
    fPolygons: TPolygonArray;         // Polygons
    fPoint2PolygonArr: TKMWordArray;  // KMPoint -> Polygon index
    //fPolygon2PointArr: TKMPointArray; // Polygon index -> KMPoint

    fDefences: TForwardFF; //Defences class
    fPathfinding: TNavMeshPathFinding; // NavMesh Pathfinding
    fPositioning: TNavMeshFloodPositioning; // NavMesh Positioning

    fNavMeshGenerator: TKMNavMeshGenerator; // NavMesh generator

    {$IFDEF DEBUG_NavMesh}
    fTimeAvrgGenerator, fTimeAvrgCopyNavMesh, fTimeAvrgTieUpTwP, fTimeAvrgTieUpPwT, fTimeAvrgSum: Int64;
    fTimePeakGenerator, fTimePeakCopyNavMesh, fTimePeakTieUpTwP, fTimePeakTieUpPwT, fTimePeakSum: Int64;
    {$ENDIF}

    //Building the navmesh from terrain
    procedure GenerateNavMesh(aStep: Integer);
    procedure FindClosestPolygon();
    procedure TieUpTilesWithPolygons();
    procedure TieUpPolygonsWithTiles();

    function GetPolygonFromPoint(const aY,aX: Integer): Word;
    function GetPolygonFromKMPoint(const aPoint: TKMPoint): Word;

  public
    constructor Create();
    destructor Destroy(); override;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property Point2Polygon[const aY,aX: Integer]: Word read GetPolygonFromPoint;
    property KMPoint2Polygon[const aPoint: TKMPoint]: Word read GetPolygonFromKMPoint;
    //property Polygon2Point: TKMPointArray read fPolygon2PointArr;
    property Polygons: TPolygonArray read fPolygons;
    property PolygonsCnt: Integer read fPolyCount;
    property Nodes: TKMPointArray read fNodes;
    property NodesCnt: Integer read fNodeCount;
    property Defences: TForwardFF read fDefences write fDefences;
    property Pathfinding: TNavMeshPathFinding read fPathfinding write fPathfinding;
    property Positioning: TNavMeshFloodPositioning read fPositioning write fPositioning;

    procedure AfterMissionInit();

    procedure UpdateState(aTick: Cardinal);
    procedure DrawPolygon(const aIdx: Integer; const aOpacity: Byte; aFillColor: Cardinal; const aTextOffset: Single = 0; const aText: String = '');
    procedure Paint(const aRect: TKMRect);
  end;

const
  MAX_LINE_LENGTH = 6;


implementation
uses
  SysUtils, Math,
  KM_Terrain, KM_RenderAux, KM_AIFields;


{ TKMNavMesh }
constructor TKMNavMesh.Create();
begin
  inherited Create;

  fNavMeshGenerator := TKMNavMeshGenerator.Create();
  fDefences := TForwardFF.Create(True);
  fPathfinding := TNavMeshPathFinding.Create();
  fPositioning := TNavMeshFloodPositioning.Create();
  {$IFDEF DEBUG_NavMesh}
    fTimeAvrgGenerator   := 0;
    fTimeAvrgCopyNavMesh := 0;
    fTimeAvrgTieUpTwP    := 0;
    fTimeAvrgTieUpPwT    := 0;
    fTimeAvrgSum         := 0;
    fTimePeakGenerator   := 0;
    fTimePeakCopyNavMesh := 0;
    fTimePeakTieUpTwP    := 0;
    fTimePeakTieUpPwT    := 0;
    fTimePeakSum         := 0;
  {$ENDIF}
end;


destructor TKMNavMesh.Destroy();
begin
  fDefences.Free;
  fPathfinding.Free;
  fPositioning.Free;
  fNavMeshGenerator.Free;
  inherited;
end;


procedure TKMNavMesh.Save(SaveStream: TKMemoryStream);
var
  K: Integer;
begin
  fNavMeshGenerator.Save(SaveStream);
  SaveStream.PlaceMarker('NavMesh');
  SaveStream.Write(fMapX);
  SaveStream.Write(fMapY);

  SaveStream.Write(fInnerNodesStartIdx);
  SaveStream.Write(fNodeCount);
  SaveStream.Write(fNodes[0], SizeOf(fNodes[0]) * fNodeCount);

  SaveStream.Write(fPolyCount);
  SaveStream.Write(fPolygons[0], SizeOf(fPolygons[0]) * fPolyCount);
  // Maybe this code will save work in future
  //for K := 0 to fPolyCount - 1 do
  //begin
  //  SaveStream.Write(fPolygons[K].CenterPoint);
  //  SaveStream.Write(fPolygons[K].Indices, SizeOf(fPolygons[I].Indices));
  //  SaveStream.Write(fPolygons[K].NearbyCount);
  //  SaveStream.Write(fPolygons[K].Poly2PointStart);
  //  SaveStream.Write(fPolygons[K].Poly2PointCnt);
  //  SaveStream.Write(fPolygons[K].Nearby, SizeOf(fPolygons[I].Nearby));
  //  SaveStream.Write(fPolygons[K].NearbyPoints, SizeOf(fPolygons[I].NearbyPoints));
  //end;

  K := Length(fPoint2PolygonArr);
  SaveStream.Write( K );
  SaveStream.Write(fPoint2PolygonArr[0], SizeOf(fPoint2PolygonArr[0]) * K );

  //K := Length(fPolygon2PointArr);
  //SaveStream.Write( K );
  //SaveStream.Write(fPolygon2PointArr[0], SizeOf(fPolygon2PointArr[0]) * K );

  // The following does not requires save
  // fDefences
  // fPathfinding
  // fPositioning
end;


procedure TKMNavMesh.Load(LoadStream: TKMemoryStream);
var
  K: Integer;
begin
  fNavMeshGenerator.Load(LoadStream);
  LoadStream.CheckMarker('NavMesh');
  LoadStream.Read(fMapX);
  LoadStream.Read(fMapY);

  LoadStream.Read(fInnerNodesStartIdx);
  LoadStream.Read(fNodeCount);
  SetLength(fNodes, fNodeCount);
  LoadStream.Read(fNodes[0], SizeOf(fNodes[0]) * fNodeCount);

  LoadStream.Read(fPolyCount);
  SetLength(fPolygons, fPolyCount);
  LoadStream.Read(fPolygons[0], SizeOf(fPolygons[0]) * fPolyCount);
  //for K := 0 to fPolyCount - 1 do
  //begin
  //  LoadStream.Read(fPolygons[K].CenterPoint);
  //  LoadStream.Read(fPolygons[K].Indices, SizeOf(fPolygons[I].Indices));
  //  LoadStream.Read(fPolygons[K].NearbyCount);
  //  LoadStream.Read(fPolygons[K].Poly2PointStart);
  //  LoadStream.Read(fPolygons[K].Poly2PointCnt);
  //  LoadStream.Read(fPolygons[K].Nearby, SizeOf(fPolygons[I].Nearby));
  //  LoadStream.Read(fPolygons[K].NearbyPoints, SizeOf(fPolygons[I].NearbyPoints));
  //end;

  LoadStream.Read(K);
  SetLength(fPoint2PolygonArr,K);
  LoadStream.Read(fPoint2PolygonArr[0], SizeOf(fPoint2PolygonArr[0]) * K );

  //LoadStream.Read(K);
  //SetLength(fPolygon2PointArr,K);
  //LoadStream.Read(fPolygon2PointArr[0], SizeOf(fPolygon2PointArr[0]) * K );
end;


procedure TKMNavMesh.AfterMissionInit();
begin
  fMapX := gTerrain.MapX;
  fMapY := gTerrain.MapY;
  GenerateNavMesh(-1);
end;


procedure TKMNavMesh.UpdateState(aTick: Cardinal);
begin
  if (aTick mod (MAX_HANDS*330) = 15) then // The normal game has 12 players so ticks with 13-18 should be cheaper for performance
    GenerateNavMesh(-1);
end;


procedure TKMNavMesh.GenerateNavMesh(aStep: Integer);
  {$IFDEF DEBUG_NavMesh}
  var
    tStart,tStop,tSum: Int64;
  procedure UpdateTimer(var aTimeAvrg, aTimePeak: Int64);
  begin
    tStop := TimeGetUsec() - tStart;
    tSum := tSum + tStop;
    aTimePeak := Max(aTimePeak, tStop);
    aTimeAvrg := Round((aTimeAvrg * 5 + tStop)/6);
    tStart := TimeGetUsec();
  end;
  {$ENDIF}
begin
  {$IFDEF DEBUG_NavMesh}
    tSum := 0;
    tStart := TimeGetUsec();
  {$ENDIF}

  //if (aStep = 0) OR (aStep = -1) then
  fNavMeshGenerator.GenerateNewNavMesh();
  {$IFDEF DEBUG_NavMesh}
    UpdateTimer(fTimeAvrgGenerator, fTimePeakGenerator);
  {$ENDIF}

  //if (aStep = 1) OR (aStep = -1) then
  fNodeCount := fNavMeshGenerator.NodeCount;
  fPolyCount := fNavMeshGenerator.PolygonCount;
  fInnerNodesStartIdx := fNavMeshGenerator.InnerPointStartIdx;
  fNodes := fNavMeshGenerator.Nodes;
  fPolygons := fNavMeshGenerator.Polygons;
  {$IFDEF DEBUG_NavMesh}
    UpdateTimer(fTimeAvrgCopyNavMesh, fTimePeakCopyNavMesh);
  {$ENDIF}

  //Mapp all map tiles to its polygons and vice versa
  //if (aStep = 2) OR (aStep = -1) then
  TieUpTilesWithPolygons();
  {$IFDEF DEBUG_NavMesh}
    UpdateTimer(fTimeAvrgTieUpTwP, fTimePeakTieUpTwP);
  {$ENDIF}
  //if (aStep = 3) OR (aStep = -1) then
  TieUpPolygonsWithTiles();
  {$IFDEF DEBUG_NavMesh}
    UpdateTimer(fTimeAvrgTieUpPwT, fTimePeakTieUpPwT);
    fTimePeakSum := Max(fTimePeakSum, tSum);
    fTimeAvrgSum := Round((fTimeAvrgSum * 5 + tSum)/6);
  {$ENDIF}
  //if (aStep = 4) OR (aStep = -1) then
  gAIFields.Influences.InitInfluences();
end;


function TKMNavMesh.GetPolygonFromPoint(const aY,aX: Integer): Word;
var
  Idx: Integer;
begin
  Result := 0;
  Idx := aY*(fMapX+1) + aX;
  if (Length(fPoint2PolygonArr) > Idx) then
    Result := fPoint2PolygonArr[Idx];
end;


function TKMNavMesh.GetPolygonFromKMPoint(const aPoint: TKMPoint): Word;
var
  Idx: Integer;
begin
  Result := 0;
  Idx := aPoint.Y*(fMapX+1) + aPoint.X;
  if (Length(fPoint2PolygonArr) > Idx) then
    Result := fPoint2PolygonArr[Idx];
end;


procedure TKMNavMesh.FindClosestPolygon();
var
  Len, MaxIdx: Integer;
  Queue: array[0..(MAX_MAP_SIZE-1)*(MAX_MAP_SIZE-1)] of Integer;
  procedure AddToQueue(aIdx, aPolygon: Integer);
  begin
    Queue[MaxIdx] := aIdx;
    Inc(Len);
    Inc(MaxIdx);
    if (MaxIdx > High(Queue)) then
      MaxIdx := 0;
    fPoint2PolygonArr[aIdx] := aPolygon;
  end;
var
  K,Y,ActIdx: Integer;
begin
  FillChar(Queue, SizeOf(Queue), #0);
  // Mark borders so they do not have to be checked (fPoint2PolygonArr have length fMapX+1 in X and fMapY+1 in Y)
  FillChar(fPoint2PolygonArr[0], SizeOf(Word)*(fMapX+1), #255);
  FillChar(fPoint2PolygonArr[(fMapX+1)*fMapY], SizeOf(Word)*(fMapX+1), #255);
  Y := 0;
  while Y < (fMapX+1) * (fMapY+1) do
  begin
    fPoint2PolygonArr[Y] := High(Word);
    fPoint2PolygonArr[Y + fMapX] := High(Word);
    Y := Y + fMapX+1;
  end;
  // Get all used points
  Len := 0;
  for K := Low(fPoint2PolygonArr) to High(fPoint2PolygonArr) do
    if (fPoint2PolygonArr[K] <> 0) AND (fPoint2PolygonArr[K] <> High(Word)) then
    begin
      Queue[Len] := K;
      Inc(Len);
    end;
  // Expand used points into empty surrounding area
  ActIdx := 0;
  MaxIdx := Len;
  while (Len > 0) do
  begin
    K := Queue[ActIdx];
    Dec(Len);
    Inc(ActIdx);
    if (ActIdx > High(Queue)) then
      ActIdx := 0;
    if (fPoint2PolygonArr[K - 1        ] = 0) then AddToQueue(K - 1        , fPoint2PolygonArr[K]);
    if (fPoint2PolygonArr[K + 1        ] = 0) then AddToQueue(K + 1        , fPoint2PolygonArr[K]);
    if (fPoint2PolygonArr[K - fMapX - 1] = 0) then AddToQueue(K - fMapX - 1, fPoint2PolygonArr[K]);
    if (fPoint2PolygonArr[K + fMapX + 1] = 0) then AddToQueue(K + fMapX + 1, fPoint2PolygonArr[K]);
  end;
end;


procedure TKMNavMesh.TieUpTilesWithPolygons();
  procedure GetNodesSortedByY(aIdx: Integer; var a,b,c: TKMPoint);
  begin
    a := fNodes[ fPolygons[aIdx].Indices[0] ];
    b := fNodes[ fPolygons[aIdx].Indices[1] ];
    c := fNodes[ fPolygons[aIdx].Indices[2] ];
    if (a.Y > b.Y) then KMSwapPoints(a,b);
    if (b.Y > c.Y) then KMSwapPoints(b,c);
    if (a.Y > b.Y) then KMSwapPoints(a,b);
  end;
  procedure NormalLineEquation(P1,P2: TKMPoint; var a,b,c: Single);
  begin
    a := - P1.Y + P2.Y;
    b := + P1.X - P2.X;
    c := - a * (P1.X + 0.5) - b * (P1.Y + 0.5); // + 0.5 will move triangle by 1/2 of tile in right down direction
  end;
  function IsRightSide(P1,P2,Point: TKMPoint): Boolean;
  begin
    Result := ((P2.X - P1.X) * (Point.Y - P1.Y) < (P2.Y - P1.Y) * (Point.X - P1.X));
  end;
  procedure FillTriangle(RightSide: Boolean; aIdx, StartY,EndY: Integer; a1,b1,c1, a2,b2,c2: Single);
  var
    X,Y: Integer;
    invA1,invA2, X1, X2: Single;
  begin
    if (a1 = 0) OR (a2 = 0) then
      Exit;
    invA1 := 1 / (a1*1.0); // a*X + b*Y + c = 0  ->  X = (- b*Y - c) * (1/a)  ->  X = C1*Y + C2
    invA2 := 1 / (a2*1.0);
    for Y := StartY to EndY do
    begin
      X1 := (- b1*Y - c1) * invA1 + 0.499;
      X2 := (- b2*Y - c2) * invA2;
      if not RightSide then
        KMSwapFloat(X1,X2);
      for X := Round( X1 ) to Trunc( X2 ) do
        fPoint2PolygonArr[ Y*(fMapX+1) + X ] := aIdx; // Property does not have write attribute
    end;
  end;
  procedure ComputeNearbyPoints(aIdx: Word);
  var
    SecondPoint: Boolean;
    K,L,M, ToIdx: Integer;
    P: TKMPoint;
    Indices: array[0..1] of Word;
  begin
    for K := fPolygons[aIdx].NearbyCount - 1 downto 0 do
    begin
      SecondPoint := False;
      ToIdx := fPolygons[aIdx].Nearby[K];
      for L := 0 to 2 do
      for M := 0 to 2 do
        if (fPolygons[aIdx].Indices[L] = fPolygons[ToIdx].Indices[M]) then
        begin
          Indices[ Byte(SecondPoint) ] := fPolygons[aIdx].Indices[L];
          SecondPoint := True;
          Break;
        end;
      if SecondPoint then
      begin
        P := KMPointAverage(fNodes[ Indices[0] ], fNodes[ Indices[1] ]);
        fPolygons[aIdx].NearbyPoints[K] := KMPoint(  Min( fMapX-1, Max(1,P.X) ), Min( fMapY-1, Max(1,P.Y) )  );

        if (fInnerNodesStartIdx >= Indices[0]) AND (fInnerNodesStartIdx > Indices[1]) then
          fPolygons[aIdx].NearbyLineLength[K] := Min(MAX_LINE_LENGTH,  Max( abs(fNodes[ Indices[0] ].X - fNodes[ Indices[1] ].X), abs(fNodes[ Indices[0] ].Y - fNodes[ Indices[1] ].Y) )  )
        else
          fPolygons[aIdx].NearbyLineLength[K] := MAX_LINE_LENGTH;
      end
      else
      begin
        for L := K to fPolygons[aIdx].NearbyCount - 2 do
        begin
          fPolygons[aIdx].NearbyPoints[L] := fPolygons[aIdx].NearbyPoints[L+1];
          fPolygons[aIdx].NearbyLineLength[L] := fPolygons[aIdx].NearbyLineLength[L+1];
        end;
        Dec(fPolygons[aIdx].NearbyCount);
      end;
    end;
  end;
var
  RightSide: Boolean;
  K: Integer;
  a1,b1,c1, a2,b2,c2, a3,b3,c3: Single;
  N1,N2,N3: TKMPoint;
begin
  SetLength(fPoint2PolygonArr, (fMapY+1) * (fMapX+1));
  FillChar(fPoint2PolygonArr[0], SizeOf(fPoint2PolygonArr[0]) * Length(fPoint2PolygonArr), #0); // 0 Is unused polygon
  for K := 1 to fPolyCount - 1 do
  begin
    // Fill fPoint2PolygonArr
    GetNodesSortedByY(K, N1,N2,N3);
    RightSide := IsRightSide(N1,N3,N2);
    NormalLineEquation(N1,N3, a1,b1,c1);
    NormalLineEquation(N1,N2, a2,b2,c2);
    NormalLineEquation(N2,N3, a3,b3,c3);
    FillTriangle(RightSide, K, N1.Y,N2.Y,   a1,b1,c1, a2,b2,c2); // Skip last line if second part is active
    FillTriangle(RightSide, K, N2.Y+1,N3.Y, a1,b1,c1, a3,b3,c3);
    // Fill another polygon informations
    // Center point must be inside of map coords
    fPolygons[K].CenterPoint := KMPoint(
                                  Min(  fMapX-1, Max( 1, Round((N1.X+N2.X+N3.X)/3) )  ),
                                  Min(  fMapY-1, Max( 1, Round((N1.Y+N2.Y+N3.Y)/3) )  )
                                );
    ComputeNearbyPoints(K);
  end;
  FindClosestPolygon();
end;


procedure TKMNavMesh.TieUpPolygonsWithTiles();
//var
//  X,Y,Polygon: Integer;
begin
  {
  // Get count of points in specific polygon
  for Y := 1 to fMapY-1 do
  for X := 1 to fMapX-1 do
    Inc(fPolygons[ Point2Polygon[Y,X] ].Poly2PointCnt); // Poly2PointCnt was set to 0 in initialization
  // Get starting index of each polygon
  for X := 1 to fPolyCount - 1 do // 0. polygon is reserved / unused
    fPolygons[X].Poly2PointStart := fPolygons[X-1].Poly2PointStart + fPolygons[X-1].Poly2PointCnt;
  // Fill points in 1D array which is common for all polygons
  SetLength(fPolygon2PointArr,(fMapX-1) * (fMapY-1));
  for Y := 1 to fMapY-1 do
  for X := 1 to fMapX-1 do
  begin
    Polygon := Point2Polygon[Y,X];
    fPolygon2PointArr[  fPolygons[Polygon].Poly2PointStart  ] := KMPoint(X,Y);
    Inc(fPolygons[Polygon].Poly2PointStart);
  end;
  // Get starting index of each polygon
  for X := 1 to fPolyCount - 1 do // 0. polygon is reserved / unused
    fPolygons[X].Poly2PointStart := fPolygons[X-1].Poly2PointStart + fPolygons[X-1].Poly2PointCnt;
  //}
end;


//Render debug symbols
procedure TKMNavMesh.DrawPolygon(const aIdx: Integer; const aOpacity: Byte; aFillColor: Cardinal; const aTextOffset: Single = 0; const aText: String = '');
var
  P0,P1,P2: TKMPoint;
begin
  if (aOpacity = 0) OR (aIdx >= PolygonsCnt) then
    Exit;
  P0 := Nodes[ Polygons[aIdx].Indices[0] ];
  P1 := Nodes[ Polygons[aIdx].Indices[1] ];
  P2 := Nodes[ Polygons[aIdx].Indices[2] ];
  gRenderAux.TriangleOnTerrain(P0.X,P0.Y, P1.X,P1.Y, P2.X,P2.Y, aFillColor OR (aOpacity shl 24));
  if (Length(aText) > 0) then
    gRenderAux.Text(Polygons[aIdx].CenterPoint.X, Polygons[aIdx].CenterPoint.Y + aTextOffset, aText, $FFFFFFFF);
end;


procedure TKMNavMesh.Paint(const aRect: TKMRect);

  function GetCommonPoints(aIdx1, aIdx2: Word; var aPoint1, aPoint2: TKMPoint): Boolean;
  var
    FirstPoint: Boolean;
    K,L: Integer;
  begin
    Result := False;
    FirstPoint := True;
    for K := 0 to 2 do
    for L := 0 to 2 do
      if (fPolygons[aIdx1].Indices[K] = fPolygons[aIdx2].Indices[L]) then
      begin
        if FirstPoint then
          aPoint1 := fNodes[ fPolygons[aIdx2].Indices[L] ]
        else
        begin
          aPoint2 := fNodes[ fPolygons[aIdx2].Indices[L] ];
          Result := True;
          Exit;
        end;
        FirstPoint := False;
      end;
  end;

var
  K, L: Integer;
  //Color: Cardinal;
  p1,p2: TKMPoint;
begin
  //{ DEFENCE SYSTEM
  // Show this defences only in case that show combat AI is not enabled;
  // when it is we need existing results not the actual (defences are updated each 1 min so it may be different)
  if AI_GEN_NAVMESH AND not OVERLAY_NAVMESH AND OVERLAY_DEFENCES AND not OVERLAY_AI_COMBAT then
    fDefences.Paint();
  //}

  if AI_GEN_NAVMESH AND (OVERLAY_HIGHLIGHT_POLY > 0) AND (OVERLAY_HIGHLIGHT_POLY < PolygonsCnt) then
    DrawPolygon(OVERLAY_HIGHLIGHT_POLY, $CC, tcRed, 1, IntToStr(OVERLAY_HIGHLIGHT_POLY));

  //AfterMissionInit();
  if not AI_GEN_NAVMESH OR not OVERLAY_NAVMESH then
    Exit;
  //{
  if fNavMeshGenerator.Paint(aRect) then
    Exit;
  //}
  //fNavMeshGenerator.Paint(aRect);
  // EXTRACT POLYGONS
  //{ Triangles and connection of NavMesh
  for K := 1 to fPolyCount - 1 do
    with fPolygons[K] do
    begin
      DrawPolygon(K, $50, tcBlack, 1, IntToStr(K));
      for L := 0 to NearbyCount - 1 do
        if GetCommonPoints(K, Nearby[L], p1, p2) then
          gRenderAux.LineOnTerrain(p1, p2, $99000000 OR ((MAX_LINE_LENGTH-NearbyLineLength[L])*16 shl 24) OR $770000 OR (NearbyLineLength[L]*20 shl 16) OR ((250-NearbyLineLength[L]*40) shl 0))
        else
          DrawPolygon(K, $90, tcWhite, 1, IntToStr(K));
    end;
  //}
  { Center points and transitions of polygons
  for K := 0 to fPolyCount - 1 do
    with fPolygons[K] do
    begin
      gRenderAux.Quad(CenterPoint.X, CenterPoint.Y, $AAFFFFFF);
      for L := 0 to NearbyCount - 1 do
        gRenderAux.Quad(NearbyPoints[L].X, NearbyPoints[L].Y, $AA000000);
    end;
  //}
end;


end.

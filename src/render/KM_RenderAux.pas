unit KM_RenderAux;
{$I KaM_Remake.inc}
interface
uses
  dglOpenGL, SysUtils, KromOGLUtils, KromUtils, Math,
  KM_Defaults, KM_CommonClasses, KM_Points;

type
  //Debug symbols render
  TRenderAux = class
  private
    procedure RenderDot(pX, pY: Single; Size: Single = 0.05);
    procedure RenderDotOnTile(pX, pY: Single);
    procedure RenderLine(x1, y1, x2, y2: Single);
    procedure RenderQuad(pX, pY: Integer);
  public
    procedure Circle(x, y, rad: Single; Fill, Line: TColor4);
    procedure CircleOnTerrain(x, y, rad: Single; Fill, Line: TColor4);
    procedure Dot(x, y: Single; aCol: TColor4; aSize: Single = 0.05);
    procedure DotOnTerrain(x, y: Single; aCol: TColor4);
    procedure LineOnTerrain(x1, y1, x2, y2: Single; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True); overload;
    procedure LineOnTerrain(const A, B: TKMPoint; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True); overload;
    procedure LineOnTerrain(const A, B: TKMPointF; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True); overload;
    procedure Line(const A, B: TKMPoint; aCol: TColor4; aPattern: Word = $FFFF); overload;
    procedure Line(const A, B: TKMPointF; aCol: TColor4; aPattern: Word = $FFFF); overload;
    procedure Line(x1, y1, x2, y2: Single; aCol: TColor4; aPattern: Word = $FFFF); overload;
    procedure Triangle(x1, y1, x2, y2, X3, Y3: Single; aCol: TColor4);
    procedure TriangleOnTerrain(x1, y1, x2, y2, X3, Y3: Single; aCol: TColor4);
    procedure TileTerrainIDs(const aRect: TKMRect);
    procedure TileTerrainKinds(const aRect: TKMRect);
    procedure Passability(const aRect: TKMRect; aPass: Byte);
    procedure RenderResizeMap(const aExceptRect: TKMRect);
    procedure Projectile(x1, y1, x2, y2: Single);
    procedure Quad(pX, pY: Integer; aCol: TColor4);
    procedure SquareOnTerrain(x1, y1, x2, y2: Single; aLineColor: TColor4);
    procedure Text(pX, pY: Single; const aText: string; aCol: TColor4); overload;
    procedure Text(pX, pY: Single; const aText: string; aCol: TColor4; const aInset: TKMPointF; aConsiderTextLength: Boolean = True); overload;
    procedure TextAtCorner(pX, pY: Integer; const aCorner: Byte; const aText: string; aCol: TColor4);
    procedure UnitMoves(const aRect: TKMRect);
    procedure UnitPointers(pX, pY: Single; Count: Integer);
    procedure UnitRoute(NodeList: TKMPointList; Pos: Integer; aUnitType: Byte);
    procedure Wires(const aRect: TKMRect);
  end;


var
  gRenderAux: TRenderAux;


implementation
uses
  KM_Render, KM_Game, KM_Terrain, KM_Resource, KM_ResTileset;

const
  TILE_TERRAIN_LAYERS_COLORS: array [0..3] of Cardinal =
    (icWhite, icLightCyan, icCyan, icDarkCyan);


//Simple dot to know where it actualy is
procedure TRenderAux.RenderDot(pX, pY: Single; Size: Single = 0.05);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  //Render as quad to control the size of it
  glBegin(GL_QUADS);
    glkRect(pX - Size, pY + Size, pX + Size, pY - Size);
  glEnd;
end;


procedure TRenderAux.RenderDotOnTile(pX, pY: Single);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  pY := gTerrain.FlatToHeight(pX, pY);
  glBegin(GL_QUADS);
    glkRect(pX, pY, pX + 0.1, pY - 0.1);
  glEnd;
end;


procedure TRenderAux.RenderLine(x1, y1, x2, y2: Single);
begin
  // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  TRender.BindTexture(0);
  glBegin(GL_LINES);
    glVertex2f(x1, gTerrain.FlatToHeight(x1, y1));
    glVertex2f(x2, gTerrain.FlatToHeight(x2, y2));
  glEnd;
end;


procedure TRenderAux.RenderQuad(pX, pY: Integer);
begin
  if not gTerrain.TileInMapCoords(pX, pY) then exit;

  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glBegin(GL_QUADS);
    with gTerrain do
    glkQuad(pX-1,pY-1-Land[pY  ,pX  ].Height/CELL_HEIGHT_DIV,
            pX  ,pY-1-Land[pY  ,pX+1].Height/CELL_HEIGHT_DIV,
            pX  ,pY-  Land[pY+1,pX+1].Height/CELL_HEIGHT_DIV,
            pX-1,pY-  Land[pY+1,pX  ].Height/CELL_HEIGHT_DIV);
  glEnd;
end;


procedure TRenderAux.Circle(x, y, rad: Single; Fill, Line: TColor4);
const
  SEC_COUNT = 20;
var
  I: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glPushMatrix;
    glTranslatef(X, Y, 0);
    glColor4ubv(@Fill);
    glBegin(GL_POLYGON);
      for I := -SEC_COUNT to SEC_COUNT do
        glVertex2f(Cos(I/SEC_COUNT*pi)*Rad, Sin(I/SEC_COUNT*pi)*Rad);//-1..1
    glEnd;
    glBegin(GL_POLYGON);
      for I := -SEC_COUNT to SEC_COUNT do
        glVertex2f(Cos(I/SEC_COUNT*pi)*Rad/3, Sin(I/SEC_COUNT*pi)*Rad/3);//-1..1
    glEnd;
    glColor4ubv(@Line);
    glBegin(GL_LINE_STRIP);
      for I := -SEC_COUNT to SEC_COUNT do
        glVertex2f(Cos(I/SEC_COUNT*pi)*Rad, Sin(I/SEC_COUNT*pi)*Rad);//-1..1
    glEnd;
  glPopMatrix;
end;


procedure TRenderAux.CircleOnTerrain(X, Y, Rad: Single; Fill, Line: TColor4);
const
  SEC_COUNT = 24;
var
  I: Integer;
  C,S: Single;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@Fill);
  glBegin(GL_POLYGON);
    for I := -SEC_COUNT to SEC_COUNT - 1 do
    begin
      C := Cos(I / SEC_COUNT * Pi) * Rad;
      S := Sin(I / SEC_COUNT * Pi) * Rad;
      glVertex2f(X + C, gTerrain.FlatToHeight(X + C, Y + S));
    end;
  glEnd;
  glColor4ubv(@Line);
  glBegin(GL_LINE_LOOP);
    for I := -SEC_COUNT to SEC_COUNT - 1 do
    begin
      C := Cos(I / SEC_COUNT * Pi) * Rad;
      S := Sin(I / SEC_COUNT * Pi) * Rad;
      glVertex2f(X + C, gTerrain.FlatToHeight(X + C, Y + S));
    end;
  glEnd;
end;


procedure TRenderAux.SquareOnTerrain(X1, Y1, X2, Y2: Single; aLineColor: TColor4);
var
  I: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aLineColor);
  glBegin(GL_LINE_LOOP);
    glVertex2f(X1, gTerrain.FlatToHeight(X1, Y1));
    for I := Ceil(X1) to Trunc(X2) do
      glVertex2f(I, gTerrain.FlatToHeight(I, Y1));
    glVertex2f(X2, gTerrain.FlatToHeight(X2, Y1));

    glVertex2f(X2, gTerrain.FlatToHeight(X2, Y2));
    for I := Trunc(X2) downto Ceil(X1) do
      glVertex2f(I, gTerrain.FlatToHeight(I, Y2));
    glVertex2f(X1, gTerrain.FlatToHeight(X1, Y2));
  glEnd;
end;


procedure TRenderAux.Dot(X,Y: Single; aCol: TColor4; aSize: Single = 0.05);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  RenderDot(X, Y, aSize);
end;


procedure TRenderAux.DotOnTerrain(x, y: Single; aCol: TColor4);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  RenderDot(X,gTerrain.FlatToHeight(X, Y));
end;


procedure TRenderAux.LineOnTerrain(x1, y1, x2, y2: Single; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  glEnable(GL_LINE_STIPPLE);
  glLineStipple(2, aPattern);
  RenderLine(X1,Y1,X2,Y2);
  glDisable(GL_LINE_STIPPLE);
  if aDots then
  begin
    RenderDot(X1, gTerrain.FlatToHeight(X1, Y1));
    RenderDot(X2, gTerrain.FlatToHeight(X2, Y2));
  end;
end;


procedure TRenderAux.LineOnTerrain(const A,B: TKMPoint; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True);
begin
  LineOnTerrain(A.X, A.Y, B.X, B.Y, aCol, aPattern, aDots);
end;


procedure TRenderAux.LineOnTerrain(const A,B: TKMPointF; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True);
begin
  LineOnTerrain(A.X, A.Y, B.X, B.Y, aCol, aPattern, aDots);
end;


procedure TRenderAux.Line(const A, B: TKMPoint; aCol: TColor4; aPattern: Word = $FFFF);
begin
  Line(A.X, A.Y, B.X, B.Y, aCol, aPattern);
end;


procedure TRenderAux.Line(const A, B: TKMPointF; aCol: TColor4; aPattern: Word = $FFFF);
begin
  Line(A.X, A.Y, B.X, B.Y, aCol, aPattern);
end;


procedure TRenderAux.Line(X1,Y1,X2,Y2: Single; aCol: TColor4; aPattern: Word = $FFFF);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);

  glEnable(GL_LINE_STIPPLE);
  glLineStipple(2, aPattern);

  glBegin(GL_LINES);
    glVertex2f(x1, y1);
    glVertex2f(x2, y2);
  glEnd;
  glDisable(GL_LINE_STIPPLE);

  RenderDot(X1, Y1);
  RenderDot(X2, Y2);
end;


procedure TRenderAux.Triangle(x1, y1, x2, y2, X3, Y3: Single; aCol: TColor4);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);

  glBegin(GL_TRIANGLES);
    glVertex2f(x1, y1);
    glVertex2f(x2, y2);
    glVertex2f(x3, y3);
  glEnd;
end;


procedure TRenderAux.TriangleOnTerrain(x1, y1, x2, y2, X3, Y3: Single; aCol: TColor4);
begin
  glColor4ubv(@aCol);

  glBegin(GL_TRIANGLES);
    glVertex2f(x1, gTerrain.FlatToHeight(x1, y1));
    glVertex2f(x2, gTerrain.FlatToHeight(x2, y2));
    glVertex2f(x3, gTerrain.FlatToHeight(x3, y3));
  glEnd;
end;


procedure TRenderAux.TileTerrainIDs(const aRect: TKMRect);
var
  I, J, K, Cnt: Integer;
  CustomStr: String;
begin

  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    begin
      CustomStr := '';
      if gTerrain.Land[I,J].IsCustom then
        CustomStr := '-C';
      if gTerrain.Land[I,J].LayersCnt = 0 then
        Text(J, I, IntToStr(gTerrain.Land[I,J].BaseLayer.Terrain)+ '-' + IntToStr(gTerrain.Land[I,J].BaseLayer.Rotation) + CustomStr,
             TILE_TERRAIN_LAYERS_COLORS[0])
      else begin
        Cnt := gTerrain.Land[I,J].LayersCnt + 1;
        Text(J, I, IntToStr(gTerrain.Land[I,J].BaseLayer.Terrain) + '-' + IntToStr(gTerrain.Land[I,J].BaseLayer.Rotation) + CustomStr,
             TILE_TERRAIN_LAYERS_COLORS[0], KMPointF(0,-0.3));
        for K := 0 to gTerrain.Land[I,J].LayersCnt - 1 do
          Text(J, I, IntToStr(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(gTerrain.Land[I,J].Layer[K].Terrain).TerKind])
                     + '*' + IntToStr(gTerrain.Land[I,J].Layer[K].Rotation),
               TILE_TERRAIN_LAYERS_COLORS[K+1], KMPointF(0,-0.3 + 0.7*(K+1)/Cnt));
      end;
    end;
end;


procedure TRenderAux.TileTerrainKinds(const aRect: TKMRect);

  procedure DrawTerKind(X,Y: Integer);
  var
    TerKind: TKMTerrainKind;
    TerKindStr: String;
  begin
    if gGame.IsMapEditor then
    begin
      TerKind := gGame.MapEditor.TerrainPainter.LandTerKind[Y,X].TerKind;
      case TerKind of
        tkCustom: TerKindStr := 'C';
        else      TerKindStr := IntToStr(BASE_TERRAIN[TerKind]);
      end;
      Text(X - 0.47, Y - 0.47, TerKindStr, icRed);
    end;
  end;

var
  I, J, K, L: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    begin
      DrawTerKind(J,I);
      for K := 0 to 3 do
        with gTerrain.Land[I,J] do
        begin
          if K in BaseLayer.Corners then
            TextAtCorner(J, I, K,
                         IntToStr(BASE_TERRAIN[TILE_CORNERS_TERRAIN_KINDS[BaseLayer.Terrain, (K + 4 - BaseLayer.Rotation) mod 4]]),
                         TILE_TERRAIN_LAYERS_COLORS[0]);
          for L := 0 to LayersCnt - 1 do
            if K in Layer[L].Corners then
              TextAtCorner(J, I, K,
                           IntToStr(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain).TerKind]),
                           TILE_TERRAIN_LAYERS_COLORS[L+1]);
        end;
    end;
  for I := aRect.Top to aRect.Bottom + 1 do
    DrawTerKind(aRect.Right + 1,I);
  for J := aRect.Left to aRect.Right do
    DrawTerKind(J,aRect.Bottom + 1 );
end;


procedure TRenderAux.Passability(const aRect: TKMRect; aPass: Byte);
var
  I, K: Integer;
begin
  if aPass <> 0 then
  begin
    glColor4f(0,1,0,0.25);
    for I := aRect.Top to aRect.Bottom do
      for K := aRect.Left to aRect.Right do
        if TKMTerrainPassability(aPass) in gTerrain.Land[I,K].Passability then
          RenderQuad(K,I);
  end;
end;


procedure TRenderAux.RenderResizeMap(const aExceptRect: TKMRect);
var
  I, K: Integer;
begin
  glColor4f(1,0,0,0.15);
  for I := 1 to gTerrain.MapY - 1 do
    for K := 1 to gTerrain.MapX - 1 do
      if not KMInRect(KMPoint(K,I), aExceptRect) then
        RenderQuad(K,I);
end;


procedure TRenderAux.Projectile(x1, y1, x2, y2: Single);
begin
  glColor4f(1, 1, 0, 1);
  RenderDot(x1, y1);
  glColor4f(1, 0, 0, 1);
  RenderDot(x2, y2, 0.1);
  RenderLine(x1, y1, x2, y2);
end;


procedure TRenderAux.Quad(pX, pY: Integer; aCol: TColor4);
begin
  glColor4ubv(@aCol);
  RenderQuad(pX, pY);
end;


procedure TRenderAux.Text(pX, pY: Single; const aText: string; aCol: TColor4);
begin
  Text(pX, pY, aText, aCol, KMPOINTF_ZERO);
end;


procedure TRenderAux.Text(pX, pY: Single; const aText: string; aCol: TColor4; const aInset: TKMPointF; aConsiderTextLength: Boolean = True);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  glRasterPos2f(pX + aInset.X - 0.5 - Byte(aConsiderTextLength)*Length(aText)/20, gTerrain.FlatToHeight(pX + aInset.X - 0.5, pY + aInset.Y - 0.5));
  glPrint(AnsiString(aText));
end;


procedure TRenderAux.TextAtCorner(pX, pY: Integer; const aCorner: Byte; const aText: string; aCol: TColor4);
begin
  case aCorner of
    0:  Text(pX - 0.3, pY - 0.3, aText, aCol, KMPOINTF(0.02, 0.02));
    1:  Text(pX + 0.3, pY - 0.3, aText, aCol, KMPOINTF(0.02, 0.02));
    2:  Text(pX + 0.3, pY + 0.3, aText, aCol, KMPOINTF(0.02, 0.02));
    3:  Text(pX - 0.3, pY + 0.3, aText, aCol, KMPOINTF(0.02, 0.02));
    else raise Exception.Create('Wrong corner: ' + IntToStr(aCorner));
  end;
end;


procedure TRenderAux.UnitMoves(const aRect: TKMRect);
var
  I, K: Integer;
  VertexUsage: Byte;
begin
  for I := aRect.Top to aRect.Bottom do
  for K := aRect.Left to aRect.Right do
  begin
    if gTerrain.Land[I,K].IsVertexUnit <> vuNone then
    begin
      VertexUsage := byte(gTerrain.Land[I,K].IsVertexUnit);
      glColor4f(1-VertexUsage/3, VertexUsage/3, 0.6, 0.8);
      RenderDot(K, gTerrain.FlatToHeight(K,I), 0.3);
    end;
    if gTerrain.Land[I,K].IsUnit <> nil then
    begin
      glColor4f(0.17, 0.83, 0, 0.8);
      RenderQuad(K,I);
    end;
  end;
end;


procedure TRenderAux.UnitPointers(pX,pY: Single; Count: Integer);
var
  I: Integer;
begin
  for I := 1 to Count do
    RenderDot(pX+I/5, gTerrain.FlatToHeight(pX,pY));
end;


procedure TRenderAux.UnitRoute(NodeList: TKMPointList; Pos: Integer; aUnitType: Byte);
var
  I, K: Integer;
  FaceX, FaceY: Single;
begin
  if NodeList.Count = 0 then Exit;
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  case aUnitType of
    1: glColor3f(1,0,0); //Serf
    10: glColor3f(1,0,1); //Worker
    15..30: glColor3f(0,1,0); //Army
    31..38: glColor3f(0,0.5,0); //Animals
    else glColor3f(1,1,0); //Citizens
  end;

  for I := 0 to NodeList.Count - 1 do
    RenderDotOnTile(NodeList[I].X + 0.5, NodeList[I].Y + 0.5);

  glBegin(GL_LINE_STRIP);
    for I := 0 to NodeList.Count - 1 do
      glVertex2f(NodeList[I].X-0.5, gTerrain.FlatToHeight(NodeList[I].X-0.5, NodeList[I].Y-0.5));
  glEnd;

  glColor4f(1,1,1,1); //Vector where unit is going to
  I := Pos;
  K := Min(Pos + 1, NodeList.Count - 1);
  FaceX := Mix(NodeList[I].X - 0.5, NodeList[K].X - 0.5, 0.4);
  FaceY := Mix(NodeList[I].Y - 0.5, NodeList[K].Y - 0.5, 0.4) + 0.2; //0.2 to render vector a bit lower so it won't gets overdrawned by another route
  RenderDotOnTile(NodeList[I].X + 0.5, NodeList[I].Y + 0.5 + 0.2);
  glBegin(GL_LINES);
    glVertex2f(NodeList[I].X-0.5, gTerrain.FlatToHeight(NodeList[I].X+0.5,NodeList[I].Y+0.5) + 0.2);
    glVertex2f(FaceX, gTerrain.FlatToHeight(FaceX+1, FaceY+1));
  glEnd;
end;


procedure TRenderAux.Wires(const aRect: TKMRect);
var
  I, K: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  for I := aRect.Top to aRect.Bottom + 1 do
  begin
    glBegin(GL_LINE_STRIP);
    for K := aRect.Left to aRect.Right + 1 do
    begin
      glColor4f(0.8, 1, 0.6, 1);
      glVertex2d(K - 1, I - 1 - gTerrain.Land[I, K].Height / CELL_HEIGHT_DIV);
    end;
    glEnd;
  end;

  glPushAttrib(GL_POINT_BIT);
    glPointSize(3);
    glBegin(GL_POINTS);
    for I := aRect.Top to aRect.Bottom + 1 do
    for K := aRect.Left to aRect.Right + 1 do
    begin
      //glColor4f(gTerrain.Land[I,K].Height/100,0,0,1.2-sqrt(sqr(I-MapYc)+sqr(K-MapXc))/10);
      glColor4f(Byte(gTerrain.Land[I,K].Fence = fncHousePlan), Byte(gTerrain.Land[I,K].Fence = fncHousePlan), 0, 1);
      glVertex2d(K - 1, I - 1 - gTerrain.Land[I, K].Height / CELL_HEIGHT_DIV);
    end;
    glEnd;
  glPopAttrib;
end;


end.

unit KM_RenderAux;
{$I KaM_Remake.inc}
interface
uses
  dglOpenGL, SysUtils, KromOGLUtils, KromUtils, Math,
  KM_Defaults, KM_CommonClasses, KM_CommonTypes, KM_Points;

type
  TKMLineMode = (lmStrip, lmPairs);

  //Debug symbols render
  TRenderAux = class
  private
    procedure RenderDot(pX, pY: Single; Size: Single = 0.05);
    procedure RenderDotOnTile(pX, pY: Single; aSize: Single = 0.1);
    procedure RenderLine(x1, y1, x2, y2: Single);
    procedure RenderQuad(pX, pY: Integer); overload;
    procedure RenderQuad(pX, pY: Single); overload;
  public
    procedure Circle(x, y, rad: Single; Fill, Line: TColor4);
    procedure CircleOnTerrain(x, y, rad: Single; Fill, Line: TColor4); overload;
    procedure CircleOnTerrain(X, Y, Rad: Single; aColor: TColor4); overload;
    procedure Dot(x, y: Single; aCol: TColor4; aSize: Single = 0.05);
    procedure DotOnTerrain(x, y: Single; aCol: TColor4; aSize: Single = 0.05);
    procedure LineOnTerrain(x1, y1, x2, y2: Single; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True); overload;
    procedure LineOnTerrain(const A, B: TKMPoint; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True); overload;
    procedure LineOnTerrain(const A, B: TKMPointF; aCol: TColor4; aPattern: Word = $FFFF; aDots: Boolean = True); overload;
    procedure LineOnTerrain(const aPoints: TKMPointArray; aColor: Cardinal; aThickness: Integer = -1; aLineMode: TKMLineMode = lmStrip; aPattern: Word = $FFFF); overload;
    procedure LineOnTerrain(const aPoints: TKMPointFArray; aColor: Cardinal; aThickness: Integer = -1; aLineMode: TKMLineMode = lmStrip; aPattern: Word = $FFFF); overload;
    procedure LineOnTerrain(aPoints: TKMPointList; aColor: Cardinal; aInset: Single = 0; aThickness: Integer = -1;
                            aLineMode: TKMLineMode = lmStrip; aPattern: Word = $FFFF); overload;
    procedure Line(const A, B: TKMPoint; aCol: TColor4; aPattern: Word = $FFFF); overload;
    procedure Line(const A, B: TKMPointF; aCol: TColor4; aPattern: Word = $FFFF); overload;
    procedure Line(x1, y1, x2, y2: Single; aCol: TColor4; aPattern: Word = $FFFF); overload;
    procedure Line(const aPoints: TKMPointFArray; aColor: TKMColor4f; aThickness: Integer = -1; aLineMode: TKMLineMode = lmStrip; aPattern: Word = $FFFF); overload;
    procedure Triangle(x1, y1, x2, y2, X3, Y3: Single; aCol: TColor4);
    procedure TriangleOnTerrain(x1, y1, x2, y2, X3, Y3: Single; aCol: TColor4);
    procedure TileTerrainIDs(const aRect: TKMRect);
    procedure TileTerrainKinds(const aRect: TKMRect);
    procedure TileTerrainOverlays(const aRect: TKMRect);
    procedure TileTerrainJamMeter(const aRect: TKMRect);
    procedure TileTerrainHeight(const aRect: TKMRect);
    procedure TileTerrainTileObjectID(const aRect: TKMRect);
    procedure TileTerrainTileLock(const aRect: TKMRect);
    procedure TileTerrainTileUnit(const aRect: TKMRect);
    procedure TileTerrainVertexUnit(const aRect: TKMRect);
    procedure TileTerrainTreeAge(const aRect: TKMRect);
    procedure TileTerrainFieldAge(const aRect: TKMRect);
    procedure Passability(const aRect: TKMRect; aPass: Byte);
    procedure RenderResizeMap(const aExceptRect: TKMRect);
    procedure Projectile(x1, y1, x2, y2: Single);
    procedure SetColor(aCol: Cardinal);
    procedure Quad(pX, pY: Integer); overload;
    procedure Quad(pX, pY: Integer; aCol: TColor4); overload;
    procedure Quad(pX, pY: Single); overload;
    procedure Quad(pX, pY: Single; aCol: TColor4); overload;
    procedure SquareOnTerrain(x1, y1, x2, y2: Single; aLineColor: TColor4);
    procedure Text(pX, pY: Single; const aText: string; aCol: TColor4); overload;
    procedure Text(pX, pY: Single; const aText: string; aCol: TColor4; const aInset: TKMPointF; aConsiderTextLength: Boolean = True); overload;
    procedure TextAtCorner(pX, pY: Integer; const aCorner: Byte; const aText: string; aCol: TColor4);
    procedure UnitMoves(const aRect: TKMRect);
    procedure UnitPointers(pX, pY: Single; Count: Integer);
    procedure UnitRoute(NodeList: TKMPointList; Pos: Integer; aUID: Integer);
    procedure Wires(const aRect: TKMRect);
    procedure RenderWireTile(const P: TKMPoint; Col: TColor4; aInset: Single = 0.0);
  end;


var
  gRenderAux: TRenderAux;


implementation
uses
  KM_Render, KM_Game, KM_GameParams, KM_Units, KM_Terrain, KM_TerrainTypes, KM_Resource, KM_ResTileset, KM_CommonUtils;

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


procedure TRenderAux.RenderDotOnTile(pX, pY: Single; aSize: Single = 0.1);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  pY := gTerrain.RenderFlatToHeight(pX, pY);
  glBegin(GL_QUADS);
    glkRect(pX - aSize/2, pY + aSize/2, pX + aSize/2, pY - aSize/2);
  glEnd;
end;


procedure TRenderAux.RenderLine(x1, y1, x2, y2: Single);
begin
  // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  TRender.BindTexture(0);
  glBegin(GL_LINES);
    glVertex2f(x1, gTerrain.RenderFlatToHeight(x1, y1));
    glVertex2f(x2, gTerrain.RenderFlatToHeight(x2, y2));
  glEnd;
end;


procedure TRenderAux.RenderQuad(pX, pY: Integer);
begin
  if not gTerrain.TileInMapCoords(pX, pY) then Exit;

  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glBegin(GL_QUADS);
    with gTerrain do
    glkQuad(pX-1,pY-1-Land^[pY  ,pX  ].RenderHeight/CELL_HEIGHT_DIV,
            pX  ,pY-1-Land^[pY  ,pX+1].RenderHeight/CELL_HEIGHT_DIV,
            pX  ,pY-  Land^[pY+1,pX+1].RenderHeight/CELL_HEIGHT_DIV,
            pX-1,pY-  Land^[pY+1,pX  ].RenderHeight/CELL_HEIGHT_DIV);
  glEnd;
end;


procedure TRenderAux.RenderQuad(pX, pY: Single);
var
  rect: TKMRectF;
begin
  rect := KMRectF(pX - 1, pY - 1, pX, pY);

  rect := gTerrain.EnsureVerticesRectWithinMap(rect);

  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glBegin(GL_QUADS);
    with gTerrain do
    glkQuad(rect.Left,  gTerrain.RenderFlatToHeight(rect.Left,  rect.Top),
            rect.Right, gTerrain.RenderFlatToHeight(rect.Right, rect.Top),
            rect.Right, gTerrain.RenderFlatToHeight(rect.Right, rect.Bottom),
            rect.Left,  gTerrain.RenderFlatToHeight(rect.Left,  rect.Bottom));
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


procedure TRenderAux.CircleOnTerrain(X, Y, Rad: Single; aColor: TColor4);
begin
  CircleOnTerrain(X, Y, Rad, aColor, aColor);
end;


procedure TRenderAux.CircleOnTerrain(X, Y, Rad: Single; Fill, Line: TColor4);
const
  SEC_COUNT = 24;
var
  I: Integer;
  C, S: Single;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@Fill);
  glBegin(GL_POLYGON);
    for I := -SEC_COUNT to SEC_COUNT - 1 do
    begin
      C := Cos(I / SEC_COUNT * Pi) * Rad;
      S := Sin(I / SEC_COUNT * Pi) * Rad;
      glVertex2f(X + C, gTerrain.RenderFlatToHeight(X + C, Y + S));
    end;
  glEnd;
  glColor4ubv(@Line);
  glBegin(GL_LINE_LOOP);
    for I := -SEC_COUNT to SEC_COUNT - 1 do
    begin
      C := Cos(I / SEC_COUNT * Pi) * Rad;
      S := Sin(I / SEC_COUNT * Pi) * Rad;
      glVertex2f(X + C, gTerrain.RenderFlatToHeight(X + C, Y + S));
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
    glVertex2f(X1, gTerrain.RenderFlatToHeight(X1, Y1));
    for I := Ceil(X1) to Trunc(X2) do
      glVertex2f(I, gTerrain.RenderFlatToHeight(I, Y1));
    glVertex2f(X2, gTerrain.RenderFlatToHeight(X2, Y1));

    glVertex2f(X2, gTerrain.RenderFlatToHeight(X2, Y2));
    for I := Trunc(X2) downto Ceil(X1) do
      glVertex2f(I, gTerrain.RenderFlatToHeight(I, Y2));
    glVertex2f(X1, gTerrain.RenderFlatToHeight(X1, Y2));
  glEnd;
end;


procedure TRenderAux.Dot(X,Y: Single; aCol: TColor4; aSize: Single = 0.05);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  RenderDot(X, Y, aSize);
end;


procedure TRenderAux.DotOnTerrain(x, y: Single; aCol: TColor4; aSize: Single = 0.05);
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  RenderDot(X, gTerrain.RenderFlatToHeight(X, Y), aSize);
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
    RenderDot(X1, gTerrain.RenderFlatToHeight(X1, Y1));
    RenderDot(X2, gTerrain.RenderFlatToHeight(X2, Y2));
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


procedure TRenderAux.Line(const aPoints: TKMPointFArray; aColor: TKMColor4f; aThickness: Integer = -1; aLineMode: TKMLineMode = lmStrip;
                          aPattern: Word = $FFFF);
var
  I, lineWidth: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  if aThickness <> -1 then
  begin
    glGetIntegerv(GL_LINE_WIDTH, @lineWidth);
    glLineWidth(aThickness);
  end;

  glColor4f(aColor.R, aColor.G, aColor.B, aColor.A);

  case aLineMode of
    lmStrip:  glBegin(GL_LINE_STRIP);
    lmPairs:  glBegin(GL_LINES);
    else      raise Exception.Create('Wrong LineMode');
  end;

  for I := 0 to High(aPoints) do
    glVertex2f(aPoints[I].X, aPoints[I].Y);

  glEnd;

  // Restore previous value for line width
  if aThickness <> -1 then
    glLineWidth(lineWidth);
end;


procedure TRenderAux.LineOnTerrain(const aPoints: TKMPointFArray; aColor: Cardinal; aThickness: Integer = -1;
                                   aLineMode: TKMLineMode = lmStrip; aPattern: Word = $FFFF);
var
  I, lineWidth: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  if aThickness <> -1 then
  begin
    glGetIntegerv(GL_LINE_WIDTH, @lineWidth);
    glLineWidth(aThickness);
  end;

  glColor4ubv(@aColor);
//  glColor4f(aColor.R, aColor.G, aColor.B, aColor.A);

  case aLineMode of
    lmStrip:  glBegin(GL_LINE_STRIP);
    lmPairs:  glBegin(GL_LINES);
    else      raise Exception.Create('Wrong LineMode');
  end;

  for I := 0 to High(aPoints) do
    glVertex2f(aPoints[I].X, gTerrain.RenderFlatToHeight(aPoints[I].X, aPoints[I].Y));

  glEnd;

  // Restore previous value for line width
  if aThickness <> -1 then
    glLineWidth(lineWidth);
end;


procedure TRenderAux.LineOnTerrain(const aPoints: TKMPointArray; aColor: Cardinal; aThickness: Integer;
                                   aLineMode: TKMLineMode; aPattern: Word);
var
  I, lineWidth: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  if aThickness <> -1 then
  begin
    glGetIntegerv(GL_LINE_WIDTH, @lineWidth);
    glLineWidth(aThickness);
  end;

  glColor4ubv(@aColor);
//  glColor4f(aColor.R, aColor.G, aColor.B, aColor.A);

  case aLineMode of
    lmStrip:  glBegin(GL_LINE_STRIP);
    lmPairs:  glBegin(GL_LINES);
    else      raise Exception.Create('Wrong LineMode');
  end;

  for I := 0 to High(aPoints) do
    glVertex2f(aPoints[I].X, gTerrain.RenderFlatToHeight(aPoints[I].X, aPoints[I].Y));

  glEnd;

  // Restore previous value for line width
  if aThickness <> -1 then
    glLineWidth(lineWidth);
end;


procedure TRenderAux.LineOnTerrain(aPoints: TKMPointList; aColor: Cardinal; aInset: Single = 0; aThickness: Integer = -1;
                                   aLineMode: TKMLineMode = lmStrip; aPattern: Word = $FFFF);
var
  I, lineWidth: Integer;
begin
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  if aThickness <> -1 then
  begin
    glGetIntegerv(GL_LINE_WIDTH, @lineWidth);
    glLineWidth(aThickness);
  end;

  glColor4ubv(@aColor);
//  glColor4f(aColor.R, aColor.G, aColor.B, aColor.A);

  case aLineMode of
    lmStrip:  glBegin(GL_LINE_STRIP);
    lmPairs:  glBegin(GL_LINES);
    else      raise Exception.Create('Wrong LineMode');
  end;

  for I := 0 to aPoints.Count - 1 do
    glVertex2f(aPoints[I].X + aInset, gTerrain.RenderFlatToHeight(aPoints[I].X + aInset, aPoints[I].Y + aInset));

  glEnd;

  // Restore previous value for line width
  if aThickness <> -1 then
    glLineWidth(lineWidth);

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
  TRender.BindTexture(0);
  glColor4ubv(@aCol);

  glBegin(GL_TRIANGLES);
    glVertex2f(x1, gTerrain.RenderFlatToHeight(x1, y1));
    glVertex2f(x2, gTerrain.RenderFlatToHeight(x2, y2));
    glVertex2f(x3, gTerrain.RenderFlatToHeight(x3, y3));
  glEnd;
end;


procedure TRenderAux.TileTerrainIDs(const aRect: TKMRect);
var
  I, J, K, cnt: Integer;
  customStr: String;
begin

  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    begin
      customStr := '';
      if gTerrain.Land^[I,J].IsCustom then
        customStr := '-C';
      customStr := customStr + '-' + IntToStr(gTerrain.Land^[I,J].BlendingLvl);
      if gTerrain.Land^[I,J].HasNoLayers then
        Text(J, I, IntToStr(gTerrain.Land^[I,J].BaseLayer.Terrain)+ '-' + IntToStr(gTerrain.Land^[I,J].BaseLayer.Rotation) + customStr,
             TILE_TERRAIN_LAYERS_COLORS[0])
      else
      begin
        cnt := gTerrain.Land^[I,J].LayersCnt + 1;
        Text(J, I, IntToStr(gTerrain.Land^[I,J].BaseLayer.Terrain) + '-' + IntToStr(gTerrain.Land^[I,J].BaseLayer.Rotation) + customStr,
             TILE_TERRAIN_LAYERS_COLORS[0], KMPointF(0,-0.3));
        for K := 0 to gTerrain.Land^[I,J].LayersCnt - 1 do
          Text(J, I, IntToStr(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(gTerrain.Land^[I,J].Layer[K].Terrain).TerKind])
                     + '*' + IntToStr(gTerrain.Land^[I,J].Layer[K].Rotation),
               TILE_TERRAIN_LAYERS_COLORS[K+1], KMPointF(0,-0.3 + 0.7*(K+1)/cnt));
      end;
    end;
end;


procedure TRenderAux.TileTerrainKinds(const aRect: TKMRect);

  procedure DrawTerKind(X,Y: Integer);
  var
    terKind: TKMTerrainKind;
    terKindStr: String;
  begin
    if gGameParams.IsMapEditor then
    begin
      terKind := gGame.TerrainPainter.LandTerKind[Y,X].TerKind;
      case terKind of
        tkCustom: terKindStr := 'C';
        else      terKindStr := IntToStr(BASE_TERRAIN[terKind]);
      end;
      Text(X - 0.47, Y - 0.47, terKindStr, icRed);
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
        with gTerrain.Land^[I,J] do
        begin
          if BaseLayer.Corner[K] then
            TextAtCorner(J, I, K,
                         IntToStr(BASE_TERRAIN[TILE_CORNERS_TERRAIN_KINDS[BaseLayer.Terrain, (K + 4 - BaseLayer.Rotation) mod 4]]),
                         TILE_TERRAIN_LAYERS_COLORS[0]);
          for L := 0 to LayersCnt - 1 do
            if Layer[L].Corner[K] then
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


procedure TRenderAux.TileTerrainOverlays(const aRect: TKMRect);
var
  I, J: Integer;
  str: string;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    begin
      str := IntToStr(Byte(gTerrain.Land^[I,J].TileOverlay));
      if gGame.Params.IsMapEditor and (gGame.MapEditor.LandMapEd^[I,J].CornOrWine > 0) then
        str := str + '-' + IntToStr(gGame.MapEditor.LandMapEd^[I,J].CornOrWineTerrain);
      Text(J, I, str, icDarkPink);
    end;
end;


procedure TRenderAux.TileTerrainTileLock(const aRect: TKMRect);
const
  TILE_LOCK_STR: array[TKMTileLock] of string = ('', 'Fenced', 'Digged', 'House', 'FieldW', 'RoadW');
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      Text(J, I, TILE_LOCK_STR[gTerrain.Land^[I,J].TileLock], icCyan);
end;

procedure TRenderAux.TileTerrainTileObjectID(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      Text(J, I, IntToStr(gTerrain.Land^[I,J].Obj), icCyan);
end;

procedure TRenderAux.TileTerrainTileUnit(const aRect: TKMRect);
var
  I, J: Integer;
  color: Cardinal;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      if gTerrain.Land^[I,J].IsUnit <> nil then
      begin
        color := GetRandomColorWSeed(TKMUnit(gTerrain.Land^[I,J].IsUnit).UID);
        Quad(J, I, $80FFFFFF and color);
      end;
end;


procedure TRenderAux.TileTerrainVertexUnit(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      case gTerrain.Land^[I,J].IsVertexUnit of
        vuNone: ;
        vuNWSE: LineOnTerrain(J - 0.5, I - 0.5, J - 1.5, I - 1.5, icBlue);
        vuNESW: LineOnTerrain(J - 1.5, I - 0.5, J - 0.5, I - 1.5, icBlue);
      end;
end;


procedure TRenderAux.TileTerrainTreeAge(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      Text(J, I, IntToStr(gTerrain.Land^[I,J].TreeAge), icCyan);
end;


procedure TRenderAux.TileTerrainFieldAge(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      Text(J, I, IntToStr(gTerrain.Land^[I,J].FieldAge), icCyan);
end;


procedure TRenderAux.TileTerrainJamMeter(const aRect: TKMRect);
const
  JAM_DRAW_STEP = 3;
var
  I, J, K, limit: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    begin
      if gTerrain.Land^[I,J].JamMeter = 0 then Continue;

      limit := (gTerrain.Land^[I,J].JamMeter + JAM_DRAW_STEP - 1) div JAM_DRAW_STEP;
      for K := 0 to limit - 1 do
        Quad(J, I, $20FFFFFF and icOrange);
      //Draw text over quads
      Text(J, I, IntToStr(gTerrain.Land^[I,J].JamMeter), icRed);
    end;
end;


procedure TRenderAux.TileTerrainHeight(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom + 1 do
    for J := aRect.Left to aRect.Right + 1 do
      //Use fHeight to show real height, even when 'Flat terrain' is checked
      Text(J-0.5, I-0.5, IntToStr(gTerrain.Land^[I,J].Height), icCyan);
end;


procedure TRenderAux.Passability(const aRect: TKMRect; aPass: Byte);
const
  DRAW_DOT_FOR_PASS: set of TKMTerrainPassability = [tpElevate, tpFactor];
var
  I, K: Integer;
  pass: TKMTerrainPassability;
begin
  if aPass <> 0 then
  begin
    pass := TKMTerrainPassability(aPass);
    glColor4f(0,1,0,0.25);
    for I := aRect.Top to aRect.Bottom do               
      for K := aRect.Left to aRect.Right do
        if pass in gTerrain.Land^[I,K].Passability then
        begin
          if pass = tpCutTree then
            CircleOnTerrain(K-1,I-1,0.25,$3F00FF00,icCyan) //draw circle, because dot could be hidden under Trees
          else
          if pass in DRAW_DOT_FOR_PASS then
            DotOnTerrain(K-1,I-1,icCyan)
          else
            RenderQuad(K,I);
        end;
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


procedure TRenderAux.SetColor(aCol: Cardinal);
begin
  glColor4ubv(@aCol);
end;


procedure TRenderAux.Quad(pX, pY: Integer);
begin
  RenderQuad(pX, pY);
end;


procedure TRenderAux.Quad(pX, pY: Integer; aCol: TColor4);
begin
  glColor4ubv(@aCol);
  RenderQuad(pX, pY);
end;


procedure TRenderAux.Quad(pX, pY: Single);
begin
  RenderQuad(pX, pY);
end;


procedure TRenderAux.Quad(pX, pY: Single; aCol: TColor4);
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
  if aText = '' then Exit;

  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
  glColor4ubv(@aCol);
  glRasterPos2f(pX + aInset.X - 0.5 - Byte(aConsiderTextLength)*Length(aText)/20, gTerrain.RenderFlatToHeight(pX + aInset.X - 0.5, pY + aInset.Y - 0.5));
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
  vertexUsage: Byte;
begin
  for I := aRect.Top to aRect.Bottom do
  for K := aRect.Left to aRect.Right do
  begin
    if gTerrain.Land^[I,K].IsVertexUnit <> vuNone then
    begin
      vertexUsage := byte(gTerrain.Land^[I,K].IsVertexUnit);
      glColor4f(1-vertexUsage/3, vertexUsage/3, 0.6, 0.8);
      RenderDot(K, gTerrain.RenderFlatToHeight(K,I), 0.3);
    end;
    if gTerrain.Land^[I,K].IsUnit <> nil then
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
    RenderDot(pX+I/5, gTerrain.RenderFlatToHeight(pX,pY));
end;


procedure TRenderAux.UnitRoute(NodeList: TKMPointList; Pos: Integer; aUID: Integer);
var
  I, K: Integer;
  faceX, faceY: Single;
  col: TKMColor3f;
begin
  if NodeList.Count = 0 then Exit;
  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

//  case aUnitType of
//    1: glColor3f(1,0,0); //Serf
//    10: glColor3f(1,0,1); //Worker
//    15..30: glColor3f(0,1,0); //Army
//    31..38: glColor3f(0,0.5,0); //Animals
//    else glColor3f(1,1,0); //Citizens
//  end;

  col := TKMColor3f.RandomWSeed(aUID);
  glColor3f(col.R, col.G, col.B);

  for I := 0 to NodeList.Count - 1 do
    RenderDotOnTile(NodeList[I].X + 0.5, NodeList[I].Y + 0.5);

  glBegin(GL_LINE_STRIP);
    for I := 0 to NodeList.Count - 1 do
      glVertex2f(NodeList[I].X-0.5, gTerrain.RenderFlatToHeight(NodeList[I].X-0.5, NodeList[I].Y-0.5));
  glEnd;

  for I := 0 to NodeList.Count - 1 do
    Text(NodeList[I].X, NodeList[I].Y, IntToStr(I), $FFFFFFFF);

  glColor4f(1,1,1,1); //Vector where unit is going to
  I := Pos;
  K := Min(Pos + 1, NodeList.Count - 1);
  faceX := Mix(NodeList[I].X - 0.5, NodeList[K].X - 0.5, 0.4);
  faceY := Mix(NodeList[I].Y - 0.5, NodeList[K].Y - 0.5, 0.4) + 0.2; //0.2 to render vector a bit lower so it won't gets overdrawned by another route
  RenderDotOnTile(NodeList[I].X + 0.5, NodeList[I].Y + 0.5 + 0.2);
  glBegin(GL_LINES);
    glVertex2f(NodeList[I].X-0.5, gTerrain.RenderFlatToHeight(NodeList[I].X+0.5,NodeList[I].Y+0.5) + 0.2);
    glVertex2f(faceX, gTerrain.RenderFlatToHeight(faceX+1, faceY+1));
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
      glVertex2d(K - 1, I - 1 - gTerrain.Land^[I, K].RenderHeight / CELL_HEIGHT_DIV);
    end;
    glEnd;
  end;

  glPushAttrib(GL_POINT_BIT);
    glPointSize(3);
    glBegin(GL_POINTS);
    for I := aRect.Top to aRect.Bottom + 1 do
    for K := aRect.Left to aRect.Right + 1 do
    begin
      //glColor4f(gTerrain.Land^[I,K].Height/100,0,0,1.2-sqrt(sqr(I-MapYc)+sqr(K-MapXc))/10);
      glColor4f(Byte(gTerrain.Fences[I,K].Kind = fncHousePlan), Byte(gTerrain.Fences[I,K].Kind = fncHousePlan), 0, 1);
      glVertex2d(K - 1, I - 1 - gTerrain.Land^[I, K].RenderHeight / CELL_HEIGHT_DIV);
    end;
    glEnd;
  glPopAttrib;
end;


//Render wire on tile
//P - tile coords
//Col - Color
//aInset - Internal adjustment, to render wire "inside" tile
procedure TRenderAux.RenderWireTile(const P: TKMPoint; Col: TColor4; aInset: Single = 0.0);
begin
  if not gTerrain.TileInMapCoords(P.X, P.Y) then Exit;

  TRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  glColor4ubv(@Col);
  glBegin(GL_LINE_LOOP);
    with gTerrain do begin
      glVertex2f(P.X-1 + aInset, P.Y-1 + aInset - Land^[P.Y  ,P.X  ].RenderHeight/CELL_HEIGHT_DIV);
      glVertex2f(P.X   - aInset, P.Y-1 + aInset - Land^[P.Y  ,P.X+1].RenderHeight/CELL_HEIGHT_DIV);
      glVertex2f(P.X   - aInset, P.Y   - aInset - Land^[P.Y+1,P.X+1].RenderHeight/CELL_HEIGHT_DIV);
      glVertex2f(P.X-1 + aInset, P.Y   - aInset - Land^[P.Y+1,P.X  ].RenderHeight/CELL_HEIGHT_DIV);
    end;
  glEnd;
end;


end.

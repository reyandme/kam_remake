unit KM_RenderGameAux;
{$I KaM_Remake.inc}
interface
uses
  KM_Points;

type
  // Aux render of the game
  TKMRenderGameAux = class
  public
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
  end;

var
  gRenderGameAux: TKMRenderGameAux;

implementation
uses
  dglOpenGL,
  SysUtils,
  KM_Entity,
  KM_RenderAux,
  KM_Game, KM_GameParams,
  KM_Units,
  KM_Terrain, KM_TerrainTypes,
  KM_Resource, KM_ResTilesetTypes,
  KM_Defaults, KM_CommonUtils;


const
  TILE_TERRAIN_LAYERS_COLORS: array [0..3] of Cardinal =
    (icWhite, icLightCyan, icCyan, icDarkCyan);


{ TKMRenderGameAux }
procedure TKMRenderGameAux.TileTerrainIDs(const aRect: TKMRect);
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
        gRenderAux.Text(J, I, IntToStr(gTerrain.Land^[I,J].BaseLayer.Terrain)+ '-' + IntToStr(gTerrain.Land^[I,J].BaseLayer.Rotation) + customStr,
                        TILE_TERRAIN_LAYERS_COLORS[0])
      else
      begin
        cnt := gTerrain.Land^[I,J].LayersCnt + 1;
        gRenderAux.Text(J, I, IntToStr(gTerrain.Land^[I,J].BaseLayer.Terrain) + '-' + IntToStr(gTerrain.Land^[I,J].BaseLayer.Rotation) + customStr,
                        TILE_TERRAIN_LAYERS_COLORS[0], KMPointF(0,-0.3));
        for K := 0 to gTerrain.Land^[I,J].LayersCnt - 1 do
          gRenderAux.Text(J, I, IntToStr(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(gTerrain.Land^[I,J].Layer[K].Terrain).TerKind])
                          + '*' + IntToStr(gTerrain.Land^[I,J].Layer[K].Rotation),
                          TILE_TERRAIN_LAYERS_COLORS[K+1], KMPointF(0,-0.3 + 0.7*(K+1)/cnt));
      end;
    end;
end;


procedure TKMRenderGameAux.TileTerrainKinds(const aRect: TKMRect);

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
      else
        terKindStr := IntToStr(BASE_TERRAIN[terKind]);
      end;
      gRenderAux.Text(X - 0.47, Y - 0.47, terKindStr, icRed);
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
            gRenderAux.TextAtCorner(J, I, K,
                                    IntToStr(BASE_TERRAIN[gRes.Tileset[BaseLayer.Terrain].TerKinds[(K + 4 - BaseLayer.Rotation) mod 4]]),
                                    TILE_TERRAIN_LAYERS_COLORS[0]);
          for L := 0 to LayersCnt - 1 do
            if Layer[L].Corner[K] then
              gRenderAux.TextAtCorner(J, I, K,
                                      IntToStr(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain).TerKind]),
                                      TILE_TERRAIN_LAYERS_COLORS[L+1]);
        end;
    end;
  for I := aRect.Top to aRect.Bottom + 1 do
    DrawTerKind(aRect.Right + 1,I);
  for J := aRect.Left to aRect.Right do
    DrawTerKind(J,aRect.Bottom + 1 );
end;


procedure TKMRenderGameAux.TileTerrainOverlays(const aRect: TKMRect);
var
  I, J: Integer;
  str: string;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    begin
      str := IntToStr(Ord(gTerrain.Land^[I,J].TileOverlay));
      if gGameParams.IsMapEditor and (gGame.MapEditor.LandMapEd^[I,J].CornOrWine > 0) then
        str := str + '-' + IntToStr(gGame.MapEditor.LandMapEd^[I,J].CornOrWineTerrain);
      gRenderAux.Text(J, I, str, icDarkPink);
    end;
end;


procedure TKMRenderGameAux.TileTerrainTileLock(const aRect: TKMRect);
const
  TILE_LOCK_STR: array[TKMTileLock] of string = ('', 'Fenced', 'Digged', 'House', 'FieldW', 'RoadW');
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      gRenderAux.Text(J, I, TILE_LOCK_STR[gTerrain.Land^[I,J].TileLock], icCyan);
end;


procedure TKMRenderGameAux.TileTerrainTileObjectID(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      gRenderAux.Text(J, I, IntToStr(gTerrain.Land^[I,J].Obj), icCyan);
end;


procedure TKMRenderGameAux.TileTerrainTileUnit(const aRect: TKMRect);
var
  I, J: Integer;
  color: Cardinal;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      if gTerrain.Land^[I,J].IsUnit <> nil then
      begin
        color := GetRandomColorWSeed(TKMUnit(gTerrain.Land^[I,J].IsUnit).UID);
        gRenderAux.Quad(J, I, $80FFFFFF and color);
      end;
end;


procedure TKMRenderGameAux.TileTerrainVertexUnit(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      case gTerrain.Land^[I,J].IsVertexUnit of
        vuNone: ;
        vuNWSE: gRenderAux.LineOnTerrain(J - 0.5, I - 0.5, J - 1.5, I - 1.5, icBlue);
        vuNESW: gRenderAux.LineOnTerrain(J - 1.5, I - 0.5, J - 0.5, I - 1.5, icBlue);
      end;
end;


procedure TKMRenderGameAux.TileTerrainTreeAge(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      gRenderAux.Text(J, I, IntToStr(gTerrain.Land^[I,J].TreeAge), icCyan);
end;


procedure TKMRenderGameAux.TileTerrainFieldAge(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
      gRenderAux.Text(J, I, IntToStr(gTerrain.Land^[I,J].FieldAge), icCyan);
end;


procedure TKMRenderGameAux.TileTerrainJamMeter(const aRect: TKMRect);
const
  JAM_DRAW_STEP = 3;
var
  I, J, K, limit: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for J := aRect.Left to aRect.Right do
    if gTerrain.Land^[I,J].JamMeter > 0 then
    begin

      limit := (gTerrain.Land^[I,J].JamMeter + JAM_DRAW_STEP - 1) div JAM_DRAW_STEP;
      for K := 0 to limit - 1 do
        gRenderAux.Quad(J, I, $20FFFFFF and icOrange);
      //Draw text over quads
      gRenderAux.Text(J, I, IntToStr(gTerrain.Land^[I,J].JamMeter), icRed);
    end;
end;


procedure TKMRenderGameAux.TileTerrainHeight(const aRect: TKMRect);
var
  I, J: Integer;
begin
  for I := aRect.Top to aRect.Bottom + 1 do
    for J := aRect.Left to aRect.Right + 1 do
      //Use fHeight to show real height, even when 'Flat terrain' is checked
      gRenderAux.Text(J-0.5, I-0.5, IntToStr(gTerrain.Land^[I,J].Height), icCyan);
end;


procedure TKMRenderGameAux.Passability(const aRect: TKMRect; aPass: Byte);
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
            gRenderAux.CircleOnTerrain(K-1,I-1,0.25,$3F00FF00,icCyan) //draw circle, because dot could be hidden under Trees
          else
          if pass in DRAW_DOT_FOR_PASS then
            gRenderAux.DotOnTerrain(K-1,I-1,icCyan)
          else
            gRenderAux.Quad(K,I);
        end;
  end;
end;


procedure TKMRenderGameAux.RenderResizeMap(const aExceptRect: TKMRect);
var
  I, K: Integer;
begin
  glColor4f(1,0,0,0.15);
  for I := 1 to gTerrain.MapY - 1 do
    for K := 1 to gTerrain.MapX - 1 do
      if not KMInRect(KMPoint(K,I), aExceptRect) then
        gRenderAux.Quad(K,I);
end;


end.

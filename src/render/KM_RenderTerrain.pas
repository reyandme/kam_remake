unit KM_RenderTerrain;
{$I KaM_Remake.inc}
interface
uses
  dglOpenGL,
  SysUtils, Math,
  KromUtils,
  KM_ResSprites, KM_ResTilesetTypes,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Points,
  KM_FogOfWar, KM_Pics,
  KM_TerrainTypes;

type
  TKMVBOArrayType = (vatNone, vatTile, vatTileLayer, vatAnimTile, vatFOW);

  TKMUVRect = array [1 .. 4, 1 .. 2] of Single; // Texture UV coordinates

  TKMTileVerticeExt = record
    X, Y, Z, UTile, VTile, ULit, UShd: Single;
  end;

  TKMTileFowVertice = record
    X, Y, Z, UFow: Single;
  end;

  TKMTileVertice = record
    X, Y, Z, UAnim, VAnim: Single;
  end;

  TKMTileVerticeExtArray = array of TKMTileVerticeExt;

  TKMTileFowVerticeArray = array of TKMTileFowVertice;

  TKMTileVerticeArray = array of TKMTileVertice;

  //Render terrain without sprites
  TKMRenderTerrain = class
  private
    fClipRect: TKMRect;
    fTextG: GLuint; //Shading gradient for lighting
    fTextB: GLuint; //Contrast BW for FOW over color-coder
    fUseVBO: Boolean; //Wherever to render terrain through VBO (faster but needs GL1.5) or DrawCalls (slower but needs only GL1.1)

    fTilesVtx: TKMTileVerticeExtArray;  //Vertice buffer for tiles
    fTilesVtxCount: Integer;
    fTilesInd: array of Integer;      //Indexes for tiles array
    fTilesIndCount: Integer;

    fTilesLayersVtx: array of TKMTileVertice; //Vertice cache for layers
    fTilesLayersInd: array of Integer;      //Indexes for layers array

    fAnimTilesVtx: TKMTileVerticeArray;       //Vertice buffer for tiles animations (water/falls/swamp)
    fAnimTilesVtxCount: Integer;
    fAnimTilesInd: array of Integer;        //Indexes for array tiles animation array
    fAnimTilesIndCount: Integer;

    fTilesFowVtx: TKMTileFowVerticeArray;     //Vertice buffer for tiles
    fTilesFowVtxCount: Integer;
    fTilesFowInd: array of Integer;         //Indexes for tiles array
    fTilesFowIndCount: Integer;

    fVtxTilesShd: GLUint;
    fIndTilesShd: GLUint;
    fVtxTilesLayersShd: GLUint;
    fIndTilesLayersShd: GLUint;
    fVtxAnimTilesShd: GLUint;
    fIndAnimTilesShd: GLUint;
    fVtxTilesFowShd: GLUint;
    fIndTilesFowShd: GLUint;
    fTileUVLookup: array [0..TILES_CNT-1, 0..3] of TKMUVRect;
    fLastBindVBOArrayType: TKMVBOArrayType;
    fVBONeedsFlush: array [TKMVBOArrayType] of Boolean;
    fVBOLastClipRect: TKMRect;
    fVBOLastGameTick: Cardinal;
    fVBOLastFOW: TKMFogOfWarCommon;

    procedure RenderQuadTexture(var TexC: TKMUVRect; tX,tY: Word); inline;
    procedure RenderQuadTextureBlended(var TexC: TKMUVRect; tX,tY: Word; aCorners: TKMTileCorners; aBlendingLevel: Byte); inline;

    function GetTileUV(Index: Word; Rot: Byte): TKMUVRect; inline;
    procedure BindVBOArray(aVBOArrayType: TKMVBOArrayType); inline;
    procedure UpdateVBO(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
    procedure DoTiles(aFOW: TKMFogOfWarCommon);
    procedure DoTilesLayers(aFOW: TKMFogOfWarCommon);
    procedure DoOverlays(aFOW: TKMFogOfWarCommon);
    procedure DoLighting(aFOW: TKMFogOfWarCommon);
    procedure DoAnimations(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
    procedure DoShadows(aFOW: TKMFogOfWarCommon);
    function VBOSupported: Boolean;
    procedure RenderFence(aFence: TKMFenceKind; Pos: TKMDirection; pX,pY: Integer);
    procedure RenderMarkup(pX, pY: Word; aFieldType: TKMFieldType);
    procedure DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aDoBindTexture: Boolean; aUseTileLookup: Boolean;
                           DoHighlight: Boolean = False; HighlightColor: Cardinal = 0; aBlendingLvl: Byte = 0); overload;
    procedure DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aCorners: TKMTileCorners; aDoBindTexture: Boolean;
                           aUseTileLookup: Boolean; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0;
                           aBlendingLvl: Byte = 0); overload;
    function DoUseVBO: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property ClipRect: TKMRect read fClipRect write fClipRect;
    procedure RenderBase(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
    procedure RenderFences(aFOW: TKMFogOfWarCommon);
    procedure RenderPlayerPlans(aFieldsList: TKMPointTagList; aHousePlansList: TKMPointDirList);
    procedure RenderFOW(aFOW: TKMFogOfWarCommon; aUseContrast: Boolean = False);
    procedure RenderTile(aTerrainId: Word; pX,pY,Rot: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0); overload;
    procedure RenderTile(pX,pY: Integer; aTileBasic: TKMTerrainTileBasic; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0); overload;
    procedure RenderTileOverlay(pX, pY: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
  end;


implementation
uses
  KM_Game,
  KM_GameParams,
  KM_Render, KM_RenderTypes,
  KM_Resource, KM_ResTypes,
  KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_Terrain;

const
  TILE_LAYERS_USE_VBO = False;
  MAX_RENDERABLE_TILES = (MAX_MAP_SIZE + 1) * (MAX_MAP_SIZE + 1);
  MAX_RENDERABLE_VERTICIES = 4 * MAX_RENDERABLE_TILES;
  MAX_RENDERABLE_INDEXES = 6 * MAX_RENDERABLE_TILES;


{ TKMRenderTerrain }
constructor TKMRenderTerrain.Create;
var
  I, K: Integer;
  pData: array [0..255] of Cardinal;
  V: TKMVBOArrayType;
begin
  inherited;
  if SKIP_RENDER then Exit;

  //Tiles UV lookup for faster access. Only base tileset for smaller size
  for I := 0 to TILES_CNT - 1 do
    for K := 0 to 3 do
      fTileUVLookup[I, K] := GetTileUV(I, K);

  //Generate gradient programmatically
  //KaM uses [0..255] gradients
  //We use slightly smoothed gradients [16..255] for Remake
  //cos it shows much more of terrain on screen and it looks too contrast
  for I := 0 to 255 do
    pData[I] := EnsureRange(Round(I * 1.0625 - 16), 0, 255) * 65793 or $FF000000;

  fTextG := TKMRender.GenTexture(256, 1, @pData[0], tfRGBA8, ftNearest, ftNearest);

  //Sharp transition between black and white
  pData[0] := $FF000000;
  pData[1] := $00000000;
  pData[2] := $00000000;
  pData[3] := $00000000;
  fTextB := TKMRender.GenTexture(4, 1, @pData[0], tfRGBA8, ftNearest, ftNearest);

  fUseVBO := DoUseVBO;

  if fUseVBO then
  begin
    glGenBuffers(1, @fVtxTilesShd);
    glGenBuffers(1, @fIndTilesShd);
    glGenBuffers(1, @fVtxTilesLayersShd);
    glGenBuffers(1, @fIndTilesLayersShd);
    glGenBuffers(1, @fVtxAnimTilesShd);
    glGenBuffers(1, @fIndAnimTilesShd);
    glGenBuffers(1, @fVtxTilesFowShd);
    glGenBuffers(1, @fIndTilesFowShd);

    //Allocate buffers large enough for the entire map
    SetLength(fTilesVtx, MAX_RENDERABLE_VERTICIES);
    SetLength(fTilesInd, MAX_RENDERABLE_INDEXES);
    SetLength(fTilesFowVtx, MAX_RENDERABLE_VERTICIES);
    SetLength(fTilesFowInd, MAX_RENDERABLE_INDEXES);
    SetLength(fAnimTilesVtx, MAX_RENDERABLE_VERTICIES);
    SetLength(fAnimTilesInd, MAX_RENDERABLE_INDEXES);

    fTilesVtxCount := 0;
    fTilesIndCount := 0;
    fTilesFowVtxCount := 0;
    fTilesFowIndCount := 0;
    fAnimTilesVtxCount := 0;
    fAnimTilesIndCount := 0;
  end;

  for V := Low(TKMVBOArrayType) to High(TKMVBOArrayType) do
    fVBONeedsFlush[V] := True;
end;


destructor TKMRenderTerrain.Destroy;
begin
//  fUseVBO := VBOSupported; //Could have been set to False if 3D rendering is enabled, so reset it
  if fUseVBO then
  begin
    //Since RenderTerrain is created fresh everytime fGame is created, we should clear
    //the buffers to avoid memory leaks.
    glDeleteBuffers(1, @fVtxTilesShd);
    glDeleteBuffers(1, @fIndTilesShd);
    glDeleteBuffers(1, @fVtxTilesLayersShd);
    glDeleteBuffers(1, @fIndTilesLayersShd);
    glDeleteBuffers(1, @fVtxAnimTilesShd);
    glDeleteBuffers(1, @fIndAnimTilesShd);
    glDeleteBuffers(1, @fVtxTilesFowShd);
    glDeleteBuffers(1, @fIndTilesFowShd);
  end;

  inherited;
end;


function TKMRenderTerrain.VBOSupported: Boolean;
begin
  //Some GPUs don't comply with OpenGL 1.5 spec on VBOs, so check Assigned instead of GL_VERSION_1_5
  Result := Assigned(glGenBuffers)        and Assigned(glBindBuffer)    and Assigned(glBufferData) and
            Assigned(glEnableClientState) and Assigned(glVertexPointer) and Assigned(glClientActiveTexture) and
            Assigned(glTexCoordPointer)   and Assigned(glDrawElements)  and Assigned(glDisableClientState) and
            Assigned(glDeleteBuffers);
end;


function TKMRenderTerrain.DoUseVBO: Boolean;
begin
  //VBO has proper vertice coords only for Light/Shadow
  //it cant handle 3D yet and because of FOW leaves terrain revealed, which is an exploit in MP
  //Thus we allow VBO only in 2D
  Result := VBOSupported and not RENDER_3D;
end;


function TKMRenderTerrain.GetTileUV(Index: Word; Rot: Byte): TKMUVRect;
var
  TexO: array [1 .. 4] of Byte; // order of UV coordinates, for rotations
  A: Byte;
begin
  TexO[1] := 1;
  TexO[2] := 2;
  TexO[3] := 3;
  TexO[4] := 4;

  // Rotate by 90 degrees: 4-1-2-3
  if Rot and 1 = 1 then
  begin
    A := TexO[4];
    TexO[4] := TexO[3];
    TexO[3] := TexO[2];
    TexO[2] := TexO[1];
    TexO[1] := A;
  end;

  //Rotate by 180 degrees: 3-4-1-2
  if Rot and 2 = 2 then
  begin
    SwapInt(TexO[1], TexO[3]);
    SwapInt(TexO[2], TexO[4]);
  end;

  // Rotate by 270 degrees = 90 + 180

  //Apply rotation
  with gGFXData[rxTiles, Index+1] do
  begin
    Result[TexO[1], 1] := Tex.u1; Result[TexO[1], 2] := Tex.v1;
    Result[TexO[2], 1] := Tex.u1; Result[TexO[2], 2] := Tex.v2;
    Result[TexO[3], 1] := Tex.u2; Result[TexO[3], 2] := Tex.v2;
    Result[TexO[4], 1] := Tex.u2; Result[TexO[4], 2] := Tex.v1;
  end;
end;


function TileHasToBeRendered(IsFirst: Boolean; aTX,aTY: Word; aFOW: TKMFogOfWarCommon): Boolean; inline;
begin
  // We have to render at least 1 tile (otherwise smth wrong with gl contex and all UI and other sprites are not rendered at all
  // so lets take the 1st tile
  Result := IsFirst or (aFOW.CheckVerticeRenderRev(aTX,aTY) > FOG_OF_WAR_MIN);
end;


procedure TKMRenderTerrain.UpdateVBO(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
var
  fog: PKMByte2Array;

  procedure SetTileVertexExt(out aVert: TKMTileVerticeExt; aTX, aTY: Word;
                             aIsBottomRow: Boolean; aUTile, aVTile: Single); inline;
  begin
    with gTerrain do
    begin
      aVert.X := aTX;
      aVert.Y := aTY - LandExt^[aTY+1, aTX+1].RenderHeight / CELL_HEIGHT_DIV;
      aVert.Z := aTY - Byte(aIsBottomRow);
      aVert.UTile := aUTile;
      aVert.VTile := aVTile;
      aVert.ULit := LandExt[aTY+1, aTX+1].RenderLight;
      aVert.UShd := -LandExt[aTY+1, aTX+1].RenderLight;
    end;
  end;

  procedure SetTileFowVertex(out aVert: TKMTileFowVertice; Fog: PKMByte2Array; aTX, aTY: Word; aIsBottomRow: Boolean); inline;
  begin
    aVert.X := aTX;
    aVert.Y := aTY - gTerrain.LandExt^[aTY+1, aTX+1].RenderHeight / CELL_HEIGHT_DIV;
    aVert.Z := aTY - Byte(aIsBottomRow);
    if Fog <> nil then
      aVert.UFow := Fog^[aTY, aTX] / 256
    else
      aVert.UFow := 255;
  end;

  procedure SetTileVertex(out aVert: TKMTileVertice; aTX, aTY: Word; aIsBottomRow: Boolean; aUAnimTile, aVAnimTile: Single); inline;
  begin
    with gTerrain do
    begin
      aVert.X := aTX;
      aVert.Y := aTY - LandExt^[aTY+1, aTX+1].RenderHeight / CELL_HEIGHT_DIV;
      aVert.Z := aTY - Byte(aIsBottomRow);
      aVert.UAnim := aUAnimTile;
      aVert.VAnim := aVAnimTile;
    end;
  end;

  function TryAddAnimTex(var aAnimCnt: Integer; aTX, aTY: Word; aAnimStep: Integer): Boolean;

    function SetAnimTileVertex(aTerrain: Word; aRotation: Byte): Boolean;
    var
      I: Integer;
      texAnimC: TKMUVRect;
      vtxOffset, indOffset: Integer;
      tile: TKMTileParams;
    begin
      tile := gRes.Tileset[aTerrain];
      if not tile.HasAnim then Exit(False);

      Result := False;

      for I := Low(tile.Animation.Layers) to High(tile.Animation.Layers) do
      begin
        if not tile.Animation.Layers[I].HasAnim then Continue;

        texAnimC := GetTileUV(tile.Animation.Layers[I].GetAnim(aAnimStep), aRotation mod 4);

        vtxOffset := aAnimCnt * 4;
        indOffset := aAnimCnt * 6;

        SetTileVertex(fAnimTilesVtx[vtxOffset],   aTX-1, aTY-1, False, texAnimC[1][1], texAnimC[1][2]);
        SetTileVertex(fAnimTilesVtx[vtxOffset+1], aTX-1, aTY,   True,  texAnimC[2][1], texAnimC[2][2]);
        SetTileVertex(fAnimTilesVtx[vtxOffset+2], aTX,   aTY,   True,  texAnimC[3][1], texAnimC[3][2]);
        SetTileVertex(fAnimTilesVtx[vtxOffset+3], aTX,   aTY-1, False, texAnimC[4][1], texAnimC[4][2]);

        fAnimTilesInd[indOffset+0] := vtxOffset;
        fAnimTilesInd[indOffset+1] := vtxOffset + 1;
        fAnimTilesInd[indOffset+2] := vtxOffset + 2;
        fAnimTilesInd[indOffset+3] := vtxOffset;
        fAnimTilesInd[indOffset+4] := vtxOffset + 3;
        fAnimTilesInd[indOffset+5] := vtxOffset + 2;

        Inc(aAnimCnt);
        Result := True;
        end;
    end;

  var
    L: Integer;
  begin
    Result := SetAnimTileVertex(gTerrain.Land^[aTY,aTX].BaseLayer.Terrain, gTerrain.Land^[aTY,aTX].BaseLayer.Rotation);
    for L := 0 to gTerrain.Land^[aTY,aTX].LayersCnt - 1 do
      if not Result then
        Result := SetAnimTileVertex(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(gTerrain.Land^[aTY,aTX].Layer[L].Terrain).TerKind],
                                    gTerrain.Land^[aTY,aTX].Layer[L].Rotation)
      else
        Exit;
  end;

var
  I, J, tilesCnt, fowCnt, animCnt, vtxOffset, indOffset: Integer;
//  P,L,TilesLayersCnt: Integer;
  sizeX, sizeY: Word;
  tX, tY: Word;
  texTileC: TKMUVRect;
  V: TKMVBOArrayType;
begin
  if not fUseVBO then Exit;

  //Skip updating VBOs if GameTick and ClipRect haven't changed
  if not gGameParams.IsMapEditor
    and (fClipRect = fVBOLastClipRect)
    and (fVBOLastFOW = aFOW)
    and (gGameParams.Tick = fVBOLastGameTick) then
    Exit;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameUpdateVBO);
  {$ENDIF}

  fVBOLastClipRect := fClipRect;
  fVBOLastGameTick := gGameParams.Tick;
  fVBOLastFOW := aFOW;

  fLastBindVBOArrayType := vatNone;

  if aFOW is TKMFogOfWar then
    fog := @TKMFogOfWar(aFOW).Revelation
  else
    fog := nil;

  sizeX := Max(fClipRect.Right - fClipRect.Left, 0);
  sizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);

  tilesCnt := 0;
  fowCnt := 0;
  animCnt := 0;
//  P := 0;
//  SetLength(fTilesLayersVtx, (SizeX + 1) * 4 * 3 * (SizeY + 1));

  with gTerrain do
    if (MapX > 0) and (MapY > 0) then
      for I := 0 to sizeY do
        for J := 0 to sizeX do
        begin
          tX := J + fClipRect.Left;
          tY := I + fClipRect.Top;

          if TileHasToBeRendered(I*J = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            texTileC := fTileUVLookup[Land^[tY, tX].BaseLayer.Terrain, Land^[tY, tX].BaseLayer.Rotation mod 4];

            vtxOffset := tilesCnt * 4;
            indOffset := tilesCnt * 6;

            //Fill Tile vertices array
            SetTileVertexExt(fTilesVtx[vtxOffset],   tX-1, tY-1, False, texTileC[1][1], texTileC[1][2]);
            SetTileVertexExt(fTilesVtx[vtxOffset+1], tX-1, tY,   True,  texTileC[2][1], texTileC[2][2]);
            SetTileVertexExt(fTilesVtx[vtxOffset+2], tX,   tY,   True,  texTileC[3][1], texTileC[3][2]);
            SetTileVertexExt(fTilesVtx[vtxOffset+3], tX,   tY-1, False, texTileC[4][1], texTileC[4][2]);

            // Set Tile terrain indices
            fTilesInd[indOffset+0] := vtxOffset;
            fTilesInd[indOffset+1] := vtxOffset + 1;
            fTilesInd[indOffset+2] := vtxOffset + 2;
            fTilesInd[indOffset+3] := vtxOffset;
            fTilesInd[indOffset+4] := vtxOffset + 3;
            fTilesInd[indOffset+5] := vtxOffset + 2;

            Inc(tilesCnt);

//            if Land^[tY, tX].LayersCnt > 0 then
//              for L := 0 to Land^[tY, tX].LayersCnt - 1 do
//              begin
//                TexTileC := GetTileUV(Land[tY,tX].Layer[L].Terrain, Land^[TY,TX].Layer[L].Rotation mod 4);
//
//                //Fill Tile vertices array
//                SetTileVertex(fTilesLayersVtx, P,   tX-1, tY-1, False, TexTileC[1][1], TexTileC[1][2]);
//                SetTileVertex(fTilesLayersVtx, P+1, tX-1, tY,   True,  TexTileC[2][1], TexTileC[2][2]);
//                SetTileVertex(fTilesLayersVtx, P+2, tX,   tY,   True,  TexTileC[3][1], TexTileC[3][2]);
//                SetTileVertex(fTilesLayersVtx, P+3, tX,   tY-1, False, TexTileC[4][1], TexTileC[4][2]);
//                P := P + 4;
//              end;
//
//              if gTerrain.Land^[tY, tX].LayersCnt > 0 then
//                // Set Tile layers terrain indices
//                for L := 0 to gTerrain.Land^[tY, tX].LayersCnt - 1 do
//                begin
//                  fTilesLayersInd[P+0] := KP shl 2; // shl 2 = *4
//                  fTilesLayersInd[P+1] := (KP shl 2) + 1;
//                  fTilesLayersInd[P+2] := (KP shl 2) + 2;
//                  fTilesLayersInd[P+3] := (KP shl 2);
//                  fTilesLayersInd[P+4] := (KP shl 2) + 3;
//                  fTilesLayersInd[P+5] := (KP shl 2) + 2;
//                  P := P + 6;
//                  Inc(KP);
//                end;
          end;

          vtxOffset := fowCnt * 4;
          indOffset := fowCnt * 6;

          // Always set FOW
          SetTileFowVertex(fTilesFowVtx[vtxOffset],   fog, tX-1, tY-1, False);
          SetTileFowVertex(fTilesFowVtx[vtxOffset+1], fog, tX-1, tY,   True);
          SetTileFowVertex(fTilesFowVtx[vtxOffset+2], fog, tX,   tY,   True);
          SetTileFowVertex(fTilesFowVtx[vtxOffset+3], fog, tX,   tY-1, False);

          // Set FOW indices
          fTilesFowInd[indOffset+0] := vtxOffset;
          fTilesFowInd[indOffset+1] := vtxOffset + 1;
          fTilesFowInd[indOffset+2] := vtxOffset + 2;
          fTilesFowInd[indOffset+3] := vtxOffset;
          fTilesFowInd[indOffset+4] := vtxOffset + 3;
          fTilesFowInd[indOffset+5] := vtxOffset + 2;

          Inc(fowCnt);

          // Render animation only if tile is not covered by FOW
          if (aFOW.CheckVerticeRenderRev(tX,tY) > FOG_OF_WAR_ACT) then
            //every tile can have only 1 animation
            TryAddAnimTex(animCnt, tX, tY, aAnimStep);
        end;

  //Update vertex/index counts
  fTilesVtxCount := 4*tilesCnt;
  fTilesIndCount := 6*tilesCnt;

  fTilesFowVtxCount := 4*fowCnt;
  fTilesFowIndCount := 6*fowCnt;

  fAnimTilesVtxCount := 4*animCnt;
  fAnimTilesIndCount := 6*animCnt;

//  SetLength(fTilesLayersVtx, P);
//  TilesLayersCnt := P div 4;
//  SetLength(fTileslayersInd, TilesLayersCnt*6);

  for V := Low(TKMVBOArrayType) to High(TKMVBOArrayType) do
    fVBONeedsFlush[V] := True;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameUpdateVBO);
  {$ENDIF}
end;


procedure TKMRenderTerrain.RenderQuadTexture(var TexC: TKMUVRect; tX,tY: Word);
begin
  with gTerrain do
    if RENDER_3D then
    begin
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1,-LandExt^[tY,  tX].RenderHeight/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  ,-LandExt^[tY+1,tX].RenderHeight/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  ,-LandExt^[tY+1,tX+1].RenderHeight/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1,-LandExt^[tY,  tX+1].RenderHeight/CELL_HEIGHT_DIV);
    end else
    begin
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1-LandExt^[tY,  tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  -LandExt^[tY+1,tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  -LandExt^[tY+1,tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1-LandExt^[tY,  tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
    end;
end;


procedure TKMRenderTerrain.RenderQuadTextureBlended(var TexC: TKMUVRect; tX,tY: Word; aCorners: TKMTileCorners; aBlendingLevel: Byte);
var
  blendFactor: Single;
begin
  blendFactor := 1 - Max(0, Min(1, aBlendingLevel / TERRAIN_MAX_BLENDING_LEVEL));
  with gTerrain do
    if RENDER_3D then
    begin
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1,-LandExt^[tY,  tX].RenderHeight/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  ,-LandExt^[tY+1,tX].RenderHeight/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  ,-LandExt^[tY+1,tX+1].RenderHeight/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1,-LandExt^[tY,  tX+1].RenderHeight/CELL_HEIGHT_DIV);
    end else
    begin
      if aCorners[0] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,blendFactor);
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1-LandExt^[tY,  tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);

      if aCorners[3] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,blendFactor);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  -LandExt^[tY+1,tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);

      if aCorners[2] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,blendFactor);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  -LandExt^[tY+1,tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);

      if aCorners[1] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,blendFactor);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1-LandExt^[tY,  tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
      glColor4f(1,1,1,1);
    end;
end;


procedure TKMRenderTerrain.DoTiles(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
  texC: TKMUVRect;
  sizeX, sizeY: Word;
  tX, tY: Word;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameTiles);
  {$ENDIF}
  //First we render base layer, then we do animated layers for Water/Swamps/Waterfalls
  //They all run at different speeds so we can't adjoin them in one layer
  glColor4f(1,1,1,1);
  //Draw with VBO only if all tiles are on the same texture
  if fUseVBO and TKMResSprites.AllTilesOnOneAtlas then
  begin
    if fTilesVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatTile);
    //Bind to tiles texture. All tiles should be places in 1 atlas,
    //so to get TexId we can use any of terrain tile Id (f.e. 1st)
    TKMRender.BindTexture(gGFXData[rxTiles, 1].Tex.TexID);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TKMTileVerticeExt), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, SizeOf(TKMTileVerticeExt), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    sizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    sizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to sizeY do
        for K := 0 to sizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if DO_DEBUG_TER_RENDER and not (0 in DEBUG_TERRAIN_LAYERS) then Continue;

          if TileHasToBeRendered(I*K = 0, tX, tY, aFow) then // Do not render tiles fully covered by FOW
          begin
            with Land^[tY,tX] do
            begin
              TKMRender.BindTexture(gGFXData[rxTiles, BaseLayer.Terrain+1].Tex.TexID);
              glBegin(GL_TRIANGLE_FAN);
              texC := fTileUVLookup[BaseLayer.Terrain, BaseLayer.Rotation mod 4];
            end;

            RenderQuadTexture(texC, tX, tY);
            glEnd;
          end;
        end;
  end;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameTiles);
  {$ENDIF}
end;


procedure TKMRenderTerrain.DoTilesLayers(aFOW: TKMFogOfWarCommon);
var
  I, K, L: Integer;
  texC: TKMUVRect;
  sizeX, sizeY: Word;
  tX, tY: Word;
  terInfo: TKMGenTerrainInfo;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameTilesLayers);
  {$ENDIF}
  //First we render base layer, then we do animated layers for Water/Swamps/Waterfalls
  //They all run at different speeds so we can't adjoin them in one layer
  glColor4f(1,1,1,1);
  //Draw with VBO only if all tiles are on the same texture

  //DONT USE VBO FOR LAYERS FOR NOW, SINCE WE CAN USE BLENDING HERE
  if TILE_LAYERS_USE_VBO
    and fUseVBO
    and TKMResSprites.AllTilesOnOneAtlas then
  begin
    if Length(fTilesLayersVtx) = 0 then Exit; //Nothing to render
    BindVBOArray(vatTileLayer);
    //Bind to tiles texture. All tiles should be places in 1 atlas,
    //so to get TexId we can use any of terrain tile Id (f.e. 1st)
    TKMRender.BindTexture(gGFXData[rxTiles, 1].Tex.TexID);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TKMTileVertice), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, SizeOf(TKMTileVertice), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, Length(fTilesLayersInd), GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    sizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    sizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to sizeY do
        for K := 0 to sizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
            for L := 0 to Land^[tY,tX].LayersCnt - 1 do
            begin
              if DO_DEBUG_TER_RENDER and not ((L + 1) in DEBUG_TERRAIN_LAYERS) then Continue;

              with Land^[tY,tX] do
              begin
                TKMRender.BindTexture(gGFXData[rxTiles, Layer[L].Terrain+1].Tex.TexID);
                glBegin(GL_TRIANGLE_FAN);
                texC := GetTileUV(Layer[L].Terrain, Layer[L].Rotation);
                terInfo := gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain);

                if terInfo.TerKind = tkCustom then
                  Exit;

                if BlendingLvl > 0 then
                  RenderQuadTextureBlended(texC, tX, tY, Layer[L].GetCorners, BlendingLvl)
                else
                  RenderQuadTexture(texC, tX, tY);
                glEnd;
              end;
            end;
        end;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); //Just in case...
  end;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameTilesLayers);
  {$ENDIF}
end;


procedure TKMRenderTerrain.DoAnimations(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
var
  I, J, K: Integer;
  texC: TKMUVRect;
  animID: Word;
  tile: TKMTileParams;
begin
  if SKIP_TER_RENDER_ANIMS then Exit;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameWater);
  {$ENDIF}

  //First we render base layer, then we do animated layers for Water/Swamps/Waterfalls
  //They all run at different speeds so we can't adjoin them in one layer
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  if fUseVBO and TKMResSprites.AllTilesOnOneAtlas then
  begin
    if fAnimTilesVtxCount = 0 then Exit; //There is no animation on map
    BindVBOArray(vatAnimTile);
    //Bind to tiles texture. All tiles should be placed in 1 atlas,
    //so to get TexId we can use any of terrain tile Id (f.e. 1st)
    TKMRender.BindTexture(gGFXData[rxTiles, 1].Tex.TexID);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TKMTileVertice), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, SizeOf(TKMTileVertice), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fAnimTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    with gTerrain do
      for I := fClipRect.Top to fClipRect.Bottom do
        for K := fClipRect.Left to fClipRect.Right do
        begin
          tile := gRes.Tileset[Land^[I,K].BaseLayer.Terrain];
          if tile.HasAnim
            and (aFOW.CheckVerticeRenderRev(K,I) > FOG_OF_WAR_ACT) then //No animation in FOW
          begin
            for J := Low(tile.Animation.Layers) to High(tile.Animation.Layers) do
            begin
              if not tile.Animation.Layers[J].HasAnim then Continue;

              animID := tile.Animation.Layers[J].GetAnim(aAnimStep);
              TKMRender.BindTexture(gGFXData[rxTiles, animID + 1].Tex.TexID);
              texC := GetTileUV(animID, Land^[I,K].BaseLayer.Rotation);

              glBegin(GL_TRIANGLE_FAN);
                glColor4f(1,1,1,1);
                RenderQuadTexture(texC, K, I);
              glEnd;
            end;
          end;
        end;
  end;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameWater);
  {$ENDIF}
end;


//Render single tile overlay
procedure TKMRenderTerrain.RenderTileOverlay(pX, pY: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
//   1      //Select road tile and rotation
//  8*2     //depending on surrounding tiles
//   4      //Bitfield
const
  RoadsConnectivity: array [0..15, 1..2] of Byte = (
    (248,0), (248,0), (248,1), (250,3),
    (248,0), (248,0), (250,0), (252,0),
    (248,1), (250,2), (248,1), (252,3),
    (250,1), (252,2), (252,1), (254,0));
var
  road, ID, rot: Byte;
begin
  //Fake tiles for MapEd fields
  if gGame.MapEditor <> nil then
    case gGame.MapEditor.LandMapEd^[pY, pX].CornOrWine of
      1:  RenderTile(gGame.MapEditor.LandMapEd^[pY, pX].CornOrWineTerrain, pX, pY, 0, DoHighlight, HighlightColor); // Corn
      2:  RenderTile(WINE_TERRAIN_ID, pX, pY, 0, DoHighlight, HighlightColor); //Wine
    end;

  if gTerrain.Land^[pY, pX].TileOverlay = toRoad then
  begin
    road := 0;
    if (pY - 1 >= 1) then
      road := road + Byte(gTerrain.Land^[pY - 1, pX].TileOverlay = toRoad) shl 0;
    if (pX + 1 <= gTerrain.MapX - 1) then
      road := road + Byte(gTerrain.Land^[pY, pX + 1].TileOverlay = toRoad) shl 1;
    if (pY + 1 <= gTerrain.MapY - 1) then
      road := road + Byte(gTerrain.Land^[pY + 1, pX].TileOverlay = toRoad) shl 2;
    if (pX - 1 >= 1) then
      road := road + Byte(gTerrain.Land^[pY, pX - 1].TileOverlay = toRoad) shl 3;
    ID := RoadsConnectivity[road, 1];
    rot := RoadsConnectivity[road, 2];
    RenderTile(ID, pX, pY, rot, DoHighlight, HighlightColor);
  end
  else if gTerrain.Land^[pY, pX].TileOverlay <> toNone then
    RenderTile(TILE_OVERLAY_IDS[gTerrain.Land^[pY, pX].TileOverlay], pX, pY, 0, DoHighlight, HighlightColor);
end;


procedure TKMRenderTerrain.DoOverlays(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameOverlays);
  {$ENDIF}
  if not (mlOverlays in gGameParams.VisibleLayers) then
    Exit;

  for I := fClipRect.Top to fClipRect.Bottom do
    for K := fClipRect.Left to fClipRect.Right do
      if TileHasToBeRendered(False,K,I,aFow) then
        RenderTileOverlay(K, I);

  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameOverlays);
  {$ENDIF}
end;


procedure TKMRenderTerrain.RenderFences(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
begin
  if gGameParams.IsMapEditor and not (mlOverlays in gGameParams.VisibleLayers) then
    Exit;

  with gTerrain do
    for I := fClipRect.Top to fClipRect.Bottom do
      for K := fClipRect.Left to fClipRect.Right do
      begin
        if TileHasToBeRendered(False,K,I,aFow) then
        begin
          if Fences[I,K].Side and 1 = 1 then
            RenderFence(Fences[I,K].Kind, dirN, K, I);
          if Fences[I,K].Side and 2 = 2 then
            RenderFence(Fences[I,K].Kind, dirE, K, I);
          if Fences[I,K].Side and 4 = 4 then
            RenderFence(Fences[I,K].Kind, dirW, K, I);
          if Fences[I,K].Side and 8 = 8 then
            RenderFence(Fences[I,K].Kind, dirS, K, I);
        end;
      end;
end;


//Player markings should be always clearly visible to the player (thats why we render them ontop FOW)
procedure TKMRenderTerrain.RenderPlayerPlans(aFieldsList: TKMPointTagList; aHousePlansList: TKMPointDirList);
var
  I: Integer;
begin
  //Rope field marks
  for I := 0 to aFieldsList.Count - 1 do
    RenderMarkup(aFieldsList[I].X, aFieldsList[I].Y, TKMFieldType(aFieldsList.Tag[I]));

  //Rope outlines
  for I := 0 to aHousePlansList.Count - 1 do
    RenderFence(fncHousePlan, aHousePlansList[I].Dir, aHousePlansList[I].Loc.X, aHousePlansList[I].Loc.Y);
end;


procedure TKMRenderTerrain.DoLighting(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
  sizeX, sizeY: Word;
  tX, tY: Word;
begin
  if SKIP_TER_RENDER_LIGHT then Exit;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameLighting);
  {$ENDIF}

  glColor4f(1, 1, 1, 1);
  //Render highlights
  glBlendFunc(GL_DST_COLOR, GL_ONE);
  TKMRender.BindTexture(fTextG);

  if fUseVBO then
  begin
    if fTilesVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatTile);
    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TKMTileVerticeExt), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(1, GL_FLOAT, SizeOf(TKMTileVerticeExt), Pointer(20));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    sizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    sizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to sizeY do
        for K := 0 to sizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            if RENDER_3D then
            begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(LandExt[  tY,   tX].RenderLight); glVertex3f(tX-1, tY-1, -LandExt^[  tY,   tX].RenderHeight / CELL_HEIGHT_DIV);
                glTexCoord1f(LandExt[tY+1,   tX].RenderLight); glVertex3f(tX-1,   tY, -LandExt^[tY+1,   tX].RenderHeight / CELL_HEIGHT_DIV);
                glTexCoord1f(LandExt[tY+1, tX+1].RenderLight); glVertex3f(  tX,   tY, -LandExt^[tY+1, tX+1].RenderHeight / CELL_HEIGHT_DIV);
                glTexCoord1f(LandExt[  tY, tX+1].RenderLight); glVertex3f(  tX, tY-1, -LandExt^[  tY, tX+1].RenderHeight / CELL_HEIGHT_DIV);
              glEnd;
            end else begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(LandExt[  tY,   tX].RenderLight); glVertex3f(tX-1, tY-1 - LandExt^[  tY,   tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(LandExt[tY+1,   tX].RenderLight); glVertex3f(tX-1,   tY - LandExt^[tY+1,   tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(LandExt[tY+1, tX+1].RenderLight); glVertex3f(  tX,   tY - LandExt^[tY+1, tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(LandExt[  tY, tX+1].RenderLight); glVertex3f(  tX, tY-1 - LandExt^[  tY, tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
              glEnd;
            end;
          end;
        end;
  end;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameLighting);
  {$ENDIF}
end;


//Render shadows and FOW at once
procedure TKMRenderTerrain.DoShadows(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
  sizeX, sizeY: Word;
  tX, tY: Word;
begin
  if SKIP_TER_RENDER_SHADOW then Exit;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameShadows);
  {$ENDIF}

  glColor4f(1, 1, 1, 1);
  glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);
  TKMRender.BindTexture(fTextG);

  if fUseVBO then
  begin
    if fTilesVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatTile);
    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TKMTileVerticeExt), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(1, GL_FLOAT, SizeOf(TKMTileVerticeExt), Pointer(24));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    sizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    sizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to sizeY do
        for K := 0 to sizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            if RENDER_3D then
            begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(-LandExt[  tY,   tX].RenderLight); glVertex3f(tX-1, tY-1, -LandExt^[  tY,   tX].RenderHeight / CELL_HEIGHT_DIV);
                glTexCoord1f(-LandExt[tY+1,   tX].RenderLight); glVertex3f(tX-1,   tY, -LandExt^[tY+1,   tX].RenderHeight / CELL_HEIGHT_DIV);
                glTexCoord1f(-LandExt[tY+1, tX+1].RenderLight); glVertex3f(  tX,   tY, -LandExt^[tY+1, tX+1].RenderHeight / CELL_HEIGHT_DIV);
                glTexCoord1f(-LandExt[  tY, tX+1].RenderLight); glVertex3f(  tX, tY-1, -LandExt^[  tY, tX+1].RenderHeight / CELL_HEIGHT_DIV);
              glEnd;
            end else begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(-LandExt[  tY,   tX].RenderLight); glVertex3f(tX-1, tY-1 - LandExt^[  tY,   tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(-LandExt[tY+1,   tX].RenderLight); glVertex3f(tX-1,   tY - LandExt^[tY+1,   tX].RenderHeight / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(-LandExt[tY+1, tX+1].RenderLight); glVertex3f(  tX,   tY - LandExt^[tY+1, tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(-LandExt[  tY, tX+1].RenderLight); glVertex3f(  tX, tY-1 - LandExt^[  tY, tX+1].RenderHeight / CELL_HEIGHT_DIV, tY-1);
              glEnd;
            end;
          end;
        end;
  end;

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  TKMRender.BindTexture(0);

  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameShadows);
  {$ENDIF}
end;


//Render FOW at once
procedure TKMRenderTerrain.RenderFOW(aFOW: TKMFogOfWarCommon; aUseContrast: Boolean = False);
var
  I, K: Integer;
  fog: PKMByte2Array;
begin
  if aFOW is TKMFogOfWarOpen then Exit;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameFOW);
  {$ENDIF}

  glColor4f(1, 1, 1, 1);

  if aUseContrast then
  begin
    //Hide everything behind FOW with a sharp transition
    glColor4f(0, 0, 0, 1);
    TKMRender.BindTexture(fTextB);
  end
  else
  begin
    glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    TKMRender.BindTexture(fTextG);
  end;

  fog := @TKMFogOfWar(aFOW).Revelation;
  if fUseVBO then
  begin
    if fTilesFowVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatFOW);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TKMTileFowVertice), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(1, GL_FLOAT, SizeOf(TKMTileFowVertice), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesFowIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    with gTerrain do
    if RENDER_3D then
      for I := fClipRect.Top to fClipRect.Bottom do
      for K := fClipRect.Left to fClipRect.Right do
      begin
        glBegin(GL_TRIANGLE_FAN);
          glTexCoord1f(fog^[I - 1, K - 1] / 255);
          glVertex3f(K - 1, I - 1, -LandExt^[I, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[I, K - 1] / 255);
          glVertex3f(K - 1, I, -LandExt^[I + 1, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[I, K] / 255);
          glVertex3f(K, I, -LandExt^[I + 1, K + 1].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[I - 1, K] / 255);
          glVertex3f(K, I - 1, -LandExt^[I, K + 1].RenderHeight / CELL_HEIGHT_DIV);
        glEnd;
      end
    else
      for I := fClipRect.Top to fClipRect.Bottom do
      for K := fClipRect.Left to fClipRect.Right do
      begin
        glBegin(GL_TRIANGLE_FAN);
          glTexCoord1f(fog^[I - 1, K - 1] / 255);
          glVertex2f(K - 1, I - 1 - LandExt^[I, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[I, K - 1] / 255);
          glVertex2f(K - 1, I - LandExt^[I + 1, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[I, K] / 255);
          glVertex2f(K, I - LandExt^[I + 1, K + 1].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[I - 1, K] / 255);
          glVertex2f(K, I - 1 - LandExt^[I, K + 1].RenderHeight / CELL_HEIGHT_DIV);
        glEnd;
      end;
  end;

  //Sprites (trees) can extend beyond the top edge of the map, so draw extra rows of fog to cover them
  //@Krom: If you know a neater/faster way to solve this problem please feel free to change it.
  //@Krom: Side note: Is it ok to not use VBOs in this case? (does mixing VBO with non-VBO code cause any problems?)
  with gTerrain do
    if fClipRect.Top <= 1 then
    begin
      //3 tiles is enough to cover the tallest tree with highest elevation on top row
      for I := -2 to 0 do
      for K := fClipRect.Left to fClipRect.Right do
      begin
        glBegin(GL_TRIANGLE_FAN);
          glTexCoord1f(fog^[0, K - 1] / 255);
          glVertex2f(K - 1, I - 1 - LandExt^[1, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[0, K - 1] / 255);
          glVertex2f(K - 1, I - LandExt^[1, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[0, K] / 255);
          glVertex2f(K, I - LandExt^[1, K + 1].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[0, K] / 255);
          glVertex2f(K, I - 1 - LandExt^[1, K + 1].RenderHeight / CELL_HEIGHT_DIV);
        glEnd;
      end;
    end;
  //Similar thing for the bottom of the map (field borders can overhang)
  with gTerrain do
    if fClipRect.Bottom >= MapY-1 then
    begin
      //1 tile is enough to cover field borders
      for K := fClipRect.Left to fClipRect.Right do
      begin
        glBegin(GL_TRIANGLE_FAN);
          glTexCoord1f(fog^[MapY-1, K - 1] / 255);
          glVertex2f(K - 1, MapY-1 - LandExt^[MapY, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[MapY-1, K - 1] / 255);
          glVertex2f(K - 1, MapY - LandExt^[MapY, K].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[MapY-1, K] / 255);
          glVertex2f(K, MapY-1 - LandExt^[MapY, K + 1].RenderHeight / CELL_HEIGHT_DIV);
          glTexCoord1f(fog^[MapY-1, K] / 255);
          glVertex2f(K, MapY - LandExt^[MapY, K + 1].RenderHeight / CELL_HEIGHT_DIV);
        glEnd;
      end;
    end;

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  TKMRender.BindTexture(0);
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameFOW);
  {$ENDIF}
end;


procedure TKMRenderTerrain.BindVBOArray(aVBOArrayType: TKMVBOArrayType);
begin
  if fLastBindVBOArrayType = aVBOArrayType then Exit; // Do not to rebind for same tyle type

  case aVBOArrayType of
    vatTile:       if fTilesVtxCount > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxTilesShd);
                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndTilesShd);

                      if fVBONeedsFlush[aVBOArrayType] then
                      begin
                        glBufferData(GL_ARRAY_BUFFER, fTilesVtxCount * SizeOf(TKMTileVerticeExt), @fTilesVtx[0].X, GL_STREAM_DRAW);
                        glBufferData(GL_ELEMENT_ARRAY_BUFFER, fTilesIndCount * SizeOf(fTilesInd[0]), @fTilesInd[0], GL_STREAM_DRAW);
                        fVBONeedsFlush[aVBOArrayType] := False;
                      end;
                    end else Exit;
    vatTileLayer:  if Length(fTilesLayersVtx) > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxTilesLayersShd);
                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndTilesLayersShd);

                      if fVBONeedsFlush[aVBOArrayType] then
                      begin
                        glBufferData(GL_ARRAY_BUFFER, Length(fTilesLayersVtx) * SizeOf(TKMTileVertice), @fTilesLayersVtx[0].X, GL_STREAM_DRAW);
                        glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(fTilesLayersInd) * SizeOf(fTilesLayersInd[0]), @fTilesLayersInd[0], GL_STREAM_DRAW);
                        fVBONeedsFlush[aVBOArrayType] := False;
                      end;
                    end else Exit;
    vatAnimTile:   if fAnimTilesVtxCount > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxAnimTilesShd);
                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndAnimTilesShd);

                      if fVBONeedsFlush[aVBOArrayType] then
                      begin
                        glBufferData(GL_ARRAY_BUFFER, fAnimTilesVtxCount * SizeOf(TKMTileVertice), @fAnimTilesVtx[0].X, GL_STREAM_DRAW);
                        glBufferData(GL_ELEMENT_ARRAY_BUFFER, fAnimTilesIndCount * SizeOf(fAnimTilesInd[0]), @fAnimTilesInd[0], GL_STREAM_DRAW);
                        fVBONeedsFlush[aVBOArrayType] := False;
                      end;
                    end else Exit;
    vatFOW:        if fTilesFowVtxCount > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxTilesFowShd);
                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndTilesFowShd);

                      if fVBONeedsFlush[aVBOArrayType] then
                      begin
                        glBufferData(GL_ARRAY_BUFFER, fTilesFowVtxCount * SizeOf(TKMTileFowVertice), @fTilesFowVtx[0].X, GL_STREAM_DRAW);
                        glBufferData(GL_ELEMENT_ARRAY_BUFFER, fTilesFowIndCount * SizeOf(fTilesFowInd[0]), @fTilesFowInd[0], GL_STREAM_DRAW);
                        fVBONeedsFlush[aVBOArrayType] := False;
                      end;
                    end else Exit;
  end;
  fLastBindVBOArrayType := aVBOArrayType;
end;


//AnimStep - animation step for terrain (water/etc)
//aFOW - whose players FOW to apply
procedure TKMRenderTerrain.RenderBase(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
begin
  // Don't use VBO when do debug terrain layers (there is no debug code in UpdateVBO). Its okay for debug
  fUseVBO := DoUseVBO and not DO_DEBUG_TER_RENDER;

  UpdateVBO(aAnimStep, aFOW);

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameTerrainBase);
  {$ENDIF}

  DoTiles(aFOW);
  //It was 'unlit water goes above lit sand'
  //But there is no big difference there, that is why, to make possible transitions with water,
  //Animations was put before DoLighting
  DoAnimations(aAnimStep, aFOW);
  //TileLayers after water, as water with animation is always base layer
  DoTilesLayers(aFOW);
  DoOverlays(aFOW);
  DoLighting(aFOW);
//  DoAnimations(aAnimStep, aFOW);
  DoShadows(aFOW);

  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameTerrainBase);
  {$ENDIF}
end;


procedure TKMRenderTerrain.DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aDoBindTexture: Boolean; aUseTileLookup: Boolean;
                                      DoHighlight: Boolean = False; HighlightColor: Cardinal = 0; aBlendingLvl: Byte = 0);
const
  NO_CORNERS: TKMTileCorners = (False, False, False, False);
begin
  DoRenderTile(aTerrainId, pX,pY,Rot, NO_CORNERS, aDoBindTexture, aUseTileLookup, DoHighlight, HighlightColor, aBlendingLvl);
end;


procedure TKMRenderTerrain.DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aCorners: TKMTileCorners; aDoBindTexture: Boolean;
                                      aUseTileLookup: Boolean; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0;
                                      aBlendingLvl: Byte = 0);
var
  texC: TKMUVRect; // Texture UV coordinates
begin
  if not gTerrain.TileInMapCoords(pX,pY) then Exit;

  if DoHighlight then
    glColor4ub(HighlightColor and $FF, (HighlightColor shr 8) and $FF, (HighlightColor shr 16) and $FF, $FF)
  else
    glColor4f(1, 1, 1, 1);

  if aDoBindTexture then
    TKMRender.BindTexture(gGFXData[rxTiles, aTerrainId + 1].Tex.TexID);

  if aUseTileLookup then
    texC := fTileUVLookup[aTerrainId, Rot mod 4]
  else
    texC := GetTileUV(aTerrainId, Rot mod 4);

  glBegin(GL_TRIANGLE_FAN);

  //todo -cComplicated: DoHighlight and HighlightColor is not considered here, we use always glColor4f(1, 1, 1, 1);
  if aBlendingLvl > 0 then
    RenderQuadTextureBlended(texC, pX, pY, aCorners, aBlendingLvl)
  else
    RenderQuadTexture(texC, pX, pY);

  glEnd;
end;


//Render single terrain cell
procedure TKMRenderTerrain.RenderTile(aTerrainId: Word; pX,pY,Rot: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
begin
  DoRenderTile(aTerrainId, pX, pY, Rot, True, True, DoHighlight, HighlightColor);
end;


//Render single terrain cell
procedure TKMRenderTerrain.RenderTile(pX,pY: Integer; aTileBasic: TKMTerrainTileBasic; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
var
  L: Integer;
  doBindTexture: Boolean;
begin
  if not gTerrain.TileInMapCoords(pX,pY) then Exit;

  doBindTexture := not TKMResSprites.AllTilesOnOneAtlas;
  if not doBindTexture then
    TKMRender.BindTexture(gGFXData[rxTiles, aTileBasic.BaseLayer.Terrain + 1].Tex.TexID);

  // Render Base Layer
  DoRenderTile(aTileBasic.BaseLayer.Terrain, pX, pY, aTileBasic.BaseLayer.Rotation, doBindTexture,
               False, DoHighlight, HighlightColor);

  // Render other Layers
  for L := 0 to aTileBasic.LayersCnt - 1 do
    DoRenderTile(aTileBasic.Layer[L].Terrain, pX, pY, aTileBasic.Layer[L].Rotation, aTileBasic.Layer[L].GetCorners,
                 doBindTexture, False, DoHighlight, HighlightColor, aTileBasic.BlendingLvl);
end;


procedure TKMRenderTerrain.RenderFence(aFence: TKMFenceKind; Pos: TKMDirection; pX,pY: Integer);
const
  FO = 4; //Fence overlap
  VO = -4; //Move fences a little down to avoid visible overlap when unit stands behind fence, but is rendered ontop of it, due to Z sorting algo we use
var
  UVa, UVb: TKMPointF;
  texID: Integer;
  x1, y1, y2, fenceX, fenceY: Single;
  heightInPx: Integer;
begin
  case aFence of
    fncHouseFence: if Pos in [dirN,dirS] then texID:=463 else texID:=467; //WIP (Wood planks)
    fncHousePlan:  if Pos in [dirN,dirS] then texID:=105 else texID:=117; //Plan (Ropes)
    fncWine:       if Pos in [dirN,dirS] then texID:=462 else texID:=466; //Fence (Wood)
    fncCorn:       if Pos in [dirN,dirS] then texID:=461 else texID:=465; //Fence (Stones)
    else          texID := 0;
  end;

  //With these directions render fences on next tile
  if Pos = dirS then Inc(pY);
  if Pos = dirW then Inc(pX);

  if Pos in [dirN, dirS] then
  begin //Horizontal
    TKMRender.BindTexture(gGFXData[rxGui,texID].Tex.TexID);
    UVa.X := gGFXData[rxGui, texID].Tex.u1;
    UVa.Y := gGFXData[rxGui, texID].Tex.v1;
    UVb.X := gGFXData[rxGui, texID].Tex.u2;
    UVb.Y := gGFXData[rxGui, texID].Tex.v2;

    y1 := pY - 1 - (gTerrain.LandExt^[pY, pX].RenderHeight + VO) / CELL_HEIGHT_DIV;
    y2 := pY - 1 - (gTerrain.LandExt^[pY, pX + 1].RenderHeight + VO) / CELL_HEIGHT_DIV;

    fenceY := gGFXData[rxGui,texID].PxWidth / CELL_SIZE_PX;
    glBegin(GL_QUADS);
      glTexCoord2f(UVb.x, UVa.y); glVertex2f(pX-1 -3/ CELL_SIZE_PX, y1);
      glTexCoord2f(UVa.x, UVa.y); glVertex2f(pX-1 -3/ CELL_SIZE_PX, y1 - fenceY);
      glTexCoord2f(UVa.x, UVb.y); glVertex2f(pX   +3/ CELL_SIZE_PX, y2 - fenceY);
      glTexCoord2f(UVb.x, UVb.y); glVertex2f(pX   +3/ CELL_SIZE_PX, y2);
    glEnd;
  end
  else
  begin //Vertical
    TKMRender.BindTexture(gGFXData[rxGui,texID].Tex.TexID);
    heightInPx := Round(CELL_SIZE_PX * (1 + (gTerrain.LandExt^[pY,pX].RenderHeight - gTerrain.LandExt^[pY+1,pX].RenderHeight)/CELL_HEIGHT_DIV)+FO);
    UVa.X := gGFXData[rxGui, texID].Tex.u1;
    UVa.Y := gGFXData[rxGui, texID].Tex.v1;
    UVb.X := gGFXData[rxGui, texID].Tex.u2;
    UVb.Y := Mix(gGFXData[rxGui, texID].Tex.v2, gGFXData[rxGui, texID].Tex.v1, heightInPx / gGFXData[rxGui, texID].pxHeight);

    y1 := pY - 1 - (gTerrain.LandExt^[pY, pX].RenderHeight + FO + VO) / CELL_HEIGHT_DIV;
    y2 := pY - (gTerrain.LandExt^[pY + 1, pX].RenderHeight + VO) / CELL_HEIGHT_DIV;

    fenceX := gGFXData[rxGui,texID].PxWidth / CELL_SIZE_PX;

    case Pos of
      dirW:  x1 := pX - 1 - 3 / CELL_SIZE_PX;
      dirE:  x1 := pX - 1 + 3 / CELL_SIZE_PX - fenceX;
      else    x1 := pX - 1; //Should never happen
    end;

    glBegin(GL_QUADS);
      glTexCoord2f(UVa.x, UVa.y); glVertex2f(x1, y1);
      glTexCoord2f(UVb.x, UVa.y); glVertex2f(x1+ fenceX, y1);
      glTexCoord2f(UVb.x, UVb.y); glVertex2f(x1+ fenceX, y2);
      glTexCoord2f(UVa.x, UVb.y); glVertex2f(x1, y2);
    glEnd;
  end;
end;


procedure TKMRenderTerrain.RenderMarkup(pX, pY: Word; aFieldType: TKMFieldType);
const
  MarkupTex: array [TKMFieldType] of Word = (0, 105, 107, 108, 0);
var
  ID: Integer;
  UVa,UVb: TKMPointF;
begin
  ID := MarkupTex[aFieldType];

  TKMRender.BindTexture(gGFXData[rxGui, ID].Tex.TexID);

  UVa.X := gGFXData[rxGui, ID].Tex.u1;
  UVa.Y := gGFXData[rxGui, ID].Tex.v1;
  UVb.X := gGFXData[rxGui, ID].Tex.u2;
  UVb.Y := gGFXData[rxGui, ID].Tex.v2;

  glBegin(GL_QUADS);
    glTexCoord2f(UVb.x, UVa.y); glVertex2f(pX-1, pY-1 - gTerrain.LandExt^[pY  ,pX  ].RenderHeight/CELL_HEIGHT_DIV+0.10);
    glTexCoord2f(UVa.x, UVa.y); glVertex2f(pX-1, pY-1 - gTerrain.LandExt^[pY  ,pX  ].RenderHeight/CELL_HEIGHT_DIV-0.15);
    glTexCoord2f(UVa.x, UVb.y); glVertex2f(pX  , pY   - gTerrain.LandExt^[pY+1,pX+1].RenderHeight/CELL_HEIGHT_DIV-0.25);
    glTexCoord2f(UVb.x, UVb.y); glVertex2f(pX  , pY   - gTerrain.LandExt^[pY+1,pX+1].RenderHeight/CELL_HEIGHT_DIV);

    glTexCoord2f(UVb.x, UVa.y); glVertex2f(pX-1, pY   - gTerrain.LandExt^[pY+1,pX  ].RenderHeight/CELL_HEIGHT_DIV);
    glTexCoord2f(UVa.x, UVa.y); glVertex2f(pX-1, pY   - gTerrain.LandExt^[pY+1,pX  ].RenderHeight/CELL_HEIGHT_DIV-0.25);
    glTexCoord2f(UVa.x, UVb.y); glVertex2f(pX  , pY-1 - gTerrain.LandExt^[pY  ,pX+1].RenderHeight/CELL_HEIGHT_DIV-0.15);
    glTexCoord2f(UVb.x, UVb.y); glVertex2f(pX  , pY-1 - gTerrain.LandExt^[pY  ,pX+1].RenderHeight/CELL_HEIGHT_DIV+0.10);
  glEnd;
end;


end.

unit KM_RenderTerrain;
{$I KaM_Remake.inc}
interface
uses
  dglOpenGL, SysUtils, KromUtils, Math, KM_ResTileset,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_FogOfWar, KM_Pics, KM_ResSprites, KM_Points, KM_Terrain;

type
  TVBOArrayType = (vatNone, vatTile, vatTileLayer, vatAnimTile, vatFOW);

  TUVRect = array [1 .. 4, 1 .. 2] of Single; // Texture UV coordinates

  TTileVerticeExt = record
    X, Y, Z, UTile, VTile, ULit, UShd: Single;
  end;

  TTileFowVertice = record
    X, Y, Z, UFow: Single;
  end;

  TTileVertice = record
    X, Y, Z, UAnim, VAnim: Single;
  end;

  TTileVerticeExtArray = array of TTileVerticeExt;

  TTileFowVerticeArray = array of TTileFowVertice;

  TTileVerticeArray = array of TTileVertice;

  //Render terrain without sprites
  TRenderTerrain = class
  private
    fClipRect: TKMRect;
    fTextG: GLuint; //Shading gradient for lighting
    fTextB: GLuint; //Contrast BW for FOW over color-coder
    fUseVBO: Boolean; //Wherever to render terrain through VBO (faster but needs GL1.5) or DrawCalls (slower but needs only GL1.1)

    fTilesVtx: TTileVerticeExtArray;  //Vertice buffer for tiles
    fTilesVtxCount: Integer;
    fTilesInd: array of Integer;      //Indexes for tiles array
    fTilesIndCount: Integer;

    fTilesLayersVtx: array of TTileVertice; //Vertice cache for layers
    fTilesLayersInd: array of Integer;      //Indexes for layers array

    fAnimTilesVtx: TTileVerticeArray;       //Vertice buffer for tiles animations (water/falls/swamp)
    fAnimTilesVtxCount: Integer;
    fAnimTilesInd: array of Integer;        //Indexes for array tiles animation array
    fAnimTilesIndCount: Integer;

    fTilesFowVtx: TTileFowVerticeArray;     //Vertice buffer for tiles
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
    fTileUVLookup: array [0..TILES_CNT-1, 0..3] of TUVRect;
    fLastBindVBOArrayType: TVBOArrayType;
    function GetTileUV(Index: Word; Rot: Byte): TUVRect; inline;
    procedure BindVBOArray(aVBOArrayType: TVBOArrayType); inline;
    procedure UpdateVBO(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
    procedure DoTiles(aFOW: TKMFogOfWarCommon);
    procedure DoTilesLayers(aFOW: TKMFogOfWarCommon);
    procedure DoOverlays(aFOW: TKMFogOfWarCommon);
    procedure DoLighting(aFOW: TKMFogOfWarCommon);
    procedure DoWater(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
    procedure DoShadows(aFOW: TKMFogOfWarCommon);
    function VBOSupported: Boolean;
    procedure RenderFence(aFence: TKMFenceType; Pos: TKMDirection; pX,pY: Integer);
    procedure RenderMarkup(pX, pY: Word; aFieldType: TKMFieldType);
    procedure DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aDoBindTexture: Boolean; aUseTileLookup: Boolean;
                           DoHighlight: Boolean = False; HighlightColor: Cardinal = 0;
                           aBlendingLvl: Byte = 0); overload;
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
    procedure RenderTileOverlay(aFOW: TKMFogOfWarCommon; pX, pY: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
  end;


implementation
uses
  KM_Game, KM_Render, KM_Resource, KM_PerfLog, KM_DevPerfLog, KM_DevPerfLogTypes;

type
  TAnimLayer = (alWater, alFalls, alSwamp);

const
  TILE_LAYERS_USE_VBO = False;
  MAX_RENDERABLE_TILES = (MAX_MAP_SIZE + 1) * (MAX_MAP_SIZE + 1);
  MAX_RENDERABLE_VERTICIES = 4 * MAX_RENDERABLE_TILES;
  MAX_RENDERABLE_INDEXES = 6 * MAX_RENDERABLE_TILES;


constructor TRenderTerrain.Create;
var
  I, K: Integer;
  pData: array [0..255] of Cardinal;
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

  fTextG := TRender.GenTexture(256, 1, @pData[0], tfRGBA8);

  //Sharp transition between black and white
  pData[0] := $FF000000;
  pData[1] := $00000000;
  pData[2] := $00000000;
  pData[3] := $00000000;
  fTextB := TRender.GenTexture(4, 1, @pData[0], tfRGBA8);

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
end;


destructor TRenderTerrain.Destroy;
begin
//  fUseVBO := VBOSupported; //Could have been set to false if 3D rendering is enabled, so reset it
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


function TRenderTerrain.VBOSupported: Boolean;
begin
  //Some GPUs don't comply with OpenGL 1.5 spec on VBOs, so check Assigned instead of GL_VERSION_1_5
  Result := Assigned(glGenBuffers)        and Assigned(glBindBuffer)    and Assigned(glBufferData) and
            Assigned(glEnableClientState) and Assigned(glVertexPointer) and Assigned(glClientActiveTexture) and
            Assigned(glTexCoordPointer)   and Assigned(glDrawElements)  and Assigned(glDisableClientState) and
            Assigned(glDeleteBuffers);
end;


function TRenderTerrain.DoUseVBO: Boolean;
begin
  Result := VBOSupported and not RENDER_3D;
end;


function TRenderTerrain.GetTileUV(Index: Word; Rot: Byte): TUVRect;
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


function IsWaterAnimTerId(aTexOffset, aTerId: Word): Boolean; inline;
var
  FullTerId: Integer;
begin
  FullTerId := aTexOffset + aTerId + 1;
  Result := (aTerId < 256)
    and InRange(FullTerId, 5000, MAX_STATIC_TERRAIN_ID) //Animations are from 5000 to 10000
    and (gGFXData[rxTiles, FullTerId].Tex.ID <> 0)
    and not InRange(FullTerId, 5549, 5600);
//  if Result then
//    if InRange(FullTerId, 305, 349) then
//    begin
//      Result := False;
//      for I := Low(WATER_ANIM_BELOW_350) to High(WATER_ANIM_BELOW_350) do
//        Result := Result or (FullTerId = WATER_ANIM_BELOW_350[I])
//    end else
//      Result := Result and not InRange(FullTerId, 5549, 5600); //Masks Ids are in that range
end;


function TileHasToBeRendered(IsFirst: Boolean; aTX,aTY: Word; aFOW: TKMFogOfWarCommon): Boolean; inline;
begin
  // We have to render at least 1 tile (otherwise smth wrong with gl contex and all UI and other sprites are not rendered at all
  // so lets take the 1st tile
  Result := IsFirst or (aFOW.CheckTileRenderRev(aTX,aTY) > FOG_OF_WAR_MIN);
end;


procedure TRenderTerrain.UpdateVBO(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
var
  Fog: PKMByte2Array;

  procedure SetTileVertexExt(out aVert: TTileVerticeExt; aTX, aTY: Word;
                             aIsBottomRow: Boolean; aUTile, aVTile: Single); inline;
  begin
    with gTerrain do
    begin
      aVert.X := aTX;
      aVert.Y := aTY - Land[aTY+1, aTX+1].Height / CELL_HEIGHT_DIV;
      aVert.Z := aTY - Byte(aIsBottomRow);
      aVert.UTile := aUTile;
      aVert.VTile := aVTile;
      aVert.ULit := Land[aTY+1, aTX+1].Light;
      aVert.UShd := -Land[aTY+1, aTX+1].Light;
    end;
  end;

  procedure SetTileFowVertex(out aVert: TTileFowVertice; Fog: PKMByte2Array; aTX, aTY: Word; aIsBottomRow: Boolean); inline;
  begin
    aVert.X := aTX;
    aVert.Y := aTY - gTerrain.Land[aTY+1, aTX+1].Height / CELL_HEIGHT_DIV;
    aVert.Z := aTY - Byte(aIsBottomRow);
    if Fog <> nil then
      aVert.UFow := Fog^[aTY, aTX] / 256
    else
      aVert.UFow := 255;
  end;

  procedure SetTileVertex(out aVert: TTileVertice; aTX, aTY: Word; aIsBottomRow: Boolean; aUAnimTile, aVAnimTile: Single); inline;
  begin
    with gTerrain do
    begin
      aVert.X := aTX;
      aVert.Y := aTY - Land[aTY+1, aTX+1].Height / CELL_HEIGHT_DIV;
      aVert.Z := aTY - Byte(aIsBottomRow);
      aVert.UAnim := aUAnimTile;
      aVert.VAnim := aVAnimTile;
    end;
  end;

  function TryAddAnimTex(var aAnimCnt: Integer; aTX, aTY, aTexOffset: Word): Boolean;
    function SetAnimTileVertex(aTerrain: Word; aRotation: Byte): Boolean;
    var
      TexAnimC: TUVRect;
      VtxOffset, IndOffset: Integer;
    begin
      Result := False;
      if IsWaterAnimTerId(aTexOffset, aTerrain) then
      begin
        TexAnimC := GetTileUV(aTexOffset + aTerrain, aRotation mod 4);

        VtxOffset := aAnimCnt * 4;
        IndOffset := aAnimCnt * 6;

        SetTileVertex(fAnimTilesVtx[VtxOffset],   aTX-1, aTY-1, False, TexAnimC[1][1], TexAnimC[1][2]);
        SetTileVertex(fAnimTilesVtx[VtxOffset+1], aTX-1, aTY,   True,  TexAnimC[2][1], TexAnimC[2][2]);
        SetTileVertex(fAnimTilesVtx[VtxOffset+2], aTX,   aTY,   True,  TexAnimC[3][1], TexAnimC[3][2]);
        SetTileVertex(fAnimTilesVtx[VtxOffset+3], aTX,   aTY-1, False, TexAnimC[4][1], TexAnimC[4][2]);

        fAnimTilesInd[IndOffset+0] := VtxOffset;
        fAnimTilesInd[IndOffset+1] := VtxOffset + 1;
        fAnimTilesInd[IndOffset+2] := VtxOffset + 2;
        fAnimTilesInd[IndOffset+3] := VtxOffset;
        fAnimTilesInd[IndOffset+4] := VtxOffset + 3;
        fAnimTilesInd[IndOffset+5] := VtxOffset + 2;

        Inc(aAnimCnt);
        Result := True;
      end;
    end;
  var
    L: Integer;
  begin
    Result := SetAnimTileVertex(gTerrain.Land[aTY,aTX].BaseLayer.Terrain, gTerrain.Land[aTY,aTX].BaseLayer.Rotation);
    for L := 0 to gTerrain.Land[aTY,aTX].LayersCnt - 1 do
      if not Result then
        Result := SetAnimTileVertex(BASE_TERRAIN[gRes.Sprites.GetGenTerrainInfo(gTerrain.Land[aTY,aTX].Layer[L].Terrain).TerKind],
                                    gTerrain.Land[aTY,aTX].Layer[L].Rotation)
      else
        Exit;
  end;

var
  I,J,TilesCnt,FowCnt,AnimCnt,VtxOffset,IndOffset: Integer;
//  P,L,TilesLayersCnt: Integer;
  SizeX, SizeY: Word;
  tX, tY: Word;
  TexTileC: TUVRect;
  AL: TAnimLayer;
  TexOffsetWater, TexOffsetFalls, TexOffsetSwamp: Word;
begin
  if not fUseVBO then Exit;
  gPerfLogs.SectionEnter(psFrameUpdateVBO);

  fLastBindVBOArrayType := vatNone;

  if aFOW is TKMFogOfWar then
    Fog := @TKMFogOfWar(aFOW).Revelation
  else
    Fog := nil;

  SizeX := Max(fClipRect.Right - fClipRect.Left, 0);
  SizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);

  TexOffsetWater := 0;
  TexOffsetFalls := 0;
  TexOffsetSwamp := 0;

  for AL := Low(TAnimLayer) to High(TAnimLayer) do
    case AL of
      alWater: TexOffsetWater := 5000 + 300 * (aAnimStep mod 8 + 1);       // 5300..7400
      alFalls: TexOffsetFalls := 5000 + 300 * (aAnimStep mod 5 + 1 + 8);   // 7700..8900
      alSwamp: TexOffsetSwamp := 5000 + 300 * ((aAnimStep mod 24) div 8 + 1 + 8 + 5); // 9200..9800
    end;

  TilesCnt := 0;
  FowCnt := 0;
  AnimCnt := 0;
//  P := 0;
//  SetLength(fTilesLayersVtx, (SizeX + 1) * 4 * 3 * (SizeY + 1));

  with gTerrain do
    if (MapX > 0) and (MapY > 0) then
      for I := 0 to SizeY do
        for J := 0 to SizeX do
        begin
          tX := J + fClipRect.Left;
          tY := I + fClipRect.Top;

          if TileHasToBeRendered(I*J = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            TexTileC := fTileUVLookup[Land[tY, tX].BaseLayer.Terrain, Land[tY, tX].BaseLayer.Rotation mod 4];

            VtxOffset := TilesCnt * 4;
            IndOffset := TilesCnt * 6;

            //Fill Tile vertices array
            SetTileVertexExt(fTilesVtx[VtxOffset],   tX-1, tY-1, False, TexTileC[1][1], TexTileC[1][2]);
            SetTileVertexExt(fTilesVtx[VtxOffset+1], tX-1, tY,   True,  TexTileC[2][1], TexTileC[2][2]);
            SetTileVertexExt(fTilesVtx[VtxOffset+2], tX,   tY,   True,  TexTileC[3][1], TexTileC[3][2]);
            SetTileVertexExt(fTilesVtx[VtxOffset+3], tX,   tY-1, False, TexTileC[4][1], TexTileC[4][2]);

            // Set Tile terrain indices
            fTilesInd[IndOffset+0] := VtxOffset;
            fTilesInd[IndOffset+1] := VtxOffset + 1;
            fTilesInd[IndOffset+2] := VtxOffset + 2;
            fTilesInd[IndOffset+3] := VtxOffset;
            fTilesInd[IndOffset+4] := VtxOffset + 3;
            fTilesInd[IndOffset+5] := VtxOffset + 2;

            Inc(TilesCnt);

//            if Land[tY, tX].LayersCnt > 0 then
//              for L := 0 to Land[tY, tX].LayersCnt - 1 do
//              begin
//                TexTileC := GetTileUV(Land[tY,tX].Layer[L].Terrain, Land[TY,TX].Layer[L].Rotation mod 4);
//
//                //Fill Tile vertices array
//                SetTileVertex(fTilesLayersVtx, P,   tX-1, tY-1, False, TexTileC[1][1], TexTileC[1][2]);
//                SetTileVertex(fTilesLayersVtx, P+1, tX-1, tY,   True,  TexTileC[2][1], TexTileC[2][2]);
//                SetTileVertex(fTilesLayersVtx, P+2, tX,   tY,   True,  TexTileC[3][1], TexTileC[3][2]);
//                SetTileVertex(fTilesLayersVtx, P+3, tX,   tY-1, False, TexTileC[4][1], TexTileC[4][2]);
//                P := P + 4;
//              end;
//
//              if gTerrain.Land[tY, tX].LayersCnt > 0 then
//                // Set Tile layers terrain indices
//                for L := 0 to gTerrain.Land[tY, tX].LayersCnt - 1 do
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

          VtxOffset := FowCnt * 4;
          IndOffset := FowCnt * 6;

          // Always set FOW
          SetTileFowVertex(fTilesFowVtx[VtxOffset],   Fog, tX-1, tY-1, False);
          SetTileFowVertex(fTilesFowVtx[VtxOffset+1], Fog, tX-1, tY,   True);
          SetTileFowVertex(fTilesFowVtx[VtxOffset+2], Fog, tX,   tY,   True);
          SetTileFowVertex(fTilesFowVtx[VtxOffset+3], Fog, tX,   tY-1, False);

          // Set FOW indices
          fTilesFowInd[IndOffset+0] := VtxOffset;
          fTilesFowInd[IndOffset+1] := VtxOffset + 1;
          fTilesFowInd[IndOffset+2] := VtxOffset + 2;
          fTilesFowInd[IndOffset+3] := VtxOffset;
          fTilesFowInd[IndOffset+4] := VtxOffset + 3;
          fTilesFowInd[IndOffset+5] := VtxOffset + 2;

          Inc(FowCnt);

          //Fill tiles animation vertices array
          if (aFOW.CheckTileRenderRev(tX,tY) > FOG_OF_WAR_ACT) then // Render animation only if tile is not covered by FOW
            if not TryAddAnimTex(AnimCnt, tX, tY, TexOffsetWater) then  //every tile can have only 1 animation
              if not TryAddAnimTex(AnimCnt, tX, tY, TexOffsetFalls) then
                TryAddAnimTex(AnimCnt, tX, tY, TexOffsetSwamp);
        end;

  //Update vertex/index counts
  fTilesVtxCount := 4*TilesCnt;
  fTilesIndCount := 6*TilesCnt;

  fTilesFowVtxCount := 4*FowCnt;
  fTilesFowIndCount := 6*FowCnt;

  fAnimTilesVtxCount := 4*AnimCnt;
  fAnimTilesIndCount := 6*AnimCnt;

//  SetLength(fTilesLayersVtx, P);
//  TilesLayersCnt := P div 4;
//  SetLength(fTileslayersInd, TilesLayersCnt*6);

  gPerfLogs.SectionLeave(psFrameUpdateVBO);
end;


procedure RenderQuadTexture(var TexC: TUVRect; tX,tY: Word); inline;
begin
  with gTerrain do
    if RENDER_3D then
    begin
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1,-Land[tY,  tX].Height/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  ,-Land[tY+1,tX].Height/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  ,-Land[tY+1,tX+1].Height/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1,-Land[tY,  tX+1].Height/CELL_HEIGHT_DIV);
    end else begin
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1-Land[tY,  tX].Height / CELL_HEIGHT_DIV, tY-1);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  -Land[tY+1,tX].Height / CELL_HEIGHT_DIV, tY-1);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  -Land[tY+1,tX+1].Height / CELL_HEIGHT_DIV, tY-1);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1-Land[tY,  tX+1].Height / CELL_HEIGHT_DIV, tY-1);
    end;
end;


procedure RenderQuadTextureBlended(var TexC: TUVRect; tX,tY: Word; aCorners: TKMTileCorners; aBlendingLevel: Byte);
var
  BlendFactor: Single;
begin
  BlendFactor := 1 - Max(0, Min(1, aBlendingLevel / TERRAIN_MAX_BLENDING_LEVEL));
  with gTerrain do
    if RENDER_3D then
    begin
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1,-Land[tY,  tX].Height/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  ,-Land[tY+1,tX].Height/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  ,-Land[tY+1,tX+1].Height/CELL_HEIGHT_DIV);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1,-Land[tY,  tX+1].Height/CELL_HEIGHT_DIV);
    end else begin
      if aCorners[0] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,BlendFactor);
      glTexCoord2fv(@TexC[1]); glVertex3f(tX-1,tY-1-Land[tY,  tX].Height / CELL_HEIGHT_DIV, tY-1);

      if aCorners[3] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,BlendFactor);
      glTexCoord2fv(@TexC[2]); glVertex3f(tX-1,tY  -Land[tY+1,tX].Height / CELL_HEIGHT_DIV, tY-1);

      if aCorners[2] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,BlendFactor);
      glTexCoord2fv(@TexC[3]); glVertex3f(tX  ,tY  -Land[tY+1,tX+1].Height / CELL_HEIGHT_DIV, tY-1);

      if aCorners[1] then
        glColor4f(1,1,1,1)
      else
        glColor4f(1,1,1,BlendFactor);
      glTexCoord2fv(@TexC[4]); glVertex3f(tX  ,tY-1-Land[tY,  tX+1].Height / CELL_HEIGHT_DIV, tY-1);
      glColor4f(1,1,1,1);
    end;
end;


procedure TRenderTerrain.DoTiles(aFOW: TKMFogOfWarCommon);
var
  TexC: TUVRect;
  I,K: Integer;
  SizeX, SizeY: Word;
  tX, tY: Word;
begin
  gPerfLogs.SectionEnter(psFrameTiles);
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
    TRender.BindTexture(gGFXData[rxTiles, 1].Tex.ID);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TTileVerticeExt), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, SizeOf(TTileVerticeExt), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    SizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    SizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to SizeY do
        for K := 0 to SizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            with Land[tY,tX] do
            begin
              TRender.BindTexture(gGFXData[rxTiles, BaseLayer.Terrain+1].Tex.ID);
              glBegin(GL_TRIANGLE_FAN);
              TexC := fTileUVLookup[BaseLayer.Terrain, BaseLayer.Rotation mod 4];
            end;

            RenderQuadTexture(TexC, tX, tY);
            glEnd;
          end;
        end;
  end;
  gPerfLogs.SectionLeave(psFrameTiles);
end;


procedure TRenderTerrain.DoTilesLayers(aFOW: TKMFogOfWarCommon);
var
  TexC: TUVRect;
  I,K,L: Integer;
  SizeX, SizeY: Word;
  tX, tY: Word;
  TerInfo: TKMGenTerrainInfo;
begin
  gPerfLogs.SectionEnter(psFrameTilesLayers);
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
    TRender.BindTexture(gGFXData[rxTiles, 1].Tex.ID);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TTileVertice), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, SizeOf(TTileVertice), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, Length(fTilesLayersInd), GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    SizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    SizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to SizeY do
        for K := 0 to SizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
            for L := 0 to Land[tY,tX].LayersCnt - 1 do
            begin
              with Land[tY,tX] do
              begin
                TRender.BindTexture(gGFXData[rxTiles, Layer[L].Terrain+1].Tex.ID);
                glBegin(GL_TRIANGLE_FAN);
                TexC := GetTileUV(Layer[L].Terrain, Layer[L].Rotation);
                TerInfo := gRes.Sprites.GetGenTerrainInfo(Layer[L].Terrain);

                if TerInfo.TerKind = tkCustom then
                  Exit;

                if BlendingLvl > 0 then
                  RenderQuadTextureBlended(TexC, tX, tY, Layer[L].Corners, BlendingLvl)
                else
                  RenderQuadTexture(TexC, tX, tY);
                glEnd;
              end;
            end;
        end;
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); //Just in case...
  end;
  gPerfLogs.SectionLeave(psFrameTilesLayers);
end;


procedure TRenderTerrain.DoWater(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
var
  AL: TAnimLayer;
  I,K: Integer;
  TexC: TUVRect;
  TexOffset: Word;
begin
  gPerfLogs.SectionEnter(psFrameWater);
  //First we render base layer, then we do animated layers for Water/Swamps/Waterfalls
  //They all run at different speeds so we can't adjoin them in one layer
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  if fUseVBO and TKMResSprites.AllTilesOnOneAtlas then
  begin
    if fAnimTilesVtxCount = 0 then Exit; //There is no animation on map
    BindVBOArray(vatAnimTile);
    //Bind to tiles texture. All tiles should be placed in 1 atlas,
    //so to get TexId we can use any of terrain tile Id (f.e. 1st)
    TRender.BindTexture(gGFXData[rxTiles, 1].Tex.ID);

    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TTileVertice), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, SizeOf(TTileVertice), Pointer(12));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fAnimTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end else begin
    //Each new layer inflicts 10% fps drop
    for AL := Low(TAnimLayer) to High(TAnimLayer) do
    begin
      case AL of
        alWater: TexOffset := 5000 + 300 * (aAnimStep mod 8 + 1);       // 5300..7400
        alFalls: TexOffset := 5000 + 300 * (aAnimStep mod 5 + 1 + 8);   // 7700..8900
        alSwamp: TexOffset := 5000 + 300 * ((aAnimStep mod 24) div 8 + 1 + 8 + 5); // 9200..9800
        else     TexOffset := 0;
      end;

      with gTerrain do
        for I := fClipRect.Top to fClipRect.Bottom do
          for K := fClipRect.Left to fClipRect.Right do
          if IsWaterAnimTerId(TexOffset, Land[I,K].BaseLayer.Terrain)
            and (aFOW.CheckTileRenderRev(K,I) > FOG_OF_WAR_ACT) then //No animation in FOW
          begin
            TRender.BindTexture(gGFXData[rxTiles, TexOffset + Land[I,K].BaseLayer.Terrain + 1].Tex.ID);
            TexC := GetTileUV(TexOffset + Land[I,K].BaseLayer.Terrain, Land[I,K].BaseLayer.Rotation);

            glBegin(GL_TRIANGLE_FAN);
              glColor4f(1,1,1,1);
              RenderQuadTexture(TexC, K, I);
            glEnd;
          end;
    end;
  end;
  gPerfLogs.SectionLeave(psFrameWater);
end;


//Render single tile overlay
procedure TRenderTerrain.RenderTileOverlay(aFOW: TKMFogOfWarCommon; pX, pY: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
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
  Road, ID, Rot: Byte;
begin
  if TileHasToBeRendered(False,pX,pY,aFow) then
  begin
    //Fake tiles for MapEd fields
    case gTerrain.Land[pY, pX].CornOrWine of
      1:  RenderTile(gTerrain.Land[pY, pX].CornOrWineTerrain, pX, pY, 0, DoHighlight, HighlightColor);
      2:  RenderTile(55, pX, pY, 0, DoHighlight, HighlightColor);
    end;

    if gTerrain.Land[pY, pX].TileOverlay = toRoad then
    begin
      Road := 0;
      if (pY - 1 >= 1) then
        Road := Road + byte(gTerrain.Land[pY - 1, pX].TileOverlay = toRoad) shl 0;
      if (pX + 1 <= gTerrain.MapX - 1) then
        Road := Road + byte(gTerrain.Land[pY, pX + 1].TileOverlay = toRoad) shl 1;
      if (pY + 1 <= gTerrain.MapY - 1) then
        Road := Road + byte(gTerrain.Land[pY + 1, pX].TileOverlay = toRoad) shl 2;
      if (pX - 1 >= 1) then
        Road := Road + byte(gTerrain.Land[pY, pX - 1].TileOverlay = toRoad) shl 3;
      ID := RoadsConnectivity[Road, 1];
      Rot := RoadsConnectivity[Road, 2];
      RenderTile(ID, pX, pY, Rot, DoHighlight, HighlightColor);
    end
    else if gTerrain.Land[pY, pX].TileOverlay <> toNone then
      RenderTile(TILE_OVERLAY_IDS[gTerrain.Land[pY, pX].TileOverlay], pX, pY, 0, DoHighlight, HighlightColor);
  end;
end;


procedure TRenderTerrain.DoOverlays(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
begin
  gPerfLogs.SectionEnter(psFrameOverlays);
  if gGame.IsMapEditor and not (mlOverlays in gGame.MapEditor.VisibleLayers) then
    Exit;

  for I := fClipRect.Top to fClipRect.Bottom do
    for K := fClipRect.Left to fClipRect.Right do
      RenderTileOverlay(aFOW, K, I);

  gPerfLogs.SectionLeave(psFrameOverlays);
end;


procedure TRenderTerrain.RenderFences(aFOW: TKMFogOfWarCommon);
var
  I,K: Integer;
begin
  if gGame.IsMapEditor and not (mlOverlays in gGame.MapEditor.VisibleLayers) then
    Exit;

  with gTerrain do
    for I := fClipRect.Top to fClipRect.Bottom do
      for K := fClipRect.Left to fClipRect.Right do
      begin
        if TileHasToBeRendered(False,K,I,aFow) then
        begin
          if Land[I,K].FenceSide and 1 = 1 then
            RenderFence(Land[I,K].Fence, dirN, K, I);
          if Land[I,K].FenceSide and 2 = 2 then 
            RenderFence(Land[I,K].Fence, dirE, K, I);
          if Land[I,K].FenceSide and 4 = 4 then 
            RenderFence(Land[I,K].Fence, dirW, K, I);
          if Land[I,K].FenceSide and 8 = 8 then 
            RenderFence(Land[I,K].Fence, dirS, K, I);
        end;
      end;
end;


//Player markings should be always clearly visible to the player (thats why we render them ontop FOW)
procedure TRenderTerrain.RenderPlayerPlans(aFieldsList: TKMPointTagList; aHousePlansList: TKMPointDirList);
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


procedure TRenderTerrain.DoLighting(aFOW: TKMFogOfWarCommon);
var
  I, K: Integer;
  SizeX, SizeY: Word;
  tX, tY: Word;
begin
  gPerfLogs.SectionEnter(psFrameLighting);
  glColor4f(1, 1, 1, 1);
  //Render highlights
  glBlendFunc(GL_DST_COLOR, GL_ONE);
  TRender.BindTexture(fTextG);

  if fUseVBO then
  begin
    if fTilesVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatTile);
    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TTileVerticeExt), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(1, GL_FLOAT, SizeOf(TTileVerticeExt), Pointer(20));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    SizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    SizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to SizeY do
        for K := 0 to SizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            if RENDER_3D then
            begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(Land[  tY,   tX].Light); glVertex3f(tX-1, tY-1, -Land[  tY,   tX].Height / CELL_HEIGHT_DIV);
                glTexCoord1f(Land[tY+1,   tX].Light); glVertex3f(tX-1,   tY, -Land[tY+1,   tX].Height / CELL_HEIGHT_DIV);
                glTexCoord1f(Land[tY+1, tX+1].Light); glVertex3f(  tX,   tY, -Land[tY+1, tX+1].Height / CELL_HEIGHT_DIV);
                glTexCoord1f(Land[  tY, tX+1].Light); glVertex3f(  tX, tY-1, -Land[  tY, tX+1].Height / CELL_HEIGHT_DIV);
              glEnd;
            end else begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(Land[  tY,   tX].Light); glVertex3f(tX-1, tY-1 - Land[  tY,   tX].Height / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(Land[tY+1,   tX].Light); glVertex3f(tX-1,   tY - Land[tY+1,   tX].Height / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(Land[tY+1, tX+1].Light); glVertex3f(  tX,   tY - Land[tY+1, tX+1].Height / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(Land[  tY, tX+1].Light); glVertex3f(  tX, tY-1 - Land[  tY, tX+1].Height / CELL_HEIGHT_DIV, tY-1);
              glEnd;
            end;
          end;
        end;
  end;
  gPerfLogs.SectionLeave(psFrameLighting);
end;


//Render shadows and FOW at once
procedure TRenderTerrain.DoShadows(aFOW: TKMFogOfWarCommon);
var
  I,K: Integer;
  SizeX, SizeY: Word;
  tX, tY: Word;
begin
  gPerfLogs.SectionEnter(psFrameShadows);
  glColor4f(1, 1, 1, 1);
  glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);
  TRender.BindTexture(fTextG);

  if fUseVBO then
  begin
    if fTilesVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatTile);
    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TTileVerticeExt), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(1, GL_FLOAT, SizeOf(TTileVerticeExt), Pointer(24));

    //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
    glDrawElements(GL_TRIANGLES, fTilesIndCount, GL_UNSIGNED_INT, Pointer(0));

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  end
  else
  begin
    SizeX := Max(fClipRect.Right - fClipRect.Left, 0);
    SizeY := Max(fClipRect.Bottom - fClipRect.Top, 0);
    with gTerrain do
      for I := 0 to SizeY do
        for K := 0 to SizeX do
        begin
          tX := K + fClipRect.Left;
          tY := I + fClipRect.Top;
          if TileHasToBeRendered(I*K = 0,tX,tY,aFow) then // Do not render tiles fully covered by FOW
          begin
            if RENDER_3D then
            begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(-Land[  tY,   tX].Light); glVertex3f(tX-1, tY-1, -Land[  tY,   tX].Height / CELL_HEIGHT_DIV);
                glTexCoord1f(-Land[tY+1,   tX].Light); glVertex3f(tX-1,   tY, -Land[tY+1,   tX].Height / CELL_HEIGHT_DIV);
                glTexCoord1f(-Land[tY+1, tX+1].Light); glVertex3f(  tX,   tY, -Land[tY+1, tX+1].Height / CELL_HEIGHT_DIV);
                glTexCoord1f(-Land[  tY, tX+1].Light); glVertex3f(  tX, tY-1, -Land[  tY, tX+1].Height / CELL_HEIGHT_DIV);
              glEnd;
            end else begin
              glBegin(GL_TRIANGLE_FAN);
                glTexCoord1f(-Land[  tY,   tX].Light); glVertex3f(tX-1, tY-1 - Land[  tY,   tX].Height / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(-Land[tY+1,   tX].Light); glVertex3f(tX-1,   tY - Land[tY+1,   tX].Height / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(-Land[tY+1, tX+1].Light); glVertex3f(  tX,   tY - Land[tY+1, tX+1].Height / CELL_HEIGHT_DIV, tY-1);
                glTexCoord1f(-Land[  tY, tX+1].Light); glVertex3f(  tX, tY-1 - Land[  tY, tX+1].Height / CELL_HEIGHT_DIV, tY-1);
              glEnd;
            end;
          end;
        end;
  end;

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  TRender.BindTexture(0);

  gPerfLogs.SectionLeave(psFrameShadows);
end;


//Render FOW at once
procedure TRenderTerrain.RenderFOW(aFOW: TKMFogOfWarCommon; aUseContrast: Boolean = False);
var
  I,K: Integer;
  Fog: PKMByte2Array;
begin
  gPerfLogs.SectionEnter(psFrameFOW);
  if aFOW is TKMFogOfWarOpen then Exit;

  glColor4f(1, 1, 1, 1);

  if aUseContrast then
  begin
    //Hide everything behind FOW with a sharp transition
    glColor4f(0, 0, 0, 1);
    TRender.BindTexture(fTextB);
  end
  else
  begin
    glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    TRender.BindTexture(fTextG);
  end;

  Fog := @TKMFogOfWar(aFOW).Revelation;
  if fUseVBO then
  begin
    if fTilesFowVtxCount = 0 then Exit; //Nothing to render
    BindVBOArray(vatFOW);
    
    //Setup vertex and UV layout and offsets
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, SizeOf(TTileFowVertice), Pointer(0));
    glClientActiveTexture(GL_TEXTURE0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(1, GL_FLOAT, SizeOf(TTileFowVertice), Pointer(12));

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
          glTexCoord1f(Fog^[I - 1, K - 1] / 255);
          glVertex3f(K - 1, I - 1, -Land[I, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[I, K - 1] / 255);
          glVertex3f(K - 1, I, -Land[I + 1, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[I, K] / 255);
          glVertex3f(K, I, -Land[I + 1, K + 1].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[I - 1, K] / 255);
          glVertex3f(K, I - 1, -Land[I, K + 1].Height / CELL_HEIGHT_DIV);
        glEnd;
      end
    else
      for I := fClipRect.Top to fClipRect.Bottom do
      for K := fClipRect.Left to fClipRect.Right do
      begin
        glBegin(GL_TRIANGLE_FAN);
          glTexCoord1f(Fog^[I - 1, K - 1] / 255);
          glVertex2f(K - 1, I - 1 - Land[I, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[I, K - 1] / 255);
          glVertex2f(K - 1, I - Land[I + 1, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[I, K] / 255);
          glVertex2f(K, I - Land[I + 1, K + 1].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[I - 1, K] / 255);
          glVertex2f(K, I - 1 - Land[I, K + 1].Height / CELL_HEIGHT_DIV);
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
          glTexCoord1f(Fog^[0, K - 1] / 255);
          glVertex2f(K - 1, I - 1 - Land[1, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[0, K - 1] / 255);
          glVertex2f(K - 1, I - Land[1, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[0, K] / 255);
          glVertex2f(K, I - Land[1, K + 1].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[0, K] / 255);
          glVertex2f(K, I - 1 - Land[1, K + 1].Height / CELL_HEIGHT_DIV);
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
          glTexCoord1f(Fog^[MapY-1, K - 1] / 255);
          glVertex2f(K - 1, MapY-1 - Land[MapY, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[MapY-1, K - 1] / 255);
          glVertex2f(K - 1, MapY - Land[MapY, K].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[MapY-1, K] / 255);
          glVertex2f(K, MapY-1 - Land[MapY, K + 1].Height / CELL_HEIGHT_DIV);
          glTexCoord1f(Fog^[MapY-1, K] / 255);
          glVertex2f(K, MapY - Land[MapY, K + 1].Height / CELL_HEIGHT_DIV);
        glEnd;
      end;
    end;

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  TRender.BindTexture(0);
  gPerfLogs.SectionLeave(psFrameFOW);
end;


procedure TRenderTerrain.BindVBOArray(aVBOArrayType: TVBOArrayType);
begin
  if fLastBindVBOArrayType = aVBOArrayType then Exit; // Do not to rebind for same tyle type

  case aVBOArrayType of
    vatTile:       if fTilesVtxCount > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxTilesShd);
                      glBufferData(GL_ARRAY_BUFFER, fTilesVtxCount * SizeOf(TTileVerticeExt), @fTilesVtx[0].X, GL_STREAM_DRAW);

                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndTilesShd);
                      glBufferData(GL_ELEMENT_ARRAY_BUFFER, fTilesIndCount * SizeOf(fTilesInd[0]), @fTilesInd[0], GL_STREAM_DRAW);
                    end else Exit;
    vatTileLayer:  if Length(fTilesLayersVtx) > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxTilesLayersShd);
                      glBufferData(GL_ARRAY_BUFFER, Length(fTilesLayersVtx) * SizeOf(TTileVertice), @fTilesLayersVtx[0].X, GL_STREAM_DRAW);

                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndTilesLayersShd);
                      glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(fTilesLayersInd) * SizeOf(fTilesLayersInd[0]), @fTilesLayersInd[0], GL_STREAM_DRAW);
                    end else Exit;
    vatAnimTile:   if fAnimTilesVtxCount > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxAnimTilesShd);
                      glBufferData(GL_ARRAY_BUFFER, fAnimTilesVtxCount * SizeOf(TTileVertice), @fAnimTilesVtx[0].X, GL_STREAM_DRAW);

                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndAnimTilesShd);
                      glBufferData(GL_ELEMENT_ARRAY_BUFFER, fAnimTilesIndCount * SizeOf(fAnimTilesInd[0]), @fAnimTilesInd[0], GL_STREAM_DRAW);
                    end else Exit;
    vatFOW:        if fTilesFowVtxCount > 0 then
                    begin
                      glBindBuffer(GL_ARRAY_BUFFER, fVtxTilesFowShd);
                      glBufferData(GL_ARRAY_BUFFER, fTilesFowVtxCount * SizeOf(TTileFowVertice), @fTilesFowVtx[0].X, GL_STREAM_DRAW);

                      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fIndTilesFowShd);
                      glBufferData(GL_ELEMENT_ARRAY_BUFFER, fTilesFowIndCount * SizeOf(fTilesFowInd[0]), @fTilesFowInd[0], GL_STREAM_DRAW);
                    end else Exit;
  end;
  fLastBindVBOArrayType := aVBOArrayType;
end;


//AnimStep - animation step for terrain (water/etc)
//aFOW - whose players FOW to apply
procedure TRenderTerrain.RenderBase(aAnimStep: Integer; aFOW: TKMFogOfWarCommon);
begin
  //VBO has proper vertice coords only for Light/Shadow
  //it cant handle 3D yet and because of FOW leaves terrain revealed, which is an exploit in MP
  //Thus we allow VBO only in 2D
  fUseVBO := DoUseVBO;

  UpdateVBO(aAnimStep, aFOW);

  gPerfLogs.SectionEnter(psFrameTerrainBase);

  DoTiles(aFOW);
  //It was 'unlit water goes above lit sand'
  //But there is no big difference there, that is why, to make possible transitions with water,
  //Water was put before DoLighting
  DoWater(aAnimStep, aFOW);
  //TileLayers after water, as water with animation is always base layer
  DoTilesLayers(aFOW);
  DoOverlays(aFOW);
  DoLighting(aFOW);
  DoShadows(aFOW);

  gPerfLogs.SectionLeave(psFrameTerrainBase);
end;


procedure TRenderTerrain.DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aDoBindTexture: Boolean; aUseTileLookup: Boolean;
                                      DoHighlight: Boolean = False; HighlightColor: Cardinal = 0;
                                      aBlendingLvl: Byte = 0);
var
  I: Integer;
  Corners: TKMTileCorners;
begin
  for I := 0 to 3 do
    Corners[I] := False;

  DoRenderTile(aTerrainId, pX,pY,Rot, Corners, aDoBindTexture, aUseTileLookup, DoHighlight, HighlightColor, aBlendingLvl);
end;


procedure TRenderTerrain.DoRenderTile(aTerrainId: Word; pX,pY,Rot: Integer; aCorners: TKMTileCorners; aDoBindTexture: Boolean;
                                      aUseTileLookup: Boolean; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0;
                                      aBlendingLvl: Byte = 0);
var
  TexC: TUVRect; // Texture UV coordinates
begin
  if not gTerrain.TileInMapCoords(pX,pY) then Exit;

  if DoHighlight then
    glColor4ub(HighlightColor and $FF, (HighlightColor shr 8) and $FF, (HighlightColor shr 16) and $FF, $FF)
  else
    glColor4f(1, 1, 1, 1);
  
  if aDoBindTexture then
    TRender.BindTexture(gGFXData[rxTiles, aTerrainId + 1].Tex.ID);

  if aUseTileLookup then
    TexC := fTileUVLookup[aTerrainId, Rot mod 4]
  else
    TexC := GetTileUV(aTerrainId, Rot mod 4);

  glBegin(GL_TRIANGLE_FAN);

  //TODO DoHighlight and HighlightColor is not considered here, we use always glColor4f(1, 1, 1, 1);
  if aBlendingLvl > 0 then
    RenderQuadTextureBlended(TexC, pX, pY, aCorners, aBlendingLvl)
  else
    RenderQuadTexture(TexC, pX, pY);

  glEnd;
end;


//Render single terrain cell
procedure TRenderTerrain.RenderTile(aTerrainId: Word; pX,pY,Rot: Integer; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
begin
  if not gTerrain.TileInMapCoords(pX,pY) then Exit;

  DoRenderTile(aTerrainId, pX, pY, Rot, True, True, DoHighlight, HighlightColor);
end;


//Render single terrain cell
procedure TRenderTerrain.RenderTile(pX,pY: Integer; aTileBasic: TKMTerrainTileBasic; DoHighlight: Boolean = False; HighlightColor: Cardinal = 0);
var
  L: Integer;
  DoBindTexture: Boolean;
begin
  if not gTerrain.TileInMapCoords(pX,pY) then Exit;

  DoBindTexture := not TKMResSprites.AllTilesOnOneAtlas;
  if not DoBindTexture then
    TRender.BindTexture(gGFXData[rxTiles, aTileBasic.BaseLayer.Terrain + 1].Tex.ID);

  // Render Base Layer
  DoRenderTile(aTileBasic.BaseLayer.Terrain, pX, pY, aTileBasic.BaseLayer.Rotation, DoBindTexture,
               False, DoHighlight, HighlightColor);

  // Render other Layers
  for L := 0 to aTileBasic.LayersCnt - 1 do
    DoRenderTile(aTileBasic.Layer[L].Terrain, pX, pY, aTileBasic.Layer[L].Rotation, aTileBasic.Layer[L].Corners,
                 DoBindTexture, False, DoHighlight, HighlightColor, aTileBasic.BlendingLvl);
    
end;


procedure TRenderTerrain.RenderFence(aFence: TKMFenceType; Pos: TKMDirection; pX,pY: Integer);
const
  FO = 4; //Fence overlap
  VO = -4; //Move fences a little down to avoid visible overlap when unit stands behind fence, but is rendered ontop of it, due to Z sorting algo we use
var
  UVa, UVb: TKMPointF;
  TexID: Integer;
  x1,y1,y2,FenceX, FenceY: Single;
  HeightInPx: Integer;
begin
  case aFence of
    fncHouseFence: if Pos in [dirN,dirS] then TexID:=463 else TexID:=467; //WIP (Wood planks)
    fncHousePlan:  if Pos in [dirN,dirS] then TexID:=105 else TexID:=117; //Plan (Ropes)
    fncWine:       if Pos in [dirN,dirS] then TexID:=462 else TexID:=466; //Fence (Wood)
    fncCorn:       if Pos in [dirN,dirS] then TexID:=461 else TexID:=465; //Fence (Stones)
    else          TexID := 0;
  end;

  //With these directions render fences on next tile
  if Pos = dirS then Inc(pY);
  if Pos = dirW then Inc(pX);

  if Pos in [dirN, dirS] then
  begin //Horizontal
    TRender.BindTexture(gGFXData[rxGui,TexID].Tex.ID);
    UVa.X := gGFXData[rxGui, TexID].Tex.u1;
    UVa.Y := gGFXData[rxGui, TexID].Tex.v1;
    UVb.X := gGFXData[rxGui, TexID].Tex.u2;
    UVb.Y := gGFXData[rxGui, TexID].Tex.v2;

    y1 := pY - 1 - (gTerrain.Land[pY, pX].Height + VO) / CELL_HEIGHT_DIV;
    y2 := pY - 1 - (gTerrain.Land[pY, pX + 1].Height + VO) / CELL_HEIGHT_DIV;

    FenceY := gGFXData[rxGui,TexID].PxWidth / CELL_SIZE_PX;
    glBegin(GL_QUADS);
      glTexCoord2f(UVb.x, UVa.y); glVertex2f(pX-1 -3/ CELL_SIZE_PX, y1);
      glTexCoord2f(UVa.x, UVa.y); glVertex2f(pX-1 -3/ CELL_SIZE_PX, y1 - FenceY);
      glTexCoord2f(UVa.x, UVb.y); glVertex2f(pX   +3/ CELL_SIZE_PX, y2 - FenceY);
      glTexCoord2f(UVb.x, UVb.y); glVertex2f(pX   +3/ CELL_SIZE_PX, y2);
    glEnd;
  end
  else
  begin //Vertical
    TRender.BindTexture(gGFXData[rxGui,TexID].Tex.ID);
    HeightInPx := Round(CELL_SIZE_PX * (1 + (gTerrain.Land[pY,pX].Height - gTerrain.Land[pY+1,pX].Height)/CELL_HEIGHT_DIV)+FO);
    UVa.X := gGFXData[rxGui, TexID].Tex.u1;
    UVa.Y := gGFXData[rxGui, TexID].Tex.v1;
    UVb.X := gGFXData[rxGui, TexID].Tex.u2;
    UVb.Y := Mix(gGFXData[rxGui, TexID].Tex.v2, gGFXData[rxGui, TexID].Tex.v1, HeightInPx / gGFXData[rxGui, TexID].pxHeight);

    y1 := pY - 1 - (gTerrain.Land[pY, pX].Height + FO + VO) / CELL_HEIGHT_DIV;
    y2 := pY - (gTerrain.Land[pY + 1, pX].Height + VO) / CELL_HEIGHT_DIV;

    FenceX := gGFXData[rxGui,TexID].PxWidth / CELL_SIZE_PX;

    case Pos of
      dirW:  x1 := pX - 1 - 3 / CELL_SIZE_PX;
      dirE:  x1 := pX - 1 + 3 / CELL_SIZE_PX - FenceX;
      else    x1 := pX - 1; //Should never happen
    end;

    glBegin(GL_QUADS);
      glTexCoord2f(UVa.x, UVa.y); glVertex2f(x1, y1);
      glTexCoord2f(UVb.x, UVa.y); glVertex2f(x1+ FenceX, y1);
      glTexCoord2f(UVb.x, UVb.y); glVertex2f(x1+ FenceX, y2);
      glTexCoord2f(UVa.x, UVb.y); glVertex2f(x1, y2);
    glEnd;
  end;
end;


procedure TRenderTerrain.RenderMarkup(pX, pY: Word; aFieldType: TKMFieldType);
const
  MarkupTex: array [TKMFieldType] of Word = (0, 105, 107, 108, 0);
var
  ID: Integer;
  UVa,UVb: TKMPointF;
begin
  ID := MarkupTex[aFieldType];

  TRender.BindTexture(gGFXData[rxGui, ID].Tex.ID);

  UVa.X := gGFXData[rxGui, ID].Tex.u1;
  UVa.Y := gGFXData[rxGui, ID].Tex.v1;
  UVb.X := gGFXData[rxGui, ID].Tex.u2;
  UVb.Y := gGFXData[rxGui, ID].Tex.v2;

  glBegin(GL_QUADS);
    glTexCoord2f(UVb.x, UVa.y); glVertex2f(pX-1, pY-1 - gTerrain.Land[pY  ,pX  ].Height/CELL_HEIGHT_DIV+0.10);
    glTexCoord2f(UVa.x, UVa.y); glVertex2f(pX-1, pY-1 - gTerrain.Land[pY  ,pX  ].Height/CELL_HEIGHT_DIV-0.15);
    glTexCoord2f(UVa.x, UVb.y); glVertex2f(pX  , pY   - gTerrain.Land[pY+1,pX+1].Height/CELL_HEIGHT_DIV-0.25);
    glTexCoord2f(UVb.x, UVb.y); glVertex2f(pX  , pY   - gTerrain.Land[pY+1,pX+1].Height/CELL_HEIGHT_DIV);

    glTexCoord2f(UVb.x, UVa.y); glVertex2f(pX-1, pY   - gTerrain.Land[pY+1,pX  ].Height/CELL_HEIGHT_DIV);
    glTexCoord2f(UVa.x, UVa.y); glVertex2f(pX-1, pY   - gTerrain.Land[pY+1,pX  ].Height/CELL_HEIGHT_DIV-0.25);
    glTexCoord2f(UVa.x, UVb.y); glVertex2f(pX  , pY-1 - gTerrain.Land[pY  ,pX+1].Height/CELL_HEIGHT_DIV-0.15);
    glTexCoord2f(UVb.x, UVb.y); glVertex2f(pX  , pY-1 - gTerrain.Land[pY  ,pX+1].Height/CELL_HEIGHT_DIV+0.10);
  glEnd;
end;


end.

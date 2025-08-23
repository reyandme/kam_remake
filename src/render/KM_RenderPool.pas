unit KM_RenderPool;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  KromOGLUtils, KromUtils,
  KM_Defaults, KM_CommonTypes, KM_CommonClasses, KM_Pics, KM_Points, KM_Render, KM_Viewport,
  KM_RenderTerrain, KM_Units, KM_HandEntity,
  KM_Houses, KM_CommonGameTypes, KM_RenderDebug,
  KM_ResTypes;

type
  TKMPaintLayer = (plTerrain, plObjects, plCursors);

  TKMRenderSprite = record
    Loc: TKMPointF; // Where sprite lower-left corner is located
    Feet: TKMPointF; // Feet of the sprite for FOW calculation (X;Y) and Z ordering (Y only)
    RX: TRXType;
    ID: Integer;
    UID: Integer;
    NewInst: Boolean;
    TeamColor: Cardinal;
    AlphaStep: Single; // Only apply-able to HouseBuild
    SelectionRect: TKMRectF; // Used for selecting units by sprite
  end;

  // List of sprites prepared to be rendered
  TKMRenderList = class
  private
    fUnitsRXData: TRXData; //shortcut
    fCount: Word;
    fRenderOrder: array of Word; // Order in which sprites will be drawn ()
    fRenderList: array of TKMRenderSprite;

    fDbgSpritesQueued: Word;
    fDbgSpritesDrawn: Word;

    procedure ClipRenderList;
    procedure SendToRender(aId: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddSprite(aRX: TRXType; aID: Integer; pX,pY: Single; aTeam: Cardinal = $0; aAlphaStep: Single = -1);
    procedure AddSpriteG(aRX: TRXType; aID: Integer; aUID: Integer; pX,pY,gX,gY: Single; aTeam: Cardinal = $0; aAlphaStep: Single = -1);

    property DbgSpritesQueued: Word read fDbgSpritesQueued;
    property DbgSpritesDrawn: Word read fDbgSpritesDrawn;

    function GetSelectionUID(const aCurPos: TKMPointF): Integer;
    procedure Clear;
    procedure SortRenderList;
    procedure Render;
  end;

  // Collect everything that need to be rendered and put it in a list
  TKMRenderPool = class
  private
    fCounter: Cardinal;
    fRXData: array [TRXType] of TRXData; // Shortcuts
    fViewport: TKMViewport;
    fRender: TKMRender;
    // fSampleHouse: TOBJModel;
    rPitch,rHeading,rBank: Integer;
    fRenderList: TKMRenderList;
    fRenderTerrain: TKMRenderTerrain;
    fRenderDebug: TKMRenderDebug;

    fFieldsList: TKMPointTagList;
    fHousePlansList: TKMPointDirList;
    fTabletsList: TKMPointTagList;
    fMarksList: TKMPointTagList;
    fHouseOutline: TKMPointList;

    procedure ApplyTransform;
    procedure SetDefaultRenderParams;
    procedure RenderBackgroundUI(const aRect: TKMRect);
    // Terrain overlay cursors rendering (incl. sprites highlighting)
    procedure RenderForegroundUI;
    procedure RenderForegroundUI_Brush;
    procedure RenderForegroundUI_ElevateEqualize;
    procedure RenderForegroundUI_ObjectsBrush;
    procedure RenderForegroundUI_Markers;
    procedure RenderForegroundUI_Units;
    procedure RenderForegroundUI_PaintBucket(aHighlightAll: Boolean);
    procedure RenderForegroundUI_UniversalEraser(aHighlightAll: Boolean);
    procedure DoRenderGroup(aUnitType: TKMUnitType; aLoc: TKMPointDir; aMembersCnt, aUnitsPerRow: Integer;  aHandColor: Cardinal);
    function TryRenderUnitOrGroup(aEntity: TKMHandEntity; aUnitFilterFunc, aGroupFilterFunc: TBooleanFunc; aUseGroupFlagColor, aDoHighlight: Boolean; aHandColor, aFlagColor: Cardinal; aHighlightColor: Cardinal = 0): Boolean;
    procedure RenderUnit(U: TKMUnit; const P: TKMPoint; aFlagColor: Cardinal; aDoHighlight: Boolean; aHighlightColor: Cardinal); overload;
    procedure RenderUnit(aUnitType: TKMUnitType; const P: TKMPointDir; aAnimStep: Integer; aFlagColor: Cardinal; aDoHighlight: Boolean = False; aHighlightColor: Cardinal = 0); overload;
    function PaintBucket_UnitToRender(aUnit: TObject): Boolean;
    function PaintBucket_GroupToRender(aGroup: TObject): Boolean;

    procedure RenderSprite(aRX: TRXType; aId: Integer; aX, aY: Single; aColor: TColor4; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0;
      aForced: Boolean = False);
    procedure RenderSpriteAlphaTest(aRX: TRXType; aId: Integer; aWoodProgress: Single; aX, aY: Single; aId2: Integer = 0; aStoneProgress: Single = 0; X2: Single = 0; Y2: Single = 0);
    procedure RenderMapElement1(aIndex: Word; aAnimStep: Cardinal; aLocX, aLocY: Integer; aLoopAnim: Boolean; aDoImmediateRender: Boolean = False; aDeleting: Boolean = False);
    procedure RenderMapElement4(aIndex: Word; aAnimStep: Cardinal; aLocX, aLocY: Integer; aIsDouble: Boolean; aDoImmediateRender: Boolean = False; aDeleting: Boolean = False);
    procedure RenderHouseOutline(aHouseSketch: TKMHouseSketch; aCol: Cardinal = icCyan);

    // Terrain rendering sub-class
    procedure CollectPlans(const aRect: TKMRect);
    procedure CollectTerrainObjects(const aRect: TKMRect; aAnimStep: Cardinal);
    procedure PaintFlagPoint(const aHouseEntrance, aFlagPoint: TKMPoint; aColor: Cardinal; aTexId: Integer; aFirstPass: Boolean;
                             aDoImmediateRender: Boolean = False);
    procedure PaintFlagPoints(aFirstPass: Boolean);

    procedure RenderWireHousePlan(const P: TKMPoint; aHouseType: TKMHouseType);
    procedure RenderTileOwnerLayer(const aRect: TKMRect);
    procedure RenderTilesGrid(const aRect: TKMRect);

    procedure RenderWireTileInt(const X,Y: Integer);
    procedure RenderTileInt(const X, Y: Integer);
  public
    constructor Create(aViewport: TKMViewport; aRender: TKMRender);
    destructor Destroy; override;

    procedure ReInit;

    procedure AddAlert(const aLoc: TKMPointF; aId: Integer; aFlagColor: TColor4);
    procedure AddProjectile(aProj: TKMProjectileType; const aRenderPos, aTilePos: TKMPointF; aDir: TKMDirection; aFlight: Single);
    procedure AddHouse(aHouse: TKMHouseType; const aLoc: TKMPoint; aWoodStep, aStoneStep, aSnowStep: Single; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
    procedure AddWholeHouse(H: TKMHouse; aFlagColor: Cardinal; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);

    procedure AddHouseTablet(aHouse: TKMHouseType; const aLoc: TKMPoint);
    procedure AddHouseBuildSupply(aHouse: TKMHouseType; const Loc: TKMPoint; Wood,Stone: Byte);
    procedure AddHouseWork(aHouse: TKMHouseType; const aLoc: TKMPoint; aActSet: TKMHouseActionSet; aAnimStep, aAnimStepPrev: Cardinal; aFlagColor: TColor4; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
    procedure AddHouseSupply(aHouse: TKMHouseType; const aLoc: TKMPoint; const R1, R2: array of Word; const R3: array of Byte; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
    procedure AddHouseMarketSupply(const aLoc: TKMPoint; aResType: TKMWareType; aResCount: Word; aAnimStep: Integer);
    procedure AddHouseStableBeasts(aHouse: TKMHouseType; const aLoc: TKMPoint; aBeastId,aBeastAge,aAnimStep: Integer; aRX: TRXType = rxHouses);
    procedure AddHouseEater(const Loc: TKMPoint; aUnit: TKMUnitType; aAct: TKMUnitActionType; aDir: TKMDirection; StepId: Integer; OffX,OffY: Single; FlagColor: TColor4);
    procedure AddUnit(aUnit: TKMUnitType; aUID: Integer; aAct: TKMUnitActionType; aDir: TKMDirection; StepId: Integer; StepFrac: Single; pX,pY: Single; FlagColor: TColor4; NewInst: Boolean; DoImmediateRender: Boolean = False; DoHighlight: Boolean = False; HighlightColor: TColor4 = 0);
    procedure AddUnitCarry(aCarry: TKMWareType; aUID: Integer; aDir: TKMDirection; StepId: Integer; StepFrac: Single; pX,pY: Single; FlagColor: TColor4);
    procedure AddUnitThought(aUnit: TKMUnitType; aAct: TKMUnitActionType; aDir: TKMDirection; Thought: TKMUnitThought; pX,pY: Single);
    procedure AddUnitFlag(aUnit: TKMUnitType; aAct: TKMUnitActionType; aDir: TKMDirection; FlagAnim: Integer; pX,pY: Single; FlagColor: TColor4; DoImmediateRender: Boolean = False);
    procedure AddUnitWithDefaultArm(aUnit: TKMUnitType; aUID: Integer; aAct: TKMUnitActionType; aDir: TKMDirection; StepId: Integer; pX,pY: Single; FlagColor: TColor4; DoImmediateRender: Boolean = False; DoHignlight: Boolean = False; HighlightColor: TColor4 = 0);

    procedure RenderMapElement(aIndex: Word; aAnimStep,pX,pY: Integer; aDoImmediateRender: Boolean = False; aDeleting: Boolean = False);
    procedure RenderSpriteOnTile(const aLoc: TKMPoint; aId: Integer; aFlagColor: TColor4 = $FFFFFFFF);
    procedure RenderSpriteOnTerrain(const aLoc: TKMPointF; aId: Integer; aFlagColor: TColor4 = $FFFFFFFF; aForced: Boolean = False);
    procedure RenderTile(aTerrainId: Word; pX,pY,Rot: Integer);
    procedure RenderWireTile(const P: TKMPoint; aCol: TColor4; aInset: Single = 0.0; aLineWidth: Single = -1);

    property RenderDebug: TKMRenderDebug read fRenderDebug;

    property RenderList: TKMRenderList read fRenderList;
    property RenderTerrain: TKMRenderTerrain read fRenderTerrain;
    procedure SetRotation(aH,aP,aB: Integer);

    procedure Render(aTickLag: Single);
  end;


var
  gRenderPool: TKMRenderPool;


implementation
uses
  Classes, SysUtils, Math,
  dglOpenGL,
  KM_Entity,
  KM_RenderAux, KM_RenderGameAux, KM_HandsCollection, KM_Game, KM_GameSettings, KM_Sound,
  KM_AIFields, KM_TerrainPainter, KM_Cursor,
  KM_Hand, KM_UnitGroup, KM_CommonUtils,
  KM_GameParams, KM_Utils, KM_ResTilesetTypes, KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_HandTypes,
  KM_Projectiles,
  KM_Terrain, KM_TerrainTypes,
  KM_Resource, KM_ResHouses, KM_ResInterpolation, KM_ResMapElements, KM_ResSprites, KM_ResUnits,
  KM_AITypes;


const
  DELETE_COLOR = $1616FF;
  INTERP_LEVEL = 8;


{ TKMRenderPool }
constructor TKMRenderPool.Create(aViewport: TKMViewport; aRender: TKMRender);
var
  RT: TRXType;
begin
  inherited Create;

  fCounter := 0;

  for RT := Low(TRXType) to High(TRXType) do
    fRXData[RT] := gRes.Sprites[RT].RXData;

  fRender := aRender;
  fViewport := aViewport;

  fRenderList     := TKMRenderList.Create;
  fRenderTerrain  := TKMRenderTerrain.Create;
  fRenderDebug    := TKMRenderDebug.Create;
  gRenderAux      := TKMRenderAux.Create;
  gRenderGameAux  := TKMRenderGameAux.Create;

  fFieldsList     := TKMPointTagList.Create;
  fHousePlansList := TKMPointDirList.Create;
  fTabletsList    := TKMPointTagList.Create;
  fMarksList      := TKMPointTagList.Create;
  fHouseOutline   := TKMPointList.Create;
  // fSampleHouse := TOBJModel.Create;
  // fSampleHouse.LoadFromFile(ExeDir + 'Store.obj');
end;


destructor TKMRenderPool.Destroy;
begin
  fFieldsList.Free;
  fHousePlansList.Free;
  fTabletsList.Free;
  fMarksList.Free;
  fHouseOutline.Free;
  // fSampleHouse.Free;
  fRenderList.Free;
  fRenderDebug.Free;
  fRenderTerrain.Free;
  gRenderGameAux.Free;
  gRenderAux.Free;

  inherited;
end;


procedure TKMRenderPool.ReInit;
begin
  if Self = nil then Exit;

  fRenderDebug.ReInit;
end;


procedure TKMRenderPool.SetRotation(aH, aP, aB: Integer);
begin
  rHeading := aH;
  rPitch   := aP;
  rBank    := aB;
end;


procedure TKMRenderPool.ApplyTransform;
var
  viewportPosRound: TKMPointF;
begin
  //Need to round the viewport position so we only translate by whole pixels
  viewportPosRound := RoundToTilePixel(fViewport.Position);

  glLoadIdentity; // Reset The View

  //Use integer division so we don't translate by half a pixel if clip is odd
  glTranslatef(fViewport.ViewportClip.X div 2, fViewport.ViewportClip.Y div 2, 0);

  glScalef(fViewport.Zoom*CELL_SIZE_PX, fViewport.Zoom*CELL_SIZE_PX, 1 / 256);

  glTranslatef(-viewportPosRound.X + gGame.ActiveInterface.ToolbarWidth/CELL_SIZE_PX/fViewport.Zoom, -viewportPosRound.Y, 0);

  if RENDER_3D then
  begin
    fRender.SetRenderMode(rm3D);

    glkScale(-CELL_SIZE_PX/14);
    glRotatef(rHeading,1,0,0);
    glRotatef(rPitch  ,0,1,0);
    glRotatef(rBank   ,0,0,1);
    glTranslatef(-viewportPosRound.X + gGame.ActiveInterface.ToolBarWidth/CELL_SIZE_PX/fViewport.Zoom, -viewportPosRound.Y - 8, 10);
    glScalef(fViewport.Zoom, fViewport.Zoom, 1);
  end;

  glRotatef(rHeading,1,0,0);
  glRotatef(rPitch  ,0,1,0);
  glRotatef(rBank   ,0,0,1);
  glTranslatef(0, 0, -viewportPosRound.Y);
end;


procedure TKMRenderPool.SetDefaultRenderParams;
begin
  glLineWidth(fViewport.Zoom * 2);
  glPointSize(fViewport.Zoom * 5);
  glEnable(GL_LINE_SMOOTH);
end;


// Render:
// 1. Sets viewport
// 2. Renders terrain
// 3. Polls Game objects to add themselves to RenderList through Add** methods
// 4. Renders cursor highlights
procedure TKMRenderPool.Render(aTickLag: Single);
var
  clipRect: TKMRect;
begin
  if fRender.Blind then Exit;

  Inc(fCounter);

  ApplyTransform;

  glPushAttrib(GL_LINE_BIT or GL_POINT_BIT);
    SetDefaultRenderParams;

    // Render only within visible area
    clipRect := fViewport.GetClip;

    fRenderDebug.ClipRect := clipRect;

    // Collect players plans for terrain layer
    CollectPlans(clipRect);

    // With depth test we can render all terrain tiles and then apply light/shadow without worrying about
    // foothills shadows going over mountain tops. Each tile strip is rendered an next Z plane.
    // Means that Z-test on gpu will take care of clipping the foothill shadows
    glEnable(GL_DEPTH_TEST);

    // Everything flat of terrain
    {$IFDEF PERFLOG}
    gPerfLogs.SectionEnter(psFrameTerrain);
    {$ENDIF}
    fRenderTerrain.ClipRect := clipRect;
    fRenderTerrain.RenderBase(gTerrain.AnimStep, gMySpectator.FogOfWar);

    // Disable depth test //and write to depth buffer,
    // so that terrain shadows could be applied seamlessly ontop
    glDisable(GL_DEPTH_TEST);

    if mlOverlays in gGameParams.VisibleLayers then
    begin
      fRenderTerrain.RenderFences(gMySpectator.FogOfWar);
      fRenderTerrain.RenderPlayerPlans(fFieldsList, fHousePlansList);
    end;

    if mlMiningRadius in gGameParams.VisibleLayers then
      fRenderDebug.PaintMiningRadius;

    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psFrameTerrain);
    {$ENDIF}

    // House highlight, debug display
    RenderBackgroundUI(clipRect);

    // Sprites are added by Terrain/Players/Projectiles, then sorted by position
    fRenderList.Clear;
    CollectTerrainObjects(clipRect, gTerrain.AnimStep);

    PaintFlagPoints(True);

    gHands.Paint(clipRect, aTickLag); // Units and houses
    gProjectiles.Paint(aTickLag);

    if gGame.GamePlayInterface <> nil then
      gGame.GamePlayInterface.Alerts.Paint(0);

    fRenderList.SortRenderList;
    fRenderList.Render;

    if mlDefencesAll in gGameParams.VisibleLayers then
      fRenderDebug.PaintDefences;

    fRenderTerrain.RenderFOW(gMySpectator.FogOfWar);

    // Alerts/rally second pass is rendered after FOW
    PaintFlagPoints(False);
    if gGame.GamePlayInterface <> nil then
      gGame.GamePlayInterface.Alerts.Paint(1);

    // Cursor overlays (including blue-wire plans), go on top of everything
    RenderForegroundUI;

  glPopAttrib;
end;


procedure TKMRenderPool.RenderBackgroundUI(const aRect: TKMRect);

  procedure HighlightUnit(U: TKMUnit; aCol: Cardinal); inline;
  begin
    gRenderAux.CircleOnTerrain(U.PositionF.X - 0.5 + U.GetSlide(axX),
                               U.PositionF.Y - 0.5 + U.GetSlide(axY),
                               0.4, aCol, icCyan);
  end;

  procedure HighlightEntity(aEntityH: TKMHighlightEntity);
  var
    I: Integer;
    G: TKMUnitGroup;
    col: Cardinal;
  begin
    if aEntityH.Entity = nil then Exit;
    
    case aEntityH.Entity.EntityType of
      etHouse:  RenderHouseOutline(TKMHouseSketch(aEntityH.Entity), aEntityH.Color); //fPositionF.X - 0.5 + GetSlide(axX), fPositionF.Y - 0.5 + GetSlide(axY), 0.35
      etUnit:   HighlightUnit(TKMUnit(aEntityH.Entity), GetRandomColorWSeed(aEntityH.Entity.UID));
      etGroup:  begin
                  G := TKMUnitGroup(aEntityH.Entity);
                  col := GetRandomColorWSeed(G.UID);
                  for I := 0 to G.Count - 1 do
                    HighlightUnit(G.Members[I], col);
                end;
    end;
  end;


var
  I, K: Integer;
begin
  //Reset Texture, just in case we forgot to do it inside some method
  TKMRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  HighlightEntity(gMySpectator.HighlightEntity);
  HighlightEntity(gMySpectator.HighlightDebug);
  HighlightEntity(gMySpectator.HighlightDebug2);
  HighlightEntity(gMySpectator.HighlightDebug3);

  if gGameParams.IsMapEditor then
    gGame.MapEditor.Paint(plTerrain, aRect);

  if gAIFields <> nil then
    gAIFields.Paint(aRect);

  if SHOW_WALK_CONNECT then
  begin
    glPushAttrib(GL_DEPTH_BUFFER_BIT);
      glDisable(GL_DEPTH_TEST);

      for I := aRect.Top to aRect.Bottom do
      for K := aRect.Left to aRect.Right do
        gRenderAux.Text(K, I, IntToStr(gTerrain.Land^[I,K].WalkConnect[wcWalk]), $FFFFFFFF);

    glPopAttrib;
  end;

  if SHOW_TERRAIN_WIRES then
    gRenderAux.Wires(aRect);

  if SHOW_TERRAIN_PASS <> 0 then
    gRenderGameAux.Passability(aRect, SHOW_TERRAIN_PASS);

  if SHOW_TERRAIN_IDS then
    gRenderGameAux.TileTerrainIDs(aRect);

  if SHOW_TERRAIN_KINDS then
    gRenderGameAux.TileTerrainKinds(aRect);

  if SHOW_TERRAIN_OVERLAYS then
    gRenderGameAux.TileTerrainOverlays(aRect);

  if SHOW_TERRAIN_HEIGHT then
    gRenderGameAux.TileTerrainHeight(aRect);

  if SHOW_JAM_METER then
    gRenderGameAux.TileTerrainJamMeter(aRect);

  if SHOW_TILE_OBJECT_ID then
    gRenderGameAux.TileTerrainTileObjectID(aRect);

  if SHOW_TILES_OWNER then
    RenderTileOwnerLayer(aRect);

  if SHOW_TREE_AGE then
    gRenderGameAux.TileTerrainTreeAge(aRect);

  if SHOW_FIELD_AGE then
    gRenderGameAux.TileTerrainFieldAge(aRect);

  if SHOW_TILE_LOCK then
    gRenderGameAux.TileTerrainTileLock(aRect);

  if SHOW_TILE_UNIT then
    gRenderGameAux.TileTerrainTileUnit(aRect);

  if SHOW_VERTEX_UNIT then
    gRenderGameAux.TileTerrainVertexUnit(aRect);

  if SHOW_TERRAIN_TILES_GRID then
    RenderTilesGrid(aRect);

  if SHOW_UNIT_MOVEMENT then
    gRenderAux.UnitMoves(aRect);

  if SHOW_VIEWPORT_POS and (gGame.ActiveInterface <> nil) then
    gGame.ActiveInterface.Viewport.Paint;
end;


procedure TKMRenderPool.CollectTerrainObjects(const aRect: TKMRect; aAnimStep: Cardinal);
var
  I, K: Integer;
begin
  if not (mlObjects in gGameParams.VisibleLayers) then Exit;

  if gGameParams.IsMapEditor then
    gGame.MapEditor.Paint(plObjects, aRect);

  with gTerrain do
    for I := aRect.Top to aRect.Bottom do
      for K := aRect.Left to aRect.Right do
      begin
        if (Land^[I, K].Obj <> OBJ_NONE) then
          RenderMapElement(Land^[I, K].Obj, AnimStep, K, I);
      end;

  // Falling trees are in a separate list
  with gTerrain do
    for I := 0 to FallingTrees.Count - 1 do
    begin
      RenderMapElement1(FallingTrees.Tag[I], aAnimStep - FallingTrees.Tag2[I], FallingTrees[I].X, FallingTrees[I].Y, False);
      Assert(AnimStep - FallingTrees.Tag2[I] <= 100, 'Falling tree overrun?');
    end;

  // Tablets on house plans, for self and allies
  fTabletsList.Clear;
  if gGameParams.IsReplayOrSpectate then
    if gMySpectator.FOWIndex = -1 then
      for I := 0 to gHands.Count - 1 do
        gHands[I].GetPlansTablets(fTabletsList, aRect)
    else
      gHands[gMySpectator.FOWIndex].GetPlansTablets(fTabletsList, aRect)
  else
    gMySpectator.Hand.GetPlansTablets(fTabletsList, aRect);

  for I := 0 to fTabletsList.Count - 1 do
    AddHouseTablet(TKMHouseType(fTabletsList.Tag[I]), fTabletsList[I]);
end;


procedure TKMRenderPool.PaintFlagPoint(const aHouseEntrance, aFlagPoint: TKMPoint; aColor: Cardinal; aTexId: Integer; aFirstPass: Boolean;
                                     aDoImmediateRender: Boolean = False);

  procedure RenderLineToPoint(const aP: TKMPointF);
  begin
    gRenderAux.LineOnTerrain(aHouseEntrance.X - 0.5, aHouseEntrance.Y - 0.5, aP.X, aP.Y, aColor, $F0F0, False);
  end;

var
  P: TKMPointF;
begin
  P := KMPointF(aFlagPoint.X - 0.5, aFlagPoint.Y - 0.5);
  if not aDoImmediateRender then
  begin
    if aFirstPass then
    begin
      AddAlert(P, aTexId, aColor);
      RenderLineToPoint(P);
    end
    else
    if gMySpectator.FogOfWar.CheckRevelation(P) < FOG_OF_WAR_MAX then
      RenderSpriteOnTerrain(P, aTexId, aColor, True); //Force to paint, even under FOW
  end
  else begin
    RenderSpriteOnTile(aFlagPoint, aTexId, aColor);
    RenderLineToPoint(P);
  end;
end;


procedure TKMRenderPool.PaintFlagPoints(aFirstPass: Boolean);
var
  house: TKMHouseWFlagPoint;
begin
  // Skip render if no house with flagpoint is chosen
  if not (gMySpectator.Selected is TKMHouseWFlagPoint) then
    Exit;

  house := TKMHouseWFlagPoint(gMySpectator.Selected);
  if house.IsFlagPointSet then
    PaintFlagPoint(house.Entrance, house.FlagPoint, gHands[house.Owner].GameFlagColor, gRes.Houses[house.HouseType].FlagPointTexId, aFirstPass);
end;


procedure TKMRenderPool.RenderTile(aTerrainId: Word; pX, pY, Rot: Integer);
begin
  fRenderTerrain.RenderTile(aTerrainId, pX, pY, Rot);
end;


procedure TKMRenderPool.RenderMapElement(aIndex: Word; aAnimStep,pX,pY: Integer; aDoImmediateRender: Boolean = False; aDeleting: Boolean = False);
begin
  if (gMySpectator.FogOfWar.CheckVerticeRenderRev(pX,pY) <= FOG_OF_WAR_MIN) then Exit;// Do not render tiles fully covered by FOW
  // Render either normal object or quad depending on what it is
  if gMapElements[aIndex].WineOrCorn then
    RenderMapElement4(aIndex,aAnimStep,pX,pY,(aIndex in [54..57]),aDoImmediateRender,aDeleting) // 54..57 are grapes, all others are doubles
  else
    RenderMapElement1(aIndex,aAnimStep,pX,pY,True,aDoImmediateRender,aDeleting);
end;


procedure TKMRenderPool.RenderMapElement1(aIndex: Word; aAnimStep: Cardinal; aLocX, aLocY: Integer; aLoopAnim: Boolean; aDoImmediateRender: Boolean = False;
  aDeleting: Boolean = False);
var
  pX, pY: Integer;
  cornerX, cornerY: Single;
  gX, gY: Single;
  Id, Id0: Integer;
  FOW: Byte;
begin
  if (gMySpectator.FogOfWar.CheckVerticeRenderRev(aLocX, aLocY) <= FOG_OF_WAR_MIN) then Exit;

  if aIndex = OBJ_BLOCK then
  begin
    // Invisible wall
    // Render as a red outline in map editor mode
    if gGameParams.IsMapEditor then
    begin
      gRenderAux.Quad(aLocX, aLocY, $600000FF);
      RenderWireTile(KMPoint(aLocX, aLocY), $800000FF);
    end;
  end
  else
  begin
    if gMapElements[aIndex].Anim.Count = 0 then Exit;

    if gGameParams.DynamicFOW then
    begin
      FOW := gMySpectator.FogOfWar.CheckTileRevelation(aLocX, aLocY);
      if FOW <= 128 then aAnimStep := 0; // Stop animation
    end;
    Id := gRes.Interpolation.Tree(aIndex, aAnimStep, gGameParams.TickFrac, aLoopAnim);
    Id0 := gMapElements[aIndex].Anim.Step[1] + 1;
    if Id <= 0 then exit;

    var rxData: PRXData := @fRXData[rxTrees];
    pX := aLocX - 1;
    pY := aLocY - 1;
    gX := pX + (rxData.Pivot[Id0].X + rxData.Size[Id0].X/2) / CELL_SIZE_PX;
    gY := pY + (rxData.Pivot[Id0].Y + rxData.Size[Id0].Y) / CELL_SIZE_PX;
    cornerX := pX + rxData.Pivot[Id].X / CELL_SIZE_PX;
    cornerY := pY - gTerrain.RenderHeightAt(gX, gY) + (rxData.Pivot[Id].Y + rxData.Size[Id].Y) / CELL_SIZE_PX;
    if aDoImmediateRender then
      RenderSprite(rxTrees, Id, cornerX, cornerY, $FFFFFFFF, aDeleting, DELETE_COLOR)
    else
      fRenderList.AddSpriteG(rxTrees, Id, 0, cornerX, cornerY, gX, gY);
  end;
end;


// 4 objects packed on 1 tile for Corn and Grapes
procedure TKMRenderPool.RenderMapElement4(aIndex: Word; aAnimStep: Cardinal; aLocX, aLocY: Integer; aIsDouble: Boolean; aDoImmediateRender: Boolean = False;
  aDeleting: Boolean = False);
var
  R: TRXData;

  procedure AddSpriteBy(aAnimStep: Integer; aLocSubX, aLocSubY: Single);
  var
    Id, Id0: Integer;
    CornerX, CornerY, gX, gY: Single;
  begin
    Id := gRes.Interpolation.Tree(aIndex, aAnimStep, gGameParams.TickFrac, True);
    Id0 := gMapElements[aIndex].Anim.Step[1] + 1;

    gX := aLocSubX + (R.Pivot[Id0].X + R.Size[Id0].X/2) / CELL_SIZE_PX;
    gY := aLocSubY + (R.Pivot[Id0].Y + R.Size[Id0].Y) / CELL_SIZE_PX;
    CornerX := aLocSubX + R.Pivot[Id].X / CELL_SIZE_PX;
    CornerY := aLocSubY - gTerrain.RenderHeightAt(gX, gY) + (R.Pivot[Id].Y + R.Size[Id].Y) / CELL_SIZE_PX;

    if aDoImmediateRender then
      RenderSprite(rxTrees, Id, CornerX, CornerY, $FFFFFFFF, aDeleting, DELETE_COLOR)
    else
      fRenderList.AddSpriteG(rxTrees, Id, 0, CornerX, CornerY, gX, gY);
  end;

var
  FOW: Byte;
begin
  if gGameParams.DynamicFOW then
  begin
    FOW := gMySpectator.FogOfWar.CheckTileRevelation(aLocX, aLocY);
    // Stop animation under FOW
    if FOW <= 128 then
      aAnimStep := 0;
  end;

  R := fRXData[rxTrees];
  if aIsDouble then
  begin
    AddSpriteBy(aAnimStep  , aLocX - 0.75, aLocY - 0.6);
    AddSpriteBy(aAnimStep+1, aLocX - 0.25, aLocY - 0.6);
  end
  else
  begin
    AddSpriteBy(aAnimStep  , aLocX - 0.75, aLocY - 0.75);
    AddSpriteBy(aAnimStep+1, aLocX - 0.25, aLocY - 0.75);
    AddSpriteBy(aAnimStep+1, aLocX - 0.75, aLocY - 0.25);
    AddSpriteBy(aAnimStep  , aLocX - 0.25, aLocY - 0.25);
  end;
end;


// Render alert
procedure TKMRenderPool.AddAlert(const aLoc: TKMPointF; aId: Integer; aFlagColor: TColor4);
var
  cornerX, cornerY: Single;
  R: TRXData;
begin
  R := fRXData[rxGui];

  cornerX := aLoc.X + R.Pivot[aId].X / CELL_SIZE_PX;
  cornerY := gTerrain.RenderFlatToHeight(aLoc).Y + R.Pivot[aId].Y / CELL_SIZE_PX;

  fRenderList.AddSpriteG(rxGui, aId, 0, cornerX, cornerY, aLoc.X, aLoc.Y, aFlagColor);
end;


// Render house WIP tablet
procedure TKMRenderPool.AddHouseTablet(aHouse: TKMHouseType; const aLoc: TKMPoint);
var
  Id: Integer;
  cornerX, cornerY, gX, gY: Single;
  R: TRXData;
begin
  R := fRXData[rxGui];
  Id := gRes.Houses[aHouse].TabletIcon;

  gX := aLoc.X + (R.Pivot[Id].X + R.Size[Id].X / 2) / CELL_SIZE_PX - 0.5;
  gY := aLoc.Y + (R.Pivot[Id].Y + R.Size[Id].Y) / CELL_SIZE_PX - 0.45;
  cornerX := aLoc.X + R.Pivot[Id].X / CELL_SIZE_PX - 0.25;
  cornerY := aLoc.Y - gTerrain.RenderHeightAt(gX, gY) + (R.Pivot[Id].Y + R.Size[Id].Y) / CELL_SIZE_PX - 0.55;
  fRenderList.AddSpriteG(rxGui, Id, 0, cornerX, cornerY, gX, gY);
end;


// Render house build supply
procedure TKMRenderPool.AddHouseBuildSupply(aHouse: TKMHouseType; const Loc: TKMPoint; Wood, Stone: Byte);
var
  rx: TRXData;
  id: Integer;
  supply: THouseBuildSupply;
  cornerX, cornerY: Single;
begin
  rx := fRXData[rxHouses];
  supply := gRes.Houses[aHouse].BuildSupply;

  if Wood <> 0 then
  begin
    id := 260 + Wood - 1;
    cornerX := Loc.X + supply[1, Wood].MoveX / CELL_SIZE_PX - 1;
    cornerY := Loc.Y + (supply[1, Wood].MoveY + rx.Size[id].Y) / CELL_SIZE_PX - 1
                     - gTerrain.LandExt^[Loc.Y + 1, Loc.X].RenderHeight / CELL_HEIGHT_DIV;
    fRenderList.AddSprite(rxHouses, id, cornerX, cornerY);
  end;

  if Stone <> 0 then
  begin
    id := 267 + Stone - 1;
    cornerX := Loc.X + supply[2, Stone].MoveX / CELL_SIZE_PX - 1;
    cornerY := Loc.Y + (supply[2, Stone].MoveY + rx.Size[id].Y) / CELL_SIZE_PX - 1
                     - gTerrain.LandExt^[Loc.Y + 1, Loc.X].RenderHeight / CELL_HEIGHT_DIV;
    fRenderList.AddSprite(rxHouses, id, cornerX, cornerY);
  end;
end;


procedure TKMRenderPool.AddWholeHouse(H: TKMHouse; aFlagColor: Cardinal; aDoImmediateRender: Boolean = False;
  aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
begin
  if H <> nil then
  begin
    AddHouse(H.HouseType, H.Position, 1, 1, 0, aDoImmediateRender, aDoHighlight, aHighlightColor);
    AddHouseSupply(H.HouseType, H.Position, H.WareInArray, H.WareOutArray, H.WareOutPoolArray, aDoImmediateRender, aDoHighlight, aHighlightColor);
    if H.CurrentAction <> nil then
      gRenderPool.AddHouseWork(H.HouseType, H.Position, H.CurrentAction.SubAction, H.WorkAnimStep, H.WorkAnimStepPrev, aFlagColor, aDoImmediateRender, aDoHighlight, aHighlightColor);
  end;
end;


// Render house in wood
procedure TKMRenderPool.AddHouse(aHouse: TKMHouseType; const aLoc: TKMPoint; aWoodStep, aStoneStep, aSnowStep: Single;
                               aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
var
  rxData: TRXData;
  picWood, picStone, picSnow: Integer;
  groundWood, groundStone, gX, gY: Single;

  function CornerX(aPic: Integer): Single;
  begin
    Result := aLoc.X + rxData.Pivot[aPic].X / CELL_SIZE_PX - 1;
  end;

  function CornerY(aPic: Integer): Single;
  begin
    Result := aLoc.Y + (rxData.Pivot[aPic].Y + rxData.Size[aPic].Y) / CELL_SIZE_PX - 1
                     - gTerrain.LandExt^[aLoc.Y + 1, aLoc.X].RenderHeight / CELL_HEIGHT_DIV;
  end;

begin
  // We cannot skip when WoodStep = 0 because building supply is rendered as a child.
  // Instead RenderSpriteAlphaTest will skip rendering when WoodStep = 0

  rxData := fRXData[rxHouses];

  picWood := gRes.Houses[aHouse].WoodPic + 1;
  picStone := gRes.Houses[aHouse].StonePic + 1;
  picSnow := gRes.Houses[aHouse].SnowPic + 1;

  groundWood := rxData.Pivot[picWood].Y + rxData.Size[picWood].Y;
  groundStone := rxData.Pivot[picStone].Y + rxData.Size[picStone].Y;

  gX := aLoc.X + (rxData.Pivot[picWood].X + rxData.Size[picWood].X / 2) / CELL_SIZE_PX - 1;
  gY := aLoc.Y + Max(groundWood, groundStone) / CELL_SIZE_PX - 1.5;

  // If it's fully built we can render without alpha
  if (aWoodStep = 1) and (aStoneStep = 1) then
  begin
    // Snow only happens on fully built houses
    if gGameSettings.GFX.AllowSnowHouses
      and (aSnowStep > 0)
      and (picSnow <> 0) then
    begin
      // If snow is 100% we only need to render snow sprite
      if aSnowStep = 1 then
        fRenderList.AddSpriteG(rxHouses, picSnow, 0, CornerX(picSnow), CornerY(picSnow), gX, gY, $0)
      else
      begin
        // Render stone with snow blended on top using AlphaTest
        fRenderList.AddSpriteG(rxHouses, picStone, 0, CornerX(picStone), CornerY(picStone), gX, gY, $0);
        fRenderList.AddSpriteG(rxHouses, picSnow, 0, CornerX(picSnow), CornerY(picSnow), gX, gY, $0, aSnowStep);
      end;
    end
    else if aDoImmediateRender then
      RenderSprite(rxHouses, picStone, CornerX(picStone), CornerY(picStone), $0, aDoHighlight, aHighlightColor)
    else
      fRenderList.AddSpriteG(rxHouses, picStone, 0, CornerX(picStone), CornerY(picStone), gX, gY, $0);
  end
  else
  begin
    // Wood part of the house (may be seen below Stone part before construction is complete, e.g. Sawmill)
    fRenderList.AddSpriteG(rxHouses, picWood, 0, CornerX(picWood), CornerY(picWood), gX, gY, $0, aWoodStep);
    if aStoneStep > 0 then
      fRenderList.AddSprite(rxHouses, picStone, CornerX(picStone), CornerY(picStone), $0, aStoneStep);
  end;
end;


procedure TKMRenderPool.AddHouseWork(aHouse: TKMHouseType; const aLoc: TKMPoint; aActSet: TKMHouseActionSet; aAnimStep, aAnimStepPrev: Cardinal;
                                   aFlagColor: TColor4; aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
var
  id: Cardinal;
  AT: TKMHouseActionType;
  A: TKMAnimLoop;
  rxData: TRXData;
  cornerX, cornerY: Single;
const
  //These house actions should animate smoothly and continuously, regardless of AnimStep
  CONTINUOUS_ANIMS: TKMHouseActionSet = [
    haSmoke, haFlagpole,
    haFlag1, haFlag2, haFlag3,
    haFire1, haFire2, haFire3, haFire4, haFire5, haFire6, haFire7, haFire8
  ];
begin
  if aActSet = [] then Exit;

  rxData := fRXData[rxHouses];

  //See if action is in set and render it
  for AT := Low(TKMHouseActionType) to High(TKMHouseActionType) do
  if AT in aActSet then
  begin
    A := gRes.Houses[aHouse].Anim[AT];
    if A.Count > 0 then
    begin
      if AT in CONTINUOUS_ANIMS then
        id := gRes.Interpolation.House(aHouse, AT, gTerrain.AnimStep, gGameParams.TickFrac)
      else
      begin
        //If the anim step is able to be interpolated from the last frame (to avoid incorrect looping)
        if aAnimStep = aAnimStepPrev+1 then
          id := gRes.Interpolation.House(aHouse, AT, aAnimStepPrev, gGameParams.TickFrac)
        else
          id := A.Step[aAnimStep mod Byte(A.Count) + 1] + 1;
      end;

      cornerX := aLoc.X + (rxData.Pivot[id].X + A.MoveX) / CELL_SIZE_PX - 1;
      cornerY := aLoc.Y + (rxData.Pivot[id].Y + A.MoveY + rxData.Size[id].Y) / CELL_SIZE_PX - 1
                       - gTerrain.LandExt^[aLoc.Y + 1, aLoc.X].RenderHeight / CELL_HEIGHT_DIV;

      if aDoImmediateRender then
        RenderSprite(rxHouses, id, cornerX, cornerY, aFlagColor, aDoHighlight, aHighlightColor)
      else
        fRenderList.AddSprite(rxHouses, id, cornerX, cornerY, aFlagColor);
    end;
  end;
end;


procedure TKMRenderPool.AddHouseSupply(aHouse: TKMHouseType; const aLoc: TKMPoint; const R1, R2: array of Word; const R3: array of Byte;
                                     aDoImmediateRender: Boolean = False; aDoHighlight: Boolean = False; aHighlightColor: TColor4 = 0);
var
  id, I, K, I2, count: Integer;
  rxData: TRXData;

  procedure AddHouseSupplySprite(aId: Integer);
  var
    CornerX, CornerY: Single;
  begin
    if aId = 0 then Exit;

    CornerX := aLoc.X + rxData.Pivot[aId].X / CELL_SIZE_PX - 1;
    CornerY := aLoc.Y + (rxData.Pivot[aId].Y + rxData.Size[aId].Y) / CELL_SIZE_PX - 1
                     - gTerrain.LandExt^[aLoc.Y + 1, aLoc.X].RenderHeight / CELL_HEIGHT_DIV;
    if aDoImmediateRender then
    begin
      RenderSprite(rxHouses, aId, CornerX, CornerY, $0, aDoHighlight, aHighlightColor);
    end else
      fRenderList.AddSprite(rxHouses, aId, CornerX, CornerY);
  end;

begin
  rxData := fRXData[rxHouses];

  for I := 1 to 4 do
  if R1[I - 1] > 0 then
  begin
    count := Min(R1[I - 1], MAX_WARES_IN_HOUSE);
    I2 := I;

    // Need to swap Coal and Steel for the ArmorSmithy
    // For some reason KaM stores these wares in swapped order, here we fix it (1 <-> 2)
    if (aHouse = htArmorSmithy) and (I in [1,2]) then
      I2 := 3-I;

    // Need to swap Timber and Leather for the ArmorWorkshop
    // For some reason KaM stores these wares in swapped order, here we fix it (1 <-> 2)
    if (aHouse = htArmorWorkshop) and (I in [1,2]) then
      I2 := 3-I;

    id := gRes.Houses[aHouse].SupplyIn[I2, count] + 1;
    AddHouseSupplySprite(id);
  end;

  if gRes.Houses[aHouse].IsWorkshop then
  begin
    for K := 0 to 19 do
      if R3[K] > 0 then
      begin
        I2 := R3[K];

        // Need to swap Shields and Armor for the ArmorWorkshop
        // For some reason KaM stores these wares in swapped order, here we fix it (1 <-> 2)
//        if (aHouse = htArmorWorkshop) and (I2 in [1,2]) then
//          I2 := 3-R3[K];

        id := gRes.Houses[aHouse].SupplyOut[I2, K mod MAX_WARES_IN_HOUSE + 1] + 1;
        AddHouseSupplySprite(id);
      end;
  end
  else
  begin
    for I := 1 to 4 do
      if R2[I - 1] > 0 then
      begin
        count := Min(R2[I - 1], MAX_WARES_IN_HOUSE);
        id := gRes.Houses[aHouse].SupplyOut[I, count] + 1;
        AddHouseSupplySprite(id);
      end;
  end;
end;


procedure TKMRenderPool.AddHouseMarketSupply(const aLoc: TKMPoint; aResType: TKMWareType; aResCount: Word; aAnimStep: Integer);
var
  I, id: Integer;
  cornerX, cornerY: Single;
  rxData: TRXData;
begin
  if aResType = wtHorse then // Horses are a beast, BeastId is the count, age is 1
    for I := 1 to Min(aResCount, MARKET_WARES[aResType].Count) do // Render each beast
      AddHouseStableBeasts(htMarket, aLoc, I, 1, aAnimStep, rxHouses)
  else
  begin
    if MARKET_WARES[aResType].Count = 0 then Exit;
    id := (MARKET_WARES[aResType].TexStart-1) + Min(aResCount, MARKET_WARES[aResType].Count);
    if id = 0 then Exit;

    rxData := fRXData[rxHouses];
    cornerX := aLoc.X + (rxData.Pivot[id].X + MARKET_WARES_OFF_X) / CELL_SIZE_PX - 1;
    cornerY := aLoc.Y + (rxData.Pivot[id].Y + MARKET_WARES_OFF_Y + rxData.Size[id].Y) / CELL_SIZE_PX - 1
                     - gTerrain.LandExt^[aLoc.Y+1,aLoc.X].RenderHeight / CELL_HEIGHT_DIV;
    fRenderList.AddSprite(rxHouses, id, cornerX, cornerY);
  end;
end;


procedure TKMRenderPool.AddHouseStableBeasts(aHouse: TKMHouseType; const aLoc: TKMPoint; aBeastId, aBeastAge, aAnimStep: Integer; aRX: TRXType = rxHouses);
var
  cornerX, cornerY: Single;
  id: Integer;
  rxData: TRXData;
  A: TKMAnimLoop;
begin
  rxData := fRXData[aRX];

  A := gRes.Houses.BeastAnim[aHouse,aBeastId,aBeastAge];

  id := gRes.Interpolation.Beast(aHouse, aBeastId, aBeastAge, aAnimStep, gGameParams.TickFrac);

  cornerX := aLoc.X + (A.MoveX + rxData.Pivot[id].X) / CELL_SIZE_PX - 1;
  cornerY := aLoc.Y + (A.MoveY + rxData.Pivot[id].Y + rxData.Size[id].Y) / CELL_SIZE_PX - 1
                   - gTerrain.LandExt^[aLoc.Y + 1, aLoc.X].RenderHeight / CELL_HEIGHT_DIV;
  fRenderList.AddSprite(aRX, id, cornerX, cornerY);
end;


// aRenderPos has gTerrain.HeightAt factored in already, aTilePos is on tile coordinates for Z ordering
procedure TKMRenderPool.AddProjectile(aProj: TKMProjectileType; const aRenderPos, aTilePos: TKMPointF; aDir: TKMDirection; aFlight: Single);
var
  FOW: Byte;
  id: Integer;
  rxData: TRXData;
  cornerX, cornerY: Single;
  ground: Single;
begin
  // We don't care about off-map arrows, but still we get TKMPoint error if X/Y gets negative
  if not gTerrain.TileInMapCoords(Round(aRenderPos.X), Round(aRenderPos.Y)) then Exit;

  if gGameParams.DynamicFOW then
  begin
    FOW := gMySpectator.FogOfWar.CheckRevelation(aRenderPos);
    if FOW <= 128 then Exit; // Don't render objects which are behind FOW
  end;

  case aProj of
    ptArrow:     id := gRes.Interpolation.UnitActionByPercent(utBowman, uaSpec, aDir, aFlight);
    ptBolt:      id := gRes.Interpolation.UnitActionByPercent(utCrossbowman, uaSpec, aDir, aFlight);
    ptSlingRock: id := gRes.Interpolation.UnitActionByPercent(utRogue, uaSpec, aDir, aFlight);
    ptTowerRock: id := gRes.Interpolation.UnitActionByPercent(utRecruit, uaSpec, aDir, aFlight);
    else          id := 1; // Nothing?
  end;

  rxData := fRXData[rxUnits];

  cornerX := rxData.Pivot[id].X / CELL_SIZE_PX - 1;
  cornerY := (rxData.Pivot[id].Y + rxData.Size[id].Y) / CELL_SIZE_PX - 1;

  case aProj of
    ptArrow, ptBolt, ptSlingRock:  ground := aTilePos.Y + (0.5 - Abs(Min(aFlight, 1) - 0.5)) - 0.5;
    ptTowerRock:                     ground := aTilePos.Y + Min(aFlight, 1)/5 - 0.4;
    else                              ground := aTilePos.Y - 1; // Nothing?
  end;

  fRenderList.AddSpriteG(rxUnits, id, 0, aRenderPos.X + cornerX, aRenderPos.Y + cornerY, aTilePos.X - 1, ground);
end;


procedure TKMRenderPool.AddUnit(aUnit: TKMUnitType; aUID: Integer; aAct: TKMUnitActionType; aDir: TKMDirection; StepId: Integer; StepFrac: Single;
                              pX,pY: Single; FlagColor: TColor4; NewInst: Boolean; DoImmediateRender: Boolean = False;
                              DoHighlight: Boolean = False; HighlightColor: TColor4 = 0);
var
  cornerX, cornerY, ground: Single;
  id, id0: Integer;
  R: TRXData;
begin
  id := gRes.Interpolation.UnitAction(aUnit, aAct, aDir, StepId, StepFrac);
  id0 := gRes.Interpolation.UnitAction(aUnit, aAct, aDir, UNIT_STILL_FRAMES[aDir], 0.0);
  if id <= 0 then exit;
  R := fRXData[rxUnits];

  cornerX := pX + R.Pivot[id].X / CELL_SIZE_PX;
  cornerY := gTerrain.RenderFlatToHeight(pX, pY) + (R.Pivot[id].Y + R.Size[id].Y) / CELL_SIZE_PX;
  ground := pY + (R.Pivot[id0].Y + R.Size[id0].Y) / CELL_SIZE_PX;

  if DoImmediateRender then
    RenderSprite(rxUnits, id, cornerX, cornerY, FlagColor, DoHighlight, HighlightColor)
  else
    if NewInst then
      fRenderList.AddSpriteG(rxUnits, id, aUID, cornerX, cornerY, pX, ground, FlagColor)
    else
      fRenderList.AddSprite(rxUnits, id, cornerX, cornerY, FlagColor);

  if SHOW_UNIT_MOVEMENT then
  if NewInst then
  begin
    gRenderAux.DotOnTerrain(pX, pY, FlagColor);
    gRenderAux.Dot(cornerX, cornerY, $FF000080);
  end;
end;


procedure TKMRenderPool.AddHouseEater(const Loc: TKMPoint; aUnit: TKMUnitType; aAct: TKMUnitActionType; aDir: TKMDirection; StepId: Integer; OffX,OffY: Single; FlagColor: TColor4);
var
  cornerX, cornerY: Single;
  id: Integer;
  R: TRXData;
begin
  id := gRes.Interpolation.UnitAction(aUnit, aAct, aDir, StepId, gGameParams.TickFrac);
  if id <= 0 then exit;
  R := fRXData[rxUnits];

  // Eaters need to interpolate land height the same as the inn otherwise they are rendered at the wrong place
  cornerX := Loc.X + OffX + R.Pivot[id].X / CELL_SIZE_PX - 1;
  cornerY := Loc.Y + OffY + (R.Pivot[id].Y + R.Size[id].Y) / CELL_SIZE_PX - 1
                   - gTerrain.LandExt^[Loc.Y + 1, Loc.X].RenderHeight / CELL_HEIGHT_DIV;

  fRenderList.AddSprite(rxUnits, id, cornerX, cornerY, FlagColor);
end;


procedure TKMRenderPool.AddUnitCarry(aCarry: TKMWareType; aUID: Integer; aDir: TKMDirection; StepId: Integer; StepFrac: Single; pX,pY: Single; FlagColor: TColor4);
var
  cornerX, cornerY: Single;
  id: Integer;
  A: TKMAnimLoop;
  R: TRXData;
begin
  A := gRes.Units.SerfCarry[aCarry, aDir];
  id := gRes.Interpolation.SerfCarry(aCarry, aDir, StepId, StepFrac);

  if id <= 0 then Exit;
  R := fRXData[rxUnits];

  cornerX := pX + (R.Pivot[id].X + A.MoveX) / CELL_SIZE_PX;
  cornerY := gTerrain.RenderFlatToHeight(pX, pY) + (R.Pivot[id].Y + R.Size[id].Y + A.MoveY) / CELL_SIZE_PX;
  fRenderList.AddSprite(rxUnits, id, cornerX, cornerY, FlagColor);
end;


procedure TKMRenderPool.AddUnitThought(aUnit: TKMUnitType; aAct: TKMUnitActionType;
                                     aDir: TKMDirection;
                                     Thought: TKMUnitThought; pX,pY: Single);
var
  cornerX, cornerY, ground: Single;
  R: TRXData;
  A: TKMAnimLoop;
  id, id0: Integer;
begin
  if Thought = thNone then Exit;
  R := fRXData[rxUnits];

  // Unit position
  A := gRes.Units[aUnit].UnitAnim[aAct, aDir];
  id0 := A.Step[UNIT_STILL_FRAMES[aDir] mod Byte(A.Count) + 1] + 1;

  // Units feet
  ground := pY + (R.Pivot[id0].Y + R.Size[id0].Y) / CELL_SIZE_PX;
  // The thought should be slightly lower than the unit so it goes OVER warrior flags
  ground := ground + THOUGHT_X_OFFSET;

  id := gRes.Interpolation.UnitThought(Thought, gTerrain.AnimStep, gGameParams.TickFrac);

  cornerX := pX + R.Pivot[id].X / CELL_SIZE_PX;
  cornerY := gTerrain.RenderFlatToHeight(pX, pY) + (R.Pivot[id].Y + R.Size[id].Y) / CELL_SIZE_PX - 1.5;
  fRenderList.AddSpriteG(rxUnits, id, 0, cornerX, cornerY, pX, ground);
end;


procedure TKMRenderPool.AddUnitFlag(aUnit: TKMUnitType; aAct: TKMUnitActionType; aDir: TKMDirection;
                                  FlagAnim: Integer; pX, pY: Single; FlagColor: TColor4; DoImmediateRender: Boolean = False);
const
  // Offsets for flags rendering in pixels
  FlagXOffset: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX, TKMDirection] of shortint = (
    ( 0, 10, -1,  2,  1, -6,-10,  4, 13),  // gtMelee
    ( 0,  6,  5,  7, -3,-10, -4, 10,  9),  // gtAntiHorse
    ( 0,  8,  6,  6, -6, -8, -3,  8,  6),  // gtRanged
    ( 0,  6,  2,  3, -5,-10, -8,  5,  6)); // gtMounted

  FlagYOffset: array [GROUP_TYPE_MIN..GROUP_TYPE_MAX, TKMDirection] of shortint = (
    ( 0, 28, 30, 30, 26, 25, 24, 25, 27),  // gtMelee
    ( 0, 23, 25, 25, 21, 20, 19, 20, 22),  // gtAntiHorse
    ( 0, 28, 30, 30, 26, 25, 24, 25, 27),  // gtRanged
    ( 0,  4, 16, 16,  4,  5,  2,  3,  4)); // gtMounted
var
  R: TRXData;
  A: TKMAnimLoop;
  id0, idFlag: Integer;
  flagX, flagY, ground: Single;
begin
  R := fRXData[rxUnits];

  // Unit position
  A := gRes.Units[aUnit].UnitAnim[aAct, aDir];
  id0 := A.Step[UNIT_STILL_FRAMES[aDir] mod Byte(A.Count) + 1] + 1;

  // Units feet
  ground := pY + (R.Pivot[id0].Y + R.Size[id0].Y) / CELL_SIZE_PX;

  // Flag position
  idFlag := gRes.Interpolation.UnitAction(aUnit, uaWalkArm, aDir, FlagAnim, gGameParams.TickFrac);
  if idFlag <= 0 then Exit;

  flagX := pX + (R.Pivot[idFlag].X + FlagXOffset[UNIT_TO_GROUP_TYPE[aUnit], aDir]) / CELL_SIZE_PX - 0.5;
  flagY := gTerrain.RenderFlatToHeight(pX, pY) + (R.Pivot[idFlag].Y + FlagYOffset[UNIT_TO_GROUP_TYPE[aUnit], aDir] + R.Size[idFlag].Y) / CELL_SIZE_PX - 2.25;

  if DoImmediateRender then
    RenderSprite(rxUnits, idFlag, flagX, flagY, FlagColor)
  else
    fRenderList.AddSpriteG(rxUnits, idFlag, 0, flagX, flagY, pX, ground, FlagColor);
end;


procedure TKMRenderPool.AddUnitWithDefaultArm(aUnit: TKMUnitType; aUID: Integer; aAct: TKMUnitActionType; aDir: TKMDirection; StepId: Integer; pX,pY: Single; FlagColor: TColor4; DoImmediateRender: Boolean = False; DoHignlight: Boolean = False; HighlightColor: TColor4 = 0);
begin
  if aUnit = utFish then
    aAct := TKMUnitFish.GetFishActionType(FISH_CNT_DEFAULT); // In map editor always render default fish

  AddUnit(aUnit, aUID, aAct, aDir, StepId, 0.0, pX, pY, FlagColor, True, DoImmediateRender, DoHignlight, HighlightColor);
  if gRes.Units[aUnit].SupportsAction(uaWalkArm) then
    AddUnit(aUnit, aUID, uaWalkArm, aDir, StepId, 0.0, pX, pY, FlagColor, True, DoImmediateRender, DoHignlight, HighlightColor);
end;


{procedure TRenderPool.RenderObject(aRX: TRXType; aId: Word; pX,pY: Single);
type
    TVector4f = record X,Y,Z,W: Single; end;
    TColor4f = record R,G,B,A: Single; end;
const
    LightPos: TVector4f = (X:-1; Y:0; Z:-2; W:0);
    LightAmb: TColor4f = (R:0.1; G:0.1; B:0.1; A:0);
    LightDiff: TColor4f = (R:0.9; G:0.9; B:0.9; A:0);
    LightSpec: TColor4f = (R:1.0; G:1.0; B:1.0; A:0);
begin
  glPushMatrix;
  glPushAttrib(GL_LIGHTING_BIT or GL_DEPTH_BUFFER_BIT);
    glScalef(1, 1, CELL_SIZE_PX);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glLightfv(GL_LIGHT0, GL_AMBIENT, @LightAmb);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, @LightDiff);
    glLightfv(GL_LIGHT0, GL_SPECULAR, @LightSpec);
    glLightfv(GL_LIGHT0, GL_POSITION, @LightPos);

    glLightModelf(GL_LIGHT_MODEL_LOCAL_VIEWER, 0.0); //Directional lighting
    glLightModeli(GL_LIGHT_MODEL_COLOR_CONTROL, GL_SEPARATE_SPECULAR_COLOR); //Specular does not depend on material color

    glTranslatef(pX, pY, -1);
    glRotatef(32.5, 1, 0, 0);
    glColor4f(0.8, 0.8, 0.8, 1);

    fSampleHouse.DrawModel;
  glPopAttrib;
  glPopMatrix;
end;}

procedure TKMRenderPool.RenderSprite(aRX: TRXType; aId: Integer; aX, aY: Single; aColor: TColor4; aDoHighlight: Boolean = False;
  aHighlightColor: TColor4 = 0; aForced: Boolean = False);
var
  tX, tY: Integer;
  rX, rY: Single;
begin
  tX := EnsureRange(Round(aX), 1, gTerrain.MapX);
  tY := EnsureRange(Round(aY), 1, gTerrain.MapY);
  //Do not render if sprite is under FOW
  if not aForced and (gMySpectator.FogOfWar.CheckVerticeRenderRev(tX, tY) <= FOG_OF_WAR_MIN) then
    Exit;

  rX := RoundToTilePixel(aX);
  rY := RoundToTilePixel(aY);

  with gGFXData[aRX, aId] do
  begin
    // FOW is rendered over the top so no need to make sprites black anymore
    glColor4ub(255, 255, 255, 255);

    TKMRender.BindTexture(Tex.TexID);
    if aDoHighlight then
      glColor3ub(aHighlightColor and $FF, aHighlightColor shr 8 and $FF, aHighlightColor shr 16 and $FF);
    glBegin(GL_QUADS);
      glTexCoord2f(Tex.u1, Tex.v2); glVertex2f(rX                     , rY                      );
      glTexCoord2f(Tex.u2, Tex.v2); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY                      );
      glTexCoord2f(Tex.u2, Tex.v1); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY-pxHeight/CELL_SIZE_PX);
      glTexCoord2f(Tex.u1, Tex.v1); glVertex2f(rX                     , rY-pxHeight/CELL_SIZE_PX);
    glEnd;
  end;

  if gGFXData[aRX, aId].Alt.TexID <> 0 then
    with gGFXData[aRX, aId] do
    begin
      glColor4ubv(@aColor);
      TKMRender.BindTexture(Alt.TexID);
      glBegin(GL_QUADS);
        glTexCoord2f(Alt.u1, Alt.v2); glVertex2f(rX                     , rY                      );
        glTexCoord2f(Alt.u2, Alt.v2); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY                      );
        glTexCoord2f(Alt.u2, Alt.v1); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY-pxHeight/CELL_SIZE_PX);
        glTexCoord2f(Alt.u1, Alt.v1); glVertex2f(rX                     , rY-pxHeight/CELL_SIZE_PX);
      glEnd;
    end;
end;


// Param - defines at which level alpha-test will be set (acts like a threshhold)
// Then we render alpha-tested Mask to stencil buffer. Only those pixels that are
// white there will have sprite rendered
// If there are two masks then we need to render sprite only there
// where its mask is white AND where second mask is black
procedure TKMRenderPool.RenderSpriteAlphaTest(aRX: TRXType; aId: Integer; aWoodProgress: Single; aX, aY: Single;
  aId2: Integer = 0; aStoneProgress: Single = 0; X2: Single = 0; Y2: Single = 0);
var
  tX, tY: Integer;
  rX, rY: Single;
begin
  // Skip rendering if alphas are zero (occurs so non-started houses can still have child sprites)
  if (aWoodProgress = 0) and (aStoneProgress = 0) then Exit;

  tX := EnsureRange(Round(aX), 1, gTerrain.MapX);
  tY := EnsureRange(Round(aY), 1, gTerrain.MapY);
  if gMySpectator.FogOfWar.CheckVerticeRenderRev(tX, tY) <= FOG_OF_WAR_MIN then Exit;

  rX := RoundToTilePixel(aX);
  rY := RoundToTilePixel(aY);

  X2 := RoundToTilePixel(X2);
  Y2 := RoundToTilePixel(Y2);

  glClear(GL_STENCIL_BUFFER_BIT);

  // Setup stencil mask
  glEnable(GL_STENCIL_TEST);
  glStencilFunc(GL_ALWAYS, 1, 1);
  glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);

  glPushAttrib(GL_COLOR_BUFFER_BIT);
    // Do not render anything on screen while setting up stencil mask
    glColorMask(False, False, False, False);

    // Prepare stencil mask. Sprite will be rendered only where are white pixels
    glEnable(GL_ALPHA_TEST);
    glBlendFunc(GL_ONE, GL_ZERO);

    // Wood progress
    glAlphaFunc(GL_GREATER, 1 - aWoodProgress);
    with gGFXData[aRX,aId] do
    begin
      glColor3f(1, 1, 1);
      TKMRender.BindTexture(Alt.TexID);
      glBegin(GL_QUADS);
        glTexCoord2f(Alt.u1,Alt.v2); glVertex2f(rX                     , rY         );
        glTexCoord2f(Alt.u2,Alt.v2); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY         );
        glTexCoord2f(Alt.u2,Alt.v1); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY-pxHeight/CELL_SIZE_PX);
        glTexCoord2f(Alt.u1,Alt.v1); glVertex2f(rX                     , rY-pxHeight/CELL_SIZE_PX);
      glEnd;
      TKMRender.BindTexture(0);
    end;

    // Stone progress
    if aId2 <> 0 then
    begin
      glStencilOp(GL_DECR, GL_DECR, GL_DECR);

      glAlphaFunc(GL_GREATER, 1 - aStoneProgress);
        with gGFXData[aRX,aId2] do
        begin
          glColor3f(1, 1, 1);
          TKMRender.BindTexture(Alt.TexID);
          glBegin(GL_QUADS);
            glTexCoord2f(Alt.u1,Alt.v2); glVertex2f(X2                     ,Y2         );
            glTexCoord2f(Alt.u2,Alt.v2); glVertex2f(X2+pxWidth/CELL_SIZE_PX,Y2         );
            glTexCoord2f(Alt.u2,Alt.v1); glVertex2f(X2+pxWidth/CELL_SIZE_PX,Y2-pxHeight/CELL_SIZE_PX);
            glTexCoord2f(Alt.u1,Alt.v1); glVertex2f(X2                     ,Y2-pxHeight/CELL_SIZE_PX);
          glEnd;
          TKMRender.BindTexture(0);
        end;
    end;

    glDisable(GL_ALPHA_TEST);
    glAlphaFunc(GL_ALWAYS, 0);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // Revert alpha mode

  glPopAttrib;

  glStencilFunc(GL_EQUAL, 1, 1);
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
  glColorMask(True, True, True, True);

  // Render sprite
  with gGFXData[aRX,aId] do
  begin
    // FOW is rendered over the top so no need to make sprites black anymore
    glColor4ub(255, 255, 255, 255);

    TKMRender.BindTexture(Tex.TexID);
    glBegin(GL_QUADS);
      glTexCoord2f(Tex.u1,Tex.v2); glVertex2f(rX                     , rY         );
      glTexCoord2f(Tex.u2,Tex.v2); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY         );
      glTexCoord2f(Tex.u2,Tex.v1); glVertex2f(rX+pxWidth/CELL_SIZE_PX, rY-pxHeight/CELL_SIZE_PX);
      glTexCoord2f(Tex.u1,Tex.v1); glVertex2f(rX                     , rY-pxHeight/CELL_SIZE_PX);
    glEnd;
    TKMRender.BindTexture(0);
  end;

  glDisable(GL_STENCIL_TEST);
end;


procedure TKMRenderPool.CollectPlans(const aRect: TKMRect);
var
  I: Integer;
begin
  fFieldsList.Clear;
  fHousePlansList.Clear;

  // Collect field plans (road, corn, wine)
  if gGameParams.IsReplayOrSpectate then
  begin
    if gMySpectator.FOWIndex = -1 then
      for I := 0 to gHands.Count - 1 do
        // Don't use Hand.GetFieldPlans as it will give us plans multiple times for allies
        gHands[I].Constructions.FieldworksList.GetFields(fFieldsList, aRect, False)
    else
      gHands[gMySpectator.FOWIndex].GetFieldPlans(fFieldsList, aRect, False);
  end
  else
  begin
    // Field plans for self and allies
    // Include fake field plans for painting
    gMySpectator.Hand.GetFieldPlans(fFieldsList, aRect, True);
  end;

  // House plans for self and allies
  if gGameParams.IsReplayOrSpectate then
  begin
    if gMySpectator.FOWIndex = -1 then
      for I := 0 to gHands.Count - 1 do
        // Don't use Hand.GetHousePlans as it will give us plans multiple times for allies
        gHands[I].Constructions.HousePlanList.GetOutlines(fHousePlansList, aRect)
    else
      gHands[gMySpectator.FOWIndex].GetHousePlans(fHousePlansList, aRect);
  end
  else
    gMySpectator.Hand.GetHousePlans(fHousePlansList, aRect);
end;


//Render wire on tile
//P - tile coords
//Col - Color
//aInset - Internal adjustment, to render wire "inside" tile
procedure TKMRenderPool.RenderWireTile(const P: TKMPoint; aCol: TColor4; aInset: Single = 0.0; aLineWidth: Single = -1);
begin
  if not gTerrain.TileInMapCoords(P.X, P.Y) then Exit;

  TKMRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  //Change LineWidth
  if aLineWidth > 0 then
    glLineWidth(aLineWidth);

  gRenderAux.RenderWireTile(P, aCol, aInset);

  if aLineWidth > 0 then
    SetDefaultRenderParams;
end;


// Until profiling we use straightforward approach of recreating outline each frame
// Optimize later if needed
procedure TKMRenderPool.RenderHouseOutline(aHouseSketch: TKMHouseSketch; aCol: TColor4 = icCyan);
var
  I: Integer;
  loc: TKMPoint;
  X, Y: Word;
begin
  if (aHouseSketch = nil) or aHouseSketch.IsEmpty then
    Exit;

  // Get an outline of build area
  fHouseOutline.Clear;

  loc := aHouseSketch.Position;
  gRes.Houses[aHouseSketch.HouseType].Outline(fHouseOutline);

  TKMRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)
//  glColor3f(0, 1, 1);
  glColor4ubv(@aCol);
  glBegin(GL_LINE_LOOP);
    with gTerrain do
    for I := 0 to fHouseOutline.Count - 1 do
    begin
      X := loc.X + fHouseOutline[I].X - 3;
      Y := loc.Y + fHouseOutline[I].Y - 4;
      glVertex2f(X, Y - LandExt^[Y+1, X+1].RenderHeight / CELL_HEIGHT_DIV);
    end;
  glEnd;
end;


procedure TKMRenderPool.RenderSpriteOnTile(const aLoc: TKMPoint; aId: Integer; aFlagColor: TColor4 = $FFFFFFFF);
var
  pX, pY: Single;
begin
  if not gTerrain.TileInMapCoords(aLoc.X, aLoc.Y)
    or (gMySpectator.FogOfWar.CheckVerticeRenderRev(aLoc.X,aLoc.Y) <= FOG_OF_WAR_MIN) then Exit;

  pX := aLoc.X - 0.5 + fRXData[rxGui].Pivot[aId].X / CELL_SIZE_PX;
  pY := gTerrain.RenderFlatToHeight(aLoc.X - 0.5, aLoc.Y - 0.5) -
        fRXData[rxGui].Pivot[aId].Y / CELL_SIZE_PX;
  RenderSprite(rxGui, aId, pX, pY, aFlagColor);
end;


procedure TKMRenderPool.RenderSpriteOnTerrain(const aLoc: TKMPointF; aId: Integer; aFlagColor: TColor4 = $FFFFFFFF; aForced: Boolean = False);
var
  pX, pY: Single;
begin
  // if not gTerrain.TileInMapCoords(aLoc.X, aLoc.Y) then Exit;
  pX := aLoc.X + fRXData[rxGui].Pivot[aId].X / CELL_SIZE_PX;
  pY := gTerrain.RenderFlatToHeight(aLoc.X, aLoc.Y) +
        fRXData[rxGui].Pivot[aId].Y / CELL_SIZE_PX;
  RenderSprite(rxGui, aId, pX, pY, aFlagColor, False, 0, aForced);
end;


procedure TKMRenderPool.RenderWireHousePlan(const P: TKMPoint; aHouseType: TKMHouseType);
var
  I: Integer;
  showHMarksIgnoreFOW: Boolean;
begin
  fMarksList.Clear;
  //Show house marks ignoring player FOW if we can see all map in replay/spec
  showHMarksIgnoreFOW := gGameParams.IsReplayOrSpectate and (gMySpectator.FOWIndex = -1);
  gMySpectator.Hand.GetHouseMarks(P, aHouseType, fMarksList, showHMarksIgnoreFOW);

  for I := 0 to fMarksList.Count - 1 do
  if fMarksList.Tag[I] = TC_OUTLINE then
    RenderWireTile(fMarksList[I], icCyan) // Cyan rect
  else
    RenderSpriteOnTile(fMarksList[I], fMarksList.Tag[I]); // Icon
end;


procedure TKMRenderPool.RenderForegroundUI_Markers;
var
  P: TKMPoint;
  house: TKMHouseWFlagPoint;
begin
  P := gCursor.Cell;
  case gCursor.Tag1 of
    MARKER_REVEAL:        begin
                            RenderSpriteOnTile(P, 394, gMySpectator.Hand.FlagColor);
                            gRenderAux.CircleOnTerrain(P.X-0.5, P.Y-0.5,
                             gCursor.MapEdSize,
                             gMySpectator.Hand.FlagColor and $10FFFFFF,
                             gMySpectator.Hand.FlagColor);
                          end;
    MARKER_DEFENCE:       begin
                            RenderSpriteOnTile(P, Ord(gCursor.MapEdDirection) + 510, gMySpectator.Hand.FlagColor);
                            case gCursor.MapEdDefPosGroupType of
                              gtMelee:      RenderSpriteOnTile(P, 371, gMySpectator.Hand.FlagColor);
                              gtAntiHorse:  RenderSpriteOnTile(P, 374, gMySpectator.Hand.FlagColor);
                              gtRanged:     RenderSpriteOnTile(P, 376, gMySpectator.Hand.FlagColor);
                              gtMounted:    RenderSpriteOnTile(P, 377, gMySpectator.Hand.FlagColor);
                            end;
                            if gCursor.MapEdDefPosType = dtBackLine then
                              RenderWireTile(P, icBlue, 0.1);
                          end;
    MARKER_CENTERSCREEN:  RenderSpriteOnTile(P, 391, gMySpectator.Hand.FlagColor);
    MARKER_AISTART:       RenderSpriteOnTile(P, 390, gMySpectator.Hand.FlagColor);
    MARKER_RALLY_POINT:   if gMySpectator.Selected is TKMHouseWFlagPoint then
                          begin
                            house := TKMHouseWFlagPoint(gMySpectator.Selected);
                            PaintFlagPoint(house.Entrance, P, gMySpectator.Hand.FlagColor, gRes.Houses[house.HouseType].FlagPointTexId, True, True);
                          end;
  end;
end;


procedure TKMRenderPool.RenderForegroundUI_ElevateEqualize;
var
  I, K: Integer;
  tmp: Single;
  rad, slope: Byte;
  F: TKMPointF;
begin
  F := gCursor.Float;
  rad := gCursor.MapEdSize;
  slope := gCursor.MapEdSlope;
  for I := Max((Round(F.Y) - rad), 1) to Min((Round(F.Y) + rad), gTerrain.MapY -1) do
    for K := Max((Round(F.X) - rad), 1) to Min((Round(F.X) + rad), gTerrain.MapX - 1) do
    begin
      case gCursor.MapEdShape of
        hsCircle: tmp := 1 - GetLengthI(I - Round(F.Y), K - Round(F.X)) / rad;
        hsSquare: tmp := 1 - Math.max(abs(I-Round(F.Y)), abs(K-Round(F.X))) / rad;
        else                 tmp := 0;
      end;
      tmp := Power(Abs(tmp), (slope + 1) / 6) * Sign(tmp); // Modify slopes curve
      tmp := EnsureRange(tmp * 2.5, 0, 1); // *2.5 makes dots more visible
      gRenderAux.DotOnTerrain(K, I, $FF or (Round(tmp*255) shl 24));
    end;
    case gCursor.MapEdShape of
      hsCircle: gRenderAux.CircleOnTerrain(round(F.X), round(F.Y), rad, $00000000,  $FFFFFFFF);
      hsSquare: gRenderAux.SquareOnTerrain(round(F.X) - rad, round(F.Y) - rad, round(F.X + rad), round(F.Y) + rad, $FFFFFFFF);
    end;
end;


procedure TKMRenderPool.RenderForegroundUI_ObjectsBrush;
var
  I, K: Integer;
  tmp: Single;
  rad, slope: Byte;
  F: TKMPointF;
begin
  F := gCursor.Float;
  rad := (gCursor.MapEdSize div 2) +1;
  slope := gCursor.MapEdSlope;
  for I := Max((Round(F.Y) - rad), 1) to Min((Round(F.Y) + rad), gTerrain.MapY -1) do
    for K := Max((Round(F.X) - rad), 1) to Min((Round(F.X) + rad), gTerrain.MapX - 1) do
    begin
      case gCursor.MapEdShape of
        hsCircle: tmp := 1 - GetLengthI(I - Round(F.Y), K - Round(F.X)) / rad;
        hsSquare: tmp := 1 - Math.max(abs(I-Round(F.Y)), abs(K-Round(F.X))) / rad;
        else                 tmp := 0;
      end;
      tmp := Power(Abs(tmp), (slope + 1) / 6) * Sign(tmp); // Modify slopes curve
      tmp := EnsureRange(tmp * 2.5, 0, 1); // *2.5 makes dots more visible
      gRenderAux.DotOnTerrain(K, I, $FF or (Round(tmp*255) shl 24));
    end;
    case gCursor.MapEdShape of
      hsCircle: gRenderAux.CircleOnTerrain(round(F.X), round(F.Y), rad, $00000000,  $FFFFFFFF);
      hsSquare: gRenderAux.SquareOnTerrain(round(F.X) - rad, round(F.Y) - rad, round(F.X + rad), round(F.Y) + rad, $FFFFFFFF);
    end;
end;

procedure TKMRenderPool.RenderWireTileInt(const X,Y: Integer);
begin
  RenderWireTile(KMPoint(X, Y), icLightCyan, 0, 0.3);
end;


procedure TKMRenderPool.RenderTileInt(const X, Y: Integer);
begin
 if gCursor.MapEdSize = 0 then
    // Brush size smaller than one cell
    gRenderAux.DotOnTerrain(Round(gCursor.Float.X), Round(gCursor.Float.Y), $FF80FF80)
  else
    RenderTile(Combo[TKMTerrainKind(gCursor.Tag1), TKMTerrainKind(gCursor.Tag1),1],X,Y,0);
end;


procedure TKMRenderPool.RenderForegroundUI_Brush;
var
  P, RP: TKMPoint;
  size: Integer;
  isSquare: Boolean;
begin
  P := gCursor.Cell;
  size := gCursor.MapEdSize;
  isSquare := gCursor.MapEdShape = hsSquare;
  if gCursor.MapEdUseMagicBrush then
    IterateOverArea(P, size, isSquare, RenderWireTileInt)
  else
  if gCursor.Tag1 <> 0 then
  begin
    if SHOW_BRUSH_APPLY_AREA then
    begin
      RP := P;
      if size = 0 then
        RP := KMPoint(Round(gCursor.Float.X+1), Round(gCursor.Float.Y+1));
      IterateOverArea(RP, size, isSquare, RenderWireTileInt, True); // Render surrounding tiles, that will be fixed with transitions
    end;
    IterateOverArea(P, size, isSquare, RenderTileInt);
  end;
end;


//Render tile owner layer
procedure TKMRenderPool.RenderTileOwnerLayer(const aRect: TKMRect);
var
  I, K: Integer;
  P: TKMPoint;
begin
  for I := aRect.Top to aRect.Bottom do
    for K := aRect.Left to aRect.Right do
    begin
      P := KMPoint(K, I);
      if    (gTerrain.Land^[I, K].TileOwner <> HAND_NONE) //owner is set for tile
        and (gTerrain.TileIsCornField(P)                   // show only for corn + wine + roads
          or gTerrain.TileIsWineField(P)
          or (gTerrain.Land^[I, K].TileOverlay = toRoad)) then
        RenderWireTile(P, gHands[gTerrain.Land^[I, K].TileOwner].FlagColor, 0.05);
    end;
end;


//Render tiles grid layer
procedure TKMRenderPool.RenderTilesGrid(const aRect: TKMRect);
var
  I, K: Integer;
begin
  for I := aRect.Top to aRect.Bottom do
    for K := aRect.Left to aRect.Right do
      RenderWireTile(KMPoint(K, I), icDarkCyan, 0, 1);
end;


procedure TKMRenderPool.RenderForegroundUI;
var
  P: TKMPoint;
begin
  if gCursor.Cell.Y * gCursor.Cell.X = 0 then Exit; // Caused a rare crash

  TKMRender.BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  if gGameParams.IsMapEditor then
    gGame.MapEditor.Paint(plCursors, KMRect(0,0,0,0));

  P := gCursor.Cell;

  if (gCursor.Mode <> cmNone) and (gCursor.Mode <> cmHouses) and
     (gMySpectator.FogOfWar.CheckTileRevelation(P.X, P.Y) = 0) then
    RenderSpriteOnTile(P, TC_BLOCK)       // Red X
  else

  with gTerrain do
  case gCursor.Mode of
    cmNone:       ;
    cmErase:      if not gGameParams.IsMapEditor then
                  begin
                    if ((gMySpectator.Hand.Constructions.FieldworksList.HasFakeField(P) <> ftNone)
                        or gMySpectator.Hand.Constructions.HousePlanList.HasPlan(P)
                        or (gMySpectator.Hand.HousesHitTest(P.X, P.Y) <> nil))
                    then
                      RenderWireTile(P, icCyan) // Cyan quad
                    else
                      RenderSpriteOnTile(P, TC_BLOCK); // Red X
                  end;
    cmRoad:       if gMySpectator.Hand.CanAddFakeFieldPlan(P, ftRoad) and (gCursor.Tag1 <> Ord(cfmErase)) then
                    RenderWireTile(P, icCyan) // Cyan quad
                  else
                    RenderSpriteOnTile(P, TC_BLOCK);       // Red X
    cmField:      if (gMySpectator.Hand.CanAddFakeFieldPlan(P, ftCorn) or (gGameParams.IsMapEditor and gTerrain.TileIsCornField(P)))
                    and (gCursor.Tag1 <> Ord(cfmErase)) then
                    RenderWireTile(P, icCyan) // Cyan quad
                  else
                    RenderSpriteOnTile(P, TC_BLOCK);       // Red X
    cmWine:       if (gMySpectator.Hand.CanAddFakeFieldPlan(P, ftWine) or (gGameParams.IsMapEditor and gTerrain.TileIsWineField(P)))
                    and (gCursor.Tag1 <> Ord(cfmErase)) then
                    RenderWireTile(P, icCyan) // Cyan quad
                  else
                    RenderSpriteOnTile(P, TC_BLOCK);       // Red X
    cmHouses:     RenderWireHousePlan(KMPointAdd(P, gCursor.DragOffset), TKMHouseType(gCursor.Tag1)); // Cyan quads and red Xs
    cmBrush:      RenderForegroundUI_Brush;
    cmTiles:      if gCursor.MapEdDir in [0..3] then
                    RenderTile(gCursor.Tag1, P.X, P.Y, gCursor.MapEdDir)
                  else
                    RenderTile(gCursor.Tag1, P.X, P.Y, (gTerrain.AnimStep div 5) mod 4); // Spin it slowly so player remembers it is on randomized
    cmOverlays:   begin
                    RenderWireTile(P, icCyan);
                    if gCursor.Tag1 > 0 then
                      RenderTile(TILE_OVERLAY_IDS[TKMTileOverlay(gCursor.Tag1)], P.X, P.Y, 0);
                    end;
    cmObjects:    begin
                    // If there's object below - paint it in Red
                    RenderMapElement(gTerrain.Land^[P.Y,P.X].Obj, gTerrain.AnimStep, P.X, P.Y, True, True);
                    RenderMapElement(gCursor.Tag1, gTerrain.AnimStep, P.X, P.Y, True);
                  end;
    cmObjectsBrush: RenderForegroundUI_ObjectsBrush;
    cmMagicWater: begin
                    if gTerrain.Land[P.Y, P.X].BaseLayer.Rotation+1 <=3 then
                      RenderTile(192, P.X, P.Y, gTerrain.Land[P.Y, P.X].BaseLayer.Rotation+1)
                    else
                      RenderTile(192, P.X, P.Y, 0);
                    RenderWireTile(P, icCyan);
                  end;
    cmEyeDropper: RenderWireTile(P, icCyan); // Cyan quad
    cmRotateTile: RenderWireTile(P, icCyan); // Cyan quad
    cmElevate,
    cmEqualize:         RenderForegroundUI_ElevateEqualize;
    cmConstHeight:      RenderForegroundUI_ElevateEqualize;
    cmUnits:            RenderForegroundUI_Units;
    cmMarkers:          RenderForegroundUI_Markers;
    cmPaintBucket:      RenderForegroundUI_PaintBucket(ssShift in gCursor.SState);
    cmUniversalEraser:  RenderForegroundUI_UniversalEraser(ssShift in gCursor.SState);
  end;

  if DISPLAY_SOUNDS then gSoundPlayer.Paint;
end;


procedure TKMRenderPool.RenderUnit(U: TKMUnit; const P: TKMPoint; aFlagColor: Cardinal; aDoHighlight: Boolean; aHighlightColor: Cardinal);
begin
  RenderUnit(U.UnitType, KMPointDir(P, U.Direction), U.AnimStep, aFlagColor, aDoHighlight, aHighlightColor);
end;


procedure TKMRenderPool.RenderUnit(aUnitType: TKMUnitType; const P: TKMPointDir; aAnimStep: Integer; aFlagColor: Cardinal; aDoHighlight: Boolean = False; aHighlightColor: Cardinal = 0);
begin
  AddUnitWithDefaultArm(aUnitType, 0, uaWalk, P.Dir, aAnimStep, P.Loc.X + UNIT_OFF_X, P.Loc.Y + UNIT_OFF_Y,
                        aFlagColor, True, aDoHighlight, aHighlightColor);
end;


procedure TKMRenderPool.DoRenderGroup(aUnitType: TKMUnitType; aLoc: TKMPointDir; aMembersCnt, aUnitsPerRow: Integer; aHandColor: Cardinal);

  procedure PaintGroup;
  var
    I: Integer;
    unitPos: TKMPointF;
    newPos: TKMPoint;
    doesFit: Boolean;
  begin
    //Paint virtual members in MapEd mode
    for I := 1 to aMembersCnt - 1 do
    begin
      newPos := GetPositionInGroup2(aLoc.Loc.X, aLoc.Loc.Y, aLoc.Dir, I, aUnitsPerRow, gTerrain.MapX, gTerrain.MapY, doesFit);
      if not doesFit then Continue; //Don't render units that are off the map in the map editor
      unitPos.X := newPos.X + UNIT_OFF_X; //MapEd units don't have sliding
      unitPos.Y := newPos.Y + UNIT_OFF_Y;
      gRenderPool.AddUnit(aUnitType, 0, uaWalk, aLoc.Dir, UNIT_STILL_FRAMES[aLoc.Dir], 0.0, unitPos.X, unitPos.Y, aHandColor, True, True);
    end;
  end;

begin
  if TKMUnitGroup.IsFlagRenderBeforeUnit(aLoc.Dir) then
  begin
    PaintGroup;
    RenderUnit(aUnitType, aLoc, UNIT_STILL_FRAMES[aLoc.Dir], aHandColor);
  end else begin
    RenderUnit(aUnitType, aLoc, UNIT_STILL_FRAMES[aLoc.Dir], aHandColor);
    PaintGroup;
  end;
end;


//Try to render Unit or Unit group.
//Return True, if succeeded
function TKMRenderPool.TryRenderUnitOrGroup(aEntity: TKMHandEntity; aUnitFilterFunc, aGroupFilterFunc: TBooleanFunc;
                                          aUseGroupFlagColor, aDoHighlight: Boolean;
                                          aHandColor, aFlagColor: Cardinal; aHighlightColor: Cardinal = 0): Boolean;
var
  U: TKMUnit;
  G: TKMUnitGroup;
  groupFlagColor: Cardinal;
begin
  Result := False;
  if aEntity.IsUnit then
  begin
    U := TKMUnit(aEntity);
    if not Assigned(aUnitFilterFunc) or aUnitFilterFunc(aEntity) then
    begin
      RenderUnit(U, U.Position, aHandColor, aDoHighlight, aHighlightColor);
      Result := True;
    end;
  end else 
  if aEntity.IsGroup then
  begin
    G := TKMUnitGroup(aEntity);
    if not Assigned(aGroupFilterFunc) or aGroupFilterFunc(aEntity) then
    begin
      U := G.FlagBearer;
      if aUseGroupFlagColor then
        groupFlagColor := G.FlagColor
      else
        groupFlagColor := aFlagColor;

      if G.IsFlagRenderBeforeUnit(U.Direction) then
      begin
        G.PaintHighlighted(0.0, aHandColor, groupFlagColor, True, aDoHighlight, aHighlightColor);
        RenderUnit(U, U.Position, aHandColor, aDoHighlight, aHighlightColor);
      end else begin
        RenderUnit(U, U.Position, aHandColor, aDoHighlight, aHighlightColor);
        G.PaintHighlighted(0.0, aHandColor, groupFlagColor, True, aDoHighlight, aHighlightColor);
      end;
      Result := True;
    end;
  end;
end;


procedure TKMRenderPool.RenderForegroundUI_Units;
var
  entity: TKMHandEntity;
  P: TKMPoint;
  dir : TKMDirection;
  UT: TKMUnitType;
  formation: TKMFormation;
begin
  Assert(gGameParams.IsMapEditor);

  if gCursor.Tag1 = 255 then
  begin
    entity := gMySpectator.HitTestCursorWGroup(True);
    TryRenderUnitOrGroup(entity, nil, nil, True, True, DELETE_COLOR, 0, DELETE_COLOR);
  end
  else
  begin
    UT := TKMUnitType(gCursor.Tag1);
    dir := dirS;

    P := gCursor.Cell;
    if gTerrain.CanPlaceUnit(P, UT) then
    begin
      if UT in UNITS_WARRIORS then
      begin
        gGame.MapEditor.DetermineGroupFormationAndDir(P, UNIT_TO_GROUP_TYPE[TKMUnitType(gCursor.Tag1)], formation, dir);
        DoRenderGroup(UT, KMPointDir(P, dir), formation.NumUnits, formation.UnitsPerRow, gMySpectator.Hand.FlagColor);
      end
      else
        AddUnitWithDefaultArm(UT, 0, uaWalk, dir, UNIT_STILL_FRAMES[dirS], P.X+UNIT_OFF_X, P.Y+UNIT_OFF_Y, gMySpectator.Hand.FlagColor, True);
    end
    else
      RenderSpriteOnTile(P, TC_BLOCK); // Red X
  end;
end;


procedure TKMRenderPool.RenderForegroundUI_UniversalEraser(aHighlightAll: Boolean);
var
  entity: TKMHandEntity;
  P: TKMPoint;
  isRendered: Boolean;
begin
  P := gCursor.Cell;
  entity := gMySpectator.HitTestCursorWGroup(True);

  isRendered := TryRenderUnitOrGroup(entity, nil, nil, True, True, DELETE_COLOR, 0, DELETE_COLOR);

  if (entity is TKMHouse) then
  begin
    AddWholeHouse(TKMHouse(entity), gHands[entity.Owner].FlagColor, True, True, DELETE_COLOR);
    isRendered := True;
  end;

  // Terrain object found on the cell
  if (aHighlightAll or not isRendered) and (gTerrain.Land^[P.Y,P.X].Obj <> OBJ_NONE) then
  begin
    RenderMapElement(gTerrain.Land^[P.Y,P.X].Obj, gTerrain.AnimStep, P.X, P.Y, True, True);
    isRendered := True;
  end;

  if (aHighlightAll or not isRendered) and
    (((gTerrain.Land^[P.Y, P.X].TileOverlay <> toNone)
        and (gTerrain.Land^[P.Y, P.X].TileLock = tlNone)) //Sometimes we can point road tile under the house, do not show Cyan quad then
      or (gGame.MapEditor.LandMapEd^[P.Y, P.X].CornOrWine <> 0)) then
    RenderWireTile(P, icCyan); // Cyan quad
end;


function TKMRenderPool.PaintBucket_GroupToRender(aGroup: TObject): Boolean;
begin
   Result := (aGroup is TKMUnitGroup) and (TKMUnitGroup(aGroup).Owner <> gMySpectator.HandID);
end;


function TKMRenderPool.PaintBucket_UnitToRender(aUnit: TObject): Boolean;
begin
   Result := (aUnit is TKMUnit) and not (aUnit is TKMUnitAnimal) and
    (TKMUnit(aUnit).Owner <> gMySpectator.HandID);
end;


procedure TKMRenderPool.RenderForegroundUI_PaintBucket(aHighlightAll: Boolean);
var
  entity: TKMHandEntity;
  highlightColor: Cardinal;
  P: TKMPoint;
  isRendered: Boolean;
begin
  P := gCursor.Cell;
  highlightColor := MultiplyBrightnessByFactor(gMySpectator.Hand.FlagColor, 2, 0.3, 0.9);
  entity := gMySpectator.HitTestCursorWGroup;

  isRendered := TryRenderUnitOrGroup(entity, PaintBucket_UnitToRender, PaintBucket_GroupToRender,
                                     False, True,
                                     gMySpectator.Hand.FlagColor, gMySpectator.Hand.FlagColor, highlightColor);

  if entity.IsHouse and (entity.Owner <> gMySpectator.HandID) then
  begin
    AddWholeHouse(TKMHouse(entity), gMySpectator.Hand.FlagColor, True, True, highlightColor);
    isRendered := True;
  end;

  if (aHighlightAll or not isRendered) and
    (((gTerrain.Land^[P.Y, P.X].TileOverlay = toRoad)
        and (gTerrain.Land^[P.Y, P.X].TileLock = tlNone)) //Sometimes we can point road tile under the house, do not show Cyan quad then
      or (gGame.MapEditor.LandMapEd^[P.Y, P.X].CornOrWine <> 0))
    and (gTerrain.Land^[P.Y, P.X].TileOwner <> gMySpectator.HandID) then //Only if tile has other owner
    RenderWireTile(P, icCyan); // Cyan quad
end;


{ TKMRenderList }
constructor TKMRenderList.Create;
begin
  inherited;

  // Pre-allocate some space
  SetLength(fRenderList, 512);

  fUnitsRXData := gRes.Sprites[rxUnits].RXData;
end;


destructor TKMRenderList.Destroy;
begin
  SetLength(fRenderList, 0);

  inherited;
end;


function TKMRenderList.GetSelectionUID(const aCurPos: TKMPointF): Integer;
var
  I, K: Integer;
begin
  Result := -1; // Didn't hit anything
  // Skip if cursor is over FOW
  if gMySpectator.FogOfWar.CheckRevelation(aCurPos) <= FOG_OF_WAR_MIN then Exit;
  // Select closest (higher Z) units first (list is in low..high Z-order)
  for I := Length(fRenderOrder) - 1 downto 0 do
  begin
    K := fRenderOrder[I];
    // Don't check child sprites, we don't want to select serfs by the long pike they are carrying
    if (fRenderList[K].UID > 0) and KMInRect(aCurPos, fRenderList[K].SelectionRect) then
    begin
      Result := fRenderList[K].UID;
      Exit;
    end;
  end;
end;


procedure TKMRenderList.Clear;
begin
  fCount := 0;
end;


procedure TKMRenderList.ClipRenderList;
var
  I, J: Integer;
begin
  SetLength(fRenderOrder, fCount);
  J := 0;
  for I := 0 to fCount - 1 do
    if fRenderList[I].NewInst then
    begin
      fRenderOrder[J] := I;
      Inc(J);
    end;
  SetLength(fRenderOrder, J);
end;


// Sort all items in list from top-right to bottom-left
procedure TKMRenderList.SortRenderList;
var
  renderOrderAux: array of Word;

  procedure DoQuickSort(aLo, aHi: Integer);
  var
    lo, hi: Integer;
    mid: Single;
  begin
    lo := aLo;
    hi := aHi;
    mid := fRenderList[fRenderOrder[(lo + hi) div 2]].Feet.Y;
    repeat
      while fRenderList[fRenderOrder[lo]].Feet.Y < mid do Inc(lo);
      while fRenderList[fRenderOrder[hi]].Feet.Y > mid do Dec(hi);
      if lo <= hi then
      begin
        SwapInt(fRenderOrder[lo], fRenderOrder[hi]);
        Inc(lo);
        Dec(hi);
      end;
    until lo > hi;
    if hi > aLo then DoQuickSort(aLo, hi);
    if lo < aHi then DoQuickSort(lo, aHi);
  end;

  procedure Merge(aStart, aMid, aEnd: Integer);
  var
    I, A, B: Integer;
  begin
    A := aStart;
    B := aMid;
    for I := aStart to aEnd - 1 do
      if (A < aMid) and ((B >= aEnd)
      or (fRenderList[renderOrderAux[A]].Feet.Y <= fRenderList[renderOrderAux[B]].Feet.Y)) then
      begin
        fRenderOrder[I] := renderOrderAux[A];
        Inc(A);
      end else begin
        fRenderOrder[I] := renderOrderAux[B];
        Inc(B);
      end;
  end;

  // The same as Merge, but RenderOrder and RenderOrderAux are switched
  procedure MergeAux(aStart, aMid, aEnd: Integer);
  var
    I, A, B: Integer;
  begin
    A := aStart;
    B := aMid;
    for I := aStart to aEnd-1 do
      if (A < aMid) and ((B >= aEnd)
      or (fRenderList[fRenderOrder[A]].Feet.Y <= fRenderList[fRenderOrder[B]].Feet.Y)) then
      begin
        renderOrderAux[I] := fRenderOrder[A];
        Inc(A);
      end else begin
        renderOrderAux[I] := fRenderOrder[B];
        Inc(B);
      end;
  end;

  // aUseAux tells us which array to store results in, it should flip each recurse
  procedure DoMergeSort(aStart, aEnd: Integer; aUseAux: Boolean);
  var
    mid: Integer;
  begin
    if aEnd - aStart < 2 then Exit;
    mid := (aStart + aEnd) div 2;
    DoMergeSort(aStart, mid, not aUseAux);
    DoMergeSort(mid, aEnd, not aUseAux);
    if aUseAux then
      MergeAux(aStart, mid, aEnd)
    else
      Merge(aStart, mid, aEnd);
  end;

begin
  ClipRenderList;
  if fCount > 0 then
  begin
    SetLength(renderOrderAux, Length(fRenderOrder));
    Move(fRenderOrder[0], renderOrderAux[0], Length(fRenderOrder)*SizeOf(fRenderOrder[0]));
    // Quicksort is unstable which causes Z fighting, so we use mergesort
    DoMergeSort(0, Length(fRenderOrder), False);
    // DoQuickSort(0, Length(RenderOrder) - 1);
  end;
end;


// New items must provide their ground level
procedure TKMRenderList.AddSpriteG(aRX: TRXType; aId: Integer; aUID: Integer; pX,pY,gX,gY: Single; aTeam: Cardinal = $0; aAlphaStep: Single = -1);
const
  MAX_SEL_RECT_HEIGHT = 60; //Restrict too long images selection rect
var
  hAdd, imH, hTop: Single;
  snsTop, snsBottom: Integer;
begin
  if fCount >= Length(fRenderList) then
    SetLength(fRenderList, fCount + 256); // Book some space

  fRenderList[fCount].Loc        := KMPointF(pX, pY); // Position of sprite, floating-point
  fRenderList[fCount].Feet       := KMPointF(gX, gY); // Ground position of sprite for Z-sorting
  fRenderList[fCount].RX         := aRX;             // RX library
  fRenderList[fCount].Id         := aId;             // Texture Id
  fRenderList[fCount].UID        := aUID;            // Object Id
  fRenderList[fCount].NewInst    := True;            // Is this a new item (can be occluded), or a child one (always on top of it's parent)
  fRenderList[fCount].TeamColor  := aTeam;           // Team Id (determines color)
  fRenderList[fCount].AlphaStep  := aAlphaStep;      // Alpha step for wip buildings

  if aUID > 0 then
    with fRenderList[fCount].SelectionRect do
    begin
      snsTop    := fUnitsRXData.SizeNoShadow[aId].Top;
      snsBottom := fUnitsRXData.SizeNoShadow[aId].Bottom;

      imH := snsBottom - snsTop + 1;
      hTop := EnsureRange(imH, CELL_SIZE_PX, MAX_SEL_RECT_HEIGHT);

      //Enlarge rect from image size to the top, to be at least CELL_SIZE_PX height
      hAdd := Max(0, CELL_SIZE_PX - imH); // height to add to image pos. half to the top, half to the bottom

      Left := pX - 0.5 - fUnitsRXData.Pivot[aId].X / CELL_SIZE_PX;
      Right := Left + 1; // Exactly +1 tile
      Bottom := gY + ((hAdd / 2) - (fUnitsRXData.Size[aId].Y - snsBottom - 1))/ CELL_SIZE_PX; // Consider shadow at the image bottom
      Top := Bottom - hTop / CELL_SIZE_PX; // -1 ~ -1.5 tiles
    end;

  Inc(fCount); // New item added
end;


// Child items don't need ground level
procedure TKMRenderList.AddSprite(aRX: TRXType; aId: Integer; pX,pY: Single; aTeam: Cardinal = $0; aAlphaStep: Single = -1);
begin
  if fCount >= Length(fRenderList) then
    SetLength(fRenderList, fCount + 256); // Book some space

  fRenderList[fCount].Loc        := KMPointF(pX,pY); // Position of sprite, floating-point
  fRenderList[fCount].Feet       := fRenderList[fCount-1].Feet;  // Ground position of sprite for Z-sorting
  fRenderList[fCount].RX         := aRX;             // RX library
  fRenderList[fCount].Id         := aId;             // Texture Id
  fRenderList[fCount].UID        := 0;               // Child sprites aren't used for selecting units
  fRenderList[fCount].NewInst    := False;           // Is this a new item (can be occluded), or a child one (always on top of it's parent)
  fRenderList[fCount].TeamColor  := aTeam;           // Team Id (determines color)
  fRenderList[fCount].AlphaStep  := aAlphaStep;      // Alpha step for wip buildings

  Inc(fCount); // New item added
end;


procedure TKMRenderList.SendToRender(aId: Integer);
var
  sp1, sp2: TKMRenderSprite;
  sp2Exists: Boolean;
begin
  // Shortcuts to Sprites info
  sp1 := fRenderList[aId];
  sp2Exists := (aId + 1 < fCount);
  if sp2Exists then
    sp2 := fRenderList[aId + 1];

  if sp1.AlphaStep = -1 then
    gRenderPool.RenderSprite(sp1.RX, sp1.Id, sp1.Loc.X, sp1.Loc.Y, sp1.TeamColor)
  else
  begin
    // Houses are rendered as Wood+Stone part. For Stone we want to skip
    // Wooden part where it is occluded (so that smooth shadows dont overlay)

    // Check if next comes our child, Stone layer
    if sp2Exists and not sp2.NewInst and (sp2.AlphaStep > 0) then
      gRenderPool.RenderSpriteAlphaTest(sp1.RX, sp1.Id, sp1.AlphaStep, sp1.Loc.X, sp1.Loc.Y,
                                                sp2.Id, sp2.AlphaStep, sp2.Loc.X, sp2.Loc.Y)
    else
      gRenderPool.RenderSpriteAlphaTest(sp1.RX, sp1.Id, sp1.AlphaStep, sp1.Loc.X, sp1.Loc.Y);
  end;

  if SHOW_GROUND_LINES and sp1.NewInst then
  begin
    // Child ground lines are useless
    glBegin(GL_LINES);
      glColor3f(1,1,0.5);
      glVertex2f(sp1.Feet.X + 0.15, gTerrain.RenderFlatToHeight(sp1.Feet).Y);
      glVertex2f(sp1.Feet.X - 0.15, gTerrain.RenderFlatToHeight(sp1.Feet).Y);
    glEnd;
  end;
end;


// Now render all these items from list
procedure TKMRenderList.Render;
var
  I, K, objectsCount: Integer;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameRenderList);
  {$ENDIF}

  fDbgSpritesQueued := fCount;
  fDbgSpritesDrawn := 0;
  objectsCount := Length(fRenderOrder);

  for I := 0 to objectsCount - 1 do
  begin
    K := fRenderOrder[I];
    glPushMatrix;

      if RENDER_3D then
      begin
        glTranslatef(fRenderList[K].Loc.X, fRenderList[K].Loc.Y, 0);
        glRotatef(gRenderPool.rHeading, -1, 0, 0);
        glTranslatef(-fRenderList[K].Loc.X, -fRenderList[K].Loc.Y, 0);
      end;

      repeat // Render child sprites after their parent
        SendToRender(K);
        if SHOW_SEL_BUFFER and fRenderList[K].NewInst and (fRenderList[K].UID > 0) then
          gRenderAux.SquareOnTerrain(fRenderList[K].SelectionRect.Left , fRenderList[K].SelectionRect.Top,
                                     fRenderList[K].SelectionRect.Right, fRenderList[K].SelectionRect.Bottom, fRenderList[K].UID or $FF000000, 1);
        Inc(K);
        Inc(fDbgSpritesDrawn);
      until ((K = fCount) or fRenderList[K].NewInst);
    glPopMatrix;
  end;
  {$IFDEF PERFLOG}
  gPerfLogs.SectionLeave(psFrameRenderList);
  {$ENDIF}
end;


end.

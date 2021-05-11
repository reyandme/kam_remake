unit KM_InterfaceGame;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  SysUtils, Controls, Classes, Math, KM_Defaults, KM_Controls, KM_Points,
  KM_InterfaceDefaults, KM_CommonTypes, KM_AIDefensePos,
  KM_Cursor, KM_Render, KM_Minimap, KM_Viewport, KM_ResFonts,
  KM_ResTypes;


type
  // Common class for ingame interfaces (Gameplay, MapEd)
  TKMUserInterfaceGame = class(TKMUserInterfaceCommon)
  private
    fDragScrollingCursorPos: TPoint;
    fDragScrollingViewportPos: TKMPointF;
    fOnUserAction: TKMUserActionEvent;

    procedure ResetDragScrolling;
    procedure PaintDefences;
  protected
    fMinimap: TKMMinimap;
    fViewport: TKMViewport;
    fDragScrolling: Boolean;

    fPaintDefences: Boolean;

    function IsDragScrollingAllowed: Boolean; virtual;
    function GetHintPositionBase: TKMPoint; override;
    function GetHintFont: TKMFont; override;
    function GetHintKind: TKMHintKind; override;

    function GetToolBarWidth: Integer; virtual; abstract;
  public
    constructor Create(aRender: TRender); reintroduce;
    destructor Destroy; override;

    property Minimap: TKMMinimap read fMinimap;
    property Viewport: TKMViewport read fViewport;
    property ToolbarWidth: Integer read GetToolBarWidth;
    property OnUserAction: TKMUserActionEvent read fOnUserAction write fOnUserAction;

    function CursorToMapCoord(X, Y: Integer): TKMPointF;

    procedure DebugControlsUpdated(aSenderTag: Integer); override;

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure KeyPress(Key: Char); override;
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;

    procedure GameSpeedChanged(aFromSpeed, aToSpeed: Single);
    procedure SyncUI(aMoveViewport: Boolean = True); virtual;
    procedure SyncUIView(const aCenter: TKMPointF; aZoom: Single = 1);
    procedure UpdateGameCursor(X, Y: Integer; Shift: TShiftState);
    procedure UpdateStateIdle(aFrameTime: Cardinal); virtual; abstract;

    procedure Paint; override;
  end;


const
  // Toolbar pads
  TB_PAD = 9; // Picked up empirically
  TB_WIDTH = 180; // Max width of sidebar elements
  TB_MAP_ED_WIDTH = 214; //Max width of sidebar elements in Map Editor
  PAGE_TITLE_Y = 5; // Page title offset
  TERRAIN_PAGE_TITLE_Y = PAGE_TITLE_Y + 2; // Terrain pages title offset
  STATS_LINES_CNT = 13; //Number of stats (F3) lines

  DEFENCE_LINE_TYPE_COL: array [TAIDefencePosType] of Cardinal = ($FF80FF00, $FFFF8000);

  // Shortcuts
  // All shortcuts are in English and are the same for all languages to avoid
  // naming collisions and confusion in discussions

  GUI_HOUSE_COUNT = 28;   // Number of KaM houses to show in GUI
  GUIHouseOrder: array [1..GUI_HOUSE_COUNT] of TKMHouseType = (
    htSchool, htInn, htQuary, htWoodcutters, htSawmill,
    htFarm, htMill, htBakery, htSwine, htButchers,
    htWineyard, htGoldMine, htCoalMine, htMetallurgists, htWeaponWorkshop,
    htTannery, htArmorWorkshop, htStables, htIronMine, htIronSmithy,
    htWeaponSmithy, htArmorSmithy, htBarracks, htStore, htWatchTower,
    htFisherHut, htMarketplace, htTownHall);

  // Template for how resources are shown in Barracks
  BARRACKS_RES_COUNT = 11;
  BarracksResType: array [1..BARRACKS_RES_COUNT] of TKMWareType =
    (wtShield, wtMetalShield, wtArmor, wtMetalArmor, wtAxe, wtSword,
     wtPike, wtHallebard, wtBow, wtArbalet, wtHorse);

  // Layout of resources in Store
  STORE_RES_COUNT = 28;
  StoreResType: array [1..STORE_RES_COUNT] of TKMWareType =
    (wtTrunk,    wtStone,   wtWood,        wtIronOre,   wtGoldOre,
     wtCoal,     wtSteel,   wtGold,        wtWine,      wtCorn,
     wtBread,    wtFlour,   wtLeather,     wtSausages,  wtPig,
     wtSkin,     wtShield,  wtMetalShield, wtArmor,     wtMetalArmor,
     wtAxe,      wtSword,   wtPike,        wtHallebard, wtBow,
     wtArbalet,  wtHorse,   wtFish);

  School_Order: array [0..13] of TKMUnitType = (
    utSerf, utWorker, utStoneCutter, utWoodcutter, utLamberjack,
    utFisher, utFarmer, utBaker, utAnimalBreeder, utButcher,
    utMiner, utMetallurgist, utSmith, utRecruit);

  Barracks_Order: array [0..8] of TKMUnitType = (
    utMilitia, utAxeFighter, utSwordsman, utBowman, utArbaletman,
    utPikeman, utHallebardman, utHorseScout, utCavalry);

  TownHall_Order: array [0..4] of TKMUnitType = (
    utPeasant, utSlingshot, utHorseman, utBarbarian, utMetalBarbarian);

  Soldiers_Order: array[0..13] of TKMUnitType = (
    utMilitia, utAxeFighter, utSwordsman, utBowman, utArbaletman,
    utPikeman, utHallebardman, utHorseScout, utCavalry,
    utPeasant, utSlingshot, utHorseman, utBarbarian, utMetalBarbarian);

  // Stats get stacked by UI logic (so that on taller screens they all were
  // in nice pairs, and would stack up only on short screens)
  StatPlan: array [0..STATS_LINES_CNT-1] of record
    HouseType: array [0..3] of TKMHouseType;
    UnitType: array [0..1] of TKMUnitType;
  end = (
    (HouseType: (htQuary, htNone, htNone, htNone);                      UnitType: (utStoneCutter, utNone)),
    (HouseType: (htWoodcutters, htNone, htNone, htNone);                UnitType: (utWoodcutter, utNone)),
    (HouseType: (htFisherHut, htNone, htNone, htNone);                  UnitType: (utFisher, utNone)),
    (HouseType: (htFarm, htWineyard, htNone, htNone);                   UnitType: (utFarmer, utNone)),
    (HouseType: (htMill, htBakery, htNone, htNone);                     UnitType: (utBaker, utNone)),
    (HouseType: (htSwine, htStables, htNone, htNone);                   UnitType: (utAnimalBreeder, utNone)),
    (HouseType: (htButchers, htTannery, htNone, htNone);                UnitType: (utButcher, utNone)),
    (HouseType: (htMetallurgists, htIronSmithy, htNone, htNone);        UnitType: (utMetallurgist, utNone)),
    (HouseType: (htArmorSmithy, htWeaponSmithy, htNone, htNone);        UnitType: (utSmith, utNone)),
    (HouseType: (htCoalMine, htIronMine, htGoldMine, htNone);           UnitType: (utMiner, utNone)),
    (HouseType: (htSawmill, htWeaponWorkshop, htArmorWorkshop, htNone); UnitType: (utLamberjack, utNone)),
    (HouseType: (htBarracks, htTownHall, htWatchTower, htNone);         UnitType: (utRecruit, utNone)),
    (HouseType: (htStore, htSchool, htInn, htMarketplace);              UnitType: (utSerf, utWorker))
    );

  MapEd_Order: array [0..13] of TKMUnitType = (
    utMilitia, utAxeFighter, utSwordsman, utBowman, utArbaletman,
    utPikeman, utHallebardman, utHorseScout, utCavalry, utBarbarian,
    utPeasant, utSlingshot, utMetalBarbarian, utHorseman);

  MapEd_Icon: array [0..13] of Word = (
    61, 62, 63, 64, 65,
    66, 67, 68, 69, 70,
    79, 80, 81, 82);

  Animal_Order: array [0..7] of TKMUnitType = (
    utWolf, utFish,        utWatersnake, utSeastar,
    utCrab, utWaterflower, utWaterleaf,  utDuck);

  Animal_Icon: array [0..7] of word = (
    71, 72, 73, 74,
    75, 76, 77, 78);

  MARKET_RES_HEIGHT = 35;

  // Big tab buttons in MapEd
  BIG_TAB_W = 41;
  BIG_PAD_W = 41;
  BIG_TAB_H = 36;
  // Small sub-tab buttons in MapEd
  SMALL_TAB_W = 30;
  SMALL_PAD_W = 30;
  SMALL_TAB_H = 26;

  MESSAGE_AREA_HEIGHT = 173+17; // Image_ChatHead + Image_ChatBody
  MESSAGE_AREA_RESIZE_Y = 200; // How much can we resize it


implementation
uses
  KM_Main, KM_Terrain, KM_RenderPool, KM_Resource, KM_ResCursors, KM_ResKeys, KM_HandsCollection, KM_GameParams,
  KM_RenderUI, KM_CommonUtils, KM_Pics, KM_GameSettings;


{ TKMUserInterfaceGame }
constructor TKMUserInterfaceGame.Create(aRender: TRender);
begin
  inherited Create(aRender.ScreenX, aRender.ScreenY);

  fMinimap := TKMMinimap.Create(False, False);
  fViewport := TKMViewport.Create(GetToolBarWidth, aRender.ScreenX, aRender.ScreenY);

  fDragScrolling := False;
  fDragScrollingCursorPos.X := 0;
  fDragScrollingCursorPos.Y := 0;
  fDragScrollingViewportPos := KMPOINTF_ZERO;

  fPaintDefences := False;

  gRenderPool := TRenderPool.Create(fViewport, aRender);
end;


destructor TKMUserInterfaceGame.Destroy;
begin
  FreeAndNil(fMinimap);
  FreeAndNil(fViewport);
  FreeAndNil(gRenderPool);
  Inherited;
end;


procedure TKMUserInterfaceGame.DebugControlsUpdated(aSenderTag: Integer);
begin
  inherited;

  if aSenderTag = Ord(dcFlatTerrain) then
    gTerrain.UpdateLighting;
end;


function TKMUserInterfaceGame.GetHintPositionBase: TKMPoint;
begin
  Result := KMPoint(GetToolBarWidth + 35, Panel_Main.Height);
end;


function TKMUserInterfaceGame.GetHintFont: TKMFont;
begin
  Result := fntOutline;
end;


function TKMUserInterfaceGame.GetHintKind: TKMHintKind;
begin
  Result := hkStatic;
end;


procedure TKMUserInterfaceGame.KeyPress(Key: Char);
begin
  inherited;
  if Assigned(fOnUserAction) then
    fOnUserAction(uatKeyPress);
end;


procedure TKMUserInterfaceGame.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
  {$IFDEF MSWindows}
var
  windowRect: TRect;
  {$ENDIF}
begin
  inherited;

  if Assigned(fOnUserAction) then
    fOnUserAction(uatKeyDown);

  aHandled := True;
  //Scrolling
  if Key = gResKeys[kfScrollLeft].Key       then
    fViewport.ScrollKeyLeft  := True
  else if Key = gResKeys[kfScrollRight].Key then
    fViewport.ScrollKeyRight := True
  else if Key = gResKeys[kfScrollUp].Key    then
    fViewport.ScrollKeyUp    := True
  else if Key =  gResKeys[kfScrollDown].Key then
    fViewport.ScrollKeyDown  := True
  else if Key = gResKeys[kfZoomIn].Key      then
    fViewport.ZoomKeyIn      := True
  else if Key = gResKeys[kfZoomOut].Key     then
    fViewport.ZoomKeyOut     := True
  else if Key = gResKeys[kfZoomReset].Key   then
    fViewport.ResetZoom
  else if (Key = gResKeys[kfMapDragScroll].Key)
      and IsDragScrollingAllowed then
  begin
    fDragScrolling := True;
   // Restrict the cursor to the window, for now.
   //todo: Allow one to drag out of the window, and still capture.
   {$IFDEF MSWindows}
     windowRect := gMain.ClientRect(1); //Reduce ClientRect by 1 pixel, to fix 'jump viewport' bug when dragscrolling over the window border
     ClipCursor(@windowRect);
   {$ENDIF}
   fDragScrollingCursorPos.X := gCursor.Pixel.X;
   fDragScrollingCursorPos.Y := gCursor.Pixel.Y;
   fDragScrollingViewportPos.X := fViewport.Position.X;
   fDragScrollingViewportPos.Y := fViewport.Position.Y;
   gRes.Cursors.Cursor := kmcDrag;
  end
  else
    aHandled := False;
end;


procedure TKMUserInterfaceGame.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if Assigned(fOnUserAction) then
    fOnUserAction(uatKeyUp);

  inherited;

  if aHandled then Exit;

  aHandled := True;
  //Scrolling
  if Key = gResKeys[kfScrollLeft].Key       then
    fViewport.ScrollKeyLeft := False
  else if Key = gResKeys[kfScrollRight].Key then
    fViewport.ScrollKeyRight := False
  else if Key = gResKeys[kfScrollUp].Key    then
    fViewport.ScrollKeyUp := False
  else if Key =  gResKeys[kfScrollDown].Key then
    fViewport.ScrollKeyDown  := False
  else if Key = gResKeys[kfZoomIn].Key      then
    fViewport.ZoomKeyIn := False
  else if Key = gResKeys[kfZoomOut].Key     then
    fViewport.ZoomKeyOut := False
  else if Key = gResKeys[kfZoomReset].Key   then
    fViewport.ResetZoom
  else if Key = gResKeys[kfMapDragScroll].Key then
  begin
    if fDragScrolling then
      ResetDragScrolling;
  end
  else aHandled := False;
end;


procedure TKMUserInterfaceGame.ResetDragScrolling;
begin
  fDragScrolling := False;
  gRes.Cursors.Cursor := kmcDefault; //Reset cursor
  gMain.ApplyCursorRestriction;
end;


function TKMUserInterfaceGame.IsDragScrollingAllowed: Boolean;
begin
  Result := True; // Allow drag scrolling by default
end;


procedure TKMUserInterfaceGame.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  inherited;
  if Assigned(fOnUserAction) then
    fOnUserAction(uatMouseUp);
end;


procedure TKMUserInterfaceGame.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  inherited;

  if Assigned(fOnUserAction) then
    fOnUserAction(uatMouseDown);
end;


procedure TKMUserInterfaceGame.MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean);
var
  VP: TKMPointF;
begin
  inherited;

  if Assigned(fOnUserAction) then
    fOnUserAction(uatMouseMove);

  aHandled := False;
  if fDragScrolling then
  begin
    if GetKeyState(gResKeys[kfMapDragScroll].Key) < 0 then
    begin
      UpdateGameCursor(X, Y, Shift);
      VP.X := fDragScrollingViewportPos.X + (fDragScrollingCursorPos.X - X) / (CELL_SIZE_PX * fViewport.Zoom);
      VP.Y := fDragScrollingViewportPos.Y + (fDragScrollingCursorPos.Y - Y) / (CELL_SIZE_PX * fViewport.Zoom);
      fViewport.Position := VP;
      aHandled := True;
    end else
      ResetDragScrolling;
  end;
end;


procedure TKMUserInterfaceGame.MouseWheel(Shift: TShiftState; WheelSteps, X, Y: Integer; var aHandled: Boolean);
var
  prevCursor: TKMPointF;
begin
  inherited;

  if Assigned(fOnUserAction) then
    fOnUserAction(uatMouseWheel);

  if (X < 0) or (Y < 0) then Exit; // This happens when you use the mouse wheel on the window frame

  // Allow to zoom only when cursor is over map. Controls handle zoom on their own
  if aHandled then Exit;
  
  UpdateGameCursor(X, Y, Shift); // Make sure we have the correct cursor position to begin with
  prevCursor := gCursor.Float;
  // +1 for ScrollSpeed = 0.
  // Sqrt to reduce Scroll speed importance
  // 11 = 10 + 1, 10 is default scroll speed
  fViewport.Zoom := fViewport.Zoom * (1 + WheelSteps * Sqrt((gGameSettings.ScrollSpeed + 1) / 11) / 12);
  UpdateGameCursor(X, Y, Shift); // Zooming changes the cursor position
  // Move the center of the screen so the cursor stays on the same tile, thus pivoting the zoom around the cursor
  fViewport.Position := KMPointF(fViewport.Position.X + prevCursor.X-gCursor.Float.X,
                                 fViewport.Position.Y + prevCursor.Y-gCursor.Float.Y);
  UpdateGameCursor(X, Y, Shift); // Recentering the map changes the cursor position
  aHandled := True;
end;


procedure TKMUserInterfaceGame.PaintDefences;
var
  I, K: Integer;
  DP: TAIDefencePosition;
  locF: TKMPointF;
  screenLoc: TKMPoint;
begin
  for I := 0 to gHands.Count - 1 do
    for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
    begin
      DP := gHands[I].AI.General.DefencePositions[K];
      locF := gTerrain.FlatToHeight(KMPointF(DP.Position.Loc.X-0.5, DP.Position.Loc.Y-0.5));
      screenLoc := fViewport.MapToScreen(locF);

      if KMInRect(screenLoc, fViewport.ViewRect) then
      begin
        //Dir selector
        TKMRenderUI.WritePicture(screenLoc.X, screenLoc.Y, 0, 0, [], rxGui,  510 + Byte(DP.Position.Dir));
        TKMRenderUI.WriteTextInShape(IntToStr(K+1), screenLoc.X, screenLoc.Y - 28, DEFENCE_LINE_TYPE_COL[DP.DefenceType],
                                     FlagColorToTextColor(GROUP_TXT_COLOR[DP.GroupType]), $80000000, IntToStr(I + 1), gHands[I].FlagColor, icWhite);
        //GroupType icon
        TKMRenderUI.WritePicture(screenLoc.X, screenLoc.Y, 0, 0, [], rxGui, GROUP_IMG[DP.GroupType]);
      end;
    end;
end;


procedure TKMUserInterfaceGame.Paint;
begin
  if (mlDefencesAll in gGameParams.VisibleLayers) then
    fPaintDefences := True;

  if fPaintDefences then
    PaintDefences;

  fPaintDefences := False;

  inherited;
end;


procedure TKMUserInterfaceGame.GameSpeedChanged(aFromSpeed, aToSpeed: Single);
begin
  fViewport.GameSpeedChanged(aFromSpeed, aToSpeed);
end;


procedure TKMUserInterfaceGame.SyncUI(aMoveViewport: Boolean = True);
begin
  fMinimap.LoadFromTerrain;
  fMinimap.Update;

  if aMoveViewport then
  begin
    fViewport.ResizeMap(gTerrain.MapX, gTerrain.MapY, gTerrain.TopHill / CELL_SIZE_PX);
    fViewport.ResetZoom;
  end;
end;


procedure TKMUserInterfaceGame.SyncUIView(const aCenter: TKMPointF; aZoom: Single = 1);
begin
  fViewport.Zoom := aZoom; // Set Zoom first, since it can apply restrictions on Position near map borders
  fViewport.Position := aCenter;
end;


function TKMUserInterfaceGame.CursorToMapCoord(X, Y: Integer): TKMPointF;
begin
  Result.X := fViewport.Position.X + (X-fViewport.ViewRect.Right/2-GetToolBarWidth/2)/CELL_SIZE_PX/fViewport.Zoom;
  Result.Y := fViewport.Position.Y + (Y-fViewport.ViewRect.Bottom/2)/CELL_SIZE_PX/fViewport.Zoom;
  Result.Y := gTerrain.ConvertCursorToMapCoord(Result.X, Result.Y);
end;


// Compute cursor position and store it in global variables
procedure TKMUserInterfaceGame.UpdateGameCursor(X, Y: Integer; Shift: TShiftState);
begin
  UpdateCursor(X, Y, Shift);

  with gCursor do
  begin
    Float := CursorToMapCoord(X, Y);

    PrevCell := Cell; //Save previous cell

    // Cursor cannot reach row MapY or column MapX, they're not part of the map (only used for vertex height)
    Cell.X := EnsureRange(Round(Float.X+0.5), 1, gTerrain.MapX-1); // Cell below cursor in map bounds
    Cell.Y := EnsureRange(Round(Float.Y+0.5), 1, gTerrain.MapY-1);

    ObjectUID := gRenderPool.RenderList.GetSelectionUID(Float);
  end;
end;


end.

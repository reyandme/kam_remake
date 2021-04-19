unit KM_InterfaceMapEditor;
{$I KaM_Remake.inc}
interface
uses
   {$IFDEF MSWindows} Windows, {$ENDIF}
   {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
   Classes, Controls, Math, StrUtils, SysUtils,
   KM_Controls, KM_Defaults, KM_Pics, KM_Points,
   KM_Houses, KM_Units, KM_UnitGroup, KM_MapEditor,
   KM_InterfaceDefaults, KM_InterfaceGame, KM_Terrain, KM_Minimap, KM_Viewport, KM_Render,
   KM_GUIMapEdHouse,
   KM_GUIMapEdPlayerGoalPopUp,
   KM_GUIMapEdTerrain,
   KM_GUIMapEdTown,
   KM_GUIMapEdPlayer,
   KM_GUIMapEdMission,
   KM_GUIMapEdTownAttackPopUp,
   KM_GUIMapEdExtras,
   KM_GUIMapEdMessage,
   KM_GUIMapEdTownFormationsPopUp,
   KM_GUIMapEdMarkerDefence,
   KM_GUIMapEdMarkerReveal,
   KM_GUIMapEdMenu,
   KM_GUIMapEdMenuQuickPlay,
   KM_GUIMapEdUnit,
   KM_GUIMapEdRMG,
   KM_MapEdTypes;

type
  TKMapEdInterface = class(TKMUserInterfaceGame)
  private
    fMouseDownOnMap: Boolean;

    // Drag object feature fields
    fDragObjectReady: Boolean;   // Ready to start drag object
    fDragObjMousePosStart: TKMPoint;
    fDragingObject: Boolean;     // Flag when drag object is happening
    fDragObject: TObject;        // Object to drag
    fDragHouseOffset: TKMPoint;  // Offset for house position, to let grab house with any of its points

    fGuiHouse: TKMMapEdHouse;
    fGuiUnit: TKMMapEdUnit;
    fGuiTerrain: TKMMapEdTerrain;
    fGuiTown: TKMMapEdTown;
    fGuiPlayer: TKMMapEdPlayer;
    fGuiMission: TKMMapEdMission;
    fGuiAttack: TKMMapEdTownAttack;
    fGuiGoal: TKMMapEdPlayerGoal;
    fGuiRMG: TKMMapEdRMG;
    fGuiFormations: TKMMapEdTownFormations;
    fGuiMenuQuickPlay: TKMMapEdMenuQuickPlay;
    fGuiExtras: TKMMapEdExtras;
    fGuiMessage: TKMMapEdMessage;
    fGuiMarkerDefence: TKMMapEdMarkerDefence;
    fGuiMarkerReveal: TKMMapEdMarkerReveal;
    fGuiMenu: TKMMapEdMenu;

    procedure Layers_UpdateVisibility;
    procedure Marker_Done(Sender: TObject);
    procedure Minimap_OnUpdate(Sender: TObject; const X,Y: Integer);
    procedure PageChanged(Sender: TObject);
    procedure Player_ActiveClick(Sender: TObject);
    procedure Message_Click(Sender: TObject);
    procedure ChangeOwner_Click(Sender: TObject);
    procedure UniversalEraser_Click(Sender: TObject);

    procedure UpdateCursor(X, Y: Integer; Shift: TShiftState);
    procedure Main_ButtonClick(Sender: TObject);
    procedure HidePages;
    procedure Cancel_Clicked(aIsRMB: Boolean; var aHandled: Boolean);
    procedure ShowMarkerInfo(aMarker: TKMMapEdMarker);
    procedure Player_SetActive(aIndex: TKMHandID);
    procedure Player_UpdatePages;
    procedure UpdateStateInternal;
    procedure UpdatePlayerSelectButtons;
    procedure SetPaintBucketMode(aSetPaintBucketMode: Boolean);
    procedure SetUniversalEraserMode(aSetUniversalEraserMode: Boolean);
    procedure MoveObjectToCursorCell(aObjectToMove: TObject);
    procedure UpdateSelection;
    procedure DragHouseModeStart(const aHouseNewPos, aHouseOldPos: TKMPoint);
    procedure DragHouseModeEnd;
    function IsDragHouseModeOn: Boolean;
    procedure ResetDragObject;
    function DoResetCursorMode: Boolean;
    procedure ShowSubMenu(aIndex: Byte);
    procedure ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
    procedure Update_Label_Coordinates;
    procedure MapTypeChanged(aIsMultiplayer: Boolean);

    procedure UnRedo_Click(Sender: TObject);
    procedure History_Click(Sender: TObject);
    procedure History_JumpTo(Sender: TObject);
    procedure History_ListChange(Sender: TObject);
    procedure History_MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
    procedure History_Close;
  protected
    MinimapView: TKMMinimapView;
    Label_Coordinates: TKMLabel;
    Button_PlayerSelect: array [0..MAX_HANDS-1] of TKMFlatButtonShape; //Animals are common for all
    Button_History: TKMButtonFlat;
    Button_Undo, Button_Redo: TKMButtonFlat;
    Button_ChangeOwner: TKMButtonFlat;
    Button_UniversalEraser: TKMButtonFlat;

    Label_Stat: TKMLabel;

    Panel_Common: TKMPanel;
      Button_Main: array [1..5] of TKMButton; //5 buttons
      Label_MissionName: TKMLabel;
      Image_Extra: TKMImage;
      Image_Message: TKMImage;

    PopUp_History: TKMPopUpPanel;
      ListBox_History: TKMListBox;
      Button_History_Undo,
      Button_History_Redo,
      Button_History_JumpTo: TKMButton;

    function GetToolBarWidth: Integer; override;

    procedure HistoryUpdateUI;
  public
    constructor Create(aRender: TRender);
    destructor Destroy; override;

    procedure ShowMessage(const aText: string);
    procedure ExportPages(const aPath: string); override;
    property Minimap: TKMMinimap read fMinimap;
    property Viewport: TKMViewport read fViewport;
    property GuiTerrain: TKMMapEdTerrain read fGuiTerrain;
    property GuiMission: TKMMapEdMission read fGuiMission;

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseWheel(Shift: TShiftState; WheelSteps, X,Y: Integer; var aHandled: Boolean); override;
    procedure Resize(X,Y: Word); override;
    procedure SetLoadMode(aMultiplayer: Boolean);

    procedure DebugControlsUpdated(aSenderTag: Integer); override;

	  procedure HistoryUndoRedo;
    procedure HistoryAddCheckpoint;

    procedure SyncUI(aMoveViewport: Boolean = True); override;
    procedure UpdateState(aTickCount: Cardinal); override;
    procedure UpdateStateImmidiately;
    procedure UpdateStateIdle(aFrameTime: Cardinal); override;
    procedure Paint; override;
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_Game, KM_GameParams, KM_GameCursor,
  KM_Resource, KM_TerrainDeposits, KM_ResCursors, KM_ResKeys, KM_GameApp,
  KM_Hand, KM_AIDefensePos, KM_RenderUI, KM_ResFonts, KM_CommonClasses, KM_UnitWarrior,
  KM_Utils,
  KM_UnitGroupTypes,
  KM_ResTypes;


{ TKMapEdInterface }
constructor TKMapEdInterface.Create(aRender: TRender);
const
  TB_PAD_MAP_ED = 0;
  TB_PAD_MBTN_LEFT = 9;
var
  I: Integer;
  S: TKMShape;
begin
  inherited;

  fMinimap.PaintVirtualGroups := True;

  ResetDragObject;
  //                                   250
  TKMImage.Create(Panel_Main, 0,    0, MAPED_TOOLBAR_WIDTH, 200, 407, rxGui, 0, [anLeft, anTop, anRight]); //Minimap place
  TKMImage.Create(Panel_Main, 0,  200, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, 0, [anLeft, anTop, anRight]);
  TKMImage.Create(Panel_Main, 0,  600, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, 0, [anLeft, anTop, anRight]);
  TKMImage.Create(Panel_Main, 0, 1000, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, 0, [anLeft, anTop, anRight]); //For 1600x1200 this is needed
  TKMImage.Create(Panel_Main, 0, 1400, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, 0, [anLeft, anTop, anRight]);
  TKMImage.Create(Panel_Main, 0, 1800, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, 0, [anLeft, anTop, anRight]); //For 4K displays

  MinimapView := TKMMinimapView.Create(Panel_Main, 10, 10, MAPED_TOOLBAR_WIDTH - 48, 176);
  MinimapView.OnChange := Minimap_OnUpdate;

  Label_MissionName := TKMLabel.Create(Panel_Main, MAPED_TOOLBAR_WIDTH + 4, 10, 500, 10, NO_TEXT, fntGrey, taLeft);
  Label_Coordinates := TKMLabel.Create(Panel_Main, MAPED_TOOLBAR_WIDTH + 4, 30, 'X: Y:', fntGrey, taLeft);
  Label_Stat := TKMLabel.Create(Panel_Main, MAPED_TOOLBAR_WIDTH + 4, 50, 0, 0, '', fntOutline, taLeft);

//  TKMLabel.Create(Panel_Main, TB_PAD, 190, TB_WIDTH, 0, gResTexts[TX_MAPED_PLAYERS], fntOutline, taLeft);
  for I := 0 to MAX_HANDS - 1 do
  begin
    Button_PlayerSelect[I]         := TKMFlatButtonShape.Create(Panel_Main, TB_PAD + (I mod 6)*24, 190 + 24*(I div 6), 21, 21, IntToStr(I+1), fntGrey, $FF0000FF);
    Button_PlayerSelect[I].Tag     := I;
    Button_PlayerSelect[I].OnClick := Player_ActiveClick;
  end;
  Button_PlayerSelect[0].Down := True; //First player selected by default

  Button_History := TKMButtonFlat.Create(Panel_Main, Button_PlayerSelect[5].Right + 3, 190, 31, 32, 677);
  Button_History.TexOffsetX := -1;
  Button_History.Down := False; // History is hidden by default
  Button_History.OnClick := History_Click;
  Button_History.Hint := GetHintWHotKey(TX_MAPED_HISTORY_HINT, kfMapedHistory);

  Button_ChangeOwner := TKMButtonFlat.Create(Panel_Main, MAPED_TOOLBAR_WIDTH - 44 - 30 + TB_PAD, 190, 30, 32, 662);
  Button_ChangeOwner.Down := False;
  Button_ChangeOwner.OnClick := ChangeOwner_Click;
  Button_ChangeOwner.Hint := GetHintWHotKey(TX_MAPED_PAINT_BUCKET_CH_OWNER, kfMapedPaintBucket);

  //Button_TerrainUndo := TKMButton.Create(Panel_Terrain, Panel_Terrain.Width - 20, 0, 10, SMALL_TAB_H + 4, '<', bsGame);
  Button_Undo := TKMButtonFlat.Create(Panel_Main, Button_PlayerSelect[5].Right + 3, 227, 15, 32, 0);
  Button_Undo.Caption := '<';
  Button_Undo.CapOffsetY := -10;
  Button_Undo.CapColor := icGreen;
  Button_Undo.Hint := gResTexts[TX_MAPED_UNDO_HINT]+ ' (''Ctrl + Z'')';
  Button_Undo.OnClick := UnRedo_Click;

  //Button_TerrainRedo := TKMButton.Create(Panel_Terrain, Panel_Terrain.Width - 10, 0, 10, SMALL_TAB_H + 4, '>', bsGame);
  Button_Redo := TKMButtonFlat.Create(Panel_Main, Button_Undo.Right + 1, 227, 15, 32, 0);
  Button_Redo.Caption := '>';
  Button_Redo.CapOffsetY := -10;
  Button_Redo.CapColor := icGreen;
  Button_Redo.Hint := gResTexts[TX_MAPED_REDO_HINT] + ' (''Ctrl + Y'' or ''Ctrl + Shift + Z'')';
  Button_Redo.OnClick := UnRedo_Click;

  Button_UniversalEraser := TKMButtonFlat.Create(Panel_Main, MAPED_TOOLBAR_WIDTH - 44 - 30 + TB_PAD, 227, 30, 32, 340);
  Button_UniversalEraser.Down := False;
  Button_UniversalEraser.OnClick := UniversalEraser_Click;
  Button_UniversalEraser.Hint := GetHintWHotKey(TX_MAPED_UNIVERSAL_ERASER, kfMapedUnivErasor);

  Image_Extra := TKMImage.Create(Panel_Main, MAPED_TOOLBAR_WIDTH, Panel_Main.Height - 48, 30, 48, 494);
  Image_Extra.Anchors := [anLeft, anBottom];
  Image_Extra.HighlightOnMouseOver := True;
  Image_Extra.OnClick := Message_Click;
  Image_Extra.Hint := GetHintWHotKey(TX_KEY_FUNC_MAPEDIT_EXTRA, kfMapedExtra);

  Image_Message := TKMImage.Create(Panel_Main, MAPED_TOOLBAR_WIDTH, Panel_Main.Height - 48*2, 30, 48, 496);
  Image_Message.Anchors := [anLeft, anBottom];
  Image_Message.HighlightOnMouseOver := True;
  Image_Message.OnClick := Message_Click;
  Image_Message.Hide; //Hidden by default, only visible when a message is shown

  //Must be created before Hint so it goes over them
  fGuiExtras := TKMMapEdExtras.Create(Panel_Main, PageChanged);
  fGuiMessage := TKMMapEdMessage.Create(Panel_Main);

  Panel_Common := TKMPanel.Create(Panel_Main,TB_PAD_MAP_ED,262,TB_MAP_ED_WIDTH,Panel_Main.Height - 262);
  Panel_Common.Anchors := [anLeft, anTop, anBottom];

  {5 big tabs}
  Button_Main[1] := TKMButton.Create(Panel_Common, TB_PAD_MBTN_LEFT + BIG_PAD_W*0, 0, BIG_TAB_W, BIG_TAB_H, 381, rxGui, bsGame);
  Button_Main[2] := TKMButton.Create(Panel_Common, TB_PAD_MBTN_LEFT + BIG_PAD_W*1, 0, BIG_TAB_W, BIG_TAB_H, 589, rxGui, bsGame);
  Button_Main[3] := TKMButton.Create(Panel_Common, TB_PAD_MBTN_LEFT + BIG_PAD_W*2, 0, BIG_TAB_W, BIG_TAB_H, 392, rxGui, bsGame);
  Button_Main[4] := TKMButton.Create(Panel_Common, TB_PAD_MBTN_LEFT + BIG_PAD_W*3, 0, BIG_TAB_W, BIG_TAB_H, 441, rxGui, bsGame);
  Button_Main[5] := TKMButton.Create(Panel_Common, TB_PAD_MBTN_LEFT + BIG_PAD_W*4, 0, BIG_TAB_W, BIG_TAB_H, 389, rxGui, bsGame);
  Button_Main[1].Hint := GetHintWHotKey(TX_MAPED_TERRAIN, kfMapedTerrain);
  Button_Main[2].Hint := GetHintWHotKey(TX_MAPED_VILLAGE, kfMapedVillage);
  Button_Main[3].Hint := GetHintWHotKey(TX_MAPED_SCRIPTS_VISUAL, kfMapedVisual);
  Button_Main[4].Hint := GetHintWHotKey(TX_MAPED_SCRIPTS_GLOBAL, kfMapedGlobal);
  Button_Main[5].Hint := GetHintWHotKey(TX_MAPED_MENU, kfMapedMainMenu);
  for I := 1 to 5 do
    Button_Main[I].OnClick := Main_ButtonClick;

  //Terrain editing pages
  fGuiTerrain := TKMMapEdTerrain.Create(Panel_Common, PageChanged, HidePages);
  fGuiTown := TKMMapEdTown.Create(Panel_Common, PageChanged);
  fGuiPlayer := TKMMapEdPlayer.Create(Panel_Common, PageChanged);
  fGuiMission := TKMMapEdMission.Create(Panel_Common, PageChanged);
  fGuiMenu := TKMMapEdMenu.Create(Panel_Common, PageChanged, MapTypeChanged);

  //Objects pages
  fGuiUnit := TKMMapEdUnit.Create(Panel_Common);
  fGuiHouse := TKMMapEdHouse.Create(Panel_Common);
  fGuiMarkerDefence := TKMMapEdMarkerDefence.Create(Panel_Common, Marker_Done);
  fGuiMarkerReveal := TKMMapEdMarkerReveal.Create(Panel_Common, Marker_Done);

  //Modal pages
  fGuiAttack := TKMMapEdTownAttack.Create(Panel_Main);
  fGuiFormations := TKMMapEdTownFormations.Create(Panel_Main);
  fGuiGoal := TKMMapEdPlayerGoal.Create(Panel_Main);
  fGuiRMG := TKMMapEdRMG.Create(Panel_Main);
  fGuiMenuQuickPlay := TKMMapEdMenuQuickPlay.Create(Panel_Main, MapTypeChanged);

  //Pass pop-ups to their dispatchers
  fGuiTown.GuiDefence.FormationsPopUp := fGuiFormations;
  fGuiTown.GuiOffence.AttackPopUp := fGuiAttack;
  fGuiPlayer.GuiPlayerGoals.GoalPopUp := fGuiGoal;
  fGuiMenu.GuiMenuQuickPlay := fGuiMenuQuickPlay;
  fGuiTerrain.GuiSelection.GuiRMGPopUp := fGuiRMG;

  // PopUp window will be reated last
  PopUp_History := TKMPopUpPanel.Create(Panel_Main, 270, 300, gResTexts[TX_MAPED_HISTORY_TITLE], pubgitScrollWCross, False, False);
  PopUp_History.Left := Panel_Main.Width - PopUp_History.Width;
  PopUp_History.Top  := 0;
  PopUp_History.DragEnabled := True;
  PopUp_History.Hide; // History is hidden by default
  PopUp_History.OnMouseWheel := History_MouseWheel;
  PopUp_History.OnClose := History_Close;

    ListBox_History := TKMListBox.Create(PopUp_History, 10, 10, PopUp_History.Width - 20, PopUp_History.Height - 50, fntMetal, bsGame);
    ListBox_History.AutoHideScrollBar := True;
    ListBox_History.OnChange := History_ListChange;
    ListBox_History.OnDoubleClick := History_JumpTo;

    Button_History_JumpTo := TKMButton.Create(PopUp_History, 10, ListBox_History.Bottom + 5,
                                                             ListBox_History.Width, 20, gResTexts[TX_MAPED_HISTORY_JUMP_TO], bsGame);
    Button_History_JumpTo.OnClick := History_JumpTo;
    Button_History_JumpTo.Hint := gResTexts[TX_MAPED_HISTORY_JUMP_TO_HINT];

    Button_History_Undo := TKMButton.Create(PopUp_History, 10, PopUp_History.Height - 10, (ListBox_History.Width div 2) - 7, 20, '<< Undo', bsGame);
    Button_History_Undo.OnClick := UnRedo_Click;
    Button_History_Undo.Hint := gResTexts[TX_MAPED_UNDO_HINT]+ ' (''Ctrl + Z'')';

    Button_History_Redo := TKMButton.Create(PopUp_History, PopUp_History.Width - 10 - Button_History_Undo.Width,
                                                           Button_History_Undo.Top, Button_History_Undo.Width, 20, 'Redo >>', bsGame);
    Button_History_Redo.OnClick := UnRedo_Click;
    Button_History_Redo.Hint := gResTexts[TX_MAPED_REDO_HINT] + ' (''Ctrl + Y'' or ''Ctrl + Shift + Z'')';


  if OVERLAY_RESOLUTIONS then
  begin
    S := TKMShape.Create(Panel_Main, 0, 0, 1024, 576);
    S.LineColor := $FF00FFFF;
    S.LineWidth := 1;
    S.Hitable := False;
    S := TKMShape.Create(Panel_Main, 0, 0, 1024, 768);
    S.LineColor := $FF00FF00;
    S.LineWidth := 1;
    S.Hitable := False;
  end;

  HidePages;
  AfterCreateComplete;
end;


destructor TKMapEdInterface.Destroy;
begin
  fGuiHouse.Free;
  fGuiTerrain.Free;
  fGuiTown.Free;
  fGuiPlayer.Free;
  fGuiMission.Free;
  fGuiAttack.Free;
  fGuiExtras.Free;
  fGuiFormations.Free;
  fGuiMenuQuickPlay.Free;
  fGuiGoal.Free;
  fGuiRMG.Free;
  fGuiMarkerDefence.Free;
  fGuiMarkerReveal.Free;
  fGuiMenu.Free;
  fGuiMessage.Free;
  fGuiUnit.Free;

  SHOW_TERRAIN_WIRES := false; //Don't show it in-game if they left it on in MapEd
  SHOW_TERRAIN_PASS := 0; //Don't show it in-game if they left it on in MapEd
  inherited;
end;


procedure TKMapEdInterface.DebugControlsUpdated(aSenderTag: Integer);
begin
  inherited;

  fGuiExtras.Refresh;
end;


procedure TKMapEdInterface.Main_ButtonClick(Sender: TObject);
begin
  //Reset cursor mode
  gGameCursor.Mode := cmNone;
  gGameCursor.Tag1 := 0;

  //Reset shown item when user clicks on any of the main buttons
  gMySpectator.Selected := nil;

  if fGuiTerrain.GuiSelection.Visible then
    gGame.MapEditor.Selection.Cancel;

  HidePages;

  if (Sender = Button_Main[1]) then fGuiTerrain.Show(ttBrush) else
  if (Sender = Button_Main[2]) then
  begin
    fGuiTown.Show(ttHouses);
    fGuiTown.ChangePlayer; //Player's AI status might have changed
  end else
  if (Sender = Button_Main[3]) then fGuiPlayer.Show(ptGoals) else
  if (Sender = Button_Main[4]) then fGuiMission.Show(mtMode) else
  if (Sender = Button_Main[5]) then
  begin
    fGuiMenu.Show;
    //Signal that active page has changed, that may affect layers visibility
    PageChanged(fGuiMenu);
  end;
end;


procedure TKMapEdInterface.HidePages;
var
  I, K: Integer;
begin
  //Hide all existing pages (2 levels)
  for I := 0 to Panel_Common.ChildCount - 1 do
    if Panel_Common.Childs[I] is TKMPanel then
    begin
      Panel_Common.Childs[I].Hide;
      for K := 0 to TKMPanel(Panel_Common.Childs[I]).ChildCount - 1 do
      if TKMPanel(Panel_Common.Childs[I]).Childs[K] is TKMPanel then
        TKMPanel(Panel_Common.Childs[I]).Childs[K].Hide;
    end;

  gGame.MapEditor.Reset;
end;


procedure TKMapEdInterface.History_Click(Sender: TObject);
begin
  PopUp_History.Visible := not PopUp_History.Visible;

  Button_History.Down := PopUp_History.Visible;
end;


procedure TKMapEdInterface.History_Close;
begin
  Button_History.Down := PopUp_History.Visible;
end;


procedure TKMapEdInterface.History_JumpTo(Sender: TObject);
begin
  if ListBox_History.Selected then
    gGame.MapEditor.History.JumpTo(ListBox_History.ItemIndex);
end;


procedure TKMapEdInterface.UpdatePlayerSelectButtons;
const
  CAP_COLOR: array [Boolean] of Cardinal = ($80808080, $FFFFFFFF);
var
  I: Integer;
begin
  for I := 0 to MAX_HANDS - 1 do
    Button_PlayerSelect[I].FontColor := CAP_COLOR[gHands[I].HasAssets];
end;


//Should update any items changed by game (resource counts, hp, etc..)
procedure TKMapEdInterface.UpdateState(aTickCount: Cardinal);
begin
  inherited;
  //Update minimap every 500ms
  if aTickCount mod 5 = 0 then
    fMinimap.Update;

  //Show players without assets in grey
  if aTickCount mod 5 = 0 then
    UpdatePlayerSelectButtons;

  UpdateStateInternal;
end;


procedure TKMapEdInterface.UpdateStateInternal;
begin
  fGuiTerrain.UpdateState;
  fGuiHouse.UpdateState;
  fGuiMenu.UpdateState;
  fGuiTown.UpdateState;
  fGuiPlayer.UpdateState;

  Button_ChangeOwner.Down := gGameCursor.Mode = cmPaintBucket;
  Button_UniversalEraser.Down := gGameCursor.Mode = cmUniversalEraser;
end;

  
procedure TKMapEdInterface.UpdateStateImmidiately;
begin
  fMinimap.Update;
  UpdatePlayerSelectButtons;
  UpdateStateInternal;
end;


procedure TKMapEdInterface.UpdateStateIdle(aFrameTime: Cardinal);
begin
  //Check to see if we need to scroll
  fViewport.UpdateStateIdle(aFrameTime, not fDragScrolling, False);
  fGuiTown.UpdateStateIdle;
  Update_Label_Coordinates;
end;


//Update UI state according to game state
procedure TKMapEdInterface.SyncUI(aMoveViewport: Boolean = True);
var
  I: Integer;
begin
  inherited;
  if aMoveViewport then
    fViewport.Position := KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2);

  MinimapView.SetMinimap(fMinimap);
  MinimapView.SetViewport(fViewport);

  //Set player colors
  for I := 0 to MAX_HANDS - 1 do
    Button_PlayerSelect[I].ShapeColor := gHands[I].FlagColor;

  Player_UpdatePages;

  UpdatePlayerSelectButtons;

  Label_MissionName.Caption := gGameParams.Name;
end;


//Active page has changed, that affects layers visibility
procedure TKMapEdInterface.PageChanged(Sender: TObject);
begin
  //Child panels visibility changed, that affects visible layers
  Layers_UpdateVisibility;
end;


//Set which layers are visible and which are not
//Layer is always visible if corresponding editing page is active (to see what gets placed)
procedure TKMapEdInterface.Layers_UpdateVisibility;
var
  flatTerWasEnabled: Boolean;
begin
  if gGame = nil then Exit; //Happens on init

  flatTerWasEnabled := mlFlatTerrain in gGameParams.VisibleLayers;

  gGameParams.VisibleLayers := [];
  gGame.MapEditor.VisibleLayers := [];

  //Map visible layers
  if fGuiExtras.CheckBox_ShowDefences.Checked {and not fGuiMarkerDefence.Visible} then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlDefencesAll];

  if fGuiExtras.CheckBox_ShowFlatTerrain.Checked then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlFlatTerrain];

  if fGuiExtras.CheckBox_ShowObjects.Checked or fGuiTerrain.IsVisible(ttObject) then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlObjects];

  if fGuiExtras.CheckBox_ShowHouses.Checked or fGuiTown.IsVisible(ttHouses) or fGuiHouse.Visible then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlHouses];

  if fGuiExtras.CheckBox_ShowUnits.Checked or fGuiTown.IsVisible(ttUnits) or fGuiUnit.Visible then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlUnits];

  if fGuiExtras.CheckBox_ShowMiningRadius.Checked then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlMiningRadius];

  if fGuiExtras.CheckBox_ShowTowersAttackRadius.Checked then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlTowersAttackRadius];

  if fGuiExtras.CheckBox_ShowUnitsAttackRadius.Checked then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlUnitsAttackRadius];

  if fGuiExtras.CheckBox_ShowOverlays.Checked then
    gGameParams.VisibleLayers := gGameParams.VisibleLayers + [mlOverlays];

  // MapEd visible layers
  if fGuiTown.IsVisible(ttDefences) or fGuiMarkerDefence.Visible then
    gGame.MapEditor.VisibleLayers := gGame.MapEditor.VisibleLayers + [melDefences];

  if fGuiPlayer.IsVisible(ptView) or fGuiMarkerReveal.Visible then
    gGame.MapEditor.VisibleLayers := gGame.MapEditor.VisibleLayers + [melRevealFOW, melCenterScreen];

  if fGuiTown.IsVisible(ttScript) then
    gGame.MapEditor.VisibleLayers := gGame.MapEditor.VisibleLayers + [melAIStart];

  if fGuiTerrain.IsVisible(ttSelection) then
    gGame.MapEditor.VisibleLayers := gGame.MapEditor.VisibleLayers + [melSelection];

  if fGuiExtras.CheckBox_ShowDeposits.Checked then
    gGame.MapEditor.VisibleLayers := gGame.MapEditor.VisibleLayers + [melDeposits];

  if fGuiMenu.GuiMenuResize.Visible then
    gGame.MapEditor.VisibleLayers := gGame.MapEditor.VisibleLayers + [melMapResize];

  if flatTerWasEnabled xor (mlFlatTerrain in gGameParams.VisibleLayers) then
    gTerrain.UpdateLighting;
end;


procedure TKMapEdInterface.Player_ActiveClick(Sender: TObject);
begin
  //Hide player-specific pages
  fGuiHouse.Hide;
  fGuiUnit.Hide;
  fGuiMarkerDefence.Hide;
  fGuiMarkerReveal.Hide;

  if gMySpectator.Selected <> nil then
    gMySpectator.Selected := nil;

  Player_SetActive(TKMControl(Sender).Tag);
end;


procedure TKMapEdInterface.SetPaintBucketMode(aSetPaintBucketMode: Boolean);
begin
  Button_ChangeOwner.Down := aSetPaintBucketMode;
  if aSetPaintBucketMode then
    gGameCursor.Mode := cmPaintBucket
  else
    gGameCursor.Mode := cmNone;
end;


procedure TKMapEdInterface.SetUniversalEraserMode(aSetUniversalEraserMode: Boolean);
begin
  Button_UniversalEraser.Down := aSetUniversalEraserMode;
  if aSetUniversalEraserMode then
  begin
    gGameCursor.Mode := cmUniversalEraser;
    // Clear selected object, as it could be deleted
    gMySpectator.Selected := nil;
    HidePages;
  end else
    gGameCursor.Mode := cmNone;
end;


procedure TKMapEdInterface.ChangeOwner_Click(Sender: TObject);
begin
  SetPaintBucketMode(not Button_ChangeOwner.Down);
end;


procedure TKMapEdInterface.UniversalEraser_Click(Sender: TObject);
begin
  SetUniversalEraserMode(not Button_UniversalEraser.Down);
end;


procedure TKMapEdInterface.UnRedo_Click(Sender: TObject);
begin
  if (Sender = Button_Undo)
    or (Sender = Button_History_Undo) then
    gGame.MapEditor.History.Undo;

  if (Sender = Button_Redo)
    or (Sender = Button_History_Redo) then
    gGame.MapEditor.History.Redo;
end;


//Active player can be set either from buttons clicked or by selecting a unit or a house
procedure TKMapEdInterface.Player_SetActive(aIndex: TKMHandID);
var
  I: Integer;
begin
  gMySpectator.HandID := aIndex;
  fGuiMission.GuiMissionPlayers.UpdatePlayer(aIndex);
  fGuiTown.GuiDefence.UpdatePlayer(aIndex);

  for I := 0 to MAX_HANDS - 1 do
    Button_PlayerSelect[I].Down := (I = gMySpectator.HandID);

  Player_UpdatePages;
end;


procedure TKMapEdInterface.ShowMarkerInfo(aMarker: TKMMapEdMarker);
begin
  HidePages; // HidePages first. That will also reset old marker;

  gGame.MapEditor.ActiveMarker := aMarker;
  Assert((aMarker.MarkerType <> mmtNone) and (aMarker.Owner <> PLAYER_NONE) and (aMarker.Index <> -1));

  Player_SetActive(aMarker.Owner);

  case aMarker.MarkerType of
    mmtDefence:    fGuiMarkerDefence.Show(aMarker.Owner, aMarker.Index);
    mmtRevealFOW:  fGuiMarkerReveal.Show(aMarker.Owner, aMarker.Index);
  end;

  Layers_UpdateVisibility;
end;


procedure TKMapEdInterface.ShowMessage(const aText: string);
begin
  fGuiMessage.Show(aText);
  Image_Message.Show; //Hidden by default, only visible when a message is shown
end;


//When marker page is done we want to return to markers control page
procedure TKMapEdInterface.Marker_Done(Sender: TObject);
begin
  gGame.MapEditor.ActiveMarker.MarkerType := mmtNone;
  if Sender = fGuiMarkerReveal then
  begin
    HidePages;
    fGuiPlayer.Show(ptView);
  end;
  if Sender = fGuiMarkerDefence then
  begin
    HidePages;
    fGuiTown.Show(ttDefences);
  end;
end;


//This function will be called if the user right clicks on the screen.
procedure TKMapEdInterface.Cancel_Clicked(aIsRMB: Boolean; var aHandled: Boolean);
begin
  if aHandled then Exit;
  //We should drop the tool but don't close opened tab. This allows eg:
  //Place a warrior, right click so you are not placing more warriors,
  //select the placed warrior.
  if aIsRMB then
  begin
    // When global tools are used, just cancel the tool, even if some page is open
    if not (gGameCursor.Mode in [cmPaintBucket, cmUniversalEraser]) then
    begin
      //These pages use RMB
      if fGuiTerrain.IsVisible(ttHeights) then Exit;
      if fGuiTerrain.IsVisible(ttTile) then Exit;
      if fGuiUnit.Visible then Exit;
      if fGuiHouse.Visible then Exit;
      if fGuiMarkerDefence.Visible then Exit;
      if fGuiMarkerReveal.Visible then Exit;
    end;

    // We rotate tile on RMB
    if gGameCursor.Mode = cmTiles then Exit;
  end;

  fGuiTerrain.Cancel_Clicked(aHandled);

  // Reset cursor
  // Call for DoResetCursorMode first to do cancel the cursor even if we already handled event earlier
  aHandled := DoResetCursorMode or aHandled;
  //Reset drag object fields
  ResetDragObject;
  gRes.Cursors.Cursor := kmcDefault;

  gGame.MapEditor.Reset;
end;


procedure TKMapEdInterface.Player_UpdatePages;
begin
  //Update players info on pages
  //Colors are updated as well
  //Update regardless of whether the panels are visible, since the user could open then at any time
  fGuiTown.ChangePlayer;
  fGuiPlayer.ChangePlayer;
end;


procedure TKMapEdInterface.Message_Click(Sender: TObject);
begin
  if Sender = Image_Extra then
    if fGuiExtras.Visible then
      fGuiExtras.Hide
    else
    begin
      fGuiMessage.Hide;
      fGuiExtras.Show;
    end;

  if Sender = Image_Message then
    if fGuiMessage.Visible then
      fGuiMessage.Hide
    else
    begin
      fGuiMessage.Show;
      fGuiExtras.Hide;
    end;
end;


//Update viewport position when user interacts with minimap
procedure TKMapEdInterface.Minimap_OnUpdate(Sender: TObject; const X,Y: Integer);
begin
  fViewport.Position := KMPointF(X,Y);
end;


procedure TKMapEdInterface.ExportPages(const aPath: string);
var
  path: string;
  I: TKMTerrainTab;
  K: TKMTownTab;
  L: TKMPlayerTab;
  M: TKMMissionTab;
begin
  inherited;

  path := aPath + 'MapEd' + PathDelim;
  ForceDirectories(path);

  for I := Low(TKMTerrainTab) to High(TKMTerrainTab) do
  begin
    HidePages;
    fGuiTerrain.Show(I);
    gGameApp.PrintScreen(path + 'Terrain' + IntToStr(Byte(I)) + '.jpg');
  end;

  for K := Low(TKMTownTab) to High(TKMTownTab) do
  begin
    HidePages;
    fGuiTown.Show(K);
    gGameApp.PrintScreen(path + 'Town' + IntToStr(Byte(K)) + '.jpg');
  end;

  for L := Low(TKMPlayerTab) to High(TKMPlayerTab) do
  begin
    HidePages;
    fGuiPlayer.Show(L);
    gGameApp.PrintScreen(path + 'Player' + IntToStr(Byte(L)) + '.jpg');
  end;

  for M := Low(TKMMissionTab) to High(TKMMissionTab) do
  begin
    HidePages;
    fGuiMission.Show(M);
    gGameApp.PrintScreen(path + 'Mission' + IntToStr(Byte(M)) + '.jpg');
  end;

  HidePages;
  fGuiHouse.Show(nil);
  gGameApp.PrintScreen(path + 'House.jpg');

  HidePages;
  fGuiUnit.Show(TKMUnit(nil));
  gGameApp.PrintScreen(path + 'Unit.jpg');
end;


function TKMapEdInterface.GetToolBarWidth: Integer;
begin
  Result := MAPED_TOOLBAR_WIDTH;
end;


procedure TKMapEdInterface.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
var
  keyHandled, keyPassedToModal: Boolean;
begin
  aHandled := True; // assume we handle all keys here

  if fMyControls.KeyDown(Key, Shift) then
  begin
    fViewport.ReleaseScrollKeys; //Release the arrow keys when you open a window with an edit to stop them becoming stuck
    Exit; //Handled by Controls
  end;

  keyHandled := False;

  //For MapEd windows / pages
  fGuiTerrain.KeyDown(Key, Shift, keyHandled); // Terrain first (because of Objects and Tiles popup windows)
  fGuiHouse.KeyDown(Key, Shift, keyHandled);
  fGuiUnit.KeyDown(Key, Shift, keyHandled);
  fGuiTown.KeyDown(Key, Shift, keyHandled);
  fGuiMission.KeyDown(Key, Shift, keyHandled);

  if keyHandled then Exit;

  inherited KeyDown(Key, Shift, keyHandled);
  if keyHandled then Exit;

  gGameCursor.SState := Shift; // Update Shift state on KeyDown

  keyPassedToModal := False;
  //Pass Key to Modal pages first
  //todo: refactoring - remove fGuiAttack.KeyDown and similar methods,
  //as KeyDown should be handled in Controls them selves (TKMPopUpWindow, f.e.)
  if (fGuiAttack.Visible and fGuiAttack.KeyDown(Key, Shift))
    or (fGuiFormations.Visible and fGuiFormations.KeyDown(Key, Shift))
    or (fGuiGoal.Visible and fGuiGoal.KeyDown(Key, Shift))
    or (fGuiMenuQuickPlay.Visible and fGuiMenuQuickPlay.KeyDown(Key, Shift)) then
    keyPassedToModal := True;

  //For now enter can open up Extra panel
  if not keyPassedToModal and (Key = gResKeys[kfMapedExtra].Key) then
    Message_Click(Image_Extra);

  // If modals are closed or they did not handle key
  if not keyPassedToModal and (Key = gResKeys[kfCloseMenu].Key) then
  begin
    Cancel_Clicked(False, keyHandled);
    if not keyHandled then
    begin
      if fGuiMessage.Visible then
        fGuiMessage.Hide
      else
      if fGuiExtras.Visible then
        fGuiExtras.Hide;
    end;
  end;
end;


procedure TKMapEdInterface.ShowSubMenu(aIndex: Byte);
begin
  fGuiTerrain.ShowSubMenu(aIndex);
  fGuiTown.ShowSubMenu(aIndex);
  fGuiPlayer.ShowSubMenu(aIndex);
  fGuiMission.ShowSubMenu(aIndex);
  fGuiMenu.ShowSubMenu(aIndex);
end;


procedure TKMapEdInterface.ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
begin
  fGuiTerrain.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiTown.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiPlayer.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiMission.ExecuteSubMenuAction(aIndex, aHandled);
end;


procedure TKMapEdInterface.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
var
  I: Integer;
  keyHandled: Boolean;
begin
  if fMyControls.KeyUp(Key, Shift) then Exit; //Handled by Controls

  inherited;

  if aHandled then Exit;

  aHandled := True; // assume we handle all keys here

  keyHandled := False;
  //For undo/redo shortcuts, palettes and other
  fGuiTerrain.KeyUp(Key, Shift, keyHandled);
  if keyHandled then Exit;

  //F1-F5 menu shortcuts
  if Key = gResKeys[kfMapedTerrain].Key   then
    Button_Main[1].Click;
  if Key = gResKeys[kfMapedVillage].Key   then
    Button_Main[2].Click;
  if Key = gResKeys[kfMapedVisual].Key    then
    Button_Main[3].Click;
  if Key = gResKeys[kfMapedGlobal].Key    then
    Button_Main[4].Click;
  if Key = gResKeys[kfMapedMainMenu].Key then
    Button_Main[5].Click;

  //1-6 submenu shortcuts
  for I := Low(MAPED_SUBMENU_HOTKEYS) to High(MAPED_SUBMENU_HOTKEYS) do
    if Key = gResKeys[MAPED_SUBMENU_HOTKEYS[I]].Key then
      ShowSubMenu(I);

  //q-w-e-r-t-y-u submenu actions shortcuts
  for I := Low(MAPED_SUBMENU_ACTIONS_HOTKEYS) to High(MAPED_SUBMENU_ACTIONS_HOTKEYS) do
    if Key = gResKeys[MAPED_SUBMENU_ACTIONS_HOTKEYS[I]].Key then
    begin
      keyHandled := False;
      ExecuteSubMenuAction(I, keyHandled);
    end;

  //Universal erasor
  if Key = gResKeys[kfMapedUnivErasor].Key then
    UniversalEraser_Click(Button_UniversalEraser);

  //Universal erasor
  if Key = gResKeys[kfMapedPaintBucket].Key then
    ChangeOwner_Click(Button_ChangeOwner);

  //History
  if Key = gResKeys[kfMapedHistory].Key then
    History_Click(Button_History);


  if (ssCtrl in Shift) and (Key = Ord('Y')) then
  begin
    UnRedo_Click(Button_Redo); // Ctrl+Y = Redo
    aHandled := True;
  end;

  if (ssCtrl in Shift) and (Key = Ord('Z')) then
  begin
    if ssShift in Shift then
      UnRedo_Click(Button_Redo) //Ctrl+Shift+Z = Redo
    else
      UnRedo_Click(Button_Undo); //Ctrl+Z = Undo
    aHandled := True;
  end;

  gGameCursor.SState := Shift; // Update Shift state on KeyUp
end;


procedure TKMapEdInterface.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var
  obj: TObject;
  keyHandled: Boolean;
begin
  inherited;

  fMyControls.MouseDown(X,Y,Shift,Button);

  if fMyControls.CtrlOver <> nil then
    Exit;

  if (Button = mbLeft) and (gGameCursor.Mode = cmNone) then
  begin
    obj := gMySpectator.HitTestCursor;
    if obj <> nil then
    begin
      UpdateSelection;
      fDragObject := obj;
      if obj is TKMHouse then
        fDragHouseOffset := KMPointSubtract(TKMHouse(obj).Entrance, gGameCursor.Cell); //Save drag point adjustement to house position
      fDragObjectReady := True;
      fDragObjMousePosStart := KMPoint(X,Y);
    end;
  end;

  keyHandled := False;
  if Button = mbRight then
    Cancel_Clicked(True, keyHandled);

  //So terrain brushes start on mouse down not mouse move
  UpdateCursor(X, Y, Shift);

  if not keyHandled then
    gGame.MapEditor.MouseDown(Button);
end;


procedure TKMapEdInterface.Update_Label_Coordinates;
begin
  Label_Coordinates.Caption := Format('X: %d, Y: %d, Z: %d', [gGameCursor.Cell.X, gGameCursor.Cell.Y,
                                                              gTerrain.Land^[EnsureRange(Round(gGameCursor.Float.Y + 1), 1, gTerrain.MapY),
                                                                            EnsureRange(Round(gGameCursor.Float.X + 1), 1, gTerrain.MapX)].RenderHeight]);
end;


procedure TKMapEdInterface.MapTypeChanged(aIsMultiplayer: Boolean);
begin
  SetLoadMode(aIsMultiplayer);
end;


procedure TKMapEdInterface.MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean);
const
  DRAG_OBJECT_MOUSE_MOVE_DIST = 15; //distance in pixels, when drag object mode starts
begin
  inherited MouseMove(Shift, X, Y, aHandled);
  if aHandled then Exit;

  aHandled := True;

  if fDragObjectReady and (KMLength(fDragObjMousePosStart, KMPoint(X,Y)) > DRAG_OBJECT_MOUSE_MOVE_DIST) then
  begin
    if not (ssLeft in Shift) then
    begin
      ResetDragObject;
      Exit;
    end else begin
      gRes.Cursors.Cursor := kmcDrag;
      fDragingObject := True;
    end;
  end;

  fMyControls.MouseMove(X,Y,Shift);

  if fMyControls.CtrlOver <> nil then
  begin
    //kmcEdit and kmcDragUp are handled by Controls.MouseMove (it will reset them when required)
    if not fViewport.Scrolling and not (gRes.Cursors.Cursor in [kmcEdit,kmcDragUp]) then
      gRes.Cursors.Cursor := kmcDefault;
    gGameCursor.SState := []; //Don't do real-time elevate when the mouse is over controls, only terrain
    Exit;
  end
  else
    DisplayHint(nil); //Clear shown hint

  if (ssLeft in Shift) or (ssRight in Shift) then
    fMouseDownOnMap := True;

  UpdateCursor(X, Y, Shift);

  gGame.MapEditor.MouseMove;
end;


procedure TKMapEdInterface.UpdateCursor(X, Y: Integer; Shift: TShiftState);
var
  marker: TKMMapEdMarker;
begin
  UpdateGameCursor(X, Y, Shift);

  if gGameCursor.Mode = cmPaintBucket then
  begin
    gRes.Cursors.Cursor := kmcPaintBucket;
    Exit;
  end;

  if fDragingObject and (ssLeft in Shift) then
  begin
    //Cursor can be reset to default, when moved to menu panel while dragging, so set it to drag cursor again
    gRes.Cursors.Cursor := kmcDrag;
    MoveObjectToCursorCell(fDragObject);
  end else
  if gGameCursor.Mode = cmNone then
  begin
    marker := gGame.MapEditor.HitTest(gGameCursor.Cell.X, gGameCursor.Cell.Y);
    if marker.MarkerType <> mmtNone then
      gRes.Cursors.Cursor := kmcInfo
    else
    if gMySpectator.HitTestCursor <> nil then
      gRes.Cursors.Cursor := kmcInfo
    else
    if not fViewport.Scrolling then
      gRes.Cursors.Cursor := kmcDefault;
  end;

  Update_Label_Coordinates;
end;


procedure TKMapEdInterface.History_ListChange(Sender: TObject);
begin
  Button_History_JumpTo.Enabled := ListBox_History.Selected;
end;


procedure TKMapEdInterface.History_MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  ListBox_History.MouseWheel(Sender, WheelSteps, aHandled);

  aHandled := True;
end;


procedure TKMapEdInterface.HistoryAddCheckpoint;
begin
  HistoryUpdateUI;
end;


procedure TKMapEdInterface.HistoryUndoRedo;
begin
  if Self = nil then Exit;

  HistoryUpdateUI;

  gGame.MapEditor.Selection.RefreshLand;

  if fGuiHouse.Visible or fGuiUnit.Visible then
  begin
    gMySpectator.Selected := nil; // Reset selection
    HidePages;
  end;
end;


procedure TKMapEdInterface.HistoryUpdateUI;
begin
  if Self = nil then Exit;

  Button_Undo.Enabled := gGame.MapEditor.History.CanUndo;
  Button_Redo.Enabled := gGame.MapEditor.History.CanRedo;

  Button_History_Undo.Enabled := Button_Undo.Enabled;
  Button_History_Redo.Enabled := Button_Redo.Enabled;

  gGame.MapEditor.History.GetCheckpoints(ListBox_History.Items);
  ListBox_History.UpdateScrollBar;

  ListBox_History.SetTopIndex(gGame.MapEditor.History.Position, True);
  History_ListChange(nil);
end;


function TKMapEdInterface.DoResetCursorMode: Boolean;
begin
  Result := gGameCursor.Mode <> cmNone;
  gGameCursor.Mode := cmNone;
end;


//Start drag house move mode (with cursor mode cmHouse)
procedure TKMapEdInterface.DragHouseModeStart(const aHouseNewPos, aHouseOldPos: TKMPoint);

  procedure SetCursorModeHouse(aHouseType: TKMHouseType);
  begin
    gGameCursor.Mode := cmHouses;
    gGameCursor.Tag1 := Byte(aHouseType);
    //Update cursor DragOffset to render house markups at proper positions
    gGameCursor.DragOffset := fDragHouseOffset;
  end;

var
  H: TKMHouse;
begin
  if fDragObject is TKMHouse then
  begin
    H := TKMHouse(fDragObject);
    //Temporarily remove house from terrain to render house markups as there is no current house (we want to move it)
    gTerrain.SetHouse(H.Position, H.HouseType, hsNone, H.Owner);
    SetCursorModeHouse(H.HouseType); //Update cursor mode to cmHouse
  end;
end;


//Drag house move mode end (with cursor mode cmHouse)
procedure TKMapEdInterface.DragHouseModeEnd;
var H: TKMHouse;
begin
  if (fDragObject is TKMHouse) then
  begin
    H := TKMHouse(fDragObject);
    H.SetPosition(KMPointAdd(gGameCursor.Cell, fDragHouseOffset));
    DoResetCursorMode;
  end;
end;


function TKMapEdInterface.IsDragHouseModeOn: Boolean;
begin
  Result := fDragingObject and (fDragObject is TKMHouse) and (gGameCursor.Mode = cmHouses);
end;


procedure TKMapEdInterface.MoveObjectToCursorCell(aObjectToMove: TObject);
var
  H: TKMHouse;
  houseNewPos, houseOldPos: TKMPoint;
begin
  if aObjectToMove = nil then Exit;

  //House move
  if aObjectToMove is TKMHouse then
  begin
    H := TKMHouse(aObjectToMove);

    houseOldPos := H.Position;

    houseNewPos := KMPointAdd(gGameCursor.Cell, fDragHouseOffset);

    if not fDragingObject then
      H.SetPosition(houseNewPos)  //handles Right click, when house is selected
    else
      if not IsDragHouseModeOn then
        DragHouseModeStart(houseNewPos, houseOldPos);
  end;

  //Unit move
  if aObjectToMove is TKMUnit then
  begin
    if aObjectToMove is TKMUnitWarrior then
      aObjectToMove := gHands.GetGroupByMember(TKMUnitWarrior(aObjectToMove))
    else
      TKMUnit(aObjectToMove).SetUnitPosition(gGameCursor.Cell);
  end;

  //Unit group move
  if aObjectToMove is TKMUnitGroup then
    //Just move group to specified location
    TKMUnitGroup(aObjectToMove).SetGroupPosition(gGameCursor.Cell);
end;


procedure TKMapEdInterface.UpdateSelection;
begin
  gMySpectator.UpdateSelect;

  if gMySpectator.Selected is TKMHouse then
  begin
    HidePages;
    Player_SetActive(TKMHouse(gMySpectator.Selected).Owner);
    fGuiHouse.Show(TKMHouse(gMySpectator.Selected));
  end;
  if gMySpectator.Selected is TKMUnit then
  begin
    HidePages;
    Player_SetActive(TKMUnit(gMySpectator.Selected).Owner);
    fGuiUnit.Show(TKMUnit(gMySpectator.Selected));
  end;
  if gMySpectator.Selected is TKMUnitGroup then
  begin
    HidePages;
    Player_SetActive(TKMUnitGroup(gMySpectator.Selected).Owner);
    fGuiUnit.Show(TKMUnitGroup(gMySpectator.Selected));
  end;
end;


procedure TKMapEdInterface.ResetDragObject;
begin
  fDragObjectReady := False;
  fDragingObject := False;
  fDragHouseOffset := KMPOINT_ZERO;
  fDragObjMousePosStart := KMPOINT_ZERO;
  fDragObject := nil;

  if gRes.Cursors.Cursor = kmcDrag then
    gRes.Cursors.Cursor := kmcDefault;

  if gGameCursor.Mode = cmHouses then
    DoResetCursorMode;
end;


procedure TKMapEdInterface.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DP: TAIDefencePosition;
  marker: TKMMapEdMarker;
  G: TKMUnitGroup;
  U: TKMUnit;
  H: TKMHouse;
begin
  if fDragingObject then
  begin
    DragHouseModeEnd;
    ResetDragObject;
  end;

  if fMyControls.CtrlOver <> nil then
  begin
    //Still need to make checkpoint if painting and released over controls
    if fMouseDownOnMap then
    begin
      gGame.MapEditor.MouseUp(Button, False);
      fMouseDownOnMap := False;
    end;
    fMyControls.MouseUp(X,Y,Shift,Button);
    Exit; //We could have caused fGame reinit, so exit at once
  end;

  fMouseDownOnMap := False;

  case Button of
    mbLeft:   if gGameCursor.Mode = cmNone then
              begin
                //If there are some additional layers we first HitTest them
                //since they are rendered ontop of Houses/Objects
                marker := gGame.MapEditor.HitTest(gGameCursor.Cell.X, gGameCursor.Cell.Y);

                if marker.MarkerType <> mmtNone then
                begin
                  ShowMarkerInfo(marker);
                  gMySpectator.Selected := nil; //We might have had a unit/group/house selected
                end
                else
                begin
                  UpdateSelection;
                  if gMySpectator.Selected <> nil then
                    gGame.MapEditor.ActiveMarker.MarkerType := mmtNone;
                end;
              end;
    mbRight:  begin
                //Right click performs some special functions and shortcuts
                if gGameCursor.Mode = cmTiles then
                  gGameCursor.MapEdDir := (gGameCursor.MapEdDir + 1) mod 4; //Rotate tile direction

                //Check if we are in rally/cutting marker mode
                if (gGameCursor.Mode = cmMarkers) and (gGameCursor.Tag1 = MARKER_RALLY_POINT) then
                begin
                  gGameCursor.Mode := cmNone;
                  Exit;
                end;

                //Move the selected object to the cursor location
                if gMySpectator.Selected is TKMHouse then
                begin
                  if ssShift in Shift then
                  begin
                    if gMySpectator.Selected is TKMHouseWFlagPoint then
                      TKMHouseWFlagPoint(gMySpectator.Selected).FlagPoint := gGameCursor.Cell;
                  end else
                    TKMHouse(gMySpectator.Selected).SetPosition(gGameCursor.Cell); //Can place is checked in SetPosition
                  Exit;
                end;

                if gMySpectator.Selected is TKMUnitGroup then
                begin
                  G := TKMUnitGroup(gMySpectator.Selected);
                  //Use Shift to set group order
                  if ssShift in gGameCursor.SState then
                  begin
                    U := gTerrain.UnitsHitTest(gGameCursor.Cell.X, gGameCursor.Cell.Y);
                    H := gHands.HousesHitTest(gGameCursor.Cell.X, gGameCursor.Cell.Y);
                    //If there's any enemy unit or house on specified tile - set attack target
                    if ((U <> nil) and (gHands[U.Owner].Alliances[G.Owner] = atEnemy))
                    or ((H <> nil) and (gHands[H.Owner].Alliances[G.Owner] = atEnemy)) then
                      G.MapEdOrder.Order := gioAttackPosition
                    //Else order group walk to specified location
                    else
                    if G.CanWalkTo(KMPoint(gGameCursor.Cell.X, gGameCursor.Cell.Y), 0) then
                      G.MapEdOrder.Order := gioSendGroup
                    else
                    //Can't take any orders: f.e. can't walk to unwalkable tile (water, mountain) or attack allied houses
                      G.MapEdOrder.Order := gioNoOrder;
                    //Save target coordinates
                    G.MapEdOrder.Pos.Loc.X := gGameCursor.Cell.X;
                    G.MapEdOrder.Pos.Loc.Y := gGameCursor.Cell.Y;
                    G.MapEdOrder.Pos.Dir := G.Direction;
                    //Update group GUI
                    fGuiUnit.Show(G);
                  end else
                    MoveObjectToCursorCell(gMySpectator.Selected);
                end else
                  MoveObjectToCursorCell(gMySpectator.Selected);

                if fGuiMarkerDefence.Visible then
                begin
                  DP := gHands[fGuiMarkerDefence.Owner].AI.General.DefencePositions[fGuiMarkerDefence.Index];
                  DP.Position := KMPointDir(gGameCursor.Cell, DP.Position.Dir);
                end;

                if fGuiMarkerReveal.Visible then
                  gGame.MapEditor.Revealers[fGuiMarkerReveal.Owner][fGuiMarkerReveal.Index] := gGameCursor.Cell;
              end;
  end;

  UpdateGameCursor(X, Y, Shift); //Updates the shift state

  gGame.MapEditor.MouseUp(Button, True);

  //Update the XY coordinates of the Center Screen button
  if (gGameCursor.Mode = cmMarkers) and (gGameCursor.Tag1 = MARKER_CENTERSCREEN) then
    fGuiPlayer.ChangePlayer; //Forces an update

  Exclude(Shift, ssRight);
  Exclude(Shift, ssLeft);
  UpdateGameCursor(X, Y, Shift); //Updates the shift state after
end;


procedure TKMapEdInterface.MouseWheel(Shift: TShiftState; WheelSteps, X,Y: Integer; var aHandled: Boolean);
begin
  if fMyControls.CtrlOver <> nil then
  begin
    fMyControls.MouseWheel(X, Y, WheelSteps, aHandled);
    if not aHandled then
      inherited;
    Exit; // Don't change field stages when mouse not over map
  end;

  if aHandled then Exit;
  
  if gGameCursor.Mode in [cmField, cmWine] then
  begin
    if (X < 0) or (Y < 0) then Exit; // This happens when you use the mouse wheel on the window frame

    gGame.MapEditor.MouseWheel(Shift, WheelSteps, X, Y);
  end else begin
    fGuiTerrain.MouseWheel(Shift, WheelSteps, X, Y, aHandled);
    if not aHandled then
      inherited;
  end;
end;


procedure TKMapEdInterface.Resize(X,Y: Word);
begin
  inherited;

  fViewport.Resize(X, Y);
  fGuiTerrain.Resize;

  // Put PopUp_History back into window, if it goes out of it
  PopUp_History.Top := PopUp_History.Top;
  PopUp_History.Left := PopUp_History.Left;
end;


procedure TKMapEdInterface.SetLoadMode(aMultiplayer: Boolean);
begin
  fGuiMenu.SetLoadMode(aMultiplayer);
end;


//UI should paint only controls
procedure TKMapEdInterface.Paint;
var
  I: Integer;
  R: TKMRawDeposit;
  locF: TKMPointF;
  screenLoc: TKMPoint;
begin
  if melDeposits in gGame.MapEditor.VisibleLayers then
  begin
    for R := Low(TKMRawDeposit) to High(TKMRawDeposit) do
      for I := 0 to gGame.MapEditor.Deposits.Count[R] - 1 do
      //Ignore water areas with 0 fish in them
      if gGame.MapEditor.Deposits.Amount[R, I] > 0 then
      begin
        locF := gTerrain.FlatToHeight(gGame.MapEditor.Deposits.Location[R, I]);
        screenLoc := fViewport.MapToScreen(locF);

        //At extreme zoom coords may become out of range of SmallInt used in controls painting
        if KMInRect(screenLoc, fViewport.ViewRect) then
          TKMRenderUI.WriteTextInShape(IntToStr(gGame.MapEditor.Deposits.Amount[R, I]), screenLoc.X, screenLoc.Y, DEPOSIT_COLORS[R], $FFFFFFFF);
      end;
  end;

  if melDefences in gGame.MapEditor.VisibleLayers then
    fPaintDefences := True;

  inherited;
end;


end.


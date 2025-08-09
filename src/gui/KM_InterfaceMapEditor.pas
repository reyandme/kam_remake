unit KM_InterfaceMapEditor;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, StrUtils, SysUtils,
  Controls,
  KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsMinimapView, KM_ControlsForm,
  KM_Defaults, KM_Pics, KM_Points,
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
  KM_MapEdTypes,
  KM_CommonTypes;

type
  TKMMapEdInterface = class(TKMUserInterfaceGame)
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

    fMapIsMultiplayer: Boolean;

    fInfoHideTime: Cardinal;

    procedure Layers_UpdateVisibility;
    procedure Marker_Done(Sender: TObject);
    procedure Minimap_OnUpdate(Sender: TObject; const aLocX, aLocY: Integer);
    procedure PageChanged(Sender: TObject);
    procedure Player_ActiveClick(Sender: TObject);
    procedure Message_Click(Sender: TObject);
    procedure ChangeOwner_Click(Sender: TObject);
    procedure UniversalEraser_Click(Sender: TObject);

    procedure UpdateMapEdCursor(X, Y: Integer; Shift: TShiftState);
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
    procedure Update_Label_Info;
    procedure MapTypeChanged(aIsMultiplayer: Boolean);

    procedure SetHousePosition(aHouse: TKMHouse; aPos: TKMPoint);

    procedure UnRedo_Click(Sender: TObject);
    procedure History_Click(Sender: TObject);
    procedure History_JumpTo(Sender: TObject);
    procedure History_ListChange(Sender: TObject);
    procedure History_MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
    procedure History_Close;
    procedure History_UpdatePos;

    function GetGuiTerrain: TKMMapEdTerrain;

    procedure MapSaveStarted;
    procedure MapSaveEnded;

    procedure ManageExtrasKeys(Key: Word; Shift: TShiftState);
  protected
    MinimapView: TKMMinimapView;
    Label_Coordinates: TKMLabel;
    Label_Info: TKMLabel;
    Button_PlayerSelect: array [0..MAX_HANDS-1] of TKMFlatButtonShape; //Animals are common for all

    Panel_MinimapButtons: TKMPanel;
      Button_History: TKMButtonFlat;
      Button_Undo, Button_Redo: TKMButtonFlat;
      Button_ChangeOwner: TKMButtonFlat;
      Button_UniversalEraser: TKMButtonFlat;

    Panel_Common: TKMPanel;
      Button_Main: array [1..5] of TKMButton; //5 buttons
      Label_MissionName: TKMLabel;
      Image_Extra: TKMImage;
      Image_Message: TKMImage;

    Form_History: TKMForm;
      ListBox_History: TKMListBox;
      Button_History_Undo,
      Button_History_Redo,
      Button_History_JumpTo: TKMButton;

    function GetToolbarWidth: Integer; override;

    procedure HistoryUpdateUI;
    procedure MapEdOptionsWereChanged;
    procedure OptionsChanged; override;
  public
    constructor Create(aRender: TKMRender; var aMapSaveStarted, aMapSaveEnded: TKMEvent);
    destructor Destroy; override;

    procedure ShowMessage(const aText: string);
    procedure ExportPages(const aPath: string); override;

    property GuiTerrain: TKMMapEdTerrain read GetGuiTerrain;
    property GuiMission: TKMMapEdMission read fGuiMission;
    property GuiMenu: TKMMapEdMenu read fGuiMenu;

    procedure KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean); override;
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
    procedure UpdateHotkeys; override;
    procedure UpdateState(aGlobalTickCount: Cardinal); override;
    procedure UpdateStateImmediately;
    procedure UpdateStateIdle(aFrameTime: Cardinal); override;
    procedure Paint; override;
  end;


implementation
uses
  KM_System,
  KM_HandsCollection, KM_Hand, KM_HandTypes, KM_HandEntity,
  KM_ResTexts, KM_Game, KM_GameParams, KM_Cursor,
  KM_Resource, KM_ResHouses, KM_TerrainDeposits, KM_ResKeys, KM_GameApp,
  KM_AIDefensePos, KM_RenderUI, KM_ResFonts, KM_CommonClasses, KM_UnitWarrior,
  KM_Maps,
  KM_Utils, KM_CommonUtils,
  KM_UnitGroupTypes,
  KM_ResTypes;

const
  INFO_SHOW_TIME = 3000; // in ms


{ TKMMapEdInterface }
constructor TKMMapEdInterface.Create(aRender: TKMRender; var aMapSaveStarted, aMapSaveEnded: TKMEvent);
const
  TB_PAD_MAP_ED = 0;
  TB_PAD_MBTN_LEFT = 9;
  HND_COL = 9;
  HND_S = 21;
  HND_P = 2;
  TOP_SIDE_BTN = 10;
  MMAP_BTN_GAP = 10;
  MMAP_BTNS_CNT = 4;
  MMAP_BTN_W = 28;
  MMAP_BTN_H = 28;
  MMAP_BTNS_GAP = 3;
var
  I: Integer;
  S: TKMShape;
begin
  inherited Create(aRender);

  fMinimap.PaintVirtualGroups := True;

  aMapSaveStarted := MapSaveStarted;
  aMapSaveEnded := MapSaveEnded;

  ResetDragObject;
  //                                   250
  // Left panel background
  TKMImage.Create(Panel_Main, 0, -200, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, [anLeft, anTop, anRight]);
  TKMImage.Create(Panel_Main, 0,  200, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, [anLeft, anTop, anRight]);
  TKMImage.Create(Panel_Main, 0,  600, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, [anLeft, anTop, anRight]);
  // For 1600x1200 this is needed
  TKMImage.Create(Panel_Main, 0, 1000, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, [anLeft, anTop, anRight]);
  TKMImage.Create(Panel_Main, 0, 1400, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, [anLeft, anTop, anRight]);
  // For 4K displays
  TKMImage.Create(Panel_Main, 0, 1800, MAPED_TOOLBAR_WIDTH, 400, 404, rxGui, [anLeft, anTop, anRight]);

  // Minimap place is drawn last
  TKMImage.Create(Panel_Main, 0,    0,                 220, 200, 679, rxGui, [anLeft, anTop, anRight]);

  MinimapView := TKMMinimapView.Create(fMinimap, Panel_Main, 10, 10, TB_MAP_ED_WIDTH - 40, 176);
  MinimapView.OnMinimapChange := Minimap_OnUpdate;

  Label_MissionName := TKMLabel.Create(Panel_Main, MAPED_TOOLBAR_WIDTH + 4, 10, 500, 10, NO_TEXT, fntGrey, taLeft);
  Label_Coordinates := TKMLabel.Create(Panel_Main, MAPED_TOOLBAR_WIDTH + 4, 30, 'X: Y:', fntGrey, taLeft);
  Label_Info := TKMLabel.Create(Panel_Main, MAPED_TOOLBAR_WIDTH + 4, 50, '', fntOutline, taLeft);

//  TKMLabel.Create(Panel_Main, TB_PAD, 190, TB_WIDTH, 0, gResTexts[TX_MAPED_PLAYERS], fntOutline, taLeft);
  for I := 0 to MAX_HANDS - 1 do
  begin
    Button_PlayerSelect[I]         := TKMFlatButtonShape.Create(Panel_Main, TB_PAD + (I mod HND_COL)*(HND_S+HND_P),
                                                                190 + (HND_S+HND_P)*(I div HND_COL),
                                                                HND_S, HND_S, IntToStr(I+1), fntGrey, $FF0000FF);
    Button_PlayerSelect[I].Tag     := I;
    Button_PlayerSelect[I].OnClick := Player_ActiveClick;
  end;
  Button_PlayerSelect[0].Down := True; //First player selected by default


  Panel_MinimapButtons := TKMPanel.Create(Panel_Main, MinimapView.Right + MMAP_BTN_GAP, TOP_SIDE_BTN,
                                          MMAP_BTN_W, MMAP_BTNS_CNT * MMAP_BTN_H + MMAP_BTNS_GAP * (MMAP_BTNS_CNT - 1));

  Button_History := TKMButtonFlat.Create(Panel_MinimapButtons, 0, 0, MMAP_BTN_W, MMAP_BTN_H, 677);
//  Button_History.BackAlpha := 1;
  Button_History.TexOffsetX := -1;
  Button_History.Down := False; // History is hidden by default
  Button_History.OnClick := History_Click;

  Button_Undo := TKMButtonFlat.Create(Panel_MinimapButtons, 0, MMAP_BTN_H + MMAP_BTNS_GAP, MMAP_BTN_W div 2, MMAP_BTN_H, 0);
//  Button_Undo.BackAlpha := 1;
  Button_Undo.Caption := '<';
  Button_Undo.CapOffsetY := -10;
  Button_Undo.CapColor := icGreen;
  Button_Undo.Hint := gResTexts[TX_MAPED_UNDO_HINT]+ ' (''Ctrl + Z'')';
  Button_Undo.OnClick := UnRedo_Click;

  Button_Redo := TKMButtonFlat.Create(Panel_MinimapButtons, Button_Undo.Right + 1, MMAP_BTN_H + MMAP_BTNS_GAP, MMAP_BTN_W div 2, MMAP_BTN_H, 0);
//  Button_Redo.BackAlpha := 1;
  Button_Redo.Caption := '>';
  Button_Redo.CapOffsetY := -10;
  Button_Redo.CapColor := icGreen;
  Button_Redo.Hint := gResTexts[TX_MAPED_REDO_HINT] + ' (''Ctrl + Y'' or ''Ctrl + Shift + Z'')';
  Button_Redo.OnClick := UnRedo_Click;

  Button_ChangeOwner := TKMButtonFlat.Create(Panel_MinimapButtons, 0, 2*(MMAP_BTN_H + MMAP_BTNS_GAP), MMAP_BTN_W - 1, MMAP_BTN_H, 662);
//  Button_ChangeOwner.BackAlpha := 1;
  Button_ChangeOwner.Down := False;
  Button_ChangeOwner.OnClick := ChangeOwner_Click;

  Button_UniversalEraser := TKMButtonFlat.Create(Panel_MinimapButtons, 0, 3*(MMAP_BTN_H + MMAP_BTNS_GAP), MMAP_BTN_W - 1, MMAP_BTN_H, 340);
//  Button_UniversalEraser.BackAlpha := 1;
  Button_UniversalEraser.Down := False;
  Button_UniversalEraser.OnClick := UniversalEraser_Click;

  Image_Extra := TKMImage.Create(Panel_Main, MAPED_TOOLBAR_WIDTH, Panel_Main.Height - 48, 30, 48, 494);
  Image_Extra.Anchors := [anLeft, anBottom];
  Image_Extra.HighlightOnMouseOver := True;
  Image_Extra.OnClick := Message_Click;

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
  
  for I := 1 to 5 do
    Button_Main[I].OnClick := Main_ButtonClick;

  //Terrain editing pages
  fGuiTerrain := TKMMapEdTerrain.Create(Panel_Common, PageChanged, HidePages);
  fGuiTown := TKMMapEdTown.Create(Panel_Common, PageChanged);
  fGuiPlayer := TKMMapEdPlayer.Create(Panel_Common, PageChanged);
  fGuiMission := TKMMapEdMission.Create(Panel_Common, PageChanged);
  fGuiMenu := TKMMapEdMenu.Create(Panel_Common, PageChanged, MapTypeChanged, UpdateHotkeys);
  fGuiMenu.GuiMenuSettings.GUICommonOptions.OnOptionsChange := MapEdOptionsWereChanged;

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

  // Form will be created last to be on top
  Form_History := TKMForm.Create(Panel_Main, 270, 300, gResTexts[TX_MAPED_HISTORY_TITLE], fbScroll, True, False, False);
  Form_History.Left := Panel_Main.Width - Form_History.Width;
  Form_History.Top  := 0;
  Form_History.DragEnabled := True;
  Form_History.Hide; // History is hidden by default
  Form_History.OnMouseWheel := History_MouseWheel;
  Form_History.OnClose := History_Close;
  Form_History.Anchors := [anTop, anRight];

    ListBox_History := TKMListBox.Create(Form_History.ItemsPanel, 10, 10, Form_History.ItemsPanel.Width - 20, Form_History.ItemsPanel.Height - 50, fntMetal, bsGame);
    ListBox_History.AutoHideScrollBar := True;
    ListBox_History.ShowHintWhenShort := True;
    ListBox_History.HintBackColor := TKMColor4f.New(87, 72, 37);
    ListBox_History.OnChange := History_ListChange;
    ListBox_History.OnDoubleClick := History_JumpTo;

    Button_History_JumpTo := TKMButton.Create(Form_History.ItemsPanel, 10, ListBox_History.Bottom + 5,
                                                             ListBox_History.Width, 20, gResTexts[TX_MAPED_HISTORY_JUMP_TO], bsGame);
    Button_History_JumpTo.OnClick := History_JumpTo;
    Button_History_JumpTo.Hint := gResTexts[TX_MAPED_HISTORY_JUMP_TO_HINT];

    Button_History_Undo := TKMButton.Create(Form_History.ItemsPanel, 10, Form_History.ItemsPanel.Height - 10, (ListBox_History.Width div 2) - 7, 20, '<< ' + gResTexts[TX_MAPED_UNDO], bsGame);
    Button_History_Undo.OnClick := UnRedo_Click;
    Button_History_Undo.Hint := gResTexts[TX_MAPED_UNDO_HINT]+ ' (''Ctrl + Z'')';

    Button_History_Redo := TKMButton.Create(Form_History.ItemsPanel, Form_History.ItemsPanel.Width - 10 - Button_History_Undo.Width,
                                                           Button_History_Undo.Top, Button_History_Undo.Width, 20, gResTexts[TX_MAPED_REDO] + ' >>', bsGame);
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

  InitDebugControls;

  HidePages;
  AfterCreateComplete;
end;


destructor TKMMapEdInterface.Destroy;
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
  fGuiMarkerDefence.Free;
  fGuiMarkerReveal.Free;
  fGuiMenu.Free;
  fGuiMessage.Free;
  fGuiUnit.Free;

  SHOW_TERRAIN_WIRES := False; //Don't show it in-game if they left it on in MapEd
  SHOW_TERRAIN_PASS := 0; //Don't show it in-game if they left it on in MapEd
  inherited;
end;


procedure TKMMapEdInterface.DebugControlsUpdated(aSenderTag: Integer);
begin
  inherited;

  fGuiExtras.Refresh;
end;


procedure TKMMapEdInterface.Main_ButtonClick(Sender: TObject);
begin
  //Reset cursor mode
  gCursor.Mode := cmNone;
  gCursor.Tag1 := 0;

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


procedure TKMMapEdInterface.HidePages;
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


procedure TKMMapEdInterface.History_Click(Sender: TObject);
begin
  Form_History.Visible := not Form_History.Visible;

  Button_History.Down := Form_History.Visible;
end;


procedure TKMMapEdInterface.History_Close;
begin
  Button_History.Down := Form_History.Visible;
end;


procedure TKMMapEdInterface.History_JumpTo(Sender: TObject);
begin
  if ListBox_History.Selected then
    gGame.MapEditor.History.JumpTo(ListBox_History.ItemIndex);
end;


procedure TKMMapEdInterface.UpdatePlayerSelectButtons;
const
  CAP_COLOR: array [Boolean] of Cardinal = ($80808080, $FFFFFFFF);
var
  I: Integer;
begin
  for I := 0 to MAX_HANDS - 1 do
    Button_PlayerSelect[I].FontColor := CAP_COLOR[gHands[I].HasAssets];
end;


//Should update any items changed by game (resource counts, hp, etc..)
procedure TKMMapEdInterface.UpdateState(aGlobalTickCount: Cardinal);
begin
  inherited;
  //Update minimap every 500ms
  if aGlobalTickCount mod 5 = 0 then
    fMinimap.Update;

  //Show players without assets in grey
  if aGlobalTickCount mod 5 = 0 then
    UpdatePlayerSelectButtons;

  UpdateStateInternal;
end;


procedure TKMMapEdInterface.UpdateStateInternal;
begin
  fGuiTerrain.UpdateState;
  fGuiHouse.UpdateState;
  fGuiMenu.UpdateState;
  fGuiTown.UpdateState;
  fGuiPlayer.UpdateState;

  Button_ChangeOwner.Down := gCursor.Mode = cmPaintBucket;
  Button_UniversalEraser.Down := gCursor.Mode = cmUniversalEraser;
end;

  
procedure TKMMapEdInterface.UpdateStateImmediately;
begin
  fMinimap.Update;
  UpdatePlayerSelectButtons;
  UpdateStateInternal;
end;


procedure TKMMapEdInterface.UpdateStateIdle(aFrameTime: Cardinal);
begin
  //Check to see if we need to scroll
  fViewport.UpdateStateIdle(aFrameTime, not fDragScrolling, False);
  fGuiTown.UpdateStateIdle;
  Update_Label_Coordinates;
  Update_Label_Info;
end;


//Update UI state according to game state
procedure TKMMapEdInterface.SyncUI(aMoveViewport: Boolean = True);
var
  I: Integer;
begin
  inherited;

  if aMoveViewport then
    fViewport.Position := KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2);

  MinimapView.SetViewport(fViewport);

  //Set player colors
  for I := 0 to MAX_HANDS - 1 do
    Button_PlayerSelect[I].ShapeColor := gHands[I].FlagColor;

  Player_UpdatePages;

  UpdatePlayerSelectButtons;

  Label_MissionName.Caption := gGameParams.Name;
end;


//Active page has changed, that affects layers visibility
procedure TKMMapEdInterface.PageChanged(Sender: TObject);
begin
  //Child panels visibility changed, that affects visible layers
  Layers_UpdateVisibility;
end;


//Set which layers are visible and which are not
//Layer is always visible if corresponding editing page is active (to see what gets placed)
procedure TKMMapEdInterface.Layers_UpdateVisibility;
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

  // Update Lighting if FlatTerrain layer was added or removed
  if flatTerWasEnabled xor (mlFlatTerrain in gGameParams.VisibleLayers) then
    gTerrain.UpdateLighting;
end;


procedure TKMMapEdInterface.Player_ActiveClick(Sender: TObject);
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


procedure TKMMapEdInterface.SetPaintBucketMode(aSetPaintBucketMode: Boolean);
begin
  Button_ChangeOwner.Down := aSetPaintBucketMode;
  if aSetPaintBucketMode then
    gCursor.Mode := cmPaintBucket
  else
    gCursor.Mode := cmNone;
end;


procedure TKMMapEdInterface.SetUniversalEraserMode(aSetUniversalEraserMode: Boolean);
begin
  Button_UniversalEraser.Down := aSetUniversalEraserMode;
  if aSetUniversalEraserMode then
  begin
    gCursor.Mode := cmUniversalEraser;
    // Clear selected object, as it could be deleted
    gMySpectator.Selected := nil;
    HidePages;
  end else
    gCursor.Mode := cmNone;
end;


procedure TKMMapEdInterface.ChangeOwner_Click(Sender: TObject);
begin
  SetPaintBucketMode(not Button_ChangeOwner.Down);
end;


procedure TKMMapEdInterface.UniversalEraser_Click(Sender: TObject);
begin
  SetUniversalEraserMode(not Button_UniversalEraser.Down);
end;


procedure TKMMapEdInterface.UnRedo_Click(Sender: TObject);
begin
  if (Sender = Button_Undo)
    or (Sender = Button_History_Undo) then
    gGame.MapEditor.History.Undo;

  if (Sender = Button_Redo)
    or (Sender = Button_History_Redo) then
    gGame.MapEditor.History.Redo;
end;


//Active player can be set either from buttons clicked or by selecting a unit or a house
procedure TKMMapEdInterface.Player_SetActive(aIndex: TKMHandID);
var
  I: Integer;
begin
  gMySpectator.HandID := aIndex;
  fGuiTown.GuiDefence.UpdatePlayer(aIndex);

  for I := 0 to MAX_HANDS - 1 do
    Button_PlayerSelect[I].Down := (I = gMySpectator.HandID);

  Player_UpdatePages;
end;


procedure TKMMapEdInterface.ShowMarkerInfo(aMarker: TKMMapEdMarker);
begin
  HidePages; // HidePages first. That will also reset old marker;

  gGame.MapEditor.ActiveMarker := aMarker;
  Assert((aMarker.MarkerType <> mmtNone) and (aMarker.Owner <> HAND_NONE) and (aMarker.Index <> -1));

  Player_SetActive(aMarker.Owner);

  case aMarker.MarkerType of
    mmtDefence:    fGuiMarkerDefence.Show(aMarker.Owner, aMarker.Index);
    mmtRevealFOW:  fGuiMarkerReveal.Show(aMarker.Owner, aMarker.Index);
  end;

  Layers_UpdateVisibility;
end;


procedure TKMMapEdInterface.ShowMessage(const aText: string);
begin
  fGuiMessage.Show(aText);
  Image_Message.Show; //Hidden by default, only visible when a message is shown
end;


//When marker page is done we want to return to markers control page
procedure TKMMapEdInterface.Marker_Done(Sender: TObject);
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
procedure TKMMapEdInterface.Cancel_Clicked(aIsRMB: Boolean; var aHandled: Boolean);
begin
  if aHandled then Exit;
  //We should drop the tool but don't close opened tab. This allows eg:
  //Place a warrior, right click so you are not placing more warriors,
  //select the placed warrior.
  if aIsRMB then
  begin
    // When global tools are used, just cancel the tool, even if some page is open
    if not (gCursor.Mode in [cmPaintBucket, cmUniversalEraser]) then
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
    if gCursor.Mode = cmTiles then Exit;

    // We change defense pos and unit direction on RMB
    if (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_DEFENCE) then Exit;
    if (gCursor.Mode = cmUnits) and (TKMUnitType(gCursor.Tag1) in UNITS_WARRIORS) then Exit;

  end;

  fGuiTerrain.Cancel_Clicked(aHandled);

  // Reset cursor
  // Call for DoResetCursorMode first to do cancel the cursor even if we already handled event earlier
  aHandled := DoResetCursorMode or aHandled;
  //Reset drag object fields
  ResetDragObject;
  gSystem.Cursor := kmcDefault;

  gGame.MapEditor.Reset;
end;


procedure TKMMapEdInterface.Player_UpdatePages;
begin
  //Update players info on pages
  //Colors are updated as well
  //Update regardless of whether the panels are visible, since the user could open then at any time
  fGuiTown.ChangePlayer;
  fGuiPlayer.ChangePlayer;
end;


procedure TKMMapEdInterface.Message_Click(Sender: TObject);
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


// Update viewport position when user interacts with minimap
procedure TKMMapEdInterface.Minimap_OnUpdate(Sender: TObject; const aLocX, aLocY: Integer);
begin
  fViewport.Position := KMPointF(aLocX, aLocY);
end;


procedure TKMMapEdInterface.ExportPages(const aPath: string);
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
    gGameApp.PrintScreen(path + 'Terrain' + IntToStr(Ord(I)) + '.jpeg');
  end;

  for K := Low(TKMTownTab) to High(TKMTownTab) do
  begin
    HidePages;
    fGuiTown.Show(K);
    gGameApp.PrintScreen(path + 'Town' + IntToStr(Ord(K)) + '.jpeg');
  end;

  for L := Low(TKMPlayerTab) to High(TKMPlayerTab) do
  begin
    HidePages;
    fGuiPlayer.Show(L);
    gGameApp.PrintScreen(path + 'Player' + IntToStr(Ord(L)) + '.jpeg');
  end;

  for M := Low(TKMMissionTab) to High(TKMMissionTab) do
  begin
    HidePages;
    fGuiMission.Show(M);
    gGameApp.PrintScreen(path + 'Mission' + IntToStr(Ord(M)) + '.jpeg');
  end;

  HidePages;
  fGuiHouse.Show(nil);
  gGameApp.PrintScreen(path + 'House.jpeg');

  HidePages;
  fGuiUnit.Show(TKMUnit(nil));
  gGameApp.PrintScreen(path + 'Unit.jpeg');
end;


function TKMMapEdInterface.GetGuiTerrain: TKMMapEdTerrain;
begin
  if Self = nil then Exit(nil);

  Result := fGuiTerrain;
end;


function TKMMapEdInterface.GetToolbarWidth: Integer;
begin
  // Don't render toolbar when SAVE_MAP_TO_FBO is set
  if SAVE_MAP_TO_FBO_RENDER then Exit(0);

  Result := MAPED_TOOLBAR_WIDTH;
end;


// This event happens every ~33ms if the Key is Down and holded
procedure TKMMapEdInterface.KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
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
  fGuiTerrain.KeyDown(Key, Shift, aIsFirst, keyHandled); // Terrain first (because of Objects and Tiles popup windows)
  fGuiHouse.KeyDown(Key, Shift, keyHandled);
  fGuiUnit.KeyDown(Key, Shift, keyHandled);
  fGuiTown.KeyDown(Key, Shift, keyHandled);
  fGuiMission.KeyDown(Key, Shift, keyHandled);

  if keyHandled then Exit;

  inherited KeyDown(Key, Shift, aIsFirst, keyHandled);
  if keyHandled then Exit;

  gCursor.SState := Shift; // Update Shift state on KeyDown

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
  if not keyPassedToModal and (Key = gResKeys[kfMapedExtra]) then
    Message_Click(Image_Extra);

  // If modals are closed or they did not handle key
  if not keyPassedToModal and (Key = gResKeys[kfCloseMenu]) then
  begin
    if fGuiMenu.GuiMenuSettings.Visible then
    begin
      fGuiMenu.GuiMenuSettings.Hide;
      Exit;
    end;

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


procedure TKMMapEdInterface.ShowSubMenu(aIndex: Byte);
begin
  fGuiTerrain.ShowSubMenu(aIndex);
  fGuiTown.ShowSubMenu(aIndex);
  fGuiPlayer.ShowSubMenu(aIndex);
  fGuiMission.ShowSubMenu(aIndex);
  fGuiMenu.ShowSubMenu(aIndex);
end;


procedure TKMMapEdInterface.ExecuteSubMenuAction(aIndex: Byte; var aHandled: Boolean);
begin
  fGuiTerrain.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiTown.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiPlayer.ExecuteSubMenuAction(aIndex, aHandled);
  fGuiMission.ExecuteSubMenuAction(aIndex, aHandled);
end;


procedure TKMMapEdInterface.MapSaveStarted;
begin
  gSystem.Cursor := kmcAnimatedDirSelector;
  fInfoHideTime := High(Cardinal);
  Label_Info.Visible := True;
  Label_Info.Caption := gResTexts[TX_MAPED_MAP_SAVING];

  gGameApp.Render; // Update 'Map saving' label
end;


procedure TKMMapEdInterface.MapSaveEnded;
begin
  fInfoHideTime := TimeGet + INFO_SHOW_TIME;
  Label_Info.Caption := gResTexts[TX_MAPED_MAP_SAVED];
  gSystem.Cursor := kmcDefault;
end;


procedure TKMMapEdInterface.ManageExtrasKeys(Key: Word; Shift: TShiftState);
begin
  if not Key in [gResKeys[kfMapedFlatTerrain], gResKeys[kfMapedTilesGrid]] then Exit;

  // Flat terrain
  if Key = gResKeys[kfMapedFlatTerrain] then
  begin
    fGuiExtras.CheckBox_ShowFlatTerrain.Checked := not fGuiExtras.CheckBox_ShowFlatTerrain.Checked;
    Layers_UpdateVisibility;
  end;

  // Tiles grid
  if Key = gResKeys[kfMapedTilesGrid] then
  begin
    fGuiExtras.CheckBox_ShowFlatTerrain.Checked := not fGuiExtras.CheckBox_ShowFlatTerrain.Checked;
    SHOW_TERRAIN_TILES_GRID := not SHOW_TERRAIN_TILES_GRID;
  end;

  //Call event handlers after we updated visible layers
  if Assigned(gGameApp.OnOptionsChange) then
    gGameApp.OnOptionsChange;

  fGuiExtras.Refresh;
end;


procedure TKMMapEdInterface.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
var
  I: Integer;
  keyHandled: Boolean;
begin
  if fMyControls.KeyUp(Key, Shift) then Exit; //Handled by Controls

  keyHandled := False;
  inherited KeyUp(Key, Shift, keyHandled);

  // Update game options in case we used sounds hotkeys
  if keyHandled then
  begin
    fGuiMenu.GuiMenuSettings.GUICommonOptions.Refresh;
    Exit;
  end;

  aHandled := True; // assume we handle all keys here

  keyHandled := False;

  if keyHandled then Exit;

  if (Key = gResKeys[kfMapedSaveMap]) and (ssCtrl in Shift) then
    gGame.SaveMapEditor(TKMapsCollection.FullPath(Trim(gGameParams.Name), '.dat', fMapIsMultiplayer));

  //F1-F5 menu shortcuts
  if Key = gResKeys[kfMapedTerrain]   then
    Button_Main[1].Click;
  if Key = gResKeys[kfMapedVillage]   then
    Button_Main[2].Click;
  if Key = gResKeys[kfMapedVisual]    then
    Button_Main[3].Click;
  if Key = gResKeys[kfMapedGlobal]    then
    Button_Main[4].Click;
  if Key = gResKeys[kfMapedMainMenu] then
    Button_Main[5].Click;

  //1-6 submenu shortcuts
  for I := Low(MAPED_SUBMENU_HOTKEYS) to High(MAPED_SUBMENU_HOTKEYS) do
    if Key = gResKeys[MAPED_SUBMENU_HOTKEYS[I]] then
      ShowSubMenu(I);

  //q-w-e-r-t-y-u submenu actions shortcuts
  for I := Low(MAPED_SUBMENU_ACTIONS_HOTKEYS) to High(MAPED_SUBMENU_ACTIONS_HOTKEYS) do
    if Key = gResKeys[MAPED_SUBMENU_ACTIONS_HOTKEYS[I]] then
    begin
      keyHandled := False;
      ExecuteSubMenuAction(I, keyHandled);
    end;

  //Universal erasor
  if Key = gResKeys[kfMapedUnivErasor] then
    UniversalEraser_Click(Button_UniversalEraser);

  //Change owner
  if Key = gResKeys[kfMapedPaintBucket] then
    ChangeOwner_Click(Button_ChangeOwner);

  //History
  if Key = gResKeys[kfMapedHistory] then
    History_Click(Button_History);

  ManageExtrasKeys(Key, Shift);

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

  gCursor.SState := Shift; // Update Shift state on KeyUp
end;


procedure TKMMapEdInterface.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var
  obj: TObject;
  keyHandled: Boolean;
begin
  inherited;

  fMyControls.MouseDown(X,Y,Shift,Button);

  if fMyControls.CtrlOver <> nil then
    Exit;

  if (Button = mbLeft) and (gCursor.Mode = cmNone) then
  begin
    obj := gMySpectator.HitTestCursor(True);
    if obj <> nil then
    begin
      UpdateSelection;
      fDragObject := obj;
      if obj is TKMHouse then
        fDragHouseOffset := KMPointSubtract(TKMHouse(obj).Entrance, gCursor.Cell); //Save drag point adjustement to house position
      fDragObjectReady := True;
      fDragObjMousePosStart := KMPoint(X,Y);
    end;
  end;

  keyHandled := False;
  if Button = mbRight then
    Cancel_Clicked(True, keyHandled);

  //So terrain brushes start on mouse down not mouse move
  UpdateMapEdCursor(X, Y, Shift);

  if not keyHandled then
    gGame.MapEditor.MouseDown(Button);
end;


procedure TKMMapEdInterface.Update_Label_Coordinates;
begin
  Label_Coordinates.Caption := Format('X: %d, Y: %d, Z: %d', [gCursor.Cell.X, gCursor.Cell.Y,
                                                              gTerrain.Land^[EnsureRange(Round(gCursor.Float.Y + 1), 1, gTerrain.MapY),
                                                                             EnsureRange(Round(gCursor.Float.X + 1), 1, gTerrain.MapX)].Height]);
end;


procedure TKMMapEdInterface.Update_Label_Info;
const
  FADE_TIME_MAX = 1000;
var
  time: Cardinal;
  A: Byte;
begin
  time := TimeGet;
  if time > fInfoHideTime then
    Label_Info.Visible := False
  else
  begin
    // a bit of 'animation'
    A := Round(Min(fInfoHideTime - time, FADE_TIME_MAX) / FADE_TIME_MAX * 255);
    Label_Info.FontColor := ((A shl 24) or $FFFFFF);
  end;
end;


procedure TKMMapEdInterface.MapTypeChanged(aIsMultiplayer: Boolean);
begin
  SetLoadMode(aIsMultiplayer);
end;


procedure TKMMapEdInterface.MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean);
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
      gSystem.Cursor := kmcDrag;
      fDragingObject := True;
    end;
  end;

  fMyControls.MouseMove(X,Y,Shift);

  if fMyControls.CtrlOver <> nil then
  begin
    //kmcEdit and kmcDragUp are handled by Controls.MouseMove (it will reset them when required)
    if not fViewport.Scrolling and not (gSystem.Cursor in [kmcEdit,kmcDragUp]) then
      gSystem.Cursor := kmcDefault;
    gCursor.SState := []; //Don't do real-time elevate when the mouse is over controls, only terrain
    Exit;
  end
  else
    ResetHint; //Clear shown hint

  if (ssLeft in Shift) or (ssRight in Shift) then
    fMouseDownOnMap := True;

  UpdateMapEdCursor(X, Y, Shift);

  gGame.MapEditor.MouseMove;
end;


procedure TKMMapEdInterface.UpdateHotkeys;
begin
  inherited;

  Button_History.Hint := GetHintWHotkey(TX_MAPED_HISTORY_HINT, kfMapedHistory);
  Button_ChangeOwner.Hint := GetHintWHotkey(TX_MAPED_PAINT_BUCKET_CH_OWNER, kfMapedPaintBucket);
  Button_UniversalEraser.Hint := GetHintWHotkey(TX_MAPED_UNIVERSAL_ERASER, kfMapedUnivErasor);
  Image_Extra.Hint := GetHintWHotkey(TX_KEY_FUNC_MAPEDIT_EXTRA, kfMapedExtra);

  Button_Main[1].Hint := GetHintWHotkey(TX_MAPED_TERRAIN, kfMapedTerrain);
  Button_Main[2].Hint := GetHintWHotkey(TX_MAPED_VILLAGE, kfMapedVillage);
  Button_Main[3].Hint := GetHintWHotkey(TX_MAPED_SCRIPTS_VISUAL, kfMapedVisual);
  Button_Main[4].Hint := GetHintWHotkey(TX_MAPED_SCRIPTS_GLOBAL, kfMapedGlobal);
  Button_Main[5].Hint := GetHintWHotkey(TX_MAPED_MENU, kfMapedMainMenu);

  fGuiTerrain.UpdateHotkeys;
  fGuiTown.UpdateHotkeys;
  fGuiPlayer.UpdateHotkeys;
  fGuiMission.UpdateHotkeys;
  fGuiMenu.UpdateHotkeys;
end;


procedure TKMMapEdInterface.MapEdOptionsWereChanged;
begin
  fMinimap.Update;
end;


procedure TKMMapEdInterface.OptionsChanged;
begin
  fGuiMenu.GuiMenuSettings.GUICommonOptions.Refresh;
end;


procedure TKMMapEdInterface.UpdateMapEdCursor(X, Y: Integer; Shift: TShiftState);
var
  marker: TKMMapEdMarker;
begin
  UpdateGameCursor(X, Y, Shift);

  if gCursor.Mode = cmPaintBucket then
  begin
    gSystem.Cursor := kmcPaintBucket;
    Exit;
  end;

  if fDragingObject and (ssLeft in Shift) then
  begin
    //Cursor can be reset to default, when moved to menu panel while dragging, so set it to drag cursor again
    gSystem.Cursor := kmcDrag;
    MoveObjectToCursorCell(fDragObject);
  end else
  if gCursor.Mode = cmNone then
  begin
    marker := gGame.MapEditor.HitTest(gCursor.Cell.X, gCursor.Cell.Y);
    if marker.MarkerType <> mmtNone then
      gSystem.Cursor := kmcInfo
    else
    if gMySpectator.HitTestCursor(True) <> nil then
      gSystem.Cursor := kmcInfo
    else
    if not fViewport.Scrolling then
      gSystem.Cursor := kmcDefault;
  end;

  Update_Label_Coordinates;
end;


procedure TKMMapEdInterface.History_ListChange(Sender: TObject);
begin
  Button_History_JumpTo.Enabled := ListBox_History.Selected;
end;


procedure TKMMapEdInterface.History_MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  ListBox_History.MouseWheel(Sender, WheelSteps, aHandled);

  aHandled := True;
end;


procedure TKMMapEdInterface.History_UpdatePos;
begin
  Form_History.Left := EnsureRange(Form_History.Left, 0, Panel_Main.Width - Form_History.Width);
  Form_History.Top  := EnsureRange(Form_History.Top, 0, Panel_Main.Height - Form_History.Height);
end;


procedure TKMMapEdInterface.HistoryAddCheckpoint;
begin
  HistoryUpdateUI;
end;


procedure TKMMapEdInterface.HistoryUndoRedo;
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


procedure TKMMapEdInterface.HistoryUpdateUI;
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


function TKMMapEdInterface.DoResetCursorMode: Boolean;
begin
  Result := gCursor.Mode <> cmNone;
  gCursor.Mode := cmNone;
end;


//Start drag house move mode (with cursor mode cmHouse)
procedure TKMMapEdInterface.DragHouseModeStart(const aHouseNewPos, aHouseOldPos: TKMPoint);

  procedure SetCursorModeHouse(aHouseType: TKMHouseType);
  begin
    gCursor.Mode := cmHouses;
    gCursor.Tag1 := Byte(aHouseType);
    //Update cursor DragOffset to render house markups at proper positions
    gCursor.DragOffset := fDragHouseOffset;
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


procedure TKMMapEdInterface.SetHousePosition(aHouse: TKMHouse; aPos: TKMPoint);
var
  newPos: Boolean;
begin
  newPos := aHouse.Position <> aPos;

  aHouse.UpdatePosition(aPos);

  if newPos then
    gGame.MapEditor.History.MakeCheckpoint(caHouses, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_MOVE_SMTH],
                                                            [gRes.Houses[aHouse.HouseType].HouseName, aPos.ToString]));
end;


//Drag house move mode end (with cursor mode cmHouse)
procedure TKMMapEdInterface.DragHouseModeEnd;
begin
  if (fDragObject is TKMHouse) then
  begin
    SetHousePosition(TKMHouse(fDragObject), KMPointAdd(gCursor.Cell, fDragHouseOffset));
    DoResetCursorMode;
  end;
end;


function TKMMapEdInterface.IsDragHouseModeOn: Boolean;
begin
  Result := fDragingObject and (fDragObject is TKMHouse) and (gCursor.Mode = cmHouses);
end;


procedure TKMMapEdInterface.MoveObjectToCursorCell(aObjectToMove: TObject);
begin
  if aObjectToMove = nil then Exit;

  // House
  if aObjectToMove is TKMHouse then
  begin
    var H := TKMHouse(aObjectToMove);

    var houseOldPos := H.Position;
    var houseNewPos := KMPointAdd(gCursor.Cell, fDragHouseOffset);

    if not fDragingObject then
      SetHousePosition(H, houseNewPos) //handles Right click, when house is selected
    else
      if not IsDragHouseModeOn then
        DragHouseModeStart(houseNewPos, houseOldPos);
  end else
  // Group (as expected, right-clicking repositions the group)
  if aObjectToMove is TKMUnitGroup then
  begin
    var G := TKMUnitGroup(aObjectToMove);
    if G.SetGroupPosition(gCursor.Cell) then
      gGame.MapEditor.History.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_MOVE_SMTH], [gRes.Units[G.UnitType].GUIName, G.Position.ToString]));
  end else
  // Warrior (a bit unexpectedly, dragging group leader around drags warriror)
  if aObjectToMove is TKMUnitWarrior then
  begin
    var G := gHands.GetGroupByMember(TKMUnitWarrior(aObjectToMove));
    if G.SetGroupPosition(gCursor.Cell) then
      gGame.MapEditor.History.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_MOVE_SMTH], [gRes.Units[G.UnitType].GUIName, G.Position.ToString]));
  end else
  // Unit
  if aObjectToMove is TKMUnit then
  begin
    var U := TKMUnit(aObjectToMove);
    if U.SetUnitPosition(gCursor.Cell) then
      gGame.MapEditor.History.MakeCheckpoint(caUnits, Format(gResTexts[TX_MAPED_HISTORY_CHPOINT_MOVE_SMTH], [gRes.Units[U.UnitType].GUIName, U.Position.ToString]));
  end;
end;


procedure TKMMapEdInterface.UpdateSelection;
begin
  gMySpectator.UpdateSelect(True, True);

  if gMySpectator.Selected is TKMHouse then
  begin
    HidePages;
    Player_SetActive(TKMHouse(gMySpectator.Selected).Owner);
    fGuiHouse.Show(TKMHouse(gMySpectator.Selected));
  end;
  if gMySpectator.Selected is TKMUnit then
  begin
    HidePages;
    if not (gMySpectator.Selected is TKMUnitAnimal) then
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


procedure TKMMapEdInterface.ResetDragObject;
begin
  fDragObjectReady := False;
  fDragingObject := False;
  fDragHouseOffset := KMPOINT_ZERO;
  fDragObjMousePosStart := KMPOINT_ZERO;
  fDragObject := nil;

  if gSystem.Cursor = kmcDrag then
    gSystem.Cursor := kmcDefault;

  if gCursor.Mode = cmHouses then
    DoResetCursorMode;
end;


procedure TKMMapEdInterface.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
    mbLeft:   if gCursor.Mode = cmNone then
              begin
                //If there are some additional layers we first HitTest them
                //since they are rendered ontop of Houses/Objects
                marker := gGame.MapEditor.HitTest(gCursor.Cell.X, gCursor.Cell.Y);

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
                if gCursor.Mode = cmTiles then
                  gCursor.MapEdDir := (gCursor.MapEdDir + 1) mod 4; //Rotate tile direction

                //Check if we are in rally/cutting marker mode
                if (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_RALLY_POINT) then
                begin
                  gCursor.Mode := cmNone;
                  Exit;
                end;

                //Move the selected object to the cursor location
                if gMySpectator.Selected is TKMHouse then
                begin
                  if ssShift in Shift then
                  begin
                    if gMySpectator.Selected is TKMHouseWFlagPoint then
                      TKMHouseWFlagPoint(gMySpectator.Selected).FlagPoint := gCursor.Cell;
                  end
                  else
                    SetHousePosition(TKMHouse(gMySpectator.Selected), gCursor.Cell); //Can place is checked in SetPosition

                  Exit;
                end;

                if gMySpectator.Selected is TKMUnitGroup then
                begin
                  G := TKMUnitGroup(gMySpectator.Selected);
                  //Use Shift to set group order
                  if ssShift in gCursor.SState then
                  begin
                    U := gTerrain.UnitsHitTest(gCursor.Cell.X, gCursor.Cell.Y);
                    H := gHands.HousesHitTest(gCursor.Cell.X, gCursor.Cell.Y);
                    //If there's any enemy unit or house on specified tile - set attack target
                    if ((U <> nil) and (gHands[U.Owner].Alliances[G.Owner] = atEnemy))
                    or ((H <> nil) and (gHands[H.Owner].Alliances[G.Owner] = atEnemy)) then
                      G.MapEdOrder.Order := gioAttackPosition
                    //Else order group walk to specified location
                    else
                    if G.CanWalkTo(KMPoint(gCursor.Cell.X, gCursor.Cell.Y), 0) then
                      G.MapEdOrder.Order := gioSendGroup
                    else
                    //Can't take any orders: f.e. can't walk to unwalkable tile (water, mountain) or attack allied houses
                      G.MapEdOrder.Order := gioNoOrder;
                    //Save target coordinates
                    G.MapEdOrder.Pos.Loc.X := gCursor.Cell.X;
                    G.MapEdOrder.Pos.Loc.Y := gCursor.Cell.Y;
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
                  DP.Position := KMPointDir(gCursor.Cell, DP.Position.Dir);
                end;

                if fGuiMarkerReveal.Visible then
                  gGame.MapEditor.Revealers[fGuiMarkerReveal.Owner][fGuiMarkerReveal.Index] := gCursor.Cell;
              end;
  end;

  UpdateGameCursor(X, Y, Shift); //Updates the shift state

  gGame.MapEditor.MouseUp(Button, True);

  //Update the XY coordinates of the Center Screen button
  if (gCursor.Mode = cmMarkers) and (gCursor.Tag1 = MARKER_CENTERSCREEN) then
    fGuiPlayer.ChangePlayer; //Forces an update

  Exclude(Shift, ssRight);
  Exclude(Shift, ssLeft);
  UpdateGameCursor(X, Y, Shift); //Updates the shift state after
end;


procedure TKMMapEdInterface.MouseWheel(Shift: TShiftState; WheelSteps, X,Y: Integer; var aHandled: Boolean);
begin
  if fMyControls.CtrlOver <> nil then
  begin
    fMyControls.MouseWheel(X, Y, WheelSteps, aHandled);
    if not aHandled then
      inherited;
    Exit; // Don't change field stages when mouse not over map
  end;

  if aHandled then Exit;
  
  fGuiTerrain.MouseWheel(Shift, WheelSteps, X, Y, aHandled);
  if not aHandled then
    inherited;
end;


procedure TKMMapEdInterface.Resize(X,Y: Word);
begin
  inherited;

  fViewport.Resize(X, Y);
  fGuiTerrain.Resize;
  fGuiMenu.Resize;

  // Put Form_History back into window, if it goes out of it
  History_UpdatePos;
end;


procedure TKMMapEdInterface.SetLoadMode(aMultiplayer: Boolean);
begin
  fMapIsMultiplayer := aMultiplayer;
  fGuiMenu.SetLoadMode(aMultiplayer);
end;


//UI should paint only controls
procedure TKMMapEdInterface.Paint;
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


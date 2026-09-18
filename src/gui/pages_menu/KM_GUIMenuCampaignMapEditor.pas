unit KM_GUIMenuCampaignMapEditor;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls, SysUtils, Math, Generics.Collections,
  KM_Maps, KM_Points,
  KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsDrop, KM_ControlsForm, KM_ControlsSwitch, KM_Pics, KM_MapTypes, KM_ResTypes,
  KM_Campaigns, KM_CampaignClasses, KM_InterfaceDefaults, KM_InterfaceTypes, KM_GUICampaignMapView, KM_GUIFileDialog;

type
  TKMCampMapSnapshot = record
    Flag: TKMPointW;
    NodeCount: Byte;
    Nodes: TKMCampaignMapNodes;
    TextPos: TKMBriefingCorner;
  end;
  TKMCampMapSnapshotArray = array of TKMCampMapSnapshot;

  TKMMenuCampaignMapEditor = class (TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText;

    fCampaign: TKMCampaign;
    fIsDirty: Boolean;

    fScrollVisible: Boolean;
    fBackgroundDialog: TKMGUIFileDialog;
    fBackgroundDialogPath: string;

    fIsPreviewActive: Boolean;
    fIsPreviewAnimDone: Boolean;
    fIsPreviewAudioExpected: Boolean;
    fIsPreviewAudioStarted: Boolean;
    fPreviewStartTime: Cardinal;
    fAnimNodeIndex: Byte;

    fBriefingLocales: array of string;

    fUndoStack, fRedoStack: TList<TKMCampMapSnapshotArray>;
    fPendingDragSnapshot: TKMCampMapSnapshotArray;
    fDragOriginLeft, fDragOriginTop: Integer;
    fDragStartTime: Cardinal;
    fHasDragThresholdCrossed: Boolean;

    procedure CreateMap;
    procedure CreateScroll;
    procedure CreateBottomButtons;
    procedure CreateLanguageRow;
    procedure CreateMissionRow;
    procedure CreateTopRow;
    procedure CreateDialogs;
    function CreateDialog(aContentHeight: Integer): TKMForm;
    function CreateDialogButton(aDialog: TKMForm; aIndex: Integer; const aCaption: UnicodeString; aOnClick: TNotifyEvent): TKMButton;

    procedure BackClick(Sender: TObject);
    procedure ScrollToggle(Sender: TObject);

    procedure SelectMap(Sender: TObject);
    procedure SelectNode(Sender: TObject);
    procedure MoveMap(Sender: TObject);
    procedure MoveNode(Sender: TObject);
    procedure DragBeginCapture(Sender: TObject);
    function CheckDragThreshold(aControl: TKMControl): Boolean;
    procedure DragEndCommit(Sender: TObject);
    procedure NodeAddClick(Sender: TObject);
    procedure NodeRemoveClick(Sender: TObject);
    procedure BriefingPosChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure ConfirmExitClick(Sender: TObject);
    procedure UndoClick(Sender: TObject);
    procedure RedoClick(Sender: TObject);
    procedure KeyDown(Sender: TObject; Key: Word; Shift: TShiftState);
    procedure LaunchClick(Sender: TObject);
    procedure LoadBackgroundClick(Sender: TObject);
    procedure BackgroundFileSelected(const aFileName: string);
    procedure LanguageChange(Sender: TObject);
    procedure FillLanguages;
    function SelectedLocale: string;
    procedure StartPreview;
    procedure StopPreview;
    procedure UpdatePreviewButtonState;
    procedure AnimNodes(aTickCount: Cardinal);
    function IsPreviewAudioDone: Boolean;

    function CaptureSnapshot: TKMCampMapSnapshotArray;
    procedure ApplySnapshot(const aSnapshot: TKMCampMapSnapshotArray);
    function SnapshotsEqual(const aFirst, aSecond: TKMCampMapSnapshotArray): Boolean;
    procedure PushUndo(const aSnapshotBeforeChange: TKMCampMapSnapshotArray);
    procedure UpdateUndoRedoState;

    procedure UpdateMaps;
    procedure UpdateNodes;
    procedure UpdateState;
    procedure UpdateBriefingPreview;
  protected
    Panel_Campaign: TKMPanel;
      MapView: TKMCampaignMapView;

      Panel_CampScroll: TKMPanel;
        Image_Scroll, Image_ScrollClose: TKMImage;
        Label_CampaignTitle, Label_CampaignText: TKMLabel;
        DropBox_EditorDifficulty: TKMDropList;

      ListBox_Maps, ListBox_Nodes: TKMListBox;
      Button_NodeAdd, Button_NodeRemove: TKMButton;
      DropBox_BriefingPos: TKMDropList;

      Image_ScrollRestore: TKMImage;
      Button_CampaignBack, Button_CampaignSave, Button_CampaignLaunch: TKMButton;
      Button_Undo, Button_Redo: TKMButton;
      Button_LoadBackground: TKMButton;

      DropBox_EditorLanguage: TKMDropColumns;

      DropBox_QuickMission: TKMDropList;
      Panel_QuickNodeBlock: TKMPanel;
        Image_QuickNodePreview: TKMImage;
        Label_QuickNodeCount: TKMLabel;
        Button_QuickNodeAdd, Button_QuickNodeRemove: TKMButton;
      CheckBox_QuickBriefingLeft: TKMCheckBox;

      Form_ConfirmExit: TKMForm;
        Label_ConfirmExit: TKMLabel;
        Button_ConfirmExitSave, Button_ConfirmExitDiscard: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;

    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure Resize(X, Y: Word);
    procedure Show(aCampaignIdStr: UnicodeString);

    procedure RefreshCampaign;
    procedure UpdateStateTick(aGlobalTickCount: Cardinal);
  end;


implementation

uses
  Dialogs,
  KM_CommonTypes, KM_Defaults, KM_CommonUtils,
  KM_ResTexts, KM_ResFonts, KM_ResLocales, KM_ResSound, KM_RenderUI, KM_Sound, KM_Audio, KM_Music, KM_Video,
  KM_GameApp, KM_GUIMenuCampaign;

const
  DRAG_HOLD_THRESHOLD_MS = 150;
  AUDIO_START_TIMEOUT_MS = 5000;
  MAX_UNDO_STEPS = 50;

  ITEM_H = 20;
  ITEM_GAP = 10;
  SMALL_GAP = 4;
  BACKDROP_PAD = 5;

  TOP_MARGIN = 10;
  UNDO_BUTTON_W = 40;
  LOAD_BG_BUTTON_W = 150;

  BUTTON_W = 120;
  LAUNCH_BUTTON_W = 120;
  BUTTON_H = 30;
  BUTTON_MARGIN_X = 20;
  BUTTON_BOTTOM = 50;
  ITEM_BOTTOM = 45;

  MISSION_DROP_W = 132;
  MISSION_DROP_COUNT = 20;
  NODE_BLOCK_W = 92;
  NODE_BLOCK_H = 28;
  NODE_BLOCK_BOTTOM = 49;
  NODE_BLOCK_PAD = 4;
  NODE_HIT_SIZE = 16;
  NODE_PREVIEW_TOP = 8;
  NODE_COUNT_SHIFT = 2;
  NODE_BUTTON_W = 30;
  BRIEFING_CHECK_W = 100;
  BRIEFING_CHECK_SHIFT_Y = 2;
  MISSION_GROUP_W = MISSION_DROP_W + ITEM_GAP + NODE_BLOCK_W + ITEM_GAP + BRIEFING_CHECK_W;

  LANG_DROP_W = 190;
  LANG_DROP_LIST_W = 210;
  LANG_DROP_COUNT = 12;
  LANG_NAME_COLUMN_LEFT = 26;
  LANG_AUDIO_COLUMN_LEFT = 130;
  AUDIO_ICON_TEX = 585; // rxGui sprite of a language that has a recording of the briefing

  EDITOR_TEXT_H = 190;
  DIFFICULTY_DROP_TOP = 266;
  DIFFICULTY_GAP = 20;

  HOLDER_LIST_W = 200;
  HOLDER_NODES_W = 100;
  HOLDER_LIST_H = 172;
  HOLDER_BUTTON_W = 48;
  HOLDER_ITEM_H = 24;

  DIALOG_CONTENT_W = 380;
  DIALOG_TEXT_H = 40;
  DIALOG_LABEL_TOP = 26;
  DIALOG_BUTTON_W = 170;
  DIALOG_BUTTON_GAP = 20;
  DIALOG_BUTTONS_W = 2 * DIALOG_BUTTON_W + DIALOG_BUTTON_GAP;
  DIALOG_BUTTON_BOTTOM = 15;
  MODAL_BEVEL_POS = -2000;
  MODAL_BEVEL_SIZE = 5000;


{ TKMMenuCampaignMapEditor }


constructor TKMMenuCampaignMapEditor.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
begin
  inherited Create(gpCampaignMapEditor);

  fScrollVisible := True;
  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;
  OnKeyDown := KeyDown;

  fUndoStack := TList<TKMCampMapSnapshotArray>.Create;
  fRedoStack := TList<TKMCampMapSnapshotArray>.Create;

  Panel_Campaign := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Campaign.AnchorsStretch;

  CreateMap;
  CreateScroll;
  CreateBottomButtons;
  CreateLanguageRow;
  CreateMissionRow;
  CreateTopRow;
  CreateDialogs;

  UpdateUndoRedoState;
end;


destructor TKMMenuCampaignMapEditor.Destroy;
begin
  FreeAndNil(fBackgroundDialog);
  FreeAndNil(fUndoStack);
  FreeAndNil(fRedoStack);

  inherited;
end;


procedure TKMMenuCampaignMapEditor.CreateMap;
var
  I: Integer;
begin
  MapView := TKMCampaignMapView.Create(Panel_Campaign, 0, 0, Panel_Campaign.Width, Panel_Campaign.Height, cmScreen, NODE_HIT_SIZE, True);
  MapView.AnchorsStretch;

  for I := 0 to MAX_CAMP_MAPS - 1 do
  begin
    MapView.Flags[I].HighlightOnMouseOver := True;
    MapView.Flags[I].DragAndDrop := True;
    MapView.Flags[I].OnBeginDragAndDrop := DragBeginCapture;
    MapView.Flags[I].OnMoveDragAndDrop := MoveMap;
    MapView.Flags[I].OnEndDragAndDrop := DragEndCommit;
    MapView.Flags[I].OnClick := SelectMap;
    MapView.Flags[I].Tag := I;
  end;

  for I := 0 to MAX_CAMP_NODES - 1 do
  begin
    MapView.Nodes[I].HighlightOnMouseOver := True;
    MapView.Nodes[I].DragAndDrop := True;
    MapView.Nodes[I].OnBeginDragAndDrop := DragBeginCapture;
    MapView.Nodes[I].OnMoveDragAndDrop := MoveNode;
    MapView.Nodes[I].OnEndDragAndDrop := DragEndCommit;
    MapView.Nodes[I].OnClick := SelectNode;
    MapView.Nodes[I].Tag := I;
  end;
end;


procedure TKMMenuCampaignMapEditor.CreateScroll;
begin
  Panel_CampScroll := TKMPanel.Create(Panel_Campaign, 0, Panel_Campaign.Height - IMG_SCROLL_MAX_HEIGHT, CAMP_SCROLL_W, IMG_SCROLL_MAX_HEIGHT);
  Panel_CampScroll.Anchors := [anLeft, anBottom];

  Image_Scroll := TKMImage.Create(Panel_CampScroll, 0, 0, CAMP_SCROLL_W, IMG_SCROLL_MAX_HEIGHT, CAMP_SCROLL_BG_TEX, rxGui);
  Image_Scroll.ClipToBounds := True;
  Image_Scroll.AnchorsStretch;
  Image_Scroll.ImageAnchors := [anLeft, anRight, anTop];

  Image_ScrollClose := TKMImage.Create(Panel_CampScroll, CAMP_SCROLL_W - CAMP_SCROLL_CLOSE_RIGHT, CAMP_SCROLL_CLOSE_TOP,
                                       CAMP_SCROLL_CLOSE_SIZE, CAMP_SCROLL_CLOSE_SIZE, CAMP_SCROLL_CLOSE_TEX);
  Image_ScrollClose.Anchors := [anTop, anRight];
  Image_ScrollClose.OnClick := ScrollToggle;
  Image_ScrollClose.HighlightOnMouseOver := True;

  Label_CampaignTitle := TKMLabel.Create(Panel_CampScroll, CAMP_TEXT_LEFT, CAMP_TITLE_TOP, CAMP_TITLE_W, CAMP_TITLE_H, NO_TEXT, fntOutline, taCenter);

  Label_CampaignText := TKMLabel.Create(Panel_CampScroll, CAMP_TEXT_LEFT, CAMP_TEXT_TOP, CAMP_TEXT_W, EDITOR_TEXT_H, NO_TEXT, fntAntiqua, taLeft);
  Label_CampaignText.WordWrap := True;

  DropBox_EditorDifficulty := TKMDropList.Create(Panel_CampScroll, CAMP_TEXT_LEFT, DIFFICULTY_DROP_TOP, CAMP_TEXT_W, ITEM_H, fntMetal, '', bsMenu);
  DropBox_EditorDifficulty.Hide;

  ListBox_Maps := TKMListBox.Create(Panel_Campaign, 0, 0, HOLDER_LIST_W, HOLDER_LIST_H, fntMetal, bsMenu);
  ListBox_Maps.OnChange := SelectMap;
  ListBox_Maps.Hide;

  ListBox_Nodes := TKMListBox.Create(Panel_Campaign, 0, 0, HOLDER_NODES_W, HOLDER_LIST_H, fntMetal, bsMenu);
  ListBox_Nodes.OnChange := SelectNode;
  ListBox_Nodes.Hide;

  Button_NodeAdd := TKMButton.Create(Panel_Campaign, 0, 0, HOLDER_BUTTON_W, HOLDER_ITEM_H, '+', bsMenu);
  Button_NodeAdd.OnClick := NodeAddClick;
  Button_NodeAdd.Hide;

  Button_NodeRemove := TKMButton.Create(Panel_Campaign, 0, 0, HOLDER_BUTTON_W, HOLDER_ITEM_H, '-', bsMenu);
  Button_NodeRemove.OnClick := NodeRemoveClick;
  Button_NodeRemove.Hide;

  DropBox_BriefingPos := TKMDropList.Create(Panel_Campaign, 0, 0, HOLDER_LIST_W, HOLDER_ITEM_H, fntMetal, '', bsMenu);
  DropBox_BriefingPos.Add(gResTexts[TX_MAPED_BRIEFING_POS_LEFT]);
  DropBox_BriefingPos.Add(gResTexts[TX_MAPED_BRIEFING_POS_RIGHT]);
  DropBox_BriefingPos.OnChange := BriefingPosChange;
  DropBox_BriefingPos.Hide;

  Image_ScrollRestore := TKMImage.Create(Panel_Campaign, Panel_Campaign.Width - CAMP_RESTORE_MARGIN_RIGHT - CAMP_RESTORE_W,
                                         Panel_Campaign.Height - CAMP_RESTORE_MARGIN_BOTTOM, CAMP_RESTORE_W, CAMP_RESTORE_H, CAMP_RESTORE_TEX);
  Image_ScrollRestore.Anchors := [anBottom, anRight];
  Image_ScrollRestore.OnClick := ScrollToggle;
  Image_ScrollRestore.HighlightOnMouseOver := True;
  Image_ScrollRestore.Hide;
end;


procedure TKMMenuCampaignMapEditor.CreateBottomButtons;
begin
  Button_CampaignBack := TKMButton.Create(Panel_Campaign, BUTTON_MARGIN_X, Panel_Campaign.Height - BUTTON_BOTTOM, BUTTON_W, BUTTON_H,
                                          gResTexts[TX_MAPED_CLOSE], bsMenu);
  Button_CampaignBack.Anchors := [anLeft, anBottom];
  Button_CampaignBack.OnClick := BackClick;

  Button_CampaignSave := TKMButton.Create(Panel_Campaign, Button_CampaignBack.Right + ITEM_GAP, Panel_Campaign.Height - BUTTON_BOTTOM, BUTTON_W, BUTTON_H,
                                          gResTexts[TX_MAPED_SAVE], bsMenu);
  Button_CampaignSave.Anchors := [anLeft, anBottom];
  Button_CampaignSave.OnClick := SaveClick;

  Button_CampaignLaunch := TKMButton.Create(Panel_Campaign, Panel_Campaign.Width - LAUNCH_BUTTON_W - BUTTON_MARGIN_X, Panel_Campaign.Height - BUTTON_BOTTOM,
                                            LAUNCH_BUTTON_W, BUTTON_H, gResTexts[TX_MAPED_CAMPAIGN_PLAY], bsMenu);
  Button_CampaignLaunch.Anchors := [anLeft, anBottom];
  Button_CampaignLaunch.OnClick := LaunchClick;
end;


procedure TKMMenuCampaignMapEditor.CreateLanguageRow;
begin
  DropBox_EditorLanguage := TKMDropColumns.Create(Panel_Campaign, Button_CampaignLaunch.Left - ITEM_GAP - LANG_DROP_W, Panel_Campaign.Height - ITEM_BOTTOM,
                                                  LANG_DROP_W, ITEM_H, fntMetal, '', bsMenu, False);
  DropBox_EditorLanguage.SetColumns(fntMetal, ['', '', ''], [0, LANG_NAME_COLUMN_LEFT, LANG_AUDIO_COLUMN_LEFT]);
  DropBox_EditorLanguage.DropWidth := LANG_DROP_LIST_W;
  DropBox_EditorLanguage.Anchors := [anLeft, anBottom];
  DropBox_EditorLanguage.DropUp := True;
  DropBox_EditorLanguage.DropCount := LANG_DROP_COUNT;
  DropBox_EditorLanguage.OnChange := LanguageChange;
end;


procedure TKMMenuCampaignMapEditor.CreateMissionRow;
var
  groupLeft: Integer;
  backdrop: TKMBevel;
begin
  groupLeft := Button_CampaignSave.Right + ITEM_GAP;

  backdrop := TKMBevel.Create(Panel_Campaign, groupLeft - BACKDROP_PAD, Panel_Campaign.Height - BUTTON_BOTTOM, MISSION_GROUP_W + 2 * BACKDROP_PAD, BUTTON_H);
  backdrop.Anchors := [anLeft, anBottom];

  DropBox_QuickMission := TKMDropList.Create(Panel_Campaign, groupLeft, Panel_Campaign.Height - ITEM_BOTTOM, MISSION_DROP_W, ITEM_H,
                                             fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
  DropBox_QuickMission.Anchors := [anLeft, anBottom];
  DropBox_QuickMission.OnChange := SelectMap;
  DropBox_QuickMission.DropUp := True;
  DropBox_QuickMission.DropCount := MISSION_DROP_COUNT;

  Panel_QuickNodeBlock := TKMPanel.Create(Panel_Campaign, DropBox_QuickMission.Right + ITEM_GAP, Panel_Campaign.Height - NODE_BLOCK_BOTTOM,
                                          NODE_BLOCK_W, NODE_BLOCK_H);
  Panel_QuickNodeBlock.Anchors := [anLeft, anBottom];

  Image_QuickNodePreview := TKMImage.Create(Panel_QuickNodeBlock, NODE_BLOCK_PAD, NODE_PREVIEW_TOP, NODE_HIT_SIZE, NODE_HIT_SIZE, NODE_TEX, rxGuiMain);
  Image_QuickNodePreview.Hitable := False;
  Image_QuickNodePreview.Highlight := True;

  Label_QuickNodeCount := TKMLabel.Create(Panel_QuickNodeBlock, Image_QuickNodePreview.Left + NODE_LABEL_OFFSET_X - NODE_COUNT_SHIFT,
                                          Image_QuickNodePreview.Top + NODE_LABEL_OFFSET_Y - NODE_COUNT_SHIFT, '', fntMini, taCenter);
  Label_QuickNodeCount.FontColor := icLightGray2;
  Label_QuickNodeCount.Hitable := False;

  Button_QuickNodeAdd := TKMButton.Create(Panel_QuickNodeBlock, Image_QuickNodePreview.Right + NODE_BLOCK_PAD, NODE_BLOCK_PAD, NODE_BUTTON_W, ITEM_H,
                                          '+', bsMenu);
  Button_QuickNodeAdd.OnClick := NodeAddClick;

  Button_QuickNodeRemove := TKMButton.Create(Panel_QuickNodeBlock, Button_QuickNodeAdd.Right + SMALL_GAP, NODE_BLOCK_PAD, NODE_BUTTON_W, ITEM_H,
                                             '-', bsMenu);
  Button_QuickNodeRemove.OnClick := NodeRemoveClick;

  CheckBox_QuickBriefingLeft := TKMCheckBox.Create(Panel_Campaign, Panel_QuickNodeBlock.Right + ITEM_GAP,
                                                   Panel_Campaign.Height - ITEM_BOTTOM + BRIEFING_CHECK_SHIFT_Y, BRIEFING_CHECK_W, ITEM_H,
                                                   gResTexts[TX_MAPED_BRIEFING_POS_LEFT], fntMetal);
  CheckBox_QuickBriefingLeft.Anchors := [anLeft, anBottom];
  CheckBox_QuickBriefingLeft.OnClick := BriefingPosChange;
end;


procedure TKMMenuCampaignMapEditor.CreateTopRow;
begin
  Button_Undo := TKMButton.Create(Panel_Campaign, TOP_MARGIN, TOP_MARGIN, UNDO_BUTTON_W, ITEM_H, '<', bsMenu);
  Button_Undo.Anchors := [anLeft, anTop];
  Button_Undo.Hint := gResTexts[TX_MAPED_UNDO_HINT] + ' (''Ctrl + Z'')';
  Button_Undo.OnClick := UndoClick;

  Button_Redo := TKMButton.Create(Panel_Campaign, Button_Undo.Right + ITEM_GAP, TOP_MARGIN, UNDO_BUTTON_W, ITEM_H, '>', bsMenu);
  Button_Redo.Anchors := [anLeft, anTop];
  Button_Redo.Hint := gResTexts[TX_MAPED_REDO_HINT] + ' (''Ctrl + Y'' or ''Ctrl + Shift + Z'')';
  Button_Redo.OnClick := RedoClick;

  Button_LoadBackground := TKMButton.Create(Panel_Campaign, Panel_Campaign.Width - LOAD_BG_BUTTON_W - TOP_MARGIN, TOP_MARGIN, LOAD_BG_BUTTON_W, ITEM_H,
                                            gResTexts[TX_MAPED_CAMPAIGN_LOAD_BG], bsMenu);
  Button_LoadBackground.Anchors := [anRight, anTop];
  Button_LoadBackground.OnClick := LoadBackgroundClick;
end;


procedure TKMMenuCampaignMapEditor.CreateDialogs;
begin
  Form_ConfirmExit := CreateDialog(DIALOG_TEXT_H);

  Label_ConfirmExit := TKMLabel.Create(Form_ConfirmExit, Form_ConfirmExit.Width div 2, DIALOG_LABEL_TOP, gResTexts[TX_MAPED_SAVE_CHANGES_CONFIRM],
                                       fntOutline, taCenter);
  Label_ConfirmExit.Anchors := [anLeft, anBottom];

  Button_ConfirmExitSave := CreateDialogButton(Form_ConfirmExit, 0, gResTexts[TX_MAPED_SAVE], ConfirmExitClick);
  Button_ConfirmExitDiscard := CreateDialogButton(Form_ConfirmExit, 1, gResTexts[TX_MAPED_DISCARD_CHANGES], ConfirmExitClick);

  fBackgroundDialogPath := ExeDir;
  fBackgroundDialog := TKMGUIFileDialog.Create(Panel_Campaign, gResTexts[TX_MAPED_CAMPAIGN_LOAD_BG], '.png', BackgroundFileSelected);
end;


function TKMMenuCampaignMapEditor.CreateDialog(aContentHeight: Integer): TKMForm;
begin
  Result := TKMForm.Create(Panel_Campaign, DIALOG_CONTENT_W, aContentHeight, '', fbGray, False, False, False);
  Result.AnchorsCenter;
  Result.Left := (Panel_Campaign.Width div 2) - (Result.Width div 2);
  Result.Top := (Panel_Campaign.Height div 2) - (Result.Height div 2);

  TKMBevel.Create(Result, MODAL_BEVEL_POS, MODAL_BEVEL_POS, MODAL_BEVEL_SIZE, MODAL_BEVEL_SIZE);
end;


function TKMMenuCampaignMapEditor.CreateDialogButton(aDialog: TKMForm; aIndex: Integer; const aCaption: UnicodeString; aOnClick: TNotifyEvent): TKMButton;
begin
  Result := TKMButton.Create(aDialog, (aDialog.Width - DIALOG_BUTTONS_W) div 2 + aIndex * (DIALOG_BUTTON_W + DIALOG_BUTTON_GAP),
                             aDialog.Height - BUTTON_H - DIALOG_BUTTON_BOTTOM, DIALOG_BUTTON_W, BUTTON_H, aCaption, bsMenu);
  Result.Anchors := [anLeft, anBottom];
  Result.OnClick := aOnClick;
end;


procedure TKMMenuCampaignMapEditor.RefreshCampaign;
const
  FLAG_TEX: array [Boolean] of Byte = (FLAG_TEX_LOCKED, FLAG_TEX_UNLOCKED);
var
  I: Integer;
begin
  MapView.SetCampaign(fCampaign);

  for I := 0 to MAX_CAMP_MAPS - 1 do
  begin
    MapView.Flags[I].Visible := I < fCampaign.Spec.MissionsCount;
    MapView.Flags[I].TexID := FLAG_TEX[I <= ListBox_Maps.ItemIndex];
    MapView.FlagLabels[I].Visible := (I < fCampaign.Spec.MissionsCount) and (I <= ListBox_Maps.ItemIndex);
  end;

  MapView.PlaceFlags;
end;


function TKMMenuCampaignMapEditor.CaptureSnapshot: TKMCampMapSnapshotArray;
var
  I: Integer;
begin
  SetLength(Result, fCampaign.Spec.MissionsCount);
  for I := 0 to fCampaign.Spec.MissionsCount - 1 do
  begin
    Result[I].Flag := fCampaign.Spec.Maps[I].Flag;
    Result[I].NodeCount := fCampaign.Spec.Maps[I].NodeCount;
    Result[I].Nodes := fCampaign.Spec.Maps[I].Nodes;
    Result[I].TextPos := fCampaign.Spec.Maps[I].TextPos;
  end;
end;


procedure TKMMenuCampaignMapEditor.ApplySnapshot(const aSnapshot: TKMCampMapSnapshotArray);
var
  I: Integer;
begin
  for I := 0 to High(aSnapshot) do
  begin
    fCampaign.Spec.Maps[I].Flag := aSnapshot[I].Flag;
    fCampaign.Spec.Maps[I].NodeCount := aSnapshot[I].NodeCount;
    fCampaign.Spec.Maps[I].Nodes := aSnapshot[I].Nodes;
    fCampaign.Spec.Maps[I].TextPos := aSnapshot[I].TextPos;
  end;

  UpdateMaps;
end;


function TKMMenuCampaignMapEditor.SnapshotsEqual(const aFirst, aSecond: TKMCampMapSnapshotArray): Boolean;
var
  I, J: Integer;
begin
  Result := False;
  if Length(aFirst) <> Length(aSecond) then
    Exit;

  for I := 0 to High(aFirst) do
  begin
    if (aFirst[I].Flag.X <> aSecond[I].Flag.X) or (aFirst[I].Flag.Y <> aSecond[I].Flag.Y) then
      Exit;
    if aFirst[I].NodeCount <> aSecond[I].NodeCount then
      Exit;
    if aFirst[I].TextPos <> aSecond[I].TextPos then
      Exit;

    for J := 0 to aFirst[I].NodeCount - 1 do
      if (aFirst[I].Nodes[J].X <> aSecond[I].Nodes[J].X) or (aFirst[I].Nodes[J].Y <> aSecond[I].Nodes[J].Y) then
        Exit;
  end;

  Result := True;
end;


procedure TKMMenuCampaignMapEditor.PushUndo(const aSnapshotBeforeChange: TKMCampMapSnapshotArray);
begin
  fUndoStack.Add(aSnapshotBeforeChange);
  if fUndoStack.Count > MAX_UNDO_STEPS then
    fUndoStack.Delete(0);

  fRedoStack.Clear;
  UpdateUndoRedoState;
end;


procedure TKMMenuCampaignMapEditor.UpdateUndoRedoState;
begin
  Button_Undo.Enabled := fUndoStack.Count > 0;
  Button_Redo.Enabled := fRedoStack.Count > 0;
end;


procedure TKMMenuCampaignMapEditor.DragBeginCapture(Sender: TObject);
begin
  fPendingDragSnapshot := CaptureSnapshot;
  fHasDragThresholdCrossed := False;
  fDragStartTime := TimeGet;
  fDragOriginLeft := TKMControl(Sender).Left;
  fDragOriginTop := TKMControl(Sender).Top;
end;


function TKMMenuCampaignMapEditor.CheckDragThreshold(aControl: TKMControl): Boolean;
begin
  if not fHasDragThresholdCrossed then
  begin
    if TimeSince(fDragStartTime) < DRAG_HOLD_THRESHOLD_MS then
    begin
      aControl.Left := fDragOriginLeft;
      aControl.Top := fDragOriginTop;
      Exit(False);
    end;
    fHasDragThresholdCrossed := True;
  end;

  Result := True;
end;


procedure TKMMenuCampaignMapEditor.DragEndCommit(Sender: TObject);
begin
  if not SnapshotsEqual(fPendingDragSnapshot, CaptureSnapshot) then
    PushUndo(fPendingDragSnapshot);
end;


procedure TKMMenuCampaignMapEditor.UndoClick(Sender: TObject);
var
  snapshot: TKMCampMapSnapshotArray;
begin
  if fUndoStack.Count = 0 then
    Exit;

  fRedoStack.Add(CaptureSnapshot);
  snapshot := fUndoStack[fUndoStack.Count - 1];
  fUndoStack.Delete(fUndoStack.Count - 1);

  ApplySnapshot(snapshot);
  fIsDirty := True;
  UpdateUndoRedoState;
end;


procedure TKMMenuCampaignMapEditor.RedoClick(Sender: TObject);
var
  snapshot: TKMCampMapSnapshotArray;
begin
  if fRedoStack.Count = 0 then
    Exit;

  fUndoStack.Add(CaptureSnapshot);
  snapshot := fRedoStack[fRedoStack.Count - 1];
  fRedoStack.Delete(fRedoStack.Count - 1);

  ApplySnapshot(snapshot);
  fIsDirty := True;
  UpdateUndoRedoState;
end;


procedure TKMMenuCampaignMapEditor.KeyDown(Sender: TObject; Key: Word; Shift: TShiftState);
begin
  if not (ssCtrl in Shift) then
    Exit;

  case Key of
    Ord('Y'): RedoClick(Button_Redo);
    Ord('Z'): if ssShift in Shift then
                RedoClick(Button_Redo)
              else
                UndoClick(Button_Undo);
  end;
end;


procedure TKMMenuCampaignMapEditor.LaunchClick(Sender: TObject);
begin
  if fIsPreviewActive then
    StopPreview
  else
    StartPreview;
end;


function LocaleRow(aLocaleIndex, aTag: Integer; aHasAudio: Boolean): TKMListRow;
var
  audioPic: TKMPic;
begin
  if aHasAudio then
    audioPic := MakePic(rxGui, AUDIO_ICON_TEX)
  else
    audioPic := MakePic(rxGui, 0);

  Result := MakeListRow(['', gResLocales[aLocaleIndex].Title, ''], [icWhite, icWhite, icWhite],
                        [MakePic(rxGuiMain, gResLocales[aLocaleIndex].FlagSpriteID), MakePic(rxGuiMain, 0), audioPic], aTag);
end;


function IndexOfLocale(const aLocales: array of string; const aLocale: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(aLocales) do
    if aLocales[I] = aLocale then
      Exit(I);

  Result := -1;
end;


function TKMMenuCampaignMapEditor.SelectedLocale: string;
begin
  if DropBox_EditorLanguage.ItemIndex >= 0 then
    Result := fBriefingLocales[DropBox_EditorLanguage.ItemIndex]
  else
    Result := '';
end;


procedure TKMMenuCampaignMapEditor.FillLanguages;
var
  I, selected: Integer;
  previousLocale: string;
  hasAudio: Boolean;
  locales: TKMStringArray;
begin
  previousLocale := SelectedLocale;
  DropBox_EditorLanguage.Clear;

  locales := fCampaign.GetTextLocales;
  SetLength(fBriefingLocales, Length(locales));

  for I := 0 to High(locales) do
  begin
    fBriefingLocales[I] := locales[I];
    hasAudio := (ListBox_Maps.ItemIndex >= 0)
                and FileExists(fCampaign.GetBriefingAudioFile(ListBox_Maps.ItemIndex, AnsiString(locales[I])));
    DropBox_EditorLanguage.Add(LocaleRow(gResLocales.IndexByCode(AnsiString(locales[I])), I, hasAudio));
  end;

  selected := IndexOfLocale(fBriefingLocales, previousLocale);
  if selected < 0 then
    selected := IndexOfLocale(fBriefingLocales, string(gResLocales.UserLocale));
  if selected < 0 then
    selected := IndexOfLocale(fBriefingLocales, string(gResLocales.DefaultLocale));
  if (selected < 0) and (Length(locales) > 0) then
    selected := 0;

  DropBox_EditorLanguage.ItemIndex := selected;
end;


procedure TKMMenuCampaignMapEditor.LanguageChange(Sender: TObject);
begin
  UpdateBriefingPreview;

  if fIsPreviewActive then
    StartPreview;
end;


procedure TKMMenuCampaignMapEditor.LoadBackgroundClick(Sender: TObject);
begin
  fBackgroundDialog.Show(fBackgroundDialogPath);
end;


procedure TKMMenuCampaignMapEditor.BackgroundFileSelected(const aFileName: string);
begin
  fBackgroundDialogPath := ExtractFilePath(aFileName);

  try
    fCampaign.SetBackgroundImage(aFileName);
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  RefreshCampaign;
end;


procedure TKMMenuCampaignMapEditor.StartPreview;
var
  I: Integer;
  audioFile: string;
begin
  if ListBox_Maps.ItemIndex < 0 then
    Exit;

  fIsPreviewActive := True;
  fIsPreviewAnimDone := fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].NodeCount = 0;
  fAnimNodeIndex := 0;

  for I := 0 to fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].NodeCount - 1 do
  begin
    MapView.Nodes[I].Visible := False;
    MapView.NodeLabels[I].Visible := False;
  end;

  gMusic.StopPlayingOtherFile;

  if SelectedLocale <> '' then
    audioFile := fCampaign.GetBriefingAudioFile(ListBox_Maps.ItemIndex, AnsiString(SelectedLocale))
  else
    audioFile := fCampaign.GetBriefingAudioFile(ListBox_Maps.ItemIndex);

  fIsPreviewAudioExpected := gMusic.IsInitialized and FileExists(audioFile);
  fIsPreviewAudioStarted := False;
  fPreviewStartTime := TimeGet;
  TKMAudio.PauseMusicToPlayFile(audioFile);

  UpdatePreviewButtonState;
end;


procedure TKMMenuCampaignMapEditor.StopPreview;
var
  I: Integer;
begin
  gMusic.StopPlayingOtherFile;

  fIsPreviewActive := False;
  fIsPreviewAnimDone := False;
  fIsPreviewAudioExpected := False;
  fIsPreviewAudioStarted := False;

  if ListBox_Maps.ItemIndex >= 0 then
    for I := 0 to fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].NodeCount - 1 do
    begin
      MapView.Nodes[I].Visible := True;
      MapView.NodeLabels[I].Visible := True;
    end;

  UpdatePreviewButtonState;
end;


procedure TKMMenuCampaignMapEditor.UpdatePreviewButtonState;
begin
  if fIsPreviewActive then
  begin
    Button_CampaignLaunch.Caption := gResTexts[TX_MAPED_CAMPAIGN_STOP];
    Button_CampaignLaunch.Enabled := True;
  end
  else
  begin
    Button_CampaignLaunch.Caption := gResTexts[TX_MAPED_CAMPAIGN_PLAY];
    Button_CampaignLaunch.Enabled := ListBox_Maps.ItemIndex >= 0;
  end;
end;


procedure TKMMenuCampaignMapEditor.AnimNodes(aTickCount: Cardinal);
var
  mapIndex: Integer;
begin
  mapIndex := ListBox_Maps.ItemIndex;
  if not InRange(fAnimNodeIndex, 0, fCampaign.Spec.Maps[mapIndex].NodeCount - 1) then
    Exit;
  if (aTickCount mod CAMP_NODE_ANIMATION_PERIOD) <> 0 then
    Exit;
  if MapView.Nodes[fAnimNodeIndex].Visible then
    Exit;

  MapView.Nodes[fAnimNodeIndex].Visible := True;
  Inc(fAnimNodeIndex);

  if fAnimNodeIndex >= fCampaign.Spec.Maps[mapIndex].NodeCount then
    fIsPreviewAnimDone := True;
end;


function TKMMenuCampaignMapEditor.IsPreviewAudioDone: Boolean;
begin
  if not fIsPreviewAudioExpected then
    Result := True
  else
  if fIsPreviewAudioStarted then
    Result := gMusic.IsOtherEnded
  else
  begin
    fIsPreviewAudioStarted := not gMusic.IsOtherEnded;
    Result := not fIsPreviewAudioStarted and (TimeSince(fPreviewStartTime) > AUDIO_START_TIMEOUT_MS);
  end;
end;


procedure TKMMenuCampaignMapEditor.UpdateStateTick(aGlobalTickCount: Cardinal);
begin
  if (fCampaign = nil) or not Panel_Campaign.Visible then
    Exit;

  if not fIsPreviewActive or (ListBox_Maps.ItemIndex < 0) then
    Exit;

  if not fIsPreviewAnimDone then
    AnimNodes(aGlobalTickCount);

  if fIsPreviewAnimDone and IsPreviewAudioDone then
    StopPreview;
end;


procedure TKMMenuCampaignMapEditor.UpdateBriefingPreview;
var
  difficulty: TKMMissionDifficulty;
  diffLevels: TKMMissionDifficultySet;
  panHeight: Integer;
begin
  if ListBox_Maps.ItemIndex < 0 then
  begin
    Label_CampaignTitle.Caption := '';
    Label_CampaignText.Caption := '';
    DropBox_EditorDifficulty.Hide;
    Exit;
  end;

  Label_CampaignTitle.Caption := fCampaign.Spec.GetCampaignMissionTitle(ListBox_Maps.ItemIndex);

  if SelectedLocale <> '' then
    Label_CampaignText.Caption := fCampaign.GetMissionBriefing(ListBox_Maps.ItemIndex, AnsiString(SelectedLocale))
  else
    Label_CampaignText.Caption := fCampaign.GetMissionBriefing(ListBox_Maps.ItemIndex);

  DropBox_EditorDifficulty.Clear;
  if fCampaign.Spec.MapsInfo[ListBox_Maps.ItemIndex].TxtInfo.HasDifficultyLevels then
  begin
    diffLevels := fCampaign.Spec.MapsInfo[ListBox_Maps.ItemIndex].TxtInfo.DifficultyLevels;
    for difficulty in diffLevels do
      DropBox_EditorDifficulty.Add(gResTexts[DIFFICULTY_LEVELS_TX[difficulty]], Byte(difficulty));
    DropBox_EditorDifficulty.ItemIndex := 0;
    DropBox_EditorDifficulty.Show;
  end
  else
    DropBox_EditorDifficulty.Hide;

  DropBox_EditorDifficulty.Top := Label_CampaignText.Top + Label_CampaignText.TextSize.Y + DIFFICULTY_GAP;

  Panel_CampScroll.Left := IfThen(fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].TextPos = bcBottomRight,
                                  Panel_Campaign.Width - Panel_CampScroll.Width, 0);

  panHeight := Label_CampaignText.Top + Label_CampaignText.TextSize.Y + CAMP_SCROLL_BOTTOM_PAD
               + CAMP_DIFFICULTY_ROW_H * Byte(DropBox_EditorDifficulty.Visible);

  if panHeight > IMG_SCROLL_MAX_HEIGHT then
    Image_Scroll.ImageAnchors := Image_Scroll.ImageAnchors + [anBottom]
  else
    Image_Scroll.ImageAnchors := Image_Scroll.ImageAnchors - [anBottom];

  Panel_CampScroll.Height := panHeight;
  Panel_CampScroll.Top := Panel_Campaign.Height - Panel_CampScroll.Height;

  Image_ScrollRestore.Top := Panel_Campaign.Height - CAMP_RESTORE_MARGIN_BOTTOM;
end;


procedure TKMMenuCampaignMapEditor.UpdateMaps;
var
  I: Integer;
begin
  DropBox_QuickMission.ItemIndex := ListBox_Maps.ItemIndex;

  if ListBox_Maps.ItemIndex >= 0 then
    Label_QuickNodeCount.Caption := IntToStr(fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].NodeCount)
  else
    Label_QuickNodeCount.Caption := '';

  FillLanguages;
  UpdateBriefingPreview;

  for I := 0 to MAX_CAMP_MAPS - 1 do
  begin
    MapView.Flags[I].Highlight := I = ListBox_Maps.ItemIndex;
    MapView.FlagLabels[I].FontColor := icLightGray2;
  end;

  ListBox_Nodes.Clear;
  for I := 0 to MAX_CAMP_NODES - 1 do
  begin
    MapView.Nodes[I].Visible := (ListBox_Maps.ItemIndex >= 0) and (I < fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].NodeCount);
    MapView.NodeLabels[I].Visible := MapView.Nodes[I].Visible;
    if MapView.Nodes[I].Visible then
    begin
      ListBox_Nodes.Add((I + 1).ToString);
      MapView.Nodes[I].Highlight := False;
      MapView.PlaceNode(ListBox_Maps.ItemIndex, I);
    end;
  end;

  Button_NodeAdd.Enabled := (ListBox_Maps.ItemIndex >= 0) and (fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].NodeCount < MAX_CAMP_NODES);
  Button_QuickNodeAdd.Enabled := Button_NodeAdd.Enabled;

  Button_NodeRemove.Enabled := False;
  Button_QuickNodeRemove.Enabled := False;

  DropBox_BriefingPos.Enabled := ListBox_Maps.ItemIndex >= 0;
  CheckBox_QuickBriefingLeft.Enabled := DropBox_BriefingPos.Enabled;
  if ListBox_Maps.ItemIndex >= 0 then
    DropBox_BriefingPos.ItemIndex := Byte(fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].TextPos = bcBottomRight)
  else
    DropBox_BriefingPos.ItemIndex := -1;
  CheckBox_QuickBriefingLeft.Checked := DropBox_BriefingPos.ItemIndex = 0;

  gMusic.StopPlayingOtherFile;
  fIsPreviewActive := False;
  fIsPreviewAnimDone := False;
  fIsPreviewAudioExpected := False;
  fIsPreviewAudioStarted := False;
  UpdatePreviewButtonState;

  RefreshCampaign;
end;


procedure TKMMenuCampaignMapEditor.UpdateNodes;
var
  I: Integer;
begin
  for I := 0 to MAX_CAMP_NODES - 1 do
    MapView.Nodes[I].Highlight := I = ListBox_Nodes.ItemIndex;

  Button_NodeRemove.Enabled := (ListBox_Maps.ItemIndex >= 0) and (ListBox_Nodes.ItemIndex >= 0);
  Button_QuickNodeRemove.Enabled := Button_NodeRemove.Enabled;
end;


procedure TKMMenuCampaignMapEditor.SelectMap(Sender: TObject);
begin
  if Sender is TKMImage then
    ListBox_Maps.ItemIndex := TKMImage(Sender).Tag
  else if Sender = DropBox_QuickMission then
    ListBox_Maps.ItemIndex := DropBox_QuickMission.ItemIndex;

  UpdateMaps;
end;


procedure TKMMenuCampaignMapEditor.SelectNode(Sender: TObject);
begin
  if Sender is TKMImage then
    ListBox_Nodes.ItemIndex := TKMImage(Sender).Tag;

  UpdateNodes;
end;


procedure TKMMenuCampaignMapEditor.Resize(X, Y: Word);
begin
  MapView.ResizeToScreen(Y);
end;


procedure TKMMenuCampaignMapEditor.MoveMap(Sender: TObject);
begin
  if not CheckDragThreshold(TKMControl(Sender)) then
    Exit;

  MapView.StoreFlag(TKMControl(Sender).Tag);
  fIsDirty := True;
end;


procedure TKMMenuCampaignMapEditor.MoveNode(Sender: TObject);
begin
  if not CheckDragThreshold(TKMControl(Sender)) then
    Exit;

  MapView.StoreNode(ListBox_Maps.ItemIndex, TKMControl(Sender).Tag);
  fIsDirty := True;
end;


procedure TKMMenuCampaignMapEditor.NodeAddClick(Sender: TObject);
const
  NODE_Y_OFFSET = 20;
var
  mapIndex, oldCount, insertIndex, baseIndex, I: Integer;
  baseX, baseY: Word;
begin
  if ListBox_Maps.ItemIndex < 0 then
    Exit;
  mapIndex := ListBox_Maps.ItemIndex;
  oldCount := fCampaign.Spec.Maps[mapIndex].NodeCount;
  if oldCount >= MAX_CAMP_NODES then
    Exit;

  if ListBox_Nodes.ItemIndex >= 0 then
  begin
    insertIndex := ListBox_Nodes.ItemIndex + 1;
    baseIndex := ListBox_Nodes.ItemIndex;
  end
  else
  begin
    insertIndex := oldCount;
    baseIndex := oldCount - 1;
  end;

  if baseIndex >= 0 then
  begin
    baseX := fCampaign.Spec.Maps[mapIndex].Nodes[baseIndex].X;
    baseY := fCampaign.Spec.Maps[mapIndex].Nodes[baseIndex].Y;
  end
  else
  begin
    baseX := fCampaign.Spec.Maps[mapIndex].Flag.X;
    baseY := fCampaign.Spec.Maps[mapIndex].Flag.Y;
  end;

  PushUndo(CaptureSnapshot);

  for I := oldCount downto insertIndex + 1 do
    fCampaign.Spec.Maps[mapIndex].Nodes[I] := fCampaign.Spec.Maps[mapIndex].Nodes[I - 1];

  fCampaign.Spec.Maps[mapIndex].NodeCount := oldCount + 1;
  fCampaign.Spec.Maps[mapIndex].Nodes[insertIndex].X := baseX;
  fCampaign.Spec.Maps[mapIndex].Nodes[insertIndex].Y := Max(0, baseY - NODE_Y_OFFSET);

  fIsDirty := True;
  UpdateMaps;
  ListBox_Nodes.ItemIndex := insertIndex;
  UpdateNodes;
end;


procedure TKMMenuCampaignMapEditor.NodeRemoveClick(Sender: TObject);
var
  mapIndex, removeIndex, selectIndex, I: Integer;
begin
  if ListBox_Maps.ItemIndex < 0 then
    Exit;
  mapIndex := ListBox_Maps.ItemIndex;
  if fCampaign.Spec.Maps[mapIndex].NodeCount = 0 then
    Exit;

  if ListBox_Nodes.ItemIndex >= 0 then
    removeIndex := ListBox_Nodes.ItemIndex
  else
    removeIndex := fCampaign.Spec.Maps[mapIndex].NodeCount - 1;

  PushUndo(CaptureSnapshot);

  for I := removeIndex to fCampaign.Spec.Maps[mapIndex].NodeCount - 2 do
    fCampaign.Spec.Maps[mapIndex].Nodes[I] := fCampaign.Spec.Maps[mapIndex].Nodes[I + 1];

  fCampaign.Spec.Maps[mapIndex].NodeCount := fCampaign.Spec.Maps[mapIndex].NodeCount - 1;

  if removeIndex - 1 >= 0 then
    selectIndex := removeIndex - 1
  else if removeIndex < fCampaign.Spec.Maps[mapIndex].NodeCount then
    selectIndex := removeIndex
  else
    selectIndex := -1;

  fIsDirty := True;
  UpdateMaps;
  ListBox_Nodes.ItemIndex := selectIndex;
  UpdateNodes;
end;


procedure TKMMenuCampaignMapEditor.BriefingPosChange(Sender: TObject);
var
  isLeft: Boolean;
begin
  if ListBox_Maps.ItemIndex < 0 then
    Exit;

  if Sender = CheckBox_QuickBriefingLeft then
    isLeft := CheckBox_QuickBriefingLeft.Checked
  else
    isLeft := DropBox_BriefingPos.ItemIndex = 0;

  PushUndo(CaptureSnapshot);

  if isLeft then
    fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].TextPos := bcBottomLeft
  else
    fCampaign.Spec.Maps[ListBox_Maps.ItemIndex].TextPos := bcBottomRight;

  DropBox_BriefingPos.ItemIndex := Byte(not isLeft);
  CheckBox_QuickBriefingLeft.Checked := isLeft;

  fIsDirty := True;
  UpdateBriefingPreview;
end;


procedure TKMMenuCampaignMapEditor.MouseMove(Shift: TShiftState; X,Y: Integer);
begin
end;


procedure TKMMenuCampaignMapEditor.Show(aCampaignIdStr: UnicodeString);
var
  I: Integer;
begin
  fCampaign := gGameApp.Campaigns.CampaignByIdU(aCampaignIdStr);
  MapView.SetCampaign(fCampaign);

  ListBox_Maps.Clear;
  DropBox_QuickMission.Clear;
  for I := 0 to fCampaign.Spec.MissionsCount - 1 do
  begin
    ListBox_Maps.Add(fCampaign.GetMissionName(I));
    DropBox_QuickMission.Add(fCampaign.GetMissionName(I));
  end;

  DropBox_EditorLanguage.Clear;

  Panel_Campaign.Show;
  ListBox_Maps.ItemIndex := 0;
  UpdateMaps;
  UpdateState;

  fIsDirty := False;
  Form_ConfirmExit.Hide;

  fUndoStack.Clear;
  fRedoStack.Clear;
  UpdateUndoRedoState;
end;


procedure TKMMenuCampaignMapEditor.SaveClick(Sender: TObject);
begin
  fCampaign.Spec.SaveToFile(fCampaign.Path + 'info.cmp');
  fIsDirty := False;
end;


procedure TKMMenuCampaignMapEditor.BackClick(Sender: TObject);
begin
  if fBackgroundDialog.IsVisible then
    Exit;

  if fIsDirty then
  begin
    Form_ConfirmExit.Show;
    Exit;
  end;

  if fIsPreviewActive then
    StopPreview;

  fOnPageChange(gpMapEditor);
end;


procedure TKMMenuCampaignMapEditor.ConfirmExitClick(Sender: TObject);
begin
  Form_ConfirmExit.Hide;

  if Sender = Button_ConfirmExitSave then
    SaveClick(Sender)
  else
  begin
    fCampaign.Spec.LoadFromFile(fCampaign.Path, 'info.cmp');
    fUndoStack.Clear;
    fRedoStack.Clear;
    UpdateUndoRedoState;
  end;

  if fIsPreviewActive then
    StopPreview;

  fIsDirty := False;
  fOnPageChange(gpMapEditor);
end;


procedure TKMMenuCampaignMapEditor.UpdateState;
begin
  Panel_CampScroll.Visible := fScrollVisible;
  Image_ScrollRestore.Visible := not fScrollVisible;
end;


procedure TKMMenuCampaignMapEditor.ScrollToggle(Sender: TObject);
begin
  fScrollVisible := not fScrollVisible;
  UpdateState;

  if Panel_CampScroll.Visible then
    gSoundPlayer.Play(sfxMessageOpen)
  else
    gSoundPlayer.Play(sfxMessageClose);
end;


end.

unit KM_GUIMapEdMenuQuickPlay;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes,
  KM_Controls, KM_ControlsBase, KM_ControlsDrop, KM_ControlsForm, KM_ControlsSwitch,
  KM_GUIMapEdMenuSave, KM_CommonTypes;

type
  TKMMapEdMenuQuickPlay = class
  private
    fMenuSave: TKMMapEdMenuSave;
    fIsMultiplayer: Boolean;
    procedure SelectedHandChanged(Sender: TObject);
    procedure Cancel_Click(Sender: TObject);
    procedure QuickPlay_Click(Sender: TObject);
    procedure StartQuickPlay;
    procedure Update_PlayerSelect;
    procedure PlayerSelectFirst;
    procedure UpdateControls;
    procedure UpdatePanel;
    function HandCanBePlayedAsHuman(aIndex: Integer): Boolean;
    procedure SaveDone(Sender: TObject);
    procedure SaveBtn_EnableStatusChanged(Sender: TObject; aValue: Boolean);
    procedure UpdateSaveBtnStatus;
  protected
    Form_QuickPlay: TKMForm;
      DropList_SelectHand: TKMDropList;
      Radio_AIOpponents: TKMRadioGroup;
      Panel_Save: TKMPanel;

      Label_Difficulty: TKMLabel;
      DropBox_Difficulty: TKMDropList;
      Button_QuickPlay, Button_Cancel: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnMapTypChanged: TBooleanEvent);
    destructor Destroy; override;

    procedure SetLoadMode(aMultiplayer: Boolean);
    procedure Show;
    procedure Resize;

    procedure Hide;
    function Visible: Boolean;
    //todo -cPractical: refactoring - do not use KeyDown in TKMMapEdMenuQuickPlay, but use Form_QuickPlay.OnKeyDown instead
    function KeyDown(Key: Word; Shift: TShiftState): Boolean;
  end;


implementation
uses
  SysUtils,
  KromUtils,
  KM_Defaults, KM_GameApp, KM_Game, KM_GameParams, KM_GameTypes, KM_HandsCollection, KM_Maps, KM_MapTypes,
  KM_Hand, KM_InterfaceGamePlay,
  KM_RenderUI, KM_ResFonts, KM_ResTexts, KM_Resource, Math;

const
  PANEL_QUICKPLAY_HEIGHT = 505;


{ TKMMapEdMenuQuickPlay }
constructor TKMMapEdMenuQuickPlay.Create(aParent: TKMPanel; aOnMapTypChanged: TBooleanEvent);
const
  CTRLS_WIDTH = 220;
  MIN_WIDTH = 240;
var
  dx, dy, desiredWidth: Integer;
  panelCaption: string;
begin
  inherited Create;

  panelCaption := gResTexts[TX_MAPED_MAP_QUICK_PLAY];
  desiredWidth := Max(MIN_WIDTH, gRes.Fonts[TKMForm.DEFAULT_CAPTION_FONT].GetTextSize(panelCaption).X + 40);

  Form_QuickPlay := TKMForm.Create(aParent, desiredWidth, PANEL_QUICKPLAY_HEIGHT, panelCaption, fbGray);

  dx := (Form_QuickPlay.ItemsPanel.Width - CTRLS_WIDTH) div 2;
    dy := 15;
    TKMLabel.Create(Form_QuickPlay.ItemsPanel, Form_QuickPlay.ItemsPanel.Width div 2, dy, gResTexts[TX_MAPED_MAP_QUICK_PLAY_SEL_PLAYER], fntMetal, taCenter);
    Inc(dy, 25);

    DropList_SelectHand := TKMDropList.Create(Form_QuickPlay.ItemsPanel, dx, dy, CTRLS_WIDTH, 20, fntGame, '', bsGame);
    DropList_SelectHand.Hint := gResTexts[TX_MAPED_MAP_QUICK_PLAY_SEL_PLAYER_TO_START];
    DropList_SelectHand.OnChange := SelectedHandChanged;
    Inc(dy, 30);

    TKMBevel.Create(Form_QuickPlay.ItemsPanel, dx, dy - 5, CTRLS_WIDTH, 70);
    TKMLabel.Create(Form_QuickPlay.ItemsPanel, Form_QuickPlay.ItemsPanel.Width div 2, dy, gResTexts[TX_AI_PLAYER_TYPE], fntOutline, taCenter);
    Inc(dy, 20);
    Radio_AIOpponents := TKMRadioGroup.Create(Form_QuickPlay.ItemsPanel, dx + 5, dy, CTRLS_WIDTH - 10, 40, fntMetal);
    Radio_AIOpponents.Add(gResTexts[TX_AI_PLAYER_CLASSIC]);
    Radio_AIOpponents.Add(gResTexts[TX_AI_PLAYER_ADVANCED]);
    Radio_AIOpponents.ItemIndex := 0; // Classic AI

    Inc(dy, Radio_AIOpponents.Height);
    Panel_Save := TKMPanel.Create(Form_QuickPlay.ItemsPanel, dx, dy, CTRLS_WIDTH, 230);

    Inc(dy, 215);
    Button_QuickPlay := TKMButton.Create(Form_QuickPlay.ItemsPanel, dx, dy, CTRLS_WIDTH, 30, gResTexts[TX_MAPED_MAP_QUICK_PLAY_START_NO_SAVE], bsGame);
    Button_QuickPlay.Hint := gResTexts[TX_MAPED_MAP_QUICK_PLAY_START_NO_SAVE_HINT];
    Button_QuickPlay.OnClick := QuickPlay_Click;

    Inc(dy, 45);
    Label_Difficulty := TKMLabel.Create(Form_QuickPlay.ItemsPanel, dx, dy, gResTexts[TX_MISSION_DIFFICULTY], fntMetal, taLeft);
    Label_Difficulty.Anchors := [anLeft, anBottom];
    Inc(dy, 20);
    DropBox_Difficulty := TKMDropList.Create(Form_QuickPlay.ItemsPanel, dx, dy, CTRLS_WIDTH, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
    DropBox_Difficulty.Anchors := [anLeft, anBottom];

    Button_Cancel := TKMButton.Create(Form_QuickPlay.ItemsPanel, (Form_QuickPlay.ItemsPanel.Width - CTRLS_WIDTH) div 2, Form_QuickPlay.ItemsPanel.Height - 40,
                                      CTRLS_WIDTH, 30, gResTexts[TX_WORD_CANCEL], bsGame);
    Button_Cancel.Anchors := [anBottom];
    Button_Cancel.Hint := gResTexts[TX_WORD_CANCEL];
    Button_Cancel.OnClick := Cancel_Click;

  fMenuSave := TKMMapEdMenuSave.Create(Panel_Save, SaveDone, aOnMapTypChanged, fntMetal, 0, 10, 220);

  fMenuSave.Button_SaveCancel.Hide;

  fMenuSave.Button_SaveSave.Top := fMenuSave.Button_SaveSave.Top + 10;
  fMenuSave.Button_SaveSave.Caption := gResTexts[TX_MAPED_MAP_QUICK_PLAY_SAVE_AND_START];
  fMenuSave.Button_SaveSave.Hint := gResTexts[TX_MAPED_MAP_QUICK_PLAY_SAVE_AND_START_HINT];
  fMenuSave.Button_SaveSave.OnChangeEnableStatus := SaveBtn_EnableStatusChanged;
end;


destructor TKMMapEdMenuQuickPlay.Destroy;
begin
  FreeAndNil(fMenuSave);
  inherited;
end;


procedure TKMMapEdMenuQuickPlay.QuickPlay_Click(Sender: TObject);
begin
  StartQuickPlay;
end;


procedure TKMMapEdMenuQuickPlay.Resize;
begin
  // will update panel ActualHeight
  UpdatePanel;
end;


procedure TKMMapEdMenuQuickPlay.StartQuickPlay;
var
  I: Integer;
  gameName, missionFileRel: String;
  color: Cardinal;
  handID: Integer;
  isMultiplayer: Boolean;
  difficulty: TKMMissionDifficulty;
  aiType: TKMAIType;
begin
  missionFileRel := gGameParams.MissionFileRel;
  gameName := gGameParams.Name;
  handID := DropList_SelectHand.GetSelectedTag;

  // Currently selected hand could not be saved yet, we have to check if it was a valid one on the last map save
  // If it not valid, then we have to select any other valid hand (there should be one)
  if not gGame.MapEditor.SavedPlayableLocs[handID] then
    for I := 0 to MAX_HANDS - 1 do
      if gGame.MapEditor.SavedPlayableLocs[I] then
      begin
        handID := I;
        Break;
      end;

  Assert(gGame.MapEditor.SavedPlayableLocs[handID], 'Can not start map on location ' + IntToStr(handID));

  color := gHands[handID].FlagColor;
  isMultiplayer := fIsMultiplayer; //Somehow fIsMultiplayer sometimes change its value... have no time to debug it. Just save to local value for now

  difficulty := mdNone;
  if DropBox_Difficulty.IsClickable and DropBox_Difficulty.IsSelected then
    difficulty := TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag);

  if not Radio_AIOpponents.IsSelected then
    aiType := aitNone
  else
    aiType := TKMAIType(Radio_AIOpponents.ItemIndex + 1);

  FreeThenNil(gGame);
  gGameApp.NewSingleMap(ExeDir + missionFileRel, gameName, handID, color, difficulty, aiType);
  gGame.StartedFromMapEditor := True;
  gGame.StartedFromMapEdAsMPMap := isMultiplayer;
  TKMGamePlayInterface(gGame.ActiveInterface).UpdateUI;
end;


//todo -cPractical: refactoring - do not use KeyDown in TKMMapEdMenuQuickPlay, but use Form_QuickPlay.OnKeyDown instead
function TKMMapEdMenuQuickPlay.KeyDown(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True; //We want to handle all keys here
  case Key of
    VK_ESCAPE:  if Button_Cancel.IsClickable then
                  Cancel_Click(Button_Cancel);
  end;
end;


procedure TKMMapEdMenuQuickPlay.UpdateControls;
var
  I: Integer;
  MD: TKMMissionDifficulty;
begin
  Button_QuickPlay.Enabled := not gGame.MapEditor.IsNewMap
                              and gGame.MapEditor.SavedMapIsPlayable
                              and DropList_SelectHand.List.Selected;

  UpdateSaveBtnStatus;

  // Disable AI checkboxes, if AI type is not allowed on a map
  Radio_AIOpponents.SetItemEnabled(0, gGame.MapEditor.CanHaveClassicAI);
  Radio_AIOpponents.SetItemEnabled(1, gGame.MapEditor.CanHaveAdvancedAI);
  // Try to check first checkable, since we uncheck item, if disable it
  Radio_AIOpponents.CheckFirstCheckable;

  //Update Difficulty dropbox
  DropBox_Difficulty.Clear;
  if gGame.MapTxtInfo.HasDifficultyLevels then
  begin
    I := 0;
    for MD in gGame.MapTxtInfo.DifficultyLevels do
    begin
      DropBox_Difficulty.Add(gResTexts[DIFFICULTY_LEVELS_TX[MD]], Byte(MD));
      if MD = mdNormal then //Default difficulty is "Normal"
        DropBox_Difficulty.ItemIndex := I;
      Inc(I);
    end;
    if not DropBox_Difficulty.IsSelected then
      DropBox_Difficulty.ItemIndex := 0;
    DropBox_Difficulty.DoSetVisible;
    Label_Difficulty.DoSetVisible;
  end else begin
    Label_Difficulty.Hide;
    DropBox_Difficulty.Hide;
  end;

  Form_QuickPlay.ActualHeight := PANEL_QUICKPLAY_HEIGHT - 50 * Ord(not DropBox_Difficulty.IsSetVisible);
end;


function TKMMapEdMenuQuickPlay.HandCanBePlayedAsHuman(aIndex: Integer): Boolean;
begin
  Result := gHands[aIndex].HasAssets and gGame.MapEditor.PlayerHuman[aIndex];
end;


procedure TKMMapEdMenuQuickPlay.PlayerSelectFirst;
var
  I: Integer;
begin
  for I := 0 to MAX_HANDS - 1 do
  if HandCanBePlayedAsHuman(I) then
  begin
    DropList_SelectHand.SelectByTag(I);
    Exit;
  end;
end;


procedure TKMMapEdMenuQuickPlay.Update_PlayerSelect;
var
  I: Integer;
begin
  DropList_SelectHand.Clear;
  for I := 0 to MAX_HANDS - 1 do
  begin
    if HandCanBePlayedAsHuman(I) then
      DropList_SelectHand.Add(Format(gResTexts[TX_PLAYER_X], [I + 1]), I);
  end;
end;


procedure TKMMapEdMenuQuickPlay.UpdateSaveBtnStatus;
begin
  if not DropList_SelectHand.List.Selected then
    fMenuSave.Button_SaveSave.Disable;
end;


procedure TKMMapEdMenuQuickPlay.UpdatePanel;
begin
  Update_PlayerSelect;

  if not DropList_SelectHand.List.Selected then
  begin
    if HandCanBePlayedAsHuman(gMySpectator.HandID) then
      DropList_SelectHand.SelectByTag(gMySpectator.HandID)
    else
      PlayerSelectFirst;
  end;

  UpdateControls;
end;


procedure TKMMapEdMenuQuickPlay.SaveBtn_EnableStatusChanged(Sender: TObject; aValue: Boolean);
begin
  if aValue then
    UpdateSaveBtnStatus;
end;


procedure TKMMapEdMenuQuickPlay.SaveDone(Sender: TObject);
begin
  StartQuickPlay;
end;


procedure TKMMapEdMenuQuickPlay.SelectedHandChanged(Sender: TObject);
begin
  UpdateControls;
end;


procedure TKMMapEdMenuQuickPlay.SetLoadMode(aMultiplayer: Boolean);
begin
  fIsMultiplayer := aMultiplayer;
  fMenuSave.SetLoadMode(aMultiplayer);
end;


procedure TKMMapEdMenuQuickPlay.Cancel_Click(Sender: TObject);
begin
  Hide;
end;


procedure TKMMapEdMenuQuickPlay.Hide;
begin
  Form_QuickPlay.Hide;
end;


procedure TKMMapEdMenuQuickPlay.Show;
begin
  UpdatePanel;
  Form_QuickPlay.Show;
  fMenuSave.Show;
end;


function TKMMapEdMenuQuickPlay.Visible: Boolean;
begin
  Result := Form_QuickPlay.Visible;
end;


end.

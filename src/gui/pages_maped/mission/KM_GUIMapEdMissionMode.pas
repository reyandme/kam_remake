unit KM_GUIMapEdMissionMode;
{$I KaM_Remake.inc}
interface
uses
   Classes,
   KM_MapTypes,
   KM_Controls, KM_Defaults;

type
  TKMMapEdMissionMode = class
  private
    procedure Mission_ModeChange(Sender: TObject);
    procedure Mission_ModeUpdate;
    procedure AIBuilderChange(Sender: TObject);

    procedure MissionParams_Click(Sender: TObject);
    procedure MissionParams_CloseClick(Sender: TObject);
    function MissionParams_OnKeyDown(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
    procedure RadioMissionDesc_Changed(Sender: TObject);
    procedure UpdateMapTxtInfo(Sender: TObject);
    procedure UpdateMapParams;
  protected
    Panel_Mode: TKMPanel;
      Radio_MissionMode: TKMRadioGroup;

      Button_MissionParams: TKMButton;
      PopUp_MissionParams: TKMPopUpPanel;
        Panel_MissionParams: TKMPanel;
          Edit_Author: TKMEdit;
          Edit_Version: TKMEdit;
          Radio_SmallDescType: TKMRadioGroup;
          Edit_SmallDesc: TKMEdit;
          NumEdit_SmallDesc: TKMNumericEdit;
          Panel_CheckBoxes: TKMPanel;
            CheckBox_Coop, CheckBox_Special, CheckBox_RMG, CheckBox_PlayableAsSP,
            CheckBox_BlockTeamSelection, CheckBox_BlockPeacetime,
            CheckBox_BlockFullMapPreview, CheckBox_BlockColorSelection: TKMCheckBox;

          CheckBox_Difficulty: array [MISSION_DIFFICULTY_MIN..MISSION_DIFFICULTY_MAX] of TKMCheckBox;

          Radio_BigDescType: TKMRadioGroup;
          Edit_BigDesc: TKMEdit;
          NumEdit_BigDesc: TKMNumericEdit;
          Memo_BigDesc: TKMMemo;
          Button_Close: TKMButton;

      Button_AIBuilderSetup: TKMButton;
      Button_AIBuilderWarn: TKMLabel;
      Button_AIBuilderOK, Button_AIBuilderCancel: TKMButton;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    function Visible: Boolean;
    procedure Hide;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  KM_ResTexts, KM_Game, KM_GameParams, KM_RenderUI, KM_ResFonts, KM_InterfaceGame, KM_HandsCollection, KM_Hand;


{ TKMMapEdMissionMode }
constructor TKMMapEdMissionMode.Create(aParent: TKMPanel);
const
  CHK_W = 300;
  RADIO_W = 250;
var
  Dif_W, Top: Integer;
  MD: TKMMissionDifficulty;
begin
  inherited Create;

  Panel_Mode := TKMPanel.Create(aParent, 0, 28, aParent.Width, 400);
  with TKMLabel.Create(Panel_Mode, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_MISSION_MODE], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];
  with TKMBevel.Create(Panel_Mode, 9, 25, Panel_Mode.Width - 9, 45) do
    Anchors := [anLeft, anTop, anRight];

  Radio_MissionMode := TKMRadioGroup.Create(Panel_Mode, 14, 30, Panel_Mode.Width - 28, 40, fntMetal);
  Radio_MissionMode.Anchors := [anLeft, anTop, anRight];
  Radio_MissionMode.Add(gResTexts[TX_MAPED_MISSION_NORMAL]);
  Radio_MissionMode.Add(gResTexts[TX_MAPED_MISSION_TACTIC]);
  Radio_MissionMode.OnChange := Mission_ModeChange;

  Button_MissionParams := TKMButton.Create(Panel_Mode, 9, 80, Panel_Mode.Width - 9, 45, gResTexts[TX_MAPED_MISSION_PARAMETERS_BTN], bsGame);
  Button_MissionParams.Anchors := [anLeft, anTop, anRight];
  Button_MissionParams.Hint := gResTexts[TX_MAPED_MISSION_PARAMETERS_BTN_HINT];
  Button_MissionParams.OnClick := MissionParams_Click;

  PopUp_MissionParams := TKMPopUpPanel.Create(aParent.MasterParent, 700, 675, gResTexts[TX_MAPED_MISSION_PARAMETERS_TITLE]);

    Panel_MissionParams := TKMPanel.Create(PopUp_MissionParams, 5, 5, PopUp_MissionParams.Width - 10, PopUp_MissionParams.Height - 10);

    Top := 0;
    TKMLabel.Create(Panel_MissionParams, 0, Top, gResTexts[TX_MAPED_MISSION_AUTHOR], fntOutline, taLeft);
    TKMLabel.Create(Panel_MissionParams, (Panel_MissionParams.Width div 2) + 5, Top, gResTexts[TX_MAPED_MISSION_VERSION], fntOutline, taLeft);
    Inc(Top, 20);
    Edit_Author := TKMEdit.Create(Panel_MissionParams, 0, Top, (Panel_MissionParams.Width div 2) - 5, 20, fntArial);
    Edit_Author.ShowColors := True;
    Edit_Version := TKMEdit.Create(Panel_MissionParams, (Panel_MissionParams.Width div 2) + 5, Top,
                                   (Panel_MissionParams.Width div 2) - 5, 20, fntArial);
    Edit_Version.ShowColors := True;

    Inc(Top, 30);
    TKMLabel.Create(Panel_MissionParams, 0, Top, gResTexts[TX_MAPED_MISSION_SMALL_DESC], fntOutline, taLeft);
    Inc(Top, 20);
    TKMBevel.Create(Panel_MissionParams, 0, Top, RADIO_W + 10, 45);

    Radio_SmallDescType := TKMRadioGroup.Create(Panel_MissionParams, 5, Top + 5, RADIO_W, 40, fntMetal);
    Radio_SmallDescType.Add(gResTexts[TX_WORD_TEXT]);
    Radio_SmallDescType.Add(gResTexts[TX_MAPED_MISSION_LIBX_TEXT_ID]);
    Radio_SmallDescType.OnChange := RadioMissionDesc_Changed;

    Edit_SmallDesc := TKMEdit.Create(Panel_MissionParams, RADIO_W + 20, Top, Panel_MissionParams.Width - RADIO_W - 25, 20, fntGame);
    Edit_SmallDesc.ShowColors := True;
    NumEdit_SmallDesc := TKMNumericEdit.Create(Panel_MissionParams, RADIO_W + 20, Top, -1, 999, fntGrey);

    Inc(Top, 55);
    TKMLabel.Create(Panel_MissionParams, 0, Top, gResTexts[TX_MAPED_MISSION_PARAMETERS_TITLE], fntOutline, taLeft);
    Inc(Top, 25);
    TKMBevel.Create(Panel_MissionParams, 0, Top, Panel_MissionParams.Width, 85);

    Inc(Top, 5);
    Panel_CheckBoxes := TKMPanel.Create(Panel_MissionParams, 5, Top, Panel_MissionParams.Width - 10, 110);

      CheckBox_Coop := TKMCheckBox.Create(Panel_CheckBoxes, 0, 0,  CHK_W, 20, gResTexts[TX_LOBBY_MAP_COOP], fntMetal);
      CheckBox_Coop.Hint := gResTexts[TX_LOBBY_MAP_COOP];

      CheckBox_Special := TKMCheckBox.Create(Panel_CheckBoxes, 0, 20, CHK_W, 20, gResTexts[TX_LOBBY_MAP_SPECIAL], fntMetal);
      CheckBox_Special.Hint := gResTexts[TX_LOBBY_MAP_SPECIAL];

      CheckBox_PlayableAsSP := TKMCheckBox.Create(Panel_CheckBoxes, 0, 40, CHK_W, 20, gResTexts[TX_MENU_MAP_PLAYABLE_AS_SP],  fntMetal);
      CheckBox_PlayableAsSP.Hint := gResTexts[TX_MAPED_MISSION_PLAYABLE_AS_SP_HINT];

      CheckBox_RMG := TKMCheckBox.Create(Panel_CheckBoxes, 0, 60, CHK_W, 20, gResTexts[TX_LOBBY_MAP_RANDOM], fntMetal);
      CheckBox_RMG.Hint := gResTexts[TX_LOBBY_MAP_RANDOM_HINT];

      CheckBox_BlockColorSelection := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 0, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_COLOR_SEL], fntMetal);
      CheckBox_BlockColorSelection.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_COLOR_SEL_HINT];

      CheckBox_BlockTeamSelection := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 20, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_TEAM_SEL],  fntMetal);
      CheckBox_BlockTeamSelection.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_TEAM_SEL_HINT];

      CheckBox_BlockPeacetime := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 40, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_PT], fntMetal);
      CheckBox_BlockPeacetime.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_PT_HINT];

      CheckBox_BlockFullMapPreview := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 60, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_FULL_MAP_PREVIEW], fntMetal);
      CheckBox_BlockFullMapPreview.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_FULL_MAP_PREVIEW_HINT];


    Inc(Top, 90);
    with TKMLabel.Create(Panel_MissionParams, 0, Top, Panel_MissionParams.Width, 20, gResTexts[TX_MAPED_MISSION_DIFFICULTY_LEVELS], fntOutline, taLeft) do
      Hint := gResTexts[TX_MAPED_MISSION_DIFFICULTY_LEVELS_HINT];
    Inc(Top, 20);
    TKMBevel.Create(Panel_MissionParams, 0, Top, Panel_MissionParams.Width, 65);

    Inc(Top, 5);
    Dif_W := (PopUp_MissionParams.Width - 20) div 3;
    for MD := MISSION_DIFFICULTY_MIN to mdEasy1 do
      CheckBox_Difficulty[MD] := TKMCheckBox.Create(Panel_MissionParams,
                                       5, Top + (Integer(MD) - Integer(mdEasy3))*20,
                                       Dif_W, 20, gResTexts[DIFFICULTY_LEVELS_TX[MD]], fntMetal);
    CheckBox_Difficulty[mdNormal] := TKMCheckBox.Create(Panel_MissionParams,
                                       5 + Dif_W + 5, Top + 20, Dif_W, 20,
                                       gResTexts[DIFFICULTY_LEVELS_TX[mdNormal]], fntMetal);

    for MD := mdHard1 to MISSION_DIFFICULTY_MAX do
      CheckBox_Difficulty[MD] := TKMCheckBox.Create(Panel_MissionParams,
                                       5 + 2*Dif_W + 5, Top + (Integer(MD) - Integer(mdHard1))*20,
                                       Dif_W, 20, gResTexts[DIFFICULTY_LEVELS_TX[MD]], fntMetal);

    Inc(Top, 65);
    TKMLabel.Create(Panel_MissionParams, 0, Top, gResTexts[TX_MAPED_MISSION_BIG_DESC], fntOutline, taLeft);
    Inc(Top, 20);
    TKMBevel.Create(Panel_MissionParams, 0, Top, RADIO_W + 10, 45);

    Radio_BigDescType := TKMRadioGroup.Create(Panel_MissionParams, 5, Top + 5, RADIO_W, 40, fntMetal);
    Radio_BigDescType.Add(gResTexts[TX_WORD_TEXT]);
    Radio_BigDescType.Add(gResTexts[TX_MAPED_MISSION_LIBX_TEXT_ID]);
    Radio_BigDescType.OnChange := RadioMissionDesc_Changed;

    Edit_BigDesc := TKMEdit.Create(Panel_MissionParams, RADIO_W + 20, Top, Panel_MissionParams.Width - RADIO_W - 25, 20, fntGame);
    Edit_BigDesc.MaxLen := 4096;
    Edit_BigDesc.AllowedChars := acAll;
    Edit_BigDesc.ShowColors := True;
    NumEdit_BigDesc := TKMNumericEdit.Create(Panel_MissionParams, RADIO_W + 20, Top, -1, 999, fntGrey);

    Inc(Top, 55);
    Memo_BigDesc := TKMMemo.Create(Panel_MissionParams, 0, Top, Panel_MissionParams.Width, 200, fntArial, bsGame);
    Memo_BigDesc.AnchorsStretch;
    Memo_BigDesc.AutoWrap := True;
    Memo_BigDesc.ScrollDown := True;

    Edit_Author.OnChange                 := UpdateMapTxtInfo;
    Edit_Version.OnChange                := UpdateMapTxtInfo;
    Edit_SmallDesc.OnChange              := UpdateMapTxtInfo;
    NumEdit_SmallDesc.OnChange           := UpdateMapTxtInfo;
    Edit_BigDesc.OnChange                := UpdateMapTxtInfo;
    NumEdit_BigDesc.OnChange             := UpdateMapTxtInfo;
    CheckBox_Coop.OnClick                := UpdateMapTxtInfo;
    CheckBox_Special.OnClick             := UpdateMapTxtInfo;
    CheckBox_RMG.OnClick                 := UpdateMapTxtInfo;
    CheckBox_PlayableAsSP.OnClick        := UpdateMapTxtInfo;
    CheckBox_BlockTeamSelection.OnClick  := UpdateMapTxtInfo;
    CheckBox_BlockColorSelection.OnClick := UpdateMapTxtInfo;
    CheckBox_BlockPeacetime.OnClick      := UpdateMapTxtInfo;
    CheckBox_BlockFullMapPreview.OnClick := UpdateMapTxtInfo;

    for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
      CheckBox_Difficulty[MD].OnClick := UpdateMapTxtInfo;

    Inc(Top, 215);
    Button_Close := TKMButton.Create(Panel_MissionParams, 0, Top, 120, 30, gResTexts[TX_WORD_CLOSE], bsGame);
    Button_Close.SetPosCenterW;
    Button_Close.OnClick := MissionParams_CloseClick;

  PopUp_MissionParams.OnKeyDown := MissionParams_OnKeyDown;

  with TKMLabel.Create(Panel_Mode, 0, 140, Panel_Mode.Width, 0, gResTexts[TX_MAPED_AI_DEFAULTS_HEADING], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];

  Button_AIBuilderSetup := TKMButton.Create(Panel_Mode, 9, 170, Panel_Mode.Width - 9, 30, gResTexts[TX_MAPED_AI_DEFAULTS_MP_BUILDER], bsGame);
  Button_AIBuilderSetup.Anchors := [anLeft, anTop, anRight];
  Button_AIBuilderSetup.Hint := gResTexts[TX_MAPED_AI_DEFAULTS_MP_BUILDER_HINT];
  Button_AIBuilderSetup.OnClick := AIBuilderChange;

  Button_AIBuilderWarn := TKMLabel.Create(Panel_Mode, 9, 160, Panel_Mode.Width - 9, 0, gResTexts[TX_MAPED_AI_DEFAULTS_CONFIRM], fntGrey, taLeft);
  Button_AIBuilderWarn.Anchors := [anLeft, anTop, anRight];
  Button_AIBuilderWarn.AutoWrap := True;
  Button_AIBuilderWarn.Hide;
  Button_AIBuilderOK := TKMButton.Create(Panel_Mode, 9, 250, 88, 20, gResTexts[TX_MAPED_OK], bsGame);
  Button_AIBuilderOK.OnClick := AIBuilderChange;
  Button_AIBuilderOK.Hide;
  Button_AIBuilderCancel := TKMButton.Create(Panel_Mode, Panel_Mode.Width - 88, 250, 88, 20, gResTexts[TX_MAPED_CANCEL], bsGame);
  Button_AIBuilderCancel.Anchors := [anTop, anRight];
  Button_AIBuilderCancel.OnClick := AIBuilderChange;
  Button_AIBuilderCancel.Hide;
end;


function TKMMapEdMissionMode.MissionParams_OnKeyDown(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True; //We want to handle all keys here
  case Key of
    VK_ESCAPE:  if Button_Close.IsClickable then
                  MissionParams_CloseClick(Button_Close);
  end;
end;


procedure TKMMapEdMissionMode.MissionParams_Click(Sender: TObject);
begin
  PopUp_MissionParams.Show;
end;


procedure TKMMapEdMissionMode.MissionParams_CloseClick(Sender: TObject);
begin
  PopUp_MissionParams.Hide;
end;


procedure TKMMapEdMissionMode.Mission_ModeChange(Sender: TObject);
begin
  gGameParams.MissionMode := TKMissionMode(Radio_MissionMode.ItemIndex);
end;


procedure TKMMapEdMissionMode.AIBuilderChange(Sender: TObject);
var I: Integer;
begin
  if Sender = Button_AIBuilderSetup then
  begin
    Button_AIBuilderOK.Show;
    Button_AIBuilderCancel.Show;
    Button_AIBuilderWarn.Show;
    Button_AIBuilderSetup.Hide;
  end;

  if Sender = Button_AIBuilderOK then
    for I := 0 to gHands.Count-1 do
    begin
      gGame.MapEditor.PlayerClassicAI[I] := True;
      gGame.MapEditor.PlayerAdvancedAI[I] := True;
      gHands[I].AI.General.DefencePositions.Clear;
      gHands[I].AI.General.Attacks.Clear;
      //Setup Multiplayer setup, for ClassicAI. Anyway we will consider Old/New AI on the game start
      gHands[I].AI.Setup.ApplyMultiplayerSetup(False);
    end;

  if (Sender = Button_AIBuilderOK) or (Sender = Button_AIBuilderCancel) then
  begin
    Button_AIBuilderOK.Hide;
    Button_AIBuilderCancel.Hide;
    Button_AIBuilderWarn.Hide;
    Button_AIBuilderSetup.Show;
  end;
end;


procedure TKMMapEdMissionMode.Mission_ModeUpdate;
begin
  Radio_MissionMode.ItemIndex := Byte(gGameParams.MissionMode);
end;


procedure TKMMapEdMissionMode.Hide;
begin
  Panel_Mode.Hide;
end;


procedure TKMMapEdMissionMode.RadioMissionDesc_Changed(Sender: TObject);
begin
  case Radio_SmallDescType.ItemIndex of
    0:  begin
          Edit_SmallDesc.Visible := True;
          NumEdit_SmallDesc.Visible := False;
        end;
    1:  begin
          Edit_SmallDesc.Visible := False;
          NumEdit_SmallDesc.Visible := True;
        end;
  end;

  case Radio_BigDescType.ItemIndex of
    0:  begin
          Edit_BigDesc.Visible := True;
          Memo_BigDesc.Visible := True;
          NumEdit_BigDesc.Visible := False;
        end;
    1:  begin
          Edit_BigDesc.Visible := False;
          Memo_BigDesc.Visible := False;
          NumEdit_BigDesc.Visible := True;
        end;
  end;

  UpdateMapTxtInfo(Sender);
end;


procedure TKMMapEdMissionMode.UpdateMapTxtInfo(Sender: TObject);
var
  MD: TKMMissionDifficulty;
begin
  if CheckBox_Coop.Checked then
  begin
    CheckBox_BlockTeamSelection.Check;
    CheckBox_BlockPeacetime.Check;
    CheckBox_BlockFullMapPreview.Check;
    CheckBox_BlockTeamSelection.Disable;
    CheckBox_BlockPeacetime.Disable;
    CheckBox_BlockFullMapPreview.Disable;
  end else begin
    CheckBox_BlockTeamSelection.Enable;
    CheckBox_BlockPeacetime.Enable;
    CheckBox_BlockFullMapPreview.Enable;
  end;

  Memo_BigDesc.Text := Edit_BigDesc.Text;
  gGame.MapTxtInfo.Author := Edit_Author.Text;
  gGame.MapTxtInfo.Version := Edit_Version.Text;

  case Radio_SmallDescType.ItemIndex of
    0:  begin
          gGame.MapTxtInfo.SmallDesc     := Edit_SmallDesc.Text;
          gGame.MapTxtInfo.SmallDescLIBX := -1;
        end;
    1:  begin
          gGame.MapTxtInfo.SmallDesc     := '';
          gGame.MapTxtInfo.SmallDescLIBX := NumEdit_SmallDesc.Value;
        end;
  end;

  case Radio_BigDescType.ItemIndex of
    0:  begin
          gGame.MapTxtInfo.SetBigDesc(Edit_BigDesc.Text);
          gGame.MapTxtInfo.BigDescLIBX := -1
        end;
    1:  begin
          gGame.MapTxtInfo.SetBigDesc('');
          gGame.MapTxtInfo.BigDescLIBX := NumEdit_BigDesc.Value;
        end;
  end;

  gGame.MapTxtInfo.IsCoop         := CheckBox_Coop.Checked;
  gGame.MapTxtInfo.IsSpecial      := CheckBox_Special.Checked;
  gGame.MapTxtInfo.IsRMG          := CheckBox_RMG.Checked;
  gGame.MapTxtInfo.IsPlayableAsSP := CheckBox_PlayableAsSP.Checked;

  gGame.MapTxtInfo.BlockTeamSelection  := CheckBox_BlockTeamSelection.Checked;
  gGame.MapTxtInfo.BlockColorSelection := CheckBox_BlockColorSelection.Checked;
  gGame.MapTxtInfo.BlockPeacetime      := CheckBox_BlockPeacetime.Checked;
  gGame.MapTxtInfo.BlockFullMapPreview := CheckBox_BlockFullMapPreview.Checked;

  gGame.MapTxtInfo.DifficultyLevels := [];

  for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
    if CheckBox_Difficulty[MD].Checked then
      Include(gGame.MapTxtInfo.DifficultyLevels, MD);
end;


procedure TKMMapEdMissionMode.UpdateMapParams;
var
  MD: TKMMissionDifficulty;
begin
  Edit_Author.SetTextSilently(gGame.MapTxtInfo.Author);   // Will not trigger OnChange event
  Edit_Version.SetTextSilently(gGame.MapTxtInfo.Version); // Will not trigger OnChange event

  if gGame.MapTxtInfo.IsSmallDescLibxSet then
    Radio_SmallDescType.ItemIndex := 1
  else
    Radio_SmallDescType.ItemIndex := 0;

  if gGame.MapTxtInfo.IsBigDescLibxSet then
    Radio_BigDescType.ItemIndex := 1
  else
    Radio_BigDescType.ItemIndex := 0;

  Edit_SmallDesc.SetTextSilently(gGame.MapTxtInfo.SmallDesc); // Will not trigger OnChange event
  NumEdit_SmallDesc.Value := gGame.MapTxtInfo.SmallDescLibx;
  Edit_BigDesc.SetTextSilently(gGame.MapTxtInfo.GetBigDesc);  // Will not trigger OnChange event
  NumEdit_BigDesc.Value   := gGame.MapTxtInfo.BigDescLibx;
  Memo_BigDesc.Text       := Edit_BigDesc.Text;

  CheckBox_Coop.Checked         := gGame.MapTxtInfo.IsCoop;
  CheckBox_Special.Checked      := gGame.MapTxtInfo.IsSpecial;
  CheckBox_RMG.Checked          := gGame.MapTxtInfo.IsRMG;
  CheckBox_PlayableAsSP.Checked := gGame.MapTxtInfo.IsPlayableAsSP;

  CheckBox_BlockTeamSelection.Checked   := gGame.MapTxtInfo.BlockTeamSelection;
  CheckBox_BlockColorSelection.Checked  := gGame.MapTxtInfo.BlockColorSelection;
  CheckBox_BlockPeacetime.Checked       := gGame.MapTxtInfo.BlockPeacetime;
  CheckBox_BlockFullMapPreview.Checked  := gGame.MapTxtInfo.BlockFullMapPreview;

  for MD := MISSION_DIFFICULTY_MIN to MISSION_DIFFICULTY_MAX do
    CheckBox_Difficulty[MD].Checked := MD in gGame.MapTxtInfo.DifficultyLevels;

  RadioMissionDesc_Changed(nil);
end;


procedure TKMMapEdMissionMode.Show;
begin
  Mission_ModeUpdate;
  Panel_Mode.Show;
  AIBuilderChange(Button_AIBuilderCancel); //Hide confirmation
  UpdateMapParams;
end;


function TKMMapEdMissionMode.Visible: Boolean;
begin
  Result := Panel_Mode.Visible;
end;


end.

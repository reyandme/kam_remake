unit KM_GUIMapEdMissionMode;
{$I KaM_Remake.inc}
interface
uses
   Classes,
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
          Radio_SmallDescType: TKMRadioGroup;
          Edit_SmallDesc: TKMEdit;
          NumEdit_SmallDesc: TKMNumericEdit;
          Panel_CheckBoxes: TKMPanel;
            CheckBox_Coop, CheckBox_Special, CheckBox_PlayableAsSP,
            CheckBox_BlockTeamSelection, CheckBox_BlockPeacetime, CheckBox_BlockFullMapPreview: TKMCheckBox;
          CheckBox_DifficultyEasy, CheckBox_DifficultyNormal, CheckBox_DifficultyHard: TKMCheckBox;
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
  KM_ResTexts, KM_Game, KM_RenderUI, KM_ResFonts, KM_InterfaceGame, KM_HandsCollection, KM_Hand, KM_MapTypes;


{ TKMMapEdMissionMode }
constructor TKMMapEdMissionMode.Create(aParent: TKMPanel);
const
  CHK_W = 300;
  RADIO_W = 250;
var
  Dif_W: Integer;
begin
  inherited Create;

  Panel_Mode := TKMPanel.Create(aParent, 0, 28, TB_MAP_ED_WIDTH, 400);
  TKMLabel.Create(Panel_Mode, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_MISSION_MODE], fntOutline, taCenter);
  TKMBevel.Create(Panel_Mode, 9, 25, TB_MAP_ED_WIDTH - 9, 45);

  Radio_MissionMode := TKMRadioGroup.Create(Panel_Mode, 14, 30, TB_MAP_ED_WIDTH - 28, 40, fntMetal);
  Radio_MissionMode.Add(gResTexts[TX_MAPED_MISSION_NORMAL]);
  Radio_MissionMode.Add(gResTexts[TX_MAPED_MISSION_TACTIC]);
  Radio_MissionMode.OnChange := Mission_ModeChange;

  Button_MissionParams := TKMButton.Create(Panel_Mode, 9, 80, TB_MAP_ED_WIDTH - 9, 45, gResTexts[TX_MAPED_MISSION_PARAMETERS_BTN], bsGame);
  Button_MissionParams.Hint := gResTexts[TX_MAPED_MISSION_PARAMETERS_BTN_HINT];
  Button_MissionParams.OnClick := MissionParams_Click;

  PopUp_MissionParams := TKMPopUpPanel.Create(aParent.MasterParent, 700, 615, gResTexts[TX_MAPED_MISSION_PARAMETERS_TITLE]);

    Panel_MissionParams := TKMPanel.Create(PopUp_MissionParams, 5, 5, PopUp_MissionParams.Width - 10, PopUp_MissionParams.Height - 10);

    TKMLabel.Create(Panel_MissionParams, 0, 0, gResTexts[TX_MAPED_MISSION_AUTHOR], fntOutline, taLeft);
    Edit_Author := TKMEdit.Create(Panel_MissionParams, 0, 20, Panel_MissionParams.Width, 20, fntArial);

    TKMLabel.Create(Panel_MissionParams, 0, 50, gResTexts[TX_MAPED_MISSION_SMALL_DESC], fntOutline, taLeft);

    TKMBevel.Create(Panel_MissionParams, 0, 70, RADIO_W + 10, 45);
    Radio_SmallDescType := TKMRadioGroup.Create(Panel_MissionParams, 5, 75, RADIO_W, 40, fntMetal);
    Radio_SmallDescType.Add(gResTexts[TX_WORD_TEXT]);
    Radio_SmallDescType.Add(gResTexts[TX_MAPED_MISSION_LIBX_TEXT_ID]);
    Radio_SmallDescType.OnChange := RadioMissionDesc_Changed;

    Edit_SmallDesc := TKMEdit.Create(Panel_MissionParams, RADIO_W + 20, 70, Panel_MissionParams.Width - RADIO_W - 25, 20, fntGame);
    NumEdit_SmallDesc := TKMNumericEdit.Create(Panel_MissionParams, RADIO_W + 20, 70, -1, 999, fntGrey);

    TKMLabel.Create(Panel_MissionParams, 0, 125, gResTexts[TX_MAPED_MISSION_PARAMETERS_TITLE], fntOutline, taLeft);
    TKMBevel.Create(Panel_MissionParams, 0, 150, Panel_MissionParams.Width, 65);

    Panel_CheckBoxes := TKMPanel.Create(Panel_MissionParams, 5, 155, Panel_MissionParams.Width - 10, 90);

      CheckBox_Coop := TKMCheckBox.Create(Panel_CheckBoxes, 0, 0,  CHK_W, 20, gResTexts[TX_LOBBY_MAP_COOP], fntMetal);
      CheckBox_Coop.Hint := gResTexts[TX_LOBBY_MAP_COOP];

      CheckBox_Special := TKMCheckBox.Create(Panel_CheckBoxes, 0, 20, CHK_W, 20, gResTexts[TX_LOBBY_MAP_SPECIAL], fntMetal);
      CheckBox_Special.Hint := gResTexts[TX_LOBBY_MAP_SPECIAL];

      CheckBox_PlayableAsSP := TKMCheckBox.Create(Panel_CheckBoxes, 0, 40, CHK_W, 20, gResTexts[TX_MENU_MAP_PLAYABLE_AS_SP],  fntMetal);
      CheckBox_PlayableAsSP.Hint := gResTexts[TX_MAPED_MISSION_PLAYABLE_AS_SP_HINT];

      CheckBox_BlockTeamSelection := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 0, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_TEAM_SEL],  fntMetal);
      CheckBox_BlockTeamSelection.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_TEAM_SEL_HINT];

      CheckBox_BlockPeacetime := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 20, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_PT], fntMetal);
      CheckBox_BlockPeacetime.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_PT_HINT];

      CheckBox_BlockFullMapPreview := TKMCheckBox.Create(Panel_CheckBoxes, CHK_W + 10, 40, CHK_W, 20, gResTexts[TX_MAPED_MISSION_BLOCK_FULL_MAP_PREVIEW], fntMetal);
      CheckBox_BlockFullMapPreview.Hint := gResTexts[TX_MAPED_MISSION_BLOCK_FULL_MAP_PREVIEW_HINT];

    with TKMLabel.Create(Panel_MissionParams, 0, 225, Panel_MissionParams.Width, 20, gResTexts[TX_MAPED_MISSION_DIFFICULTY_LEVELS], fntOutline, taLeft) do
      Hint := gResTexts[TX_MAPED_MISSION_DIFFICULTY_LEVELS_HINT];
    TKMBevel.Create(Panel_MissionParams, 0, 245, Panel_MissionParams.Width, 25);

    Dif_W := (PopUp_MissionParams.Width - 20) div 3;
    CheckBox_DifficultyEasy   := TKMCheckBox.Create(Panel_MissionParams, 5,               250, Dif_W, 20, 'Easy',   fntMetal);
    CheckBox_DifficultyNormal := TKMCheckBox.Create(Panel_MissionParams, 5 + Dif_W + 5,   250, Dif_W, 20, 'Normal', fntMetal);
    CheckBox_DifficultyHard   := TKMCheckBox.Create(Panel_MissionParams, 5 + 2*Dif_W + 5, 250, Dif_W, 20, 'Hard',   fntMetal);

    TKMLabel.Create(Panel_MissionParams, 0, 275, gResTexts[TX_MAPED_MISSION_BIG_DESC], fntOutline, taLeft);
    TKMBevel.Create(Panel_MissionParams, 0, 295, RADIO_W + 10, 45);

    Radio_BigDescType := TKMRadioGroup.Create(Panel_MissionParams, 5, 300, RADIO_W, 40, fntMetal);
    Radio_BigDescType.Add(gResTexts[TX_WORD_TEXT]);
    Radio_BigDescType.Add(gResTexts[TX_MAPED_MISSION_LIBX_TEXT_ID]);
    Radio_BigDescType.OnChange := RadioMissionDesc_Changed;

    Edit_BigDesc := TKMEdit.Create(Panel_MissionParams, RADIO_W + 20, 295, Panel_MissionParams.Width - RADIO_W - 25, 20, fntGame);
    Edit_BigDesc.MaxLen := 4096;
    Edit_BigDesc.AllowedChars := acAll;
    NumEdit_BigDesc := TKMNumericEdit.Create(Panel_MissionParams, RADIO_W + 20, 295, -1, 999, fntGrey);

    Memo_BigDesc := TKMMemo.Create(Panel_MissionParams, 0, 350, Panel_MissionParams.Width, 200, fntArial, bsGame);
    Memo_BigDesc.AnchorsStretch;
    Memo_BigDesc.AutoWrap := True;
    Memo_BigDesc.ScrollDown := True;

    Edit_Author.OnChange                 := UpdateMapTxtInfo;
    Edit_SmallDesc.OnChange              := UpdateMapTxtInfo;
    NumEdit_SmallDesc.OnChange           := UpdateMapTxtInfo;
    Edit_BigDesc.OnChange                := UpdateMapTxtInfo;
    NumEdit_BigDesc.OnChange             := UpdateMapTxtInfo;
    CheckBox_Coop.OnClick                := UpdateMapTxtInfo;
    CheckBox_Special.OnClick             := UpdateMapTxtInfo;
    CheckBox_PlayableAsSP.OnClick        := UpdateMapTxtInfo;
    CheckBox_BlockTeamSelection.OnClick  := UpdateMapTxtInfo;
    CheckBox_BlockPeacetime.OnClick      := UpdateMapTxtInfo;
    CheckBox_BlockFullMapPreview.OnClick := UpdateMapTxtInfo;
    CheckBox_DifficultyEasy.OnClick              := UpdateMapTxtInfo;
    CheckBox_DifficultyNormal.OnClick            := UpdateMapTxtInfo;
    CheckBox_DifficultyHard.OnClick              := UpdateMapTxtInfo;

    Button_Close := TKMButton.Create(Panel_MissionParams, 0, 565, 120, 30, gResTexts[TX_WORD_CLOSE], bsGame);
    Button_Close.SetPosCenterW;
    Button_Close.OnClick := MissionParams_CloseClick;

  PopUp_MissionParams.OnKeyDown := MissionParams_OnKeyDown;

  TKMLabel.Create(Panel_Mode, 0, 140, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_AI_DEFAULTS_HEADING], fntOutline, taCenter);

  Button_AIBuilderSetup := TKMButton.Create(Panel_Mode, 9, 170, TB_MAP_ED_WIDTH - 9, 30, gResTexts[TX_MAPED_AI_DEFAULTS_MP_BUILDER], bsGame);
  Button_AIBuilderSetup.Hint := gResTexts[TX_MAPED_AI_DEFAULTS_MP_BUILDER_HINT];
  Button_AIBuilderSetup.OnClick := AIBuilderChange;

  Button_AIBuilderWarn := TKMLabel.Create(Panel_Mode, 9, 160, TB_MAP_ED_WIDTH - 9, 0, gResTexts[TX_MAPED_AI_DEFAULTS_CONFIRM], fntGrey, taLeft);
  Button_AIBuilderWarn.AutoWrap := True;
  Button_AIBuilderWarn.Hide;
  Button_AIBuilderOK := TKMButton.Create(Panel_Mode, 9, 250, 88, 20, gResTexts[TX_MAPED_OK], bsGame);
  Button_AIBuilderOK.OnClick := AIBuilderChange;
  Button_AIBuilderOK.Hide;
  Button_AIBuilderCancel := TKMButton.Create(Panel_Mode, 101, 250, 88, 20, gResTexts[TX_MAPED_CANCEL], bsGame);
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
  gGame.MissionMode := TKMissionMode(Radio_MissionMode.ItemIndex);
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
  Radio_MissionMode.ItemIndex := Byte(gGame.MissionMode);
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
  gGame.MapTxtInfo.Author        := Edit_Author.Text;

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
  gGame.MapTxtInfo.IsPlayableAsSP := CheckBox_PlayableAsSP.Checked;

  gGame.MapTxtInfo.BlockTeamSelection  := CheckBox_BlockTeamSelection.Checked;
  gGame.MapTxtInfo.BlockPeacetime      := CheckBox_BlockPeacetime.Checked;
  gGame.MapTxtInfo.BlockFullMapPreview := CheckBox_BlockFullMapPreview.Checked;

  gGame.MapTxtInfo.DifficultyLevels := [];
  if CheckBox_DifficultyEasy.Checked then
    Include(gGame.MapTxtInfo.DifficultyLevels, mdEasy);
  if CheckBox_DifficultyNormal.Checked then
    Include(gGame.MapTxtInfo.DifficultyLevels, mdNormal);
  if CheckBox_DifficultyHard.Checked then
    Include(gGame.MapTxtInfo.DifficultyLevels, mdHard);
end;


procedure TKMMapEdMissionMode.UpdateMapParams;
begin
  Edit_Author.Text := gGame.MapTxtInfo.Author;

  if gGame.MapTxtInfo.IsSmallDescLibxSet then
    Radio_SmallDescType.ItemIndex := 1
  else
    Radio_SmallDescType.ItemIndex := 0;

  if gGame.MapTxtInfo.IsBigDescLibxSet then
    Radio_BigDescType.ItemIndex := 1
  else
    Radio_BigDescType.ItemIndex := 0;

  Edit_SmallDesc.Text     := gGame.MapTxtInfo.SmallDesc;
  NumEdit_SmallDesc.Value := gGame.MapTxtInfo.SmallDescLibx;
  Edit_BigDesc.Text       := gGame.MapTxtInfo.GetBigDesc;
  NumEdit_BigDesc.Value   := gGame.MapTxtInfo.BigDescLibx;
  Memo_BigDesc.Text       := Edit_BigDesc.Text;

  CheckBox_Coop.Checked         := gGame.MapTxtInfo.IsCoop;
  CheckBox_Special.Checked      := gGame.MapTxtInfo.IsSpecial;
  CheckBox_PlayableAsSP.Checked := gGame.MapTxtInfo.IsPlayableAsSP;

  CheckBox_BlockTeamSelection.Checked   := gGame.MapTxtInfo.BlockTeamSelection;
  CheckBox_BlockPeacetime.Checked       := gGame.MapTxtInfo.BlockPeacetime;
  CheckBox_BlockFullMapPreview.Checked  := gGame.MapTxtInfo.BlockFullMapPreview;

  CheckBox_DifficultyEasy.Checked    := mdEasy   in gGame.MapTxtInfo.DifficultyLevels;
  CheckBox_DifficultyNormal.Checked  := mdNormal in gGame.MapTxtInfo.DifficultyLevels;
  CheckBox_DifficultyHard.Checked    := mdHard   in gGame.MapTxtInfo.DifficultyLevels;

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

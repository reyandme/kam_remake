unit KM_GUIMapEdMissionPlayers;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsPopUp, KM_ControlsSwitch,
  KM_Defaults, KM_Pics;

type
  TKMMapEdPlayerType = (mptDefault, mptHuman, mptClassicAI, mptAdvancedAI);

  TKMMapEdConfirmationType = (mctNone, mctMPSetup, mctDeletePlayer);

  TKMMapEdMissionPlayers = class
  private
    fPlayerIdToConfirm: TKMHandID;
    fConfirmationType: TKMMapEdConfirmationType;

    procedure Mission_PlayerTypesChange(Sender: TObject);
    procedure Mission_PlayerTypesAllClick(Sender: TObject);
    procedure Mission_PlayerIdUpdate;
    procedure PlayerDelete_Click(Sender: TObject);
    procedure PlayerDeleteConfirm_Click(Sender: TObject);
    procedure PlayerMPSetup_Click(Sender: TObject);
    procedure ClosePlayerTypes_Click(Sender: TObject);

    procedure DoConfirm(aVisible: Boolean);
  protected
    Panel_PlayerTypes: TKMPopUpPanel;
      ChkBox_PlayerTypes: array [0..MAX_HANDS-1, TKMMapEdPlayerType] of TKMCheckBox;
      Button_PlayerMPSetup: array [0..MAX_HANDS-1] of TKMButtonFlat;
      Button_PlayerDelete: array [0..MAX_HANDS-1] of TKMButtonFlat;
      ChkBox_PlayerTypesAll: array [mptHuman..mptAdvancedAI] of TKMCheckBox;
      Label_PlayerTypesAll: TKMLabel;
      Label_PlayerId: array [0..MAX_HANDS-1] of TKMLabel;
      Button_Close: TKMButton;

    PopUp_Confirm_Player: TKMPopUpMenu;
      Image_Confirm_Player: TKMImage;
      Button_PlayerConfirm, Button_PlayerConfirmCancel: TKMButton;
      Label_PlayerConfirmTitle, Label_PlayerConfirmWarn: TKMLabel;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure Show;
    function Visible: Boolean;
    procedure Hide;

    procedure UpdatePlayerTypes;
  end;


implementation
uses
  KM_Game,
  KM_HandsCollection, KM_Hand,
  KM_ResTexts, KM_ResFonts, KM_ResTypes,
  KM_RenderUI;

const
  PANEL_W  = 300;
  BTN_MPSETUP_W = 24;
  BTN_DELETE_W = 22;
  LINE_H = 26;
  ICON_SPACE_W = 25;
  ICON_SPACE_H = 32;
  CONF_W = 500;
  CONF_H = 260;
  CONF_BTN_W = 170;
  CONF_BTN_PAD = 40;

  PLAYER_TYPE_TX: array [mptHuman..mptAdvancedAI] of Integer = (TX_PLAYER_HUMAN, TX_AI_PLAYER_CLASSIC, TX_AI_PLAYER_ADVANCED);

{ TKMMapEdMissionPlayers }
constructor TKMMapEdMissionPlayers.Create(aParent: TKMPanel);
var
  I, top, panelH: Integer;
  MPT: TKMMapEdPlayerType;
begin
  inherited Create;

  fConfirmationType := mctNone;

  panelH := LINE_H * MAX_HANDS + 80;

  Panel_PlayerTypes := TKMPopUpPanel.Create(aParent.MasterParent, PANEL_W, panelH + 20, gResTexts[TX_MAPED_PLAYERS_TYPE],
                                            pubgitYellow, False, False);
  top := 0;
  TKMLabel.Create(Panel_PlayerTypes.ItemsPanel,  13, top, 20, 20, '#', fntGrey, taLeft);

  with TKMLabel.Create(Panel_PlayerTypes.ItemsPanel, 33, top, 30, 20, gResTexts[TX_MAPED_PLAYERS_DEFAULT_SHORT], fntGrey, taLeft) do
    Hint := gResTexts[TX_MAPED_PLAYERS_DEFAULT];
  with TKMImage.Create(Panel_PlayerTypes.ItemsPanel,84, top, 60, 20, 588, rxGui) do
    Hint := gResTexts[TX_PLAYER_HUMAN];
  with TKMImage.Create(Panel_PlayerTypes.ItemsPanel,127, top, 20, 20,  62, rxGuiMain) do
    Hint := gResTexts[TX_AI_PLAYER_CLASSIC];
  with TKMImage.Create(Panel_PlayerTypes.ItemsPanel,169, top, 20, 20,  74, rxGuiMain) do
    Hint := gResTexts[TX_AI_PLAYER_ADVANCED];

  Inc(top, 25);
  for I := 0 to MAX_HANDS - 1 do
  begin

    Label_PlayerId[I] := TKMLabel.Create(Panel_PlayerTypes.ItemsPanel,  13, top, 20, 20, IntToStr(I+1), fntOutline, taLeft);

    for MPT := Low(TKMMapEdPlayerType) to High(TKMMapEdPlayerType) do
    begin
      ChkBox_PlayerTypes[I,MPT] := TKMCheckBox.Create(Panel_PlayerTypes.ItemsPanel, 43 + Ord(MPT)*42, top - 2, 20, 20, '', fntMetal);
      ChkBox_PlayerTypes[I,MPT].Tag     := I;
      ChkBox_PlayerTypes[I,MPT].OnClick := Mission_PlayerTypesChange;
    end;

    Button_PlayerMPSetup[I] := TKMButtonFlat.Create(Panel_PlayerTypes.ItemsPanel,
                                                   ChkBox_PlayerTypes[I, mptAdvancedAI].Right + 20, top - 5, BTN_MPSETUP_W, BTN_MPSETUP_W, 678);
    Button_PlayerMPSetup[I].Hint := Format(gResTexts[TX_MAPED_PLAYER_AI_MP_SETUP_HINT],  [I + 1]);
    Button_PlayerMPSetup[I].Tag := I;
    Button_PlayerMPSetup[I].OnClick := PlayerMPSetup_Click;

    Button_PlayerDelete[I] := TKMButtonFlat.Create(Panel_PlayerTypes.ItemsPanel,
                                                   Button_PlayerMPSetup[I].Right + 20, top - 4, BTN_DELETE_W, BTN_DELETE_W, 340);
    Button_PlayerDelete[I].Hint := Format(gResTexts[TX_MAPED_PLAYER_DELETE_HINT], [I + 1]);
    Button_PlayerDelete[I].Tag := I;
    Button_PlayerDelete[I].OnClick := PlayerDelete_Click;

    Inc(top, LINE_H);
  end;

  Label_PlayerTypesAll := TKMLabel.Create(Panel_PlayerTypes.ItemsPanel,  13, top, 75, 20, gResTexts[TX_MAPED_PLAYER_TYPE_ALLOW_ALL],
                                          fntOutline, taLeft);

  for MPT := Low(ChkBox_PlayerTypesAll) to High(ChkBox_PlayerTypesAll) do
  begin
    ChkBox_PlayerTypesAll[MPT] := TKMCheckBox.Create(Panel_PlayerTypes.ItemsPanel, 43 + Ord(MPT)*42, top - 2, 20, 20, '', fntMetal, True);
    ChkBox_PlayerTypesAll[MPT].Tag     := Ord(MPT);
    ChkBox_PlayerTypesAll[MPT].Hint    := Format(gResTexts[TX_MAPED_PLAYER_TYPE_ALLOW_ALL_HINT],
                                               [gResTexts[PLAYER_TYPE_TX[MPT]]]);
    ChkBox_PlayerTypesAll[MPT].OnClick := Mission_PlayerTypesAllClick;
  end;

  Button_Close := TKMButton.Create(Panel_PlayerTypes.ItemsPanel, 15,
                                   Panel_PlayerTypes.ItemsPanel.Height - 40,
                                   PANEL_W - 30, 30, gResTexts[TX_WORD_CLOSE], bsGame);
  Button_Close.Anchors := [anLeft, anRight, anBottom];
  Button_Close.OnClick := ClosePlayerTypes_Click;

  PopUp_Confirm_Player := TKMPopUpMenu.Create(aParent.MasterParent, CONF_W);
  PopUp_Confirm_Player.Height := CONF_H;
  PopUp_Confirm_Player.AnchorsCenter;
  PopUp_Confirm_Player.Left := (aParent.MasterParent.Width div 2) - (PopUp_Confirm_Player.Width div 2);
  PopUp_Confirm_Player.Top := (aParent.MasterParent.Height div 2) - 90;

    TKMBevel.Create(PopUp_Confirm_Player, -2000,  -2000, 5000, 5000);

    Image_Confirm_Player := TKMImage.Create(PopUp_Confirm_Player, 0, 0, PopUp_Confirm_Player.Width, PopUp_Confirm_Player.Height, 15, rxGuiMain);
    Image_Confirm_Player.ImageStretch;

    Label_PlayerConfirmTitle := TKMLabel.Create(PopUp_Confirm_Player, PopUp_Confirm_Player.Width div 2, 40, Format(gResTexts[TX_MAPED_PLAYER_DELETE_TITLE], [0]), fntOutline, taCenter);
    Label_PlayerConfirmTitle.Anchors := [anLeft, anBottom];

    Label_PlayerConfirmWarn := TKMLabel.Create(PopUp_Confirm_Player, 20, 85, PopUp_Confirm_Player.Width - 40, 0, gResTexts[TX_MAPED_PLAYER_DELETE_CONFIRM], fntMetal, taCenter);
    Label_PlayerConfirmWarn.WordWrap := True;
    Label_PlayerConfirmWarn.Anchors := [anLeft, anBottom];

    Button_PlayerConfirm := TKMButton.Create(PopUp_Confirm_Player, ((CONF_W - CONF_BTN_PAD) div 2) - CONF_BTN_W, CONF_H - 50, CONF_BTN_W, 30,
                                             gResTexts[TX_WORD_OK], bsMenu);
    Button_PlayerConfirm.Anchors := [anLeft, anBottom];
    Button_PlayerConfirm.OnClick := PlayerDeleteConfirm_Click;

    Button_PlayerConfirmCancel  := TKMButton.Create(PopUp_Confirm_Player, (CONF_W + CONF_BTN_PAD) div 2, CONF_H - 50, CONF_BTN_W, 30,
                                                    gResTexts[TX_WORD_CANCEL], bsMenu);
    Button_PlayerConfirmCancel.Anchors := [anLeft, anBottom];
    Button_PlayerConfirmCancel.OnClick := PlayerDeleteConfirm_Click;
end;


procedure TKMMapEdMissionPlayers.UpdatePlayerTypes;
var
  I: Integer;
  MPT: TKMMapEdPlayerType;
  enabledCnt, checkedCnt: array [mptHuman..mptAdvancedAI] of Integer;
  hasAssets, isAllEnabled: Boolean;
begin
  gGame.MapEditor.ValidatePlayerTypes;

  for MPT := Low(enabledCnt) to High(enabledCnt) do
  begin
    enabledCnt[MPT] := 0;
    checkedCnt[MPT] := 0;
  end;

  for I := 0 to gHands.Count - 1 do
  begin
    hasAssets := gHands[I].HasAssets;
    ChkBox_PlayerTypes[I, mptDefault].Enabled     := hasAssets;
    ChkBox_PlayerTypes[I, mptHuman].Enabled       := hasAssets and not (gGame.MapEditor.DefaultHuman = I);
    ChkBox_PlayerTypes[I, mptClassicAI].Enabled   := hasAssets;
    ChkBox_PlayerTypes[I, mptAdvancedAI].Enabled  := hasAssets;

    ChkBox_PlayerTypes[I, mptDefault].Checked     := hasAssets and (gGame.MapEditor.DefaultHuman = I);
    ChkBox_PlayerTypes[I, mptHuman].Checked       := hasAssets and gGame.MapEditor.PlayerHuman[I];
    ChkBox_PlayerTypes[I, mptClassicAI].Checked   := hasAssets and gGame.MapEditor.PlayerClassicAI[I];
    ChkBox_PlayerTypes[I, mptAdvancedAI].Checked  := hasAssets and gGame.MapEditor.PlayerAdvancedAI[I];

    for MPT := Low(ChkBox_PlayerTypesAll) to High(ChkBox_PlayerTypesAll) do
    begin
      enabledCnt[MPT] := enabledCnt[MPT] + Byte(ChkBox_PlayerTypes[I, MPT].Enabled);
      checkedCnt[MPT] := checkedCnt[MPT] + Byte(ChkBox_PlayerTypes[I, MPT].Checked
                                        and ChkBox_PlayerTypes[I, MPT].Enabled);
    end;

    Button_PlayerMPSetup[I].Enabled := hasAssets;
    Button_PlayerDelete[I].Enabled := hasAssets;
  end;

  isAllEnabled := False;
  for MPT := Low(ChkBox_PlayerTypesAll) to High(ChkBox_PlayerTypesAll) do
  begin
    ChkBox_PlayerTypesAll[MPT].Enabled := enabledCnt[MPT] > 0;
    isAllEnabled := isAllEnabled or ChkBox_PlayerTypesAll[MPT].Enabled;

    //Uncheck if all are unchecked and disabled
    if not ChkBox_PlayerTypesAll[MPT].Enabled
      and (checkedCnt[MPT] = 0) then
      ChkBox_PlayerTypesAll[MPT].Uncheck;

    if enabledCnt[MPT] > 0 then
    begin

      if checkedCnt[MPT] = 0 then
        ChkBox_PlayerTypesAll[MPT].Uncheck //Uncheck if all is unchecked
      else
      if checkedCnt[MPT] >= enabledCnt[MPT] then
        ChkBox_PlayerTypesAll[MPT].Check //Check if all checked
      else
        ChkBox_PlayerTypesAll[MPT].SemiCheck; //SemiCheck in other cases
    end;
    if ChkBox_PlayerTypesAll[MPT].Checked then
      ChkBox_PlayerTypesAll[MPT].Hint := Format(gResTexts[TX_MAPED_PLAYER_TYPE_DISALLOW_ALL_HINT],
                                              [gResTexts[PLAYER_TYPE_TX[MPT]]])
    else
      ChkBox_PlayerTypesAll[MPT].Hint := Format(gResTexts[TX_MAPED_PLAYER_TYPE_ALLOW_ALL_HINT],
                                              [gResTexts[PLAYER_TYPE_TX[MPT]]]);
  end;
  Label_PlayerTypesAll.Enabled := isAllEnabled;
end;


procedure TKMMapEdMissionPlayers.DoConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Assert(fConfirmationType <> mctNone);
    case fConfirmationType of
      mctMPSetup:      begin
                         Label_PlayerConfirmTitle.Caption := Format(gResTexts[TX_MAPED_PLAYER_AI_MP_SETUP_CONFIRM_TITLE], [fPlayerIdToConfirm + 1]);
                         Label_PlayerConfirmWarn.Caption := Format(gResTexts[TX_MAPED_PLAYER_AI_MP_SETUP_CONFIRM], [fPlayerIdToConfirm + 1]);
                       end;
      mctDeletePlayer: begin
                         Label_PlayerConfirmTitle.Caption := Format(gResTexts[TX_MAPED_PLAYER_DELETE_TITLE], [fPlayerIdToConfirm + 1]);
                         Label_PlayerConfirmWarn.Caption := gResTexts[TX_MAPED_PLAYER_DELETE_CONFIRM];
                       end;
    end;

    PopUp_Confirm_Player.Show;
  end else
    PopUp_Confirm_Player.Hide;
end;


procedure TKMMapEdMissionPlayers.PlayerDelete_Click(Sender: TObject);
var
  playerId: Integer;
begin
  playerId := TKMButtonFlat(Sender).Tag;

  if Sender = Button_PlayerDelete[playerId] then
  begin
    fPlayerIdToConfirm := playerId;
    fConfirmationType := mctDeletePlayer;
    DoConfirm(True);
  end;
end;


procedure TKMMapEdMissionPlayers.PlayerDeleteConfirm_Click(Sender: TObject);
begin
  if Sender = Button_PlayerConfirmCancel then
    DoConfirm(False);

  if Sender = Button_PlayerConfirm then
  begin
    case fConfirmationType of
      mctMPSetup:       gGame.MapEditor.ApplyAIMultiplayerSetup(fPlayerIdToConfirm);
      mctDeletePlayer:  gGame.MapEditor.DeletePlayer(fPlayerIdToConfirm);
    end;

    DoConfirm(False);

    Mission_PlayerIdUpdate;
    UpdatePlayerTypes;
  end;
end;


procedure TKMMapEdMissionPlayers.PlayerMPSetup_Click(Sender: TObject);
var
  playerId: Integer;
begin
  playerId := TKMButtonFlat(Sender).Tag;

  if Sender = Button_PlayerMPSetup[playerId] then
  begin
    fPlayerIdToConfirm := playerId;
    fConfirmationType := mctMPSetup;
    DoConfirm(True);
  end;
end;


procedure TKMMapEdMissionPlayers.ClosePlayerTypes_Click(Sender: TObject);
begin
  Hide;
end;


procedure TKMMapEdMissionPlayers.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  if not Visible then Exit;

  // Handle only VK_ESCAPE
  if Key <> VK_ESCAPE then Exit;

  aHandled := True;

  if PopUp_Confirm_Player.Visible then
    PopUp_Confirm_Player.Hide //Hide 'delete player' confirmation dialog
  else
    Hide;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesAllClick(Sender: TObject);
var
  I: Integer;
  MPT: TKMMapEdPlayerType;
  checked: Boolean;
begin
  MPT := TKMMapEdPlayerType(TKMCheckBox(Sender).Tag);

  for I := 0 to MAX_HANDS - 1 do
  begin
    if not ChkBox_PlayerTypes[I, MPT].IsClickable then
      Continue;

    checked := TKMCheckBox(Sender).Checked;

    ChkBox_PlayerTypes[I, MPT].SetChecked(checked);
    case MPT of
      mptHuman:       gGame.MapEditor.PlayerHuman[I] := checked;
      mptClassicAI:   gGame.MapEditor.PlayerClassicAI[I] := checked;
      mptAdvancedAI:  gGame.MapEditor.PlayerAdvancedAI[I] := checked;
    end;
  end;

  UpdatePlayerTypes;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesChange(Sender: TObject);
var
  playerId: Integer;
begin
  playerId := TKMCheckBox(Sender).Tag;

  //There should be exactly one default human player
  if Sender = ChkBox_PlayerTypes[playerId, mptDefault] then
  begin
    gGame.MapEditor.DefaultHuman := playerId;
    gGame.MapEditor.PlayerHuman[playerId] := True;
  end;

  if Sender = ChkBox_PlayerTypes[playerId, mptHuman] then
  begin
    gGame.MapEditor.PlayerHuman[playerId] := ChkBox_PlayerTypes[playerId, mptHuman].Checked;
    //User cannot set player type undetermined
    if not ChkBox_PlayerTypes[playerId, mptHuman].Checked
        and not ChkBox_PlayerTypes[playerId, mptClassicAI].Checked
        and not ChkBox_PlayerTypes[playerId, mptAdvancedAI].Checked then
        gGame.MapEditor.PlayerClassicAI[playerId] := True;
  end;

  if (Sender = ChkBox_PlayerTypes[playerId, mptClassicAI])
    or (Sender = ChkBox_PlayerTypes[playerId, mptAdvancedAI]) then
  begin
    gGame.MapEditor.PlayerClassicAI[playerId] := ChkBox_PlayerTypes[playerId, mptClassicAI].Checked;
    gGame.MapEditor.PlayerAdvancedAI[playerId] := ChkBox_PlayerTypes[playerId, mptAdvancedAI].Checked;
    if not ChkBox_PlayerTypes[playerId, mptHuman].Checked then
    begin
      //User cannot set player type undetermined
      if not ChkBox_PlayerTypes[playerId, mptClassicAI].Checked
        and not ChkBox_PlayerTypes[playerId, mptAdvancedAI].Checked then
        gGame.MapEditor.PlayerHuman[playerId] := True;
      //Can't be 2 default AI types (without human)
//      if CheckBox_PlayerTypes[PlayerId, mptClassicAI].Checked
//        and CheckBox_PlayerTypes[PlayerId, mptAdvancedAI].Checked then
//      begin
//        if (Sender = CheckBox_PlayerTypes[PlayerId, mptClassicAI]) then
//          gGame.MapEditor.PlayerAdvancedAI[PlayerId] := False
//        else
//          gGame.MapEditor.PlayerClassicAI[PlayerId] := False;
//      end;
    end;
  end;

  UpdatePlayerTypes;
end;

procedure TKMMapEdMissionPlayers.Mission_PlayerIdUpdate;
var
  I: Integer;
begin
  for I := 0 to MAX_HANDS - 1 do
    if I < gHands.Count then
    begin
      Label_PlayerId[I].Enabled := gHands[I].HasAssets;
      Button_PlayerMPSetup[I].Enabled := gHands[I].HasAssets;
      Button_PlayerDelete[I].Enabled := gHands[I].HasAssets;
    end;
end;


procedure TKMMapEdMissionPlayers.Hide;
begin
  Panel_PlayerTypes.Hide;
end;


procedure TKMMapEdMissionPlayers.Show;
begin
  UpdatePlayerTypes;
  Mission_PlayerIdUpdate;
  Panel_PlayerTypes.Show;
end;


function TKMMapEdMissionPlayers.Visible: Boolean;
begin
  Result := Panel_PlayerTypes.Visible;
end;


end.

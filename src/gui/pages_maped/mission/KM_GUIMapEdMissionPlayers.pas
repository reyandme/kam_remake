unit KM_GUIMapEdMissionPlayers;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Controls, KM_Defaults, KM_Pics;

type
  TKMMapEdMissionPlayers = class
  private
    PopUp_Confirm_PlayerClear: TKMPopUpMenu;
    Image_Confirm_PlayerClear: TKMImage;
    Button_PlayerClearConfirm, Button_PlayerClearCancel: TKMButton;
    Label_PlayerClearConfirmTitle, Label_PlayerClearConfirm: TKMLabel;

    procedure Mission_PlayerTypesChange(Sender: TObject);
    procedure Mission_PlayerTypesUpdate;
    procedure Mission_PlayerIdUpdate;
    procedure PlayerClear_Click(Sender: TObject);
    procedure PlayerClearConfirm(aVisible: Boolean);
  protected
    Panel_PlayerTypes: TKMPanel;
    CheckBox_PlayerTypes: array [0..MAX_HANDS-1, 0..2] of TKMCheckBox;
    Label_PlayerId : array [0..MAX_HANDS-1] of TKMLabel;
    Button_PlayerClear: TKMButton;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    function Visible: Boolean;
    procedure Hide;

    procedure ChangePlayer;
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_Game, KM_RenderUI, KM_ResFonts, KM_InterfaceGame,
  KM_Hand;


constructor TKMMapEdMissionPlayers.Create(aParent: TKMPanel);
var
  I,K: Integer;
begin
  inherited Create;

  Panel_PlayerTypes := TKMPanel.Create(aParent, 0, 28, TB_WIDTH, 400);
  TKMLabel.Create(Panel_PlayerTypes, 0, PAGE_TITLE_Y, TB_WIDTH, 0, gResTexts[TX_MAPED_PLAYERS_TYPE], fnt_Outline, taCenter);
  TKMLabel.Create(Panel_PlayerTypes,  4, 30, 20, 20, '#',       fnt_Grey, taLeft);
  TKMLabel.Create(Panel_PlayerTypes, 24, 30, 60, 20, gResTexts[TX_MAPED_PLAYERS_DEFAULT], fnt_Grey, taLeft);
  TKMImage.Create(Panel_PlayerTypes,102, 30, 60, 20, 588, rxGui);
  TKMImage.Create(Panel_PlayerTypes,164, 30, 20, 20,  62, rxGuiMain);
  for I := 0 to MAX_HANDS - 1 do
  begin                                                         //   25
    Label_PlayerId[i] := TKMLabel.Create(Panel_PlayerTypes,  4, 50+I*23, 20, 20, IntToStr(I+1), fnt_Outline, taLeft);

    for K := 0 to 2 do
    begin
      CheckBox_PlayerTypes[I,K] := TKMCheckBox.Create(Panel_PlayerTypes, 44+K*60, 48+I*23, 20, 20, '', fnt_Metal);
      CheckBox_PlayerTypes[I,K].Tag       := I;
      CheckBox_PlayerTypes[I,K].OnClick   := Mission_PlayerTypesChange;
    end;
  end;

  Button_PlayerClear := TKMButton.Create(Panel_PlayerTypes, 4, 325, TB_WIDTH - 4, 26, Format(gResTexts[TX_NENU_PLAYER_CLEAR], [1]), bsMenu);
  Button_PlayerClear.OnClick := PlayerClear_Click;

  PopUp_Confirm_PlayerClear := TKMPopUpMenu.Create(aParent.MasterParent, 400);
  PopUp_Confirm_PlayerClear.Height := 200;
  PopUp_Confirm_PlayerClear.AnchorsCenter;
  PopUp_Confirm_PlayerClear.Left := (aParent.MasterParent.Width div 2) - (PopUp_Confirm_PlayerClear.Width div 2);
  PopUp_Confirm_PlayerClear.Top := (aParent.MasterParent.Height div 2) - 90;

    TKMBevel.Create(PopUp_Confirm_PlayerClear, -1000,  -1000, 4000, 4000);

    Image_Confirm_PlayerClear := TKMImage.Create(PopUp_Confirm_PlayerClear, 0, 0, PopUp_Confirm_PlayerClear.Width, PopUp_Confirm_PlayerClear.Height, 15, rxGuiMain);
    Image_Confirm_PlayerClear.ImageStretch;

    Label_PlayerClearConfirmTitle := TKMLabel.Create(PopUp_Confirm_PlayerClear, PopUp_Confirm_PlayerClear.Width div 2, 40, Format(gResTexts[TX_NENU_PLAYER_CLEAR_TITLE], [0]), fnt_Outline, taCenter);
    Label_PlayerClearConfirmTitle.Anchors := [anLeft, anBottom];

    Label_PlayerClearConfirm := TKMLabel.Create(PopUp_Confirm_PlayerClear, PopUp_Confirm_PlayerClear.Width div 2, 85, gResTexts[TX_NENU_PLAYER_CLEAR_CONFIRM], fnt_Metal, taCenter);
    Label_PlayerClearConfirm.Anchors := [anLeft, anBottom];

    Button_PlayerClearConfirm := TKMButton.Create(PopUp_Confirm_PlayerClear, 20, 155, 170, 30, gResTexts[TX_WORD_CLEAR], bsMenu);
    Button_PlayerClearConfirm.Anchors := [anLeft, anBottom];
    Button_PlayerClearConfirm.OnClick := PlayerClear_Click;

    Button_PlayerClearCancel  := TKMButton.Create(PopUp_Confirm_PlayerClear, PopUp_Confirm_PlayerClear.Width - 190, 155, 170, 30, gResTexts[TX_WORD_CANCEL], bsMenu);
    Button_PlayerClearCancel.Anchors := [anLeft, anBottom];
    Button_PlayerClearCancel.OnClick := PlayerClear_Click;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesUpdate;
var I: Integer;
begin
  for I := 0 to gHands.Count - 1 do
  begin
    CheckBox_PlayerTypes[I, 0].Enabled := gHands[I].HasAssets;
    CheckBox_PlayerTypes[I, 1].Enabled := gHands[I].HasAssets;
    CheckBox_PlayerTypes[I, 2].Enabled := gHands[I].HasAssets;

    CheckBox_PlayerTypes[I, 0].Checked := gHands[I].HasAssets and (gGame.MapEditor.DefaultHuman = I);
    CheckBox_PlayerTypes[I, 1].Checked := gHands[I].HasAssets and gGame.MapEditor.PlayerHuman[I];
    CheckBox_PlayerTypes[I, 2].Checked := gHands[I].HasAssets and gGame.MapEditor.PlayerAI[I];
  end;
end;


procedure TKMMapEdMissionPlayers.PlayerClearConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Label_PlayerClearConfirmTitle.Caption := Format(gResTexts[TX_NENU_PLAYER_CLEAR_TITLE], [gMySpectator.HandIndex + 1]);
    PopUp_Confirm_PlayerClear.Show;

  end else begin
    PopUp_Confirm_PlayerClear.Hide;

  end;
end;


procedure TKMMapEdMissionPlayers.PlayerClear_Click(Sender: TObject);
begin

  if Sender = Button_PlayerClear then
    PlayerClearConfirm(True);

  if Sender = Button_PlayerClearCancel then
    PlayerClearConfirm(False);

  if Sender = Button_PlayerClearConfirm then
  begin
    gGame.MapEditor.ClearObjectsPlayer(gMySpectator.HandIndex);
    PlayerClearConfirm(False);
    Mission_PlayerIdUpdate;
  end;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesChange(Sender: TObject);
var PlayerId: Integer;
begin
  PlayerId := TKMCheckBox(Sender).Tag;

  //There should be exactly one default human player
  if Sender = CheckBox_PlayerTypes[PlayerId, 0] then
    gGame.MapEditor.DefaultHuman := PlayerId;


  if Sender = CheckBox_PlayerTypes[PlayerId, 1] then
  begin
    gGame.MapEditor.PlayerHuman[PlayerId] := CheckBox_PlayerTypes[PlayerId, 1].Checked;
    //User cannot set player type undetermined
    if (not CheckBox_PlayerTypes[PlayerId, 1].Checked)
        and (not CheckBox_PlayerTypes[PlayerId, 2].Checked) then
        gGame.MapEditor.PlayerAI[PlayerId] := true;
  end;

  if Sender = CheckBox_PlayerTypes[PlayerId, 2] then
  begin
    gGame.MapEditor.PlayerAI[PlayerId] := CheckBox_PlayerTypes[PlayerId, 2].Checked;
    //User cannot set player type undetermined
    if (not CheckBox_PlayerTypes[PlayerId, 1].Checked)
        and (not CheckBox_PlayerTypes[PlayerId, 2].Checked) then
        gGame.MapEditor.PlayerHuman[PlayerId] := true;
  end;

  Mission_PlayerTypesUpdate;
end;

procedure TKMMapEdMissionPlayers.Mission_PlayerIdUpdate;
var I : integer;
begin
  Button_PlayerClear.Enabled := gHands[gMySpectator.HandIndex].HasAssets;
  ChangePlayer;

  for I := 0 to MAX_HANDS - 1 do
    if I < gHands.Count then
      if gHands[I].HasAssets then
        Label_PlayerId[i].FontColor := $FFFFFFFF
      else
        Label_PlayerId[i].FontColor := $FF808080;
end;


procedure TKMMapEdMissionPlayers.ChangePlayer;
begin
  Button_PlayerClear.Caption := Format(gResTexts[TX_NENU_PLAYER_CLEAR], [gMySpectator.HandIndex + 1]);
end;


procedure TKMMapEdMissionPlayers.Hide;
begin
  Panel_PlayerTypes.Hide;
end;


procedure TKMMapEdMissionPlayers.Show;
begin
  Mission_PlayerTypesUpdate;
  Mission_PlayerIdUpdate;
  Panel_PlayerTypes.Show;
end;


function TKMMapEdMissionPlayers.Visible: Boolean;
begin
  Result := Panel_PlayerTypes.Visible;
end;


end.

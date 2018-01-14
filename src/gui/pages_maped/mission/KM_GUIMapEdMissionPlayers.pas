unit KM_GUIMapEdMissionPlayers;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Controls, KM_Defaults, KM_Pics;

type
  TKMMapEdMissionPlayers = class
  private
    procedure Mission_PlayerTypesChange(Sender: TObject);
    procedure Mission_PlayerTypesUpdate;
    procedure Mission_PlayerIdUpdate;
    procedure PlayerDelete_Click(Sender: TObject);
    procedure PlayerDeleteConfirm(aVisible: Boolean);
  protected
    Panel_PlayerTypes: TKMPanel;
    CheckBox_PlayerTypes: array [0..MAX_HANDS-1, 0..2] of TKMCheckBox;
    Label_PlayerId : array [0..MAX_HANDS-1] of TKMLabel;

    PopUp_Confirm_PlayerDelete: TKMPopUpMenu;
    Image_Confirm_PlayerDelete: TKMImage;
    Button_PlayerDelete, Button_PlayerDeleteConfirm, Button_PlayerDeleteCancel: TKMButton;
    Label_PlayerDeleteConfirmTitle, Label_PlayerDeleteConfirm: TKMLabel;
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


{ TKMMapEdMissionPlayers }
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

  Button_PlayerDelete := TKMButton.Create(Panel_PlayerTypes, 4, 325, TB_WIDTH - 4, 26, Format(gResTexts[TX_MAPED_PLAYER_DELETE], [1]), bsMenu);
  Button_PlayerDelete.OnClick := PlayerDelete_Click;

  PopUp_Confirm_PlayerDelete := TKMPopUpMenu.Create(aParent.MasterParent, 400);
  PopUp_Confirm_PlayerDelete.Height := 200;
  PopUp_Confirm_PlayerDelete.AnchorsCenter;
  PopUp_Confirm_PlayerDelete.Left := (aParent.MasterParent.Width div 2) - (PopUp_Confirm_PlayerDelete.Width div 2);
  PopUp_Confirm_PlayerDelete.Top := (aParent.MasterParent.Height div 2) - 90;

    TKMBevel.Create(PopUp_Confirm_PlayerDelete, -1000,  -1000, 4000, 4000);

    Image_Confirm_PlayerDelete := TKMImage.Create(PopUp_Confirm_PlayerDelete, 0, 0, PopUp_Confirm_PlayerDelete.Width, PopUp_Confirm_PlayerDelete.Height, 15, rxGuiMain);
    Image_Confirm_PlayerDelete.ImageStretch;

    Label_PlayerDeleteConfirmTitle := TKMLabel.Create(PopUp_Confirm_PlayerDelete, PopUp_Confirm_PlayerDelete.Width div 2, 40, Format(gResTexts[TX_MAPED_PLAYER_DELETE_TITLE], [0]), fnt_Outline, taCenter);
    Label_PlayerDeleteConfirmTitle.Anchors := [anLeft, anBottom];

    Label_PlayerDeleteConfirm := TKMLabel.Create(PopUp_Confirm_PlayerDelete, PopUp_Confirm_PlayerDelete.Width div 2, 85, gResTexts[TX_MAPED_PLAYER_DELETE_CONFIRM], fnt_Metal, taCenter);
    Label_PlayerDeleteConfirm.Anchors := [anLeft, anBottom];

    Button_PlayerDeleteConfirm := TKMButton.Create(PopUp_Confirm_PlayerDelete, 20, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_DELETE], bsMenu);
    Button_PlayerDeleteConfirm.Anchors := [anLeft, anBottom];
    Button_PlayerDeleteConfirm.OnClick := PlayerDelete_Click;

    Button_PlayerDeleteCancel  := TKMButton.Create(PopUp_Confirm_PlayerDelete, PopUp_Confirm_PlayerDelete.Width - 190, 155, 170, 30, gResTexts[TX_WORD_CANCEL], bsMenu);
    Button_PlayerDeleteCancel.Anchors := [anLeft, anBottom];
    Button_PlayerDeleteCancel.OnClick := PlayerDelete_Click;
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


procedure TKMMapEdMissionPlayers.PlayerDeleteConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Label_PlayerDeleteConfirmTitle.Caption := Format(gResTexts[TX_MAPED_PLAYER_DELETE_TITLE], [gMySpectator.HandIndex + 1]);
    PopUp_Confirm_PlayerDelete.Show;

  end else begin
    PopUp_Confirm_PlayerDelete.Hide;

  end;
end;


procedure TKMMapEdMissionPlayers.PlayerDelete_Click(Sender: TObject);
begin

  if Sender = Button_PlayerDelete then
    PlayerDeleteConfirm(True);

  if Sender = Button_PlayerDeleteCancel then
    PlayerDeleteConfirm(False);

  if Sender = Button_PlayerDeleteConfirm then
  begin
    gGame.MapEditor.DeletePlayer(gMySpectator.HandIndex);
    PlayerDeleteConfirm(False);
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
  Button_PlayerDelete.Enabled := gHands[gMySpectator.HandIndex].HasAssets;
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
  Button_PlayerDelete.Caption := Format(gResTexts[TX_MAPED_PLAYER_DELETE], [gMySpectator.HandIndex + 1]);
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

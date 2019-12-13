unit KM_GUIMapEdMissionPlayers;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, SysUtils,
  KM_Controls, KM_Defaults, KM_Pics;

type
  TKMMapEdMissionPlayers = class
  private
    fPlayerIdToDelete: TKMHandID;

    procedure Mission_PlayerTypesChange(Sender: TObject);
    procedure Mission_PlayerTypesAllClick(Sender: TObject);
    procedure Mission_PlayerTypesUpdate;
    procedure Mission_PlayerIdUpdate;
    procedure PlayerDelete_Click(Sender: TObject);
    procedure ClosePlayerTypes_Click(Sender: TObject);

    procedure PlayerDeleteConfirm(aVisible: Boolean);
  protected
    Panel_PlayerTypes: TKMPopUpPanel;
      ChkBox_PlayerTypes: array [0..MAX_HANDS-1, 0..3] of TKMCheckBox;
      ChkBox_PlayerTypesAll: array [0..2] of TKMCheckBox;
      Label_PlayerTypesAll: TKMLabel;
      Label_PlayerId: array [0..MAX_HANDS-1] of TKMLabel;
      Button_Close: TKMButton;

    PopUp_Confirm_PlayerDelete: TKMPopUpMenu;
      Image_Confirm_PlayerDelete: TKMImage;
      Button_PlayerDelete, Button_PlayerDeleteConfirm, Button_PlayerDeleteCancel: TKMButton;
      Label_PlayerDeleteConfirmTitle, Label_PlayerDeleteConfirm: TKMLabel;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure Show;
    function Visible: Boolean;
    procedure Hide;

    procedure UpdatePlayer(aIndex: TKMHandID = -1);
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_Game, KM_RenderUI, KM_ResFonts, KM_InterfaceGame,
  KM_Hand;

const
  PANEL_W  = 200;
  LINE_H = 22;
  ICON_SPACE_W = 25;
  ICON_SPACE_H = 32;

  PLAYER_TYPE_TX: array [0..2] of Integer = (TX_PLAYER_HUMAN, TX_AI_PLAYER_CLASSIC, TX_AI_PLAYER_ADVANCED);

{ TKMMapEdMissionPlayers }
constructor TKMMapEdMissionPlayers.Create(aParent: TKMPanel);
var
  I,K, Top, PanelH: Integer;
begin
  inherited Create;

  fPlayerIdToDelete := -1;

  PanelH := LINE_H * MAX_HANDS + 140;

  Panel_PlayerTypes := TKMPopUpPanel.Create(aParent.MasterParent, PANEL_W, PanelH + 20, gResTexts[TX_MAPED_PLAYERS_TYPE],
                                            pubgitYellowish, False);
  Panel_PlayerTypes.Height := PanelH;

  Top := 0;
  TKMLabel.Create(Panel_PlayerTypes,  13, Top, 20, 20, '#', fntGrey, taLeft);

  with TKMLabel.Create(Panel_PlayerTypes, 33, Top, 30, 20, gResTexts[TX_MAPED_PLAYERS_DEFAULT_SHORT], fntGrey, taLeft) do
    Hint := gResTexts[TX_MAPED_PLAYERS_DEFAULT];
  with TKMImage.Create(Panel_PlayerTypes,84, Top, 60, 20, 588, rxGui) do
    Hint := gResTexts[TX_PLAYER_HUMAN];
  with TKMImage.Create(Panel_PlayerTypes,127, Top, 20, 20,  62, rxGuiMain) do
    Hint := gResTexts[TX_AI_PLAYER_CLASSIC];
  with TKMImage.Create(Panel_PlayerTypes,169, Top, 20, 20,  74, rxGuiMain) do
    Hint := gResTexts[TX_AI_PLAYER_ADVANCED];

  Inc(Top, 25);
  for I := 0 to MAX_HANDS - 1 do
  begin

    Label_PlayerId[I] := TKMLabel.Create(Panel_PlayerTypes,  13, Top, 20, 20, IntToStr(I+1), fntOutline, taLeft);

    for K := 0 to 3 do
    begin
      ChkBox_PlayerTypes[I,K] := TKMCheckBox.Create(Panel_PlayerTypes, 43 + K*42, Top - 2, 20, 20, '', fntMetal);
      ChkBox_PlayerTypes[I,K].Tag     := I;
      ChkBox_PlayerTypes[I,K].OnClick := Mission_PlayerTypesChange;
    end;
    Inc(Top, LINE_H);
  end;

  Label_PlayerTypesAll := TKMLabel.Create(Panel_PlayerTypes,  13, Top, 75, 20, gResTexts[TX_MAPED_PLAYER_TYPE_ALLOW_ALL],
                                          fntOutline, taLeft);

  for K := 0 to 2 do
  begin
    ChkBox_PlayerTypesAll[K] := TKMCheckBox.Create(Panel_PlayerTypes, 43 + (K+1)*42, Top - 2, 20, 20, '', fntMetal, True);
    ChkBox_PlayerTypesAll[K].Tag     := K + 1;
    ChkBox_PlayerTypesAll[K].Hint    := Format(gResTexts[TX_MAPED_PLAYER_TYPE_ALLOW_ALL_HINT],
                                               [gResTexts[PLAYER_TYPE_TX[K]]]);
    ChkBox_PlayerTypesAll[K].OnClick := Mission_PlayerTypesAllClick;
  end;
  Inc(Top, 30);

  Button_PlayerDelete := TKMButton.Create(Panel_PlayerTypes, 15, Top, PANEL_W - 30, 26,
                                          Format(gResTexts[TX_MAPED_PLAYER_DELETE], [1]), bsGame);
  Button_PlayerDelete.OnClick := PlayerDelete_Click;

  Button_Close := TKMButton.Create(Panel_PlayerTypes, 15,
                                            Panel_PlayerTypes.Height - 40,
                                            PANEL_W - 30, 30, gResTexts[TX_WORD_CLOSE], bsGame);
  Button_Close.OnClick := ClosePlayerTypes_Click;

  PopUp_Confirm_PlayerDelete := TKMPopUpMenu.Create(aParent.MasterParent, 450);
  PopUp_Confirm_PlayerDelete.Height := 200;
  PopUp_Confirm_PlayerDelete.AnchorsCenter;
  PopUp_Confirm_PlayerDelete.Left := (aParent.MasterParent.Width div 2) - (PopUp_Confirm_PlayerDelete.Width div 2);
  PopUp_Confirm_PlayerDelete.Top := (aParent.MasterParent.Height div 2) - 90;

    TKMBevel.Create(PopUp_Confirm_PlayerDelete, -1000,  -1000, 4000, 4000);

    Image_Confirm_PlayerDelete := TKMImage.Create(PopUp_Confirm_PlayerDelete, 0, 0, PopUp_Confirm_PlayerDelete.Width, PopUp_Confirm_PlayerDelete.Height, 15, rxGuiMain);
    Image_Confirm_PlayerDelete.ImageStretch;

    Label_PlayerDeleteConfirmTitle := TKMLabel.Create(PopUp_Confirm_PlayerDelete, PopUp_Confirm_PlayerDelete.Width div 2, 40, Format(gResTexts[TX_MAPED_PLAYER_DELETE_TITLE], [0]), fntOutline, taCenter);
    Label_PlayerDeleteConfirmTitle.Anchors := [anLeft, anBottom];

    Label_PlayerDeleteConfirm := TKMLabel.Create(PopUp_Confirm_PlayerDelete, 20, 85, PopUp_Confirm_PlayerDelete.Width - 40, 0, gResTexts[TX_MAPED_PLAYER_DELETE_CONFIRM], fntMetal, taCenter);
    Label_PlayerDeleteConfirm.Anchors := [anLeft, anBottom];

    Button_PlayerDeleteConfirm := TKMButton.Create(PopUp_Confirm_PlayerDelete, 20, 155, 170, 30, gResTexts[TX_MENU_LOAD_DELETE_DELETE], bsMenu);
    Button_PlayerDeleteConfirm.Anchors := [anLeft, anBottom];
    Button_PlayerDeleteConfirm.OnClick := PlayerDelete_Click;

    Button_PlayerDeleteCancel  := TKMButton.Create(PopUp_Confirm_PlayerDelete, PopUp_Confirm_PlayerDelete.Width - 190, 155, 170, 30, gResTexts[TX_WORD_CANCEL], bsMenu);
    Button_PlayerDeleteCancel.Anchors := [anLeft, anBottom];
    Button_PlayerDeleteCancel.OnClick := PlayerDelete_Click;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesUpdate;
var
  I, K: Integer;
  EnabledCnt, CheckedCnt: array [0..2] of Integer;
  HasAssets, IsAllEnabled, HasDefault: Boolean;
begin
  for K := Low(EnabledCnt) to High(EnabledCnt) do
  begin
    EnabledCnt[K] := 0;
    CheckedCnt[K] := 0;
  end;

  HasDefault := False;

  for I := 0 to gHands.Count - 1 do
  begin
    HasAssets := gHands[I].HasAssets;
    ChkBox_PlayerTypes[I, 0].Enabled := HasAssets;
    ChkBox_PlayerTypes[I, 1].Enabled := HasAssets and not (gGame.MapEditor.DefaultHuman = I);
    ChkBox_PlayerTypes[I, 2].Enabled := HasAssets;
    ChkBox_PlayerTypes[I, 3].Enabled := HasAssets;

    ChkBox_PlayerTypes[I, 0].Checked := HasAssets and (gGame.MapEditor.DefaultHuman = I);
    ChkBox_PlayerTypes[I, 1].Checked := HasAssets and gGame.MapEditor.PlayerHuman[I];
    ChkBox_PlayerTypes[I, 2].Checked := HasAssets and gGame.MapEditor.PlayerClassicAI[I];
    ChkBox_PlayerTypes[I, 3].Checked := HasAssets and gGame.MapEditor.PlayerAdvancedAI[I];

    HasDefault := HasDefault or ChkBox_PlayerTypes[I, 0].Checked;

    for K := 0 to 2 do
    begin
      EnabledCnt[K] := EnabledCnt[K] + Byte(ChkBox_PlayerTypes[I, K + 1].Enabled);
      CheckedCnt[K] := CheckedCnt[K] + Byte(ChkBox_PlayerTypes[I, K + 1].Checked
                                        and ChkBox_PlayerTypes[I, K + 1].Enabled);
    end;
  end;

  //No default human player choosen
  if not HasDefault then
  begin
    //Try to find first human to set him as default
    for I := 0 to gHands.Count - 1 do
    begin
      if ChkBox_PlayerTypes[I, 1].Checked then
      begin
        ChkBox_PlayerTypes[I, 0].Check;
        ChkBox_PlayerTypes[I, 1].Disable;
        gGame.MapEditor.DefaultHuman := I;
        HasDefault := True;
        Break;
      end;
    end;
    //Stil no default is set (no humans)
    //Find first hand and set it as enabled for humans and as default
    if not HasDefault then
      for I := 0 to gHands.Count - 1 do
        if gHands[I].HasAssets then
        begin
          ChkBox_PlayerTypes[I, 0].Check; //Default human
          ChkBox_PlayerTypes[I, 1].Check; //Human
          ChkBox_PlayerTypes[I, 1].Disable;
          gGame.MapEditor.DefaultHuman := I;
          Break;
        end;
  end;

  IsAllEnabled := False;
  for K := 0 to 2 do
  begin
    ChkBox_PlayerTypesAll[K].Enabled := EnabledCnt[K] > 0;
    IsAllEnabled := IsAllEnabled or ChkBox_PlayerTypesAll[K].Enabled;

    //Uncheck if all are unchecked and disabled
    if not ChkBox_PlayerTypesAll[K].Enabled
      and (CheckedCnt[K] = 0) then
      ChkBox_PlayerTypesAll[K].Uncheck;

    if EnabledCnt[K] > 0 then
    begin

      if CheckedCnt[K] = 0 then
        ChkBox_PlayerTypesAll[K].Uncheck //Uncheck if all is unchecked
      else
      if CheckedCnt[K] >= EnabledCnt[K] then
        ChkBox_PlayerTypesAll[K].Check //Check if all checked
      else
        ChkBox_PlayerTypesAll[K].SemiCheck; //SemiCheck in other cases
    end;
    if ChkBox_PlayerTypesAll[K].Checked then
      ChkBox_PlayerTypesAll[K].Hint := Format(gResTexts[TX_MAPED_PLAYER_TYPE_DISALLOW_ALL_HINT],
                                              [gResTexts[PLAYER_TYPE_TX[K]]])
    else
      ChkBox_PlayerTypesAll[K].Hint := Format(gResTexts[TX_MAPED_PLAYER_TYPE_ALLOW_ALL_HINT],
                                              [gResTexts[PLAYER_TYPE_TX[K]]]);
  end;
  Label_PlayerTypesAll.Enabled := IsAllEnabled;
end;


procedure TKMMapEdMissionPlayers.PlayerDeleteConfirm(aVisible: Boolean);
begin
  if aVisible then
  begin
    Label_PlayerDeleteConfirmTitle.Caption := Format(gResTexts[TX_MAPED_PLAYER_DELETE_TITLE], [fPlayerIdToDelete + 1]);
    PopUp_Confirm_PlayerDelete.Show;
  end else
    PopUp_Confirm_PlayerDelete.Hide;
end;


procedure TKMMapEdMissionPlayers.PlayerDelete_Click(Sender: TObject);
begin
  if Sender = Button_PlayerDelete then
    PlayerDeleteConfirm(True);

  if Sender = Button_PlayerDeleteCancel then
    PlayerDeleteConfirm(False);

  if Sender = Button_PlayerDeleteConfirm then
  begin
    gGame.MapEditor.DeletePlayer(fPlayerIdToDelete);
    PlayerDeleteConfirm(False);

    Mission_PlayerIdUpdate;
    Mission_PlayerTypesUpdate;
  end;
end;


procedure TKMMapEdMissionPlayers.ClosePlayerTypes_Click(Sender: TObject);
begin
  Hide;
end;


procedure TKMMapEdMissionPlayers.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  aHandled := False;
  if (Key = VK_ESCAPE) and Visible then
  begin
    Hide;
    aHandled := True;
  end;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesAllClick(Sender: TObject);
var
  I, K: Integer;
  Checked: Boolean;
begin
  K := TKMCheckBox(Sender).Tag;

  for I := 0 to MAX_HANDS - 1 do
  begin
    if not ChkBox_PlayerTypes[I, K].IsClickable then
      Continue;

    Checked := TKMCheckBox(Sender).Checked;

    ChkBox_PlayerTypes[I, K].SetChecked(Checked);
    case K of
      1:  gGame.MapEditor.PlayerHuman[I] := Checked;
      2:  gGame.MapEditor.PlayerClassicAI[I] := Checked;
      3:  gGame.MapEditor.PlayerAdvancedAI[I] := Checked;
    end;
  end;

  Mission_PlayerTypesUpdate;
end;


procedure TKMMapEdMissionPlayers.Mission_PlayerTypesChange(Sender: TObject);
var
  PlayerId: Integer;
begin
  PlayerId := TKMCheckBox(Sender).Tag;

  UpdatePlayer(PlayerId);

  //There should be exactly one default human player
  if Sender = ChkBox_PlayerTypes[PlayerId, 0] then
  begin
    gGame.MapEditor.DefaultHuman := PlayerId;
    gGame.MapEditor.PlayerHuman[PlayerId] := True;
  end;

  if Sender = ChkBox_PlayerTypes[PlayerId, 1] then
  begin
    gGame.MapEditor.PlayerHuman[PlayerId] := ChkBox_PlayerTypes[PlayerId, 1].Checked;
    //User cannot set player type undetermined
    if not ChkBox_PlayerTypes[PlayerId, 1].Checked
        and not ChkBox_PlayerTypes[PlayerId, 2].Checked
        and not ChkBox_PlayerTypes[PlayerId, 3].Checked then
        gGame.MapEditor.PlayerClassicAI[PlayerId] := True;
  end;

  if (Sender = ChkBox_PlayerTypes[PlayerId, 2])
    or (Sender = ChkBox_PlayerTypes[PlayerId, 3]) then
  begin
    gGame.MapEditor.PlayerClassicAI[PlayerId] := ChkBox_PlayerTypes[PlayerId, 2].Checked;
    gGame.MapEditor.PlayerAdvancedAI[PlayerId] := ChkBox_PlayerTypes[PlayerId, 3].Checked;
    if not ChkBox_PlayerTypes[PlayerId, 1].Checked then
    begin
      //User cannot set player type undetermined
      if not ChkBox_PlayerTypes[PlayerId, 2].Checked
        and not ChkBox_PlayerTypes[PlayerId, 3].Checked then
        gGame.MapEditor.PlayerHuman[PlayerId] := True;
      //Can't be 2 default AI types (without human)
//      if CheckBox_PlayerTypes[PlayerId, 2].Checked
//        and CheckBox_PlayerTypes[PlayerId, 3].Checked then
//      begin
//        if (Sender = CheckBox_PlayerTypes[PlayerId, 2]) then
//          gGame.MapEditor.PlayerAdvancedAI[PlayerId] := False
//        else
//          gGame.MapEditor.PlayerClassicAI[PlayerId] := False;
//      end;
    end;
  end;

  Mission_PlayerTypesUpdate;
end;

procedure TKMMapEdMissionPlayers.Mission_PlayerIdUpdate;
var
  I: Integer;
begin
  UpdatePlayer;

  for I := 0 to MAX_HANDS - 1 do
    if I < gHands.Count then
      Label_PlayerId[I].Enabled := gHands[I].HasAssets;
end;


procedure TKMMapEdMissionPlayers.UpdatePlayer(aIndex: TKMHandID = -1);
begin
  if aIndex = -1 then
    aIndex := gMySpectator.HandID;

  Button_PlayerDelete.Enabled := gHands[aIndex].HasAssets;
  Button_PlayerDelete.Caption := Format(gResTexts[TX_MAPED_PLAYER_DELETE], [aIndex + 1]);
  fPlayerIdToDelete := aIndex;
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

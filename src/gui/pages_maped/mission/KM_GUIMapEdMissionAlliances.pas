unit KM_GUIMapEdMissionAlliances;
{$I KaM_Remake.inc}
interface
uses
   {$IFDEF MSWindows} Windows, {$ENDIF}
   {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
   Classes, SysUtils,
   KM_Controls, KM_Defaults, KM_InterfaceGame, KM_Pics;

type
  TKMMapEdMissionAlliances = class
  private
    procedure CloseAlliances_Click(Sender: TObject);

    procedure Mission_AlliancesChange(Sender: TObject);
    procedure Mission_AlliancesUpdate;
  protected
    Panel_Alliances: TKMPanel;
    PopUp_Alliances: TKMPopUpMenu;
      Bevel_Alliances: TKMBevel;
      Image_Alliances: TKMImage;
      CheckBox_Alliances: array [0..MAX_HANDS-1, 0..MAX_HANDS-1] of TKMCheckBox;
      CheckBox_AlliancesSym: TKMCheckBox;
      Button_CloseAlliances: TKMButton;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure Show;
    function Visible: Boolean;
    procedure Hide;
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_RenderUI, KM_ResFonts, KM_Hand, KM_ResKeys;


{ TKMMapEdMissionAlliances }
constructor TKMMapEdMissionAlliances.Create(aParent: TKMPanel);
var
  I, K: Integer;
begin
  inherited Create;

  PopUp_Alliances := TKMPopUpMenu.Create(aParent.MasterParent, 330);
  PopUp_Alliances.Height := 420;
  PopUp_Alliances.AnchorsCenter;
  PopUp_Alliances.Left := (aParent.MasterParent.Width div 2) - (PopUp_Alliances.Width div 2);
  PopUp_Alliances.Top := (aParent.MasterParent.Height div 2) - (PopUp_Alliances.Height div 2);

    Bevel_Alliances := TKMBevel.Create(PopUp_Alliances, -1000,  -1000, 4000, 4000);
    Bevel_Alliances.BackAlpha := 0.7;
    Bevel_Alliances.EdgeAlpha := 0.9;

    Image_Alliances := TKMImage.Create(PopUp_Alliances, 0, 0, PopUp_Alliances.Width, PopUp_Alliances.Height, 3, rxGuiMain);
    Image_Alliances.ImageStretch;

  Panel_Alliances := TKMPanel.Create(PopUp_Alliances, 30, 30, PopUp_Alliances.Width - 60, PopUp_Alliances.Height - 60);

  TKMLabel.Create(Panel_Alliances, 0, PAGE_TITLE_Y, Panel_Alliances.Width, 0, gResTexts[TX_MAPED_ALLIANCE], fnt_Outline, taCenter);
  for I := 0 to MAX_HANDS - 1 do
  begin
    TKMLabel.Create(Panel_Alliances, 40 + I * 20, 30, IntToStr(I + 1), fnt_Grey, taCenter);
    TKMLabel.Create(Panel_Alliances, 10, 50 + I * 20, IntToStr(I + 1), fnt_Grey, taCenter);
    for K := 0 to MAX_HANDS - 1 do
    begin
      CheckBox_Alliances[I,K] := TKMCheckBox.Create(Panel_Alliances, 32 + K * 20, 50 + I * 20, 30, 30, '', fnt_Metal);
      CheckBox_Alliances[I,K].Tag       := I * MAX_HANDS + K;
      CheckBox_Alliances[I,K].OnClick   := Mission_AlliancesChange;
    end;
  end;

  //It does not have OnClick event for a reason:
  // - we don't have a rule to make alliances symmetrical yet
  CheckBox_AlliancesSym := TKMCheckBox.Create(Panel_Alliances, Panel_Alliances.Center.X - 105, Panel_Alliances.Height - 60, 150, 20, gResTexts[TX_MAPED_ALLIANCE_SYMMETRIC], fnt_Metal);
  CheckBox_AlliancesSym.Checked := True;
  CheckBox_AlliancesSym.Disable;

  Button_CloseAlliances := TKMButton.Create(Panel_Alliances, Panel_Alliances.Center.X - 130, Panel_Alliances.Height - 30,
                                            200, 30, gResTexts[TX_MAPED_TERRAIN_CLOSE_PALETTE], bsGame);
  Button_CloseAlliances.OnClick := CloseAlliances_Click;
end;


procedure TKMMapEdMissionAlliances.CloseAlliances_Click(Sender: TObject);
begin
  Hide;
end;


procedure TKMMapEdMissionAlliances.Mission_AlliancesChange(Sender: TObject);
const
  ALL: array [Boolean] of TAllianceType = (at_Enemy, at_Ally);
var
  I,K: Integer;
begin
  I := TKMCheckBox(Sender).Tag div gHands.Count;
  K := TKMCheckBox(Sender).Tag mod gHands.Count;

  gHands[I].Alliances[K] := ALL[CheckBox_Alliances[I,K].Checked or (I = K)];

  //Copy status to symmetrical item
  if CheckBox_AlliancesSym.Checked then
  begin
    CheckBox_Alliances[K,I].Checked := CheckBox_Alliances[I,K].Checked;
    gHands[K].Alliances[I] := gHands[I].Alliances[K];
  end;

  Mission_AlliancesUpdate;
end;


procedure TKMMapEdMissionAlliances.Mission_AlliancesUpdate;
var
  I,K: Integer;
begin
  for I := 0 to gHands.Count - 1 do
  for K := 0 to gHands.Count - 1 do
  begin
    CheckBox_Alliances[I,K].Enabled := gHands[I].HasAssets and gHands[K].HasAssets;
    CheckBox_Alliances[I,K].Checked := gHands[I].HasAssets and gHands[K].HasAssets and (gHands[I].Alliances[K] = at_Ally);
  end;
end;


procedure TKMMapEdMissionAlliances.KeyDown(Key: Word; Shift: TShiftState;
  var aHandled: Boolean);
begin
  aHandled := Key = gResKeys[SC_MAPEDIT_OBJ_PALETTE].Key;
  if (Key = VK_ESCAPE) and PopUp_Alliances.Visible then
  begin
    Hide;
    aHandled := True;
  end;
end;


procedure TKMMapEdMissionAlliances.Hide;
begin
  PopUp_Alliances.Hide;
end;


procedure TKMMapEdMissionAlliances.Show;
begin
  Mission_AlliancesUpdate;
  PopUp_Alliances.Show;
end;


function TKMMapEdMissionAlliances.Visible: Boolean;
begin
  Result := Panel_Alliances.Visible;
end;


end.

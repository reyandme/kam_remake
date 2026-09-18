unit KM_GUIMapEdMenuSave;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsSwitch, KM_ControlsDrop,
  KM_InterfaceGame, KM_CommonTypes, KM_ResFonts;


type
  TKMMapEdMenuSave = class
  private
    fIsMultiplayer: Boolean;
    fIsOriginalCampaign: Boolean;
    fOriginalCampaignPath: string;
    fOriginalMissionName: string;
    fOriginalCampaignTag: Integer;
    fOriginalMissionIndex: Integer;
    fOnDone: TNotifyEvent;
    fOnMapTypChanged: TBooleanEvent;

    procedure Menu_SaveClick(Sender: TObject);
    procedure UpdateCategoryLayout;
    procedure UpdateMissionIndexRange;
    procedure PopulateCampaignList;
    function IsCampaignCategory: Boolean;
  protected
    Panel_Save: TKMPanel;
      Bevel_SaveMapType: TKMBevel;
      Radio_Save_MapType: TKMRadioGroup;
      DropList_SaveCampaign: TKMDropList;
      FilenameEdit_SaveName: TKMFilenameEdit;
      Label_SaveMissionIndex: TKMLabel;
      NumEdit_SaveMissionIndex: TKMNumericEdit;
      Label_SaveExists: TKMLabel;
      CheckBox_SaveExists: TKMCheckBox;
  public
    Button_SaveSave: TKMButton;
    Button_SaveCancel: TKMButton;
    constructor Create(aParent: TKMPanel; aOnDone: TNotifyEvent; aOnMapTypChanged: TBooleanEvent; aLabelFont: TKMFont = fntOutline;
                       aLeftPanelInset: Integer = TB_PAD; aTopPanelInset: Integer = 45; aControlsWidth: Integer = TB_MAP_ED_WIDTH-TB_PAD);

    procedure SetLoadMode(aMultiplayer: Boolean);
    procedure Show;
    procedure Hide;
  end;


implementation
uses
  Math,
  KM_Maps, KM_MapUtils, KM_Game, KM_GameApp, KM_GameParams, KM_Campaigns, KM_RenderUI, KM_ResTexts, KM_InterfaceDefaults, KM_InterfaceTypes,
  KM_Resource, KM_Defaults;

const
  SAVE_CAT_MP = 1;
  SAVE_CAT_CAMPAIGN = 2;


{ TKMMapEdMenuSave }
constructor TKMMapEdMenuSave.Create(aParent: TKMPanel; aOnDone: TNotifyEvent; aOnMapTypChanged: TBooleanEvent;
                                    aLabelFont: TKMFont = fntOutline;
                                    aLeftPanelInset: Integer = TB_PAD; aTopPanelInset: Integer = 45;
                                    aControlsWidth: Integer = TB_MAP_ED_WIDTH - TB_PAD);
begin
  inherited Create;

  fOnDone := aOnDone;
  fOnMapTypChanged := aOnMapTypChanged;
  fIsMultiplayer := False;

  Panel_Save := TKMPanel.Create(aParent, 0, aTopPanelInset, aControlsWidth + aLeftPanelInset, 270);
  Panel_Save.Anchors := [anLeft, anTop, anBottom];

  TKMLabel.Create(Panel_Save,aLeftPanelInset,0,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_TITLE], aLabelFont, taLeft);

  Bevel_SaveMapType := TKMBevel.Create(Panel_Save, aLeftPanelInset, 25, aControlsWidth, 52);
  Radio_Save_MapType := TKMRadioGroup.Create(Panel_Save,13,27,aControlsWidth,50,fntGrey);
  Radio_Save_MapType.ItemIndex := 0;
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Save_MapType.Add(gResTexts[TX_MENU_CAMPAIGNS]);
  Radio_Save_MapType.OnChange := Menu_SaveClick;

  DropList_SaveCampaign := TKMDropList.Create(Panel_Save, aLeftPanelInset, Radio_Save_MapType.Bottom + 8, aControlsWidth, 20, fntGrey, '', bsGame);
  DropList_SaveCampaign.OnChange := Menu_SaveClick;

  FilenameEdit_SaveName := TKMFilenameEdit.Create(Panel_Save,aLeftPanelInset,80,aControlsWidth,20, fntGrey);
  FilenameEdit_SaveName.AutoFocusable := False;
  FilenameEdit_SaveName.OnChange := Menu_SaveClick;

  Label_SaveMissionIndex := TKMLabel.Create(Panel_Save, aLeftPanelInset, 80, 110, 20, '', fntGrey, taLeft);
  Label_SaveMissionIndex.TextVAlign := tvaMiddle;
  Label_SaveMissionIndex.Hide;

  NumEdit_SaveMissionIndex := TKMNumericEdit.Create(Panel_Save, aLeftPanelInset + 115, 80, 1, 99, fntGrey);
  NumEdit_SaveMissionIndex.AutoFocusable := False;
  NumEdit_SaveMissionIndex.OnChange := Menu_SaveClick;
  NumEdit_SaveMissionIndex.Hide;

  Label_SaveExists := TKMLabel.Create(Panel_Save,aLeftPanelInset,110,aControlsWidth,0,gResTexts[TX_MAPED_SAVE_EXISTS],fntOutline,taCenter);

  CheckBox_SaveExists := TKMCheckBox.Create(Panel_Save,aLeftPanelInset,130,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
  CheckBox_SaveExists.OnClick := Menu_SaveClick;

  Button_SaveSave := TKMButton.Create(Panel_Save,aLeftPanelInset,150,aControlsWidth,30,gResTexts[TX_MAPED_SAVE],bsGame);
  Button_SaveSave.OnClick := Menu_SaveClick;

  Button_SaveCancel:= TKMButton.Create(Panel_Save,aLeftPanelInset,190,aControlsWidth,30,gResTexts[TX_MAPED_SAVE_CANCEL],bsGame);
  Button_SaveCancel.OnClick := Menu_SaveClick;
end;


function TKMMapEdMenuSave.IsCampaignCategory: Boolean;
begin
  Result := Radio_Save_MapType.ItemIndex = SAVE_CAT_CAMPAIGN;
end;


procedure TKMMapEdMenuSave.PopulateCampaignList;
var
  I, J: Integer;
begin
  DropList_SaveCampaign.Clear;
  fOriginalCampaignTag := -1;
  fOriginalMissionIndex := -1;

  for I := 0 to gGameApp.Campaigns.Count - 1 do
  begin
    DropList_SaveCampaign.Add(gGameApp.Campaigns[I].Spec.GetCampaignTitle, I);

    if fIsOriginalCampaign and SameFileName(ExcludeTrailingPathDelimiter(gGameApp.Campaigns[I].Path), ExcludeTrailingPathDelimiter(fOriginalCampaignPath)) then
    begin
      fOriginalCampaignTag := I;
      for J := 0 to gGameApp.Campaigns[I].Spec.MissionsCount - 1 do
        if SameText(gGameApp.Campaigns[I].GetMissionName(J), fOriginalMissionName) then
        begin
          fOriginalMissionIndex := J;
          Break;
        end;
    end;
  end;

  if gGameApp.Campaigns.Count > 0 then
    DropList_SaveCampaign.SelectByTag(Max(0, fOriginalCampaignTag));
end;


procedure TKMMapEdMenuSave.UpdateMissionIndexRange;
var
  campaign: TKMCampaign;
begin
  if not DropList_SaveCampaign.IsSelected then
    Exit;

  campaign := gGameApp.Campaigns[DropList_SaveCampaign.GetSelectedTag];
  Label_SaveMissionIndex.Caption := campaign.Spec.IdStr + ':';
  NumEdit_SaveMissionIndex.Left := Label_SaveMissionIndex.Left
                                  + gRes.Fonts[Label_SaveMissionIndex.Font].GetTextSize(Label_SaveMissionIndex.Caption).X + 6;
  NumEdit_SaveMissionIndex.ValueMin := 1;
  NumEdit_SaveMissionIndex.ValueMax := Max(1, campaign.Spec.MissionsCount);

  if (DropList_SaveCampaign.GetSelectedTag = fOriginalCampaignTag) and (fOriginalMissionIndex >= 0) then
    NumEdit_SaveMissionIndex.Value := fOriginalMissionIndex + 1
  else
    NumEdit_SaveMissionIndex.Value := 1;
end;


procedure TKMMapEdMenuSave.UpdateCategoryLayout;
var
  filenameEditTop: Integer;
begin
  DropList_SaveCampaign.Visible := IsCampaignCategory;
  FilenameEdit_SaveName.Visible := not IsCampaignCategory;
  Label_SaveMissionIndex.Visible := IsCampaignCategory;
  NumEdit_SaveMissionIndex.Visible := IsCampaignCategory;

  if IsCampaignCategory then
  begin
    filenameEditTop := DropList_SaveCampaign.Bottom + 8;
    UpdateMissionIndexRange;
  end else
    filenameEditTop := Radio_Save_MapType.Bottom + 18;

  FilenameEdit_SaveName.Top := filenameEditTop;
  Label_SaveMissionIndex.Top := filenameEditTop;
  NumEdit_SaveMissionIndex.Top := filenameEditTop;
  Label_SaveExists.Top := filenameEditTop + 30;
  CheckBox_SaveExists.Top := filenameEditTop + 50;
  Button_SaveSave.Top := filenameEditTop + 70;
  Button_SaveCancel.Top := filenameEditTop + 110;
end;


procedure TKMMapEdMenuSave.Menu_SaveClick(Sender: TObject);

  function GetSaveName: UnicodeString;
  var
    campaign: TKMCampaign;
  begin
    if IsCampaignCategory then
    begin
      if not DropList_SaveCampaign.IsSelected then Exit('');
      campaign := gGameApp.Campaigns[DropList_SaveCampaign.GetSelectedTag];
      Result := campaign.GetMissionFile(NumEdit_SaveMissionIndex.Value - 1, '.dat');
    end
    else
      Result := TKMapsCollection.FullPath(Trim(FilenameEdit_SaveName.Text), '.dat', Radio_Save_MapType.ItemIndex = SAVE_CAT_MP);
  end;

  function IsSameAsOriginal: Boolean;
  begin
    Result := IsCampaignCategory and fIsOriginalCampaign
              and (DropList_SaveCampaign.GetSelectedTag = fOriginalCampaignTag)
              and (NumEdit_SaveMissionIndex.Value - 1 = fOriginalMissionIndex);
  end;

begin
  if (Sender = Radio_Save_MapType) or (Sender = DropList_SaveCampaign) then
    UpdateCategoryLayout;

  if (Sender = FilenameEdit_SaveName) or (Sender = Radio_Save_MapType) or (Sender = DropList_SaveCampaign) or (Sender = NumEdit_SaveMissionIndex) then
  begin
    if IsCampaignCategory and not DropList_SaveCampaign.IsSelected then
    begin
      CheckBox_SaveExists.Enabled := False;
      Button_SaveSave.Enabled := False;
    end
    else
    begin
      if IsSameAsOriginal then
        CheckBox_SaveExists.Enabled := False
      else
        CheckBox_SaveExists.Enabled := FileExists(GetSaveName);

      if IsCampaignCategory then
        Button_SaveSave.Enabled := not CheckBox_SaveExists.Enabled
      else
        Button_SaveSave.Enabled := not CheckBox_SaveExists.Enabled and FilenameEdit_SaveName.IsValid;
    end;
    Label_SaveExists.Visible := CheckBox_SaveExists.Enabled;
    CheckBox_SaveExists.Checked := False;
  end
  else

  if Sender = CheckBox_SaveExists then
    Button_SaveSave.Enabled := CheckBox_SaveExists.Checked
  else

  if Sender = Button_SaveSave then
  begin
    if not IsCampaignCategory then
    begin
      fIsMultiplayer := Radio_Save_MapType.ItemIndex = SAVE_CAT_MP;
      if Assigned(fOnMapTypChanged) then
        fOnMapTypChanged(fIsMultiplayer);
    end;

    gGame.SaveMapEditor(GetSaveName);

    //Player colors and mapname has changed
    gGame.ActiveInterface.SyncUI(False); //Don't move the viewport

    fOnDone(Self);
  end
  else

  if Sender = Button_SaveCancel then
    fOnDone(Self);
end;


procedure TKMMapEdMenuSave.Hide;
begin
  Panel_Save.Hide;
end;


procedure TKMMapEdMenuSave.Show;
begin
  fIsOriginalCampaign := IsCampaignMissionPathRel(gGameParams.MissionFileRel);
  if fIsOriginalCampaign then
  begin
    fOriginalCampaignPath := ExtractFileDir(ExtractFileDir(ExeDir + gGameParams.MissionFileRel)) + PathDelim;
    fOriginalMissionName := gGameParams.Name;
  end else
  begin
    fOriginalCampaignPath := '';
    fOriginalMissionName := '';
  end;

  PopulateCampaignList;

  if fIsOriginalCampaign then
    Radio_Save_MapType.ItemIndex := SAVE_CAT_CAMPAIGN
  else
    SetLoadMode(fIsMultiplayer);

  UpdateCategoryLayout;

  FilenameEdit_SaveName.Text := gGameParams.Name;
  FilenameEdit_SaveName.Focus;
  Menu_SaveClick(FilenameEdit_SaveName);

  Panel_Save.Show;
end;


procedure TKMMapEdMenuSave.SetLoadMode(aMultiplayer: Boolean);
begin
  fIsMultiplayer := aMultiplayer;
  if aMultiplayer then
    Radio_Save_MapType.ItemIndex := 1
  else
    Radio_Save_MapType.ItemIndex := 0;
end;


end.

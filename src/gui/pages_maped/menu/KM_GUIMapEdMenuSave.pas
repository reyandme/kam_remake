unit KM_GUIMapEdMenuSave;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils, KM_Defaults,
   KM_Controls, KM_Maps, KM_InterfaceGame, KM_CommonTypes;


type
  TKMMapEdMenuSave = class
  private
    fMapFolder: TKMapFolder;
    fOnDone: TNotifyEvent;
    fOnMapFolderChanged: TKMapFolderEvent;

    procedure Menu_SaveClick(Sender: TObject);
  protected
    Panel_Save: TKMPanel;
      Radio_Save_MapType: TKMRadioGroup;
      DropBox_Campaigns: TKMDropList;
      Edit_SaveName: TKMEdit;
      Label_SaveExists: TKMLabel;
      CheckBox_SaveExists: TKMCheckBox;
  public
    Button_SaveSave: TKMButton;
    Button_SaveCancel: TKMButton;
    constructor Create(aParent: TKMPanel; aOnDone: TNotifyEvent; aOnMapFolderChanged: TKMapFolderEvent;
                       aLeftPanelInset: Integer = TB_PAD; aTopPanelInset: Integer = 45; aControlsWidth: Integer = TB_MAP_ED_WIDTH-TB_PAD);

    procedure SetLoadMode(aMapFolder: TKMapFolder);
    procedure Show;
    procedure Hide;
  end;


implementation
uses
  KM_Game, KM_GameParams, KM_RenderUI, KM_ResFonts, KM_ResTexts, KM_InterfaceDefaults, KM_GameApp, KM_GameSettings;


{ TKMMapEdMenuSave }
constructor TKMMapEdMenuSave.Create(aParent: TKMPanel; aOnDone: TNotifyEvent; aOnMapFolderChanged: TKMapFolderEvent;
                                    aLeftPanelInset: Integer = TB_PAD; aTopPanelInset: Integer = 45; aControlsWidth: Integer = TB_MAP_ED_WIDTH - TB_PAD);
var
  I: Integer;
begin
  inherited Create;

  fOnDone := aOnDone;
  fOnMapFolderChanged := aOnMapFolderChanged;

  Panel_Save := TKMPanel.Create(aParent, 0, aTopPanelInset, aControlsWidth + aLeftPanelInset, 230);
  Panel_Save.Anchors := [anLeft, anTop, anBottom];

  TKMLabel.Create(Panel_Save,aLeftPanelInset,0,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_TITLE],fntOutline,taLeft);

  TKMBevel.Create(Panel_Save, aLeftPanelInset, 25, aControlsWidth, 64);
  Radio_Save_MapType  := TKMRadioGroup.Create(Panel_Save,13,29,aControlsWidth,58,fntGrey);
  Radio_Save_MapType.ItemIndex := 0;
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Save_MapType.Add(gResTexts[TX_MENU_CAMPAIGNS]);
  Radio_Save_MapType.OnChange := Menu_SaveClick;

  DropBox_Campaigns := TKMDropList.Create(Panel_Save, 9, 100, Panel_Save.Width - 9, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
  DropBox_Campaigns.Anchors := [anLeft, anBottom];
  DropBox_Campaigns.OnChange := Menu_SaveClick;
  DropBox_Campaigns.Clear;
  for I := 0 to gGameApp.Campaigns.Count - 1 do
    DropBox_Campaigns.Add(gGameApp.Campaigns[I].GetCampaignTitle);
  DropBox_Campaigns.ItemIndex := gGameSettings.MapEdCMIndex;
  DropBox_Campaigns.Hide;

  Edit_SaveName       := TKMEdit.Create(Panel_Save,aLeftPanelInset,125,aControlsWidth,20, fntGrey);
  Edit_SaveName.MaxLen := MAX_SAVENAME_LENGTH;
  Edit_SaveName.AllowedChars := acFileName;
  Edit_SaveName.AutoFocusable := False;
  Label_SaveExists    := TKMLabel.Create(Panel_Save,aLeftPanelInset,155,aControlsWidth,0,gResTexts[TX_MAPED_SAVE_EXISTS],fntOutline,taCenter);
  CheckBox_SaveExists := TKMCheckBox.Create(Panel_Save,aLeftPanelInset,175,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
  Button_SaveSave     := TKMButton.Create(Panel_Save,aLeftPanelInset,195,aControlsWidth,30,gResTexts[TX_MAPED_SAVE],bsGame);
  Button_SaveCancel   := TKMButton.Create(Panel_Save,aLeftPanelInset,245,aControlsWidth,30,gResTexts[TX_MAPED_SAVE_CANCEL],bsGame);
  Edit_SaveName.OnChange      := Menu_SaveClick;
  CheckBox_SaveExists.OnClick := Menu_SaveClick;
  Button_SaveSave.OnClick     := Menu_SaveClick;
  Button_SaveCancel.OnClick   := Menu_SaveClick;
end;


procedure TKMMapEdMenuSave.Menu_SaveClick(Sender: TObject);

  function GetSaveName: UnicodeString;
  begin
    if Radio_Save_MapType.ItemIndex = 2 then
      Result := ExeDir + gGameApp.Campaigns[DropBox_Campaigns.ItemIndex].Path + PathDelim + Trim(Edit_SaveName.Text) + PathDelim + Trim(Edit_SaveName.Text) + '.dat'
    else
      Result := TKMapsCollection.FullPath(Trim(Edit_SaveName.Text), '.dat', TKMapFolder(Radio_Save_MapType.ItemIndex));
  end;

begin
  if (Sender = Edit_SaveName) or (Sender = Radio_Save_MapType) or (Sender = DropBox_Campaigns) then
  begin
    DropBox_Campaigns.Visible := Radio_Save_MapType.ItemIndex = 2;
    CheckBox_SaveExists.Enabled := FileExists(GetSaveName);
    Label_SaveExists.Visible := CheckBox_SaveExists.Enabled;
    CheckBox_SaveExists.Checked := False;
    Button_SaveSave.Enabled := not CheckBox_SaveExists.Enabled and (Length(Trim(Edit_SaveName.Text)) > 0);
  end
  else

  if Sender = CheckBox_SaveExists then
    Button_SaveSave.Enabled := CheckBox_SaveExists.Checked
  else

  if Sender = Button_SaveSave then
  begin
    fMapFolder := TKMapFolder(Radio_Save_MapType.ItemIndex);
    if Assigned(fOnMapFolderChanged) then
      fOnMapFolderChanged(fMapFolder);

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
  Edit_SaveName.Text := gGameParams.Name;
  Edit_SaveName.Focus;
  Menu_SaveClick(Edit_SaveName);
  Panel_Save.Show;
end;


procedure TKMMapEdMenuSave.SetLoadMode(aMapFolder: TKMapFolder);
begin
  Radio_Save_MapType.ItemIndex := Integer(aMapFolder);
end;


end.

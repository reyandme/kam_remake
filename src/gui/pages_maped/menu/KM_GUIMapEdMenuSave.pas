unit KM_GUIMapEdMenuSave;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsSwitch,
  KM_InterfaceGame, KM_CommonTypes, KM_ResFonts;


type
  TKMMapEdMenuSave = class
  private
    fIsMultiplayer: Boolean;
    fOnDone: TNotifyEvent;
    fOnMapTypChanged: TBooleanEvent;

    procedure Menu_SaveClick(Sender: TObject);
  protected
    Panel_Save: TKMPanel;
      Radio_Save_MapType: TKMRadioGroup;
      FilenameEdit_SaveName: TKMFilenameEdit;
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
  KM_Maps, KM_Game, KM_GameParams, KM_RenderUI, KM_ResTexts, KM_InterfaceDefaults, KM_InterfaceTypes;


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

  Panel_Save := TKMPanel.Create(aParent, 0, aTopPanelInset, aControlsWidth + aLeftPanelInset, 230);
  Panel_Save.Anchors := [anLeft, anTop, anBottom];

  TKMLabel.Create(Panel_Save,aLeftPanelInset,0,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_TITLE], aLabelFont, taLeft);

  TKMBevel.Create(Panel_Save, aLeftPanelInset, 25, aControlsWidth, 37);
  Radio_Save_MapType := TKMRadioGroup.Create(Panel_Save,13,27,aControlsWidth,35,fntGrey);
  Radio_Save_MapType.ItemIndex := 0;
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Save_MapType.OnChange := Menu_SaveClick;

  FilenameEdit_SaveName := TKMFilenameEdit.Create(Panel_Save,aLeftPanelInset,80,aControlsWidth,20, fntGrey);
  FilenameEdit_SaveName.AutoFocusable := False;
  FilenameEdit_SaveName.OnChange := Menu_SaveClick;

  Label_SaveExists := TKMLabel.Create(Panel_Save,aLeftPanelInset,110,aControlsWidth,0,gResTexts[TX_MAPED_SAVE_EXISTS],fntOutline,taCenter);

  CheckBox_SaveExists := TKMCheckBox.Create(Panel_Save,aLeftPanelInset,130,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
  CheckBox_SaveExists.OnClick := Menu_SaveClick;

  Button_SaveSave := TKMButton.Create(Panel_Save,aLeftPanelInset,150,aControlsWidth,30,gResTexts[TX_MAPED_SAVE],bsGame);
  Button_SaveSave.OnClick := Menu_SaveClick;

  Button_SaveCancel:= TKMButton.Create(Panel_Save,aLeftPanelInset,190,aControlsWidth,30,gResTexts[TX_MAPED_SAVE_CANCEL],bsGame);
  Button_SaveCancel.OnClick := Menu_SaveClick;
end;


procedure TKMMapEdMenuSave.Menu_SaveClick(Sender: TObject);

  function GetSaveName: UnicodeString;
  begin
    Result := TKMapsCollection.FullPath(Trim(FilenameEdit_SaveName.Text), '.dat', Radio_Save_MapType.ItemIndex = 1);
  end;

begin
  if (Sender = FilenameEdit_SaveName) or (Sender = Radio_Save_MapType) then
  begin
    CheckBox_SaveExists.Enabled := FileExists(GetSaveName);
    Label_SaveExists.Visible := CheckBox_SaveExists.Enabled;
    CheckBox_SaveExists.Checked := False;
    Button_SaveSave.Enabled := not CheckBox_SaveExists.Enabled and FilenameEdit_SaveName.IsValid;
  end
  else

  if Sender = CheckBox_SaveExists then
    Button_SaveSave.Enabled := CheckBox_SaveExists.Checked
  else

  if Sender = Button_SaveSave then
  begin
    fIsMultiplayer := Radio_Save_MapType.ItemIndex = 1;
    if Assigned(fOnMapTypChanged) then
      fOnMapTypChanged(fIsMultiplayer);

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
  SetLoadMode(fIsMultiplayer);
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

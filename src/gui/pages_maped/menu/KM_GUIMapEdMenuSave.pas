unit KM_GUIMapEdMenuSave;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Controls, KM_Maps, KM_InterfaceGame, KM_CommonTypes;


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
      Edit_SaveName: TKMEdit;
      Label_SaveExists: TKMLabel;
      CheckBox_SaveExists: TKMCheckBox;
  public
    Button_SaveSave: TKMButton;
    Button_SaveCancel: TKMButton;
    constructor Create(aParent: TKMPanel; aOnDone: TNotifyEvent; aOnMapTypChanged: TBooleanEvent;
                       aLeftPanelInset: Integer = TB_PAD; aTopPanelInset: Integer = 45; aControlsWidth: Integer = TB_WIDTH);

    procedure SetLoadMode(aMultiplayer: Boolean);
    procedure Show;
    procedure Hide;
  end;


implementation
uses
  KM_Game, KM_RenderUI, KM_ResFonts, KM_ResTexts, KM_InterfaceDefaults;


{ TKMMapEdMenuSave }
constructor TKMMapEdMenuSave.Create(aParent: TKMPanel; aOnDone: TNotifyEvent; aOnMapTypChanged: TBooleanEvent;
                                    aLeftPanelInset: Integer = 9; aTopPanelInset: Integer = 45; aControlsWidth: Integer = TB_WIDTH);
begin
  inherited Create;

  fOnDone := aOnDone;
  fOnMapTypChanged := aOnMapTypChanged;
  fIsMultiplayer := False;

  Panel_Save := TKMPanel.Create(aParent, 0, aTopPanelInset, aControlsWidth + aLeftPanelInset, 230);
  TKMLabel.Create(Panel_Save,aLeftPanelInset,0,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_TITLE],fntOutline,taLeft);

  TKMBevel.Create(Panel_Save, aLeftPanelInset, 25, aControlsWidth, 37);
  Radio_Save_MapType  := TKMRadioGroup.Create(Panel_Save,13,27,aControlsWidth,35,fntGrey);
  Radio_Save_MapType.ItemIndex := 0;
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Save_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Save_MapType.OnChange := Menu_SaveClick;

  Edit_SaveName       := TKMEdit.Create(Panel_Save,aLeftPanelInset,80,aControlsWidth,20, fntGrey);
  Edit_SaveName.MaxLen := MAX_SAVENAME_LENGTH;
  Edit_SaveName.AllowedChars := acFileName;
  Label_SaveExists    := TKMLabel.Create(Panel_Save,aLeftPanelInset,110,aControlsWidth,0,gResTexts[TX_MAPED_SAVE_EXISTS],fntOutline,taCenter);
  CheckBox_SaveExists := TKMCheckBox.Create(Panel_Save,aLeftPanelInset,130,aControlsWidth,20,gResTexts[TX_MAPED_SAVE_OVERWRITE], fntMetal);
  Button_SaveSave     := TKMButton.Create(Panel_Save,aLeftPanelInset,150,aControlsWidth,30,gResTexts[TX_MAPED_SAVE],bsGame);
  Button_SaveCancel   := TKMButton.Create(Panel_Save,aLeftPanelInset,190,aControlsWidth,30,gResTexts[TX_MAPED_SAVE_CANCEL],bsGame);
  Edit_SaveName.OnChange      := Menu_SaveClick;
  CheckBox_SaveExists.OnClick := Menu_SaveClick;
  Button_SaveSave.OnClick     := Menu_SaveClick;
  Button_SaveCancel.OnClick   := Menu_SaveClick;
end;


procedure TKMMapEdMenuSave.Menu_SaveClick(Sender: TObject);

  function GetSaveName: UnicodeString;
  begin
    Result := TKMapsCollection.FullPath(Trim(Edit_SaveName.Text), '.dat', Radio_Save_MapType.ItemIndex = 1);
  end;

begin
  if (Sender = Edit_SaveName) or (Sender = Radio_Save_MapType) then
  begin
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
    fIsMultiplayer := Radio_Save_MapType.ItemIndex = 1;
    if Assigned(fOnMapTypChanged) then
      fOnMapTypChanged(fIsMultiplayer);

    gGame.SaveMapEditor(GetSaveName);
    gGame.MapEditor.WasSaved := True;

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
  Edit_SaveName.Text := gGame.GameName;
  Menu_SaveClick(Edit_SaveName);
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

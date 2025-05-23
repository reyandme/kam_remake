unit KM_GUIMapEdExtras;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Defaults,
   KM_Controls, KM_ControlsBase, KM_ControlsDrop, KM_ControlsSwitch, KM_ControlsTrackBar;

type
  TKMMapEdExtras = class
  private
    fOnChange: TNotifyEvent;
    procedure Extra_Change(Sender: TObject);
    procedure Extra_Close(Sender: TObject);
    procedure Extra_FOWChange(Sender: TObject);
  protected
    Panel_Extra: TKMPanel;
    Image_ExtraClose: TKMImage;
    TrackBar_Passability: TKMTrackBar;
    Label_Passability: TKMLabel;
    Dropbox_PlayerFOW: TKMDropList;
  public
    CheckBox_ShowObjects: TKMCheckBox;
    CheckBox_ShowHouses: TKMCheckBox;
    CheckBox_ShowUnits: TKMCheckBox;
    CheckBox_ShowOverlays: TKMCheckBox;
    CheckBox_ShowDeposits: TKMCheckBox;
    CheckBox_ShowMiningRadius: TKMCheckBox;
    CheckBox_ShowTowersAttackRadius: TKMCheckBox;
    CheckBox_ShowUnitsAttackRadius: TKMCheckBox;
    CheckBox_ShowDefences: TKMCheckBox;
    CheckBox_ShowFlatTerrain: TKMCheckBox;
    CheckBox_ShowTilesOwner: TKMCheckBox;
    CheckBox_ShowTilesGrid: TKMCheckBox;
    constructor Create(aParent: TKMPanel; aOnChange: TNotifyEvent);

    procedure Show;
    procedure Refresh;
    function Visible: Boolean;
    procedure Hide;
  end;


implementation
uses
  KM_GameApp, KM_GameParams,
  KM_HandsCollection, KM_Sound, KM_ResSound,
  KM_RenderUI, KM_ResFonts, KM_ResTexts;


{ TKMMapEdExtras }
constructor TKMMapEdExtras.Create(aParent: TKMPanel; aOnChange: TNotifyEvent);
const
  PANEL_HEIGHT = 280;
var
  I: Integer;
begin
  inherited Create;

  fOnChange := aOnChange;

  Panel_Extra := TKMPanel.Create(aParent, MAPED_TOOLBAR_WIDTH+30, aParent.Height - PANEL_HEIGHT, 600, PANEL_HEIGHT);
  Panel_Extra.Anchors := [anLeft, anBottom];
  Panel_Extra.Hide;

  with TKMImage.Create(Panel_Extra, 0, 0, 600, PANEL_HEIGHT, 409) do
  begin
    Anchors := [anLeft, anTop, anBottom];
    ImageAnchors := [anLeft, anRight, anTop];
  end;

  Image_ExtraClose := TKMImage.Create(Panel_Extra, 600 - 76, 24, 32, 32, 52);
  Image_ExtraClose.Anchors := [anTop, anRight];
  Image_ExtraClose.Hint := gResTexts[TX_MSG_CLOSE_HINT];
  Image_ExtraClose.OnClick := Extra_Close;
  Image_ExtraClose.HighlightOnMouseOver := True;

  TrackBar_Passability := TKMTrackBar.Create(Panel_Extra, 50, 70, 220, 0, Byte(High(TKMTerrainPassability)));
  TrackBar_Passability.Font := fntAntiqua;
  TrackBar_Passability.Caption := gResTexts[TX_MAPED_VIEW_PASSABILITY];
  TrackBar_Passability.Position := 0; //Disabled by default
  TrackBar_Passability.OnChange := Extra_Change;
  Label_Passability := TKMLabel.Create(Panel_Extra, 50, 114, 180, 0, gResTexts[TX_MAPED_PASSABILITY_OFF], fntAntiqua, taLeft);

  CheckBox_ShowObjects := TKMCheckBox.Create(Panel_Extra, 300, 70, 280, 20, gResTexts[TX_MAPED_VIEW_OBJECTS], fntAntiqua);
  CheckBox_ShowObjects.Checked := True; //Enabled by default
  CheckBox_ShowObjects.OnClick := Extra_Change;
  CheckBox_ShowHouses := TKMCheckBox.Create(Panel_Extra, 300, 90, 280, 20, gResTexts[TX_MAPED_VIEW_HOUSES], fntAntiqua);
  CheckBox_ShowHouses.Checked := True; //Enabled by default
  CheckBox_ShowHouses.OnClick := Extra_Change;
  CheckBox_ShowUnits := TKMCheckBox.Create(Panel_Extra, 300, 110, 280, 20, gResTexts[TX_MAPED_VIEW_UNITS], fntAntiqua);
  CheckBox_ShowUnits.Checked := True; //Enabled by default
  CheckBox_ShowUnits.OnClick := Extra_Change;
  CheckBox_ShowOverlays := TKMCheckBox.Create(Panel_Extra, 300, 130, 280, 20, gResTexts[TX_MAPED_VIEW_OVERLAYS], fntAntiqua);
  CheckBox_ShowOverlays.Checked := True; //Enabled by default
  CheckBox_ShowOverlays.OnClick := Extra_Change;
  CheckBox_ShowDeposits := TKMCheckBox.Create(Panel_Extra, 300, 150, 280, 20, gResTexts[TX_MAPED_VIEW_DEPOSISTS], fntAntiqua);
  CheckBox_ShowDeposits.Checked := True; //Enabled by default
  CheckBox_ShowDeposits.OnClick := Extra_Change;
  CheckBox_ShowMiningRadius := TKMCheckBox.Create(Panel_Extra, 300, 170, 280, 20, gResTexts[TX_MAPED_VIEW_MINING_RADIUS], fntAntiqua);
  CheckBox_ShowMiningRadius.Checked := False; //Disabled by default
  CheckBox_ShowMiningRadius.OnClick := Extra_Change;
  CheckBox_ShowTowersAttackRadius := TKMCheckBox.Create(Panel_Extra, 300, 190, 280, 20, gResTexts[TX_MAPED_VIEW_TOWERS_ATTACK_RADIUS], fntAntiqua);
  CheckBox_ShowTowersAttackRadius.Checked := False; //Disabled by default
  CheckBox_ShowTowersAttackRadius.OnClick := Extra_Change;
  CheckBox_ShowUnitsAttackRadius := TKMCheckBox.Create(Panel_Extra, 300, 210, 280, 20, gResTexts[TX_MAPED_VIEW_UNITS_ATTACK_RADIUS], fntAntiqua);
  CheckBox_ShowUnitsAttackRadius.Checked := False; //Disabled by default
  CheckBox_ShowUnitsAttackRadius.OnClick := Extra_Change;
  CheckBox_ShowDefences := TKMCheckBox.Create(Panel_Extra, 300, 230, 280, 20, gResTexts[TX_MAPED_VIEW_DEFENCES], fntAntiqua);
  CheckBox_ShowDefences.Checked := False; //Disabled by default
  CheckBox_ShowDefences.OnClick := Extra_Change;
  CheckBox_ShowFlatTerrain := TKMCheckBox.Create(Panel_Extra, 300, 250, 280, 20, gResTexts[TX_MAPED_VIEW_FLAT_TERRAIN], fntAntiqua);
  CheckBox_ShowFlatTerrain.Checked := False; //Disabled by default
  CheckBox_ShowFlatTerrain.OnClick := Extra_Change;

  CheckBox_ShowTilesOwner := TKMCheckBox.Create(Panel_Extra, 50, 170, 220, 20, gResTexts[TX_MAPED_SHOW_TILE_OWNERS], fntAntiqua);
  CheckBox_ShowTilesOwner.Checked := False; //Disabled by default
  CheckBox_ShowTilesOwner.OnClick := Extra_Change;
  CheckBox_ShowTilesGrid := TKMCheckBox.Create(Panel_Extra, 50, 190, 220, 20, gResTexts[TX_MAPED_SHOW_TILES_GRID], fntAntiqua);
  CheckBox_ShowTilesGrid.Checked := False; //Disabled by default
  CheckBox_ShowTilesGrid.OnClick := Extra_Change;

  //dropdown list needs to be ontop other buttons created on Panel_Main
  Dropbox_PlayerFOW := TKMDropList.Create(Panel_Extra, 460, 70, 160, 20, fntMetal, '', bsGame);

  Dropbox_PlayerFOW.Add('Show all', -1);
  for I := 0 to MAX_HANDS - 1 do
    Dropbox_PlayerFOW.Add(Format(gResTexts[TX_PLAYER_X], [I]), I);

  Dropbox_PlayerFOW.Hint := gResTexts[TX_REPLAY_PLAYER_PERSPECTIVE];
  Dropbox_PlayerFOW.OnChange := Extra_FOWChange;
  //todo -cComplicated: This feature isn't working properly yet so it's hidden. FOW should be set by
  // revealers list and current locations of units/houses (must update when they move)
  Dropbox_PlayerFOW.Hide;
end;


procedure TKMMapEdExtras.Extra_Change(Sender: TObject);
begin
  SHOW_TERRAIN_PASS       := TrackBar_Passability.Position;
  SHOW_TERRAIN_TILES_GRID := CheckBox_ShowTilesGrid.Checked;
  SHOW_TILES_OWNER        := CheckBox_ShowTilesOwner.Checked;

  if TrackBar_Passability.Position <> 0 then
    Label_Passability.Caption := PASSABILITY_GUI_TEXT[TKMTerrainPassability(SHOW_TERRAIN_PASS)]
  else
    Label_Passability.Caption := gResTexts[TX_MAPED_PASSABILITY_OFF];

  fOnChange(Self);

  //Call event handlers after we updated visible layers
  if Assigned(gGameApp.OnOptionsChange) then
    gGameApp.OnOptionsChange;
end;


procedure TKMMapEdExtras.Extra_Close(Sender: TObject);
begin
  Hide;
end;


procedure TKMMapEdExtras.Extra_FOWChange(Sender: TObject);
begin
  gMySpectator.FOWIndex := Dropbox_PlayerFOW.GetTag(Dropbox_PlayerFOW.ItemIndex);
  //fGame.Minimap.Update(False); //Force update right now so FOW doesn't appear to lag
end;


procedure TKMMapEdExtras.Hide;
begin
  gSoundPlayer.Play(sfxnMPChatClose);
  Panel_Extra.Hide;
end;


procedure TKMMapEdExtras.Refresh;
begin
  CheckBox_ShowTilesGrid.Checked  := SHOW_TERRAIN_TILES_GRID;
  CheckBox_ShowTilesOwner.Checked := SHOW_TILES_OWNER;
  TrackBar_Passability.Position   := SHOW_TERRAIN_PASS;

  CheckBox_ShowObjects.Checked            := mlObjects            in gGameParams.VisibleLayers;
  CheckBox_ShowHouses.Checked             := mlHouses             in gGameParams.VisibleLayers;
  CheckBox_ShowUnits.Checked              := mlUnits              in gGameParams.VisibleLayers;
  CheckBox_ShowOverlays.Checked           := mlOverlays           in gGameParams.VisibleLayers;
  CheckBox_ShowMiningRadius.Checked       := mlMiningRadius       in gGameParams.VisibleLayers;
  CheckBox_ShowTowersAttackRadius.Checked := mlTowersAttackRadius in gGameParams.VisibleLayers;
  CheckBox_ShowUnitsAttackRadius.Checked  := mlUnitsAttackRadius  in gGameParams.VisibleLayers;
  CheckBox_ShowDefences.Checked           := mlDefencesAll        in gGameParams.VisibleLayers;
  CheckBox_ShowFlatTerrain.Checked        := mlFlatTerrain        in gGameParams.VisibleLayers;
//  CheckBox_ShowDeposits.Checked         := mlDeposits in gGame.MapEditor.VisibleLayers;
end;


procedure TKMMapEdExtras.Show;
begin
  gSoundPlayer.Play(sfxnMPChatOpen);
  Refresh;
  Panel_Extra.Show;
end;


function TKMMapEdExtras.Visible: Boolean;
begin
  Result := Panel_Extra.Visible;
end;


end.

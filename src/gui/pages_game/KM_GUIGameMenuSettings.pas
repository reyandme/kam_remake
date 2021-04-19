unit KM_GUIGameMenuSettings;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Controls, KM_CommonTypes;

type
  TKMGameMenuSettings = class
  private
    fOnChangeSetting: TEvent;
    procedure Menu_Settings_Change(Sender: TObject);
    procedure UpdateControlsPosition;
  protected
    Panel_Settings: TKMPanel;
      CheckBox_Autosave: TKMCheckBox;
      CheckBox_AllyEnemy_ColorMode: TKMCheckBox;
      CheckBox_ReplayAutopauseAtPTEnd: TKMCheckBox;
      CheckBox_ReplaySpecShowBeacons: TKMCheckBox;
      TrackBar_Brightness: TKMTrackBar;
      TrackBar_SFX: TKMTrackBar;
      TrackBar_Music: TKMTrackBar;
      TrackBar_ScrollSpeed: TKMTrackBar;
      CheckBox_MusicOff: TKMCheckBox;
      CheckBox_ShuffleOn: TKMCheckBox;
  public
    constructor Create(aParent: TKMPanel; aOnChangeSetting: TEvent);

    procedure Refresh;
    procedure SetAutosaveEnabled(aEnabled: Boolean);
    procedure Show;
    procedure Hide;
    procedure UpdateView;
    function Visible: Boolean;
  end;


implementation
uses
  KM_GameSettings, KM_ResTexts, KM_ResFonts, KM_InterfaceGame, KM_Music, KM_Sound, KM_Game, KM_GameParams,
  KM_GameTypes;


{ TKMMapEdMenuQuit }
constructor TKMGameMenuSettings.Create(aParent: TKMPanel; aOnChangeSetting: TEvent);
const
  PAD = 3;
  WID = TB_WIDTH - PAD * 2;
var
  TopPos: Integer;
begin
  inherited Create;

  fOnChangeSetting := aOnChangeSetting;

  Panel_Settings := TKMPanel.Create(aParent, TB_PAD, 44, TB_WIDTH, 412);
    TopPos := 15;
    CheckBox_Autosave := TKMCheckBox.Create(Panel_Settings,PAD,TopPos,WID,20,gResTexts[TX_MENU_OPTIONS_AUTOSAVE],fntMetal);
    CheckBox_Autosave.OnClick := Menu_Settings_Change;
    Inc(TopPos, 25);

    CheckBox_AllyEnemy_ColorMode := TKMCheckBox.Create(Panel_Settings,PAD,TopPos,WID,20,gResTexts[TX_GAME_SETTINGS_COLOR_MODE],fntMetal);
    CheckBox_AllyEnemy_ColorMode.Hint := gResTexts[TX_GAME_SETTINGS_COLOR_MODE_HINT];
    CheckBox_AllyEnemy_ColorMode.OnClick := Menu_Settings_Change;
    Inc(TopPos, 40);

    CheckBox_ReplayAutopauseAtPTEnd := TKMCheckBox.Create(Panel_Settings,PAD,TopPos,WID,20,gResTexts[TX_GAME_SETTINGS_REPLAY_AUTOPAUSE],fntMetal);
    CheckBox_ReplayAutopauseAtPTEnd.Hint := gResTexts[TX_GAME_SETTINGS_REPLAY_AUTOPAUSE_HINT];
    CheckBox_ReplayAutopauseAtPTEnd.OnClick := Menu_Settings_Change;
    Inc(TopPos, 40);
    CheckBox_ReplaySpecShowBeacons := TKMCheckBox.Create(Panel_Settings,PAD,TopPos,WID,20,gResTexts[TX_GAME_SETTINGS_SHOW_BEACONS],fntMetal);
    CheckBox_ReplaySpecShowBeacons.Hint := gResTexts[TX_GAME_SETTINGS_SHOW_BEACONS_HINT];
    CheckBox_ReplaySpecShowBeacons.OnClick := Menu_Settings_Change;
    Inc(TopPos, 25);
    TrackBar_Brightness := TKMTrackBar.Create(Panel_Settings,PAD,TopPos,WID,0,20);
    TrackBar_Brightness.Caption := gResTexts[TX_MENU_OPTIONS_BRIGHTNESS];
    TrackBar_Brightness.OnChange := Menu_Settings_Change;
    Inc(TopPos, 55);
    TrackBar_ScrollSpeed := TKMTrackBar.Create(Panel_Settings,PAD,TopPos,WID,0,20);
    TrackBar_ScrollSpeed.Caption := gResTexts[TX_MENU_OPTIONS_SCROLL_SPEED];
    TrackBar_ScrollSpeed.OnChange := Menu_Settings_Change;
    Inc(TopPos, 55);
    TrackBar_SFX := TKMTrackBar.Create(Panel_Settings,PAD,TopPos,WID,0,20);
    TrackBar_SFX.Caption := gResTexts[TX_MENU_SFX_VOLUME];
    TrackBar_SFX.Hint := gResTexts[TX_MENU_SFX_VOLUME_HINT];
    TrackBar_SFX.OnChange := Menu_Settings_Change;
    Inc(TopPos, 55);
    TrackBar_Music := TKMTrackBar.Create(Panel_Settings,PAD,TopPos,WID,0,20);
    TrackBar_Music.Caption := gResTexts[TX_MENU_MUSIC_VOLUME];
    TrackBar_Music.Hint := gResTexts[TX_MENU_MUSIC_VOLUME_HINT];
    TrackBar_Music.OnChange := Menu_Settings_Change;
    Inc(TopPos, 55);
    CheckBox_MusicOff := TKMCheckBox.Create(Panel_Settings,PAD,TopPos,WID,20,gResTexts[TX_MENU_OPTIONS_MUSIC_DISABLE_SHORT],fntMetal);
    CheckBox_MusicOff.Hint := gResTexts[TX_MENU_OPTIONS_MUSIC_DISABLE_HINT];
    CheckBox_MusicOff.OnClick := Menu_Settings_Change;
    Inc(TopPos, 25);
    CheckBox_ShuffleOn := TKMCheckBox.Create(Panel_Settings,PAD,TopPos,WID,20,gResTexts[TX_MENU_OPTIONS_MUSIC_SHUFFLE_SHORT],fntMetal);
    CheckBox_ShuffleOn.Hint := gResTexts[TX_MENU_OPTIONS_MUSIC_SHUFFLE_HINT];
    CheckBox_ShuffleOn.OnClick := Menu_Settings_Change;
end;


procedure TKMGameMenuSettings.UpdateView;
begin
  CheckBox_ReplayAutopauseAtPTEnd.Enabled := (gGameParams.Mode = gmReplayMulti) and gGame.IsPeaceTime;
  CheckBox_AllyEnemy_ColorMode.Checked := gGameSettings.PlayersColorMode = pcmAllyEnemy;
end;


procedure TKMGameMenuSettings.UpdateControlsPosition;
var
  Top: Integer;
begin
  Top := 15;

  if gGameParams.IsReplay then
    CheckBox_Autosave.Hide
  else begin
    CheckBox_Autosave.DoSetVisible;
    Inc(Top, 25);
  end;

  CheckBox_AllyEnemy_ColorMode.Top := Top;
  CheckBox_AllyEnemy_ColorMode.DoSetVisible;
  Inc(Top, 40);

  if gGameParams.Mode = gmReplayMulti then
  begin
    CheckBox_ReplayAutopauseAtPTEnd.Top := Top;
    CheckBox_ReplayAutopauseAtPTEnd.DoSetVisible;
    Inc(Top, 40);
  end else
    CheckBox_ReplayAutopauseAtPTEnd.Hide;

  if gGameParams.Mode in [gmReplaySingle, gmReplayMulti, gmMultiSpectate] then
  begin
    CheckBox_ReplaySpecShowBeacons.Top := Top;
    CheckBox_ReplaySpecShowBeacons.DoSetVisible;
    Inc(Top, 25);
  end else
    CheckBox_ReplaySpecShowBeacons.Hide;

  TrackBar_Brightness.Top := Top;
  Inc(Top, 55);
  TrackBar_ScrollSpeed.Top := Top;
  Inc(Top, 55);
  TrackBar_SFX.Top := Top;
  Inc(Top, 55);
  TrackBar_Music.Top := Top;
  Inc(Top, 55);
  CheckBox_MusicOff.Top := Top;
  Inc(Top, 25);
  CheckBox_ShuffleOn.Top := Top;

  Panel_Settings.Height := CheckBox_ShuffleOn.Top + CheckBox_ShuffleOn.Height + 2;
end;

procedure TKMGameMenuSettings.Refresh;
begin
  TrackBar_Brightness.Position     := gGameSettings.Brightness;
  CheckBox_Autosave.Checked        := gGameSettings.Autosave;
  CheckBox_ReplayAutopauseAtPTEnd.Checked := gGameSettings.ReplayAutopause;
  TrackBar_ScrollSpeed.Position    := gGameSettings.ScrollSpeed;
  TrackBar_SFX.Position            := Round(gGameSettings.SoundFXVolume * TrackBar_SFX.MaxValue);
  TrackBar_Music.Position          := Round(gGameSettings.MusicVolume * TrackBar_Music.MaxValue);
  CheckBox_MusicOff.Checked        := gGameSettings.MusicOff;
  CheckBox_ShuffleOn.Checked       := gGameSettings.ShuffleOn;
  CheckBox_AllyEnemy_ColorMode.Checked := gGameSettings.PlayersColorMode = pcmAllyEnemy;

  if gGameParams.IsReplay then
    CheckBox_ReplaySpecShowBeacons.Checked := gGameSettings.ReplayShowBeacons
  else if gGameParams.Mode = gmMultiSpectate then
    CheckBox_ReplaySpecShowBeacons.Checked := gGameSettings.SpecShowBeacons;

  TrackBar_Music.Enabled           := not CheckBox_MusicOff.Checked;
  CheckBox_ShuffleOn.Enabled       := not CheckBox_MusicOff.Checked;
  CheckBox_ReplayAutopauseAtPTEnd.Enabled := (gGameParams.Mode = gmReplayMulti) and gGame.IsPeaceTime;
  UpdateControlsPosition;
end;


procedure TKMGameMenuSettings.Menu_Settings_Change(Sender: TObject);
var
  MusicToggled, ShuffleToggled: Boolean;
begin
  //Change these options only if they changed state since last time
  MusicToggled   := (gGameSettings.MusicOff <> CheckBox_MusicOff.Checked);
  ShuffleToggled := (gGameSettings.ShuffleOn <> CheckBox_ShuffleOn.Checked);

  gGameSettings.Brightness            := TrackBar_Brightness.Position;
  gGameSettings.Autosave              := CheckBox_Autosave.Checked;
  gGameSettings.ReplayAutopause       := CheckBox_ReplayAutopauseAtPTEnd.Checked;
  gGameSettings.ScrollSpeed           := TrackBar_ScrollSpeed.Position;
  gGameSettings.SoundFXVolume         := TrackBar_SFX.Position / TrackBar_SFX.MaxValue;
  gGameSettings.MusicVolume           := TrackBar_Music.Position / TrackBar_Music.MaxValue;
  gGameSettings.MusicOff              := CheckBox_MusicOff.Checked;
  gGameSettings.ShuffleOn             := CheckBox_ShuffleOn.Checked;
  if CheckBox_AllyEnemy_ColorMode.Checked then
    gGameSettings.PlayersColorMode := pcmAllyEnemy
  else
    gGameSettings.PlayersColorMode := pcmDefault;

  if gGameParams.IsReplay then
    gGameSettings.ReplayShowBeacons   := CheckBox_ReplaySpecShowBeacons.Checked
  else if gGameParams.Mode = gmMultiSpectate then
    gGameSettings.SpecShowBeacons   := CheckBox_ReplaySpecShowBeacons.Checked;

  gSoundPlayer.UpdateSoundVolume(gGameSettings.SoundFXVolume);
  gMusic.Volume := gGameSettings.MusicVolume;
  if MusicToggled then
  begin
    gMusic.ToggleEnabled(not gGameSettings.MusicOff);
    if not gGameSettings.MusicOff then
      ShuffleToggled := True; //Re-shuffle songs if music has been enabled
  end;
  if ShuffleToggled then
    gMusic.ToggleShuffle(gGameSettings.ShuffleOn);

  TrackBar_Music.Enabled := not CheckBox_MusicOff.Checked;
  CheckBox_ShuffleOn.Enabled := not CheckBox_MusicOff.Checked;


  if Assigned(fOnChangeSetting) then
    fOnChangeSetting();
end;


procedure TKMGameMenuSettings.Hide;
begin
  Panel_Settings.Hide;
end;


procedure TKMGameMenuSettings.SetAutosaveEnabled(aEnabled: Boolean);
begin
  CheckBox_Autosave.Enabled := aEnabled;
end;


procedure TKMGameMenuSettings.Show;
begin
  Panel_Settings.Show;
end;


function TKMGameMenuSettings.Visible: Boolean;
begin
  Result := Panel_Settings.Visible;
end;


end.

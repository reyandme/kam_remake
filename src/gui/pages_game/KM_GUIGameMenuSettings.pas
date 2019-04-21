unit KM_GUIGameMenuSettings;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Controls, KM_Defaults, KM_CommonTypes;

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

    procedure Menu_Settings_Fill;
    procedure SetAutosaveEnabled(aEnabled: Boolean);
    procedure Show;
    procedure Hide;
    procedure UpdateView;
    function Visible: Boolean;
  end;


implementation
uses
  KM_GameApp, KM_ResTexts, KM_RenderUI, KM_ResFonts, KM_InterfaceGame, KM_Sound, KM_Game,
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
  CheckBox_ReplayAutopauseAtPTEnd.Enabled := (gGame.GameMode = gmReplayMulti) and gGame.IsPeaceTime;
  CheckBox_AllyEnemy_ColorMode.Checked := gGameApp.GameSettings.PlayersColorMode = pcmAllyEnemy;
end;


procedure TKMGameMenuSettings.UpdateControlsPosition;
var
  Top: Integer;
begin
  Top := 15;

  if gGame.IsReplay then
    CheckBox_Autosave.Hide
  else begin
    CheckBox_Autosave.Show;
    Inc(Top, 25);
  end;

  CheckBox_AllyEnemy_ColorMode.Top := Top;
  CheckBox_AllyEnemy_ColorMode.Show;
  Inc(Top, 40);

  if gGame.GameMode = gmReplayMulti then
  begin
    CheckBox_ReplayAutopauseAtPTEnd.Top := Top;
    CheckBox_ReplayAutopauseAtPTEnd.Show;
    Inc(Top, 40);
  end else
    CheckBox_ReplayAutopauseAtPTEnd.Hide;

  if gGame.GameMode in [gmReplaySingle, gmReplayMulti, gmMultiSpectate] then
  begin
    CheckBox_ReplaySpecShowBeacons.Top := Top;
    CheckBox_ReplaySpecShowBeacons.Show;
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

procedure TKMGameMenuSettings.Menu_Settings_Fill;
begin
  TrackBar_Brightness.Position     := gGameApp.GameSettings.Brightness;
  CheckBox_Autosave.Checked        := gGameApp.GameSettings.Autosave;
  CheckBox_ReplayAutopauseAtPTEnd.Checked := gGameApp.GameSettings.ReplayAutopause;
  TrackBar_ScrollSpeed.Position    := gGameApp.GameSettings.ScrollSpeed;
  TrackBar_SFX.Position            := Round(gGameApp.GameSettings.SoundFXVolume * TrackBar_SFX.MaxValue);
  TrackBar_Music.Position          := Round(gGameApp.GameSettings.MusicVolume * TrackBar_Music.MaxValue);
  CheckBox_MusicOff.Checked        := gGameApp.GameSettings.MusicOff;
  CheckBox_ShuffleOn.Checked       := gGameApp.GameSettings.ShuffleOn;
  CheckBox_AllyEnemy_ColorMode.Checked := gGameApp.GameSettings.PlayersColorMode = pcmAllyEnemy;

  if gGame.IsReplay then
    CheckBox_ReplaySpecShowBeacons.Checked := gGameApp.GameSettings.ReplayShowBeacons
  else if gGame.GameMode = gmMultiSpectate then
    CheckBox_ReplaySpecShowBeacons.Checked := gGameApp.GameSettings.SpecShowBeacons;

  TrackBar_Music.Enabled           := not CheckBox_MusicOff.Checked;
  CheckBox_ShuffleOn.Enabled       := not CheckBox_MusicOff.Checked;
  CheckBox_ReplayAutopauseAtPTEnd.Enabled := (gGame.GameMode = gmReplayMulti) and gGame.IsPeaceTime;
  UpdateControlsPosition;
end;


procedure TKMGameMenuSettings.Menu_Settings_Change(Sender: TObject);
var
  MusicToggled, ShuffleToggled: Boolean;
begin
  //Change these options only if they changed state since last time
  MusicToggled   := (gGameApp.GameSettings.MusicOff <> CheckBox_MusicOff.Checked);
  ShuffleToggled := (gGameApp.GameSettings.ShuffleOn <> CheckBox_ShuffleOn.Checked);

  gGameApp.GameSettings.Brightness            := TrackBar_Brightness.Position;
  gGameApp.GameSettings.Autosave              := CheckBox_Autosave.Checked;
  gGameApp.GameSettings.ReplayAutopause       := CheckBox_ReplayAutopauseAtPTEnd.Checked;
  gGameApp.GameSettings.ScrollSpeed           := TrackBar_ScrollSpeed.Position;
  gGameApp.GameSettings.SoundFXVolume         := TrackBar_SFX.Position / TrackBar_SFX.MaxValue;
  gGameApp.GameSettings.MusicVolume           := TrackBar_Music.Position / TrackBar_Music.MaxValue;
  gGameApp.GameSettings.MusicOff              := CheckBox_MusicOff.Checked;
  gGameApp.GameSettings.ShuffleOn             := CheckBox_ShuffleOn.Checked;
  if CheckBox_AllyEnemy_ColorMode.Checked then
    gGameApp.GameSettings.PlayersColorMode := pcmAllyEnemy
  else
    gGameApp.GameSettings.PlayersColorMode := pcmColors;

  if gGame.IsReplay then
    gGameApp.GameSettings.ReplayShowBeacons   := CheckBox_ReplaySpecShowBeacons.Checked
  else if gGame.GameMode = gmMultiSpectate then
    gGameApp.GameSettings.SpecShowBeacons   := CheckBox_ReplaySpecShowBeacons.Checked;

  gSoundPlayer.UpdateSoundVolume(gGameApp.GameSettings.SoundFXVolume);
  gGameApp.MusicLib.UpdateMusicVolume(gGameApp.GameSettings.MusicVolume);
  if MusicToggled then
  begin
    gGameApp.MusicLib.ToggleMusic(not gGameApp.GameSettings.MusicOff);
    if not gGameApp.GameSettings.MusicOff then
      ShuffleToggled := True; //Re-shuffle songs if music has been enabled
  end;
  if ShuffleToggled then
    gGameApp.MusicLib.ToggleShuffle(gGameApp.GameSettings.ShuffleOn);

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

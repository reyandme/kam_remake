unit KM_GUIMenuOptions;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils,
  KM_Controls,
  KromOGLUtils,
  KM_MainSettings,
  KM_Pics, KM_Resolutions, KM_ResKeys, KM_GUICommonKeys,
  KM_InterfaceDefaults, KM_InterfaceTypes, KM_CommonTypes;


type
  TKMMenuOptions = class(TKMMenuPageCommon)
  private
    fGuiCommonKeys: TKMGUICommonKeys;

    fLastAlphaShadows: Boolean;

    fOnPageChange: TKMMenuChangeEventText; // will be in ancestor class

    fMainSettings: TKMainSettings;
    fResolutions: TKMResolutions;

    // We remember old values to enable/disable "Apply" button dynamicaly
    fPrevResolutionId: TKMScreenResIndex;
    // Try to pick the same refresh rate on resolution change
    fDesiredRefRate: Integer;

    procedure ApplyResolution(Sender: TObject);
    procedure TestVideo_Click(Sender: TObject);
    procedure Change(Sender: TObject);
    procedure ChangeResolution(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure EscKeyDown(Sender: TObject);
    procedure FlagClick(Sender: TObject);
    procedure RefreshResolutions;
    procedure KeysClick(Sender: TObject);

    procedure Init;
  protected
    Panel_Options: TKMPanel;
      Panel_Options_GFX: TKMPanel;
        CheckBox_Options_LerpRender: TKMCheckBox;
        CheckBox_Options_LerpAnims: TKMCheckBox;
        CheckBox_Options_VSync: TKMCheckBox;
        CheckBox_Options_ShadowQuality: TKMCheckBox;
        TrackBar_Options_Brightness: TKMTrackBar;
      Panel_Options_Video: TKMPanel;
        CheckBox_Options_VideoEnable: TKMCheckBox;
        CheckBox_Options_VideoStartup: TKMCheckBox;
        CheckBox_Options_VideoStretch: TKMCheckBox;
        TrackBar_Options_VideoVolume: TKMTrackBar;
        Button_Options_VideoTest: TKMButton;

      Panel_Options_Fonts: TKMPanel;
        CheckBox_Options_FullFonts: TKMCheckBox;
      Panel_Options_Ctrl: TKMPanel;
        TrackBar_Options_ScrollSpeed: TKMTrackBar;
      Panel_Options_Game: TKMPanel;
        CheckBox_Options_Autosave: TKMCheckBox;
        CheckBox_Options_AutosaveAtGameEnd: TKMCheckBox;
        CheckBox_MakeSavePoints: TKMCheckBox;
        CheckBox_SaveWareDistribution: TKMCheckBox;
      Panel_Options_Replays: TKMPanel;
        CheckBox_Options_ReplayAutopause: TKMCheckBox;
      Panel_Options_Mods: TKMPanel;
        CheckBox_Options_SnowHouses: TKMCheckBox;
      Panel_Options_Sound: TKMPanel;
        Label_Options_MusicOff: TKMLabel;
        TrackBar_Options_SFX,TrackBar_Options_Music: TKMTrackBar;
        CheckBox_Options_MusicOff: TKMCheckBox;
        CheckBox_Options_ShuffleOn: TKMCheckBox;
      Panel_Options_Lang: TKMPanel;
        Radio_Options_Lang: TKMRadioGroup;
        Image_Options_Lang_Flags: array of TKMImage;
      Panel_Options_Res: TKMPanel;
        CheckBox_Options_FullScreen: TKMCheckBox;
        DropBox_Options_Resolution: TKMDropList;
        DropBox_Options_RefreshRate: TKMDropList;
        Button_Options_ResApply: TKMButton;
      Button_OptionsKeys: TKMButton;
      Button_OptionsBack: TKMButton;
  public
    OnToggleLocale: TKMToggleLocaleEvent;
    OnOptionsChange: TEvent;
    OnPreloadGameResources: TEvent;

    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText; aOnKeysUpdated: TEvent);
    destructor Destroy; override;

    procedure Refresh;
    function Visible: Boolean;
    procedure Show;
  end;


implementation
uses
  KM_Main, KM_Music, KM_Sound, KM_RenderUI, KM_Resource, KM_ResTexts, KM_ResLocales, KM_ResFonts, KM_ResSound, KM_Video,
  KM_ResTypes,
  KM_GameSettings,
  KM_GameAppSettings;


{ TKMGUIMainOptions }
constructor TKMMenuOptions.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText; aOnKeysUpdated: TEvent);

const
  BLOCK_SPAN = 18;

  function NextBlock(var aTop: Integer; aCtrl: TKMControl; aAdj: Integer = 0): Integer;
  begin
    aTop := aCtrl.Bottom + BLOCK_SPAN + aAdj;
    Result := aTop;
  end;

var
  I, top, bottomLine, lineCnt, panelTop: Integer;
  str: string;
begin
  inherited Create(gpOptions);

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := EscKeyDown;
  // We cant pass pointers to Settings in here cos on GUI creation fMain/gGameApp are not initialized yet

  panelTop := (aParent.Height - 620) div 2 - 20;
  Panel_Options := TKMPanel.Create(aParent,(aParent.Width - 880) div 2, panelTop, 880, aParent.Height - panelTop);
  Panel_Options.AnchorsStretch;

  with TKMImage.Create(Panel_Options,705 - Panel_Options.Left,220 - Panel_Options.Top,round(207*1.3),round(295*1.3),6,rxGuiMain) do
  begin
    ImageStretch;
    Anchors := [anLeft];
  end;

    //--- Column 1 --------------------------------------------------------------

    top := 0;
    bottomLine := 30 + gResLocales.Count*20 + 10;

    // Resolutions section
    Panel_Options_Res := TKMPanel.Create(Panel_Options, 0, top, 280, 175);
    NextBlock(top, Panel_Options_Res);
    Panel_Options_Res.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Res, 6, 0, 270, 20, gResTexts[TX_MENU_OPTIONS_RESOLUTION], fntOutline, taLeft);
      TKMBevel.Create(Panel_Options_Res, 0, 20, 280, Panel_Options_Res.Height - 20);

      CheckBox_Options_FullScreen := TKMCheckBox.Create(Panel_Options_Res, 10, 30, 260, 20, gResTexts[TX_MENU_OPTIONS_FULLSCREEN], fntMetal);
      CheckBox_Options_FullScreen.OnClick := ChangeResolution;

      DropBox_Options_Resolution := TKMDropList.Create(Panel_Options_Res, 10, 50, 260, 20, fntMetal, '', bsMenu);
      DropBox_Options_Resolution.OnChange := ChangeResolution;

      DropBox_Options_RefreshRate := TKMDropList.Create(Panel_Options_Res, 10, 85, 260, 20, fntMetal, '', bsMenu);
      DropBox_Options_RefreshRate.OnChange := ChangeResolution;

      Button_Options_ResApply := TKMButton.Create(Panel_Options_Res, 10, 125, 260, 30, gResTexts[TX_MENU_OPTIONS_APPLY], bsMenu);
      Button_Options_ResApply.OnClick := ApplyResolution;

    // Graphics section
    Panel_Options_GFX := TKMPanel.Create(Panel_Options, 0, top, 280, 165);
    NextBlock(top, Panel_Options_GFX);
    Panel_Options_GFX.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_GFX,6,0,270,20,gResTexts[TX_MENU_OPTIONS_GRAPHICS],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_GFX,0,20,280,145);

      CheckBox_Options_LerpRender := TKMCheckBox.Create(Panel_Options_GFX, 10, 30, 260, 20, gResTexts[TX_MENU_OPTIONS_LERP_RENDER], fntMetal);
      CheckBox_Options_LerpRender.Hint := gResTexts[TX_SETTINGS_LERP_RENDER_HINT];
      CheckBox_Options_LerpRender.OnClick := Change;

      CheckBox_Options_LerpAnims := TKMCheckBox.Create(Panel_Options_GFX, 10, 50, 260, 20, gResTexts[TX_MENU_OPTIONS_LERP_ANIMS], fntMetal);
      CheckBox_Options_LerpAnims.Hint := gResTexts[TX_SETTINGS_LERP_ANIMS_HINT];
      CheckBox_Options_LerpAnims.OnClick := Change;

      CheckBox_Options_VSync := TKMCheckBox.Create(Panel_Options_GFX, 10, 70, 260, 20, gResTexts[TX_MENU_OPTIONS_VSYNC], fntMetal);
      CheckBox_Options_VSync.OnClick := Change;

      CheckBox_Options_ShadowQuality := TKMCheckBox.Create(Panel_Options_GFX, 10, 90, 260, 20, gResTexts[TX_MENU_OPTIONS_SHADOW_QUALITY], fntMetal);
      CheckBox_Options_ShadowQuality.OnClick := Change;

      TrackBar_Options_Brightness := TKMTrackBar.Create(Panel_Options_GFX, 10, 110, 256, OPT_SLIDER_MIN,OPT_SLIDER_MAX);
      TrackBar_Options_Brightness.Caption := gResTexts[TX_MENU_OPTIONS_BRIGHTNESS];
      TrackBar_Options_Brightness.OnChange:=Change;

    // Videos
    Panel_Options_Video := TKMPanel.Create(Panel_Options, 0, top, 280, 195);
    NextBlock(top, Panel_Options_Video);
    Panel_Options_Video.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Video,6,0,270,20,gResTexts[TX_MENU_OPTIONS_VIDEOS],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Video,0,20,280,175);
      CheckBox_Options_VideoEnable := TKMCheckBox.Create(Panel_Options_Video, 10, 30, 260, 20, gResTexts[TX_MENU_OPTIONS_VIDEOS_ENABLE], fntMetal);
      CheckBox_Options_VideoEnable.OnClick := Change;
      CheckBox_Options_VideoStretch := TKMCheckBox.Create(Panel_Options_Video, 10, 50, 260, 20, gResTexts[TX_MENU_OPTIONS_VIDEOS_STRETCH], fntMetal);
      CheckBox_Options_VideoStretch.OnClick := Change;
      CheckBox_Options_VideoStartup := TKMCheckBox.Create(Panel_Options_Video, 10, 70, 260, 20, gResTexts[TX_MENU_OPTIONS_VIDEOS_STARTUP], fntMetal);
      CheckBox_Options_VideoStartup.OnClick := Change;
      TrackBar_Options_VideoVolume := TKMTrackBar.Create(Panel_Options_Video, 10, 90, 256, OPT_SLIDER_MIN, OPT_SLIDER_MAX);
      TrackBar_Options_VideoVolume.Caption := gResTexts[TX_MENU_OPTIONS_VIDEOS_VOLUME];
      TrackBar_Options_VideoVolume.OnChange := Change;

      Button_Options_VideoTest := TKMButton.Create(Panel_Options_Video, 10, 150, 260, 30, gResTexts[TX_MENU_OPTIONS_VIDEOS_TEST], bsMenu);
      Button_Options_VideoTest.OnClick := TestVideo_Click;

    Panel_Options_Video.Visible := gVideoPlayer.PlayerEnabled;

    {$IFNDEF VIDEOS}
    Panel_Options_Video.Hide; //Hide panel when no videos defined
    {$ENDIF}

    // Back button
    Button_OptionsBack := TKMButton.Create(Panel_Options, 0, bottomLine, 280, 30, gResTexts[TX_MENU_BACK], bsMenu);
    Button_OptionsBack.Anchors := [anLeft];
    Button_OptionsBack.OnClick := BackClick;

    //--- Column 2 --------------------------------------------------------------

    top := 0;
    // SFX section
    Panel_Options_Sound := TKMPanel.Create(Panel_Options, 300, top, 280, 175);
    NextBlock(top, Panel_Options_Sound);
    Panel_Options_Sound.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Sound,6,0,270,20,gResTexts[TX_MENU_OPTIONS_SOUND],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Sound,0,20,280,Panel_Options_Sound.Height - 20);

      TrackBar_Options_SFX       := TKMTrackBar.Create(Panel_Options_Sound, 10, 27, 256, OPT_SLIDER_MIN, OPT_SLIDER_MAX);
      TrackBar_Options_Music     := TKMTrackBar.Create(Panel_Options_Sound, 10, 77, 256, OPT_SLIDER_MIN, OPT_SLIDER_MAX);
      CheckBox_Options_MusicOff  := TKMCheckBox.Create(Panel_Options_Sound, 10, 127, 256, 20, gResTexts[TX_MENU_OPTIONS_MUSIC_DISABLE], fntMetal);
      CheckBox_Options_ShuffleOn := TKMCheckBox.Create(Panel_Options_Sound, 10, 147, 256, 20, gResTexts[TX_MENU_OPTIONS_MUSIC_SHUFFLE], fntMetal);
      TrackBar_Options_SFX.Caption   := gResTexts[TX_MENU_SFX_VOLUME];
      TrackBar_Options_Music.Caption := gResTexts[TX_MENU_MUSIC_VOLUME];
      TrackBar_Options_SFX.OnChange      := Change;
      TrackBar_Options_Music.OnChange    := Change;
      CheckBox_Options_MusicOff.OnClick  := Change;
      CheckBox_Options_ShuffleOn.OnClick := Change;

    // Controls section
    Panel_Options_Ctrl := TKMPanel.Create(Panel_Options, 300, top, 280, 145);
    NextBlock(top, Panel_Options_Ctrl);
    Panel_Options_Ctrl.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Ctrl,6,0,270,20,gResTexts[TX_MENU_OPTIONS_CONTROLS],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Ctrl,0,20,280,105);

      TrackBar_Options_ScrollSpeed := TKMTrackBar.Create(Panel_Options_Ctrl,10,27,256,OPT_SLIDER_MIN,OPT_SLIDER_MAX);
      TrackBar_Options_ScrollSpeed.Caption := gResTexts[TX_MENU_OPTIONS_SCROLL_SPEED];
      TrackBar_Options_ScrollSpeed.OnChange := Change;

      // Keybindings button
      Button_OptionsKeys := TKMButton.Create(Panel_Options_Ctrl, 10, 77, 260, 30, gResTexts[TX_MENU_OPTIONS_KEYBIND], bsMenu);
      Button_OptionsKeys.Anchors := [anLeft];
      Button_OptionsKeys.OnClick := KeysClick;

    // Gameplay section
    str := gResTexts[TX_MENU_OPTIONS_MAKE_SAVEPOINTS];
    gRes.Fonts[fntMetal].GetTextSize(str, lineCnt);

    Dec(top, 20);
    Panel_Options_Game := TKMPanel.Create(Panel_Options, 300, top, 280, 110 + 20*lineCnt);
    NextBlock(top, Panel_Options_Game, 4);
    Panel_Options_Game.Anchors := [anLeft];

      TKMLabel.Create(Panel_Options_Game,6,0,270,20,gResTexts[TX_MENU_OPTIONS_GAMEPLAY],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Game,0,20,280,Panel_Options_Game.Height - 20);

      CheckBox_Options_Autosave := TKMCheckBox.Create(Panel_Options_Game,10,27,256,20,gResTexts[TX_MENU_OPTIONS_AUTOSAVE], fntMetal);
      CheckBox_Options_Autosave.OnClick := Change;

      CheckBox_Options_AutosaveAtGameEnd := TKMCheckBox.Create(Panel_Options_Game,10,47,256,20,gResTexts[TX_MENU_OPTIONS_AUTOSAVE_AT_GAME_END], fntMetal);
      CheckBox_Options_AutosaveAtGameEnd.OnClick := Change;

      CheckBox_MakeSavePoints := TKMCheckBox.Create(Panel_Options_Game,10,67,256,40,str, fntMetal);
      CheckBox_MakeSavePoints.OnClick := Change;

      CheckBox_SaveWareDistribution := TKMCheckBox.Create(Panel_Options_Game,10,87,256,40,gResTexts[TX_MENU_OPTIONS_SAVE_RESOURCE_DISTRIBUTION], fntMetal);
      CheckBox_SaveWareDistribution.OnClick := Change;


    //Replays section
    Panel_Options_Replays := TKMPanel.Create(Panel_Options,300,top,280,50);
    NextBlock(top, Panel_Options_Replays, 4);
    Panel_Options_Replays.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Replays,6,0,270,20,gResTexts[TX_WORD_REPLAY] + ':',fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Replays,0,20,280,30);

      CheckBox_Options_ReplayAutopause := TKMCheckBox.Create(Panel_Options_Replays,10,27,256,20,gResTexts[TX_SETTINGS_PAUSE_AT_PT_END], fntMetal);
      CheckBox_Options_ReplayAutopause.OnClick := Change;

    // Mods
//    Panel_Options_Mods := TKMPanel.Create(Panel_Options,300,bottomLine-20,280,50);
    Panel_Options_Mods := TKMPanel.Create(Panel_Options,300,top,280,50);
    Panel_Options_Mods.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Mods,6,0,270,20,gResTexts[TX_MENU_OPTIONS_MODS] + ':',fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Mods,0,20,280,30);

      CheckBox_Options_SnowHouses := TKMCheckBox.Create(Panel_Options_Mods,10,27,256,20,gResTexts[TX_MENU_OPTIONS_MODS_SNOW_HOUSES], fntMetal);
      CheckBox_Options_SnowHouses.OnClick := Change;


    //--- Column 3 --------------------------------------------------------------

    top := 0;
    // Language section
    Panel_Options_Lang := TKMPanel.Create(Panel_Options,600,top,240,30+gResLocales.Count*20);
    NextBlock(top, Panel_Options_Lang);
    Panel_Options_Lang.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Lang,6,0,242,20,gResTexts[TX_MENU_OPTIONS_LANGUAGE],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Lang,0,20,280,10+gResLocales.Count*20);

      Radio_Options_Lang := TKMRadioGroup.Create(Panel_Options_Lang, 28, 27, 220, 20*gResLocales.Count, fntMetal);
      SetLength(Image_Options_Lang_Flags,gResLocales.Count);
      for I := 0 to gResLocales.Count - 1 do
      begin
        Radio_Options_Lang.Add(gResLocales[I].Title);
        Image_Options_Lang_Flags[I] := TKMImage.Create(Panel_Options_Lang,6,28+(I*20),16,11, gResLocales[I].FlagSpriteID, rxGuiMain);
        Image_Options_Lang_Flags[I].Tag := I;
        Image_Options_Lang_Flags[I].OnClick := FlagClick;
      end;
      Radio_Options_Lang.OnChange := Change;

    // Language Fonts section

      TKMBevel.Create(Panel_Options_Lang,0,30+gResLocales.Count*20+10,280,30);

      CheckBox_Options_FullFonts := TKMCheckBox.Create(Panel_Options_Lang, 10,30+gResLocales.Count*20+17,220,20, gResTexts[TX_MENU_OPTIONS_FONTS], fntMetal);
      CheckBox_Options_FullFonts.OnClick := Change;

    // Panel_Options_Keys
    fGuiCommonKeys := TKMGUICommonKeys.Create(aParent, aOnKeysUpdated);
end;


destructor TKMMenuOptions.Destroy;
begin
  fGuiCommonKeys.Free;

  inherited;
end;


// This is called when the options page is shown, so update all the values
// Note: Options can be required to fill before gGameApp is completely initialized,
// hence we need to pass either gGameApp.Settings or a direct Settings link
procedure TKMMenuOptions.Refresh;
begin
  Init;

  CheckBox_Options_Autosave.Checked          := gGameSettings.Autosave;
  CheckBox_Options_AutosaveAtGameEnd.Checked := gGameSettings.AutosaveAtGameEnd;
  CheckBox_Options_ReplayAutopause.Checked   := gGameSettings.ReplayAutopause;
  TrackBar_Options_Brightness.Position       := gGameSettings.Brightness;
  CheckBox_Options_LerpRender.Checked        := gGameSettings.InterpolatedRender;
  CheckBox_Options_LerpAnims.Checked         := gGameSettings.InterpolatedAnimations;
  CheckBox_Options_VSync.Checked             := fMainSettings.VSync;
  CheckBox_Options_FullFonts.Enabled         := not gResLocales.LocaleByCode(gGameSettings.Locale).NeedsFullFonts;
  CheckBox_Options_FullFonts.Checked         := gGameSettings.LoadFullFonts or not CheckBox_Options_FullFonts.Enabled;
  CheckBox_Options_ShadowQuality.Checked     := gGameSettings.AlphaShadows;
  TrackBar_Options_ScrollSpeed.Position      := gGameSettings.ScrollSpeed;
  TrackBar_Options_SFX.Position              := Round(gGameSettings.SoundFXVolume * TrackBar_Options_SFX.MaxValue);
  TrackBar_Options_Music.Position            := Round(gGameSettings.MusicVolume * TrackBar_Options_Music.MaxValue);
  CheckBox_Options_MusicOff.Checked          := gGameSettings.MusicOff;
  TrackBar_Options_Music.Enabled             := not CheckBox_Options_MusicOff.Checked;
  CheckBox_Options_ShuffleOn.Checked         := gGameSettings.ShuffleOn;
  CheckBox_Options_ShuffleOn.Enabled         := not CheckBox_Options_MusicOff.Checked;
  CheckBox_Options_VideoEnable.Checked       := gGameSettings.VideoOn;
  CheckBox_Options_VideoStretch.Checked      := gGameSettings.VideoStretch;
  CheckBox_Options_VideoStretch.Enabled      := gGameSettings.VideoOn;
  CheckBox_Options_VideoStartup.Checked      := gGameSettings.VideoStartup;
  CheckBox_Options_VideoStartup.Enabled      := gGameSettings.VideoOn;
  TrackBar_Options_VideoVolume.Position      := Round(gGameSettings.VideoVolume * TrackBar_Options_VideoVolume.MaxValue);
  //Disable Video volume util we will fix it
  //Video volume is set via windows mixer now, and it affect all other game sounds/music after the end of video playback
  TrackBar_Options_VideoVolume.Enabled     := False; //gGameSettings.VideoOn;
  Button_Options_VideoTest.Enabled         := gGameSettings.VideoOn;
  CheckBox_Options_SnowHouses.Checked      := gGameSettings.AllowSnowHouses;
  CheckBox_MakeSavePoints.Checked          := gGameSettings.SaveCheckpoints;
  CheckBox_SaveWareDistribution.Checked    := gGameSettings.SaveWareDistribution;

  Radio_Options_Lang.ItemIndex := gResLocales.IndexByCode(gGameSettings.Locale);

  // We need to reset dropboxes every time we enter Options page
  RefreshResolutions;
end;


// Changed options are saved immediately (cos they are easy to restore/rollback)
procedure TKMMenuOptions.Change(Sender: TObject);
var
  musicToggled, shuffleToggled: Boolean;
begin
  // Change these options only if they changed state since last time
  musicToggled := (gGameSettings.MusicOff <> CheckBox_Options_MusicOff.Checked);
  shuffleToggled := (gGameSettings.ShuffleOn <> CheckBox_Options_ShuffleOn.Checked);

  gGameSettings.Autosave           := CheckBox_Options_Autosave.Checked;
  gGameSettings.AutosaveAtGameEnd  := CheckBox_Options_AutosaveAtGameEnd.Checked;
  gGameSettings.ReplayAutopause    := CheckBox_Options_ReplayAutopause.Checked;
  gGameSettings.Brightness         := TrackBar_Options_Brightness.Position;
  gGameSettings.InterpolatedRender := CheckBox_Options_LerpRender.Checked;
  gGameSettings.InterpolatedAnimations := CheckBox_Options_LerpAnims.Checked;
  fMainSettings.VSync              := CheckBox_Options_VSync.Checked;
  gGameSettings.AlphaShadows       := CheckBox_Options_ShadowQuality.Checked;
  gGameSettings.ScrollSpeed        := TrackBar_Options_ScrollSpeed.Position;
  gGameSettings.SoundFXVolume      := TrackBar_Options_SFX.Position / TrackBar_Options_SFX.MaxValue;
  gGameSettings.MusicVolume        := TrackBar_Options_Music.Position / TrackBar_Options_Music.MaxValue;
  gGameSettings.MusicOff           := CheckBox_Options_MusicOff.Checked;
  gGameSettings.ShuffleOn          := CheckBox_Options_ShuffleOn.Checked;
  gGameSettings.VideoOn            := CheckBox_Options_VideoEnable.Checked;
  gGameSettings.VideoStretch       := CheckBox_Options_VideoStretch.Checked;
  gGameSettings.VideoStartup       := CheckBox_Options_VideoStartup.Checked;
  gGameSettings.VideoVolume        := TrackBar_Options_VideoVolume.Position / TrackBar_Options_VideoVolume.MaxValue;
  gGameSettings.AllowSnowHouses    := CheckBox_Options_SnowHouses.Checked;
  gGameSettings.SaveCheckpoints    := CheckBox_MakeSavePoints.Checked;
  gGameSettings.SaveWareDistribution := CheckBox_SaveWareDistribution.Checked;

  TrackBar_Options_Music.Enabled      := not CheckBox_Options_MusicOff.Checked;
  CheckBox_Options_ShuffleOn.Enabled  := not CheckBox_Options_MusicOff.Checked;

  gSoundPlayer.UpdateSoundVolume(gGameSettings.SoundFXVolume);
  gMusic.Volume := gGameSettings.MusicVolume;
  SetupVSync(fMainSettings.VSync);
  if musicToggled then
  begin
    gMusic.ToggleEnabled(not gGameSettings.MusicOff);
    if not gGameSettings.MusicOff then
      shuffleToggled := True; // Re-shuffle songs if music has been enabled
  end;
  if shuffleToggled then
    gMusic.ToggleShuffle(gGameSettings.ShuffleOn);

  if Sender = CheckBox_Options_FullFonts then
  begin
    gGameSettings.LoadFullFonts := CheckBox_Options_FullFonts.Checked;
    if CheckBox_Options_FullFonts.Checked and (gRes.Fonts.LoadLevel <> fllFull) then
    begin
      // When enabling full fonts, use ToggleLocale reload the entire interface
      if Assigned(OnToggleLocale) then
        OnToggleLocale(gResLocales[Radio_Options_Lang.ItemIndex].Code, gpOptions);
      Exit; // Exit ASAP because whole interface will be recreated
    end;
  end;

  if Sender = Radio_Options_Lang then
  begin
    if Assigned(OnToggleLocale) then
      OnToggleLocale(gResLocales[Radio_Options_Lang.ItemIndex].Code, gpOptions);
    Exit; // Exit ASAP because whole interface will be recreated
  end;

  if Sender = CheckBox_Options_VideoEnable then
  begin
    CheckBox_Options_VideoStartup.Enabled := CheckBox_Options_VideoEnable.Checked;
    CheckBox_Options_VideoStretch.Enabled := CheckBox_Options_VideoEnable.Checked;
    //Disable Video volume util we will fix it
    //Video volume is set via windows mixer now, and it affect all other game sounds/music after the end of video playback
    TrackBar_Options_VideoVolume.Enabled  := False; //CheckBox_Options_VideoEnable.Checked;
    Button_Options_VideoTest.Enabled      := CheckBox_Options_VideoEnable.Checked;
  end;

  if Assigned(OnOptionsChange) then
    OnOptionsChange();
end;


// Apply resolution changes
procedure TKMMenuOptions.ChangeResolution(Sender: TObject);
var
  I: Integer;
  resID, refID: Integer;
begin
  if fResolutions.Count = 0 then Exit;

  DropBox_Options_Resolution.Enabled := CheckBox_Options_FullScreen.Checked;
  DropBox_Options_RefreshRate.Enabled := CheckBox_Options_FullScreen.Checked;

  // Repopulate RefreshRates list
  if Sender = DropBox_Options_Resolution then
  begin
    resID := DropBox_Options_Resolution.ItemIndex;

    // Reset refresh rates, because they are different for each resolution
    DropBox_Options_RefreshRate.Clear;
    for I := 0 to fResolutions.Items[resID].RefRateCount - 1 do
    begin
      DropBox_Options_RefreshRate.Add(Format('%d Hz', [fResolutions.Items[resID].RefRate[I]]));
      // Make sure to select something. SelectedRefRate is prefered, otherwise select first
      if (I = 0) or (fResolutions.Items[resID].RefRate[I] = fDesiredRefRate) then
        DropBox_Options_RefreshRate.ItemIndex := I;
    end;
  end;

  // Make button enabled only if new resolution/mode differs from old
  resID := DropBox_Options_Resolution.ItemIndex;
  refID := DropBox_Options_RefreshRate.ItemIndex;
  Button_Options_ResApply.Enabled :=
      (fMainSettings.FullScreen <> CheckBox_Options_FullScreen.Checked) or
      (CheckBox_Options_FullScreen.Checked and ((fPrevResolutionId.ResID <> resID) or
                                                (fPrevResolutionId.RefID <> refID)));
  // Remember which one we have selected so we can reselect it if the user changes resolution
  fDesiredRefRate := fResolutions.Items[resID].RefRate[refID];
end;


procedure TKMMenuOptions.ApplyResolution(Sender: TObject);
var
  ResID, RefID: Integer;
  NewResolution: TKMScreenRes;
begin
  if fResolutions.Count = 0 then Exit;

  fMainSettings.FullScreen := CheckBox_Options_FullScreen.Checked;

  ResID := DropBox_Options_Resolution.ItemIndex;
  RefID := DropBox_Options_RefreshRate.ItemIndex;
  NewResolution.Width := fResolutions.Items[ResID].Width;
  NewResolution.Height := fResolutions.Items[ResID].Height;
  NewResolution.RefRate := fResolutions.Items[ResID].RefRate[RefID];

  fMainSettings.Resolution := NewResolution;
  gMain.ReinitRender(True);
end;


procedure TKMMenuOptions.TestVideo_Click(Sender: TObject);
begin
  gVideoPlayer.AddVideo('Victory');
  gVideoPlayer.AddVideo('Campaigns\The Shattered Kingdom\Intro');
  gVideoPlayer.AddVideo('Defeat');
  gVideoPlayer.AddVideo('KaM');
  gVideoPlayer.Play;
end;


function TKMMenuOptions.Visible: Boolean;
begin
  Result := Panel_Options.Visible;
end;


procedure TKMMenuOptions.FlagClick(Sender: TObject);
begin
  Assert(Sender is TKMImage);
  Radio_Options_Lang.ItemIndex := TKMImage(Sender).Tag;
  Change(Radio_Options_Lang);
end;


// Resets dropboxes, they will have correct values
procedure TKMMenuOptions.RefreshResolutions;
var
  I: Integer;
  R: TKMScreenResIndex;
begin
  DropBox_Options_Resolution.Clear;
  DropBox_Options_RefreshRate.Clear;

  R := fResolutions.GetResolutionIDs(fMainSettings.Resolution);

  if fResolutions.Count > 0 then
  begin
    for I := 0 to fResolutions.Count - 1 do
    begin
      DropBox_Options_Resolution.Add(Format('%dx%d', [fResolutions.Items[I].Width, fResolutions.Items[I].Height]));
      if (I = 0) or (I = R.ResID) then
        DropBox_Options_Resolution.ItemIndex := I;
    end;

    for I := 0 to fResolutions.Items[R.ResID].RefRateCount - 1 do
    begin
      DropBox_Options_RefreshRate.Add(Format('%d Hz', [fResolutions.Items[R.ResID].RefRate[I]]));
      if (I = 0) or (I = R.RefID) then
      begin
        DropBox_Options_RefreshRate.ItemIndex := I;
        fDesiredRefRate := fResolutions.Items[R.ResID].RefRate[I];
      end;
    end;
  end
  else
  begin
    // No supported resolutions
    DropBox_Options_Resolution.Add(gResTexts[TX_MENU_OPTIONS_RESOLUTION_NOT_SUPPORTED]);
    DropBox_Options_RefreshRate.Add(gResTexts[TX_MENU_OPTIONS_REFRESH_RATE_NOT_SUPPORTED]);
    DropBox_Options_Resolution.ItemIndex := 0;
    DropBox_Options_RefreshRate.ItemIndex := 0;
  end;

  CheckBox_Options_FullScreen.Checked := fMainSettings.FullScreen;
  // Controls should be disabled, when there is no resolution to choose
  CheckBox_Options_FullScreen.Enabled := fResolutions.Count > 0;
  DropBox_Options_Resolution.Enabled  := (fMainSettings.FullScreen) and (fResolutions.Count > 0);
  DropBox_Options_RefreshRate.Enabled := (fMainSettings.FullScreen) and (fResolutions.Count > 0);

  fPrevResolutionId := R;
  Button_Options_ResApply.Disable;
end;


procedure TKMMenuOptions.Init;
begin
  // Remember what we are working with
  // (we do that on Show because Create gets called from Main/Game constructor and fMain/gGameApp are not yet assigned)
  // Ideally we could pass them as parameters here
  fMainSettings := gMain.Settings;
  fResolutions := gMain.Resolutions;
  fLastAlphaShadows := gGameSettings.AlphaShadows;
end;


procedure TKMMenuOptions.Show;
begin
  Refresh;
  Panel_Options.Show;
end;


procedure TKMMenuOptions.KeysClick(Sender: TObject);
begin
  fGuiCommonKeys.Show;
end;


procedure TKMMenuOptions.BackClick(Sender: TObject);
begin
  // Return to MainMenu and restore resolution changes
  gGameAppSettings.SaveSettings;

  if    (fLastAlphaShadows <> gGameSettings.AlphaShadows)
    and Assigned(OnPreloadGameResources) then
    OnPreloadGameResources;  //Update loaded game resources, if we changed alpha shadow setting

  fOnPageChange(gpMainMenu);
end;


procedure TKMMenuOptions.EscKeyDown(Sender: TObject);
begin
  if not fGuiCommonKeys.Visible then
    BackClick(nil);
end;


end.

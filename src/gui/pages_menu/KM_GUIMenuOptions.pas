unit KM_GUIMenuOptions;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls, KromOGLUtils, Math, SysUtils,
  KM_Controls, KM_Settings, KM_Pics, KM_Resolutions, KM_ResKeys,
  KM_InterfaceDefaults;


type
  TKMMenuOptions = class (TKMMenuPageCommon)
  private
    fTempKeys: TKMKeyLibrary;
    fLastAlphaShadows: Boolean;

    fOnPageChange: TKMMenuChangeEventText; // will be in ancestor class

    fMainSettings: TKMainSettings;
    fGameSettings: TKMGameSettings;
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
    procedure KeysRefreshList;
    function KeysUpdate(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
  protected
    Panel_Options: TKMPanel;
      Panel_Options_GFX: TKMPanel;
        TrackBar_Options_Brightness: TKMTrackBar;
        CheckBox_Options_VSync: TKMCheckBox;
      Panel_Options_Video: TKMPanel;
        CheckBox_Options_VideoEnable: TKMCheckBox;
        CheckBox_Options_VideoStartup: TKMCheckBox;
        CheckBox_Options_VideoStretch: TKMCheckBox;
        TrackBar_Options_VideoVolume: TKMTrackBar;
        Button_Options_VideoTest: TKMButton;

      Panel_Options_Fonts: TKMPanel;
        CheckBox_Options_FullFonts: TKMCheckBox;
        CheckBox_Options_ShadowQuality: TKMCheckBox;
      Panel_Options_Ctrl: TKMPanel;
        TrackBar_Options_ScrollSpeed: TKMTrackBar;
      Panel_Options_Game: TKMPanel;
        CheckBox_Options_Autosave: TKMCheckBox;
        CheckBox_Options_AutosaveAtGameEnd: TKMCheckBox;
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
      PopUp_OptionsKeys: TKMPopUpMenu;
        Panel_OptionsKeys: TKMPanel;
          ColumnBox_OptionsKeys: TKMColumnBox;
          Panel_OptionKeys_Btns: TKMPanel;
            Button_OptionsKeysClear: TKMButton;
            Button_OptionsKeysReset: TKMButton;
            Button_OptionsKeysOK: TKMButton;
            Button_OptionsKeysCancel: TKMButton;
      Button_OptionsBack: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    destructor Destroy; override;
    procedure Refresh;
    function Visible: Boolean;
    procedure Show;
  end;


implementation
uses
  KM_Main, KM_GameApp, KM_Sound, KM_RenderUI, KM_Resource, KM_ResTexts, KM_ResLocales, KM_ResFonts, KM_ResSound, KM_Video;


{ TKMGUIMainOptions }
constructor TKMMenuOptions.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);

const
  BLOCK_SPAN = 18;

  function NextBlock(var aTop: Integer; aCtrl: TKMControl; aAdj: Integer = 0): Integer;
  begin
    aTop := aCtrl.Bottom + BLOCK_SPAN + aAdj;
    Result := aTop;
  end;

var
  I, top, bottomLine: Integer;
begin
  inherited Create(gpOptions);

  fTempKeys := TKMKeyLibrary.Create;

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := EscKeyDown;
  // We cant pass pointers to Settings in here cos on GUI creation fMain/gGameApp are not initialized yet

  Panel_Options := TKMPanel.Create(aParent,(aParent.Width - 880) div 2,(aParent.Height - 580) div 2,880, aParent.Height);
  Panel_Options.AnchorsStretch;

  with TKMImage.Create(Panel_Options,705 - Panel_Options.Left,220 - Panel_Options.Top,round(207*1.3),round(295*1.3),6,rxGuiMain) do
  begin
    ImageStretch;
    Anchors := [anLeft];
  end;

    //--- Column 1 --------------------------------------------------------------


    top := 0;
    bottomLine := 30+gResLocales.Count*20+10;

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
    Panel_Options_GFX := TKMPanel.Create(Panel_Options,0,top,280,125);
    NextBlock(top, Panel_Options_GFX);
    Panel_Options_GFX.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_GFX,6,0,270,20,gResTexts[TX_MENU_OPTIONS_GRAPHICS],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_GFX,0,20,280,105);
      CheckBox_Options_VSync := TKMCheckBox.Create(Panel_Options_GFX, 10, 30, 260, 20, gResTexts[TX_MENU_OPTIONS_VSYNC], fntMetal);
      CheckBox_Options_VSync.OnClick := Change;
      CheckBox_Options_ShadowQuality := TKMCheckBox.Create(Panel_Options_GFX, 10, 50, 260, 20, gResTexts[TX_MENU_OPTIONS_SHADOW_QUALITY], fntMetal);
      CheckBox_Options_ShadowQuality.OnClick := Change;
      TrackBar_Options_Brightness:=TKMTrackBar.Create(Panel_Options_GFX,10,70,256,OPT_SLIDER_MIN,OPT_SLIDER_MAX);
      TrackBar_Options_Brightness.Caption := gResTexts[TX_MENU_OPTIONS_BRIGHTNESS];
      TrackBar_Options_Brightness.OnChange:=Change;

    // Videos
    Panel_Options_Video := TKMPanel.Create(Panel_Options,0,top,280,195);
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

    {$IFNDEF VIDEOS}
    Panel_Options_Video.Hide; //Hide panel when no videos defined
    {$ENDIF}

    // Back button
    Button_OptionsBack := TKMButton.Create(Panel_Options,0,bottomLine,280,30,gResTexts[TX_MENU_BACK],bsMenu);
    Button_OptionsBack.Anchors := [anLeft];
    Button_OptionsBack.OnClick := BackClick;

    //--- Column 2 --------------------------------------------------------------

    top := 0;
    // SFX section
    Panel_Options_Sound := TKMPanel.Create(Panel_Options,300,top,280,175);
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
    Panel_Options_Ctrl := TKMPanel.Create(Panel_Options,300,top,280,125);
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
    Panel_Options_Game := TKMPanel.Create(Panel_Options,300,top,280,70);
    NextBlock(top, Panel_Options_Game, -5);
    Panel_Options_Game.Anchors := [anLeft];
      TKMLabel.Create(Panel_Options_Game,6,0,270,20,gResTexts[TX_MENU_OPTIONS_GAMEPLAY],fntOutline,taLeft);
      TKMBevel.Create(Panel_Options_Game,0,20,280,50);

      CheckBox_Options_Autosave := TKMCheckBox.Create(Panel_Options_Game,10,27,256,20,gResTexts[TX_MENU_OPTIONS_AUTOSAVE], fntMetal);
      CheckBox_Options_Autosave.OnClick := Change;

      CheckBox_Options_AutosaveAtGameEnd := TKMCheckBox.Create(Panel_Options_Game,10,47,256,20,gResTexts[TX_MENU_OPTIONS_AUTOSAVE_AT_GAME_END], fntMetal);
      CheckBox_Options_AutosaveAtGameEnd.OnClick := Change;

    //Replays section
    Panel_Options_Replays := TKMPanel.Create(Panel_Options,300,top,280,50);
    NextBlock(top, Panel_Options_Replays, -6);
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
    PopUp_OptionsKeys := TKMPopUpMenu.Create(aParent, 740);
    PopUp_OptionsKeys.Height := 640;
    PopUp_OptionsKeys.AnchorsCenter; // Keep centered, don't stretch already poor BG image
    PopUp_OptionsKeys.Left := (aParent.Width - PopUp_OptionsKeys.Width) div 2;
    PopUp_OptionsKeys.Top := (aParent.Height - PopUp_OptionsKeys.Height) div 2;

      TKMBevel.Create(PopUp_OptionsKeys, -2000, -2000, 5000, 5000);

      TKMImage.Create(PopUp_OptionsKeys, 0, 0, PopUp_OptionsKeys.Width, PopUp_OptionsKeys.Height, 15, rxGuiMain).ImageStretch;

      Panel_OptionsKeys := TKMPanel.Create(PopUp_OptionsKeys, 20, 10, 700, 600);

        TKMLabel.Create(Panel_OptionsKeys, 20, 35, 660, 30, gResTexts[TX_MENU_OPTIONS_KEYBIND], fntOutline, taCenter).Anchors := [anLeft,anBottom];

        ColumnBox_OptionsKeys := TKMColumnBox.Create(Panel_OptionsKeys, 20, 110, 660, 400, fntMetal, bsMenu);
        ColumnBox_OptionsKeys.SetColumns(fntOutline, [gResTexts[TX_MENU_OPTIONS_FUNCTION], gResTexts[TX_MENU_OPTIONS_KEY]], [0, 350]);
        ColumnBox_OptionsKeys.Anchors := [anLeft,anTop,anBottom];
        ColumnBox_OptionsKeys.ShowLines := True;
        ColumnBox_OptionsKeys.PassAllKeys := True;
        ColumnBox_OptionsKeys.OnChange := KeysClick;
        ColumnBox_OptionsKeys.OnKeyUp := KeysUpdate;

        TKMLabel.Create(Panel_OptionsKeys, 20, 520, 660, 30, '* ' + gResTexts[TX_KEY_UNASSIGNABLE], fntMetal, taLeft);

        Panel_OptionKeys_Btns := TKMPanel.Create(Panel_OptionsKeys, 0, 530, Panel_OptionsKeys.Width, Panel_OptionsKeys.Height - 530);

          Button_OptionsKeysClear := TKMButton.Create(Panel_OptionKeys_Btns, 470, 0, 200, 30, gResTexts[TX_MENU_OPTIONS_CLEAR], bsMenu);
          Button_OptionsKeysClear.OnClick := KeysClick;

          Button_OptionsKeysReset := TKMButton.Create(Panel_OptionKeys_Btns, 30, 40, 200, 30, gResTexts[TX_MENU_OPTIONS_RESET], bsMenu);
          Button_OptionsKeysReset.OnClick := KeysClick;

          Button_OptionsKeysOK := TKMButton.Create(Panel_OptionKeys_Btns, 250, 40, 200, 30, gResTexts[TX_MENU_OPTIONS_OK], bsMenu);
          Button_OptionsKeysOK.OnClick := KeysClick;

          Button_OptionsKeysCancel := TKMButton.Create(Panel_OptionKeys_Btns, 470, 40, 200, 30, gResTexts[TX_MENU_OPTIONS_CANCEL], bsMenu);
          Button_OptionsKeysCancel.OnClick := KeysClick;
end;


destructor TKMMenuOptions.Destroy;
begin
  FreeAndNil(fTempKeys);
  inherited;
end;


// This is called when the options page is shown, so update all the values
// Note: Options can be required to fill before gGameApp is completely initialized,
// hence we need to pass either gGameApp.Settings or a direct Settings link
procedure TKMMenuOptions.Refresh;
begin
  CheckBox_Options_Autosave.Checked        := fGameSettings.Autosave;
  CheckBox_Options_AutosaveAtGameEnd.Checked := fGameSettings.AutosaveAtGameEnd;
  CheckBox_Options_ReplayAutopause.Checked := fGameSettings.ReplayAutopause;
  TrackBar_Options_Brightness.Position     := fGameSettings.Brightness;
  CheckBox_Options_VSync.Checked           := fMainSettings.VSync;
  CheckBox_Options_FullFonts.Enabled       := not gResLocales.LocaleByCode(fGameSettings.Locale).NeedsFullFonts;
  CheckBox_Options_FullFonts.Checked       := fGameSettings.LoadFullFonts or not CheckBox_Options_FullFonts.Enabled;
  CheckBox_Options_ShadowQuality.Checked   := fGameSettings.AlphaShadows;
  TrackBar_Options_ScrollSpeed.Position    := fGameSettings.ScrollSpeed;
  TrackBar_Options_SFX.Position            := Round(fGameSettings.SoundFXVolume * TrackBar_Options_SFX.MaxValue);
  TrackBar_Options_Music.Position          := Round(fGameSettings.MusicVolume * TrackBar_Options_Music.MaxValue);
  CheckBox_Options_MusicOff.Checked        := fGameSettings.MusicOff;
  TrackBar_Options_Music.Enabled           := not CheckBox_Options_MusicOff.Checked;
  CheckBox_Options_ShuffleOn.Checked       := fGameSettings.ShuffleOn;
  CheckBox_Options_ShuffleOn.Enabled       := not CheckBox_Options_MusicOff.Checked;
  CheckBox_Options_VideoEnable.Checked     := fGameSettings.VideoOn;
  CheckBox_Options_VideoStretch.Checked    := fGameSettings.VideoStretch;
  CheckBox_Options_VideoStretch.Enabled    := fGameSettings.VideoOn;
  CheckBox_Options_VideoStartup.Checked    := fGameSettings.VideoStartup;
  CheckBox_Options_VideoStartup.Enabled    := fGameSettings.VideoOn;
  TrackBar_Options_VideoVolume.Position    := Round(fGameSettings.VideoVolume * TrackBar_Options_VideoVolume.MaxValue);
  TrackBar_Options_VideoVolume.Enabled     := fGameSettings.VideoOn;
  Button_Options_VideoTest.Enabled         := fGameSettings.VideoOn;
  CheckBox_Options_SnowHouses.Checked      := fGameSettings.AllowSnowHouses;

  Radio_Options_Lang.ItemIndex := gResLocales.IndexByCode(fGameSettings.Locale);

  // We need to reset dropboxes every time we enter Options page
  RefreshResolutions;
end;


// Changed options are saved immediately (cos they are easy to restore/rollback)
procedure TKMMenuOptions.Change(Sender: TObject);
var
  MusicToggled, ShuffleToggled: Boolean;
begin
  // Change these options only if they changed state since last time
  MusicToggled := (fGameSettings.MusicOff <> CheckBox_Options_MusicOff.Checked);
  ShuffleToggled := (fGameSettings.ShuffleOn <> CheckBox_Options_ShuffleOn.Checked);

  fGameSettings.Autosave        := CheckBox_Options_Autosave.Checked;
  fGameSettings.AutosaveAtGameEnd := CheckBox_Options_AutosaveAtGameEnd.Checked;
  fGameSettings.ReplayAutopause := CheckBox_Options_ReplayAutopause.Checked;
  fGameSettings.Brightness      := TrackBar_Options_Brightness.Position;
  fMainSettings.VSync           := CheckBox_Options_VSync.Checked;
  fGameSettings.AlphaShadows    := CheckBox_Options_ShadowQuality.Checked;
  fGameSettings.ScrollSpeed     := TrackBar_Options_ScrollSpeed.Position;
  fGameSettings.SoundFXVolume   := TrackBar_Options_SFX.Position / TrackBar_Options_SFX.MaxValue;
  fGameSettings.MusicVolume     := TrackBar_Options_Music.Position / TrackBar_Options_Music.MaxValue;
  fGameSettings.MusicOff        := CheckBox_Options_MusicOff.Checked;
  fGameSettings.ShuffleOn       := CheckBox_Options_ShuffleOn.Checked;
  fGameSettings.VideoOn         := CheckBox_Options_VideoEnable.Checked;
  fGameSettings.VideoStretch    := CheckBox_Options_VideoStretch.Checked;
  fGameSettings.VideoStartup    := CheckBox_Options_VideoStartup.Checked;
  fGameSettings.VideoVolume     := TrackBar_Options_VideoVolume.Position / TrackBar_Options_VideoVolume.MaxValue;
  fGameSettings.AllowSnowHouses := CheckBox_Options_SnowHouses.Checked;

  TrackBar_Options_Music.Enabled      := not CheckBox_Options_MusicOff.Checked;
  CheckBox_Options_ShuffleOn.Enabled  := not CheckBox_Options_MusicOff.Checked;

  gSoundPlayer.UpdateSoundVolume(fGameSettings.SoundFXVolume);
  gGameApp.MusicLib.UpdateMusicVolume(fGameSettings.MusicVolume);
  SetupVSync(fMainSettings.VSync);
  if MusicToggled then
  begin
    gGameApp.MusicLib.ToggleMusic(not fGameSettings.MusicOff);
    if not fGameSettings.MusicOff then
      ShuffleToggled := True; // Re-shuffle songs if music has been enabled
  end;
  if ShuffleToggled then
    gGameApp.MusicLib.ToggleShuffle(fGameSettings.ShuffleOn);

  if Sender = CheckBox_Options_FullFonts then
  begin
    fGameSettings.LoadFullFonts := CheckBox_Options_FullFonts.Checked;
    if CheckBox_Options_FullFonts.Checked and (gRes.Fonts.LoadLevel <> fllFull) then
    begin
      // When enabling full fonts, use ToggleLocale reload the entire interface
      gGameApp.ToggleLocale(gResLocales[Radio_Options_Lang.ItemIndex].Code);
      Exit; // Exit ASAP because whole interface will be recreated
    end;
  end;

  if Sender = Radio_Options_Lang then
  begin
    gGameApp.ToggleLocale(gResLocales[Radio_Options_Lang.ItemIndex].Code);
    Exit; // Exit ASAP because whole interface will be recreated
  end;

  if Sender = CheckBox_Options_VideoEnable then
  begin
    CheckBox_Options_VideoStartup.Enabled := CheckBox_Options_VideoEnable.Checked;
    CheckBox_Options_VideoStretch.Enabled := CheckBox_Options_VideoEnable.Checked;
    TrackBar_Options_VideoVolume.Enabled  := CheckBox_Options_VideoEnable.Checked;
    Button_Options_VideoTest.Enabled      := CheckBox_Options_VideoEnable.Checked;
  end;

  if Assigned(gGameApp.OnOptionsChange) then
    gGameApp.OnOptionsChange();
end;


// Apply resolution changes
procedure TKMMenuOptions.ChangeResolution(Sender: TObject);
var
  I: Integer;
  ResID, RefID: Integer;
begin
  if fResolutions.Count = 0 then Exit;

  DropBox_Options_Resolution.Enabled := CheckBox_Options_FullScreen.Checked;
  DropBox_Options_RefreshRate.Enabled := CheckBox_Options_FullScreen.Checked;

  // Repopulate RefreshRates list
  if Sender = DropBox_Options_Resolution then
  begin
    ResID := DropBox_Options_Resolution.ItemIndex;

    // Reset refresh rates, because they are different for each resolution
    DropBox_Options_RefreshRate.Clear;
    for I := 0 to fResolutions.Items[ResID].RefRateCount - 1 do
    begin
      DropBox_Options_RefreshRate.Add(Format('%d Hz', [fResolutions.Items[ResID].RefRate[I]]));
      // Make sure to select something. SelectedRefRate is prefered, otherwise select first
      if (I = 0) or (fResolutions.Items[ResID].RefRate[I] = fDesiredRefRate) then
        DropBox_Options_RefreshRate.ItemIndex := I;
    end;
  end;

  // Make button enabled only if new resolution/mode differs from old
  ResID := DropBox_Options_Resolution.ItemIndex;
  RefID := DropBox_Options_RefreshRate.ItemIndex;
  Button_Options_ResApply.Enabled :=
      (fMainSettings.FullScreen <> CheckBox_Options_FullScreen.Checked) or
      (CheckBox_Options_FullScreen.Checked and ((fPrevResolutionId.ResID <> ResID) or
                                                (fPrevResolutionId.RefID <> RefID)));
  // Remember which one we have selected so we can reselect it if the user changes resolution
  fDesiredRefRate := fResolutions.Items[ResID].RefRate[RefID];
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


procedure TKMMenuOptions.Show;
begin
  // Remember what we are working with
  // (we do that on Show because Create gets called from Main/Game constructor and fMain/gGameApp are not yet assigned)
  // Ideally we could pass them as parameters here
  fMainSettings := gMain.Settings;
  fGameSettings := gGameApp.GameSettings;
  fResolutions := gMain.Resolutions;
  fLastAlphaShadows := fGameSettings.AlphaShadows;

  Refresh;
  Panel_Options.Show;
end;


procedure TKMMenuOptions.KeysClick(Sender: TObject);
var I: Integer;
begin
  if Sender = Button_OptionsKeys then
  begin
    // Reload the keymap in case player changed it and checks his changes in game
    gResKeys.LoadKeymapFile;

    // Update TempKeys from gResKeys
    for I := 0 to gResKeys.Count - 1 do
      fTempKeys[I] := gResKeys[I];

    KeysRefreshList;
    PopUp_OptionsKeys.Show;
  end;

  if Sender = Button_OptionsKeysOK then
  begin
    PopUp_OptionsKeys.Hide;

    // Save TempKeys to gResKeys
    for I := 0 to gResKeys.Count - 1 do
      gResKeys[I] := fTempKeys[I];

    gResKeys.SaveKeymap;
  end;

  if Sender = Button_OptionsKeysCancel then
    PopUp_OptionsKeys.Hide;

  if (Sender = Button_OptionsKeysClear) then
    KeysUpdate(Button_OptionsKeysClear, 0, []);

  if Sender = Button_OptionsKeysReset then
  begin
    fTempKeys.ResetKeymap;
    KeysRefreshList;
  end;

  if Sender = ColumnBox_OptionsKeys then
    ColumnBox_OptionsKeys.HighlightError := False;
end;


procedure TKMMenuOptions.KeysRefreshList;

  function GetFunctionName(aTX_ID: Integer): String;
  begin
    case aTX_ID of
      TX_KEY_FUNC_GAME_SPEED_2: Result := Format(gResTexts[aTX_ID], [FormatFloat('##0.##', gGameApp.GameSettings.SpeedMedium)]);
      TX_KEY_FUNC_GAME_SPEED_3: Result := Format(gResTexts[aTX_ID], [FormatFloat('##0.##', gGameApp.GameSettings.SpeedFast)]);
      TX_KEY_FUNC_GAME_SPEED_4: Result := Format(gResTexts[aTX_ID], [FormatFloat('##0.##', gGameApp.GameSettings.SpeedVeryFast)]);
      else                      Result := gResTexts[aTX_ID];

    end;
  end;

const
  KEY_TX: array [TKMFuncArea] of Word = (TX_KEY_COMMON, TX_KEY_GAME, TX_KEY_SPECTATE_REPLAY, TX_KEY_MAPEDIT);
var
  I, prevI: Integer;
  K: TKMFuncArea;
  KeyName: UnicodeString;
begin
  prevI := ColumnBox_OptionsKeys.TopIndex;

  ColumnBox_OptionsKeys.Clear;

  for K := Low(TKMFuncArea) to High(TKMFuncArea) do
  begin
    // Section
    ColumnBox_OptionsKeys.AddItem(MakeListRow([gResTexts[KEY_TX[K]], ' '], [$FF3BB5CF, $FF3BB5CF], [$FF0000FF, $FF0000FF], -1));

    // Do not show the debug keys
    for I := 0 to fTempKeys.Count - 1 do
      if (fTempKeys[I].Area = K) and not fTempKeys[I].IsChangableByPlayer then
      begin
        KeyName := fTempKeys.GetKeyNameById(I);
        if I = SC_DEBUG_WINDOW then
          KeyName := KeyName + ' / Ctrl + ' + KeyName; //Also show Ctrl + F11, for debug window hotkey
        ColumnBox_OptionsKeys.AddItem(MakeListRow([GetFunctionName(fTempKeys[I].TextId), KeyName],
                                                  [$FFFFFFFF, $FFFFFFFF], [$FF0000FF, $FF0000FF], I));
      end;
  end;

  ColumnBox_OptionsKeys.TopIndex := prevI;
end;


function TKMMenuOptions.KeysUpdate(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
var
  id: Integer;
begin
  Result := True; // We handle all keys here
  if ColumnBox_OptionsKeys.ItemIndex = -1 then Exit;

  ColumnBox_OptionsKeys.HighlightError := False;
  id := ColumnBox_OptionsKeys.Rows[ColumnBox_OptionsKeys.ItemIndex].Tag;

  if not InRange(id, 0, fTempKeys.Count - 1) then Exit;

  if not fTempKeys.AllowKeySet(fTempKeys[id].Area, Key) then
  begin
    ColumnBox_OptionsKeys.HighlightError := True;
    gSoundPlayer.Play(sfxnError);
    Exit;
  end;

  fTempKeys.SetKey(id, Key);

  KeysRefreshList;
end;


procedure TKMMenuOptions.BackClick(Sender: TObject);
begin
  // Return to MainMenu and restore resolution changes
  fMainSettings.SaveSettings;

  if fLastAlphaShadows <> fGameSettings.AlphaShadows then
    gGameApp.PreloadGameResources;  //Update loaded game resources, if we changed alpha shadow setting

  fOnPageChange(gpMainMenu);
end;


procedure TKMMenuOptions.EscKeyDown(Sender: TObject);
begin
  if not PopUp_OptionsKeys.Visible then
    BackClick(nil);
end;


end.

unit KM_Settings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC}Forms,{$ENDIF}   //Lazarus do not know UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_Resolutions, KM_WareDistribution, KM_MapTypes,
  KM_Defaults, KM_Points, KM_CommonTypes, KM_CommonClasses;


type

  TKMWindowParamsRecord = record
    Width, Height, Left, Top: SmallInt;
    State: TWindowState;
  end;

  TKMWindowParams = class
  private
    fWidth, fHeight, fLeft, fTop: SmallInt; // Window size/position on the screen
    fState: TWindowState;                   // Window state (wsNormal/wsMaximized)
    fLockParams: Boolean;                   // Lock updating window params, used when Fullscreen turned On
    fIsChanged: Boolean;
    fNeedResetToDefaults: Boolean;          // Flag, when set params should be updated with defaults
  public
    constructor Create;
    property Width: SmallInt read fWidth;
    property Height: SmallInt read fHeight;
    property Left: SmallInt read fLeft;
    property Top: SmallInt read fTop;
    property State: TWindowState read fState;
    property IsChanged: Boolean read fIsChanged;
    property NeedResetToDefaults: Boolean read fNeedResetToDefaults write fNeedResetToDefaults;

    procedure ApplyWindowParams(const aParams: TKMWindowParamsRecord; aDefaults: Boolean = False);
    procedure LockParams;
    procedure UnlockParams;
    function IsValid(aMonitorsInfo: TKMPointArray): Boolean;
  end;


  //Settings that are irrelevant to the game (game does not cares about them)
  //Everything gets written through setter to set fNeedsSave flag
  TKMainSettings = class
  private
    fNeedsSave: Boolean;
    fFullScreen: Boolean;
    fFPSCap: Integer;
    fResolution: TKMScreenRes;
    fWindowParams: TKMWindowParams;
    fVSync: Boolean;
    fNoRenderMaxTime: Integer;     //Longest period of time, when there was no Render (usually on hiiiigh game speed like x300)
    procedure SetFullScreen(aValue: Boolean);
    procedure SetResolution(const Value: TKMScreenRes);
    procedure SetVSync(aValue: Boolean);
  protected
    procedure Changed;
    function LoadFromINI(const aFileName: UnicodeString): Boolean;
    procedure SaveToINI(const aFileName: UnicodeString);
  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveSettings(aForce: Boolean = False);
    procedure ReloadSettings;

    property FPSCap: Integer read fFPSCap;
    property FullScreen: Boolean read fFullScreen write SetFullScreen;
    property Resolution: TKMScreenRes read fResolution write SetResolution;
    property WindowParams: TKMWindowParams read fWindowParams;
    property VSync: Boolean read fVSync write SetVSync;
    property NoRenderMaxTime: Integer read fNoRenderMaxTime;

    function IsNoRenerMaxTimeSet: Boolean;
  end;

  //Gameplay settings, those that affect the game
  //Everything gets written through setter to set fNeedsSave flag
  TKMGameSettings = class
  private
    fNeedsSave: Boolean;

    //GFX
    fBrightness: Byte;
    fAlphaShadows: Boolean;
    fLoadFullFonts: Boolean;

    //Game
    fAutosave: Boolean;
    fAutosaveAtGameEnd: Boolean;
    fAutosaveFrequency: Integer;
    fAutosaveCount: Integer;
    fReplayAutopause: Boolean;
    fReplayShowBeacons: Boolean; //Replay variable - show beacons during replay
    fSpecShowBeacons: Boolean;   //Spectator variable - show beacons while spectating
    fShowGameTime: Boolean;      //Show game time label (always)

    fPlayersColorMode: TKMPlayerColorMode;
    fPlayerColorSelf: Cardinal;
    fPlayerColorAlly: Cardinal;
    fPlayerColorEnemy: Cardinal;

    fScrollSpeed: Byte;
    fLocale: AnsiString;
    fSpeedPace: Word;
    fSpeedMedium: Single;
    fSpeedFast: Single;
    fSpeedVeryFast: Single;
    fWareDistribution: TKMWareDistribution;

    fDayGamesCount: Integer;       //Number of games played today (used for saves namings)
    fLastDayGamePlayed: TDateTime; //Last day game played

    //Campaign
    fCampaignLastDifficulty: TKMMissionDifficulty;

    //Replay
    fReplayAutosave: Boolean;
    fReplayAutosaveFrequency: Integer;

    //SFX
    fMusicOff: Boolean;
    fShuffleOn: Boolean;
    fMusicVolume: Single;
    fSoundFXVolume: Single;

    //Multiplayer
    fMultiplayerName: AnsiString;
    fLastIP: string;
    fLastPort: string;
    fLastRoom: string;
    fLastPassword: string;
    fFlashOnMessage: Boolean;

    //Server
    fServerPort: string;
    fMasterServerAddress: string;
    fServerName: AnsiString;
    fMasterAnnounceInterval: Integer;
    fMaxRooms: Integer;
    fServerPacketsAccumulatingDelay: Integer;
    fAutoKickTimeout: Integer;
    fPingInterval: Integer;
    fAnnounceServer: Boolean;
    fHTMLStatusFile: UnicodeString;
    fServerWelcomeMessage: UnicodeString;

    fServerDynamicFOW: Boolean;
    fServerMapsRosterEnabled: Boolean;
    fServerMapsRosterStr: UnicodeString;
    fServerLimitPTFrom, fServerLimitPTTo: Integer;
    fServerLimitSpeedFrom, fServerLimitSpeedTo: Single;
    fServerLimitSpeedAfterPTFrom, fServerLimitSpeedAfterPTTo: Single;

    //Menu
    fMenu_FavouriteMapsStr: UnicodeString;
    fMenu_MapSPType: Byte;
    fMenu_ReplaysType: Byte;
    fMenu_MapEdMapType: Byte;
    fMenu_MapEdNewMapX: Word;
    fMenu_MapEdNewMapY: Word;
    fMenu_MapEdSPMapCRC: Cardinal;
    fMenu_MapEdMPMapCRC: Cardinal;
    fMenu_MapEdMPMapName: UnicodeString;
    fMenu_MapEdDLMapCRC: Cardinal;
    fMenu_CampaignName: UnicodeString;
    fMenu_ReplaySPSaveName: UnicodeString;
    fMenu_ReplayMPSaveName: UnicodeString;
    fMenu_SPScenarioMapCRC: Cardinal;
    fMenu_SPMissionMapCRC: Cardinal;
    fMenu_SPTacticMapCRC: Cardinal;
    fMenu_SPSpecialMapCRC: Cardinal;
    fMenu_SPSaveFileName: UnicodeString;
    fMenu_LobbyMapType: Byte;

    fFavouriteMaps: TKMMapsCRCList;

    //GFX
    procedure SetBrightness(aValue: Byte);
    procedure SetAlphaShadows(aValue: Boolean);
    procedure SetLoadFullFonts(aValue: Boolean);

    //Game
    procedure SetAutosave(aValue: Boolean);
    procedure SetAutosaveAtGameEnd(aValue: Boolean);
    procedure SetAutosaveFrequency(aValue: Integer);
    procedure SetAutosaveCount(aValue: Integer);
    procedure SetLocale(const aLocale: AnsiString);
    procedure SetScrollSpeed(aValue: Byte);
    procedure SetSpecShowBeacons(aValue: Boolean);
    procedure SetShowGameTime(aValue: Boolean);
    procedure SetPlayersColorMode(aValue: TKMPlayerColorMode);
    procedure SetPlayerColorSelf(aValue: Cardinal);
    procedure SetPlayerColorAlly(aValue: Cardinal);
    procedure SetPlayerColorEnemy(aValue: Cardinal);

    procedure SetDayGamesCount(aValue: Integer);
    procedure SetLastDayGamePlayed(aValue: TDateTime);

    //Campaign
    procedure SetCampaignLastDifficulty(aValue: TKMMissionDifficulty);

    //Replay
    procedure SetReplayAutopause(aValue: Boolean);
    procedure SetReplayShowBeacons(aValue: Boolean);
    procedure SetReplayAutosave(aValue: Boolean);
    procedure SetReplayAutosaveFrequency(aValue: Integer);

    //SFX
    procedure SetMusicOff(aValue: Boolean);
    procedure SetShuffleOn(aValue: Boolean);
    procedure SetMusicVolume(aValue: Single);
    procedure SetSoundFXVolume(aValue: Single);

    //Multiplayer
    procedure SetMultiplayerName(const aValue: AnsiString);
    procedure SetLastIP(const aValue: string);
    procedure SetLastPort(const aValue: string);
    procedure SetLastRoom(const aValue: string);
    procedure SetLastPassword(const aValue: string);
    procedure SetFlashOnMessage(aValue: Boolean);

    //Server
    procedure SetMasterServerAddress(const aValue: string);
    procedure SetServerName(const aValue: AnsiString);
    procedure SetServerPort(const aValue: string);
    procedure SetServerWelcomeMessage(const aValue: UnicodeString);
    procedure SetAnnounceServer(aValue: Boolean);
    procedure SetAutoKickTimeout(aValue: Integer);
    procedure SetPingInterval(aValue: Integer);
    procedure SetMasterAnnounceInterval(eValue: Integer);
    procedure SetHTMLStatusFile(const eValue: UnicodeString);
    procedure SetMaxRooms(eValue: Integer);
    procedure SetServerPacketsAccumulatingDelay(aValue: Integer);

    //Menu
    procedure SetMenuFavouriteMapsStr(const aValue: UnicodeString);
    procedure SetMenuMapSPType(aValue: Byte);
    procedure SetMenuReplaysType(aValue: Byte);
    procedure SetMenuMapEdMapType(aValue: Byte);
    procedure SetMenuMapEdNewMapX(aValue: Word);
    procedure SetMenuMapEdNewMapY(aValue: Word);
    procedure SetMenuMapEdSPMapCRC(aValue: Cardinal);
    procedure SetMenuMapEdMPMapCRC(aValue: Cardinal);
    procedure SetMenuMapEdMPMapName(const aValue: UnicodeString);
    procedure SetMenuMapEdDLMapCRC(aValue: Cardinal);
    procedure SetMenuCampaignName(const aValue: UnicodeString);
    procedure SetMenuReplaySPSaveName(const aValue: UnicodeString);
    procedure SetMenuReplayMPSaveName(const aValue: UnicodeString);
    procedure SetMenuSPScenarioMapCRC(aValue: Cardinal);
    procedure SetMenuSPMissionMapCRC(aValue: Cardinal);
    procedure SetMenuSPTacticMapCRC(aValue: Cardinal);
    procedure SetMenuSPSpecialMapCRC(aValue: Cardinal);
    procedure SetMenuSPSaveFileName(const aValue: UnicodeString);
    procedure SetMenuLobbyMapType(aValue: Byte);
  protected
    function LoadFromINI(const FileName: UnicodeString): Boolean;
    procedure SaveToINI(const FileName: UnicodeString);
    procedure Changed;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SaveSettings(aForce: Boolean=False);
    procedure ReloadSettings;

    //GFX
    property Brightness: Byte read fBrightness write SetBrightness;
    property AlphaShadows: Boolean read fAlphaShadows write SetAlphaShadows;
    property LoadFullFonts: Boolean read fLoadFullFonts write SetLoadFullFonts;

    //Game
    property Autosave: Boolean read fAutosave write SetAutosave;
    property AutosaveAtGameEnd: Boolean read fAutosaveAtGameEnd write SetAutosaveAtGameEnd;

    property AutosaveFrequency: Integer read fAutosaveFrequency write SetAutosaveFrequency;
    property AutosaveCount: Integer read fAutosaveCount write SetAutosaveCount;
    property SpecShowBeacons: Boolean read fSpecShowBeacons write SetSpecShowBeacons;
    property ShowGameTime: Boolean read fShowGameTime write SetShowGameTime;

    property PlayersColorMode: TKMPlayerColorMode read fPlayersColorMode write SetPlayersColorMode;
    property PlayerColorSelf: Cardinal read fPlayerColorSelf write SetPlayerColorSelf;
    property PlayerColorAlly: Cardinal read fPlayerColorAlly write SetPlayerColorAlly;
    property PlayerColorEnemy: Cardinal read fPlayerColorEnemy write SetPlayerColorEnemy;

    property ScrollSpeed: Byte read fScrollSpeed write SetScrollSpeed;
    property Locale: AnsiString read fLocale write SetLocale;
    property SpeedPace: Word read fSpeedPace;
    property SpeedMedium: Single read fSpeedMedium;
    property SpeedFast: Single read fSpeedFast;
    property SpeedVeryFast: Single read fSpeedVeryFast;
    property WareDistribution: TKMWareDistribution read fWareDistribution;

    property DayGamesCount: Integer read fDayGamesCount write SetDayGamesCount;
    property LastDayGamePlayed: TDateTime read fLastDayGamePlayed write SetLastDayGamePlayed;

    //Campaign
    property CampaignLastDifficulty: TKMMissionDifficulty read fCampaignLastDifficulty write SetCampaignLastDifficulty;

    //Replay
    property ReplayAutopause: Boolean read fReplayAutopause write SetReplayAutopause;
    property ReplayShowBeacons: Boolean read fReplayShowBeacons write SetReplayShowBeacons;
    property ReplayAutosave: Boolean read fReplayAutosave write SetReplayAutosave;
    property ReplayAutosaveFrequency: Integer read fReplayAutosaveFrequency write SetReplayAutosaveFrequency;

    //SFX
    property MusicOff: Boolean read fMusicOff write SetMusicOff;
    property ShuffleOn: Boolean read fShuffleOn write SetShuffleOn;
    property MusicVolume: Single read fMusicVolume write SetMusicVolume;
    property SoundFXVolume: Single read fSoundFXVolume write SetSoundFXVolume;

    //Multiplayer
    property MultiplayerName: AnsiString read fMultiplayerName write SetMultiplayerName;
    property LastIP: string read fLastIP write SetLastIP;
    property LastPort: string read fLastPort write SetLastPort;
    property LastRoom: string read fLastRoom write SetLastRoom;
    property LastPassword: string read fLastPassword write SetLastPassword;

    //Server
    property ServerPort: string read fServerPort write SetServerPort;
    property MasterServerAddress: string read fMasterServerAddress write SetMasterServerAddress;
    property ServerName: AnsiString read fServerName write SetServerName;
    property MasterAnnounceInterval: Integer read fMasterAnnounceInterval write SetMasterAnnounceInterval;
    property AnnounceServer: Boolean read fAnnounceServer write SetAnnounceServer;
    property MaxRooms: Integer read fMaxRooms write SetMaxRooms;
    property ServerPacketsAccumulatingDelay: Integer read fServerPacketsAccumulatingDelay write SetServerPacketsAccumulatingDelay;
    property FlashOnMessage: Boolean read fFlashOnMessage write SetFlashOnMessage;
    property AutoKickTimeout: Integer read fAutoKickTimeout write SetAutoKickTimeout;
    property PingInterval: Integer read fPingInterval write SetPingInterval;
    property HTMLStatusFile: UnicodeString read fHTMLStatusFile write SetHTMLStatusFile;
    property ServerWelcomeMessage: UnicodeString read fServerWelcomeMessage write SetServerWelcomeMessage;

    property ServerDynamicFOW: Boolean read fServerDynamicFOW;
    property ServerMapsRosterEnabled: Boolean read fServerMapsRosterEnabled;
    property ServerMapsRosterStr: UnicodeString read fServerMapsRosterStr;
    property ServerLimitPTFrom: Integer read fServerLimitPTFrom;
    property ServerLimitPTTo: Integer read fServerLimitPTTo;
    property ServerLimitSpeedFrom: Single read fServerLimitSpeedFrom;
    property ServerLimitSpeedTo: Single read fServerLimitSpeedTo;
    property ServerLimitSpeedAfterPTFrom: Single read fServerLimitSpeedAfterPTFrom;
    property ServerLimitSpeedAfterPTTo: Single read fServerLimitSpeedAfterPTTo;

    //Menu
    property MenuMapSPType: Byte read fMenu_MapSPType write SetMenuMapSPType;
    property MenuReplaysType: Byte read fMenu_ReplaysType write SetMenuReplaysType;
    property MenuMapEdMapType: Byte read fMenu_MapEdMapType write SetMenuMapEdMapType;
    property MenuMapEdNewMapX: Word read fMenu_MapEdNewMapX write SetMenuMapEdNewMapX;
    property MenuMapEdNewMapY: Word read fMenu_MapEdNewMapY write SetMenuMapEdNewMapY;
    property MenuMapEdSPMapCRC: Cardinal read fMenu_MapEdSPMapCRC write SetMenuMapEdSPMapCRC;
    property MenuMapEdMPMapCRC: Cardinal read fMenu_MapEdMPMapCRC write SetMenuMapEdMPMapCRC;
    property MenuMapEdMPMapName: UnicodeString read fMenu_MapEdMPMapName write SetMenuMapEdMPMapName;
    property MenuMapEdDLMapCRC: Cardinal read fMenu_MapEdDLMapCRC write SetMenuMapEdDLMapCRC;
    property MenuCampaignName: UnicodeString read fMenu_CampaignName write SetMenuCampaignName;
    property MenuReplaySPSaveName: UnicodeString read fMenu_ReplaySPSaveName write SetMenuReplaySPSaveName;
    property MenuReplayMPSaveName: UnicodeString read fMenu_ReplayMPSaveName write SetMenuReplayMPSaveName;
    property MenuSPScenarioMapCRC: Cardinal read fMenu_SPScenarioMapCRC write SetMenuSPScenarioMapCRC;
    property MenuSPMissionMapCRC: Cardinal read fMenu_SPMissionMapCRC write SetMenuSPMissionMapCRC;
    property MenuSPTacticMapCRC: Cardinal read fMenu_SPTacticMapCRC write SetMenuSPTacticMapCRC;
    property MenuSPSpecialMapCRC: Cardinal read fMenu_SPSpecialMapCRC write SetMenuSPSpecialMapCRC;
    property MenuSPSaveFileName: UnicodeString read fMenu_SPSaveFileName write SetMenuSPSaveFileName;
    property MenuLobbyMapType: Byte read fMenu_LobbyMapType write SetMenuLobbyMapType;

    property FavouriteMaps: TKMMapsCRCList read fFavouriteMaps;
  end;


implementation
uses
  SysUtils, INIfiles, Math,
  KM_Log, KM_CommonUtils;

const
  NO_RENDER_MAX_TIME_MIN = 10; //in ms
  NO_RENDER_MAX_TIME_DEFAULT = 1000; //in ms
  NO_RENDER_MAX_TIME_UNDEF = -1; //undefined


{ TMainSettings }
constructor TKMainSettings.Create;
begin
  inherited;
  fWindowParams := TKMWindowParams.Create;
  LoadFromINI(ExeDir + SETTINGS_FILE);
  fNeedsSave := False;
  gLog.AddTime('Global settings loaded from ' + SETTINGS_FILE);
end;


destructor TKMainSettings.Destroy;
begin
  SaveToINI(ExeDir+SETTINGS_FILE);
  FreeAndNil(fWindowParams);
  inherited;
end;


procedure TKMainSettings.Changed;
begin
  fNeedsSave := True;
end;


function TKMainSettings.LoadFromINI(const aFileName: UnicodeString): Boolean;
var
  F: TMemIniFile;
begin
  Result := FileExists(aFileName);

  F := TMemIniFile.Create(aFileName {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );

  try
    fFullScreen         := F.ReadBool   ('GFX', 'FullScreen',       False);
    fVSync              := F.ReadBool   ('GFX', 'VSync',            True);
    fResolution.Width   := F.ReadInteger('GFX', 'ResolutionWidth',  MENU_DESIGN_X);
    fResolution.Height  := F.ReadInteger('GFX', 'ResolutionHeight', MENU_DESIGN_Y);
    fResolution.RefRate := F.ReadInteger('GFX', 'RefreshRate',      60);
    fFPSCap := EnsureRange(F.ReadInteger('GFX', 'FPSCap', DEF_FPS_CAP), MIN_FPS_CAP, MAX_FPS_CAP);

    // For proper window positioning we need Left and Top records
    // Otherwise reset all window params to defaults
    if F.ValueExists('Window', 'WindowLeft') and F.ValueExists('Window', 'WindowTop') then
    begin
      fWindowParams.fWidth  := F.ReadInteger('Window', 'WindowWidth',  MENU_DESIGN_X);
      fWindowParams.fHeight := F.ReadInteger('Window', 'WindowHeight', MENU_DESIGN_Y);
      fWindowParams.fLeft   := F.ReadInteger('Window', 'WindowLeft',   -1);
      fWindowParams.fTop    := F.ReadInteger('Window', 'WindowTop',    -1);
      fWindowParams.fState  := TWindowState(EnsureRange(F.ReadInteger('Window', 'WindowState', 0), 0, 2));
    end else
      fWindowParams.fNeedResetToDefaults := True;

    fNoRenderMaxTime        := F.ReadInteger('Misc', 'NoRenderMaxTime', NO_RENDER_MAX_TIME_DEFAULT);
    if fNoRenderMaxTime < NO_RENDER_MAX_TIME_MIN then
      fNoRenderMaxTime := NO_RENDER_MAX_TIME_UNDEF;

    // Reset wsMinimized state to wsNormal
    if (fWindowParams.fState = TWindowState.wsMinimized) then
      fWindowParams.fState := TWindowState.wsNormal;
  finally
    FreeAndNil(F);
  end;

  fNeedsSave := False;
end;


//Don't rewrite the file for each individual change, do it in one batch for simplicity
procedure TKMainSettings.SaveToINI(const aFileName: UnicodeString);
var
  F: TMemIniFile;
begin
  if BLOCK_FILE_WRITE then
    Exit;
  F := TMemIniFile.Create(aFileName {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );

  try
    F.WriteBool   ('GFX','FullScreen',      fFullScreen);
    F.WriteBool   ('GFX','VSync',           fVSync);
    F.WriteInteger('GFX','ResolutionWidth', fResolution.Width);
    F.WriteInteger('GFX','ResolutionHeight',fResolution.Height);
    F.WriteInteger('GFX','RefreshRate',     fResolution.RefRate);
    F.WriteInteger('GFX','FPSCap',          fFPSCap);

    F.WriteInteger('Window','WindowWidth',    fWindowParams.Width);
    F.WriteInteger('Window','WindowHeight',   fWindowParams.Height);
    F.WriteInteger('Window','WindowLeft',     fWindowParams.Left);
    F.WriteInteger('Window','WindowTop',      fWindowParams.Top);
    F.WriteInteger('Window','WindowState',    Ord(fWindowParams.State));

    F.WriteInteger('Misc', 'NoRenderMaxTime', fNoRenderMaxTime);

    F.UpdateFile; //Write changes to file
  finally
    FreeAndNil(F);
  end;

  fNeedsSave := False;
end;


function TKMainSettings.IsNoRenerMaxTimeSet: Boolean;
begin
  Result := fNoRenderMaxTime <> NO_RENDER_MAX_TIME_UNDEF;
end;


procedure TKMainSettings.SetFullScreen(aValue: boolean);
begin
  fFullScreen := aValue;
  Changed;
end;


procedure TKMainSettings.SetResolution(const Value: TKMScreenRes);
begin
  fResolution := Value;
  Changed;
end;


procedure TKMainSettings.SetVSync(aValue: boolean);
begin
  fVSync := aValue;
  Changed;
end;


procedure TKMainSettings.ReloadSettings;
begin
  LoadFromINI(ExeDir + SETTINGS_FILE);
end;


procedure TKMainSettings.SaveSettings(aForce: Boolean);
begin
  if fNeedsSave or aForce or fWindowParams.IsChanged then
    SaveToINI(ExeDir + SETTINGS_FILE);
end;


{ TGameSettings }
procedure TKMGameSettings.Changed;
begin
  fNeedsSave := True;
end;


constructor TKMGameSettings.Create;
begin
  inherited;

  fWareDistribution := TKMWareDistribution.Create;

  fFavouriteMaps := TKMMapsCRCList.Create;
  fFavouriteMaps.OnMapsUpdate := SetMenuFavouriteMapsStr;

  ReloadSettings;
end;


destructor TKMGameSettings.Destroy;
begin
  SaveToINI(ExeDir + SETTINGS_FILE);
  FreeAndNil(fWareDistribution);
  FreeAndNil(fFavouriteMaps);

  inherited;
end;


//Save only when needed
procedure TKMGameSettings.SaveSettings(aForce: Boolean = False);
begin
  if fNeedsSave or fWareDistribution.Changed or aForce then
    SaveToINI(ExeDir + SETTINGS_FILE);
end;


procedure TKMGameSettings.ReloadSettings;
begin
  LoadFromINI(ExeDir + SETTINGS_FILE);
  gLog.AddTime('Game settings loaded from ' + SETTINGS_FILE);
end;


function TKMGameSettings.LoadFromINI(const FileName: UnicodeString): Boolean;
var
  F: TMemIniFile;
  TempCard: Int64;
  ServerName: UnicodeString;
begin
  Result := FileExists(FileName);

  F := TMemIniFile.Create(FileName {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );
  try
    fBrightness         := F.ReadInteger  ('GFX', 'Brightness',         1);
    fAlphaShadows       := F.ReadBool     ('GFX', 'AlphaShadows',       True);
    fLoadFullFonts      := F.ReadBool     ('GFX', 'LoadFullFonts',      False);

    fAutosave           := F.ReadBool     ('Game', 'Autosave',          True); //Should be ON by default
    fAutosaveAtGameEnd  := F.ReadBool     ('Game', 'AutosaveOnGameEnd', False); //Should be OFF by default
    SetAutosaveFrequency(F.ReadInteger    ('Game', 'AutosaveFrequency', AUTOSAVE_FREQUENCY_DEFAULT));
    SetAutosaveCount    (F.ReadInteger    ('Game', 'AutosaveCount',     AUTOSAVE_COUNT));
    fSpecShowBeacons    := F.ReadBool     ('Game', 'SpecShowBeacons',   False); //Disabled by default
    fShowGameTime       := F.ReadBool     ('Game', 'ShowGameTime',      False); //Disabled by default
    fPlayersColorMode   := TKMPlayerColorMode(F.ReadInteger  ('Game', 'PlayersColorMode', Byte(pcmColors))); //Show players colors by default

    //Load minimap colors as hex strings 6-hex digits width
    if TryStrToInt64('$' + F.ReadString('Game', 'PlayerColorSelf', IntToHex(Integer(clPlayerSelf and $FFFFFF), 6)), TempCard) then
      fPlayerColorSelf := $FF000000 or TempCard
    else
      fPlayerColorSelf := clPlayerSelf;

    if TryStrToInt64('$' + F.ReadString('Game', 'PlayerColorAlly', IntToHex(Integer(clPlayerAlly and $FFFFFF), 6)), TempCard) then
      fPlayerColorAlly := $FF000000 or TempCard
    else
      fPlayerColorAlly := clPlayerAlly;

    if TryStrToInt64('$' + F.ReadString('Game', 'PlayerColorEnemy', IntToHex(Integer(clPlayerEnemy and $FFFFFF), 6)), TempCard) then
      fPlayerColorEnemy := $FF000000 or TempCard
    else
      fPlayerColorEnemy := clPlayerEnemy;

    fScrollSpeed        := F.ReadInteger  ('Game', 'ScrollSpeed',       10);
    fSpeedPace          := F.ReadInteger  ('Game', 'SpeedPace',         100);
    fSpeedMedium        := F.ReadFloat    ('Game', 'SpeedMedium',       3);
    fSpeedFast          := F.ReadFloat    ('Game', 'SpeedFast',         6);
    fSpeedVeryFast      := F.ReadFloat    ('Game', 'SpeedVeryFast',     10);

    fLocale             := AnsiString(F.ReadString ('Game', 'Locale', UnicodeString(DEFAULT_LOCALE)));

    fDayGamesCount      := F.ReadInteger  ('Game', 'DayGamesCount',     0);
    fLastDayGamePlayed  := F.ReadDate     ('Game', 'LastDayGamePlayed', 0);

    fWareDistribution.LoadFromStr(F.ReadString ('Game','WareDistribution',''));

    fCampaignLastDifficulty := TKMMissionDifficulty(F.ReadInteger('Campaign', 'CampaignLastDifficulty', Byte(mdNormal))); //Normal as default

    fReplayAutopause    := F.ReadBool       ('Replay', 'ReplayAutopause',   False); //Disabled by default
    fReplayShowBeacons  := F.ReadBool       ('Replay', 'ReplayShowBeacons', False); //Disabled by default
    fReplayAutosave     := F.ReadBool       ('Replay', 'ReplayAutosave',          True); //Should be ON by default
    SetReplayAutosaveFrequency(F.ReadInteger('Replay', 'ReplayAutosaveFrequency', REPLAY_AUTOSAVE_FREQUENCY_DEFAULT));

    fSoundFXVolume  := F.ReadFloat  ('SFX',  'SFXVolume',      0.5);
    fMusicVolume    := F.ReadFloat  ('SFX',  'MusicVolume',    0.5);
    fMusicOff       := F.ReadBool   ('SFX',  'MusicDisabled',  False);
    fShuffleOn      := F.ReadBool   ('SFX',  'ShuffleEnabled', False);

    if INI_HITPOINT_RESTORE then
      HITPOINT_RESTORE_PACE := F.ReadInteger('Fights', 'HitPointRestorePace', DEFAULT_HITPOINT_RESTORE)
    else
      HITPOINT_RESTORE_PACE := DEFAULT_HITPOINT_RESTORE;

    fMultiplayerName        := AnsiString(F.ReadString ('Multiplayer','Name','NoName'));
    fLastIP                 := F.ReadString ('Multiplayer','LastIP','127.0.0.1');
    fLastPort               := F.ReadString ('Multiplayer','LastPort','56789');
    fLastRoom               := F.ReadString ('Multiplayer','LastRoom','0');
    fLastPassword           := F.ReadString('Multiplayer','LastPassword','');
    fFlashOnMessage         := F.ReadBool   ('Multiplayer','FlashOnMessage',True);

    fServerPort             := F.ReadString ('Server','ServerPort','56789');
    //We call it MasterServerAddressNew to force it to update in everyone's .ini file when we changed address.
    //If the key stayed the same then everyone would still be using the old value from their settings.
    fMasterServerAddress    := F.ReadString ('Server','MasterServerAddressNew','http://kam.hodgman.id.au/');
    fMasterAnnounceInterval := F.ReadInteger('Server','MasterServerAnnounceInterval',180);
    fAnnounceServer         := F.ReadBool   ('Server','AnnounceDedicatedServer',True);

    ServerName              := F.ReadString ('Server','ServerName','KaM Remake Server');
    fServerName             := AnsiString(StrTrimChar(ServerName, #39)); //Trim single quotes from the start and from the end of servername

    fMaxRooms               := F.ReadInteger('Server','MaxRooms',16);
    ServerPacketsAccumulatingDelay := F.ReadInteger('Server','PacketsAccumulatingDelay',20);
    fAutoKickTimeout        := F.ReadInteger('Server','AutoKickTimeout',20);
    fPingInterval           := F.ReadInteger('Server','PingMeasurementInterval',1000);
    fHTMLStatusFile         := F.ReadString ('Server','HTMLStatusFile','KaM_Remake_Server_Status.html');
    fServerWelcomeMessage   := {$IFDEF FPC} UTF8Decode {$ENDIF} (F.ReadString ('Server','WelcomeMessage',''));

    fServerDynamicFOW       := F.ReadBool  ('Server', 'DynamicFOW', False);
    fServerMapsRosterEnabled:= F.ReadBool  ('Server', 'MapsRosterEnabled', False);
    fServerMapsRosterStr    := F.ReadString('Server', 'MapsRoster', '');
    fServerLimitPTFrom      := F.ReadInteger('Server', 'LimitPTFrom',     0);
    fServerLimitPTTo        := F.ReadInteger('Server', 'LimitPTTo',       300);
    fServerLimitSpeedFrom   := F.ReadFloat  ('Server', 'LimitSpeedFrom',  0);
    fServerLimitSpeedTo     := F.ReadFloat  ('Server', 'LimitSpeedTo',    10);
    fServerLimitSpeedAfterPTFrom  := F.ReadFloat('Server', 'LimitSpeedAfterPTFrom', 0);
    fServerLimitSpeedAfterPTTo    := F.ReadFloat('Server', 'LimitSpeedAfterPTTo',   10);

    fMenu_FavouriteMapsStr   := F.ReadString('Menu', 'FavouriteMaps', '');
    fFavouriteMaps.LoadFromString(fMenu_FavouriteMapsStr);

    fMenu_MapSPType         := F.ReadInteger('Menu', 'MapSPType',  0);
    fMenu_ReplaysType       := F.ReadInteger('Menu', 'ReplaysType',  0);
    fMenu_MapEdMapType      := F.ReadInteger('Menu', 'MapEdMapType', 0);
    fMenu_MapEdNewMapX      := F.ReadInteger('Menu', 'MapEdNewMapX', 64);
    fMenu_MapEdNewMapY      := F.ReadInteger('Menu', 'MapEdNewMapY', 64);
    fMenu_MapEdSPMapCRC     := StrToInt64(F.ReadString('Menu', 'MapEdSPMapCRC', '0'));
    fMenu_MapEdMPMapCRC     := StrToInt64(F.ReadString('Menu', 'MapEdMPMapCRC', '0'));
    fMenu_MapEdMPMapName    := F.ReadString('Menu', 'MapEdMPMapName', '');
    fMenu_MapEdDLMapCRC     := StrToInt64(F.ReadString('Menu', 'MapEdDLMapCRC', '0'));
    fMenu_CampaignName      := F.ReadString('Menu', 'CampaignName', '');
    fMenu_ReplaySPSaveName  := F.ReadString('Menu', 'ReplaySPSaveName', '');
    fMenu_ReplayMPSaveName  := F.ReadString('Menu', 'ReplayMPSaveName', '');
    fMenu_SPScenarioMapCRC  := StrToInt64(F.ReadString('Menu', 'SPScenarioMapCRC', '0'));
    fMenu_SPMissionMapCRC   := StrToInt64(F.ReadString('Menu', 'SPMissionMapCRC', '0'));
    fMenu_SPTacticMapCRC    := StrToInt64(F.ReadString('Menu', 'SPTacticMapCRC',  '0'));
    fMenu_SPSpecialMapCRC   := StrToInt64(F.ReadString('Menu', 'SPSpecialMapCRC', '0'));
    fMenu_SPSaveFileName    := F.ReadString('Menu', 'SPSaveFileName', '');
    fMenu_LobbyMapType      := F.ReadInteger('Menu', 'LobbyMapType', 0);
  finally
    F.Free;
  end;

  fNeedsSave := False;
end;


//Don't rewrite the file for each individual change, do it in one batch for simplicity
procedure TKMGameSettings.SaveToINI(const FileName: UnicodeString);
var
  F: TMemIniFile;
begin
  if BLOCK_FILE_WRITE then
    Exit;
  F := TMemIniFile.Create(FileName {$IFDEF WDC}, TEncoding.UTF8 {$ENDIF} );
  try
    F.WriteInteger('GFX','Brightness',    fBrightness);
    F.WriteBool   ('GFX','AlphaShadows',  fAlphaShadows);
    F.WriteBool   ('GFX','LoadFullFonts', fLoadFullFonts);

    F.WriteBool   ('Game','Autosave',           fAutosave);
    F.WriteBool   ('Game','AutosaveOnGameEnd',  fAutosaveAtGameEnd);
    F.WriteInteger('Game','AutosaveFrequency',  fAutosaveFrequency);
    F.WriteInteger('Game','AutosaveCount',      fAutosaveCount);

    F.WriteBool   ('Game','SpecShowBeacons',    fSpecShowBeacons);
    F.WriteBool   ('Game','ShowGameTime',       fShowGameTime);

    F.WriteInteger('Game','PlayersColorMode', Byte(fPlayersColorMode));

    F.WriteString ('Game','PlayerColorSelf',   IntToHex(fPlayerColorSelf and $FFFFFF, 6));
    F.WriteString ('Game','PlayerColorAlly',   IntToHex(fPlayerColorAlly and $FFFFFF, 6));
    F.WriteString ('Game','PlayerColorEnemy',  IntToHex(fPlayerColorEnemy and $FFFFFF, 6));

    F.WriteInteger('Game','ScrollSpeed',        fScrollSpeed);
    F.WriteInteger('Game','SpeedPace',          fSpeedPace);
    F.WriteFloat  ('Game','SpeedMedium',        fSpeedMedium);
    F.WriteFloat  ('Game','SpeedFast',          fSpeedFast);
    F.WriteFloat  ('Game','SpeedVeryFast',      fSpeedVeryFast);

    F.WriteString ('Game','Locale',          UnicodeString(fLocale));

    F.WriteInteger('Game','DayGamesCount',        fDayGamesCount);
    F.WriteDate   ('Game','LastDayGamePlayed',  fLastDayGamePlayed);

    F.WriteString('Game','WareDistribution', fWareDistribution.PackToStr);

    F.WriteInteger('Campaign','CampaignLastDifficulty', Byte(fCampaignLastDifficulty));

    F.WriteBool   ('Replay','ReplayAutopause',         fReplayAutopause);
    F.WriteBool   ('Replay','ReplayShowBeacons',       fReplayShowBeacons);
    F.WriteBool   ('Replay','ReplayAutosave',          fReplayAutosave);
    F.WriteInteger('Replay','ReplayAutosaveFrequency', fReplayAutosaveFrequency);

    F.WriteFloat  ('SFX','SFXVolume',     fSoundFXVolume);
    F.WriteFloat  ('SFX','MusicVolume',   fMusicVolume);
    F.WriteBool   ('SFX','MusicDisabled', fMusicOff);
    F.WriteBool   ('SFX','ShuffleEnabled',fShuffleOn);

    if INI_HITPOINT_RESTORE then
      F.WriteInteger('Fights','HitPointRestorePace', HITPOINT_RESTORE_PACE);

    F.WriteString ('Multiplayer','Name',            UnicodeString(fMultiplayerName));
    F.WriteString ('Multiplayer','LastIP',          fLastIP);
    F.WriteString ('Multiplayer','LastPort',        fLastPort);
    F.WriteString ('Multiplayer','LastRoom',        fLastRoom);
    F.WriteString ('Multiplayer','LastPassword',    fLastPassword);
    F.WriteBool   ('Multiplayer','FlashOnMessage',  fFlashOnMessage);

    F.WriteString ('Server','ServerName',                   '''' + UnicodeString(fServerName) + ''''); //Add single quotes for server name
    F.WriteString ('Server','WelcomeMessage',               {$IFDEF FPC} UTF8Encode {$ENDIF}(fServerWelcomeMessage));
    F.WriteString ('Server','ServerPort',                   fServerPort);
    F.WriteBool   ('Server','AnnounceDedicatedServer',      fAnnounceServer);
    F.WriteInteger('Server','MaxRooms',                     fMaxRooms);
    F.WriteInteger('Server','PacketsAccumulatingDelay',     fServerPacketsAccumulatingDelay);
    F.WriteString ('Server','HTMLStatusFile',               fHTMLStatusFile);
    F.WriteInteger('Server','MasterServerAnnounceInterval', fMasterAnnounceInterval);
    F.WriteString ('Server','MasterServerAddressNew',       fMasterServerAddress);
    F.WriteInteger('Server','AutoKickTimeout',              fAutoKickTimeout);
    F.WriteInteger('Server','PingMeasurementInterval',      fPingInterval);

    F.WriteBool   ('Server','DynamicFOW',             fServerDynamicFOW);
    F.WriteBool   ('Server','MapsRosterEnabled',      fServerMapsRosterEnabled);
    F.WriteString ('Server','MapsRoster',             fServerMapsRosterStr);
    F.WriteInteger('Server','LimitPTFrom',            fServerLimitPTFrom);
    F.WriteInteger('Server','LimitPTTo',              fServerLimitPTTo);
    F.WriteFloat  ('Server','LimitSpeedFrom',         fServerLimitSpeedFrom);
    F.WriteFloat  ('Server','LimitSpeedTo',           fServerLimitSpeedTo);
    F.WriteFloat  ('Server','LimitSpeedAfterPTFrom',  fServerLimitSpeedAfterPTFrom);
    F.WriteFloat  ('Server','LimitSpeedAfterPTTo',    fServerLimitSpeedAfterPTTo);

    F.WriteString ('Menu',  'FavouriteMaps',      fMenu_FavouriteMapsStr);
    F.WriteInteger('Menu',  'MapSPType',          fMenu_MapSPType);
    F.WriteInteger('Menu',  'ReplaysType',        fMenu_ReplaysType);
    F.WriteInteger('Menu',  'MapEdMapType',       fMenu_MapEdMapType);
    F.WriteInteger('Menu',  'MapEdNewMapX',       fMenu_MapEdNewMapX);
    F.WriteInteger('Menu',  'MapEdNewMapY',       fMenu_MapEdNewMapY);
    F.WriteString ('Menu',  'MapEdSPMapCRC',      IntToStr(fMenu_MapEdSPMapCRC));
    F.WriteString ('Menu',  'MapEdMPMapCRC',      IntToStr(fMenu_MapEdMPMapCRC));
    F.WriteString ('Menu',  'MapEdMPMapName',     fMenu_MapEdMPMapName);
    F.WriteString ('Menu',  'MapEdDLMapCRC',      IntToStr(fMenu_MapEdDLMapCRC));
    F.WriteString ('Menu',  'CampaignName',       fMenu_CampaignName);
    F.WriteString ('Menu',  'ReplaySPSaveName',   fMenu_ReplaySPSaveName);
    F.WriteString ('Menu',  'ReplayMPSaveName',   fMenu_ReplayMPSaveName);
    F.WriteString ('Menu',  'SPScenarioMapCRC',   IntToStr(fMenu_SPScenarioMapCRC));
    F.WriteString ('Menu',  'SPMissionMapCRC',    IntToStr(fMenu_SPMissionMapCRC));
    F.WriteString ('Menu',  'SPTacticMapCRC',     IntToStr(fMenu_SPTacticMapCRC));
    F.WriteString ('Menu',  'SPSpecialMapCRC',    IntToStr(fMenu_SPSpecialMapCRC));
    F.WriteString ('Menu',  'SPSaveFileName',     fMenu_SPSaveFileName);
    F.WriteInteger('Menu',  'LobbyMapType',       fMenu_LobbyMapType);

    F.UpdateFile; //Write changes to file
  finally
    F.Free;
  end;

  fNeedsSave := False;
end;


procedure TKMGameSettings.SetLocale(const aLocale: AnsiString);
begin
  //We can get some unsupported LocaleCode, but that is fine, it will have Eng fallback anyway
  fLocale := aLocale;
  Changed;
end;


procedure TKMGameSettings.SetBrightness(aValue: Byte);
begin
  fBrightness := EnsureRange(aValue, 0, 20);
  Changed;
end;


procedure TKMGameSettings.SetFlashOnMessage(aValue: Boolean);
begin
  fFlashOnMessage := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuFavouriteMapsStr(const aValue: UnicodeString);
begin
  fMenu_FavouriteMapsStr := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapSPType(aValue: Byte);
begin
  fMenu_MapSPType := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuReplaysType(aValue: Byte);
begin
  fMenu_ReplaysType := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapEdMapType(aValue: Byte);
begin
  fMenu_MapEdMapType := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapEdNewMapX(aValue: Word);
begin
  fMenu_MapEdNewMapX := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapEdNewMapY(aValue: Word);
begin
  fMenu_MapEdNewMapY := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapEdSPMapCRC(aValue: Cardinal);
begin
  fMenu_MapEdSPMapCRC := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapEdMPMapCRC(aValue: Cardinal);
begin
  fMenu_MapEdMPMapCRC := aValue;
  Changed;
end;



procedure TKMGameSettings.SetMenuMapEdMPMapName(const aValue: UnicodeString);
begin
  fMenu_MapEdMPMapName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuMapEdDLMapCRC(aValue: Cardinal);
begin
  fMenu_MapEdDLMapCRC := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuCampaignName(const aValue: UnicodeString);
begin
  fMenu_CampaignName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuReplaySPSaveName(const aValue: UnicodeString);
begin
  fMenu_ReplaySPSaveName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuReplayMPSaveName(const aValue: UnicodeString);
begin
  fMenu_ReplayMPSaveName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuSPScenarioMapCRC(aValue: Cardinal);
begin
  fMenu_SPScenarioMapCRC := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuSPMissionMapCRC(aValue: Cardinal);
begin
  fMenu_SPMissionMapCRC := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuSPTacticMapCRC(aValue: Cardinal);
begin
  fMenu_SPTacticMapCRC := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuSPSpecialMapCRC(aValue: Cardinal);
begin
  fMenu_SPSpecialMapCRC := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuSPSaveFileName(const aValue: UnicodeString);
begin
  fMenu_SPSaveFileName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMenuLobbyMapType(aValue: Byte);
begin
  fMenu_LobbyMapType := aValue;
  Changed;
end;


procedure TKMGameSettings.SetAutosave(aValue: Boolean);
begin
  fAutosave := aValue;
  Changed;
end;


procedure TKMGameSettings.SetAutosaveAtGameEnd(aValue: Boolean);
begin
  fAutosaveAtGameEnd := aValue;
  Changed;
end;


procedure TKMGameSettings.SetAutosaveCount(aValue: Integer);
begin
  fAutosaveCount := EnsureRange(aValue, AUTOSAVE_COUNT_MIN, AUTOSAVE_COUNT_MAX);
  Changed;
end;


procedure TKMGameSettings.SetAutosaveFrequency(aValue: Integer);
begin
  fAutosaveFrequency := EnsureRange(aValue, AUTOSAVE_FREQUENCY_MIN, AUTOSAVE_FREQUENCY_MAX);
  Changed;
end;


procedure TKMGameSettings.SetSpecShowBeacons(aValue: Boolean);
begin
  fSpecShowBeacons := aValue;
  Changed;
end;


procedure TKMGameSettings.SetShowGameTime(aValue: Boolean);
begin
  fShowGameTime := aValue;
  Changed;
end;


procedure TKMGameSettings.SetPlayersColorMode(aValue: TKMPlayerColorMode);
begin
  fPlayersColorMode := aValue;
  Changed;
end;


procedure TKMGameSettings.SetPlayerColorSelf(aValue: Cardinal);
begin
  fPlayerColorSelf := aValue;
  Changed;
end;


procedure TKMGameSettings.SetPlayerColorAlly(aValue: Cardinal);
begin
  fPlayerColorAlly := aValue;
  Changed;
end;


procedure TKMGameSettings.SetPlayerColorEnemy(aValue: Cardinal);
begin
  fPlayerColorEnemy := aValue;
  Changed;
end;


procedure TKMGameSettings.SetDayGamesCount(aValue: Integer);
begin
  fDayGamesCount := aValue;
  Changed;
end;


procedure TKMGameSettings.SetLastDayGamePlayed(aValue: TDateTime);
begin
  fLastDayGamePlayed := aValue;
  Changed;
end;


procedure TKMGameSettings.SetCampaignLastDifficulty(aValue: TKMMissionDifficulty);
begin
  fCampaignLastDifficulty := aValue;
  Changed;
end;


procedure TKMGameSettings.SetReplayAutopause(aValue: Boolean);
begin
  fReplayAutopause := aValue;
  Changed;
end;


procedure TKMGameSettings.SetReplayShowBeacons(aValue: Boolean);
begin
  fReplayShowBeacons := aValue;
  Changed;
end;



procedure TKMGameSettings.SetReplayAutosave(aValue: Boolean);
begin
  fReplayAutosave := aValue;
  Changed;
end;


procedure TKMGameSettings.SetReplayAutosaveFrequency(aValue: Integer);
begin
  fReplayAutosaveFrequency := EnsureRange(aValue, REPLAY_AUTOSAVE_FREQUENCY_MIN, REPLAY_AUTOSAVE_FREQUENCY_MAX);
  Changed;
end;


procedure TKMGameSettings.SetScrollSpeed(aValue: Byte);
begin
  fScrollSpeed := aValue;
  Changed;
end;


procedure TKMGameSettings.SetAlphaShadows(aValue: Boolean);
begin
  fAlphaShadows := aValue;
  Changed;
end;


procedure TKMGameSettings.SetLoadFullFonts(aValue: Boolean);
begin
  fLoadFullFonts := aValue;
  Changed;
end;


procedure TKMGameSettings.SetSoundFXVolume(aValue: Single);
begin
  fSoundFXVolume := EnsureRange(aValue, 0, 1);
  Changed;
end;


procedure TKMGameSettings.SetMultiplayerName(const aValue: AnsiString);
begin
  fMultiplayerName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetLastIP(const aValue: string);
begin
  fLastIP := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMasterServerAddress(const aValue: string);
begin
  fMasterServerAddress := aValue;
  Changed;
end;


procedure TKMGameSettings.SetServerName(const aValue: AnsiString);
begin
  fServerName := aValue;
  Changed;
end;


procedure TKMGameSettings.SetLastPort(const aValue: string);
begin
  fLastPort := aValue;
  Changed;
end;


procedure TKMGameSettings.SetLastRoom(const aValue: string);
begin
  fLastRoom := aValue;
  Changed;
end;


procedure TKMGameSettings.SetLastPassword(const aValue: string);
begin
  fLastPassword := aValue;
  Changed;
end;


procedure TKMGameSettings.SetServerPacketsAccumulatingDelay(aValue: Integer);
begin
  fServerPacketsAccumulatingDelay := EnsureRange(aValue, 0, 1000); //This is rough restrictions. Real one are in TKMNetServer
  Changed;
end;


procedure TKMGameSettings.SetServerPort(const aValue: string);
begin
  fServerPort := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMusicVolume(aValue: Single);
begin
  fMusicVolume := EnsureRange(aValue, 0, 1);
  Changed;
end;


procedure TKMGameSettings.SetMusicOff(aValue: Boolean);
begin
  fMusicOff := aValue;
  Changed;
end;


procedure TKMGameSettings.SetShuffleOn(aValue: Boolean);
begin
  fShuffleOn := aValue;
  Changed;
end;


procedure TKMGameSettings.SetMaxRooms(eValue: Integer);
begin
  fMaxRooms := eValue;
  Changed;
end;


procedure TKMGameSettings.SetHTMLStatusFile(const eValue: UnicodeString);
begin
  fHTMLStatusFile := eValue;
  Changed;
end;


procedure TKMGameSettings.SetMasterAnnounceInterval(eValue: Integer);
begin
  fMasterAnnounceInterval := eValue;
  Changed;
end;


procedure TKMGameSettings.SetPingInterval(aValue: Integer);
begin
  fPingInterval := aValue;
  Changed;
end;


procedure TKMGameSettings.SetAutoKickTimeout(aValue: Integer);
begin
  fAutoKickTimeout := aValue;
  Changed;
end;


procedure TKMGameSettings.SetAnnounceServer(aValue: Boolean);
begin
  fAnnounceServer := aValue;
  Changed;
end;


procedure TKMGameSettings.SetServerWelcomeMessage(const aValue: UnicodeString);
begin
  fServerWelcomeMessage := aValue;
  Changed;
end;


{TKMWindowParams}
constructor TKMWindowParams.Create;
begin
  inherited;
  fIsChanged := False;
  fLockParams := False;
  fNeedResetToDefaults := False;
end;


procedure TKMWindowParams.ApplyWindowParams(const aParams: TKMWindowParamsRecord; aDefaults: Boolean = False);
begin
  if not fLockParams then
  begin
    fWidth := aParams.Width;
    fHeight := aParams.Height;
    fLeft := aParams.Left;
    fTop := aParams.Top;
    fState := aParams.State;
    fIsChanged := True;
    fNeedResetToDefaults := aDefaults;
  end;
end;


procedure TKMWindowParams.LockParams;
begin
  fLockParams := True;
end;


procedure TKMWindowParams.UnlockParams;
begin
  fLockParams := False;
end;


// Check window param, with current Screen object
function TKMWindowParams.IsValid(aMonitorsInfo: TKMPointArray): Boolean;
var I, ScreenMaxWidth, ScreenMaxHeight: Integer;
begin
  ScreenMaxWidth := 0;
  ScreenMaxHeight := 0;
  // Calc Max width/height for multi screen systems
  // Assume appending monitor screens left to right, so summarise width, get max of height
  for I := Low(aMonitorsInfo) to High(aMonitorsInfo) do
  begin
    ScreenMaxWidth := ScreenMaxWidth + aMonitorsInfo[I].X;
    ScreenMaxHeight := max(ScreenMaxHeight, aMonitorsInfo[I].Y);
  end;
  // Do not let put window too much left or right. 100px is enought to get it back in that case
  Result := (fLeft > -fWidth + 100)
        and (fLeft < ScreenMaxWidth - 100)
        and (fTop >= 0)
        and (fTop < ScreenMaxHeight - 100)
        and (fWidth >= MIN_RESOLUTION_WIDTH)
        and (fWidth <= ScreenMaxWidth)
        and (fHeight >= MIN_RESOLUTION_HEIGHT)
        and (fHeight <= ScreenMaxHeight)
        and (fState in [TWindowState.wsNormal, TWindowState.wsMaximized]);
end;


end.

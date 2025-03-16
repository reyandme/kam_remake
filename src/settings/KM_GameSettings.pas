unit KM_GameSettings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC}Forms,{$ENDIF}   //Lazarus do not know UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_WareDistribution, KM_MapTypes,
  KM_Defaults, KM_CommonTypes,
  KM_Lists,
  KM_CommonClasses,

  KM_IoXML, KM_InterfaceTypes,
  KM_GameAppSettingsPart;


type
  TKMSettingsGFX = record
  private
    fBrightness: Byte;
    fInterpolatedAnimations: Boolean;
    procedure SetBrightness(aValue: Byte);
    function GetInterpolatedAnimations: Boolean;
  public
    AlphaShadows: Boolean;
    LoadFullFonts: Boolean;
    InterpolatedRender: Boolean;
    AllowSnowHouses: Boolean;
    property InterpolatedAnimations: Boolean read GetInterpolatedAnimations write fInterpolatedAnimations;
    property Brightness: Byte read fBrightness write SetBrightness;
  end;

  TKMSettingsSFX = record
  private
    fMusicVolume: Single;
    fSoundFXVolume: Single;
    procedure SetMusicVolume(aValue: Single);
    procedure SetSoundFXVolume(aValue: Single);
  public
    MusicEnabled: Boolean;
    ShuffleOn: Boolean;
    property MusicVolume: Single read fMusicVolume write SetMusicVolume;
    property SoundFXVolume: Single read fSoundFXVolume write SetSoundFXVolume;
  end;

  TKMSettingsVideo = record
  private
    fVideoVolume: Single;
    procedure SetVideoVolume(aValue: Single);
  public
    Enabled: Boolean;
    VideoStretch: Boolean;
    PlayOnStartup: Boolean;
    property VideoVolume: Single read fVideoVolume write SetVideoVolume;
  end;


  // Gameplay settings, those that affect the game
  TKMGameSettings = class(TKMGameAppSettingsPart)
  private
    //Game
    fAutosave: Boolean;
    fAutosaveAtGameEnd: Boolean;
    fAutosaveFrequency: Integer;
    fAutosaveCount: Integer;
    fReplayAutopause: Boolean;
    fReplayShowBeacons: Boolean; //Replay variable - show beacons during replay
    fSpecShowBeacons: Boolean;   //Spectator variable - show beacons while spectating
    fShowGameTime: Boolean;      //Show game time label (always)
    fShowGameSpeed: Boolean;     //Show game speed label and clock (always)

    fSaveCheckpoints: Boolean; //Save game checkpoint for replay
    fSaveCheckpointsFreq: Integer;
    fSaveCheckpointsLimit: Integer;

    fPlayersColorMode: TKMPlayerColorMode;
    fPlayerColorSelf: Cardinal;
    fPlayerColorAlly: Cardinal;
    fPlayerColorEnemy: Cardinal;

    fDefaultZoom: Single;
    fZoomBehaviour: TKMZoomBehaviour;
    fScrollSpeed: Single;
    fLocale: AnsiString;
    fSpeedPace: Word;
    fSpeedMedium: Single;
    fSpeedFast: Single;
    fSpeedVeryFast: Single;
    fWareDistribution: TKMWareDistribution;
    fSaveWareDistribution: Boolean;

    fDayGamesCount: Integer;       //Number of games played today (used for saves namings)
    fLastDayGamePlayed: TDateTime; //Last day game played

    //Campaign
    fCampaignLastDifficulty: TKMMissionDifficulty;

    //Replay
    fReplaySavepoint: Boolean;
    fReplaySavepointFrequency: Integer;

    //MapEd
    fMapEdHistoryDepth: Integer;
    fMapEdMaxTerrainHeight: Integer;

    //Multiplayer
    fMultiplayerName: AnsiString;
    fLastIP: string;
    fLastPort: string;
    fLastRoom: string;
    fLastPassword: string;
    fFlashOnMessage: Boolean;

    //Misc
    fAsyncGameResLoader: Boolean;

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

    fDebug_SaveRandomChecks: Boolean;
    fDebug_SaveGameAsText: Boolean;

    fFavouriteMaps: TKMMapsCRCList;

    //Game
    procedure SetAutosaveFrequency(aValue: Integer);
    procedure SetAutosaveCount(aValue: Integer);
    procedure SetLocale(const aLocale: AnsiString);


    procedure SetSaveCheckpointsFreq(const aValue: Integer);
    procedure SetSaveCheckpointsLimit(const aValue: Integer);

    //Replay
    procedure SetReplaySavepointFrequency(aValue: Integer);

    //MapEd
    procedure SetMapEdHistoryDepth(const aValue: Integer);
    procedure SetMapEdMaxTerrainHeight(const aValue: Integer);

    //Menu
    procedure SetMenuFavouriteMapsStr(const aValue: UnicodeString);

    procedure SetSpeedPace(const aValue: Word);
    function GetFavouriteMaps: TKMMapsCRCList;
    function GetAsyncGameResLoader: Boolean;
  public
    GFX: TKMSettingsGFX;
    SFX: TKMSettingsSFX;
    Video: TKMSettingsVideo;

    constructor Create;
    destructor Destroy; override;

    procedure LoadFromXML; override;
    procedure SaveToXML; override;

    procedure LoadFavouriteMapsFromXML;
    procedure SaveFavouriteMapsToXML;

    // Game
    property Autosave: Boolean read fAutosave write fAutosave;
    property AutosaveAtGameEnd: Boolean read fAutosaveAtGameEnd write fAutosaveAtGameEnd;
    property AutosaveFrequency: Integer read fAutosaveFrequency write SetAutosaveFrequency;
    property AutosaveCount: Integer read fAutosaveCount write SetAutosaveCount;
    property SpecShowBeacons: Boolean read fSpecShowBeacons write fSpecShowBeacons;
    property ShowGameTime: Boolean read fShowGameTime write fShowGameTime;
    property ShowGameSpeed: Boolean read fShowGameSpeed write fShowGameSpeed;

    property SaveCheckpoints: Boolean read fSaveCheckpoints write fSaveCheckpoints;
    property SaveCheckpointsFreq: Integer read fSaveCheckpointsFreq write SetSaveCheckpointsFreq;
    property SaveCheckpointsLimit: Integer read fSaveCheckpointsLimit write SetSaveCheckpointsLimit;

    property PlayersColorMode: TKMPlayerColorMode read fPlayersColorMode write fPlayersColorMode;
    property PlayerColorSelf: Cardinal read fPlayerColorSelf write fPlayerColorSelf;
    property PlayerColorAlly: Cardinal read fPlayerColorAlly write fPlayerColorAlly;
    property PlayerColorEnemy: Cardinal read fPlayerColorEnemy write fPlayerColorEnemy;

    property DefaultZoom: Single read fDefaultZoom;
    property ZoomBehaviour: TKMZoomBehaviour read fZoomBehaviour write fZoomBehaviour;
    property ScrollSpeed: Single read fScrollSpeed write fScrollSpeed;
    property Locale: AnsiString read fLocale write SetLocale;
    property SpeedPace: Word read fSpeedPace write SetSpeedPace;
    property SpeedMedium: Single read fSpeedMedium;
    property SpeedFast: Single read fSpeedFast;
    property SpeedVeryFast: Single read fSpeedVeryFast;
    property WareDistribution: TKMWareDistribution read fWareDistribution;
    property SaveWareDistribution: Boolean read fSaveWareDistribution write fSaveWareDistribution;

    property DayGamesCount: Integer read fDayGamesCount write fDayGamesCount;
    property LastDayGamePlayed: TDateTime read fLastDayGamePlayed write fLastDayGamePlayed;

    // Campaign
    property CampaignLastDifficulty: TKMMissionDifficulty read fCampaignLastDifficulty write fCampaignLastDifficulty;

    // Replay
    property ReplayAutopause: Boolean read fReplayAutopause write fReplayAutopause;
    property ReplayShowBeacons: Boolean read fReplayShowBeacons write fReplayShowBeacons;
    property ReplaySavepoint: Boolean read fReplaySavepoint write fReplaySavepoint;
    property ReplaySavepointFrequency: Integer read fReplaySavepointFrequency write SetReplaySavepointFrequency;

    // MapEd
    property MapEdHistoryDepth: Integer read fMapEdHistoryDepth write SetMapEdHistoryDepth;
    property MapEdMaxTerrainHeight: Integer read fMapEdMaxTerrainHeight write SetMapEdMaxTerrainHeight;

    //Multiplayer
    property MultiplayerName: AnsiString read fMultiplayerName write fMultiplayerName;
    property FlashOnMessage: Boolean read fFlashOnMessage write fFlashOnMessage;
    property LastIP: string read fLastIP write fLastIP;
    property LastPort: string read fLastPort write fLastPort;
    property LastRoom: string read fLastRoom write fLastRoom;
    property LastPassword: string read fLastPassword write fLastPassword;

    //Misc
    property AsyncGameResLoader: Boolean read GetAsyncGameResLoader;

    // Menu
    property MenuMapSPType: Byte read fMenu_MapSPType write fMenu_MapSPType;
    property MenuReplaysType: Byte read fMenu_ReplaysType write fMenu_ReplaysType;
    property MenuMapEdMapType: Byte read fMenu_MapEdMapType write fMenu_MapEdMapType;
    property MenuMapEdNewMapX: Word read fMenu_MapEdNewMapX write fMenu_MapEdNewMapX;
    property MenuMapEdNewMapY: Word read fMenu_MapEdNewMapY write fMenu_MapEdNewMapY;
    property MenuMapEdSPMapCRC: Cardinal read fMenu_MapEdSPMapCRC write fMenu_MapEdSPMapCRC;
    property MenuMapEdMPMapCRC: Cardinal read fMenu_MapEdMPMapCRC write fMenu_MapEdMPMapCRC;
    property MenuMapEdMPMapName: UnicodeString read fMenu_MapEdMPMapName write fMenu_MapEdMPMapName;
    property MenuMapEdDLMapCRC: Cardinal read fMenu_MapEdDLMapCRC write fMenu_MapEdDLMapCRC;
    property MenuCampaignName: UnicodeString read fMenu_CampaignName write fMenu_CampaignName;
    property MenuReplaySPSaveName: UnicodeString read fMenu_ReplaySPSaveName write fMenu_ReplaySPSaveName;
    property MenuReplayMPSaveName: UnicodeString read fMenu_ReplayMPSaveName write fMenu_ReplayMPSaveName;
    property MenuSPScenarioMapCRC: Cardinal read fMenu_SPScenarioMapCRC write fMenu_SPScenarioMapCRC;
    property MenuSPMissionMapCRC: Cardinal read fMenu_SPMissionMapCRC write fMenu_SPMissionMapCRC;
    property MenuSPTacticMapCRC: Cardinal read fMenu_SPTacticMapCRC write fMenu_SPTacticMapCRC;
    property MenuSPSpecialMapCRC: Cardinal read fMenu_SPSpecialMapCRC write fMenu_SPSpecialMapCRC;
    property MenuSPSaveFileName: UnicodeString read fMenu_SPSaveFileName write fMenu_SPSaveFileName;
    property MenuLobbyMapType: Byte read fMenu_LobbyMapType write fMenu_LobbyMapType;

    //Debug
    property DebugSaveRandomChecks: Boolean read fDebug_SaveRandomChecks write fDebug_SaveRandomChecks;
    property DebugSaveGameAsText: Boolean read fDebug_SaveGameAsText write fDebug_SaveGameAsText;

    property FavouriteMaps: TKMMapsCRCList read GetFavouriteMaps;
  end;

var
  gGameSettings: TKMGameSettings;


implementation
uses
  SysUtils, INIfiles, Math,
  KM_TerrainTypes;


{ TKMSettingsGFX }
function TKMSettingsGFX.GetInterpolatedAnimations: Boolean;
begin
  Result := InterpolatedRender and fInterpolatedAnimations;
end;


procedure TKMSettingsGFX.SetBrightness(aValue: Byte);
begin
  fBrightness := EnsureRange(aValue, 0, 20);
end;


{ TKMSettingsSFX }
procedure TKMSettingsSFX.SetSoundFXVolume(aValue: Single);
begin
  fSoundFXVolume := EnsureRange(aValue, 0, 1);
end;


procedure TKMSettingsSFX.SetMusicVolume(aValue: Single);
begin
  fMusicVolume := EnsureRange(aValue, 0, 1);
end;


{ TKMSettingsVideo }
procedure TKMSettingsVideo.SetVideoVolume(aValue: Single);
begin
  fVideoVolume := EnsureRange(aValue, 0, 1);
end;


{ TKMGameSettings }
constructor TKMGameSettings.Create;
begin
  inherited;

  fWareDistribution := TKMWareDistribution.Create;

  fFavouriteMaps := TKMMapsCRCList.Create;
  fFavouriteMaps.OnMapsUpdate := SetMenuFavouriteMapsStr;
end;


destructor TKMGameSettings.Destroy;
begin
  FreeAndNil(fWareDistribution);
  FreeAndNil(fFavouriteMaps);

  inherited;
end;


function TKMGameSettings.GetAsyncGameResLoader: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fAsyncGameResLoader;
end;


function TKMGameSettings.GetFavouriteMaps: TKMMapsCRCList;
begin
  if Self = nil then Exit(nil);

  Result := fFavouriteMaps;
end;


procedure TKMGameSettings.LoadFavouriteMapsFromXML;
var
  nGameSettings, nMenu: TKMXmlNode;
begin
  if Self = nil then Exit;

  nGameSettings := Root.AddOrFindChild('Game');

  nMenu := nGameSettings.AddOrFindChild('Menu');
    fMenu_FavouriteMapsStr   := nMenu.Attributes['FavouriteMaps'].AsString('');
    fFavouriteMaps.LoadFromString(fMenu_FavouriteMapsStr);
end;


procedure TKMGameSettings.SaveFavouriteMapsToXML;
var
  nGameSettings, nMenu: TKMXmlNode;
begin
  if Self = nil then Exit;
  if BLOCK_FILE_WRITE then Exit;

  nGameSettings := Root.AddOrFindChild('Game');

  nMenu := nGameSettings.AddOrFindChild('Menu');
    nMenu.Attributes['FavouriteMaps'] := fMenu_FavouriteMapsStr;
end;


procedure TKMGameSettings.LoadFromXML;
var
  nGameSettings,
  nGFX,
  nSFX,
  nMusic,
  nVideo,
  nGameCommon,
    nGameAutosave,
    nGameSavePoints,
    nGamePlayersColor,
    nUI,
    nGameSpeed,
    nGameWareDistribution,
    nGameMisc,
  nGameTweaks,
  nCampaign,
  nReplay,
  nMapEd,
  nMultiplayer,
  nMenu,
    nMenuSP,
    nMenuReplay,
    nMenuMapEd,
  nMisc,
  nDebug: TKMXmlNode;
  tempCard: Int64;
begin
  if Self = nil then Exit;
  inherited;

  nGameSettings := Root.AddOrFindChild('Game');

  // Game GFX
  nGFX := nGameSettings.AddOrFindChild('GFX');
    GFX.Brightness     := nGFX.Attributes['Brightness'].AsInteger(1);
    GFX.AlphaShadows   := nGFX.Attributes['AlphaShadows'].AsBoolean(True);
    GFX.LoadFullFonts  := nGFX.Attributes['LoadFullFonts'].AsBoolean(False);

  // SFX
  nSFX := nGameSettings.AddOrFindChild('SFX');
    SFX.SoundFXVolume  := nSFX.Attributes['Volume'].AsFloat(0.5);

  // Music
  nMusic := nGameSettings.AddOrFindChild('Music');
    SFX.MusicEnabled := nMusic.Attributes['Enabled'].AsBoolean(True);
    SFX.MusicVolume  := nMusic.Attributes['Volume'].AsFloat(0.5);
    SFX.ShuffleOn    := nMusic.Attributes['Shuffle'].AsBoolean(False);

  // Video
  nVideo := nGameSettings.AddOrFindChild('Video');
    Video.Enabled      := nVideo.Attributes['Enabled'].AsBoolean(False); //Disabled by default
    Video.VideoStretch := nVideo.Attributes['Stretch'].AsBoolean(True);
    Video.PlayOnStartup := nVideo.Attributes['Startup'].AsBoolean(True);
    Video.VideoVolume  := nVideo.Attributes['Volume'].AsFloat(1);

  // GameCommon
  nGameCommon := nGameSettings.AddOrFindChild('GameCommon');
    fLocale := AnsiString(nGameCommon.Attributes['Locale'].AsString(UnicodeString(DEFAULT_LOCALE)));
    // UI
    nUI := nGameCommon.AddOrFindChild('UI');
      fDefaultZoom    := nUI.Attributes['DefaultZoom'].AsFloat(1);
      fZoomBehaviour  := TKMZoomBehaviour(nUI.Attributes['ZoomBehaviour'].AsInteger(Ord(zbFull))); // Default zoom value is zbFull
    // Speed
    nGameSpeed := nGameCommon.AddOrFindChild('Speed');
      fSpeedMedium    := nGameSpeed.Attributes['Medium'].AsFloat(3);
      fSpeedFast      := nGameSpeed.Attributes['Fast'].AsFloat(6);
      fSpeedVeryFast  := nGameSpeed.Attributes['VeryFast'].AsFloat(10);
      SpeedPace       := nGameSpeed.Attributes['Pace'].AsInteger(SPEED_PACE_DEFAULT); // Set SpeedPace via setter
      fScrollSpeed    := nGameSpeed.Attributes['ScrollSpeed'].AsFloat(5);

    // Autosave
    nGameAutosave := nGameCommon.AddOrFindChild('Autosave');
      fAutosave           := nGameAutosave.Attributes['Enabled'].AsBoolean(True);
      fAutosaveAtGameEnd  := nGameAutosave.Attributes['OnGameEnd'].AsBoolean(False);
      AutosaveFrequency   := nGameAutosave.Attributes['Frequency'].AsInteger(AUTOSAVE_FREQUENCY_DEFAULT); // With setter
      AutosaveCount       := nGameAutosave.Attributes['Count'].AsInteger(AUTOSAVE_COUNT_DEF); // With setter

    // SavePoints
    nGameSavePoints := nGameCommon.AddOrFindChild('SavePoints');
      fSaveCheckpoints      := nGameSavePoints.Attributes['Enabled'].AsBoolean(True);
      SaveCheckpointsFreq   := nGameSavePoints.Attributes['Frequency'].AsInteger(GAME_SAVE_CHECKPOINT_FREQ_DEF); // With setter
      SaveCheckpointsLimit  := nGameSavePoints.Attributes['Limit'].AsInteger(GAME_SAVE_CHECKPOINT_CNT_LIMIT_DEF); // With setter

    // PlayersColor
    nGamePlayersColor := nGameCommon.AddOrFindChild('PlayersColor');
      fPlayersColorMode := TKMPlayerColorMode(nGamePlayersColor.Attributes['Mode'].AsInteger(Byte(pcmDefault))); //Show players colors by default
      //Load minimap colors as hex strings 6-hex digits width
      if TryStrToInt64('$' + nGamePlayersColor.Attributes['Self'].AsString(IntToHex(Integer(clPlayerSelf and $FFFFFF), 6)), tempCard) then
        fPlayerColorSelf := $FF000000 or tempCard
      else
        fPlayerColorSelf := clPlayerSelf;

      if TryStrToInt64('$' + nGamePlayersColor.Attributes['Ally'].AsString(IntToHex(Integer(clPlayerAlly and $FFFFFF), 6)), tempCard) then
        fPlayerColorAlly := $FF000000 or tempCard
      else
        fPlayerColorAlly := clPlayerAlly;

      if TryStrToInt64('$' + nGamePlayersColor.Attributes['Enemy'].AsString(IntToHex(Integer(clPlayerEnemy and $FFFFFF), 6)), tempCard) then
        fPlayerColorEnemy := $FF000000 or tempCard
      else
        fPlayerColorEnemy := clPlayerEnemy;

    // Ware distribution
    nGameWareDistribution := nGameCommon.AddOrFindChild('WareDistribution');
      fWareDistribution.LoadFromStr(nGameWareDistribution.Attributes['Value'].AsString(''));
      fSaveWareDistribution := nGameWareDistribution.Attributes['SavedBetweenGames'].AsBoolean(True); //Enabled by default

    // Misc
    nGameMisc := nGameCommon.AddOrFindChild('Misc');
      fSpecShowBeacons := nGameMisc.Attributes['SpecShowBeacons'].AsBoolean(False);
      fShowGameTime    := nGameMisc.Attributes['ShowGameTime'].AsBoolean(False);
      fShowGameSpeed   := nGameMisc.Attributes['ShowGameSpeed'].AsBoolean(False);
      fDayGamesCount   := nGameMisc.Attributes['DayGamesCount'].AsInteger(0);
      if nGameMisc.HasAttribute('LastDayGamePlayed') then
        fLastDayGamePlayed  := nGameMisc.Attributes['LastDayGamePlayed'].AsDateTime
      else
        fLastDayGamePlayed  := DATE_TIME_ZERO;

    // Tweaks
    nGameTweaks := nGameCommon.AddOrFindChild('Tweaks');
      GFX.AllowSnowHouses         := nGameTweaks.Attributes['AllowSnowHouses'].AsBoolean(True);
      GFX.InterpolatedRender      := nGameTweaks.Attributes['InterpolatedRender'].AsBoolean(False);
      GFX.InterpolatedAnimations  := nGameTweaks.Attributes['InterpolatedAnimations'].AsBoolean(False);

  // Campaign
  nCampaign := nGameSettings.AddOrFindChild('Campaign');
    fCampaignLastDifficulty := TKMMissionDifficulty(nCampaign.Attributes['CampaignLastDifficulty'].AsInteger(Byte(mdNormal))); //Normal as default

  // Replay
  nReplay := nGameSettings.AddOrFindChild('Replay');
    fReplayAutopause          := nReplay.Attributes['Autopause'].AsBoolean(False);
    fReplayShowBeacons        := nReplay.Attributes['ShowBeacons'].AsBoolean(False);
    fReplaySavepoint          := nReplay.Attributes['Savepoint'].AsBoolean(True);
    ReplaySavepointFrequency  := nReplay.Attributes['SavepointFrequency'].AsInteger(REPLAY_SAVEPOINT_FREQUENCY_DEF); // With setter

  // MapEd
  nMapEd := nGameSettings.AddOrFindChild('MapEd');
    MapEdHistoryDepth     := nMapEd.Attributes['HistoryDepth'].AsInteger(MAPED_HISTORY_DEPTH_DEF); // With setter
    MapEdMaxTerrainHeight := nMapEd.Attributes['MaxTerrainHeight'].AsInteger(HEIGHT_MAX); // With setter;

  // Multiplayer
  nMultiplayer := nGameSettings.AddOrFindChild('Multiplayer');
    fMultiplayerName  := AnsiString(nMultiplayer.Attributes['Name'].AsString('NoName'));
    fLastIP           := nMultiplayer.Attributes['LastIP'].AsString('127.0.0.1');
    fLastPort         := nMultiplayer.Attributes['LastPort'].AsString('56789');
    fLastRoom         := nMultiplayer.Attributes['LastRoom'].AsString('0');
    fLastPassword     := nMultiplayer.Attributes['LastPassword'].AsString('');
    fFlashOnMessage   := nMultiplayer.Attributes['FlashOnMessage'].AsBoolean(True);

  // Misc
  nMisc := nGameSettings.AddOrFindChild('Misc');
    fAsyncGameResLoader := nMisc.Attributes['AsyncGameResLoader'].AsBoolean(True);

  // Menu
  nMenu := nGameSettings.AddOrFindChild('Menu');
    fMenu_FavouriteMapsStr   := nMenu.Attributes['FavouriteMaps'].AsString('');
    fFavouriteMaps.LoadFromString(fMenu_FavouriteMapsStr);
    fMenu_LobbyMapType      := nMenu.Attributes['LobbyMapType'].AsInteger(0);
    fMenu_CampaignName      := nMenu.Attributes['CampaignName'].AsString('');

    nMenuSP := nMenu.AddOrFindChild('Singleplayer');
      fMenu_MapSPType         := nMenuSP.Attributes['Type'].AsInteger(0);
      fMenu_SPScenarioMapCRC  := StrToInt64(nMenuSP.Attributes['ScenarioMapCRC'].AsString('0'));
      fMenu_SPMissionMapCRC   := StrToInt64(nMenuSP.Attributes['MissionMapCRC'].AsString('0'));
      fMenu_SPTacticMapCRC    := StrToInt64(nMenuSP.Attributes['TacticMapCRC'].AsString('0'));
      fMenu_SPSpecialMapCRC   := StrToInt64(nMenuSP.Attributes['SpecialMapCRC'].AsString('0'));
      fMenu_SPSaveFileName    := nMenuSP.Attributes['SaveFileName'].AsString('');

    nMenuReplay := nMenu.AddOrFindChild('Replay');
      fMenu_ReplaysType       := nMenuReplay.Attributes['Type'].AsInteger(0);
      fMenu_ReplaySPSaveName  := nMenuReplay.Attributes['SPSaveName'].AsString('');
      fMenu_ReplayMPSaveName  := nMenuReplay.Attributes['MPSaveName'].AsString('');

    nMenuMapEd := nMenu.AddOrFindChild('MapEd');
      fMenu_MapEdMapType      := nMenuMapEd.Attributes['MapType'].AsInteger(0);
      fMenu_MapEdNewMapX      := nMenuMapEd.Attributes['NewMapX'].AsInteger(128);
      fMenu_MapEdNewMapY      := nMenuMapEd.Attributes['NewMapY'].AsInteger(128);
      fMenu_MapEdSPMapCRC     := StrToInt64(nMenuMapEd.Attributes['SPMapCRC'].AsString('0'));
      fMenu_MapEdMPMapCRC     := StrToInt64(nMenuMapEd.Attributes['MPMapCRC'].AsString('0'));
      fMenu_MapEdMPMapName    := nMenuMapEd.Attributes['MPMapName'].AsString('');
      fMenu_MapEdDLMapCRC     := StrToInt64(nMenuMapEd.Attributes['DLMapCRC'].AsString('0'));

  // Debug
  nDebug := nGameSettings.AddOrFindChild('Debug');
  if SAVE_RANDOM_CHECKS then
    fDebug_SaveRandomChecks := nDebug.Attributes['SaveRandomChecks'].AsBoolean(True);

  if SAVE_GAME_AS_TEXT then
    fDebug_SaveGameAsText := nDebug.Attributes['SaveGameAsText'].AsBoolean(False);

  if INI_HITPOINT_RESTORE then
    HITPOINT_RESTORE_PACE := nDebug.Attributes['HitPointRestorePace'].AsInteger(DEFAULT_HITPOINT_RESTORE)
  else
    HITPOINT_RESTORE_PACE := DEFAULT_HITPOINT_RESTORE;
end;


//Don't rewrite the file for each individual change, do it in one batch for simplicity
procedure TKMGameSettings.SaveToXML;
var
  nGameSettings,
  nGFX,
  nSFX,
  nMusic,
  nVideo,
  nGameCommon,
    nGameAutosave,
    nGameSavePoints,
    nGamePlayersColor,
    nUI,
    nGameSpeed,
    nGameWareDistribution,
    nGameMisc,
  nGameTweaks,
  nCampaign,
  nReplay,
  nMapEd,
  nMultiplayer,
  nMenu,
    nMenuSP,
    nMenuReplay,
    nMenuMapEd,
  nMisc,
  nDebug: TKMXmlNode;
begin
  if Self = nil then Exit;
  if BLOCK_FILE_WRITE then Exit;

  inherited;

  nGameSettings := Root.AddOrFindChild('Game');
  // Clear old data before filling in
  {$IFDEF WDC}
  // Todo: do proper check on FPC
  nGameSettings.Clear;
  {$ENDIF}

  // Game GFX
  nGFX := nGameSettings.AddOrFindChild('GFX');
    nGFX.Attributes['Brightness']     := GFX.Brightness;
    nGFX.Attributes['AlphaShadows']   := GFX.AlphaShadows;
    nGFX.Attributes['LoadFullFonts']  := GFX.LoadFullFonts;

  // SFX
  nSFX := nGameSettings.AddOrFindChild('SFX');
    nSFX.Attributes['Volume'] := SFX.SoundFXVolume;

  // Music
  nMusic := nGameSettings.AddOrFindChild('Music');
    nMusic.Attributes['Enabled']  := SFX.MusicEnabled; // Reversed value
    nMusic.Attributes['Volume']   := SFX.MusicVolume;
    nMusic.Attributes['Shuffle']  := SFX.ShuffleOn;

  // Video
  nVideo := nGameSettings.AddOrFindChild('Video');
    nVideo.Attributes['Enabled']  := Video.Enabled;
    nVideo.Attributes['Stretch']  := Video.VideoStretch;
    nVideo.Attributes['Startup']  := Video.PlayOnStartup;
    nVideo.Attributes['Volume']   := Video.VideoVolume;

  // GameCommon
  nGameCommon := nGameSettings.AddOrFindChild('GameCommon');
    nGameCommon.Attributes['Locale'] := UnicodeString(fLocale);
    // UI
    nUI := nGameCommon.AddOrFindChild('UI');
      nUI.Attributes['DefaultZoom']         := fDefaultZoom;
      nUI.Attributes['ZoomBehaviour']       := Integer(fZoomBehaviour);

    // Speed
    nGameSpeed := nGameCommon.AddOrFindChild('Speed');
      nGameSpeed.Attributes['Medium']       := fSpeedMedium;
      nGameSpeed.Attributes['Fast']         := fSpeedFast;
      nGameSpeed.Attributes['VeryFast']     := fSpeedVeryFast;
      nGameSpeed.Attributes['Pace']         := fSpeedPace;
      nGameSpeed.Attributes['ScrollSpeed']  := fScrollSpeed;

    // Autosave
    nGameAutosave := nGameCommon.AddOrFindChild('Autosave');
      nGameAutosave.Attributes['Enabled']   := fAutosave;
      nGameAutosave.Attributes['OnGameEnd'] := fAutosaveAtGameEnd;
      nGameAutosave.Attributes['Frequency'] := fAutosaveFrequency;
      nGameAutosave.Attributes['Count']     := fAutosaveCount;

    // SavePoints
    nGameSavePoints := nGameCommon.AddOrFindChild('SavePoints');
      nGameSavePoints.Attributes['Enabled']   := fSaveCheckpoints;
      nGameSavePoints.Attributes['Frequency'] := fSaveCheckpointsFreq;
      nGameSavePoints.Attributes['Limit']     := fSaveCheckpointsLimit;

    // PlayersColor
    nGamePlayersColor := nGameCommon.AddOrFindChild('PlayersColor');
      nGamePlayersColor.Attributes['Mode']  := Byte(fPlayersColorMode);
      nGamePlayersColor.Attributes['Self']  := IntToHex(fPlayerColorSelf and $FFFFFF, 6);
      nGamePlayersColor.Attributes['Ally']  := IntToHex(fPlayerColorAlly and $FFFFFF, 6);
      nGamePlayersColor.Attributes['Enemy'] := IntToHex(fPlayerColorEnemy and $FFFFFF, 6);

    // Ware distribution
    nGameWareDistribution := nGameCommon.AddOrFindChild('WareDistribution');
      nGameWareDistribution.Attributes['Value'] := fWareDistribution.PackToStr;
      nGameWareDistribution.Attributes['SavedBetweenGames'] := fSaveWareDistribution;

    // Misc
    nGameMisc := nGameCommon.AddOrFindChild('Misc');
      nGameMisc.Attributes['SpecShowBeacons']   := fSpecShowBeacons;
      nGameMisc.Attributes['ShowGameTime']      := fShowGameTime;
      nGameMisc.Attributes['ShowGameSpeed']     := fShowGameSpeed;
      nGameMisc.Attributes['DayGamesCount']     := fDayGamesCount;
      nGameMisc.Attributes['LastDayGamePlayed'] := fLastDayGamePlayed;

    // Tweaks
    nGameTweaks := nGameCommon.AddOrFindChild('Tweaks');
      nGameTweaks.Attributes['AllowSnowHouses']         := GFX.AllowSnowHouses;
      nGameTweaks.Attributes['InterpolatedRender']      := GFX.InterpolatedRender;
      nGameTweaks.Attributes['InterpolatedAnimations']  := GFX.InterpolatedAnimations;

  // Campaign
  nCampaign := nGameSettings.AddOrFindChild('Campaign');
    nCampaign.Attributes['CampaignLastDifficulty'] := Byte(fCampaignLastDifficulty);

  // Replay
  nReplay := nGameSettings.AddOrFindChild('Replay');
    nReplay.Attributes['Autopause']          := fReplayAutopause;
    nReplay.Attributes['ShowBeacons']        := fReplayShowBeacons;
    nReplay.Attributes['Savepoint']          := fReplaySavepoint;
    nReplay.Attributes['SavepointFrequency'] := fReplaySavepointFrequency;

  // MapEd
  nMapEd := nGameSettings.AddOrFindChild('MapEd');
    nMapEd.Attributes['HistoryDepth'] := fMapEdHistoryDepth;
    nMapEd.Attributes['MaxTerrainHeight'] := fMapEdMaxTerrainHeight;

  // Multiplayer
  nMultiplayer := nGameSettings.AddOrFindChild('Multiplayer');
    nMultiplayer.Attributes['Name']           := UnicodeString(fMultiplayerName);
    nMultiplayer.Attributes['LastIP']         := fLastIP;
    nMultiplayer.Attributes['LastPort']       := fLastPort;
    nMultiplayer.Attributes['LastRoom']       := fLastRoom;
    nMultiplayer.Attributes['LastPassword']   := fLastPassword;
    nMultiplayer.Attributes['FlashOnMessage'] := fFlashOnMessage;

  // Misc
  nMisc := nGameSettings.AddOrFindChild('Misc');
    nMisc.Attributes['AsyncGameResLoader'] := fAsyncGameResLoader;

  // Menu
  nMenu := nGameSettings.AddOrFindChild('Menu');
    nMenu.Attributes['FavouriteMaps'] := fMenu_FavouriteMapsStr;
    nMenu.Attributes['CampaignName']  := fMenu_CampaignName;
    nMenu.Attributes['LobbyMapType']  := fMenu_LobbyMapType;

    nMenuSP := nMenu.AddOrFindChild('Singleplayer');
      nMenuSP.Attributes['Type'] := fMenu_MapSPType;
      nMenuSP.Attributes['ScenarioMapCRC']  := IntToStr(fMenu_SPScenarioMapCRC);
      nMenuSP.Attributes['MissionMapCRC']   := IntToStr(fMenu_SPMissionMapCRC);
      nMenuSP.Attributes['TacticMapCRC']    := IntToStr(fMenu_SPTacticMapCRC);
      nMenuSP.Attributes['SpecialMapCRC']   := IntToStr(fMenu_SPSpecialMapCRC);
      nMenuSP.Attributes['SaveFileName']    := fMenu_SPSaveFileName;

    nMenuReplay := nMenu.AddOrFindChild('Replay');
      nMenuReplay.Attributes['Type']       := fMenu_ReplaysType;
      nMenuReplay.Attributes['SPSaveName'] := fMenu_ReplaySPSaveName;
      nMenuReplay.Attributes['MPSaveName'] := fMenu_ReplayMPSaveName;

    nMenuMapEd := nMenu.AddOrFindChild('MapEd');
      nMenuMapEd.Attributes['MapType']    := fMenu_MapEdMapType;
      nMenuMapEd.Attributes['NewMapX']    := fMenu_MapEdNewMapX;
      nMenuMapEd.Attributes['NewMapY']    := fMenu_MapEdNewMapY;
      nMenuMapEd.Attributes['SPMapCRC']   := IntToStr(fMenu_MapEdSPMapCRC);
      nMenuMapEd.Attributes['MPMapCRC']   := IntToStr(fMenu_MapEdMPMapCRC);
      nMenuMapEd.Attributes['MPMapName']  := fMenu_MapEdMPMapName;
      nMenuMapEd.Attributes['DLMapCRC']   := IntToStr(fMenu_MapEdDLMapCRC);

  // Debug
  nDebug := nGameSettings.AddOrFindChild('Debug');
  if SAVE_RANDOM_CHECKS then
    nDebug.Attributes['SaveRandomChecks'] := fDebug_SaveRandomChecks;

  if SAVE_GAME_AS_TEXT then
    nDebug.Attributes['SaveGameAsText'] := fDebug_SaveGameAsText;

  if INI_HITPOINT_RESTORE then
    nDebug.Attributes['HitPointRestorePace'] := HITPOINT_RESTORE_PACE;
end;


procedure TKMGameSettings.SetLocale(const aLocale: AnsiString);
begin
  //We can get some unsupported LocaleCode, but that is fine, it will have Eng fallback anyway
  fLocale := aLocale;
end;


procedure TKMGameSettings.SetMenuFavouriteMapsStr(const aValue: UnicodeString);
begin
  // This proc is used by an event
  fMenu_FavouriteMapsStr := aValue;
end;


procedure TKMGameSettings.SetAutosaveCount(aValue: Integer);
begin
  fAutosaveCount := EnsureRange(aValue, AUTOSAVE_COUNT_MIN, AUTOSAVE_COUNT_MAX);
end;


procedure TKMGameSettings.SetAutosaveFrequency(aValue: Integer);
begin
  fAutosaveFrequency := EnsureRange(aValue, AUTOSAVE_FREQUENCY_MIN, AUTOSAVE_FREQUENCY_MAX);
end;


procedure TKMGameSettings.SetSpeedPace(const aValue: Word);
begin
  // Allow to set speed pace only while in debug mode.
  // Its possible to alter game speed now, so there is no need actual need for speed pace change
  // And actual game speed is recorded in the game / replay, but speed pace is not.
  // So its better to show on what actual speed some speedrunner made his crazy run
  {$IFDEF DEBUG}
  fSpeedPace := aValue;
  {$ELSE}
  fSpeedPace := SPEED_PACE_DEFAULT;
  {$ENDIF}
end;


procedure TKMGameSettings.SetSaveCheckpointsFreq(const aValue: Integer);
begin
  fSaveCheckpointsFreq := EnsureRange(aValue, GAME_SAVE_CHECKPOINT_FREQ_MIN, GAME_SAVE_CHECKPOINT_FREQ_MAX);
end;


procedure TKMGameSettings.SetSaveCheckpointsLimit(const aValue: Integer);
begin
  fSaveCheckpointsLimit := EnsureRange(aValue, GAME_SAVE_CHECKPOINT_CNT_LIMIT_MIN, GAME_SAVE_CHECKPOINT_CNT_LIMIT_MAX);
end;


procedure TKMGameSettings.SetReplaySavepointFrequency(aValue: Integer);
begin
  fReplaySavepointFrequency := EnsureRange(aValue, REPLAY_SAVEPOINT_FREQUENCY_MIN, REPLAY_SAVEPOINT_FREQUENCY_MAX);
end;


procedure TKMGameSettings.SetMapEdHistoryDepth(const aValue: Integer);
begin
  fMapEdHistoryDepth := EnsureRange(aValue, MAPED_HISTORY_DEPTH_MIN, MAPED_HISTORY_DEPTH_MAX);
end;


procedure TKMGameSettings.SetMapEdMaxTerrainHeight(const aValue: Integer);
begin
  fMapEdMaxTerrainHeight := EnsureRange(aValue, 0, HEIGHT_MAX);
end;


end.

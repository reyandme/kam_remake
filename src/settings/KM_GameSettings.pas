unit KM_GameSettings;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF FPC}Forms,{$ENDIF}   //Lazarus do not know UITypes
  {$IFDEF WDC}UITypes,{$ENDIF} //We use settings in console modules
  KM_WareDistribution, KM_MapTypes,
  KM_Defaults, KM_CommonTypes, KM_CommonClasses,

  KM_IoXML,
  KM_GameAppSettings;


type
  //Gameplay settings, those that affect the game
  //Everything gets written through setter to set fNeedsSave flag
  TKMGameSettings = class(TKMGameAppSettingsPart)
  private
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
    fShowGameSpeed: Boolean;     //Show game speed label and clock (always)

    fSaveCheckpoints: Boolean; //Save game checkpoint for replay
    fSaveCheckpointsFreq: Integer;
    fSaveCheckpointsLimit: Integer;

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
    fSaveWareDistribution: Boolean;

    fDayGamesCount: Integer;       //Number of games played today (used for saves namings)
    fLastDayGamePlayed: TDateTime; //Last day game played

    //GameTweaks
    fGameTweaks_AllowSnowHouses: Boolean;
    fGameTweaks_InterpolatedRender: Boolean;
    fGameTweaks_InterpolatedAnimations: Boolean;

    //Campaign
    fCampaignLastDifficulty: TKMMissionDifficulty;

    //Replay
    fReplaySavepoint: Boolean;
    fReplaySavepointFrequency: Integer;

    //SFX
    fMusicOff: Boolean;
    fShuffleOn: Boolean;
    fMusicVolume: Single;
    fSoundFXVolume: Single;

    //Video
    fVideoOn: Boolean;
    fVideoStretch: Boolean;
    fVideoStartup: Boolean;
    fVideoVolume: Single;

    //MapEd
    fMapEdHistoryDepth: Integer;

    //Multiplayer
    fMultiplayerName: AnsiString;
    fLastIP: string;
    fLastPort: string;
    fLastRoom: string;
    fLastPassword: string;
    fFlashOnMessage: Boolean;

    //Misc
    fAsyncGameResLoad: Boolean;

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
    procedure SetShowGameSpeed(aValue: Boolean);

    procedure SetSaveWareDistribution(const aValue: Boolean);
    procedure SetSaveCheckpoints(const aValue: Boolean);
    procedure SetSaveCheckpointsFreq(const aValue: Integer);
    procedure SetSaveCheckpointsLimit(const aValue: Integer);

    procedure SetPlayersColorMode(aValue: TKMPlayerColorMode);
    procedure SetPlayerColorSelf(aValue: Cardinal);
    procedure SetPlayerColorAlly(aValue: Cardinal);
    procedure SetPlayerColorEnemy(aValue: Cardinal);

    procedure SetDayGamesCount(aValue: Integer);
    procedure SetLastDayGamePlayed(aValue: TDateTime);

    //GameTweaks
    procedure SetAllowSnowHouses(aValue: Boolean);
    procedure SetInterpolatedRender(aValue: Boolean);
    procedure SetInterpolatedAnimations(const Value: Boolean);

    //Campaign
    procedure SetCampaignLastDifficulty(aValue: TKMMissionDifficulty);

    //Replay
    procedure SetReplayAutopause(aValue: Boolean);
    procedure SetReplayShowBeacons(aValue: Boolean);
    procedure SetReplaySavepoint(aValue: Boolean);
    procedure SetReplaySavepointFrequency(aValue: Integer);

    //SFX
    procedure SetMusicOff(aValue: Boolean);
    procedure SetShuffleOn(aValue: Boolean);
    procedure SetMusicVolume(aValue: Single);
    procedure SetSoundFXVolume(aValue: Single);

    //Video
    procedure SetVideoOn(aValue: Boolean);
    procedure SetVideoStretch(aValue: Boolean);
    procedure SetVideoStartup(aValue: Boolean);
    procedure SetVideoVolume(aValue: Single);

    //MapEd
    procedure SetMapEdHistoryDepth(const aValue: Integer);

    //Multiplayer
    procedure SetMultiplayerName(const aValue: AnsiString);
    procedure SetLastIP(const aValue: string);
    procedure SetLastPort(const aValue: string);
    procedure SetLastRoom(const aValue: string);
    procedure SetLastPassword(const aValue: string);
    procedure SetFlashOnMessage(aValue: Boolean);

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

    //Debug
    procedure SetDebugSaveRandomChecks(aValue: Boolean);
    procedure SetDebugSaveGameAsText(aValue: Boolean);
    procedure SetSpeedPace(const aValue: Word);
    function GetFavouriteMaps: TKMMapsCRCList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SaveSettings(aForce: Boolean = False); override;

    procedure LoadFromXML; override;
    procedure SaveToXML; override;

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
    property ShowGameSpeed: Boolean read fShowGameSpeed write SetShowGameSpeed;

    property SaveCheckpoints: Boolean read fSaveCheckpoints write SetSaveCheckpoints;
    property SaveCheckpointsFreq: Integer read fSaveCheckpointsFreq write SetSaveCheckpointsFreq;
    property SaveCheckpointsLimit: Integer read fSaveCheckpointsLimit write SetSaveCheckpointsLimit;

    property PlayersColorMode: TKMPlayerColorMode read fPlayersColorMode write SetPlayersColorMode;
    property PlayerColorSelf: Cardinal read fPlayerColorSelf write SetPlayerColorSelf;
    property PlayerColorAlly: Cardinal read fPlayerColorAlly write SetPlayerColorAlly;
    property PlayerColorEnemy: Cardinal read fPlayerColorEnemy write SetPlayerColorEnemy;

    property ScrollSpeed: Byte read fScrollSpeed write SetScrollSpeed;
    property Locale: AnsiString read fLocale write SetLocale;
    property SpeedPace: Word read fSpeedPace write SetSpeedPace;
    property SpeedMedium: Single read fSpeedMedium;
    property SpeedFast: Single read fSpeedFast;
    property SpeedVeryFast: Single read fSpeedVeryFast;
    property WareDistribution: TKMWareDistribution read fWareDistribution;
    property SaveWareDistribution: Boolean read fSaveWareDistribution write SetSaveWareDistribution;

    property DayGamesCount: Integer read fDayGamesCount write SetDayGamesCount;
    property LastDayGamePlayed: TDateTime read fLastDayGamePlayed write SetLastDayGamePlayed;

    //GameTweaks
    property AllowSnowHouses: Boolean read fGameTweaks_AllowSnowHouses write SetAllowSnowHouses;
    property InterpolatedRender: Boolean read fGameTweaks_InterpolatedRender write SetInterpolatedRender;
    property InterpolatedAnimations: Boolean read fGameTweaks_InterpolatedAnimations write SetInterpolatedAnimations;

    //Campaign
    property CampaignLastDifficulty: TKMMissionDifficulty read fCampaignLastDifficulty write SetCampaignLastDifficulty;

    //Replay
    property ReplayAutopause: Boolean read fReplayAutopause write SetReplayAutopause;
    property ReplayShowBeacons: Boolean read fReplayShowBeacons write SetReplayShowBeacons;
    property ReplaySavepoint: Boolean read fReplaySavepoint write SetReplaySavepoint;
    property ReplaySavepointFrequency: Integer read fReplaySavepointFrequency write SetReplaySavepointFrequency;

    //SFX
    property MusicOff: Boolean read fMusicOff write SetMusicOff;
    property ShuffleOn: Boolean read fShuffleOn write SetShuffleOn;
    property MusicVolume: Single read fMusicVolume write SetMusicVolume;
    property SoundFXVolume: Single read fSoundFXVolume write SetSoundFXVolume;

    //Video
    property VideoOn: Boolean read fVideoOn write SetVideoOn;
    property VideoStretch: Boolean read fVideoStretch write SetVideoStretch;
    property VideoStartup: Boolean read fVideoStartup write SetVideoStartup;
    property VideoVolume: Single read fVideoVolume write SetVideoVolume;

    //MapEd
    property MapEdHistoryDepth: Integer read fMapEdHistoryDepth write SetMapEdHistoryDepth;

    //Multiplayer
    property MultiplayerName: AnsiString read fMultiplayerName write SetMultiplayerName;
    property FlashOnMessage: Boolean read fFlashOnMessage write SetFlashOnMessage;
    property LastIP: string read fLastIP write SetLastIP;
    property LastPort: string read fLastPort write SetLastPort;
    property LastRoom: string read fLastRoom write SetLastRoom;
    property LastPassword: string read fLastPassword write SetLastPassword;

    //Misc
    property AsyncGameResLoad: Boolean read fAsyncGameResLoad;

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

    //Debug
    property DebugSaveRandomChecks: Boolean read fDebug_SaveRandomChecks write SetDebugSaveRandomChecks;
    property DebugSaveGameAsText: Boolean read fDebug_SaveGameAsText write SetDebugSaveGameAsText;

    property FavouriteMaps: TKMMapsCRCList read GetFavouriteMaps;
  end;

var
  gGameSettings: TKMGameSettings;


implementation
uses
  SysUtils, INIfiles, Math;


{ TGameSettings }
constructor TKMGameSettings.Create;
begin
  fWareDistribution := TKMWareDistribution.Create;

  fFavouriteMaps := TKMMapsCRCList.Create;
  fFavouriteMaps.OnMapsUpdate := SetMenuFavouriteMapsStr;

  inherited;

  gGameSettings := Self;
end;


destructor TKMGameSettings.Destroy;
begin
  inherited; // Save settings first

  // Cleanup everything afterwards
  FreeAndNil(fWareDistribution);
  FreeAndNil(fFavouriteMaps);

  gGameSettings := nil;
end;


function TKMGameSettings.GetFavouriteMaps: TKMMapsCRCList;
begin
  if Self = nil then Exit(nil);

  Result := fFavouriteMaps;
end;


//Save only when needed
procedure TKMGameSettings.SaveSettings(aForce: Boolean = False);
begin
  if SKIP_SETTINGS_SAVE then Exit;

  if NeedsSave or fWareDistribution.Changed or aForce then
    gGameAppSettings.SaveSettings(aForce);
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
    fBrightness     := nGFX.Attributes['Brightness'].AsInteger(1);
    fAlphaShadows   := nGFX.Attributes['AlphaShadows'].AsBoolean(True);
    fLoadFullFonts  := nGFX.Attributes['LoadFullFonts'].AsBoolean(False);

  // SFX
  nSFX := nGameSettings.AddOrFindChild('SFX');
    fSoundFXVolume  := nSFX.Attributes['Volume'].AsFloat(0.5);

  // Music
  nMusic := nGameSettings.AddOrFindChild('Music');
    fMusicOff     := not nMusic.Attributes['Enabled'].AsBoolean(True); // Reversed value
    fMusicVolume  := nMusic.Attributes['Volume'].AsFloat(0.5);
    fShuffleOn    := nMusic.Attributes['Shuffle'].AsBoolean(False);

  // Video
  nVideo := nGameSettings.AddOrFindChild('Video');
    fVideoOn      := nVideo.Attributes['Enabled'].AsBoolean(False); //Disabled by default
    fVideoStretch := nVideo.Attributes['Stretch'].AsBoolean(True);
    fVideoStartup := nVideo.Attributes['Startup'].AsBoolean(True);
    fVideoVolume  := nVideo.Attributes['Volume'].AsFloat(0.5);

  // GameCommon
  nGameCommon := nGameSettings.AddOrFindChild('GameCommon');
    fLocale := AnsiString(nGameCommon.Attributes['Locale'].AsString(UnicodeString(DEFAULT_LOCALE)));
    // Speed
    nGameSpeed := nGameCommon.AddOrFindChild('Speed');
      fSpeedMedium    := nGameSpeed.Attributes['Medium'].AsFloat(3);
      fSpeedFast      := nGameSpeed.Attributes['Fast'].AsFloat(6);
      fSpeedVeryFast  := nGameSpeed.Attributes['VeryFast'].AsFloat(10);
      SpeedPace       := nGameSpeed.Attributes['Pace'].AsInteger(SPEED_PACE_DEFAULT); // Set SpeedPace via setter
      fScrollSpeed    := nGameSpeed.Attributes['ScrollSpeed'].AsInteger(10);

    // Autosave
    nGameAutosave := nGameCommon.AddOrFindChild('Autosave');
      fAutosave           := nGameAutosave.Attributes['Enabled'].AsBoolean(True);
      fAutosaveAtGameEnd  := nGameAutosave.Attributes['OnGameEnd'].AsBoolean(False);
      fAutosaveFrequency  := nGameAutosave.Attributes['Frequency'].AsInteger(AUTOSAVE_FREQUENCY_DEFAULT);
      fAutosaveCount      := nGameAutosave.Attributes['Count'].AsInteger(AUTOSAVE_COUNT_DEF);

    // SavePoints
    nGameSavePoints := nGameCommon.AddOrFindChild('SavePoints');
      fSaveCheckpoints      := nGameSavePoints.Attributes['Enabled'].AsBoolean(True);
      fSaveCheckpointsFreq  := nGameSavePoints.Attributes['Frequency'].AsInteger(GAME_SAVE_CHECKPOINT_FREQ_DEF);
      fSaveCheckpointsLimit := nGameSavePoints.Attributes['Limit'].AsInteger(GAME_SAVE_CHECKPOINT_CNT_LIMIT_DEF);

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
      fSpecShowBeacons    := nGameMisc.Attributes['SpecShowBeacons'].AsBoolean(False);
      fShowGameTime       := nGameMisc.Attributes['ShowGameTime'].AsBoolean(False);
      fShowGameSpeed      := nGameMisc.Attributes['ShowGameSpeed'].AsBoolean(False);
      fDayGamesCount      := nGameMisc.Attributes['DayGamesCount'].AsInteger(0);
      if nGameMisc.HasAttribute('LastDayGamePlayed') then
        fLastDayGamePlayed  := nGameMisc.Attributes['LastDayGamePlayed'].AsDateTime
      else
        fLastDayGamePlayed  := DATE_TIME_ZERO;

    // Tweaks
    nGameTweaks := nGameCommon.AddOrFindChild('Tweaks');
      AllowSnowHouses     := nGameTweaks.Attributes['AllowSnowHouses'].AsBoolean(True);     // With restriction by ALLOW_SNOW_HOUSES
      InterpolatedRender  := nGameTweaks.Attributes['InterpolatedRender'].AsBoolean(False); // With restriction by ALLOW_INTERPOLATED_RENDER

  // Campaign
  nCampaign := nGameSettings.AddOrFindChild('Campaign');
    fCampaignLastDifficulty := TKMMissionDifficulty(nCampaign.Attributes['CampaignLastDifficulty'].AsInteger(Byte(mdNormal))); //Normal as default

  // Replay
  nReplay := nGameSettings.AddOrFindChild('Replay');
    fReplayAutopause := nReplay.Attributes['Autopause'].AsBoolean(False);
    fReplayShowBeacons := nReplay.Attributes['ShowBeacons'].AsBoolean(False);
    fReplaySavepoint := nReplay.Attributes['Savepoint'].AsBoolean(True);
    fReplaySavepointFrequency := nReplay.Attributes['SavepointFrequency'].AsInteger(REPLAY_SAVEPOINT_FREQUENCY_DEF);

  // MapEd
  nMapEd := nGameSettings.AddOrFindChild('MapEd');
    MapEdHistoryDepth := nMapEd.Attributes['HistoryDepth'].AsInteger(MAPED_HISTORY_DEPTH_DEF); // With setter

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
    fAsyncGameResLoad := nMisc.Attributes['AsyncGameResLoad'].AsBoolean(False);

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

  // Game GFX
  nGFX := nGameSettings.AddOrFindChild('GFX');
    nGFX.Attributes['Brightness']     := fBrightness;
    nGFX.Attributes['AlphaShadows']   := fAlphaShadows;
    nGFX.Attributes['LoadFullFonts']  := fLoadFullFonts;

  // SFX
  nSFX := nGameSettings.AddOrFindChild('SFX');
    nSFX.Attributes['Volume'] := fSoundFXVolume;

  // Music
  nMusic := nGameSettings.AddOrFindChild('Music');
    nMusic.Attributes['Enabled']  := not fMusicOff; // Reversed value
    nMusic.Attributes['Volume']   := fMusicVolume;
    nMusic.Attributes['Shuffle']  := fShuffleOn;

  // Video
  nVideo := nGameSettings.AddOrFindChild('Video');
    nVideo.Attributes['Enabled']  := fVideoOn;
    nVideo.Attributes['Stretch']  := fVideoStretch;
    nVideo.Attributes['Startup']  := fVideoStartup;
    nVideo.Attributes['Volume']   := fVideoVolume;

  // GameCommon
  nGameCommon := nGameSettings.AddOrFindChild('GameCommon');
    nGameCommon.Attributes['Locale'] := UnicodeString(fLocale);
    // Speed
    nGameSpeed := nGameCommon.AddOrFindChild('Speed');
      nGameSpeed.Attributes['Medium']       := fSpeedMedium;
      nGameSpeed.Attributes['Fast']         := fSpeedFast;
      nGameSpeed.Attributes['VeryFast']     := fSpeedVeryFast;
      nGameSpeed.Attributes['Pace']         := fSpeedPace;
      nGameSpeed.Attributes['ScrollSpeed']  := fScrollSpeed;

    // Autosave
    nGameAutosave := nGameCommon.AddOrFindChild('Autosave');
      nGameAutosave.Attributes['Enabled']          := fAutosave;
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
      nGameTweaks.Attributes['AllowSnowHouses']     := fGameTweaks_AllowSnowHouses;
      nGameTweaks.Attributes['InterpolatedRender']  := fGameTweaks_InterpolatedRender;

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
    nMisc.Attributes['AsyncGameResLoad'] := fAsyncGameResLoad;

  // Menu
  nMenu := nGameSettings.AddOrFindChild('Menu');
    nMenu.Attributes['FavouriteMaps'] := fMenu_FavouriteMapsStr;
    nMenu.Attributes['CampaignName']      := fMenu_CampaignName;
    nMenu.Attributes['LobbyMapType']      := fMenu_LobbyMapType;

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


procedure TKMGameSettings.SetDebugSaveRandomChecks(aValue: Boolean);
begin
  fDebug_SaveRandomChecks := aValue;
  Changed;
end;


procedure TKMGameSettings.SetDebugSaveGameAsText(aValue: Boolean);
begin
  fDebug_SaveGameAsText := aValue;
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


procedure TKMGameSettings.SetSaveWareDistribution(const aValue: Boolean);
begin
  fSaveWareDistribution := aValue;
  Changed;
end;


procedure TKMGameSettings.SetShowGameTime(aValue: Boolean);
begin
  fShowGameTime := aValue;
  Changed;
end;


procedure TKMGameSettings.SetShowGameSpeed(aValue: Boolean);
begin
  fShowGameSpeed := aValue;
  Changed;
end;


procedure TKMGameSettings.SetSaveCheckpoints(const aValue: Boolean);
begin
  fSaveCheckpoints := aValue;
  Changed;
end;


procedure TKMGameSettings.SetSaveCheckpointsFreq(const aValue: Integer);
begin
  fSaveCheckpointsFreq := EnsureRange(aValue, GAME_SAVE_CHECKPOINT_FREQ_MIN, GAME_SAVE_CHECKPOINT_FREQ_MAX);
  Changed;
end;


procedure TKMGameSettings.SetSaveCheckpointsLimit(const aValue: Integer);
begin
  fSaveCheckpointsLimit := EnsureRange(aValue, GAME_SAVE_CHECKPOINT_CNT_LIMIT_MIN, GAME_SAVE_CHECKPOINT_CNT_LIMIT_MAX);
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


procedure TKMGameSettings.SetAllowSnowHouses(aValue: Boolean);
begin
  if not ALLOW_SNOW_HOUSES then Exit;

  fGameTweaks_AllowSnowHouses := aValue;
  Changed;
end;

procedure TKMGameSettings.SetInterpolatedAnimations(const Value: Boolean);
begin
  if not ALLOW_INTERPOLATED_ANIMS then Exit;

  fGameTweaks_InterpolatedAnimations := Value;
end;


procedure TKMGameSettings.SetInterpolatedRender(aValue: Boolean);
begin
  if not ALLOW_INTERPOLATED_RENDER then Exit;

  fGameTweaks_InterpolatedRender := aValue;
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


procedure TKMGameSettings.SetReplaySavepoint(aValue: Boolean);
begin
  fReplaySavepoint := aValue;
  Changed;
end;


procedure TKMGameSettings.SetReplaySavepointFrequency(aValue: Integer);
begin
  fReplaySavepointFrequency := EnsureRange(aValue, REPLAY_SAVEPOINT_FREQUENCY_MIN, REPLAY_SAVEPOINT_FREQUENCY_MAX);
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


procedure TKMGameSettings.SetVideoOn(aValue: Boolean);
begin
  fVideoOn := aValue;
  Changed;
end;


procedure TKMGameSettings.SetVideoStretch(aValue: Boolean);
begin
  fVideoStretch := aValue;
  Changed;
end;


procedure TKMGameSettings.SetVideoStartup(aValue: Boolean);
begin
  fVideoStartup := aValue;
  Changed;
end;


procedure TKMGameSettings.SetVideoVolume(aValue: Single);
begin
  fVideoVolume := EnsureRange(aValue, 0, 1);
  Changed;
end;


procedure TKMGameSettings.SetMapEdHistoryDepth(const aValue: Integer);
begin
  fMapEdHistoryDepth := EnsureRange(aValue, MAPED_HISTORY_DEPTH_MIN, MAPED_HISTORY_DEPTH_MAX);
  Changed;
end;


end.

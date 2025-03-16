unit KM_Game;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_WorkerThread,
  KM_Networking,
  KM_PathFinding,
  KM_GameParams, KM_GameInputProcess,
  KM_GameSavePoints,
  KM_GameOptions, KM_GameTypes,
  KM_MapEditor, KM_Campaigns, KM_Maps, KM_MapTypes, KM_CampaignClasses, KM_TerrainPainter,
  KM_Render, KM_Scripting,
  KM_MediaTypes,
  KM_InterfaceGame, KM_InterfaceGamePlay, KM_InterfaceMapEditor,
  KM_ResTypes, KM_ResFonts, KM_ResTexts,
  KM_Hand,
  KM_Defaults, KM_Points, KM_CommonTypes, KM_CommonClasses, KM_CommonClassesExt,
  KM_GameUIDTracker;

type
  // Class that manages single game session
  TKMGame = class
  private // Irrelevant to savegame
    fOptions: TKMGameOptions;
    fGameInputProcess: TKMGameInputProcess;
    fTextMission: TKMTextLibraryMulti;
    fPathfinding: TKMPathFinding;
    fActiveInterface: TKMUserInterfaceGame; // Shortcut for both of UI
    fGamePlayInterface: TKMGamePlayInterface;
    fMapEditorInterface: TKMMapEdInterface;
    fMapEditor: TKMMapEditor;
    fTerrainPainter: TKMTerrainPainter;
    fSavePoints: TKMSavePointCollection;
    fScripting: TKMScripting;
    fOnDestroy: TEvent;

    fIsExiting: Boolean; // Set this to True on Exit and unit/house pointers will be released without cross-checking
    fIsPaused: Boolean;
    fSpeedActual: Single; // Actual speedup value, used to play the game
    fSpeedMultiplier: Word; // How many ticks are compressed into one
    fWaitingForNetwork: Boolean; // Indicates that we are waiting for other players commands in MP
    fAdvanceFrame: Boolean; // Replay variable to advance 1 frame, afterwards set to False
    fLockedMutex: Boolean;
    fIgnoreConsistencyCheckErrors: Boolean; // User can ignore all consistency check errors while watching SP replay

    fParams: TKMGameParams;
    fSetGameTickEvent: TCardinalEvent;
    fSetGameTickFracEvent: TSingleEvent;
    fSetGameModeEvent: TKMGameModeSetEvent;
    fSetMissionFileSP: TUnicodeStringEvent;
    fSetBlockPointer: TBooleanEvent;

    fAIType: TKMAIType;
    fMapTxtInfo: TKMMapTxtInfo;

    // Should be saved
    fCampaignMission: Byte;         // Which campaign map it is, so we can unlock next one on victory
    fCampaignName: TKMCampaignId;  // Is this a game part of some campaign
    fSpeedGIP: Single; // GameSpeed, recorded to GIP, could be requested by scripts
    fSpeedChangeAllowed: Boolean; // Is game speed change allowed?

    // Saved to local data
    fLastReplayTickLocal: Cardinal; // stored / loaded in the .sloc file, if available
    fSkipReplayEndCheck: Boolean;

    // Do not save
    fSpeedChangeTick: Single;
    fSpeedChangeTime: Cardinal; // time of last game speed change
    fPausedTicksCnt: Cardinal;
    fIsJustStarted: Boolean; // True when game is just started (loaded save / savepoint / started) and no ticks were played yet

    fLastTimeUserAction: Cardinal;
    fLastAfkMessageSent: Cardinal;
    fLastUpdateState: Cardinal;

    fReadyToStop: Boolean;
    fSeed: Integer;

    // Relative pathname to savegame we are playing (game was loaded from it� '.bas' file for replays), so it gets saved to crashreport
    fLoadFromFileRel: UnicodeString;
    fLastSaveFileRel: UnicodeString;  // Relative pathname to last savegame we are playing, so game could restart from this point

    fAutosavesCnt: Integer;
    fLastSaves: TKMLimitedUniqueList<string>;

    fIsStarted: Boolean;

    fDoHold: Boolean; // Request to run Hold after UpdateState has finished
    fDoHoldState: TKMGameResultMsg; // The type of Hold we want to occur due to DoGameHold

    fLastSaveStreamSize: Cardinal;

    // Worker threads
    fSaveWorkerThreadHolder: TKMWorkerThreadHolder; // Worker thread for normal saves and save at the end of PT
    fBaseSaveWorkerThreadHolder: TKMWorkerThreadHolder; // Worker thread for base save only
    fAutoSaveWorkerThreadHolder: TKMWorkerThreadHolder; // Worker thread for autosaves only
    fSavePointWorkerThreadHolder: TKMWorkerThreadHolder; // Worker thread for savepoints only

    fMapEdMapSaveStarted: TEvent;
    fMapEdMapSaveEnded: TEvent;

    procedure IssueAutosaveCommand(aAfterPT: Boolean);
    function FindHandToSpec: Integer;
    function CheckIfPieceTimeJustEnded: Boolean;
    function GetWaitingPlayersList: TKMByteArray;
    function GetControlledHandIndex: TKMHandID;
    procedure UserAction(aActionType: TKMUserActionType);
    function GetReplayAutosaveEffectiveFrequency: Integer;

    function GetMapEditor: TKMMapEditor;
    function GetGamePlayInterface: TKMGamePlayInterface;

    procedure GameMPDisconnect(const aData: UnicodeString);
    procedure OtherPlayerDisconnected(aDefeatedPlayerHandId: Integer);
    function GetActiveHandIDs: TKMByteSet;

    procedure VisibleLayersWereSet;

    procedure RecalcMapCRC;

    function GetTickDuration: Single;
    procedure UpdateTickCounters;
    function GetTicksBehindCnt: Single;
    procedure SetIsPaused(aValue: Boolean);
    function GetIsPlayerWaiting: Boolean;

    function IsMPGameSpeedChangeAllowed: Boolean;

    procedure GameSpeedActualChanged(aFromSpeed, aToSpeed: Single);
    procedure SetSpeedActualValue(aSpeed: Single);

    procedure IncTick;
    function CheckPauseGameAtTick: Boolean;
    function IsReplayEnded: Boolean;

    {$IFDEF RNG_SPY} function DoSaveRandomChecks: Boolean; {$ENDIF}

    function DoSaveGameAsText: Boolean;
    function DoRenderGame: Boolean;

    procedure MultiplayerRig(aNewGame: Boolean);

    procedure PrepareSaveFolder(const aPathName: String; aSaveByPlayer: Boolean; aSaveWorkerThread: TKMWorkerThread);
    procedure SaveGameToStream(aTimestamp: TDateTime; aSaveStream: TKMemoryStream); overload;
    procedure SaveGameToStream(aTimestamp: TDateTime; aHeaderStream, aBodyStream: TKMemoryStream); overload;
    procedure SaveGameToFile(const aPathName: String; aSaveByPlayer: Boolean; aSaveWorkerThread: TKMWorkerThread; aTimestamp: TDateTime; const aMPLocalDataPathName: String = '');

    function PlayGameTick: Boolean;
    function PlayReplayTick: Boolean;

    function PlayNextTick: Boolean;
    function GetMapSize: TKMPoint;
    function GetMapSizeInfo: UnicodeString;
  public
    GameResult: TKMGameResultMsg;

    StartedFromMapEditor: Boolean;    // True if we start game from map editor ('Quick Play')
    StartedFromMapEdAsMPMap: Boolean; // True if we start game from map editor ('Quick Play') with MP map

    constructor Create(aGameMode: TKMGameMode; aRender: TKMRender; aOnDestroy: TEvent;
                       aSaveWorkerThreadHolder,
                       aBaseSaveWorkerThreadHolder,
                       aAutoSaveWorkerThreadHolder,
                       aSavePointWorkerThreadHolder: TKMWorkerThreadHolder);
    destructor Destroy; override;

    procedure Start(const aMissionFullFilePath, aName: UnicodeString; aFullCRC, aSimpleCRC: Cardinal; aCampaign: TKMCampaign;
                    aCampMission: Byte; aLocation: ShortInt; aColor: Cardinal; aMapDifficulty: TKMMissionDifficulty = mdNone;
                    aAIType: TKMAIType = aitNone);

    procedure AfterStart;
    procedure MapEdStartEmptyMap(aSizeX, aSizeY: Integer);
    procedure LoadFromStream(var LoadStream: TKMemoryStream);
    procedure LoadFromFile(const aPathName: UnicodeString; const aCustomReplayFile: UnicodeString = '');
    procedure LoadSavePoint(aTick: Cardinal; const aSaveFile: UnicodeString);
    procedure AfterLoad;

    procedure Save(const aSaveName: UnicodeString); overload;
    procedure Save(const aSaveName: UnicodeString; aTimestamp: TDateTime); overload;
    procedure Save(const aSaveName: UnicodeString; aTimestamp: TDateTime; aSaveWorkerThread: TKMWorkerThread); overload;
    procedure SaveAndWait(const aSaveName: UnicodeString);
    procedure WaitForSaveToBeDone;
    procedure WaitForAllSavesToBeDone;

    procedure AutoSave(aTimestamp: TDateTime);
    procedure AutoSaveAfterPT(aTimestamp: TDateTime);
    procedure MakeSavePoint;
    procedure SaveMapEditor(const aPathName: UnicodeString); overload;
    procedure SaveMapEditor(const aPathName: UnicodeString; const aInsetRect: TKMRect); overload;

    procedure RestartReplay; // Restart the replay but keep current viewport position/zoom

    property MapSizeInfo: UnicodeString read GetMapSizeInfo;
    property MapSize: TKMPoint read GetMapSize;

    procedure GameMPPlay;
    procedure GameMPReadyToPlay;
    procedure Hold(aDoHold: Boolean; Msg: TKMGameResultMsg); // Hold the game to ask if player wants to play after Victory/Defeat/ReplayEnd
    procedure RequestHold(Msg: TKMGameResultMsg);
    procedure PlayerVictory(aHandIndex: TKMHandID);
    procedure PlayerDefeat(aPlayerIndex: TKMHandID; aShowDefeatMessage: Boolean = True);
    procedure WaitingPlayersDisplay(aWaiting: Boolean);
    procedure WaitingPlayersDrop;
    procedure ShowScriptError(const aMsg: UnicodeString);

    property AIType: TKMAIType read fAIType;

    property IsExiting: Boolean read fIsExiting;
    property IsPaused: Boolean read fIsPaused write SetIsPaused;
    property IsWaitingForNetwork: Boolean read fWaitingForNetwork;
    property IsPlayerWaiting: Boolean read GetIsPlayerWaiting;

    property IsStarted: Boolean read fIsStarted;
    property ReadyToStop: Boolean read fReadyToStop write fReadyToStop;

    function MissionTime: TDateTime;
    function GetPeacetimeRemaining: TDateTime;
    function CheckTime(aTimeTicks: Cardinal): Boolean;
    function IsPeaceTime: Boolean;

    function IsSpeedUpAllowed: Boolean;
    function CanMPPlayerChangeSpeed: Boolean;

    function IsWareDistributionStoredBetweenGames: Boolean;
    procedure DebugControlsUpdated(Sender: TObject; aSenderTag: Integer);

    property MapTxtInfo: TKMMapTxtInfo read fMapTxtInfo;
    procedure ShowMessage(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aEntityUID: Integer; aHandIndex: TKMHandID);
    procedure ShowMessageLocal(aKind: TKMMessageKind; const aText: UnicodeString; const aLoc: TKMPoint);

    procedure OverlayUpdate;
    procedure OverlaySet(aHand: TKMHandID; const aMarkup: AnsiString; aParams: array of const);
    procedure OverlayAppend(aHand: TKMHandID; const aMarkup: AnsiString; aParams: array of const);
    procedure OverlaySetWordWrap(aHand: TKMHandID; aWordWrap: Boolean);
    procedure OverlaySetFont(aHand: TKMHandID; aFont: TKMFont);

    property CampaignName: TKMCampaignId read fCampaignName;
    property CampaignMap: Byte read fCampaignMission;
    property SpeedActual: Single read fSpeedActual;
    property SpeedGIP: Single read fSpeedGIP;
    property SpeedChangeAllowed: Boolean read fSpeedChangeAllowed write fSpeedChangeAllowed;
    property TickDuration: Single read GetTickDuration;
    property SavePoints: TKMSavePointCollection read fSavePoints write fSavePoints;

    function PlayerLoc: Byte; // Can used in SP game/replay only
    function PlayerColor: Cardinal; // Can used in SP game/replay only

    property ControlledHandIndex: TKMHandID read GetControlledHandIndex;

    property Scripting: TKMScripting read fScripting;
    property Params: TKMGameParams read fParams;
    property SaveFile: UnicodeString read fLoadFromFileRel;

    procedure AddScriptSoundRemoveRequest(aScriptSoundUID: Integer; aHandID: TKMHandID);
    function GetScriptSoundFilePath(const aSound: AnsiString; aAudioFormat: TKMAudioFormat): UnicodeString;

    property LastReplayTickLocal: Cardinal read fLastReplayTickLocal write fLastReplayTickLocal;
    property SkipReplayEndCheck: Boolean read fSkipReplayEndCheck write fSkipReplayEndCheck;
    function GetReplayLastTick: Cardinal;

    property IgnoreConsistencyCheckErrors: Boolean read fIgnoreConsistencyCheckErrors;

    property LockedMutex: Boolean read fLockedMutex write fLockedMutex;

    function GetNormalSpeed: Single;
    function GetToggledNormalSpeed: Single;
    procedure StepOneFrame;

    procedure TrySetSpeed(aSpeed: Single; aToggle: Boolean);
    procedure SetSpeed(aSpeed: Single); overload;
    procedure SetSpeed(aSpeed: Single; aToggle: Boolean); overload;
    procedure SetSpeed(aSpeed: Single; aToggle: Boolean; aToggleTo: Single); overload;

    procedure SetSpeedActual(aSpeed: Single);
    procedure SetSpeedGIP(aSpeed: Single; aUpdateActual: Boolean = False; aUpdateOptionsSpeed: Boolean = False);

    class function SavePath(const aName: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;
    class function SaveName(const aFolder, aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString; overload;
    class function SaveName(const aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString; overload;

    procedure UpdateMultiplayerTeams;

    function GetHandsCount: Integer;

    property Pathfinding: TKMPathFinding read fPathfinding;
    property GameInputProcess: TKMGameInputProcess read fGameInputProcess write fGameInputProcess;
    property Options: TKMGameOptions read fOptions;
    property ActiveInterface: TKMUserInterfaceGame read fActiveInterface;
    property GamePlayInterface: TKMGamePlayInterface read GetGamePlayInterface;
    property MapEditorInterface: TKMMapEdInterface read fMapEditorInterface;
    property MapEditor: TKMMapEditor read GetMapEditor;
    property TerrainPainter: TKMTerrainPainter read fTerrainPainter;
    property TextMission: TKMTextLibraryMulti read fTextMission;

    procedure SetSeed(aSeed: Integer);

    property LastSaves: TKMLimitedUniqueList<string> read fLastSaves;
    property SaveWorkerThreadHolder: TKMWorkerThreadHolder read fSaveWorkerThreadHolder;

    function GetCurrectTickSaveCRC: Cardinal;
    procedure ReplayInconsistency(aCommand: TKMStoredGIPCommand; aMyRand: Cardinal);
    procedure SaveCampaignScriptData(SaveStream: TKMemoryStream);

    procedure Render(aRender: TKMRender);
    procedure UpdateGame;
    procedure UpdateState(aGlobalTickCount: Cardinal);
    procedure UpdateStateIdle(aFrameTime: Cardinal);
  end;


var
  gGame: TKMGame;


implementation
uses
  {$IFDEF PARALLEL_RUNNER}
    KM_AIParameters, // If you want to remove this, then please make sure that the Runner can be compiled with ParallelRunner Build Configuration
  {$ENDIF}
  {$IFDEF FPC}
  Types,
  {$IFDEF Unix}
  LCLType, Controls,
  {$ENDIF}
  {$ENDIF}
  {$IFDEF WDC} System.Types, {$ENDIF}
  Classes, SysUtils, Math, TypInfo,
  Dialogs,
  {$IFDEF WDC} UITypes, {$ENDIF}
  KromUtils,
  KM_Sound, KM_ScriptSound,
  KM_PathFindingAStarOld, KM_PathFindingAStarNew, KM_PathFindingJPS,
  KM_Projectiles, KM_AIFields, KM_NetworkTypes,
  KM_Main, KM_System, KM_GameApp, KM_RenderPool, KM_GameInfo, KM_GameClasses,
  KM_Terrain, KM_TerrainTypes, KM_HandsCollection, KM_HandSpectator, KM_MapEdTypes,
  KM_MissionScript, KM_MissionScript_Info, KM_MissionScript_Standard,
  KM_GameInputProcess_Multi, KM_GameInputProcess_Single,
  KM_Resource, KM_ResSound,
  KM_InterfaceDefaults, KM_InterfaceTypes, KM_GameSettings, KM_GameAppSettings,
  KM_Log, KM_ScriptingEvents, KM_Saves, KM_FileIO, KM_CommonUtils,
  {$IFDEF RNG_SPY} KM_RandomChecks, {$ENDIF}
  KM_DevPerfLog, KM_DevPerfLogTypes,
  KM_NetPlayersList,
  KM_HandTypes, KM_ResLocales,
  KM_ServerSettings,
  KM_CampaignTypes,
  KM_MapUtils, KM_Utils, KM_WorkerThreadUtils;

const
  LAST_SAVES_MAX_CNT = 5; // Max number of save names to collect for crashreport

// Create template for the Game
// aRender - who will be rendering the Game session
// aNetworking - access to MP stuff
constructor TKMGame.Create(aGameMode: TKMGameMode; aRender: TKMRender; aOnDestroy: TEvent;
                           aSaveWorkerThreadHolder,
                           aBaseSaveWorkerThreadHolder,
                           aAutoSaveWorkerThreadHolder,
                           aSavePointWorkerThreadHolder: TKMWorkerThreadHolder);
const
  UI_MODE: array [TKMGameMode] of TUIMode = (umSP, umSP, umMP, umSpectate, umSP, umReplay, umReplay);
begin
  inherited Create;

  // Suppress Alt key for menu while in the game. We can use Alt key as a modificator for some hotkeys (for School hotkeys, f.e.)
  if gMain <> nil then
    gMain.FormMain.SuppressAltForMenu := True;

  fParams := TKMGameParams.Create(aGameMode, RecalcMapCRC, VisibleLayersWereSet, fSetGameTickEvent, fSetGameTickFracEvent,
                                  fSetGameModeEvent, fSetMissionFileSP, fSetBlockPointer);

  fSaveWorkerThreadHolder := aSaveWorkerThreadHolder;
  fBaseSaveWorkerThreadHolder := aBaseSaveWorkerThreadHolder;
  fAutoSaveWorkerThreadHolder := aAutoSaveWorkerThreadHolder;
  fSavePointWorkerThreadHolder := aSavePointWorkerThreadHolder;

  fOnDestroy := aOnDestroy;

  fAdvanceFrame := False;
  gUIDTracker := TKMGameUIDTracker.Create;
  GameResult   := grCancel;
  fDoHold    := False;
  fSkipReplayEndCheck := False;
  fWaitingForNetwork := False;
  fOptions  := TKMGameOptions.Create;
  fSpeedChangeTick := 0;
  fSpeedChangeTime := 0;
  fSpeedChangeAllowed := True;
  fPausedTicksCnt := 0;
  fLastTimeUserAction := TimeGet;
  fLastAfkMessageSent := 0;

  fIsStarted := False;
  fIsPaused := False;
  fIsExiting := False;
  fIsJustStarted := False;

  fTerrainPainter := TKMTerrainPainter.Create;

  fSavePoints := TKMSavePointCollection.Create;

  fMapTxtInfo := TKMMapTxtInfo.Create;

  fLastSaves := TKMLimitedUniqueList<string>.Create(LAST_SAVES_MAX_CNT);
  fAutosavesCnt := 0;

  // UserInterface is different between Gameplay and MapEd
  if (aRender = nil) then // Render can be nil if map is generated by Random Map Generator
  begin
    fMapEditorInterface := nil;
    fActiveInterface := nil;
  end
  else
  begin
    if fParams.IsMapEditor then
    begin
      fMapEditorInterface := TKMMapEdInterface.Create(aRender, fMapEdMapSaveStarted, fMapEdMapSaveEnded);
      fActiveInterface := fMapEditorInterface;
    end
    else
    begin
      fGamePlayInterface := TKMGamePlayInterface.Create(aRender, UI_MODE[fParams.Mode]);
      fGamePlayInterface.OnUserAction := UserAction;
      fActiveInterface := fGamePlayInterface;
    end;
  end;

  // pseudo GIP command, since we just want to initialize speed with default values
  SetSpeedGIP(GAME_SPEED_NORMAL, True);

  fSpeedChangeTime := TimeGet;

  // Here comes terrain/mission init
  SetKaMSeed(4); //Every time the game will be the same as previous. Good for debug.
  gTerrain := TKMTerrain.Create;
  gHands := TKMHandsCollection.Create;
  gAIFields := TKMAIFields.Create;

  {$IFDEF PERFLOG}
  gPerfLogs.GameCreated;
  {$ENDIF}
  gLog.AddTime('<== Game creation is done ==>');

  gScriptSounds := TKMScriptSoundsManager.Create; //Currently only used by scripting
  fScripting := TKMScriptingCreator.CreateGameScripting(ShowScriptError);

  fIgnoreConsistencyCheckErrors := False;

  case PATHFINDER_TO_USE of
    0:    fPathfinding := TKMPathfindingAStarOld.Create;
    1:    fPathfinding := TKMPathfindingAStarNew.Create;
    2:    fPathfinding := TKMPathfindingJPS.Create;
  else
    fPathfinding := TKMPathfindingAStarOld.Create;
  end;
  gProjectiles := TKMProjectiles.Create(gRenderPool.AddProjectile);

  {$IFDEF RNG_SPY}
  if gRandomCheckLogger <> nil then
  begin
    gRandomCheckLogger.Clear;
    gRandomCheckLogger.Enabled := not fParams.IsMapEditor and not fParams.IsReplay; //Disable random check logger for MapEditor
  end;
  {$ENDIF}

  gGameSettings.PlayersColorMode := pcmDefault;
end;


// Destroy what was created
destructor TKMGame.Destroy;
begin
  if gMain <> nil then
    gMain.FormMain.SuppressAltForMenu := False;

  // We might have crashed part way through .Create, so we can't assume ANYTHING exists here.
  // Doing so causes a 2nd exception which overrides 1st. Hence check <> nil on everything except Frees, TObject.Free does that already.

  if fLockedMutex then gMain.UnlockMutex;
  fIsExiting := True;

  // if (fGameInputProcess <> nil) and (fGameInputProcess.ReplayState = gipRecording) then
  //   fGameInputProcess.SaveToFile(SaveName('basesave', EXT_SAVE_REPLAY, fParams.IsMultiplayerOrSpec));

  FreeThenNil(fTerrainPainter);

  FreeThenNil(fMapEditor);
  FreeThenNil(gHands);
  FreeThenNil(gTerrain);
  FreeAndNil(gAIFields);
  FreeAndNil(gProjectiles);
  FreeAndNil(fPathfinding);
  FreeAndNil(fScripting);
  FreeAndNil(gScriptSounds);
  FreeAndNil(fMapTxtInfo);
  FreeAndNil(fLastSaves);

  // Could be nil, if want to reuse fGIP for other gGame instance (gGame could be recreated when jump between checkpoints in replay)
  if fSavePoints <> nil then
    FreeAndNil(fSavePoints);

  FreeThenNil(fGamePlayInterface);
  FreeThenNil(fMapEditorInterface);

  // Could be nil, if want to reuse fGIP for other gGame instance (gGame could be recreated when jump between checkpoints in replay)
  if fGameInputProcess <> nil then
    FreeAndNil(fGameInputProcess);

  FreeAndNil(fOptions);
  FreeAndNil(gUIDTracker);
  FreeAndNil(fTextMission);

  // When leaving the game we should always reset the cursor in case the user had beacon or linking selected
  gSystem.Cursor := kmcDefault;

  FreeAndNil(gMySpectator);

  {$IFDEF RNG_SPY}
  if gRandomCheckLogger <> nil then
    gRandomCheckLogger.Clear;
  {$ENDIF}

  FreeAndNil(fParams);

  if Assigned(fOnDestroy) then
    fOnDestroy();

  inherited;
end;


function TKMGame.GetMapSize: TKMPoint;
begin
  Result := KMPoint(gTerrain.MapX, gTerrain.MapY);
end;


function TKMGame.GetMapSizeInfo: UnicodeString;
begin
  Result := 'Map size: ' + IntToStr(gTerrain.MapX) + ' x ' + IntToStr(gTerrain.MapY);
end;


// New mission
procedure TKMGame.Start(const aMissionFullFilePath, aName: UnicodeString; aFullCRC, aSimpleCRC: Cardinal; aCampaign: TKMCampaign;
                            aCampMission: Byte; aLocation: ShortInt; aColor: Cardinal;
                            aMapDifficulty: TKMMissionDifficulty = mdNone; aAIType: TKMAIType = aitNone);
const
  GAME_PARSE: array [TKMGameMode] of TKMMissionParsingMode = (
    mpmSingle, mpmSingle, mpmMulti, mpmMulti, mpmEditor, mpmSingle, mpmSingle);
var
  I: Integer;
  parseMode: TKMMissionParsingMode;
  playerEnabled: TKMHandEnabledArray;
  parser: TKMMissionParserStandard;
  parserPlayerInfo: TKMMissionParserInfo;
  mapInfo: TKMMapInfo;
  campDataStream: TKMemoryStream;
  campaignDataFilePath: UnicodeString;
begin
  gLog.AddTime('GameStart');
  Assert(fParams.Mode in [gmMulti, gmMultiSpectate, gmMapEd, gmSingle, gmCampaign]);

  gRes.Units.ResetToDefaults;
  gRes.Wares.ResetToDefaults;

  fParams.Name := aName;

  fParams.MissionFullFilePath := aMissionFullFilePath;

  fParams.MapSimpleCRC := aSimpleCRC;
  fParams.MapFullCRC := aFullCRC;

  fCampaignName := nil;

  if aCampaign <> nil then
    fCampaignName := aCampaign.Spec.CampaignId;

  fCampaignMission := aCampMission;
  fParams.MissionDifficulty := aMapDifficulty;
  fAIType := aAIType;

  if fParams.IsMultiPlayerOrSpec then
    fSetMissionFileSP('') // In MP map could be in DL or MP folder, so don't store path
  else
    fSetMissionFileSP(ExtractRelativePath(ExeDir, aMissionFullFilePath)); // We store relative path

  fLoadFromFileRel := '';
  fLastSaveFileRel := '';
  FreeAndNil(gMySpectator); // In case somebody looks at it while parsing DAT, e.g. destroyed houses

  gLog.AddTime('Loading DAT file: ' + aMissionFullFilePath);

  // Disable players in MP to skip their assets from loading by MissionParser
  // In SP all players are enabled by default
  case fParams.Mode of
    gmMulti, gmMultiSpectate:
              begin
                gNetworking.ResetPacketsStats;
                fParams.DynamicFOW := gNetworking.NetGameFilter.DynamicFOW;
                FillChar(playerEnabled, SizeOf(playerEnabled), #0);
                for I := 1 to gNetworking.NetPlayers.Count do
                  if not gNetworking.NetPlayers[I].IsSpectator then
                    playerEnabled[gNetworking.NetPlayers[I].HandIndex] := True;

                // Fixed AIs are always enabled (e.g. coop missions)
                for I := 0 to gNetworking.MapInfo.LocCount - 1 do
                  if (gNetworking.MapInfo.CanBeClassicAI[I] or gNetworking.MapInfo.CanBeAdvancedAI[I])
                    and not gNetworking.MapInfo.CanBeHuman[I] then
                    playerEnabled[I] := True;
              end;
    gmSingle, gmCampaign: // Setup should tell us which player is AI and which not

              // We have to preload map players info, so we could check what player to enable
              // F.e. human only should be disabled, if it was not chosen as a starting loc for a player (f.e. when test MP maps as an SP map)
              // or Classic AI only loc should be disabled for if AdvancedAI type was chosen to play against
              // We have to disable certain locs before parsing the map,
              // otherwise it will hard or even impossible to clean it afterwards
              // (f.e. its impossible to clean wine/corn fields, since terrain under them will be overwritten)
              begin
                mapInfo := TKMMapInfo.CreateDummy;
                parserPlayerInfo := TKMMissionParserInfo.Create;
                try
                  parserPlayerInfo.LoadMission(aMissionFullFilePath, mapInfo, pmPlayers);
                finally
                  parserPlayerInfo.Free;
                end;

                // -1 means automatically detect the location (used for tutorials and campaigns)
                if aLocation = -1 then
                  aLocation := mapInfo.DefaultHuman;

                Assert(InRange(aLocation, 0, mapInfo.LocCount - 1), 'No human player detected');

                for I := 0 to mapInfo.LocCount - 1 do
                  // Enable loc for player,
                  // or if AI can be placed on a loc and (same AI type is chosen or if there are no other AI types allowed on that loc)
                  playerEnabled[I] :=  (I = aLocation)
                                    or (mapInfo.CanBeClassicAI[I]  and ((fAIType = aitClassic) or mapInfo.AICanBeOnlyClassic[I]))
                                    or (mapInfo.CanBeAdvancedAI[I] and ((fAIType = aitAdvanced) or mapInfo.AICanBeOnlyAdvanced[I]));
                mapInfo.Free;
              end;

    else      FillChar(playerEnabled, SizeOf(playerEnabled), #255);
  end;

  // Choose how we will parse the script
  parseMode := GAME_PARSE[fParams.Mode];

  if fParams.IsMapEditor then
  begin
    // Mission loader needs to read the data into MapEd (e.g. FOW revealers)
    fMapEditor := TKMMapEditor.Create(False, fTerrainPainter, fMapEditorInterface.HistoryUndoRedo, fMapEditorInterface.HistoryAddCheckpoint);
    fMapEditor.OnEyedropper := fMapEditorInterface.GuiTerrain.GuiTiles.TilesTableSetTileTexId;
    fMapEditor.DetectAttachedFiles(aMissionFullFilePath);
  end;

  parser := TKMMissionParserStandard.Create(parseMode, playerEnabled);
  try
    // Any fatal errors in parsing will be raised as exceptions and caught up higher
    parser.LoadMission(aMissionFullFilePath);

    if fParams.IsMapEditor then
    begin
      // Activate all players
      gHands.AddPlayers(MAX_HANDS - gHands.Count);

      for I := 0 to gHands.Count - 1 do
        gHands[I].FogOfWar.RevealEverything;

      gMySpectator := TKMSpectator.Create(0);
      gMySpectator.FOWIndex := HAND_NONE;
    end
    else
    if fParams.IsSingleplayerGame then
    begin
      for I := 0 to gHands.Count - 1 do
        gHands[I].HandType := hndComputer;

      // We already determined human location on players-info parsing step
      // but for some manually edit maps locs could have no assets while being enabled in the .dat
      Assert(InRange(aLocation, 0, gHands.Count - 1), 'No human player was detected');
      gHands[aLocation].HandType := hndHuman;

      gMySpectator := TKMSpectator.Create(aLocation);

      // If no color specified use default from mission file (don't overwrite it)
      if aColor <> NO_OVERWRITE_COLOR then
        gMySpectator.Hand.FlagColor := aColor;

      // Set Advanced AI for only advanced locs and if choosen Advanced AI in Single map setup or no other AI types are allowed
      for I := 0 to gHands.Count - 1 do
        if gHands[I].Enabled
          and gHands[I].IsComputer
          and (aitAdvanced in gHands[I].CanBeAITypes)
          and ((fAIType = aitAdvanced) or (gHands[I].CanBeAITypes = [aitAdvanced])) then
          gHands[I].AI.Setup.EnableAdvancedAI;
    end;

    if parser.MinorErrors <> '' then
      if fParams.IsMapEditor then
        fMapEditorInterface.ShowMessage('Warnings in mission script:|' + parser.MinorErrors)
      else
        fGamePlayInterface.MessageIssue(mkQuill, 'Warnings in mission script:|' + parser.MinorErrors);

    if not fParams.IsMapEditor then
    begin
      if aCampaign <> nil then
      begin
        campDataStream := aCampaign.SavedData.ScriptDataStream;
        campDataStream.Seek(0, soBeginning); //Seek to the beginning before we read it
        campaignDataFilePath := aCampaign.GetCampaignDataScriptFilePath;
      end
      else
      begin
        campDataStream := nil;
        campaignDataFilePath := '';
      end;

      fScripting.LoadFromFile(ChangeFileExt(aMissionFullFilePath, '.script'), campaignDataFilePath, campDataStream);
      // fScripting reports compile errors itself now
    end;


    // MapTxtInfo should be loaded before MultiplayerRig, since we use map txt params there in UpdateHandState
    fMapTxtInfo.LoadTXTInfo(ChangeFileExt(aMissionFullFilePath, '.txt'));

    // Set default goals for SP game on MP map with PlayableAsSP flag
    if fParams.IsSingle
      and fMapTxtInfo.IsPlayableAsSP
      and fMapTxtInfo.CanAddDefaultGoals then
      gHands.AddDefaultGoalsToAll(fParams.MissionMode);


    case fParams.Mode of
      gmMulti, gmMultiSpectate:
                begin
                  fGameInputProcess := TKMGameInputProcess_Multi.Create(gipRecording);
                  fTextMission := TKMTextLibraryMulti.Create;
                  // Make a full scan for Libx top ID, to allow unordered Libx ID's by not carefull mapmakers
                  fTextMission.LoadLocale(ChangeFileExt(aMissionFullFilePath, '.%s.libx'));
                end;
      gmSingle, gmCampaign:
                begin
                  fGameInputProcess := TKMGameInputProcess_Single.Create(gipRecording);
                  fTextMission := TKMTextLibraryMulti.Create;
                  // Make a full scan for Libx top ID, to allow unordered Libx ID's by not carefull mapmakers
                  fTextMission.LoadLocale(ChangeFileExt(aMissionFullFilePath, '.%s.libx'));
                end;
      gmMapEd:  ;
    end;

    gLog.AddTime('Gameplay recording initialized', True);

    if fParams.IsMultiPlayerOrSpec then
      MultiplayerRig(True);

    // some late operations for parser (f.e. ProcessAttackPositions, which should be done after MultiplayerRig)
    parser.PostLoadMission;
  finally
    parser.Free;
  end;

  gLog.AddTime('Game options: ' + fOptions.ToString);
  gLog.AddTime('Gameplay initialized', True);
end;


procedure TKMGame.AfterStart;
var
  I: Integer;
  viewPos: TKMPointF;
begin
  gLog.AddTime('After game start');
  gHands.AfterMissionInit;

  // Random after StartGame and ViewReplay should match
  if fParams.IsMultiPlayerOrSpec then
    SetSeed(gNetworking.NetGameOptions.RandomSeed)
  else
    SetSeed(RandomRange(1, 2147483646));

  // We need to make basesave.bas since we don't know the savegame name
  // until after user saves it, but we need to attach replay base to it.
  // Basesave is sort of temp we save to HDD instead of keeping in RAM
  if fParams.Mode in [gmSingle, gmCampaign, gmMulti, gmMultiSpectate] then
    {$IFDEF PARALLEL_RUNNER}
      SaveGameToFile(SaveName('basesave_thread_' + IntToStr(THREAD_NUMBER), EXT_SAVE_BASE, fParams.IsMultiplayerOrSpec), False, fBaseSaveWorkerThreadHolder.Worker, UTCNow);
    {$ELSE}
      SaveGameToFile(SaveName(BASESAVE_NAME, EXT_SAVE_BASE, fParams.IsMultiplayerOrSpec), False, fBaseSaveWorkerThreadHolder.Worker, UTCNow);
    {$ENDIF}

  if fParams.IsMapEditor then
  begin
    fMapEditor.History.Clear;
    fMapEditor.History.MakeCheckpoint(caAll, gResTexts[TX_MAPED_HISTORY_CHPOINT_INITIAL]);
    fMapEditorInterface.GuiMission.GuiMissionPlayers.UpdatePlayerTypes; {Will update MapEditor PlayerHuman/PLayerAI etc} //todo: refactor
    fMapEditor.AfterCreated;
  end;

  // MissionStart goes after basesave to keep it pure (repeats on Load of basesave)
  gScriptEvents.ProcMissionStart;

  // When everything is ready we can update UI
  fActiveInterface.SyncUI;
  if fParams.IsMapEditor then
  begin
    viewPos := KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2);
    // Find first hand with assets and set viewport to its center screen
    for I := 0 to gHands.Count - 1 do
      if gHands[I].HasAssets then
      begin
        gMySpectator.HandID := I;
        viewPos := KMPointF(gMySpectator.Hand.CenterScreen);
        Break;
      end;

    fActiveInterface.SyncUIView(viewPos);
  end
  else
    fActiveInterface.SyncUIView(KMPointF(gMySpectator.Hand.CenterScreen));

  if fGamePlayInterface <> nil then
    fGamePlayInterface.GuiGameResultsMP.ResetControls;

  gRenderPool.ReInit;

  fIsStarted := True;
  fIsJustStarted := True; // Mark game as just started

  gLog.AddTime('After game start', True);
end;


function TKMGame.FindHandToSpec: Integer;
var
  I: Integer;
  handIndex, humanPlayerHandIndex: TKMHandID;
begin
  // Find the 1st enabled human hand to be spectating initially.
  // If there is no enabled human hands, then find the 1st enabled hand
  handIndex := -1;
  humanPlayerHandIndex := -1;
  for I := 0 to gHands.Count - 1 do
    if gHands[I].Enabled then
    begin
      if handIndex = -1 then  // save only first index
        handIndex := I;
      if gHands[I].IsHuman then
      begin
        humanPlayerHandIndex := I;
        Break;
      end;
    end;
  if humanPlayerHandIndex <> -1 then
    handIndex := humanPlayerHandIndex
  else if handIndex = -1 then // Should never happen, cause there should be at least 1 enabled hand.
    handIndex := 0;
  Result := handIndex;
end;


// All setup data gets taken from gNetworking class
procedure TKMGame.MultiplayerRig(aNewGame: Boolean);
const
  NETPLAYERTYPE_TO_AITYPE: array[TKMNetPlayerType] of TKMAIType = (aitNone, aitNone, aitClassic, aitAdvanced);

  procedure UpdateMySpectator;
  begin
    // Update gMySpectator
    FreeAndNil(gMySpectator); // May have been created earlier
    if gNetworking.MyNetPlayer.IsSpectator then
    begin
      gMySpectator := TKMSpectator.Create(FindHandToSpec);
      gMySpectator.FOWIndex := HAND_NONE; // Show all by default while spectating
    end
    else
      gMySpectator := TKMSpectator.Create(gNetworking.MyNetPlayer.HandIndex);
  end;

  procedure UpdateSpeeds;
  var
    isPT: Boolean;
    oldSpeedPT, oldSpeedAfterPT: Single;
  begin
    oldSpeedPT := fOptions.SpeedPT;
    oldSpeedAfterPT := fOptions.SpeedAfterPT;
    // Copy game options from lobby to this game
    fOptions.Peacetime := gNetworking.NetGameOptions.Peacetime;
    fOptions.SpeedPT := gNetworking.NetGameOptions.SpeedPT;
    fOptions.SpeedAfterPT := gNetworking.NetGameOptions.SpeedAfterPT;

    isPT := IsPeacetime;

    if aNewGame  // Set game speed for new game
      // when saved game speed was changed in the lobby
      or (    isPT and not SameValue(oldSpeedPT,      fOptions.SpeedPT,      0.01))
      or (not isPT and not SameValue(oldSpeedAfterPT, fOptions.SpeedAfterPT, 0.01))
      // if there are more then one undefeated human player
      or not IsMPGameSpeedChangeAllowed then
      // Only host can change game speed
      TrySetSpeed(GetNormalSpeed, False);
  end;

  procedure UpdateAAI;
  var
    I: Integer;
  begin
    // Check for default advanced AI's
    if gNetworking.IsMap then
      for I := 0 to gNetworking.MapInfo.LocCount - 1 do
        if gNetworking.MapInfo.CanBeAdvancedAI[I]
          and not gNetworking.MapInfo.CanBeClassicAI[I]
          and not gNetworking.MapInfo.CanBeHuman[I] then
          gHands[I].AI.Setup.EnableAdvancedAI; // Just enable Advanced AI, do not override MapEd AI params
  end;

  procedure UpdatePlayersInfo;
  var
    I: Integer;
    handIndex: TKMHandID;
    playersInfo: string;
    playerNickname: AnsiString;
  begin
    playersInfo := '';
    // Assign existing NetPlayers(1..N) to map players(0..N-1)
    for I := 1 to gNetworking.NetPlayers.Count do
      if not gNetworking.NetPlayers[I].IsSpectator then
      begin
        handIndex := gNetworking.NetPlayers[I].HandIndex;
        gHands[handIndex].FlagColor := gNetworking.NetPlayers[I].FlagColor;
        // Store Team in the hand info
        // We will need to save hand team into save file,
        // to be able to restore team of this hand in the lobby
        // (and there is no network team info, f.e. after disconnection or new player joined the lobby as a replacement)
        gHands[handIndex].Team := gNetworking.NetPlayers[I].Team;

        // In saves players can be changed to AIs, which needs to be stored in the replay
        // Also one player could replace another, we have to update its player name
        if gNetworking.SelectGameKind = ngkSave then
        begin
          // No need to send this command by every player
          if gNetworking.IsHost then
          begin
            if gNetworking.NetPlayers[I].IsHuman then
              playerNickname := gNetworking.NetPlayers[I].Nickname
            else
              playerNickname := '';

            // Command execution will update player, same way as it will be updated in the replay
            fGameInputProcess.CmdPlayerChanged(handIndex, playerNickname, gNetworking.NetPlayers[I].GetPlayerType,
                                              NETPLAYERTYPE_TO_AITYPE[gNetworking.NetPlayers[I].PlayerNetType]);
          end;
        end
        else
          gHands.UpdateHandState(handIndex, gNetworking.NetPlayers[I].GetPlayerType, NETPLAYERTYPE_TO_AITYPE[gNetworking.NetPlayers[I].PlayerNetType]);

        // Update player nickname to show in the list for specs, in the stats etc
        gHands[handIndex].OwnerNickname := gNetworking.NetPlayers[I].Nickname;

        playersInfo := playersInfo + sLineBreak +
                       Format('netI: %d P: %s hand: %d',
                              [I, gHands[handIndex].GetHandOwnerName(gNetworking.NetPlayers[I].IsHuman,
                                                                     gNetworking.NetPlayers[I].IsAdvancedComputer,
                                                                     True,
                                                                     False),
                               handIndex]);
      end
      else
        playersInfo := playersInfo + sLineBreak + Format('netI: %d P: %s is spectator', [I, gNetworking.NetPlayers[I].NicknameU]);

    gLog.AddTime('NetPlayersInfo: cnt = ' + IntToStr(gNetworking.NetPlayers.Count) + playersInfo);
  end;

  procedure DisableUnusedHandsGoals;
  var
    I: Integer;
  begin
    // Find enabled human hands, where if there is no net player on that loc
    // then disable all goals with this hand for other hands
    for I := 0 to gHands.Count - 1 do
    begin
      if gHands[I].Enabled and gHands[I].IsHuman then
      begin
        if gNetworking.NetPlayers.PlayerIndexToLocal(I) = -1 then
          gHands.UpdateGoalsForHand(I, False);
      end;
    end;
  end;

begin
  UpdateMySpectator;
  UpdateSpeeds;
  UpdateAAI;
  UpdatePlayersInfo;
  DisableUnusedHandsGoals;

  // Setup alliances
  // We mirror Lobby team setup on to alliances. Savegame and coop has the setup already
  if (gNetworking.SelectGameKind = ngkMap) and not gNetworking.MapInfo.TxtInfo.BlockTeamSelection then
    UpdateMultiplayerTeams;

  // We cannot remove a player from a save (as they might be interacting with other players)

  // FOW should never be synced for saves, it should be left like it was when the save was
  // created otherwise it can cause issues in special maps using PlayerShareFog
  if gNetworking.SelectGameKind <> ngkSave then
    gHands.SyncFogOfWar; //Syncs fog of war revelation between players AFTER alliances

  // Multiplayer missions don't have goals yet, so add the defaults (except for special/coop missions)
  if (gNetworking.SelectGameKind = ngkMap)
    and gNetworking.MapInfo.TxtInfo.CanAddDefaultGoals then
    gHands.AddDefaultGoalsToAll(fParams.MissionMode);

  gNetworking.OnPlay           := GameMPPlay;
  gNetworking.OnReadyToPlay    := GameMPReadyToPlay;
  gNetworking.OnCommands       := TKMGameInputProcess_Multi(fGameInputProcess).RecieveCommands;
  gNetworking.OnTextMessage    := fGamePlayInterface.ChatMessage;
  gNetworking.OnPlayersSetup   := fGamePlayInterface.AlliesOnPlayerSetup;
  gNetworking.OnPingInfo       := fGamePlayInterface.AlliesOnPingInfo;
  gNetworking.OnDisconnect     := GameMPDisconnect; // For auto reconnecting
  gNetworking.OnJoinerDropped := OtherPlayerDisconnected;
  gNetworking.OnUpdateMinimap := nil;
  gNetworking.OnReassignedHost := nil; // Reset Lobby OnReassignedHost
  gNetworking.OnReassignedJoiner := nil; // So it is no longer assigned to a lobby event
  gNetworking.GameCreated;

  if gNetworking.Connected and (gNetworking.NetGameState = lgsLoading) then
    WaitingPlayersDisplay(True); // Waiting for players
end;


procedure TKMGame.UpdateMultiplayerTeams;
var
  I, K: Integer;
  playerI: TKMHand;
  playerK: Integer;
begin
  for I := 1 to gNetworking.NetPlayers.Count do
    if not gNetworking.NetPlayers[I].IsSpectator then
    begin
      playerI := gHands[gNetworking.NetPlayers[I].HandIndex];
      for K := 1 to gNetworking.NetPlayers.Count do
        if not gNetworking.NetPlayers[K].IsSpectator then
        begin
          playerK := gNetworking.NetPlayers[K].HandIndex;

          // Players are allies if they belong to same team (team 0 means free-for-all)
          if (I = K)
          or ((gNetworking.NetPlayers[I].Team <> 0)
          and (gNetworking.NetPlayers[I].Team = gNetworking.NetPlayers[K].Team)) then
            playerI.Alliances[playerK] := atAlly
          else
            playerI.Alliances[playerK] := atEnemy;
        end;
    end;
end;


// Everyone is ready to start playing
// Issued by gNetworking at the time depending on each Players lag individually
procedure TKMGame.GameMPPlay;
begin
  WaitingPlayersDisplay(False); //Finished waiting for players
  gNetworking.AnnounceGameInfo(MissionTime, fParams.Name);
  gLog.AddTime('Net game began');
end;


procedure TKMGame.GameMPReadyToPlay;
begin
  // Update the list of players that are ready to play
  WaitingPlayersDisplay(True);
end;


procedure TKMGame.OtherPlayerDisconnected(aDefeatedPlayerHandId: Integer);
begin
  gGame.GameInputProcess.CmdGame(gicGamePlayerDefeat, aDefeatedPlayerHandId);
end;


procedure TKMGame.RecalcMapCRC;
var
  mapInfo: TKMMapInfo;
  mapKind: TKMMapKind;
  fileDirName: string;
begin
  fileDirName := GetFileDirName(ExtractFileDir(fParams.MissionFullFilePath));
  if DetermineMapKind(fileDirName, mapKind) then
  begin
    mapInfo := TKMMapInfo.Create(GetFileDirName(fParams.MissionFullFilePath), True, mapKind); // Force recreate map CRC
    try
      fParams.MapFullCRC := mapInfo.CRC;
      fParams.MapSimpleCRC := mapInfo.MapAndDatCRC;
    finally
      mapInfo.Free;
    end;
  end;
end;


// Get active hand ids as set (enabled hands for SP/replay or connected not spectators
function TKMGame.GetActiveHandIDs: TKMByteSet;
var
  I: Integer;
  netPlayer: TKMNetPlayerInfo;
begin
  Result := [];
  if fParams.IsMultiPlayerOrSpec then
  begin
    for I := 1 to gNetworking.NetPlayers.Count do
    begin
      netPlayer := gNetworking.NetPlayers[I];
      if not netPlayer.IsHuman
      or netPlayer.IsSpectator
      or not netPlayer.Connected
      or (netPlayer.HandIndex = -1)
      or not gHands[netPlayer.HandIndex].Enabled then
        Continue;

      Include(Result, netPlayer.HandIndex);
    end;
  end
  else
    for I := 0 to gHands.Count - 1 do
      if gHands[I].Enabled then
        Include(Result, I);
end;


procedure TKMGame.GameMPDisconnect(const aData: UnicodeString);
begin
  if gNetworking.NetGameState in [lgsGame, lgsReconnecting] then
  begin
    gLog.LogNetConnection('GameMPDisconnect: ' + aData);
    gNetworking.OnJoinFail := GameMPDisconnect; // If the connection fails (e.g. timeout) then try again
    gNetworking.OnJoinAssignedHost := nil;
    gNetworking.OnJoinSucc := nil;
    gNetworking.AttemptReconnection;
  end
  else
  begin
    gNetworking.Disconnect;
    gGameApp.StopGame(grDisconnect, gResTexts[TX_GAME_ERROR_NETWORK] + ' ' + aData)
  end;
end;


// Occasional replay inconsistencies are a known bug, we don't need reports of it
procedure TKMGame.ReplayInconsistency(aCommand: TKMStoredGIPCommand; aMyRand: Cardinal);
const
  TRY_KAM_RANDOM_CNT = 10;
  {$IFDEF RNG_SPY}
var
  I: Integer;
  tempSeedI, tempSeedF: Integer;
  valI: Integer;
  valF: Double;
  {$ENDIF}
begin
  gLog.AddTime('Replay failed a consistency check at tick ' + IntToStr(fParams.Tick));
  gLog.AddTime(Format('MyRand = %d, seed: %d; but command: %s', [aMyRand, GetKaMSeed, fGameInputProcess.StoredGIPCommandToString(aCommand)]));

  {$IFDEF RNG_SPY}
  if gLog.CanLogRandomChecks() then
  begin
    gLog.LogRandomChecks('Next KaMRandom seed values are: ');
    tempSeedI := GetKaMSeed;
    tempSeedF := GetKaMSeed;
    for I := 0 to TRY_KAM_RANDOM_CNT - 1 do
    begin
      valI := KaMRandomWSeed(tempSeedI, MaxInt);
      valF := KaMRandomWSeed(tempSeedF);
      gLog.LogRandomChecks(Format('%d: seed: %d; KaMRandomI: %30d', [I+1, tempSeedI, valI]));
      gLog.LogRandomChecks(Format('%d: seed: %d; KaMRandomF: %30s', [I+1, tempSeedF, FormatFloat('0.##############################', valF)]));
      if valI = aMyRand then
        gLog.LogRandomChecks('Find match with MyRand !!!');
    end;
  end;
  {$ENDIF}

  if not fIgnoreConsistencyCheckErrors then
  begin
    // Stop game from executing while the user views the message
    fIsPaused := True;
    case MessageDlg(gResTexts[TX_REPLAY_FAILED], mtWarning, [mbYes, mbYesToAll, mbNo], 0) of
      mrYes:      fIsPaused := False;
      mrYesToAll: begin
                    fIgnoreConsistencyCheckErrors := True;  // Ignore these errors in future while watching this replay
                    fIsPaused := False;
                  end
      else        gGameApp.StopGame(grError);
    end;
  end;
end;


// Put the game on Hold for Victory screen
procedure TKMGame.Hold(aDoHold: Boolean; Msg: TKMGameResultMsg);
begin
  fDoHold := False;
  fGamePlayInterface.ReleaseDirectionSelector; // In case of victory/defeat while moving troops
  gSystem.Cursor := kmcDefault;

  fGamePlayInterface.Viewport.ReleaseScrollKeys;
  GameResult := Msg;

  if aDoHold then
  begin
    fIsPaused := True;
    fGamePlayInterface.ShowPlayMore(True, Msg);
  end else
    fIsPaused := False;
end;


procedure TKMGame.RequestHold(Msg: TKMGameResultMsg);
begin
  fDoHold := True;
  fDoHoldState := Msg;
end;


procedure TKMGame.PlayerVictory(aHandIndex: TKMHandID);
begin
  if fParams.IsMultiPlayerOrSpec then
  begin
    if gNetworking.NetPlayers.PlayerIndexToLocal(aHandIndex) = -1 then
      Exit;

    gNetworking.PostLocalMessage(
      Format(gResTexts[TX_MULTIPLAYER_PLAYER_WON], [gHands[aHandIndex].GetOwnerNameColoredU]),
      csSystem);

    if Assigned(gNetworking.OnPlayersSetup) then
      gNetworking.OnPlayersSetup; // Update players panel
  end;

  if fParams.Mode = gmMultiSpectate then
    Exit;

  if (aHandIndex = gMySpectator.HandID)
  and not gGameSettings.Video.Enabled then // Don't play victory sound if videos are on
    gSoundPlayer.Play(sfxnVictory, 1, True); // Fade music

  if fParams.IsMultiplayerGame then
  begin
    if aHandIndex = gMySpectator.HandID then
    begin
      GameResult := grWin;
      fGamePlayInterface.ShowMPPlayMore(grWin);
    end;
  end
  else
    RequestHold(grWin);
end;


function TKMGame.PlayerLoc: Byte;
begin
  Result := gMySpectator.HandID;
end;


// Wrap for GameApp to access player color (needed for restart mission)
function TKMGame.PlayerColor: Cardinal;
begin
  Result := gMySpectator.Hand.FlagColor;
end;


procedure TKMGame.PlayerDefeat(aPlayerIndex: TKMHandID; aShowDefeatMessage: Boolean = True);

  procedure PlayDefeatSound;
  begin
    if not gGameSettings.Video.Enabled then // Don't play defeat sound if videos are on
      gSoundPlayer.Play(sfxnDefeat, 1, True); // Fade music
  end;

begin
  case fParams.Mode of
    gmSingle, gmCampaign:
              if aPlayerIndex = gMySpectator.HandID then
              begin
                PlayDefeatSound;
                RequestHold(grDefeat);
              end;
    gmMulti:  begin
                if aShowDefeatMessage then
                  gNetworking.PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_PLAYER_DEFEATED],
                                                      [gHands[aPlayerIndex].GetOwnerNameColoredU]), csSystem);

                if aPlayerIndex = gMySpectator.HandID then
                begin
                  PlayDefeatSound;
                  GameResult := grDefeat;
                  fGamePlayInterface.ShowMPPlayMore(grDefeat);
                end;

                if Assigned(gNetworking.OnPlayersSetup) then
                  gNetworking.OnPlayersSetup; // Update players panel
              end;
    gmMultiSpectate:
              begin
                if aShowDefeatMessage then
                  gNetworking.PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_PLAYER_DEFEATED],
                                                      [gHands[aPlayerIndex].GetOwnerNameColoredU]), csSystem);

                if Assigned(gNetworking.OnPlayersSetup) then
                  gNetworking.OnPlayersSetup; // Update players panel
              end;
    // We have not thought of anything to display on players defeat in Replay
  end;
end;


// Get list of players we are waiting for. We do it here because gNetworking does not knows about GIP
function TKMGame.GetWaitingPlayersList: TKMByteArray;
var
  errorMsg: UnicodeString;
begin
  case gNetworking.NetGameState of
    lgsGame, lgsReconnecting:
        // GIP is waiting for next tick
        Result := TKMGameInputProcess_Multi(fGameInputProcess).GetWaitingPlayers(fParams.Tick + 1);
    lgsLoading:
        // We are waiting during inital loading
        Result := gNetworking.NetPlayers.GetNotReadyToPlayPlayers;
    else  begin
            SetLength(Result, 0);
            errorMsg := 'GetWaitingPlayersList from wrong state: '
                       + GetEnumName(TypeInfo(TKMNetGameState), Integer(gNetworking.NetGameState));
            gLog.AddTime(errorMsg);
            // raise Exception.Create(ErrorMsg); // This error sometimes occur when host quits, but that's not critical, so we can just log it
          end;
  end;
end;


procedure TKMGame.WaitingPlayersDisplay(aWaiting: Boolean);
begin
  fWaitingForNetwork := aWaiting;
  fGamePlayInterface.ShowNetworkLag(aWaiting, GetWaitingPlayersList, gNetworking.IsHost);
end;


procedure TKMGame.WaitingPlayersDrop;
begin
  gNetworking.DropPlayers(GetWaitingPlayersList);
end;


// Start MapEditor (empty map)
procedure TKMGame.MapEdStartEmptyMap(aSizeX, aSizeY: Integer);
var
  I: Integer;
begin
  fParams.Name := gResTexts[TX_MAPED_NEW_MISSION];

  fSetMissionFileSP('');
  fLoadFromFileRel := '';
  fLastSaveFileRel := '';

  fMapEditor := TKMMapEditor.Create(True, fTerrainPainter, fMapEditorInterface.HistoryUndoRedo, fMapEditorInterface.HistoryAddCheckpoint);

  fMapEditor.OnEyedropper := fMapEditorInterface.GuiTerrain.GuiTiles.TilesTableSetTileTexId;
  fMapEditor.MissionDefSavePath := fParams.Name + '.dat';
  gTerrain.MakeNewMap(aSizeX, aSizeY, True);
  fTerrainPainter.InitEmpty;
  fMapEditor.History.MakeCheckpoint(caAll, gResTexts[TX_MAPED_HISTORY_CHPOINT_INITIAL]);

  gHands.AddPlayers(MAX_HANDS); // Create MAX players
  gHands[0].HandType := hndHuman; // Make Player1 human by default
  for I := 0 to gHands.Count - 1 do
  begin
    gHands[I].FogOfWar.RevealEverything;
    gHands[I].CenterScreen := KMPoint(aSizeX div 2, aSizeY div 2);
  end;

  gMySpectator := TKMSpectator.Create(0);
  gMySpectator.FOWIndex := HAND_NONE;

  gHands.AfterMissionInit;

  if fParams.IsSingleplayerGame then
    fGameInputProcess := TKMGameInputProcess_Single.Create(gipRecording);

  // When everything is ready we can update UI
  if (fActiveInterface <> nil) then // fActiveInterface can be nil if map is generated by Random map generator
  begin
    fActiveInterface.SyncUI;
    fActiveInterface.SyncUIView(KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2));
  end;

  gRenderPool.ReInit;

  fIsStarted := True;

  gLog.AddTime('Gameplay initialized', True);
end;


procedure TKMGame.AutoSaveAfterPT(aTimestamp: TDateTime);
begin
  Save(AUTOSAVE_AFTER_PT_END_SAVE_NAME, aTimestamp);
end;


procedure DoAutoSaveRename(aIsMultiPlayerOrSpec: Boolean);
var
  I: Integer;
begin
  // Delete last autosave
  KMDeleteFolder(TKMGame.SavePath(AUTOSAVE_SAVE_NAME + Int2Fix(gGameSettings.AutosaveCount, 2), aIsMultiPlayerOrSpec));

  // Shift remaining autosaves by 1 position back
  for I := gGameSettings.AutosaveCount downto 2 do // 03 to 01
    KMMoveFolder(TKMGame.SavePath(AUTOSAVE_SAVE_NAME + Int2Fix(I - 1, 2), aIsMultiPlayerOrSpec),
                 TKMGame.SavePath(AUTOSAVE_SAVE_NAME + Int2Fix(I, 2), aIsMultiPlayerOrSpec));

  // Rename temp to be first in list
  KMMoveFolder(TKMGame.SavePath(AUTOSAVE_SAVE_NAME, aIsMultiPlayerOrSpec),
               TKMGame.SavePath(AUTOSAVE_SAVE_NAME + '01', aIsMultiPlayerOrSpec));
end;


procedure TKMGame.AutoSave(aTimestamp: TDateTime);
{$IFDEF WDC}
var
  localIsMultiPlayerOrSpec: Boolean;
{$ENDIF}
begin
  Save(AUTOSAVE_SAVE_NAME, aTimestamp, fAutoSaveWorkerThreadHolder.Worker); //Save to temp file

  // If possible perform file deletion/renaming in a different thread so we don't delay game
  {$IFDEF WDC}
    // Avoid accessing Self from async thread, copy required states to local variables
    localIsMultiPlayerOrSpec := fParams.IsMultiPlayerOrSpec;
    fAutoSaveWorkerThreadHolder.Worker.QueueWork(procedure
    begin
      DoAutoSaveRename(localIsMultiPlayerOrSpec);
    end, 'AutoSaveRename');
  {$ELSE}
    DoAutoSaveRename(fParams.IsMultiPlayerOrSpec);
  {$ENDIF}
end;


procedure TKMGame.SaveMapEditor(const aPathName: UnicodeString);
begin
  SaveMapEditor(aPathName, KMRECT_ZERO);
end;


// aPathName - full path to DAT file
procedure TKMGame.SaveMapEditor(const aPathName: UnicodeString; const aInsetRect: TKMRect);
var
  I: Integer;
  missionParser: TKMMissionParserStandard;
  mapInfo: TKMMapInfo;
  mapKind: TKMMapKind;
  mapPath: string;
  oldSimpleCRC, oldFullCRC: Cardinal;
begin
  if aPathName = '' then Exit;

  if Assigned(fMapEdMapSaveStarted) then
    fMapEdMapSaveStarted;

  // Store old values, cause they will be updated after save
  oldSimpleCRC := fParams.MapSimpleCRC;
  oldFullCRC := fParams.MapFullCRC;

  // Prepare and save

  // Remove assets out of map bounds first (units / houses)
  // Those 'fake' assets, that will not be loaded could affectsaved assets,
  // F.e. if we have 'fake' first storehouse, then commands will add second storehouse as a second one
  // and its wares will be corrupted
  gHands.RemoveAssetsOutOfBounds(aInsetRect);
  gHands.RemoveEmptyPlayers;

  mapPath := ExtractFilePath(aPathName);

  if fMapEditor.IsNewMap then
    KMDeleteFolderContent(mapPath); // Delete any possible old map with the same name, if there was any

  ForceDirectories(mapPath);
  gLog.AddTime('Saving from map editor: ' + aPathName);

  fMapEditor.MissionDefSavePath := aPathName;
  fMapEditor.SaveAttachements(aPathName);

  // Create empty script file, in there is no any. It will not harm anyone
  KMCreateEmptyFile(ChangeFileExt(aPathName, EXT_FILE_SCRIPT_DOT));

  fMapTxtInfo.SaveTXTInfo(ChangeFileExt(aPathName, '.txt'));
  gTerrain.SaveToFile(ChangeFileExt(aPathName, '.map'), aInsetRect);
  fTerrainPainter.SaveToFile(ChangeFileExt(aPathName, '.map'), aInsetRect);
  missionParser := TKMMissionParserStandard.Create(mpmEditor);
  missionParser.SaveDATFile(ChangeFileExt(aPathName, '.dat'), aInsetRect.Left, aInsetRect.Top);
  FreeAndNil(missionParser);

  // Update GameSettings for saved maps positions in list on MapEd menu
  if DetermineMapKind(GetFileDirName(ExtractFileDir(aPathName)), mapKind) then
  begin
    // Update GameSettings for saved maps positions in list on MapEd menu
    // Force recreate map CRC
    // Run silently... (no need to spam to the log if there are preprocessing errors)
    mapInfo := TKMMapInfo.Create(GetFileDirName(aPathName), True, mapKind, True);
    try
      case mapInfo.Kind of
        mkSP:       begin
                      gGameSettings.MenuMapEdSPMapCRC := mapInfo.MapAndDatCRC;
                      gGameSettings.MenuMapEdMapType := 0;
                      // Update saved SP game list saved selected map position CRC if we resave this map
                      if oldSimpleCRC = gGameSettings.MenuSPScenarioMapCRC then
                        gGameSettings.MenuSPScenarioMapCRC := mapInfo.MapAndDatCRC;
                      if oldSimpleCRC = gGameSettings.MenuSPMissionMapCRC then
                        gGameSettings.MenuSPMissionMapCRC := mapInfo.MapAndDatCRC;
                      if oldSimpleCRC = gGameSettings.MenuSPTacticMapCRC then
                        gGameSettings.MenuSPTacticMapCRC := mapInfo.MapAndDatCRC;
                      if oldSimpleCRC = gGameSettings.MenuSPSpecialMapCRC then
                        gGameSettings.MenuSPSpecialMapCRC := mapInfo.MapAndDatCRC;
                    end;
        mkMP:       begin
                      gGameSettings.MenuMapEdMPMapCRC := mapInfo.MapAndDatCRC;
                      gGameSettings.MenuMapEdMPMapName := mapInfo.Name;
                      gGameSettings.MenuMapEdMapType := 1;
                    end;
        mkDL:       begin
                      gGameSettings.MenuMapEdDLMapCRC := mapInfo.MapAndDatCRC;
                      gGameSettings.MenuMapEdMapType := 2;
                    end;
      end;
      // Update favorite map CRC if we resave favourite map with the same name
      if fParams.Name = mapInfo.Name then
      begin
        gGameSettings.FavouriteMaps.Replace(oldSimpleCRC, mapInfo.MapAndDatCRC);
        gServerSettings.ServerMapsRoster.Replace(oldFullCRC, mapInfo.CRC);
		gGameAppSettings.SaveSettings;
      end;

      // Update CRC's after map save
      fParams.MapSimpleCRC := mapInfo.MapAndDatCRC;
      fParams.MapFullCRC := mapInfo.CRC;
    finally
      mapInfo.Free;
    end;
  end;

  fParams.Name := TruncateExt(ExtractFileName(aPathName));
  fSetMissionFileSP(ExtractRelativePath(ExeDir, aPathName));

  // Append empty players in place of removed ones
  gHands.AddPlayers(MAX_HANDS - gHands.Count);
  for I := 0 to gHands.Count - 1 do
    gHands[I].FogOfWar.RevealEverything;

  if Assigned(fMapEdMapSaveEnded) then
    fMapEdMapSaveEnded;
end;


procedure TKMGame.Render(aRender: TKMRender);
var
  tickLag: Single;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameFullC);
  {$ENDIF}
  try
    // How far in the past should we render? (0.0=Current tick, 1.0=Previous tick)
    if gGameSettings.GFX.InterpolatedRender then
    begin
      tickLag := TimeSince(fLastUpdateState) / gMain.GameTickInterval;
      tickLag := 1.0 - tickLag;
      tickLag := EnsureRange(tickLag, 0.0, 1.0);
    end
    else
      tickLag := 0.0;

    fSetGameTickFracEvent(1.0 - tickLag);

    if DoRenderGame then
      gRenderPool.Render(tickLag);

    aRender.SetRenderMode(rm2D);

    // Do not render UI when do save map to FBO
    if not SAVE_MAP_TO_FBO_RENDER then
      fActiveInterface.Paint;

    fGameInputProcess.Paint;

  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psFrameFullC);
    {$ENDIF}
  end;
end;


// Used to restart game / replay while debugging
procedure TKMGame.RestartReplay;
begin
  gGameApp.NewReplay(ChangeFileExt(ExeDir + fLastSaveFileRel, EXT_SAVE_BASE_DOT));
end;


function TKMGame.GetMapEditor: TKMMapEditor;
begin
  if Self = nil then Exit(nil);

  Result := fMapEditor;
end;


function TKMGame.GetScriptSoundFilePath(const aSound: AnsiString; aAudioFormat: TKMAudioFormat): UnicodeString;
const
  AUDIO_EXT: array[TKMAudioFormat] of AnsiString = (WAV_FILE_EXT, OGG_FILE_EXT);
var
  camp: TKMCampaign;
begin
  // check for MissionPath\MissionName.SoundName.locale.ext
  Result := GetLocalizedFilePath(ExeDir + ChangeFileExt(fParams.MissionFileRel, '.' + string(aSound)),
                                 gResLocales.UserLocale, gResLocales.FallbackLocale, AUDIO_EXT[aAudioFormat]);

  // Try to load Campaign specific audio file in the campaign Sounds folder (not mission specific)
  if fParams.IsCampaign and (gGameApp.Campaigns.ActiveCampaign <> nil) and not FileExists(Result) then
  begin
    camp := gGameApp.Campaigns.ActiveCampaign;
    // check for Campaigns\CampaignName\Sounds\CMP.SoundName.locale.ext
    Result := GetLocalizedFilePath(camp.Path + CAMPAIGN_SOUNDS_FOLDER_NAME + PathDelim + camp.Spec.IdStr + '.' + UnicodeString(aSound),
                                   gResLocales.UserLocale, gResLocales.FallbackLocale, AUDIO_EXT[aAudioFormat]);
  end;
end;


// TDateTime stores days/months/years as 1 and hours/minutes/seconds as fractions of a 1
// Treat 10 ticks as 1 sec irregardless of user-set pace
function TKMGame.MissionTime: TDateTime;
begin
  // Convert cardinal into TDateTime, where 1hour = 1/24 and so on..
  Result := fParams.Tick / 24 / 60 / 60 / 10;
end;


function TKMGame.GetPeacetimeRemaining: TDateTime;
begin
  Result := Max(0, Int64(fOptions.Peacetime * 600) - fParams.Tick) / 24 / 60 / 60 / 10;
end;


// Tests whether time has past
function TKMGame.CheckTime(aTimeTicks: Cardinal): Boolean;
begin
  Result := (fParams.Tick >= aTimeTicks);
end;


function TKMGame.IsSpeedUpAllowed: Boolean;
begin
  if Self = nil then Exit(False);
  
  Result := not fParams.IsMultiPlayerOrSpec or IsMPGameSpeedChangeAllowed;
end;


// Can this player change game speed?
function TKMGame.CanMPPlayerChangeSpeed: Boolean;
begin
  Assert(fParams.IsMultiPlayerOrSpec);
  Result := False;
  if (Self = nil) or (gHands.Count = 0) then Exit;

  if (gNetworking = nil) or not gNetworking.IsHost then Exit; // Only host can change game speed in MP

  Result := IsMPGameSpeedChangeAllowed;
end;


// Can game speed be changed (by someone in the game)?
// Game speed could be changed if there are only AI players who can continue to play
// Defeated / or not connected human players do not considered as well
function TKMGame.IsMPGameSpeedChangeAllowed: Boolean;
var
  I, netI: Integer;
begin
  Result := False;
  if Self = nil then Exit;

  if not fParams.IsMultiPlayerOrSpec
    or (gHands = nil) // Game is not started yet
    or (gHands.Count = 0) then Exit; // Game is not loaded yet

  // Allow to speedup game if there is only 1 MP human connected to the game (player or spectator)
  if gNetworking.NetPlayers.GetConnectedCount = 1 then
    Exit(True);

  for I := 0 to gHands.Count - 1 do
  begin
    if    gHands[I].Enabled
      and gHands[I].IsHuman
      and not gHands[I].AI.HasLost then
    begin
      netI := gNetworking.GetNetPlayerIndex(I);
      if (netI <> -1) and gNetworking.NetPlayers[netI].Connected then
        Exit;
    end;
  end;

  Result := True;
end;


function TKMGame.IsWareDistributionStoredBetweenGames: Boolean;
begin
  Result := fParams.IsNormalMission // No need to store ware distribution for Tactic mission
            and gGameSettings.SaveWareDistribution // If "save ware distribution" is ON
            and fParams.IsNormalGame; // Not for Replay / MapEd
end;


procedure TKMGame.ShowMessage(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aEntityUID: Integer; aHandIndex: TKMHandID);
begin
  // Once you have lost no messages can be received
  if gHands[aHandIndex].AI.HasLost then Exit;

  // Store it in hand so it can be included in MP save file
  gHands[aHandIndex].MessageLog.Add(aKind, aTextID, aLoc, aEntityUID);

  // Don't play sound in replays or spectator
  if (aHandIndex = gMySpectator.HandID) and fParams.IsNormalGame then
    gSoundPlayer.Play(sfxMessageNotice, 2);
end;


procedure TKMGame.ShowMessageLocal(aKind: TKMMessageKind; const aText: UnicodeString; const aLoc: TKMPoint);
begin
  fGamePlayInterface.MessageIssue(aKind, aText, aLoc);
end;


procedure TKMGame.ShowScriptError(const aMsg: UnicodeString);
begin
  fGamePlayInterface.MessageIssue(mkQuill, aMsg);
end;


procedure TKMGame.OverlayUpdate;
begin
  fGamePlayInterface.SetScriptedOverlay(gMySpectator.Hand.OverlayText, gMySpectator.Hand.OverlayTextSettings);
  fGamePlayInterface.UpdateOverlayControls;
end;


// Clear + Append
procedure TKMGame.OverlaySet(aHand: TKMHandID; const aMarkup: AnsiString; aParams: array of const);
var
  I: Integer;
begin
  for I := 0 to gHands.Count - 1 do
  if (I = aHand) or (aHand = HAND_NONE) then
  begin
    gHands[I].OverlayMarkup := '';
    gHands[I].OverlayParams.Clear;
  end;

  OverlayAppend(aHand, aMarkup, aParams);
end;


procedure TKMGame.OverlayAppend(aHand: TKMHandID; const aMarkup: AnsiString; aParams: array of const);
var
  I: Integer;
begin
  for I := 0 to gHands.Count - 1 do
  if (I = aHand) or (aHand = HAND_NONE) then
  begin
    gHands[I].OverlayMarkup := gHands[I].OverlayMarkup + aMarkup;
    gHands[I].OverlayParams.AddVarRecs(aParams);

    // Update text to show
    gHands[I].OverlayText := TextMission.ParseTextMarkup(UnicodeString(gHands[I].OverlayMarkup),
                                                         gHands[I].OverlayParams.ToVarRecArray);
  end;

  OverlayUpdate;
end;


procedure TKMGame.OverlaySetWordWrap(aHand: TKMHandID; aWordWrap: Boolean);
var
  I: Integer;
begin
  if aHand = HAND_NONE then
    for I := 0 to gHands.Count - 1 do
      gHands[I].SetOverlayTextWordWrap(aWordWrap)
  else
    gHands[aHand].SetOverlayTextWordWrap(aWordWrap);
end;


procedure TKMGame.OverlaySetFont(aHand: TKMHandID; aFont: TKMFont);
var
  I: Integer;
begin
  if aHand = HAND_NONE then
    for I := 0 to gHands.Count - 1 do
      gHands[I].SetOverlayTextFont(aFont)
  else
    gHands[aHand].SetOverlayTextFont(aFont);
end;


function TKMGame.IsPeaceTime: Boolean;
begin
  if (Self = nil) or (fOptions = nil) then Exit(False);

  Result := not CheckTime(fOptions.Peacetime * 600);
end;


function TKMGame.CheckIfPieceTimeJustEnded: Boolean;
begin
  if (Self = nil) or (fOptions = nil) then Exit(False);

  Result := False;
  if fOptions.Peacetime = 0 then Exit;

  if fParams.IsMultiplayer and (fParams.Tick = fOptions.Peacetime * 600) then
  begin
    Result := True;
    gSoundPlayer.Play(sfxnPeacetime, 1, True); // Fades music
    gScriptEvents.ProcPeacetimeEnd;
  end;
end;


function TKMGame.GetNormalSpeed: Single;
begin
  if fParams.IsMultiPlayerOrSpec then
  begin
    if IsPeaceTime then
      Result := fOptions.SpeedPT
    else
      Result := fOptions.SpeedAfterPT;
  end
  else
    Result := GAME_SPEED_NORMAL;
end;


// Speed to which we are going to toggle to when press F5
function TKMGame.GetToggledNormalSpeed: Single;
begin
  if fParams.IsMultiPlayerOrSpec then
  begin
    if IsPeaceTime then
      Result := fOptions.SpeedPT
    else
      Result := fOptions.SpeedAfterPT;
  end
  else
    Result := fSpeedGIP;
end;


procedure TKMGame.SetSpeedGIP(aSpeed: Single; aUpdateActual: Boolean = False; aUpdateOptionsSpeed: Boolean = False);
var
  speedChanged: Boolean;
begin
  speedChanged := fSpeedGIP <> aSpeed;

  // Update gameOptions SpeedPT / SpeedAfterPT for MP game
  // If speed was changed from script, then we want to lobby speed to be affected as well
  // But if speed was changed via F5-F8, then we want to save Lobby speed values,
  // since we want to set it back via pressing F5-F8 twice
  if aUpdateOptionsSpeed and fParams.IsMultiPlayerOrSpec then
  begin
    if IsPeacetime then
      fOptions.SpeedPT := aSpeed
    else
      fOptions.SpeedAfterPT := aSpeed;
  end;

  fSpeedGIP := aSpeed;
  if aUpdateActual then
    SetSpeedActual(aSpeed) // will also UpdateClockUI
  else
    fGamePlayInterface.UpdateClockUI;

  if speedChanged then
    gScriptEvents.ProcGameSpeedChanged(aSpeed); // Script events should trigger on GIP game speed, not on the actual speed
end;


procedure TKMGame.SetSpeedActual(aSpeed: Single);
var
  oldGameSpeed: Single;
begin
  // MapEd always runs at x1
  if fParams.IsMapEditor then
  begin
    SetSpeedActualValue(GAME_SPEED_NORMAL);
    Exit;
  end;

  oldGameSpeed := fSpeedActual;

  UpdateTickCounters;

  SetSpeedActualValue(aSpeed);

  // Need to adjust the delay immediately in MP
  if fParams.IsMultiPlayerOrSpec and (fGameInputProcess <> nil) then
    TKMGameInputProcess_Multi(fGameInputProcess).AdjustDelay(fSpeedActual);

  if Assigned(gGameApp.OnGameSpeedActualChange) then
    gGameApp.OnGameSpeedActualChange(fSpeedActual);

  GameSpeedActualChanged(oldGameSpeed, fSpeedActual);
end;


procedure TKMGame.SetSpeedActualValue(aSpeed: Single);
begin
  fSpeedActual := aSpeed;

  // When speed is above x5 we start to skip rendering frames
  // by doing several updates per timer tick
  if fSpeedActual > 5 then
  begin
    fSpeedMultiplier := Round(fSpeedActual / 4);
    gMain.SetGameTickInterval(Round(gGameSettings.SpeedPace / fSpeedActual * fSpeedMultiplier));
  end
  else
  begin
    fSpeedMultiplier := 1;
    gMain.SetGameTickInterval(Round(gGameSettings.SpeedPace / fSpeedActual));
  end;

  fGamePlayInterface.UpdateClockUI;
end;


procedure TKMGame.SetSpeed(aSpeed: Single);
begin
  Assert(aSpeed > 0);

  // MapEd always runs at x1
  if fParams.IsMapEditor then
  begin
    SetSpeedActualValue(GAME_SPEED_NORMAL);
    Exit;
  end;

  if fParams.IsReplay then
    SetSpeedActual(aSpeed)
  else if fSpeedChangeAllowed then
    fGameInputProcess.CmdGame(gicGameSpeed, aSpeed);
end;


// Set speed in SP game or if we are the host (no need to spam with speed gicCommands for other players)
procedure TKMGame.TrySetSpeed(aSpeed: Single; aToggle: Boolean);
begin
  if not fParams.IsMultiPlayerOrSpec or gNetworking.IsHost then
    SetSpeed(aSpeed, aToggle);
end;


procedure TKMGame.SetSpeed(aSpeed: Single; aToggle: Boolean);
begin
  SetSpeed(aSpeed, aToggle, GetNormalSpeed);
end;


procedure TKMGame.SetSpeed(aSpeed: Single; aToggle: Boolean; aToggleTo: Single);
var
  newGameSpeed: Single;
begin
  // There is no reason to 'toggle' to the same value. Toggle to NORMAL_SPEED (x1) instead
  if SameValue(aSpeed, aToggleTo, 0.001) then
    aToggleTo := GAME_SPEED_NORMAL;

  // Make the speed toggle between normal speed and desired value
  if SameValue(aSpeed, fSpeedActual, 0.001) and aToggle then
    newGameSpeed := aToggleTo
  else
    newGameSpeed := aSpeed;

  SetSpeed(newGameSpeed);
end;


procedure TKMGame.GameSpeedActualChanged(aFromSpeed, aToSpeed: Single);
begin
  fActiveInterface.GameSpeedChanged(aFromSpeed, aToSpeed);
end;


// Return Controlled hand index in game or -1, if there is no one (spectator/replay/maped)
function TKMGame.GetControlledHandIndex: TKMHandID;
begin
  Result := -1;
  if fParams.IsNormalGame then
    Result := gMySpectator.HandID;
end;


function TKMGame.GetCurrectTickSaveCRC: Cardinal;
var
  stream: TKMemoryStream;
begin
  stream := TKMemoryStreamBinary.Create;
  try
    SaveGameToStream(0, stream);
    Result := Adler32CRC(stream);
  finally
    stream.Free;
  end;
end;


function TKMGame.GetGamePlayInterface: TKMGamePlayInterface;
begin
  if Self = nil then Exit(nil);

  Result := fGamePlayInterface;
end;


function TKMGame.GetHandsCount: Integer;
begin
  Result := gHands.Count;
end;


procedure TKMGame.SetIsPaused(aValue: Boolean);
begin
  fIsPaused := aValue;
  UpdateTickCounters;
end;


function TKMGame.GetIsPlayerWaiting: Boolean;
begin
  Result := fIsPaused or fWaitingForNetwork;
end;


// In replay mode we can step the game by exactly one frame and then pause again
procedure TKMGame.StepOneFrame;
begin
  Assert(fParams.IsReplay, 'We can work step-by-step only in Replay');
  SetSpeed(1, False); // Make sure we step only one tick. Do not allow multiple updates in UpdateState loop
  fAdvanceFrame := True;
end;


procedure TKMGame.SaveGameToStream(aTimestamp: TDateTime; aSaveStream: TKMemoryStream);
begin
  aSaveStream.Write(False); // False - as not compressed save
  SaveGameToStream(aTimestamp, nil, aSaveStream);
end;


// Saves the game in TKMemoryStream
procedure TKMGame.SaveGameToStream(aTimestamp: TDateTime; aHeaderStream, aBodyStream: TKMemoryStream);
const
  //@Rey: Please add comment explaining how the 20mb value was picked
  EXTRA_ALLOC_FOR_SAVE = 20 * 1024 * 1024; // Empirical value
var
  gameInfo: TKMGameInfo;
  I, netIndex: Integer;
  gameRes: TKMGameResultMsg;
  sizeToAllocate: Cardinal;
  isMulti: Boolean;
begin
  gameInfo := TKMGameInfo.Create(fMapTxtInfo);

  // Pre-allocate memory for save stream, could save up to 25% of save time
  // Even if we make a bad guess, Stream will reallocate more by itself, if needed
  if fLastSaveStreamSize = 0 then
    sizeToAllocate := gTerrain.MapX * gTerrain.MapY * SizeOf(TKMTerrainTile) + EXTRA_ALLOC_FOR_SAVE // Allocate a lot first time
  else
    sizeToAllocate := Round(fLastSaveStreamSize * 1.25); // Assume save didn't grow more then 1.25 times

  aBodyStream.SetSize(sizeToAllocate);

  if aHeaderStream = nil then
    aHeaderStream := aBodyStream; //Write into the body stream, since we don't use compression
  // ----------------------------------------------------------------
  // Save to HeaderStream at first
  // ----------------------------------------------------------------
  try
    gameInfo.Title := fParams.Name;
    gameInfo.MapFullCRC := fParams.MapFullCRC;
    gameInfo.MapSimpleCRC := fParams.MapSimpleCRC;
    gameInfo.TickCount := fParams.Tick;
    gameInfo.SaveTimestamp := aTimestamp;
    gameInfo.MissionMode := fParams.MissionMode;
    gameInfo.MissionDifficulty := fParams.MissionDifficulty;
    gameInfo.MapSizeX := gTerrain.MapX;
    gameInfo.MapSizeY := gTerrain.MapY;
    gameInfo.PlayerCount := gHands.Count;
    for I := 0 to gHands.Count - 1 do
    begin
      if gNetworking = nil then
      begin
        gameInfo.Enabled[I] := False;
        gameInfo.CanBeHuman[I] := False;
        gameInfo.CanBeClassicAI[I] := False;
        gameInfo.CanBeAdvancedAI[I] := False;
        gameInfo.OwnerNickname[I] := '';
        gameInfo.HandTypes[I] := hndHuman;
        gameInfo.Color[I] := 0;
        gameInfo.Team[I] := 0;
      end
      else
      begin
        netIndex := gNetworking.NetPlayers.PlayerIndexToLocal(I);
        if netIndex <> -1 then
        begin
          gameInfo.Enabled[I] := True;
          gameInfo.CanBeHuman[I] := gNetworking.NetPlayers[netIndex].IsHuman;
          gameInfo.CanBeClassicAI[I] := gNetworking.NetPlayers[netIndex].IsClassicComputer;
          gameInfo.CanBeAdvancedAI[I] := gNetworking.NetPlayers[netIndex].IsAdvancedComputer;
          gameInfo.OwnerNickname[I] := gNetworking.NetPlayers[netIndex].Nickname;
          gameInfo.HandTypes[I] := gNetworking.NetPlayers[netIndex].GetPlayerType;
          gameInfo.Color[I] := gNetworking.NetPlayers[netIndex].FlagColor;
          gameInfo.Team[I] := gNetworking.NetPlayers[netIndex].Team;
        end
        else
        begin
          gameInfo.Enabled[I] := gHands[I].Enabled;
          gameInfo.CanBeHuman[I] := gHands[I].IsHuman;
          gameInfo.CanBeClassicAI[I] := aitClassic in gHands[I].CanBeAITypes;
          gameInfo.CanBeAdvancedAI[I] := aitAdvanced in gHands[I].CanBeAITypes;
          gameInfo.OwnerNickname[I] := gHands[I].OwnerNickname; //MP nickname, not translated OwnerName
          gameInfo.HandTypes[I] := gHands[I].HandType;
          gameInfo.Color[I] := gHands[I].FlagColor;
          gameInfo.Team[I] := gHands[I].Team;
        end;
      end;
    end;

    gameInfo.Save(aHeaderStream); // Saved to header stream (uncompressed)
    gameInfo.TxtInfo := nil; // Don't Free MapTxtInfo object in gameInfo, its used by our game
  finally
    FreeAndNil(gameInfo);
  end;

  fOptions.Save(aHeaderStream); // Saved to header stream (uncompressed)

  isMulti := fParams.IsMultiPlayerOrSpec or (ALLOW_SAVE_IN_REPLAY and (fParams.Mode = gmReplayMulti));
  // Because some stuff is only saved in singleplayer we need to know whether it is included in this save,
  // so we can load multiplayer saves in single player and vice versa.
  aHeaderStream.Write(isMulti);

  // In SinglePlayer we want to show player a preview of what the game looked like when he saved
  // Save Minimap is near the start so it can be accessed quickly
  if not isMulti then
    fGamePlayInterface.SaveMinimap(aHeaderStream);

  // ----------------------------------------------------------------
  // Save to BodyStream from that point
  // ----------------------------------------------------------------
  // We need to know which campaign to display after victory
  aBodyStream.Write(fCampaignName <> nil);
  if fCampaignName <> nil then
  begin
    fCampaignName.Save(aBodyStream);
    aBodyStream.Write(fCampaignMission);
  end;

  aBodyStream.Write(fParams.DynamicFOW);
  aBodyStream.Write(fSpeedGIP);
  aBodyStream.Write(fSpeedChangeAllowed);

  // We need to know which mission/savegame to try to restart. This is unused in MP
  if not isMulti then
    aBodyStream.WriteW(fParams.MissionFileRelSP);

  gUIDTracker.Save(aBodyStream); // Units-Houses ID tracker
  aBodyStream.Write(GetKaMSeed); // Include the random seed in the save file to ensure consistency in replays

  if not isMulti then
  begin
    // Game results differ for game and replay (grReplayEnd for replay),
    // Set some default value
    if GAME_SAVE_STRIP_FOR_CRC then
      gameRes := grCancel
    else
      gameRes := GameResult;

    aBodyStream.Write(gameRes, SizeOf(GameResult));
  end;

  gTerrain.Save(aBodyStream); // Saves the map
  fTerrainPainter.Save(aBodyStream);
  gHands.Save(aBodyStream, isMulti); // Saves all players properties individually
  if not isMulti then
    gMySpectator.Save(aBodyStream);

  if gHands.CanHaveAI() then
    gAIFields.Save(aBodyStream);

  fPathfinding.Save(aBodyStream);
  gProjectiles.Save(aBodyStream);
  fScripting.Save(aBodyStream);
  gScriptSounds.Save(aBodyStream);
  aBodyStream.Write(fAIType, SizeOf(fAIType));

  fTextMission.Save(aBodyStream);

  gRes.Units.SaveCustomData(aBodyStream);
  gRes.Wares.SaveCustomData(aBodyStream);

  // Parameters that are not identical for all players should not be saved as we need saves to be
  // created identically on all player's computers. Eventually these things can go through the GIP

  // For multiplayer consistency we compare all saves CRCs, they should be created identical on all player's computers.
  if not isMulti then
    fGamePlayInterface.Save(aBodyStream); //Saves message queue and school/barracks selected units

  {$IFDEF PARALLEL_RUNNER}
    SaveGAParameters(aBodyStream);
  {$ENDIF}

  // Trim stream size to current position
  aBodyStream.TrimToPosition;

  // Remember how much space did we use, so next time we have a good estimate
  fLastSaveStreamSize := aBodyStream.Size;

  // If we want stuff like the MessageStack and screen center to be stored in multiplayer saves,
  // we must send those "commands" through the GIP so all players know about them and they're in sync.
  // There is a comment in fGame.Load about MessageList on this topic.
end;


procedure TKMGame.PrepareSaveFolder(const aPathName: String; aSaveByPlayer: Boolean; aSaveWorkerThread: TKMWorkerThread);
var
  path: string;
begin
  path := aPathName;
  // Makes the folders in case they were deleted.
  // Should do before save Minimap file for MP game
  if (aPathName <> '') then
  begin
    // We can make directories in async too, since all save parts are made in async now
    aSaveWorkerThread.QueueWork(procedure
    begin
      path := ExtractFilePath(path);
      if DirectoryExists(path) then
      begin
        // Delete save folder content, since we want to overwrite old saves
        if aSaveByPlayer then
        begin
          // Delete whole folder to the bin
          // It looks better have one folder in the bin, than many files
          KMDeleteFolderToBin(path);
          ForceDirectories(path);
        end
        else
          // Delete all files
          KMDeleteFolderContent(path);
      end
      else
        ForceDirectories(path);
    end, 'Prepare save dir');
  end;
end;


// Saves the game in all its glory
procedure TKMGame.SaveGameToFile(const aPathName: String; aSaveByPlayer: Boolean; aSaveWorkerThread: TKMWorkerThread;
                                 aTimestamp: TDateTime; const aMPLocalDataPathName: String = '');
var
  mainStream, headerStream, bodyStream, saveStreamTxt: TKMemoryStream;
  gameMPLocalData: TKMGameMPLocalData;
begin
  if BLOCK_SAVE then Exit; // This must be here because of paraller Runner

  // We have to wait until basesave is made before first game save
  fBaseSaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete;

  gLog.AddTime(Format('Saving game at tick %d to ''%s''', [fParams.Tick, aPathName]));

  Assert(not fParams.IsMapEditor and (ALLOW_SAVE_IN_REPLAY or not fParams.IsReplay), 'Saving from wrong state');

  PrepareSaveFolder(aPathName, aSaveByPlayer, aSaveWorkerThread);

  mainStream    := TKMemoryStreamBinary.Create(False); // Not compressed
  headerStream  := TKMemoryStreamBinary.Create(False); // Not compressed
  bodyStream    := TKMemoryStreamBinary.Create(not SAVE_NO_COMPRESSION);  // Compressed by default

  SaveGameToStream(aTimestamp, headerStream, bodyStream);

  // In MP each player has his own perspective, hence we dont save minimaps in the main save file to avoid cheating,
  // but save minimap in separate file with local game data
  if fParams.IsMultiPlayerOrSpec and (aMPLocalDataPathName <> '') then
  begin
    try
      gameMPLocalData := TKMGameMPLocalData.Create(fLastReplayTickLocal, gNetworking.MyNetPlayer.StartLocation, fGamePlayInterface.Minimap);
      try
        gameMPLocalData.SaveToFileAsync(aMPLocalDataPathName, aSaveWorkerThread);
      finally
        FreeAndNil(gameMPLocalData);
      end;
    except
      on E: Exception do
        // Ignore any errors while saving minimap, because its optional for MP games
        gLog.AddTime('Error while saving save minimap to ' + aMPLocalDataPathName + ': ' + E.Message
          {$IFDEF WDC}+ sLineBreak + E.StackTrace{$ENDIF}
          );
    end
  end;

  mainStream.Write(True); // Save is compressed
  AsyncSaveStreamsToFileAndFree(mainStream, headerStream, bodyStream, aPathName, SAVE_HEADER_MARKER, SAVE_BODY_MARKER, aSaveWorkerThread);

  // Save .sav.txt file
  if DoSaveGameAsText then
  begin
    saveStreamTxt := TKMemoryStreamText.Create;
    SaveGameToStream(aTimestamp, saveStreamTxt);
    AsyncSaveToFileAndFree(saveStreamTxt, aPathName + EXT_SAVE_TXT_DOT, aSaveWorkerThread);
  end;
end;


procedure TKMGame.WaitForSaveToBeDone;
begin
  fSaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
end;


procedure TKMGame.WaitForAllSavesToBeDone;
begin
  fSaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
  fBaseSaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
  fAutoSaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
  fSavePointWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
end;


// Save game and wait till async worker complete all of its jobs
procedure TKMGame.SaveAndWait(const aSaveName: UnicodeString);
begin
  Save(aSaveName);

  //Wait for previous save async tasks to complete before proceeding
  fSaveWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
end;


procedure TKMGame.Save(const aSaveName: UnicodeString);
begin
  Save(aSaveName, UTCNow);
end;


procedure TKMGame.Save(const aSaveName: UnicodeString; aTimestamp: TDateTime);
begin
  Save(aSaveName, aTimestamp, fSaveWorkerThreadHolder.Worker); // Use default save worker thread
end;


// Saves game by provided name
procedure TKMGame.Save(const aSaveName: UnicodeString; aTimestamp: TDateTime; aSaveWorkerThread: TKMWorkerThread);
var
  I, index: Integer;
  fullPath, mpLocalDataPath, newSaveName, loadFrom: UnicodeString;
  {$IFDEF RNG_SPY} rngPath: UnicodeString; {$ENDIF}
  saveByPlayer: Boolean;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameSaveWait);
  {$ENDIF}
  try
    // Wait for previous save async tasks to complete before proceeding
    // We don't really need to wait here, since worker will wait automatically anyway in his queue
    // But if saves are made too often (f.e. on a very high game speed)
    // then waiting here will force worker to finish all of his previous jobs in his queue,
    // which is better than waiting a lot of time at the 'final save'
    aSaveWorkerThread.WaitForAllWorkToComplete;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameSaveWait);
    {$ENDIF}
  end;

  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameSave);
  {$ENDIF}
  try
    // Emulate slow save in the async save thread
    if SLOW_GAME_SAVE_ASYNC then
      aSaveWorkerThread.QueueWork(procedure
        begin
          Sleep(10000);
        end,
        'Slow Game Save'
      );

    // Convert name to full path+name
    fullPath := SaveName(aSaveName, EXT_SAVE_MAIN, fParams.IsMultiplayer);
    mpLocalDataPath := SaveName(aSaveName, EXT_SAVE_MP_LOCAL, fParams.IsMultiplayer);

    saveByPlayer :=     (aSaveName <> AUTOSAVE_SAVE_NAME)
                    and (aSaveName <> AUTOSAVE_AFTER_PT_END_SAVE_NAME)
                    and (aSaveName <> RETURN_TO_LOBBY_SAVE);
    SaveGameToFile(fullPath, saveByPlayer, aSaveWorkerThread, aTimestamp, mpLocalDataPath);

    if not fParams.IsMultiPlayerOrSpec then
      // Update GameSettings for saved positions in lists of saves and replays
      gGameSettings.MenuSPSaveFileName := aSaveName;

    // Remember which savegame to try to restart (if game was not saved before)
    fLastSaveFileRel := ExtractRelativePath(ExeDir, fullPath);

    newSaveName := SaveName(aSaveName, EXT_SAVE_BASE, fParams.IsMultiplayer);
    // Copy basesave so we have a starting point for replay
    if fParams.IsReplay then
    begin
      loadFrom := ChangeFileExt(ExeDir + fLoadFromFileRel, EXT_SAVE_BASE_DOT);
      // Game was saved from replay (.bas file)
      if FileExists(loadFrom) then
        {$IFDEF WDC}
        KMCopyFileAsync(loadFrom, newSaveName, True, aSaveWorkerThread);
        {$ELSE}
        KMCopyFile(loadFrom, newSaveName, True);
        {$ENDIF}
    end else
      // Normally saved game
      {$IFDEF PARALLEL_RUNNER}
        {$IFDEF WDC}
        KMCopyFileAsync(SaveName('basesave_thread_' + IntToStr(THREAD_NUMBER), EXT_SAVE_BASE, fParams.IsMultiplayer), NewSaveName, True, aSaveWorkerThread);
        {$ELSE}
        KMCopyFile(SaveName('basesave_thread_' + IntToStr(THREAD_NUMBER), EXT_SAVE_BASE, fParams.IsMultiplayer), NewSaveName, True, aSaveWorkerThread);
        {$ENDIF}
      {$ELSE}
        {$IFDEF WDC}
        KMCopyFileAsync(SaveName('basesave', EXT_SAVE_BASE, fParams.IsMultiplayer), newSaveName, True, aSaveWorkerThread);
        {$ELSE}
        KMCopyFile(SaveName('basesave', EXT_SAVE_BASE, fParams.IsMultiplayer), newSaveName, True);
        {$ENDIF}
      {$ENDIF}

    // Save replay info
    fGameInputProcess.SaveToFileAsync(ChangeFileExt(fullPath, EXT_SAVE_REPLAY_DOT), aSaveWorkerThread);

    // Save checkpoints
    if gGameSettings.SaveCheckpoints and not SKIP_SAVE_SAVPTS_TO_FILE then
    begin
      // Wait till all of the savepoints will be created
      fSavePointWorkerThreadHolder.Worker.WaitForAllWorkToComplete;
      // We can save savepoints by our savepoints worker, since we save to the different file anyway
      fSavePoints.SaveToFileAsync(ChangeFileExt(fullPath, EXT_SAVE_GAME_SAVEPTS_DOT), aSaveWorkerThread);
    end;

    {$IFDEF RNG_SPY}
    if DoSaveRandomChecks then
      try
        rngPath := ChangeFileExt(fullPath, EXT_SAVE_RNG_LOG_DOT);
        gRandomCheckLogger.SaveToPathAsync(rngPath, aSaveWorkerThread);
      except
        on E: Exception do
          gLog.AddTime('Error saving random checks to ' + rngPath); //Silently log error, don't propagate error further
      end;
    {$ENDIF}

    // Collect latest save names
    if aSaveName = AUTOSAVE_SAVE_NAME then
    begin
      fAutosavesCnt := EnsureRange(fAutosavesCnt + 1, 1, gGameSettings.AutosaveCount);

      // Increase numbers for autosave names in the list
      for I := fAutosavesCnt - 1 downto 1 do
      begin
        index := fLastSaves.IndexOfItem(AUTOSAVE_SAVE_NAME + Int2Fix(I, 2), TDirection.FromEnd);
        // we use limited list, so some autosave names will be deleted if other save names were added earlier
        if index <> -1 then
          fLastSaves[index] := AUTOSAVE_SAVE_NAME + Int2Fix(I + 1, 2);
      end;
      fLastSaves.Add(AUTOSAVE_SAVE_NAME + '01');
    end
    else
    if aSaveName <> CRASHREPORT_SAVE_NAME then
      fLastSaves.Add(aSaveName);

  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameSave);
    {$ENDIF}
  end;
end;


procedure TKMGame.SaveCampaignScriptData(SaveStream: TKMemoryStream);
begin
  fScripting.SaveCampaignData(SaveStream);
end;


procedure TKMGame.LoadFromStream(var LoadStream: TKMemoryStream);
var
  gameInfo: TKMGameInfo;
  loadedSeed: LongInt;
  compressedSaveBody, saveIsMultiplayer, isCampaign, dynamicFOW: Boolean;
  missionFileSP: UnicodeString;
  headerStream, bodyStream: TKMemoryStream;
begin
  LoadStream.Read(compressedSaveBody);

  if compressedSaveBody then
  begin
    headerStream := TKMemoryStreamBinary.Create;
    bodyStream := TKMemoryStreamBinary.Create(True);
    LoadStream.LoadToStreams(headerStream, bodyStream, SAVE_HEADER_MARKER, SAVE_BODY_MARKER);
  end
  else
  begin
    headerStream := LoadStream;
    bodyStream := LoadStream;
  end;

  // ----------------------------------------------------------------
  // Load from HeaderStream at first
  // ----------------------------------------------------------------
  try
    // We need only few essential parts from GameInfo, the rest is duplicate from gTerrain and fPlayers
    gameInfo := TKMGameInfo.Create;
    try
      gameInfo.Load(headerStream);
      fParams.Name := gameInfo.Title;
      fParams.MapFullCRC := gameInfo.MapFullCRC;
      fParams.MapSimpleCRC := gameInfo.MapSimpleCRC;
      fSetGameTickEvent(gameInfo.TickCount);
      fParams.MissionMode := gameInfo.MissionMode;
      fParams.MissionDifficulty := gameInfo.MissionDifficulty;
      fMapTxtInfo.Free; // Free previously create gGame's fMapTxtInfo, which was created in TKMGame.Create
      fMapTxtInfo := gameInfo.TxtInfo;
      gameInfo.TxtInfo := nil; // Don't Free MapTxtInfo object in gameInfo, its used by our game
    finally
      FreeAndNil(gameInfo);
    end;

    fOptions.Load(headerStream);

    // So we can allow loading of multiplayer saves in single player and vice versa we need to know which type THIS save is
    headerStream.Read(saveIsMultiplayer);
    if saveIsMultiplayer and (fParams.Mode = gmReplaySingle) then
      fSetGameModeEvent(gmReplayMulti); // We only know which it is once we've read the save file, so update it now

    // If the player loads a multiplayer save in singleplayer or replay mode, we require a mutex lock to prevent cheating
    // If we're loading in multiplayer mode we have already locked the mutex when entering multiplayer menu,
    // which is better than aborting loading in a multiplayer game (spoils it for everyone else too)
    if saveIsMultiplayer and (fParams.Mode in [gmSingle, gmCampaign, gmReplaySingle, gmReplayMulti]) then
      if gMain.LockMutex then
        fLockedMutex := True // Remember so we unlock it in Destroy
      else
        // Abort loading (exception will be caught in gGameApp and shown to the user)
        raise Exception.Create(gResTexts[TX_MULTIPLE_INSTANCES]);

    // Not used, (only stored for SP preview) but it's easiest way to skip past it
    if not saveIsMultiplayer then
      fGamePlayInterface.LoadMinimap(headerStream);

    // ----------------------------------------------------------------
    // Load from BodyStream from that point
    // ----------------------------------------------------------------
    // We need to know which campaign to display after victory
    bodyStream.Read(isCampaign);
    if isCampaign then
    begin
      fCampaignName := TKMCampaignId.Load(bodyStream);
      bodyStream.Read(fCampaignMission);
    end;

    bodyStream.Read(dynamicFOW);
    fParams.DynamicFOW := dynamicFOW;
    bodyStream.Read(fSpeedGIP);

    // Set game actual speed, so we will have same speed after game load as it was when game was saved
    if not fParams.IsReplay then
      SetSpeedActualValue(fSpeedGIP)
    else
      fGamePlayInterface.UpdateClockUI; // To show actual game speed in the replay

    bodyStream.Read(fSpeedChangeAllowed);

    // If there is Campaign Name in save then change GameMode to gmCampaign, because GameMode is not stored in Save
    if isCampaign
      and not fParams.IsReplay then // Not for replays thought...
      fSetGameModeEvent(gmCampaign);

    // We need to know which mission/savegame to try to restart. This is unused in MP.
    if not saveIsMultiplayer then
    begin
      bodyStream.ReadW(missionFileSP);
      fSetMissionFileSP(missionFileSP);
    end;

    gUIDTracker.Load(bodyStream);
    bodyStream.Read(loadedSeed);

    if not saveIsMultiplayer then
      bodyStream.Read(GameResult, SizeOf(GameResult));

    // Load the data into the game
    gTerrain.Load(bodyStream);
    fTerrainPainter.Load(bodyStream);

    gHands.Load(bodyStream);
    gMySpectator := TKMSpectator.Create(0);
    if not saveIsMultiplayer then
      gMySpectator.Load(bodyStream);

    if gHands.CanHaveAI() then
      gAIFields.Load(bodyStream);

    fPathfinding.Load(bodyStream);
    gProjectiles.Load(bodyStream);
    fScripting.Load(bodyStream);
    gScriptSounds.Load(bodyStream);
    bodyStream.Read(fAIType, SizeOf(fAIType));

    fTextMission := TKMTextLibraryMulti.Create;
    fTextMission.Load(bodyStream);

    gRes.Units.LoadCustomData(bodyStream);
    gRes.Wares.LoadCustomData(bodyStream);

    if fParams.IsReplayOrSpectate then
    begin
      gMySpectator.FOWIndex := HAND_NONE; // Show all by default in replays
      // HandIndex is the first enabled player
      gMySpectator.HandID := FindHandToSpec;
    end;

    // Multiplayer saves don't have this piece of information. Its valid only for MyPlayer
    // todo: Send all message commands through GIP (note: that means there will be a delay when you press delete)
    if not saveIsMultiplayer then
      fGamePlayInterface.Load(bodyStream);

    {$IFDEF PARALLEL_RUNNER}
      LoadGAParameters(bodyStream);
    {$ENDIF}

    if fParams.IsReplay then
      fGameInputProcess := TKMGameInputProcess_Single.Create(gipReplaying) //Replay
    else
      if fParams.IsMultiPlayerOrSpec then
        fGameInputProcess := TKMGameInputProcess_Multi.Create(gipRecording) //Multiplayer
      else
        fGameInputProcess := TKMGameInputProcess_Single.Create(gipRecording);

    SetSeed(loadedSeed); // Seed is used in MultiplayerRig when changing humans to AIs through GIP for replay
  finally
    if compressedSaveBody then
    begin
      headerStream.Free;
      bodyStream.Free;
    end;
  end;

  fIsJustStarted := True; // Mark game as just started
end;


procedure TKMGame.LoadFromFile(const aPathName: UnicodeString; const aCustomReplayFile: UnicodeString = '');

  procedure LoadReplayDataFromFile(const aFileName: string);
  begin
    fGameInputProcess.LoadFromFile(ChangeFileExt(aFileName, EXT_SAVE_REPLAY_DOT));
    fSavePoints.LoadFromFile(ChangeFileExt(aFileName, EXT_SAVE_GAME_SAVEPTS_DOT));
  end;

var
  loadStream: TKMemoryStream;
  gameMPLocalData: TKMGameMPLocalData;
  {$IFDEF RNG_SPY} rngPath: UnicodeString; {$ENDIF}
begin
  fLoadFromFileRel := ChangeFileExt(ExtractRelativePath(ExeDir, aPathName), EXT_SAVE_MAIN_DOT);
  fLastSaveFileRel := fLoadFromFileRel; // We set last save to the loaded file, so we will be able to restart from this point

  gLog.AddTime('Loading game from: ' + aPathName);

  // We should wait for the all of save workers to complete their jobs until we load a next save.
  // Otherwise we could end up loading some corrupted save data if saving is not done yet and we load in the middle of the save process
  WaitForAllSavesToBeDone;

  loadStream := TKMemoryStreamBinary.Create;
  try
    if not FileExists(aPathName) then
      raise Exception.Create('Savegame could not be found at ''' + aPathName + '''');

    loadStream.LoadFromFile(aPathName);

    LoadFromStream(loadStream);

    if aCustomReplayFile = '' then
      LoadReplayDataFromFile(aPathName)
    else
    begin
      gLog.AddTime('Loading game replay from: ' + aCustomReplayFile);
      LoadReplayDataFromFile(aCustomReplayFile);
    end;

    // Load MP game local data
    if fParams.Mode = gmReplayMulti then
    begin
      gameMPLocalData := TKMGameMPLocalData.Create;
      try
        gameMPLocalData.LoadFromFile(ChangeFileExt(ExtractRelativePath(ExeDir, aPathName), EXT_SAVE_MP_LOCAL_DOT));
        fLastReplayTickLocal := gameMPLocalData.LastReplayTick;
      finally
        FreeAndNil(gameMPLocalData);
      end;
    end;

    // SetSeed was there, I dont know the dependencies so please check if it is ok to include it in LoadGameStream

    {$IFDEF RNG_SPY}
    if DoSaveRandomChecks then
      try
        rngPath := ChangeFileExt(aPathName, EXT_SAVE_RNG_LOG_DOT);
        gRandomCheckLogger.LoadFromPath(rngPath);
        gRandomCheckLogger.Enabled := not fParams.IsMapEditor and not fParams.IsReplay;  // Disable random check logger for MapEditor
      except
        on E: Exception do
          gLog.AddTime('Error loading random checks from ' + rngPath); // Silently log error, don't propagate error further
      end;
    {$ENDIF}

    gLog.AddTime('Loading game', True);
  finally
    FreeAndNil(loadStream);
  end;
end;


procedure TKMGame.LoadSavePoint(aTick: Cardinal; const aSaveFile: UnicodeString);
var
  spStream, decompStream: TKMemoryStream;
  lastReplayTick: Cardinal;
  skipReplayEndCheck: Boolean;
begin
  gLog.AddTime('Loading replay from save');
  fLastSaveFileRel := aSaveFile;

  if fSavePoints.Contains(aTick) then
  begin
    lastReplayTick := fLastReplayTickLocal;
    skipReplayEndCheck := fSkipReplayEndCheck;

    spStream := TKMemoryStreamBinary(fSavePoints[aTick]);
    spStream.Position := 0;

    decompStream := TKMemoryStreamBinary.Create;
    try
      decompStream.LoadFromStreamCompressed(spStream);
      LoadFromStream(decompStream);
    finally
      decompStream.Free;
    end;

    // Restore game (replay) parameters, that are shared among all game savepoints
    gGame.LastReplayTickLocal := lastReplayTick;
    gGame.SkipReplayEndCheck := skipReplayEndCheck;
    gLog.AddTime('Loading replay from save done', True);
  end;
end;


// Save game/replay savepoint
procedure TKMGame.MakeSavePoint;
var
  saveStream: TKMemoryStream;
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psGameSavePoint);
  {$ENDIF}
  try
    if (fSavePoints = nil) or fSavePoints.Contains(fParams.Tick) then // No need to save twice on the same tick
      Exit;

    gLog.AddTime('Make savepoint at tick ' + IntToStr(fParams.Tick));

    saveStream := TKMemoryStreamBinary.Create;
    SaveGameToStream(0, saveStream); // Date is not important

    fSavePoints.NewSavePointAsyncAndFree(saveStream, fParams.Tick, fSavePointWorkerThreadHolder.Worker);
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psGameSavePoint);
    {$ENDIF}
  end;
end;


procedure TKMGame.AfterLoad;
var
  I: Integer;
begin
  gLog.AddTime('After game loading');
  // Should check all Unit-House ID references and replace them with actual pointers
  gHands.SyncLoad;

  for I := 0 to gHands.Count - 1 do
    try
      gHands[I].OverlayText := TextMission.ParseTextMarkup(UnicodeString(gHands[I].OverlayMarkup), gHands[I].OverlayParams.ToVarRecArray);
    except
      // Format may throw an exception
      on E: EConvertError do
        gLog.AddTime(Format('EConvert Error while loading overlay for hand %d, '
                        + 'OverlayMarkup = ''%s'', OverlayParams.Count = %d; ErrorMsg: %s',
                      [I, gHands[I].OverlayMarkup, gHands[I].OverlayParams.Count, E.Message]));
    end;



  gTerrain.SyncLoad;
  gProjectiles.SyncLoad;
  fScripting.SyncLoad;

  if fParams.IsMultiPlayerOrSpec then
    MultiplayerRig(False);

  UpdateTickCounters; // We have to update game-speed-changed counters

  if fParams.Mode in [gmSingle, gmCampaign, gmMulti, gmMultiSpectate] then
  begin
    KMDeleteFile(SaveName('basesave', EXT_SAVE_BASE, fParams.IsMultiPlayerOrSpec));
    ForceDirectories(SavePath('basesave', fParams.IsMultiPlayerOrSpec)); // basesave directory could not exist at this moment, if this is the first game ever, f.e.
    KMCopyFile(ChangeFileExt(ExeDir + fLoadFromFileRel, EXT_SAVE_BASE_DOT), SaveName('basesave', EXT_SAVE_BASE, fParams.IsMultiPlayerOrSpec));
  end;

  // Repeat mission init if necessary
  if fParams.Tick = 0 then
    gScriptEvents.ProcMissionStart;

  // When everything is ready we can update UI
  fActiveInterface.SyncUI;

  if fParams.IsMultiPlayerOrSpec then
  begin
    // MP does not saves view position cos of save identity for all players
    fActiveInterface.SyncUIView(KMPointF(gMySpectator.Hand.CenterScreen));
    // In MP saves hotkeys can't be saved by UI, they must be network synced
    if fParams.IsNormalGame then
      fGamePlayInterface.LoadHotkeysFromHand;
  end;

  if fParams.IsReplay then
  begin
    // SP Replay need to set screen position
    fActiveInterface.SyncUIView(KMPointF(gMySpectator.Hand.CenterScreen));

    fGamePlayInterface.UpdateReplayMarks;
  end
  else
  // Save dummy GIP to know when game was loaded. Good for debug
  // Only by host in MP game
  if not fParams.IsMultiPlayerOrSpec or gNetworking.IsHost then
    fGameInputProcess.CmdGame(gicGameLoadSave, Integer(fParams.Tick));

  gRenderPool.ReInit;

  fIsStarted := True;

  gLog.AddTime('Game options: ' + fOptions.ToString);
  gLog.AddTime('After game loading', True);
end;


function TKMGame.GetTickDuration: Single;
begin
  Result := gGameSettings.SpeedPace / fSpeedActual;
end;


function TKMGame.GetTicksBehindCnt: Single;
var
  calculatedTick: Single;
  timeS: Cardinal;
begin
  if (Self = nil) or (fParams = nil) then Exit(0);

  // Lets calculate tick, that shoud be at that moment in theory, depending of speed multiplier and game duration
  timeS := TimeSince(fSpeedChangeTime);
  calculatedTick := timeS*fSpeedActual/gGameSettings.SpeedPace - fPausedTicksCnt;
  // Calc how far behind are we, in ticks
  Result := calculatedTick + fSpeedChangeTick - fParams.Tick;
end;


procedure TKMGame.UpdateTickCounters;
var
  ticksBehind: Single;
begin
  if Self = nil then Exit;

  ticksBehind := GetTicksBehindCnt; // save number of ticks we are behind now
  fSpeedChangeTick := fParams.Tick;
  if fParams.IsMultiPlayerOrSpec and not IsMPGameSpeedChangeAllowed then
    // Remember if we were some ticks behind at that moment.
    // Important for MP game with many players, but can be omitted for SP and MP with only 1 player
    fSpeedChangeTick := fSpeedChangeTick + ticksBehind;
  // set fGameSpeedChangeTime after we invoke GetTicksBehindCnt !
  fSpeedChangeTime := TimeGet;
  fPausedTicksCnt := 0;
end;


procedure TKMGame.UpdateGame;
  procedure DoUpdateGame;
  begin
    if not PlayNextTick then
      Inc(fPausedTicksCnt);
    if fDoHold then
      Hold(True, fDoHoldState);
  end;

var
  I: Integer;
  ticksBehindCnt: Single;
begin
  if (Self = nil) or fIsExiting then Exit;
  
  DoUpdateGame;

  if CALC_EXPECTED_TICK then
  begin
    ticksBehindCnt := GetTicksBehindCnt;

    // When our game is more then 0.5 tick behind - play another tick immediately
    // This will prevent situation, when lags on local PC (on zoon out, f.e.) leads to lags for all other MP players
    // Also game speed become absolutely presize
    if ticksBehindCnt > 0.5 then
      // f.e. if we behind on 1.4 ticks - make 1 more update, for 1.6 - 2 more updates
      for I := 0 to Min(Trunc(ticksBehindCnt - 0.5), MAX_TICKS_PER_GAME_UPDATE - 1) do // do not do too many GameUpdates at once. Limit them
        DoUpdateGame;
  end
  else
  begin
    // Always play several ticks per update. This is more convinient while using debugger
    for I := 1 to fSpeedMultiplier - 1 do // 1 Tick we already played
      DoUpdateGame;
  end;
end;


procedure TKMGame.IssueAutosaveCommand(aAfterPT: Boolean);
var
  gicType: TKMGameInputCommandType;
begin
  if aAfterPT then
    gicType := gicGameAutoSaveAfterPT
  else
    gicType := gicGameAutoSave;

  gLog.AddTime(Format('Issue %s command at tick %d', [GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(gicType)),
                                                      fParams.Tick]));

  if fParams.IsMultiPlayerOrSpec then
  begin
    if gNetworking.IsHost then // Host initiate autosave command
      fGameInputProcess.CmdGame(gicType, UTCNow); // Timestamp must be synchronised
  end
  else
    if gGameSettings.Autosave then
      fGameInputProcess.CmdGame(gicType, UTCNow);
end;


procedure TKMGame.SetSeed(aSeed: Integer);
begin
  if (CUSTOM_SEED_VALUE > 0) and not fParams.IsReplay then
    aSeed := CUSTOM_SEED_VALUE;

  gLog.AddTime('Set game seed: ' + IntToStr(aSeed));

  KM_CommonUtils.SetKaMSeed(aSeed);
  fSeed := aSeed; //Save it for debug only
end;


procedure TKMGame.IncTick;
begin
  fSetGameTickEvent(fParams.Tick + 1); // Thats our tick counter for gameplay events
  if LOG_GAME_TICK then
    gLog.AddTime('Tick: ' + IntToStr(fParams.Tick));
end;


function TKMGame.IsReplayEnded: Boolean;
var
  lastReplayTick: Cardinal;
begin
  lastReplayTick := GetReplayLastTick;

  if lastReplayTick > 0 then
    Result := fParams.Tick >= lastReplayTick
  else
    Result := fGameInputProcess.ReplayEnded;
end;


function TKMGame.GetReplayLastTick: Cardinal;
begin
  Result := Max4(fLastReplayTickLocal,
                 fGameInputProcess.GetLastTick,
                 fParams.Tick,
                 fSavePoints.LastTick);
end;


function TKMGame.CheckPauseGameAtTick: Boolean;

  procedure SetReplayPause;
  begin
    IsPaused := True;
    // Set replay UI to paused state, sync replay timer and other UI elements
    fGamePlayInterface.UpdateReplayButtons;
    fGamePlayInterface.UpdateState(gGameApp.GlobalTickCount);
  end;

begin
  Result := False;

  if (fParams.Mode = gmReplayMulti)
    and gGameSettings.ReplayAutopause
    and (fOptions.Peacetime * 600 = fParams.Tick + 1) then
  begin
    SetReplayPause;
    Exit(True);
  end;

  if fParams.Tick = PAUSE_GAME_BEFORE_TICK - 1 then
  begin
    if fParams.IsReplay then
      SetReplayPause
    else
      fGamePlayInterface.SetPause(True);

    Exit(True);
  end;
end;


function TKMGame.PlayGameTick: Boolean;

  // Make savepoint and autosaves
  procedure ManageSaves;
  const
    // Spread savepoints / autosaves / autosave at PT end (at 0 tick) among ticks to avoid async / main threads overload
    SAVEPT_TICK_SHIFT = 1;
  begin
    // Do not add autosave or savepoint for a just started / loaded game
    if fIsJustStarted then Exit;

    // Save game to memory (to be able to load it later)
    // Make savepoint only after everything is updated (UpdateState)
    if gGameSettings.SaveCheckpoints
      and (fSavePoints.Count <= gGameSettings.SaveCheckpointsLimit) // Do not allow to spam saves, could cause OUT_OF_MEMORY error
      and ((fParams.Tick = MAKE_SAVEPT_BEFORE_TICK - 1) or (fParams.Tick = 0)
        or ((fParams.Tick + SAVEPT_TICK_SHIFT) = (fOptions.Peacetime*60*10)) // At PT end. Make savepoint a bit earlier, to avoid save lag
        or (((fParams.Tick + SAVEPT_TICK_SHIFT) mod gGameSettings.SaveCheckpointsFreq) = 0)) then // Make savepoint a bit earlier, to avoid save lag
      MakeSavePoint;

    // Avoid 2 autosaves made at the same tick (at PT end and normal autosave)
    if CheckIfPieceTimeJustEnded then // Send warning messages about peacetime if required
    begin
      // gicGameSpeed will do speed change in the replay
      TrySetSpeed(fOptions.SpeedAfterPT, False);
      gNetworking.PostLocalMessage(gResTexts[TX_MP_PEACETIME_OVER], csNone);
      IssueAutosaveCommand(True);
    end
    else
    if (fParams.Tick = 0) or ((fParams.Tick mod gGameSettings.AutosaveFrequency) = 0) then
      IssueAutosaveCommand(False);
  end;

begin
  Result := False;

  {$IFDEF PERFLOG}
  gPerfLogs.TickBegin(fParams.Tick + 1);
  {$ENDIF}
  try
    try
      // As soon as next command arrives we are no longer in a waiting state
      if fWaitingForNetwork then
        WaitingPlayersDisplay(False);

      // Make savepoints and saves BEFORE tick increment
      // Thus all of the previous gip commands, which were made from last tick increment,
      // will be added to the save.
      ManageSaves;

      IncTick;

      // Game is no longer 'just started'
      fIsJustStarted := False;

      fGameInputProcess.TakePlannedCommands;

      fLastUpdateState := TimeGet;

      fLastReplayTickLocal := fParams.Tick;

      if fParams.IsMultiPlayerOrSpec then
        gNetworking.LastProcessedTick := fParams.Tick;

      // Tell the master server about our game on the specific tick (host only)
      if fParams.IsMultiPlayerOrSpec and gNetworking.IsHost
        and ((fParams.IsNormalMission and (fParams.Tick = ANNOUNCE_BUILD_MAP))
        or (fParams.IsTactic and (fParams.Tick = ANNOUNCE_BATTLE_MAP))) then
      gNetworking.ServerQuery.SendMapInfo(fParams.Name, fParams.MapFullCRC, gNetworking.NetPlayers.GetConnectedCount);

      fScripting.UpdateState;
      gTerrain.UpdateState;

      if gHands.CanHaveAI() then
        gAIFields.UpdateState(fParams.Tick);

      gHands.UpdateState(fParams.Tick); // Quite slow

      if gGame = nil then Exit; // Quit the update if game was stopped for some reason

      gMySpectator.UpdateState(fParams.Tick);
      fPathfinding.UpdateState;
      gProjectiles.UpdateState; // If game has stopped it's NIL

      fGameInputProcess.RunningTimer(fParams.Tick); // GIP_Multi issues all commands for this tick

      // Returning to the lobby (through MP GIP) ends the game
      if gGame = nil then Exit;

      // In aggressive mode store a command every tick so we can find exactly when a replay mismatch occurs
      if AGGRESSIVE_REPLAYS then
        fGameInputProcess.CmdTemp(gicTempDoNothing); // do call cmd before SaveGameCheckpoint

      fSavePoints.LastTick := Max(fSavePoints.LastTick, fParams.Tick);

      // Update our ware distributions from settings at the start of the game
      if (fParams.Tick = 1)
      and IsWareDistributionStoredBetweenGames then
        fGameInputProcess.CmdWareDistribution(gicWareDistributions, AnsiString(gGameSettings.WareDistribution.PackToStr));

      Result := True;

      CheckPauseGameAtTick;
    finally
      {$IFDEF RNG_SPY}
      // Save rng logger even if game crashed during tick execution, f.e. because of desync
      if DoSaveRandomChecks then
        gRandomCheckLogger.UpdateState(fParams.Tick);
      {$ENDIF}
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.TickEnd;
    {$ENDIF}
  end;
end;


function TKMGame.PlayReplayTick: Boolean;

  procedure ManageSaves;
  begin
    // Do not add savepoint for a just loaded game
    if fIsJustStarted then Exit;

    // Only increase LastTick, since we could load replay earlier at earlier state
    fSavePoints.LastTick := Max(fSavePoints.LastTick, fParams.Tick);

    // Save replay to memory (to be able to load it later)
    // Make replay save only after everything is updated (UpdateState)
    if gGameSettings.ReplaySavepoint
      and (fSavePoints.Count <= REPLAY_SAVEPOINT_CNT_MAX) // Do not allow to spam saves, could cause OUT_OF_MEMORY error
      and ((fParams.Tick = 1) // First tick
        or (fParams.Tick = MAKE_SAVEPT_BEFORE_TICK - 1)
        or (fParams.Tick = (fOptions.Peacetime*60*10)) // At PT end
        or ((fParams.Tick mod GetReplayAutosaveEffectiveFrequency) = 0)) then
    begin
      MakeSavePoint;
      fGamePlayInterface.AddReplayMark(fParams.Tick);
    end;
  end;

begin
  Result := False;

  fLastUpdateState := TimeGet;
  {$IFDEF PERFLOG}
  gPerfLogs.TickBegin(fParams.Tick + 1);
  {$ENDIF}

  try
    // Make savepoints and saves BEFORE tick increment
    // Same way we do in the PlayGameTick
    ManageSaves;

    IncTick;

    // Game is no longer 'just started'
    fIsJustStarted := False;

    fScripting.UpdateState;
    gTerrain.UpdateState;
    gAIFields.UpdateState(fParams.Tick);
    gHands.UpdateState(fParams.Tick); // Quite slow
    if gGame = nil then Exit; // Quit the update if game was stopped for some reason
    gMySpectator.UpdateState(fParams.Tick);
    fPathfinding.UpdateState;
    gProjectiles.UpdateState; // If game has stopped it's NIL

    // Issue stored commands
    fGameInputProcess.ReplayTimer(fParams.Tick);
    // Used when need to run Runner replays sometimes (we could make replay at tick 1 and then need to 'simulate' gicTempDoNothing GIP cmd
//    if AGGRESSIVE_REPLAYS and (fParams.Tick > 1) then
//      KaMRandom(MaxInt, 'TKMGameInputProcess.StoreCommand');

    CheckIfPieceTimeJustEnded; // Send warning messages about peacetime if required (peacetime sound should still be played in replays)

    if gGame = nil then Exit; // Quit if the game was stopped by a replay mismatch

    if not fSkipReplayEndCheck and IsReplayEnded then
      RequestHold(grReplayEnd);

    if fAdvanceFrame then
    begin
      fAdvanceFrame := False;
      fIsPaused := True;
      fGamePlayInterface.ShowDebugInfo;
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.TickEnd;
    {$ENDIF}
  end;

  if fDoHold then Exit;

  CheckPauseGameAtTick;

  Result := True;
end;


function TKMGame.PlayNextTick: Boolean;
var
  gipMP: TKMGameInputProcess_Multi;
begin
  Result := False;
  // Some PCs seem to change 8087CW randomly between events like Timers and OnMouse*,
  // so we need to set it right before we do game logic processing
  Set8087CW($133F);

  if fIsPaused or ReadyToStop then
    Exit;

  fSetBlockPointer(False);

  try
    try
      case fParams.Mode of
        gmSingle,
        gmCampaign:       Result := PlayGameTick;
        gmMulti,
        gmMultiSpectate:  begin
                            gipMP := TKMGameInputProcess_Multi(fGameInputProcess);
                            // For MP game we have to play tick (and possible GIP) only in lgsGame state
                            // Otherwise gNetworking.MyIndex could contain corrupted data
                            // (f.e. when reconnecting MyIndex is reset by TKMNetworking.Join, assuming we will receive a new one with PlayerList packet
                            // which could be delayed)
                            // Other NetGameState's states could also have potential problems
                            if gNetworking.NetGameState = lgsGame then // MP game in Game state
                            begin
                              if gipMP.CommandsConfirmed(fParams.Tick + 1) then
                                Result := PlayGameTick
                              else
                              begin
                                gipMP.WaitingForConfirmation(fParams.Tick);
                                if gipMP.NumberConsecutiveWaits > Max(10, Round(fSpeedGIP)) then
                                  WaitingPlayersDisplay(True);
                              end;
                              gipMP.UpdateState(fParams.Tick); // Do maintenance
                            end;
                          end;
        gmReplaySingle,
        gmReplayMulti:    Result := PlayReplayTick;
        gmMapEd:          begin
                            fLastUpdateState := TimeGet;
                            {$IFDEF PERFLOG}
                            gPerfLogs.TickBegin(gGameApp.GlobalTickCount);
                            {$ENDIF}
                            gTerrain.IncAnimStep;
                            gHands.IncAnimStep;
                            gHands.PlayerAnimals.UpdateVisualState;
                            gHands.UpdateVisualState;
                            {$IFDEF PERFLOG}
                            gPerfLogs.TickEnd;
                            {$ENDIF}
                          end;
      end;
    except
        on E: Exception do
        begin
          gLog.AddTime('Exception on tick ' + IntToStr(fParams.Tick) + ': ' + E.Message
                       {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
          raise;
        end;
    end;
  finally
    fSetBlockPointer(True);
  end;
end;


{$IFDEF RNG_SPY}
function TKMGame.DoSaveRandomChecks: Boolean;
begin
  Result := gGameSettings.DebugSaveRandomChecks
            and SAVE_RANDOM_CHECKS
            and (gRandomCheckLogger <> nil);
end;
{$ENDIF}


function TKMGame.DoRenderGame: Boolean;
begin
  // Do not render game under game stats page
  Result := fParams.IsMapEditor or not fGamePlayInterface.StatsOpened;
end;


function TKMGame.DoSaveGameAsText: Boolean;
begin
  Result := gGameSettings.DebugSaveGameAsText
            and SAVE_GAME_AS_TEXT;
end;


function TKMGame.GetReplayAutosaveEffectiveFrequency: Integer;
begin
  Assert(fParams.IsReplay, 'Wrong game mode');
  Result := Math.Max(gGameSettings.ReplaySavepointFrequency,
                     // Do not save too often, that could cause OUT_OF_MEMORY error
                     fGameInputProcess.GetLastTick div (REPLAY_SAVEPOINT_CNT_MAX - 2)); // - 2 for starting one and for PT
  Result := Ceil(Result / 300)*300; // Ceil to every 30 sec
end;


procedure TKMGame.UserAction(aActionType: TKMUserActionType);
begin
  fLastTimeUserAction := Max(fLastTimeUserAction, TimeGet);
end;


procedure TKMGame.VisibleLayersWereSet;
begin
  gTerrain.UpdateRenderHeight;
end;


// Add remove script sounds request to the script sounds manager
procedure TKMGame.AddScriptSoundRemoveRequest(aScriptSoundUID: Integer; aHandID: TKMHandID);
begin
  gScriptSounds.AddRemoveRequest(aScriptSoundUID, aHandID, GetActiveHandIDs);
end;


procedure TKMGame.UpdateState(aGlobalTickCount: Cardinal);
const
  PLAYER_AFK_TIME = 5; // in minutes. Notify other players, when this player is AFK
  PLAYER_AFK_MESSAGE_DELAY = 5*60*1000; // in ms, wait till next AFK message. do not spam players with messages
begin
  gScriptSounds.UpdateStateGlobal;

  fActiveInterface.UpdateState(aGlobalTickCount);

  if not fIsPaused then
  begin
    // Notify about player being AFK
    if fParams.IsMultiplayerGame // Only for MP game players, not specs
      and (TimeSince(fLastTimeUserAction) > PLAYER_AFK_TIME*60*1000)
      and (TimeSince(fLastAfkMessageSent) > PLAYER_AFK_MESSAGE_DELAY) then
    begin
      gNetworking.PostMessage(TX_PLAYER_AFK_MESSAGE, csSystem, gNetworking.MyNetPlayer.NicknameColoredU,
                              WrapColor(IntToStr(TimeSince(fLastTimeUserAction) div 60000), icGoldenYellow));
      fLastAfkMessageSent := TimeGet;
    end;
  end;

  if aGlobalTickCount mod 10 = 0 then
    fMapEditor.UpdateState;
end;


// This is our real-time "thread", use it wisely
procedure TKMGame.UpdateStateIdle(aFrameTime: Cardinal);
begin
  fActiveInterface.UpdateStateIdle(aFrameTime);

  // Terrain should be updated in real time when user applies brushes
  if fMapEditor <> nil then
    fMapEditor.UpdateStateIdle;
end;


procedure TKMGame.DebugControlsUpdated(Sender: TObject; aSenderTag: Integer);
begin
  if Self = nil then Exit;

  ActiveInterface.DebugControlsUpdated(aSenderTag);
end;


class function TKMGame.SavePath(const aName: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;
begin
  Result := TKMSavesCollection.Path(aName, aIsMultiplayer);
end;


class function TKMGame.SaveName(const aFolder, aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;
begin
  Result := TKMSavesCollection.Path(aFolder, aIsMultiplayer) + aName + '.' + aExt;
end;


class function TKMGame.SaveName(const aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;
begin
  Result := TKMSavesCollection.FullPath(aName, aExt, aIsMultiplayer);
end;


end.

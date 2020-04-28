unit KM_Game;
{$I KaM_Remake.inc}
interface
uses
  ExtCtrls,
  {$IFDEF USE_MAD_EXCEPT} MadExcept, {$ENDIF}
  KM_WorkerThread,
  KM_Networking,
  KM_PathFinding,
  KM_GameInputProcess, KM_GameSavedReplays, KM_GameOptions, KM_Scripting, KM_MapEditor, KM_Campaigns, KM_Render, KM_Sound,
  KM_InterfaceGame, KM_InterfaceGamePlay, KM_InterfaceMapEditor,
  KM_ResTexts, KM_Maps, KM_MapTypes, KM_Hand,
  KM_Defaults, KM_Points, KM_CommonTypes, KM_CommonClasses,
  KM_GameTypes, KM_TerrainPainter;

type

  //Class that manages single game session
  TKMGame = class
  private //Irrelevant to savegame
    fTimerGame: TTimer;
    fGameOptions: TKMGameOptions;
    fNetworking: TKMNetworking;
    fGameInputProcess: TKMGameInputProcess;
    fTextMission: TKMTextLibraryMulti;
    fPathfinding: TPathFinding;
    fActiveInterface: TKMUserInterfaceGame; //Shortcut for both of UI
    fGamePlayInterface: TKMGamePlayInterface;
    fMapEditorInterface: TKMapEdInterface;
    fMapEditor: TKMMapEditor;
    fTerrainPainter: TKMTerrainPainter;
    fSavedReplays: TKMSavedReplays;
    fScripting: TKMScripting;
    fOnDestroy: TEvent;

    fIsExiting: Boolean; //Set this to true on Exit and unit/house pointers will be released without cross-checking
    fIsPaused: Boolean;
    fGameSpeedActual: Single; //Actual speedup value, used to play the game
    fGameSpeedMultiplier: Word; //How many ticks are compressed into one
    fGameMode: TKMGameMode;
    fWaitingForNetwork: Boolean; //Indicates that we are waiting for other players commands in MP
    fAdvanceFrame: Boolean; //Replay variable to advance 1 frame, afterwards set to false
    fSaveFile: UnicodeString;  //Relative pathname to savegame we are playing, so it gets saved to crashreport
    fGameLockedMutex: Boolean;
    fOverlayText: array[0..MAX_HANDS] of UnicodeString; //Needed for replays. Not saved since it's translated
    fIgnoreConsistencyCheckErrors: Boolean; // User can ignore all consistency check errors while watching SP replay

    fAIType: TKMAIType;
    fMapTxtInfo: TKMMapTxtInfo;

    //Should be saved
    fCampaignMap: Byte;         //Which campaign map it is, so we can unlock next one on victory
    fCampaignName: TKMCampaignId;  //Is this a game part of some campaign
    fDynamicFOW: Boolean;
    fGameSpeedGIP: Single; //GameSpeed, recorded to GIP, could be requested by scripts
    fGameSpeedChangeAllowed: Boolean; //Is game speed change allowed?

    fBlockGetPointer: Boolean; //?? should be saved ??

    //Saved and loaded via GameInfo
    fGameName: UnicodeString;
    fGameMapSimpleCRC: Cardinal; //CRC of map (based on Map and Dat) used in MapEd
    fGameMapFullCRC: Cardinal; //CRC of map for reporting stats to master server. Also used in MapEd
    fGameTick: Cardinal;
    fMissionMode: TKMissionMode;
    fMissionDifficulty: TKMMissionDifficulty;

    fUIDTracker: Cardinal;       //Units-Houses tracker, to issue unique IDs
    fMissionFileSP: UnicodeString; //Relative pathname to mission we are playing, so it gets saved to crashreport. SP only, see GetMissionFile.

    //Saved to local data
    fLastReplayTick: Cardinal;
    fSkipReplayEndCheck: Boolean;

    //DO not save
    fGameSpeedChangeTick: Single;
    fGameSpeedChangeTime: Cardinal; //time of last game speed change
    fPausedTicksCnt: Cardinal;

    fLastTimeUserAction: Cardinal;
    fLastAfkMessageSent: Cardinal;

    fReadyToStop: Boolean;
    fGameSeed: Integer;

    fLoadFromFile: UnicodeString; //Path to file, from which game was loaded. '.bas' file for replays

    fSaveWorkerThread: TKMWorkerThread;

    procedure GameMPDisconnect(const aData: UnicodeString);
    procedure OtherPlayerDisconnected(aDefeatedPlayerHandId: Integer);
    procedure MultiplayerRig(aNewGame: Boolean);
    procedure SaveGameToStream(aTimestamp: TDateTime; aSaveStream: TKMemoryStream);
    procedure SaveGameToFile(const aPathName: String; aTimestamp: TDateTime; const aMPLocalDataPathName: String = '');
    procedure UpdatePeaceTime;
    function GetWaitingPlayersList: TKMByteArray;
    function FindHandToSpec: Integer;
    procedure UpdateTickCounters;
    function GetTicksBehindCnt: Single;
    procedure SetIsPaused(aValue: Boolean);
    procedure IssueAutosaveCommand(aAfterPT: Boolean = False);

    function GetGameTickDuration: Single;
    procedure GameSpeedActualChanged(aFromSpeed, aToSpeed: Single);
    function GetControlledHandIndex: TKMHandID;
    procedure IncGameTick;
    procedure CheckPauseGameAtTick;
    function IsReplayEnded: Boolean;

    function PlayNextTick: Boolean;
    procedure UserAction(aActionType: TKMUserActionType);
    function GetReplayAutosaveEffectiveFrequency: Integer;

    function DoSaveRandomChecks: Boolean;
    function DoSaveGameAsText: Boolean;

    function GetMissionFile: UnicodeString;

    procedure SetGameSpeedActualValue(aSpeed: Single);
    procedure UpdateClockUI;
    function GetMapEditor: TKMMapEditor;

    function DoRenderGame: Boolean;
  public
    GameResult: TKMGameResultMsg;
    DoGameHold: Boolean; //Request to run GameHold after UpdateState has finished
    DoGameHoldState: TKMGameResultMsg; //The type of GameHold we want to occur due to DoGameHold

    StartedFromMapEditor: Boolean; //True if we start game from map editor ('Try Map')
    StartedFromMapEdAsMPMap: Boolean;     //True if we start game from map editor ('Try Map') with MP map

    constructor Create(aGameMode: TKMGameMode; aRender: TRender; aNetworking: TKMNetworking; aOnDestroy: TEvent);
    destructor Destroy; override;

    procedure GameStart(const aMissionFile, aGameName: UnicodeString; aFullCRC, aSimpleCRC: Cardinal; aCampaign: TKMCampaign;
                        aCampMap: Byte; aLocation: ShortInt; aColor: Cardinal; aMapDifficulty: TKMMissionDifficulty = mdNone;
                        aAIType: TKMAIType = aitNone; aAutoselectHumanLoc: Boolean = False);

    procedure AfterStart;
    procedure MapEdStartEmptyMap(aSizeX, aSizeY: Integer);
    procedure LoadFromStream(var LoadStream: TKMemoryStreamBinary);
    procedure LoadFromFile(const aPathName: UnicodeString; const aCustomReplayFile: UnicodeString = '');
    procedure LoadSavedReplay(aTick: Cardinal; const aSaveFile: UnicodeString);
    procedure AfterLoad;

    function MapSizeInfo: UnicodeString;

    procedure GameMPPlay(Sender: TObject);
    procedure GameMPReadyToPlay(Sender: TObject);
    procedure GameHold(aDoHold: Boolean; Msg: TKMGameResultMsg); //Hold the game to ask if player wants to play after Victory/Defeat/ReplayEnd
    procedure RequestGameHold(Msg: TKMGameResultMsg);
    procedure PlayerVictory(aHandIndex: TKMHandID);
    procedure PlayerDefeat(aPlayerIndex: TKMHandID; aShowDefeatMessage: Boolean = True);
    procedure WaitingPlayersDisplay(aWaiting: Boolean);
    procedure WaitingPlayersDrop;
    procedure ShowScriptError(const aMsg: UnicodeString);

    procedure AutoSave(aTimestamp: TDateTime);
    procedure AutoSaveAfterPT(aTimestamp: TDateTime);
    procedure SaveReplayToMemory();
    procedure SaveMapEditor(const aPathName: UnicodeString); overload;
    procedure SaveMapEditor(const aPathName: UnicodeString; const aInsetRect: TKMRect); overload;
    procedure RestartReplay; //Restart the replay but keep current viewport position/zoom

    property AIType: TKMAIType read fAIType;

    property IsExiting: Boolean read fIsExiting;
    property IsPaused: Boolean read fIsPaused write SetIsPaused;
    property ReadyToStop: Boolean read fReadyToStop write fReadyToStop;
    property DynamicFOW: Boolean read fDynamicFOW write fDynamicFOW;
    property BlockGetPointer: Boolean read fBlockGetPointer;
    function AllowGetPointer: Boolean;
    property MissionFile: UnicodeString read GetMissionFile;

    function MissionTime: TDateTime;
    function GetPeacetimeRemaining: TDateTime;
    function CheckTime(aTimeTicks: Cardinal): Boolean;
    function IsPeaceTime: Boolean;
    function IsMapEditor: Boolean;
    function IsCampaign: Boolean;
    function IsMultiPlayerOrSpec: Boolean;
    function IsMultiplayerGame: Boolean;
    function IsMultiplayer: Boolean;
    function IsReplay: Boolean;
    function IsReplayOrSpectate: Boolean;
    function IsSingleplayerGame: Boolean;
    function IsSingleplayer: Boolean;
    function IsNormalGame: Boolean;
    function IsSpeedUpAllowed: Boolean;
    function IsMPGameSpeedChangeAllowed: Boolean;

    function IsWareDistributionStoredBetweenGames: Boolean;

    function IsTactic: Boolean;
    function IsNormalMission: Boolean;

    property MapTxtInfo: TKMMapTxtInfo read fMapTxtInfo;
    procedure ShowMessage(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aHandIndex: TKMHandID);
    procedure ShowMessageLocal(aKind: TKMMessageKind; const aText: UnicodeString; const aLoc: TKMPoint);
    procedure OverlayUpdate;
    procedure OverlaySet(const aText: UnicodeString; aPlayer: Shortint);
    procedure OverlayAppend(const aText: UnicodeString; aPlayer: Shortint);
    property GameTick: Cardinal read fGameTick;
    property GameName: UnicodeString read fGameName;
    property CampaignName: TKMCampaignId read fCampaignName;
    property CampaignMap: Byte read fCampaignMap;
    property GameSpeedActual: Single read fGameSpeedActual;
    property GameSpeedGIP: Single read fGameSpeedGIP;
    property GameSpeedChangeAllowed: Boolean read fGameSpeedChangeAllowed write fGameSpeedChangeAllowed;
    property GameTickDuration: Single read GetGameTickDuration;
    property SavedReplays: TKMSavedReplays read fSavedReplays write fSavedReplays;

    function PlayerLoc: Byte; //Can used in SP game/replay only
    function PlayerColor: Cardinal; //Can used in SP game/replay only

    property ControlledHandIndex: TKMHandID read GetControlledHandIndex;

    property Scripting: TKMScripting read fScripting;
    property GameMode: TKMGameMode read fGameMode;
    property SaveFile: UnicodeString read fSaveFile;

    {$IFDEF RUNNER}
    procedure SetGameMode(aGameMode: TKMGameMode);
    {$ENDIF}

    function GetScriptSoundFile(const aSound: AnsiString; aAudioFormat: TKMAudioFormat): UnicodeString;
    property LastReplayTick: Cardinal read fLastReplayTick write fLastReplayTick;
    property SkipReplayEndCheck: Boolean read fSkipReplayEndCheck write fSkipReplayEndCheck;
    property IgnoreConsistencyCheckErrors: Boolean read fIgnoreConsistencyCheckErrors;

    property MissionMode: TKMissionMode read fMissionMode write fMissionMode;
    property MissionDifficulty: TKMMissionDifficulty read fMissionDifficulty write fMissionDifficulty;
    property GameLockedMutex: Boolean read fGameLockedMutex write fGameLockedMutex;

    function HasMissionDifficulty: Boolean;
    function GetNewUID: Integer;
    function GetNormalGameSpeed: Single;
    procedure StepOneFrame;

    procedure SetGameSpeed(aSpeed: Single); overload;
    procedure SetGameSpeed(aSpeed: Single; aToggle: Boolean); overload;
    procedure SetGameSpeed(aSpeed: Single; aToggle: Boolean; aToggleTo: Single); overload;

    procedure SetGameSpeedActual(aSpeed: Single);
    procedure SetGameSpeedGIP(aSpeed: Single; aUpdateActual: Boolean = False);

    class function SavePath(const aName: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;
    class function SaveName(const aFolder, aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString; overload;
    class function SaveName(const aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString; overload;

    procedure UpdateMultiplayerTeams;

    property Networking: TKMNetworking read fNetworking;
    property Pathfinding: TPathFinding read fPathfinding;
    property GameInputProcess: TKMGameInputProcess read fGameInputProcess write fGameInputProcess;
    property GameOptions: TKMGameOptions read fGameOptions;
    property ActiveInterface: TKMUserInterfaceGame read fActiveInterface;
    property GamePlayInterface: TKMGamePlayInterface read fGamePlayInterface;
    property MapEditorInterface: TKMapEdInterface read fMapEditorInterface;
    property MapEditor: TKMMapEditor read GetMapEditor;
    property TerrainPainter: TKMTerrainPainter read fTerrainPainter;
    property TextMission: TKMTextLibraryMulti read fTextMission;

    procedure SetSeed(aSeed: Integer);

    procedure Save(const aSaveName: UnicodeString); overload;
    procedure Save(const aSaveName: UnicodeString; aTimestamp: TDateTime); overload;

    function GetCurrectTickSaveCRC: Cardinal;
    {$IFDEF USE_MAD_EXCEPT}
    procedure AttachCrashReport(const ExceptIntf: IMEException; const aZipFile: UnicodeString);
    {$ENDIF}
    procedure ReplayInconsistancy(aCommand: TKMStoredGIPCommand; aMyRand: Cardinal);
    procedure SaveCampaignScriptData(SaveStream: TKMemoryStream);

    procedure Render(aRender: TRender);
    procedure UpdateGame(Sender: TObject);
    procedure UpdateState(aGlobalTickCount: Cardinal);
    procedure UpdateStateIdle(aFrameTime: Cardinal);
  end;


var
  gGame: TKMGame;


implementation
uses
  Classes, Controls, Dialogs, SysUtils, KromUtils, Math, TypInfo,
  {$IFDEF WDC} UITypes, {$ENDIF}
  KM_PathFindingAStarOld, KM_PathFindingAStarNew, KM_PathFindingJPS,
  KM_Projectiles, KM_AIFields,
  KM_Main, KM_GameApp, KM_RenderPool, KM_GameInfo, KM_GameClasses,
  KM_Terrain, KM_HandsCollection, KM_HandSpectator, KM_MapEditorHistory,
  KM_MissionScript, KM_MissionScript_Standard, KM_GameInputProcess_Multi, KM_GameInputProcess_Single,
  KM_Resource, KM_ResCursors, KM_ResSound, KM_InterfaceDefaults,
  KM_Log, KM_ScriptingEvents, KM_Saves, KM_FileIO, KM_CommonUtils, KM_RandomChecks, KM_DevPerfLog, KM_DevPerfLogTypes;

//Create template for the Game
//aRender - who will be rendering the Game session
//aNetworking - access to MP stuff
constructor TKMGame.Create(aGameMode: TKMGameMode; aRender: TRender; aNetworking: TKMNetworking; aOnDestroy: TEvent);
const
  UIMode: array[TKMGameMode] of TUIMode = (umSP, umSP, umMP, umSpectate, umSP, umReplay, umReplay);
begin
  inherited Create;

  fSaveWorkerThread := TKMWorkerThread.Create;

  {$IFDEF DEBUG}
  TThread.NameThreadForDebugging('SaveWorker', fSaveWorkerThread.ThreadID);
  {$ENDIF}

  fGameMode := aGameMode;
  fNetworking := aNetworking;
  fOnDestroy := aOnDestroy;

  fAdvanceFrame := False;
  fUIDTracker   := 0;
  GameResult   := grCancel;
  DoGameHold    := False;
  fSkipReplayEndCheck := False;
  fWaitingForNetwork := False;
  fGameOptions  := TKMGameOptions.Create;
  fMissionDifficulty := mdNone;
  fDynamicFOW := False;
  fGameSpeedChangeTick := 0;
  fGameSpeedChangeTime := 0;
  fGameSpeedChangeAllowed := True;
  fPausedTicksCnt := 0;
  fBlockGetPointer := False;
  fLastTimeUserAction := TimeGet;
  fLastAfkMessageSent := 0;
  fLoadFromFile := '';

  fTerrainPainter := TKMTerrainPainter.Create;

  fSavedReplays := TKMSavedReplays.Create;

  fMapTxtInfo := TKMMapTxtInfo.Create;

  //UserInterface is different between Gameplay and MapEd
  if (aRender = nil) then // Render can be nil if map is generated by Random Map Generator
  begin
    fMapEditorInterface := nil;
    fActiveInterface := nil;
  end
  else
  begin
    if (fGameMode = gmMapEd) then
    begin
      fMapEditorInterface := TKMapEdInterface.Create(aRender);
      fActiveInterface := fMapEditorInterface;
    end
    else
    begin
      fGamePlayInterface := TKMGamePlayInterface.Create(aRender, UIMode[fGameMode]);
      fGamePlayInterface.OnUserAction := UserAction;
      fActiveInterface := fGamePlayInterface;
    end;
  end;

  fTimerGame := TTimer.Create(nil);
  //pseudo GIP command, since we just want to initialize speed with default values
  SetGameSpeedGIP(GAME_SPEED_NORMAL, True);

  if not GAME_NO_UPDATE_ON_TIMER then
  begin
    fTimerGame.OnTimer := UpdateGame;
    fTimerGame.Enabled := True;
  end;

  fGameSpeedChangeTime := TimeGet;

  //Here comes terrain/mission init
  SetKaMSeed(4); //Every time the game will be the same as previous. Good for debug.
  gTerrain := TKMTerrain.Create;
  gHands := TKMHandsCollection.Create;
  gAIFields := TKMAIFields.Create;

  {$IFDEF PERFLOG}
  gPerfLogs.Clear;
  {$ENDIF}
  gLog.AddTime('<== Game creation is done ==>');

  gScriptSounds := TKMScriptSoundsManager.Create; //Currently only used by scripting
  fScripting := TKMScriptingCreator.CreateScripting(ShowScriptError);

  fIgnoreConsistencyCheckErrors := False;

  case PathFinderToUse of
    0:    fPathfinding := TPathfindingAStarOld.Create;
    1:    fPathfinding := TPathfindingAStarNew.Create;
    2:    fPathfinding := TPathfindingJPS.Create;
    else  fPathfinding := TPathfindingAStarOld.Create;
  end;
  gProjectiles := TKMProjectiles.Create;

  if gRandomCheckLogger <> nil then
  begin
    gRandomCheckLogger.Clear;
    gRandomCheckLogger.Enabled := not IsMapEditor and not IsReplay; //Disable random check logger for MapEditor
  end;

  gGameApp.GameSettings.PlayersColorMode := pcmDefault;

  fGameTick := 0; //Restart counter
end;


//Destroy what was created
destructor TKMGame.Destroy;
begin
  //We might have crashed part way through .Create, so we can't assume ANYTHING exists here.
  //Doing so causes a 2nd exception which overrides 1st. Hence check <> nil on everything except Frees, TObject.Free does that already.

  if fGameLockedMutex then gMain.UnlockMutex;
  if fTimerGame <> nil then fTimerGame.Enabled := False;
  fIsExiting := True;

  //if (fGameInputProcess <> nil) and (fGameInputProcess.ReplayState = gipRecording) then
  //  fGameInputProcess.SaveToFile(SaveName('basesave', EXT_SAVE_REPLAY, fGameMode in [gmMulti, gmMultiSpectate]));

  FreeAndNil(fTimerGame);

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

  //Could be nil, if want to reuse fGIP for other gGame instance (gGame could be recreated when jump between checkpoints in replay)
  if fSavedReplays <> nil then
    FreeAndNil(fSavedReplays);

  FreeThenNil(fGamePlayInterface);
  FreeThenNil(fMapEditorInterface);

  //Could be nil, if want to reuse fGIP for other gGame instance (gGame could be recreated when jump between checkpoints in replay)
  if fGameInputProcess <> nil then
    FreeAndNil(fGameInputProcess);

  FreeAndNil(fGameOptions);
  FreeAndNil(fTextMission);

  //When leaving the game we should always reset the cursor in case the user had beacon or linking selected
  gRes.Cursors.Cursor := kmcDefault;

  FreeAndNil(gMySpectator);

  if gRandomCheckLogger <> nil then
    gRandomCheckLogger.Clear;

  if Assigned(fOnDestroy) then
    fOnDestroy();

  //This will ensure all queued work is completed before destruction
  FreeAndNil(fSaveWorkerThread);

  inherited;
end;


function TKMGame.MapSizeInfo: UnicodeString;
begin
  Result := 'Map size: ' + IntToStr(gTerrain.MapX) + ' x ' + IntToStr(gTerrain.MapY);
end;


//New mission
procedure TKMGame.GameStart(const aMissionFile, aGameName: UnicodeString; aFullCRC, aSimpleCRC: Cardinal; aCampaign: TKMCampaign;
                            aCampMap: Byte; aLocation: ShortInt; aColor: Cardinal;
                            aMapDifficulty: TKMMissionDifficulty = mdNone; aAIType: TKMAIType = aitNone;
                            aAutoselectHumanLoc: Boolean = False);
const
  GAME_PARSE: array [TKMGameMode] of TKMMissionParsingMode = (
    mpmSingle, mpmSingle, mpmMulti, mpmMulti, mpmEditor, mpmSingle, mpmSingle);

  NO_OVERWRITE_COLOR = $00000000;
var
  I: Integer;
  ParseMode: TKMMissionParsingMode;
  PlayerEnabled: TKMHandEnabledArray;
  Parser: TKMMissionParserStandard;
  CampaignData: TKMemoryStreamBinary;
  CampaignDataTypeFile: UnicodeString;
begin
  gLog.AddTime('GameStart');
  Assert(fGameMode in [gmMulti, gmMultiSpectate, gmMapEd, gmSingle, gmCampaign]);

  gRes.Units.ResetToDefaults;
  gRes.Wares.ResetToDefaults;

  fGameName := aGameName;
  fGameMapSimpleCRC := aSimpleCRC;
  fGameMapFullCRC := aFullCRC;
  if aCampaign <> nil then
    fCampaignName := aCampaign.CampaignId
  else
    fCampaignName := NO_CAMPAIGN;
  fCampaignMap := aCampMap;
  fMissionDifficulty := aMapDifficulty;
  fAIType := aAIType;

  if IsMultiPlayerOrSpec then
    fMissionFileSP := '' //In MP map could be in DL or MP folder, so don't store path
  else
    fMissionFileSP := ExtractRelativePath(ExeDir, aMissionFile);

  fSaveFile := '';
  FreeAndNil(gMySpectator); //In case somebody looks at it while parsing DAT, e.g. destroyed houses

  gLog.AddTime('Loading DAT file: ' + aMissionFile);

  //Disable players in MP to skip their assets from loading by MissionParser
  //In SP all players are enabled by default
  case fGameMode of
    gmMulti, gmMultiSpectate:
              begin
                fNetworking.ResetPacketsStats;
                fDynamicFOW := fNetworking.NetGameFilter.DynamicFOW;
                FillChar(PlayerEnabled, SizeOf(PlayerEnabled), #0);
                for I := 1 to fNetworking.NetPlayers.Count do
                  if not fNetworking.NetPlayers[I].IsSpectator then
                    PlayerEnabled[fNetworking.NetPlayers[I].HandIndex] := True;

                //Fixed AIs are always enabled (e.g. coop missions)
                for I := 0 to fNetworking.MapInfo.LocCount - 1 do
                  if (fNetworking.MapInfo.CanBeAI[I] or fNetworking.MapInfo.CanBeAdvancedAI[I])
                    and not fNetworking.MapInfo.CanBeHuman[I] then
                    PlayerEnabled[I] := True;
              end;
    gmSingle, gmCampaign: //Setup should tell us which player is AI and which not
              for I := 0 to MAX_HANDS - 1 do
                PlayerEnabled[I] := True;
    else      FillChar(PlayerEnabled, SizeOf(PlayerEnabled), #255);
  end;

  //Choose how we will parse the script
  ParseMode := GAME_PARSE[fGameMode];

  if fGameMode = gmMapEd then
  begin
    //Mission loader needs to read the data into MapEd (e.g. FOW revealers)
    fMapEditor := TKMMapEditor.Create(fTerrainPainter, fMapEditorInterface.HistoryUndoRedo, fMapEditorInterface.HistoryAddCheckpoint);
    fMapEditor.DetectAttachedFiles(aMissionFile);
  end;

  Parser := TKMMissionParserStandard.Create(ParseMode, PlayerEnabled);
  try
    if not Parser.LoadMission(aMissionFile) then
      raise Exception.Create(Parser.FatalErrors);

    if fGameMode = gmMapEd then
    begin
      // Activate all players
      gHands.AddPlayers(MAX_HANDS - gHands.Count);

      for I := 0 to gHands.Count - 1 do
        gHands[I].FogOfWar.RevealEverything;

      gMySpectator := TKMSpectator.Create(0);
      gMySpectator.FOWIndex := PLAYER_NONE;
    end
    else
    if fGameMode in [gmSingle, gmCampaign] then
    begin
      for I := 0 to gHands.Count - 1 do
        gHands[I].HandType := hndComputer;

      // -1 means automatically detect the location (used for tutorials and campaigns)
      if aLocation = -1 then
        aLocation := Parser.DefaultLocation;

      //Try to autoselect player loc, if needed
      if aAutoselectHumanLoc
        and (not InRange(aLocation, 0, gHands.Count - 1)
             or not gHands[aLocation].Enabled) then
        begin
          for I := 0 to gHands.Count - 1 do
            if gHands[I].Enabled then
              aLocation := I;
          aColor := NO_OVERWRITE_COLOR; //Do not overwrite player color
        end;

      Assert(InRange(aLocation, 0, gHands.Count - 1), 'No human player detected');
      gHands[aLocation].HandType := hndHuman;
      gMySpectator := TKMSpectator.Create(aLocation);

      // If no color specified use default from mission file (don't overwrite it)
      if aColor <> NO_OVERWRITE_COLOR then
        gMySpectator.Hand.FlagColor := aColor;

      //Set Advanced AI for only advanced locs and if choosen Advanced AI in Single map setup  
      for I := 0 to gHands.Count - 1 do
        if (gHands[I].HandType = hndComputer) 
          and ((gHands[I].HandAITypes = [aitAdvanced])
            or ((gHands[I].HandAITypes = [aitClassic, aitAdvanced])
              and (aAIType = aitAdvanced))) then
            gHands[I].AI.Setup.EnableAdvancedAI

    end;

    if Parser.MinorErrors <> '' then
      if IsMapEditor then
        fMapEditorInterface.ShowMessage('Warnings in mission script:|' + Parser.MinorErrors)
      else
        fGamePlayInterface.MessageIssue(mkQuill, 'Warnings in mission script:|' + Parser.MinorErrors);

    if fGameMode <> gmMapEd then
    begin
      if aCampaign <> nil then
      begin
        CampaignData := aCampaign.ScriptData;
        CampaignData.Seek(0, soBeginning); //Seek to the beginning before we read it
        CampaignDataTypeFile := aCampaign.GetScriptDataTypeFile;
      end
      else
      begin
        CampaignData := nil;
        CampaignDataTypeFile := '';
      end;

      fScripting.LoadFromFile(ChangeFileExt(aMissionFile, '.script'), CampaignDataTypeFile, CampaignData);
      //fScripting reports compile errors itself now
    end;


    case fGameMode of
      gmMulti, gmMultiSpectate:
                begin
                  fGameInputProcess := TKMGameInputProcess_Multi.Create(gipRecording, fNetworking);
                  fTextMission := TKMTextLibraryMulti.Create;
                  fTextMission.LoadLocale(ChangeFileExt(aMissionFile, '.%s.libx'));
                end;
      gmSingle, gmCampaign:
                begin
                  fGameInputProcess := TKMGameInputProcess_Single.Create(gipRecording);
                  fTextMission := TKMTextLibraryMulti.Create;
                  fTextMission.LoadLocale(ChangeFileExt(aMissionFile, '.%s.libx'));
                end;
      gmMapEd:  ;
    end;

    gLog.AddTime('Gameplay recording initialized', True);

    if fGameMode in [gmMulti, gmMultiSpectate] then
      MultiplayerRig(True);

    //some late operations for parser (f.e. ProcessAttackPositions, which should be done after MultiplayerRig)
    Parser.PostLoadMission;
  finally
    Parser.Free;
  end;

  fMapTxtInfo.LoadTXTInfo(ChangeFileExt(aMissionFile, '.txt'));

  gLog.AddTime('Gameplay initialized', True);
end;


procedure TKMGame.AfterStart;
var
  I: Integer;
  ViewPos: TKMPointF;
begin
  gLog.AddTime('After game start');
  gHands.AfterMissionInit(fGameMode <> gmMapEd); //Don't flatten roads in MapEd

  //Random after StartGame and ViewReplay should match
  if IsMultiPlayerOrSpec then
    SetSeed(fNetworking.NetGameOptions.RandomSeed)
  else
    SetSeed(RandomRange(1, 2147483646));

  //We need to make basesave.bas since we don't know the savegame name
  //until after user saves it, but we need to attach replay base to it.
  //Basesave is sort of temp we save to HDD instead of keeping in RAM
  if fGameMode in [gmSingle, gmCampaign, gmMulti, gmMultiSpectate] then
    {$IFDEF PARALLEL_RUNNER}
      SaveGameToFile(SaveName('basesave_thread_'+IntToStr(THREAD_NUMBER), EXT_SAVE_BASE, IsMultiPlayerOrSpec), UTCNow);
    {$ELSE}
      SaveGameToFile(SaveName('basesave', EXT_SAVE_BASE, IsMultiPlayerOrSpec), UTCNow);
    {$ENDIF}

  if IsMapEditor then
  begin
    fMapEditor.History.Clear;
    fMapEditor.History.MakeCheckpoint(caAll, gResTexts[TX_MAPED_HISTORY_CHPOINT_INITIAL]);
  end;

  //MissionStart goes after basesave to keep it pure (repeats on Load of basesave)
  gScriptEvents.ProcMissionStart;

  //When everything is ready we can update UI
  fActiveInterface.SyncUI;
  if IsMapEditor then
  begin
    ViewPos := KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2);
    //Find first hand with assets and set viewport to its center screen
    for I := 0 to gHands.Count - 1 do
      if gHands[I].HasAssets then
      begin
        gMySpectator.HandID := I;
        ViewPos := KMPointF(gMySpectator.Hand.CenterScreen);
        Break;
      end;

    fActiveInterface.SyncUIView(ViewPos);
  end
  else
    fActiveInterface.SyncUIView(KMPointF(gMySpectator.Hand.CenterScreen));

  if fGamePlayInterface <> nil then
    fGamePlayInterface.GuiGameResultsMP.ResetControls;

  gLog.AddTime('After game ends', True);
end;


function TKMGame.FindHandToSpec: Integer;
var I: Integer;
    handIndex, humanPlayerHandIndex: TKMHandID;
begin
  //Find the 1st enabled human hand to be spectating initially.
  //If there is no enabled human hands, then find the 1st enabled hand
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


//All setup data gets taken from fNetworking class
procedure TKMGame.MultiplayerRig(aNewGame: Boolean);
var
  I: Integer;
  HIndex: TKMHandID;
begin
  //Copy game options from lobby to this game
  fGameOptions.Peacetime := fNetworking.NetGameOptions.Peacetime;
  fGameOptions.SpeedPT := fNetworking.NetGameOptions.SpeedPT;
  fGameOptions.SpeedAfterPT := fNetworking.NetGameOptions.SpeedAfterPT;

  if aNewGame then
    SetGameSpeed(GetNormalGameSpeed, True);

  //Check for default advanced AI's
  if fNetworking.IsMap then
    for I := 0 to fNetworking.MapInfo.LocCount - 1 do
      if fNetworking.MapInfo.CanBeAdvancedAI[I]
        and not fNetworking.MapInfo.CanBeAI[I]
        and not fNetworking.MapInfo.CanBeHuman[I] then
        gHands[I].AI.Setup.EnableAdvancedAI; //Just enable Advanced AI, do not override MapEd AI params

  //Assign existing NetPlayers(1..N) to map players(0..N-1)
  for I := 1 to fNetworking.NetPlayers.Count do
    if not fNetworking.NetPlayers[I].IsSpectator then
    begin
      HIndex := fNetworking.NetPlayers[I].HandIndex;
      gHands[HIndex].HandType := fNetworking.NetPlayers[I].GetPlayerType;
      gHands[HIndex].FlagColor := fNetworking.NetPlayers[I].FlagColor;

      if fNetworking.NetPlayers[I].IsComputer then
      begin
        //For MP locs we will set AI MP setup only when loc is allowed for humans too.
        //For only AI locs there we should use AI params set from MapEd
        if gHands[HIndex].CanBeHuman then
          gHands[HIndex].AI.Setup.ApplyMultiplayerSetup(fNetworking.NetPlayers[I].IsAdvancedComputer)
        else
          //Just enable Advanced AI, do not override MapEd AI params
          gHands[HIndex].AI.Setup.EnableAdvancedAI(fNetworking.NetPlayers[I].IsAdvancedComputer);
      end
      else
      //We can start to play for defeated hand, f.e. if player just left the game and we restart from save with other player
      if fNetworking.NetPlayers[I].IsHuman and gHands[HIndex].AI.HasLost then
      begin
        gHands[HIndex].AI.ResetWonOrLost; //Reset WonOrLost status
        gHands.UpdateGoalsForHand(HIndex, True); //Enable this hand goals for all other hands
      end;

      //In saves players can be changed to AIs, which needs to be stored in the replay
      if fNetworking.SelectGameKind = ngkSave then
        TKMGameInputProcess_Multi(GameInputProcess).PlayerTypeChange(HIndex, gHands[HIndex].HandType);

      //Set owners name so we can write it into savegame/replay
      gHands[HIndex].SetOwnerNikname(fNetworking.NetPlayers[I].Nikname);
    end;

  //Find enabled human hands, where if there is no net player on that loc
  //then disable all goals with this hand for other hands
  for I := 0 to gHands.Count - 1 do
  begin
    if gHands[I].Enabled and gHands[I].IsHuman then
    begin
      if fNetworking.NetPlayers.PlayerIndexToLocal(I) = -1 then
        gHands.UpdateGoalsForHand(I, False);
    end;
  end;


  //Setup alliances
  //We mirror Lobby team setup on to alliances. Savegame and coop has the setup already
  if (fNetworking.SelectGameKind = ngkMap) and not fNetworking.MapInfo.TxtInfo.BlockTeamSelection then
    UpdateMultiplayerTeams;

  FreeAndNil(gMySpectator); //May have been created earlier
  if fNetworking.MyNetPlayer.IsSpectator then
  begin
    gMySpectator := TKMSpectator.Create(FindHandToSpec);
    gMySpectator.FOWIndex := PLAYER_NONE; //Show all by default while spectating
  end
  else
    gMySpectator := TKMSpectator.Create(fNetworking.MyNetPlayer.HandIndex);

  //We cannot remove a player from a save (as they might be interacting with other players)

  //FOW should never be synced for saves, it should be left like it was when the save was
  //created otherwise it can cause issues in special maps using PlayerShareFog
  if fNetworking.SelectGameKind <> ngkSave then
    gHands.SyncFogOfWar; //Syncs fog of war revelation between players AFTER alliances

  //Multiplayer missions don't have goals yet, so add the defaults (except for special/coop missions)
  if (fNetworking.SelectGameKind = ngkMap)
    and not fNetworking.MapInfo.TxtInfo.IsSpecial
    and not fNetworking.MapInfo.TxtInfo.IsCoop then
    gHands.AddDefaultGoalsToAll(fMissionMode);

  fNetworking.OnPlay           := GameMPPlay;
  fNetworking.OnReadyToPlay    := GameMPReadyToPlay;
  fNetworking.OnCommands       := TKMGameInputProcess_Multi(fGameInputProcess).RecieveCommands;
  fNetworking.OnTextMessage    := fGamePlayInterface.ChatMessage;
  fNetworking.OnPlayersSetup   := fGamePlayInterface.AlliesOnPlayerSetup;
  fNetworking.OnPingInfo       := fGamePlayInterface.AlliesOnPingInfo;
  fNetworking.OnDisconnect     := GameMPDisconnect; //For auto reconnecting
  fNetworking.OnJoinerDropped := OtherPlayerDisconnected;
  fNetworking.OnUpdateMinimap := nil;
  fNetworking.OnReassignedHost := nil; //Reset Lobby OnReassignedHost
  fNetworking.OnReassignedJoiner := nil; //So it is no longer assigned to a lobby event
  fNetworking.GameCreated;

  if fNetworking.Connected and (fNetworking.NetGameState = lgsLoading) then
    WaitingPlayersDisplay(True); //Waiting for players
end;


procedure TKMGame.UpdateMultiplayerTeams;
var
  I, K: Integer;
  PlayerI: TKMHand;
  PlayerK: Integer;
begin
  for I := 1 to fNetworking.NetPlayers.Count do
    if not fNetworking.NetPlayers[I].IsSpectator then
    begin
      PlayerI := gHands[fNetworking.NetPlayers[I].HandIndex];
      for K := 1 to fNetworking.NetPlayers.Count do
        if not fNetworking.NetPlayers[K].IsSpectator then
        begin
          PlayerK := fNetworking.NetPlayers[K].HandIndex;

          //Players are allies if they belong to same team (team 0 means free-for-all)
          if (I = K)
          or ((fNetworking.NetPlayers[I].Team <> 0)
          and (fNetworking.NetPlayers[I].Team = fNetworking.NetPlayers[K].Team)) then
            PlayerI.Alliances[PlayerK] := atAlly
          else
            PlayerI.Alliances[PlayerK] := atEnemy;
        end;
    end;
end;


//Everyone is ready to start playing
//Issued by fNetworking at the time depending on each Players lag individually
procedure TKMGame.GameMPPlay(Sender: TObject);
begin
  WaitingPlayersDisplay(False); //Finished waiting for players
  fNetworking.AnnounceGameInfo(MissionTime, GameName);
  gLog.AddTime('Net game began');
end;


procedure TKMGame.GameMPReadyToPlay(Sender: TObject);
begin
  //Update the list of players that are ready to play
  WaitingPlayersDisplay(True);
end;


procedure TKMGame.OtherPlayerDisconnected(aDefeatedPlayerHandId: Integer);
begin
  gGame.GameInputProcess.CmdGame(gicGamePlayerDefeat, aDefeatedPlayerHandId);
end;


procedure TKMGame.GameMPDisconnect(const aData: UnicodeString);
begin
  if fNetworking.NetGameState in [lgsGame, lgsReconnecting] then
  begin
    gLog.LogNetConnection('GameMPDisconnect: ' + aData);
    fNetworking.OnJoinFail := GameMPDisconnect; //If the connection fails (e.g. timeout) then try again
    fNetworking.OnJoinAssignedHost := nil;
    fNetworking.OnJoinSucc := nil;
    fNetworking.AttemptReconnection;
  end
  else
  begin
    fNetworking.Disconnect;
    gGameApp.StopGame(grDisconnect, gResTexts[TX_GAME_ERROR_NETWORK] + ' ' + aData)
  end;
end;


{$IFDEF USE_MAD_EXCEPT}
procedure TKMGame.AttachCrashReport(const ExceptIntf: IMEException; const aZipFile: UnicodeString);

  procedure AttachFile(const aFile: UnicodeString);
  begin
    if (aFile = '') or not FileExists(aFile) then Exit;
    ExceptIntf.AdditionalAttachments.Add(aFile, '', aZipFile);
  end;

var I: Integer;
    MissionFile, Path: UnicodeString;
    SearchRec: TSearchRec;
begin
  gLog.AddTime('Creating crash report...');

  //Attempt to save the game, but if the state is too messed up it might fail
  try
    if (fGameMode in [gmSingle, gmCampaign, gmMulti, gmMultiSpectate])
      and not (fGamePlayInterface.UIMode = umReplay) then //In case game mode was altered or loaded with logical error
    begin
      Save('crashreport', UTCNow);
      AttachFile(SaveName('crashreport', EXT_SAVE_MAIN, IsMultiPlayerOrSpec));
//      AttachFile(SaveName('crashreport', EXT_SAVE_MAIN_TXT, IsMultiPlayerOrSpec)); //Todo Debug. remove before release
      AttachFile(SaveName('crashreport', EXT_SAVE_BASE, IsMultiPlayerOrSpec));
      AttachFile(SaveName('crashreport', EXT_SAVE_REPLAY, IsMultiPlayerOrSpec));
      AttachFile(SaveName('crashreport', EXT_SAVE_MP_LOCAL, IsMultiPlayerOrSpec));
      AttachFile(SaveName('crashreport', EXT_SAVE_RNG_LOG, IsMultiPlayerOrSpec));
    end;
  except
    on E : Exception do
      gLog.AddTime('Exception while trying to save game for crash report: ' + E.ClassName + ': ' + E.Message);
  end;

  MissionFile := GetMissionFile;
  Path := ExtractFilePath(ExeDir + MissionFile);

  AttachFile(ExeDir + MissionFile);
  AttachFile(ExeDir + ChangeFileExt(MissionFile, '.map')); //Try to attach the map

  //Try to add main script file and all other scripts, because they could be included
  if FileExists(ExeDir + ChangeFileExt(MissionFile, '.script')) then
  begin
    FindFirst(Path + '*.script', faAnyFile - faDirectory, SearchRec);
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          AttachFile(Path + SearchRec.Name);
      until (FindNext(SearchRec) <> 0);
    finally
      FindClose(SearchRec);
    end;
  end;

  if (fGameMode in [gmReplaySingle, gmReplayMulti])
    or (fGamePlayInterface.UIMode = umReplay) then //In case game mode was altered or loaded with logical error
  begin
    //For replays attach only replay save files
    AttachFile(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_BASE_DOT));
    AttachFile(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_REPLAY_DOT));
    AttachFile(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_MAIN_DOT));
//    AttachFile(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_MAIN_TXT_DOT)); //Todo Debug. remove before release
    AttachFile(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_MP_LOCAL_DOT));
  end else if (fGameMode <> gmMapEd) then // no need autosaves for MapEd error...
    //For other game modes attach last autosaves
    for I := 1 to Min(gGameApp.GameSettings.AutosaveCount, AUTOSAVE_ATTACH_TO_CRASHREPORT_MAX) do //Add autosaves
    begin
      AttachFile(SaveName('autosave' + Int2Fix(I, 2), EXT_SAVE_REPLAY, IsMultiPlayerOrSpec));
      AttachFile(SaveName('autosave' + Int2Fix(I, 2), EXT_SAVE_BASE, IsMultiPlayerOrSpec));
      AttachFile(SaveName('autosave' + Int2Fix(I, 2), EXT_SAVE_MAIN, IsMultiPlayerOrSpec));
//      AttachFile(SaveName('autosave' + Int2Fix(I, 2), EXT_SAVE_MAIN_TXT, IsMultiPlayerOrSpec)); //Todo Debug. remove before release
      AttachFile(SaveName('autosave' + Int2Fix(I, 2), EXT_SAVE_MP_LOCAL, IsMultiPlayerOrSpec));
      AttachFile(SaveName('autosave' + Int2Fix(I, 2), EXT_SAVE_RNG_LOG, IsMultiPlayerOrSpec));
    end;

  gLog.AddTime('Crash report created');
end;
{$ENDIF}


//Occasional replay inconsistencies are a known bug, we don't need reports of it
procedure TKMGame.ReplayInconsistancy(aCommand: TKMStoredGIPCommand; aMyRand: Cardinal);
const
  TRY_KAM_RANDOM_CNT = 20;
var
  I: Integer;
  TempSeedI, TempSeedF: Integer;
  ValI: Integer;
  ValF: Double;
begin
  gLog.AddTime('Replay failed a consistency check at tick ' + IntToStr(fGameTick));
  gLog.AddTime(Format('MyRand = %d, but command: %s', [aMyRand, TKMGameInputProcess.StoredGIPCommandToString(aCommand)]));
  if gLog.CanLogRandomChecks() then
  begin
    gLog.LogRandomChecks('Next KaMRandom values are: ');
    TempSeedI := GetKaMSeed;
    TempSeedF := GetKaMSeed;
    for I := 0 to TRY_KAM_RANDOM_CNT - 1 do
    begin
      ValI := KaMRandomWSeed(TempSeedI, MaxInt);
      ValF := KaMRandomWSeed(TempSeedF);
      gLog.LogRandomChecks(Format('%d: KaMRandomI: %30d', [I+1, ValI]));
      gLog.LogRandomChecks(Format('%d: KaMRandomF: %30s', [I+1, FormatFloat('0.##############################', ValF)]));
      if ValI = aMyRand then
        gLog.LogRandomChecks('Find match with MyRand !!!');
    end;
  end;

  if not fIgnoreConsistencyCheckErrors then
  begin
    //Stop game from executing while the user views the message
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


//Put the game on Hold for Victory screen
procedure TKMGame.GameHold(aDoHold: Boolean; Msg: TKMGameResultMsg);
begin
  DoGameHold := False;
  fGamePlayInterface.ReleaseDirectionSelector; //In case of victory/defeat while moving troops
  gRes.Cursors.Cursor := kmcDefault;

  fGamePlayInterface.Viewport.ReleaseScrollKeys;
  GameResult := Msg;

  if aDoHold then
  begin
    fIsPaused := True;
    fGamePlayInterface.ShowPlayMore(True, Msg);
  end else
    fIsPaused := False;
end;


procedure TKMGame.RequestGameHold(Msg: TKMGameResultMsg);
begin
  DoGameHold := true;
  DoGameHoldState := Msg;
end;


procedure TKMGame.PlayerVictory(aHandIndex: TKMHandID);
begin
  if IsMultiPlayerOrSpec then
  begin
    if fNetworking.NetPlayers.PlayerIndexToLocal(aHandIndex) = -1 then
      Exit;
      
    fNetworking.PostLocalMessage(
      Format(gResTexts[TX_MULTIPLAYER_PLAYER_WON], [gHands[aHandIndex].GetOwnerNameColoredU]),
      csSystem);

    if Assigned(fNetworking.OnPlayersSetup) then
      fNetworking.OnPlayersSetup(nil); //Update players panel
  end;

  if fGameMode = gmMultiSpectate then
    Exit;

  if aHandIndex = gMySpectator.HandID then
    gSoundPlayer.Play(sfxnVictory, 1, True); //Fade music

  if fGameMode = gmMulti then
  begin
    if aHandIndex = gMySpectator.HandID then
    begin
      GameResult := grWin;
      fGamePlayInterface.ShowMPPlayMore(grWin);
    end;
  end
  else
    RequestGameHold(grWin);
end;


function TKMGame.PlayerLoc: Byte;
begin
  Result := gMySpectator.HandID;
end;


//Wrap for GameApp to access player color (needed for restart mission)
function TKMGame.PlayerColor: Cardinal;
begin
  Result := gMySpectator.Hand.FlagColor;
end;


procedure TKMGame.PlayerDefeat(aPlayerIndex: TKMHandID; aShowDefeatMessage: Boolean = True);
begin
  case GameMode of
    gmSingle, gmCampaign:
              if aPlayerIndex = gMySpectator.HandID then
              begin
                gSoundPlayer.Play(sfxnDefeat, 1, True); //Fade music
                RequestGameHold(grDefeat);
              end;
    gmMulti:  begin
                if aShowDefeatMessage then
                  fNetworking.PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_PLAYER_DEFEATED],
                                                      [gHands[aPlayerIndex].GetOwnerNameColoredU]), csSystem);

                if aPlayerIndex = gMySpectator.HandID then
                begin
                  gSoundPlayer.Play(sfxnDefeat, 1, True); //Fade music
                  GameResult := grDefeat;
                  fGamePlayInterface.ShowMPPlayMore(grDefeat);
                end;

                if Assigned(fNetworking.OnPlayersSetup) then
                  fNetworking.OnPlayersSetup(nil); //Update players panel

              end;
    gmMultiSpectate:
              begin
                if aShowDefeatMessage then
                  fNetworking.PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_PLAYER_DEFEATED],
                                                      [gHands[aPlayerIndex].GetOwnerNameColoredU]), csSystem);

                if Assigned(fNetworking.OnPlayersSetup) then
                  fNetworking.OnPlayersSetup(nil); //Update players panel
              end;
    //We have not thought of anything to display on players defeat in Replay
  end;
end;


//Get list of players we are waiting for. We do it here because fNetworking does not knows about GIP
function TKMGame.GetWaitingPlayersList: TKMByteArray;
var
  ErrorMsg: UnicodeString;
begin
  case fNetworking.NetGameState of
    lgsGame, lgsReconnecting:
        //GIP is waiting for next tick
        Result := TKMGameInputProcess_Multi(fGameInputProcess).GetWaitingPlayers(fGameTick + 1);
    lgsLoading:
        //We are waiting during inital loading
        Result := fNetworking.NetPlayers.GetNotReadyToPlayPlayers;
    else  begin
            SetLength(Result, 0);
            ErrorMsg := 'GetWaitingPlayersList from wrong state: '
                       + GetEnumName(TypeInfo(TKMNetGameState), Integer(fNetworking.NetGameState));
            gLog.AddTime(ErrorMsg);
            //raise Exception.Create(ErrorMsg); //This error sometimes occur when host quits, but that's not critical, so we can just log it
          end;
  end;
end;


procedure TKMGame.WaitingPlayersDisplay(aWaiting: Boolean);
begin
  fWaitingForNetwork := aWaiting;
  fGamePlayInterface.ShowNetworkLag(aWaiting, GetWaitingPlayersList, fNetworking.IsHost);
end;


procedure TKMGame.WaitingPlayersDrop;
begin
  fNetworking.DropPlayers(GetWaitingPlayersList);
end;


//Start MapEditor (empty map)
procedure TKMGame.MapEdStartEmptyMap(aSizeX, aSizeY: Integer);
var
  I: Integer;
begin
  fGameName := gResTexts[TX_MAPED_NEW_MISSION];

  fMissionFileSP := '';
  fSaveFile := '';

  fMapEditor := TKMMapEditor.Create(fTerrainPainter, fMapEditorInterface.HistoryUndoRedo, fMapEditorInterface.HistoryAddCheckpoint);
  fMapEditor.MissionDefSavePath := fGameName + '.dat';
  gTerrain.MakeNewMap(aSizeX, aSizeY, True);
  fTerrainPainter.InitEmpty;
  fMapEditor.History.MakeCheckpoint(caAll, gResTexts[TX_MAPED_HISTORY_CHPOINT_INITIAL]);
  fMapEditor.IsNewMap := True;

  gHands.AddPlayers(MAX_HANDS); //Create MAX players
  gHands[0].HandType := hndHuman; //Make Player1 human by default
  for I := 0 to gHands.Count - 1 do
  begin
    gHands[I].FogOfWar.RevealEverything;
    gHands[I].CenterScreen := KMPoint(aSizeX div 2, aSizeY div 2);
  end;

  gMySpectator := TKMSpectator.Create(0);
  gMySpectator.FOWIndex := PLAYER_NONE;

  gHands.AfterMissionInit(false);

  if fGameMode in [gmSingle, gmCampaign] then
    fGameInputProcess := TKMGameInputProcess_Single.Create(gipRecording);

  //When everything is ready we can update UI
  if (fActiveInterface <> nil) then // fActiveInterface can be nil if map is generated by Random map generator
  begin
    fActiveInterface.SyncUI;
    fActiveInterface.SyncUIView(KMPointF(gTerrain.MapX / 2, gTerrain.MapY / 2));
  end;

  gLog.AddTime('Gameplay initialized', True);
end;


procedure TKMGame.AutoSaveAfterPT(aTimestamp: TDateTime);
begin
  Save('autosave_after_pt_end', aTimestamp);
end;


procedure DoAutoSaveRename(aIsMultiPlayerOrSpec: Boolean);
var
  I: Integer;
begin
  //Delete last autosave
  KMDeleteFolder(TKMGame.SavePath('autosave' + Int2Fix(gGameApp.GameSettings.AutosaveCount, 2), aIsMultiPlayerOrSpec));

  //Shift remaining autosaves by 1 position back
  for I := gGameApp.GameSettings.AutosaveCount downto 2 do // 03 to 01
    KMMoveFolder(TKMGame.SavePath('autosave' + Int2Fix(I - 1, 2), aIsMultiPlayerOrSpec), TKMGame.SavePath('autosave' + Int2Fix(I, 2), aIsMultiPlayerOrSpec));

  //Rename temp to be first in list
  KMMoveFolder(TKMGame.SavePath('autosave', aIsMultiPlayerOrSpec), TKMGame.SavePath('autosave01', aIsMultiPlayerOrSpec));
end;


procedure TKMGame.AutoSave(aTimestamp: TDateTime);
{$IFDEF WDC}
var
  LocalIsMultiPlayerOrSpec: Boolean;
{$ENDIF}
begin
  Save('autosave', aTimestamp); //Save to temp file

  //If possible perform file deletion/renaming in a different thread so we don't delay game
  {$IFDEF WDC}
    //Avoid accessing Self from async thread, copy required states to local variables
    LocalIsMultiPlayerOrSpec := IsMultiPlayerOrSpec;
    fSaveWorkerThread.QueueWork(procedure
    begin
      DoAutoSaveRename(LocalIsMultiPlayerOrSpec);
    end);
  {$ELSE}
    DoAutoSaveRename(IsMultiPlayerOrSpec);
  {$ENDIF}
end;


procedure TKMGame.SaveMapEditor(const aPathName: UnicodeString);
begin
  SaveMapEditor(aPathName, KMRECT_ZERO);
end;


//aPathName - full path to DAT file
procedure TKMGame.SaveMapEditor(const aPathName: UnicodeString; const aInsetRect: TKMRect);
var
  I: Integer;
  fMissionParser: TKMMissionParserStandard;
  MapInfo: TKMapInfo;
  MapFolder: TKMapFolder;
begin
  if aPathName = '' then exit;

  // Prepare and save

  // Remove assets out of map bounds first (units / houses)
  // Those 'fake' assets, that will not be loaded could affectsaved assets,
  // F.e. if we have 'fake' first storehouse, then commands will add second storehouse as a second one
  // and its wares will be corrupted
  gHands.RemoveAssetsOutOfBounds(aInsetRect);
  gHands.RemoveEmptyPlayers;

  ForceDirectories(ExtractFilePath(aPathName));
  gLog.AddTime('Saving from map editor: ' + aPathName);

  fMapEditor.MissionDefSavePath := aPathName;
  fMapEditor.SaveAttachements(aPathName);
  fMapTxtInfo.SaveTXTInfo(ChangeFileExt(aPathName, '.txt'));
  gTerrain.SaveToFile(ChangeFileExt(aPathName, '.map'), aInsetRect);
  fTerrainPainter.SaveToFile(ChangeFileExt(aPathName, '.map'), aInsetRect);
  fMissionParser := TKMMissionParserStandard.Create(mpmEditor);
  fMissionParser.SaveDATFile(ChangeFileExt(aPathName, '.dat'), aInsetRect.Left, aInsetRect.Top);
  FreeAndNil(fMissionParser);

  // Update GameSettings for saved maps positions in list on MapEd menu
  if DetermineMapFolder(GetFileDirName(ExtractFileDir(aPathName)), MapFolder) then
  begin
    // Update GameSettings for saved maps positions in list on MapEd menu
    MapInfo := TKMapInfo.Create(GetFileDirName(aPathName), True, MapFolder); //Force recreate map CRC
    case MapInfo.MapFolder of
      mfSP:       begin
                    gGameApp.GameSettings.MenuMapEdSPMapCRC := MapInfo.MapAndDatCRC;
                    gGameApp.GameSettings.MenuMapEdMapType := 0;
                    // Update saved SP game list saved selected map position CRC if we resave this map
                    if fGameMapSimpleCRC = gGameApp.GameSettings.MenuSPScenarioMapCRC then
                      gGameApp.GameSettings.MenuSPScenarioMapCRC := MapInfo.MapAndDatCRC;
                    if fGameMapSimpleCRC = gGameApp.GameSettings.MenuSPMissionMapCRC then
                      gGameApp.GameSettings.MenuSPMissionMapCRC := MapInfo.MapAndDatCRC;
                    if fGameMapSimpleCRC = gGameApp.GameSettings.MenuSPTacticMapCRC then
                      gGameApp.GameSettings.MenuSPTacticMapCRC := MapInfo.MapAndDatCRC;
                    if fGameMapSimpleCRC = gGameApp.GameSettings.MenuSPSpecialMapCRC then
                      gGameApp.GameSettings.MenuSPSpecialMapCRC := MapInfo.MapAndDatCRC;
                  end;
      mfMP:       begin
                    gGameApp.GameSettings.MenuMapEdMPMapCRC := MapInfo.MapAndDatCRC;
                    gGameApp.GameSettings.MenuMapEdMPMapName := MapInfo.FileName;
                    gGameApp.GameSettings.MenuMapEdMapType := 1;
                  end;
      mfDL:       begin
                    gGameApp.GameSettings.MenuMapEdDLMapCRC := MapInfo.MapAndDatCRC;
                    gGameApp.GameSettings.MenuMapEdMapType := 2;
                  end;
    end;
    // Update favorite map CRC if we resave favourite map with the same name
    if fGameName = MapInfo.FileName then
    begin
      gGameApp.GameSettings.FavouriteMaps.Replace(fGameMapSimpleCRC, MapInfo.MapAndDatCRC);
      gGameApp.GameSettings.ServerMapsRoster.Replace(fGameMapFullCRC, MapInfo.CRC);
    end;
    MapInfo.Free;
  end;

  fGameName := TruncateExt(ExtractFileName(aPathName));
  fMissionFileSP := ExtractRelativePath(ExeDir, aPathName);

  //Append empty players in place of removed ones
  gHands.AddPlayers(MAX_HANDS - gHands.Count);
  for I := 0 to gHands.Count - 1 do
    gHands[I].FogOfWar.RevealEverything;
end;


procedure TKMGame.Render(aRender: TRender);
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psFrameFullC);
  {$ENDIF}
  try
    if DoRenderGame then
      gRenderPool.Render;

    aRender.SetRenderMode(rm2D);
    fActiveInterface.Paint;

  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psFrameFullC);
    {$ENDIF}
  end;
end;


procedure TKMGame.RestartReplay;
begin
  gGameApp.NewReplay(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_BASE_DOT));
end;


function TKMGame.GetMapEditor: TKMMapEditor;
begin
  if Self = nil then Exit(nil);

  Result := fMapEditor;
end;


function TKMGame.GetMissionFile: UnicodeString;
begin
  if not IsMultiplayer then
    Result := fMissionFileSP //In SP we store it
  else
    //In MP we can't store it since it will be MapsMP or MapsDL on different clients
    Result := TKMapsCollection.GuessMPPath(fGameName, '.dat', fGameMapFullCRC);
end;


function TKMGame.GetScriptSoundFile(const aSound: AnsiString; aAudioFormat: TKMAudioFormat): UnicodeString;
var Ext: UnicodeString;
begin
  case aAudioFormat of
    afWav: Ext := WAV_FILE_EXT;
    afOgg: Ext := OGG_FILE_EXT;
  end;
  Result := ChangeFileExt(GetMissionFile, '.' + UnicodeString(aSound) + Ext)
end;


//TDateTime stores days/months/years as 1 and hours/minutes/seconds as fractions of a 1
//Treat 10 ticks as 1 sec irregardless of user-set pace
function TKMGame.MissionTime: TDateTime;
begin
  //Convert cardinal into TDateTime, where 1hour = 1/24 and so on..
  Result := fGameTick / 24 / 60 / 60 / 10;
end;


function TKMGame.GetPeacetimeRemaining: TDateTime;
begin
  Result := Max(0, Int64(fGameOptions.Peacetime * 600) - fGameTick) / 24 / 60 / 60 / 10;
end;


//Tests whether time has past
function TKMGame.CheckTime(aTimeTicks: Cardinal): Boolean;
begin
  Result := (fGameTick >= aTimeTicks);
end;


function TKMGame.IsMapEditor: Boolean;
begin
  Result := fGameMode = gmMapEd;
end;


function TKMGame.IsCampaign: Boolean;
begin
  Result := fGameMode = gmCampaign;
end;


function TKMGame.IsSpeedUpAllowed: Boolean;
begin
  Result := not IsMultiPlayerOrSpec or IsMPGameSpeedChangeAllowed;
end;


function TKMGame.IsMPGameSpeedChangeAllowed: Boolean;
begin
  Result := (fGameMode in [gmMulti, gmMultiSpectate])
        and (fNetworking.NetPlayers.GetNotDroppedCount = 1);
end;


function TKMGame.IsWareDistributionStoredBetweenGames: Boolean;
begin
  Result := IsNormalMission //No need to store ware distribution for Tactic mission
            and gGameApp.GameSettings.SaveWareDistribution //If "save ware distribution" is ON
            and (fGameMode in [gmSingle, gmCampaign, gmMulti]); //Not for Replay / MapEd
end;


function TKMGame.IsTactic: Boolean;
begin
  Result := fMissionMode = mmTactic;
end;


function TKMGame.IsNormalMission: Boolean;
begin
  Result := fMissionMode = mmNormal;
end;


function TKMGame.IsMultiplayerGame: Boolean;
begin
  Result := fGameMode = gmMulti;
end;


// We often need to see if game is MP
function TKMGame.IsMultiPlayerOrSpec: Boolean;
begin
  Result := fGameMode in [gmMulti, gmMultiSpectate];
end;


function TKMGame.IsMultiplayer: Boolean;
begin
  Result := fGameMode in [gmMulti, gmMultiSpectate, gmReplayMulti];
end;


function TKMGame.IsSingleplayerGame: Boolean;
begin
  Result := fGameMode in [gmSingle, gmCampaign];
end;


function TKMGame.IsSingleplayer: Boolean;
begin
  Result := fGameMode in [gmSingle, gmCampaign, gmReplaySingle];
end;


function TKMGame.IsNormalGame: Boolean;
begin
  Result := fGameMode in [gmSingle, gmCampaign, gmMulti];
end;


function TKMGame.IsReplay: Boolean;
begin
  Result := fGameMode in [gmReplaySingle, gmReplayMulti];
end;


function TKMGame.IsReplayOrSpectate: Boolean;
begin
  Result := fGameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti];
end;


procedure TKMGame.ShowMessage(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aHandIndex: TKMHandID);
begin
  //Once you have lost no messages can be received
  if gHands[aHandIndex].AI.HasLost then Exit;

  //Store it in hand so it can be included in MP save file
  gHands[aHandIndex].MessageLog.Add(aKind, aTextID, aLoc);

  //Don't play sound in replays or spectator
  if (aHandIndex = gMySpectator.HandID) and (fGameMode in [gmSingle, gmCampaign, gmMulti]) then
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
  fGamePlayInterface.SetScriptedOverlay(fOverlayText[gMySpectator.HandID]);
  fGamePlayInterface.UpdateOverlayControls;
end;


procedure TKMGame.OverlaySet(const aText: UnicodeString; aPlayer: Shortint);
var
  I: Integer;
begin
  if aPlayer = PLAYER_NONE then
    for I := 0 to MAX_HANDS do
      fOverlayText[I] := aText
  else
    fOverlayText[aPlayer] := aText;

  OverlayUpdate;
end;


procedure TKMGame.OverlayAppend(const aText: UnicodeString; aPlayer: Shortint);
var
  I: Integer;
begin
  if aPlayer = PLAYER_NONE then
    for I := 0 to MAX_HANDS do
      fOverlayText[I] := fOverlayText[I] + aText
  else
    fOverlayText[aPlayer] := fOverlayText[aPlayer] + aText;

  OverlayUpdate;
end;


function TKMGame.IsPeaceTime: Boolean;
begin
  Result := not CheckTime(fGameOptions.Peacetime * 600);
end;


procedure TKMGame.UpdatePeaceTime;
var
  PeaceTicksRemaining: Cardinal;
begin
  PeaceTicksRemaining := Max(0, Int64((fGameOptions.Peacetime * 600)) - fGameTick);
  if (PeaceTicksRemaining = 1) and (fGameMode in [gmMulti, gmMultiSpectate, gmReplayMulti]) then
  begin
    gSoundPlayer.Play(sfxnPeacetime, 1, True); //Fades music
    if fGameMode in [gmMulti, gmMultiSpectate] then
    begin
      SetGameSpeed(fGameOptions.SpeedAfterPT, False);
      fNetworking.PostLocalMessage(gResTexts[TX_MP_PEACETIME_OVER], csNone);
      IssueAutosaveCommand(True);

      gScriptEvents.ProcPeacetimeEnd;
    end;
  end;
end;


function TKMGame.GetNewUID: Integer;
const
  //Prime numbers let us generate sequence of non-repeating values of max_value length
  max_value = 16777213;
  step = 8765423;
begin
  //UIDs have the following properties:
  // - allow -1 to indicate no UID (const UID_NONE = -1)
  // - fit within 24bit (we can use that much for RGB colorcoding in unit picking)
  // - Start from 1, so that black colorcode can be detected in render and then re-mapped to -1

  fUIDTracker := (fUIDTracker + step) mod max_value + 1; //1..N range, 0 is nothing for colorpicker
  Result := fUIDTracker;
end;


function TKMGame.HasMissionDifficulty: Boolean;
begin
  Result := fMissionDifficulty <> mdNone;
end;


function TKMGame.GetNormalGameSpeed: Single;
begin
  if IsMultiPlayerOrSpec then
  begin
    if IsPeaceTime then
      Result := fGameOptions.SpeedPT
    else
      Result := fGameOptions.SpeedAfterPT;
  end
  else
    Result := GAME_SPEED_NORMAL;
end;


procedure TKMGame.UpdateClockUI;
begin
  //don't show speed clock in MP since you can't turn it on/off
  if IsSpeedUpAllowed or gGameApp.GameSettings.ShowGameTime or SHOW_GAME_TICK then
    fGamePlayInterface.UpdateClock(fGameSpeedActual, fGameSpeedGIP, IsReplay);
end;


procedure TKMGame.SetGameSpeedGIP(aSpeed: Single; aUpdateActual: Boolean = False);
var
  speedChanged: Boolean;
begin
  speedChanged := fGameSpeedGIP <> aSpeed;

  fGameSpeedGIP := aSpeed;
  if aUpdateActual then
    SetGameSpeedActual(aSpeed) //will also UpdateClockUI
  else
    UpdateClockUI;

  if speedChanged then
    gScriptEvents.ProcGameSpeedChanged(aSpeed); //Script events should trigger on GIP game speed, not on the actual speed
end;


procedure TKMGame.SetGameSpeedActual(aSpeed: Single);
var
  OldGameSpeed: Single;
begin
  //MapEd always runs at x1
  if IsMapEditor then
  begin
    SetGameSpeedActualValue(GAME_SPEED_NORMAL);
    Exit;
  end;

  OldGameSpeed := fGameSpeedActual;

  UpdateTickCounters;

  SetGameSpeedActualValue(aSpeed);

  //Need to adjust the delay immediately in MP
  if IsMultiPlayerOrSpec and (fGameInputProcess <> nil) then
    TKMGameInputProcess_Multi(fGameInputProcess).AdjustDelay(fGameSpeedActual);

  if Assigned(gGameApp.OnGameSpeedActualChange) then
    gGameApp.OnGameSpeedActualChange(fGameSpeedActual);

  GameSpeedActualChanged(OldGameSpeed, fGameSpeedActual);
end;


procedure TKMGame.SetGameSpeedActualValue(aSpeed: Single);
begin
  fGameSpeedActual := aSpeed;

  //When speed is above x5 we start to skip rendering frames
  //by doing several updates per timer tick
  if fGameSpeedActual > 5 then
  begin
    fGameSpeedMultiplier := Round(fGameSpeedActual / 4);
    fTimerGame.Interval := Round(gGameApp.GameSettings.SpeedPace / fGameSpeedActual * fGameSpeedMultiplier);
  end
  else
  begin
    fGameSpeedMultiplier := 1;
    fTimerGame.Interval := Round(gGameApp.GameSettings.SpeedPace / fGameSpeedActual);
  end;

  UpdateClockUI;
end;


procedure TKMGame.SetGameSpeed(aSpeed: Single);
begin
  Assert(aSpeed > 0);

  //MapEd always runs at x1
  if IsMapEditor then
  begin
    SetGameSpeedActualValue(GAME_SPEED_NORMAL);
    Exit;
  end;

  if IsReplay then
    SetGameSpeedActual(aSpeed)
  else if fGameSpeedChangeAllowed then
    fGameInputProcess.CmdGame(gicGameSpeed, aSpeed);
end;


{$IFDEF RUNNER}
procedure TKMGame.SetGameMode(aGameMode: TKMGameMode);
begin
  fGameMode := aGameMode;
end;
{$ENDIF}


procedure TKMGame.SetGameSpeed(aSpeed: Single; aToggle: Boolean);
begin
  SetGameSpeed(aSpeed, aToggle, GetNormalGameSpeed);
end;


procedure TKMGame.SetGameSpeed(aSpeed: Single; aToggle: Boolean; aToggleTo: Single);
var
  NewGameSpeed: Single;
begin
  //Make the speed toggle between normal speed and desired value
  if (aSpeed = fGameSpeedActual) and aToggle then
    NewGameSpeed := aToggleTo
  else
    NewGameSpeed := aSpeed;

  SetGameSpeed(NewGameSpeed);
end;


procedure TKMGame.GameSpeedActualChanged(aFromSpeed, aToSpeed: Single);
begin
  fActiveInterface.GameSpeedChanged(aFromSpeed, aToSpeed);
end;


//Return Controlled hand index in game or -1, if there is no one (spectator/replay/maped)
function TKMGame.GetControlledHandIndex: TKMHandID;
begin
  Result := -1;
  if fGameMode in [gmSingle, gmCampaign, gmMulti] then
    Result := gMySpectator.HandID;
end;


function TKMGame.GetCurrectTickSaveCRC: Cardinal;
var
  stream: TKMemoryStreamBinary;
begin
  stream := TKMemoryStreamBinary.Create;
  try
    SaveGameToStream(0, stream);
    Result := Adler32CRC(stream);
  finally
    stream.Free;
  end;
end;


procedure TKMGame.SetIsPaused(aValue: Boolean);
begin
  fIsPaused := aValue;
  UpdateTickCounters;
end;


function TKMGame.AllowGetPointer: Boolean;
begin
  Result := IsSingleplayerGame or IsMapEditor or not BlockGetPointer {or SKIP_POINTER_REF_CHECK};
end;


//In replay mode we can step the game by exactly one frame and then pause again
procedure TKMGame.StepOneFrame;
begin
  Assert(fGameMode in [gmReplaySingle,gmReplayMulti], 'We can work step-by-step only in Replay');
  SetGameSpeed(1, False); //Make sure we step only one tick. Do not allow multiple updates in UpdateState loop
  fAdvanceFrame := True;
end;


//Saves the game in TKMemoryStream
procedure TKMGame.SaveGameToStream(aTimestamp: TDateTime; aSaveStream: TKMemoryStream);
var
  GameInfo: TKMGameInfo;
  I, netIndex: Integer;
  gameRes: TKMGameResultMsg;
begin
  GameInfo := TKMGameInfo.Create;
  try
    GameInfo.Title := fGameName;
    GameInfo.MapFullCRC := fGameMapFullCRC;
    GameInfo.MapSimpleCRC := fGameMapSimpleCRC;
    GameInfo.TickCount := fGameTick;
    GameInfo.SaveTimestamp := aTimestamp;
    GameInfo.MissionMode := fMissionMode;
    GameInfo.MissionDifficulty := fMissionDifficulty;
    GameInfo.MapSizeX := gTerrain.MapX;
    GameInfo.MapSizeY := gTerrain.MapY;

    GameInfo.PlayerCount := gHands.Count;
    for I := 0 to gHands.Count - 1 do
    begin
      if fNetworking = nil then
      begin
        GameInfo.Enabled[I] := False;
        GameInfo.CanBeHuman[I] := False;
        GameInfo.OwnerNikname[I] := '';
        GameInfo.HandTypes[I] := hndHuman;
        GameInfo.Color[I] := 0;
        GameInfo.Team[I] := 0;
      end else
      begin
        netIndex := fNetworking.NetPlayers.PlayerIndexToLocal(I);
        if netIndex <> -1 then
        begin
          GameInfo.Enabled[I] := True;
          GameInfo.CanBeHuman[I] := fNetworking.NetPlayers[netIndex].IsHuman;
          GameInfo.OwnerNikname[I] := fNetworking.NetPlayers[netIndex].Nikname;
          GameInfo.HandTypes[I] := fNetworking.NetPlayers[netIndex].GetPlayerType;
          GameInfo.Color[I] := fNetworking.NetPlayers[netIndex].FlagColor;
          GameInfo.Team[I] := fNetworking.NetPlayers[netIndex].Team;
        end
        else
        begin
          GameInfo.Enabled[I] := gHands[I].Enabled;
          GameInfo.CanBeHuman[I] := gHands[I].HandType = hndHuman;
          GameInfo.OwnerNikname[I] := gHands[I].OwnerNikname; //MP nikname, not translated OwnerName
          GameInfo.HandTypes[I] := gHands[I].HandType;
          GameInfo.Color[I] := gHands[I].FlagColor;
          GameInfo.Team[I] := 0;
        end;
      end;
    end;

    GameInfo.Save(aSaveStream);
  finally
    FreeAndNil(GameInfo);
  end;

  fGameOptions.Save(aSaveStream);
                 
  //Because some stuff is only saved in singleplayer we need to know whether it is included in this save,
  //so we can load multiplayer saves in single player and vice versa.
  aSaveStream.Write(IsMultiPlayerOrSpec);

  //In SinglePlayer we want to show player a preview of what the game looked like when he saved
  //Save Minimap is near the start so it can be accessed quickly
  if not IsMultiPlayerOrSpec then
    fGamePlayInterface.SaveMinimap(aSaveStream);

  //We need to know which campaign to display after victory
  aSaveStream.Write(fCampaignName, SizeOf(TKMCampaignId));
  aSaveStream.Write(fCampaignMap);

  aSaveStream.Write(fDynamicFOW);
  aSaveStream.Write(fGameSpeedGIP);
  aSaveStream.Write(fGameSpeedChangeAllowed);

  //We need to know which mission/savegame to try to restart. This is unused in MP
  if not IsMultiPlayerOrSpec then
    aSaveStream.WriteW(fMissionFileSP);
    
  aSaveStream.Write(fUIDTracker); //Units-Houses ID tracker
  aSaveStream.Write(GetKaMSeed); //Include the random seed in the save file to ensure consistency in replays

  if not IsMultiPlayerOrSpec then
  begin
    // Game results differ for game and replay (grReplayEnd for replay),
    // Set some default value
    if GAME_SAVE_STRIP_FOR_CRC then
      gameRes := grCancel
    else
      gameRes := GameResult;
      
    aSaveStream.Write(gameRes, SizeOf(GameResult));    
  end;

  gTerrain.Save(aSaveStream); //Saves the map
  fTerrainPainter.Save(aSaveStream);
  gHands.Save(aSaveStream, fGameMode in [gmMulti, gmMultiSpectate]); //Saves all players properties individually
  if not IsMultiPlayerOrSpec then
    gMySpectator.Save(aSaveStream);
  gAIFields.Save(aSaveStream);
  fPathfinding.Save(aSaveStream);
  gProjectiles.Save(aSaveStream);
  fScripting.Save(aSaveStream);
  gScriptSounds.Save(aSaveStream);
  aSaveStream.Write(fAIType, SizeOf(fAIType));

  fTextMission.Save(aSaveStream);

  gRes.Units.SaveCustomData(aSaveStream);
  gRes.Wares.SaveCustomData(aSaveStream);

  //Parameters that are not identical for all players should not be saved as we need saves to be
  //created identically on all player's computers. Eventually these things can go through the GIP

  //For multiplayer consistency we compare all saves CRCs, they should be created identical on all player's computers.
  if not IsMultiPlayerOrSpec then
    fGamePlayInterface.Save(aSaveStream); //Saves message queue and school/barracks selected units

  //If we want stuff like the MessageStack and screen center to be stored in multiplayer saves,
  //we must send those "commands" through the GIP so all players know about them and they're in sync.
  //There is a comment in fGame.Load about MessageList on this topic.
end;


//Saves the game in all its glory
procedure TKMGame.SaveGameToFile(const aPathName: String; aTimestamp: TDateTime;
                                 const aMPLocalDataPathName: String = '');
var
  SaveStream, SaveStreamTxt: TKMemoryStream;
  GameMPLocalData: TKMGameMPLocalData;
begin
  if BLOCK_SAVE then // This must be here because of paraller Runner
    Exit;
  gLog.AddTime('Saving game start: ' + aPathName);

  Assert((fGameMode <> gmMapEd) and (ALLOW_SAVE_IN_REPLAY or not IsReplay), 'Saving from wrong state');

  SaveStreamTxt := nil;
  if DoSaveGameAsText then
    SaveStreamTxt := TKMemoryStreamText.Create;

  SaveStream := TKMemoryStreamBinary.Create;

  SaveGameToStream(aTimestamp, SaveStream);

  //Makes the folders in case they were deleted.
  //Should do before save Minimap file for MP game
  if (aPathName <> '') then
  begin
    //NOTE: Doing this async means that every part of saving must be done async!
    //Seems error prone so I disabled it for now
    ForceDirectories(ExtractFilePath(aPathName));
    {fSaveWorkerThread.QueueWork(procedure
    begin
      ForceDirectories(ExtractFilePath(aPathName));
    end);}
  end;

  //In MP each player has his own perspective, hence we dont save minimaps in the main save file to avoid cheating,
  //but save minimap in separate file with local game data
  if IsMultiPlayerOrSpec and (aMPLocalDataPathName <> '') then
  begin
    try
      GameMPLocalData := TKMGameMPLocalData.Create(fLastReplayTick, fNetworking.MyNetPlayer.StartLocation, fGamePlayInterface.Minimap);
      try
        GameMPLocalData.SaveToFileAsync(aMPLocalDataPathName, fSaveWorkerThread);
      finally
        FreeAndNil(GameMPLocalData);
      end;
    except
      on E: Exception do
        //Ignore any errors while saving minimap, because its optional for MP games
        gLog.AddTime('Error while saving save minimap to ' + aMPLocalDataPathName + ': ' + E.Message
          {$IFDEF WDC}+ sLineBreak + E.StackTrace{$ENDIF}
          );
    end
  end;

  TKMemoryStream.AsyncSaveToFileAndFree(SaveStream, aPathName, fSaveWorkerThread);
  if DoSaveGameAsText then
  begin
    SaveGameToStream(aTimestamp, SaveStreamTxt);
    TKMemoryStream.AsyncSaveToFileAndFree(SaveStreamTxt, aPathName + EXT_SAVE_TXT_DOT, fSaveWorkerThread);
  end;

  gLog.AddTime('Saving game end: ' + aPathName);
end;


procedure TKMGame.Save(const aSaveName: UnicodeString);
begin
  Save(aSaveName, UTCNow);
end;


//Saves game by provided name
procedure TKMGame.Save(const aSaveName: UnicodeString; aTimestamp: TDateTime);
var
  fullPath, RngPath, mpLocalDataPath, NewSaveName: UnicodeString;
begin
  //Wait for previous save async tasks to complete before proceeding
  fSaveWorkerThread.WaitForAllWorkToComplete;

  //Convert name to full path+name
  fullPath := SaveName(aSaveName, EXT_SAVE_MAIN, IsMultiplayer);
  mpLocalDataPath := SaveName(aSaveName, EXT_SAVE_MP_LOCAL, IsMultiplayer);

  SaveGameToFile(fullPath, aTimestamp, mpLocalDataPath);

  if not IsMultiPlayerOrSpec then
    // Update GameSettings for saved positions in lists of saves and replays
    gGameApp.GameSettings.MenuSPSaveFileName := aSaveName;

  //Remember which savegame to try to restart (if game was not saved before)
  fSaveFile := ExtractRelativePath(ExeDir, fullPath);

  NewSaveName := SaveName(aSaveName, EXT_SAVE_BASE, IsMultiplayer);
  //Copy basesave so we have a starting point for replay
  if IsReplay then
  begin
    //Game was saved from replay (.bas file)
    if FileExists(fLoadFromFile) then
      KMCopyFileAsync(fLoadFromFile, NewSaveName, True, fSaveWorkerThread);
  end else
    //Normally saved game
    {$IFDEF PARALLEL_RUNNER}
      KMCopyFileAsync(SaveName('basesave_thread_'+IntToStr(THREAD_NUMBER), EXT_SAVE_BASE, IsMultiplayer), NewSaveName, True, fSaveWorkerThread);
    {$ELSE}
      KMCopyFileAsync(SaveName('basesave', EXT_SAVE_BASE, IsMultiplayer), NewSaveName, True, fSaveWorkerThread);
    {$ENDIF}

  //Save replay queue
  gLog.AddTime('Saving replay info');
  // Save replay info
  fGameInputProcess.SaveToFileAsync(ChangeFileExt(fullPath, EXT_SAVE_REPLAY_DOT), fSaveWorkerThread);

  // Save checkpoints
  if gGameApp.GameSettings.SaveCheckpoints and not SKIP_SAVE_SAVPTS_TO_FILE then
    fSavedReplays.SaveToFileAsync(ChangeFileExt(fullPath, EXT_SAVE_GAME_SAVEPTS_DOT), fSaveWorkerThread);

  if DoSaveRandomChecks then
    try
      RngPath := ChangeFileExt(fullPath, EXT_SAVE_RNG_LOG_DOT);
      gRandomCheckLogger.SaveToPathAsync(RngPath, fSaveWorkerThread);
    except
      on E: Exception do
        gLog.AddTime('Error saving random checks to ' + RngPath); //Silently log error, don't propagate error further
    end;

  gLog.AddTime('Saving game', True);
end;


procedure TKMGame.SaveCampaignScriptData(SaveStream: TKMemoryStream);
begin
  fScripting.SaveCampaignData(SaveStream);
end;


procedure TKMGame.LoadFromStream(var LoadStream: TKMemoryStreamBinary);
var
  GameInfo: TKMGameInfo;
  LoadedSeed: LongInt;
  SaveIsMultiplayer, IsCampaign: Boolean;
  I: Integer;
begin
  //We need only few essential parts from GameInfo, the rest is duplicate from gTerrain and fPlayers
  GameInfo := TKMGameInfo.Create;
  try
    GameInfo.Load(LoadStream);
    fGameName := GameInfo.Title;
    fGameMapFullCRC := GameInfo.MapFullCRC;
    fGameMapSimpleCRC := GameInfo.MapSimpleCRC;
    fGameTick := GameInfo.TickCount;
    fMissionMode := GameInfo.MissionMode;
    fMissionDifficulty := GameInfo.MissionDifficulty;
  finally
    FreeAndNil(GameInfo);
  end;

  fGameOptions.Load(LoadStream);

  //So we can allow loading of multiplayer saves in single player and vice versa we need to know which type THIS save is
  LoadStream.Read(SaveIsMultiplayer);
  if SaveIsMultiplayer and (fGameMode = gmReplaySingle) then
    fGameMode := gmReplayMulti; //We only know which it is once we've read the save file, so update it now

  //If the player loads a multiplayer save in singleplayer or replay mode, we require a mutex lock to prevent cheating
  //If we're loading in multiplayer mode we have already locked the mutex when entering multiplayer menu,
  //which is better than aborting loading in a multiplayer game (spoils it for everyone else too)
  if SaveIsMultiplayer and (fGameMode in [gmSingle, gmCampaign, gmReplaySingle, gmReplayMulti]) then
    if gMain.LockMutex then
      fGameLockedMutex := True //Remember so we unlock it in Destroy
    else
      //Abort loading (exception will be caught in gGameApp and shown to the user)
      raise Exception.Create(gResTexts[TX_MULTIPLE_INSTANCES]);

  //Not used, (only stored for SP preview) but it's easiest way to skip past it
  if not SaveIsMultiplayer then
    fGamePlayInterface.LoadMinimap(LoadStream);

  //We need to know which campaign to display after victory
  LoadStream.Read(fCampaignName, SizeOf(TKMCampaignId));
  LoadStream.Read(fCampaignMap);

  LoadStream.Read(fDynamicFOW);
  LoadStream.Read(fGameSpeedGIP);

  // Set game actual speed, so we will have same speed after game load as it was when game was saved
  if not IsReplay then
    SetGameSpeedActualValue(fGameSpeedGIP)
  else
    UpdateClockUI; //To show actual game speed in the replay

  LoadStream.Read(fGameSpeedChangeAllowed);

  //Check if this save is Campaign game save
  IsCampaign := False;
  for I := Low(TKMCampaignId) to High(TKMCampaignId) do
    if fCampaignName[I] <> NO_CAMPAIGN[I] then
      IsCampaign := True;

  //If there is Campaign Name in save then change GameMode to gmCampaign, because GameMode is not stored in Save
  if IsCampaign
    and not (fGameMode in [gmReplaySingle, gmReplayMulti]) then //Not for replays thought...
    fGameMode := gmCampaign;

  //We need to know which mission/savegame to try to restart. This is unused in MP.
  if not SaveIsMultiplayer then
    LoadStream.ReadW(fMissionFileSP);

  LoadStream.Read(fUIDTracker);
  LoadStream.Read(LoadedSeed);
  
  if not SaveIsMultiplayer then
    LoadStream.Read(GameResult, SizeOf(GameResult));

  //Load the data into the game
  gTerrain.Load(LoadStream);
  fTerrainPainter.Load(LoadStream);

  gHands.Load(LoadStream);
  gMySpectator := TKMSpectator.Create(0);
  if not SaveIsMultiplayer then
    gMySpectator.Load(LoadStream);
  gAIFields.Load(LoadStream);
  fPathfinding.Load(LoadStream);
  gProjectiles.Load(LoadStream);
  fScripting.Load(LoadStream);
  gScriptSounds.Load(LoadStream);
  LoadStream.Read(fAIType, SizeOf(fAIType));

  fTextMission := TKMTextLibraryMulti.Create;
  fTextMission.Load(LoadStream);

  gRes.Units.LoadCustomData(LoadStream);
  gRes.Wares.LoadCustomData(LoadStream);

  if gGame.GameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti] then
  begin
    gMySpectator.FOWIndex := PLAYER_NONE; //Show all by default in replays
    //HandIndex is the first enabled player
    gMySpectator.HandID := FindHandToSpec;
  end;

  //Multiplayer saves don't have this piece of information. Its valid only for MyPlayer
  //todo: Send all message commands through GIP (note: that means there will be a delay when you press delete)
  if not SaveIsMultiplayer then
    fGamePlayInterface.Load(LoadStream);

  if IsReplay then
    fGameInputProcess := TKMGameInputProcess_Single.Create(gipReplaying) //Replay
  else
    if fGameMode in [gmMulti, gmMultiSpectate] then
      fGameInputProcess := TKMGameInputProcess_Multi.Create(gipRecording, fNetworking) //Multiplayer
    else
      fGameInputProcess := TKMGameInputProcess_Single.Create(gipRecording);

  SetSeed(LoadedSeed); //Seed is used in MultiplayerRig when changing humans to AIs through GIP for replay
end;


procedure TKMGame.LoadFromFile(const aPathName: UnicodeString; const aCustomReplayFile: UnicodeString = '');

  procedure LoadReplayDataFromFile(const aFileName: string);
  begin
    fGameInputProcess.LoadFromFile(ChangeFileExt(aFileName, EXT_SAVE_REPLAY_DOT));
    fSavedReplays.LoadFromFile(ChangeFileExt(aFileName, EXT_SAVE_GAME_SAVEPTS_DOT));
  end;

var
  LoadStream: TKMemoryStreamBinary;
  GameMPLocalData: TKMGameMPLocalData;
  RngPath: UnicodeString;
begin
  fSaveFile := ChangeFileExt(ExtractRelativePath(ExeDir, aPathName), EXT_SAVE_MAIN_DOT);

  gLog.AddTime('Loading game from: ' + aPathName);

  LoadStream := TKMemoryStreamBinary.Create;
  try
    if not FileExists(aPathName) then
      raise Exception.Create('Savegame could not be found at ''' + aPathName + '''');

    fLoadFromFile := aPathName;

    LoadStream.LoadFromFile(aPathName);

    LoadFromStream(LoadStream);

    if aCustomReplayFile = '' then
      LoadReplayDataFromFile(aPathName)
    else
    begin
      gLog.AddTime('Loading game replay from: ' + aCustomReplayFile);
      LoadReplayDataFromFile(aCustomReplayFile);
    end;

    //Load MP game local data
    if fGameMode = gmReplayMulti then
    begin
      GameMPLocalData := TKMGameMPLocalData.Create;
      try
        GameMPLocalData.LoadFromFile(ChangeFileExt(ExtractRelativePath(ExeDir, aPathName), EXT_SAVE_MP_LOCAL_DOT));
        fLastReplayTick := GameMPLocalData.LastReplayTick;
      finally
        FreeAndNil(GameMPLocalData);
      end;
    end;

    // SetSeed was there, I dont know the dependencies so please check if it is ok to include it in LoadGameStream

    if DoSaveRandomChecks then
      try
        RngPath := ChangeFileExt(aPathName, EXT_SAVE_RNG_LOG_DOT);
        gRandomCheckLogger.LoadFromPath(RngPath);
        gRandomCheckLogger.Enabled := not IsMapEditor and not IsReplay;  //Disable random check logger for MapEditor
      except
        on E: Exception do
          gLog.AddTime('Error loading random checks from ' + RngPath); //Silently log error, don't propagate error further
      end;

    gLog.AddTime('Loading game', True);
  finally
    FreeAndNil(LoadStream);
  end;
end;


procedure TKMGame.LoadSavedReplay(aTick: Cardinal; const aSaveFile: UnicodeString);
var
  loadStream: TKMemoryStreamBinary;
  lastReplayTick: Cardinal;
  skipReplayEndCheck: Boolean;
begin
  gLog.AddTime('Loading replay from save');
  fSaveFile := aSaveFile;

  if fSavedReplays.Contains(aTick) then
  begin
    lastReplayTick := fLastReplayTick;
    skipReplayEndCheck := fSkipReplayEndCheck;

    loadStream := TKMemoryStreamBinary(fSavedReplays[aTick]);
    loadStream.Position := 0;
    LoadFromStream(loadStream);

    // Restore game (replay) parameters, that are shared among all game savepoints
    gGame.LastReplayTick := lastReplayTick;
    gGame.SkipReplayEndCheck := skipReplayEndCheck;
    gLog.AddTime('Loading replay from save done', True);
  end;
end;


// Save game/replay savepoint
procedure TKMGame.SaveReplayToMemory();
var
  SaveStream: TKMemoryStreamBinary;
begin
  if (fSavedReplays = nil) or fSavedReplays.Contains(fGameTick) then //No need to save twice on the same tick
    Exit;

  gLog.AddTime('Make savepoint at tick ' + IntToStr(fGameTick));

  SaveStream := TKMemoryStreamBinary.Create;
  SaveGameToStream(TDateTime(0), SaveStream); // Date is not important

  fSavedReplays.NewSave(SaveStream, fGameTick);
end;


procedure TKMGame.AfterLoad;
begin
  gLog.AddTime('After game loading');
  //Should check all Unit-House ID references and replace them with actual pointers
  gHands.SyncLoad;
  gTerrain.SyncLoad;
  gProjectiles.SyncLoad;
  fScripting.SyncLoad;

  if fGameMode in [gmMulti, gmMultiSpectate] then
    MultiplayerRig(False);

  if fGameMode in [gmSingle, gmCampaign, gmMulti, gmMultiSpectate] then
  begin
    DeleteFile(SaveName('basesave', EXT_SAVE_BASE, IsMultiPlayerOrSpec));
    ForceDirectories(SavePath('basesave', IsMultiPlayerOrSpec)); //basesave directory could not exist at this moment, if this is the first game ever, f.e.
    KMCopyFile(ChangeFileExt(ExeDir + fSaveFile, EXT_SAVE_BASE_DOT), SaveName('basesave', EXT_SAVE_BASE, IsMultiPlayerOrSpec));
  end;

  //Repeat mission init if necessary
  if fGameTick = 0 then
    gScriptEvents.ProcMissionStart;

  //When everything is ready we can update UI
  fActiveInterface.SyncUI;

  if IsMultiPlayerOrSpec then
  begin
    //MP does not saves view position cos of save identity for all players
    fActiveInterface.SyncUIView(KMPointF(gMySpectator.Hand.CenterScreen));
    //In MP saves hotkeys can't be saved by UI, they must be network synced
    if fGameMode in [gmSingle, gmCampaign, gmMulti] then
      fGamePlayInterface.LoadHotkeysFromHand;
  end;

  if IsReplay then
  begin
    //SP Replay need to set screen position
    fActiveInterface.SyncUIView(KMPointF(gMySpectator.Hand.CenterScreen));

    fGamePlayInterface.UpdateReplayMarks;
  end
  else
    // Save dummy GIP to know when game was loaded. Good for debug
    fGameInputProcess.CmdGame(gicGameLoadSave, Integer(fGameTick));

  gLog.AddTime('After game loading', True);
end;


function TKMGame.GetGameTickDuration: Single;
begin
  Result := gGameApp.GameSettings.SpeedPace / fGameSpeedActual;
end;


function TKMGame.GetTicksBehindCnt: Single;
var
  CalculatedTick: Single;
  TimeSince: Cardinal;
begin
  //Lets calculate tick, that shoud be at that moment in theory, depending of speed multiplier and game duration
  TimeSince := GetTimeSince(fGameSpeedChangeTime);
  CalculatedTick := TimeSince*fGameSpeedActual/gGameApp.GameSettings.SpeedPace - fPausedTicksCnt;
  //Calc how far behind are we, in ticks
  Result := CalculatedTick + fGameSpeedChangeTick - fGameTick;
end;


procedure TKMGame.UpdateTickCounters;
var TicksBehind: Single;
begin
  TicksBehind := GetTicksBehindCnt; // save number of ticks we are behind now
  fGameSpeedChangeTick := fGameTick;
  if IsMultiPlayerOrSpec and not IsMPGameSpeedChangeAllowed then
    // Remember if we were some ticks behind at that moment.
    // Important for MP game with many players, but can be omitted for SP and MP with only 1 player
    fGameSpeedChangeTick := fGameSpeedChangeTick + TicksBehind;
  //set fGameSpeedChangeTime after we invoke GetTicksBehindCnt !
  fGameSpeedChangeTime := TimeGet;
  fPausedTicksCnt := 0;
end;


procedure TKMGame.UpdateGame(Sender: TObject);
  procedure DoUpdateGame;
  begin
    if not PlayNextTick then
      Inc(fPausedTicksCnt);
    if DoGameHold then
      GameHold(True, DoGameHoldState);
  end;

var
  TicksBehindCnt: Single;
  I: Integer;

begin
  DoUpdateGame;
  
  if CALC_EXPECTED_TICK then
  begin
    TicksBehindCnt := GetTicksBehindCnt;

    //When our game is more then 0.5 tick behind - play another tick immidiately
    //This will prevent situation, when lags on local PC (on zoon out, f.e.) leads to lags for all other MP players
    //Also game speed become absolutely presize
    if TicksBehindCnt > 0.5 then
      // f.e. if we behind on 1.4 ticks - make 1 more update, for 1.6 - 2 more updates
      for I := 0 to Min(Trunc(TicksBehindCnt - 0.5), MAX_TICKS_PER_GAME_UPDATE - 1) do // do not do too many GameUpdates at once. Limit them
        DoUpdateGame;
  end
  else
  begin
    // Always play several ticks per update. This is more convinient while using debugger 
    for I := 1 to fGameSpeedMultiplier - 1 do // 1 Tick we already played
      DoUpdateGame;
  end;
end;


procedure TKMGame.IssueAutosaveCommand(aAfterPT: Boolean = False);
var
  GICType: TKMGameInputCommandType;
begin
  if aAfterPT then
    GICType := gicGameAutoSaveAfterPT
  else
    GICType := gicGameAutoSave;

  if IsMultiPlayerOrSpec then
  begin
    if fNetworking.IsHost then
    begin
      fGameInputProcess.CmdGame(GICType, UTCNow); //Timestamp must be synchronised
    end;
  end
  else
    if gGameApp.GameSettings.Autosave then
    begin
      fGameInputProcess.CmdGame(GICType, UTCNow);
    end;
end;


procedure TKMGame.SetSeed(aSeed: Integer);
begin
  if USE_CUSTOM_SEED and not IsReplay then
    aSeed := CUSTOM_SEED_VALUE;

  gLog.AddTime('Set game seed: ' + IntToStr(aSeed));

  KM_CommonUtils.SetKaMSeed(aSeed);
  fGameSeed := aSeed; //Save it for debug only
end;


procedure TKMGame.IncGameTick;
begin
  Inc(fGameTick); //Thats our tick counter for gameplay events
  if LOG_GAME_TICK then
    gLog.AddTime('Tick: ' + IntToStr(fGameTick));
end;


function TKMGame.IsReplayEnded: Boolean;
begin
  if fLastReplayTick > 0 then
    Result := fGameTick >= fLastReplayTick
  else
    Result := fGameInputProcess.ReplayEnded;
end;


procedure TKMGame.CheckPauseGameAtTick;

  procedure SetReplayPause;
  begin
    IsPaused := True;
    //Set replay UI to paused state, sync replay timer and other UI elements
    fGamePlayInterface.UpdateReplayButtons(False);
    fGamePlayInterface.UpdateState(fGameTick);
  end;

var
  PeaceTimeLeft, PTTicks: Cardinal;
begin
  PeaceTimeLeft := 0;
  PTTicks := fGameOptions.Peacetime * 600;

  if (fGameMode = gmReplayMulti) and (PTTicks >= fGameTick) then
    PeaceTimeLeft := PTTicks - fGameTick;

  if fGameTick = PAUSE_GAME_AT_TICK then
  begin
    if IsReplay then
      SetReplayPause
    else
      fGamePlayInterface.SetPause(True);
  end;

  if (PeaceTimeLeft = 1) and gGameApp.GameSettings.ReplayAutopause then
    SetReplayPause;
end;


function TKMGame.PlayNextTick: Boolean;
begin
  Result := False;
  //Some PCs seem to change 8087CW randomly between events like Timers and OnMouse*,
  //so we need to set it right before we do game logic processing
  Set8087CW($133F);

  if fIsPaused or ReadyToStop then Exit;

  fBlockGetPointer := False;

  try
    try
      case fGameMode of
        gmSingle, gmCampaign, gmMulti, gmMultiSpectate:
                      if not (fGameMode in [gmMulti, gmMultiSpectate]) or (fNetworking.NetGameState <> lgsLoading) then
                      begin
                        if fGameInputProcess.CommandsConfirmed(fGameTick + 1) then
                        begin
                          {$IFDEF PERFLOG}
                          gPerfLogs.StackCPU.TickBegin;
                          gPerfLogs.SectionEnter(psGameTick, fGameTick + 1);
                          {$ENDIF}
                          try
                            // As soon as next command arrives we are no longer in a waiting state
                            if fWaitingForNetwork then
                              WaitingPlayersDisplay(False);

                            IncGameTick;

                            fLastReplayTick := fGameTick;

                            if (fGameMode in [gmMulti, gmMultiSpectate]) then
                              fNetworking.LastProcessedTick := fGameTick;

                            //Tell the master server about our game on the specific tick (host only)
                            if (fGameMode in [gmMulti, gmMultiSpectate]) and fNetworking.IsHost
                              and (((fMissionMode = mmNormal) and (fGameTick = ANNOUNCE_BUILD_MAP))
                              or ((fMissionMode = mmTactic) and (fGameTick = ANNOUNCE_BATTLE_MAP))) then
                            fNetworking.ServerQuery.SendMapInfo(fGameName, fGameMapFullCRC, fNetworking.NetPlayers.GetConnectedCount);

                            fScripting.UpdateState;
                            UpdatePeacetime; //Send warning messages about peacetime if required
                            gTerrain.UpdateState;
                            gAIFields.UpdateState(fGameTick);
                            gHands.UpdateState(fGameTick); //Quite slow

                            if gGame = nil then Exit; //Quit the update if game was stopped for some reason

                            gMySpectator.UpdateState(fGameTick);
                            fPathfinding.UpdateState;
                            gProjectiles.UpdateState; //If game has stopped it's NIL

                            fGameInputProcess.RunningTimer(fGameTick); //GIP_Multi issues all commands for this tick

                            //Returning to the lobby (through MP GIP) ends the game
                            if gGame = nil then Exit;

                            //In aggressive mode store a command every tick so we can find exactly when a replay mismatch occurs
                            if AGGRESSIVE_REPLAYS then
                              fGameInputProcess.CmdTemp(gicTempDoNothing); //do call cmd before SaveGameCheckpoint

                            fSavedReplays.LastTick := Max(fSavedReplays.LastTick, fGameTick);

                            //Save replay to memory (to be able to load it later)
                            //Make replay save only after everything is updated (UpdateState)
                            if gGameApp.GameSettings.SaveCheckpoints
                              and (fSavedReplays.Count <= gGameApp.GameSettings.SaveCheckpointsLimit) //Do not allow to spam saves, could cause OUT_OF_MEMORY error
                              and ((fGameTick = MAKE_SAVEPT_AT_TICK)
                                or (fGameTick = (fGameOptions.Peacetime*60*10)) //At PT end
                                or ((fGameTick mod gGameApp.GameSettings.SaveCheckpointsFreq) = 0)) then
                              SaveReplayToMemory;

                            // Update our ware distributions from settings at the start of the game
                            if (fGameTick = 1)
                            and IsWareDistributionStoredBetweenGames then
                              fGameInputProcess.CmdWareDistribution(gicWareDistributions, gGameApp.GameSettings.WareDistribution.PackToStr);

                            if (fGameTick mod gGameApp.GameSettings.AutosaveFrequency) = 0 then
                              IssueAutosaveCommand;

                            CheckPauseGameAtTick;

                            Result := True;

                            if DoSaveRandomChecks then
                              gRandomCheckLogger.UpdateState(fGameTick);
                          finally
                            {$IFDEF PERFLOG}
                            gPerfLogs.SectionLeave(psGameTick);
                            gPerfLogs.StackCPU.TickEnd;
                            {$ENDIF}
                          end;
                        end
                        else
                        begin
                          fGameInputProcess.WaitingForConfirmation(fGameTick);
                          if TKMGameInputProcess_Multi(fGameInputProcess).NumberConsecutiveWaits > Max(10, Round(fGameSpeedGIP)) then
                            WaitingPlayersDisplay(True);
                        end;
                        fGameInputProcess.UpdateState(fGameTick); //Do maintenance
                      end;
        gmReplaySingle,gmReplayMulti:
                      begin
                        IncGameTick;
                        {$IFDEF PERFLOG}
                        gPerfLogs.StackCPU.TickBegin;
                        gPerfLogs.SectionEnter(psGameTick, fGameTick);
                        {$ENDIF}

                        try
                          fScripting.UpdateState;
                          UpdatePeacetime; //Send warning messages about peacetime if required (peacetime sound should still be played in replays)
                          gTerrain.UpdateState;
                          gAIFields.UpdateState(fGameTick);
                          gHands.UpdateState(fGameTick); //Quite slow
                          if gGame = nil then Exit; //Quit the update if game was stopped for some reason
                          gMySpectator.UpdateState(fGameTick);
                          fPathfinding.UpdateState;
                          gProjectiles.UpdateState; //If game has stopped it's NIL

                          //Issue stored commands
                          fGameInputProcess.ReplayTimer(fGameTick);

                          if gGame = nil then
                            Exit; //Quit if the game was stopped by a replay mismatch

                          //Only increase LastTick, since we could load replay earlier at earlier state
//                          if fSavedReplays <> nil then
                          fSavedReplays.LastTick := Max(fSavedReplays.LastTick, fGameTick);

                          //Save replay to memory (to be able to load it later)
                          //Make replay save only after everything is updated (UpdateState)
                          if gGameApp.GameSettings.ReplayAutosave
                            and (fSavedReplays.Count <= REPLAY_AUTOSAVE_CNT_MAX) //Do not allow to spam saves, could cause OUT_OF_MEMORY error
                            and ((fGameTick = 1) //First tick
                              or (fGameTick = MAKE_SAVEPT_AT_TICK)
                              or (fGameTick = (fGameOptions.Peacetime*60*10)) //At PT end
                              or ((fGameTick mod GetReplayAutosaveEffectiveFrequency) = 0)) then
                          begin
                            SaveReplayToMemory;
                            fGamePlayInterface.AddReplayMark(fGameTick);
                          end;

                          if not fSkipReplayEndCheck and IsReplayEnded then
                            RequestGameHold(grReplayEnd);

                          if fAdvanceFrame then
                          begin
                            fAdvanceFrame := False;
                            fIsPaused := True;
                          end;
                        finally
                          {$IFDEF PERFLOG}
                          gPerfLogs.SectionLeave(psGameTick);
                          gPerfLogs.StackCPU.TickEnd;
                          {$ENDIF}
                        end;

                        if DoGameHold then
                          Exit;

                        CheckPauseGameAtTick;

                        Result := True;
                      end;
        gmMapEd:   begin
                      gTerrain.IncAnimStep;
                      gHands.IncAnimStep;
                    end;
      end;
    except
        on E: Exception do
        begin
          gLog.AddTime('Exception on tick ' + IntToStr(fGameTick) + ': ' + E.Message
                       {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
          raise;
        end;
    end;
  finally
    fBlockGetPointer := True;
  end;
end;


function TKMGame.DoSaveRandomChecks: Boolean;
begin
  Result := gGameApp.GameSettings.DebugSaveRandomChecks
            and SAVE_RANDOM_CHECKS
            and (gRandomCheckLogger <> nil);
end;


function TKMGame.DoRenderGame: Boolean;
begin
  // Do not render game under game stats page
  Result := IsMapEditor or not fGamePlayInterface.StatsOpened;
end;


function TKMGame.DoSaveGameAsText: Boolean;
begin
  Result := gGameApp.GameSettings.DebugSaveGameAsText
            and SAVE_GAME_AS_TEXT;
end;


function TKMGame.GetReplayAutosaveEffectiveFrequency: Integer;
begin
  Assert(IsReplay, 'Wrong game mode');
  Result := Math.Max(gGameApp.GameSettings.ReplayAutosaveFrequency,
                     //Do not save too often, that could cause OUT_OF_MEMORY error
                     fGameInputProcess.GetLastTick div (REPLAY_AUTOSAVE_CNT_MAX - 2)); // - 2 for starting one and for PT
  Result := Ceil(Result / 300)*300; //Ceil to every 30 sec
end;


procedure TKMGame.UserAction(aActionType: TKMUserActionType);
begin
  fLastTimeUserAction := Max(fLastTimeUserAction, TimeGet);
end;


procedure TKMGame.UpdateState(aGlobalTickCount: Cardinal);
const
  PLAYER_AFK_TIME = 5; //in minutes. Notify other players, when this player is AFK
  PLAYER_AFK_MESSAGE_DELAY = 5*60*1000; //in ms, wait till next AFK message. do not spam players with messages
begin
  if gScriptSounds <> nil then
    gScriptSounds.UpdateState;

  if not fIsPaused then
  begin
    fActiveInterface.UpdateState(aGlobalTickCount);

    //Notify about player being AFK
    if (gGame.GameMode = gmMulti) //Only for MP game players, not specs
      and (GetTimeSince(fLastTimeUserAction) > PLAYER_AFK_TIME*60*1000)
      and (GetTimeSince(fLastAfkMessageSent) > PLAYER_AFK_MESSAGE_DELAY) then
    begin
      fNetworking.PostMessage(TX_PLAYER_AFK_MESSAGE, csSystem, fNetworking.MyNetPlayer.NiknameColoredU,
                              WrapColor(IntToStr(GetTimeSince(fLastTimeUserAction) div 60000), icGoldenYellow));
      fLastAfkMessageSent := TimeGet;
    end;
  end;

  if (aGlobalTickCount mod 10 = 0) and (fMapEditor <> nil) then
    fMapEditor.UpdateState;
end;


//This is our real-time "thread", use it wisely
procedure TKMGame.UpdateStateIdle(aFrameTime: Cardinal);
begin
  if (not fIsPaused) or IsReplay then
    fActiveInterface.UpdateStateIdle(aFrameTime);

  //Terrain should be updated in real time when user applies brushes
  if fMapEditor <> nil then
    fMapEditor.UpdateStateIdle;
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

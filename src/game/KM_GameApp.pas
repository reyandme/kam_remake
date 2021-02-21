unit KM_GameApp;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF WDC} UITypes, {$ENDIF}
  {$IFDEF FPC} Controls, {$ENDIF}
  Classes, Dialogs, ExtCtrls,
  KM_CommonTypes, KM_Defaults, KM_RenderControl, KM_Video,
  KM_Campaigns, KM_Game, KM_InterfaceMainMenu, KM_Resource,
  KM_Music, KM_Maps, KM_MapTypes, KM_CampaignTypes, KM_Networking,
  KM_GameSettings,
  KM_KeysSettings,
  KM_ServerSettings,
  KM_Render,
  KM_GameTypes, KM_Points, KM_Console,
  KM_WorkerThread;

type
  //Methods relevant to gameplay
  TKMGameApp = class
  private
    fGlobalTickCount: Cardinal;
    fIsExiting: Boolean;

    fCampaigns: TKMCampaignsCollection;
    fGameSettings: TKMGameSettings;
    fKeysSettings: TKMKeysSettings;
    fServerSettings: TKMServerSettings;
    fNetworking: TKMNetworking;
    fTimerUI: TTimer;
    fMainMenuInterface: TKMMainMenuInterface;
    fLastTimeRender: Cardinal;

    fChat: TKMChat;

    fOnCursorUpdate: TIntegerStringEvent;
    fOnGameSpeedChange: TSingleEvent;
    fOnGameStart: TKMGameModeChangeEvent;
    fOnGameEnd: TKMGameModeChangeEvent;

    fOnOptionsChange: TEvent;

    // Worker threads
    fSaveWorkerThread: TKMWorkerThread; // Worker thread for normal saves and save at the end of PT
    fBaseSaveWorkerThread: TKMWorkerThread; // Worker thread for base save only
    fAutoSaveWorkerThread: TKMWorkerThread; // Worker thread for autosaves only

    procedure CreateGame(aGameMode: TKMGameMode);

    procedure SaveCampaignsProgress;
    procedure GameLoadingStep(const aText: UnicodeString);
    procedure LoadGameAssets;
    procedure LoadGameFromSave(const aFilePath: String; aGameMode: TKMGameMode; const aGIPPath: String = '');
    procedure LoadGameFromScript(const aMissionFile, aGameName: String; aFullCRC, aSimpleCRC: Cardinal; aCampaign: TKMCampaign;
                                 aMap: Byte; aGameMode: TKMGameMode; aDesiredLoc: ShortInt; aDesiredColor: Cardinal;
                                 aDifficulty: TKMMissionDifficulty = mdNone; aAIType: TKMAIType = aitNone;
                                 aAutoselectHumanLoc: Boolean = False);
    procedure LoadGameSavePoint(aTick: Cardinal);
    procedure LoadGameFromScratch(aSizeX, aSizeY: Integer; aGameMode: TKMGameMode);
    function SaveName(const aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;

    procedure GameStarted(aGameMode: TKMGameMode);
    procedure GameEnded(aGameMode: TKMGameMode);
    procedure GameDestroyed;
    procedure GameFinished;
    function GetGameSettings: TKMGameSettings;
    procedure SetOnOptionsChange(const aEvent: TEvent);

    procedure InitMainMenu(aScreenX, aScreenY: Word);
  public
    constructor Create(aRenderControl: TKMRenderControl; aScreenX, aScreenY: Word; aVSync: Boolean; aOnLoadingStep: TEvent;
                       aOnLoadingText: TUnicodeStringEvent; aOnCursorUpdate: TIntegerStringEvent; NoMusic: Boolean = False);
    destructor Destroy; override;
    procedure AfterConstruction(aReturnToOptions: Boolean); reintroduce;

    procedure PrepageStopGame(aMsg: TKMGameResultMsg);
    procedure StopGame(aMsg: TKMGameResultMsg; const aTextMsg: UnicodeString = '');
    procedure AnnounceReturnToLobby;
    procedure PrepareReturnToLobby(aTimestamp: TDateTime);
    procedure StopGameReturnToLobby;
    function CanClose: Boolean;
    procedure Resize(X,Y: Integer);
    procedure ToggleLocale(const aLocale: AnsiString);
    procedure NetworkInit;
    procedure SendMPGameInfo;
    function RenderVersion: UnicodeString;
    procedure PrintScreen(const aFilename: UnicodeString = '');
    function CheckDATConsistency: Boolean;

    procedure PreloadGameResources;

    //These are all different game kinds we can start
    procedure NewCampaignMap(aCampaignId: TKMCampaignId; aMap: Byte; aDifficulty: TKMMissionDifficulty = mdNone);
    procedure NewSingleMap(const aMissionFile, aGameName: UnicodeString; aDesiredLoc: ShortInt = -1;
                           aDesiredColor: Cardinal = $00000000; aDifficulty: TKMMissionDifficulty = mdNone;
                           aAIType: TKMAIType = aitNone; aAutoselectHumanLoc: Boolean = False);
    procedure NewSingleSave(const aSaveName: UnicodeString);
    procedure NewMultiplayerMap(const aFileName: UnicodeString; aMapFolder: TKMapFolder; aCRC: Cardinal; aSpectating: Boolean;
                                aDifficulty: TKMMissionDifficulty);
    procedure NewMultiplayerSave(const aSaveName: UnicodeString; Spectating: Boolean);
    procedure NewRestartLast(const aGameName, aMission, aSave: UnicodeString; aGameMode: TKMGameMode; aCampName: TKMCampaignId;
                             aCampMap: Byte; aLocation: Byte; aColor: Cardinal; aDifficulty: TKMMissionDifficulty = mdNone;
                             aAIType: TKMAIType = aitNone);
    procedure NewEmptyMap(aSizeX, aSizeY: Integer);
    procedure NewMapEditor(const aFileName: UnicodeString; aSizeX: Integer = 0; aSizeY: Integer = 0;
                           aMapFullCRC: Cardinal = 0; aMapSimpleCRC: Cardinal = 0; aMultiplayerLoadMode: Boolean = False);
    procedure NewReplay(const aFilePath: UnicodeString);
    procedure NewSaveAndReplay(const aSavPath, aRplPath: UnicodeString);
    function TryLoadSavePoint(aTick: Integer): Boolean;
    procedure LoadPrevSavePoint;

    procedure SaveMapEditor(const aPathName: UnicodeString);

    property Campaigns: TKMCampaignsCollection read fCampaigns;
    function Game: TKMGame;
    property GameSettings: TKMGameSettings read GetGameSettings;
    property MainMenuInterface: TKMMainMenuInterface read fMainMenuInterface;
    property Networking: TKMNetworking read fNetworking;
    property GlobalTickCount: Cardinal read fGlobalTickCount;
    property Chat: TKMChat read fChat;

    procedure KeyDown(Key: Word; Shift: TShiftState);
    procedure KeyPress(Key: Char);
    procedure KeyUp(Key: Word; Shift: TShiftState);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseWheel(Shift: TShiftState; WheelSteps: Integer; X,Y: Integer; var aHandled: Boolean);
    procedure FPSMeasurement(aFPS: Cardinal);

    property SaveWorkerThread: TKMWorkerThread read fSaveWorkerThread;
    property BaseSaveWorkerThread: TKMWorkerThread read fBaseSaveWorkerThread;
    property AutoSaveWorkerThread: TKMWorkerThread read fAutoSaveWorkerThread;

    procedure UnlockAllCampaigns;

    procedure DebugControlsUpdated(Sender: TObject; aSenderTag: Integer);

    property OnGameSpeedActualChange: TSingleEvent read fOnGameSpeedChange write fOnGameSpeedChange;
    property OnGameStart: TKMGameModeChangeEvent read fOnGameStart write fOnGameStart;
    property OnGameEnd: TKMGameModeChangeEvent read fOnGameEnd write fOnGameEnd;
    property OnOptionsChange: TEvent read fOnOptionsChange write SetOnOptionsChange;

    procedure Render(aForPrintScreen: Boolean = False);
    procedure UpdateState(Sender: TObject);
    procedure UpdateStateIdle(aFrameTime: Cardinal);
  end;


var
  gGameApp: TKMGameApp;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  SysUtils, DateUtils, Math, TypInfo, KromUtils,
  {$IFDEF USE_MAD_EXCEPT} KM_Exceptions, {$ENDIF}
  KM_FormLogistics,
  KM_Main, KM_Controls, KM_Log, KM_Sound, KM_GameInputProcess, KM_GameInputProcess_Multi,
  KM_GameSavePoints,
  KM_InterfaceDefaults, KM_GameCursor, KM_ResTexts,
  KM_Saves, KM_CommonUtils, KM_RandomChecks, KM_DevPerfLog, KM_DevPerfLogTypes;


{ Creating everything needed for MainMenu, game stuff is created on StartGame }
constructor TKMGameApp.Create(aRenderControl: TKMRenderControl; aScreenX, aScreenY: Word; aVSync: Boolean; aOnLoadingStep: TEvent;
                              aOnLoadingText: TUnicodeStringEvent; aOnCursorUpdate: TIntegerStringEvent; NoMusic: Boolean = False);
begin
  inherited Create;

  fOnCursorUpdate := aOnCursorUpdate;

  fGameSettings := TKMGameSettings.Create;

  fServerSettings := TKMServerSettings.Create;

  fLastTimeRender := 0;

  gRender := TRender.Create(aRenderControl, aScreenX, aScreenY, aVSync);

  fChat := TKMChat.Create;

  gGameCursor := TKMGameCursor.Create;

  if fGameSettings.DebugSaveRandomChecks and SAVE_RANDOM_CHECKS then
    gRandomCheckLogger := TKMRandomCheckLogger.Create;

  gRes := TKMResource.Create(aOnLoadingStep, aOnLoadingText);
  gRes.LoadMainResources(fGameSettings.Locale, fGameSettings.LoadFullFonts);
  fKeysSettings := TKMKeysSettings.Create;

  {$IFDEF USE_MAD_EXCEPT}gExceptions.LoadTranslation;{$ENDIF}

  //Show the message if user has old OpenGL drivers (pre-1.4)
  if gRender.IsOldGLVersion then
    //MessageDlg works better than Application.MessageBox or others, it stays on top and
    //pauses here until the user clicks ok.
    MessageDlg(gResTexts[TX_GAME_ERROR_OLD_OPENGL] + EolW + EolW + gResTexts[TX_GAME_ERROR_OLD_OPENGL_2], mtWarning, [mbOk], 0);

  gSoundPlayer  := TKMSoundPlayer.Create(fGameSettings.SoundFXVolume);
  gMusic     := TKMMusicLib.Create(fGameSettings.MusicVolume);
  gSoundPlayer.OnRequestFade   := gMusic.Fade;
  gSoundPlayer.OnRequestUnfade := gMusic.Unfade;

  fCampaigns    := TKMCampaignsCollection.Create;
  fCampaigns.Load;

  //If game was reinitialized from options menu then we should return there
  InitMainMenu(aScreenX, aScreenY);

  fTimerUI := TTimer.Create(nil);
  fTimerUI.Interval := GLOBAL_TICK_UPDATE_FREQ;
  fTimerUI.OnTimer  := UpdateState;
  fTimerUI.Enabled  := True;

  //Start the Music playback as soon as loading is complete
  if (not NoMusic) and not fGameSettings.MusicOff then
    gMusic.PlayMenuTrack;

  gMusic.ToggleShuffle(fGameSettings.ShuffleOn); //Determine track order

  fSaveWorkerThread := TKMWorkerThread.Create('SaveWorker');
  fAutoSaveWorkerThread := TKMWorkerThread.Create('AutoSaveWorker');
  fBaseSaveWorkerThread := TKMWorkerThread.Create('BaseSaveWorker');

  fOnGameStart := GameStarted;
  fOnGameEnd := GameEnded;
end;


procedure TKMGameApp.AfterConstruction(aReturnToOptions: Boolean);
begin
  if aReturnToOptions then
    fMainMenuInterface.PageChange(gpOptions)
  else
    fMainMenuInterface.PageChange(gpMainMenu);
end;


{ Destroy what was created }
destructor TKMGameApp.Destroy;
begin
  //Freeing network sockets and OpenAL can result in events like Resize/Paint occuring (seen in crash reports)
  //Set fIsExiting so we know to skip them
  fIsExiting := True;

  //We might have crashed part way through .Create, so we can't assume ANYTHING exists here.
  //Doing so causes a 2nd exception which overrides 1st. Hence check <> nil on everything except Free (TObject.Free does that already)

  if fTimerUI <> nil then fTimerUI.Enabled := False;
  // Stop music immediately, so it doesn't keep playing and jerk while things get destroyed
  if gMusic <> nil then gMusic.Stop;

  StopGame(grSilent);

  //This will ensure all queued work is completed before destruction
  FreeAndNil(fSaveWorkerThread);
  FreeAndNil(fAutoSaveWorkerThread);
  FreeAndNil(fBaseSaveWorkerThread);

  FreeAndNil(fChat);
  FreeAndNil(fTimerUI);
  FreeThenNil(fCampaigns);
  FreeThenNil(fGameSettings);
  FreeThenNil(fKeysSettings);
  FreeThenNil(fServerSettings);
  FreeThenNil(fMainMenuInterface);
  FreeThenNil(gRes);
  FreeThenNil(gSoundPlayer);
  FreeThenNil(gMusic);
  FreeAndNil(fNetworking);
  FreeAndNil(gRandomCheckLogger);
  FreeAndNil(gGameCursor);

  FreeThenNil(gRender);

  inherited;
end;


procedure TKMGameApp.InitMainMenu(aScreenX, aScreenY: Word);
begin
  fMainMenuInterface := TKMMainMenuInterface.Create(aScreenX, aScreenY, fCampaigns,
                                                    NewSingleMap, NewCampaignMap, NewMapEditor, NewReplay, NewSingleSave,
                                                    ToggleLocale, PreloadGameResources, NetworkInit);
end;


procedure TKMGameApp.DebugControlsUpdated(Sender: TObject; aSenderTag: Integer);
begin
  if gGame = nil then
    fMainMenuInterface.DebugControlsUpdated(aSenderTag)
  else
    gGame.DebugControlsUpdated(Sender, aSenderTag);
end;


//Determine if the game can be closed without loosing any important progress
function TKMGameApp.CanClose: Boolean;
begin
  //There are no unsaved changes in MainMenu and in Replays
  //In all other cases (maybe except gsOnHold?) there are potentially unsaved changes
  Result := (gGame = nil) or gGame.Params.IsReplay;
end;


procedure TKMGameApp.ToggleLocale(const aLocale: AnsiString);
begin
  Assert(gGame = nil, 'We don''t want to recreate whole fGame for that. Let''s limit it only to MainMenu');

  gLog.AddTime('Toggle to locale ' + UnicodeString(aLocale));
  fMainMenuInterface.PageChange(gpLoading, gResTexts[TX_MENU_NEW_LOCALE]);
  Render; //Force to repaint information screen

  fTimerUI.Enabled := False; //Disable it while switching, if an OpenAL error appears the timer should be disabled
  fGameSettings.Locale := aLocale; //Wrong Locale will be ignored

  //Release resources that use Locale info
  FreeAndNil(fNetworking);
  FreeAndNil(fCampaigns);
  FreeAndNil(fMainMenuInterface);

  //Recreate resources that use Locale info
  gRes.LoadLocaleResources(fGameSettings.Locale);
  //Fonts might need reloading too
  gRes.LoadLocaleFonts(fGameSettings.Locale, fGameSettings.LoadFullFonts);

  //Force reload game resources, if they during loading process,
  //as that could cause an error in the loading thread
  //(did not figure it out why. Its easier just to reload game resources in that rare case)
  {$IFDEF LOAD_GAME_RES_ASYNC}
  if fGameSettings.AsyncGameResLoad and not gRes.Sprites.GameResLoadCompleted then
    gRes.LoadGameResources(fGameSettings.AlphaShadows, True);
  {$ENDIF}

  {$IFDEF USE_MAD_EXCEPT}gExceptions.LoadTranslation;{$ENDIF}

  //Campaigns use single locale
  fCampaigns := TKMCampaignsCollection.Create;
  fCampaigns.Load;
  InitMainMenu(gRender.ScreenX, gRender.ScreenY);
  fMainMenuInterface.PageChange(gpOptions);
  Resize(gRender.ScreenX, gRender.ScreenY); //Force the recreated main menu to resize to the user's screen
  fTimerUI.Enabled := True; //Safe to enable the timer again
end;


//Preload game resources while in menu
procedure TKMGameApp.PreloadGameResources;
begin
  {$IFDEF LOAD_GAME_RES_ASYNC}
  //Load game resources asychronously (by other thread)
  if fGameSettings.AsyncGameResLoad then
    gRes.LoadGameResources(fGameSettings.AlphaShadows, True);
  {$ENDIF}
end;


procedure TKMGameApp.Resize(X,Y: Integer);
begin
  if Self = nil then Exit;
  if fIsExiting then Exit;

  gRender.Resize(X, Y);
  gVideoPlayer.Resize(X, Y);

  //Main menu is invisible while in game, but it still exists and when we return to it
  //it must be properly sized (player could resize the screen while playing)
  fMainMenuInterface.Resize(X, Y);

  if gGame <> nil then
    gGame.ActiveInterface.Resize(X, Y);
end;


procedure TKMGameApp.KeyDown(Key: Word; Shift: TShiftState);
var
  keyHandled: Boolean;
begin
  if gVideoPlayer.IsActive then
  begin
    gVideoPlayer.KeyDown(Key, Shift);
    Exit;
  end;

  if gGame <> nil then
    gGame.ActiveInterface.KeyDown(Key, Shift, keyHandled)
  else
    fMainMenuInterface.KeyDown(Key, Shift, keyHandled);
end;


procedure TKMGameApp.KeyPress(Key: Char);
begin
  if gGame <> nil then
    gGame.ActiveInterface.KeyPress(Key)
  else
    fMainMenuInterface.KeyPress(Key);
end;


procedure TKMGameApp.KeyUp(Key: Word; Shift: TShiftState);
var
  keyHandled: Boolean;
begin
  //List of conflicting keys that we should try to avoid using in debug/game:
  //  F12 Pauses Execution and switches to debug
  //  F10 sets focus on MainMenu1
  //  F9 is the default key in Fraps for video capture
  //  F4 and F9 are used in debug to control run-flow
  //  others.. unknown

  keyHandled := False;

  if gGame <> nil then
    gGame.ActiveInterface.KeyUp(Key, Shift, keyHandled)
  else
    fMainMenuInterface.KeyUp(Key, Shift, keyHandled);
end;


procedure TKMGameApp.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if gVideoPlayer.IsActive then
  begin
    gVideoPlayer.MouseDown(Button, Shift, X, Y);
    Exit;
  end;

  if gGame <> nil then
    gGame.ActiveInterface.MouseDown(Button,Shift,X,Y)
  else
    fMainMenuInterface.MouseDown(Button,Shift,X,Y);
end;


procedure TKMGameApp.MouseMove(Shift: TShiftState; X,Y: Integer);
var
  ctrl: TKMControl;
  ctrlID: Integer;
begin
  if not InRange(X, 1, gRender.ScreenX - 1)
  or not InRange(Y, 1, gRender.ScreenY - 1) then
    Exit; // Exit if Cursor is outside of frame

  if gGame <> nil then
    gGame.ActiveInterface.MouseMove(Shift,X,Y)
  else
    //fMainMenuInterface = nil while loading a new locale
    if fMainMenuInterface <> nil then
      fMainMenuInterface.MouseMove(Shift, X,Y);

  if Assigned(fOnCursorUpdate) then
  begin
    fOnCursorUpdate(SB_ID_CURSOR_COORD, Format('Cursor: %d:%d', [X, Y]));
    fOnCursorUpdate(SB_ID_TILE,         Format('Tile: %.1f:%.1f [%d:%d]',
                               [gGameCursor.Float.X, gGameCursor.Float.Y,
                               gGameCursor.Cell.X, gGameCursor.Cell.Y]));
    if SHOW_CONTROLS_ID then
    begin
      if gGame <> nil then
        ctrl := gGame.ActiveInterface.MyControls.HitControl(X,Y, True)
      else
        ctrl := fMainMenuInterface.MyControls.HitControl(X,Y, True);
      ctrlID := -1;
      if ctrl <> nil then
        ctrlID := ctrl.ID;
      fOnCursorUpdate(SB_ID_CTRL_ID, Format('Control ID: %d', [ctrlID]));
    end;
  end;
end;


procedure TKMGameApp.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if gGame <> nil then
    gGame.ActiveInterface.MouseUp(Button,Shift,X,Y)
  else
    fMainMenuInterface.MouseUp(Button, Shift, X,Y);
end;


procedure TKMGameApp.MouseWheel(Shift: TShiftState; WheelSteps: Integer; X, Y: Integer; var aHandled: Boolean);
begin
  aHandled := False;
  if Self = nil then Exit;

  if gGame <> nil then
    gGame.ActiveInterface.MouseWheel(Shift, WheelSteps, X, Y, aHandled)
  else
    fMainMenuInterface.MouseWheel(Shift, WheelSteps, X, Y, aHandled);
end;


procedure TKMGameApp.FPSMeasurement(aFPS: Cardinal);
begin
  fNetworking.FPSMeasurement(aFPS);
end;


function TKMGameApp.Game: TKMGame;
begin
  if Self = nil then Exit(nil);

  Result := gGame;
end;


procedure TKMGameApp.GameLoadingStep(const aText: UnicodeString);
begin
  fMainMenuInterface.AppendLoadingText(aText);
  Render;
end;


procedure TKMGameApp.LoadGameAssets;
begin
  //Load the resources if necessary
  fMainMenuInterface.PageChange(gpLoading);
  Render;

  GameLoadingStep(gResTexts[TX_MENU_LOADING_DEFINITIONS]);
  gRes.OnLoadingText := GameLoadingStep;
  gRes.LoadGameResources(fGameSettings.AlphaShadows);

  GameLoadingStep(gResTexts[TX_MENU_LOADING_INITIALIZING]);

  GameLoadingStep(gResTexts[TX_MENU_LOADING_SCRIPT]);
end;


procedure TKMGameApp.SaveCampaignsProgress;
begin
  if fCampaigns <> nil then
    fCampaigns.SaveProgress;
end;


procedure TKMGameApp.UnlockAllCampaigns;
begin
  if fCampaigns <> nil then
  begin
    fCampaigns.UnlockAllCampaignsMissions;
    fCampaigns.SaveProgress;

    fMainMenuInterface.RefreshCampaigns;
  end;
end;


procedure TKMGameApp.CreateGame(aGameMode: TKMGameMode);
begin
  gGame := TKMGame.Create(aGameMode, gRender, GameDestroyed, fSaveWorkerThread, fBaseSaveWorkerThread, fAutoSaveWorkerThread);
end;


procedure TKMGameApp.PrepageStopGame(aMsg: TKMGameResultMsg);
var
  lastSentCmdsTick: Integer;
begin
  if (gGame = nil) or gGame.ReadyToStop then Exit;

  gSoundPlayer.AbortAllLongSounds; //SFX with a long duration should be stopped when quitting

  if aMsg in [grWin, grDefeat, grCancel, grSilent] then
  begin
    //If the game was a part of a campaign, select that campaign,
    //so we know which menu to show next and unlock next map
    fCampaigns.SetActive(fCampaigns.CampaignById(gGame.CampaignName), gGame.CampaignMap);

    if fCampaigns.ActiveCampaign <> nil then
    begin
      //Always save campaign data, even if the player lost (scripter can choose when to modify it)
      fCampaigns.ActiveCampaign.ScriptData.Clear;
      gGame.SaveCampaignScriptData(fCampaigns.ActiveCampaign.ScriptData);

      if aMsg = grWin then
        fCampaigns.UnlockNextMap; //Unlock next map before save campaign progress

      //Always save Campaigns progress after mission
      //We always save script data with SaveCampaignScriptData
      //then campaign progress should be saved always as well on any outcome (win or lose)
      //otherwise we will get inconsistency
      SaveCampaignsProgress;
    end;
  end;

  if gGame.Params.IsMultiPlayerOrSpec then
  begin
    if fNetworking.Connected then
    begin
      if TKMGameInputProcess_Multi(gGame.GameInputProcess) <> nil then
        lastSentCmdsTick := TKMGameInputProcess_Multi(gGame.GameInputProcess).LastSentCmdsTick
      else
        lastSentCmdsTick := LAST_SENT_COMMANDS_TICK_NONE;
      fNetworking.AnnounceDisconnect(lastSentCmdsTick);
    end;
    fNetworking.Disconnect;
  end;

  gGame.ReadyToStop := True;

  if (gGame.GamePlayInterface <> nil) and (gGame.GamePlayInterface.GuiGameSpectator <> nil) then
    gGame.GamePlayInterface.GuiGameSpectator.CloseDropBox;

  if (gGame.GameResult in [grWin, grDefeat]) and not gGame.Params.IsReplay then
  begin
    GameFinished;
    if fGameSettings.AutosaveAtGameEnd then
      // We have to use local time for local save name (Now) and UTC time inside the save (UTCNow, it will be converted back to local on read)
      gGame.Save(Format('%s %s #%d', [gGame.Params.Name, FormatDateTime('yyyy-mm-dd', Now), fGameSettings.DayGamesCount]), UTCNow);
  end;

  if Assigned(fOnGameEnd) then
    fOnGameEnd(gGame.Params.Mode);
end;


//Game needs to be stopped
//1. Disconnect from network
//2. Save games replay
//3. Fill in game results
//4. Fill in menu message if needed
//5. Free the game object
//6. Switch to MainMenu
procedure TKMGameApp.StopGame(aMsg: TKMGameResultMsg; const aTextMsg: UnicodeString = '');
begin
  if gGame = nil then Exit;

  PrepageStopGame(aMsg);

  case aMsg of
    grWin,
    grDefeat,
    grCancel:      case gGame.Params.Mode of
                      gmSingle:         fMainMenuInterface.PageChange(gpSinglePlayer);
                      gmCampaign:       if aTextMsg = '' then //Rely on text message (for campaign it should contain CampaignID)
                                          fMainMenuInterface.PageChange(gpMainMenu) //Goto main menu in case we fail campaing mission
                                        else
                                          fMainMenuInterface.PageChange(gpCampaign, aTextMsg); //Goto Campaign menu in case we win campaing mission
                      gmMulti,
                      gmMultiSpectate:  fMainMenuInterface.PageChange(gpMultiplayer);
                    end;
    grReplayEnd:   fMainMenuInterface.PageChange(gpReplays);
    grError,
    grDisconnect:  begin
                      if gGame.Params.IsMultiPlayerOrSpec then
                        //After Error page User will go to the main menu, but Mutex will be still locked.
                        //We will need to unlock it on gGame destroy, so mark it with GameLockedMutex
                        gGame.LockedMutex := True;
                      fMainMenuInterface.PageChange(gpError, aTextMsg);
                    end;
    grSilent:      ;//Used when loading new savegame from gameplay UI
    grMapEdEnd:    fMainMenuInterface.PageChange(gpMapEditor);
  end;

  FreeThenNil(gGame);
  gLog.AddTime('Gameplay ended - ' + GetEnumName(TypeInfo(TKMGameResultMsg), Integer(aMsg)) + ' /' + aTextMsg);
end;


procedure TKMGameApp.AnnounceReturnToLobby;
begin
  //When this GIC command is executed, it will run PrepareReturnToLobby
  gGame.GameInputProcess.CmdGame(gicGameSaveReturnLobby, UTCNow);
end;


procedure TKMGameApp.PrepareReturnToLobby(aTimestamp: TDateTime);
begin
  if gGame = nil then Exit;
  gGame.Save(RETURN_TO_LOBBY_SAVE, aTimestamp);
  gGame.IsPaused := True; //Freeze the game
  fNetworking.AnnounceReadyToReturnToLobby;
  //Now we wait for other clients to reach this step, then fNetworking triggers StopGameReturnToLobby
end;


procedure TKMGameApp.StopGameReturnToLobby;
begin
  if gGame = nil then Exit;

  FreeThenNil(gGame);
  fNetworking.ReturnToLobby; //Clears gGame event pointers from Networking
  fMainMenuInterface.ReturnToLobby(RETURN_TO_LOBBY_SAVE); //Assigns Lobby event pointers to Networking and selects map
  if fNetworking.IsHost then
    fNetworking.SendPlayerListAndRefreshPlayersSetup; //Call now that events are attached to lobby

  gLog.AddTime('Gameplay ended - Return to lobby');
end;


procedure TKMGameApp.LoadGameFromSave(const aFilePath: String; aGameMode: TKMGameMode; const aGIPPath: String = '');
var
  loadError, filePath: String;
begin
  //Save const aFilePath locally, since it could be destroyed as some Game Object instance in StopGame
  //!!!!! DO NOT USE aMissionFile or aGameName further in this method
  filePath := aFilePath;
  //----------------------------------------------------------------------
  StopGame(grSilent); //Stop everything silently
  LoadGameAssets;

  //Reset controls if MainForm exists (KMR could be run without main form)
  if gMain <> nil then
    gMain.FormMain.ControlsReset;

  CreateGame(aGameMode);
  try
    gGame.LoadFromFile(filePath, aGIPPath);
  except
    on E: Exception do
    begin
      //Trap the exception and show it to the user in nicer form.
      //Note: While debugging, Delphi will still stop execution for the exception,
      //unless Tools > Debugger > Exception > "Stop on Delphi Exceptions" is unchecked.
      //But to normal player the dialog won't show.
      loadError := Format(gResTexts[TX_MENU_PARSE_ERROR], [filePath]) + '||' + E.ClassName + ': ' + E.Message;
      StopGame(grError, loadError);
      gLog.AddTime('Game creation Exception: ' + loadError
        {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF}
        );
      Exit;
    end;
  end;

  gGame.AfterLoad; //Call after load separately, so errors in it could be sended in crashreport

  if Assigned(fOnCursorUpdate) then
    fOnCursorUpdate(SB_ID_MAP_SIZE, gGame.MapSizeInfo);
end;


//Do not use _const_ aMissionFile, aGameName: UnicodeString, as for some unknown reason sometimes aGameName is not accessed after StopGame(grSilent) (pointing to a wrong value)
procedure TKMGameApp.LoadGameFromScript(const aMissionFile, aGameName: String; aFullCRC, aSimpleCRC: Cardinal; aCampaign: TKMCampaign;
                                        aMap: Byte; aGameMode: TKMGameMode; aDesiredLoc: ShortInt; aDesiredColor: Cardinal;
                                        aDifficulty: TKMMissionDifficulty = mdNone; aAIType: TKMAIType = aitNone;
                                        aAutoselectHumanLoc: Boolean = False);
var
  loadError, missionFile, gameName: String;
begin
  //Save const parameters locally, since it could be destroyed as some Game Object instance in StopGame
  //!!!!! DO NOT USE aMissionFile or aGameName further in this method
  missionFile := aMissionFile;
  gameName := aGameName;
  //!!!!! ------------------------------------------------------------
  StopGame(grSilent); //Stop everything silently
  LoadGameAssets;

  //Reset controls if MainForm exists (KMR could be run without main form)
  if gMain <> nil then
    gMain.FormMain.ControlsReset;

  CreateGame(aGameMode);
  try
    gGame.Start(missionFile, gameName, aFullCRC, aSimpleCRC, aCampaign, aMap, aDesiredLoc, aDesiredColor, aDifficulty, aAIType, aAutoselectHumanLoc);
  except
    on E : Exception do
    begin
      //Trap the exception and show it to the user in nicer form.
      //Note: While debugging, Delphi will still stop execution for the exception,
      //unless Tools > Debugger > Exception > "Stop on Delphi Exceptions" is unchecked.
      //But to normal player the dialog won't show.
      loadError := Format(gResTexts[TX_MENU_PARSE_ERROR], [missionFile]) + '||' + E.ClassName + ': ' + E.Message;
      StopGame(grError, loadError);
      gLog.AddTime('Game creation Exception: ' + loadError
        {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF}
        );
      Exit;
    end;
  end;

  //Clear chat for SP game, as it useddthere only for console commands
  if gGame.Params.IsSingleplayerGame then
    fChat.Clear;

  gGame.AfterStart; //Call after start separately, so errors in it could be sended in crashreport

  if Assigned(fOnCursorUpdate) then
    fOnCursorUpdate(SB_ID_MAP_SIZE, gGame.MapSizeInfo);
end;


procedure TKMGameApp.LoadGameSavePoint(aTick: Cardinal);
var
  loadError: string;
  savedReplays: TKMSavePointCollection;
  gameMode: TKMGameMode;
  saveFile: UnicodeString;
  gameInputProcess: TKMGameInputProcess;
begin
  if (gGame = nil) then Exit;

  // Get existing configuration
  savedReplays := gGame.SavePoints;
  gGame.SavePoints := nil;
  gameMode := gGame.Params.Mode;
  saveFile := gGame.SaveFile;
  // Store GIP locally, to restore it later
  // GIP is the same for every checkpoint, that is why its not stored in the saved replay checkpoint, so we can reuse it
  gameInputProcess := gGame.GameInputProcess;
  gGame.GameInputProcess := nil;

  StopGame(grSilent); //Stop everything silently
  LoadGameAssets;

  //Reset controls if MainForm exists (KMR could be run without main form)
  if gMain <> nil then
    gMain.FormMain.ControlsReset;

  CreateGame(gameMode);
  try
    // SavedReplays have been just created, and we will reassign them in the next line.
    // Then Free the newly created save replays object first
    gGame.SavePoints.Free;
    gGame.SavePoints := savedReplays;
    gGame.LoadSavePoint(aTick, saveFile);
    gGame.LastReplayTick := Max(gGame.LastReplayTick, savedReplays.LastTick);
    // Free GIP, which was created on game creation
    gGame.GameInputProcess.Free;
    // Restore GIP
    gGame.GameInputProcess := gameInputProcess;
    // Move GIP cursor to the actual position
    gGame.GameInputProcess.MoveCursorTo(aTick);
  except
    on E: Exception do
    begin
      //Trap the exception and show it to the user in nicer form.
      //Note: While debugging, Delphi will still stop execution for the exception,
      //unless Tools > Debugger > Exception > "Stop on Delphi Exceptions" is unchecked.
      //But to normal player the dialog won't show.
      loadError := '||' + E.ClassName + ': ' + E.Message;
      StopGame(grError, loadError);
      gLog.AddTime('Game creation Exception: ' + loadError
        {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF}
        );
      Exit;
    end;
  end;

  gGame.AfterLoad; //Call after load separately, so errors in it could be sended in crashreport

  if Assigned(fOnCursorUpdate) then
    fOnCursorUpdate(SB_ID_MAP_SIZE, gGame.MapSizeInfo);
end;


procedure TKMGameApp.LoadGameFromScratch(aSizeX, aSizeY: Integer; aGameMode: TKMGameMode);
var
  loadError: string;
begin
  StopGame(grSilent); //Stop everything silently
  LoadGameAssets;

  //Reset controls if MainForm exists (KMR could be run without main form)
  if gMain <> nil then
    gMain.FormMain.ControlsReset;

  CreateGame(aGameMode);
  gGame.SetSeed(4); //Every time the game will be the same as previous. Good for debug.
  try
    gGame.MapEdStartEmptyMap(aSizeX, aSizeY);
  except
    on E : Exception do
    begin
      //Trap the exception and show it to the user in nicer form.
      //Note: While debugging, Delphi will still stop execution for the exception,
      //unless Tools > Debugger > Exception > "Stop on Delphi Exceptions" is unchecked.
      //But to normal player the dialog won't show.
      loadError := Format(gResTexts[TX_MENU_PARSE_ERROR], ['-']) + '||' + E.ClassName + ': ' + E.Message;
      StopGame(grError, loadError);
      gLog.AddTime('Game creation Exception: ' + loadError
        {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF}
        );
      Exit;
    end;
  end;

  if Assigned(fOnCursorUpdate) then
    fOnCursorUpdate(SB_ID_MAP_SIZE, gGame.MapSizeInfo);
end;


procedure TKMGameApp.NewCampaignMap(aCampaignId: TKMCampaignId; aMap: Byte; aDifficulty: TKMMissionDifficulty = mdNone);
var
  camp: TKMCampaign;
begin
  camp := fCampaigns.CampaignById(aCampaignId);
  LoadGameFromScript(camp.GetMissionFile(aMap), camp.GetMissionTitle(aMap), 0, 0, camp, aMap, gmCampaign, -1, 0, aDifficulty);

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.NewSingleMap(const aMissionFile, aGameName: UnicodeString; aDesiredLoc: ShortInt = -1;
                                  aDesiredColor: Cardinal = $00000000; aDifficulty: TKMMissionDifficulty = mdNone;
                                  aAIType: TKMAIType = aitNone; aAutoselectHumanLoc: Boolean = False);
begin
  LoadGameFromScript(aMissionFile, aGameName, 0, 0, nil, 0, gmSingle, aDesiredLoc, aDesiredColor, aDifficulty, aAIType,
                     aAutoselectHumanLoc);

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.NewSingleSave(const aSaveName: UnicodeString);
begin
  //Convert SaveName to local FilePath
  LoadGameFromSave(SaveName(aSaveName, EXT_SAVE_MAIN, False), gmSingle);

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.NewMultiplayerMap(const aFileName: UnicodeString; aMapFolder: TKMapFolder; aCRC: Cardinal; aSpectating: Boolean;
                                       aDifficulty: TKMMissionDifficulty);
var
  gameMode: TKMGameMode;
begin
  if aSpectating then
    gameMode := gmMultiSpectate
  else
    gameMode := gmMulti;
  LoadGameFromScript(TKMapsCollection.FullPath(aFileName, '.dat', aMapFolder, aCRC), aFileName, aCRC, 0, nil, 0, gameMode, 0, 0, aDifficulty);

  //Starting the game might have failed (e.g. fatal script error)
  if gGame <> nil then
  begin
    gGame.GamePlayInterface.GameStarted;

    if Assigned(fOnGameStart) and (gGame <> nil) then
      fOnGameStart(gGame.Params.Mode);
  end;
end;


procedure TKMGameApp.NewMultiplayerSave(const aSaveName: UnicodeString; Spectating: Boolean);
var
  gameMode: TKMGameMode;
begin
  if Spectating then
    gameMode := gmMultiSpectate
  else
    gameMode := gmMulti;
  //Convert SaveName to local FilePath
  //aFileName is the same for all players, but Path to it is different
  LoadGameFromSave(SaveName(aSaveName, EXT_SAVE_MAIN, True), gameMode);

  //Copy the chat and typed lobby message to the in-game chat
  gGame.GamePlayInterface.GameStarted;

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.NewRestartLast(const aGameName, aMission, aSave: UnicodeString; aGameMode: TKMGameMode;
                                    aCampName: TKMCampaignId; aCampMap: Byte; aLocation: Byte; aColor: Cardinal;
                                    aDifficulty: TKMMissionDifficulty = mdNone; aAIType: TKMAIType = aitNone);
begin
  if FileExists(ExeDir + aMission) then
    LoadGameFromScript(ExeDir + aMission, aGameName, 0, 0, fCampaigns.CampaignById(aCampName), aCampMap, aGameMode, aLocation, aColor, aDifficulty, aAIType)
  else
  if FileExists(ChangeFileExt(ExeDir + aSave, EXT_SAVE_BASE_DOT)) then
    LoadGameFromSave(ChangeFileExt(ExeDir + aSave, EXT_SAVE_BASE_DOT), aGameMode)
  else
    fMainMenuInterface.PageChange(gpError, 'Can not repeat last mission');

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);

end;


//Used by Runner util
procedure TKMGameApp.NewEmptyMap(aSizeX, aSizeY: Integer);
begin
  LoadGameFromScratch(aSizeX, aSizeY, gmSingle);

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);

end;


procedure TKMGameApp.NewMapEditor(const aFileName: UnicodeString; aSizeX: Integer = 0; aSizeY: Integer = 0;
                                  aMapFullCRC: Cardinal = 0; aMapSimpleCRC: Cardinal = 0; aMultiplayerLoadMode: Boolean = False);
begin
  if aFileName <> '' then
  begin
    LoadGameFromScript(aFileName, TruncateExt(ExtractFileName(aFileName)), aMapFullCRC, aMapSimpleCRC, nil, 0, gmMapEd, 0, 0);
    // gGame could be nil if we failed to load map
    if gGame <> nil then
      gGame.MapEditorInterface.SetLoadMode(aMultiplayerLoadMode);
  end
  else begin
    aSizeX := EnsureRange(aSizeX, MIN_MAP_SIZE, MAX_MAP_SIZE);
    aSizeY := EnsureRange(aSizeY, MIN_MAP_SIZE, MAX_MAP_SIZE);
    LoadGameFromScratch(aSizeX, aSizeY, gmMapEd);
    // gGame could be nil if we failed to load map
    if gGame <> nil then
      gGame.MapEditorInterface.SetLoadMode(aMultiplayerLoadMode);
  end;

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.SaveMapEditor(const aPathName: UnicodeString);
begin
  if aPathName <> '' then
    gGame.SaveMapEditor(aPathName);
end;


procedure TKMGameApp.NewReplay(const aFilePath: UnicodeString);
begin
  Assert(ExtractFileExt(aFilePath) = EXT_SAVE_BASE_DOT);
  LoadGameFromSave(aFilePath, gmReplaySingle); //Will be changed to gmReplayMulti depending on save contents

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.NewSaveAndReplay(const aSavPath, aRplPath: UnicodeString);
begin
  LoadGameFromSave(aSavPath, gmReplaySingle, aRplPath); //Will be changed to gmReplayMulti depending on save contents

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


// Good for debug, when need to load savepoint from debugger before known crash during debugging tick
procedure TKMGameApp.LoadPrevSavePoint;
begin
  if (gGame = nil) or (gGame.SavePoints = nil) then Exit;

  TryLoadSavePoint(gGame.SavePoints.LatestPointTickBefore(gGame.Params.Tick));
end;


function TKMGameApp.TryLoadSavePoint(aTick: Integer): Boolean;
begin
  Result := False;

  if (gGame = nil) or (gGame.SavePoints = nil) then Exit;
  
  if not gGame.SavePoints.Contains(aTick) then Exit;

  LoadGameSavePoint(aTick);
  Result := True;

  if Assigned(fOnGameStart) and (gGame <> nil) then
    fOnGameStart(gGame.Params.Mode);
end;


procedure TKMGameApp.GameStarted(aGameMode: TKMGameMode);
begin
  if gMain <> nil then
  begin
    gMain.FormMain.SetExportGameStats(aGameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti]);
    gMain.FormMain.SetSaveEditableMission(aGameMode = gmMapEd);
  end;
end;


function TKMGameApp.GetGameSettings: TKMGameSettings;
begin
  if Self = nil then Exit(nil);

  Result := fGameSettings;
end;


procedure TKMGameApp.GameEnded(aGameMode: TKMGameMode);
begin
  if gMain <> nil then
  begin
    gMain.FormMain.SetExportGameStats((aGameMode in [gmMultiSpectate, gmReplaySingle, gmReplayMulti])
                                       or (gGame.GameResult in [grWin, grDefeat]));
    gMain.FormMain.SetSaveEditableMission(False);
  end;

  if Assigned(FormLogistics) then
    FormLogistics.Clear;
end;


procedure TKMGameApp.GameDestroyed;
begin
  if gMain <> nil then
    gMain.FormMain.SetExportGameStats(False);
end;


//Happens when game was won or lost
procedure TKMGameApp.GameFinished;
begin
  if CompareDate(fGameSettings.LastDayGamePlayed, Today) < 0 then
    fGameSettings.DayGamesCount := 0;

  fGameSettings.LastDayGamePlayed := Today;
  fGameSettings.DayGamesCount := fGameSettings.DayGamesCount + 1;
end;


function TKMGameApp.SaveName(const aName, aExt: UnicodeString; aIsMultiplayer: Boolean): UnicodeString;
begin
  Result := TKMSavesCollection.FullPath(aName, aExt, aIsMultiplayer);
end;


procedure TKMGameApp.NetworkInit;
begin
  if fNetworking = nil then
    fNetworking := TKMNetworking.Create(fServerSettings.MasterServerAddress,
                                        fServerSettings.AutoKickTimeout,
                                        fServerSettings.PingInterval,
                                        fServerSettings.MasterAnnounceInterval,
                                        fServerSettings.ServerUDPScanPort,
                                        fServerSettings.ServerPacketsAccumulatingDelay,
                                        fServerSettings.ServerDynamicFOW,
                                        fServerSettings.ServerMapsRosterEnabled,
                                        fServerSettings.ServerMapsRosterStr,
                                        KMRange(fServerSettings.ServerLimitPTFrom, fServerSettings.ServerLimitPTTo),
                                        KMRange(fServerSettings.ServerLimitSpeedFrom, fServerSettings.ServerLimitSpeedTo),
                                        KMRange(fServerSettings.ServerLimitSpeedAfterPTFrom, fServerSettings.ServerLimitSpeedAfterPTTo));

  // Set event handlers anyway. Those could be reset by someone
  fNetworking.OnMPGameInfoChanged := SendMPGameInfo;
  fNetworking.OnStartMap := NewMultiplayerMap;
  fNetworking.OnStartSave := NewMultiplayerSave;
  fNetworking.OnAnnounceReturnToLobby := AnnounceReturnToLobby;
  fNetworking.OnDoReturnToLobby := StopGameReturnToLobby;
end;


//Called by fNetworking to access MissionTime/GameName if they are valid
//fNetworking knows nothing about fGame
procedure TKMGameApp.SendMPGameInfo;
begin
  if gGame <> nil then
    fNetworking.AnnounceGameInfo(gGame.MissionTime, gGame.Params.Name)
  else
    fNetworking.AnnounceGameInfo(-1, ''); //fNetworking will fill the details from lobby
end;


procedure TKMGameApp.SetOnOptionsChange(const aEvent: TEvent);
begin
  fOnOptionsChange := aEvent;

  fMainMenuInterface.SetOnOptionsChange(aEvent);
end;


procedure TKMGameApp.Render(aForPrintScreen: Boolean = False);
begin
  if Self = nil then Exit;
  if SKIP_RENDER then Exit;
  if fIsExiting then Exit;
  if gRender.Blind then Exit;
  if not fTimerUI.Enabled then Exit; //Don't render while toggling locale

  gRender.BeginFrame;

  {$IFDEF PERFLOG}
  gPerfLogs.StackGFX.FrameBegin;
  gPerfLogs.SectionEnter(psFrameFullG);

  try
  {$ENDIF}
    if gVideoPlayer.IsActive then
      gVideoPlayer.Paint
    else
    if gGame <> nil then
      gGame.Render(gRender)
    else
      fMainMenuInterface.Paint;

    gRender.RenderBrightness(fGameSettings.Brightness);
  {$IFDEF PERFLOG}
  finally
    gPerfLogs.SectionLeave(psFrameFullG);
    gPerfLogs.StackGFX.FrameEnd;
  end;

  if gMain <> nil then
    gPerfLogs.Render(TOOLBAR_WIDTH + 10, gMain.FormMain.RenderArea.Width - 10, gMain.FormMain.RenderArea.Height - 10);
  {$ENDIF}

  gRender.EndFrame;
  gRender.Query.QueriesSwapBuffers;

  fLastTimeRender := TimeGet;

  if not aForPrintScreen and (gGame <> nil) then
    if Assigned(fOnCursorUpdate) then
      fOnCursorUpdate(SB_ID_OBJECT, 'Obj: ' + IntToStr(gGameCursor.ObjectUID));
end;


function TKMGameApp.RenderVersion: UnicodeString;
begin
  Result := 'OpenGL ' + gRender.RendererVersion;
end;


procedure TKMGameApp.PrintScreen(const aFilename: UnicodeString = '');
var
  strDate, strName: string;
begin
  Render(True);
  if aFilename = '' then
  begin
    DateTimeToString(strDate, 'yyyy-mm-dd hh-nn-ss', Now); //2007-12-23 15-24-33
    strName := ExeDir + 'screenshots\KaM Remake ' + strDate + '.jpg';
  end
  else
    strName := aFilename;

  ForceDirectories(ExtractFilePath(strName));
  gRender.DoPrintScreen(strName);
end;


function TKMGameApp.CheckDATConsistency: Boolean;
begin
  Result := ALLOW_MP_MODS or (gRes.GetDATCRC = $4F5458E6); //That's the magic CRC of official .dat files
end;


procedure TKMGameApp.UpdateState(Sender: TObject);
begin
  //Some PCs seem to change 8087CW randomly between events like Timers and OnMouse*,
  //so we need to set it right before we do game logic processing
  Set8087CW($133F);

  Inc(fGlobalTickCount);
  //Always update networking for auto reconnection and query timeouts
  if fNetworking <> nil then
    fNetworking.UpdateState(fGlobalTickCount);

  gVideoPlayer.UpdateState;

  if gGame <> nil then
  begin
    gGame.UpdateState(fGlobalTickCount);
    if gGame.Params.IsMultiPlayerOrSpec and (fGlobalTickCount mod 100 = 0) then
      SendMPGameInfo; //Send status to the server every 10 seconds
  end
  else
    fMainMenuInterface.UpdateState(fGlobalTickCount);

  //Every 1000ms
  if fGlobalTickCount mod 10 = 0 then
  begin
    // Music
    if not fGameSettings.MusicOff and gMusic.IsEnded then
      gMusic.PlayNextTrack; //Feed new music track

    //StatusBar
    if (gGame <> nil) and not gGame.IsPaused and Assigned(fOnCursorUpdate) then
        fOnCursorUpdate(SB_ID_TIME, 'Time: ' + TimeToString(gGame.MissionTime));
  end;

  if (gMain <> nil) //Could be nil for Runner Util
    and (gMain.Settings <> nil)
    and gMain.Settings.IsNoRenderMaxTimeSet
    and (TimeSince(fLastTimeRender) > gMain.Settings.NoRenderMaxTime) then
    Render;
end;


// This is our real-time "thread", use it wisely
procedure TKMGameApp.UpdateStateIdle(aFrameTime: Cardinal);
begin
  if gGame <> nil then gGame.UpdateStateIdle(aFrameTime);
  if gMusic <> nil then gMusic.UpdateStateIdle;
  if gSoundPlayer <> nil then gSoundPlayer.UpdateStateIdle;
  if fNetworking <> nil then fNetworking.UpdateStateIdle;
  if gRes <> nil then gRes.UpdateStateIdle;
end;


end.

unit KM_Main;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  KM_FormMain, KM_FormLoading, KM_Maps,
  KM_MainSettings, KM_Resolutions, KM_Video,
  KM_WindowParams,
  KM_GameAppSettings
  {$IFDEF FPC}
  , Types
  {$ENDIF}
  ;


type
  // Provides basement for the Game App
  // Should be abstract enough, so that the Game could be a race-sim or a quest or any other
  TKMMain = class
  private
    fFormMain: TFormMain;
    fFormLoading: TFormLoading;

    fGameTickInterval: Cardinal;

    fRenderSchedule, fTickSchedule, fUpdateStateSchedule: Cardinal;
    fLastRenderTime, fOldFrameTimes, fFrameCount: Cardinal;
    {$IFDEF MSWindows}
    fMutex: THandle;
    {$ENDIF}

//    fMainSettings: TKMainSettings;
    fResolutions: TKMResolutions;
    fMapCacheUpdater: TTMapsCacheUpdater;

    fFPS: Single;
    fFPSString: String;

    procedure DoRestore(Sender: TObject);
    procedure DoActivate(Sender: TObject);
    procedure DoDeactivate(Sender: TObject);
    procedure DoIdle(Sender: TObject; var Done: Boolean);

    function GetRenderInterval: Cardinal;
    function ForcedRenderRequired: Boolean;

    procedure DoRender;
    procedure SleepUntilNextSchedule;

    procedure MapCacheUpdate;
    procedure UpdateFPS(latestFrameTime: Cardinal);

    procedure GameSpeedChange(aSpeed: Single);
    function DoHaveGenericPermission: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function Start: Boolean;
    procedure CloseQuery(var aCanClose: Boolean);
    procedure Stop(Sender: TObject);

    procedure UpdateWindowParams(const aWindowParams: TKMWindowParamsRecord);
    procedure Move(const aWindowParams: TKMWindowParamsRecord);
    procedure ForceResize;
    procedure Resize(aWidth, aHeight: Integer); overload;
    procedure Resize(aWidth, aHeight: Integer; const aWindowParams: TKMWindowParamsRecord); overload;
    procedure Render;
    procedure ShowAbout;
    property FormMain: TFormMain read fFormMain;

    procedure ApplyCursorRestriction;
    function GetScreenBounds(out aBounds: TRect): Boolean;
    function IsFormActive: Boolean;
    function ClientRect(aPixelsCntToReduce: Integer = 0): TRect;
    function ClientToScreen(aPoint: TPoint): TPoint;
    function ReinitRender(aReturnToOptions: Boolean): Boolean;

    property FPSString: String read fFPSString;

    function IsDebugChangeAllowed: Boolean;

    function LockMutex: Boolean;
    procedure UnlockMutex;

    procedure StatusBarText(aPanelIndex: Integer; const aText: UnicodeString);

    procedure SetGameTickInterval(aInterval: Cardinal);
    property GameTickInterval: Cardinal read fGameTickInterval;

    property Resolutions: TKMResolutions read fResolutions;
  end;


var
  gMain: TKMMain;


implementation
uses
  Classes, SysUtils, SysConst, StrUtils, Math,
  Forms,
  {$IF DEFINED(MSWindows)}
  MMSystem,
  {$ELSEIF DEFINED(Unix)}
  Dialogs, LCLType, Controls,
  {$ENDIF}
  {$IFDEF USE_MAD_EXCEPT} KM_Exceptions, {$ENDIF}
  KromUtils, KM_FileIO,
  KM_GameApp, KM_VclHelpers,
  KM_System,
  KM_ResTexts,
  KM_KeysSettings,
  KM_Music,
  KM_Log, KM_CommonUtils, KM_Defaults, KM_Points, KM_DevPerfLog,
  KM_CommonExceptions,
  KromShellUtils, KM_MapTypes;


const
  // Mutex is used to block duplicate app launch on the same PC
  // Random GUID generated in Delphi by Ctrl+Shift+G
  // Generated for versions r13651+
  // We can allow to have beta and r6720 versions to be opened at the same time
  KAM_MUTEX = 'AAF80942-EC97-4D02-9339-07AB8FEFA187';


{$OVERFLOWCHECKS OFF}
function AddWithOverflow(A, B: Cardinal): Cardinal; inline;
begin
  Result := A + B;
end;
{$OVERFLOWCHECKS ON}


{ TKMMain }
constructor TKMMain.Create;
var
  collapsed: Boolean;
begin
  inherited;

  fGameTickInterval := 100;

  // Create exception handler as soon as possible in case it crashes early on
  {$IFDEF USE_MAD_EXCEPT}gExceptions := TKMExceptions.Create;{$ENDIF}

  //Form created first will be on taskbar
  Application.CreateForm(TFormMain, fFormMain);
  Application.CreateForm(TFormLoading, fFormLoading);

  {$IFDEF PERFLOG}
  gPerfLogs := TKMPerfLogs.Create([], True);
  gPerfLogs.ShowForm(fFormMain.cpPerfLogs);
  gPerfLogs.OnFormChanged := fFormMain.OtherFormChanged;

  collapsed := fFormMain.cpPerfLogs.Collapsed; //Save collapsed flag
  fFormMain.cpPerfLogs.Collapsed := False; //We can set TCategoryPanel height only when collapsed set to False
  fFormMain.cpPerfLogs.Height := gPerfLogs.FormHeight;
  fFormMain.cpPerfLogs.Collapsed := collapsed; //Restore collapsed flag
  {$ELSE}
  fFormMain.cpPerfLogs.Hide;
  {$ENDIF}
end;


destructor TKMMain.Destroy;
begin
  {$IFDEF PERFLOG}gPerfLogs.Free;{$ENDIF}

  {$IFDEF USE_MAD_EXCEPT}FreeAndNil(gExceptions);{$ENDIF}

  inherited;
end;


// Assertion error handler
procedure CustomAssertErrorHandler(const Message, Filename: string; LineNumber: Integer; ErrorAddr: Pointer);
var
  fileNameOnly: string;
begin
  // Show only filename in the error message
  fileNameOnly := ExtractFileName(Filename);

  if Message <> '' then
    raise EAssertionFailed.CreateFmt(SAssertError,
      [Message, fileNameOnly, LineNumber]) at ErrorAddr
  else
    raise EAssertionFailed.CreateFmt(SAssertError,
      [SAssertionFailed, fileNameOnly, LineNumber]) at ErrorAddr;
end;



// Return False in case we had difficulties on the start
function TKMMain.Start: Boolean;

  function GetScreenMonitorsInfo: TKMPointArray;
  var
    I: Integer;
  begin
    SetLength(Result, Screen.MonitorCount);
    for I := 0 to Screen.MonitorCount-1 do
    begin
      Result[I].X := Screen.Monitors[I].Width;
      Result[I].Y := Screen.Monitors[I].Height;
    end;
  end;

const
  LOG_CREATE_TRY_CNT = 3;
var
  tryInd: Integer;
  logsPath: UnicodeString;
  time: Cardinal;
begin
  Result := True;

  time := TimeGet;

  ExeDir := ExtractFilePath(ParamStr(0));

  // Set custom AssertErrorhandler to avoid dev paths in the error messages, which could be seen by players
  AssertErrorProc := @CustomAssertErrorHandler;

  //Random is only used for cases where order does not matter, e.g. shuffle tracks
  Randomize;

  fFormLoading.Label5.Caption := UnicodeString(GAME_VERSION);
  fFormLoading.Show; //This is our splash screen
  fFormLoading.Refresh;

  {$IFDEF MSWindows}
  TimeBeginPeriod(1); //initialize timer precision
  {$ENDIF}

  if not BLOCK_FILE_WRITE then
  begin
    tryInd := 0;
    logsPath := ExeDir + 'Logs' + PathDelim + 'KaM_' + FormatDateTime('yyyy-mm-dd_hh-nn-ss-zzz', Now) + '.log';
    // Try to create log several times
    while (gLog = nil) and (tryInd < LOG_CREATE_TRY_CNT) do
    begin
      try
        Inc(tryInd);
        CreateDir(ExeDir + 'Logs' + PathDelim);
        gLog := TKMLog.Create(logsPath); //First thing - create a log
      except
        on E: Exception do
          if tryInd < LOG_CREATE_TRY_CNT then
            Sleep(200) // Just wait a bit
          else
            raise EGameInitError.Create('Error initializing logging into file: ''' + logsPath + ''':' + sLineBreak + E.Message
                                        {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
      end;
    end;
    gLog.DeleteOldLogs;
  end;

  gLog.AddTime('Game Load started');

  //Resolutions are created first so that we could check Settings against them
  fResolutions := TKMResolutions.Create;

  //Only after we read settings (fullscreen property and resolutions)
  //we can decide whenever we want to create Game fullscreen or not (OpenGL init depends on that)
  gGameAppSettings := TKMGameAppSettings.Create(Screen.Width, Screen.Height);

  //We need to verify INI values, as they can be from another display
  if not fResolutions.IsValid(gMainSettings.Resolution) then
  begin
    gMainSettings.Resolution := fResolutions.FindCorrect(gMainSettings.Resolution);
    if not fResolutions.IsValid(gMainSettings.Resolution) then
      gMainSettings.FullScreen := False;
  end;

  gVideoPlayer := TKMVideoPlayer.Create(ENABLE_VIDEOS_UNDER_WINE or not IsUnderWine);

  fFormMain.Caption := 'KaM Remake - ' + UnicodeString(GAME_VERSION);
  //Will make the form slightly higher, so do it before ReinitRender so it is reset
  fFormMain.UpdateFormState;

  // Check INI window params, if not valid - set NeedResetToDefaults flag for future update
  if not gMainSettings.WindowParams.IsValid(GetScreenMonitorsInfo) then
    gMainSettings.WindowParams.NeedResetToDefaults := True;

  // Stop app if we did not ReinitRender properly (didn't pass game folder permissions test)
  //todo: refactor. Separate folder permissions check and render initialization
  // Locale and texts could be loaded separetely to show proper translated error message
  if not ReinitRender(False) then
    Exit(False);

  fFormMain.ControlsReset;  // Reset controls will update Defaults.pas settings after loaded DevSettings
  fFormMain.ControlsRefill; // Refill some of the debug controls from game settings

  // Create gSystem before Application.OnActivate (it uses FlashingStop)
  gSystem := TKMSystem.Create(fFormMain.Handle);

  Application.OnIdle := DoIdle;
  Application.OnActivate := DoActivate;
  Application.OnDeactivate := DoDeactivate;
  Application.OnRestore := DoRestore; //OnActivate seems to happen at the wrong times, OnRestore happens when alt-tabbing back in full screen mode

  //Update map cache files (*.mi) in the background so map lists load faster
  MapCacheUpdate;

  //Process messages in queue before hiding Loading, so that they all land on Loading form, not main one
  Application.ProcessMessages;
  fFormLoading.Hide;

  fFormMain.AfterFormCreated;

  gLog.AddTime('Game Load Done in ' + IntToStr(TimeSince(time)));
end;


procedure TKMMain.StatusBarText(aPanelIndex: Integer; const aText: UnicodeString);
begin
  fFormMain.StatusBar1.Panels[aPanelIndex].Text := aText;
end;


procedure TKMMain.GameSpeedChange(aSpeed: Single);
begin
  // Set check state without trigger OnClick event handler for the CheckBox
  fFormMain.chkSuperSpeed.SetCheckedWithoutClick(aSpeed = DEBUG_SPEEDUP_SPEED);
end;


procedure TKMMain.CloseQuery(var aCanClose: Boolean);
var
  wasRunning: Boolean;
begin
  //MessageDlg works better than Application.MessageBox or others, it stays on top and
  //pauses here until the user clicks ok. However for some reason we chose MessageBox
  //thus we need to pause the game manually

  aCanClose := (gGameApp = nil) or (gGameApp.Game = nil) or gGameApp.Game.Params.IsReplay;

  if not aCanClose then
  begin
    //We want to pause the game for the time user verifies he really wants to close
    wasRunning := not gGameApp.Game.Params.IsMultiPlayerOrSpec
                  and not gGameApp.Game.Params.IsMapEditor
                  and not gGameApp.Game.IsPaused;

    //Pause the game
    if wasRunning then
      gGameApp.Game.IsPaused := True;

    //Ask the Player
    {$IF DEFINED(MSWindows)}
    //MessageBox works best in Windows (gets stuck under main form less)
    aCanClose := MessageBox( fFormMain.Handle,
                            PChar(gResTexts[TX_EXIT_WARN_MESSAGE]),
                            PChar(gResTexts[TX_EXIT_WARN_HEADER]),
                            MB_YESNO or MB_ICONWARNING or MB_SETFOREGROUND or MB_TASKMODAL
                           ) = IDYES;
    {$ELSEIF DEFINED(Unix)}
    aCanClose := MessageDlg(gResTexts[TX_EXIT_WARN_MESSAGE], mtWarning, [mbYes, mbNo], 0) = mrYes;
    {$ELSE}
    {$ERROR Unsupported case. Please, implement the function}
    {$ENDIF}

    //Resume the game
    if not aCanClose and wasRunning then
      gGameApp.Game.IsPaused := False;
  end;
end;


procedure TKMMain.Stop(Sender: TObject);
begin
  try
    gLog.AddTime('Stopping game application...');
    FreeThenNil(gSystem);
    //Reset the resolution
    FreeThenNil(fResolutions);

    if fMapCacheUpdater <> nil then
      fMapCacheUpdater.Stop;

    // Save Keys settings before destruction of gGameApp, since gResKeys, gResTexts, gResKeyFuncs are used when save to xml
    gKeySettings.SaveToXML;

    FreeThenNil(gGameApp);
    // Destroy gGameAppSettings after GameApp is destroyed, since gGameSettings could be used during destruction
    FreeThenNil(gGameAppSettings);

    FreeThenNil(gLog);

    {$IFDEF MSWindows}
    TimeEndPeriod(1);
    ClipCursor(nil); //Release the cursor restriction
    {$ENDIF}

    // We could have been asked to close by MainForm or from other place (e.g. MainMenu Exit button)
    // In first case Form will take care about closing itself

    // Do not call gMain.Stop from FormClose handler again
    fFormMain.OnClose := nil;

    if Assigned(gVideoPlayer) then
      gVideoPlayer.Free;

    // fFormMain.DevSettingsSave; Moved into MainForm itself, since it's purely MainForms business. Rest of the app should know nothing about it

    if Sender <> fFormMain then
      fFormMain.Close;
  except
    on E: Exception do
        gLog.AddTime('Exception while closing game app: ' + E.Message
                     {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
  end;
end;


//Apply the cursor restriction when alt-tabbing back
procedure TKMMain.DoRestore(Sender: TObject);
begin
  if Application.Active and (gMainSettings <> nil) then
    ApplyCursorRestriction; //Cursor restriction is lost when alt-tabbing out, so we need to apply it again
end;


procedure TKMMain.DoActivate(Sender: TObject);
begin
  if Application.Active then
    gSystem.FlashingStop;
end;


procedure TKMMain.DoDeactivate(Sender: TObject);
begin
  //Occurs during Toggle to fullscreen, should be ignored
  if Application.Active then Exit;

  //Prevent the game window from being in the way by minimizing when alt-tabbing
  if (gMainSettings <> nil) and gMainSettings.FullScreen then
  begin
    {$IFDEF MSWindows}
      ClipCursor(nil); //Remove all cursor clipping just in case Windows doesn't automatically
    {$ENDIF}
    Application.Minimize;
  end;
end;


procedure TKMMain.UpdateFPS(latestFrameTime: Cardinal);
var
  fpsLag: Integer;
begin
  if gMainSettings <> nil then //gMainSettings could be nil on Game Exit ?? Just check if its not nil
  begin
    Inc(fOldFrameTimes, latestFrameTime);
    Inc(fFrameCount);
    if fOldFrameTimes >= FPS_INTERVAL then
    begin
      fFPS := 1000 / (fOldFrameTimes / fFrameCount);
      if gGameApp <> nil then
        gGameApp.FPSMeasurement(Round(fFPS));

      fpsLag := 1000 div gMainSettings.FPSCap;
      fFPSString := Format('%.1f FPS', [fFPS]) + IfThen(CAP_MAX_FPS, ' (' + IntToStr(fpsLag) + ')');
      StatusBarText(SB_ID_FPS, fFPSString);
      fOldFrameTimes := 0;
      fFrameCount := 0;
    end;
  end;
end;


function TKMMain.GetRenderInterval: Cardinal;
begin
  Result := 0;
  if CAP_MAX_FPS and (gMainSettings <> nil) then
    Result := 1000 div gMainSettings.FPSCap;
end;


procedure TKMMain.DoRender;
var renderDelta: Cardinal;
begin
  renderDelta := TimeSince(fLastRenderTime);
  fLastRenderTime := TimeGet;
  UpdateFPS(renderDelta);

  gGameApp.UpdateStateIdle(renderDelta);
  gGameApp.Render;
end;


procedure TKMMain.SleepUntilNextSchedule;
var
  nextTime, nextRender, nextTick, timeNow, sleepTime, renderInterval: Cardinal;
begin
  renderInterval := GetRenderInterval;

  nextRender := AddWithOverflow(fRenderSchedule, renderInterval);
  nextTick := AddWithOverflow(fTickSchedule, fGameTickInterval);

  if nextRender > nextTick then
    nextTime := nextRender
  else
    nextTime := nextTick;

  timeNow := TimeGet;
  if nextTime > timeNow then
  begin
    sleepTime := nextTime - timeNow;
    //Check for TimeGet overflow (never sleep longer than the render interval)
    if sleepTime < renderInterval then
      Sleep(sleepTime);
  end;
end;


function TKMMain.ForcedRenderRequired: Boolean;
begin
  Result := (gMainSettings <> nil)
    and gMainSettings.IsNoRenderMaxTimeSet
    and (TimeSince(fLastRenderTime) > gMainSettings.NoRenderMaxTime);
end;


procedure TKMMain.DoIdle(Sender: TObject; var Done: Boolean);

  function CalculateSchedule(aLastTime, aTimeSince, aInterval: Cardinal): Cardinal;
  var
    ticksBehind: Cardinal;
  begin
    ticksBehind := (aTimeSince div aInterval);
    Result := AddWithOverflow(aLastTime, ticksBehind*aInterval);
  end;

const
  MAX_TIME_BETWEEN_RENDERS = 1000; //Render at least 1 FPS
  UI_UPDATE_INTERVAL = 100;
var
  renderInterval, timeSinceRender, timeSinceTick, timeSinceUpdateUI: Cardinal;
begin
  Done := False; //Repeats OnIdle asap without performing Form-specific idle code

  if gGameApp = nil then
  begin
    Sleep(10);
    Exit;
  end;

  if CHECK_8087CW then
    //$1F3F is used to mask out reserved/undefined bits
    Assert((Get8087CW and $1F3F = $133F), '8087CW is wrong');

  //Some PCs seem to change 8087CW randomly between events like Timers and OnMouse*,
  //so we need to set it right before we do game logic processing
  Set8087CW($133F);

  //Priority 1. Do we need to tick?
  timeSinceTick := TimeSince(fTickSchedule);
  if (timeSinceTick >= fGameTickInterval) and not ForcedRenderRequired then
  begin
    gGameApp.DoGameTick;
    fTickSchedule := CalculateSchedule(fTickSchedule, timeSinceTick, fGameTickInterval);
  end
  else
  begin
    //Priority 2. UI update and render
    timeSinceUpdateUI := TimeSince(fUpdateStateSchedule);
    if timeSinceUpdateUI >= UI_UPDATE_INTERVAL then
    begin
      gGameApp.UpdateState;
      fUpdateStateSchedule := CalculateSchedule(fUpdateStateSchedule, timeSinceUpdateUI, UI_UPDATE_INTERVAL);
    end;

    renderInterval := GetRenderInterval;
    if renderInterval > 0 then
    begin
      timeSinceRender := TimeSince(fRenderSchedule);
      if timeSinceRender >= renderInterval then
      begin
        DoRender;
        fRenderSchedule := CalculateSchedule(fRenderSchedule, timeSinceRender, renderInterval);
      end
      else
        SleepUntilNextSchedule;
    end
    else
      DoRender; //No FPS cap so always render
  end;
end;


// Check game execution dir generic permissions
function TKMMain.DoHaveGenericPermission: Boolean;
const
  GRANTED: array[Boolean] of string = ('blocked', 'granted');
var
  readAcc, writeAcc, execAcc, dirWritable: Boolean;
begin
  CheckFolderPermission(ExeDir, readAcc, writeAcc, execAcc);

  dirWritable := IsDirectoryWriteable(ExeDir);

  gLog.AddTime(Format('Check game folder ''%s'' generic permissions: READ: %s; WRITE: %s; EXECUTE: %s; folder is writable: ',
                      [ExeDir, GRANTED[readAcc], GRANTED[writeAcc], GRANTED[execAcc], BoolToStr(dirWritable, True)]));

  Result := dirWritable and readAcc and writeAcc and execAcc;
end;


function TKMMain.ReinitRender(aReturnToOptions: Boolean): Boolean;

  procedure ShowPermissionsError;
  begin
    SKIP_RENDER := True; // Skip render, since gGameApp will show panels on FullScreen mode
    fFormLoading.Hide; //Will close the form on Full Screen mode
    fFormMain.Hide;
    gMusic.Stop;
    fFormMain.ShowFolderPermissionError; // Show localized error message
    Stop(nil); // Stop the app
  end;

begin
  Result := True;
  if gMainSettings.FullScreen then
  begin
    // Lock window params while we are in FullScreen mode
    gMainSettings.WindowParams.LockParams;
    if fResolutions.IsValid(gMainSettings.Resolution) then
      fResolutions.SetResolution(gMainSettings.Resolution)
    else
      gMainSettings.FullScreen := False;
  end else
    fResolutions.Restore;

  fFormLoading.Position := poScreenCenter;

  // Will show windowed form and play videos
  // Should be made before GameApp creation, otherwise window position will not be set correctly
  // (its prbably because it will be overwritten, on gGameApp creation)
  if not gMainSettings.FullScreen then
    fFormMain.ShowInWindow;

  //It's required to re-init whole OpenGL related things when RC gets toggled fullscreen
  FreeThenNil(gGameApp); //Saves all settings into ini file in midst
  gGameApp := TKMGameApp.Create(fFormMain.RenderArea,
                                fFormMain.RenderArea.Width,
                                fFormMain.RenderArea.Height,
                                gMainSettings.VSync,
                                fFormLoading.LoadingStep,
                                fFormLoading.LoadingText,
                                StatusBarText);

  // Will show fullscreen form and play videos
  // We need to start it after GameApp creation, since we need gResLocales to load proper video file by loaded locale
  if gMainSettings.FullScreen then
    fFormMain.ShowFullscreen;

  // Check if player has all permissions on game folder. Close the app if not
  // Check is done after gGameApp creating because we want to load texts first to shw traslated error message
  //todo: refactor. Separate folder permissions check and render initialization
  // Locale and texts could be loaded separetely to show proper translated error message
  try
    if (gLog = nil)
      or (not aReturnToOptions and not DoHaveGenericPermission) then
    begin
      ShowPermissionsError;
      Exit(False); // Stop the app
    end;
  except
    // but it seems like Exit alone doesn't work - try-except block does
    ShowPermissionsError;
    Exit(False); // Stop the app
  end;

  gGameApp.OnGameSpeedActualChange := GameSpeedChange;
  gGameApp.AfterConstruction(aReturnToOptions);

  //Preload game resources while in menu to make 1st game start faster
  gGameApp.PreloadGameResources;

  gGameApp.OnOptionsChange := fFormMain.ControlsRefill;
  fFormMain.OnControlsUpdated := gGameApp.DebugControlsUpdated;

  gLog.AddTime('ToggleFullscreen');
  gLog.AddTime('Form Width/Height: '+inttostr(fFormMain.Width)+':'+inttostr(fFormMain.Height));
  gLog.AddTime('Panel Width/Height: '+inttostr(fFormMain.RenderArea.Width)+':'+inttostr(fFormMain.RenderArea.Height));

  //Hide'n'show will make form go ontop of taskbar
  fFormMain.Hide;
  fFormMain.Show;

  ForceResize; //Force everything to resize

  // Unlock window params if are no longer in FullScreen mode
  if not gMainSettings.FullScreen then
    gMainSettings.WindowParams.UnlockParams;

  ApplyCursorRestriction;
end;


function TKMMain.LockMutex: Boolean;
begin
  Result := True;
  {$IFDEF MSWindows}
    if not BLOCK_DUPLICATE_APP then Exit;

    fMutex := CreateMutex(nil, True, PChar(KAM_MUTEX));

    if fMutex = 0 then
      RaiseLastOSError;

    Result := (GetLastError <> ERROR_ALREADY_EXISTS);

    if not Result then
      // Close our own handle on the mutex because someone else already made the mutex
      UnlockMutex;
  {$ENDIF}
end;


procedure TKMMain.UnlockMutex;
begin
  {$IFDEF MSWindows}
    if not BLOCK_DUPLICATE_APP then Exit;
    if fMutex = 0 then Exit; //Didn't have a mutex lock
    CloseHandle(fMutex);
    fMutex := 0;
  {$ENDIF}
end;


procedure TKMMain.MapCacheUpdate;
begin
  // Thread frees itself automatically
  fMapCacheUpdater := TTMapsCacheUpdater.Create([mkSP, mkMP, mkDL]);
end;


function TKMMain.IsDebugChangeAllowed: Boolean;
begin
  Result := (gGameApp.Game = nil)
            or not gGameApp.Game.Params.IsMultiPlayerOrSpec
            or MULTIPLAYER_CHEATS;
end;


function TKMMain.ClientRect(aPixelsCntToReduce: Integer = 0): TRect;
begin
  Result := fFormMain.RenderArea.ClientRect;
  Result.TopLeft := ClientToScreen(Result.TopLeft);
  Result.TopLeft.X := Result.TopLeft.X + aPixelsCntToReduce;
  Result.TopLeft.Y := Result.TopLeft.Y + aPixelsCntToReduce;
  Result.BottomRight := ClientToScreen(Result.BottomRight);
  Result.BottomRight.X := Result.BottomRight.X - aPixelsCntToReduce;
  Result.BottomRight.Y := Result.BottomRight.Y - aPixelsCntToReduce;
end;


function TKMMain.ClientToScreen(aPoint: TPoint): TPoint;
begin
  Result := fFormMain.RenderArea.ClientToScreen(aPoint);
end;


//Can be invalid very breifly if you change resolutions (this is possible in Windowed mode)
function TKMMain.GetScreenBounds(out aBounds: TRect): Boolean;
var
  I: Integer;
begin
  Result := False;
  try
    aBounds := Classes.Rect(-1,-1,-1,-1);
    fFormMain.Monitor; //This forces Delphi to reload Screen.Monitors (only if necessary) and so fixes crashes when using multiple monitors
    //Maximized is a special case, it can only be on one monitor. This is required because when maximized form.left = -9 (on Windows 7 anyway)
    if fFormMain.WindowState = wsMaximized then
    begin
      for I := 0 to Screen.MonitorCount-1 do
        //Find the monitor with the left closest to the left of the form
        if (I = 0)
        or ((Abs(fFormMain.Left - Screen.Monitors[I].Left) <= Abs(fFormMain.Left - aBounds.Left)) and
            (Abs(fFormMain.Top  - Screen.Monitors[I].Top ) <= Abs(fFormMain.Top  - aBounds.Top))) then
        begin
          Result := True;
          aBounds.Left  := Screen.Monitors[I].Left;
          aBounds.Right := Screen.Monitors[I].Width+Screen.Monitors[I].Left;
          aBounds.Top   := Screen.Monitors[I].Top;
          aBounds.Bottom:= Screen.Monitors[I].Height+Screen.Monitors[I].Top;
        end;
    end
    else
      for I:=0 to Screen.MonitorCount-1 do
        //See if our form is within the boundaries of this monitor (I.e. when it is not outside the boundaries)
        if not ((fFormMain.Left                   >= Screen.Monitors[I].Width + Screen.Monitors[I].Left) or
                (fFormMain.Width + fFormMain.Left <= Screen.Monitors[I].Left) or
                (fFormMain.Top                    >= Screen.Monitors[I].Height + Screen.Monitors[I].Top) or
                (fFormMain.Height + fFormMain.Top <= Screen.Monitors[I].Top)) then
        begin
          if not Result then
          begin
            //First time we have to initialise the result
            Result := True;
            aBounds.Left  := Screen.Monitors[I].Left;
            aBounds.Right := Screen.Monitors[I].Width+Screen.Monitors[I].Left;
            aBounds.Top   := Screen.Monitors[I].Top;
            aBounds.Bottom:= Screen.Monitors[I].Height+Screen.Monitors[I].Top;
          end
          else
          begin
            //After the first time we compare it with the previous result and take the largest possible area
            aBounds.Left  := Math.Min(aBounds.Left,  Screen.Monitors[I].Left);
            aBounds.Right := Math.Max(aBounds.Right, Screen.Monitors[I].Width+Screen.Monitors[I].Left);
            aBounds.Top   := Math.Min(aBounds.Top,   Screen.Monitors[I].Top);
            aBounds.Bottom:= Math.Max(aBounds.Bottom,Screen.Monitors[I].Height+Screen.Monitors[I].Top);
          end;
        end;
  except
    on E: Exception do
      gLog.AddTime('Exception in TKMMain.GetScreenBounds: ' + E.Message
                   {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
  end;
end;


function TKMMain.IsFormActive: Boolean;
begin
  Result := fFormMain.Active;
end;


procedure TKMMain.Render;
begin
  if Self = nil then Exit;

  gGameApp.Render;
end;


//Force everything to resize
procedure TKMMain.ForceResize;
begin
  Resize(fFormMain.RenderArea.Width, fFormMain.RenderArea.Height);
end;


procedure TKMMain.Resize(aWidth, aHeight: Integer);
begin
  if Self = nil then Exit;

  gGameApp.Resize(aWidth, aHeight);
end;


procedure TKMMain.Resize(aWidth, aHeight: Integer; const aWindowParams: TKMWindowParamsRecord);
begin
  if gGameApp = nil then Exit;

  gGameApp.Resize(aWidth, aHeight);
  UpdateWindowParams(aWindowParams);
end;


procedure TKMMain.Move(const aWindowParams: TKMWindowParamsRecord);
begin
  if Self = nil then Exit;

  UpdateWindowParams(aWindowParams);
end;


procedure TKMMain.UpdateWindowParams(const aWindowParams: TKMWindowParamsRecord);
begin
  if gGameApp = nil then Exit;
  if gMainSettings.WindowParams = nil then Exit; //just in case...

  gMainSettings.WindowParams.ApplyWindowParams(aWindowParams);
end;


procedure TKMMain.SetGameTickInterval(aInterval: Cardinal);
begin
  if Self = nil then Exit; // Could be nil in Runner
  
  fGameTickInterval := aInterval;
end;


procedure TKMMain.ShowAbout;
begin
  if Self = nil then Exit;

  fFormLoading.Position := poScreenCenter;
  fFormLoading.Bar1.Position := 0;
  fFormLoading.Label1.Caption := '';
  fFormLoading.Show;
end;


//Restrict cursor movement in fullscreen mode
//For multiple monitors, it's very annoying if you play a fullscreen game and your cursor slides
//onto second monitor instead of stopping at the edge as expected.
procedure TKMMain.ApplyCursorRestriction;
var
  rect: TRect;
begin
  //This restriction is removed when alt-tabbing out, and added again when alt-tabbing back
  {$IFDEF MSWindows}
  if gMainSettings.FullScreen then
  begin
    rect := fFormMain.BoundsRect;
    ClipCursor(@rect);
  end
  else
    ClipCursor(nil); //Otherwise have no restriction
  {$ENDIF}
end;


end.

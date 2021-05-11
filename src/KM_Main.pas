unit KM_Main;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  KM_FormMain, KM_FormLoading, KM_Maps,
  KM_MainSettings, KM_Resolutions, KM_Video,
  KM_WindowParams,
  KM_GameAppSettings;


type
  // Provides basement for the Game App
  // Should be abstract enough, so that the Game could be a race-sim or a quest or any other
  TKMMain = class
  private
    fFormMain: TFormMain;
    fFormLoading: TFormLoading;

    fGameTickInterval: Cardinal;

    fLastRenderTime, fLastTickTime: Cardinal;
    fOldFrameTimes, fFrameCount: Cardinal;
    {$IFNDEF FPC}
    fFlashing: Boolean;
    {$ENDIF}
    fMutex: THandle;

    fGameAppSettings: TKMGameAppSettings;
    fMainSettings: TKMainSettings;
    fResolutions: TKMResolutions;
    fMapCacheUpdater: TTMapsCacheUpdater;

    fFPS: Single;
    fFPSString: String;

    procedure DoRestore(Sender: TObject);
    procedure DoActivate(Sender: TObject);
    procedure DoDeactivate(Sender: TObject);
    procedure DoIdle(Sender: TObject; var Done: Boolean);

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
    procedure FlashingStart;
    procedure FlashingStop;

    property FPSString: String read fFPSString;

    function IsDebugChangeAllowed: Boolean;

    function LockMutex: Boolean;
    procedure UnlockMutex;

    procedure StatusBarText(aPanelIndex: Integer; const aText: UnicodeString);

    procedure SetGameTickInterval(aInterval: Cardinal);

    property Resolutions: TKMResolutions read fResolutions;
    property Settings: TKMainSettings read fMainSettings;
  end;


var
  gMain: TKMMain;


implementation
uses
  Classes, Forms,
  {$IFDEF MSWindows} MMSystem, {$ENDIF}
  {$IFDEF USE_MAD_EXCEPT} KM_Exceptions, {$ENDIF}
  SysUtils, SysConst, StrUtils, Math, KromUtils, KM_FileIO,
  KM_GameApp, KM_Helpers,
  KM_Log, KM_CommonUtils, KM_Defaults, KM_Points, KM_DevPerfLog,
  KM_CommonExceptions,
  KromShellUtils, KM_MapTypes;


const
  // Mutex is used to block duplicate app launch on the same PC
  // Random GUID generated in Delphi by Ctrl+G
  KAM_MUTEX = '07BB7CC6-33F2-44ED-AD04-1E255E0EDF0D';


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
begin
  Result := True;

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

  //Resolutions are created first so that we could check Settings against them
  fResolutions := TKMResolutions.Create;

  //Only after we read settings (fullscreen property and resolutions)
  //we can decide whenever we want to create Game fullscreen or not (OpenGL init depends on that)
  fGameAppSettings := TKMGameAppSettings.Create;
  fMainSettings := TKMainSettings.Create(Screen.Width, Screen.Height);
  //We need to verify INI values, as they can be from another display
  if not fResolutions.IsValid(fMainSettings.Resolution) then
  begin
    fMainSettings.Resolution := fResolutions.FindCorrect(fMainSettings.Resolution);
    if not fResolutions.IsValid(fMainSettings.Resolution) then
      fMainSettings.FullScreen := False;
  end;

  gVideoPlayer := TKMVideoPlayer.Create(ENABLE_VIDEOS_UNDER_WINE or not IsUnderWine);

  fFormMain.Caption := 'KaM Remake - ' + UnicodeString(GAME_VERSION);
  //Will make the form slightly higher, so do it before ReinitRender so it is reset
  fFormMain.ControlsSetVisibile(SHOW_DEBUG_CONTROLS);

  // Check INI window params, if not valid - set NeedResetToDefaults flag for future update
  if not fMainSettings.WindowParams.IsValid(GetScreenMonitorsInfo) then
    fMainSettings.WindowParams.NeedResetToDefaults := True;

  // Stop app if we did not ReinitRender properly (didn't pass game folder permissions test)
  //todo: refactor. Separate folder permissions check and render initialization
  // Locale and texts could be loaded separetely to show proper translated error message
  if not ReinitRender(False) then
  begin
    SKIP_RENDER := True; // Skip render, since gGameApp will show panels on FullScreen mode
    fFormLoading.Hide; //Will close the form on Full Screen mode
    fFormMain.Hide;
    fFormMain.ShowFolderPermissionError; // Show localized error message
    Stop(nil); // Stop the app
    Exit(False);
  end;

  fFormMain.ControlsRefill; //Refill some of the debug controls from game settings

  Application.OnIdle := DoIdle;
  Application.OnActivate := DoActivate;
  Application.OnDeactivate := DoDeactivate;
  Application.OnRestore := DoRestore; //OnActivate seems to happen at the wrong times, OnRestore happens when alt-tabbing back in full screen mode

  //Update map cache files (*.mi) in the background so map lists load faster
  MapCacheUpdate;

  //Preload game resources while in menu to make 1st game start faster
  gGameApp.PreloadGameResources;

  //Process messages in queue before hiding Loading, so that they all land on Loading form, not main one
  Application.ProcessMessages;
  fFormLoading.Hide;

  fFormMain.AfterFormCreated;
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
    {$IFDEF MSWindows}
    //MessageBox works best in Windows (gets stuck under main form less)
    aCanClose := MessageBox( fFormMain.Handle,
                            PChar('Any unsaved changes will be lost. Exit?'),
                            PChar('Warning'),
                            MB_YESNO or MB_ICONWARNING or MB_SETFOREGROUND or MB_TASKMODAL
                           ) = IDYES;
    {$ENDIF}
    {$IFDEF Unix}
    CanClose := MessageDlg('Any unsaved changes will be lost. Exit?', mtWarning, [mbYes, mbNo], 0) = mrYes;
    {$ENDIF}

    //Resume the game
    if not aCanClose and wasRunning then
      gGameApp.Game.IsPaused := False;
  end;
end;


procedure TKMMain.Stop(Sender: TObject);
begin
  try
    //Reset the resolution
    FreeThenNil(fResolutions);
    FreeThenNil(fMainSettings);

    if fMapCacheUpdater <> nil then
      fMapCacheUpdater.Stop;
    FreeThenNil(gGameApp);
    FreeThenNil(fGameAppSettings); // After GameApp is destroyed
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

    fFormMain.SaveDevSettings;

    if Sender <> fFormMain then
      fFormMain.Close;
  except
    on E: Exception do
      begin
        gLog.AddTime('Exception while closing game app: ' + E.Message
                     {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
      end;
  end;
end;


//Apply the cursor restriction when alt-tabbing back
procedure TKMMain.DoRestore(Sender: TObject);
begin
  if Application.Active and (fMainSettings <> nil) then
    ApplyCursorRestriction; //Cursor restriction is lost when alt-tabbing out, so we need to apply it again
end;


procedure TKMMain.DoActivate(Sender: TObject);
begin
  if Application.Active then
    FlashingStop;
end;


procedure TKMMain.DoDeactivate(Sender: TObject);
begin
  //Occurs during Toggle to fullscreen, should be ignored
  if Application.Active then Exit;

  //Prevent the game window from being in the way by minimizing when alt-tabbing
  if (fMainSettings <> nil) and fMainSettings.FullScreen then
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
  if fMainSettings <> nil then //fMainSettings could be nil on Game Exit ?? Just check if its not nil
  begin
    Inc(fOldFrameTimes, latestFrameTime);
    Inc(fFrameCount);
    if fOldFrameTimes >= FPS_INTERVAL then
    begin
      fFPS := 1000 / (fOldFrameTimes / fFrameCount);
      if gGameApp <> nil then
        gGameApp.FPSMeasurement(Round(fFPS));

      fpsLag := 1000 div fMainSettings.FPSCap;
      fFPSString := Format('%.1f FPS', [fFPS]) + IfThen(CAP_MAX_FPS, ' (' + IntToStr(fpsLag) + ')');
      StatusBarText(SB_ID_FPS, fFPSString);
      fOldFrameTimes := 0;
      fFrameCount := 0;
    end;
  end;
end;


procedure TKMMain.DoIdle(Sender: TObject; var Done: Boolean);

  {$OVERFLOWCHECKS OFF}
  function AddWithOverflow(A, B: Cardinal): Cardinal; inline;
  begin
    Result := A + B;
  end;
  {$OVERFLOWCHECKS ON}

const
  MAX_TIME_BETWEEN_RENDERS = 1000; //Render at least 1 FPS
var
  timeSinceRender, timeSinceTick, sleepTime: Cardinal;
begin
  if CHECK_8087CW then
    //$1F3F is used to mask out reserved/undefined bits
    Assert((Get8087CW and $1F3F = $133F), '8087CW is wrong');

  //Some PCs seem to change 8087CW randomly between events like Timers and OnMouse*,
  //so we need to set it right before we do game logic processing
  Set8087CW($133F);

  timeSinceTick := TimeSince(fLastTickTime);
  timeSinceRender := TimeSince(fLastRenderTime);

  //Priority 1. Do we need to tick?
  if (timeSinceTick >= fGameTickInterval) and (timeSinceRender < MAX_TIME_BETWEEN_RENDERS) then
  begin
    if gGameApp <> nil then
      gGameApp.UpdateState;

    if timeSinceTick < 4*fGameTickInterval then
    begin
      //To maintain a constant tick rate simply add 100ms to the last tick time
      fLastTickTime := AddWithOverflow(fLastTickTime, fGameTickInterval);
    end
    else
    begin
      //We have fallen too far behind so don't attempt to maintain the tick rate
      fLastTickTime := TimeGet;
    end;
  end
  else
  begin
    //Priority 2. Do we need to render?
    if not CAP_MAX_FPS or (fMainSettings = nil) or (timeSinceRender > (1000 div fMainSettings.FPSCap)) then
    begin
      fLastRenderTime := TimeGet;
      UpdateFPS(timeSinceRender);
      if gGameApp <> nil then
      begin
        gGameApp.UpdateStateIdle(timeSinceRender);
        gGameApp.Render;
      end;
    end
    else
    begin
      Sleep(1);
    end;
  end;

  Done := False; //Repeats OnIdle asap without performing Form-specific idle code
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
begin
  Result := True;
  if fMainSettings.FullScreen then
  begin
    // Lock window params while we are in FullScreen mode
    fMainSettings.WindowParams.LockParams;
    if fResolutions.IsValid(fMainSettings.Resolution) then
      fResolutions.SetResolution(fMainSettings.Resolution)
    else
      fMainSettings.FullScreen := False;
  end else
    fResolutions.Restore;

  fFormLoading.Position := poScreenCenter;
  fFormMain.ToggleFullscreen(fMainSettings.FullScreen, fMainSettings.WindowParams.NeedResetToDefaults);

  //It's required to re-init whole OpenGL related things when RC gets toggled fullscreen
  FreeThenNil(gGameApp); //Saves all settings into ini file in midst
  gGameApp := TKMGameApp.Create(fFormMain.RenderArea,
                                fFormMain.RenderArea.Width,
                                fFormMain.RenderArea.Height,
                                fMainSettings.VSync,
                                fFormLoading.LoadingStep,
                                fFormLoading.LoadingText,
                                StatusBarText);

  // Check if player has all permissions on game folder. Close the app if not
  // Check is done after gGameApp creating because we want to load texts first to shw traslated error message
  //todo: refactor. Separate folder permissions check and render initialization
  // Locale and texts could be loaded separetely to show proper translated error message
  if (gLog = nil)
    or (not aReturnToOptions and not DoHaveGenericPermission) then
    Exit(False); // Will show 'You have not enough permissions' message to the player

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
  if (not fMainSettings.FullScreen) then
    fMainSettings.WindowParams.UnlockParams;

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
  if not Result then UnlockMutex; //Close our own handle on the mutex because someone else already made the mutex
  {$ENDIF}
  {$IFDEF Unix}
    Result := True;
  {$ENDIF}
end;


procedure TKMMain.MapCacheUpdate;
begin
  //Thread frees itself automatically
  fMapCacheUpdater := TTMapsCacheUpdater.Create([mfSP, mfMP, mfDL]);
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


procedure TKMMain.FlashingStart;
{$IFNDEF FPC}
var
  flashInfo: TFlashWInfo;
{$ENDIF}
begin
  {$IFNDEF FPC}
  if (GetForegroundWindow <> gMain.FormMain.Handle) then
  begin
    flashInfo.cbSize := 20;
    flashInfo.hwnd := Application.Handle;
    flashInfo.dwflags := FLASHW_ALL;
    flashInfo.ucount := 5; // Flash 5 times
    flashInfo.dwtimeout := 0; // Use default cursor blink rate
    fFlashing := True;
    FlashWindowEx(flashInfo);
  end
  {$ENDIF}
end;


procedure TKMMain.FlashingStop;
{$IFNDEF FPC}
var
  flashInfo: TFlashWInfo;
{$ENDIF}
begin
  {$IFNDEF FPC}
  if fFlashing then
  begin
    flashInfo.cbSize := 20;
    flashInfo.hwnd := Application.Handle;
    flashInfo.dwflags := FLASHW_STOP;
    flashInfo.ucount := 0;
    flashInfo.dwtimeout := 0;
    fFlashing := False;
    FlashWindowEx(flashInfo);
  end
  {$ENDIF}
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
  aBounds := Classes.Rect(-1,-1,-1,-1);
  fFormMain.Monitor; //This forces Delphi to reload Screen.Monitors (only if necessary) and so fixes crashes when using multiple monitors
  //Maximized is a special case, it can only be on one monitor. This is required because when maximized form.left = -9 (on Windows 7 anyway)
  if fFormMain.WindowState = wsMaximized then
  begin
    for I:=0 to Screen.MonitorCount-1 do
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
  if fMainSettings.WindowParams = nil then Exit; //just in case...

  fMainSettings.WindowParams.ApplyWindowParams(aWindowParams);
end;


procedure TKMMain.SetGameTickInterval(aInterval: Cardinal);
begin
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
  if fMainSettings.FullScreen then
  begin
    rect := fFormMain.BoundsRect;
    ClipCursor(@rect);
  end
  else
    ClipCursor(nil); //Otherwise have no restriction
  {$ENDIF}
end;


end.

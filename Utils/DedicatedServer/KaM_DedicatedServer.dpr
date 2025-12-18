program KaM_DedicatedServer;
{$I ..\..\KaM_Remake.inc}

{$IFDEF MSWindows}
  {$APPTYPE CONSOLE}
{$ENDIF}

//Next instructions could help sometimes for cross-compile builds
//{$IFDEF FPC_CROSSCOMPILING}
//  {$IFDEF UNIX}
//    {$linklib libc_nonshared.a}
//  {$ENDIF}
//{$ENDIF}

uses
  {$IFDEF UNIX}
    {$DEFINE UseCThreads}
    cthreads, //We use a thread for deleting old log files
    BaseUnix,
  {$ENDIF}
  Classes, SysUtils,
  {$IFDEF MSWindows} Windows, MMSystem, {$ENDIF}
  {$IFDEF FPC} Interfaces, {$ENDIF}

  KM_CommonUtils in '..\..\src\utils\KM_CommonUtils.pas',
  KM_Defaults in '..\..\src\common\KM_Defaults.pas',
  KM_Points in '..\..\src\common\KM_Points.pas',
  KM_Log in '..\..\src\KM_Log.pas',
  KM_Settings in '..\..\src\settings\KM_Settings.pas',
  KM_ServerSettings in '..\..\src\settings\KM_ServerSettings.pas',
  KM_NetTypes in '..\..\src\net\KM_NetTypes.pas',
  KM_NetDedicatedServer in '..\..\src\net\KM_NetDedicatedServer.pas',
  {$IFDEF WDC}
  KM_ConsoleTimer in '..\..\src\utils\KM_ConsoleTimer.pas',
  {$ENDIF}
  KM_ServerEventHandler in 'KM_ServerEventHandler.pas';

var
  fEventHandler: TKMServerEventHandler;
  fDedicatedServer: TKMNetDedicatedServer;
  fSettings: TKMServerSettings;
  fSettingsLastModified: Integer;
  fLastSettingsFileCheck: Cardinal;

{$IFDEF WDC}
procedure MyProcessMessages;
var myMsg: TMsg;
begin
  while PeekMessage(myMsg, 0, 0, 0, 0) do
  begin
    GetMessage(myMsg, 0, 0, 0);
    TranslateMessage(myMsg);
    DispatchMessage(myMsg);
  end;
end;
{$ENDIF}

procedure RunTheServer;
var
  GameFilter: TKMPGameFilter;
begin
  fDedicatedServer := TKMNetDedicatedServer.Create(fSettings.MaxRooms,
                                                fSettings.AutoKickTimeout,
                                                fSettings.PingInterval,
                                                fSettings.MasterAnnounceInterval,
                                                fSettings.ServerUDPScanPort,
                                                fSettings.MasterServerAddress,
                                                fSettings.HTMLStatusFile,
                                                fSettings.ServerWelcomeMessage,
                                                fSettings.ServerPacketsAccumulatingDelay,
                                                True);
  GameFilter := TKMPGameFilter.Create(fSettings.ServerDynamicFOW,
                                      fSettings.ServerMapsRosterEnabled,
                                      fSettings.ServerMapsRosterStr,
                                      KMRange(fSettings.ServerLimitPTFrom, fSettings.ServerLimitPTTo),
                                      KMRange(fSettings.ServerLimitSpeedFrom, fSettings.ServerLimitSpeedTo),
                                      KMRange(fSettings.ServerLimitSpeedAfterPTFrom, fSettings.ServerLimitSpeedAfterPTTo));
  fDedicatedServer.Server.GameFilter := GameFilter;
  fDedicatedServer.OnMessage := fEventHandler.ServerStatusMessage;
  fDedicatedServer.Start(fSettings.ServerName, StrToInt(fSettings.ServerPort), fSettings.AnnounceServer, fSettings.ServerUDPAnnounce);

  while fDedicatedServer <> nil do
  begin
    fDedicatedServer.UpdateState;
    //Reload the INI file if it has changed, by checking the file age every 5 seconds
    if TimeSince(fLastSettingsFileCheck) >= 5000 then
    begin
      fLastSettingsFileCheck := TimeGet;
      if FileAge(fSettings.Path) <> fSettingsLastModified then
      begin
        fEventHandler.ServerStatusMessage('Reloading updated settings from ' + fSettings.Path);
        fSettings.ReloadSettings;
        fSettingsLastModified := FileAge(fSettings.Path);
        fDedicatedServer.UpdateSettings(fSettings.ServerName,
                                        fSettings.AnnounceServer,
                                        fSettings.ServerUDPAnnounce,
                                        fSettings.AutoKickTimeout,
                                        fSettings.PingInterval,
                                        fSettings.MasterAnnounceInterval,
                                        fSettings.ServerUDPScanPort,
                                        fSettings.MasterServerAddress,
                                        fSettings.HTMLStatusFile,
                                        fSettings.ServerWelcomeMessage,
                                        fSettings.ServerPacketsAccumulatingDelay);
      end;
    end;
    //In Lazarus LNet will wait for 1ms in CallAction for the OS to respond with socket events
    //so we don't need to do ProcessMessage or Sleep here.
    {$IFDEF WDC}
    MyProcessMessages; //This will process network (or other) events
    Sleep(1); //Don't hog CPU (this can also be used to create an artifical latency)
    {$ENDIF}
    CheckSynchronize(); //Update threads synchronization, as Console Timers work in a separate thread
  end;
end;

{$IFDEF FPC}
function GetExceptionCallStack: string;
var
  I: Integer;
  P: Pointer;
begin
  Result := '*** STACKTRACE ***' + LineEnding;
  Result := Result + BackTraceStrFunc(ExceptAddr);
  for I := 0 to ExceptFrameCount - 1 do
  begin
    P := (ExceptFrames + I)^;
    Result := Result + LineEnding + BackTraceStrFunc(P);
  end;
  Result := Result + LineEnding + '*** END STACKTRACE ***';
end;
{$ENDIF}

//Called when our process is asked to terminate (by either Windows or Linux)
procedure ServerKilled;
begin
  if fEventHandler <> nil then
    fEventHandler.ServerStatusMessage('Interrupt received, shutting down server...')
  else
    Writeln('Interrupt received, shutting down server...');

  if fDedicatedServer <> nil then
  begin
    fDedicatedServer.Stop;
    FreeAndNil(fDedicatedServer);
  end;
  FreeAndNil(fEventHandler);

  Halt; //Terminate the process
end;

{$IFDEF MSWindows}
function OnConsoleCtrl(ACtrl: DWord): LongBool; stdcall;
begin
  Result := False;
  if (ACtrl = CTRL_C_EVENT) or (ACtrl = CTRL_BREAK_EVENT) or (ACtrl = CTRL_CLOSE_EVENT) then
  begin
    Result := True;
    ServerKilled;
  end;
end;
{$ENDIF}

{$IFDEF UNIX}
procedure OnInterrupt(ASignal: cint); cdecl;
begin
  ServerKilled;
end;
{$ENDIF}

begin
  //Define CONSOLE for Lazarus
  {$IFDEF FPC}
    {$DEFINE CONSOLE}
  {$ENDIF}
  {$IFDEF UNIX}
  //Handle interupts (requests for our process to terminate)
  FpSignal(SIGTerm, @OnInterrupt);
  FpSignal(SIGINT, @OnInterrupt);
  {$ENDIF}
  {$IFDEF MSWindows}
  TimeBeginPeriod(1); //initialize timer precision
  SetConsoleCtrlHandler(@OnConsoleCtrl, True); //Handle requests for our process to terminate
  {$ENDIF}

  fEventHandler := TKMServerEventHandler.Create; // Will create gLog as well

  // DedicatedServer stores everything alongside in the local folder
  fSettings := TKMServerSettings.Create(slExeDir);
  fSettings.SaveSettings;
  fSettingsLastModified := FileAge(fSettings.Path);
  fLastSettingsFileCheck := TimeGet;

  Writeln('=========== KaM Remake ' + GAME_VERSION + ' Dedicated Server ===========');
  Writeln('');
  Writeln('Log file: ' + gLog.LogPath);
  Writeln('Settings file: ' + fSettings.Path);
  Writeln('');

  fEventHandler.ServerStatusMessage('Using protocol for clients running ' + NET_PROTOCOL_REVISON);

  while True do
  begin
    // Catch and log exceptions
    try
      RunTheServer;
    except
      on E: Exception do //todo -cComplicated: For some reason this doesn't catch exceptions that occur within network events e.g. OnReceive (once server is running errors can really only occur in these events)
      begin
        fEventHandler.ServerStatusMessage('EXCEPTION: ' + E.ClassName + ': ' + E.Message);
        {$IFDEF FPC} fEventHandler.ServerStatusMessage(GetExceptionCallStack()); {$ENDIF}
        {$IFDEF WDC} fEventHandler.ServerStatusMessage(E.StackTrace); {$ENDIF}
        fEventHandler.ServerStatusMessage('Server restarting...');
        FreeAndNil(fDedicatedServer);
        fEventHandler.ServerStatusMessage('Sleeping for 5 seconds...');
        Sleep(5000); //Give the OS time to close the socket before restarting
      end;
    end;
  end;

  fDedicatedServer.Stop;
  fDedicatedServer.Free;
  fEventHandler.Free;

  {$IFDEF MSWindows}
  TimeEndPeriod(1);
  {$ENDIF}
end.

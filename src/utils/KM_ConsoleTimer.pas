unit KM_ConsoleTimer;
{$I KaM_Remake.inc}

interface
uses
  Windows, Classes, SyncObjs, Diagnostics;

  //Example taken from
  //https://stackoverflow.com/questions/12026951/using-vcl-ttimer-in-delphi-console-application
type

  //Mimic class for ExtCtrls.TTimer, which is not allowed to use in console app
  //Event procedure proceed in the main thread
  //To archive that Classes.CheckSynchronized should be invoked from the main thread
  TKMConsoleTimer = Class(TThread)
  private
    FCancelFlag: TSimpleEvent;
    FTimerEnabledFlag: TSimpleEvent;
    FTimerProc: TNotifyEvent; // method to call
    FInterval: integer;
    procedure SetEnabled(doEnable: boolean);
    function GetEnabled: boolean;
    procedure SetInterval(interval: integer);
    procedure SwapToMainThread;
  protected
    procedure Execute; override;
  public
    Constructor Create;
    Destructor Destroy; override;
    property Enabled : boolean read GetEnabled write SetEnabled;
    property Interval: integer read FInterval write SetInterval;
    // Note: OnTimerEvent is executed in TKMConsoleTimer thread
    property OnTimerEvent: TNotifyEvent read FTimerProc write FTimerProc;
  end;
	

implementation
uses
  SysUtils;


constructor TKMConsoleTimer.Create;
begin
  inherited Create(false);
  FTimerEnabledFlag := TSimpleEvent.Create;
  FCancelFlag := TSimpleEvent.Create;
  FTimerProc := nil;
  FInterval := 1000;
  Self.FreeOnTerminate := false; // Main thread controls for thread destruction
end;


destructor TKMConsoleTimer.Destroy; // Call TConsoleTimer.Free to cancel the thread
begin
  Terminate; 
  FTimerEnabledFlag.ResetEvent; // Stop timer event
  FCancelFlag.SetEvent; // Set cancel flag
  Waitfor; // Synchronize
  FCancelFlag.Free;
  FTimerEnabledFlag.Free;
  inherited;
end;


//Method to synchronize on
procedure TKMConsoleTimer.SwapToMainThread;
begin
  FTimerProc(Self); // should be invoked in main server thread
end;


procedure TKMConsoleTimer.SetEnabled(doEnable: boolean);
begin
  if doEnable then
    FTimerEnabledFlag.SetEvent
  else
    FTimerEnabledFlag.ResetEvent;
end;


procedure TKMConsoleTimer.SetInterval(interval: integer);
begin
  FInterval := interval;
end;


procedure TKMConsoleTimer.Execute;
var
  waitList: array [0 .. 1] of THandle;
  waitInterval,lastProcTime: Int64;
  sw: TStopWatch;
begin
  sw.Create;
  waitList[0] := FTimerEnabledFlag.Handle;
  waitList[1] := FCancelFlag.Handle;
  lastProcTime := 0;
  while not Terminated do
  begin
    if (WaitForMultipleObjects(2, @waitList[0], false, INFINITE) <>
      WAIT_OBJECT_0) then
      break; // Terminate thread when FCancelFlag is signaled
    if Assigned(FTimerProc) then
    begin
      waitInterval := FInterval - lastProcTime;
      if (waitInterval < 0) then
        waitInterval := 0;
      if WaitForSingleObject(FCancelFlag.Handle,waitInterval) <> WAIT_TIMEOUT then
        break;

      if WaitForSingleObject(FTimerEnabledFlag.Handle, 0) = WAIT_OBJECT_0 then
      begin
        sw.Start;
        Synchronize(SwapToMainThread); //Invoke event procedure in main thread
        sw.Stop;
        // Interval adjusted for FTimerProc execution time
        lastProcTime := sw.ElapsedMilliSeconds;
      end;
    end;
  end;
end;


function TKMConsoleTimer.GetEnabled: boolean;
begin
  Result := (FTimerEnabledFlag.Waitfor(0) = wrSignaled);
end;


end.

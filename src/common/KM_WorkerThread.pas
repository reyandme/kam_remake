unit KM_WorkerThread;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Generics.Collections;

  // procedure TKMWorkLoggerCallback(aJobName: String);

type
  ITKMWorkerThreadTask = class abstract(TInterfacedObject)
    procedure exec; virtual; abstract;
  end;

  TKMWorkerThreadTaskBase = class abstract(ITKMWorkerThreadTask)
  protected
    WorkName: string;
  public
    constructor Create(const aWorkName: String);
  end;

  TKMWorkerThreadTask = class(TKMWorkerThreadTaskBase)
  private
    Proc: TProc;
    Callback: TProc<String>;
  public
    constructor Create(aProc: TProc; aCallback: TProc<String> = nil; aWorkName: string = ''); overload;
    constructor Create(aProc: TProc; aCallback: aWorkName: string = ''); overload;

    procedure exec; override;
  end;

  TKMWorkerThread = class(TThread)
  private
    fWorkerThreadName: string;
    fWorkCompleted: Boolean;
    fTaskQueue: TQueue<ITKMWorkerThreadTask>;

    procedure NameThread; overload;
    procedure NameThread(aThreadName: string); overload;
    function GetBaseThreadName: string;
  public
    //Special mode for exception handling. Runs work synchronously inside Enqueue
    fSynchronousExceptionMode: Boolean;

    constructor Create(const aThreadName: string = '');
    destructor Destroy; override;
    procedure Execute; override;

    procedure Enqueue(aTask: ITKMWorkerThreadTask);
    procedure WaitForAllWorkToComplete;
  end;


  // Holder of WorkerThread
  // It should manage its state and recreate an instance if needed
  TKMWorkerThreadHolder = class
  private
    fWorkerThreadName: string;
    fWorkerThread: TKMWorkerThread;
    function GetWorkerThread: TKMWorkerThread;
  public
    constructor Create(const aThreadName: String);
    destructor Destroy; override;

    property Worker: TKMWorkerThread read GetWorkerThread write fWorkerThread;
  end;


implementation
uses
  KM_Log;


constructor TKMWorkerThreadTaskBase.Create(const aWorkName: String);
begin
  WorkName := aWorkName;
end;

constructor TKMWorkerThreadTask.Create(aProc: TProc; aCallback: TProc<String> = nil; aWorkName: string = '');
begin
  inherited Create(aWorkName);
  Proc := aProc;
  Callback := aCallback;
end;

constructor TKMWorkerThreadTask.Create(aProc: TProc; aWorkName: string = '');
begin
  Create(aProc, nil, aWorkName);
end;

procedure TKMWorkerThreadTask.exec;
begin
  Proc();
  if Assigned(Callback) then
    Callback(WorkName);
end;

{ TKMWorkerThread }
constructor TKMWorkerThread.Create(const aThreadName: string = '');
begin
  //Thread isn't started until all constructors have run to completion
  //so Create(False) may be put in front as well
  inherited Create(False);

  fWorkerThreadName := aThreadName;

  {$IFDEF DEBUG}
  if fWorkerThreadName <> '' then
    TThread.NameThreadForDebugging(fWorkerThreadName, ThreadID);
  {$ENDIF}

  fWorkCompleted := False;
  fSynchronousExceptionMode := False;
  fTaskQueue := TQueue<ITKMWorkerThreadTask>.Create;
end;

destructor TKMWorkerThread.Destroy;
begin
  Terminate;
  //Wake the thread if it's waiting
  TMonitor.Enter(fTaskQueue);
  try
    TMonitor.Pulse(fTaskQueue);
  finally
    TMonitor.Exit(fTaskQueue);
  end;

  inherited Destroy;

  fTaskQueue.Free; // Free task queue after Worker thread is destroyed so we don't wait for it
end;


function TKMWorkerThread.GetBaseThreadName: string;
begin
  {$IFDEF DEBUG}
  Result := fWorkerThreadName + ' Jobs=' + IntToStr(fTaskQueue.Count); // Has to be synced!
  {$ELSE}
  Result := '';
  {$ENDIF}
end;


procedure TKMWorkerThread.NameThread;
begin
  {$IFDEF DEBUG}
  NameThread(fWorkerThreadName);
  {$ENDIF}
end;


procedure TKMWorkerThread.NameThread(aThreadName: string);
begin
  {$IFDEF DEBUG}
  if fWorkerThreadName <> '' then
    TThread.NameThreadForDebugging(aThreadName);
  {$ENDIF}
end;


procedure TKMWorkerThread.Execute;
var
  job: ITKMWorkerThreadTask;
  loopRunning: Boolean;
  threadName: string;
begin
  job := nil;
  loopRunning := True;
  threadName := '';

  while loopRunning do
  begin
    TMonitor.Enter(fTaskQueue);
    try
      threadName := GetBaseThreadName; // get name under TMonitor, cause we access fTaskQueue
      if fTaskQueue.Count > 0 then
      begin
        job := fTaskQueue.Dequeue;
      end
      else
      begin
        //We may only terminate once we have finished all our work
        if Terminated then
        begin
          loopRunning := False;
        end
        else
        begin
          //Notify main thread that worker is idle if it's blocked in WaitForAllWorkToComplete
          fWorkCompleted := True;
          TMonitor.Pulse(fTaskQueue);

          TMonitor.Wait(fTaskQueue, 10000);
          if fTaskQueue.Count > 0 then
            job := fTaskQueue.Dequeue;
        end;
      end;
    finally
      TMonitor.Exit(fTaskQueue);
    end;

    if job <> nil then
    begin
      NameThread(threadName);
      job.exec;
      FreeAndNil(job);
    end;

    NameThread;
  end;
end;

// procedure TKMWorkLoggerCallback(aJobName: String);
// begin
//   gLog.MultithreadLogging := True;
//   try
//     gLog.AddTime(Format('Job ''%s'' is completed', [aJobName]));
//   finally
//     gLog.MultithreadLogging := False;
//   end;
// end;

procedure TKMWorkerThread.Enqueue(aTask: ITKMWorkerThreadTask);
begin
  if fSynchronousExceptionMode then
  begin
    aTask.exec;
  end
  else
  begin
    if Finished then
      raise Exception.Create('Worker thread not running in TKMWorkerThread.Enqueue');

    TMonitor.Enter(fTaskQueue);
    try
      fWorkCompleted := False;
      fTaskQueue.Enqueue(aTask);

      TMonitor.Pulse(fTaskQueue);
    finally
      TMonitor.Exit(fTaskQueue);
    end;
  end;
end;


procedure TKMWorkerThread.WaitForAllWorkToComplete;
begin
  if fSynchronousExceptionMode then
    Exit;

  TMonitor.Enter(fTaskQueue);
  try
    if not fWorkCompleted and not Finished then
    begin
      //Wait infinite until worker thread finish his job
      while not TMonitor.Wait(fTaskQueue, 1000) do ;
    end;
  finally
    TMonitor.Exit(fTaskQueue);
  end;
end;


{ TKMWorkerThreadHolder }
constructor TKMWorkerThreadHolder.Create(const aThreadName: String);
begin
  inherited Create;

  fWorkerThreadName := aThreadName;
end;


destructor TKMWorkerThreadHolder.Destroy;
begin
  FreeAndNil(fWorkerThread);

  inherited;
end;


// Get working thread instance
// Working thread could be Finished, f.e. in case of an error during its execution
// Thread is not running in that case after Continue is pressed in madexcept window and has Finished flag
// We can call old thread destructor via Free-ing it and then recreate new worker thread.
function TKMWorkerThreadHolder.GetWorkerThread: TKMWorkerThread;
begin
  if (fWorkerThread = nil) then
    // Create new thread
    fWorkerThread := TKMWorkerThread.Create(fWorkerThreadName)
  else
  if fWorkerThread.Finished then
  begin
    // Call destructor of an old thread
    fWorkerThread.Free;
    // Create new one instead
    fWorkerThread := TKMWorkerThread.Create(fWorkerThreadName);
  end;

  Result := fWorkerThread;
end;


end.


unit KM_WorkerThread;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Generics.Collections;

type
  TKMWorkerThreadTask = class
    Proc: TProc;
  end;

  TKMWorkerThread = class(TThread)
  private
    fWorkCompleted: Boolean;
    fTaskQueue: TQueue<TKMWorkerThreadTask>;
  public
    //Special mode for exception handling. Runs work synchronously inside QueueWork
    fSynchronousExceptionMode: Boolean;

    constructor Create;
    destructor Destroy; override;
    procedure Execute; override;

    procedure QueueWork(aProc: TProc);
    procedure WaitForAllWorkToComplete;
  end;

implementation


{ TKMWorkerThread }
constructor TKMWorkerThread.Create;
begin
  //Thread isn't started until all constructors have run to completion
  //so Create(False) may be put in front as well
  inherited Create(False);

  fWorkCompleted := False;
  fSynchronousExceptionMode := False;
  fTaskQueue := TQueue<TKMWorkerThreadTask>.Create;
end;

destructor TKMWorkerThread.Destroy;
begin
  Terminate;
  //Wake the thread if it's waiting
  TMonitor.Enter(fTaskQueue);
  TMonitor.Pulse(fTaskQueue);
  TMonitor.Exit(fTaskQueue);

  inherited;
end;

procedure TKMWorkerThread.Execute;
var
  Job: TKMWorkerThreadTask;
  LoopRunning: Boolean;
begin
  Job := nil;
  LoopRunning := True;

  while LoopRunning do
  begin
    TMonitor.Enter(fTaskQueue);
    if fTaskQueue.Count > 0 then
    begin
      Job := fTaskQueue.Dequeue;
    end
    else
    begin
      //We may only terminate once we have finished all our work
      if Terminated then
      begin
        LoopRunning := False;
      end
      else
      begin
        //Notify main thread that worker is idle if it's blocked in WaitForAllWorkToComplete
        fWorkCompleted := True;
        TMonitor.Pulse(fTaskQueue);

        TMonitor.Wait(fTaskQueue, 10000);
        if fTaskQueue.Count > 0 then
          Job := fTaskQueue.Dequeue;
      end;
    end;
    TMonitor.Exit(fTaskQueue);

    if Job <> nil then
    begin
      Job.Proc();
      FreeAndNil(Job);
    end;
  end;
end;

procedure TKMWorkerThread.QueueWork(aProc: TProc);
var
  Job: TKMWorkerThreadTask;
begin
  if fSynchronousExceptionMode then
  begin
    aProc();
  end
  else
  begin
    if Finished then
      raise Exception.Create('Worker thread not running in TKMWorkerThread.QueueWork');

    Job := TKMWorkerThreadTask.Create;
    Job.Proc := aProc;

    TMonitor.Enter(fTaskQueue);

    fWorkCompleted := False;
    fTaskQueue.Enqueue(Job);

    TMonitor.Pulse(fTaskQueue);
    TMonitor.Exit(fTaskQueue);
  end;
end;

procedure TKMWorkerThread.WaitForAllWorkToComplete;
begin
  if fSynchronousExceptionMode then
    Exit;

  TMonitor.Enter(fTaskQueue);
  if not fWorkCompleted and not Finished then
  begin
    if not TMonitor.Wait(fTaskQueue, 10000) then
      raise Exception.Create('Timeout in TKMWorkerThread.WaitForAllWorkToComplete');
  end;
  TMonitor.Exit(fTaskQueue);
end;

end.

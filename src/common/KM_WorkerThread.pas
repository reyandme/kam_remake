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
  Job := TKMWorkerThreadTask.Create;
  Job.Proc := aProc;

  TMonitor.Enter(fTaskQueue);

  fWorkCompleted := False;
  fTaskQueue.Enqueue(Job);

  TMonitor.Pulse(fTaskQueue);
  TMonitor.Exit(fTaskQueue);
end;

procedure TKMWorkerThread.WaitForAllWorkToComplete;
begin
  TMonitor.Enter(fTaskQueue);
  while not fWorkCompleted do
  begin
    TMonitor.Wait(fTaskQueue, 10000);
  end;
  TMonitor.Exit(fTaskQueue);
end;

end.

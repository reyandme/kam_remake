unit KM_GameSaveWorkerThreadHolder;
interface
uses
  SysUtils, 
  KM_WorkerThread;


type
  TKMGameSaveWorkerType = (wtMain, wtGIP, wtSavePoints, wtRandomChecks);

  TKMGameSaveWorkerThreadHolder = class
  private
    fName: string;
    fWorkerHolders: array[TKMGameSaveWorkerType] of TKMWorkerThreadHolder;
    function GetWorkerThread(aWT: TKMGameSaveWorkerType): TKMWorkerThread;
  public
    constructor Create(const aWorkerName: String);
    destructor Destroy; override;

    property Worker[ST: TKMGameSaveWorkerType]: TKMWorkerThread read GetWorkerThread;
    procedure SetSynchronousExceptionMode(const aValue: Boolean);
    procedure WaitForAllWorkToComplete;
    procedure QueueToAll(aWorkerType: TKMGameSaveWorkerType; aProc: TProc; aJobName: string = '');    
    procedure WaitForWorker(aWorkerType: TKMGameSaveWorkerType);
  end;

implementation
uses
  TypInfo,
  KM_Log;

const
  WORKER_NAMES: array[TKMGameSaveWorkerType] of string = ('SaveMain', 'SaveGIP', 'SavePoints', 'SaveRNG');

  
{ TKMGameSaveWorkerThreadHolder }
constructor TKMGameSaveWorkerThreadHolder.Create(const aWorkerName: String);
var
  WT: TKMGameSaveWorkerType;
begin
  inherited Create;

  fName := aWorkerName;
  for WT := Low(TKMGameSaveWorkerType) to High(TKMGameSaveWorkerType) do
    fWorkerHolders[WT] := TKMWorkerThreadHolder.Create(fName + ' ' + WORKER_NAMES[WT]);
end;


destructor TKMGameSaveWorkerThreadHolder.Destroy;
var
  WT: TKMGameSaveWorkerType;
begin
  for WT := Low(TKMGameSaveWorkerType) to High(TKMGameSaveWorkerType) do
    fWorkerHolders[WT].Free;

  inherited;
end;


function TKMGameSaveWorkerThreadHolder.GetWorkerThread(aWT: TKMGameSaveWorkerType): TKMWorkerThread;
begin
  Result := fWorkerHolders[aWT].Worker;
end;


procedure TKMGameSaveWorkerThreadHolder.SetSynchronousExceptionMode(const aValue: Boolean);
var
  WT: TKMGameSaveWorkerType;
begin
  for WT := Low(TKMGameSaveWorkerType) to High(TKMGameSaveWorkerType) do
    fWorkerHolders[WT].Worker.SynchronousExceptionMode := aValue;
end;


procedure TKMGameSaveWorkerThreadHolder.WaitForAllWorkToComplete;
var
  WT: TKMGameSaveWorkerType;
begin
  gLog.MultithreadLogging := True;
  gLog.AddTime('START WaitForAllWorkToComplete ');
  for WT := Low(TKMGameSaveWorkerType) to High(TKMGameSaveWorkerType) do
    fWorkerHolders[WT].Worker.WaitForAllWorkToComplete;
  gLog.AddTime('DONE WaitForAllWorkToComplete ');
  gLog.MultithreadLogging := False;
end;


procedure TKMGameSaveWorkerThreadHolder.QueueToAll(aWorkerType: TKMGameSaveWorkerType; aProc: TProc; aJobName: string = '');
begin
  gLog.MultithreadLogging := True;
  gLog.AddTime('START QueueToAll ' + GetEnumName(TypeInfo(TKMGameSaveWorkerType), Integer(aWorkerType)));
  fWorkerHolders[aWorkerType].Worker.QueueWork(procedure
    var
      WT: TKMGameSaveWorkerType;
    begin
      gLog.MultithreadLogging := True;
      try
        for WT := Low(TKMGameSaveWorkerType) to High(TKMGameSaveWorkerType) do
          if aWorkerType <> WT then
          begin
            fWorkerHolders[aWorkerType].Worker.WaitForAllWorkToComplete;
          end;

        aProc();
      finally
        gLog.MultithreadLogging := False;
      end;
    end, aJobName
  );
  gLog.AddTime('DONE QueueToAll ' + GetEnumName(TypeInfo(TKMGameSaveWorkerType), Integer(aWorkerType)));
  gLog.MultithreadLogging := False;
end;


procedure TKMGameSaveWorkerThreadHolder.WaitForWorker(aWorkerType: TKMGameSaveWorkerType);
var
  WT: TKMGameSaveWorkerType;
begin
  gLog.MultithreadLogging := True;
  gLog.AddTime('START WaitForWorker ' + GetEnumName(TypeInfo(TKMGameSaveWorkerType), Integer(aWorkerType)));
  for WT := Low(TKMGameSaveWorkerType) to High(TKMGameSaveWorkerType) do
  begin
    if aWorkerType = WT then Continue;

    fWorkerHolders[WT].Worker.QueueWork(procedure
      begin
        fWorkerHolders[aWorkerType].Worker.WaitForAllWorkToComplete;
      end, 'WaitForWorker ' + GetEnumName(TypeInfo(TKMGameSaveWorkerType), Integer(aWorkerType)));
  end;
  gLog.AddTime('DONE WaitForWorker ' + GetEnumName(TypeInfo(TKMGameSaveWorkerType), Integer(aWorkerType)));
  gLog.MultithreadLogging := False;
end;


end.


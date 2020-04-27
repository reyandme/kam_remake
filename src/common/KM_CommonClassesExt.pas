unit KM_CommonClassesExt;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, TypInfo, Generics.Collections;

type
  ERuntimeTypeError = class(Exception);

  TSet<T> = class
  strict private
    class function TypeInfo: PTypeInfo; inline; static;
    class function GetSetToString(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): String; static;
  public
    class function IsSet: Boolean; static;
    class function Cardinality(const Value: T): Integer; static;
    class function SetToString(const Value: T): String; static;
  end;

  // List with unique elements
  TKMListUnique<T> = class(TList<T>)
  public
    function Add(const Value: T): Integer; reintroduce;
  end;

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

  function GetCardinality(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): Integer; inline;

const
  Masks: array[0..7] of Byte = (1, 2, 4, 8, 16, 32, 64, 128);

implementation


{ TSet<T>

  Usage: Writeln(TSet<SomeSet>.Cardinality(Value));

  taken from:
  https://stackoverflow.com/questions/34442102/how-can-i-get-the-number-of-elements-of-any-variable-of-type-set }
class function TSet<T>.TypeInfo: PTypeInfo;
begin
  Result := System.TypeInfo(T);
end;

class function TSet<T>.IsSet: Boolean;
begin
  Result := TypeInfo.Kind = tkSet;
end;

function GetCardinality(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): Integer; inline;
var
  I, J: Integer;
begin
  Result := 0;
  for I := 0 to SizeOfSet - 1 do
    for J := 0 to 7 do
      if (PSet^[I] and Masks[J]) > 0 then
        Inc(Result);
end;


class function TSet<T>.GetSetToString(const PSet: PByteArray; const SizeOfSet(*in bytes*): Integer): String;
var
  I, J: Integer;
  BaseType: PTypeInfo;
begin
  Result := '';

  BaseType := GetTypeData(TypeInfo).CompType{$IFDEF WDC}^{$ENDIF}; //FPC has PTypeInfo here, while WDC has PPTypeInfo

  for I := 0 to SizeOfSet - 1 do
    for J := 0 to 7 do
      if (PSet^[I] and Masks[J]) > 0 then
      begin
        if Result <> '' then
          Result := Result + ', ';
        {$IFDEF WDC}
        Result := Result + GetEnumName(BaseType, J + I*8);
        {$ENDIF}
        {$IFDEF FPC}
        if BaseType^.Kind = tkInteger then //For some reason FPC can't return EnumName, at least for tkInteger values
          Result := Result + IntToStr(J + I*8)
        else
          Result := Result + GetEnumName(BaseType, J + I*8);
        {$ENDIF}
      end;
  Result := '[' + Result + ']';
end;

class function TSet<T>.Cardinality(const Value: T): Integer;
var
  EnumTypeData: PTypeData;
begin
  if not IsSet then
    raise ERuntimeTypeError.Create('Invalid type in TSet<T>, T must be a set');
  Result := GetCardinality(PByteArray(@Value), SizeOf(Value));
end;


class function TSet<T>.SetToString(const Value: T): String;
var
  EnumTypeData: PTypeData;
begin
  if not IsSet then
    raise ERuntimeTypeError.Create('Invalid type in TSet<T>, T must be a set');

  Result := GetSetToString(PByteArray(@Value), SizeOf(Value));
end;



{ TKMListUnique<T> }
function TKMListUnique<T>.Add(const Value: T): Integer;
begin
  if Contains(Value) then Exit;

  inherited Add(Value);
end;


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

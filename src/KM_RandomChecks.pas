unit KM_RandomChecks;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC}zstream, {$ENDIF}
  {$IFDEF WDC}ZLib, {$ENDIF}
  Generics.Collections,
  KM_CommonClasses, KM_WorkerThread;

type
  TKMLogRngType = (lrtNone, lrtInt, lrtSingle, lrtExt);

  TKMRngLogRecord = record
    ValueType: TKMLogRngType;
    Seed: Integer;
    ValueI: Integer;
    ValueS: Single;
    ValueE: Extended;
    CallerId: Byte;
  end;

  TKMRLRecordList = TList<TKMRngLogRecord>;

  // Logger for random check calls
  TKMRandomCheckLogger = class
  private
    fEnabled: Boolean;
    fGameTick: Cardinal;
    fSavedTicksCnt: Cardinal;
    fRngChecksInTick: TKMRLRecordList;
//    fSaveStream: TKMemoryStreamBinary;
//    fRngLogStream: TKMemoryStream;
    fCallers: TDictionary<Byte, AnsiString>;
    fRngLog: TDictionary<Cardinal, TKMRLRecordList>;
    fTickStreamQueue: TObjectQueue<TKMemoryStreamBinary>;

    function GetCallerID(const aCaller: AnsiString; aValue: Extended; aValueType: TKMLogRngType): Byte;
    procedure AddRecordToList(aTick: Cardinal; const aRec: TKMRngLogRecord);
    procedure AddRecordToDict(aTick: Cardinal; const aRec: TKMRngLogRecord);

    procedure LoadFromStreamAndParseToDict(aLoadStream: TKMemoryStream);
    procedure SaveTickToStream(aStream: TKMemoryStream; aRngChecksInTick: TKMRLRecordList);

    procedure LoadHeader(aLoadStream: TKMemoryStream);

//    procedure ParseSaveStream;
    procedure ParseStreamToDict(aLoadStream: TKMemoryStream);
    function GetEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddToLog(const aCaller: AnsiString; aValue: Integer; aSeed: Integer); overload;
    procedure AddToLog(const aCaller: AnsiString; aValue: Single; aSeed: Integer); overload;
    procedure AddToLog(const aCaller: AnsiString; aValue: Extended; aSeed: Integer); overload;

//    property RngLogStream: TKMemoryStream read fRngLogStream;

    property Enabled: Boolean read GetEnabled write fEnabled;

    procedure SaveToPathAsync(const aPath: String; aWorkerThread: TKMWorkerThread);
//    procedure ParseSaveStreamAndSaveAsText(aPath: String);
    procedure SaveAsText(const aPath: String);
    procedure LoadFromPath(const aPath: String);
    procedure LoadFromPathAndParseToDict(const aPath: String);
    procedure Clear;

    procedure UpdateState(aGameTick: Cardinal);
  end;


var
  gRandomCheckLogger: TKMRandomCheckLogger;



implementation
uses
  Math,
  KM_Log, Classes, SysUtils, KM_Defaults;

var
  MAX_TICKS_CNT: Integer = 10*60*10; // 10 minutes


{ TKMRandomLogger }
constructor TKMRandomCheckLogger.Create;
begin
//  fRngLogStream := TKMemoryStream.Create;
  fCallers := TDictionary<Byte, AnsiString>.Create;
  fRngLog := TDictionary<Cardinal, TKMRLRecordList>.Create;
  fTickStreamQueue := TObjectQueue<TKMemoryStreamBinary>.Create;
  fTickStreamQueue.OwnsObjects := True; // Set the OwnsObjects to true - the Queue will free them automatically
  fRngChecksInTick := TKMRLRecordList.Create;
  fSavedTicksCnt := 0;
  fEnabled := True;

//  fSaveStream := TKMemoryStreamBinary.Create;
end;


destructor TKMRandomCheckLogger.Destroy;
begin
  Clear;
  FreeAndNil(fRngLog);
  FreeAndNil(fCallers);
  FreeAndNil(fRngChecksInTick);
  FreeAndNil(fTickStreamQueue);
//  FreeAndNil(fRngLogStream);

//  FreeAndNil(fSaveStream);

  inherited;
end;


function TKMRandomCheckLogger.GetCallerID(const aCaller: AnsiString; aValue: Extended; aValueType: TKMLogRngType): Byte;
var
  CallerPair: TPair<Byte, AnsiString>;
begin
  for CallerPair in fCallers do
  begin
    if CallerPair.Value = aCaller then
      Exit(CallerPair.Key);
  end;

  Result := fCallers.Count;
  fCallers.Add(Result, aCaller);
end;


function TKMRandomCheckLogger.GetEnabled: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fEnabled;
end;


procedure TKMRandomCheckLogger.AddToLog(const aCaller: AnsiString; aValue: Integer; aSeed: Integer);
var
  rec: TKMRngLogRecord;
begin
  if (Self = nil) or not fEnabled then Exit;

  rec.Seed := aSeed;
  rec.ValueType := lrtInt;
  rec.ValueI := aValue;
  rec.CallerId := GetCallerID(aCaller, aValue, lrtInt);

  AddRecordToList(fGameTick, rec);
end;

procedure TKMRandomCheckLogger.AddToLog(const aCaller: AnsiString; aValue: Single; aSeed: Integer);
var
  rec: TKMRngLogRecord;
begin
  if (Self = nil) or not fEnabled then Exit;

  rec.Seed := aSeed;
  rec.ValueType := lrtSingle;
  rec.ValueS := aValue;
  rec.CallerId := GetCallerID(aCaller, aValue, lrtInt);

  AddRecordToList(fGameTick, rec);
end;

procedure TKMRandomCheckLogger.AddToLog(const aCaller: AnsiString; aValue: Extended; aSeed: Integer);
var
  rec: TKMRngLogRecord;
begin
  if (Self = nil) or not fEnabled then Exit;

  rec.Seed := aSeed;
  rec.ValueType := lrtExt;
  rec.ValueE := aValue;
  rec.CallerId := GetCallerID(aCaller, aValue, lrtInt);

  AddRecordToList(fGameTick, rec);
end;


procedure TKMRandomCheckLogger.AddRecordToDict(aTick: Cardinal; const aRec: TKMRngLogRecord);
var
  list: TList<TKMRngLogRecord>;
begin
  if (Self = nil) or not fEnabled then Exit;

  if not fRngLog.TryGetValue(aTick, list) then
  begin
    list := TList<TKMRngLogRecord>.Create;
    fRngLog.Add(aTick, list);
  end;

  list.Add(aRec);
end;



procedure TKMRandomCheckLogger.AddRecordToList(aTick: Cardinal; const aRec: TKMRngLogRecord);
begin
  if (Self = nil) or not fEnabled then Exit;

  fRngChecksInTick.Add(aRec);
end;


procedure TKMRandomCheckLogger.SaveTickToStream(aStream: TKMemoryStream; aRngChecksInTick: TKMRLRecordList);
var
  I: Integer;
  RngValueType: TKMLogRngType;
begin
  if (Self = nil) or not fEnabled then Exit;

  aStream.Write(fGameTick); //Tick
  aStream.Write(Integer(aRngChecksInTick.Count)); //Number of log records in tick
//  Inc(Cnt, fRngChecksInTick.Count);
  for I := 0 to aRngChecksInTick.Count - 1 do
  begin
    aStream.Write(aRngChecksInTick[I].Seed);
    RngValueType := aRngChecksInTick[I].ValueType;
    aStream.Write(RngValueType, SizeOf(RngValueType));
    aStream.Write(aRngChecksInTick[I].CallerId);
    case RngValueType of
      lrtInt:     aStream.Write(aRngChecksInTick[I].ValueI);
      lrtSingle:  aStream.Write(aRngChecksInTick[I].ValueS);
      lrtExt:     aStream.Write(aRngChecksInTick[I].ValueE);
    end;
  end;
end;


procedure TKMRandomCheckLogger.UpdateState(aGameTick: Cardinal);
var
  tickStream: TKMemoryStreamBinary;
begin
  if (Self = nil) or not fEnabled then Exit;

  fGameTick := aGameTick;

  // Delete oldest stream object from queue
  if fTickStreamQueue.Count > MAX_TICKS_CNT then
  begin
    fTickStreamQueue.Dequeue; // Will also automatically free an object, because of OwnObjects property
    fTickStreamQueue.TrimExcess;
  end;

  tickStream := TKMemoryStreamBinary.Create;
  SaveTickToStream(tickStream, fRngChecksInTick);
  fTickStreamQueue.Enqueue(tickStream);

  fRngChecksInTick.Clear;

  fSavedTicksCnt := fTickStreamQueue.Count;
end;


procedure TKMRandomCheckLogger.LoadHeader(aLoadStream: TKMemoryStream);
var
  I, Count: Integer;
  CallerId: Byte;
  CallerName: AnsiString;
begin
  if (Self = nil) then Exit;

  aLoadStream.CheckMarker('CallersTable');
  aLoadStream.Read(Count);
  for I := 0 to Count - 1 do
  begin
    aLoadStream.Read(CallerId);
    aLoadStream.ReadA(CallerName);
    fCallers.Add(CallerId, CallerName);
  end;
  aLoadStream.CheckMarker('KaMRandom_calls');
  aLoadStream.Read(fSavedTicksCnt);
end;


procedure TKMRandomCheckLogger.LoadFromPath(const aPath: String);
var
  I: Integer;
  tickStreamSize: Cardinal;
  LoadStream, tickStream: TKMemoryStreamBinary;
begin
  if Self = nil then Exit;

  if not FileExists(aPath) then
  begin
    gLog.AddTime('RandomsChecks file ''' + aPath + ''' was not found. Skip load rng');
    Exit;
  end;

  Clear;
  LoadStream := TKMemoryStreamBinary.Create;
  try
    LoadStream.LoadFromFileCompressed(aPath, 'RNGCompressed');

    LoadHeader(LoadStream);

    for I := 0 to fSavedTicksCnt - 1 do
    begin
      tickStream := TKMemoryStreamBinary.Create;

      LoadStream.Read(tickStreamSize);
      tickStream.CopyFrom(LoadStream, tickStreamSize);

      fTickStreamQueue.Enqueue(tickStream);
    end;

//    fSaveStream.CopyFrom(LoadStream, LoadStream.Size - LoadStream.Position);
  finally
    LoadStream.Free;
  end;
end;


procedure TKMRandomCheckLogger.LoadFromStreamAndParseToDict(aLoadStream: TKMemoryStream);
begin
  Clear;

  LoadHeader(aLoadStream);

  ParseStreamToDict(aLoadStream);
end;


procedure TKMRandomCheckLogger.LoadFromPathAndParseToDict(const aPath: String);
var
  LoadStream: TKMemoryStreamBinary;
begin
  if Self = nil then Exit;

  if not FileExists(aPath) then
  begin
    gLog.AddTime('RandomsChecks file ''' + aPath + ''' was not found. Skip load rng');
    Exit;
  end;

  LoadStream := TKMemoryStreamBinary.Create;
  try
    LoadStream.LoadFromFileCompressed(aPath, 'RNGCompressed');
    LoadFromStreamAndParseToDict(LoadStream);
  finally
    LoadStream.Free;
  end;
end;


//procedure TKMRandomCheckLogger.ParseSaveStream;
//var
//  ReadStream: TKMemoryStream;
//begin
//  ReadStream := TKMemoryStreamBinary.Create;
//  try
//    ReadStream.CopyFrom(fSaveStream, 0);
//    ReadStream.Position := 0;
//    ParseStreamToDict(ReadStream);
//  finally
//    ReadStream.Free;
//  end;
//end;


procedure TKMRandomCheckLogger.ParseStreamToDict(aLoadStream: TKMemoryStream);
var
  LogRec: TKMRngLogRecord;

  procedure ClearLogRec;
  begin
    LogRec.ValueI := 0;
    LogRec.ValueS := 0;
    LogRec.ValueE := 0;
    LogRec.CallerId := 0;
    LogRec.ValueType := lrtNone;
  end;

var
  I, K, CountInTick: Integer;
  Tick, tickStreamSize: Cardinal;
begin
  for I := 0 to fSavedTicksCnt - 1 do
  begin
    aLoadStream.Read(tickStreamSize); // load tick stream size and omit it, we don't use it here

    aLoadStream.Read(Tick);
    aLoadStream.Read(CountInTick);

    for K := 0 to CountInTick - 1 do
    begin
      ClearLogRec;
      aLoadStream.Read(LogRec.Seed);
      aLoadStream.Read(LogRec.ValueType, SizeOf(LogRec.ValueType));
      aLoadStream.Read(LogRec.CallerId);

      case LogRec.ValueType of
        lrtInt:     aLoadStream.Read(LogRec.ValueI);
        lrtSingle:  aLoadStream.Read(LogRec.ValueS);
        lrtExt:     aLoadStream.Read(LogRec.ValueE);
      end;
      AddRecordToDict(Tick, LogRec);
    end;
  end;
end;


//procedure TKMRandomCheckLogger.ParseSaveStreamAndSaveAsText(aPath: String);
//begin
//  ParseSaveStream;
//  SaveAsText(aPath);
//end;


procedure TKMRandomCheckLogger.SaveToPathAsync(const aPath: String; aWorkerThread: TKMWorkerThread);
var
  SaveStream, TickStream: TKMemoryStreamBinary;
//  CompressionStream: TCompressionStream;
  CallerPair: TPair<Byte, AnsiString>;
  enumerator: TEnumerator<TKMemoryStreamBinary>;
begin
  if (Self = nil) then Exit;

  SaveStream := TKMemoryStreamBinary.Create;

  SaveStream.PlaceMarker('CallersTable');
  SaveStream.Write(Integer(fCallers.Count));

  for CallerPair in fCallers do
  begin
    SaveStream.Write(CallerPair.Key);
    SaveStream.WriteA(CallerPair.Value);
  end;

  SaveStream.PlaceMarker('KaMRandom_calls');

  SaveStream.Write(Integer(fSavedTicksCnt));

  enumerator := fTickStreamQueue.GetEnumerator;

  while enumerator.MoveNext do
  begin
    TickStream := enumerator.Current;
    SaveStream.Write(Cardinal(TickStream.Size));
    SaveStream.CopyFrom(TickStream, 0);
  end;

  enumerator.Free;

//  SaveStream.CopyFrom(fSaveStream, 0);


//  for LogPair in fRngLog do
//  begin
//    SaveTickToStream(SaveStream, LogPair.Value);
//    Inc(Cnt, LogPair.Value.Count);
//  end;

//  SaveStream.WriteA('Total COUNT = ');
//  SaveStream.WriteA(AnsiString(IntToStr(Cnt)));

//  CompressionStream := TCompressionStream.Create(clNone, SaveStream);
//  CompressionStream.CopyFrom(fRngLogStream, 0);
  //SaveStream now contains the compressed data from SourceStream
//  CompressionStream.Free;

  TKMemoryStream.AsyncSaveToFileCompressedAndFree(SaveStream, aPath, 'RNGCompressed', aWorkerThread);
end;


procedure TKMRandomCheckLogger.SaveAsText(const aPath: String);
var
//  LogPair: TPair<Cardinal, TList<TKMRngLogRecord>>;
  I, Cnt: Integer;
  KeyTick: Cardinal;
  SL: TStringList;
  S, ValS: String;
  CallersIdList: TList<Byte>;
  CallerId: Byte;
  LogTicksList: TList<Cardinal>;
  LogRecList: TList<TKMRngLogRecord>;
begin
  if Self = nil then Exit;
  
  Cnt := 0;
  SL := TStringList.Create;
  try
    CallersIdList := TList<Byte>.Create(fCallers.Keys);
    try
      SL.Add('Callers: ' + IntToStr(CallersIdList.Count));
      CallersIdList.Sort;
      for CallerId in CallersIdList do
        SL.Add(Format('%d - %s', [CallerId, fCallers[CallerId]]));
    finally
      CallersIdList.Free;
    end;

    LogTicksList := TList<Cardinal>.Create(fRngLog.Keys);
    try
      SL.Add('LogRngRecords: ' + IntToStr(LogTicksList.Count) + ' ticks');
      LogTicksList.Sort;
      for KeyTick in LogTicksList do
      begin
        LogRecList := fRngLog[KeyTick];
        SL.Add(Format('Tick: %d, Tick Rng Count: %d', [KeyTick, LogRecList.Count]));
        Inc(Cnt, LogRecList.Count);
        for I := 0 to LogRecList.Count - 1 do
        begin
          ValS := 'NaN';
          case LogRecList[I].ValueType of
            lrtInt:     ValS := 'I ' + IntToStr(LogRecList[I].ValueI);
            lrtSingle:  ValS := 'S ' + FormatFloat('0.##############################', LogRecList[I].ValueS);
            lrtExt:     ValS := 'E ' + FormatFloat('0.##############################', LogRecList[I].ValueE);
          end;
          S := Format('%3d. %-50sSeed: %12d Val: %s', [I, fCallers[LogRecList[I].CallerId], LogRecList[I].Seed, ValS]);
          SL.Add(S);
        end;
      end;
    finally
      LogTicksList.Free;
    end;
    SL.Add('Total randomchecks count = ' + IntToStr(Cnt));
    SL.SaveToFile(aPath);
  finally
    SL.Free;
  end;
end;


procedure TKMRandomCheckLogger.Clear;
var
  list: TList<TKMRngLogRecord>;
//  TickStream: TKMemoryStreamBinary;
//  enumerator: TEnumerator<TKMemoryStreamBinary>;
begin
  if Self = nil then Exit;

  fCallers.Clear;
  fCallers.TrimExcess;

//  fSaveStream.Clear;

//  enumerator := fTickStreamQueue.GetEnumerator;
//
//  while enumerator.MoveNext do
//  begin
//    TickStream := enumerator.Current;
//    TickStream.Free;
//  end;

  fTickStreamQueue.Clear;
  fTickStreamQueue.TrimExcess;

  for list in fRngLog.Values do
    list.Free;

  fRngLog.Clear;
  fRngLog.TrimExcess;
  fEnabled := True;
end;


end.

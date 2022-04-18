unit KM_RandomChecks;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC}zstream, {$ENDIF}
  {$IFDEF WDC}ZLib, {$ENDIF}
  Generics.Collections,
  KM_CommonClasses
  {$IFDEF WDC OR FPC_FULLVERSION >= 30200}, KM_WorkerThread{$ENDIF};

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
//    fSaveStream: TKMemoryStream;
//    fRngLogStream: TKMemoryStream;
    fCallers: TDictionary<Byte, AnsiString>;
    fRngLog: TDictionary<Cardinal, TKMRLRecordList>;
    fTickStreamQueue: TObjectQueue<TKMemoryStream>;

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

    {$IFDEF WDC OR FPC_FULLVERSION >= 30200}
    procedure SaveToPathAsync(const aPath: String; aWorkerThread: TKMWorkerThread);
    {$ENDIF}
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
  KM_Log, Classes, SysUtils;

var
  MAX_TICKS_CNT: Integer = 10*60*10; // 10 minutes


{ TKMRandomLogger }
constructor TKMRandomCheckLogger.Create;
begin
//  fRngLogStream := TKMemoryStream.Create;
  fCallers := TDictionary<Byte, AnsiString>.Create;
  fRngLog := TDictionary<Cardinal, TKMRLRecordList>.Create;
  fTickStreamQueue := TObjectQueue<TKMemoryStream>.Create;
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
  callerPair: TPair<Byte, AnsiString>;
begin
  for callerPair in fCallers do
  begin
    if callerPair.Value = aCaller then
      Exit(callerPair.Key);
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
  rngValueType: TKMLogRngType;
begin
  if (Self = nil) or not fEnabled then Exit;

  aStream.Write(fGameTick); //Tick
  aStream.Write(Integer(aRngChecksInTick.Count)); //Number of log records in tick
//  Inc(Cnt, fRngChecksInTick.Count);
  for I := 0 to aRngChecksInTick.Count - 1 do
  begin
    aStream.Write(aRngChecksInTick[I].Seed);
    rngValueType := aRngChecksInTick[I].ValueType;
    aStream.Write(rngValueType, SizeOf(rngValueType));
    aStream.Write(aRngChecksInTick[I].CallerId);
    case rngValueType of
      lrtInt:     aStream.Write(aRngChecksInTick[I].ValueI);
      lrtSingle:  aStream.Write(aRngChecksInTick[I].ValueS);
      lrtExt:     aStream.Write(aRngChecksInTick[I].ValueE);
    end;
  end;
end;


procedure TKMRandomCheckLogger.UpdateState(aGameTick: Cardinal);
var
  tickStream: TKMemoryStream;
begin
  if (Self = nil) or not fEnabled then Exit;

  fGameTick := aGameTick;

  // Delete oldest stream object from queue
  if fTickStreamQueue.Count >= MAX_TICKS_CNT then
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
  callerId: Byte;
  callerName: AnsiString;
begin
  if (Self = nil) then Exit;

  aLoadStream.CheckMarker('CallersTable');
  aLoadStream.Read(Count);
  for I := 0 to Count - 1 do
  begin
    aLoadStream.Read(callerId);
    aLoadStream.ReadA(callerName);
    fCallers.Add(callerId, callerName);
  end;
  aLoadStream.CheckMarker('KaMRandom_calls');
  aLoadStream.Read(fSavedTicksCnt);
end;


procedure TKMRandomCheckLogger.LoadFromPath(const aPath: String);
var
  I: Integer;
  tickStreamSize: Cardinal;
  loadStream, tickStream: TKMemoryStream;
begin
  if Self = nil then Exit;

  if not FileExists(aPath) then
  begin
    gLog.AddTime('RandomsChecks file ''' + aPath + ''' was not found. Skip load rng');
    Exit;
  end;

  Clear;
  loadStream := TKMemoryStreamBinary.Create;
  try
    loadStream.LoadFromFileCompressed(aPath, 'RNGCompressed');

    LoadHeader(loadStream);

    for I := 0 to fSavedTicksCnt - 1 do
    begin
      tickStream := TKMemoryStreamBinary.Create;

      loadStream.Read(tickStreamSize);
      tickStream.CopyFrom(loadStream, tickStreamSize);

      fTickStreamQueue.Enqueue(tickStream);
    end;

//    fSaveStream.CopyFrom(LoadStream, LoadStream.Size - LoadStream.Position);
  finally
    loadStream.Free;
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
  loadStream: TKMemoryStream;
begin
  if Self = nil then Exit;

  if not FileExists(aPath) then
  begin
    gLog.AddTime('RandomsChecks file ''' + aPath + ''' was not found. Skip load rng');
    Exit;
  end;

  loadStream := TKMemoryStreamBinary.Create;
  try
    loadStream.LoadFromFileCompressed(aPath, 'RNGCompressed');
    LoadFromStreamAndParseToDict(loadStream);
  finally
    loadStream.Free;
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
  logRec: TKMRngLogRecord;

  procedure ClearLogRec;
  begin
    //@Rey: Consider using LogRec := default(TKMRngLogRecord);
    logRec.ValueI := 0;
    logRec.ValueS := 0;
    logRec.ValueE := 0;
    logRec.CallerId := 0;
    logRec.ValueType := lrtNone;
  end;

var
  I, K, countInTick: Integer;
  tick, tickStreamSize: Cardinal;
begin
  for I := 0 to fSavedTicksCnt - 1 do
  begin
    aLoadStream.Read(tickStreamSize); // load tick stream size and omit it, we don't use it here

    aLoadStream.Read(tick);
    aLoadStream.Read(countInTick);

    for K := 0 to countInTick - 1 do
    begin
      ClearLogRec;
      aLoadStream.Read(logRec.Seed);
      aLoadStream.Read(logRec.ValueType, SizeOf(logRec.ValueType));
      aLoadStream.Read(logRec.CallerId);

      case logRec.ValueType of
        lrtInt:     aLoadStream.Read(logRec.ValueI);
        lrtSingle:  aLoadStream.Read(logRec.ValueS);
        lrtExt:     aLoadStream.Read(logRec.ValueE);
      end;
      AddRecordToDict(tick, logRec);
    end;
  end;
end;


//procedure TKMRandomCheckLogger.ParseSaveStreamAndSaveAsText(aPath: String);
//begin
//  ParseSaveStream;
//  SaveAsText(aPath);
//end;


{$IFDEF WDC OR FPC_FULLVERSION >= 30200}
procedure TKMRandomCheckLogger.SaveToPathAsync(const aPath: String; aWorkerThread: TKMWorkerThread);
var
  saveStream, tickStream: TKMemoryStream;
//  CompressionStream: TCompressionStream;
  callerPair: TPair<Byte, AnsiString>;
  enumerator: TEnumerator<TKMemoryStream>;
begin
  if (Self = nil) then Exit;

  saveStream := TKMemoryStreamBinary.Create;

  // Allocate memory for save stream, could save up to 25% of save time
  saveStream.SetSize(fTickStreamQueue.Count * 2 * 1024); // on 1 hour game *1024 is usually enough

  saveStream.PlaceMarker('CallersTable');
  saveStream.Write(Integer(fCallers.Count));

  for callerPair in fCallers do
  begin
    saveStream.Write(callerPair.Key);
    saveStream.WriteA(callerPair.Value);
  end;

  saveStream.PlaceMarker('KaMRandom_calls');

  saveStream.Write(Integer(fSavedTicksCnt));

  enumerator := fTickStreamQueue.GetEnumerator;

  while enumerator.MoveNext do
  begin
    tickStream := enumerator.Current;
    saveStream.Write(Cardinal(tickStream.Size));
    saveStream.CopyFrom(tickStream, 0);
  end;

  enumerator.Free;

  saveStream.TrimToPosition;

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

  TKMemoryStream.AsyncSaveToFileCompressedAndFree(saveStream, aPath, 'RNGCompressed', aWorkerThread);
end;
{$ENDIF}


procedure TKMRandomCheckLogger.SaveAsText(const aPath: String);
const
  MAX_SL_COUNT = 1024*1024; // Avoid huge files and OOM errors
var
  I, cnt, K: Integer;
  keyTick: Cardinal;
  SL: TStringList;
  S, valS: String;
  callersIdList: TList<Byte>;
  callerId: Byte;
  logTicksList: TList<Cardinal>;
  logRecList: TList<TKMRngLogRecord>;
begin
  if Self = nil then Exit;
  
  cnt := 0;
  K := 0;
  SL := TStringList.Create;
  try
    callersIdList := TList<Byte>.Create(fCallers.Keys);
    try
      SL.Add('Callers: ' + IntToStr(callersIdList.Count));
      callersIdList.Sort;
      for callerId in callersIdList do
        SL.Add(Format('%d - %s', [callerId, fCallers[callerId]]));
    finally
      callersIdList.Free;
    end;

    logTicksList := TList<Cardinal>.Create(fRngLog.Keys);
    try
      SL.Add('LogRngRecords: ' + IntToStr(logTicksList.Count) + ' ticks');
      logTicksList.Sort;
      for keyTick in logTicksList do
      begin
        logRecList := fRngLog[keyTick];
        SL.Add(Format('Tick: %d, Tick Rng Count: %d', [keyTick, logRecList.Count]));
        Inc(cnt, logRecList.Count);
        for I := 0 to logRecList.Count - 1 do
        begin
          valS := 'NaN';
          case logRecList[I].ValueType of
            lrtInt:     valS := 'I ' + IntToStr(logRecList[I].ValueI);
            lrtSingle:  valS := 'S ' + FormatFloat('0.##############################', logRecList[I].ValueS);
            lrtExt:     valS := 'E ' + FormatFloat('0.##############################', logRecList[I].ValueE);
          end;
          S := Format('%3d. %-50sSeed: %12d Val: %s', [I, fCallers[logRecList[I].CallerId], logRecList[I].Seed, valS]);
          SL.Add(S);
        end;
        if SL.Count > MAX_SL_COUNT then
        begin
          SL.SaveToFile(aPath + IntToStr(K));
          SL.Clear;
          Inc(K);
        end;

      end;
    finally
      logTicksList.Free;
    end;
    SL.Add('Total randomchecks count = ' + IntToStr(cnt));
    if K = 0 then
      SL.SaveToFile(aPath)
    else
      SL.SaveToFile(aPath + IntToStr(K));
  finally
    SL.Free;
  end;
end;


procedure TKMRandomCheckLogger.Clear;
var
  list: TList<TKMRngLogRecord>;
//  TickStream: TKMemoryStream;
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

//  fRngLog.Clear; // It seems no need to clear, FastMM says there is memory leak because of it
  fRngLog.TrimExcess;
  fEnabled := True;
end;


end.

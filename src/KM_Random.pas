unit KM_Random;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC}zstream, {$ENDIF}
  {$IFDEF WDC}ZLib, {$ENDIF}
  Generics.Collections,
  KM_CommonTypes, KM_CommonClasses;

type
  TKMLogRngType = (lrtNone, lrtInt, lrtSingle, lrtExt);

  TKMRngLogRecord = record
    ValueType: TKMLogRngType;
    ValueI: Integer;
    ValueS: Single;
    ValueE: Extended;
    CallerId: Byte;
//    Tick: Cardinal;
  end;

  TKMRLRecordList = TList<TKMRngLogRecord>;

  TKMRandomCheckLogger = class
  private
    fGameTick: Cardinal;
//    fRngLogStream: TKMemoryStream;
    fCallers: TDictionary<Byte, AnsiString>;
    fRngLog: TDictionary<Cardinal, TKMRLRecordList>;
    function GetCallerID(const aCaller: AnsiString; aValue: Extended; aValueType: TKMLogRngType): Byte;
    procedure AddRecordToList(aTick: Cardinal; const aRec: TKMRngLogRecord);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddToLog(const aCaller: AnsiString; aValue: Integer); overload;
    procedure AddToLog(const aCaller: AnsiString; aValue: Single); overload;
    procedure AddToLog(const aCaller: AnsiString; aValue: Extended); overload;

//    property RngLogStream: TKMemoryStream read fRngLogStream;

    procedure SaveToPath(aPath: String);
    procedure SaveAsText(aPath: String);
    procedure LoadFromPath(aPath: String);
    procedure Clear;

    procedure UpdateState(aGameTick: Cardinal);


  end;


var
  gRandomCheckLogger: TKMRandomCheckLogger;



implementation
uses
  Classes, SysUtils, KromUtils, KM_Defaults{, KM_Game};

//const
//  MAX_LOG_LENGTH = 200000;


{ TKMRandomLogger }
constructor TKMRandomCheckLogger.Create;
begin
//  fRngLogStream := TKMemoryStream.Create;
  fCallers := TDictionary<Byte, AnsiString>.Create;
  fRngLog := TDictionary<Cardinal, TKMRLRecordList>.Create;
end;


destructor TKMRandomCheckLogger.Destroy;
begin
  Clear;
  FreeAndNil(fRngLog);
  FreeAndNil(fCallers);
//  FreeAndNil(fRngLogStream);
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


procedure TKMRandomCheckLogger.AddToLog(const aCaller: AnsiString; aValue: Integer);
var
  rec: TKMRngLogRecord;
begin
  rec.ValueType := lrtInt;
  rec.ValueI := aValue;
  rec.CallerId := GetCallerID(aCaller, aValue, lrtInt);

  AddRecordToList(fGameTick, rec);
end;

procedure TKMRandomCheckLogger.AddToLog(const aCaller: AnsiString; aValue: Single);
var
  rec: TKMRngLogRecord;
begin
  rec.ValueType := lrtSingle;
  rec.ValueS := aValue;
  rec.CallerId := GetCallerID(aCaller, aValue, lrtInt);

  AddRecordToList(fGameTick, rec);
end;

procedure TKMRandomCheckLogger.AddToLog(const aCaller: AnsiString; aValue: Extended);
var
  rec: TKMRngLogRecord;
begin
  rec.ValueType := lrtExt;
  rec.ValueE := aValue;
  rec.CallerId := GetCallerID(aCaller, aValue, lrtInt);

  AddRecordToList(fGameTick, rec);
end;


procedure TKMRandomCheckLogger.AddRecordToList(aTick: Cardinal; const aRec: TKMRngLogRecord);
var
  list: TList<TKMRngLogRecord>;
begin
  if not fRngLog.TryGetValue(aTick, list) then
  begin
    list := TList<TKMRngLogRecord>.Create;
    fRngLog.Add(aTick, list);
  end;

  list.Add(aRec);
end;


procedure TKMRandomCheckLogger.UpdateState(aGameTick: Cardinal);
begin
  fGameTick := aGameTick;
//  if fRngLog.Count > MAX_LOG_LENGTH then
//    fRngLog.DeleteRange(0, fRngLog.Count - MAX_LOG_LENGTH);
end;


procedure TKMRandomCheckLogger.LoadFromPath(aPath: String);
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
  LoadStream: TKMemoryStreamBinary;
  I, K, Count, CountInTick: Integer;
  CallerId: Byte;
  CallerName: AnsiString;
  Tick: Cardinal;
begin
  Clear;
  LoadStream := TKMemoryStreamBinary.Create;
  try
    LoadStream.LoadFromFile(aPath);
    LoadStream.CheckMarker('CallersTable');
    LoadStream.Read(Count);
    for I := 0 to Count - 1 do
    begin
      LoadStream.Read(CallerId);
      LoadStream.ReadA(CallerName);
      fCallers.Add(CallerId, CallerName);
    end;

    LoadStream.CheckMarker('KaMRandom_calls');
    LoadStream.Read(Count);
    for I := 0 to Count - 1 do
    begin
      LoadStream.Read(Tick);
      LoadStream.Read(CountInTick);

      for K := 0 to CountInTick - 1 do
      begin
        ClearLogRec;
        LoadStream.Read(LogRec.ValueType, SizeOf(LogRec.ValueType));
        LoadStream.Read(LogRec.CallerId);

        case LogRec.ValueType of
          lrtInt:     LoadStream.Read(LogRec.ValueI);
          lrtSingle:  LoadStream.Read(LogRec.ValueS);
          lrtExt:     LoadStream.Read(LogRec.ValueE);
        end;
        AddRecordToList(Tick, LogRec);
      end;
    end;
  finally
    LoadStream.Free;
  end;
end;


procedure TKMRandomCheckLogger.SaveToPath(aPath: String);
var
  SaveStream: TKMemoryStreamBinary;
//  CompressionStream: TCompressionStream;
  CallerPair: TPair<Byte, AnsiString>;
  LogPair: TPair<Cardinal, TKMRLRecordList>;
  I, Cnt: Integer;
  RngValueType: TKMLogRngType;
begin
  if not SAVE_RANDOM_CHECKS then
    Exit;

  SaveStream := TKMemoryStreamBinary.Create;

  SaveStream.PlaceMarker('CallersTable');
  SaveStream.Write(Integer(fCallers.Count));

  for CallerPair in fCallers do
  begin
    SaveStream.Write(CallerPair.Key);
    SaveStream.WriteA(CallerPair.Value);
  end;

  SaveStream.PlaceMarker('KaMRandom_calls');
  Cnt := 0;
  SaveStream.Write(Integer(fRngLog.Count));
  for LogPair in fRngLog do
  begin
    SaveStream.Write(LogPair.Key); //Tick
    SaveStream.Write(Integer(LogPair.Value.Count)); //Number of log records in tick
    Inc(Cnt, LogPair.Value.Count);
    for I := 0 to LogPair.Value.Count - 1 do
    begin
      RngValueType := LogPair.Value[I].ValueType;
      SaveStream.Write(RngValueType, SizeOf(RngValueType));
      SaveStream.Write(LogPair.Value[I].CallerId);
      case RngValueType of
        lrtInt:     SaveStream.Write(LogPair.Value[I].ValueI);
        lrtSingle:  SaveStream.Write(LogPair.Value[I].ValueS);
        lrtExt:     SaveStream.Write(LogPair.Value[I].ValueE);
      end;
    end;
  end;
  SaveStream.WriteA('Total COUNT = ');
  SaveStream.WriteA(AnsiString(IntToStr(Cnt)));

//  CompressionStream := TCompressionStream.Create(clNone, SaveStream);
//  CompressionStream.CopyFrom(fRngLogStream, 0);
  //SaveStream now contains the compressed data from SourceStream
//  CompressionStream.Free;

  SaveStream.SaveToFile(aPath);
  SaveStream.Free;
end;


procedure TKMRandomCheckLogger.SaveAsText(aPath: String);
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
          S := Format('%d. %s: %s', [I, fCallers[LogRecList[I].CallerId], ValS]);
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
begin
  fCallers.Clear;

  for list in fRngLog.Values do
    list.Free;

  fRngLog.Clear;
end;


end.

unit KM_GameSavePoints;
{$I KaM_Remake.inc}
interface
uses
  SyncObjs, Generics.Collections,
  KM_CommonClasses, KM_WorkerThread;

type
  TKMSavePoint = class
  private
    fStream: TKMemoryStream;
    fTick: Cardinal;
    // Opened spectator menu, viewports position etc...
  public
    constructor Create(aStream: TKMemoryStream; aTick: Cardinal);
    destructor Destroy; override;

    property Stream: TKMemoryStream read fStream;
    property Tick: Cardinal read fTick;
  end;

  TKMSavePointCollection = class
  private
    fAsyncSaveThreadsCnt: Byte; //Number of threads doing save atm. Usually should be not more than 1
    fWaitCS: TCriticalSection;
    fSaveCS: TCriticalSection;
    fSavePoints: TDictionary<Cardinal, TKMSavePoint>;
    //Properties to restore after load saved replay
    fLastTick: Cardinal;

    function GetCount: Integer;
    function GetSavePoint(aTick: Cardinal): TKMSavePoint;
    function GetStream(aTick: Cardinal): TKMemoryStream;
    function GetLastTick: Cardinal;
    procedure SetLastTick(const aLastTick: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;

    property LastTick: Cardinal read GetLastTick write SetLastTick;
    procedure Clear;

    procedure Lock;
    procedure Unlock;

    property Count: Integer read GetCount;
    property SavePoint[aTick: Cardinal]: TKMSavePoint read GetSavePoint;
    property Stream[aTick: Cardinal]: TKMemoryStream read GetStream; default;
    function Contains(aTick: Cardinal): Boolean;
    procedure FillTicks(aTicksList: TList<Cardinal>);

    procedure NewSavePoint(aStream: TKMemoryStream; aTick: Cardinal);

    function LatestPointTickBefore(aTick: Cardinal): Cardinal;

    procedure Save(aSaveStream: TKMemoryStream);
    procedure Load(aLoadStream: TKMemoryStream);

    procedure SaveToFileAsync(const aFileName: UnicodeString; aWorkerThread: TKMWorkerThread);
    procedure LoadFromFile(const aFileName: UnicodeString);
  end;


implementation
uses
  SysUtils, Classes;


{ TKMSavePoint }
constructor TKMSavePoint.Create(aStream: TKMemoryStream; aTick: Cardinal);
begin
  inherited Create;

  fStream := aStream;
  fTick := aTick;
end;


destructor TKMSavePoint.Destroy;
begin
  fStream.Free;

  inherited;
end;


{ TKMSavePointCollection }
constructor TKMSavePointCollection.Create;
begin
  inherited;

  fSaveCS := TCriticalSection.Create;
  fWaitCS := TCriticalSection.Create;
  fSavePoints := TDictionary<Cardinal, TKMSavePoint>.Create;
  fLastTick := 0;
end;


destructor TKMSavePointCollection.Destroy;
begin
  {$IFDEF WDC}
  // Wait till all threads release waitLock
  while True do
  begin
    fWaitCS.Enter;
    try
      if fAsyncSaveThreadsCnt = 0 then
        Break;
    finally
      fWaitCS.Leave;
    end;
    Sleep(100);
  end;
  {$ENDIF}

  Lock; // Lock even in destructor
  try
    Clear;
    fSavePoints.Free; // TKMList will free all objects of the list
  finally
    Unlock;
  end;
  fSaveCS.Free;
  fWaitCS.Free;

  inherited;
end;


function TKMSavePointCollection.GetCount: Integer;
begin
  if Self = nil then Exit(0);

  Lock;
  try
    Result := fSavePoints.Count;
  finally
    Unlock;
  end;
end;


function TKMSavePointCollection.GetLastTick: Cardinal;
begin
  if Self = nil then Exit(0);

  Result := fLastTick;
end;


procedure TKMSavePointCollection.SetLastTick(const aLastTick: Cardinal);
begin
  if Self = nil then Exit;

  fLastTick := aLastTick;
end;


procedure TKMSavePointCollection.Clear;
var
  savePoint: TKMSavePoint;
begin
  if Self = nil then Exit;

  Lock;
  try
    for savePoint in fSavePoints.Values do
      savePoint.Free;

    fSavePoints.Clear;
  finally
    Unlock;
  end;
end;


function TKMSavePointCollection.Contains(aTick: Cardinal): Boolean;
begin
  if Self = nil then Exit(False);

  Lock;
  try
    Result := fSavePoints.ContainsKey(aTick);
  finally
    Unlock;
  end;
end;


procedure TKMSavePointCollection.FillTicks(aTicksList: TList<Cardinal>);
var
  Tick: Cardinal;
begin
  if Self = nil then Exit;

  Lock;
  try
    for Tick in fSavePoints.Keys do
      aTicksList.Add(Tick);
  finally
    Unlock;
  end;
end;


function TKMSavePointCollection.GetSavePoint(aTick: Cardinal): TKMSavePoint;
begin
  Result := nil;
  if Self = nil then Exit;

  Lock;
  try
    if fSavePoints.ContainsKey(aTick) then
      Result := fSavePoints[aTick];
  finally
    Unlock;
  end;
end;


function TKMSavePointCollection.GetStream(aTick: Cardinal): TKMemoryStream;
var
  savePoint: TKMSavePoint;
begin
  Result := nil;
  if Self = nil then Exit;

  Lock;
  try
    if fSavePoints.TryGetValue(aTick, savePoint) then
      Result := savePoint.Stream;
  finally
    Unlock;
  end;
end;


procedure TKMSavePointCollection.NewSavePoint(aStream: TKMemoryStream; aTick: Cardinal);
begin
  if Self = nil then Exit;

  Lock;
  try
    if not fSavePoints.ContainsKey(aTick) then // Check if we don't have same tick save here too, since we work in multithread environment
      fSavePoints.Add(aTick, TKMSavePoint.Create(aStream, aTick));
  finally
    Unlock;
  end;
end;


procedure TKMSavePointCollection.Save(aSaveStream: TKMemoryStream);
var
  keyArray : TArray<Cardinal>;
  key: Cardinal;
  savePoint: TKMSavePoint;
begin
  if Self = nil then Exit;

  Lock;
  try
    aSaveStream.PlaceMarker('SavePoints');
    aSaveStream.Write(fLastTick);
    aSaveStream.Write(fSavePoints.Count);

    keyArray := fSavePoints.Keys.ToArray;
    TArray.Sort<Cardinal>(keyArray);

    // todo: potential OutOfMemory error in this cycle
    for key in keyArray do
    begin
      aSaveStream.PlaceMarker('SavePoint');
      aSaveStream.Write(key);
      savePoint := fSavePoints.Items[key];
      aSaveStream.Write(Cardinal(savePoint.fStream.Size));
      aSaveStream.CopyFrom(savePoint.fStream, 0);
    end;
  finally
    Unlock;
  end;
end;


procedure TKMSavePointCollection.SaveToFileAsync(const aFileName: UnicodeString; aWorkerThread: TKMWorkerThread);
{$IFNDEF WDC}
var
  localStream: TKMemoryStream;
{$ENDIF}
begin
  if Self = nil then Exit;

  {$IFDEF WDC}
    fWaitCS.Enter;
    try
      Inc(fAsyncSaveThreadsCnt); // Increase save threads counter in main thread
    finally
      fWaitCS.Leave;
    end;

    aWorkerThread.QueueWork(
      procedure
      var
        localStream: TKMemoryStream;
      begin
        localStream := TKMemoryStreamBinary.Create;
        try
          Save(localStream); // Save has Lock / Unlock inside already
          fWaitCS.Enter;
          try
            Dec(fAsyncSaveThreadsCnt); // Decrease thread counter since we saved all data into thread local stream
          finally
            fWaitCS.Leave;
          end;
          localStream.SaveToFileCompressed(aFileName, 'SavePointsCompressed');
        finally
          localStream.Free;
        end;
      end, 'Save SavePoints');
  {$ELSE}
    localStream := TKMemoryStreamBinary.Create;
    try
      Save(localStream);
      localStream.SaveToFileCompressed(aFileName, 'SavePointsCompressed');
    finally
      localStream.Free;
    end;
  {$ENDIF}
end;


procedure TKMSavePointCollection.Lock;
begin
  if Self = nil then Exit;

  fSaveCS.Enter;
end;


procedure TKMSavePointCollection.Unlock;
begin
  if Self = nil then Exit;

  fSaveCS.Leave;
end;


procedure TKMSavePointCollection.LoadFromFile(const aFileName: UnicodeString);
var
  S: TKMemoryStream;
begin
  if Self = nil then Exit;
  if not FileExists(aFileName) then Exit;

  S := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFileCompressed(aFileName, 'SavePointsCompressed');
    Load(S);
  finally
    S.Free;
  end;
end;


// Get latest savepoint tick, before aTick
// 0 - if not found
function TKMSavePointCollection.LatestPointTickBefore(aTick: Cardinal): Cardinal;
var
  key: Cardinal;
begin
  Result := 0;
  if Self = nil then Exit;

  Lock;
  try
    for key in fSavePoints.Keys do
      if (key <= aTick) and (key > Result) then
        Result := key;
  finally
    Unlock;
  end;
end;

procedure TKMSavePointCollection.Load(aLoadStream: TKMemoryStream);
var
  I, cnt: Integer;
  tick, size: Cardinal;
  savePoint: TKMSavePoint;
  stream: TKMemoryStream;
begin
  if Self = nil then Exit;

  Lock;
  try
    fSavePoints.Clear;

    aLoadStream.CheckMarker('SavePoints');
    aLoadStream.Read(fLastTick);
    aLoadStream.Read(cnt);

    for I := 0 to cnt - 1 do
    begin
      aLoadStream.CheckMarker('SavePoint');
      aLoadStream.Read(tick);
      aLoadStream.Read(size);

      stream := TKMemoryStreamBinary.Create;
      stream.CopyFrom(aLoadStream, size);

      savePoint := TKMSavePoint.Create(stream, tick);

      fSavePoints.Add(tick, savePoint);
    end;
  finally
    Unlock;
  end;
end;


end.

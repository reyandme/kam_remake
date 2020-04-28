unit KM_GameSavedReplays;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_CommonClasses, KM_WorkerThread;

type
  TKMSavedReplay = class
  private
    fStream: TKMemoryStream;
    fTick: Cardinal;
    // Opened spectator menu, viewports position etc...
  public
    constructor Create(aStream: TKMemoryStream; aTick: Cardinal);
    destructor Destroy(); override;

    property Stream: TKMemoryStream read fStream;
    property Tick: Cardinal read fTick;
  end;

  TKMSavedReplays = class
  private
    fReplaySaves: TDictionary<Cardinal, TKMSavedReplay>;
    //Properties to restore after load saved replay
    fLastTick: Cardinal;

    function GetCount(): Integer;
    function GetSave(aTick: Cardinal): TKMSavedReplay;
    function GetStream(aTick: Cardinal): TKMemoryStream;
  public
    constructor Create();
    destructor Destroy; override;

    property LastTick: Cardinal read fLastTick write fLastTick;
    procedure Clear;

    property Count: Integer read GetCount;
    property Replay[aTick: Cardinal]: TKMSavedReplay read GetSave;
    property Stream[aTick: Cardinal]: TKMemoryStream read GetStream; default;
    function Contains(aTick: Cardinal): Boolean;
    procedure FillTicks(aTicksList: TList<Cardinal>);

    procedure NewSave(aStream: TKMemoryStream; aTick: Cardinal);

    procedure Save(aSaveStream: TKMemoryStream);
    procedure Load(aLoadStream: TKMemoryStream);

    procedure SaveToFileAsync(const aFileName: UnicodeString; aWorkerThread: TKMWorkerThread);
    procedure LoadFromFile(const aFileName: UnicodeString);
  end;

implementation
uses
  SysUtils, Classes;

{ TKMSavedReplays }
constructor TKMSavedReplays.Create();
begin
  fReplaySaves := TDictionary<Cardinal, TKMSavedReplay>.Create();
  fLastTick := 0;
end;


destructor TKMSavedReplays.Destroy();
begin
  Clear;

  fReplaySaves.Free; // TKMList will free all objects of the list
  inherited;
end;


function TKMSavedReplays.GetCount(): Integer;
begin
  Result := fReplaySaves.Count;
end;


procedure TKMSavedReplays.Clear;
var
  Replay: TKMSavedReplay;
begin
  for Replay in fReplaySaves.Values do
    Replay.Free;

  fReplaySaves.Clear;
end;


function TKMSavedReplays.Contains(aTick: Cardinal): Boolean;
begin
  Result := fReplaySaves.ContainsKey(aTick);
end;


procedure TKMSavedReplays.FillTicks(aTicksList: TList<Cardinal>);
var
  Tick: Cardinal;
begin
  for Tick in fReplaySaves.Keys do
    aTicksList.Add(Tick);
end;


function TKMSavedReplays.GetSave(aTick: Cardinal): TKMSavedReplay;
begin
  Result := nil;
  if fReplaySaves.ContainsKey(aTick) then
    Result := fReplaySaves[aTick];
end;


function TKMSavedReplays.GetStream(aTick: Cardinal): TKMemoryStream;
var
  Rpl: TKMSavedReplay;
begin
  Result := nil;
  if fReplaySaves.TryGetValue(aTick, Rpl) then
    Result := Rpl.Stream;
end;


procedure TKMSavedReplays.NewSave(aStream: TKMemoryStream; aTick: Cardinal);
begin
  fReplaySaves.Add(aTick, TKMSavedReplay.Create(aStream, aTick) );
end;


procedure TKMSavedReplays.Save(aSaveStream: TKMemoryStream);
var
  keyArray : TArray<Cardinal>;
  key: Cardinal;
  rpl: TKMSavedReplay;
begin
  aSaveStream.PlaceMarker('SavedReplays');
  aSaveStream.Write(fLastTick);
  aSaveStream.Write(fReplaySaves.Count);

  keyArray := fReplaySaves.Keys.ToArray;
  TArray.Sort<Cardinal>(keyArray);

  for key in keyArray do
  begin
    aSaveStream.PlaceMarker('SavePoint');
    aSaveStream.Write(key);
    rpl := fReplaySaves.Items[key];
    aSaveStream.Write(Cardinal(rpl.fStream.Size));
    aSaveStream.CopyFrom(rpl.fStream, 0);
  end;
end;


procedure TKMSavedReplays.SaveToFileAsync(const aFileName: UnicodeString; aWorkerThread: TKMWorkerThread);
var
  S: TKMemoryStreamBinary;
begin
  S := TKMemoryStreamBinary.Create;
  Save(S);
  TKMemoryStream.AsyncSaveToFileCompressedAndFree(S, aFileName, 'SavedReplaysCompressed', aWorkerThread);
end;


procedure TKMSavedReplays.LoadFromFile(const aFileName: UnicodeString);
var
  S: TKMemoryStreamBinary;
begin
  if not FileExists(aFileName) then Exit;

  S := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFileCompressed(aFileName, 'SavedReplaysCompressed');
    Load(S);
  finally
    S.Free;
  end;
end;


procedure TKMSavedReplays.Load(aLoadStream: TKMemoryStream);
var
  I, cnt: Integer;
  tick, size: Cardinal;
  rpl: TKMSavedReplay;
  stream: TKMemoryStream;
begin
  fReplaySaves.Clear;

  aLoadStream.CheckMarker('SavedReplays');
  aLoadStream.Read(fLastTick);
  aLoadStream.Read(cnt);

  for I := 0 to cnt - 1 do
  begin
    aLoadStream.CheckMarker('SavePoint');
    aLoadStream.Read(tick);
    aLoadStream.Read(size);

    stream := TKMemoryStreamBinary.Create;
    stream.CopyFrom(aLoadStream, size);

    rpl := TKMSavedReplay.Create(stream, tick);

    fReplaySaves.Add(tick, rpl);
  end;
end;


{ TKMSavedReplay }
constructor TKMSavedReplay.Create(aStream: TKMemoryStream; aTick: Cardinal);
begin
  inherited Create;

  fStream := aStream;
  fTick := aTick;
end;


destructor TKMSavedReplay.Destroy();
begin
  fStream.Free;

  inherited;
end;


end.

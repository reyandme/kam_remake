unit KM_GameSavedReplays;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KM_CommonClasses;

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

    procedure SaveToFile(const aFileName: UnicodeString);
    procedure LoadFromFile(const aFileName: UnicodeString);
  end;

implementation
uses
  SysUtils, Classes,
  KM_Game
  {$IFDEF FPC}, zstream {$ENDIF}
  {$IFDEF WDC}, ZLib {$ENDIF}
  {$IFDEF WDC}, System.Threading {$ENDIF};


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


procedure DoCompressedSaveAndFree(const aFileName: UnicodeString; S: TKMemoryStreamBinary);
var
  S2: TKMemoryStreamBinary;
  CS: TCompressionStream;
begin
  S2 := TKMemoryStreamBinary.Create;
  try
    S2.PlaceMarker('SavedReplaysCompressed');

    CS := TCompressionStream.Create(cldefault, S2);
    CS.CopyFrom(S, 0);
    CS.Free;

    S2.SaveToFile(aFileName);
  finally
    S.Free;
    S2.Free;
  end;
end;


procedure TKMSavedReplays.SaveToFile(const aFileName: UnicodeString);
var
  S: TKMemoryStreamBinary;
begin
  S := TKMemoryStreamBinary.Create;
  Save(S);

  {$IFDEF WDC}
    //Can't run this async currently because of AutoSaveRename
    TTask.Run(procedure
    begin
      {$IFDEF DEBUG}
      TThread.NameThreadForDebugging('TKMSavedReplays.SaveToFile');
      {$ENDIF}
      DoCompressedSaveAndFree(aFileName, S);
    end, gGame.fSaveWorkerPool);
  {$ELSE}
    DoCompressedSaveAndFree(aFileName, S);
  {$ENDIF}

  //S is freed in DoCompressedSaveAndFree
end;


procedure TKMSavedReplays.LoadFromFile(const aFileName: UnicodeString);
var
  S, S2: TKMemoryStreamBinary;
  DS: TDecompressionStream;
begin
  if not FileExists(aFileName) then Exit;

  S := TKMemoryStreamBinary.Create;
  S2 := TKMemoryStreamBinary.Create;
  try
    S.LoadFromFile(aFileName);
    S.CheckMarker('SavedReplaysCompressed');
    DS := TDecompressionStream.Create(S);
    S2.CopyFromDecompression(DS);
    S2.Position := 0;
    DS.Free;

    Load(S2);
  finally
    S.Free;
    S2.Free;
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

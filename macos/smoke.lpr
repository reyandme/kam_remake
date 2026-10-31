program KaMMacSmoke;
{$I ../KaM_Remake.inc}
uses
  cthreads, Interfaces, SysUtils, Classes, Math,
  uPSCompiler, uPSRuntime, uPSUtils,
  KM_IoXML, KM_IoPNG, KM_FileIO, KM_CommonTypes, KM_CommonClasses,
  KM_CommonClassesExt, KM_WorkerThread, KM_Points;


type
  TKMProbe = packed record
    A: Byte;
    B: Integer;
    C: Word;
  end;

  TKMNativeHost = class
    function Text(const aText: UnicodeString): UnicodeString;
  end;

var
  gChecks: Integer;


procedure Check(aCondition: Boolean);
begin
  if not aCondition then
    raise Exception.CreateFmt('Smoke check %d failed', [gChecks + 1]);
  Inc(gChecks);
end;


function NativeAdd(aLeft, aRight: Integer): Integer;
begin
  Result := aLeft + aRight;
end;


function NativeScale(aValue: Single): Single;
begin
  Result := aValue * 2;
end;


function NativeText(const aText: UnicodeString): UnicodeString;
begin
  Result := aText + '!';
end;


procedure ScriptCheck(aCondition: Boolean);
begin
  Check(aCondition);
end;


function NativePoint(aX, aY: Integer): TKMPoint;
begin
  Result.X := aX;
  Result.Y := aY;
end;


function NativeProbe(aValue: Integer): TKMProbe;
begin
  Result.A := 7;
  Result.B := aValue;
  Result.C := 321;
end;


function NativeArray(aCount: Integer): TIntegerArray;
var
  I: Integer;
begin
  SetLength(Result, aCount);
  for I := 0 to aCount - 1 do
    Result[I] := I * 3;
end;


function NativeSum(const aValues: array of Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(aValues) do
    Inc(Result, aValues[I]);
end;


procedure NativeBump(var aValue: Integer);
begin
  Inc(aValue, 9);
end;


function TKMNativeHost.Text(const aText: UnicodeString): UnicodeString;
begin
  Result := aText + '!';
end;


function RegisterNative(aCompiler: TPSPascalCompiler; const aName: tbtString): Boolean;
begin
  aCompiler.AddDelphiFunction('function NativeAdd(A, B: Integer): Integer;');
  aCompiler.AddDelphiFunction('function NativeScale(A: Single): Single;');
  aCompiler.AddDelphiFunction('function NativeText(const S: UnicodeString): UnicodeString;');
  aCompiler.AddDelphiFunction('procedure ScriptCheck(B: Boolean);');
  aCompiler.AddTypeS('TKMPoint', 'record X, Y: Integer; end;');
  aCompiler.AddTypeS('TProbe', 'record A: Byte; B: Integer; C: Word; end;');
  aCompiler.AddTypeS('TIntegerArray', 'array of Integer');
  aCompiler.AddDelphiFunction('function NativePoint(X, Y: Integer): TKMPoint;');
  aCompiler.AddDelphiFunction('function NativeProbe(B: Integer): TProbe;');
  aCompiler.AddDelphiFunction('function NativeArray(N: Integer): TIntegerArray;');
  aCompiler.AddDelphiFunction('function NativeSum(const A: array of Integer): Integer;');
  aCompiler.AddDelphiFunction('procedure NativeBump(var X: Integer);');
  aCompiler.AddDelphiFunction('function NativeMethod(const S: UnicodeString): UnicodeString;');
  Result := True;
end;


procedure TestCollectionStream;
var
  values: TKMVarValueList;
  stream: TKMemoryStreamBinary;
begin
  values := TKMVarValueList.Create;
  stream := TKMemoryStreamBinary.Create;
  try
    values.Save(stream);
    stream.PlaceMarker('AfterList');
    stream.Position := 0;
    values.Load(stream);
    stream.CheckMarker('AfterList');
    Check(values.Count = 0);
  finally
    FreeAndNil(stream);
    FreeAndNil(values);
  end;
end;


procedure TestWorker;
var
  worker: TKMWorkerThread;
  workCount: Integer;
begin
  workCount := 0;
  worker := TKMWorkerThread.Create('SmokeWorker');
  try
    worker.QueueWork(procedure
      begin
        Inc(workCount);
      end);
    worker.WaitForAllWorkToComplete;
    Check(workCount = 1);
  finally
    FreeAndNil(worker);
  end;
end;


procedure TestXMLAndFiles;
var
  document: TKMXmlDocument;
  worker: TKMWorkerThread;
  xmlText: string;
begin
  document := TKMXmlDocument.Create;
  try
    document.Root.AddOrFindChild('Main').Attributes['Number'] := 42;
    document.Root.FindNode('Main').Attributes['Enabled'] := True;
    document.SaveToFile('out/smoke.xml');
  finally
    FreeAndNil(document);
  end;

  KMCopyFile('out/smoke.xml', 'out/smoke-copy.xml', True);
  Check(FileExists('out/smoke-copy.xml'));
  worker := TKMWorkerThread.Create('SmokeCopyWorker');
  try
    KMCopyFileAsync('out/smoke.xml', 'out/smoke-copy-async.xml', True, worker);
    worker.WaitForAllWorkToComplete;
    Check(FileExists('out/smoke-copy-async.xml'));
  finally
    FreeAndNil(worker);
  end;

  document := TKMXmlDocument.Create;
  try
    document.LoadFromFile('out/smoke.xml');
    Check(document.Root.FindNode('Main').Attributes['Number'].AsInteger = 42);
    Check(document.Root.FindNode('Main').Attributes['Enabled'].AsBoolean);
    Check(document.Root.ChildsCount = 1);
    xmlText := document.Text;
    document.Text := xmlText;
    Check(document.Root.FindNode('Main').Attributes['Number'].AsInteger = 42);
    document.Root.FindNode('Main').Clear;
    Check(not document.Root.FindNode('Main').HasAttribute('Number'));
  finally
    FreeAndNil(document);
  end;
end;


procedure TestPNG;
var
  pixels, loaded: TKMCardinalArray;
  width, height: Word;
  I: Integer;
begin
  SetLength(pixels, 4);
  pixels[0] := $00112233;
  pixels[1] := $80123456;
  pixels[2] := $FFABCDEF;
  pixels[3] := $FFFFFFFF;
  SaveToPng(2, 2, pixels, 'out/smoke.png');
  LoadFromPng('out/smoke.png', width, height, loaded);
  Check((width = 2) and (height = 2));
  for I := 0 to High(pixels) do
    Check(loaded[I] = pixels[I]);
end;


procedure TestScriptCalls;
const
  SCRIPT_SOURCE =
    'var P: TKMPoint; R: TProbe; A: TIntegerArray; X: Integer; begin ' +
    'P:=NativePoint(31,-9); ScriptCheck((P.X=31) and (P.Y=-9)); ' +
    'R:=NativeProbe(-1234); ScriptCheck((R.A=7) and (R.B=-1234) and (R.C=321)); ' +
    'A:=NativeArray(4); ScriptCheck((Length(A)=4) and (A[3]=9)); ScriptCheck(NativeSum(A)=18); ' +
    'X:=2; NativeBump(X); ScriptCheck(X=11); ScriptCheck(NativeMethod(''host'')=''host!''); ' +
    'ScriptCheck(NativeAdd(-7,3)=-4); ScriptCheck(NativeScale(1.25)=2.5); ' +
    'ScriptCheck(NativeText(''hello'')=''hello!''); end.';
var
  compiler: TPSPascalCompiler;
  executor: TPSExec;
  host: TKMNativeHost;
  byteCode: AnsiString;
  I: Integer;
begin
  compiler := TPSPascalCompiler.Create;
  executor := TPSExec.Create;
  host := TKMNativeHost.Create;
  try
    compiler.OnUses := @RegisterNative;
    if not compiler.Compile(SCRIPT_SOURCE) then
    begin
      for I := 0 to compiler.MsgCount - 1 do
        WriteLn(compiler.Msg[I].MessageToString);
      raise Exception.Create('Smoke script did not compile');
    end;
    Check(compiler.GetOutput(byteCode));
    executor.RegisterDelphiMethod(host, @TKMNativeHost.Text, 'NativeMethod', cdRegister);
    executor.RegisterDelphiFunction(@NativePoint, 'NativePoint', cdRegister);
    executor.RegisterDelphiFunction(@NativeProbe, 'NativeProbe', cdRegister);
    executor.RegisterDelphiFunction(@NativeArray, 'NativeArray', cdRegister);
    executor.RegisterDelphiFunction(@NativeSum, 'NativeSum', cdRegister);
    executor.RegisterDelphiFunction(@NativeBump, 'NativeBump', cdRegister);
    executor.RegisterDelphiFunction(@NativeAdd, 'NativeAdd', cdRegister);
    executor.RegisterDelphiFunction(@NativeScale, 'NativeScale', cdRegister);
    executor.RegisterDelphiFunction(@NativeText, 'NativeText', cdRegister);
    executor.RegisterDelphiFunction(@ScriptCheck, 'ScriptCheck', cdRegister);
    Check(executor.LoadData(byteCode));
    if not executor.RunScript then
      raise Exception.Create('Script error: ' + executor.ExceptionString);
  finally
    FreeAndNil(host);
    FreeAndNil(executor);
    FreeAndNil(compiler);
  end;
end;


begin
  gChecks := 0;
  TestCollectionStream;
  TestWorker;
  TestXMLAndFiles;
  TestPNG;
  TestScriptCalls;
  WriteLn('PASS: ', gChecks, ' checks (streams, workers, XML, files, PNG and ARM64 script calls)');
end.

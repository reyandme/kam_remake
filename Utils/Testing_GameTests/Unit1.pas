unit Unit1;
{$I KaM_Remake.inc}
interface
uses
  Forms, Controls, StdCtrls, Spin, ExtCtrls, Classes, SysUtils, Graphics, Types, Math, Windows,
  KM_Test, KM_Log, KM_RenderControl, KM_GameApp,
  TypInfo,
  {$IFDEF WDC} Vcl.ComCtrls, Vcl.CheckLst {$ELSE} ComCtrls, CheckLst {$ENDIF};


type
  TForm2 = class(TForm)
    btnRunOne: TButton;
    seCycles: TSpinEdit;
    lblDelay: TLabel;
    seDelay: TSpinEdit;
    Label1: TLabel;
    lbTests: TListBox;
    clbTags: TCheckListBox;
    Label2: TLabel;
    pcMain: TPageControl;
    tsLog: TTabSheet;
    meLog: TMemo;
    tsRender: TTabSheet;
    pnlRender: TPanel;
    chkRender: TCheckBox;
    chkThrottleRender: TCheckBox;
    seSeed: TSpinEdit;
    Label7: TLabel;
    btnRunAll: TButton;
    btnStop: TButton;
    Label3: TLabel;
    Label5: TLabel;
    procedure clbTagsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkRenderClick(Sender: TObject);
    procedure btnRunOneClick(Sender: TObject);
    procedure btnRunAllClick(Sender: TObject);
    procedure lbTestsClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    fRenderArea: TKMRenderControl;
    fResults: TKMRunResults;
    fStopped: Boolean;
    procedure RefreshTestList;
    function IsStopped: Boolean;
    procedure HandleProgress(const aValue: string);
    procedure EnsureResourcesLoaded(aBlind: Boolean = False);
    procedure RefreshTagList;
    procedure RunTest(aClass: TKMTestClass; aSeed: Integer);
  public
    function RunFromCmdLine: Boolean;
  end;


implementation
uses
  StrUtils,
  KM_GameTypes, KM_Defaults,
  KM_MainSettings, KM_GameSettings, KM_GameAppSettings;

{$R *.dfm}


procedure TForm2.clbTagsClick(Sender: TObject);
begin
  RefreshTestList;
end;


procedure TForm2.btnStopClick(Sender: TObject);
begin
  fStopped := True;
  btnStop.Enabled := False;
end;


procedure TForm2.FormCreate(Sender: TObject);
begin
  Caption := ExtractFileName(Application.ExeName);
  SKIP_SOUND := True;
  SKIP_LOADING_CURSOR := True;
  SKIP_SETTINGS_SAVE := True;
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  gLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'Testing_GameTests.log');

  // Init settings global variables
  gGameAppSettings := TKMGameAppSettings.Create(1024, 768);

  fRenderArea := TKMRenderControl.Create(pnlRender);
  fRenderArea.Parent := pnlRender;
  fRenderArea.Align := alClient;
  fRenderArea.Color := clMaroon;

  RefreshTagList;
  RefreshTestList;

  if Length(gTestList) > 0 then
  begin
    lbTests.ItemIndex := 0;
    btnRunOne.Enabled := True;
    btnRunAll.Enabled := True;
    btnStop.Enabled := False;
  end;
end;


procedure TForm2.RefreshTagList;
begin
  var tagSet: TKMTestTagSet := [];
  for var I := 0 to High(gTestList) do
    tagSet := tagSet + gTestList[I].TestTags;

  for var tag := Low(TKMTestTag) to High(TKMTestTag) do
  begin
    if tag in tagSet then
    begin
      var tagName := GetEnumName(TypeInfo(TKMTestTag), Integer(tag));
      if Copy(tagName, 1, 2) = 'tc' then
        Delete(tagName, 1, 2);
      clbTags.Items.AddObject(tagName, TObject(tag));
      clbTags.Checked[clbTags.Items.Count - 1] := True;
    end;
  end;
end;


procedure TForm2.RefreshTestList;
begin
  var allowedTags: TKMTestTagSet := [];
  for var I := 0 to clbTags.Items.Count - 1 do
    if clbTags.Checked[I] then
      allowedTags := allowedTags + [TKMTestTag(Integer(clbTags.Items.Objects[I]))];

  lbTests.Items.Clear;
  for var I := 0 to High(gTestList) do
  begin
    var allowedByTags := False;
    for var tag in gTestList[I].TestTags do
      if tag in allowedTags then
        allowedByTags := True;

    if allowedByTags then
    begin
      var testName := gTestList[I].ClassName;
      testName := StringReplace(testName, 'TKMTest_', '', [rfIgnoreCase]);
      lbTests.Items.AddObject(testName, TObject(I));
    end;
  end;

  if lbTests.Items.Count > 0 then
    lbTests.ItemIndex := 0
  else
    btnRunOne.Enabled := False;

  lbTestsClick(nil);
end;


procedure TForm2.chkRenderClick(Sender: TObject);
begin
  SKIP_RENDER := not chkRender.Checked;
end;


procedure TForm2.FormDestroy(Sender: TObject);
begin
  FreeAndNil(gLog);
end;


procedure TForm2.lbTestsClick(Sender: TObject);
var
  ID: Integer;
begin
  ID := lbTests.ItemIndex;
  if ID = -1 then Exit;
  btnRunOne.Enabled := True;
  btnRunAll.Enabled := True;
  btnStop.Enabled := False;
end;


function TForm2.IsStopped: Boolean;
begin
  Result := fStopped;
end;


procedure TForm2.RunTest(aClass: TKMTestClass; aSeed: Integer);
begin
  EnsureResourcesLoaded;

  fStopped := False;

  var T := GetTickCount;
  var thisTest := aClass.Create(IsStopped, HandleProgress);
  try
    thisTest.ThrottleRender := chkThrottleRender.Checked;
    thisTest.DelayValue := seDelay.Value;

    fResults := thisTest.Run(aSeed);

    var resStr := '';
    case fResults.TestResult of
      trSuccess:    resStr := 'SUCCESS';
      trFailed:     resStr := 'FAILED: ' + fResults.TestMessage;
      trException:  resStr := 'EXCEPTION: ' + fResults.TestMessage;
    end;

    meLog.Lines.Append(Format('%-32s: %s, seed %d, %d ms', [aClass.ClassName, resStr, aSeed, GetTickCount - T]));
  finally
    thisTest.Free;
  end;
end;


procedure TForm2.btnRunOneClick(Sender: TObject);
begin
  if lbTests.ItemIndex = -1 then Exit;
  var testIndex := Integer(lbTests.Items.Objects[lbTests.ItemIndex]);
  var thisTestClass := gTestList[testIndex];

  btnRunOne.Enabled := False;
  btnRunAll.Enabled := False;
  btnStop.Enabled := True;
  try
    for var I := 0 to seCycles.Value - 1 do
    begin
      if fStopped then Break;

      RunTest(thisTestClass, seSeed.Value + I);
    end;
  finally
    btnRunOne.Enabled := True;
    btnRunAll.Enabled := True;
    btnStop.Enabled := False;
  end;
end;


procedure TForm2.btnRunAllClick(Sender: TObject);
begin
  meLog.Clear;
  meLog.Lines.Append('Running All');
  pcMain.ActivePage := tsLog;

  var testsCompleted := 0;
  var TotalT := GetTickCount;

  btnRunOne.Enabled := False;
  btnRunAll.Enabled := False;
  btnStop.Enabled := True;
  try
    for var I := 0 to seCycles.Value - 1 do
    for var K := 0 to lbTests.Items.Count - 1 do
    begin
      if fStopped then Break;

      var testIndex := Integer(lbTests.Items.Objects[K]);
      var thisTestClass := gTestList[testIndex];

      RunTest(thisTestClass, seSeed.Value + I);

      Inc(testsCompleted);
    end;
  finally
    meLog.Lines.Append('=============================');
    meLog.Lines.Append(Format('Total Tests Run: %d', [testsCompleted]));
    meLog.Lines.Append(Format('Total Time Spent: %d ms', [GetTickCount - TotalT]));

    btnRunOne.Enabled := True;
    btnRunAll.Enabled := True;
    btnStop.Enabled := False;
  end;
end;


procedure TForm2.HandleProgress(const aValue: string);
begin
  Label2.Caption := aValue;
  Label2.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.EnsureResourcesLoaded(aBlind: Boolean = False);
var
  tgtWidth, tgtHeight: Word;
  renderArea: TKMRenderControl;
begin
  if gGameApp <> nil then Exit;

  // Blind mode needs no OpenGL context and no window, hence the app could be run from the command line.
  // SKIP_RENDER must be set before the resources are loaded, it also skips loading of the sprites
  if aBlind then
  begin
    SKIP_RENDER := True;
    renderArea := nil;
  end
  else
    renderArea := fRenderArea;

  if renderArea = nil then
  begin
    tgtWidth := 1024;
    tgtHeight := 768;
  end else
  begin
    tgtWidth := renderArea.Width;
    tgtHeight := renderArea.Height;
  end;

  gGameApp := TKMGameApp.Create(renderArea, tgtWidth, tgtHeight, False, nil, nil, nil, True);
  gGameSettings.Autosave := False;
  gGameSettings.SaveCheckpoints := False;
  gGameApp.PreloadGameResources;
end;


// Batch mode, allows to run tests without any user interaction:
//   Testing_GameTests.exe --run-all [--seed=N] [--cycles=N] [--windowed] [--out=<file>]
//   Testing_GameTests.exe --run=Recruit
// --run filter is a case insensitive substring of the test class name.
// Results are written into the --out file,
// ExitCode:
//   0 - everything passed
//   1 - some tests failed
//   2 - no test matched the filter
// Returns False when there were no known switches, then the app should just show its window as usual
function TForm2.RunFromCmdLine: Boolean;

  function ValueOf(const aPrefix, aParameter: string): string;
  begin
    Result := Copy(aParameter, Length(aPrefix) + 1, MaxInt);
  end;

const
  PARAM_RUN_ALL   = '--run-all';
  PARAM_RUN       = '--run=';
  PARAM_SEED      = '--seed=';
  PARAM_CYCLES    = '--cycles=';
  PARAM_OUT       = '--out=';
  PARAM_WINDOWED  = '--windowed';
begin
  Result := False;

  var paramFilter := '';
  var paramSeed := seSeed.Value;
  var paramCycles := 1;
  var paramHeadless := True;
  var paramOutFile := ChangeFileExt(ParamStr(0), '_results.log');

  for var I := 1 to ParamCount do
  begin
    var param := ParamStr(I);

    if SameText(param, PARAM_RUN_ALL) then
      Result := True
    else
    if StartsText(PARAM_RUN, param) then
    begin
      paramFilter := ValueOf(PARAM_RUN, param);
      if paramFilter <> '' then // An empty value is most likely a missing argument, not "run everything"
        Result := True;
    end
    else
    if StartsText(PARAM_SEED, param) then
      paramSeed := StrToIntDef(ValueOf(PARAM_SEED, param), paramSeed)
    else
    if StartsText(PARAM_CYCLES, param) then
      paramCycles := Max(1, StrToIntDef(ValueOf(PARAM_CYCLES, param), paramCycles))
    else
    if StartsText(PARAM_OUT, param) then
      paramOutFile := ValueOf(PARAM_OUT, param)
    else
    if SameText(param, PARAM_WINDOWED) then
      paramHeadless := False;
  end;

  if not Result then Exit;

  if not paramHeadless then
    Show; // Render control needs a window to create its OpenGL context

  var sw := TStreamWriter.Create(paramOutFile);
  try
    try
      EnsureResourcesLoaded(paramHeadless);

      var ranCnt := 0;
      var failedCnt := 0;
      for var C := 0 to paramCycles - 1 do
        for var I := 0 to High(gTestList) do
        begin
          if (paramFilter <> '') and (Pos(LowerCase(paramFilter), LowerCase(gTestList[I].ClassName)) = 0) then Continue;

          // TKMTest.Run does not guard its SetUp, hence one broken test should not kill the whole batch
          try
            RunTest(gTestList[I], paramSeed + C);
          except
            on E: Exception do
            begin
              fResults.TestResult := trException;
              fResults.TestMessage := E.ClassName + ': ' + E.Message;

              // SetUp may have raised before TKMTest.Run reached its own try/finally (Run does not
              // guard SetUp), so TearDown never ran - the game could still be half-started, which
              // would poison every remaining test's SetUp. Clean it up here as a last resort
              if (gGameApp <> nil) and (gGameApp.Game <> nil) then
                gGameApp.StopGame(grSilent);
            end;
          end;
          Inc(ranCnt);

          case fResults.TestResult of
            trSuccess:    sw.WriteLine(Format('%-40s SUCCESS      seed %d', [gTestList[I].ClassName, paramSeed + C]));
            trFailed:     sw.WriteLine(Format('%-40s FAILED       seed %d: %s', [gTestList[I].ClassName, paramSeed + C, fResults.TestMessage]));
            trException:  sw.WriteLine(Format('%-40s EXCEPTION    seed %d: %s', [gTestList[I].ClassName, paramSeed + C, fResults.TestMessage]));
          end;

          if fResults.TestResult <> trSuccess then
            Inc(failedCnt);
        end;

        if ranCnt = 0 then
        begin
          sw.WriteLine(Format('No tests matched filter "%s"', [paramFilter]));
          ExitCode := 2;
        end
        else
        begin
          sw.WriteLine(Format('Tests run: %d, failed: %d', [ranCnt, failedCnt]));
          ExitCode := Ord(failedCnt > 0);
        end;
    except
      on E: Exception do
      begin
        sw.WriteLine('EXCEPTION before tests could complete: %s: %s', [E.ClassName, E.Message]);
        ExitCode := 3;
      end;
    end;
  finally
    sw.Free;
  end;
end;


end.

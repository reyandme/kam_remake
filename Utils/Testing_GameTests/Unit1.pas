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
    procedure EnsureResourcesLoaded;
    procedure RefreshTagList;
    procedure RunTest(aClass: TKMTestClass; aSeed: Integer);
  end;


implementation
uses
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


procedure TForm2.EnsureResourcesLoaded;
var
  tgtWidth, tgtHeight: Word;
begin
  if gGameApp <> nil then Exit;

  if fRenderArea = nil then
  begin
    tgtWidth := 1024;
    tgtHeight := 768;
  end else
  begin
    tgtWidth := fRenderArea.Width;
    tgtHeight := fRenderArea.Height;
  end;

  gGameApp := TKMGameApp.Create(fRenderArea, tgtWidth, tgtHeight, False, nil, nil, nil, True);
  gGameSettings.Autosave := False;
  gGameSettings.SaveCheckpoints := False;
  gGameApp.PreloadGameResources;
end;


end.

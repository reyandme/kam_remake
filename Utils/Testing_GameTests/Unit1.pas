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
    btnRun: TButton;
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
    procedure btnRunClick(Sender: TObject);
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
    procedure RunOne(aClass: TKMTestClass; aCount: Integer);
    procedure RunAll(aCount: Integer);
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
    btnRun.Enabled := True;
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
    btnRun.Enabled := False;

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
  btnRun.Enabled := True;
  btnRunAll.Enabled := True;
  btnStop.Enabled := False;
end;


function TForm2.IsStopped: Boolean;
begin
  Result := fStopped;
end;


procedure TForm2.RunOne(aClass: TKMTestClass; aCount: Integer);
begin
  EnsureResourcesLoaded;

  fStopped := False;

  var thisTest := aClass.Create(IsStopped, HandleProgress);
  try
    thisTest.ThrottleRender := chkThrottleRender.Checked;
    thisTest.DelayValue := seDelay.Value;

    fResults := thisTest.Run(aCount);
  finally
    thisTest.Free;
  end;
end;


procedure TForm2.btnRunClick(Sender: TObject);
var
  Count: Integer;
  thisTestClass: TKMTestClass;
begin
  if lbTests.ItemIndex = -1 then Exit;
  var testIndex := Integer(lbTests.Items.Objects[lbTests.ItemIndex]);
  Count := seCycles.Value;
  if Count <= 0 then Exit;
  thisTestClass := gTestList[testIndex];

  btnRun.Enabled := False;
  btnRunAll.Enabled := False;
  btnStop.Enabled := True;
  try
    RunOne(thisTestClass, Count);
  finally
    btnRun.Enabled := True;
    btnRunAll.Enabled := True;
    btnStop.Enabled := False;
  end;
end;


procedure TForm2.RunAll(aCount: Integer);
var
  resStr: string;
begin
  EnsureResourcesLoaded;

  fStopped := False;

  var TotalT := GetTickCount;
  var TotalTestsRun := 0;

  for var K := 0 to lbTests.Items.Count - 1 do
  begin
    if fStopped then Break;

    var testIndex := Integer(lbTests.Items.Objects[K]);
    var thisTestClass := gTestList[testIndex];

    var thisTest := thisTestClass.Create(IsStopped, HandleProgress);
    try
      var T := GetTickCount;
      thisTest.ThrottleRender := chkThrottleRender.Checked;
      thisTest.DelayValue := seDelay.Value;

      fResults := thisTest.Run(aCount);

      for var I := 0 to aCount - 1 do
      begin
        case fResults.TestResults[I] of
          trSuccess:    resStr := 'SUCCESS';
          trFailed:     resStr := 'FAILED: ' + fResults.TestMessages[I];
          trException:  resStr := 'EXCEPTION: ' + fResults.TestMessages[I];
        end;

        if aCount > 1 then
          meLog.Lines.Append(Format('%-32s (Run %d): %s (%d ms)', [thisTestClass.ClassName, I+1, resStr, GetTickCount - T]))
        else
          meLog.Lines.Append(Format('%-32s: %s (%d ms)', [thisTestClass.ClassName, resStr, GetTickCount - T]));
      end;

      Inc(TotalTestsRun, aCount);
    finally
      thisTest.Free;
    end;

    Application.ProcessMessages;
  end;

  meLog.Lines.Append('=============================');
  meLog.Lines.Append(Format('Total Tests Run: %d', [TotalTestsRun]));
  meLog.Lines.Append(Format('Total Time Spent: %d ms', [GetTickCount - TotalT]));
end;


procedure TForm2.btnRunAllClick(Sender: TObject);
var
  Count: Integer;
begin
  Count := seCycles.Value;
  if Count <= 0 then Exit;

  meLog.Clear;
  pcMain.ActivePage := tsLog;

  btnRun.Enabled := False;
  btnRunAll.Enabled := False;
  btnStop.Enabled := True;
  try
    RunAll(Count);
  finally
    btnRun.Enabled := True;
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

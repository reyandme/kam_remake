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
    btnTryFoundSeed: TButton;
    seCycles: TSpinEdit;
    lblDelay: TLabel;
    seDelay: TSpinEdit;
    Label1: TLabel;
    ListBox1: TListBox;
    clbCategories: TCheckListBox;
    Label2: TLabel;
    PageControl1: TPageControl;
    TabSheet5: TTabSheet;
    moResults: TMemo;
    Render: TTabSheet;
    Panel1: TPanel;
    chkRender: TCheckBox;
    chkThrottleRender: TCheckBox;
    seDuration: TSpinEdit;
    Label4: TLabel;
    seSeed: TSpinEdit;
    Label7: TLabel;
    btnRunAll: TButton;
    btnStop: TButton;
    procedure clbCategoriesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkRenderClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnTryFoundSeedClick(Sender: TObject);
    procedure btnRunAllClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    fResults: TKMRunResults;
    fRunTime: string;
    fStopped: Boolean;
    RenderArea: TKMRenderControl;
    procedure RefreshTestList;
    function IsStopped: Boolean;
    procedure HandleProgress(const aValue: string);
  end;


var
  Form2: TForm2;


implementation
uses
  KM_GameTypes, KM_Defaults;

{$R *.dfm}


procedure TForm2.clbCategoriesClick(Sender: TObject);
begin
  RefreshTestList;
end;


procedure TForm2.RefreshTestList;
var
  I: Integer;
  Match: Boolean;
  S: string;
begin
  var allowedTags: TKMTestTagSet := [];
  for I := 0 to clbCategories.Items.Count - 1 do
    if clbCategories.Checked[I] then
      allowedTags := allowedTags + [TKMTestTag(Integer(clbCategories.Items.Objects[I]))];

  ListBox1.Items.Clear;
  for I := 0 to High(gTestList) do
  begin
    Match := False;
    for var tag in gTestList[I].TestTags do
      if tag in allowedTags then
        Match := True;

    if Match then
    begin
      S := gTestList[I].ClassName;
      S := StringReplace(S, 'TKMRunner', '', [rfIgnoreCase]);
      ListBox1.Items.AddObject(S, TObject(I));
    end;
  end;

  if ListBox1.Items.Count > 0 then
    ListBox1.ItemIndex := 0
  else
    btnRun.Enabled := False;
    
  ListBox1Click(nil);
end;


procedure TForm2.btnStopClick(Sender: TObject);
begin
  fStopped := True;
  btnStop.Enabled := False;
end;


procedure TForm2.FormCreate(Sender: TObject);
var
  I: Integer;
  S: string;
begin
  if gLog = nil then
    gLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'Testing_GameTests.log');

  RenderArea := TKMRenderControl.Create(Panel1);
  RenderArea.Parent := Panel1;
  RenderArea.Align := alClient;
  RenderArea.Color := clMaroon;

  var tagSet: TKMTestTagSet := [];
  for I := 0 to High(gTestList) do
    tagSet := tagSet + gTestList[I].TestTags;

  for var tag := Low(TKMTestTag) to High(TKMTestTag) do
  begin
    if tag in tagSet then
    begin
      S := GetEnumName(TypeInfo(TKMTestTag), Integer(tag));
      if Copy(S, 1, 2) = 'tc' then
        Delete(S, 1, 2);
      clbCategories.Items.AddObject(S, TObject(tag));
      clbCategories.Checked[clbCategories.Items.Count - 1] := True;
    end;
  end;

  RefreshTestList;

  if Length(gTestList) > 0 then
  begin
    ListBox1.ItemIndex := 0;
    btnRun.Enabled := True;
    btnRunAll.Enabled := True;
    btnTryFoundSeed.Enabled := True;
    btnStop.Enabled := False;
  end;

  SKIP_RENDER := not chkRender.Checked;
  Caption := ExtractFileName(Application.ExeName);
end;


procedure TForm2.chkRenderClick(Sender: TObject);
begin
  SKIP_RENDER := not chkRender.Checked;
end;


procedure TForm2.FormDestroy(Sender: TObject);
begin
  FreeAndNil(gLog);
end;


procedure TForm2.FormShow(Sender: TObject);
const
  LEFT_PARAM = '-left';
  TOP_PARAM = '-top';
var
  I: Integer;
  val: Integer;
begin
  I := 1;
  while I <= ParamCount do
  begin
    if (paramstr(I) = LEFT_PARAM) then
    begin
      Inc(I);
      if TryStrToInt(paramstr(I), val) then
        Left := val;
    end;

    if (paramstr(I) = TOP_PARAM) then
    begin
      Inc(I);
      if TryStrToInt(paramstr(I), val) then
        Top := val;
    end;

    Inc(I);
  end;
end;


procedure TForm2.ListBox1Click(Sender: TObject);
var
  ID: Integer;
begin
  ID := ListBox1.ItemIndex;
  if ID = -1 then Exit;
  btnRun.Enabled := True;
  btnRunAll.Enabled := True;
  btnTryFoundSeed.Enabled := True;
  btnStop.Enabled := False;
end;


function TForm2.IsStopped: Boolean;
begin
  Result := fStopped;
end;


procedure TForm2.btnRunClick(Sender: TObject);
var
  T: Cardinal;
  ID, Count: Integer;
  thisTestClass: TKMTestClass;
  thisTest: TKMTest;
begin
  if ListBox1.ItemIndex = -1 then Exit;
  ID := Integer(ListBox1.Items.Objects[ListBox1.ItemIndex]);
  Count := seCycles.Value;
  if Count <= 0 then Exit;

  fStopped := False;

  btnRun.Enabled := False;
  btnRunAll.Enabled := False;
  btnTryFoundSeed.Enabled := False;
  btnStop.Enabled := True;
  try
    thisTestClass := gTestList[ID];

    if chkRender.Checked then
      thisTest := thisTestClass.Create(RenderArea, IsStopped, HandleProgress)
    else
      thisTest := thisTestClass.Create(nil, IsStopped, HandleProgress);

    try
      T := GetTickCount;
      thisTest.Duration := seDuration.Value;
      thisTest.Seed := seSeed.Value;
      thisTest.ThrottleRender := chkThrottleRender.Checked;
      thisTest.DelayValue := seDelay.Value;

      fResults := thisTest.Run(Count);
      fRunTime := 'Done in ' + IntToStr(GetTickCount - T) + ' ms';
    finally
      thisTest.Free;
    end;
  finally
    btnRun.Enabled := True;
    btnRunAll.Enabled := True;
    btnTryFoundSeed.Enabled := True;
    btnStop.Enabled := False;
  end;
end;


procedure TForm2.btnRunAllClick(Sender: TObject);
var
  T, TotalT: Cardinal;
  TotalTestsRun: Integer;
  ID, Count: Integer;
  thisTestClass: TKMTestClass;
  thisTest: TKMTest;
  I, K: Integer;
  resStr: string;
begin
  Count := seCycles.Value;
  if Count <= 0 then Exit;

  fStopped := False;

  moResults.Clear;
  PageControl1.ActivePage := TabSheet5;

  btnRun.Enabled := False;
  btnRunAll.Enabled := False;
  btnTryFoundSeed.Enabled := False;
  btnStop.Enabled := True;

  TotalT := GetTickCount;
  TotalTestsRun := 0;

  for K := 0 to ListBox1.Items.Count - 1 do
  begin
    if fStopped then Break;

    ID := Integer(ListBox1.Items.Objects[K]);
    thisTestClass := gTestList[ID];

    if chkRender.Checked then
      thisTest := thisTestClass.Create(RenderArea, IsStopped, HandleProgress)
    else
      thisTest := thisTestClass.Create(nil, IsStopped, HandleProgress);

    try
      T := GetTickCount;
      thisTest.Duration := seDuration.Value;
      thisTest.Seed := seSeed.Value;
      thisTest.ThrottleRender := chkThrottleRender.Checked;
      thisTest.DelayValue := seDelay.Value;

      fResults := thisTest.Run(Count);
      
      for I := 0 to Count - 1 do
      begin
        case fResults.TestResults[I] of
          trSuccess: resStr := 'SUCCESS';
          trFailed: resStr := 'FAILED: ' + fResults.TestMessages[I];
          trException: resStr := 'EXCEPTION: ' + fResults.TestMessages[I];
        end;

        if Count > 1 then
          moResults.Lines.Append(Format('%s (Run %d): %s (%d ms)', [thisTestClass.ClassName, I+1, resStr, GetTickCount - T]))
        else
          moResults.Lines.Append(Format('%s: %s (%d ms)', [thisTestClass.ClassName, resStr, GetTickCount - T]));
      end;
      
      Inc(TotalTestsRun, Count);
    finally
      thisTest.Free;
    end;
    
    Application.ProcessMessages;
  end;

  moResults.Lines.Append('=============================');
  moResults.Lines.Append(Format('Total Tests Run: %d', [TotalTestsRun]));
  moResults.Lines.Append(Format('Total Time Spent: %d ms', [GetTickCount - TotalT]));

  btnRun.Enabled := True;
  btnRunAll.Enabled := True;
  btnTryFoundSeed.Enabled := True;
  btnStop.Enabled := False;
end;


procedure TForm2.btnTryFoundSeedClick(Sender: TObject);
var
  T: Cardinal;
  ID: Integer;
  thisTestClass: TKMTestClass;
  thisTest: TKMTest;
  resStr: string;
begin
  if ListBox1.ItemIndex = -1 then Exit;
  ID := Integer(ListBox1.Items.Objects[ListBox1.ItemIndex]);

  fStopped := False;

  btnRun.Enabled := False;
  btnRunAll.Enabled := False;
  btnTryFoundSeed.Enabled := False;
  btnStop.Enabled := True;

  moResults.Clear;
  PageControl1.ActivePage := TabSheet5;

  thisTestClass := gTestList[ID];

  while not fStopped do
  begin
    if chkRender.Checked then
      thisTest := thisTestClass.Create(RenderArea, IsStopped, HandleProgress)
    else
      thisTest := thisTestClass.Create(nil, IsStopped, HandleProgress);

    try
      T := GetTickCount;
      thisTest.Duration := seDuration.Value;
      thisTest.Seed := seSeed.Value;
      thisTest.ThrottleRender := chkThrottleRender.Checked;
      thisTest.DelayValue := seDelay.Value;

      fResults := thisTest.Run(1);

      case fResults.TestResults[0] of
        trSuccess: resStr := 'SUCCESS';
        trFailed: resStr := 'FAILED: ' + fResults.TestMessages[0];
        trException: resStr := 'EXCEPTION: ' + fResults.TestMessages[0];
      end;

      moResults.Lines.Append(Format('%s (Seed %d): %s (%d ms)', [thisTestClass.ClassName, seSeed.Value, resStr, GetTickCount - T]));

      if fResults.TestResults[0] = trFailed then
      begin
        moResults.Lines.Append('Found ETestFailed at seed ' + IntToStr(seSeed.Value));
        Break;
      end;

    finally
      thisTest.Free;
    end;

    seSeed.Value := seSeed.Value + 1;
    Application.ProcessMessages;
  end;

  btnRun.Enabled := True;
  btnRunAll.Enabled := True;
  btnTryFoundSeed.Enabled := True;
  btnStop.Enabled := False;
end;


procedure TForm2.HandleProgress(const aValue: string);
begin
  Label2.Caption := aValue;
  Label2.Refresh;
  Application.ProcessMessages;
end;


end.

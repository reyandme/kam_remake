unit Unit1;
{$I KaM_Remake.inc}
interface
uses
  Forms, Controls, StdCtrls, Spin, ExtCtrls, Classes, SysUtils, Graphics, Types, Math, Windows,
  Unit_Runner, KM_RenderControl,
  {$IFDEF WDC} Vcl.ComCtrls {$ELSE} ComCtrls {$ENDIF};


type
  TForm2 = class(TForm)
    btnRun: TButton;
    seCycles: TSpinEdit;
    Label1: TLabel;
    ListBox1: TListBox;
    Memo2: TMemo;
    Label2: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TrackBar1: TTrackBar;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Label3: TLabel;
    TabSheet4: TTabSheet;
    Memo1: TMemo;
    Render: TTabSheet;
    Panel1: TPanel;
    chkRender: TCheckBox;
    seDuration: TSpinEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    seSeed: TSpinEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    rgAIType: TRadioGroup;
    btnStop: TButton;
    btnPause: TButton;
    rgMaps: TRadioGroup;
    rgTeams: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure TabSheetResize(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    fY: array of TLabel;
    fX: array of TLabel;
    fResults: TKMRunResults;
    fRunTime: string;
    fStopped: Boolean;
    fPaused: Boolean;
    RenderArea: TKMRenderControl;
    function IsStopped: Boolean;
    function IsPaused: Boolean;
    procedure RunnerProgress(const aValue: UnicodeString);
    procedure RunnerProgress2(const aValue: UnicodeString);
    procedure RunnerProgress3(const aValue: UnicodeString);
    procedure RunnerProgress4(const aValue: UnicodeString);
    procedure RunnerProgress5(const aValue: UnicodeString);
    procedure RunnerProgress_Left(const aValue: UnicodeString);
    procedure RunnerProgress_Left2(const aValue: UnicodeString);
    procedure RunnerProgress_Left3(const aValue: UnicodeString);
    procedure RefreshResults(aImg: TImage);
    procedure RefreshDistribution(aImg: TImage);
    procedure RefreshTimes(aImg: TImage);
    procedure RefreshAxisLabels(aImg: TImage; aTopX, aTopY: Integer);
  end;


var
  Form2: TForm2;


implementation
{$R *.dfm}
uses
  KM_GameTypes;


const
  COLORS_COUNT = 8;
  LineCol: array [0..COLORS_COUNT - 1] of TColor =
    (clRed, clBlue, clGreen, clPurple, clMaroon, clGray, clBlack, clOlive);


{$IFDEF FPC}
function Point(X,Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;
{$ENDIF}


procedure TForm2.btnStopClick(Sender: TObject);
begin
  fStopped := True;
  btnStop.Enabled := False;
end;



procedure TForm2.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  RenderArea := TKMRenderControl.Create(Panel1);
  RenderArea.Parent := Panel1;
  RenderArea.Align := alClient;
  RenderArea.Color := clMaroon;

  for I := 0 to High(RunnerList) do
    ListBox1.Items.Append(RunnerList[I].ClassName);

  if Length(RunnerList) > 0 then
  begin
    ListBox1.ItemIndex := 0;
    btnRun.Enabled := True;
    btnStop.Enabled := False;
    btnPause.Enabled := False;
  end;

  Caption := ExtractFileName(Application.ExeName);
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
  btnStop.Enabled := False;
  btnPause.Enabled := False;
end;


procedure TForm2.PageControl1Change(Sender: TObject);
var
  I,J: Integer;
  S: string;
begin
  case PageControl1.ActivePageIndex of
    0: RefreshResults(Image1);
    1: RefreshDistribution(Image2);
    2: RefreshTimes(Image3);
  end;

  Memo1.Clear;
  Memo1.Lines.BeginUpdate;
  for I := 0 to fResults.ChartsCount - 1 do
  begin
    S := IntToStr(I) + '. ';
    for J := 0 to fResults.ValueCount - 1 do
      S := S + Format('%d-%d ', [J, fResults.Value[I,J]]);
    Memo1.Lines.Append(S);
  end;
  Memo1.Lines.EndUpdate;
  Memo1.Lines.Append(fRunTime);
end;


function TForm2.IsStopped: Boolean;
begin
  Result := fStopped;
end;


function TForm2.IsPaused: Boolean;
begin
  Result := fPaused;
end;


procedure TForm2.btnPauseClick(Sender: TObject);
begin
  fPaused := True;
  btnPause.Enabled := False;
end;


procedure TForm2.btnRunClick(Sender: TObject);
var
  T: Cardinal;
  ID, Count: Integer;
  RunnerClass: TKMRunnerClass;
  Runner: TKMRunnerCommon;
begin
  ID := ListBox1.ItemIndex;
  if ID = -1 then Exit;
  Count := seCycles.Value;
  if Count <= 0 then Exit;

  fStopped := False;

  Memo1.Clear;
  btnRun.Enabled := False;
  btnStop.Enabled := True;
  btnPause.Enabled := False; //Always disabled for now
  try
    RunnerClass := RunnerList[ID];

    if chkRender.Checked then
      Runner := RunnerClass.Create(RenderArea, {IsPaused, }IsStopped)
    else
      Runner := RunnerClass.Create(nil, {IsPaused, }IsStopped);

    Runner.OnProgress := RunnerProgress;
    Runner.OnProgress_Left := RunnerProgress_Left;
    Runner.OnProgress_Left2 := RunnerProgress_Left2;
    Runner.OnProgress_Left3 := RunnerProgress_Left3;
    Runner.OnProgress2 := RunnerProgress2;
    Runner.OnProgress3 := RunnerProgress3;
    Runner.OnProgress4 := RunnerProgress4;
    Runner.OnProgress5 := RunnerProgress5;
    try
      T := GetTickCount;
      Runner.Duration := seDuration.Value;
      Runner.Seed := seSeed.Value;
      if rgAIType.ItemIndex = 0 then
        Runner.AIType := aitClassic
      else
        Runner.AIType := aitAdvanced;

      Runner.MapsType := TKMRunnerMapsType(rgMaps.ItemIndex);
      Runner.TeamType := TKMRunnerTeamsType(rgTeams.ItemIndex);

      fResults := Runner.Run(Count);
      fRunTime := 'Done in ' + IntToStr(GetTickCount - T) + ' ms';
    finally
      Runner.Free;
    end;

    PageControl1Change(nil);
  finally
    btnRun.Enabled := True;
    btnStop.Enabled := False;
    btnPause.Enabled := False;
  end;
end;


procedure TForm2.RefreshAxisLabels(aImg: TImage; aTopX, aTopY: Integer);
var
  I: Integer;
  Steps: Integer;
  Step: Word;
begin
  for I := 0 to High(fX) do
    FreeAndNil(fX[I]);

  for I := 0 to High(fY) do
    FreeAndNil(fY[I]);

  Step := Max(Round(aTopY / aImg.Height / 20), 1);

  Steps := Min(aTopY, aImg.Height div 20 div Step);
  SetLength(fY, Steps+1);
  if Steps > 0 then
  for I := 0 to Steps do
  begin
    fY[I] := TLabel.Create(aImg.Parent);
    fY[I].Parent := aImg.Parent;
    fY[I].Alignment := taRightJustify;
    fY[I].Transparent := True;
    fY[I].Left := aImg.Left - 1;
    fY[I].Top := aImg.Top + aImg.Height - Round(aImg.Height / Steps * I) - fY[I].Height + 6;
    fY[I].Caption := IntToStr(Round(aTopY * I / Steps))+'-';
  end;

  Steps := Min(aTopX, aImg.Width div 40);
  SetLength(fX, Steps);
  if Steps > 1 then
  for I := 0 to High(fX) do
  begin
    fX[I] := TLabel.Create(aImg.Parent);
    fX[I].Parent := aImg.Parent;
    fX[I].Alignment := taRightJustify;
    fX[I].Left := aImg.Left + Round(aImg.Width / High(fX) * I);
    fX[I].Top := aImg.Top + aImg.Height + 4;
    fX[I].Caption := FloatToStr(Round(aTopX * I * 10 / High(fX)) / 10);
  end;
end;


procedure TForm2.RefreshDistribution(aImg: TImage);
var
  I,J: Integer;
  DotX, DotY: Word;
  TopX, TopY: Integer;
  StatMax: Integer;
  Stats: array of Integer;
begin
  if aImg.Picture.Bitmap <> nil then
    aImg.Picture.Bitmap.SetSize(aImg.Width, aImg.Height);
  aImg.Canvas.FillRect(aImg.Canvas.ClipRect);

  StatMax := 0;
  for I := 0 to fResults.ValueCount - 1 do
  begin
    SetLength(Stats, 0); //Erase
    SetLength(Stats, Round(fResults.ValueMax) - Round(fResults.ValueMin) + 1);
    for J := 0 to fResults.ChartsCount - 1 do
      Inc(Stats[Round(fResults.Value[J,I]) - Round(fResults.ValueMin)]);

    for J := 0 to High(Stats) do
      StatMax := Max(StatMax, Stats[J]);
  end;

  for I := 0 to fResults.ValueCount - 1 do
  begin
    aImg.Canvas.Pen.Color := LineCol[I mod COLORS_COUNT];

    SetLength(Stats, 0); //Erase
    SetLength(Stats, Round(fResults.ValueMax) - Round(fResults.ValueMin) + 1);
    for J := 0 to fResults.ChartsCount - 1 do
      Inc(Stats[Round(fResults.Value[J,I]) - Round(fResults.ValueMin)]);

    for J := Low(Stats) to High(Stats) do
    begin
      if Length(Stats) > 1 then
        DotX := Round((J - Low(Stats)) * aImg.Width / (Length(Stats) - 1))
      else
        DotX := aImg.Width div 2;

      DotY := aImg.Height - Round(aImg.Height * Stats[J] / StatMax);

      if DotY <> aImg.Height then
        aImg.Canvas.Ellipse(DotX-2, DotY-2, DotX+2, DotY+2);

      if J = 0 then
        aImg.Canvas.PenPos := Point(DotX, DotY)
      else
        aImg.Canvas.LineTo(DotX, DotY);
    end;
  end;
  TopX := Length(Stats);
  TopY := StatMax;

  RefreshAxisLabels(aImg, TopX, TopY);
end;


procedure TForm2.RefreshResults(aImg: TImage);
var
  I,J: Integer;
  DotX, DotY: Word;
  TopX, TopY: Integer;
begin
  if aImg.Picture.Bitmap <> nil then
    aImg.Picture.Bitmap.SetSize(aImg.Width, aImg.Height);
  aImg.Canvas.FillRect(aImg.Canvas.ClipRect);

  for I := 0 to fResults.ValueCount - 1 do
  begin
    aImg.Canvas.Pen.Color := LineCol[I mod COLORS_COUNT];
    for J := 0 to fResults.ChartsCount - 1 do
    begin
      if fResults.ChartsCount > 1 then
        DotX := Round(J / (fResults.ChartsCount - 1) * aImg.Width)
      else
        DotX := aImg.Width div 2;
      if fResults.ValueMax <> 0 then
        DotY := aImg.Height - Round(fResults.Value[J,I] / fResults.ValueMax * aImg.Height)
      else
        DotY := aImg.Height;
      aImg.Canvas.Ellipse(DotX-2, DotY-2, DotX+2, DotY+2);
      if J = 0 then
        aImg.Canvas.PenPos := Point(DotX, DotY)
      else
        aImg.Canvas.LineTo(DotX, DotY);
    end;
  end;
  TopX := fResults.ChartsCount;
  TopY := fResults.ValueMax;

  RefreshAxisLabels(aImg, TopX, TopY);
end;


procedure TForm2.RefreshTimes(aImg: TImage);
var
  I,J: Integer;
  CutOff: Byte;
  DotX, DotY: Word;
  TopX, TopY: Integer;
begin
  if aImg.Picture.Bitmap <> nil then
    aImg.Picture.Bitmap.SetSize(aImg.Width, aImg.Height);
  aImg.Canvas.FillRect(aImg.Canvas.ClipRect);

  CutOff := TrackBar1.Position;

  for I := 0 to fResults.ChartsCount - 1 do
  begin
    aImg.Canvas.Pen.Color := LineCol[I mod COLORS_COUNT];

    for J := 0 to fResults.TimesCount - 1 do
    if fResults.Times[I,J] >= CutOff then
    begin
      DotX := Round(J / (fResults.TimesCount - 1) * aImg.Width);
      DotY := aImg.Height - Round(fResults.Times[I,J] / fResults.TimeMax * aImg.Height);

      aImg.Canvas.PenPos := Point(DotX, aImg.Height);
      aImg.Canvas.LineTo(DotX, DotY);
    end;
  end;
  TopX := fResults.TimesCount;
  TopY := fResults.TimeMax;

  RefreshAxisLabels(aImg, TopX, TopY);
end;


procedure TForm2.RunnerProgress(const aValue: UnicodeString);
begin
  Label2.Caption := aValue;
  Label2.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress2(const aValue: UnicodeString);
begin
  Label5.Caption := aValue;
  Label5.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress3(const aValue: UnicodeString);
begin
  Label6.Caption := aValue;
  Label6.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress4(const aValue: UnicodeString);
begin
  Label8.Caption := aValue;
  Label8.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress5(const aValue: UnicodeString);
begin
  Label12.Caption := aValue;
  Label12.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress_Left(const aValue: UnicodeString);
begin
  Label9.Caption := aValue;
  Label9.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress_Left2(const aValue: UnicodeString);
begin
  Label10.Caption := aValue;
  Label10.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.RunnerProgress_Left3(const aValue: UnicodeString);
begin
  Label11.Caption := aValue;
  Label11.Refresh;
  Application.ProcessMessages;
end;


procedure TForm2.TabSheetResize(Sender: TObject);
begin
  PageControl1Change(nil);
end;


procedure TForm2.TrackBar1Change(Sender: TObject);
begin
  PageControl1Change(nil);
end;

end.

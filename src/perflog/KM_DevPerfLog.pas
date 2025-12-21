unit KM_DevPerfLog;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils,
  Forms, Controls,
  KM_CommonTypes,
  KM_DevPerfLogSingle, KM_DevPerfLogStack, KM_DevPerfLogTypes;


type
  // Collection of PerfLoggers
  TKMPerfLogs = class
  private
    fTick: Integer;
    fPerfLogForm: TForm;
    fItems: array [TPerfSectionDev] of TKMPerfLogSingle;
    fStackCPU: TKMPerfLogStackCPU;
    fStackGFX: TKMPerfLogStackGFX;
    function GetItem(aSection: TPerfSectionDev): TKMPerfLogSingle;
    function GetStackCPU: TKMPerfLogStackCPU;
    function GetStackGFX: TKMPerfLogStackGFX;

    procedure SetOnFormChanged(const aValue: TKMEvent);

    procedure SectionEnter(aSection: TPerfSectionDev; aTick: Integer; aTag: Integer = 0); overload;
  public
    Enabled: Boolean;
    Scale: Integer;
    Smoothing: Boolean;
    ClearOnGameStart: Boolean; // Clear all graphs for every game
    SaveOnExit: Boolean;

    constructor Create(aSections: TPerfSectionSet; aHighPrecision: Boolean);
    destructor Destroy; override;

    property Items[aSection: TPerfSectionDev]: TKMPerfLogSingle read GetItem; default;
    property StackCPU: TKMPerfLogStackCPU read GetStackCPU;
    property StackGFX: TKMPerfLogStackGFX read GetStackGFX;

    procedure SectionEnter(aSection: TPerfSectionDev); overload;//; aTick: Integer = -1; aTag: Integer = 0);
    procedure SectionLeave(aSection: TPerfSectionDev);

    procedure SectionAddValue(aSection: TPerfSectionDev; aValue: Int64; aTick: Integer; aTagS: string = '');

    procedure GameCreated;

    procedure Clear;

    procedure Render(aLeft, aWidth, aHeight: Integer);
    procedure SaveToFile(const aFilename: string; aSaveThreshold: Integer = 10);

    procedure ShowForm(aContainer: TWinControl);
    property OnFormChanged: TKMEvent write SetOnFormChanged;
    function FormHeight: Integer;

    procedure TickBegin(aTick: Integer);
    procedure TickEnd;
  end;


{$IFDEF DBG_PERFLOG}
var
  gPerfLogs: TKMPerfLogs;
{$ENDIF}


implementation
uses
  KM_DevPerfLogForm,
  TypInfo, KM_Defaults, KM_RenderUI, KM_RenderAux, KM_ResFonts;


{ TKMPerfLogs }
constructor TKMPerfLogs.Create(aSections: TPerfSectionSet; aHighPrecision: Boolean);
{$IFDEF DBG_PERFLOG}
const
  DEFAULT_PF_SCALE = 30;
var
  I: TPerfSectionDev;
{$ENDIF}
begin
  inherited Create;
  {$IFDEF DBG_PERFLOG}
  Scale := DEFAULT_PF_SCALE;

  for I := LOW_PERF_SECTION to High(TPerfSectionDev) do
  begin
    case SECTION_INFO[I].Kind of
      plkCPU: fItems[I] := TKMPerfLogSingleCPU.Create;
      plkGFX: fItems[I] := TKMPerfLogSingleGFX.Create;
    end;
    fItems[I].Enabled := (I in aSections);
    fItems[I].Color := TKMColor4f.New(SECTION_INFO[I].Color);
    fItems[I].Display := (I in aSections);
    if fItems[I] is TKMPerfLogSingleCPU then
      TKMPerfLogSingleCPU(fItems[I]).HighPrecision := aHighPrecision;
  end;

  fStackCPU := TKMPerfLogStackCPU.Create;
  fStackGFX := TKMPerfLogStackGFX.Create;
  Enabled := False;
  {$ENDIF}
end;


destructor TKMPerfLogs.Destroy;
{$IFDEF DBG_PERFLOG}
var
  I: TPerfSectionDev;
  s: string;
{$ENDIF}
begin
  {$IFDEF DBG_PERFLOG}
  if SaveOnExit then
  begin
    DateTimeToString(s, 'yyyy-mm-dd_hh-nn-ss', Now); //2007-12-23 15-24-33
    gPerfLogs.SaveToFile(ExeDir + 'logs' + PathDelim + 'performance_log_' + s + '.log');
  end;

  for I := LOW_PERF_SECTION to High(TPerfSectionDev) do
    FreeAndNil(fItems[I]);

  FreeAndNil(fStackCPU);
  FreeAndNil(fStackGFX);
  {$ENDIF}
  inherited;
end;


function TKMPerfLogs.GetItem(aSection: TPerfSectionDev): TKMPerfLogSingle;
begin
  if Self = nil then Exit(nil);

  // This easy check allows us to exit if the Log was not initialized, e.g. in utils
  Result := fItems[aSection]
end;


function TKMPerfLogs.GetStackGFX: TKMPerfLogStackGFX;
begin
  if Self = nil then Exit(nil);

  // This easy check allows us to exit if the Log was not initialized, e.g. in utils
  Result := fStackGFX
end;


function TKMPerfLogs.GetStackCPU: TKMPerfLogStackCPU;
begin
  if Self = nil then Exit(nil);

  // This easy check allows us to exit if the Log was not initialized, e.g. in utils
  Result := fStackCPU
end;


procedure TKMPerfLogs.SectionAddValue(aSection: TPerfSectionDev; aValue: Int64; aTick: Integer; aTagS: string = '');
begin
  if Self = nil then Exit;

  fItems[aSection].SectionAddValue(aValue, aTick, aTagS);
end;


procedure TKMPerfLogs.SectionEnter(aSection: TPerfSectionDev);
begin
  if (Self = nil) or not Enabled then Exit;

  if IsCPUSection(aSection) then
    SectionEnter(aSection, fTick)
  else
    SectionEnter(aSection, -1);
end;


procedure TKMPerfLogs.SectionEnter(aSection: TPerfSectionDev; aTick: Integer; aTag: Integer = 0);
begin
  if Self = nil then Exit;

  fItems[aSection].SectionEnter(aTick, aTag);

  if IsCPUSection(aSection) then
    fStackCPU.SectionEnter(aSection)
  else
    fStackGFX.SectionEnter(aSection);
end;


procedure TKMPerfLogs.SectionLeave(aSection: TPerfSectionDev);
begin
  if (Self = nil) or not Enabled then Exit;

  fItems[aSection].SectionLeave;

  if SECTION_INFO[aSection].Kind = plkCPU then
    fStackCPU.SectionRollback(aSection)
  else
    fStackGFX.SectionRollback(aSection);
end;


procedure TKMPerfLogs.SetOnFormChanged(const aValue: TKMEvent);
begin
  TFormPerfLogs(fPerfLogForm).OnFormChanged := aValue;
end;


procedure TKMPerfLogs.GameCreated;
begin
  if Self = nil then Exit;

  if ClearOnGameStart then
    Clear;
end;


procedure TKMPerfLogs.Clear;
var
  PS: TPerfSectionDev;
begin
  if Self = nil then Exit;

  fStackCPU.Clear;
  fStackGFX.Clear;
  for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
    fItems[PS].Clear;
end;


procedure TKMPerfLogs.Render(aLeft, aWidth, aHeight: Integer);
var
  cCount, lastTick: Integer;

  procedure UpdateCntNLastTick(aCount, aLastTick: Integer);
  begin
    if cCount < aCount then
    begin
      cCount := aCount;
      lastTick := aLastTick;
    end;
  end;

const
  PAD_SIDE = 40;
  PAD_Y = 10;
  EMA_ALPHA = 0.075; // Exponential Moving Average alpha, picked empirically
  X_TICKS_CNT = 10;
  X_TICKS_FREQ = 100;
var
  PS: TPerfSectionDev;
  I, K, off, xTick, ticksCnt, scaleY: Integer;
  needChart: Boolean;
  x, y: Single;
  lbl: string;
begin
  if (Self = nil) or not Enabled then Exit;

  lastTick := 0;
  cCount := 0;

  scaleY := aHeight;

  UpdateCntNLastTick(fStackCPU.Count, fStackCPU.Count);
  UpdateCntNLastTick(fStackGFX.Count, fStackGFX.Count);

  for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
  begin
    fItems[PS].Render(aLeft + PAD_SIDE, aLeft + aWidth - PAD_SIDE * 2, aHeight - PAD_Y, scaleY, EMA_ALPHA, Scale, Smoothing);
    UpdateCntNLastTick(fItems[PS].Count, fItems[PS].EnterTick);
  end;

  // Stacked chart
  fStackCPU.Render(aLeft + PAD_SIDE, aLeft + aWidth - PAD_SIDE * 2, aHeight - PAD_Y, scaleY, EMA_ALPHA, Scale, Smoothing);
  fStackGFX.Render(aLeft + PAD_SIDE, aLeft + aWidth - PAD_SIDE * 2, aHeight - PAD_Y, scaleY, EMA_ALPHA, Scale, Smoothing);

  needChart := fStackCPU.Display or fStackGFX.Display;
  for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
    needChart := needChart or fItems[PS].Display;

  if needChart then
  begin
    // Baseline
    gRenderAux.Line(aLeft + PAD_SIDE + 0.5, aHeight - PAD_Y + 0.5, aLeft + PAD_SIDE + aWidth + 0.5, aHeight - PAD_Y + 0.5, icWhite);

    // Y-axis ticks
    for K := 0 to 10 do
    begin
      y := scaleY / 10 * K;
      gRenderAux.Line(aLeft + PAD_SIDE + 0.5, aHeight - PAD_Y + 0.5 - y, aLeft + PAD_SIDE - 3.5, aHeight - PAD_Y + 0.5 - y, icWhite);

      lbl := FormatFloat('##0.#', Scale / 10 * K) + 'ms';
      TKMRenderUI.WriteText(aLeft + PAD_SIDE - 5, Trunc(aHeight - PAD_Y - y - 8), 0, lbl, fntMini, taRight);
    end;

    cCount := Min(cCount - 1, aWidth);
    ticksCnt := (aWidth div X_TICKS_FREQ);
    for I := 0 to ticksCnt - 1 do
    begin
      off := (lastTick mod X_TICKS_FREQ);
      xTick := lastTick - off - I*X_TICKS_FREQ;

      if xTick < 0 then Continue;

      x := aLeft + PAD_SIDE + 0.5 + off + I*X_TICKS_FREQ;
      y := aHeight - PAD_Y + 0.5;

      //Tick text
      TKMRenderUI.WriteText(Round(x), Round(y + 5), 0, IntToStr(xTick), fntMini, taCenter);
      //Tick mark
      gRenderAux.Line(x, y - 3, x, y + 3, icWhite);
      //Tick vertical dashed line
      gRenderAux.Line(x, y - scaleY, x, y, icLightGray, $F0F0);
    end;
  end;
end;


procedure TKMPerfLogs.SaveToFile(const aFilename: string; aSaveThreshold: Integer = 10);
var
  I: TPerfSectionDev;
  S: TStringList;
begin
  if (Self = nil) or not Enabled then Exit;

  ForceDirectories(ExtractFilePath(aFilename));

  S := TStringList.Create;

  for I := LOW_PERF_SECTION to High(TPerfSectionDev) do
  if fItems[I].Enabled then
  begin
    //Section name
    S.Append(SECTION_INFO[I].Name);
    S.Append(StringOfChar('-', 60));

    fItems[I].SaveToStringList(S, aSaveThreshold);

    // Gap
    S.Append('');
    S.Append('');
  end;

  S.SaveToFile(aFilename);
  S.Free;
end;


function TKMPerfLogs.FormHeight: Integer;
begin
  Result := TFormPerfLogs(fPerfLogForm).FormHeight;
end;


procedure TKMPerfLogs.ShowForm(aContainer: TWinControl);
begin
  if Self = nil then Exit;

  fPerfLogForm := TFormPerfLogs.Create(aContainer);

  fPerfLogForm.Parent := aContainer;

  if aContainer = nil then
  begin
    fPerfLogForm.Align := alNone;
    fPerfLogForm.BorderStyle := bsDialog;
  end;

  TFormPerfLogs(fPerfLogForm).Show(Self);
end;


procedure TKMPerfLogs.TickBegin(aTick: Integer);
begin
  if (Self = nil) or not Enabled then Exit;

  fTick := aTick;
  StackCPU.TickBegin;
  SectionEnter(psGameTick, aTick);
end;


procedure TKMPerfLogs.TickEnd;
var
  I: TPerfSectionDev;
begin
  if (Self = nil) or not Enabled then Exit;

  StackCPU.TickEnd;
  SectionLeave(psGameTick);

  // Enter and leave section to add zero records for not happened events in that tick
  // (f.e. for game save)
  // that will make 'rare' graphs move at the same positions as other 'every tick' graphs
  for I := LOW_PERF_SECTION to High(TPerfSectionDev) do
    if IsCPUSection(I) and IsTimerSection(I) then
    begin
      fItems[I].SectionEnter(fTick);
      fItems[I].SectionLeave;
    end;
end;


end.

unit KM_DevPerfLog;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils,
  Vcl.Forms, Vcl.Controls,
  KM_CommonTypes,
  KM_DevPerfLogSingle, KM_DevPerfLogStack, KM_DevPerfLogTypes;


type
  // Collection of PerfLoggers
  TKMPerfLogs = class
  private
    fPerfLogForm: TForm;
    fItems: array [TPerfSectionDev] of TKMPerfLogSingle;
    fStackCPU: TKMPerfLogStackCPU;
    fStackGFX: TKMPerfLogStackGFX;
    function GetItem(aSection: TPerfSectionDev): TKMPerfLogSingle;
    function GetStackCPU: TKMPerfLogStackCPU;
    function GetStackGFX: TKMPerfLogStackGFX;
  public
    FrameBudget: Integer;
    Smoothing: Boolean;
    SaveOnExit: Boolean;

    constructor Create(aSections: TPerfSectionSet; aHighPrecision: Boolean);
    destructor Destroy; override;

    property Items[aSection: TPerfSectionDev]: TKMPerfLogSingle read GetItem; default;
    property StackCPU: TKMPerfLogStackCPU read GetStackCPU;
    property StackGFX: TKMPerfLogStackGFX read GetStackGFX;

    procedure SectionEnter(aSection: TPerfSectionDev; aTick: Integer = -1; aTag: Integer = 0);
    procedure SectionLeave(aSection: TPerfSectionDev);

    procedure Clear;

    procedure Render(aLeft, aWidth, aHeight: Integer);
    procedure SaveToFile(aFilename: string; aSaveThreshold: Integer = 10);
    procedure ShowForm(aContainer: TWinControl);
    function FormHeight: Integer;

    class function IsCPUSection(aSection: TPerfSectionDev): Boolean;
    class function IsGFXSection(aSection: TPerfSectionDev): Boolean;
  end;


const
  // Tabs are for GUI structure
  // Can not use typed constants within another constants declaration :(
  // http://stackoverflow.com/questions/28699518/
  // Avoid Green, it blends with mostly green terrain
  SECTION_INFO: array [TPerfSectionDev] of record
    Name: string;
    ClassName: TKMPerfLogClass;
    Color: TKMColor3f;
  end = (
    (Name: 'All';                     ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:0;B:0);),
    (Name: 'GameTick';                ClassName: TKMPerfLogSingleCPU; Color: (R:1.0;G:1;B:0);),
    (Name: '   Hands';                ClassName: TKMPerfLogSingleCPU; Color: (R:1;G:0.25;B:0);),
    (Name: '     Units';              ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:0.5;B:0.5);),
    (Name: '     Deliveries';         ClassName: TKMPerfLogSingleCPU; Color: (R:0.75;G:0.25;B:0.25);),
    (Name: '     WalkConnect';        ClassName: TKMPerfLogSingleCPU; Color: (R:1;G:0.75;B:0.75);),
    (Name: '   FOW';                  ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:0.75;B:0);),
    (Name: '   Pathfinding';          ClassName: TKMPerfLogSingleCPU; Color: (R:0.0;G:1;B:0.75);),
    (Name: '   HungarianReorder';     ClassName: TKMPerfLogSingleCPU; Color: (R:1.0;G:0;B:1);),
    (Name: '   AIFields';             ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:0.5;B:1);),
    (Name: '   AI';                   ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:0.75;B:1);),
    (Name: '     AI City Advanced';   ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:0.75;B:0.25);),
    (Name: '     AI Army Advanced';   ClassName: TKMPerfLogSingleCPU; Color: (R:0.25;G:0.75;B:1);),
    (Name: '     AI City Classic';    ClassName: TKMPerfLogSingleCPU; Color: (R:0.25;G:0.5;B:1);),
    (Name: '     AI Army Classic';    ClassName: TKMPerfLogSingleCPU; Color: (R:0.5;G:0.5;B:0.25);),
    (Name: '   Terrain';              ClassName: TKMPerfLogSingleCPU; Color: (R:0.5;G:0.5;B:0.5);),
    (Name: '   TerrainFinder';        ClassName: TKMPerfLogSingleCPU; Color: (R:0;G:1;B:1);),
    (Name: '   Scripting';            ClassName: TKMPerfLogSingleCPU; Color: (R:1;G:0.25;B:0.75);),
    (Name: '   Minimap';              ClassName: TKMPerfLogSingleCPU; Color: (R:0.7;G:0;B:0.9);),
    (Name: 'Render.CPU';              ClassName: TKMPerfLogSingleCPU; Color: (R:1.0;G:0;B:0);),
    (Name: 'Render.GFX';              ClassName: TKMPerfLogSingleGFX; Color: (R:0;G:1;B:1);),
    (Name: '     Terrain';            ClassName: TKMPerfLogSingleGFX; Color: (R:0;G:0.25;B:0.25);),
    (Name: '       TerBase';          ClassName: TKMPerfLogSingleGFX; Color: (R:0;G:0.5;B:0.25);),
    (Name: '         Tiles';          ClassName: TKMPerfLogSingleGFX; Color: (R:0.25;G:0;B:0.25);),
    (Name: '         Water';          ClassName: TKMPerfLogSingleGFX; Color: (R:0.25;G:0;B:0.5);),
    (Name: '         Layers';         ClassName: TKMPerfLogSingleGFX; Color: (R:0.5;G:0;B:0.25);),
    (Name: '         Overlays';       ClassName: TKMPerfLogSingleGFX; Color: (R:0.5;G:0.5;B:0.25);),
    (Name: '         Light';          ClassName: TKMPerfLogSingleGFX; Color: (R:0.5;G:0.25;B:0);),
    (Name: '         Shadows';        ClassName: TKMPerfLogSingleGFX; Color: (R:0.75;G:0.5;B:0);),
    (Name: '     RenderList';         ClassName: TKMPerfLogSingleGFX; Color: (R:0.5;G:1;B:0.75);),
    (Name: '     FOWRender';          ClassName: TKMPerfLogSingleGFX; Color: (R:0.75;G:1;B:0.75);),
    (Name: '   UpdateVBO';            ClassName: TKMPerfLogSingleCPU; Color: (R:0.5;G:0.5;B:1);),
    (Name: '   GUI';                  ClassName: TKMPerfLogSingleGFX; Color: (R:1.0;G:0.25;B:0);)
  );

{$IFDEF PERFLOG}
var
  gPerfLogs: TKMPerfLogs;
{$ENDIF}


implementation
uses
  KM_DevPerfLogForm,
  TypInfo, KM_Defaults, KM_RenderUI, KM_RenderAux, KM_ResFonts;


{ TKMPerfLogs }
constructor TKMPerfLogs.Create(aSections: TPerfSectionSet; aHighPrecision: Boolean);
{$IFDEF PERFLOG}
var
  I: TPerfSectionDev;
{$ENDIF}
begin
  inherited Create;
  {$IFDEF PERFLOG}
  FrameBudget := 20;

  for I := LOW_PERF_SECTION to High(TPerfSectionDev) do
  begin
    fItems[I] := SECTION_INFO[I].ClassName.Create;
    fItems[I].Enabled := (I in aSections);
    fItems[I].Color := TKMColor4f.New(SECTION_INFO[I].Color);
    fItems[I].Display := (I in aSections);
    if fItems[I] is TKMPerfLogSingleCPU then
      TKMPerfLogSingleCPU(fItems[I]).HighPrecision := aHighPrecision;
  end;

  fStackCPU := TKMPerfLogStackCPU.Create;
  fStackGFX := TKMPerfLogStackGFX.Create;
  {$ENDIF}
end;


destructor TKMPerfLogs.Destroy;
{$IFDEF PERFLOG}
var
  I: TPerfSectionDev;
  s: string;
{$ENDIF}
begin
  {$IFDEF PERFLOG}
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
  // This easy check allows us to exit if the Log was not initialized, e.g. in utils
  if Self <> nil then
    Result := fItems[aSection]
  else
    Result := nil;
end;


function TKMPerfLogs.GetStackGFX: TKMPerfLogStackGFX;
begin
  // This easy check allows us to exit if the Log was not initialized, e.g. in utils
  if Self <> nil then
    Result := fStackGFX
  else
    Result := nil;
end;


class function TKMPerfLogs.IsCPUSection(aSection: TPerfSectionDev): Boolean;
begin
  Result := SECTION_INFO[aSection].ClassName = TKMPerfLogSingleCPU;
end;


class function TKMPerfLogs.IsGFXSection(aSection: TPerfSectionDev): Boolean;
begin
  Result := SECTION_INFO[aSection].ClassName = TKMPerfLogSingleGFX;
end;


function TKMPerfLogs.GetStackCPU: TKMPerfLogStackCPU;
begin
  // This easy check allows us to exit if the Log was not initialized, e.g. in utils
  if Self <> nil then
    Result := fStackCPU
  else
    Result := nil;
end;


procedure TKMPerfLogs.SectionEnter(aSection: TPerfSectionDev; aTick: Integer = -1; aTag: Integer = 0);
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
  if Self = nil then Exit;

  fItems[aSection].SectionLeave;

  if SECTION_INFO[aSection].ClassName = TKMPerfLogSingleCPU then
    fStackCPU.SectionRollback(aSection)
  else
    fStackGFX.SectionRollback(aSection);
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
  if Self = nil then Exit;

  lastTick := 0;
  cCount := 0;

  scaleY := aHeight;

  UpdateCntNLastTick(fStackCPU.Count, fStackCPU.Count);
  UpdateCntNLastTick(fStackGFX.Count, fStackGFX.Count);

  for PS := LOW_PERF_SECTION to High(TPerfSectionDev) do
  begin
    fItems[PS].Render(aLeft + PAD_SIDE, aLeft + aWidth - PAD_SIDE * 2, aHeight - PAD_Y, scaleY, EMA_ALPHA, FrameBudget, Smoothing);
    UpdateCntNLastTick(fItems[PS].Count, fItems[PS].EnterTick);
  end;

  // Stacked chart
  fStackCPU.Render(aLeft + PAD_SIDE, aLeft + aWidth - PAD_SIDE * 2, aHeight - PAD_Y, scaleY, EMA_ALPHA, FrameBudget, Smoothing);
  fStackGFX.Render(aLeft + PAD_SIDE, aLeft + aWidth - PAD_SIDE * 2, aHeight - PAD_Y, scaleY, EMA_ALPHA, FrameBudget, Smoothing);

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

      lbl := FormatFloat('##0.#', FrameBudget / 10 * K) + 'ms';
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


procedure TKMPerfLogs.SaveToFile(aFilename: string; aSaveThreshold: Integer = 10);
var
  I: TPerfSectionDev;
  S: TStringList;
begin
  if Self = nil then Exit;

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


end.

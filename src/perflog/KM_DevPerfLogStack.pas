unit KM_DevPerfLogStack;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils, KromUtils,
  {$IFDEF WDC}
  System.Generics.Collections,
  {$ENDIF}
  {$IFDEF FPC}
  Generics.Collections,
  {$ENDIF}
  KM_DevPerfLogTypes;


type
  TKMSectionData = class
  private
    fCount: Integer;
    fSection: TPerfSectionDev;
    fEnabled: Boolean;
    fShow: Boolean;

    procedure SetEnabled(aEnabled: Boolean);
    procedure SetShow(aShow: Boolean);
    function GetEnabled: Boolean;
    function GetShow: Boolean;
  public
    constructor Create; overload;
    constructor Create(aSection: TPerfSectionDev); overload;

    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Show: Boolean read GetShow write SetShow;
  end;


  TKMPerfLogStack = class
  private
    fSectionNames: TStringList; // String contains Key, Object contains integer Count
    fCount: Integer;
    fTimes: array of array of Int64; // in usec
    fCaptions: array of record
      AvgBase, Middle: Single;
    end;

    fPrevSection: TStack<Integer>;
    fThisSection: Integer;

    function GetTime(aID, aSectionI: Integer): Int64; inline;
    function GetSectionData(aSection: TPerfSectionDev): TKMSectionData; overload;
    function GetSectionData(aIndex: Integer): TKMSectionData; overload;

    property SectionDataI[aIndex: Integer]: TKMSectionData read GetSectionData;
    function GetCount: Integer;
  protected
    procedure SectionRollback; overload;
    function SectionEnterI(aSection: Integer; aRollback: Boolean = False): Boolean; virtual;
    procedure SectionLeave; virtual;
    function GetSectionTime: Int64; virtual; abstract;
    procedure InitSection(aIndex: Integer); virtual;
  public
    Enabled: Boolean;
    Display: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure GetSectionsStats(aList: TStringList);
    procedure Render(aLeft, aWidth, aHeight, aScaleY: Integer; aEmaAlpha: Single; aFrameBudget: Integer; aSmoothing: Boolean);
    property SectionData[aSection: TPerfSectionDev]: TKMSectionData read GetSectionData; default;
    property Count: Integer read GetCount;
    procedure SectionRollback(aName: string); overload;
    procedure SectionRollback(aSection: TPerfSectionDev); overload;

    procedure SectionEnter(aName: string; aSection: TPerfSectionDev = psNone); overload;
    procedure SectionEnter(aSection: TPerfSectionDev); overload;
  end;

  // GPU logging
  // Async through gRenderLow.Queries
  TKMPerfLogStackGFX = class(TKMPerfLogStack)
  private
    fGPUQueryList: array of Integer;
  protected
    function SectionEnterI(aSection: Integer; aCount: Boolean = True): Boolean; override;
    function GetSectionTime: Int64; override;
    procedure InitSection(aIndex: Integer); override;
    procedure SectionLeave; override;
  public
    procedure FrameBegin;
    procedure FrameEnd;
  end;

  TKMPerfLogStackCPU = class(TKMPerfLogStack)
  private
    fEnterTime: Int64;
    fInTick: Boolean;
  protected
    function SectionEnterI(aSection: Integer; aRollback: Boolean = False): Boolean; override;
    function GetSectionTime: Int64; override;
  public
    HighPrecision: Boolean;
    constructor Create;
    procedure TickBegin;
    procedure TickEnd;
  end;


implementation
uses
  KM_Render, KM_RenderAux, KM_RenderUI, KM_DevPerfLog,
  KM_Points, KM_CommonUtils, KM_CommonTypes, KM_ResFonts;


{ TKMSectionData }
constructor TKMSectionData.Create;
begin
  Create(psNone);
end;


constructor TKMSectionData.Create(aSection: TPerfSectionDev);
begin
  inherited Create;

  fCount := 0;
  fSection := aSection;

  fShow := aSection <> psNone;
end;


function TKMSectionData.GetEnabled: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fEnabled;
end;


function TKMSectionData.GetShow: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fShow;
end;


procedure TKMSectionData.SetEnabled(aEnabled: Boolean);
begin
  if Self = nil then Exit;

  fEnabled := aEnabled;
end;


procedure TKMSectionData.SetShow(aShow: Boolean);
begin
  if Self = nil then Exit;

  fShow := aShow;
end;


{ TKMPerfLogStack }
constructor TKMPerfLogStack.Create;
begin
  inherited;

  fSectionNames := TStringList.Create;
  fPrevSection := TStack<Integer>.Create;
end;


destructor TKMPerfLogStack.Destroy;
begin
  fSectionNames.Free;
  fPrevSection.Free;

  inherited;
end;


procedure TKMPerfLogStack.Clear;
begin
  if Self = nil then Exit; 

  fCount := 0;
  fSectionNames.Clear;
end;


// Get total stats in msec
procedure TKMPerfLogStack.GetSectionsStats(aList: TStringList);
var
  I, K: Integer;
  secTime, totalTime: Single;
begin
  if Self = nil then Exit;

  aList.Clear;

  totalTime := 0;

  for I := 0 to fSectionNames.Count - 1 do
  begin
    // Sum section length
    secTime := 0;
    for K := 0 to fCount - 1 do
      secTime := secTime + fTimes[K,I] / 1000;

    // Times are cumulative. Convert them back into separate
    secTime := secTime - totalTime;
    totalTime := totalTime + secTime;
    aList.AddObject(fSectionNames[I], TObject(secTime));
  end;

  aList.AddObject('[Total]', TObject(totalTime));
end;


function TKMPerfLogStack.GetCount: Integer;
begin
  if Self = nil then Exit(0);

  Result := fCount;
end;

function TKMPerfLogStack.GetSectionData(aIndex: Integer): TKMSectionData;
begin
  if Self = nil then Exit(nil);

  Result := TKMSectionData(fSectionNames.Objects[aIndex]);
end;


function TKMPerfLogStack.GetSectionData(aSection: TPerfSectionDev): TKMSectionData;
var
  I: Integer;
  sectionData: TKMSectionData;
begin
  Result := nil;
  if Self = nil then Exit;

  for I := 0 to fSectionNames.Count - 1 do
  begin
    sectionData := TKMSectionData(fSectionNames.Objects[I]);
    if (sectionData <> nil)
      and (sectionData.fSection = aSection) then
      Exit(sectionData);
  end;
end;


// Get total sections time before section (considering not shown sections)
function TKMPerfLogStack.GetTime(aID, aSectionI: Integer): Int64;
var
  I: Integer;
begin
  Result := 0;
  Assert(aSectionI < fSectionNames.Count);

  for I := 0 to aSectionI do
    if TKMSectionData(fSectionNames.Objects[I]).fShow then
      Result := Result + fTimes[aID, I];
end;


procedure TKMPerfLogStack.Render(aLeft, aWidth, aHeight, aScaleY: Integer; aEmaAlpha: Single; aFrameBudget: Integer; aSmoothing: Boolean);
const
  HALF_CAPTION_HEIGHT = 10;
  LERP_AVG = 0.025;
var
  I, K, L, prevSection: Integer;
  t1, t2, tLast: Int64;
  cCount: Integer;
  vaFill: TKMPointFArray;
  vaLine: TKMPointFArray;
  ty: Integer;
  accum1, accum2, accum3: Single;
  fillCol: TKMColor4f;
  sectionData: TKMSectionData;
  isFirstSection: Boolean;
begin
  if Self = nil then Exit;
  if not Display then Exit;
  if fCount <= 1 then Exit;

  cCount := Min(fCount - 1, aWidth);
  SetLength(vaFill, cCount * 2);
  SetLength(vaLine, cCount);
  isFirstSection := True;
  prevSection := -1;

  for I := 0 to fSectionNames.Count - 1 do
  begin
    sectionData := TKMSectionData(fSectionNames.Objects[I]);

    if not sectionData.fShow then
      Continue;

    if sectionData.fSection <> psNone then
      fillCol := TKMColor4f.New(SECTION_INFO[sectionData.fSection].Color, 0.4)
    else
      fillCol := TKMColor4f.New(TKMColor3f.Generic(I), 0.4);

    accum1 := aHeight;
    accum2 := aHeight;
    accum3 := aHeight;
    tLast := 0;

    // Do not render newest time, it has not been complete nor stacked yet
    for K := cCount - 1 downto 0 do
    begin
      // Skip current time, it's not finalized yet
      L := (fCount - 2) - K;

      // Fill is made with hundreds of 1px lines, so we get pixel-perfect fill between 2 charts
      if isFirstSection then
      begin
        t2 := GetTime(L,I);
        vaFill[K*2]   := TKMPointF.New(aLeft + K + 0.5, aHeight + 0.5);
        vaFill[K*2+1] := TKMPointF.New(aLeft + K + 0.5, aHeight + 0.5 - t2 / 1000 / aFrameBudget * aScaleY);
      end else
      begin
        t1 := GetTime(L,I-1);
        t2 := t1 + fTimes[L,I];
        vaFill[K*2]   := TKMPointF.New(aLeft + K + 0.5, aHeight + 0.5 - t1 / 1000 / aFrameBudget * aScaleY);
        vaFill[K*2+1] := TKMPointF.New(aLeft + K + 0.5, aHeight + 0.5 - t2 / 1000 / aFrameBudget * aScaleY);
      end;

      vaLine[K] := TKMPointF.New(aLeft + K + 0.5, aHeight + 0.5 - t2 / 1000 / aFrameBudget * aScaleY);

      if L = fCount - 2 then
        tLast := T2;

      if aSmoothing then
      begin
        // Exponential Moving Average
        accum1 := aEmaAlpha * vaLine[K].Y + (1 - aEmaAlpha) * accum1;
        vaLine[K].Y := accum1;

        accum2 := aEmaAlpha * vaFill[K*2].Y + (1 - aEmaAlpha) * accum2;
        vaFill[K*2].Y := accum2;

        accum3 := aEmaAlpha * vaFill[K*2+1].Y + (1 - aEmaAlpha) * accum3;
        vaFill[K*2+1].Y := accum3;
      end;
    end;

    // Fill
    gRenderAux.Line(vaFill, fillCol, 1, lmPairs);

    // Border
    gRenderAux.Line(vaLine, TKMColor4f.White.Alpha(0.2), 1, lmStrip);

    fCaptions[I].AvgBase := Lerp(fCaptions[I].AvgBase, tLast, LERP_AVG);

    if isFirstSection then
      fCaptions[I].Middle := fCaptions[I].AvgBase / 2
    else
      fCaptions[I].Middle := (fCaptions[prevSection].AvgBase + fCaptions[I].AvgBase) / 2;

    // Sections captions
    if (fCaptions[I].AvgBase - fCaptions[I].Middle) / 1000 / aFrameBudget * aScaleY > HALF_CAPTION_HEIGHT then
    begin
      ty := EnsureRange(Round(fCaptions[I].Middle / 1000 / aFrameBudget * aScaleY), 0, 5000);
      TKMRenderUI.WriteText(aLeft + 4, Trunc(aHeight + 0.5 - ty - 7), 0,
        Trim(SECTION_INFO[sectionData.fSection].Name) + ' x' + IntToStr(sectionData.fCount), fntMini, taLeft);
    end;

    prevSection := I;
    isFirstSection := False;
  end;
end;


{ TKMPerfLogStackCPU }
constructor TKMPerfLogStackCPU.Create;
begin
  inherited;

  HighPrecision := True;
end;


procedure TKMPerfLogStackCPU.TickBegin;
var
  I: Integer;
  sectionData: TKMSectionData;
begin
  if (Self = nil) or not Enabled then Exit;

  fThisSection := -1;
  fPrevSection.Clear;

  Inc(fCount);

  if fCount >= Length(fTimes) then
    SetLength(fTimes, Length(fTimes) + 1024, fSectionNames.Count);

  for I := 0 to fSectionNames.Count - 1 do
  begin
    sectionData := TKMSectionData(fSectionNames.Objects[I]);
    if sectionData = nil then
      sectionData := TKMSectionData.Create
    else
      sectionData.fCount := 0;

    fSectionNames.Objects[I] := sectionData;
  end;

  SectionEnter('TickBegin');
  fInTick := True;
end;


procedure TKMPerfLogStack.SectionEnter(aName: string; aSection: TPerfSectionDev = psNone);
var
  I: Integer;
begin
  if (Self = nil) or not Enabled {or not fInTick} then Exit;

  Assert(aName <> '');

  I := fSectionNames.IndexOf(aName);
  if I = -1 then
  begin
    I := fSectionNames.Add(aName);
    Assert(I = fSectionNames.Count - 1);

    InitSection(I);

    fSectionNames.Objects[I] := TKMSectionData.Create(aSection);

    SetLength(fTimes, Length(fTimes), fSectionNames.Count);
    SetLength(fCaptions, fSectionNames.Count);
  end;

  SectionEnterI(I);
end;


procedure TKMPerfLogStack.SectionEnter(aSection: TPerfSectionDev);
begin
  SectionEnter(GetSectionName(aSection), aSection);
end;


procedure TKMPerfLogStack.SectionRollback(aSection: TPerfSectionDev);
begin
  SectionRollback(GetSectionName(aSection));
end;


procedure TKMPerfLogStack.SectionRollback(aName: string);
var
  I: Integer;
begin
  if Self = nil then Exit;

  I := fSectionNames.IndexOf(aName);

  if (I = -1) or not SectionDataI[I].Enabled then Exit;

  SectionRollback;
end;


procedure TKMPerfLogStack.SectionRollback;
var
  section: Integer;
begin
  if (Self = nil) or not Enabled {or not fInTick} then Exit;

  section := -1;
  if fPrevSection.Count > 0 then
    section := fPrevSection.Pop;

  SectionEnterI(section, True);
end;


function TKMPerfLogStack.SectionEnterI(aSection: Integer; aRollback: Boolean = False): Boolean;
var
  sectData: TKMSectionData;
begin
  Result := False;
  if (Self = nil) or not Enabled then Exit;

  if not aRollback
    and ((aSection = -1)
      or ({(SectionDataI[aSection] <> nil) and }not SectionDataI[aSection].Enabled)) then Exit;

  SectionLeave;

  if not aRollback and (fThisSection <> -1) then
    fPrevSection.Push(fThisSection);

  fThisSection := aSection;

  if fThisSection = -1 then Exit;

  if not aRollback then
  begin
    sectData := SectionDataI[fThisSection];
    if sectData <> nil then
      sectData.fCount := sectData.fCount + 1;
  end;
  Result := True;
end;


function TKMPerfLogStackCPU.SectionEnterI(aSection: Integer; aRollback: Boolean = False): Boolean;
begin
  Result := False;
  if not inherited then Exit;

  if HighPrecision then
    fEnterTime := TimeGetUsec
  else
    fEnterTime := TimeGet;

  Result := True;
end;


function TKMPerfLogStackCPU.GetSectionTime: Int64;
begin
  if Self = nil then Exit(0);

  // Get us time from previous frame
  if HighPrecision then
    Result := GetTimeUsecSince(fEnterTime)
  else
    Result := GetTimeSince(fEnterTime) * 1000;
end;


procedure TKMPerfLogStack.SectionLeave;
begin
  if not Enabled {or not fInTick} then Exit;

  if fThisSection = -1 then Exit;

  // Sum times, since same section could be entered more than once
  fTimes[fCount - 1, fThisSection] := fTimes[fCount - 1, fThisSection] + GetSectionTime;
end;


procedure TKMPerfLogStack.InitSection;
begin
  //Do nothing
end;


procedure TKMPerfLogStackCPU.TickEnd;
const
  LERP_AVG = 0.025;
begin
  if (Self = nil) or not Enabled then Exit;

  SectionLeave;

  fThisSection := -1;
  fPrevSection.Clear;

  fInTick := False;
end;


{ TKMPerfLogStackGFX }
procedure TKMPerfLogStackGFX.FrameBegin;
var
  I: Integer;
  sectionData: TKMSectionData;
begin
  if (Self = nil) or not Enabled then Exit;

  fThisSection := -1;
  fPrevSection.Clear;

  Inc(fCount);

  if fCount >= Length(fTimes) then
    SetLength(fTimes, Length(fTimes) + 1024, fSectionNames.Count);

  for I := 0 to fSectionNames.Count - 1 do
  begin
    sectionData := TKMSectionData(fSectionNames.Objects[I]);
    if sectionData = nil then
      sectionData := TKMSectionData.Create
    else
      sectionData.fCount := 0;

    fSectionNames.Objects[I] := sectionData;
  end;

  SectionEnter('FrameBegin');
end;


procedure TKMPerfLogStackGFX.SectionLeave;
begin
  if not Enabled {or not fInTick} then Exit;

  if fThisSection = -1 then Exit;

  gRender.Query.QueriesEnd(fGPUQueryList[fThisSection]);

  inherited;
end;


function TKMPerfLogStackGFX.SectionEnterI(aSection: Integer; aCount: Boolean = True): Boolean;
begin
  Result := False;
  if not inherited then Exit;

  if fThisSection = -1 then Exit;

  gRender.Query.QueriesBegin(fGPUQueryList[fThisSection]);

  Result := True;
end;


function TKMPerfLogStackGFX.GetSectionTime: Int64;
begin
  // Get us time from previous frame
  Result := gRender.Query.QueriesTime(fGPUQueryList[fThisSection]);
  Result := Round(Result / 1000);
end;


procedure TKMPerfLogStackGFX.InitSection(aIndex: Integer);
begin
  SetLength(fGPUQueryList, fSectionNames.Count);
  fGPUQueryList[aIndex] := gRender.Query.QueriesGen;
end;


procedure TKMPerfLogStackGFX.FrameEnd;
begin
  if (Self = nil) or not Enabled then Exit;

  SectionLeave;

  fPrevSection.Clear;
  fThisSection := -1;
end;


end.

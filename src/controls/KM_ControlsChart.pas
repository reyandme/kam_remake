unit KM_ControlsChart;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KromOGLUtils,
  KM_Controls,
  KM_RenderUI, KM_ResFonts,
  KM_CommonClasses, KM_CommonTypes, KM_Points, KM_Defaults;


type
  TKMGraphLine = record
    Title: UnicodeString;
    TitleDetailed: TKMStringArray;
    TitleDetailedColor: TKMCardinalArray;
    Tag: Integer;
    Color: TColor4;
    Visible: Boolean;
    Values: TKMCardinalArray;
    ValuesAlt: TKMCardinalArray;
  end;

  TKMChart = class(TKMControl)
  private
    fCaption: UnicodeString;
    fFont: TKMFont;
    fCount: Integer;
    fItemHeight: Byte;
    fLegendWidth: Word;
    fLegendCaption: String;
    fLineOver: Integer;
    fLines: array of TKMGraphLine;
    fMaxLength: Cardinal; //Maximum samples (by horizontal axis)
    fMinTime: Cardinal; //Minimum time (in sec), used only for Rendering time ticks
    fMaxTime: Cardinal; //Maximum time (in sec), used only for Rendering time ticks
    fMaxValue: Cardinal; //Maximum value (by vertical axis)
    fPeaceTime: Cardinal;

    //Legend separators
    fSeparatorPositions: TXStringList;
    fSeparatorHeight: Byte;
    fSeparatorColor: TColor4;

    fOnLegendClick: TObjectIntBoolEvent;
    procedure UpdateMaxValue;
    function GetLine(aIndex:Integer): TKMGraphLine;
    function GetLineNumber(aY: Integer): Integer;
//    function GetSeparatorsHeight(aIndex: Integer): Integer;
    function GetSeparatorPos(aIndex: Integer): Integer;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
    destructor Destroy; override;

    procedure AddLine(const aTitle: UnicodeString; aColor: TColor4; const aValues: TKMCardinalArray; aTag: Integer = -1); overload;
    procedure AddLine(const aTitle: UnicodeString; aColor: TColor4; const aTitleDetailed: TKMStringArray;
                      const aTitleDetailedColor: TKMCardinalArray; const aValues: TKMCardinalArray; aTag: Integer = -1); overload;
    procedure AddAltLine(const aAltValues: TKMCardinalArray);
    procedure TrimToFirstVariation;
    property Caption: UnicodeString read fCaption write fCaption;
    procedure Clear;
    procedure SetLineVisible(aLineID:Integer; aVisible:Boolean);
    property MaxLength: Cardinal read fMaxLength write fMaxLength;
    property MaxTime: Cardinal read fMaxTime write fMaxTime;
    property Lines[aIndex: Integer]: TKMGraphLine read GetLine;
    property LineCount:Integer read fCount;
    property Font: TKMFont read fFont write fFont;
    property LegendWidth: Word read fLegendWidth write fLegendWidth;
    property LegendCaption: String read fLegendCaption write fLegendCaption;
    property Peacetime: Cardinal read fPeaceTime write fPeaceTime;

    property SeparatorPos[aIndex: Integer]: Integer read GetSeparatorPos;
    property SeparatorColor: TColor4 read fSeparatorColor write fSeparatorColor;
    property SeparatorHeight: Byte read fSeparatorHeight write fSeparatorHeight;

    procedure AddSeparator(aPosition: Integer);
    procedure SetSeparatorPositions(aSeparatorPositions: TStringList);
    procedure ClearSeparators;

    property OnLegendClick: TObjectIntBoolEvent read fOnLegendClick write fOnLegendClick;

    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;

    procedure Paint; override;
  end;


implementation
uses
  SysUtils, Math,
  KM_Resource, KM_ResTexts,
  KM_CommonUtils;


{ TKMChart }
constructor TKMChart.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  fSeparatorPositions := TXStringList.Create;
  fSeparatorPositions.Sorted := True; // Better we have separators sorted

  fFont := fntOutline;
  fItemHeight := 20;
  fLineOver := -1;
  fLegendWidth := 150;
  fSeparatorColor := clChartSeparator;
  fSeparatorHeight := 10;
end;


destructor TKMChart.Destroy;
begin
  FreeAndNil(fSeparatorPositions);
  inherited;
end;


procedure TKMChart.AddLine(const aTitle: UnicodeString; aColor: TColor4; const aValues: TKMCardinalArray; aTag: Integer = -1);
var
  titleDetailed: TKMStringArray;
  titleDetailedColor: TKMCardinalArray;
begin
  SetLength(titleDetailed, 0);
  SetLength(titleDetailedColor, 0);
  AddLine(aTitle, aColor, titleDetailed, titleDetailedColor, aValues, aTag);
end;


procedure TKMChart.AddLine(const aTitle: UnicodeString; aColor: TColor4; const aTitleDetailed: TKMStringArray;
                           const aTitleDetailedColor: TKMCardinalArray; const aValues: TKMCardinalArray; aTag: Integer = -1);
begin
  if fMaxLength = 0 then Exit;

  Assert(Length(aTitleDetailed) = Length(aTitleDetailedColor), 'aTitleDetailed and aTitleDetailedColor should have same length');

  //Make sure there is enough Values to copy to local storage with Move procedure
  Assert(Length(aValues) >= fMaxLength);

  SetLength(fLines, fCount + 1);

  fLines[fCount].Color := aColor;
  fLines[fCount].Title := aTitle;
  fLines[fCount].Tag := aTag;
  fLines[fCount].Visible := True;
  fLines[fCount].TitleDetailed := aTitleDetailed;
  fLines[fCount].TitleDetailedColor := aTitleDetailedColor;
  SetLength(fLines[fCount].Values, fMaxLength);
  if SizeOf(aValues) <> 0 then
    Move(aValues[0], fLines[fCount].Values[0], SizeOf(aValues[0]) * fMaxLength);
  Inc(fCount);

  UpdateMaxValue;
end;


function TKMChart.GetSeparatorPos(aIndex: Integer): Integer;
begin
  Result := -1;
  if not InRange(aIndex, 0, fSeparatorPositions.Count - 1) then Exit;

  Result := StrToInt(fSeparatorPositions[aIndex]);
end;


//function TKMChart.GetSeparatorsHeight(aIndex: Integer): Integer;
//var
//  I, Pos: Integer;
//begin
//  Result := 0;
//  for I := 0 to fSeparatorPositions.Count - 1 do
//  begin
//    Pos := SeparatorPos[I];
//    if (Pos <> -1) and (Pos <= aIndex) then
//      Inc(Result, fSeparatorHeight);
//  end;
//end;


procedure TKMChart.AddSeparator(aPosition: Integer);
begin
  fSeparatorPositions.Add(IntToStr(aPosition));
end;


procedure TKMChart.SetSeparatorPositions(aSeparatorPositions: TStringList);
begin
  fSeparatorPositions.Clear;
  fSeparatorPositions.AddStrings(aSeparatorPositions);
end;


//Add alternative values line (e.g. wares count vs. wares produced)
procedure TKMChart.AddAltLine(const aAltValues: TKMCardinalArray);
begin
  Assert(Length(aAltValues) >= fMaxLength);

  SetLength(fLines[fCount-1].ValuesAlt, fMaxLength);
  if SizeOf(aAltValues) <> 0 then
    Move(aAltValues[0], fLines[fCount-1].ValuesAlt[0], SizeOf(aAltValues[0]) * fMaxLength);

  UpdateMaxValue;
end;


//Trims the graph until 5% before the first variation
procedure TKMChart.TrimToFirstVariation;
var
  I, K, firstVarSample: Integer;
  startVal: Cardinal;
begin
  firstVarSample := -1;
  for I:=0 to fCount-1 do
    if Length(fLines[I].Values) > 0 then
    begin
      startVal := fLines[I].Values[0];
      for K:=1 to Length(fLines[I].Values)-1 do
        if fLines[I].Values[K] <> startVal then
        begin
          if (K < firstVarSample) or (firstVarSample = -1) then
            firstVarSample := K - 1;
          Break;
        end;
    end;
  if firstVarSample <= 0 then
  begin
    fMinTime := 0; //No variation at all, so don't trim it (but clear previous value)
    Exit;
  end;
  //Take 5% before the first varied sample
  firstVarSample := Max(0, firstVarSample - Max(1, Round(0.05*(fMaxLength - firstVarSample))));
  //Trim all fLines[I].Values to start at FirstVarSample
  for I := 0 to fCount - 1 do
  begin
    Move(fLines[I].Values[firstVarSample], fLines[I].Values[0], (Length(fLines[I].Values)-firstVarSample)*SizeOf(fLines[I].Values[0]));
    SetLength(fLines[I].Values, Length(fLines[I].Values)-firstVarSample);
  end;
  //Set start time so the horizontal time ticks are rendered correctly
  fMinTime := Round((firstVarSample/fMaxLength) * fMaxTime);
  //All lines have now been trimmed, so update fMaxLength
  fMaxLength := fMaxLength - firstVarSample;
end;


procedure TKMChart.Clear;
begin
  fCount := 0;
  SetLength(fLines, 0);
  fMaxValue := 0;
  ClearSeparators;
end;


procedure TKMChart.ClearSeparators;
begin
  fSeparatorPositions.Clear;
end;


procedure TKMChart.SetLineVisible(aLineID: Integer; aVisible: Boolean);
begin
  fLines[aLineID].Visible := aVisible;
  UpdateMaxValue;
end;


procedure TKMChart.UpdateMaxValue;
var
  I, K: Integer;
begin
  fMaxValue := 0;
  for I := 0 to fCount - 1 do
    if fLines[I].Visible then
      for K := 0 to fMaxLength - 1 do
        if fLines[I].Values[K] > fMaxValue then
          fMaxValue := fLines[I].Values[K];
end;


function TKMChart.GetLine(aIndex: Integer): TKMGraphLine;
begin
  Result := fLines[aIndex];
end;


function TKMChart.GetLineNumber(aY: Integer): Integer;
var
  I, S, lineTop, lineBottom: Integer;
begin
  Result := -1;
  S := 0;
  lineTop := AbsTop + 5 + 20*Byte(fLegendCaption <> '');
  for I := 0 to fCount - 1 do
  begin
    if SeparatorPos[S] = I then
    begin
      Inc(lineTop, fSeparatorHeight);
      Inc(S);
    end;
    lineBottom := lineTop + fItemHeight*(1 + Length(Lines[I].TitleDetailed));
    if InRange(aY, lineTop, lineBottom) then
    begin
      Result := I;
      Exit;
    end;
    lineTop := lineBottom;
  end;
end;


procedure TKMChart.MouseMove(X, Y: Integer; Shift: TShiftState);
begin
  inherited;

  fLineOver := -1;
  if X < AbsLeft + Width - fLegendWidth + 5 then Exit;
  fLineOver := GetLineNumber(Y);
end;


procedure TKMChart.MouseUp(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  I: Integer;
begin
  inherited;

  if X < AbsLeft + Width - fLegendWidth+5 then Exit;

  I := GetLineNumber(Y);
  if not InRange(I, 0, fCount - 1) then Exit;

  fLines[I].Visible := not fLines[I].Visible;

  UpdateMaxValue;

  if Assigned(fOnLegendClick) then
    fOnLegendClick(Self, I, fLines[I].Visible);
end;


procedure TKMChart.Paint;
const
  INTERVAL_CNT: array [0..9] of Word = (1, 5, 10, 50, 100, 500, 1000, 5000, 10000, 50000);
  INTERVAL_TIME: array [0..10] of Word = (30, 1*60, 5*60, 10*60, 15*60, 30*60, 1*60*60, 2*60*60, 3*60*60, 4*60*60, 5*60*60);

var
  G: TKMRect;
  topValue: Integer;

  procedure PaintAxisLabel(aTime: Integer; aIsPT: Boolean = False);
  var
    xPos: Integer;
  begin
    xPos := G.Left + Round((aTime - fMinTime) / (fMaxTime-fMinTime) * (G.Right - G.Left));
    TKMRenderUI.WriteShape(xPos, G.Bottom - 2, 2, 5, IfThen(aIsPT, clChartPeacetimeLn, icWhite));
    TKMRenderUI.WriteText (xPos, G.Bottom + 4, 0, TimeToString(aTime / 24 / 60 / 60), fntGame, taLeft, IfThen(aIsPT, clChartPeacetimeLbl, icWhite));
    TKMRenderUI.WriteLine(xPos, G.Top, xPos, G.Bottom, IfThen(aIsPT, clChartPeacetimeLn, clChartDashedVLn), $CCCC);
    if aIsPT then
      TKMRenderUI.WriteText(xPos - 3, G.Bottom + 4, 0, gResTexts[TX_CHART_PT_END], fntGame, taRight, clChartPeacetimeLbl);
  end;

  procedure RenderHorizontalAxisTicks;
  var
    I, best: Integer;
  begin
    //Find first time interval that will have less than 10 ticks
    best := 0;
    for I := Low(INTERVAL_TIME) to High(INTERVAL_TIME) do
      if (fMaxTime-fMinTime) div INTERVAL_TIME[I] < 7 then
      begin
        best := INTERVAL_TIME[I];
        Break;
      end;

    //Paint time axis labels
    if (best <> 0) and (fMaxTime <> fMinTime) then
      if (fPeaceTime <> 0) and InRange(fPeaceTime, fMinTime, fMaxTime) then
      begin
        //Labels before PT and PT himself
        for I := 0 to ((fPeaceTime - fMinTime) div best) do
          PaintAxisLabel(fPeaceTime - I * best, I = 0);

        //Labels after PT
        for I := 1 to ((fMaxTime - fPeaceTime) div best) do
          PaintAxisLabel(fPeaceTime + I * best);
      end else
        for I := Ceil(fMinTime / best) to (fMaxTime div best) do
          PaintAxisLabel(I * best);
  end;

  function GetLineColor(aColor: Cardinal): Cardinal;
  begin
    //Adjust the color if it blends with black background
    Result := EnsureBrightness(aColor, 0.3);

    // If color is similar to highlight color, then use alternative HL color
    if GetColorDistance(Result, clChartHighlight) < 0.1 then
      Result := clChartHighlight2;
  end;

  procedure RenderChartAndLegend;
  const
    MARKS_FONT: TKMFont = fntGrey;
  var
    I, J, S, checkSize, xPos, yPos, height: Integer;
    titleDetailedH: Integer;
    newColor: TColor4;
  begin
    checkSize := gRes.Fonts[MARKS_FONT].GetTextSize('v').Y + 1;
    S := 0;
    xPos := G.Right + 10;
    yPos := G.Top + 8 + 20*Byte(fLegendCaption <> '');

    titleDetailedH := 0;
    //Charts and legend
    for I := 0 to fCount - 1 do
    begin
      newColor := GetLineColor(fLines[I].Color);

      if (csOver in State) and (I = fLineOver) then
        newColor := clChartHighlight;

      //Charts
      if fLines[I].Visible then
      begin
        TKMRenderUI.WritePlot(G.Left, G.Top, G.Right-G.Left, G.Bottom-G.Top, fLines[I].Values, topValue, newColor, 2);
        if Length(fLines[I].ValuesAlt) > 0 then
          TKMRenderUI.WritePlot(G.Left, G.Top, G.Right-G.Left, G.Bottom-G.Top, fLines[I].ValuesAlt, topValue, newColor, 1);
      end;

      if SeparatorPos[S] = I then
      begin
        Inc(yPos, fSeparatorHeight);
        Inc(S);
      end;

      //Checkboxes
      TKMRenderUI.WriteBevel(xPos, yPos, checkSize - 4, checkSize - 4, 1, 0.3);
      TKMRenderUI.WriteOutline(xPos, yPos, checkSize - 4, checkSize - 4, 1, clChkboxOutline);
      if fLines[I].Visible then
        TKMRenderUI.WriteText(xPos + (checkSize-4) div 2, yPos - 1, 0, 'v', MARKS_FONT, taCenter, newColor);

      //Legend
      TKMRenderUI.WriteText(xPos + checkSize, yPos, 0, fLines[I].Title, fntGame, taLeft, newColor);
      Inc(yPos, fItemHeight);

      //Detailed legend
      for J := Low(fLines[I].TitleDetailed) to High(fLines[I].TitleDetailed) do
      begin
        TKMRenderUI.WriteText(xPos + checkSize + 5, yPos, 0, fLines[I].TitleDetailed[J], fntGrey, taLeft, GetLineColor(fLines[I].TitleDetailedColor[J]));
        Inc(yPos, fItemHeight);
        Inc(titleDetailedH, fItemHeight);
      end;
    end;

    //Legend title and outline
    height := fItemHeight*fCount + titleDetailedH + 6 + 20*Byte(fLegendCaption <> '') + fSeparatorPositions.Count*fSeparatorHeight;
    TKMRenderUI.WriteShape(G.Right + 5, G.Top, fLegendWidth, height, icDarkestGrayTrans);
    TKMRenderUI.WriteOutline(G.Right + 5, G.Top, fLegendWidth, height, 1, icGray);
    if fLegendCaption <> '' then
      TKMRenderUI.WriteText(G.Right + 5, G.Top + 4, fLegendWidth, fLegendCaption, fntMetal, taCenter, icWhite);
  end;

var
  I: Integer;
  best, tmp: Integer;
begin
  inherited;

  G := KMRect(AbsLeft + 40, AbsTop, AbsLeft + Width - fLegendWidth, AbsTop + Height - 20);

  //Add margin to MaxValue so that it does not blends with upper border
  topValue := Max(Round(fMaxValue * 1.1), fMaxValue + 1);

  //Find first interval that will have less than 10 ticks
  best := 0;
  for I := Low(INTERVAL_CNT) to High(INTERVAL_CNT) do
    if topValue div INTERVAL_CNT[I] < 10 then
    begin
      best := INTERVAL_CNT[I];
      Break;
    end;

  //Dashed lines in the background
  if best <> 0 then
    for I := 1 to (topValue div best) do
    begin
      tmp := G.Top + Round((1 - I * best / topValue) * (G.Bottom - G.Top));
      TKMRenderUI.WriteText(G.Left - 5, tmp - 6, 0, IntToStr(I * best), fntGame, taRight);
      TKMRenderUI.WriteLine(G.Left, tmp, G.Right, tmp, clChartDashedHLn, $CCCC);
    end;

  //Render horizontal axis ticks
  RenderHorizontalAxisTicks;

  RenderChartAndLegend;

  //Render the highlighted line above all the others and thicker so you can see where it goes under others
  if (csOver in State) and InRange(fLineOver, 0, fCount-1) and fLines[fLineOver].Visible then
    TKMRenderUI.WritePlot(G.Left, G.Top, G.Right-G.Left, G.Bottom-G.Top, fLines[fLineOver].Values, topValue, clChartHighlight, 3);

  //Outline
  TKMRenderUI.WriteOutline(G.Left, G.Top, G.Right-G.Left, G.Bottom-G.Top, 1, icWhite);

  //Title
  TKMRenderUI.WriteText(G.Left + 5, G.Top + 5, 0, fCaption, fFont, taLeft);

  //Render vertical axis captions
  TKMRenderUI.WriteText(G.Left - 5, G.Bottom - 6, 0, IntToStr(0), fntGame, taRight);
  //TKMRenderUI.WriteText(Left+20, Top + 20, 0, 0, IntToStr(fMaxValue), fntGame, taRight);

end;


end.


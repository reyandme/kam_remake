unit KM_ControlsProgressBar;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections,
  KromOGLUtils,
  Classes, Controls,
  KM_Controls,
  KM_RenderUI,
  KM_ResFonts,
  KM_Points,
  KM_CommonTypes;


type
  // Abstract Progress bar
  TKMProgressBarAbstract = class abstract(TKMControl)
  private
    fFont: TKMFont;
    fTextAlign: TKMTextAlign;
  protected
    procedure PaintBar; virtual; abstract;
  public
    //CaptionLeft and CaptionRight are shown to the left and right from main Caption. Use them only with taCenter
    Caption, CaptionLeft, CaptionRight: UnicodeString;
    FontColor: TColor4;
    TextYOffset: Integer;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont = fntMini);
    procedure SetCaptions(const aCaptionLeft, aCaption, aCaptionRight: UnicodeString);
    procedure Paint; override;
  end;


  {Percent bar}
  TKMPercentBar = class(TKMProgressBarAbstract)
  private
    fPosition: Single;
    fSeam: Single;
    fMainColor: Cardinal;
    fAddColor: Cardinal;
    procedure SetPosition(aValue: Single);
    procedure SetSeam(aValue: Single);
  protected
    procedure PaintBar; override;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont = fntMini);
    property Seam: Single read fSeam write SetSeam;
    property Position: Single read fPosition write SetPosition;
    property MainColor: Cardinal read fMainColor write fMainColor;
    property AddColor: Cardinal read fAddColor write fAddColor;
  end;


  TKMReplayBar = class(TKMPercentBar)
  private
    fIsDirty: Boolean; //True is Marks are not not sorted yet
    fPosition: Integer;
    fPeacetime: Integer;
    fMaxValue: Integer;
    fHighlightMark: Integer;
    fMarks: TList<Integer>;
    fMarksPattern: Word;
    fOnMarkClick: TIntegerEvent;
    fHintResText: Word;
    procedure TrySortMarks;
    procedure SetPosition(aValue: Integer);
    procedure SetPeacetime(aValue: Integer);
    procedure SetMaxValue(aValue: Integer);
  protected
    procedure ControlMouseMove(Sender: TObject; X, Y: Integer; Shift: TShiftState);
    procedure PaintBar; override;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont = fntMini); overload;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight, aPosition, aPeacetime, aMaxValue: Integer; aFont: TKMFont = fntMini); overload;
    destructor Destroy; override;

    property Position: Integer read fPosition;
    property Peacetime: Integer read fPeacetime;
    property MaxValue: Integer read fMaxValue write SetMaxValue;

    procedure SetParameters(aPosition, aPeacetime, aMaxValue: Integer);
    property MarksPattern: Word read fMarksPattern write fMarksPattern;
    property HintResText: Word read fHintResText write fHintResText;
//    property Marks: TList<Integer> read GetMarks;

    procedure AddMark(aMark: Integer);
    procedure Clear;

    property OnMarkClick: TIntegerEvent read fOnMarkClick write fOnMarkClick;

    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure MouseUp  (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
  end;


implementation
uses
  SysUtils,
  Math,
  KM_Resource, KM_ResTexts,
  KM_Defaults,
  KM_CommonUtils;


{ TKMProgressBarAbstract }
constructor TKMProgressBarAbstract.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont = fntMini);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);
  fFont := aFont;
  FontColor := $FFFFFFFF;
  fTextAlign := taCenter;
end;


procedure TKMProgressBarAbstract.SetCaptions(const aCaptionLeft, aCaption, aCaptionRight: UnicodeString);
begin
  CaptionLeft := aCaptionLeft;
  Caption := aCaption;
  CaptionRight := aCaptionRight;
end;


procedure TKMProgressBarAbstract.Paint;
var
  captionSize: TKMPoint;
begin
  inherited;

  PaintBar;

  //Now draw text over the bar, if it is required
  if Caption <> '' then
  begin
    //Shadow
    TKMRenderUI.WriteText(AbsLeft + 2, (AbsTop + Height div 2)+TextYOffset-4,
                          Width-4, Caption, fFont, fTextAlign, $FF000000);
    //Text
    TKMRenderUI.WriteText(AbsLeft + 1, (AbsTop + Height div 2)+TextYOffset-5,
                          Width-4, Caption, fFont, fTextAlign, FontColor);
  end;

  if (CaptionLeft <> '') or (CaptionRight <> '') then
    captionSize := gRes.Fonts[fFont].GetTextSize(Caption);

  if CaptionLeft <> '' then
  begin
    //Shadow
    TKMRenderUI.WriteText(AbsLeft + 2, (AbsTop + Height div 2)+TextYOffset-4,
                         (Width-4 - captionSize.X) div 2, CaptionLeft, fFont, taRight, $FF000000);
    //Text
    TKMRenderUI.WriteText(AbsLeft + 1, (AbsTop + Height div 2)+TextYOffset-5,
                         (Width-4 - captionSize.X) div 2, CaptionLeft, fFont, taRight, FontColor);
  end;

  if CaptionRight <> '' then
  begin
    //Shadow
    TKMRenderUI.WriteText(AbsLeft + 2 + ((Width-4 + captionSize.X) div 2), (AbsTop + Height div 2)+TextYOffset-4,
                         (Width-4 - captionSize.X) div 2, CaptionRight, fFont, taLeft, $FF000000);
    //Text
    TKMRenderUI.WriteText(AbsLeft + 1 + ((Width-4 + captionSize.X) div 2), (AbsTop + Height div 2)+TextYOffset-5,
                         (Width-4 - captionSize.X) div 2, CaptionRight, fFont, taLeft, FontColor);
  end;
end;


{ TKMPercentBar }
constructor TKMPercentBar.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont = fntMini);
begin
  inherited;

  fMainColor := icBarColorGreen;
  fAddColor := icBarColorBlue;
end;


procedure TKMPercentBar.SetPosition(aValue: Single);
begin
  fPosition := EnsureRange(aValue, 0, 1);
end;


procedure TKMPercentBar.SetSeam(aValue: Single);
begin
  fSeam := EnsureRange(aValue, 0, 1);
end;


procedure TKMPercentBar.PaintBar;
begin
  TKMRenderUI.WritePercentBar(AbsLeft, AbsTop, Width, Height, fPosition, fSeam, fMainColor, fAddColor);
end;


{ TKMReplayBar }
constructor TKMReplayBar.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont = fntMini);
begin
  Create(aParent, aLeft, aTop, aWidth, aHeight, 0, MaxInt, MaxInt, aFont);
end;


constructor TKMReplayBar.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight, aPosition, aPeacetime, aMaxValue: Integer;
                                aFont: TKMFont = fntMini);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight, aFont);

  SetParameters(aPosition, aPeacetime, aMaxValue);
  fMarksPattern := $CF3; //Looks good for 25px height bar

  fHighlightMark := -1;

  fMarks := TList<Integer>.Create;

  aParent.MasterControl.SubscribeOnOtherMouseMove(ControlMouseMove);
end;


destructor TKMReplayBar.Destroy;
begin
  FreeAndNil(fMarks);

  inherited;
end;


procedure TKMReplayBar.SetParameters(aPosition, aPeacetime, aMaxValue: Integer);
begin
  //Apply setters
  MaxValue := aMaxValue; //Should be first, since we restrict Position and PT with MaxValue
  SetPosition(aPosition);
  SetPeacetime(aPeacetime);
end;


procedure TKMReplayBar.AddMark(aMark: Integer);
begin
  if Self = nil then Exit;

  Assert(fMarks <> nil, 'Marks is not initilized');

  fMarks.Add(aMark);
  fIsDirty := True;
end;


procedure TKMReplayBar.SetPosition(aValue: Integer);
begin
  fPosition := EnsureRange(aValue, 0, fMaxValue);
//  Caption := IntToStr(fPosition);
end;


procedure TKMReplayBar.SetPeacetime(aValue: Integer);
begin
  fPeacetime := EnsureRange(aValue, 0, MaxInt);
end;


procedure TKMReplayBar.SetMaxValue(aValue: Integer);
begin
  fMaxValue := EnsureRange(aValue, 1, MaxInt);
end;


procedure TKMReplayBar.MouseMove(X,Y: Integer; Shift: TShiftState);
const
  MAX_DIST_PERCENT = 0.02;
var
  pos, bestDist, dist: Integer;
  mark, bestMark: Integer;
begin
  inherited;
  pos := Round((X - AbsLeft) / Width * MaxValue);

  bestDist := MaxInt;
  bestMark := -1;

  TrySortMarks;
  for mark in fMarks do
  begin
    dist := Abs(pos - mark);
    if dist < MAX_DIST_PERCENT*fMaxValue then
    begin
      if dist < bestDist then
      begin
        bestDist := dist;
        bestMark := mark;
      end else
        Break; //List is sorted, we have found what we need
    end;
  end;

  fHighlightMark := bestMark;

  if fHighlightMark <> -1 then
  begin
    Hint := Format(gResTexts[fHintResText], [TickToTimeStr(fHighlightMark)]);
//    Caption := IntToStr(fPosition) + ' (' + IntToStr(fHighlightMark) + ')';
  end
  else
  begin
    Hint := '';
//    Caption := IntToStr(fPosition);
  end;
end;


procedure TKMReplayBar.MouseUp(X: Integer; Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  if (fHighlightMark <> -1) and Assigned(fOnMarkClick) then
    fOnMarkClick(fHighlightMark);
end;


procedure TKMReplayBar.TrySortMarks;
begin
  if fIsDirty then
  begin
    fIsDirty := False;
    fMarks.Sort;
  end;
end;


procedure TKMReplayBar.PaintBar;
begin
  inherited;
  TKMRenderUI.WriteReplayBar(AbsLeft, AbsTop, Width, Height, fPosition, fPeacetime, fMaxValue, fMarks, MarksPattern, fHighlightMark);
end;


procedure TKMReplayBar.Clear;
begin
  fMarks.Clear;
end;


procedure TKMReplayBar.ControlMouseMove(Sender: TObject; X, Y: Integer; Shift: TShiftState);
begin
  inherited;
  if not InRange(X, AbsLeft, AbsRight)
    or not InRange(Y, AbsTop, AbsBottom) then
    fHighlightMark := -1;
end;


end.


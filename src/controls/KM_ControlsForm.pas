unit KM_ControlsForm;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_Controls, KM_ControlsBase,
  KM_CommonTypes, KM_Points, KM_ResFonts;


type
  TKMFormBackgroundType = (
    fbGray,   // Dark grey scroll with big header roll
    fbYellow, // Yellow scroll without header roll
    fbScroll  // Yellow scroll with small header roll
  );

  TKMForm = class(TKMPanel)
  const
    DEFAULT_CAPTION_FONT = fntOutline;
  private
    fDragging: Boolean;
    fDragStartPos: TKMPoint;
    fBackground: TKMFormBackgroundType;
    fHandleCloseKey: Boolean;
    fCapOffsetY: Integer;

    fOnClose: TKMEvent;
    procedure UpdateSizes;
    procedure Close(Sender: TObject);

    procedure HandleOtherControlMouseMove(Sender: TObject; X,Y: Integer; Shift: TShiftState);
    procedure HandleOtherControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    procedure HandleOtherControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);

    function MarginMainLeftRight: Integer;
    function MarginMainTop: Integer;
    function MarginMainBottom: Integer;
    function MarginCrossTop: Integer;
    function MarginCrossRight: Integer;

    function GetActualWidth: Integer;
    procedure SetActualWidth(aValue: Integer);
    function GetActualHeight: Integer;
    procedure SetActualHeight(aValue: Integer);

    procedure SetHandleCloseKey(aValue: Boolean);
    procedure SetCapOffsetY(aValue: Integer);
    function GetCaption: string;
    procedure SetCaption(const aValue: string);
  protected
    Bevel_Contents: TKMBevel;
    Bevel_ModalBackground: TKMBevel;
    Image_Background, Image_Close: TKMImage;
    Label_Caption: TKMLabel;
    procedure SetWidth(aValue: Integer); override;
    procedure SetHeight(aValue: Integer); override;
  public
    ItemsPanel: TKMPanel;
    DragEnabled: Boolean;

    constructor Create(aParent: TKMPanel; aContentWidth, aContentHeight: Integer; const aCaption: UnicodeString = '';
                       aBackground: TKMFormBackgroundType = fbYellow; aCloseIcon: Boolean = False;
                       aBevelForContents: Boolean = True; aModalBackground: Boolean = True);

    procedure MouseDown (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseMove (X,Y: Integer; Shift: TShiftState); override;
    procedure MouseUp   (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;

    function KeyUp(Key: Word; Shift: TShiftState): Boolean; override;

    property OnClose: TKMEvent read fOnClose write fOnClose;

    property ActualHeight: Integer read GetActualHeight write SetActualHeight;
    property ActualWidth: Integer read GetActualWidth write SetActualWidth;
    property CapOffsetY: Integer read fCapOffsetY write SetCapOffsetY;
    property Caption: string read GetCaption write SetCaption;

    property HandleCloseKey: Boolean read fHandleCloseKey write SetHandleCloseKey;
  end;


implementation
uses
  Math,
  KM_RenderUI,
  KM_ResTexts, KM_ResKeys, KM_ResTypes;


{ TKMForm }
constructor TKMForm.Create(aParent: TKMPanel; aContentWidth, aContentHeight: Integer; const aCaption: UnicodeString = '';
                                 aBackground: TKMFormBackgroundType = fbYellow; aCloseIcon: Boolean = False;
                                 aBevelForContents: Boolean = True; aModalBackground: Boolean = True);
begin
  fBackground := aBackground;

  var desiredWidth := aContentWidth + 2 * MarginMainLeftRight;
  var desiredHeight := aContentHeight + MarginMainBottom + MarginMainTop;
  var allowedWidth := Min(aParent.Width, desiredWidth);
  var allowedHeight := Min(aParent.Height, desiredHeight);
  var desiredLeft := Max(0, (aParent.Width - allowedWidth) div 2);
  var desiredTop := Max(0, (aParent.Height - allowedHeight) div 2);

  // Create panel with calculated sizes
  inherited Create(aParent, desiredLeft, desiredTop, allowedWidth, allowedHeight);

  // Fix its base sizes as a desired one
  BaseWidth := desiredWidth;
  BaseHeight := desiredHeight;

  FitInParent := True;
  DragEnabled := False;
  fHandleCloseKey := False;
  fCapOffsetY := 0;

  if aModalBackground then
    Bevel_ModalBackground := TKMBevel.Create(Self, -5000, -5000, 10000, 10000);

  Image_Background := TKMImage.Create(Self, 0, 0, allowedWidth, allowedHeight, 15, rxGuiMain);

  ItemsPanel := TKMPanel.Create(Self, MarginMainLeftRight, MarginMainTop, Width - 2*MarginMainLeftRight, Height - MarginMainTop - MarginMainBottom);

  case fBackground of
    fbGray:   Image_Background.TexId := 15;
    fbYellow: Image_Background.TexId := 18;
    fbScroll: begin
                Image_Background.Rx := rxGui;
                Image_Background.TexId := 409;
              end;
  end;

  if aCloseIcon then
  begin
    Image_Close := TKMImage.Create(Self, Width - MarginCrossRight, MarginCrossTop, 31, 30, 52);
    Image_Close.Anchors := [anTop, anRight];
    Image_Close.Hint := gResTexts[TX_MSG_CLOSE_HINT];
    Image_Close.OnClick := Close;
    Image_Close.HighlightOnMouseOver := True;
  end;

  ItemsPanel.AnchorsStretch;
  if aBevelForContents then
  begin
    Bevel_Contents := TKMBevel.Create(ItemsPanel, 0, 0, ItemsPanel.Width, ItemsPanel.Height);
    Bevel_Contents.AnchorsStretch;
  end;

  Image_Background.ImageStretch;

  Label_Caption := TKMLabel.Create(ItemsPanel, 0, -25, ItemsPanel.Width, 20, aCaption, DEFAULT_CAPTION_FONT, taCenter);

  AnchorsCenter;
  Hide;

  fMasterControl.SubscribeOnOtherMouseMove(HandleOtherControlMouseMove);
  fMasterControl.SubscribeOnOtherMouseDown(HandleOtherControlMouseDown);
  fMasterControl.SubscribeOnOtherMouseUp(HandleOtherControlMouseUp);
end;


function TKMForm.MarginMainLeftRight: Integer;
const
  MARGIN_SIDE: array [TKMFormBackgroundType] of Byte = (20, 35, 20);
begin
  Result := MARGIN_SIDE[fBackground];
end;


function TKMForm.MarginMainTop: Integer;
const
  MARGIN_TOP: array [TKMFormBackgroundType] of Byte = (40, 80, 50);
begin
  Result := MARGIN_TOP[fBackground];
end;


function TKMForm.MarginMainBottom: Integer;
const
  MARGIN_BOTTOM: array [TKMFormBackgroundType] of Byte = (20, 50, 20);
begin
  Result := MARGIN_BOTTOM[fBackground];
end;


function TKMForm.MarginCrossTop: Integer;
const
  CROSS_TOP: array [TKMFormBackgroundType] of Byte = (24, 40, 24);
begin
  Result := CROSS_TOP[fBackground];
end;


function TKMForm.MarginCrossRight: Integer;
const
  // Margin from right side, depends on bg graphics
  CROSS_RIGHT: array [TKMFormBackgroundType] of Byte = (50, 130, 55);
begin
  Result := CROSS_RIGHT[fBackground];
end;


function TKMForm.GetCaption: string;
begin
  Result := Label_Caption.Caption;
end;


procedure TKMForm.Close(Sender: TObject);
begin
  Hide;

  if Assigned(fOnClose) then
    fOnClose;
end;


procedure TKMForm.HandleOtherControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  if Sender = Image_Background then
    MouseDown(X, Y, Shift, Button);
end;


procedure TKMForm.HandleOtherControlMouseMove(Sender: TObject; X, Y: Integer; Shift: TShiftState);
begin
  inherited;

  MouseMove(X, Y, Shift);
end;


procedure TKMForm.HandleOtherControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  MouseUp(X, Y, Shift, Button);
end;


procedure TKMForm.MouseDown(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  if not DragEnabled then Exit;

  fDragging := True;
  fDragStartPos := TKMPoint.New(X,Y);
end;

procedure TKMForm.MouseMove(X, Y: Integer; Shift: TShiftState);
begin
  inherited;

  if not DragEnabled or not fDragging then Exit;

  Left := EnsureRange(Left + X - fDragStartPos.X, 0, fMasterControl.MasterPanel.Width - Width);
  Top := EnsureRange(Top + Y - fDragStartPos.Y, -Image_Background.Top, fMasterControl.MasterPanel.Height - Height);

  fDragStartPos := TKMPoint.New(X,Y);
end;

procedure TKMForm.MouseUp(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  if not DragEnabled then Exit;

  fDragging := False;
end;


function TKMForm.KeyUp(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := inherited;
  if Result then Exit; // Key already handled

  if not fHandleCloseKey then Exit;

  if Key = gResKeys[kfCloseMenu] then
  begin
    Close(nil);
    Result := True;
  end;
end;


procedure TKMForm.SetHeight(aValue: Integer);
begin
  inherited;

  UpdateSizes;
end;


procedure TKMForm.SetWidth(aValue: Integer);
begin
  inherited;

  UpdateSizes;
end;


procedure TKMForm.UpdateSizes;
begin
  Image_Background.Width := Width;
  Image_Background.Height := Height;
end;


function TKMForm.GetActualWidth: Integer;
begin
  Result := ItemsPanel.Width;
end;


procedure TKMForm.SetActualWidth(aValue: Integer);
var
  baseW: Integer;
begin
  baseW := aValue + MarginMainLeftRight*2;
  SetWidth(Min(Parent.Width, baseW));
end;


function TKMForm.GetActualHeight: Integer;
begin
  Result := ItemsPanel.Height;
end;


procedure TKMForm.SetActualHeight(aValue: Integer);
var
  baseH, h: Integer;
begin
  baseH := aValue + MarginMainBottom + MarginMainTop;
  h := Min(Parent.Height, baseH);
  SetHeight(h);
end;


procedure TKMForm.SetHandleCloseKey(aValue: Boolean);
begin
  fHandleCloseKey := aValue;
  Focusable := aValue;
end;


procedure TKMForm.SetCapOffsetY(aValue: Integer);
begin
  Label_Caption.Top := Label_Caption.Top + aValue - fCapOffsetY;

  fCapOffsetY := aValue;
end;


procedure TKMForm.SetCaption(const aValue: string);
begin
  Label_Caption.Caption := aValue;
end;


end.


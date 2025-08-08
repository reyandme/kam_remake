unit KM_ControlsPopUp;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_Controls, KM_ControlsBase, KM_ControlsList,
  KM_CommonTypes, KM_Points,
  KM_ResFonts;


type
  TKMPopUpMenuMode = (
    pmmActionOnMouseDownNMove, // Action triggered by mouse down and mouse move (drag)
    pmmActionOnMouseUp         // Action triggered only by mouse up
  );

const
  DEFAULT_POPUP_MENU_MODE = pmmActionOnMouseUp;

type
  // Popup with a short list (context menu)
  // For bigger taks - use TKMPopUpPanel!
  TKMPopUpMenu = class(TKMPanel)
  private
    fMenuMode: TKMPopUpMenuMode;
    procedure MenuHide(Sender: TObject);
    procedure MenuActionTriggered(Sender: TObject);
    procedure HandleOtherControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    procedure SetItemIndex(aValue: Integer);
    function GetItemIndex: Integer;
    function GetItemTag(aIndex: Integer): Integer;
  protected
    Shape_Background: TKMShape;
    ColumnBox_List: TKMColumnBox;
  public
    constructor Create(aParent: TKMPanel; aWidth: Integer; aMenuMode: TKMPopUpMenuMode = DEFAULT_POPUP_MENU_MODE);
    procedure AddItem(const aCaption: UnicodeString; aTag: Integer = 0);
    procedure UpdateItem(aIndex: Integer; const aCaption: UnicodeString);
    procedure Clear;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property ItemTags[aIndex: Integer]: Integer read GetItemTag;
    procedure ShowAt(X,Y: Integer);
    procedure HideMenu;

    property MenuMode: TKMPopUpMenuMode read fMenuMode;

    procedure MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
  end;

  TKMPopUpBGImageType = (
    pbGray,   // Dark grey scroll with big header roll
    pbYellow, // Yellow scroll without header roll
    pbScroll  // Yellow scroll with small header roll
  );

  TKMPopUpPanel = class(TKMPanel)
  const
    DEFAULT_CAPTION_FONT = fntOutline;
  private
    fDragging: Boolean;
    fDragStartPos: TKMPoint;
    fBGImageType: TKMPopUpBGImageType;
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

    constructor Create(aParent: TKMPanel; aWidth, aHeight: Integer; const aCaption: UnicodeString = '';
                       aImageType: TKMPopUpBGImageType = pbYellow; aCloseIcon: Boolean = False;
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


  //Form that can be dragged around (and resized?)
//  TKMForm = class(TKMPanel)
//  private
//    fHeaderHeight: Integer;
//    fButtonClose: TKMButtonFlat;
//    fLabelCaption: TKMLabel;
//
//    fDragging: Boolean;
//    fOffsetX: Integer;
//    fOffsetY: Integer;
//    function HitHeader(X, Y: Integer): Boolean;
//    procedure FormCloseClick(Sender: TObject);
//    function GetCaption: UnicodeString;
//    procedure SetCaption(const aValue: UnicodeString);
//  public
//    OnMove: TNotifyEvent;
//    OnClose: TNotifyEvent;
//
//    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
//    property Caption: UnicodeString read GetCaption write SetCaption;
//    procedure MouseDown (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
//    procedure MouseMove (X,Y: Integer; Shift: TShiftState); override;
//    procedure MouseUp   (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
//    procedure PaintPanel(aPaintLayer: TKMPaintLayer); override;
//  end;


implementation
uses
  Math,
  KM_RenderUI,
  KM_ResTexts, KM_ResKeys, KM_ResTypes,
  KM_Defaults;


{ TKMPopUpMenu }
constructor TKMPopUpMenu.Create(aParent: TKMPanel; aWidth: Integer; aMenuMode: TKMPopUpMenuMode = DEFAULT_POPUP_MENU_MODE);
begin
  inherited Create(aParent, 0, 0, aWidth, 0);

  fMenuMode := aMenuMode;

  // Note that Shape belongs to us, but we will manually position it to align with Parent to cover it
  Shape_Background := TKMShape.Create(Self, 0, 0, aParent.Width, aParent.Height);
  Shape_Background.OnClick := MenuHide;

  ColumnBox_List := TKMColumnBox.Create(Self, 0, 0, aWidth, 0, fntGrey, bsMenu);
  ColumnBox_List.AnchorsStretch;
  ColumnBox_List.BackAlpha := 0.8;
  ColumnBox_List.Focusable := False;
  ColumnBox_List.SetColumns(fntGrey, [''], [0]);
  ColumnBox_List.ShowHeader := False;

  case fMenuMode of
    pmmActionOnMouseDownNMove: ColumnBox_List.OnChange := MenuActionTriggered;
    pmmActionOnMouseUp:        ColumnBox_List.OnClick  := MenuActionTriggered;
  end;

  fMasterControl.SubscribeOnOtherMouseUp(HandleOtherControlMouseUp);

  Hide;
end;


procedure TKMPopUpMenu.Clear;
begin
  ColumnBox_List.Clear;
end;


function TKMPopUpMenu.GetItemIndex: Integer;
begin
  Result := ColumnBox_List.ItemIndex;
end;


function TKMPopUpMenu.GetItemTag(aIndex: Integer): Integer;
begin
  Result := ColumnBox_List.Rows[aIndex].Tag;
end;


procedure TKMPopUpMenu.SetItemIndex(aValue: Integer);
begin
  ColumnBox_List.ItemIndex := aValue;
end;


procedure TKMPopUpMenu.AddItem(const aCaption: UnicodeString; aTag: Integer = 0);
begin
  ColumnBox_List.AddItem(MakeListRow([aCaption], aTag));

  // Set own height (and anchored List will follow)
  Height := ColumnBox_List.ItemHeight * ColumnBox_List.RowCount;
end;


procedure TKMPopUpMenu.UpdateItem(aIndex: Integer; const aCaption: UnicodeString);
begin
  ColumnBox_List.Rows[aIndex].Cells[0].Caption := aCaption;
end;


procedure TKMPopUpMenu.MenuActionTriggered(Sender: TObject);
begin
  if Assigned(OnClick) then
    OnClick(Self);

  if fMenuMode = pmmActionOnMouseUp then
    HideMenu;
end;


procedure TKMPopUpMenu.MenuHide(Sender: TObject);
begin
  Hide;
end;


procedure TKMPopUpMenu.HideMenu;
begin
  MenuHide(nil);
end;


procedure TKMPopUpMenu.ShowAt(X, Y: Integer);
begin
  // Position self (and List will follow)
  AbsLeft := X;
  AbsTop := Y;

  // Actualize modal background position
  Shape_Background.AbsLeft := Parent.AbsLeft;
  Shape_Background.AbsTop := Parent.AbsTop;

  // Reset previously selected item
  ColumnBox_List.ItemIndex := -1;

  Show;
end;


procedure TKMPopUpMenu.HandleOtherControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  MouseUp(X, Y, Shift, Button);
end;


procedure TKMPopUpMenu.MouseUp(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  Hide;
end;


{ TKMPopUpPanel }
// aWidth / aHeight represents not TKMPopUpPanel sizes, but its internal panel: ItemsPanel
// PopUpPanel draw bigger image behind it
constructor TKMPopUpPanel.Create(aParent: TKMPanel; aWidth, aHeight: Integer; const aCaption: UnicodeString = '';
                                 aImageType: TKMPopUpBGImageType = pbYellow; aCloseIcon: Boolean = False;
                                 aBevelForContents: Boolean = True; aModalBackground: Boolean = True);
begin
  fBGImageType := aImageType;

  var desiredWidth := aWidth + 2 * MarginMainLeftRight;
  var desiredHeight := aHeight + MarginMainBottom + MarginMainTop;
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

  case fBGImageType of
    pbGray:   Image_Background.TexId := 15;
    pbYellow: Image_Background.TexId := 18;
    pbScroll: begin
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


function TKMPopUpPanel.MarginMainLeftRight: Integer;
const
  MARGIN_SIDE: array [TKMPopUpBGImageType] of Byte = (20, 35, 20);
begin
  Result := MARGIN_SIDE[fBGImageType];
end;


function TKMPopUpPanel.MarginMainTop: Integer;
const
  MARGIN_TOP: array [TKMPopUpBGImageType] of Byte = (40, 80, 50);
begin
  Result := MARGIN_TOP[fBGImageType];
end;


function TKMPopUpPanel.MarginMainBottom: Integer;
const
  MARGIN_BOTTOM: array [TKMPopUpBGImageType] of Byte = (20, 50, 20);
begin
  Result := MARGIN_BOTTOM[fBGImageType];
end;


function TKMPopUpPanel.MarginCrossTop: Integer;
const
  CROSS_TOP: array [TKMPopUpBGImageType] of Byte = (24, 40, 24);
begin
  Result := CROSS_TOP[fBGImageType];
end;


function TKMPopUpPanel.MarginCrossRight: Integer;
const
  // Margin from right side, depends on bg graphics
  CROSS_RIGHT: array [TKMPopUpBGImageType] of Byte = (50, 130, 55);
begin
  Result := CROSS_RIGHT[fBGImageType];
end;


function TKMPopUpPanel.GetCaption: string;
begin
  Result := Label_Caption.Caption;
end;


procedure TKMPopUpPanel.Close(Sender: TObject);
begin
  Hide;

  if Assigned(fOnClose) then
    fOnClose;
end;


procedure TKMPopUpPanel.HandleOtherControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  if Sender = Image_Background then
    MouseDown(X, Y, Shift, Button);
end;


procedure TKMPopUpPanel.HandleOtherControlMouseMove(Sender: TObject; X, Y: Integer; Shift: TShiftState);
begin
  inherited;

  MouseMove(X, Y, Shift);
end;


procedure TKMPopUpPanel.HandleOtherControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  MouseUp(X, Y, Shift, Button);
end;


procedure TKMPopUpPanel.MouseDown(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  if not DragEnabled then Exit;

  fDragging := True;
  fDragStartPos := TKMPoint.New(X,Y);
end;

procedure TKMPopUpPanel.MouseMove(X, Y: Integer; Shift: TShiftState);
begin
  inherited;

  if not DragEnabled or not fDragging then Exit;

  Left := EnsureRange(Left + X - fDragStartPos.X, 0, fMasterControl.MasterPanel.Width - Width);
  Top := EnsureRange(Top + Y - fDragStartPos.Y, -Image_Background.Top, fMasterControl.MasterPanel.Height - Height);

  fDragStartPos := TKMPoint.New(X,Y);
end;

procedure TKMPopUpPanel.MouseUp(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;

  if not DragEnabled then Exit;

  fDragging := False;
end;


function TKMPopUpPanel.KeyUp(Key: Word; Shift: TShiftState): Boolean;
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


procedure TKMPopUpPanel.SetHeight(aValue: Integer);
begin
  inherited;

  UpdateSizes;
end;


procedure TKMPopUpPanel.SetWidth(aValue: Integer);
begin
  inherited;

  UpdateSizes;
end;


procedure TKMPopUpPanel.UpdateSizes;
begin
  Image_Background.Width := Width;
  Image_Background.Height := Height;
end;


function TKMPopUpPanel.GetActualWidth: Integer;
begin
  Result := ItemsPanel.Width;
end;


procedure TKMPopUpPanel.SetActualWidth(aValue: Integer);
var
  baseW: Integer;
begin
  baseW := aValue + MarginMainLeftRight*2;
  SetWidth(Min(Parent.Width, baseW));
end;


function TKMPopUpPanel.GetActualHeight: Integer;
begin
  Result := ItemsPanel.Height;
end;


procedure TKMPopUpPanel.SetActualHeight(aValue: Integer);
var
  baseH, h: Integer;
begin
  baseH := aValue + MarginMainBottom + MarginMainTop;
  h := Min(Parent.Height, baseH);
  SetHeight(h);
end;


procedure TKMPopUpPanel.SetHandleCloseKey(aValue: Boolean);
begin
  fHandleCloseKey := aValue;
  Focusable := aValue;
end;


procedure TKMPopUpPanel.SetCapOffsetY(aValue: Integer);
begin
  Label_Caption.Top := Label_Caption.Top + aValue - fCapOffsetY;

  fCapOffsetY := aValue;
end;


procedure TKMPopUpPanel.SetCaption(const aValue: string);
begin
  Label_Caption.Caption := aValue;
end;


{ TKMForm }
//constructor TKMForm.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
//begin
//  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);
//
//  fHeaderHeight := 24;
//
//  fButtonClose := TKMButtonFlat.Create(Self, aWidth - fHeaderHeight + 2, 2, fHeaderHeight-4, fHeaderHeight-4, 340, rxGui);
//  fButtonClose.OnClick := FormCloseClick;
//  fLabelCaption := TKMLabel.Create(Self, 0, 5, aWidth, fHeaderHeight, 'Form1', fntOutline, taCenter);
//  fLabelCaption.Hitable := False;
//end;
//
//
//procedure TKMForm.FormCloseClick(Sender: TObject);
//begin
//  Hide;
//
//  if Assigned(OnClose) then
//    OnClose(Self);
//end;
//
//
//function TKMForm.GetCaption: UnicodeString;
//begin
//  Result := fLabelCaption.Caption;
//end;
//
//
//procedure TKMForm.SetCaption(const aValue: UnicodeString);
//begin
//  fLabelCaption.Caption := aValue;
//end;
//
//
//function TKMForm.HitHeader(X, Y: Integer): Boolean;
//begin
//  Result := InRange(X - AbsLeft, 0, Width) and InRange(Y - AbsTop, 0, fHeaderHeight);
//end;
//
//
//procedure TKMForm.MouseDown(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
//begin
//  inherited;
//
//  if HitHeader(X,Y) then
//  begin
//    fDragging := True;
//    fOffsetX := X - AbsLeft;
//    fOffsetY := Y - AbsTop;
//  end;
//
//  MouseMove(X, Y, Shift);
//end;
//
//
//procedure TKMForm.MouseMove(X,Y: Integer; Shift: TShiftState);
//begin
//  inherited;
//
//  if fDragging and (csDown in State) then
//  begin
//    AbsLeft := EnsureRange(X - fOffsetX, 0, MasterParent.Width - Width);
//    AbsTop := EnsureRange(Y - fOffsetY, 0, MasterParent.Height - Height);
//
//    if Assigned(OnMove) then
//      OnMove(Self);
//  end;
//end;
//
//
//procedure TKMForm.MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
//begin
//  inherited;
//  MouseMove(X,Y,Shift);
//
//end;
//
//
//procedure TKMForm.PaintPanel(aPaintLayer: TKMPaintLayer);
//begin
//  TKMRenderUI.WriteShadow(AbsLeft, AbsTop, Width, Height, 15, $40000000);
//
//  TKMRenderUI.WriteOutline(AbsLeft, AbsTop, Width, Height, 3, $FF000000);
//  TKMRenderUI.WriteOutline(AbsLeft+1, AbsTop+1, Width-2, Height-2, 1, $FF80FFFF);
//
//  inherited;
//end;


end.


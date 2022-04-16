unit KM_Controls;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  Controls,
  Generics.Collections,
  KromOGLUtils,
  KM_RenderUI, KM_Pics,
  KM_ResFonts, KM_ResTypes,
  KM_CommonClasses, KM_CommonTypes, KM_Points, KM_Defaults;


type
  TNotifyEventShift = procedure(Sender: TObject; Shift: TShiftState) of object;
  TNotifyEventMB = procedure(Sender: TObject; AButton: TMouseButton) of object;
  TNotifyEventMW = procedure(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean) of object;
  TKMMouseMoveEvent = procedure(Sender: TObject; X,Y: Integer; Shift: TShiftState) of object;
  TKMMouseUpDownEvent = procedure(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton) of object;
  TNotifyEventKey = procedure(Sender: TObject; Key: Word) of object;
  TNotifyEventKeyFunc = function(Sender: TObject; Key: Word): Boolean of object;
  TNotifyEventKeyShift = procedure(Key: Word; Shift: TShiftState) of object;
  TNotifyEventKeyShiftFunc = function(Sender: TObject; Key: Word; Shift: TShiftState): Boolean of object;
  TNotifyEventXY = procedure(Sender: TObject; X, Y: Integer) of object;
  TNotifyEvenClickHold = procedure(Sender: TObject; AButton: TMouseButton; var aHandled: Boolean) of object;
  TPointEventShiftFunc = function (Sender: TObject; Shift: TShiftState; const X,Y: Integer): Boolean of object;

  TKMControlState = (csDown, csFocus, csOver);
  TKMControlStateSet = set of TKMControlState;

  TKMHintKind = (hkControl, // Rendered above control
                 hkStatic,  // 'Classic' hint: rendered in the game / mapEd at the bottom left of the play-area
                 hkTextNotFit); // Hint to show text, when it could not fit in the control, f.e. in the Lists and ColumnBoxes

  TKMControl = class;
  TKMPanel = class;

  { TKMMasterControl }
  TKMMasterControl = class
  private
    fMasterPanel: TKMPanel; //Parentmost control (TKMPanel with all its childs)
    fCtrlDown: TKMControl; //Control that was pressed Down
    fCtrlFocus: TKMControl; //Control which has input Focus
    fCtrlOver: TKMControl; //Control which has cursor Over it
    fCtrlUp: TKMControl; //Control above which cursor was released

    fControlIDCounter: Integer;

    fMouseMoveSubsList: TList<TKMMouseMoveEvent>;
    fMouseDownSubsList: TList<TKMMouseUpDownEvent>;
    fMouseUpSubsList: TList<TKMMouseUpDownEvent>;

    function IsCtrlCovered(aCtrl: TKMControl): Boolean;
    procedure SetCtrlDown(aCtrl: TKMControl);
    procedure SetCtrlFocus(aCtrl: TKMControl);
    procedure SetCtrlOver(aCtrl: TKMControl);
    procedure SetCtrlUp(aCtrl: TKMControl);

    function GetNextCtrlID: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property MasterPanel: TKMPanel read fMasterPanel;
    function IsFocusAllowed(aCtrl: TKMControl): Boolean;
    function IsAutoFocusAllowed(aCtrl: TKMControl): Boolean;
    procedure UpdateFocus(aSender: TKMControl);

    property CtrlDown: TKMControl read fCtrlDown write SetCtrlDown;
    property CtrlFocus: TKMControl read fCtrlFocus write SetCtrlFocus;
    property CtrlOver: TKMControl read fCtrlOver write SetCtrlOver;
    property CtrlUp: TKMControl read fCtrlUp write SetCtrlUp;

    procedure AddMouseMoveCtrlSub(const aMouseMoveEvent: TKMMouseMoveEvent);
    procedure AddMouseDownCtrlSub(const aMouseDownEvent: TKMMouseUpDownEvent);
    procedure AddMouseUpCtrlSub(const aMouseUpEvent: TKMMouseUpDownEvent);

    function HitControl(X,Y: Integer; aIncludeDisabled: Boolean = False; aIncludeNotHitable: Boolean = False): TKMControl;

    function KeyDown    (Key: Word; Shift: TShiftState): Boolean;
    procedure KeyPress  (Key: Char);
    function KeyUp      (Key: Word; Shift: TShiftState): Boolean;
    procedure MouseDown (X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    procedure MouseMove (X,Y: Integer; Shift: TShiftState);
    procedure MouseUp   (X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    procedure MouseWheel(X,Y: Integer; WheelSteps: Integer; var aHandled: Boolean);

    procedure Paint;

    procedure SaveToFile(const aFileName: UnicodeString);

    procedure UpdateState(aGlobalTickCount: Cardinal);
  end;


  {Base class for all TKM elements}
  TKMControl = class
//  type
//    TKMKeyPressKind = (kpkDown, kpkPress);
//    TKMKeyPress = record
//      Time: Int64;
////      Key: Word;
//      C: Char;
//      Kind: TKMKeyPressKind;
//      function ToString: string;
//    end;
  private
//    fKeyPressList: TList<TKMKeyPress>;

    fParent: TKMPanel;
    fAnchors: TKMAnchorsSet;

    //Left and Top are floating-point to allow to precisely store controls position
    //when Anchors [] are used. Cos that means that control must be centered
    //even if the Parent resized by 1px. Otherwise error quickly accumulates on
    //multiple 1px resizes
    //Everywhere else Top and Left are accessed through Get/Set and treated as Integers
    fLeft: Single;
    fTop: Single;
    fWidth: Integer;
    fHeight: Integer;

    fFitInParent: Boolean; // Do we force to fit into parent width / height. Check TKMPanel.SetHeight / SetWidth for details
    fBaseWidth: Integer; // initial width / height used to restore control sizes when fFitInParent property is set
    fBaseHeight: Integer;

    fEnabled: Boolean;
    fVisible: Boolean;
    fFocusable: Boolean; //Can this control have focus (e.g. TKMEdit sets this true)
    fHitable: Boolean; //Can this control be hit with the cursor?
    fControlIndex: Integer; //Index number of this control in his Parent's (TKMPanel) collection
    fID: Integer; //Control global ID
    fHint: UnicodeString; //Text that shows up when cursor is over that control, mainly for Buttons
    fHintBackColor: TKMColor4f; //Hint background color

    fClickHoldMode: Boolean;
    fClickHoldHandled: Boolean;
    fTimeOfLastMouseDown: Cardinal;
    fLastMouseDownButton: TMouseButton;
    fLastClickPos: TKMPoint;

    fOnClick: TNotifyEvent;
    fOnClickShift: TNotifyEventShift;
    fOnClickRight: TPointEvent;
    fOnClickHold: TNotifyEvenClickHold;
    fOnDoubleClick: TNotifyEvent;
    fOnMouseWheel: TNotifyEventMW;
    fOnFocus: TBooleanObjEvent;
    fOnChangeVisibility: TBooleanObjEvent;
    fOnChangeEnableStatus: TBooleanObjEvent;
    fOnKeyDown: TNotifyEventKeyShiftFunc;
    fOnKeyUp: TNotifyEventKeyShiftFunc;

    fOnWidthChange: TObjectIntegerEvent;
    fOnHeightChange: TObjectIntegerEvent;
    fOnSizeSet: TNotifyEvent;
    fOnPositionSet: TNotifyEvent;

    fIsHitTestUseDrawRect: Boolean; //Should we use DrawRect for hitTest, or AbsPositions?

    function GetAbsLeft: Integer;
    function GetAbsTop: Integer;
    function GetAbsRight: Integer;
    function GetAbsBottom: Integer;

    function GetLeft: Integer;
    function GetTop: Integer;
    function GetRight: Integer;
    function GetBottom: Integer;
    function GetHeight: Integer;
    function GetWidth: Integer;
    function GetCenter: TKMPoint;

    function GetVisible: Boolean;
    procedure SetAbsLeft(aValue: Integer);
    procedure SetAbsTop(aValue: Integer);
    procedure SetTopF(aValue: Single);
    procedure SetLeftF(aValue: Single);
    function GetControlRect: TKMRect;
    function GetControlAbsRect: TKMRect;
    function GetIsFocused: Boolean;
    function GetIsClickable: Boolean;

    procedure ResetClickHoldMode;

    procedure DebugKeyDown(Key: Word; Shift: TShiftState);
    procedure SetFocusable(const aValue: Boolean);
    function GetMasterPanel: TKMPanel;
  protected
    fEnabledVisually: Boolean;
    fMouseWheelStep: Integer;
    fTimeOfLastClick: Cardinal; //Required to handle double-clicks

    procedure SetLeft(aValue: Integer); virtual;
    procedure SetTop(aValue: Integer); virtual;
    procedure SetHeight(aValue: Integer); virtual;
    procedure SetWidth(aValue: Integer); virtual;

    procedure SetLeftSilently(aValue: Integer);
    procedure SetTopSilently(aValue: Integer);
    procedure SetHeightSilently(aValue: Integer);
    procedure SetWidthSilently(aValue: Integer);

    function GetAbsDrawLeft: Integer; virtual;
    function GetAbsDrawTop: Integer; virtual;
    function GetAbsDrawRight: Integer; virtual;
    function GetAbsDrawBottom: Integer; virtual;

    property AbsDrawLeft: Integer read GetAbsDrawLeft;
    property AbsDrawRight: Integer read GetAbsDrawRight;
    property AbsDrawTop: Integer read GetAbsDrawTop;
    property AbsDrawBottom: Integer read GetAbsDrawBottom;

    function GetDrawRect: TKMRect; virtual;

    procedure SetVisible(aValue: Boolean); virtual;
    procedure SetEnabled(aValue: Boolean); virtual;
    procedure SetAnchors(aValue: TKMAnchorsSet); virtual;
    procedure SetHitable(const aValue: Boolean); virtual;
    function GetIsPainted: Boolean; virtual;
    function GetSelfAbsLeft: Integer; virtual;
    function GetSelfAbsTop: Integer; virtual;
    function GetSelfHeight: Integer; virtual;
    function GetSelfWidth: Integer; virtual;
    procedure UpdateVisibility; virtual;
    procedure UpdateEnableStatus; virtual;
//    procedure ControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton); virtual;
//    procedure ControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton); virtual;
    procedure FocusChanged(aFocused: Boolean); virtual;
    //Let the control know that it was clicked to do its internal magic
    procedure DoClick(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); virtual;
    procedure DoClickHold(Sender: TObject; Button: TMouseButton; var aHandled: Boolean); virtual;
    function DoHandleMouseWheelByDefault: Boolean; virtual;

    function GetHint: UnicodeString; virtual;
    function GetHintKind: TKMHintKind; virtual;
    function GetHintFont: TKMFont; virtual;
    function IsHintSelected: Boolean; virtual;
    function GetHintBackColor: TKMColor4f; virtual;
    function GetHintTextColor: TColor4; virtual;
    function GetHintBackRect: TKMRect; virtual;
    function GetHintTextOffset: TKMPoint; virtual;
    procedure SetHint(const aHint: UnicodeString); virtual;
    procedure SetHintBackColor(const aValue: TKMColor4f); virtual;

    function CanFocusNext: Boolean; virtual;
  public
    AutoFocusable: Boolean; //Can we focus on this element automatically (f.e. if set to False we will able to Focus only by manual mouse click)
    HandleMouseWheelByDefault: Boolean; //Do control handle MW by default? Usually it is
    CanChangeEnable: Boolean; //Enable state could be changed

    State: TKMControlStateSet; //Each control has it localy to avoid quering Collection on each Render
    Scale: Single; //Child controls position is scaled

    Tag: Integer; //Some tag which can be used for various needs
    Tag2: Integer; //Some tag which can be used for various needs

    DebugHighlight: Boolean;

    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
    destructor Destroy; override;
    function HitTest(X, Y: Integer; aIncludeDisabled: Boolean = False; aIncludeNotHitable: Boolean = False): Boolean; virtual;

    property Parent: TKMPanel read fParent;
    property MasterPanel: TKMPanel read GetMasterPanel;

    property AbsLeft: Integer read GetAbsLeft write SetAbsLeft;
    property AbsRight: Integer read GetAbsRight;
    property AbsTop: Integer read GetAbsTop write SetAbsTop;
    property AbsBottom: Integer read GetAbsBottom;

    property Left: Integer read GetLeft write SetLeft;
    property Right: Integer read GetRight;
    property Top: Integer read GetTop write SetTop;
    property Bottom: Integer read GetBottom;
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property BaseWidth: Integer read fBaseWidth write fBaseWidth;
    property BaseHeight: Integer read fBaseHeight write fBaseHeight;

    property Center: TKMPoint read GetCenter;
    property ID: Integer read fID;
    function GetIDsStr: String;
    property Hint: UnicodeString read GetHint write SetHint; //Text that shows up when cursor is over that control, mainly for Buttons
    property HintKind: TKMHintKind read GetHintKind;
    property HintFont: TKMFont read GetHintFont;
    property HintSelected: Boolean read IsHintSelected;
    property HintBackColor: TKMColor4f read GetHintBackColor write SetHintBackColor;
    property HintTextColor: TColor4 read GetHintTextColor;
    property HintBackRect: TKMRect read GetHintBackRect;
    property HintTextOffset: TKMPoint read GetHintTextOffset;

    property MouseWheelStep: Integer read fMouseWheelStep write fMouseWheelStep;

    property FitInParent: Boolean read fFitInParent write fFitInParent;
    property IsHitTestUseDrawRect: Boolean read fIsHitTestUseDrawRect write fIsHitTestUseDrawRect;

    // "Self" coordinates - this is the coordinates of control itself.
    // For simple controls they are equal to normal coordinates
    // but for composite controls this is coord. for control itself, without any other controls inside composite
    // (f.e. for TKMNumericEdit this is his internal edit coord without Inc/Dec buttons)
    property SelfAbsLeft: Integer read GetSelfAbsLeft;
    property SelfAbsTop: Integer read GetSelfAbsTop;
    property SelfWidth: Integer read GetSelfWidth;
    property SelfHeight: Integer read GetSelfHeight;

    property Rect: TKMRect read GetControlRect;
    property AbsRect: TKMRect read GetControlAbsRect;
    property Anchors: TKMAnchorsSet read fAnchors write SetAnchors;
    property Enabled: Boolean read fEnabled write SetEnabled;
    property Visible: Boolean read GetVisible write SetVisible;
    property Focusable: Boolean read fFocusable write SetFocusable;
    property Hitable: Boolean read fHitable write SetHitable;
    property IsSetVisible: Boolean read fVisible;
    property IsPainted: Boolean read GetIsPainted;
    property IsFocused: Boolean read GetIsFocused;
    property IsClickable: Boolean read GetIsClickable;  // Control considered 'Clickabale' if it is Visible and Enabled
    property ControlIndex: Integer read fControlIndex;
    procedure Enable;
    procedure Disable;
    procedure Show; virtual;
    procedure Hide;
    procedure DoSetVisible; //Differs from Show, that we do not force to show Parents
    procedure Focus;
    procedure Unfocus;
    procedure AnchorsCenter;
    procedure AnchorsStretch;
    procedure ToggleVisibility;
    function MasterParent: TKMPanel;

    procedure SetPosCenter;
    procedure SetPosCenterW;
    procedure SetPosCenterH;

    function KeyDown(Key: Word; Shift: TShiftState): Boolean; virtual;
    procedure KeyPress(Key: Char); virtual;
    function KeyUp(Key: Word; Shift: TShiftState): Boolean; virtual;
    procedure MouseDown (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); virtual;
    procedure MouseMove (X,Y: Integer; Shift: TShiftState); virtual;
    procedure MouseUp   (X,Y: Integer; Shift: TShiftState; Button: TMouseButton); virtual;
    procedure MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean); virtual;

    property OnClick: TNotifyEvent read fOnClick write fOnClick;
    property OnClickShift: TNotifyEventShift read fOnClickShift write fOnClickShift;
    property OnClickRight: TPointEvent read fOnClickRight write fOnClickRight;
    property OnClickHold: TNotifyEvenClickHold read fOnClickHold write fOnClickHold;
    property OnDoubleClick: TNotifyEvent read fOnDoubleClick write fOnDoubleClick;
    property OnMouseWheel: TNotifyEventMW read fOnMouseWheel write fOnMouseWheel;
    property OnFocus: TBooleanObjEvent read fOnFocus write fOnFocus;
    property OnChangeVisibility: TBooleanObjEvent read fOnChangeVisibility write fOnChangeVisibility;
    property OnChangeEnableStatus: TBooleanObjEvent read fOnChangeEnableStatus write fOnChangeEnableStatus;
    property OnKeyDown: TNotifyEventKeyShiftFunc read fOnKeyDown write fOnKeyDown;
    property OnKeyUp: TNotifyEventKeyShiftFunc read fOnKeyUp write fOnKeyUp;

    property OnWidthChange: TObjectIntegerEvent read fOnWidthChange write fOnWidthChange;
    property OnHeightChange: TObjectIntegerEvent read fOnHeightChange write fOnHeightChange;
    property OnSizeSet: TNotifyEvent read fOnSizeSet write fOnSizeSet;
    property OnPositionSet: TNotifyEvent read fOnPositionSet write fOnPositionSet;

    procedure Paint; virtual;
    procedure UpdateState(aTickCount: Cardinal); virtual;

    function ToStr: string;
  end;

  TKMControlClass = class of TKMControl;
  TKMControlClassArray = array of TKMControlClass;


  { Panel which keeps child items in it, it's virtual and invisible }
  TKMPanel = class(TKMControl)
  private
    procedure Init;
  protected
    fMasterControl: TKMMasterControl;
    //Do not propogate SetEnabled and SetVisible because that would show/enable ALL childs childs
    //e.g. scrollbar on a listbox
    procedure SetHeight(aValue: Integer); override;
    procedure SetWidth(aValue: Integer); override;

//    procedure ControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
//    procedure ControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure UpdateVisibility; override;
    procedure UpdateEnableStatus; override;
    function DoPanelHandleMouseWheelByDefault: Boolean; virtual;

    procedure Enlarge(aChild: TKMControl);
  public
    PanelHandleMouseWheelByDefault: Boolean; //Do whole panel handle MW by default? Usually it is
    FocusedControlIndex: Integer; //Index of currently focused control on this Panel
    ChildCount: Word;
    Childs: array of TKMControl;
    constructor Create(aParent: TKMMasterControl; aLeft, aTop, aWidth, aHeight: Integer); overload;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer); overload;
    destructor Destroy; override;
    function AddChild(aChild: TKMControl): Integer; virtual;
    procedure SetCanChangeEnable(aEnable: Boolean; aExceptControls: array of TKMControlClass; aAlsoSetEnable: Boolean = True);

    function FindFocusableControl(aFindNext: Boolean): TKMControl;
    procedure FocusNext;
    procedure ResetFocusedControlIndex;

    property MasterControl: TKMMasterControl read fMasterControl;

    procedure Paint; override;

    procedure UpdateState(aTickCount: Cardinal); override;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  SysUtils, StrUtils, Math,
  Clipbrd,
  KromUtils,
  KM_System,
  KM_ControlsBase, KM_ControlsDragger, KM_ControlsEdit, KM_ControlsSwitch, KM_ControlsTrackBar, KM_ControlsTypes,
  KM_ControlsWaresRow,
  KM_Resource, KM_ResSprites, KM_ResSound, KM_ResTexts, KM_ResKeys,
  KM_Render, KM_RenderTypes,
  KM_Sound, KM_CommonUtils, KM_UtilsExt,
  KM_GameSettings, KM_InterfaceTypes;


const
  CLICK_HOLD_TIME_THRESHOLD = 200; // Time period, determine delay between mouse down and 1st click hold events


{ TKMControl }
constructor TKMControl.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited Create;

  Scale         := 1;
  fHitable      := True; //All controls can be clicked by default
  CanChangeEnable := True; //All controls can change enable status by default
  fLeft         := aLeft;
  fTop          := aTop;
  fWidth        := aWidth;
  fHeight       := aHeight;

  fBaseWidth    := aWidth;
  fBaseHeight   := aHeight;

  Anchors       := [anLeft, anTop];
  State         := [];
  fEnabled      := True;
  fVisible      := True;
  Tag           := 0;
  fHint         := '';
  fHintBackColor := TKMColor4f.New(0, 0, 0, 0.7); // Black with 0.7 alpha
  fMouseWheelStep := 1;
  fControlIndex := -1;
  AutoFocusable := True;
  HandleMouseWheelByDefault := True;
  fLastClickPos := KMPOINT_ZERO;
  fIsHitTestUseDrawRect := False;
  DebugHighlight := False;

//  fKeyPressList := TList<TKMKeyPress>.Create;

  if aParent <> nil then
    fID := aParent.fMasterControl.GetNextCtrlID
  else
  if Self is TKMPanel then
    fID := 0;

  //Parent will be Nil only for master Panel which contains all the controls in it
  fParent   := aParent;
  if aParent <> nil then
    fControlIndex := aParent.AddChild(Self);
end;

destructor TKMControl.Destroy;
begin
//  fKeyPressList.Free;

  inherited;
end;


procedure TKMControl.DebugKeyDown(Key: Word; Shift: TShiftState);
var
  amt: Byte;
begin
  if MODE_DESIGN_CONTROLS then
  begin
    amt := 1;
    if ssShift in Shift then amt := 10;
    if ssAlt in Shift then amt := 100;

    if Key = VK_LEFT  then fLeft   := fLeft - amt;
    if Key = VK_RIGHT then fLeft   := fLeft + amt;
    if Key = VK_UP    then fTop    := fTop  - amt;
    if Key = VK_DOWN  then fTop    := fTop  + amt;
    if Key = VK_HOME  then fWidth  := fWidth  + amt;
    if Key = VK_END   then fWidth  := fWidth  - amt;
    if Key = VK_PRIOR then fHeight := fHeight  + amt;
    if Key = VK_NEXT  then fHeight := fHeight  - amt;
  end;
end;


function TKMControl.KeyDown(Key: Word; Shift: TShiftState): Boolean;
//var
//  keyPress: TKMKeyPress;
begin
//  if fKeyPressList.Count = 0 then
//    keyPress.Time := TimeGetUSec
//  else
//    keyPress.Time := TimeSinceUSec(fKeyPressList[0].Time);

//  keyPress.Key := Key;
//  keyPress.C := Char(Key);
//  keyPress.Kind := kpkDown;
//  fKeyPressList.Add(keyPress);

  Result := MODE_DESIGN_CONTROLS;

  if Assigned(fOnKeyDown) then
    Result := fOnKeyDown(Self, Key, Shift);

  // Exit if control handlers handle the event
  if Result then
    Exit;

  // Unfocus focused control without AutoFocusable flag on Esc key
  if IsFocused and not AutoFocusable and (Key = VK_ESCAPE) then
    Unfocus;
end;


procedure TKMControl.KeyPress(Key: Char);
//var
//  I: Integer;
//  keyPress: TKMKeyPress;
begin
//  if fKeyPressList.Count = 0 then
//    keyPress.Time := TimeGetUSec
//  else
//    keyPress.Time := TimeSinceUSec(fKeyPressList[0].Time);
////  keyPress.Key := 0;
//  keyPress.C := Key;
//  keyPress.Kind := kpkPress;
//
//  fKeyPressList.Add(keyPress);

//  gLog.AddTime('KeyPressList cnt ' + IntToStr(fKeyPressList.Count));
//  for I := 0 to fKeyPressList.Count - 1 do
//    gLog.AddTime(fKeyPressList[I].ToString);

  //Could be something common
end;


function TKMControl.CanFocusNext: Boolean;
begin
  Result := True;
end;


function TKMControl.KeyUp(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
  if (Key = VK_TAB) and CanFocusNext and IsFocused then
  begin
    Parent.FocusNext;
    Exit(True);
  end;

  if Assigned(fOnKeyUp) then
    Result := fOnKeyUp(Self, Key, Shift);
end;


procedure TKMControl.ResetClickHoldMode;
begin
  if Self <> nil then // Could be nil when control is destroyes already, f.e. on game (map) exit
  begin
    fClickHoldMode := False;
    fClickHoldHandled := False;
  end;
end;


procedure TKMControl.MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  //if Assigned(fOnMouseDown) then fOnMouseDown(Self); { Unused }
  fClickHoldMode := True;
  fTimeOfLastMouseDown := TimeGet;
  fLastMouseDownButton := Button;
end;


procedure TKMControl.MouseMove(X,Y: Integer; Shift: TShiftState);
begin
  //if Assigned(fOnMouseOver) then fOnMouseOver(Self); { Unused }
  if (csDown in State) then
  begin
    //Update fClickHoldMode
    if InRange(X, AbsLeft, AbsRight) and InRange(Y, AbsTop, AbsBottom) then
      fClickHoldMode := True
    else
      fClickHoldMode := False;
  end;
end;


procedure TKMControl.MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  clickHoldHandled: Boolean;
begin
  //if Assigned(fOnMouseUp) then OnMouseUp(Self); { Unused }

  if (csDown in State) then
  begin
    State := State - [csDown];
    clickHoldHandled := fClickHoldHandled;
    ResetClickHoldMode;
    //Send Click events
    if not clickHoldHandled then // Do not send click event, if it was handled already while in click hold mode
      DoClick(X, Y, Shift, Button);
    end;
  // No code is allowed after DoClick, as control object could be destroyed,
  // that means we will modify freed memory, which will cause memory leaks
end;


function TKMControl.GetIDsStr: String;
begin
  if Self = nil then Exit('');

  Result := IntToStr(fID) + ' ' + fParent.GetIDsStr;
end;


function TKMControl.GetHint: UnicodeString;
begin
  Result := fHint;
end;


function TKMControl.GetHintFont: TKMFont;
begin
  Result := fntMonospaced; // Should be actually overridden in the ancestors
end;


function TKMControl.IsHintSelected: Boolean;
begin
  Result := False;
end;


function TKMControl.GetHintKind: TKMHintKind;
begin
  Result := hkControl;
end;


procedure TKMControl.SetHintBackColor(const aValue: TKMColor4f);
begin
  fHintBackColor := aValue;
end;


function TKMControl.GetHintBackColor: TKMColor4f;
begin
  Result := fHintBackColor;
end;


function TKMControl.GetHintBackRect: TKMRect;
begin
  Result := KMRECT_ZERO;
end;


function TKMControl.GetHintTextColor: TColor4;
begin
  Result := icWhite;
end;


function TKMControl.GetHintTextOffset: TKMPoint;
begin
  Result := KMPOINT_ZERO;
end;


procedure TKMControl.SetHint(const aHint: UnicodeString);
begin
  //fHint := StringReplace(aHint, '|', ' ', [rfReplaceAll]); //Not sure why we were need to replace | here...
  fHint := aHint;
end;


function TKMControl.DoHandleMouseWheelByDefault: Boolean;
begin
  Result := HandleMouseWheelByDefault            //Controls handle MouseWheel by default
    and Parent.DoPanelHandleMouseWheelByDefault; //But their parent could override this
end;


procedure TKMControl.MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  if Assigned(fOnMouseWheel) then
    fOnMouseWheel(Self, WheelSteps, aHandled)
  else
  if fParent <> nil then
  begin
    if DoHandleMouseWheelByDefault then
      fParent.MouseWheel(Sender, WheelSteps, aHandled)
    else
      aHandled := False;
  end
  else
    aHandled := False;
end;


//fVisible is checked earlier
function TKMControl.HitTest(X, Y: Integer; aIncludeDisabled: Boolean = False; aIncludeNotHitable: Boolean = False): Boolean;
begin
  Result := False;
  if    (Hitable or aIncludeNotHitable)
    and (fEnabled or aIncludeDisabled) then
  begin
    //DrawRect could is restricted by parent panel size and also could be restricted with parent ScrollPanel
    //While outside of ScrollPanel its better to use Abs coordinates
    //since some childs could be outside of its parent borders for some reason
    if fIsHitTestUseDrawRect then
      Result := KMInRect(KMPoint(X,Y), GetDrawRect)
    else
      Result := InRange(X, AbsLeft, AbsRight)
            and InRange(Y, AbsTop, AbsBottom);
  end;
end;


{One common thing - draw childs for self}
procedure TKMControl.Paint;
var
  sColor: TColor4;
  tmp: TKMPoint;
  skipText: Boolean;
begin
  Inc(CtrlPaintCount);

  if SHOW_FOCUSED_CONTROL and (csFocus in State) then
    TKMRenderUI.WriteOutline(AbsLeft-2, AbsTop-2, Width+4, Height+4, 2, $FF00D0FF);

  if (SHOW_CONTROL_OVER or MODE_DESIGN_CONTROLS) and (csOver in State) then
    TKMRenderUI.WriteOutline(AbsLeft-2, AbsTop-2, Width+4, Height+4, 2, $FFFFD000);

  if SHOW_CONTROLS_ID then
  begin
    skipText := SKIP_RENDER_TEXT; //Save value
    SKIP_RENDER_TEXT := False; // Force Render debug data
    TKMRenderUI.WriteText(AbsLeft+1, AbsTop, fWidth, IntToStr(fID), TKMFont(DEBUG_TEXT_FONT_ID), taLeft);
    SKIP_RENDER_TEXT := skipText; // Restore value
  end;

  if DebugHighlight then
    TKMRenderUI.WriteOutline(AbsLeft-2, AbsTop-2, Width+4, Height+4, 2, icRed);

  if not SHOW_CONTROLS_OVERLAY then Exit;

  sColor := $00000000;

  if Self is TKMPanel then sColor := $200000FF;

  if Self is TKMLabel then
  begin //Special case for aligned text
    tmp := TKMLabel(Self).TextSize;
    TKMRenderUI.WriteShape(TKMLabel(Self).TextLeft, AbsTop, tmp.X, tmp.Y, $4000FFFF, $80FFFFFF);
    TKMRenderUI.WriteOutline(AbsLeft, AbsTop, fWidth, fHeight, 1, $FFFFFFFF);
    TKMRenderUI.WriteShape(AbsLeft-3, AbsTop-3, 6, 6, sColor or $FF000000, $FFFFFFFF);
    Exit;
  end;

  if Self is TKMLabelScroll then
  begin //Special case for aligned text
    tmp := TKMLabelScroll(Self).TextSize;
    TKMRenderUI.WriteShape(TKMLabelScroll(Self).TextLeft, AbsTop, tmp.X, tmp.Y, $4000FFFF, $80FFFFFF);
    TKMRenderUI.WriteOutline(AbsLeft, AbsTop, fWidth, fHeight, 1, $FFFFFFFF);
    TKMRenderUI.WriteShape(AbsLeft-3, AbsTop-3, 6, 6, sColor or $FF000000, $FFFFFFFF);
    Exit;
  end;

  if Self is TKMImage      then sColor := $2000FF00;
  if Self is TKMImageStack then sColor := $2080FF00;
  if Self is TKMCheckBox   then sColor := $20FF00FF;
  if Self is TKMTrackBar   then sColor := $2000FF00;
  if Self is TKMCostsRow   then sColor := $2000FFFF;
  if Self is TKMRadioGroup then sColor := $20FFFF00;

  if csOver in State then sColor := sColor OR $30000000; //Highlight on mouse over

  TKMRenderUI.WriteShape(AbsLeft, AbsTop, fWidth, fHeight, sColor, $FFFFFFFF);
  TKMRenderUI.WriteShape(AbsLeft-3, AbsTop-3, 6, 6, sColor or $FF000000, $FFFFFFFF);
end;


function TKMControl.GetMasterPanel: TKMPanel;
begin
  Result := Parent.MasterControl.MasterPanel;
end;


{Shortcuts to Controls properties}
procedure TKMControl.SetAbsLeft(aValue: Integer);
begin
  if Parent = nil then
    Left := aValue
  else
    Left := Round((aValue - Parent.AbsLeft) / Parent.Scale);
end;

procedure TKMControl.SetAbsTop(aValue: Integer);
begin
  if Parent = nil then
    Top := aValue
  else
    Top := Round((aValue - Parent.AbsTop) / Parent.Scale);
end;

//GetAbsCoordinates
function TKMControl.GetAbsBottom: Integer;
begin
  Result := GetAbsTop + GetHeight;
end;

function TKMControl.GetAbsLeft: Integer;
begin
  if Parent = nil then
    Result := Round(fLeft)
  else
    Result := Round(fLeft * Parent.Scale) + Parent.GetAbsLeft;
end;

function TKMControl.GetAbsRight: Integer;
begin
  Result := GetAbsLeft + GetWidth;
end;

function TKMControl.GetAbsTop: Integer;
begin
  if Parent = nil then
    Result := Round(fTop)
  else
    Result := Round(fTop * Parent.Scale) + Parent.GetAbsTop;
end;
//-------------------------------

//AbsDrawCoordinates
function TKMControl.GetAbsDrawLeft: Integer;
begin
  Result := GetAbsLeft;
end;

function TKMControl.GetAbsDrawTop: Integer;
begin
  Result := GetAbsTop;
end;

function TKMControl.GetAbsDrawRight: Integer;
begin
  Result := GetAbsRight;
end;

function TKMControl.GetAbsDrawBottom: Integer;
begin
  Result := GetAbsBottom;
end;
//-------------------------------

function TKMControl.GetLeft: Integer;
begin
  Result := Round(fLeft)
end;

function TKMControl.GetTop: Integer;
begin
  Result := Round(fTop)
end;

function TKMControl.GetBottom: Integer;
begin
  Result := GetTop + GetHeight;
end;

function TKMControl.GetRight: Integer;
begin
  Result := GetLeft + GetWidth;
end;


procedure TKMControl.SetLeft(aValue: Integer);
begin
  fLeft := aValue;

  if Assigned(fOnPositionSet) then
    fOnPositionSet(Self);
end;


procedure TKMControl.SetTop(aValue: Integer);
begin
  fTop := aValue;

  if Assigned(fOnPositionSet) then
    fOnPositionSet(Self);
end;


procedure TKMControl.SetLeftSilently(aValue: Integer);
begin
  fLeft := aValue;
end;


procedure TKMControl.SetTopSilently(aValue: Integer);
begin
  fTop := aValue;
end;


procedure TKMControl.SetHeightSilently(aValue: Integer);
begin
  fHeight := aValue;
end;


procedure TKMControl.SetWidthSilently(aValue: Integer);
begin
  fWidth := aValue;
end;


function TKMControl.GetHeight: Integer;
begin
  Result := fHeight;
end;


function TKMControl.GetWidth: Integer;
begin
  Result := fWidth;
end;


function TKMControl.GetCenter: TKMPoint;
begin
  Result := KMPoint(GetLeft + (GetWidth div 2), GetTop + (GetHeight div 2));
end;


function TKMControl.GetSelfAbsLeft: Integer;
begin
  Result := AbsLeft;
end;


function TKMControl.GetSelfAbsTop: Integer;
begin
  Result := AbsTop;
end;


function TKMControl.GetSelfHeight: Integer;
begin
  Result := fHeight;
end;


function TKMControl.GetSelfWidth: Integer;
begin
  Result := fWidth;
end;


procedure TKMControl.SetTopF(aValue: Single);
begin
  //Call child classes SetTop methods
  SetTop(Round(aValue));

  //Assign actual FP value
  fTop := aValue;
end;

procedure TKMControl.SetLeftF(aValue: Single);
begin
  //Call child classes SetTop methods
  SetLeft(Round(aValue));

  //Assign actual FP value
  fLeft := aValue;
end;


function TKMControl.GetControlRect: TKMRect;
begin
  Result := KMRect(Left, Top, Left + Width, Top + Height);
end;


function TKMControl.GetControlAbsRect: TKMRect;
begin
  Result := KMRect(AbsLeft, AbsTop, AbsRight, AbsBottom);
end;


function TKMControl.GetIsFocused: Boolean;
begin
  Result := csFocus in State;
end;


function TKMControl.GetIsClickable: Boolean;
begin
  Result := Visible and Enabled;
end;


//Overriden in child classes
procedure TKMControl.SetHeight(aValue: Integer);
var
  oldH: Integer;
begin
  oldH := fHeight;
  fHeight := aValue;

  if (oldH <> fHeight) and Assigned(fOnHeightChange) then
    fOnHeightChange(Self, fHeight);

  if Assigned(fOnSizeSet) then
    fOnSizeSet(Self);
end;

//Overriden in child classes
procedure TKMControl.SetWidth(aValue: Integer);
var
  oldW: Integer;
begin
  oldW := fHeight;
  fWidth := aValue;

  if (oldW <> fWidth) and Assigned(fOnWidthChange) then
    fOnWidthChange(Self, fWidth);

  if Assigned(fOnSizeSet) then
    fOnSizeSet(Self);
end;


function TKMControl.GetDrawRect: TKMRect;
begin
  if fParent <> nil then
  begin
    Result := fParent.GetDrawRect;
    if Result <> KMRECT_INVALID_TILES then
      Result := KMRectIntersect(Result, AbsDrawLeft, AbsDrawTop, AbsDrawRight, AbsDrawBottom);
  end else
    Result := KMRect(AbsDrawLeft, AbsDrawTop, AbsDrawRight, AbsDrawBottom);
end;


//Let the control know that it was clicked to do its internal magic
procedure TKMControl.DoClick(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  //Note that we process double-click separately (actual sequence is Click + Double-Click)
  //because we would not like to delay Click just to make sure it is single.
  //On the ther hand it does no harm to call Click first
  if (Button = mbLeft)
    and Assigned(fOnDoubleClick)
    and KMSamePoint(fLastClickPos, KMPoint(X,Y))
    and (TimeSince(fTimeOfLastClick) <= GetDoubleClickTime) then
  begin
    fTimeOfLastClick := 0;
    fOnDoubleClick(Self);
  end
  else
  begin
    if (Button = mbLeft) and Assigned(fOnDoubleClick) then
    begin
      fTimeOfLastClick := TimeGet;
      fLastClickPos := KMPoint(X,Y);
    end;

    if Assigned(fOnClickShift) then
      fOnClickShift(Self, Shift)
    else
    if (Button = mbLeft) and Assigned(fOnClick) then
      fOnClick(Self)
    else
    if (Button = mbRight) and Assigned(fOnClickRight) then
      fOnClickRight(Self, X, Y);
  end;
end;


procedure TKMControl.DoClickHold(Sender: TObject; Button: TMouseButton; var aHandled: Boolean);
begin
  aHandled := False;
  //Let descendants override this method
end;


// Check Control including all its Parents to see if Control is actually displayed/visible
function TKMControl.GetVisible: Boolean;
begin
  if Self = nil then Exit(False);

  Result := fVisible and ((Parent = nil) or Parent.Visible);
end;


function TKMControl.GetIsPainted: Boolean;
begin
  Result := GetVisible;
end;


procedure TKMControl.SetEnabled(aValue: Boolean);
var
  oldEnabled: Boolean;
begin
  if not CanChangeEnable then Exit; //Change enability is blocked

  oldEnabled := fEnabled;
  fEnabled := aValue;

  // Only swap focus if enability changed
  if (oldEnabled <> fEnabled) and (Focusable or (Self is TKMPanel)) then
    MasterParent.fMasterControl.UpdateFocus(Self);

  UpdateEnableStatus;
end;


procedure TKMControl.SetFocusable(const aValue: Boolean);
var
  oldFocusable: Boolean;
begin
  oldFocusable := fFocusable;

  fFocusable := aValue;

  // Update focus if Focusable was changed
  if oldFocusable <> fFocusable then
    Parent.MasterControl.UpdateFocus(Self);
end;


procedure TKMControl.SetHitable(const aValue: Boolean);
begin
  fHitable := aValue;
end;


procedure TKMControl.SetAnchors(aValue: TKMAnchorsSet);
begin
  fAnchors := aValue;
end;


procedure TKMControl.SetVisible(aValue: Boolean);
var
  oldVisible: Boolean;
begin
  oldVisible := fVisible;
  fVisible := aValue;

  //Swap focus and UpdateVisibility only if visibility changed
  if (oldVisible <> fVisible) then
  begin
    if Focusable or (Self is TKMPanel) then
      MasterParent.fMasterControl.UpdateFocus(Self);

    UpdateVisibility;
  end;
end;


procedure TKMControl.UpdateState(aTickCount: Cardinal);
var
  sameMouseBtn: Boolean;
begin
  if (csDown in State) and fClickHoldMode and (TimeSince(fTimeOfLastMouseDown) > CLICK_HOLD_TIME_THRESHOLD)  then
  begin
    sameMouseBtn := False;
    case fLastMouseDownButton of
      mbLeft:   sameMouseBtn := (GetKeyState(VK_LBUTTON) < 0);
      mbRight:  sameMouseBtn := (GetKeyState(VK_RBUTTON) < 0);
    end;
    if sameMouseBtn then
    begin
      DoClickHold(Self, fLastMouseDownButton, fClickHoldHandled);
      if Assigned(fOnClickHold) then
        fOnClickHold(Self, fLastMouseDownButton, fClickHoldHandled);
    end else
      ResetClickHoldMode; //Can happen if user alt-tab from game window while holding MB. Reset Click Hold mode then
  end;

end;


procedure TKMControl.UpdateVisibility;
begin
  if Assigned(fOnChangeVisibility) then
    fOnChangeVisibility(Self, fVisible);
  //Let descendants override this method
end;


procedure TKMControl.UpdateEnableStatus;
begin
  if Assigned(fOnChangeEnableStatus) then
    fOnChangeEnableStatus(Self, fEnabled);
  //Let descendants override this method
end;


procedure TKMControl.FocusChanged(aFocused: Boolean);
begin
  //Let descendants override this method
end;


//procedure TKMControl.ControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
//begin
//  //Let descendants override this method
//end;
//
//
//procedure TKMControl.ControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
//begin
//  //Let descendants override this method
//end;


procedure TKMControl.Enable;  begin SetEnabled(True);  end; //Overrides will be set too
procedure TKMControl.Disable; begin SetEnabled(False); end;


// Show up entire branch in which control resides
procedure TKMControl.Show;
begin
  if Parent <> nil then Parent.Show;
  Visible := True;
end;


procedure TKMControl.ToggleVisibility;
begin
  Visible := not Visible;
end;


procedure TKMControl.Hide;
begin
  Visible := False;
end;


procedure TKMControl.DoSetVisible;
begin
  Visible := True;
end;


procedure TKMControl.AnchorsCenter;
begin
  Anchors := [];
end;


procedure TKMControl.AnchorsStretch;
begin
  Anchors := [anLeft, anTop, anRight, anBottom];
end;


procedure TKMControl.Focus;
begin
  if not IsFocused and Focusable then
  begin
    // Reset master control focus
    Parent.fMasterControl.CtrlFocus := nil;
    Parent.FocusedControlIndex := ControlIndex;
    Parent.fMasterControl.CtrlFocus := Self;
//    Parent.fMasterControl.UpdateFocus(Parent); // It looks like we can manually set focus, no need for update procedure
  end;
end;


procedure TKMControl.Unfocus;
begin
  Parent.fMasterControl.CtrlFocus := nil;
end;


function TKMControl.MasterParent: TKMPanel;
var
  P: TKMPanel;
begin
  if not (Self is TKMPanel) then
    P := Parent
  else
    P := TKMPanel(Self);

  while P.Parent <> nil do
    P := P.Parent;
  Result := P;
end;


procedure TKMControl.SetPosCenterW;
begin
  Left := (Parent.Width - Width) div 2;
end;


procedure TKMControl.SetPosCenterH;
begin
  Top := (Parent.Height - Height) div 2;
end;


procedure TKMControl.SetPosCenter;
begin
  SetPosCenterW;
  SetPosCenterH;
end;


function TKMControl.ToStr: string;
begin
  if Self = nil then Exit('nil');
  
  Result := Format('ID=%d ParentID=%d Class=%s AbsPos: (%d;%d) Pos: (%d;%d) Sizes: [%d;%d]',
                   [fID, Parent.ID, ClassName, AbsLeft, AbsTop, Left, Top, fWidth, fHeight]);
end;


{ TKMPanel } //virtual panels that contain child items
constructor TKMPanel.Create(aParent: TKMMasterControl; aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited Create(nil, aLeft, aTop, aWidth, aHeight);

  fMasterControl := aParent;
  aParent.fMasterPanel := Self;
  Init;
end;


constructor TKMPanel.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  fMasterControl := aParent.fMasterControl;
  Init;
end;


procedure TKMPanel.Init;
begin
  ResetFocusedControlIndex;
  PanelHandleMouseWheelByDefault := True; //Panels handle mousewheel by default
end;


procedure TKMPanel.ResetFocusedControlIndex;
begin
  FocusedControlIndex := -1;
end;


destructor TKMPanel.Destroy;
var
  I: Integer;
begin
  for I := 0 to ChildCount - 1 do
    Childs[I].Free;

  inherited;
end;


function TKMPanel.FindFocusableControl(aFindNext: Boolean): TKMControl;
var
  I, ctrlToFocusI: Integer;
begin
  Result := nil;
  ctrlToFocusI := -1;
  for I := 0 to ChildCount - 1 do
    if fMasterControl.IsAutoFocusAllowed(Childs[I]) and (
      (FocusedControlIndex = -1)                          // If FocusControl was not set (no focused element on panel)
      or (FocusedControlIndex = Childs[I].ControlIndex) // We've found last focused Control
      or (ctrlToFocusI <> -1)) then                         // We did find last focused Control on previos iterations
    begin
      //Do we need to find next focusable control ?
      if aFindNext and (ctrlToFocusI = -1)
        //FocusedControlIndex = -1 means there is no focus on this panel. Then we need to focus on first good control
        and (FocusedControlIndex <> -1) then
      begin
        ctrlToFocusI := I;
        Continue;
      end else begin
        Result := Childs[I]; // We find Control to focus on, then exit
        Exit;
      end;
    end;

  // If we did not find Control to focus on, try to find in the first controls of Panel (let's cycle the search)
  if ctrlToFocusI <> -1 then
  begin
    // We will try to find it until the same Control, that we find before in previous For cycle
    for I := 0 to ctrlToFocusI do // So if there will be no proper controls, then set focus again to same control with I = CtrlToFocusI
      if fMasterControl.IsAutoFocusAllowed(Childs[I]) then
      begin
        Result := Childs[I];
        Exit;
      end;
  end;
end;


//Focus next focusable control on this Panel
procedure TKMPanel.FocusNext;
var
  ctrl: TKMControl;
begin
  if InRange(FocusedControlIndex, 0, ChildCount - 1) then
  begin
    ctrl := FindFocusableControl(True);
    if ctrl <> nil then
      FocusedControlIndex := ctrl.ControlIndex; // update FocusedControlIndex to let fCollection.UpdateFocus focus on it
    //Need to update Focus only through UpdateFocus
    fMasterControl.UpdateFocus(Self);
  end;
end;


procedure TKMPanel.Enlarge(aChild: TKMControl);
begin
  if Self = nil then Exit;

  fLeft := Left + Min(0, aChild.Left);
  fTop := Top + Min(0, aChild.Top);
  fWidth := Width - Min(0, aChild.Left);
  fHeight := Height - Min(0, aChild.Top);
  fWidth := Width + Max(0, aChild.Right - Right);
  fHeight := Height + Max(0, aChild.Bottom - Bottom);

  fParent.Enlarge(Self);
end;


function TKMPanel.AddChild(aChild: TKMControl): Integer;
begin
  //Descendants of TKMScrollPanel should all use DrawRect for HitTest
  aChild.fIsHitTestUseDrawRect := fIsHitTestUseDrawRect;

  if ChildCount >= Length(Childs) then
    SetLength(Childs, ChildCount + 16);

  Childs[ChildCount] := aChild;
  Result := ChildCount;
  Inc(ChildCount);
end;


procedure TKMPanel.SetCanChangeEnable(aEnable: Boolean; aExceptControls: array of TKMControlClass; aAlsoSetEnable: Boolean = True);
var
  I, J: Integer;
  skipChild: Boolean;
begin
  if aEnable and aAlsoSetEnable then
    Enabled := aEnable;
  for I := 0 to ChildCount - 1 do
  begin
    if Childs[I] is TKMPanel then
      TKMPanel(Childs[I]).SetCanChangeEnable(aEnable, aExceptControls, aAlsoSetEnable)
    else begin
      skipChild := False;
      for J := Low(aExceptControls) to High(aExceptControls) do
        if Childs[I] is aExceptControls[J] then
        begin
          skipChild := True;
          Break;
        end;

      if skipChild then
        Continue;

      //Unblock first to be able to change Enable status
      if aEnable then
        Childs[I].CanChangeEnable := aEnable;

      if aAlsoSetEnable then
      begin
        Childs[I].Enabled := aEnable;
        //Set fEnabledVisually for TKMButtonFlat. They looks better in that case
        if Childs[I] is TKMButtonFlat then
          Childs[I].fEnabledVisually := not aEnable;
      end;

      if not aEnable then
        Childs[I].CanChangeEnable := aEnable;
    end;
  end;
  if not aEnable and aAlsoSetEnable then
    Enabled := aEnable;
end;


procedure TKMPanel.SetHeight(aValue: Integer);
var
  I, diff: Integer;
begin
  for I := 0 to ChildCount - 1 do
  begin
    diff := aValue - fHeight;

    if (anTop in Childs[I].Anchors) and (anBottom in Childs[I].Anchors) then
      Childs[I].Height := Childs[I].Height + diff
    else
    if anTop in Childs[I].Anchors then
      //Do nothing
    else
    if anBottom in Childs[I].Anchors then
      Childs[I].SetTopF(Childs[I].fTop + diff)
    else
    begin
      // Fit into parent panel
      if Childs[I].FitInParent then
      begin
        // Child base is bigger, than parent is going to be
        if aValue < Childs[I].BaseHeight then
        begin
          Childs[I].Height := aValue;
          Childs[I].SetTopF(0);
        end
        else
        // Child base is smaller, restore it BaseHeight
        begin
          Childs[I].Height := Childs[I].BaseHeight;
          // Use 'centered' position for now
          // We could try to save or to set 'baseTop as a float value of total parent height' in the future
          Childs[I].SetTopF((aValue - Childs[I].Height) / 2);
        end;
      end
      else
        Childs[I].SetTopF(Childs[I].fTop + diff / 2);
    end;
  end;

  inherited;
end;


procedure TKMPanel.SetWidth(aValue: Integer);
var
  I: Integer;
begin
  for I := 0 to ChildCount - 1 do
    if (anLeft in Childs[I].Anchors) and (anRight in Childs[I].Anchors) then
      Childs[I].Width := Childs[I].Width + (aValue - fWidth)
    else
    if anLeft in Childs[I].Anchors then
      //Do nothing
    else
    if anRight in Childs[I].Anchors then
      Childs[I].SetLeftF(Childs[I].fLeft + (aValue - fWidth))
    else
    begin
      // Fit into parent panel
      if Childs[I].FitInParent then
      begin
        // Child base is bigger, than parent is going to be
        if aValue < Childs[I].BaseWidth then
        begin
          Childs[I].Width := aValue;
          Childs[I].SetLeftF(0);
        end
        else
          // Child base is smaller, restore it BaseWidth
        begin
          Childs[I].Width := Childs[I].BaseWidth;
          // Use 'centered' position for now
          // We could try to save or to set 'baseLeft as a float value of total parent width' in the future
          Childs[I].SetLeftF((aValue - Childs[I].Width) / 2);
        end;
      end
      else
        Childs[I].SetLeftF(Childs[I].fLeft + (aValue - fWidth) / 2);
    end;

  inherited;
end;


//procedure TKMPanel.ControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
//var
//  I: Integer;
//begin
//  inherited;
//  for I := 0 to ChildCount - 1 do
//    Childs[I].ControlMouseDown(Sender, X, Y, Shift, Button);
//end;
//
//
//procedure TKMPanel.ControlMouseUp(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
//var
//  I: Integer;
//begin
//  inherited;
//  for I := 0 to ChildCount - 1 do
//    Childs[I].ControlMouseUp(Sender, X, Y, Shift, Button);
//end;


procedure TKMPanel.UpdateState(aTickCount: Cardinal);
var
  I: Integer;
begin
  for I := 0 to ChildCount - 1 do
    Childs[I].UpdateState(aTickCount);
end;


procedure TKMPanel.UpdateVisibility;
var
  I: Integer;
begin
  inherited;
  for I := 0 to ChildCount - 1 do
    Childs[I].UpdateVisibility;
end;


procedure TKMPanel.UpdateEnableStatus;
var
  I: Integer;
begin
  inherited;
  for I := 0 to ChildCount - 1 do
    Childs[I].UpdateEnableStatus;
end;


function TKMPanel.DoPanelHandleMouseWheelByDefault: Boolean;
begin
  Result := PanelHandleMouseWheelByDefault //Panels handle mousewheel by default
    and ((Parent = nil) or Parent.DoPanelHandleMouseWheelByDefault); //But their parents could override this
end;


procedure TKMPanel.Paint;
var
  I: Integer;
begin
  // Paint self (dev overlays)
  inherited;

  // Paint children
  for I := 0 to ChildCount - 1 do
    if Childs[I].fVisible then
      Childs[I].Paint;
end;


{ TKMMasterControl }
constructor TKMMasterControl.Create;
begin
  inherited;

  fMouseMoveSubsList := TList<TKMMouseMoveEvent>.Create;
  fMouseDownSubsList := TList<TKMMouseUpDownEvent>.Create;
  fMouseUpSubsList := TList<TKMMouseUpDownEvent>.Create;
end;


destructor TKMMasterControl.Destroy;
begin
  fMouseUpSubsList.Free;
  fMouseDownSubsList.Free;
  fMouseMoveSubsList.Free;

  // Free and nil to avoid problems on game Exit (MouseMove invokes ScanChilds over object, while he is going to be freed)
  // So we want to object to be nil'ed first, so we could check it in the ScanChilds
  // Will destroy all its childs as well
  FreeAndNil(fMasterPanel);

  inherited;
end;


procedure TKMMasterControl.AddMouseMoveCtrlSub(const aMouseMoveEvent: TKMMouseMoveEvent);
begin
  if Self = nil then Exit;

  fMouseMoveSubsList.Add(aMouseMoveEvent);
end;


procedure TKMMasterControl.AddMouseDownCtrlSub(const aMouseDownEvent: TKMMouseUpDownEvent);
begin
  if Self = nil then Exit;

  fMouseDownSubsList.Add(aMouseDownEvent);
end;


procedure TKMMasterControl.AddMouseUpCtrlSub(const aMouseUpEvent: TKMMouseUpDownEvent);
begin
  if Self = nil then Exit;

  fMouseUpSubsList.Add(aMouseUpEvent);
end;


procedure TKMMasterControl.SetCtrlDown(aCtrl: TKMControl);
begin
  if fCtrlDown <> nil then
    fCtrlDown.State := fCtrlDown.State - [csDown]; //Release previous

  if aCtrl <> nil then
    aCtrl.State := aCtrl.State + [csDown];         //Press new

  fCtrlDown := aCtrl;                              //Update info
end;


procedure TKMMasterControl.SetCtrlFocus(aCtrl: TKMControl);
begin
  if fCtrlFocus <> nil then
    fCtrlFocus.State := fCtrlFocus.State - [csFocus];

  if aCtrl <> nil then
    aCtrl.State := aCtrl.State + [csFocus];

  if aCtrl <> fCtrlFocus then
  begin
    if fCtrlFocus <> nil then
    begin
      fCtrlFocus.FocusChanged(False);
      if fCtrlFocus <> nil then
      begin
        if  Assigned(fCtrlFocus.fOnFocus) then
            fCtrlFocus.fOnFocus(fCtrlFocus, False);
        // Reset Parent Panel FocusedControlIndex only for different parents
        if (aCtrl = nil) or (aCtrl.Parent <> fCtrlFocus.Parent) then
            fCtrlFocus.Parent.ResetFocusedControlIndex;
      end;
    end;

    if aCtrl <> nil then
    begin
      aCtrl.FocusChanged(True);
      if Assigned(aCtrl.fOnFocus) then
        aCtrl.fOnFocus(aCtrl, True);
      aCtrl.Parent.FocusedControlIndex := aCtrl.ControlIndex; //Set Parent Panel FocusedControlIndex to new focused control
    end;
  end;

  fCtrlFocus := aCtrl;
end;


procedure TKMMasterControl.SetCtrlOver(aCtrl: TKMControl);
begin
  if fCtrlOver <> nil then fCtrlOver.State := fCtrlOver.State - [csOver];
  if aCtrl <> nil then aCtrl.State := aCtrl.State + [csOver];
  fCtrlOver := aCtrl;
end;


procedure TKMMasterControl.SetCtrlUp(aCtrl: TKMControl);
begin
  fCtrlUp := aCtrl;
  //Give focus only to controls with Focusable=True
  if (fCtrlUp <> nil) and fCtrlUp.Focusable then
    if fCtrlDown = fCtrlUp then
      CtrlFocus := fCtrlUp
    else
      CtrlFocus := nil;
end;


//Check If Control if it is allowed to be focused on (manual or automatically)
function TKMMasterControl.IsFocusAllowed(aCtrl: TKMControl): Boolean;
begin
  if Self = nil then Exit(False);

  Result := aCtrl.fVisible
        and aCtrl.Enabled
        and aCtrl.Focusable
        and not IsCtrlCovered(aCtrl); // Do not allow to focus on covered Controls
end;


//Check If Control if it is allowed to be automatically (not manual, by user) focused on
function TKMMasterControl.IsAutoFocusAllowed(aCtrl: TKMControl): Boolean;
begin
  if Self = nil then Exit(False);

  Result := aCtrl.AutoFocusable and IsFocusAllowed(aCtrl);
end;


function TKMMasterControl.GetNextCtrlID: Integer;
begin
  Inc(fControlIDCounter);
  Result := fControlIDCounter;
end;


//Update focused control
procedure TKMMasterControl.UpdateFocus(aSender: TKMControl);

  function FindFocusable(C: TKMPanel): Boolean;
  var
    I: Integer;
    ctrl: TKMControl;
  begin
    Result := False;
    ctrl := C.FindFocusableControl(False);
    if ctrl <> nil then
    begin
      CtrlFocus := ctrl;
      Result := True;
      Exit;
    end;

    for I := 0 to C.ChildCount - 1 do
      if C.Childs[I].fVisible
        and C.Childs[I].Enabled
        and (C.Childs[I] is TKMPanel) then
      begin
        Result := FindFocusable(TKMPanel(C.Childs[I]));
        if Result then Exit;
      end;
  end;

begin
  if Self = nil then Exit;

  if aSender.Visible and aSender.Enabled
    and ((not (aSender is TKMPanel) and aSender.Focusable) or (aSender is TKMPanel)) then
  begin
    // Something showed up or became enabled

    // If something showed up - focus on it
    if not (aSender is TKMPanel) and aSender.Focusable then
      CtrlFocus := aSender;
    // If panel showed up - try to focus on its contents
    if aSender is TKMPanel then
      FindFocusable(TKMPanel(aSender));
  end else
  begin
    // Something went hidden or disabled
    if (CtrlFocus = nil) or not CtrlFocus.Visible or not CtrlFocus.Enabled or not CtrlFocus.Focusable then
    begin
      // If there was no focus, or it is our Focus control that went hidden or disabled
      CtrlFocus := nil;
      FindFocusable(fMasterPanel);
    end;
  end;
end;


procedure TKMMasterControl.UpdateState(aGlobalTickCount: Cardinal);
begin
  if Self = nil then Exit;

  fMasterPanel.UpdateState(aGlobalTickCount);
end;


//Check if control is covered by other controls or not
//We assume that control is covered if any of his 4 corners is covered
//For corners used actual corners with 1 px offset inside to solve border collisions
//Use Self coordinates to check, because some controls can contain other sub-controls (f.e. TKMNumericEdit)
function TKMMasterControl.IsCtrlCovered(aCtrl: TKMControl): Boolean;
begin
  Result := (HitControl(aCtrl.SelfAbsLeft + 1, aCtrl.SelfAbsTop + 1) <> aCtrl)
        or (HitControl(aCtrl.SelfAbsLeft + aCtrl.SelfWidth - 1, aCtrl.SelfAbsTop + 1) <> aCtrl)
        or (HitControl(aCtrl.SelfAbsLeft + 1, aCtrl.SelfAbsTop + aCtrl.SelfHeight - 1) <> aCtrl)
        or (HitControl(aCtrl.SelfAbsLeft + aCtrl.SelfWidth - 1, aCtrl.SelfAbsTop + aCtrl.SelfHeight - 1) <> aCtrl);
end;


{ Recursing function to find topmost control (excl. Panels)}
function TKMMasterControl.HitControl(X,Y: Integer; aIncludeDisabled: Boolean = False; aIncludeNotHitable: Boolean = False): TKMControl;

  function ScanChild(P: TKMPanel; aX,aY: Integer): TKMControl;
  var
    I: Integer;
    child: TKMControl;
  begin
    // Could sometimes happen on game exit?
    if (Self = nil) or (P = nil) then Exit(nil);

    Result := nil;
    //Process controls in reverse order since last created are on top
    for I := P.ChildCount - 1 downto 0 do
    begin
      child := P.Childs[I];
      if child.fVisible then //If we can't see it, we can't touch it
      begin
        //Scan Panels childs first, if none is hit - hittest the panel
        if (child is TKMPanel) then
        begin
          Result := ScanChild(TKMPanel(child),aX,aY);
          if Result <> nil then
            Exit;
        end;
        if child.HitTest(aX, aY, aIncludeDisabled, aIncludeNotHitable) then
        begin
          Result := child;
          Exit;
        end;
      end;
    end;
  end;

begin
  if Self = nil then Exit(nil);

  Result := ScanChild(fMasterPanel, X, Y);
end;


function TKMMasterControl.KeyDown(Key: Word; Shift: TShiftState): Boolean;
var
  control: TKMControl;
begin
  Result := False;

  if Self = nil then Exit;

  //CtrlFocus could be on another menu page and no longer visible
  if (CtrlFocus <> nil) and CtrlFocus.Visible then
  begin
    control := CtrlFocus;
    //Lets try to find who can handle KeyDown event in controls tree
    while (control <> nil) and not control.KeyDown(Key, Shift) do
      control := control.Parent;

    Result := control <> nil; // means we find someone, who handle that event
  end;

  if MODE_DESIGN_CONTROLS and (CtrlOver <> nil) then
    CtrlOver.DebugKeyDown(Key, Shift);
end;


procedure TKMMasterControl.KeyPress(Key: Char);
begin
  if Self = nil then Exit;

  //CtrlFocus could be on another menu page and no longer visible
  if (CtrlFocus <> nil) and CtrlFocus.Visible then
    CtrlFocus.KeyPress(Key);
end;


function TKMMasterControl.KeyUp(Key: Word; Shift: TShiftState): Boolean;
var
  control: TKMControl;
begin
  Result := False;

  if Self = nil then Exit;

  //CtrlFocus could be on another menu page and no longer visible
  if (CtrlFocus <> nil) and CtrlFocus.Visible then
  begin
    control := CtrlFocus;
    //Lets try to find who can handle KeyUp event in controls tree
    while (control <> nil) and not control.KeyUp(Key, Shift) do
      control := control.Parent;

    Result := control <> nil; // means we find someone, who handle that event
  end;
end;


procedure TKMMasterControl.MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  I: Integer;
begin
  if Self = nil then Exit;

  CtrlDown := HitControl(X,Y);

  // Notify all ControlMouseDown subscribers
  for I := 0 to fMouseDownSubsList.Count - 1 do
    if Assigned(fMouseDownSubsList[I]) then
      fMouseDownSubsList[I](CtrlDown, X, Y, Shift, Button);
//  fMasterPanel.ControlMouseDown(CtrlDown, X, Y, Shift, Button);

  if CtrlDown <> nil then
    CtrlDown.MouseDown(X, Y, Shift, Button);
end;


procedure TKMMasterControl.MouseMove(X,Y: Integer; Shift: TShiftState);
var
  I: Integer;
begin
  if Self = nil then Exit;

  CtrlOver := HitControl(X,Y);

  // Notify all ControlMouseMove subscribers
  for I := 0 to fMouseMoveSubsList.Count - 1 do
    if Assigned(fMouseMoveSubsList[I]) then
      fMouseMoveSubsList[I](CtrlOver, X, Y, Shift);

  //User is dragging some Ctrl (e.g. scrollbar) and went away from Ctrl bounds
  if (CtrlDown <> nil) and CtrlDown.Visible then
    CtrlDown.MouseMove(X, Y, Shift)
  else
  if CtrlOver <> nil then
    CtrlOver.MouseMove(X, Y, Shift);

  //The Game hides cursor when using DirectionSelector, don't spoil it
  if gSystem.Cursor <> kmcInvisible then
  begin
    if CtrlOver is TKMEdit then
      gSystem.Cursor := kmcEdit
    else
    if CtrlOver is TKMDragger then
      gSystem.Cursor := kmcDragUp
    else
      if gSystem.Cursor in [kmcEdit, kmcDragUp] then
        gSystem.Cursor := kmcDefault; //Reset the cursor from these two special cursors
  end;
end;


procedure TKMMasterControl.MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  I: Integer;
begin
  CtrlUp := HitControl(X,Y);

  //Here comes tricky part, we can't do anything after calling an event (it might Destroy everything,
  //e.g. Exit button, or Resolution change). We need to release CtrlDown (otherwise it remains
  //pressed), but we need to keep csDown state until it's registered by Control.MouseUp
  //to call OnClick. So, we nil fCtrlDown here and Control.MouseUp will reset ControlState
  //Other case, if we don't care for OnClick (CtrlDown<>CtrlUp) - just release the CtrDown as usual
  if CtrlDown <> CtrlUp then
    CtrlDown := nil
  else
    fCtrlDown := nil;


  // Notify all ControlMouseUp subscribers
  for I := 0 to fMouseUpSubsList.Count - 1 do
    if Assigned(fMouseUpSubsList[I]) then
      fMouseUpSubsList[I](CtrlUp, X, Y, Shift, Button);

//  fMasterPanel.ControlMouseUp(CtrlUp, X, Y, Shift, Button); // Must be invoked before CtrlUp.MouseUp to avoid problems on game Exit

  if CtrlUp <> nil then
    CtrlUp.MouseUp(X, Y, Shift, Button);

  //Do not place any code here, we could have Exited in OnClick event
end;


procedure TKMMasterControl.MouseWheel(X,Y: Integer; WheelSteps: Integer; var aHandled: Boolean);
var
  ctrl: TKMControl;
begin
  if Self = nil then Exit;

  ctrl := HitControl(X, Y);
  if ctrl <> nil then
    ctrl.MouseWheel(ctrl, WheelSteps, aHandled);
end;


// Paint controls
// Leave painting of childs to their parent control
procedure TKMMasterControl.Paint;
var
  str: string;
begin
  if Self = nil then Exit;

  CtrlPaintCount := 0;
  fMasterPanel.Paint;

  if MODE_DESIGN_CONTROLS and (CtrlOver <> nil) then
  begin
    if GetKeyState(VK_CONTROL) < 0 then
      str := Format('%d:%d/%d:%d', [CtrlOver.AbsLeft, CtrlOver.AbsTop, CtrlOver.Width, CtrlOver.Height])
    else
      str := Format('%d:%d/%d:%d', [CtrlOver.Left, CtrlOver.Top, CtrlOver.Width, CtrlOver.Height]);

    TKMRenderUI.WriteText(CtrlOver.AbsLeft, CtrlOver.AbsTop - 14, 0, str, fntGrey, taLeft);
  end;
end;


procedure TKMMasterControl.SaveToFile(const aFileName: UnicodeString);
var
  ft: Textfile;
begin
  if Self = nil then Exit;

  AssignFile(ft,aFileName);
  Rewrite(ft);

  //fCtrl.SaveToFile; //Will save all the childs as well, recursively alike Paint or HitControl
  //writeln(ft, ClassName);
  //writeln(ft, Format('[%d %d %d %d]', [fLeft, fTop, fWidth, fHeight]));

  CloseFile(ft);
end;


{ TKMControl.TKMKeyPress }
//function TKMControl.TKMKeyPress.ToString: string;
//var
//  kindStr: string;
//begin
//  case Kind of
//    kpkDown:  kindStr := 'Down';
//    kpkPress: kindStr := 'Press';
//    else      kindStr := 'unknown';
//  end;
////  Result := Format('T=%d %s Key=%d C=%s ', [Integer(Time), kpkPress, Key, String(C)]);
//  Result := Format('T=%d %s C=%d ', [Integer(Time), kindStr, {Key, }Ord(c)]);
//end;


end.


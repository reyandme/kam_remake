unit KM_ControlsEdit;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_Controls, KM_ControlsBase, KM_ControlsTypes,
  KM_RenderUI,
  KM_ResFonts,
  KM_Points;


type
  // Basic Edit class with selection available
  TKMSelectableEdit = class abstract(TKMControl)
  private
    fFont: TKMFont;
    fLeftIndex: Integer; //The position of the character shown left-most when text does not fit

    fCursorPos: Integer;
    fSelectable: Boolean;
    fSelectionStart: Integer;
    fSelectionEnd: Integer;
    fSelectionInitialPos: Integer;

    procedure SetCursorPos(aPos: Integer);
    function GetCursorPosAt(X: Integer): Integer;
    procedure ResetSelection;
    function HasSelection: Boolean;
    function GetSelectedText: UnicodeString;
    procedure SetSelectionStart(aValue: Integer);
    procedure SetSelectionEnd(aValue: Integer);
    procedure DeleteSelectedText;
    procedure SetSelections(aValue1, aValue2: Integer);
    procedure UpdateSelection(aOldCursorPos: Integer; aIsSelecting: Boolean);
  protected
    fText: UnicodeString;
    procedure SelEditCtrlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    procedure FocusChanged(aFocused: Boolean); override;
    function GetMaxLength: Word; virtual; abstract;
    function IsCharValid(aChar: WideChar): Boolean; virtual; abstract;
    procedure ValidateText(aTriggerOnChange: Boolean = True); virtual;
    function KeyEventHandled(Key: Word; Shift: TShiftState): Boolean; virtual; abstract;
    procedure PaintSelection;
    function DrawEolSymbol: Boolean; virtual;
    function DoShowMarkup: Boolean; virtual;
//    function GetControlMouseDownProc: TKMMouseUpDownEvent; virtual;

    procedure Changed;
  public
    ReadOnly: Boolean;
    BlockInput: Boolean; // Blocks all input into the field, but allow focus, selection and copy selected text

    OnChange: TNotifyEvent;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aSelectable: Boolean = True);

    property CursorPos: Integer read fCursorPos write SetCursorPos;
    property Selectable: Boolean read fSelectable write fSelectable;
    property SelectionStart: Integer read fSelectionStart write SetSelectionStart;
    property SelectionEnd: Integer read fSelectionEnd write SetSelectionEnd;
    procedure MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    function KeyDown(Key: Word; Shift: TShiftState): Boolean; override;
    procedure KeyPress(Key: Char); override;
    function KeyUp(Key: Word; Shift: TShiftState): Boolean; override;
  end;

  // Edit for text
  TKMEdit = class(TKMSelectableEdit)
  private
    fAllowedChars: TKMAllowedChars;
    procedure SetText(const aText: UnicodeString);
  protected
    function GetMaxLength: Word; override;
    function IsCharValid(aChar: WideChar): Boolean; override;
    procedure ValidateText(aTriggerOnChange: Boolean = True); override;
    function KeyEventHandled(Key: Word; Shift: TShiftState): Boolean; override;
    function GetRText: UnicodeString;
    function DrawEolSymbol: Boolean; override;
    function DoShowMarkup: Boolean; override;
  public
    Masked: Boolean; //Mask entered text as *s
    MaxLen: Word;
    ShowColors: Boolean;
    DrawOutline: Boolean;
    OutlineColor: Cardinal;
    OnIsKeyEventHandled: TNotifyEventKeyFunc; //Invoked to check is key overrides default handle policy or not
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aSelectable: Boolean = True);

    property AllowedChars: TKMAllowedChars read fAllowedChars write fAllowedChars;
    property Text: UnicodeString read fText write SetText;
    procedure UpdateText(const aText: UnicodeString; aTriggerOnChange: Boolean = True);
    procedure SetTextSilently(const aText: UnicodeString);

    function HitTest(X, Y: Integer; aIncludeDisabled: Boolean = False; aIncludeNotHitable: Boolean = False): Boolean; override;
    procedure Paint; override;
  end;


  TKMFilenameEdit = class(TKMEdit)
  private
    function GetIsValid: Boolean;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aSelectable: Boolean = True);

    property IsValid: Boolean read GetIsValid;
  end;


  TKMNumericEdit = class(TKMSelectableEdit)
  private
    fButtonInc: TKMButton;
    fButtonDec: TKMButton;
    fValue: Integer;
    procedure ButtonClick(Sender: TObject; Shift: TShiftState);

    procedure SetValueNCheckRange(aValue: Int64);
    procedure SetValue(aValue: Integer);
    procedure CheckValueOnUnfocus;
    procedure ClickHold(Sender: TObject; Button: TMouseButton; var aHandled: Boolean);
  protected
    procedure SetLeft(aValue: Integer); override;
    procedure SetTop(aValue: Integer); override;
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    procedure SetHint(const aValue: UnicodeString); override;
    function GetSelfAbsLeft: Integer; override;
    function GetSelfWidth: Integer; override;
    function GetMaxLength: Word; override;
    function IsCharValid(Key: WideChar): Boolean; override;
    procedure ValidateText(aTriggerOnChange: Boolean = True); override;
    procedure FocusChanged(aFocused: Boolean); override;
    function KeyEventHandled(Key: Word; Shift: TShiftState): Boolean; override;
    procedure NumEdCtrlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    function DoHandleMouseWheelByDefault: Boolean; override;
  public
    ValueMin: Integer;
    ValueMax: Integer;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aValueMin, aValueMax: Integer; aFont: TKMFont = fntGrey; aSelectable: Boolean = True);
    property Value: Integer read fValue write SetValue;

    function KeyDown(Key: Word; Shift: TShiftState): Boolean; override;
    procedure MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean); override;
    procedure Paint; override;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Clipbrd,
  SysUtils, StrUtils, Math,
  KromUtils, KromOGLUtils,
  KM_ControlsUtils,
  KM_Resource, KM_ResTypes,
  KM_CommonTypes, KM_Defaults,
  KM_CommonUtils, KM_UtilsExt;


{ TKMSelectableEdit }
constructor TKMSelectableEdit.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aSelectable: Boolean);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);
  fFont := aFont;
  CursorPos := 0;

  //Text input fields are focusable by concept
  Focusable := True;
  ReadOnly := False;
  BlockInput := False;
  fSelectable := aSelectable;

  // Subscribe to get other controls mouse down events
  // Descendants of TKMSelectableEdit could add more event handlers
  aParent.MasterControl.AddMouseDownCtrlSub(SelEditCtrlMouseDown);
end;


procedure TKMSelectableEdit.DeleteSelectedText;
begin
  Delete(fText, fSelectionStart+1, fSelectionEnd-fSelectionStart);

  if CursorPos = fSelectionEnd then
    CursorPos := CursorPos - (fSelectionEnd-fSelectionStart);

  ResetSelection;
end;


function TKMSelectableEdit.GetCursorPosAt(X: Integer): Integer;
var
  rText: UnicodeString;
begin
  rText := Copy(fText, fLeftIndex+1, Length(fText) - fLeftIndex);
  if gRes.Fonts[fFont].GetTextSize(rText, DoShowMarkup, DrawEolSymbol).X < X-SelfAbsLeft-4 then
    Result := Length(rText) + fLeftIndex
  else
    Result := gRes.Fonts[fFont].CharsThatFit(rText, X-SelfAbsLeft-4, DoShowMarkup, DrawEolSymbol) + fLeftIndex;
end;


function TKMSelectableEdit.GetSelectedText: UnicodeString;
begin
  Result := '';
  if HasSelection then
    Result := Copy(fText, fSelectionStart+1, fSelectionEnd - fSelectionStart);
end;


function TKMSelectableEdit.HasSelection: Boolean;
begin
  Result := (fSelectionStart <> -1) and (fSelectionEnd <> -1) and (fSelectionStart <> fSelectionEnd);
end;


procedure TKMSelectableEdit.ResetSelection;
begin
  fSelectionStart := -1;
  fSelectionEnd := -1;
  fSelectionInitialPos := -1;
end;


procedure TKMSelectableEdit.SetSelectionEnd(aValue: Integer);
begin
  if fSelectable then
    fSelectionEnd := EnsureRange(aValue, 0, Length(fText));
end;


procedure TKMSelectableEdit.SetSelectionStart(aValue: Integer);
begin
  if fSelectable then
    fSelectionStart := EnsureRange(aValue, 0, Length(fText));
end;


//Set selections with pair of value, using he fact, that fSelectionStart <= fSelectionEnd
procedure TKMSelectableEdit.SetSelections(aValue1, aValue2: Integer);
begin
  SelectionStart := Min(aValue1, aValue2);
  SelectionEnd := Max(aValue1, aValue2);
end;


procedure TKMSelectableEdit.ValidateText(aTriggerOnChange: Boolean = True);
begin
  if aTriggerOnChange then
    Changed;
end;


procedure TKMSelectableEdit.Changed;
begin
  // OnChange should be called here, since we changed the input and don't want to wait until KeyUp event
  if Assigned(OnChange) then
    OnChange(Self);
end;


procedure TKMSelectableEdit.SetCursorPos(aPos: Integer);
var
  rText: UnicodeString;
begin
  fCursorPos := EnsureRange(aPos, 0, Length(fText));
  if fCursorPos < fLeftIndex then
    fLeftIndex := fCursorPos
  else
  begin
    //Remove characters to the left of fLeftIndex
    rText := Copy(fText, fLeftIndex+1, Length(fText));
    while fCursorPos-fLeftIndex > gRes.Fonts[fFont].CharsThatFit(rText, Width-8, False, DrawEolSymbol) do
    begin
      Inc(fLeftIndex);
      //Remove characters to the left of fLeftIndex
      rText := Copy(fText, fLeftIndex+1, Length(fText));
    end;
  end;
end;


//Update selection start/end due to change cursor position
procedure TKMSelectableEdit.UpdateSelection(aOldCursorPos: Integer; aIsSelecting: Boolean);
begin
  if aIsSelecting then
  begin
    if HasSelection then
    begin
      if aOldCursorPos = SelectionStart then
        SetSelections(CursorPos, SelectionEnd)
      else
      if aOldCursorPos = SelectionEnd then
        SetSelections(SelectionStart, CursorPos);
    end else
      SetSelections(aOldCursorPos, CursorPos);
  end
  else
    ResetSelection;
end;


function TKMSelectableEdit.KeyDown(Key: Word; Shift: TShiftState): Boolean;

  // Update cursor pos considering Ctrl Key to go to the next / prev word in the text
  procedure UpdateCursorPos(aCursorDir: TKMCursorDir);
  begin
    if ssCtrl in Shift then
    begin
      case aCursorDir of
        cdNone:     ;
        cdForward:  CursorPos := GetNextWordPos(fText, CursorPos);
        cdBack:     CursorPos := GetPrevWordPos(fText, CursorPos);
      end;
    end
    else
      CursorPos := CursorPos + ShortInt(aCursorDir);
  end;

var
  oldCursorPos: Integer;
begin
  Result := KeyEventHandled(Key, Shift);
  if inherited KeyDown(Key, Shift) or ReadOnly then Exit;

  //Allow some keys while blocking input
  if BlockInput
    and not ((Key in [VK_LEFT, VK_RIGHT, VK_HOME, VK_END])
      or ((ssCtrl in Shift) and (Key in [VK_LEFT, VK_RIGHT, Ord('A'), Ord('C')]))) then Exit;

  oldCursorPos := CursorPos;

  //Clipboard operations
  if (Shift = [ssCtrl]) and (Key <> VK_CONTROL) then
    case Key of
      Ord('A'): begin
                  SelectionStart := 0;
                  SelectionEnd := Length(fText);
                end;
      Ord('C'): if HasSelection then
                  Clipboard.AsText := GetSelectedText;
      Ord('X'): if HasSelection then
                begin
                  Clipboard.AsText := GetSelectedText;
                  DeleteSelectedText;
                  ValidateText;
                end;
      Ord('V'): begin
                  if HasSelection then
                  begin
                    Delete(fText, fSelectionStart + 1, fSelectionEnd-fSelectionStart);
                    Insert(Clipboard.AsText, fText, fSelectionStart + 1);
                    ValidateText;
                    if CursorPos = fSelectionStart then
                      CursorPos := CursorPos + Length(Clipboard.AsText)
                    else if CursorPos = fSelectionEnd then
                      CursorPos := CursorPos + Length(Clipboard.AsText) - (fSelectionEnd-fSelectionStart);
                    ResetSelection;
                  end else begin
                    Insert(Clipboard.AsText, fText, CursorPos + 1);
                    ValidateText;
                    CursorPos := CursorPos + Length(Clipboard.AsText);
                  end;
                end;
    end;

  case Key of
    VK_BACK:    if HasSelection then
                begin
                  DeleteSelectedText;
                  ValidateText;
                end
                else
                begin
                  Delete(fText, CursorPos, 1);
                  CursorPos := CursorPos - 1;
                  ValidateText;
                end;
    VK_DELETE:  if HasSelection then
                begin
                  DeleteSelectedText;
                  ValidateText;
                end
                else
                begin
                  Delete(fText, CursorPos + 1, 1);
                  ValidateText;
                end;
  end;

  case Key of
    VK_LEFT,
    VK_RIGHT: begin
                UpdateCursorPos(GetCursorDir(Key));
                UpdateSelection(oldCursorPos, IsSelecting(Key, Shift));
              end;
    VK_HOME:  begin
                CursorPos := 0;
                UpdateSelection(oldCursorPos, IsSelecting(Key, Shift));
              end;
    VK_END:   begin
                CursorPos := Length(fText);
                UpdateSelection(oldCursorPos, IsSelecting(Key, Shift));
              end;
  end;
end;


procedure TKMSelectableEdit.KeyPress(Key: Char);
begin
  inherited;

  if ReadOnly or BlockInput then Exit;

  if HasSelection and IsCharValid(Key) then
    DeleteSelectedText
  else
  if Length(fText) >= GetMaxLength then Exit;

  Insert(Key, fText, CursorPos + 1);
  CursorPos := CursorPos + 1; //Before ValidateText so it moves the cursor back if the new char was invalid
  ValidateText; //Validate text at the end of all changes (delete selected and insert)
end;


function TKMSelectableEdit.KeyUp(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := KeyEventHandled(Key, Shift);
  if inherited KeyUp(Key, Shift) or ReadOnly then Exit;
end;


procedure TKMSelectableEdit.MouseDown(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  oldCursorPos: Integer;
begin
  if ReadOnly then Exit;
  inherited;
  // Update Focus now, because we need to focus on MouseDown, not on MouseUp as by default for all controls
  MasterParent.MasterControl.UpdateFocus(Self);

  oldCursorPos := CursorPos;
  CursorPos := GetCursorPosAt(X);

  if Focusable then
  begin
    //Try select on Shift + LMB click
    UpdateSelection(oldCursorPos, (oldCursorPos <> -1) and (Shift = [ssLeft, ssShift]));
    fSelectionInitialPos := CursorPos;
  end;
end;


procedure TKMSelectableEdit.MouseMove(X, Y: Integer; Shift: TShiftState);
var
  curCursorPos, oldCursorPos: Integer;
begin
  if ReadOnly then Exit;
  inherited;
  if (ssLeft in Shift) and (fSelectionInitialPos <> -1) then
  begin
    curCursorPos := GetCursorPosAt(X);
    // To rotate line to left while selecting
    if (X-SelfAbsLeft-4 < 0) and (fLeftIndex > 0) then
      curCursorPos := curCursorPos - 1;

    oldCursorPos := CursorPos;
    CursorPos := CurCursorPos;
    UpdateSelection(oldCursorPos, True);
  end;
end;


procedure TKMSelectableEdit.MouseUp(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  if ReadOnly then Exit;
  inherited;
  fSelectionInitialPos := -1;
end;


procedure TKMSelectableEdit.PaintSelection;
var
  beforeSelectionText, selectionText: UnicodeString;
  beforeSelectionW, selectionW: Integer;
begin
  if HasSelection then
  begin
    beforeSelectionText := Copy(fText, fLeftIndex+1, max(fSelectionStart, fLeftIndex) - fLeftIndex);
    selectionText := Copy(fText, max(fSelectionStart, fLeftIndex)+1, fSelectionEnd - max(fSelectionStart, fLeftIndex));

    beforeSelectionW := gRes.Fonts[fFont].GetTextSize(beforeSelectionText, DoShowMarkup, DrawEolSymbol).X;
    selectionW := gRes.Fonts[fFont].GetTextSize(selectionText, DoShowMarkup, DrawEolSymbol).X;

    TKMRenderUI.WriteShape(SelfAbsLeft+4+beforeSelectionW, AbsTop+3, min(selectionW, Width-8), Height-6, clTextSelection);
  end;
end;


function TKMSelectableEdit.DrawEolSymbol: Boolean;
begin
  Result := False; //EOL is not showing by default
end;


function TKMSelectableEdit.DoShowMarkup: Boolean;
begin
  Result := False; // Markup is not showing by default
end;


procedure TKMSelectableEdit.SelEditCtrlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  if (Sender <> Self) then
    ResetSelection;
end;


//function TKMSelectableEdit.GetControlMouseDownProc: TKMMouseUpDownEvent;
//begin
//  Result := ControlMouseDown;
//end;


procedure TKMSelectableEdit.FocusChanged(aFocused: Boolean);
begin
  inherited;
  if not aFocused then
    ResetSelection;
end;


{ TKMEdit }
constructor TKMEdit.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aSelectable: Boolean = True);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight, aFont, aSelectable);
  fAllowedChars := acText; //Set to the widest by default
  MaxLen := 256; //Default max length to prevent chat spam
end;


function TKMEdit.GetMaxLength: Word;
begin
  Result := MaxLen;
end;


function TKMEdit.GetRText: UnicodeString;
begin
  if Masked then
    Result := StringOfChar('*', Length(fText))
  else
    Result := fText;
  Result := Copy(Result, fLeftIndex+1, Length(Result));
end;


function TKMEdit.DrawEolSymbol: Boolean;
begin
  Result := AllowedChars = acAll;
end;


function TKMEdit.DoShowMarkup: Boolean;
begin
  Result := ShowColors;
end;


function TKMEdit.HitTest(X, Y: Integer; aIncludeDisabled: Boolean = False; aIncludeNotHitable: Boolean = False): Boolean;
begin
  //When control is read-only we don't want to recieve Focus event
  Result := inherited HitTest(X,Y) and not ReadOnly;
end;


procedure TKMEdit.SetText(const aText: UnicodeString);
begin
  UpdateText(aText);
  //Setting the text should place cursor to the end
  fLeftIndex := 0;
  SetCursorPos(Length(Text));
end;


procedure TKMEdit.UpdateText(const aText: UnicodeString; aTriggerOnChange: Boolean = True);
begin
  fText := aText;
  ValidateText(aTriggerOnChange); //Validate first since it could change fText
  CursorPos := Math.Min(CursorPos, Length(fText));
end;


procedure TKMEdit.SetTextSilently(const aText: UnicodeString);
begin
  UpdateText(aText, False);
end;


function TKMEdit.IsCharValid(aChar: WideChar): Boolean;
begin
  Result := IsCharAllowed(aChar, fAllowedChars);
end;


//Validates fText basing on predefined sets of allowed or disallowed chars
//It iterates from end to start of a string - deletes chars and moves cursor appropriately
procedure TKMEdit.ValidateText(aTriggerOnChange: Boolean = True);
var
  I: Integer;
begin
  //Parse whole text incase user placed it from clipboard
  //Validate contents
  for I := Length(fText) downto 1 do
    if not IsCharValid(fText[I]) then
    begin
      Delete(fText, I, 1);
      if CursorPos >= I then //Keep cursor in place
        CursorPos := CursorPos - 1;
    end;

  //Validate length
  if Length(fText) > MaxLen then
    fText := Copy(fText, 0, MaxLen);

  inherited ValidateText(aTriggerOnChange); //Could trigger OnChange event
end;


//Key events which have no effect should not be handled (allows scrolling while chat window open with no text entered)
function TKMEdit.KeyEventHandled(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;

  //Don't include backspace/delete because edits should always handle those. Otherwise when you
  //press backspace repeatedly to remove all characters it will apply other shortcuts like
  //resetting the zoom if you press it once too many times.
  case Key of
    VK_UP,
    VK_DOWN,
    VK_LEFT,
    VK_RIGHT,
    VK_HOME,
    VK_END: Result := (fText <> ''); //These keys have no effect when text is blank
  end;

  //We want these keys to be ignored by TKMEdit
  if Key in [VK_F1..VK_F12, VK_ESCAPE, VK_RETURN, VK_TAB, VK_MBUTTON] then Result := False;

  //Ctrl can be used as an escape character, e.g. CTRL+B places beacon while chat is open
  if ssCtrl in Shift then Result := (Key in [VK_LEFT, VK_RIGHT, Ord('A'), Ord('C'), Ord('X'), Ord('V')]);

  // If key is ignored, then check if can still handle it (check via OnIsKeyEventHandled)
  if not Result and Assigned(OnIsKeyEventHandled) then
    Result := OnIsKeyEventHandled(Self, Key);
end;


procedure TKMEdit.Paint;
var
  col: TColor4;
  rText: UnicodeString;
  offX: Integer;
begin
  inherited;

  if DrawOutline then
  begin
    TKMRenderUI.WriteShape(AbsLeft-1, AbsTop-1, Width+2, Height+2, $00000000, OutlineColor);
    TKMRenderUI.WriteShape(AbsLeft-2, AbsTop-2, Width+4, Height+4, $00000000, OutlineColor);
  end;

  TKMRenderUI.WriteBevel(AbsLeft, AbsTop, Width, Height);

  if not Enabled then
    col := icGray2
  else if BlockInput then
    col := icLightGray
  else
    col := icWhite;

  if Masked then
    rText := StringOfChar('*', Length(fText))
  else
    rText := fText;
  rText := Copy(fText, fLeftIndex+1, Length(fText)); //Remove characters to the left of fLeftIndex

  PaintSelection;

  //Characters that do not fit are trimmed
  TKMRenderUI.WriteText(AbsLeft+4, AbsTop+3, Width-8, rText, fFont, taLeft, col, not ShowColors, True, DrawEolSymbol);

  //Render text cursor
  if (csFocus in State) and ((TimeGet div 500) mod 2 = 0) then
  begin
    SetLength(rText, CursorPos - fLeftIndex);
    offX := AbsLeft + 2 + gRes.Fonts[fFont].GetTextSize(rText, True, DrawEolSymbol).X;
    TKMRenderUI.WriteShape(offX, AbsTop+2, 3, Height-4, col, $FF000000);
  end;
end;


{ TKMFilenameEdit }
constructor TKMFilenameEdit.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aSelectable: Boolean = True);
const
  MAX_SAVENAME_LENGTH = 50;
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight, aFont, aSelectable);

  fAllowedChars := acFileName; // Set to the widest by default
  MaxLen := MAX_SAVENAME_LENGTH;
end;


function TKMFilenameEdit.GetIsValid: Boolean;
const
  // Windows has the following reserved folder names, according to:
  // https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
  WIN_RESERVED_FILENAMES: array [0..21] of string = (
    'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6',
    'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7',
    'LPT8', 'LPT9');
var
  S, txt: string;
begin
  txt := Trim(fText);
  Result := (txt <> '') and (RightStr(txt, 1) <> '.');
  if not Result then Exit;

  for S in WIN_RESERVED_FILENAMES do
    if S = txt.ToUpper then
      Exit(False);
end;


{ TKMNumericEdit }
constructor TKMNumericEdit.Create(aParent: TKMPanel; aLeft, aTop, aValueMin, aValueMax: Integer; aFont: TKMFont = fntGrey; aSelectable: Boolean = True);
var
  W: Word;
begin
  // Text width + padding + buttons
  W := Max(gRes.Fonts[fntGrey].GetTextSize(IntToStr(aValueMax)).X, gRes.Fonts[fntGrey].GetTextSize(IntToStr(aValueMin)).X) + 10 + 20 + 20;

  inherited Create(aParent, aLeft, aTop, W, 20, aFont, aSelectable);

  ReadOnly := False;

  ValueMin := aValueMin;
  ValueMax := aValueMax;
  Value := 0;

  fButtonDec := TKMButton.Create(aParent, aLeft,           aTop, 20, 20, '-', bsGame);
  fButtonInc := TKMButton.Create(aParent, aLeft + W - 20,  aTop, 20, 20, '+', bsGame);
  fButtonInc.CapOffsetY := 1;
  fButtonDec.OnClickShift := ButtonClick;
  fButtonInc.OnClickShift := ButtonClick;
  fButtonDec.OnMouseWheel := MouseWheel;
  fButtonInc.OnMouseWheel := MouseWheel;
  fButtonDec.OnClickHold := ClickHold;
  fButtonInc.OnClickHold := ClickHold;

  // Subscribe to get other controls mouse down events
  aParent.MasterControl.AddMouseDownCtrlSub(NumEdCtrlMouseDown);
end;


procedure TKMNumericEdit.ClickHold(Sender: TObject; Button: TMouseButton; var aHandled: Boolean);
var
  amt: Integer;
begin
  inherited;
  aHandled := True;

  amt := GetMultiplicator(Button);

  if Sender = fButtonDec then
    Value := Value - amt
  else
  if Sender = fButtonInc then
    Value := Value + amt;

  if (amt <> 0) and Assigned(OnChange) then
    OnChange(Self);
end;


function TKMNumericEdit.KeyDown(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := KeyEventHandled(Key, Shift);
  inherited KeyDown(Key, Shift);

  case Key of
    VK_UP:      begin
                  SetValueNCheckRange(Int64(Value) + 1 + 9*Byte(ssShift in Shift));
                  Changed;
                end;
    VK_DOWN:    begin
                  SetValueNCheckRange(Int64(Value) - 1 - 9*Byte(ssShift in Shift));
                  Changed;
                end;
    VK_DELETE:  ValidateText; //Update value, cause we just deleted text and KeyPress was not invoked
  end;
end;


function TKMNumericEdit.KeyEventHandled(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;

  //Don't include backspace/delete because edits should always handle those. Otherwise when you
  //press backspace repeatedly to remove all characters it will apply other shortcuts like
  //resetting the zoom if you press it once too many times.
  case Key of
    VK_LEFT,
    VK_RIGHT,
    VK_HOME,
    VK_END: Result := (fText <> ''); //These keys have no effect when text is blank
  end;

  //We want these keys to be ignored by TKMNumericEdit
  if Key in [VK_F1..VK_F12, VK_ESCAPE, VK_RETURN, VK_TAB, VK_MBUTTON] then Result := False;

  //Ctrl can be used as an escape character, e.g. CTRL+B places beacon while chat is open
  if ssCtrl in Shift then
    Result := (Key in [VK_LEFT, VK_RIGHT, Ord('A'), Ord('C'), Ord('X'), Ord('V')]);
end;


function TKMNumericEdit.GetMaxLength: Word;
var
  minValue: Integer;
begin
  if ValueMin = Low(Integer) then
    minValue := ValueMin + 1  // to prevent integer overflow, when take Abs(MinValue);
  else
    minValue := ValueMin;

  if (Max(Abs(ValueMax), Abs(minValue)) <> 0) then
    Result := Trunc(Max(Log10(Abs(ValueMax)) + Byte(ValueMax < 0), Log10(Abs(minValue)) + Byte(minValue < 0))) + 1
  else
    Result := 1;
end;


function TKMNumericEdit.DoHandleMouseWheelByDefault: Boolean;
begin
  Result := False;
end;


procedure TKMNumericEdit.MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  inherited;

  if aHandled then Exit;

  SetValueNCheckRange(Int64(Value) + WheelSteps*(1 + 9*Byte(GetKeyState(VK_SHIFT) < 0)));

  aHandled := WheelSteps <> 0;

  Focus;

  if Assigned(OnChange) then
    OnChange(Self);
end;


procedure TKMNumericEdit.ButtonClick(Sender: TObject; Shift: TShiftState);
begin
  if Sender = fButtonDec then
    SetValueNCheckRange(Int64(Value) - GetMultiplicator(Shift))
  else
  if Sender = fButtonInc then
    SetValueNCheckRange(Int64(Value) + GetMultiplicator(Shift))
  else
    Exit;

  Focus;

  if Assigned(OnChange) then
    OnChange(Self);
end;


procedure TKMNumericEdit.SetTop(aValue: Integer);
begin
  inherited;

  fButtonDec.Top := Top;
  fButtonInc.Top := Top;
end;


procedure TKMNumericEdit.SetLeft(aValue: Integer);
begin
  inherited;

  fButtonDec.Left := Left;
  fButtonInc.Left := Left + Width - 20;
end;


procedure TKMNumericEdit.SetEnabled(aValue: Boolean);
begin
  inherited;
  fButtonDec.Enabled := Enabled;
  fButtonInc.Enabled := Enabled;
end;


procedure TKMNumericEdit.SetHint(const aValue: UnicodeString);
begin
  inherited;
  fButtonDec.Hint := aValue;
  fButtonInc.Hint := aValue;
end;


procedure TKMNumericEdit.SetVisible(aValue: Boolean);
begin
  inherited;
  fButtonDec.Visible := IsSetVisible;
  fButtonInc.Visible := IsSetVisible;
end;


function TKMNumericEdit.GetSelfAbsLeft: Integer;
begin
  Result := AbsLeft + 20;
end;


function TKMNumericEdit.GetSelfWidth: Integer;
begin
  Result := Width - 40;
end;


function TKMNumericEdit.IsCharValid(Key: WideChar): Boolean;
begin
  Result := SysUtils.CharInSet(Key, ['0'..'9']) or ((Key = '-') and (ValueMin < 0));
end;


procedure TKMNumericEdit.SetValueNCheckRange(aValue: Int64);
begin
  SetValue(EnsureRange(aValue, Low(Integer), High(Integer)));
end;


procedure TKMNumericEdit.SetValue(aValue: Integer);
begin
  fValue := EnsureRange(aValue, ValueMin, ValueMax);
  fText := IntToStr(fValue);

  //External Value assignment should not generate OnChange event
end;


procedure TKMNumericEdit.ValidateText(aTriggerOnChange: Boolean = True);
var
  I: Integer;
  allowedChars: TSetOfAnsiChar;
  onlyMinus, isEmpty: Boolean;
begin
  isEmpty := (fText = #8); // When deleting text with Backspace last character is still in string - backspace character (#8)

  allowedChars := ['0'..'9'];
  //Validate contents
  for I := Length(fText) downto 1 do
  begin
    if I = 1 then Include(allowedChars, '-');

    if not KromUtils.CharInSet(fText[I], allowedChars) then
    begin
      Delete(fText, I, 1);
      if CursorPos >= I then //Keep cursor in place
        CursorPos := CursorPos - 1;
    end;
  end;

  onlyMinus := (fText = '-');

  if (fText = '') or onlyMinus or isEmpty then
    Value := 0
  else
    SetValueNCheckRange(StrToInt64(fText));

  if onlyMinus then fText := '-'; //Set text back to '-' while still editing.
  if isEmpty then fText := ''; //Set text back to '' while still editing.

  CursorPos := Min(CursorPos, Length(fText)); //In case we had leading zeros in fText string

  inherited ValidateText(aTriggerOnChange); //Could trigger OnChange event
end;


procedure TKMNumericEdit.Paint;
var
  col: TColor4;
  rText: UnicodeString;
  offX: Integer;
begin
  inherited;

  TKMRenderUI.WriteBevel(AbsLeft + 20, AbsTop, Width - 40, Height);

  if Enabled then
    col := $FFFFFFFF
  else
    col := $FF888888;

  rText := Copy(fText, fLeftIndex+1, Length(fText)); //Remove characters to the left of fLeftIndex

  PaintSelection;

  TKMRenderUI.WriteText(AbsLeft+24, AbsTop+3, 0, fText, fFont, taLeft, col); //Characters that do not fit are trimmed

  //Render text cursor
  if (csFocus in State) and ((TimeGet div 500) mod 2 = 0) then
  begin
    SetLength(rText, CursorPos - fLeftIndex);
    offX := AbsLeft + 22 + gRes.Fonts[fFont].GetTextSize(rText).X;
    TKMRenderUI.WriteShape(offX, AbsTop+2, 3, Height-4, col, $FF000000);
  end;
end;


procedure TKMNumericEdit.CheckValueOnUnfocus;
begin
  if (fText = '-') or (fText = '') then //after unfocus, if only '-' is in string, set value to 0
    Value := 0;
end;


procedure TKMNumericEdit.FocusChanged(aFocused: Boolean);
begin
  inherited;
  if not aFocused then
    CheckValueOnUnfocus;
end;


procedure TKMNumericEdit.NumEdCtrlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  if (Sender <> Self) then
    CheckValueOnUnfocus;
end;


end.


unit KM_ControlsMemo;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_Controls, KM_ControlsScroll,
  KM_RenderUI, KM_ResFonts,
  KM_CommonTypes, KM_Points;


type
  TKMMemo = class(TKMControl)
  private
    fFont: TKMFont; //Should not be changed from inital value, it will mess up the word wrapping
    fItemHeight: Byte;
    fItems: TStringList;
    fWordWrap: Boolean;
    fIndentAfterNL: Boolean;
    fText: UnicodeString;
    fScrollDown: Boolean;
    fScrollBar: TKMScrollBar;
    fOnChange: TNotifyEvent;
    fCursorPos: Integer;
    fSelectable: Boolean;
    fSelectionStart: Integer;
    fSelectionEnd: Integer;
    fSelectionInitialPos: Integer;

    procedure SetWordWrap(const Value: Boolean);
    function GetText: UnicodeString;
    procedure SetText(const aText: UnicodeString);
    function GetTopIndex: smallint;
    procedure SetTopIndex(aIndex: SmallInt);
    procedure ReformatText;
    procedure UpdateScrollBar;

    function KeyEventHandled(Key: Word; Shift: TShiftState): Boolean;

    procedure SetCursorPos(aPos: Integer);
    function LinearToPointPos(aPos: Integer): TKMPoint;
    function PointToLinearPos(aColumn, aRow: Integer): Integer;
    function GetCharPosAt(X,Y: Integer): TKMPoint;
    function GetCursorPosAt(X,Y: Integer): Integer;
    procedure ResetSelection;
    function HasSelection: Boolean;
    function GetPlainText(aUsePipeAsEOL: Boolean; aStart: Integer = -1; aEnd: Integer = -1): UnicodeString;
    function GetSelectedText: UnicodeString;
    function GetMaxCursorPos: Integer;
    function GetMaxPosInRow(aRow: Integer): Integer;
    function GetMinPosInRow(aRow: Integer): Integer;
    function GetMaxCursorPosInRow: Integer;
    function GetMinCursorPosInRow: Integer;
    procedure SetSelectionStart(aValue: Integer);
    procedure SetSelectionEnd(aValue: Integer);
    procedure SetSelections(aValue1, aValue2: Integer);
    procedure UpdateSelection(aOldCursorPos: Integer; aIsSelecting: Boolean);
  protected
    procedure SetHeight(aValue: Integer); override;
    procedure SetWidth(aValue: Integer); override;
    procedure SetVisible(aValue: Boolean); override;
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetTop(aValue: Integer); override;
    procedure FocusChanged(aFocused: Boolean); override;
    procedure ControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
    function DoHandleMouseWheelByDefault: Boolean; override;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle; aSelectable: Boolean = True);
    destructor Destroy; override;

    procedure Add(const aItem: UnicodeString);
    procedure Clear;
    procedure ScrollToBottom;
    property WordWrap: Boolean read fWordWrap write SetWordWrap; //Whether to automatically wrap text within given text area width
    property IndentAfterNL: Boolean read fIndentAfterNL write fIndentAfterNL;
    property Text: UnicodeString read GetText write SetText;
    property ItemHeight: Byte read fItemHeight write fItemHeight;
    property TopIndex: Smallint read GetTopIndex write SetTopIndex;
    property ScrollDown: Boolean read fScrollDown write fScrollDown;
    property CursorPos: Integer read fCursorPos write SetCursorPos;
    property Selectable: Boolean read fSelectable write fSelectable;
    property SelectionStart: Integer read fSelectionStart write SetSelectionStart;
    property SelectionEnd: Integer read fSelectionEnd write SetSelectionEnd;

    function GetVisibleRows: Integer;
    function KeyDown(Key: Word; Shift: TShiftState): Boolean; override;
    function KeyUp(Key: Word; Shift: TShiftState): Boolean; override;
    procedure MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean); override;
    procedure MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;

    property OnChange: TNotifyEvent read fOnChange write fOnChange;

    procedure Paint; override;
  end;


implementation
uses
  KM_Defaults,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  SysUtils, StrUtils, Math,
  Clipbrd,
  KromUtils,
  KM_ControlsUtils,
  KM_Resource, KM_Render, KM_RenderTypes,
  KM_CommonUtils;


{ TKMMemo }
constructor TKMMemo.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle; aSelectable: Boolean = True);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);
  fItemHeight := 20;
  fItems := TStringList.Create;
  fFont := aFont;

  fScrollBar := TKMScrollBar.Create(aParent, aLeft+aWidth-20, aTop, 20, aHeight, saVertical, aStyle);
  UpdateScrollBar; //Initialise the scrollbar
  fSelectable := aSelectable;

  aParent.MasterControl.SubscribeOnOtherMouseDown(ControlMouseDown);
end;


destructor TKMMemo.Destroy;
begin
  fItems.Free;
  inherited;
end;


procedure TKMMemo.SetHeight(aValue: Integer);
begin
  inherited;
  fScrollBar.Height := Height;
  UpdateScrollBar; //Since height has changed
end;


procedure TKMMemo.SetWidth(aValue: Integer);
begin
  inherited;
  fScrollBar.Left := Left + Width - fScrollBar.Width;
  ReformatText; //Repositions the scroll bar as well
end;


//Copy property to scrollbar. Otherwise it won't be rendered
procedure TKMMemo.SetVisible(aValue: Boolean);
begin
  inherited;

  //Hide scrollbar and its buttons
  fScrollBar.Visible := IsSetVisible and (fScrollBar.MaxValue <> fScrollBar.MinValue);
end;


function TKMMemo.GetTopIndex: smallint;
begin
  Result := fScrollBar.Position;
end;


procedure TKMMemo.SetTopIndex(aIndex: smallint);
begin
  fScrollBar.Position := aIndex;
end;


procedure TKMMemo.SetEnabled(aValue: Boolean);
begin
  inherited;
  fScrollBar.Enabled := Enabled;
end;


procedure TKMMemo.SetTop(aValue: Integer);
begin
  inherited;
  fScrollBar.Top := Top;
end;


procedure TKMMemo.SetWordWrap(const Value: boolean);
begin
  fWordWrap := Value;
  ReformatText;
end;


function TKMMemo.GetText: UnicodeString;
begin
  Result := fText;
end;


procedure TKMMemo.SetText(const aText: UnicodeString);
begin
  fText := aText;
  ReformatText;

  if Assigned(fOnChange) then
    fOnChange(Self);
end;


procedure TKMMemo.ReformatText;
var
  newText: UnicodeString;
begin
  if fWordWrap then
    newText := gRes.Fonts[fFont].WordWrap(fText, Width - fScrollBar.Width - 8, True, IndentAfterNL)
  else
    newText := fText;

  //KaM uses | for new line, fItems.Text:= uses standard eol to parse each item from the string
  fItems.Text := StringReplace(newText, '|', EolW, [rfReplaceAll]);
  UpdateScrollBar;
end;


function TKMMemo.GetVisibleRows: Integer;
begin
  Result := Height div fItemHeight;
end;


//fItems.Count or Height has changed
procedure TKMMemo.UpdateScrollBar;
var
  oldMax: Integer;
begin
  oldMax := fScrollBar.MaxValue;
  fScrollBar.MaxValue := fItems.Count - GetVisibleRows;
  fScrollBar.Visible := IsSetVisible and (fScrollBar.MaxValue <> fScrollBar.MinValue);

  if fScrollDown then
  begin
    if oldMax - fScrollBar.Position <= 2 then //If they were near the bottom BEFORE updating, keep them at the bottom
      SetTopIndex(fItems.Count) //This puts it at the bottom because of the EnsureRange in SetTopIndex
  end
  else
    SetTopIndex(fScrollBar.Position);
end;


procedure TKMMemo.SetCursorPos(aPos: Integer);
begin
  fCursorPos := EnsureRange(aPos, 0, GetMaxCursorPos);
end;


function TKMMemo.GetPlainText(aUsePipeAsEOL: Boolean; aStart: Integer = -1; aEnd: Integer = -1): UnicodeString;
begin
  if aStart = -1 then
    aStart := 0;

  if aEnd = -1 then
    aEnd := Length(fItems.Text);

  // First remove EOL's to get correct positions in text
  Result := StringReplace(fItems.Text, EolW, '|', [rfReplaceAll]);
  // Get text with selected positions, cleaned of color markup
  Result := Copy(GetNoColorMarkupText(Result), aStart + 1, aEnd - aStart);
  // Return EOL's back
  if not aUsePipeAsEOL then
    Result := StringReplace(Result, '|', EolW, [rfReplaceAll]);
end;


function TKMMemo.GetSelectedText: UnicodeString;
begin
  Result := '';
  if HasSelection then
    Result := GetPlainText(False, fSelectionStart, fSelectionEnd);
end;


function TKMMemo.HasSelection: Boolean;
begin
  Result := (fSelectionStart <> -1) and (fSelectionEnd <> -1) and (fSelectionStart <> fSelectionEnd);
end;


procedure TKMMemo.ResetSelection;
begin
  fSelectionStart := -1;
  fSelectionEnd := -1;
  fSelectionInitialPos := -1;
end;


//We are using 2 systems for position: Linear (cumulative) and 'Point' (2D with column and row)
//Every system have Length(RowText)+1 positions in every line
//Convert Linear position into 2D position
function TKMMemo.LinearToPointPos(aPos: Integer): TKMPoint;
var I, row, column: Integer;
    rowText: UnicodeString;
    rowStartPos, rowEndPos: Integer;
begin
  row := 0;
  column := 0;
  for I := 0 to fItems.Count - 1 do
  begin
    rowText := GetNoColorMarkupText(fItems[I]);
    rowStartPos := PointToLinearPos(0, I);
    rowEndPos := rowStartPos + Length(rowText);
    if InRange(aPos, rowStartPos, rowEndPos) then
    begin
      row := I;
      column := aPos - rowStartPos;
      Break;
    end;
  end;
  Result := KMPoint(column, row);
end;


//We are using 2 systems for position: Linear (cumulative) and 'Point' (2D with column and row)
//Every system have Length(RowText)+1 positions in every line
//Convert 2D position into Linear position
function TKMMemo.PointToLinearPos(aColumn, aRow: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  aRow := EnsureRange(aRow, 0, fItems.Count-1);
  for I := 0 to aRow-1 do
    Inc(Result, Length(GetNoColorMarkupText(fItems[I])) + 1); //+1 for special KaM new line symbol ('|')
  Inc(Result, EnsureRange(aColumn, 0, GetMaxPosInRow(aRow)));
end;


//Return position of Cursor in 2D of point X,Y on the screen
function TKMMemo.GetCharPosAt(X,Y: Integer): TKMPoint;
var
  row, column: Integer;
begin
  row := 0;
  column := 0;

  if fItems.Count > 0 then
  begin
    row := (EnsureRange(Y-AbsTop-3, 0, Height-6) div fItemHeight) + TopIndex;
    row := EnsureRange(row, 0, fItems.Count-1);
    column := gRes.Fonts[fFont].CharsThatFit(GetNoColorMarkupText(fItems[row]), X-AbsLeft-4);
  end;
  Result := KMPoint(column, row);
end;


//Return position of Cursor in linear system of point X,Y on the screen
function TKMMemo.GetCursorPosAt(X,Y: Integer): Integer;
var
  charPos: TKMPoint;
begin
  charPos := GetCharPosAt(X, Y);
  Result := PointToLinearPos(charPos.X, charPos.Y);
end;


// Maximum possible position of Cursor
function TKMMemo.GetMaxCursorPos: Integer;
begin
  Result := Length(StringReplace(fItems.Text, EolW, '', [rfReplaceAll])) + EnsureRange(fItems.Count-1, 0, fItems.Count);
end;


// Minimum possible position of Cursor in its current Row
function TKMMemo.GetMinCursorPosInRow: Integer;
begin
  Result := GetMinPosInRow(LinearToPointPos(CursorPos).Y)
end;


// Maximum possible position of Cursor in its current Row
function TKMMemo.GetMaxCursorPosInRow: Integer;
begin
  Result := GetMaxPosInRow(LinearToPointPos(CursorPos).Y)
end;


// Minimum possible position of Cursor in the specified aRow
function TKMMemo.GetMinPosInRow(aRow: Integer): Integer;
begin
  if aRow = 0 then
    Result := 0
  else
    Result := GetMaxPosInRow(aRow - 1) + 1;
end;


// Maximum possible position of Cursor in the specified aRow
function TKMMemo.GetMaxPosInRow(aRow: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to min(aRow, fItems.Count - 1) do
    Inc(Result, Length(GetNoColorMarkupText(fItems[I])) + 1);
  Result := EnsureRange(Result - 1, 0, Result);
end;


procedure TKMMemo.SetSelectionStart(aValue: Integer);
var
  maxPos: Integer;
begin
  if fSelectable then
  begin
    maxPos := GetMaxCursorPos;
    fSelectionStart := EnsureRange(aValue, 0, maxPos);
  end;
end;


procedure TKMMemo.SetSelectionEnd(aValue: Integer);
var
  maxPos: Integer;
begin
  if fSelectable then
  begin
    maxPos := GetMaxCursorPos;
    fSelectionEnd := EnsureRange(aValue, 0, maxPos);
  end;
end;


//Set selections with pair of value, using he fact, that fSelectionStart <= fSelectionEnd
procedure TKMMemo.SetSelections(aValue1, aValue2: Integer);
begin
  fSelectionStart := Min(aValue1, aValue2);
  fSelectionEnd := Max(aValue1, aValue2);
end;


//Update selection start/end due to change cursor position
procedure TKMMemo.UpdateSelection(aOldCursorPos: Integer; aIsSelecting: Boolean);
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


procedure TKMMemo.Add(const aItem: UnicodeString);
begin
  if fText <> '' then
    fText := fText + '|';

  fText := fText + aItem; //Append the new string

  SetText(fText); //Updates the text in fItems
  UpdateScrollBar; //Scroll down with each item that is added.

  if Assigned(fOnChange) then
    fOnChange(Self);
end;


procedure TKMMemo.Clear;
begin
  fText := '';
  fItems.Clear;
  ResetSelection;
  UpdateScrollBar;

  if Assigned(fOnChange) then
    fOnChange(Self);
end;


procedure TKMMemo.ScrollToBottom;
begin
  SetTopIndex(fItems.Count);
end;


//Key events which have no effect should not be handled (allows scrolling while chat window open with no text entered)
function TKMMemo.KeyEventHandled(Key: Word; Shift: TShiftState): Boolean;
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
    VK_END,
    VK_PRIOR,
    VK_NEXT: Result := (fText <> ''); //These keys have no effect when text is blank
  end;

  //We want these keys to be ignored by chat, so game shortcuts still work
  if Key in [VK_F1..VK_F12, VK_ESCAPE, VK_MBUTTON] then Result := False;

  //Ctrl can be used as an escape character, e.g. CTRL+B places beacon while chat is open
  if ssCtrl in Shift then Result := (Key in [VK_LEFT, VK_RIGHT, Ord('A'), Ord('C'), Ord('X')]);
end;


function TKMMemo.KeyDown(Key: Word; Shift: TShiftState): Boolean;
  //Move cursor vertically (change cursor row)
  procedure MoveCursorVertically(aRowIncrement: Integer);
  var
    cursorPointPos: TKMPoint;
    newCursorPosY: Integer;
    srcLineText, destLineText: UnicodeString;
  begin
    cursorPointPos := LinearToPointPos(CursorPos);
    newCursorPosY := EnsureRange(cursorPointPos.Y + aRowIncrement, 0, fItems.Count-1);
    if newCursorPosY <> cursorPointPos.Y then
    begin
      // Because we don't use monospaces fonts, then its better to find proper column, which depends of text width in px
      srcLineText := GetNoColorMarkupText(Copy(fItems[cursorPointPos.Y], 1, cursorPointPos.X));
      destLineText := GetNoColorMarkupText(fItems[newCursorPosY]);
      //Use 'rounding' version of CharsThatFit to get more precise position
      cursorPointPos.X := gRes.Fonts[fFont].CharsThatFit(destLineText, gRes.Fonts[fFont].GetTextSize(srcLineText).X, True);
      CursorPos := PointToLinearPos(cursorPointPos.X, newCursorPosY);
      // Update scroll position, if needed
      if TopIndex > newCursorPosY then
        TopIndex := newCursorPosY
      else if TopIndex < newCursorPosY - GetVisibleRows + 1 then
        TopIndex := newCursorPosY - GetVisibleRows + 1;
    end;
  end;

  // Update cursor pos considering Ctrl Key to go to the next / prev word in the text
  procedure UpdateCursorPos(aCursorDir: TKMCursorDir);
  begin
    if ssCtrl in Shift then
    begin
      case aCursorDir of
        cdNone:     ;
        cdForward:  CursorPos := GetNextWordPos(GetPlainText(True), CursorPos);
        cdBack:     CursorPos := GetPrevWordPos(GetPlainText(True), CursorPos);
      end;
    end
    else
      CursorPos := CursorPos + ShortInt(aCursorDir);
  end;

var
  oldCursorPos: Integer;
  isSelect: Boolean;
begin
  Result := KeyEventHandled(Key, Shift);
  if inherited KeyDown(Key, Shift) then Exit;

  //Clipboard operations
  if (Shift = [ssCtrl]) and (Key <> VK_CONTROL) then
    case Key of
      Ord('A'): SetSelections(0, GetMaxCursorPos);
      Ord('C'),
      Ord('X'): if HasSelection then
                  Clipboard.AsText := GetSelectedText;
    end;

  oldCursorPos := CursorPos;
  isSelect := IsSelecting(Key, Shift);

  case Key of
    VK_LEFT,
    VK_RIGHT: begin
                UpdateCursorPos(GetCursorDir(Key));
                UpdateSelection(oldCursorPos, isSelect);
              end;
    VK_UP:    begin
                MoveCursorVertically(-1);
                UpdateSelection(oldCursorPos, isSelect);
              end;
    VK_DOWN:  begin
                MoveCursorVertically(1);
                UpdateSelection(oldCursorPos, isSelect);
              end;
    VK_PRIOR: begin
                MoveCursorVertically(-GetVisibleRows);
                UpdateSelection(oldCursorPos, isSelect);
              end;
    VK_NEXT:  begin
                MoveCursorVertically(GetVisibleRows);
                UpdateSelection(oldCursorPos, isSelect);
              end;
    VK_HOME:  begin
                CursorPos := GetMinCursorPosInRow;
                UpdateSelection(oldCursorPos, isSelect);
              end;
    VK_END:   begin
                CursorPos := GetMaxCursorPosInRow;
                UpdateSelection(oldCursorPos, isSelect);
              end;
  end
end;


function TKMMemo.KeyUp(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := inherited KeyUp(Key, Shift) or KeyEventHandled(Key, Shift);
end;


function TKMMemo.DoHandleMouseWheelByDefault: Boolean;
begin
  Result := False;
end;


procedure TKMMemo.MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  inherited;

  if aHandled then Exit;

  SetTopIndex(TopIndex - WheelSteps);

  aHandled := WheelSteps <> 0;
end;


procedure TKMMemo.MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  oldCursorPos: Integer;
begin
  inherited;

  Focusable := fSelectable and (fText <> ''); // Do not focus on empty Memo's
  // Update Focus now, because we need to focus on MouseDown, not on MouseUp as by default for all controls
  MasterParent.MasterControl.UpdateFocus(Self);

  oldCursorPos := CursorPos;
  CursorPos := GetCursorPosAt(X, Y);

  if Focusable then
  begin
    //Try select on Shift + LMB click
    UpdateSelection(oldCursorPos, (oldCursorPos <> -1) and (Shift = [ssLeft, ssShift]));
    fSelectionInitialPos := CursorPos;
  end;
end;


procedure TKMMemo.MouseMove(X,Y: Integer; Shift: TShiftState);
var
  oldCursorPos: Integer;
  charPos: TKMPoint;
begin
  inherited;
  if (ssLeft in Shift) and (fSelectionInitialPos <> -1) then
  begin
    charPos := GetCharPosAt(X, Y);

    // To rotate text to top while selecting
    if (Y-AbsTop-3 < 0) and (TopIndex > 0) then
    begin
      Dec(charPos.Y);
      SetTopIndex(TopIndex-1);
    end;
    // To rotate text to bottom while selecting
    if (Y-AbsTop-3 > Height)
      and (fScrollBar.Position < fScrollBar.MaxValue) then
    begin
      charPos.Y := EnsureRange(charPos.Y+1, 0, fItems.Count);
      SetTopIndex(TopIndex+1);
    end;

    oldCursorPos := CursorPos;
    CursorPos := PointToLinearPos(charPos.X, charPos.Y);;
    UpdateSelection(oldCursorPos, True);
  end;
end;


procedure TKMMemo.MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;
  fSelectionInitialPos := -1;
end;


procedure TKMMemo.ControlMouseDown(Sender: TObject; X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  // Reset all, if other control was clicked
  if Sender <> Self then
  begin
    ResetSelection;
    Focusable := False;
    CursorPos := -1;
    MasterParent.MasterControl.UpdateFocus(Self);
  end;
end;


procedure TKMMemo.FocusChanged(aFocused: Boolean);
begin
  if not aFocused then
  begin
    ResetSelection;
    CursorPos := -1;
    Focusable := False;
  end;
end;


procedure TKMMemo.Paint;
var
  I, paintWidth, selPaintTop, selPaintHeight: Integer;
  beforeSelectionText, selectionText, rowText: UnicodeString;
  beforeSelectionW, selectionW, selStartPosInRow, selEndPosInRow, rowStartPos, rowEndPos: Integer;
  offX, offY: Integer;
begin
  inherited;
  if fScrollBar.Visible then
    paintWidth := Width - fScrollBar.Width //Leave space for scrollbar
  else
    paintWidth := Width; //List takes up the entire width

  TKMRenderUI.WriteBevel(AbsLeft, AbsTop, paintWidth, Height, 1, 0.5);

  for I := 0 to Math.min(fItems.Count-1, GetVisibleRows - 1) do
  begin
    rowText := GetNoColorMarkupText(fItems[TopIndex+I]);
    rowStartPos := PointToLinearPos(0, TopIndex+I);
    rowEndPos := rowStartPos + Length(rowText);
    if HasSelection then
    begin
      selStartPosInRow := fSelectionStart - rowStartPos;
      selEndPosInRow := fSelectionEnd - rowStartPos;

      selStartPosInRow := EnsureRange(selStartPosInRow, 0, rowEndPos);
      selEndPosInRow := EnsureRange(selEndPosInRow, selStartPosInRow, rowEndPos);

      if selStartPosInRow <> selEndPosInRow then
      begin
        beforeSelectionText := Copy(rowText, 1, selStartPosInRow);
        selectionText := Copy(rowText, selStartPosInRow+1, selEndPosInRow - selStartPosInRow);

        beforeSelectionW := gRes.Fonts[fFont].GetTextSize(beforeSelectionText).X;
        selectionW := gRes.Fonts[fFont].GetTextSize(selectionText).X;

        selPaintHeight := fItemHeight;
        selPaintTop := AbsTop+I*fItemHeight;
        if I = 0 then
        begin
          Dec(selPaintHeight, 3);
          Inc(selPaintTop, 3);
        end;

        TKMRenderUI.WriteShape(AbsLeft+4+beforeSelectionW, selPaintTop, min(selectionW, Width-8), selPaintHeight, clTextSelection);
      end;
    end;

    //Render text cursor
    if fSelectable and (csFocus in State) and ((TimeGet div 500) mod 2 = 0)
      and InRange(CursorPos, rowStartPos, rowEndPos) then
    begin
      offX := AbsLeft + 2 + gRes.Fonts[fFont].GetTextSize(Copy(rowText, 1, CursorPos-rowStartPos)).X;
      offY := AbsTop + 2 + I*fItemHeight;
      TKMRenderUI.WriteShape(offX, offY, 3, fItemHeight-4, $FFFFFFFF, $FF000000);
    end;
    TKMRenderUI.WriteText(AbsLeft+4, AbsTop+I*fItemHeight+3, Width-8, fItems.Strings[TopIndex+I] , fFont, taLeft);
  end;
end;


end.


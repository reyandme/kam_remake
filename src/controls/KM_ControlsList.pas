unit KM_ControlsList;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  Controls,
  KromOGLUtils,
  KM_Controls, KM_ControlsScroll,
  KM_RenderUI,
  KM_ResFonts,
  KM_Pics,
  KM_Defaults, KM_Points, KM_CommonTypes;


type
  TKMNotifyCellClick = procedure(Sender: TObject; const aCellX, aCellY: Integer; var aHandled: Boolean) of object;
  TKMNotifyCellClickShift = procedure(Sender: TObject; const aCellX, aCellY: Integer; Shift: TShiftState; var aHandled: Boolean) of object;
  TKMNotifyColumnClick = procedure(Sender: TObject; const aColumn: Integer) of object;

  TKMSearchableList = class(TKMControl)
  private
    fSearch: UnicodeString; //Contains user input characters we should search for
    fLastKeyTime: Cardinal;
  protected
    fFont: TKMFont; //Should not be changed from inital value, it will mess up the word wrapping
    fOnChange: TNotifyEvent;
    function GetHintKind: TKMHintKind; override;
    function GetHintFont: TKMFont; override;
    function IsHintSelected: Boolean; override;

    function CanSearch: Boolean; virtual; abstract;
    function GetRowCount: Integer; virtual; abstract;
    function GetItemIndex: Integer; virtual; abstract;
    procedure SetItemIndex(aIndex: Integer); virtual; abstract;
    function GetTopIndex: Integer; virtual; abstract;
    procedure SetTopIndex(aIndex: Integer); overload; virtual; abstract;
    function GetVisibleRows: Integer; virtual; abstract;
    function GetItemString(aIndex: Integer): UnicodeString; virtual; abstract;
    function GetMouseOverRow: Integer; virtual; abstract;

    function KeyEventHandled(Key: Word; Shift: TShiftState): Boolean; virtual;
    function CanChangeSelection: Boolean; virtual;
  public
    procedure SetTopIndex(aIndex: Integer; aStayOnList: Boolean); overload;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property TopIndex: Integer read GetTopIndex write SetTopIndex;
    property RowCount: Integer read GetRowCount;

    function KeyDown(Key: Word; Shift: TShiftState): Boolean; override;
    procedure KeyPress(Key: Char); override;
    function KeyUp(Key: Word; Shift: TShiftState): Boolean; override;
  end;


  TKMListBox = class(TKMSearchableList)
  const
    TXT_PAD_X = 4;
    TXT_PAD_Y = 3;
  private
    fAutoHideScrollBar: Boolean;
    fBackAlpha: Single; //Alpha of background (usually 0.5, dropbox 1)
    fItemHeight: Byte;
    fItemIndex: Integer;
    fItems: TStringList;
    fMouseOverRow: SmallInt;
    fShowHintWhenShort: Boolean;
    fSeparatorPositions: array of Integer;
    fSeparatorHeight: Byte;
    fSeparatorColor: TColor4;
    fSeparatorTexts: TStringList;
    fSeparatorFont: TKMFont;
    fScrollBar: TKMScrollBar;
    fSearchEnabled: Boolean;
    procedure SetBackAlpha(aValue: Single);
    procedure SetItemHeight(const Value: Byte);
    procedure SetAutoHideScrollBar(Value: Boolean);
    function GetItem(aIndex: Integer): UnicodeString;
    function GetSeparatorPos(aIndex: Integer): Integer;
    function GetItemTop(aIndex: Integer): Integer;

    function GetPaintWidth: Integer;
    function GetRenderTextWidth: Integer;

    property PaintWidth: Integer read GetPaintWidth;
    property RenderTextWidth: Integer read GetRenderTextWidth;

    function GetCount: Integer;
    function GetSeparatorsCount: Integer;
  protected
    procedure SetLeft(aValue: Integer); override;
    procedure SetTop(aValue: Integer); override;
    procedure SetHeight(aValue: Integer); override;
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    function GetSelfWidth: Integer; override;
    function DoHandleMouseWheelByDefault: Boolean; override;

    function GetHint: UnicodeString; override;
    function GetHintBackRect: TKMRect; override;
    function GetHintTextOffset: TKMPoint; override;

    //TKMSearchableList
    function CanSearch: Boolean; override;
    function GetRowCount: Integer; override;
    function GetItemIndex: Integer; override;
    procedure SetItemIndex(aIndex: Integer); override;
    function GetTopIndex: Integer; override;
    procedure SetTopIndex(aIndex: Integer); override;
    function GetItemString(aIndex: Integer): UnicodeString; override;
    function GetMouseOverRow: Integer; override;
  public
    ItemTags: array of Integer;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle);
    destructor Destroy; override;

    property AutoHideScrollBar: boolean read fAutoHideScrollBar write SetAutoHideScrollBar;
    property BackAlpha: Single write SetBackAlpha;

    property SearchEnabled: Boolean read fSearchEnabled write fSearchEnabled;

    procedure Add(const aItem: UnicodeString; aTag: Integer = 0);
    procedure AddSeparator(aPosition: Integer; const aText: String = '');
    procedure ClearSeparators;

    procedure Clear;
    property Count: Integer read GetCount;
    property SeparatorsCount: Integer read GetSeparatorsCount;

    function GetVisibleRows: Integer; override;

    property Item[aIndex: Integer]: UnicodeString read GetItem; default;
    property ItemHeight: Byte read fItemHeight write SetItemHeight; //Accessed by DropBox
    property Items: TStringList read fItems;
    procedure UpdateScrollBar;

    property ShowHintWhenShort: Boolean read fShowHintWhenShort write fShowHintWhenShort;

    property SeparatorPos[aIndex: Integer]: Integer read GetSeparatorPos;
    property SeparatorFont: TKMFont read fSeparatorFont write fSeparatorFont;
    property SeparatorColor: TColor4 read fSeparatorColor write fSeparatorColor;
    property SeparatorHeight: Byte read fSeparatorHeight write fSeparatorHeight;

    function Selected: Boolean;
    procedure MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean); override;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;

    procedure Paint; override;
  end;

  TKMSortDirection = (sdNone, sdUp, sdDown);

  TKMListHeaderColumn = class
    Caption: UnicodeString;
    Glyph: TKMPic;
    HeaderHint: UnicodeString;
    Offset: Word; //Offsets are easier to handle than widths
  end;

  TKMListHeader = class(TKMControl)
  private
    fFont: TKMFont;
    fCount: Integer;
    fColumns: array of TKMListHeaderColumn;
    fColumnHighlight: Integer;
    fSortIndex: Integer;
    fSortDirection: TKMSortDirection;
    fTextAlign: TKMTextAlign;
    function GetColumnIndex(X: Integer): Integer;
    function GetColumn(aIndex: Integer): TKMListHeaderColumn;
    procedure ClearColumns;
    function GetColumnWidth(aIndex: Integer): Integer;
    function GetOffset(aIndex: Integer): Word;
    procedure SetOffset(aIndex: Integer; aValue: Word);
    function GetHeaderHint(aIndex: Integer): UnicodeString;
    procedure SetHeaderHint(aIndex: Integer; const aValue: UnicodeString);
  protected
    procedure DoClick(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    function GetHint: UnicodeString; override;
  public
    BackAlpha: Single; //Alpha of background
    EdgeAlpha: Single; //Alpha of background outline

    OnColumnClick: TKMNotifyColumnClick;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
    destructor Destroy; override;

    procedure SetColumns(aFont: TKMFont; aColumns: array of String; aColumnOffsets: array of Word); overload;
    procedure SetColumns(aFont: TKMFont; aColumns, aHints: array of String; aColumnOffsets: array of Word); overload;
    property Offset[aIndes: Integer]: Word read GetOffset write SetOffset;
    property HeaderHint[aIndes: Integer]: UnicodeString read GetHeaderHint write SetHeaderHint;

    property Count: Integer read fCount;
    property Font: TKMFont read fFont write fFont;
    property ColumnCount: Integer read fCount;
    property Columns[aIndex: Integer]: TKMListHeaderColumn read GetColumn;
    property SortIndex: Integer read fSortIndex write fSortIndex;
    property SortDirection: TKMSortDirection read fSortDirection write fSortDirection;
    property TextAlign: TKMTextAlign read fTextAlign write fTextAlign;
    property ColumnWidth[aIndex: Integer]: Integer read GetColumnWidth;

    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure Paint; override;
  end;

  TKMListRow = record
    Cells: array of record
      Caption: UnicodeString;  //Main Text
      SubTxt: UnicodeString; //Gray text below main text
      CellHint: UnicodeString;
      Color: TColor4;
      HighlightColor: TColor4;
      HighlightOnMouseOver: Boolean;
      Enabled: Boolean;
      Pic: TKMPic;
    end;
    Tag: Integer;
  end;

  TKMListColumn = class
    Font: TKMFont;
    HintFont: TKMFont;
    TextAlign: TKMTextAlign;
    TriggerOnChange: Boolean;
  end;

  TKMColumnBox = class(TKMSearchableList)
  const
    COL_PAD_X = 4;
    TXT_PAD_Y = 2;
  private
    fBackAlpha: Single; //Alpha of background
    fEdgeAlpha: Single; //Alpha of outline
    fItemHeight: Byte;
    fItemIndex: Integer;
    fSearchColumn: ShortInt; //which columns text we should search, -1 for disabled
    fRowCount: Integer;
    fColumns: array of TKMListColumn;
    fHeader: TKMListHeader;
    fShowHeader: Boolean;
    fShowLines: Boolean;
    fMouseOverRow: SmallInt;
    fShowHintWhenShort: Boolean;
    fMouseOverColumn: SmallInt;
    fMouseOverCell: TKMPoint;
    fScrollBar: TKMScrollBar;
    fOnCellClick: TKMNotifyCellClick;
    fOnCellClickShift: TKMNotifyCellClickShift;
    fOnChangeInvoked: Boolean;
    procedure SetBackAlpha(aValue: Single);
    procedure SetEdgeAlpha(aValue: Single);
    function GetSortIndex: Integer;
    procedure SetSortIndex(aIndex: Integer);
    function GetSortDirection: TKMSortDirection;
    procedure SetSortDirection(aDirection: TKMSortDirection);
    procedure UpdateScrollBar;
    procedure SetShowHeader(aValue: Boolean);
    function GetOnColumnClick: TKMNotifyColumnClick;
    procedure SetOnColumnClick(const aValue: TKMNotifyColumnClick);
    function GetColumn(aIndex: Integer): TKMListColumn;
    procedure ClearColumns;
    procedure SetSearchColumn(aValue: ShortInt);
    procedure ResetMouseOver;
    procedure UpdateMouseOverPosition(X,Y: Integer);
    procedure UpdateItemIndex(Shift: TShiftState; var aOnChangeInvoked: Boolean);
    function GetItem(aIndex: Integer): TKMListRow;
    function GetSelectedItem: TKMListRow;
    function GetSelectedItemTag: Integer;
    procedure ScrollBarChangeVisibility;
    procedure ScrollBarChanged(Sender: TObject);
  protected
    procedure SetLeft(aValue: Integer); override;
    procedure SetTop(aValue: Integer); override;
    procedure SetWidth(aValue: Integer); override;
    procedure SetHeight(aValue: Integer); override;
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    function GetSelfAbsTop: Integer; override;
    function GetSelfHeight: Integer; override;
    function GetSelfWidth: Integer; override;
    function DoHandleMouseWheelByDefault: Boolean; override;
    function GetHint: UnicodeString; override;
    function GetHintTextColor: TColor4; override;
    function GetHintBackRect: TKMRect; override;
    function GetHintTextOffset: TKMPoint; override;

    // TKMSearchableList methods implementation
    function CanSearch: Boolean; override;
    function GetRowCount: Integer; override;
    function GetItemIndex: Integer; override;
    procedure SetItemIndex(aIndex: Integer); override;
    function GetTopIndex: Integer; override;
    procedure SetTopIndex(aIndex: Integer); override;
    function GetItemString(aIndex: Integer): UnicodeString; override;
    function GetMouseOverRow: Integer; override;

    function CanChangeSelection: Boolean; override;

    function CanFocusNext: Boolean; override;
  public
    HideSelection: Boolean;
    HighlightError: Boolean;
    HighlightOnMouseOver: Boolean;
    Rows: array of TKMListRow; //Exposed to public since we need to edit sub-fields
    PassAllKeys: Boolean;
    ColumnIdForScroll: Integer; //When scroll is visible, we can move columns to the left. Using specified ColumnId. If ColumnId = -1, then no column width is changed

    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle);
    destructor Destroy; override;

    property Item[aIndex: Integer]: TKMListRow read GetItem; default;
    property SelectedItem: TKMListRow read GetSelectedItem;
    property SelectedItemTag: Integer read GetSelectedItemTag;
    procedure SetColumns(aHeaderFont: TKMFont; aCaptions: array of String; aOffsets: array of Word); overload;
    procedure SetColumns(aHeaderFont: TKMFont; aCaptions: array of string; aOffsets: array of Word; aCaptionsAsHints: Boolean); overload;
    procedure SetColumns(aHeaderFont: TKMFont; aCaptions, aHints: array of String; aOffsets: array of Word); overload;
    procedure AddItem(aItem: TKMListRow);
    procedure Clear;
    function GetVisibleRows: Integer; override;
    function GetVisibleRowsExact: Single;
    function IsSelected: Boolean;
    property ShowHeader: Boolean read fShowHeader write SetShowHeader;
    property ShowHintWhenShort: Boolean read fShowHintWhenShort write fShowHintWhenShort;
    property ShowLines: Boolean read fShowLines write fShowLines;
    property SearchColumn: ShortInt read fSearchColumn write SetSearchColumn;

    property Columns[aIndex: Integer]: TKMListColumn read GetColumn;
    property BackAlpha: Single read fBackAlpha write SetBackAlpha;
    property EdgeAlpha: Single read fEdgeAlpha write SetEdgeAlpha;
    property RowCount: Integer read fRowCount;
    property ItemHeight: Byte read fItemHeight write fItemHeight;
    property Header: TKMListHeader read fHeader;

    //Sort properties are just hints to render Up/Down arrows. Actual sorting is done by client
    property OnColumnClick: TKMNotifyColumnClick read GetOnColumnClick write SetOnColumnClick;
    property OnCellClick: TKMNotifyCellClick read fOnCellClick write fOnCellClick;
    property OnCellClickShift: TKMNotifyCellClickShift read fOnCellClickShift write fOnCellClickShift;
    property SortIndex: Integer read GetSortIndex write SetSortIndex;
    property SortDirection: TKMSortDirection read GetSortDirection write SetSortDirection;

    procedure JumpToSelected;

    function KeyDown(Key: Word; Shift: TShiftState): Boolean; override;
    procedure KeyPress(Key: Char); override;
    function KeyUp(Key: Word; Shift: TShiftState): Boolean; override;
    procedure MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseMove(X,Y: Integer; Shift: TShiftState); override;
    procedure MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean); override;
    procedure DoClick(X, Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;

    procedure DoPaintLine(aIndex: Integer; X,Y: Integer; PaintWidth: Integer; aAllowHighlight: Boolean = True); overload;
    procedure DoPaintLine(aIndex: Integer; X, Y: Integer; PaintWidth: Integer; aColumnsToShow: array of Boolean; aAllowHighlight: Boolean = True); overload;
    procedure Paint; override;
  end;


  function MakeListRow(const aCaption: array of String; aTag: Integer = 0): TKMListRow; overload;
  function MakeListRow(const aCaption, aHint: array of String; aTag: Integer = 0): TKMListRow; overload;
  function MakeListRow(const aCaption: array of string; const aColor: array of TColor4; aTag: Integer = 0): TKMListRow; overload;
  function MakeListRow(const aCaption, aHint: array of string; const aColor: array of TColor4; aTag: Integer = 0): TKMListRow; overload;
  function MakeListRow(const aCaption: array of string; const aColor: array of TColor4; const aColorHighlight: array of TColor4; aTag: Integer = 0): TKMListRow; overload;
  function MakeListRow(const aCaption: array of string; const aColor: array of TColor4; const aPic: array of TKMPic; aTag: Integer = 0): TKMListRow; overload;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  SysUtils, StrUtils, Math,
  KM_ControlsTypes, KM_ControlsUtils,
  KM_Resource, KM_ResTypes,
  KM_CommonUtils;


function MakeListRow(const aCaption: array of String; aTag: Integer = 0): TKMListRow;
var
  I: Integer;
begin
  SetLength(Result.Cells, Length(aCaption));

  for I := 0 to High(aCaption) do
  begin
    Result.Cells[I].Caption := aCaption[I];
    Result.Cells[I].Color := $FFFFFFFF;
    Result.Cells[I].Enabled := True;
  end;
  Result.Tag := aTag;
end;


function MakeListRow(const aCaption, aHint: array of String; aTag: Integer = 0): TKMListRow;
var
  I: Integer;
begin
  Assert(Length(aCaption) = Length(aHint));
  SetLength(Result.Cells, Length(aCaption));

  for I := 0 to High(aCaption) do
  begin
    Result.Cells[I].Caption := aCaption[I];
    Result.Cells[I].CellHint := aHint[I];
    Result.Cells[I].Color := $FFFFFFFF;
    Result.Cells[I].Enabled := True;
  end;
  Result.Tag := aTag;
end;


function MakeListRow(const aCaption: array of string; const aColor: array of TColor4; aTag: Integer = 0): TKMListRow;
var I: Integer;
begin
  Assert(Length(aCaption) = Length(aColor));

  SetLength(Result.Cells, Length(aCaption));

  for I := 0 to High(aCaption) do
  begin
    Result.Cells[I].Caption := aCaption[I];
    Result.Cells[I].Color := aColor[I];
    Result.Cells[I].Enabled := True;
  end;
  Result.Tag := aTag;
end;


function MakeListRow(const aCaption, aHint: array of string; const aColor: array of TColor4; aTag: Integer = 0): TKMListRow;
var I: Integer;
begin
  Assert(Length(aCaption) = Length(aColor));
  Assert(Length(aCaption) = Length(aHint));

  SetLength(Result.Cells, Length(aCaption));

  for I := 0 to High(aCaption) do
  begin
    Result.Cells[I].Caption := aCaption[I];
    Result.Cells[I].CellHint := aHint[I];
    Result.Cells[I].Color := aColor[I];
    Result.Cells[I].Enabled := True;
  end;
  Result.Tag := aTag;
end;


function MakeListRow(const aCaption: array of string; const aColor: array of TColor4; const aColorHighlight: array of TColor4; aTag: Integer = 0): TKMListRow;
var
  I: Integer;
begin
  Assert(Length(aCaption) = Length(aColor));
  Assert(Length(aCaption) = Length(aColorHighlight));

  SetLength(Result.Cells, Length(aCaption));

  for I := 0 to High(aCaption) do
  begin
    Result.Cells[I].Caption := aCaption[I];
    Result.Cells[I].Color := aColor[I];
    Result.Cells[I].HighlightColor := aColorHighlight[I];
    Result.Cells[I].Enabled := True;
  end;
  Result.Tag := aTag;
end;


function MakeListRow(const aCaption: array of string; const aColor: array of TColor4; const aPic: array of TKMPic;
                     aTag: Integer = 0): TKMListRow;
var
  I: Integer;
begin
  Assert(Length(aCaption) = Length(aColor));
  Assert(Length(aCaption) = Length(aPic));

  SetLength(Result.Cells, Length(aCaption));

  for I := 0 to High(aCaption) do
  begin
    Result.Cells[I].Caption := aCaption[I];
    Result.Cells[I].Color := aColor[I];
    Result.Cells[I].Pic := aPic[I];
    Result.Cells[I].Enabled := True;
  end;
  Result.Tag := aTag;
end;


{ TKMSearchableList }
procedure TKMSearchableList.KeyPress(Key: Char);
var
  I, oldIndex: Integer;
begin
  //KeyPress used only for key input search, do not allow unsupported Keys.
  //Otherwise fOnChange will be invoked on any key pressed
  if not IsCharAllowed(Key, acFileName) then Exit;

  if not CanSearch then
    Exit;

  oldIndex := GetItemIndex;

  //Allow to type several characters in a row to pick some item
  if TimeSince(fLastKeyTime) < 1000 then
    fSearch := fSearch + Key
  else
    fSearch := Key;

  fLastKeyTime := TimeGet;

  for I := 0 to GetRowCount - 1 do
    if AnsiStartsText(fSearch, GetItemString(I)) then
    begin
      SetItemIndex(I);
      SetTopIndex(GetItemIndex - GetVisibleRows div 2);
      Break;
    end;

  if Assigned(fOnChange) and (oldIndex <> GetItemIndex) then
    fOnChange(Self);
end;


function TKMSearchableList.KeyEventHandled(Key: Word; Shift: TShiftState): Boolean;
begin
  //We want these keys to be ignored
  if Key in [VK_F1..VK_F12, VK_ESCAPE, VK_RETURN, VK_DELETE, VK_TAB, VK_MBUTTON] then
    Result := False
  else
    Result := CanSearch or (Key in [VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT]);

  Result := Result and CanChangeSelection; //Don't handle keys if can't change selection
end;


function TKMSearchableList.CanChangeSelection: Boolean;
begin
  Result := True;
end;


function TKMSearchableList.GetHintFont: TKMFont;
begin
  Result := fFont;
end;


function TKMSearchableList.GetHintKind: TKMHintKind;
begin
  Result := hkTextNotFit;
end;


function TKMSearchableList.IsHintSelected: Boolean;
begin
  Result := (ItemIndex <> -1) and (GetMouseOverRow = ItemIndex);
end;


function TKMSearchableList.KeyDown(Key: Word; Shift: TShiftState): Boolean;
var
  oldIndex, newIndex: Integer;
  pageScrolling: Boolean;
begin
  Result := KeyEventHandled(Key, Shift);
  if inherited KeyDown(Key, Shift) then Exit;

  if not CanChangeSelection then Exit; //Can't change selection

  pageScrolling := False;
  oldIndex := ItemIndex;
  case Key of
    VK_UP:      newIndex := ItemIndex - 1;
    VK_DOWN:    newIndex := ItemIndex + 1;
    VK_HOME:    newIndex := 0;
    VK_END:     newIndex := RowCount - 1;
    VK_PRIOR:   begin
                  newIndex := EnsureRange(ItemIndex - GetVisibleRows, 0, RowCount - 1);
                  pageScrolling := True;
                end;
    VK_NEXT:    begin
                  newIndex := EnsureRange(ItemIndex + GetVisibleRows, 0, RowCount - 1);
                  pageScrolling := True;
                end;
    VK_RETURN:  begin
                  //Trigger click to hide drop downs
                  if Assigned(OnClick) then
                    OnClick(Self);
                  //Double click on Enter
                  if Assigned(OnDoubleClick) then
                    OnDoubleClick(Self);
                  Exit;
                end;
    else        Exit;
  end;

  if InRange(newIndex, 0, RowCount - 1) then
  begin
    ItemIndex := newIndex;
    if pageScrolling then
      TopIndex := ItemIndex - (oldIndex - TopIndex) // Save position from the top of the list
    else if TopIndex < ItemIndex - GetVisibleRows + 1 then //Moving down
      TopIndex := ItemIndex - GetVisibleRows + 1
    else if TopIndex > ItemIndex then //Moving up
      TopIndex := ItemIndex;
  end;

  if Assigned(fOnChange) and (oldIndex <> newIndex) then
    fOnChange(Self);
end;


function TKMSearchableList.KeyUp(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := KeyEventHandled(Key, Shift);
  if inherited KeyUp(Key, Shift) then Exit;
end;


procedure TKMSearchableList.SetTopIndex(aIndex: Integer; aStayOnList: Boolean);
begin
  if not aStayOnList
    or not InRange(aIndex - TopIndex, 0, GetVisibleRows - 1) then
  begin
    if aIndex < TopIndex then
      TopIndex := ItemIndex
    else
    if aIndex > TopIndex + GetVisibleRows - 1 then
      TopIndex := aIndex - GetVisibleRows + 1;
  end;
end;


{ TKMListBox }
constructor TKMListBox.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  fBackAlpha := 0.5;
  fItemHeight := 20;
  fItemIndex := -1;
  fItems := TStringList.Create;
  fFont := aFont;
  fAutoHideScrollBar := False; //Always show the scrollbar by default, then it can be turned off if required
  fShowHintWhenShort := False;
  Focusable := True; //For up/down keys
  fSeparatorHeight := 0;
  fSeparatorTexts := TStringList.Create;
  fSeparatorFont := fntAntiqua; //Looks good on dark solid background
  fSeparatorColor := clListSeparatorShape;
  fSearchEnabled := False;

  fScrollBar := TKMScrollBar.Create(aParent, aLeft+aWidth-20, aTop, 20, aHeight, saVertical, aStyle);
  UpdateScrollBar; //Initialise the scrollbar
end;


destructor TKMListBox.Destroy;
begin
  fSeparatorTexts.Free;
  fItems.Free;
  inherited;
end;


function TKMListBox.CanSearch: Boolean;
begin
  Result := fSearchEnabled;
end;


function TKMListBox.GetRowCount: Integer;
begin
  Result := fItems.Count;
end;


procedure TKMListBox.SetItemHeight(const Value: byte);
begin
  fItemHeight := Value;
  UpdateScrollBar;
end;


procedure TKMListBox.SetItemIndex(aIndex: Integer);
begin
  if InRange(aIndex, 0, GetRowCount - 1) then
    fItemIndex := aIndex
  else
    fItemIndex := -1;
end;


function TKMListBox.GetItemIndex: Integer;
begin
  Result := fItemIndex;
end;


function TKMListBox.GetItemString(aIndex: Integer): UnicodeString;
begin
  Result := fItems[aIndex];
end;


procedure TKMListBox.SetLeft(aValue: Integer);
begin
  inherited;
  fScrollBar.Left := Left + Width - fScrollBar.Width;
end;


procedure TKMListBox.SetTop(aValue: Integer);
begin
  inherited;
  fScrollBar.Top := Top;
end;


procedure TKMListBox.SetHeight(aValue: Integer);
begin
  inherited;
  fScrollBar.Height := Height;
  UpdateScrollBar; //Since height has changed
end;


//Copy property to scrollbar. Otherwise it won't be rendered
procedure TKMListBox.SetVisible(aValue: Boolean);
begin
  inherited;
  fScrollBar.Visible := IsSetVisible and (not fAutoHideScrollBar or fScrollBar.Enabled); //Hide scrollbar and its buttons
end;


function TKMListBox.GetSelfWidth: Integer;
begin
  if fScrollBar.Visible then
    Result := Width - fScrollBar.Width //Leave space for scrollbar
  else
    Result := Width; //List takes up the entire width
end;


function TKMListBox.GetTopIndex: Integer;
begin
  Result := fScrollBar.Position;
end;


procedure TKMListBox.SetTopIndex(aIndex: Integer);
begin
  fScrollBar.Position := aIndex;
end;


procedure TKMListBox.SetBackAlpha(aValue: single);
begin
  fBackAlpha := aValue;
  fScrollBar.BackAlpha := aValue;
end;


procedure TKMListBox.SetEnabled(aValue: Boolean);
begin
  inherited;
  fScrollBar.Enabled := Enabled;
end;


//fItems.Count has changed
procedure TKMListBox.UpdateScrollBar;
begin
  fScrollBar.MaxValue := fItems.Count - GetVisibleRows;
  fScrollBar.Visible := IsSetVisible and (not fAutoHideScrollBar or fScrollBar.Enabled);
  //Separators can not be used with scroll bar for now.
  //Scrollbar works line-wise, not pixel-wise,
  //so adding separators could cause visual issues
  //(list 'jumping' when there is or there is no separator, when separator width is not equal to line width)
  Assert(not (fScrollBar.Visible and (SeparatorsCount > 0)), 'Separators can not be used with scroll bar');
end;


procedure TKMListBox.Add(const aItem: UnicodeString; aTag: Integer = 0);
begin
  fItems.Add(aItem);
  SetLength(ItemTags, Length(ItemTags) + 1);
  ItemTags[Length(ItemTags)-1] := aTag;
  UpdateScrollBar;
end;


//Add separator just before aPosition item in list with aText on it
procedure TKMListBox.AddSeparator(aPosition: Integer; const aText: String = '');
begin
  fSeparatorTexts.Add(aText);
  SetLength(fSeparatorPositions, Length(fSeparatorPositions) + 1);
  fSeparatorPositions[Length(fSeparatorPositions)-1] := aPosition;
  // Update List height, since we added separator to it
  Height := Height + SeparatorHeight;
  //Separators can not be used with scroll bar for now.
  //Scrollbar works line-wise, not pixel-wise,
  //so adding separators could cause visual issues
  //(list 'jumping' when there is or there is no separator, when separator width is not equal to line width)
  Assert(not fScrollBar.Visible, 'Separators can not be used with scroll bar');
end;


procedure TKMListBox.ClearSeparators;
var
  sepCnt: Integer;
begin
  // SeparatorsCount locally.
  // We should update Height only after clearing separators arrays
  sepCnt := SeparatorsCount;
  fSeparatorTexts.Clear;
  SetLength(fSeparatorPositions, 0);
  // Update List height, since we removed separators from it
  Height := Height - sepCnt*SeparatorHeight;
end;


procedure TKMListBox.Clear;
begin
  fItems.Clear;
  SetLength(ItemTags, 0);
  ClearSeparators;
  fItemIndex := -1;
  UpdateScrollBar;
end;


//Hide the scrollbar if it is not required (disabled) This is used for drop boxes.
procedure TKMListBox.SetAutoHideScrollBar(Value: boolean);
begin
  fAutoHideScrollBar := Value;
  UpdateScrollBar;
end;


function TKMListBox.GetCount: Integer;
begin
  Result := fItems.Count;
end;


function TKMListBox.Selected: Boolean;
begin
  Result := fItemIndex <> -1;
end;


function TKMListBox.GetSeparatorsCount: Integer;
begin
  Result := Length(fSeparatorPositions);
end;


function TKMListBox.GetVisibleRows: Integer;
begin
  Result := (Height - fSeparatorHeight*SeparatorsCount) div fItemHeight;
end;


function TKMListBox.GetHint: UnicodeString;
var
  hintStr: string;
begin
  Result := inherited GetHint;

  if not fShowHintWhenShort or (fMouseOverRow = -1) then Exit;

  if Result = '' then
  begin
    if //Got crashed sometimes when mouse over empty disabled ComboBox with Header (fMouseOverCell = [0;0])
      fItems.Count > fMouseOverRow then
    begin
      hintStr := fItems[fMouseOverRow];
      // Show hint, if caption does not fit into the cell
      if gRes.Fonts[fFont].GetTextSize(hintStr).X > RenderTextWidth then
        Result := hintStr;
    end;
  end;
end;


function TKMListBox.GetHintBackRect: TKMRect;
const
  SELECT_PAD = 1;
var
  top: Integer;
begin
  if fMouseOverRow = -1 then Exit(KMRECT_ZERO);

  top := GetItemTop(fMouseOverRow) - GetItemTop(TopIndex) - SELECT_PAD;
  Result := KMRect(-1, top, PaintWidth, top + fItemHeight + SELECT_PAD);
end;


function TKMListBox.GetHintTextOffset: TKMPoint;
begin
  if fMouseOverRow = -1 then Exit(KMPOINT_ZERO);

  Result := TKMPoint.New(TXT_PAD_X, TXT_PAD_Y + GetItemTop(fMouseOverRow) - GetItemTop(TopIndex));
end;


function TKMListBox.GetItem(aIndex: Integer): UnicodeString;
begin
  Result := fItems[aIndex];
end;


function TKMListBox.GetSeparatorPos(aIndex: Integer): Integer;
begin
  Result := fSeparatorPositions[aIndex];
end;


//Get aIndex item top position, considering separators
function TKMListBox.GetItemTop(aIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := fItemHeight*aIndex;
  for I := 0 to Length(fSeparatorPositions) - 1 do
    if fSeparatorPositions[I] <= aIndex then
      Inc(Result, fSeparatorHeight);
end;


function TKMListBox.GetMouseOverRow: Integer;
begin
  Result := fMouseOverRow;
end;


function TKMListBox.GetPaintWidth: Integer;
begin
  Result := Width - fScrollBar.Width * Byte(fScrollBar.Visible);
end;


function TKMListBox.GetRenderTextWidth: Integer;
begin
  Result := PaintWidth - 2*TXT_PAD_X;
end;


procedure TKMListBox.MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;
  MouseMove(X,Y,Shift); //Will change Position and call OnChange event
end;


procedure TKMListBox.MouseMove(X,Y: Integer; Shift: TShiftState);

  // We should use this function, to go from 1st line to the next lines, because we could have separators in the list
  function GetItemOverIndex(aY: Integer): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    for I := 0 to Min(fItems.Count, GetVisibleRows) - 1 do
      if InRange(aY, AbsTop + GetItemTop(I), AbsTop + GetItemTop(I) + fItemHeight) then
        Exit(I);
  end;

var
  newIndex: Integer;
begin
  inherited;

  fMouseOverRow := -1;

  if   not InRange(X, AbsLeft, AbsLeft + Width - (fScrollBar.Width * Byte(fScrollBar.Visible)))
    or not InRange(Y, AbsTop, AbsTop + Height) then Exit;

  fMouseOverRow := GetItemOverIndex(Y);

  if fMouseOverRow <> -1 then
    fMouseOverRow := fMouseOverRow + TopIndex
  else
    Exit;

  if (ssLeft in Shift) then
  begin
    newIndex := fMouseOverRow;

    if newIndex > fItems.Count - 1 then
    begin
      //Double clicking not allowed if we are clicking past the end of the list, but keep last item selected
      fTimeOfLastClick := 0;
      newIndex := fItems.Count - 1;
    end;

    if newIndex <> fItemIndex then
    begin
      fItemIndex := newIndex;
      fTimeOfLastClick := 0; //Double click shouldn't happen if you click on one server A, then server B
      if Assigned(fOnChange) then
        fOnChange(Self);
    end;
  end;
end;


function TKMListBox.DoHandleMouseWheelByDefault: Boolean;
begin
  Result := False;
end;


procedure TKMListBox.MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  inherited;

  if aHandled then Exit;

  SetTopIndex(TopIndex - WheelSteps);
  fScrollBar.Position := TopIndex; //Make the scrollbar move too when using the wheel

  aHandled := WheelSteps <> 0;
end;


procedure TKMListBox.Paint;
var
  I: Integer;
  shapeColor, outlineColor: TColor4;
begin
  inherited;

  // Draw background
  TKMRenderUI.WriteBevel(AbsLeft, AbsTop, PaintWidth, Height, 1, fBackAlpha);

  // Draw selection outline and rectangle (shape)
  if (fItemIndex <> -1) and InRange(fItemIndex - TopIndex, 0, GetVisibleRows - 1) then
  begin
    if IsFocused then
    begin
      shapeColor := clListSelShape;
      outlineColor := clListSelOutline;
    end else begin
      shapeColor := clListSelShapeUnfocused;
      outlineColor := clListSelOutlineUnfocused;
    end;
    TKMRenderUI.WriteShape(AbsLeft, AbsTop + GetItemTop(fItemIndex) - GetItemTop(TopIndex),
                           PaintWidth, fItemHeight, shapeColor, outlineColor);
  end;

  // Draw text lines
  for I := 0 to Min(fItems.Count, GetVisibleRows) - 1 do
    TKMRenderUI.WriteText(AbsLeft + TXT_PAD_X, AbsTop + GetItemTop(I) + TXT_PAD_Y, RenderTextWidth, fItems.Strings[TopIndex+I] , fFont, taLeft);

  // Draw separators
  for I := 0 to Length(fSeparatorPositions) - 1 do
  begin
    TKMRenderUI.WriteShape(AbsLeft, AbsTop + GetItemTop(fSeparatorPositions[I]) - fSeparatorHeight,
                           PaintWidth - 1, fSeparatorHeight, fSeparatorColor);
    if fSeparatorTexts[I] <> '' then
      TKMRenderUI.WriteText(AbsLeft + TXT_PAD_X, AbsTop + GetItemTop(fSeparatorPositions[I]) - fSeparatorHeight,
                            RenderTextWidth, fSeparatorTexts[I], fSeparatorFont, taCenter)
  end;
end;


{ TKMListHeader }
constructor TKMListHeader.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  BackAlpha := 0.5;
  EdgeAlpha := 0.75;
  fSortDirection := sdNone;
  fSortIndex := -1;
end;


destructor TKMListHeader.Destroy;
begin
  ClearColumns;

  inherited;
end;


procedure TKMListHeader.ClearColumns;
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    FreeAndNil(fColumns[I]);
end;


function TKMListHeader.GetColumnIndex(X: Integer): Integer;
var
  I, cellRightOffset: Integer;
begin
  Result := -1;

  for I := 0 to fCount - 1 do
  begin
    if I = fCount - 1 then
      cellRightOffset := AbsLeft + Width
    else
      cellRightOffset := AbsLeft + fColumns[I+1].Offset - 1;
    if InRange(X, AbsLeft + fColumns[I].Offset, cellRightOffset) then
      Result := I;
  end;
end;


function TKMListHeader.GetColumn(aIndex: Integer): TKMListHeaderColumn;
begin
  Result := fColumns[aIndex];
end;


function TKMListHeader.GetColumnWidth(aIndex: Integer): Integer;
begin
  if aIndex = fCount - 1 then
    Result := Width - fColumns[aIndex].Offset
  else
    Result := fColumns[aIndex+1].Offset - fColumns[aIndex].Offset;
end;


function TKMListHeader.GetHint: UnicodeString;
begin
  Result := inherited GetHint;
  if (Result = '') and (fColumnHighlight <> -1) then
    Result := HeaderHint[fColumnHighlight];
end;


//We know we were clicked and now we can decide what to do
procedure TKMListHeader.DoClick(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  columnID: Integer;
begin
  //do not invoke inherited here, to fully override parent DoClick method
  columnID := GetColumnIndex(X);
  if (columnID <> -1) and Assigned(OnColumnClick) then
  begin
    //We could process the clicks here (i.e. do the sorting inplace)
    //but there are various circumstances where plain string sorting will look wrong
    //and the ListBox just misses the knowledge to do it right:
    //MP game status (sort by type), ping (sort 1>9), playercount (sort 9>1), dates (sort by TDateTime)
    //Let the UI communicate to Game and do it right

    //Apply sorting to the column, toggling the state, sdDown is default
    if fSortIndex = columnID then
      if fSortDirection = sdDown then
        fSortDirection := sdUp
      else
        fSortDirection := sdDown
    else
      fSortDirection := sdDown;
    fSortIndex := columnID;
    OnColumnClick(Self, columnID);
  end
  else
    inherited; //Process the usual clicks if e.g. there are no columns
end;


procedure TKMListHeader.SetColumns(aFont: TKMFont; aColumns: array of String; aColumnOffsets: array of Word);
var
  hints: array of String;
begin
  SetLength(hints, Length(aColumns));
  SetColumns(aFont, aColumns, hints, aColumnOffsets);
end;


procedure TKMListHeader.SetColumns(aFont: TKMFont; aColumns, aHints: array of String; aColumnOffsets: array of Word);
var
  I: Integer;
begin
  Assert(Length(aColumns) = Length(aColumnOffsets));
  Assert(Length(aHints) = Length(aColumnOffsets));

  fFont := aFont;

  ClearColumns;

  fCount := Length(aColumns);
  SetLength(fColumns, fCount);
  for I := 0 to fCount - 1 do
  begin
    fColumns[I] := TKMListHeaderColumn.Create;
    fColumns[I].Caption := aColumns[I];
    fColumns[I].HeaderHint := aHints[I];
    fColumns[I].Offset := aColumnOffsets[I];
  end;
end;


function TKMListHeader.GetOffset(aIndex: Integer): Word;
begin
  Result := fColumns[aIndex].Offset;
end;


procedure TKMListHeader.SetOffset(aIndex: Integer; aValue: Word);
begin
  fColumns[aIndex].Offset := aValue;
end;


function TKMListHeader.GetHeaderHint(aIndex: Integer): UnicodeString;
begin
  Result := fColumns[aIndex].HeaderHint;
end;


procedure TKMListHeader.SetHeaderHint(aIndex: Integer; const aValue: UnicodeString);
begin
  fColumns[aIndex].HeaderHint := aValue;
end;


procedure TKMListHeader.MouseMove(X, Y: Integer; Shift: TShiftState);
begin
  inherited;
  fColumnHighlight := GetColumnIndex(X);
end;


procedure TKMListHeader.Paint;
var
  I: Integer;
  columnLeft: Integer;
  columnWidth: Integer;
  textSize: TKMPoint;
begin
  inherited;

  for I := 0 to fCount - 1 do
  begin
    if I < fCount - 1 then
      columnWidth := fColumns[I+1].Offset - fColumns[I].Offset
    else
      columnWidth := Width - fColumns[I].Offset;

    if columnWidth <= 0 then Break;

    columnLeft := AbsLeft + fColumns[I].Offset;

    TKMRenderUI.WriteBevel(columnLeft, AbsTop, columnWidth, Height, EdgeAlpha, BackAlpha);
    if Assigned(OnColumnClick) and (csOver in State) and (fColumnHighlight = I) then
      TKMRenderUI.WriteShape(columnLeft, AbsTop, columnWidth, Height, $20FFFFFF);

    if fColumns[I].Glyph.ID <> 0 then
      TKMRenderUI.WritePicture(columnLeft + 4, AbsTop, columnWidth - 8, Height, [], fColumns[I].Glyph.RX, fColumns[I].Glyph.ID)
    else
    begin
      textSize := gRes.Fonts[fFont].GetTextSize(fColumns[I].Caption);
      TKMRenderUI.WriteText(columnLeft + 4, AbsTop + (Height - textSize.Y) div 2 + 2, columnWidth - 8, fColumns[I].Caption, fFont, fTextAlign);
    end;

    if Assigned(OnColumnClick) and (fSortIndex = I) then
      case fSortDirection of
        sdDown: TKMRenderUI.WritePicture(columnLeft + columnWidth - 4-10, AbsTop + 6, 10, 11, [], rxGui, 60);
        sdUp:   TKMRenderUI.WritePicture(columnLeft + columnWidth - 4-10, AbsTop + 6, 10, 11, [], rxGui, 59);
      end;
  end;
end;


{ TKMColumnListBox }
constructor TKMColumnBox.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle);
const
  DEF_HEADER_HEIGHT = 24;
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);
  fFont       := aFont;
  fItemHeight := 20;
  fItemIndex  := -1;
  fShowHeader := True;
  fShowHintWhenShort := False;
  SearchColumn := -1; //Disabled by default
  Focusable := True; //For up/down keys
  ColumnIdForScroll := -1;

  fHeader := TKMListHeader.Create(aParent, aLeft, aTop, aWidth - fItemHeight, DEF_HEADER_HEIGHT);

  fScrollBar := TKMScrollBar.Create(aParent, aLeft+aWidth-fItemHeight, aTop, fItemHeight, aHeight, saVertical, aStyle);
  fScrollBar.OnChange := ScrollBarChanged;
  UpdateScrollBar; //Initialise the scrollbar

  SetEdgeAlpha(1);
  SetBackAlpha(0.5);
end;


destructor TKMColumnBox.Destroy;
begin
  ClearColumns;

  inherited;
end;


function TKMColumnBox.CanSearch: Boolean;
begin
  Result := SearchColumn <> -1;
end;


function TKMColumnBox.GetRowCount: Integer;
begin
  Result := fRowCount;
end;


function TKMColumnBox.GetItemIndex: Integer;
begin
  Result := fItemIndex;
end;


function TKMColumnBox.GetItemString(aIndex: Integer): UnicodeString;
begin
  Result := Rows[aIndex].Cells[SearchColumn].Caption;
end;


function TKMColumnBox.GetMouseOverRow: Integer;
begin
  Result := fMouseOverRow;
end;


procedure TKMColumnBox.SetSearchColumn(aValue: ShortInt);
begin
  fSearchColumn := aValue;
end;


procedure TKMColumnBox.SetShowHeader(aValue: Boolean);
begin
  fHeader.Visible := aValue;
  fShowHeader := aValue;
end;


procedure TKMColumnBox.SetLeft(aValue: Integer);
begin
  inherited;

  fHeader.Left := Left;
  fScrollBar.Left := Left + Width - fScrollBar.Width;
end;


procedure TKMColumnBox.SetTop(aValue: Integer);
begin
  inherited;

  //Update header and scrollbar so that their Top matched
  fHeader.Top := Top;
  fScrollBar.Top := Top;
end;


procedure TKMColumnBox.SetWidth(aValue: Integer);
begin
  inherited;

  fHeader.Width := Width;
  fScrollBar.Left := Left + Width - fScrollBar.Width;
end;


procedure TKMColumnBox.SetHeight(aValue: Integer);
begin
  inherited;
  fScrollBar.Height := Height;
  UpdateScrollBar; //Since height has changed
end;


procedure TKMColumnBox.SetItemIndex(aIndex: Integer);
begin
  if InRange(aIndex, 0, RowCount - 1) then
    fItemIndex := aIndex
  else
    fItemIndex := -1;
end;


procedure TKMColumnBox.SetOnColumnClick(const aValue: TKMNotifyColumnClick);
begin
  fHeader.OnColumnClick := aValue;
end;


procedure TKMColumnBox.SetSortDirection(aDirection: TKMSortDirection);
begin
  fHeader.SortDirection := aDirection;
end;


procedure TKMColumnBox.SetSortIndex(aIndex: Integer);
begin
  fHeader.SortIndex := aIndex;
end;


//Copy property to scrollbar. Otherwise it won't be rendered
procedure TKMColumnBox.SetVisible(aValue: Boolean);
begin
  inherited;
  fHeader.Visible := IsSetVisible and fShowHeader;
  fScrollBar.Visible := IsSetVisible and fScrollBar.Enabled; //Hide scrollbar and its buttons
end;


function TKMColumnBox.GetSelfAbsTop: Integer;
begin
  Result := AbsTop + (fHeader.Height + 1) * Byte(fShowHeader);
end;


function TKMColumnBox.GetSelfHeight: Integer;
begin
  Result := Height - (fHeader.Height + 1) * Byte(fShowHeader);
end;


function TKMColumnBox.GetSelfWidth: Integer;
begin
  if fScrollBar.Visible then
    Result := Width - fScrollBar.Width //Leave space for scrollbar
  else
    Result := Width; //List takes up the entire width
end;


function TKMColumnBox.GetTopIndex: Integer;
begin
  Result := fScrollBar.Position;
end;


function TKMColumnBox.GetVisibleRows: Integer;
begin
  Result := Floor(GetVisibleRowsExact);
end;


function TKMColumnBox.GetVisibleRowsExact: Single;
begin
  Result := (Height - fHeader.Height * Byte(ShowHeader)) / fItemHeight;
end;


function TKMColumnBox.IsSelected: Boolean;
begin
  Result := fItemIndex <> -1;
end;


procedure TKMColumnBox.SetTopIndex(aIndex: Integer);
begin
  fScrollBar.Position := aIndex;
end;


procedure TKMColumnBox.SetBackAlpha(aValue: Single);
begin
  fBackAlpha := aValue;
  fHeader.BackAlpha := aValue;
  fScrollBar.BackAlpha := aValue;
end;


procedure TKMColumnBox.SetEdgeAlpha(aValue: Single);
begin
  fEdgeAlpha := aValue;
  fHeader.EdgeAlpha := aValue;
  fScrollBar.EdgeAlpha := aValue;
end;


procedure TKMColumnBox.SetEnabled(aValue: Boolean);
begin
  inherited;
  fHeader.Enabled := Enabled;
  fScrollBar.Enabled := Enabled;
end;


function TKMColumnBox.GetColumn(aIndex: Integer): TKMListColumn;
begin
  Result := fColumns[aIndex];
end;


function TKMColumnBox.GetItem(aIndex: Integer): TKMListRow;
begin
  if InRange(aIndex, 0, RowCount - 1) then
    Result := Rows[aIndex]
  else
    raise Exception.Create('Cannot get Item with index ' + IntToStr(aIndex));
end;


function TKMColumnBox.GetSelectedItem: TKMListRow;
begin
  if IsSelected then
    Result := Rows[fItemIndex]
  else
    raise Exception.Create('No selected item found');
end;


function TKMColumnBox.GetSelectedItemTag: Integer;
begin
  Result := -1;
  if IsSelected then
    Result := GetSelectedItem.Tag;
end;


procedure TKMColumnBox.ScrollBarChangeVisibility;
var
  I: Integer;
begin
  if Visible and (ColumnIdForScroll <> -1) then
  begin
    if fScrollBar.Visible then
      for I := ColumnIdForScroll to fHeader.Count - 1 do
        fHeader.Offset[I] := fHeader.Offset[I] - fScrollBar.Width
    else
    begin
      for I := ColumnIdForScroll to fHeader.Count - 1 do
        fHeader.Offset[I] := fHeader.Offset[I] + fScrollBar.Width;
    end;
  end;
end;


procedure TKMColumnBox.ScrollBarChanged(Sender: TObject);
begin
  // Reset mouse over field, since we don't want hints to be shown while changing scrollbar f.e.
  ResetMouseOver;
end;


function TKMColumnBox.GetOnColumnClick: TKMNotifyColumnClick;
begin
  Result := fHeader.OnColumnClick;
end;


function TKMColumnBox.GetSortDirection: TKMSortDirection;
begin
  Result := fHeader.SortDirection;
end;


function TKMColumnBox.GetSortIndex: Integer;
begin
  Result := fHeader.SortIndex;
end;


// fRowCount or Height has changed
procedure TKMColumnBox.UpdateScrollBar;
var
  oldScrollBarVisible: Boolean;
begin
  fScrollBar.MaxValue := fRowCount - (Height - fHeader.Height * Byte(ShowHeader)) div fItemHeight;
  Assert(fScrollBar.MaxValue >= fScrollBar.MinValue);
  oldScrollBarVisible := fScrollBar.Visible;
  fScrollBar.Visible := IsSetVisible and (fScrollBar.MaxValue <> fScrollBar.MinValue);
  if fScrollBar.Visible <> oldScrollBarVisible then
    ScrollBarChangeVisibility;
end;


// If we don't add columns there will be Assert on items add
procedure TKMColumnBox.SetColumns(aHeaderFont: TKMFont; aCaptions: array of string; aOffsets: array of Word);
var
  hints: array of string;
begin
  SetLength(hints, Length(aCaptions));
  SetColumns(aHeaderFont, aCaptions, hints, aOffsets);
end;


procedure TKMColumnBox.SetColumns(aHeaderFont: TKMFont; aCaptions: array of string; aOffsets: array of Word; aCaptionsAsHints: Boolean);
begin
  if aCaptionsAsHints then
    SetColumns(aHeaderFont, aCaptions, aCaptions, aOffsets)
  else
    SetColumns(aHeaderFont, aCaptions, aOffsets);
end;


procedure TKMColumnBox.SetColumns(aHeaderFont: TKMFont; aCaptions, aHints: array of String; aOffsets: array of Word);
var
  I: Integer;
begin
  Assert(Length(aCaptions) = Length(aOffsets));
  Assert(Length(aHints) = Length(aOffsets));

  Clear; //We don't want to conflict with already added rows elements
  ClearColumns;

  fHeader.SetColumns(aHeaderFont, aCaptions, aHints, aOffsets);

  SetLength(fColumns, fHeader.ColumnCount);
  for I := 0 to fHeader.ColumnCount - 1 do
  begin
    fColumns[I] := TKMListColumn.Create;
    fColumns[I].Font := fFont; //Reset to default font
    fColumns[I].TextAlign := taLeft; //Default alignment
    fColumns[I].TriggerOnChange := True; //by default all columns trigger OnChange
  end;
end;


procedure TKMColumnBox.AddItem(aItem: TKMListRow);
begin
  Assert(fHeader.ColumnCount > 0);
  Assert(Length(aItem.Cells) = fHeader.ColumnCount);

  if fRowCount >= Length(Rows) then
    SetLength(Rows, fRowCount + 16);

  Rows[fRowCount] := aItem;

  Inc(fRowCount);
  UpdateScrollBar;
end;


procedure TKMColumnBox.Clear;
begin
  fRowCount := 0;
  fItemIndex := -1;
  UpdateScrollBar;
end;


procedure TKMColumnBox.ClearColumns;
var
  I: Integer;
begin
  for I := 0 to fHeader.ColumnCount - 1 do
    FreeAndNil(fColumns[I]);
end;


procedure TKMColumnBox.JumpToSelected;
begin
  if (ItemIndex <> -1)
    and not InRange(ItemIndex - TopIndex, 0, GetVisibleRows-1)
  then
    if ItemIndex < TopIndex then
      TopIndex := ItemIndex
    else
    if ItemIndex > TopIndex + GetVisibleRows - 1 then
      TopIndex := ItemIndex - GetVisibleRows + 1;
end;


function TKMColumnBox.KeyDown(Key: Word; Shift: TShiftState): Boolean;
begin
  if PassAllKeys then Exit(False);

  Result := inherited;
end;


function TKMColumnBox.CanChangeSelection: Boolean;
begin
  Result := not HideSelection;
end;


function TKMColumnBox.CanFocusNext: Boolean;
begin
  Result := not PassAllKeys;
end;


procedure TKMColumnBox.KeyPress(Key: Char);
begin
  if PassAllKeys then
    Exit
  else
    inherited;
end;


function TKMColumnBox.KeyUp(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
  if PassAllKeys then
  begin
    if Assigned(OnKeyUp) then
      Result := OnKeyUp(Self, Key, Shift);

    Exit;
  end;

  Result := inherited;
end;


procedure TKMColumnBox.ResetMouseOver;
begin
  fMouseOverColumn := -1;
  fMouseOverRow := -1;
  fMouseOverCell := KMPOINT_INVALID_TILE;
end;


//Update mouse over row/cell positions (fMouseOver* variables)
procedure TKMColumnBox.UpdateMouseOverPosition(X,Y: Integer);
var
  I, cellLeftOffset, cellRightOffset: Integer;
begin
  ResetMouseOver;

  if InRange(X, AbsLeft, AbsLeft + Width - fScrollBar.Width * Byte(fScrollBar.Visible))
    and InRange(Y, AbsTop + fHeader.Height*Byte(fHeader.Visible), AbsTop + fHeader.Height*Byte(fHeader.Visible) + Floor(GetVisibleRowsExact * fItemHeight) - 1) then
  begin
    for I := 0 to fHeader.ColumnCount - 1 do
    begin
      cellLeftOffset := AbsLeft + fHeader.Columns[I].Offset;
      if I = fHeader.ColumnCount - 1 then
        cellRightOffset := AbsLeft + Width - fScrollBar.Width * Byte(fScrollBar.Visible)
      else
        cellRightOffset := AbsLeft + fHeader.Columns[I+1].Offset - 1;
      if InRange(X, cellLeftOffset, cellRightOffset) then
      begin
        fMouseOverColumn := I;
        Break;
      end;
    end;

    fMouseOverRow := TopIndex + (Y - AbsTop - fHeader.Height * Byte(fShowHeader)) div fItemHeight;

    if fMouseOverRow >= fRowCount then
      fMouseOverRow := -1;

    if (fMouseOverRow <> -1) and (fMouseOverColumn <> -1) then
      fMouseOverCell := TKMPoint.New(fMouseOverColumn, fMouseOverRow);
  end;
end;


procedure TKMColumnBox.DoClick(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
var
  isClickHandled: Boolean;
begin
  //do not invoke inherited here, to fully override parent DoClick method
  isClickHandled := False;

  if not KMSamePoint(fMouseOverCell, KMPOINT_INVALID_TILE)
  and Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Enabled then
  begin
    if Assigned(fOnCellClick) then
      fOnCellClick(Self, fMouseOverCell.X, fMouseOverCell.Y, isClickHandled)
    else
      if Assigned(fOnCellClickShift) then
        fOnCellClickShift(Self, fMouseOverCell.X, fMouseOverCell.Y, Shift, isClickHandled);
  end;

  // Let propagate click event only when OnCellClick did not handle it
  if isClickHandled then Exit;

  inherited DoClick(X, Y, Shift, Button);
  if Assigned(fOnChange)
  and not fOnChangeInvoked
  and (fMouseOverCell <> KMPOINT_INVALID_TILE) //Only trigger ovew cells
  and Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Enabled then // Only trigger for enabled cells
    fOnChange(Self);
end;


procedure TKMColumnBox.UpdateItemIndex(Shift: TShiftState; var aOnChangeInvoked: Boolean);
var
  newIndex: Integer;
begin
  aOnChangeInvoked := False;
  if not (ssLeft in Shift) or (fMouseOverRow = -1) then
    Exit;

  // Do not do anything else, in case Cell we are working on is Disabled
  if (fMouseOverCell = KMPOINT_INVALID_TILE)
    or not Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Enabled then
    Exit;

  newIndex := fMouseOverRow;

  if newIndex >= fRowCount then
  begin
    //Double clicking not allowed if we are clicking past the end of the list, but keep last item selected
    fTimeOfLastClick := 0;
    newIndex := -1;
  end;

  if InRange(newIndex, 0, fRowCount - 1) and (newIndex <> fItemIndex)  then
  begin
    fTimeOfLastClick := 0; //Double click shouldn't happen if you click on one server A, then server B
    ItemIndex := newIndex;
    if not KMSamePoint(fMouseOverCell, KMPOINT_INVALID_TILE)
      and Columns[fMouseOverCell.X].TriggerOnChange
      and (fMouseOverCell <> KMPOINT_INVALID_TILE) //Only trigger ovew cells
      and Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Enabled // Only trigger for enabled cells
      and Assigned(fOnChange) then
    begin
      fOnChange(Self);
      aOnChangeInvoked := True;
    end;
  end;
end;


procedure TKMColumnBox.MouseDown(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  inherited;
  UpdateMouseOverPosition(X, Y);
  UpdateItemIndex(Shift, fOnChangeInvoked);
  //Lets do DoClick here instead of MouseUp event handler, because of some TKMColumnBox specific logic
  if (csDown in State) then
  begin
    State := State - [csDown];

    //Send Click events
    DoClick(X, Y, Shift, Button);
    fOnChangeInvoked := False;
  end;
end;


procedure TKMColumnBox.MouseMove(X,Y: Integer; Shift: TShiftState);
var
  onChangeInvoked: Boolean;
begin
  inherited;
  UpdateMouseOverPosition(X, Y);
  UpdateItemIndex(Shift, onChangeInvoked);
end;


procedure TKMColumnBox.MouseUp(X,Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  //We handle normal MouseUp event in MouseDown, so just hide ancestor MouseUp here
end;


function TKMColumnBox.DoHandleMouseWheelByDefault: Boolean;
begin
  Result := False;
end;


procedure TKMColumnBox.MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
begin
  inherited;

  if aHandled then Exit;

  SetTopIndex(TopIndex - WheelSteps);
  fScrollBar.Position := TopIndex; //Make the scrollbar move too when using the wheel

  aHandled := WheelSteps <> 0;
end;


function TKMColumnBox.GetHint: UnicodeString;
var
  hintStr: String;
begin
  Result := inherited GetHint;
  if Result = '' then
  begin
    if not KMSamePoint(fMouseOverCell, KMPOINT_INVALID_TILE)
      //Got crashed sometimes when mouse over empty disabled ComboBox with Header (fMouseOverCell = [0;0])
      and (Length(Rows) > fMouseOverCell.Y)
      and (Length(Rows[fMouseOverCell.Y].Cells) > fMouseOverCell.X) then
    begin
      Result := Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].CellHint;
      if fShowHintWhenShort and (Result = '') then
      begin
        hintStr := Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Caption;
        // Show hint, if caption does not fit into the cell
        if gRes.Fonts[fFont].GetTextSize(hintStr).X > fHeader.ColumnWidth[fMouseOverCell.X] - COL_PAD_X then
          Result := hintStr;
      end;
    end;
  end;
end;


function TKMColumnBox.GetHintTextColor: TColor4;
begin
  if fMouseOverCell = KMPOINT_INVALID_TILE then Exit(inherited);

  Result := Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Color;
end;


function TKMColumnBox.GetHintBackRect: TKMRect;
const
  SELECT_PAD = 1;
var
  top: Integer;
begin
  if fMouseOverCell = KMPOINT_INVALID_TILE then Exit(KMRECT_ZERO);

  top := fHeader.Height * Byte(fShowHeader) + (fMouseOverCell.Y - TopIndex) * fItemHeight - SELECT_PAD;
  Result := KMRect(fHeader.Columns[fMouseOverCell.X].Offset, //beware we dont consider hidden columns here, since there are none needed atm
                   top,
                   0, // Width is not used
                   top + fItemHeight + SELECT_PAD);
end;


function TKMColumnBox.GetHintTextOffset: TKMPoint;
var
  textSize: TKMPoint;
begin
  if fMouseOverCell = KMPOINT_INVALID_TILE then Exit(KMPOINT_ZERO);

  textSize := gRes.Fonts[fFont].GetTextSize(Rows[fMouseOverCell.Y].Cells[fMouseOverCell.X].Caption);

  Result := TKMPoint.New(COL_PAD_X + fHeader.Columns[fMouseOverCell.X].Offset, //beware we dont consider hidden columns here, since there are none needed atm
                    TXT_PAD_Y + fHeader.Height * Byte(fShowHeader)
                              + (fMouseOverCell.Y - TopIndex) * fItemHeight
                              + (fItemHeight - textSize.Y) div 2);
end;


procedure TKMColumnBox.DoPaintLine(aIndex: Integer; X, Y: Integer; PaintWidth: Integer; aAllowHighlight: Boolean = True);
var
  I: Integer;
  columnsToShow: array of Boolean;
begin
  SetLength(columnsToShow, Length(fColumns));
  for I := Low(columnsToShow) to High(columnsToShow) do
    columnsToShow[I] := True; // show all columns by default
  DoPaintLine(aIndex, X, Y, PaintWidth, columnsToShow, aAllowHighlight);
end;


procedure TKMColumnBox.DoPaintLine(aIndex: Integer; X, Y: Integer; PaintWidth: Integer; aColumnsToShow: array of Boolean;
                                   aAllowHighlight: Boolean = True);
  function IsHighlightOverCell(aCellIndex: Integer): Boolean;
  begin
    Result := aAllowHighlight
                and Rows[aIndex].Cells[aCellIndex].HighlightOnMouseOver
                and (fMouseOverCell.X = aCellIndex) and (fMouseOverCell.Y = aIndex)
                and (csOver in State);
  end;

var
  I: Integer;
  availWidth, hiddenColumnsTotalWidth: Integer;
  textSize: TKMPoint;
  color: Cardinal;
begin
  Assert(Length(fColumns) = Length(aColumnsToShow));
  hiddenColumnsTotalWidth := 0;
  for I := 0 to fHeader.ColumnCount - 1 do
  begin
    if not aColumnsToShow[I] then
    begin
      Inc(hiddenColumnsTotalWidth, fHeader.ColumnWidth[I]);
      Continue;
    end;
    //Determine available width
    if I = fHeader.ColumnCount - 1 then
      availWidth := PaintWidth - 4 - fHeader.Columns[I].Offset - COL_PAD_X
    else
      availWidth := fHeader.Columns[I+1].Offset - fHeader.Columns[I].Offset - COL_PAD_X;
    //Trim the width based on our allowed PaintWidth
    availWidth := Min(availWidth, PaintWidth - fHeader.Columns[I].Offset);

    if availWidth <= 0 then Continue; //If the item overflows our allowed PaintWidth do not paint it

    //Paint column
    if Rows[aIndex].Cells[I].Pic.ID <> 0 then
      TKMRenderUI.WritePicture(X + COL_PAD_X + fHeader.Columns[I].Offset - hiddenColumnsTotalWidth, Y + 1,
                               availWidth, fItemHeight, [],
                               Rows[aIndex].Cells[I].Pic.RX,
                               Rows[aIndex].Cells[I].Pic.ID,
                               Rows[aIndex].Cells[I].Enabled,
                               Rows[aIndex].Cells[I].Color,
                               0.4*Byte(IsHighlightOverCell(I) or (HighlightOnMouseOver and (csOver in State) and (fMouseOverRow = aIndex))));

    if Rows[aIndex].Cells[I].Caption <> '' then
      if Rows[aIndex].Cells[I].SubTxt <> '' then
      begin
        textSize := gRes.Fonts[fFont].GetTextSize(Rows[aIndex].Cells[I].Caption);
        TKMRenderUI.WriteText(X + COL_PAD_X + fHeader.Offset[I] - hiddenColumnsTotalWidth,
                              Y + 4,
                              availWidth,
                              Rows[aIndex].Cells[I].Caption,
                              fColumns[I].Font, fColumns[I].TextAlign, Rows[aIndex].Cells[I].Color);
        TKMRenderUI.WriteText(X + COL_PAD_X + fHeader.Offset[I] - hiddenColumnsTotalWidth,
                              Y + 1 + fItemHeight div 2,
                              availWidth,
                              Rows[aIndex].Cells[I].SubTxt,
                              fColumns[I].HintFont, fColumns[I].TextAlign, $FFB0B0B0);
      end else
      begin
        textSize := gRes.Fonts[fFont].GetTextSize(Rows[aIndex].Cells[I].Caption);
        if aAllowHighlight
          and ((HighlightOnMouseOver and (csOver in State) and (fMouseOverRow = aIndex))
          or (HighlightError and (aIndex = ItemIndex))
          or IsHighlightOverCell(I)) then
          color := Rows[aIndex].Cells[I].HighlightColor
        else
          color := Rows[aIndex].Cells[I].Color;

        if not Enabled then
          color := ReduceBrightness(color, 136);
        TKMRenderUI.WriteText(X + COL_PAD_X + fHeader.Offset[I] - hiddenColumnsTotalWidth,
                              Y + TXT_PAD_Y + (fItemHeight - textSize.Y) div 2,
                              availWidth,
                              Rows[aIndex].Cells[I].Caption,
                              fColumns[I].Font, fColumns[I].TextAlign, color);
      end;
  end;
end;


procedure TKMColumnBox.Paint;
var
  I, paintWidth, maxItem, Y: Integer;
  outlineColor, shapeColor: TColor4;
begin
  inherited;

  if fScrollBar.Visible then
    paintWidth := Width - fScrollBar.Width //Leave space for scrollbar
  else
    paintWidth := Width; //List takes up the entire width

  fHeader.Width := paintWidth;

  Y := AbsTop + fHeader.Height * Byte(fShowHeader);
  maxItem := GetVisibleRows;

  TKMRenderUI.WriteBevel(AbsLeft, Y, paintWidth, Height - fHeader.Height * Byte(fShowHeader), fEdgeAlpha, fBackAlpha);

  //Grid lines should be below selection focus
  if fShowLines then
    for I := 0 to Math.Min(fRowCount, maxItem) do
      TKMRenderUI.WriteShape(AbsLeft+1, Y + I * fItemHeight - 1, paintWidth - 2, 1, $FFBBBBBB);

  TKMRenderUI.SetupClipY(AbsTop, AbsTop + Height - 1);

  //Selection highlight
  if not HideSelection
    and (fItemIndex <> -1)
    and InRange(ItemIndex - TopIndex, 0, maxItem) then
  begin

    if IsFocused then
    begin
      shapeColor := clListSelShape;
      outlineColor := clListSelOutline;
    end else begin
      shapeColor := clListSelShapeUnfocused;
      outlineColor := clListSelOutlineUnfocused;
    end;

    TKMRenderUI.WriteShape(AbsLeft, Y + fItemHeight * (fItemIndex - TopIndex), paintWidth, fItemHeight, shapeColor);
    TKMRenderUI.WriteOutline(AbsLeft, Y + fItemHeight * (fItemIndex - TopIndex), paintWidth, fItemHeight, 1 + Byte(fShowLines), outlineColor);
  end;

  //Paint rows text and icons above selection for clear visibility
  for I := 0 to Math.min(fRowCount - TopIndex - 1, maxItem) do
    DoPaintLine(TopIndex + I, AbsLeft, Y + I * fItemHeight, paintWidth);

  TKMRenderUI.ReleaseClipY;
end;


end.


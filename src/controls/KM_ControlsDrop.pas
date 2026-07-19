unit KM_ControlsDrop;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  Controls,
  KromOGLUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsList,
  KM_ResTypes, KM_ResFonts,
  KM_RenderUI;


type
  TKMDropCommon = class(TKMControl)
  private
    fDropCount: Integer;
    fDropUp: Boolean;
    fFont: TKMFont;
    fButton: TKMButton;
    fShape: TKMShape;
    fAutoClose: Boolean;

    fOnChange: TNotifyEvent;
    fOnShowList: TNotifyEvent;

    procedure UpdateDropPosition; virtual; abstract;
    procedure ButtonClick(Sender: TObject);
    procedure ListShow(Sender: TObject); virtual;
    procedure ListClick(Sender: TObject); virtual;
    procedure ListChange(Sender: TObject); virtual;
    procedure ListHide(Sender: TObject); virtual;
    function ListVisible: Boolean; virtual; abstract;
    function GetItemIndex: SmallInt; virtual; abstract;
    procedure SetItemIndex(aIndex: SmallInt); virtual; abstract;
  protected
    procedure DoClick(X,Y: Integer; Shift: TShiftState; Button: TMouseButton); override;
    procedure SetLeft(aValue: Integer); override;
    procedure SetTop(aValue: Integer); override;
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    function ListKeyDown(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
    procedure UpdateVisibility; override;
    function GetCount: Integer; virtual; abstract;
    procedure SetDropCount(const aValue: Integer); virtual;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; aStyle: TKMButtonStyle;
                       aAutoClose: Boolean = True);

    procedure Clear; virtual; abstract;
    procedure OpenList;
    procedure CloseList;
    procedure SetOpenList(aOpen: Boolean);
    procedure SwitchOpen;

    property DropCount: Integer read fDropCount write SetDropCount;
    property DropUp: Boolean read fDropUp write fDropUp;
    property ItemIndex: SmallInt read GetItemIndex write SetItemIndex;
    function IsOpen: Boolean; virtual;
    property Count: Integer read GetCount;

    property OnShowList: TNotifyEvent read fOnShowList write fOnShowList;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
    procedure Paint; override;
  end;


  //DropBox with a ListBox
  TKMDropList = class(TKMDropCommon)
  private
    fCaption: UnicodeString; //Current caption (Default or from list)
    fDefaultCaption: UnicodeString;
    fDropWidth: Integer;
    fList: TKMListBox;
    fListTopIndex: Integer;
    procedure UpdateDropPosition; override;
    procedure ListShow(Sender: TObject); override;
    procedure ListClick(Sender: TObject); override;
    procedure ListChange(Sender: TObject); override;
    procedure ListHide(Sender: TObject); override;
    function ListVisible: Boolean; override;
    function GetItem(aIndex: Integer): UnicodeString;
    function GetItemIndex: smallint; override;
    procedure SetItemIndex(aIndex: smallint); override;
    procedure SetDropWidth(aDropWidth: Integer);
    function GetShowHintWhenShort: Boolean;
    procedure SetShowHintWhenShort(const aValue: Boolean);
  protected
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    function GetCount: Integer; override;
    procedure SetDropCount(const aValue: Integer); override;
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; const aDefaultCaption: UnicodeString;
                       aStyle: TKMButtonStyle; aAutoClose: Boolean = True; aBackAlpha: Single = 0.85);
    procedure Clear; override;
    procedure Add(const aItem: UnicodeString; aTag: Integer = 0);
    procedure SelectByName(const aText: UnicodeString);
    procedure SelectByTag(aTag: Integer);
    function HasTag(aTag: Integer): Boolean;
    function GetTag(aIndex: Integer): Integer;
    function GetSelectedTag: Integer;
    function IsSelected: Boolean;
    property ShowHintWhenShort: Boolean read GetShowHintWhenShort write SetShowHintWhenShort;
    property DefaultCaption: UnicodeString read fDefaultCaption write fDefaultCaption;
    property Item[aIndex: Integer]: UnicodeString read GetItem;
    property List: TKMListBox read fList;
    function IsOpen: Boolean; override;
    property DropWidth: Integer read fDropWidth write SetDropWidth;

    procedure Paint; override;
  end;


  //DropBox with a ColumnBox
  TKMDropColumns = class(TKMDropCommon)
  private
    fDefaultCaption: UnicodeString;
    fDropWidth: Integer;
    fList: TKMColumnBox;
    fListTopIndex: Integer;
    fColumnsToShowWhenListHidden: array of Boolean; //which columns to show, when list is hidden
    procedure UpdateDropPosition; override;
    procedure ListShow(Sender: TObject); override;
    procedure ListClick(Sender: TObject); override;
    procedure ListChange(Sender: TObject); override;
    procedure ListHide(Sender: TObject); override;
    function ListVisible: Boolean; override;
    function GetItem(aIndex: Integer): TKMListRow;
    function GetItemIndex: Smallint; override;
    procedure SetItemIndex(aIndex: Smallint); override;
    procedure SetDropWidth(aDropWidth: Integer);
    function GetShowHintWhenShort: Boolean;
    procedure SetShowHintWhenShort(const aValue: Boolean);
  protected
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    function GetCount: Integer; override;
  public
    FadeImageWhenDisabled: Boolean;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; const aDefaultCaption: UnicodeString; aStyle: TKMButtonStyle; aShowHeader: Boolean = True);
    procedure Add(aItem: TKMListRow);
    procedure Clear; override;
    property List: TKMColumnBox read fList;
    property Item[aIndex: Integer]: TKMListRow read GetItem; default;
    procedure SetColumns(aFont: TKMFont; aColumns: array of string; aColumnOffsets: array of Word); overload;
    procedure SetColumns(aFont: TKMFont; aColumns: array of string; aColumnOffsets: array of Word; aColumnsToShowWhenListHidden: array of Boolean); overload;
    property DefaultCaption: UnicodeString read fDefaultCaption write fDefaultCaption;
    property DropWidth: Integer read fDropWidth write SetDropWidth;
    property ShowHintWhenShort: Boolean read GetShowHintWhenShort write SetShowHintWhenShort;

    procedure Paint; override;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Math,
  KM_Defaults;


{ TKMDropCommon }
constructor TKMDropCommon.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont;
                                 aStyle: TKMButtonStyle; aAutoClose: Boolean = True);
var
  P: TKMPanel;
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  fDropCount := 10;
  fDropUp := False;
  fFont := aFont;

  fButton := TKMButton.Create(aParent, aLeft+aWidth-aHeight, aTop, aHeight, aHeight, 590, rxGui, aStyle);
  fButton.OnClick := ButtonClick;
  fButton.MakesSound := False;

  P := MasterParent;
  fShape := TKMShape.Create(P, 0, 0, P.Width, P.Height);
  fShape.AnchorsStretch;
  fShape.OnClick := ListHide;

  fAutoClose := aAutoClose;
end;


procedure TKMDropCommon.UpdateVisibility;
begin
  inherited;
  if not Visible then
    CloseList;
end;


function TKMDropCommon.IsOpen: Boolean;
begin
  Result := fShape.Visible;
end;


procedure TKMDropCommon.ButtonClick(Sender: TObject);
begin
  //Call the DoDlick event to show the list AND generate DropBox.OnClick event
  DoClick(fButton.AbsLeft + fButton.Width div 2, fButton.AbsTop + fButton.Height div 2, [], mbLeft);
end;


procedure TKMDropCommon.ListShow(Sender: TObject);
begin
  if ListVisible then
  begin
    ListHide(nil);
    Exit;
  end;

  if fAutoClose and (Count > 0) then
    fShape.Show;

  if Assigned(fOnShowList) then fOnShowList(Self);
end;


procedure TKMDropCommon.DoClick(X, Y: Integer; Shift: TShiftState; Button: TMouseButton);
begin
  //do not invoke inherited here, to fully override parent DoClick method

  //It's common behavior when click on dropbox will show the list
  if fAutoClose then
    ListShow(Self)
  else
    if not ListVisible then
    begin
      fButton.TexId := 591;
      ListShow(Self)
    end else begin
      fButton.TexId := 590;
      ListHide(Self);
    end;

  inherited;
end;


//Handle KeyDown on List
function TKMDropCommon.ListKeyDown(Sender: TObject; Key: Word; Shift: TShiftState): Boolean;
begin
  if fAutoClose and (Key = VK_ESCAPE) then // Close List on ESC, if autoclosable
  begin
    ListHide(nil);
    Result := True;
  end else
    Result := False;
end;


procedure TKMDropCommon.ListClick(Sender: TObject);
begin
  //No need to call fOnChange here since ListChange was already called
  if fAutoClose then ListHide(nil);
end;


procedure TKMDropCommon.ListChange(Sender: TObject);
begin
  if (ItemIndex <> -1) then
    if Assigned(fOnChange) then fOnChange(Self);
end;


procedure TKMDropCommon.ListHide(Sender: TObject);
begin
  fShape.Hide;
end;


procedure TKMDropCommon.SetDropCount(const aValue: Integer);
begin
  fDropCount := aValue;
end;


procedure TKMDropCommon.SetEnabled(aValue: Boolean);
begin
  inherited;
  fButton.Enabled := Enabled;
end;


procedure TKMDropCommon.OpenList;
begin
  ListShow(nil);
end;


procedure TKMDropCommon.CloseList;
begin
  ListHide(nil);
end;


procedure TKMDropCommon.SetOpenList(aOpen: Boolean);
begin
  if aOpen then
    OpenList
  else
    CloseList;
end;


procedure TKMDropCommon.SwitchOpen;
begin
  if IsOpen then
    CloseList
  else
    OpenList;
end;


procedure TKMDropCommon.SetLeft(aValue: Integer);
begin
  inherited;
  // Stick the button to us
  fButton.Left := Left + Width - Height;
end;


procedure TKMDropCommon.SetTop(aValue: Integer);
begin
  inherited;
  // Stick the button to us
  fButton.Top := Top;
end;


procedure TKMDropCommon.SetVisible(aValue: Boolean);
begin
  inherited;
  fButton.Visible := aValue;
  if not aValue then ListHide(Self);
end;


procedure TKMDropCommon.Paint;
begin
  inherited;

  TKMRenderUI.WriteBevel(AbsLeft, AbsTop, Width, Height);

  // Make sure the list stays where it needs to be relative DropBox (e.g. on window resize)
  UpdateDropPosition;
end;


{ TKMDropList }
constructor TKMDropList.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; const aDefaultCaption: UnicodeString;
                               aStyle: TKMButtonStyle; aAutoClose: Boolean = True; aBackAlpha: Single = 0.85);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight, aFont, aStyle, aAutoClose);

  fDefaultCaption := aDefaultCaption;

  fListTopIndex := 0;

  fList := TKMListBox.Create(MasterParent, 0, 0, aWidth, 0, fFont, aStyle);
  fList.Height := fList.ItemHeight * fDropCount;
  fList.AutoHideScrollBar := True; //A drop box should only have a scrollbar if required
  fList.BackAlpha := aBackAlpha;
  fList.OnClick := ListClick;
  fList.OnChange := ListChange;

  DropWidth := aWidth;

  ListHide(nil);
  fList.OnKeyDown := ListKeyDown;
end;


procedure TKMDropList.ListShow(Sender: TObject);
begin
  inherited;
  if ListVisible or (Count < 1) then Exit;

  //Make sure the selected item is visible when list is opened
  if (ItemIndex <> -1) then
  begin
    if InRange(ItemIndex, fListTopIndex, fListTopIndex + fList.GetVisibleRows) then //Try to open list at previously saved scroll position
      fList.TopIndex := fListTopIndex
    else
      fList.TopIndex := ItemIndex;
  end;

  fList.Show;
end;


procedure TKMDropList.ListClick(Sender: TObject);
begin
  fCaption := fList.Item[ItemIndex];

  inherited;
end;


procedure TKMDropList.ListChange(Sender: TObject);
begin
  fCaption := fList.Item[ItemIndex];

  inherited;
end;


procedure TKMDropList.ListHide(Sender: TObject);
begin
  fListTopIndex := fList.TopIndex; //Save list scroll position
  inherited;
  fList.Hide;
end;


function TKMDropList.ListVisible: Boolean;
begin
  Result := fList.Visible;
end;


function TKMDropList.GetItemIndex: Smallint;
begin
  Result := fList.ItemIndex;
end;


procedure TKMDropList.SetItemIndex(aIndex: Smallint);
begin
  fList.ItemIndex := aIndex;
  if aIndex <> -1 then
    fCaption := fList.Item[fList.ItemIndex]
  else
    fCaption := fDefaultCaption;
end;


function TKMDropList.GetShowHintWhenShort: Boolean;
begin
  Result := fList.ShowHintWhenShort;
end;


procedure TKMDropList.SetShowHintWhenShort(const aValue: Boolean);
begin
  fList.ShowHintWhenShort := aValue;
end;


function TKMDropList.IsOpen: Boolean;
begin
  Result := fList.Visible;
end;


procedure TKMDropList.SetDropCount(const aValue: Integer);
begin
  inherited;

  fList.Height := fList.ItemHeight * fDropCount;
end;


procedure TKMDropList.SetDropWidth(aDropWidth: Integer);
begin
  fDropWidth := aDropWidth;
  fList.AbsLeft := AbsLeft + Width - aDropWidth;
  fList.Width := aDropWidth;
end;


procedure TKMDropList.SetEnabled(aValue: Boolean);
begin
  inherited;
  fList.Enabled := Enabled;
  if not Enabled and fList.Visible then
    ListHide(nil);
end;


procedure TKMDropList.SetVisible(aValue: Boolean);
begin
  inherited;
  if not aValue then ListHide(Self);
end;


function TKMDropList.GetCount: Integer;
begin
  Result := fList.Count;
end;


// When new items are added to the list we must update the drop height and position
procedure TKMDropList.UpdateDropPosition;
begin
  if Count > 0 then
  begin
    fList.Height := Math.Min(fDropCount, fList.Count) * fList.ItemHeight + fList.SeparatorsCount*fList.SeparatorHeight;

    if fDropUp then
      fList.AbsTop := AbsTop - fList.Height
    else
      fList.AbsTop := AbsTop + Height;

    fList.Left := AbsLeft + Width - DropWidth - MasterParent.AbsLeft;
  end;
end;


procedure TKMDropList.Add(const aItem: UnicodeString; aTag: Integer = 0);
begin
  fList.Add(aItem, aTag);
end;


procedure TKMDropList.SelectByName(const aText: UnicodeString);
var I: Integer;
begin
  fList.ItemIndex := -1;
  for I := 0 to fList.Count - 1 do
    if fList.Item[I] = aText then
      SetItemIndex(I);
end;


procedure TKMDropList.SelectByTag(aTag: Integer);
var I: Integer;
begin
  fList.ItemIndex := -1;
  for I := 0 to fList.Count - 1 do
    if fList.ItemTags[I] = aTag then
      SetItemIndex(I);
end;


function TKMDropList.HasTag(aTag: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to fList.Count - 1 do
    if fList.ItemTags[I] = aTag then
      Exit(True);
end;


function TKMDropList.IsSelected: Boolean;
begin
  Result := fList.ItemIndex <> -1;
end;


function TKMDropList.GetTag(aIndex: Integer): Integer;
begin
  Result := fList.ItemTags[aIndex];
end;


function TKMDropList.GetSelectedTag: Integer;
begin
  Result := GetTag(fList.ItemIndex);
end;


function TKMDropList.GetItem(aIndex: Integer): UnicodeString;
begin
  Result := fList.Item[aIndex];
end;


procedure TKMDropList.Clear;
begin
  fList.Clear;
end;


procedure TKMDropList.Paint;
var
  col: TColor4;
begin
  inherited;

  if Enabled then
    col := icWhite
  else
    col := icGray2;

  TKMRenderUI.WriteText(AbsLeft+4, AbsTop+4, Width-8, fCaption, fFont, taLeft, col);
end;


{ TKMDropColumns }
constructor TKMDropColumns.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aFont: TKMFont; const aDefaultCaption: UnicodeString; aStyle: TKMButtonStyle; aShowHeader: Boolean = True);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight, aFont, aStyle);

  fListTopIndex := 0;

  fDefaultCaption := aDefaultCaption;

  fList := TKMColumnBox.Create(MasterParent, 0, 0, aWidth, 0, fFont, aStyle);
  fList.BackAlpha := 0.85;
  fList.OnClick := ListClick;
  fList.OnChange := ListChange;
  fList.ShowHeader := aShowHeader;

  DropWidth := aWidth;

  ListHide(nil);
  fList.OnKeyDown := ListKeyDown;
end;


procedure TKMDropColumns.ListShow(Sender: TObject);
begin
  inherited;
  if ListVisible or (Count < 1) then Exit;

  //Make sure the selected item is visible when list is opened
  if (ItemIndex <> -1) then
  begin
    if InRange(ItemIndex, fListTopIndex, fListTopIndex + fList.GetVisibleRows) then //Try to open list at previously saved scroll position
      fList.TopIndex := fListTopIndex
    else
      fList.TopIndex := ItemIndex;
  end;

  fList.Show;
end;


procedure TKMDropColumns.ListClick(Sender: TObject);
begin
  inherited;
end;


procedure TKMDropColumns.ListChange(Sender: TObject);
begin
  inherited;
end;


procedure TKMDropColumns.ListHide(Sender: TObject);
begin
  fListTopIndex := fList.TopIndex; //Save list scroll position
  inherited;
  fList.Hide;
end;


function TKMDropColumns.ListVisible: Boolean;
begin
  Result := fList.Visible;
end;


function TKMDropColumns.GetItemIndex: smallint;
begin
  Result := fList.ItemIndex;
end;


procedure TKMDropColumns.SetItemIndex(aIndex: smallint);
begin
  fList.ItemIndex := aIndex;
end;


procedure TKMDropColumns.SetDropWidth(aDropWidth: Integer);
begin
  fDropWidth := aDropWidth;
  fList.AbsLeft := AbsLeft + Width - aDropWidth;
  fList.Width := aDropWidth;
end;


function TKMDropColumns.GetShowHintWhenShort: Boolean;
begin
  Result := fList.ShowHintWhenShort
end;


procedure TKMDropColumns.SetShowHintWhenShort(const aValue: Boolean);
begin
  fList.ShowHintWhenShort := aValue;
end;


procedure TKMDropColumns.SetColumns(aFont: TKMFont; aColumns: array of string; aColumnOffsets: array of Word);
var
  I: Integer;
  columnsToShowWhenListHidden: array of Boolean;
begin
  SetLength(columnsToShowWhenListHidden, Length(aColumns));
  for I := Low(columnsToShowWhenListHidden) to High(columnsToShowWhenListHidden) do
    columnsToShowWhenListHidden[I] := True; // by default show all columns
  SetColumns(aFont, aColumns, aColumnOffsets, columnsToShowWhenListHidden);
end;


procedure TKMDropColumns.SetColumns(aFont: TKMFont; aColumns: array of string; aColumnOffsets: array of Word; aColumnsToShowWhenListHidden: array of Boolean);
var
  I: Integer;
begin
  Assert(Length(aColumns) = Length(aColumnsToShowWhenListHidden));
  fList.SetColumns(aFont, aColumns, aColumnOffsets);
  SetLength(fColumnsToShowWhenListHidden, Length(aColumnsToShowWhenListHidden));
  for I := Low(aColumnsToShowWhenListHidden) to High(aColumnsToShowWhenListHidden) do
    fColumnsToShowWhenListHidden[I] := aColumnsToShowWhenListHidden[I];
end;


procedure TKMDropColumns.SetEnabled(aValue: Boolean);
begin
  inherited;
  fList.Enabled := Enabled;
end;


procedure TKMDropColumns.SetVisible(aValue: Boolean);
begin
  inherited;
  if not aValue then ListHide(Self);
end;


function TKMDropColumns.GetCount: Integer;
begin
  Result := fList.RowCount;
end;


//When new items are added to the list we must update the drop height and position
procedure TKMDropColumns.UpdateDropPosition;
begin
  if Count > 0 then
  begin
    fList.Height := Math.Min(fDropCount, fList.RowCount) * fList.ItemHeight + fList.Header.Height * Ord(fList.ShowHeader);

    if fDropUp then
      fList.AbsTop := AbsTop - fList.Height
    else
      fList.AbsTop := AbsTop + Height;

    fList.Left := AbsLeft + Width - DropWidth - MasterParent.AbsLeft;
  end;
end;


procedure TKMDropColumns.Add(aItem: TKMListRow);
begin
  fList.AddItem(aItem);
end;


function TKMDropColumns.GetItem(aIndex: Integer): TKMListRow;
begin
  Result := fList.Rows[aIndex];
end;


procedure TKMDropColumns.Clear;
begin
  fList.Clear;
end;


procedure TKMDropColumns.Paint;
var
  col: TColor4;
begin
  inherited;

  if Enabled then
    col := icWhite
  else
    col := icGray2;

  if ItemIndex = -1 then
    TKMRenderUI.WriteText(AbsLeft + 4, AbsTop + 4, Width - 8 - fButton.Width, fDefaultCaption, fFont, taLeft, col)
  else
    fList.DoPaintLine(ItemIndex, AbsLeft, AbsTop, Width - fButton.Width, fColumnsToShowWhenListHidden, False);
end;


end.

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
    pmActOnMouseUp,       // Action triggered only by mouse up (default)
    pmActOnMouseDownNMove // Action triggered by mouse down and mouse move (drag)
  );

type
  // Popup with a short list (context menu)
  // For bigger taks - use TKMForm!
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
    constructor Create(aParent: TKMPanel; aWidth: Integer; aMenuMode: TKMPopUpMenuMode = pmActOnMouseUp);
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


implementation
uses
  Math,
  KM_RenderUI;


{ TKMPopUpMenu }
constructor TKMPopUpMenu.Create(aParent: TKMPanel; aWidth: Integer; aMenuMode: TKMPopUpMenuMode = pmActOnMouseUp);
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
    pmActOnMouseUp:        ColumnBox_List.OnClick  := MenuActionTriggered;
    pmActOnMouseDownNMove: ColumnBox_List.OnChange := MenuActionTriggered;
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

  if fMenuMode = pmActOnMouseUp then
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


end.


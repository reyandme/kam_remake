unit KM_ControlsWaresRow;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls,
  KM_Controls, KM_ControlsBase,
  KM_ResTypes,
  KM_CommonTypes, KM_Defaults;


type
  // Row with resource name and icons
  TKMWaresRow = class(TKMButtonFlatCommon)
  public
    WareCount: Word;
    WareCntAsNumber: Boolean;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth: Integer); overload;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth: Integer; aClickable: Boolean); overload;
    procedure Paint; override;
  end;


  // Ware order bar
  TKMWareOrderRow = class(TKMControl)
  private
    fWaresRow: TKMWaresRow;
    fOrderAdd: TKMButton;
    fOrderLab: TKMLabel;
    fOrderRem: TKMButton;
    fOrderCount: Integer;
    fImmediateOrder: Boolean; //Order count should be changed immediately in control. Should be False usually
    procedure ButtonClick(Sender: TObject; Shift: TShiftState);
    procedure ClickHold(Sender: TObject; Button: TMouseButton; var aHandled: Boolean);
    procedure SetOrderRemHint(const aValue: UnicodeString);
    procedure SetOrderAddHint(const aValue: UnicodeString);
    procedure SetOrderCount(aValue: Integer);
  protected
    procedure SetTop(aValue: Integer); override;
    procedure SetEnabled(aValue: Boolean); override;
    procedure SetVisible(aValue: Boolean); override;
    function DoHandleMouseWheelByDefault: Boolean; override;
  public
    OrderCntMin: Integer;
    OrderCntMax: Integer;
    OnChange: TObjectIntegerEvent;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth: Integer; aOrderCntMax: Integer = MAX_WARES_IN_HOUSE;
                       aOrderCntMin: Integer = 0; aImmediateOrder: Boolean = False);
    property WareRow: TKMWaresRow read fWaresRow;
    property OrderCount: Integer read fOrderCount write SetOrderCount;
    property OrderRemHint: UnicodeString write SetOrderRemHint;
    property OrderAddHint: UnicodeString write SetOrderAddHint;
    procedure MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean); override;
    procedure Paint; override;
  end;


  // Production cost bar
  TKMCostsRow = class(TKMControl)
  public
    RX: TRXType;
    TexID1, TexID2: Word;
    Count: Byte;
    Caption: UnicodeString;
    MaxCount: Byte;
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aMaxCount: Byte = 6);
    procedure Paint; override;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  SysUtils, Math,
  KM_RenderUI,
  KM_ResFonts,
  KM_UtilsExt;

const
  WARE_ROW_HEIGHT = 21;


{ TKMWaresRow }
constructor TKMWaresRow.Create(aParent: TKMPanel; aLeft, aTop, aWidth: Integer);
begin
  Create(aParent, aLeft, aTop, aWidth, False);
end;


constructor TKMWaresRow.Create(aParent: TKMPanel; aLeft, aTop, aWidth: Integer; aClickable: Boolean);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, WARE_ROW_HEIGHT, 0);
  Clickable := aClickable;
  HideHighlight := not aClickable;
end;


procedure TKMWaresRow.Paint;
var
  I: Integer;
begin
  inherited;
  TKMRenderUI.WriteText(AbsLeft + 4, AbsTop + 3, Width-8, Caption, fntGame, taLeft, $FFE0E0E0);
  //Render in reverse order so the rightmost resource is on top (otherwise lighting looks wrong)
  if WareCntAsNumber then
  begin
    TKMRenderUI.WriteText(AbsLeft + Width - 18 - 70 + 24, AbsTop + 3, 40, IntToStr(WareCount), fntGame, taRight, $FFE0E0E0);
    TKMRenderUI.WritePicture(AbsLeft + Width - 18, AbsTop + 3, 14, 14, [], RX, TexID);
  end else
    for I := WareCount - 1 downto 0 do
      TKMRenderUI.WritePicture(AbsLeft + Width - 18 - I * 14, AbsTop + 3, 14, 14, [], RX, TexID);
end;


{ TKMWareOrderRow }
constructor TKMWareOrderRow.Create(aParent: TKMPanel; aLeft, aTop, aWidth: Integer; aOrderCntMax: Integer = MAX_WARES_IN_HOUSE;
                                   aOrderCntMin: Integer = 0; aImmediateOrder: Boolean = False);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, WARE_ROW_HEIGHT);

  fWaresRow := TKMWaresRow.Create(aParent, aLeft + 68, aTop, aWidth - 68);

  fImmediateOrder := aImmediateOrder;

  OrderCntMin := aOrderCntMin;
  OrderCntMax := aOrderCntMax;

  fOrderRem := TKMButton.Create(aParent, aLeft,   0, 20, Height - 2, '-', bsGame);
  fOrderAdd := TKMButton.Create(aParent, aLeft + 46,  0, 20, Height - 2, '+', bsGame);
  //Label after buttons, to be sure it will be on top of them, to let player read value from it, if too long (more then 3 symbols)
  fOrderLab := TKMLabel.Create (aParent, aLeft + 33,  0, '', fntGrey, taCenter);

  fOrderAdd.CapOffsetY := 1;

  fOrderRem.OnClickShift := ButtonClick;
  fOrderAdd.OnClickShift := ButtonClick;
  fOrderRem.OnMouseWheel := MouseWheel;
  fOrderAdd.OnMouseWheel := MouseWheel;
  fWaresRow.OnMouseWheel := MouseWheel;
  fOrderRem.OnClickHold := ClickHold;
  fOrderAdd.OnClickHold := ClickHold;
end;


procedure TKMWareOrderRow.ButtonClick(Sender: TObject; Shift: TShiftState);
var
  amt: Integer;
begin
  amt := GetMultiplicator(Shift);
  if Sender = fOrderRem then
    amt := -amt;

  if amt = 0 then Exit;

  if fImmediateOrder then
    OrderCount := fOrderCount + amt;

  Focus;

  if Assigned(OnChange) then
    OnChange(Self, amt);
end;


function TKMWareOrderRow.DoHandleMouseWheelByDefault: Boolean;
begin
  Result := False;
end;


procedure TKMWareOrderRow.MouseWheel(Sender: TObject; WheelSteps: Integer; var aHandled: Boolean);
var
  amt: Integer;
begin
  inherited;

  if aHandled then Exit;

  amt := MouseWheelStep * WheelSteps;
  if GetKeyState(VK_SHIFT) < 0 then
    amt := amt * 10;

  if fImmediateOrder then
    OrderCount := fOrderCount + amt;

  aHandled := amt <> 0;

  Focus;

  if Assigned(OnChange) then
    OnChange(Self, amt);
end;


procedure TKMWareOrderRow.ClickHold(Sender: TObject; Button: TMouseButton; var aHandled: Boolean);
var
  amt: Integer;
begin
  inherited;
  aHandled := True;

  amt := GetMultiplicator(Button);

  if Sender = fOrderRem then
    amt := -amt;

  if amt = 0 then Exit;

  if fImmediateOrder then
    OrderCount := fOrderCount + amt;

  if Assigned(OnChange) then
    OnChange(Self, amt);
end;


procedure TKMWareOrderRow.SetOrderCount(aValue: Integer);
begin
  fOrderCount := EnsureRange(aValue, OrderCntMin, OrderCntMax);
end;


procedure TKMWareOrderRow.SetOrderRemHint(const aValue: UnicodeString);
begin
  fOrderRem.Hint := aValue;
end;


procedure TKMWareOrderRow.SetOrderAddHint(const aValue: UnicodeString);
begin
  fOrderAdd.Hint := aValue;
end;


procedure TKMWareOrderRow.SetTop(aValue: Integer);
begin
  inherited;
  fWaresRow.Top := aValue;
end;


//Copy property to buttons
procedure TKMWareOrderRow.SetEnabled(aValue: Boolean);
begin
  inherited;
  fWaresRow.Enabled := Enabled;
  fOrderRem.Enabled := Enabled;
  fOrderLab.Enabled := Enabled;
  fOrderAdd.Enabled := Enabled;
end;


//Copy property to buttons. Otherwise they won't be rendered
procedure TKMWareOrderRow.SetVisible(aValue: Boolean);
begin
  inherited;
  fWaresRow.Visible := IsSetVisible;
  fOrderRem.Visible := IsSetVisible;
  fOrderLab.Visible := IsSetVisible;
  fOrderAdd.Visible := IsSetVisible;
end;


procedure TKMWareOrderRow.Paint;
begin
  inherited;

  fOrderRem.Top := Top + 1; //Use internal fTop instead of GetTop (which will return absolute value)
  fOrderLab.Top := Top + 4;
  fOrderAdd.Top := Top + 1;

  fOrderLab.Caption := IntToKStr(OrderCount, 1000);
end;


{ TKMCostsRow }
constructor TKMCostsRow.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aMaxCount: Byte = 6);
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  MaxCount := aMaxCount;
end;


procedure TKMCostsRow.Paint;
var
  I, gap: Integer;
begin
  inherited;
  TKMRenderUI.WriteText(AbsLeft, AbsTop + 4, Width-20, Caption, fntGrey, taLeft, $FFFFFFFF);

  if Count > 0 then
  begin
    if Count <= MaxCount then
      gap := 20
    else
      gap := Trunc(MaxCount * 20 / Count);

    if TexID1 <> 0 then
      for I := Count - 1 downto 0 do
        TKMRenderUI.WritePicture(AbsLeft+Width-gap*(I+1), AbsTop, 20, Height, [], RX, TexID1);
  end else
    begin
    if TexID1 <> 0 then
      TKMRenderUI.WritePicture(AbsLeft+Width-40, AbsTop, 20, Height, [], RX, TexID1);
    if TexID2 <> 0 then
      TKMRenderUI.WritePicture(AbsLeft+Width-20, AbsTop, 20, Height, [], RX, TexID2);
  end;
end;


end.


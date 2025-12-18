unit KM_GUIMapEdUnit;
{$I KaM_Remake.inc}
interface
uses
   Classes, Math, StrUtils, SysUtils, Controls,
   KromUtils,
   KM_Controls, KM_ControlsBase, KM_ControlsDrop, KM_ControlsEdit, KM_ControlsProgressBar,
   KM_Pics, KM_Units, KM_UnitGroup;

type
  TKMMapEdUnit = class
  private
    fUnit: TKMUnit;
    fGroup: TKMUnitGroup;

    procedure SetUnitsPerRaw(aValue: Integer);
    procedure SetPositionUnitConditions(aValue: Integer);

    procedure Unit_ArmyChange1(Sender: TObject);
    procedure Unit_ArmyChangeShift(Sender: TObject; Shift: TShiftState);
    procedure Unit_ArmyChange2(Sender: TObject; Shift: TShiftState);
    procedure Unit_ArmyClickHold(Sender: TObject; aButton: TMouseButton; var aHandled: Boolean);
    procedure UnitConditionsChange(Sender: TObject; Shift: TShiftState);
    procedure UnitConditionsClickHold(Sender: TObject; aButton: TMouseButton; var aHandled: Boolean);
    procedure UnitFishCntChange(Sender: TObject);
  protected
    Panel_Unit: TKMPanel;
    Label_UnitName: TKMLabel;
    Label_UnitCondition: TKMLabel;
    Label_UnitDescription: TKMLabel;
    ConditionBar_Unit: TKMPercentBar;
    Button_ConditionInc, Button_ConditionDefault, Button_ConditionDec: TKMButton;
    Image_UnitPic: TKMImage;
    Edit_FishCount: TKMNumericEdit;

    Panel_Army: TKMPanel;
    Button_Army_RotCW, Button_Army_RotCCW: TKMButton;
    Button_Army_ForUp, Button_Army_ForDown: TKMButton;
    ImageStack_Army: TKMImageStack;
    Label_ArmyCount: TKMLabel;
    Button_ArmyDec, Button_ArmyFood, Button_ArmyInc: TKMButton;
    DropBox_ArmyOrder: TKMDropList;
    Edit_ArmyOrderX: TKMNumericEdit;
    Edit_ArmyOrderY: TKMNumericEdit;
    Edit_ArmyOrderDir: TKMNumericEdit;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure Show(aUnit: TKMUnit); overload;
    procedure Show(aGroup: TKMUnitGroup); overload;
    procedure Hide;
    function Visible: Boolean;
  end;


implementation
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  KM_Defaults, KM_Points,
  KM_InterfaceGame, KM_InterfaceTypes,
  KM_HandsCollection, KM_HandTypes, KM_HandEntity,
  KM_RenderUI,
  KM_Resource, KM_ResFonts, KM_ResTexts, KM_ResUnits, KM_ResTypes,
  KM_Game, KM_UtilsExt, KM_Terrain,
  KM_UnitGroupTypes,
  KM_MapEdTypes;


{ TKMMapEdUnit }
constructor TKMMapEdUnit.Create(aParent: TKMPanel);
begin
  inherited Create;

  Panel_Unit := TKMPanel.Create(aParent, TB_PAD, 45, TB_MAP_ED_WIDTH - TB_PAD, 400);
  Label_UnitName        := TKMLabel.Create(Panel_Unit,0,16,Panel_Unit.Width,0,'',fntOutline,taCenter);
  Image_UnitPic         := TKMImage.Create(Panel_Unit,0,38,54,100,521);
  Label_UnitCondition   := TKMLabel.Create(Panel_Unit,65,40,116,0,gResTexts[TX_UNIT_CONDITION],fntGrey,taCenter);

  ConditionBar_Unit       := TKMPercentBar.Create(Panel_Unit,65,55,116,15);
  Button_ConditionDec     := TKMButton.Create(Panel_Unit,65,78,20,20,'-', bsGame);
  Button_ConditionInc     := TKMButton.Create(Panel_Unit,161,78,20,20,'+', bsGame);
  Button_ConditionDefault := TKMButton.Create(Panel_Unit,86,78,74,20,gResTexts[TX_UNIT_CONDITION_DEFAULT], bsGame);

  Button_ConditionDec.OnClickShift := UnitConditionsChange;
  Button_ConditionInc.OnClickShift := UnitConditionsChange;
  Button_ConditionDec.OnClickHold  := UnitConditionsClickHold;
  Button_ConditionInc.OnClickHold  := UnitConditionsClickHold;
  Button_ConditionDefault.OnClickShift  := UnitConditionsChange;

  Label_UnitDescription := TKMLabel.Create(Panel_Unit,0,152,Panel_Unit.Width,200,'',fntGrey,taLeft); //Taken from LIB resource
  Label_UnitDescription.WordWrap := True;

  TKMLabel.Create(Panel_Army, 0, 185, 'X:', fntGrey, taLeft);
  Edit_FishCount := TKMNumericEdit.Create(Panel_Unit, 20, 172, 1, UNIT_FISH_CONUT_MAX);
  Edit_FishCount.AutoFocusable := False;
  Edit_FishCount.OnChange := UnitFishCntChange;
  Edit_FishCount.Value := UNIT_FISH_CONUT_DEFAULT;

  Panel_Army := TKMPanel.Create(Panel_Unit, 0, 160, Panel_Unit.Width, 400);
  Button_Army_RotCCW  := TKMButton.Create(Panel_Army,       0,  0, 56, 40, 23, rxGui, bsGame);
  Button_Army_RotCW   := TKMButton.Create(Panel_Army,     124,  0, 56, 40, 24, rxGui, bsGame);
  Button_Army_ForUp   := TKMButton.Create(Panel_Army,       0, 46, 56, 40, 33, rxGui, bsGame);
  ImageStack_Army     := TKMImageStack.Create(Panel_Army,  62, 46, 56, 40, 43, 50);
  Label_ArmyCount     := TKMLabel.Create(Panel_Army,       62, 60, 56, 20, '-', fntOutline, taCenter);
  Button_Army_ForDown := TKMButton.Create(Panel_Army,     124, 46, 56, 40, 32, rxGui, bsGame);
  Button_Army_RotCW.OnClickShift   := Unit_ArmyChangeShift;
  Button_Army_RotCCW.OnClickShift  := Unit_ArmyChangeShift;
  Button_Army_ForUp.OnClickShift   := Unit_ArmyChangeShift;
  Button_Army_ForDown.OnClickShift := Unit_ArmyChangeShift;

  Button_ArmyDec  := TKMButton.Create(Panel_Army,  0,92,56,40,'-', bsGame);
  Button_ArmyFood := TKMButton.Create(Panel_Army, 62,92,56,40,29, rxGui, bsGame);
  Button_ArmyInc  := TKMButton.Create(Panel_Army,124,92,56,40,'+', bsGame);
  Button_ArmyDec.OnClickShift := Unit_ArmyChange2;
  Button_ArmyFood.OnClick     := Unit_ArmyChange1;
  Button_ArmyInc.OnClickShift := Unit_ArmyChange2;

  Button_Army_ForUp.OnClickHold   := Unit_ArmyClickHold;
  Button_Army_ForDown.OnClickHold := Unit_ArmyClickHold;
  Button_Army_RotCW.OnClickHold   := Unit_ArmyClickHold;
  Button_Army_RotCCW.OnClickHold  := Unit_ArmyClickHold;
  Button_ArmyDec.OnClickHold      := Unit_ArmyClickHold;
  Button_ArmyInc.OnClickHold      := Unit_ArmyClickHold;

  //Group order
  //todo -cComplicated: Orders should be placed with a cursor (but keep numeric input as well?)
  TKMLabel.Create(Panel_Army, 0, 140, Panel_Army.Width, 0, gResTexts[TX_MAPED_GROUP_ORDER], fntOutline, taLeft);
  DropBox_ArmyOrder := TKMDropList.Create(Panel_Army, 0, 160, Panel_Army.Width, 20, fntMetal, '', bsGame);
  DropBox_ArmyOrder.Add(gResTexts[TX_MAPED_GROUP_ORDER_NONE]);
  DropBox_ArmyOrder.Add(gResTexts[TX_MAPED_GROUP_ORDER_WALK]);
  DropBox_ArmyOrder.Add(gResTexts[TX_MAPED_GROUP_ORDER_ATTACK]);
  DropBox_ArmyOrder.OnChange := Unit_ArmyChange1;

  TKMLabel.Create(Panel_Army, 0, 185, 'X:', fntGrey, taLeft);
  Edit_ArmyOrderX := TKMNumericEdit.Create(Panel_Army, 20, 185, 1, MAX_MAP_SIZE - 1);
  Edit_ArmyOrderX.AutoFocusable := False;
  Edit_ArmyOrderX.OnChange := Unit_ArmyChange1;
  TKMLabel.Create(Panel_Army, 0, 205, 'Y:', fntGrey, taLeft);
  Edit_ArmyOrderY := TKMNumericEdit.Create(Panel_Army, 20, 205, 1, MAX_MAP_SIZE - 1);
  Edit_ArmyOrderY.AutoFocusable := False;
  Edit_ArmyOrderY.OnChange := Unit_ArmyChange1;
  TKMLabel.Create(Panel_Army, 110, 185, gResTexts[TX_MAPED_GROUP_ORDER_DIRECTION], fntGrey, taLeft);
  Edit_ArmyOrderDir := TKMNumericEdit.Create(Panel_Army, 110, 205, 0, 7);
  Edit_ArmyOrderDir.OnChange := Unit_ArmyChange1;
end;


procedure TKMMapEdUnit.Show(aUnit: TKMUnit);
begin
  fUnit := aUnit;
  fGroup := nil;

  Label_UnitDescription.Show;
  Panel_Unit.Show;

  ConditionBar_Unit.Visible := not fUnit.IsAnimal;
  Label_UnitCondition.Visible := not fUnit.IsAnimal;
  Button_ConditionInc.Visible := not fUnit.IsAnimal;
  Button_ConditionDec.Visible := not fUnit.IsAnimal;
  Button_ConditionDefault.Visible := not fUnit.IsAnimal;
  Button_ConditionDefault.Enabled := not fUnit.StartWDefaultCondition;
  Panel_Army.Hide;

  Edit_FishCount.Visible := fUnit is TKMUnitFish;
  if Edit_FishCount.Visible then
    Edit_FishCount.Value := TKMUnitFish(fUnit).FishCount;

  if fUnit = nil then Exit;

  Label_UnitName.Caption := gRes.Units[fUnit.UnitType].GUIName;

  if fUnit.IsAnimal then
  begin
    Image_UnitPic.TexID := 0;
    Image_UnitPic.FlagColor := icGray;
    if fUnit is TKMUnitFish then
      Label_UnitDescription.Caption := gResTexts[TX_MAPED_FISH_COUNT]
    else
      Label_UnitDescription.Caption := '';
  end
  else
  begin
    Image_UnitPic.TexID := gRes.Units[fUnit.UnitType].GUIScroll;
    Image_UnitPic.FlagColor := gHands[fUnit.Owner].FlagColor;
    SetPositionUnitConditions(fUnit.Condition);
    Label_UnitDescription.Caption := gRes.Units[fUnit.UnitType].Description;
  end;
end;


procedure TKMMapEdUnit.Show(aGroup: TKMUnitGroup);
begin
  fUnit := nil;
  fGroup := aGroup;

  Label_UnitDescription.Hide;
  Panel_Unit.Show;

  ConditionBar_Unit.Show;
  Label_UnitCondition.Show;
  Button_ConditionInc.Show;
  Button_ConditionDec.Show;
  Button_ConditionDefault.Show;
  Button_ConditionDefault.Enabled := not fGroup.FlagBearer.StartWDefaultCondition;

  Edit_FishCount.Hide;

  Panel_Army.Show;

  if fGroup = nil then Exit;

  Label_UnitName.Caption := gRes.Units[fGroup.UnitType].GUIName;
  Image_UnitPic.TexID := gRes.Units[fGroup.UnitType].GUIScroll;
  Image_UnitPic.FlagColor := gHands[fGroup.Owner].FlagColor;
  SetPositionUnitConditions(fGroup.Condition);

  //Warrior specific
  Edit_ArmyOrderX.ValueMax := gTerrain.MapX - 1;
  Edit_ArmyOrderY.ValueMax := gTerrain.MapY - 1;

  ImageStack_Army.SetCount(fGroup.MapEdCount, fGroup.UnitsPerRow, fGroup.UnitsPerRow div 2);
  Label_ArmyCount.Caption := IntToStr(fGroup.MapEdCount);
  DropBox_ArmyOrder.ItemIndex := Byte(fGroup.MapEdOrder.Order);
  Edit_ArmyOrderX.Value := fGroup.MapEdOrder.Pos.Loc.X;
  Edit_ArmyOrderY.Value := fGroup.MapEdOrder.Pos.Loc.Y;
  Edit_ArmyOrderDir.Value := Max(Byte(fGroup.MapEdOrder.Pos.Dir) - 1, 0);
  Unit_ArmyChange1(nil);
end;


procedure TKMMapEdUnit.UnitConditionsChange(Sender: TObject; Shift: TShiftState);
var
  U: TKMUnit;
  newCondition: Integer;
begin
  if fUnit = nil then
    U := fGroup.FlagBearer
  else
    U := fUnit;

  newCondition := U.Condition;

  if Sender = Button_ConditionDefault then
    U.StartWDefaultCondition := not U.StartWDefaultCondition
  else if Sender = Button_ConditionInc then
  begin
    newCondition := U.Condition + GetMultiplicator(Shift);
    U.StartWDefaultCondition := False;
    Button_ConditionDefault.Enable;
  end else if Sender = Button_ConditionDec then
  begin
    newCondition := U.Condition - GetMultiplicator(Shift);
    U.StartWDefaultCondition := False;
    Button_ConditionDefault.Enable;
  end else if Sender = Button_ArmyFood then
  begin
    if fGroup.Condition = UNIT_MAX_CONDITION then
    begin
      newCondition := TKMUnitGroup.GetDefaultCondition;
      U.StartWDefaultCondition := True;
      Button_ConditionDefault.Disable;
    end else
    begin
      newCondition := UNIT_MAX_CONDITION;
      U.StartWDefaultCondition := False;
      Button_ConditionDefault.Enable;
    end;
  end;

  if fGroup <> nil then
  begin
    fGroup.Condition := newCondition;
    if newCondition = TKMUnitGroup.GetDefaultCondition then
      U.StartWDefaultCondition := True;
  end
  else
  begin
    fUnit.Condition := newCondition;
    if newCondition = TKMUnit.GetDefaultCondition then
      U.StartWDefaultCondition := True;
  end;

  if U.StartWDefaultCondition then
  begin
    if fGroup <> nil then
      fGroup.Condition := TKMUnitGroup.GetDefaultCondition
    else
      fUnit.Condition := TKMUnit.GetDefaultCondition;
    Button_ConditionDefault.Disable;
  end;
  SetPositionUnitConditions(U.Condition);
end;


procedure TKMMapEdUnit.UnitConditionsClickHold(Sender: TObject; aButton: TMouseButton; var aHandled: Boolean);
begin
  if (Sender = Button_ConditionDec)
    or (Sender = Button_ConditionInc) then
    UnitConditionsChange(Sender, GetShiftState(aButton));
end;


procedure TKMMapEdUnit.UnitFishCntChange(Sender: TObject);
begin
  Assert(fUnit is TKMUnitFish);

  TKMUnitFish(fUnit).FishCount := Edit_FishCount.Value;
  gGame.MapEditor.Deposits.UpdateAreas([rdFish]);
end;


procedure TKMMapEdUnit.Unit_ArmyChange1(Sender: TObject);
begin
  // Use empty shift state, because value will change too fast otherwise
  Unit_ArmyChangeShift(Sender, []);
end;


procedure TKMMapEdUnit.SetPositionUnitConditions(aValue: Integer);
begin
  ConditionBar_Unit.Caption :=  IntToStr(aValue) + '/' + IntToStr(UNIT_MAX_CONDITION);
  ConditionBar_Unit.Position := aValue / UNIT_MAX_CONDITION;
end;


procedure TKMMapEdUnit.SetUnitsPerRaw(aValue: Integer);
begin
  fGroup.UnitsPerRow := Max(aValue, 1);
end;


procedure TKMMapEdUnit.Unit_ArmyChangeShift(Sender: TObject; Shift: TShiftState);
var
  rotCnt: Integer;
begin
  if Sender = Button_Army_ForUp then
    SetUnitsPerRaw(fGroup.UnitsPerRow - GetMultiplicator(Shift, RMB_ADD_ROWS_CNT));

  if Sender = Button_Army_ForDown then
    SetUnitsPerRaw(fGroup.UnitsPerRow + GetMultiplicator(Shift, RMB_ADD_ROWS_CNT));

  ImageStack_Army.SetCount(fGroup.MapEdCount, fGroup.UnitsPerRow, fGroup.UnitsPerRow div 2);
  Label_ArmyCount.Caption := IntToStr(fGroup.MapEdCount);

  if (Sender = Button_Army_RotCW) or (Sender = Button_Army_RotCCW) then
  begin
    // 180 degrees by Shift
    if ssShift in Shift then
      rotCnt := 4
    else
    // 90 degrees by RMB
    if IsRMBInShiftState(Shift) then
      rotCnt := 2
    else
      rotCnt := 1;

    rotCnt := rotCnt * (2 * Byte(Sender = Button_Army_RotCW) - 1);

    fGroup.Direction := KMAddDirection(fGroup.Direction, rotCnt);
  end;

  fGroup.ResetAnimStep;

  //Toggle between full and half condition
  if Sender = Button_ArmyFood then
    UnitConditionsChange(Sender, []);

  fGroup.MapEdOrder.Order := TKMGroupInitialOrder(DropBox_ArmyOrder.ItemIndex);
  fGroup.MapEdOrder.Pos.Loc.X := Edit_ArmyOrderX.Value;
  fGroup.MapEdOrder.Pos.Loc.Y := Edit_ArmyOrderY.Value;
  fGroup.MapEdOrder.Pos.Dir := TKMDirection(Edit_ArmyOrderDir.Value + 1);

  if DropBox_ArmyOrder.ItemIndex = 0 then
  begin
    Edit_ArmyOrderX.Disable;
    Edit_ArmyOrderY.Disable;
    Edit_ArmyOrderDir.Disable;
  end
  else
    if DropBox_ArmyOrder.ItemIndex = 2 then
    begin
      Edit_ArmyOrderX.Enable;
      Edit_ArmyOrderY.Enable;
      Edit_ArmyOrderDir.Disable; //Attack position doesn't let you set direction
    end
    else
    begin
      Edit_ArmyOrderX.Enable;
      Edit_ArmyOrderY.Enable;
      Edit_ArmyOrderDir.Enable;
    end;
end;


procedure TKMMapEdUnit.Unit_ArmyClickHold(Sender: TObject; aButton: TMouseButton; var aHandled: Boolean);
begin
  if (Sender = Button_ArmyDec)
    or (Sender = Button_ArmyInc) then
    Unit_ArmyChange2(Sender, GetShiftState(AButton));

  if (Sender = Button_Army_ForUp)
    or (Sender = Button_Army_ForDown) then
    Unit_ArmyChangeShift(Sender, GetShiftState(AButton));

  if (Sender = Button_Army_RotCW)
    or (Sender = Button_Army_RotCCW) then
    Unit_ArmyChange1(Sender);
end;


procedure TKMMapEdUnit.Unit_ArmyChange2(Sender: TObject; Shift: TShiftState);
var
  newCount: Integer;
begin
  if Sender = Button_ArmyDec then
    //Decrease
    newCount := fGroup.MapEdCount - GetMultiplicator(Shift)
  else
    //Increase
    newCount := fGroup.MapEdCount + GetMultiplicator(Shift);

  fGroup.MapEdCount := EnsureRange(newCount, 1, MAPED_GROUP_MAX_CNT); //Limit max members

  if ssCtrl in Shift then
    SetUnitsPerRaw(Ceil(Sqrt(1.5*fGroup.MapEdCount)));

  ImageStack_Army.SetCount(fGroup.MapEdCount, fGroup.UnitsPerRow, fGroup.UnitsPerRow div 2);
  Label_ArmyCount.Caption := IntToStr(fGroup.MapEdCount);
end;


procedure TKMMapEdUnit.Hide;
begin
  Panel_Unit.Hide;
end;


procedure TKMMapEdUnit.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  if (Key = VK_ESCAPE)
    and Visible
    and (gMySpectator.Selected <> nil) then
    begin
      gMySpectator.Selected := nil;
      Hide;
      aHandled := True;
    end;
end;


function TKMMapEdUnit.Visible: Boolean;
begin
  Result := Panel_Unit.Visible;
end;


end.

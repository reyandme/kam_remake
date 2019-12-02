unit KM_GUIMapEdTownOffence;
{$I KaM_Remake.inc}
interface
uses
   Classes, Controls, Math, SysUtils,
   KM_Controls,
   KM_InterfaceDefaults,
   KM_Points, KM_AIAttacks, KM_GUIMapEdTownAttackPopUp;

type
  TKMMapEdTownOffence = class (TKMMapEdSubMenuPage)
  private
    fAttackPopUp: TKMMapEdTownAttack;
    procedure Attacks_Add(Sender: TObject);
    procedure Attacks_Del(Sender: TObject);
    procedure Attacks_Edit(aIndex: Integer);
    procedure Attacks_ListClick(Sender: TObject);
    procedure Attacks_ListDoubleClick(Sender: TObject);
    procedure Attacks_OnDone(Sender: TObject);
    procedure Attacks_Refresh;
    procedure AutoAttackClick(Sender: TObject);
    procedure SetAttackPopUp(aValue: TKMMapEdTownAttack);
    procedure UpdateControls;
  protected
    Panel_Offence: TKMPanel;
      CheckBox_AutoAttack: TKMCheckBox;
      ColumnBox_Attacks: TKMColumnBox;
      Button_AttacksAdd: TKMButton;
      Button_AttacksDel: TKMButton;
  public
    constructor Create(aParent: TKMPanel);

    property AttackPopUp: TKMMapEdTownAttack read fAttackPopUp write SetAttackPopUp;

    procedure Show;
    procedure Hide;
    function Visible: Boolean; override;
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_RenderUI, KM_ResFonts, KM_InterfaceGame, KM_Hand, KM_Utils;


{ TKMMapEdTownOffence }
constructor TKMMapEdTownOffence.Create(aParent: TKMPanel);
begin
  inherited Create;

  Panel_Offence := TKMPanel.Create(aParent, 0, 28, TB_MAP_ED_WIDTH, 400);
  TKMLabel.Create(Panel_Offence, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_AI_ATTACK], fntOutline, taCenter);

  CheckBox_AutoAttack := TKMCheckBox.Create(Panel_Offence, 9, 24, TB_MAP_ED_WIDTH - 9, 20, gResTexts[TX_MAPED_AI_ATTACK_AUTO], fntMetal);
  CheckBox_AutoAttack.Hint := GetHintWHotKey(TX_MAPED_AI_ATTACK_AUTO_HINT, MAPED_SUBMENU_ACTIONS_HOTKEYS[0]);
  CheckBox_AutoAttack.OnClick := AutoAttackClick;

  ColumnBox_Attacks := TKMColumnBox.Create(Panel_Offence, 9, 50, TB_MAP_ED_WIDTH - 9, 210, fntGame, bsGame);
  ColumnBox_Attacks.SetColumns(fntOutline,
    [gResTexts[TX_MAPED_AI_ATTACK_COL_TYPE],
     gResTexts[TX_MAPED_AI_ATTACK_COL_DELAY],
     gResTexts[TX_MAPED_AI_ATTACK_COL_MEN],
     gResTexts[TX_MAPED_AI_ATTACK_COL_TARGET],
     gResTexts[TX_MAPED_AI_ATTACK_COL_LOC]], [0, 20, 60, 100, 130], True);
  ColumnBox_Attacks.OnClick := Attacks_ListClick;
  ColumnBox_Attacks.OnDoubleClick := Attacks_ListDoubleClick;

  Button_AttacksAdd := TKMButton.Create(Panel_Offence, 9, 270, 25, 25, '+', bsGame);
  Button_AttacksAdd.OnClick := Attacks_Add;
  Button_AttacksAdd.Hint := GetHintWHotKey(TX_MAPED_AI_ATTACK_ADD, MAPED_SUBMENU_ACTIONS_HOTKEYS[1]);
  Button_AttacksDel := TKMButton.Create(Panel_Offence, 39, 270, 25, 25, 'X', bsGame);
  Button_AttacksDel.OnClick := Attacks_Del;
  Button_AttacksDel.Hint := GetHintWHotKey(TX_MAPED_AI_ATTACK_DEL, MAPED_SUBMENU_ACTIONS_HOTKEYS[2]);

  fSubMenuActionsEvents[0] := AutoAttackClick;
  fSubMenuActionsEvents[1] := Attacks_Add;
  fSubMenuActionsEvents[2] := Attacks_Del;

  fSubMenuActionsCtrls[0] := CheckBox_AutoAttack;
  fSubMenuActionsCtrls[1] := Button_AttacksAdd;
  fSubMenuActionsCtrls[2] := Button_AttacksDel;
end;


//Add a dummy attack and let mapmaker edit it
procedure TKMMapEdTownOffence.Attacks_Add(Sender: TObject);
var
  AA: TKMAIAttack;
begin
  FillChar(AA, SizeOf(AA), #0);
  gMySpectator.Hand.AI.General.Attacks.AddAttack(AA);

  Attacks_Refresh;
  ColumnBox_Attacks.ItemIndex := gMySpectator.Hand.AI.General.Attacks.Count - 1;

  //Edit the attack we have just appended
  Attacks_Edit(ColumnBox_Attacks.ItemIndex);
end;


procedure TKMMapEdTownOffence.Attacks_Del(Sender: TObject);
var I: Integer;
begin
  I := ColumnBox_Attacks.ItemIndex;
  if InRange(I, 0, gMySpectator.Hand.AI.General.Attacks.Count - 1) then
    gMySpectator.Hand.AI.General.Attacks.Delete(I);

  Attacks_Refresh;
end;


procedure TKMMapEdTownOffence.Attacks_Edit(aIndex: Integer);
begin
  Assert(InRange(aIndex, 0, gMySpectator.Hand.AI.General.Attacks.Count - 1));
  AttackPopUp.Show(gMySpectator.HandID, aIndex);
end;


procedure TKMMapEdTownOffence.Attacks_ListClick(Sender: TObject);
var
  I: Integer;
begin
  I := ColumnBox_Attacks.ItemIndex;
  Button_AttacksDel.Enabled := InRange(I, 0, gMySpectator.Hand.AI.General.Attacks.Count - 1);
end;


procedure TKMMapEdTownOffence.Attacks_ListDoubleClick(Sender: TObject);
var
  I: Integer;
begin
  I := ColumnBox_Attacks.ItemIndex;

  //Check if user double-clicked on an existing item (not on an empty space)
  if InRange(I, 0, gMySpectator.Hand.AI.General.Attacks.Count - 1) then
    Attacks_Edit(I);
end;


procedure TKMMapEdTownOffence.Attacks_OnDone(Sender: TObject);
begin
  Attacks_Refresh;
end;


procedure TKMMapEdTownOffence.Attacks_Refresh;
const
  Typ: array [TKMAIAttackType] of String = ('O', 'R');
  Tgt: array [TKMAIAttackTarget] of String = ('U', 'HA', 'HS', 'Pos');
  TypeHint: array [TKMAIAttackType] of Integer = (TX_MAPED_AI_ATTACK_TYPE_ONCE, TX_MAPED_AI_ATTACK_TYPE_REP);
  TargetHint: array [TKMAIAttackTarget] of Integer = (TX_MAPED_AI_TARGET_CLOSEST,
                                                   TX_MAPED_AI_TARGET_HOUSE_ARMY,
                                                   TX_MAPED_AI_TARGET_HOUSE_START,
                                                   TX_MAPED_AI_TARGET_CUSTOM);
var
  I, Index, TopIndex: Integer;
  A: TKMAIAttack;
  CustomPosS: String;
begin
  TopIndex := ColumnBox_Attacks.TopIndex; //Save index and TopIndex to restore after refresh
  Index := ColumnBox_Attacks.ItemIndex;
  ColumnBox_Attacks.Clear;

  for I := 0 to gMySpectator.Hand.AI.General.Attacks.Count - 1 do
  begin
    A := gMySpectator.Hand.AI.General.Attacks[I];
    CustomPosS := '';
    if A.Target = attCustomPosition then
      CustomPosS := TypeToString(A.CustomPosition);

    ColumnBox_Attacks.AddItem(MakeListRow([Typ[A.AttackType],
                                           IntToStr(A.Delay div 10),
                                           IntToStr(A.TotalMen),
                                           Tgt[A.Target],
                                           CustomPosS],
                                          [gResTexts[TypeHint[A.AttackType]],
                                           gResTexts[TX_MAPED_AI_ATTACK_DELAY] + ': ' + IntToStr(A.Delay),
                                           gResTexts[TX_MAPED_AI_ATTACK_SOLDIERS] + ': ' + IntToStr(A.TotalMen),
                                           gResTexts[TargetHint[A.Target]],
                                           CustomPosS]));
  end;

  Attacks_ListClick(nil);

  CheckBox_AutoAttack.Checked := gMySpectator.Hand.AI.Setup.AutoAttack;

  //Try to restore previous selected element
  if Index >= ColumnBox_Attacks.RowCount then
    Index := ColumnBox_Attacks.RowCount - 1;

  ColumnBox_Attacks.ItemIndex := Index;
  ColumnBox_Attacks.TopIndex := TopIndex;

  ColumnBox_Attacks.JumpToSelected;

  UpdateControls;
end;


procedure TKMMapEdTownOffence.UpdateControls;
begin
  ColumnBox_Attacks.Enabled := not CheckBox_AutoAttack.Checked;
  Button_AttacksAdd.Enabled := not CheckBox_AutoAttack.Checked;
  Button_AttacksDel.Enabled := ColumnBox_Attacks.IsSelected;
end;


procedure TKMMapEdTownOffence.AutoAttackClick(Sender: TObject);
begin
  gMySpectator.Hand.AI.Setup.AutoAttack := CheckBox_AutoAttack.Checked;
  UpdateControls;
end;


procedure TKMMapEdTownOffence.Hide;
begin
  Panel_Offence.Hide;
end;


procedure TKMMapEdTownOffence.SetAttackPopUp(aValue: TKMMapEdTownAttack);
begin
  fAttackPopUp := aValue;
  fAttackPopUp.fOnDone := Attacks_OnDone;
end;


procedure TKMMapEdTownOffence.Show;
begin
  Attacks_Refresh;
  Panel_Offence.Show;
end;


function TKMMapEdTownOffence.Visible: Boolean;
begin
  Result := Panel_Offence.Visible;
end;


end.

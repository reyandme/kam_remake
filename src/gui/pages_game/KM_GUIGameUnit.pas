unit KM_GUIGameUnit;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, SysUtils, KM_Controls, KM_Units, KM_UnitGroup, KM_CommonTypes;//, KM_CommonClasses, KM_CommonTypes, KM_Defaults, KM_Pics,

type
  TKMGUIGameUnit = class
  private
    fAnimStep: Cardinal;
    fAskDismiss: Boolean;
    fJoiningGroups: Boolean;
    fSetViewportEvent: TPointFEvent;

    procedure Unit_Dismiss(Sender: TObject);
    procedure Dismiss_Click(Sender: TObject);
    procedure Army_ActivateControls(aGroup: TKMUnitGroup);
    procedure Army_Issue_Order(Sender: TObject);
    procedure ShowDismissBtn;
    procedure Unit_Scroll_Click(Sender: TObject);
    procedure Show_Common(aUnit: TKMUnit);
    procedure SendUnitDismissCommand;
  protected
    Panel_Unit: TKMPanel;
      Image_PlayerFlag: TKMImage;
      Label_UnitName: TKMLabel;
      Label_UnitCondition: TKMLabel;
      Label_UnitTask: TKMLabel;
      Label_UnitDescription: TKMLabel;
      ConditionBar_Unit: TKMPercentBar;
      Image_UnitPic: TKMImage;
      Button_Unit_Dismiss: TKMButton;

      Panel_Unit_Dismiss: TKMPanel;
         Label_Unit_Dismiss: TKMLabel;
         Button_Unit_DismissYes,Button_Unit_DismissNo: TKMButton;

      Panel_Army: TKMPanel;
        Button_Army_GoTo,Button_Army_Stop,Button_Army_Attack: TKMButton;
        Button_Army_RotCW,Button_Army_Storm,Button_Army_RotCCW: TKMButton;
        Button_Army_ForUp,Button_Army_ForDown: TKMButton;
        ImageStack_Army: TKMImageStack;
        Button_Army_Split,Button_Army_Join,Button_Army_Feed: TKMButton;
        Label_Army_MembersCount: TKMLabel;

      Panel_Army_JoinGroups: TKMPanel;
        Button_Army_Join_Cancel: TKMButton;
        Label_Army_Join_Message: TKMLabel;
  public
    OnUnitDismiss: TEvent;
    OnSelectingTroopDirection: TBooleanFunc;
    OnArmyCanTakeOrder: TBooleanFunc;
    constructor Create(aParent: TKMPanel; aSetViewportEvent: TPointFEvent);
    property AskDismiss: Boolean read fAskDismiss write fAskDismiss;
    property JoiningGroups: Boolean read fJoiningGroups write fJoiningGroups;

    function Visible: Boolean;
    procedure Hide;
    procedure KeyUp(Key: Word; Shift: TShiftState);

    procedure ShowUnitInfo(aUnit: TKMUnit; aAskDismiss: Boolean = False);
    procedure ShowGroupInfo(Sender: TKMUnitGroup; aAskDismiss: Boolean = False);
    procedure Army_HideJoinMenu(Sender: TObject);
  end;
  


implementation
uses
  Math,
  KM_Game, KM_GameInputProcess, KM_HandsCollection, KM_Hand, KM_HandSpectator, KM_InterfaceGame, KM_RenderUI,
  KM_Resource, KM_ResFonts, KM_ResTexts, KM_ResKeys, KM_ResHouses, KM_ResSound, KM_ResCursors, KM_ResUnits, KM_Pics,
  KM_UnitWarrior, KM_Utils, KM_Defaults, KM_Sound, KM_CommonUtils;

const
  UNIT_FLAG_TEX_ID = 1159;
  UNIT_FLAG_TEX_ID_FRAME = 5;


{ TKMGUIGameUnit }

constructor TKMGUIGameUnit.Create(aParent: TKMPanel; aSetViewportEvent: TPointFEvent);
begin
  fSetViewportEvent := aSetViewportEvent;
  fAnimStep := 0;

  Panel_Unit := TKMPanel.Create(aParent, TB_PAD, 44, TB_WIDTH, 400);
    Image_PlayerFlag := TKMImage.Create(Panel_Unit, 0, 19, 20, 13, 1159, rxHouses); // before unit name label
    Label_UnitName        := TKMLabel.Create(Panel_Unit,0,16,TB_WIDTH,30,'',fntOutline,taCenter);

    Image_UnitPic         := TKMImage.Create(Panel_Unit,0,38,54,100,521);
    Image_UnitPic.Hint    := gResTexts[TX_UNIT_SCROLL_HINT];
    Image_UnitPic.OnClick := Unit_Scroll_Click;
    Image_UnitPic.HighlightOnMouseOver := True;
    Image_UnitPic.HighlightCoef := 0.1; //highlight just a little bit

    Label_UnitCondition   := TKMLabel.Create(Panel_Unit,65,40,116,30,gResTexts[TX_UNIT_CONDITION],fntGrey,taCenter);
    ConditionBar_Unit     := TKMPercentBar.Create(Panel_Unit,65,55,116,15);

    Button_Unit_Dismiss   := TKMButton.Create(Panel_Unit,65,41,30,30,667, rxGui, bsGame);
    Button_Unit_Dismiss.OnClick := Dismiss_Click;

    Label_UnitTask        := TKMLabel.Create(Panel_Unit,65,80,116,60,'',fntGrey,taLeft);
    Label_UnitTask.AutoWrap := True;
    Label_UnitDescription := TKMLabel.Create(Panel_Unit,0,152,TB_WIDTH,200,'',fntGrey,taLeft); // Taken from LIB resource
    Label_UnitDescription.AutoWrap := True;

    Panel_Unit_Dismiss := TKMPanel.Create(Panel_Unit, 0, 132, TB_WIDTH, 182);
    Label_Unit_Dismiss             := TKMLabel.Create(Panel_Unit_Dismiss,0,2,TB_WIDTH,20,gResTexts[TX_UNIT_TASK_DISMISS_CONFIRMATION],fntGrey,taCenter);
    Label_Unit_Dismiss.AutoWrap    := True;
    Button_Unit_DismissYes         := TKMButton.Create(Panel_Unit_Dismiss,0,100,TB_WIDTH,30,gResTexts[TX_UNIT_TASK_DISMISS_BTN],bsGame);
    Button_Unit_DismissNo          := TKMButton.Create(Panel_Unit_Dismiss,0,135,TB_WIDTH,30,gResTexts[TX_WORD_CANCEL],bsGame);
    Button_Unit_DismissYes.OnClick := Unit_Dismiss;
    Button_Unit_DismissNo.OnClick  := Unit_Dismiss;

    Panel_Army := TKMPanel.Create(Panel_Unit, 0, 160, TB_WIDTH, 182);
    // Military buttons start at 8.170 and are 52x38/30 (60x46)
    Button_Army_GoTo   := TKMButton.Create(Panel_Army,  0,  0, 56, 40, 27, rxGui, bsGame);
    Button_Army_Stop   := TKMButton.Create(Panel_Army, 62,  0, 56, 40, 26, rxGui, bsGame);
    Button_Army_Attack := TKMButton.Create(Panel_Army,124,  0, 56, 40, 25, rxGui, bsGame);
    Button_Army_RotCCW := TKMButton.Create(Panel_Army,  0, 46, 56, 40, 23, rxGui, bsGame);
    Button_Army_Storm  := TKMButton.Create(Panel_Army, 62, 46, 56, 40, 28, rxGui, bsGame);
    Button_Army_RotCW  := TKMButton.Create(Panel_Army,124, 46, 56, 40, 24, rxGui, bsGame);
    Button_Army_ForUp  := TKMButton.Create(Panel_Army,  0, 92, 56, 40, 33, rxGui, bsGame);
    ImageStack_Army    := TKMImageStack.Create(Panel_Army, 62, 92, 56, 40, 43, 50);
    Label_Army_MembersCount := TKMLabel.Create(Panel_Army, 62, 106, 56, 20, '', fntOutline, taCenter);
    Button_Army_ForDown:= TKMButton.Create(Panel_Army,124, 92, 56, 40, 32, rxGui, bsGame);
    Button_Army_Split  := TKMButton.Create(Panel_Army,  0,138, 56, 34, 31, rxGui, bsGame);
    Button_Army_Join   := TKMButton.Create(Panel_Army, 62,138, 56, 34, 30, rxGui, bsGame);
    Button_Army_Feed   := TKMButton.Create(Panel_Army,124,138, 56, 34, 29, rxGui, bsGame);

    // All one-click-action (i.e. not attack, move, link up) army controls have a single procedure
    // that decides what to do based on Sender
    Button_Army_GoTo.OnClick    := Army_Issue_Order;
    Button_Army_Stop.OnClick    := Army_Issue_Order;
    Button_Army_Attack.OnClick  := Army_Issue_Order;
    Button_Army_RotCW.OnClick   := Army_Issue_Order;
    Button_Army_Storm.OnClick   := Army_Issue_Order;
    Button_Army_RotCCW.OnClick  := Army_Issue_Order;
    Button_Army_ForDown.OnClick := Army_Issue_Order;
    Button_Army_ForUp.OnClick   := Army_Issue_Order;
    Button_Army_Split.OnClick   := Army_Issue_Order;
    Button_Army_Join.OnClick    := Army_Issue_Order;
    Button_Army_Feed.OnClick    := Army_Issue_Order;

    // Disable not working buttons
    Button_Army_GoTo.Hide;
    Button_Army_Attack.Hide;

    // Hints
    Button_Army_GoTo.Hint     := gResTexts[TX_ARMY_GOTO_HINT];
    Button_Army_Stop.Hint     := GetHintWHotKey(TX_TROOP_HALT_HINT, SC_ARMY_HALT);
    Button_Army_Attack.Hint   := gResTexts[TX_ARMY_ATTACK_HINT];
    Button_Army_RotCW.Hint    := GetHintWHotKey(TX_ARMY_ROTATE_CW_HINT, SC_ARMY_ROTATE_CW);
    Button_Army_Storm.Hint    := GetHintWHotKey(TX_ARMY_STORM_HINT, SC_ARMY_STORM);
    Button_Army_RotCCW.Hint   := GetHintWHotKey(TX_ARMY_ROTATE_CCW_HINT, SC_ARMY_ROTATE_CCW);
    Button_Army_ForDown.Hint  := GetHintWHotKey(TX_ARMY_LINE_ADD_HINT, SC_ARMY_ADD_LINE);
    Button_Army_ForUp.Hint    := GetHintWHotKey(TX_ARMY_LINE_REM_HINT, SC_ARMY_DEL_LINE);
    Button_Army_Split.Hint    := GetHintWHotKey(TX_TROOP_SPLIT_HINT, SC_ARMY_SPLIT);
    Button_Army_Join.Hint     := GetHintWHotKey(TX_TROOP_LINK_HINT, SC_ARMY_LINK);
    Button_Army_Feed.Hint     := GetHintWHotKey(TX_ARMY_FEED_HINT, SC_ARMY_FOOD);

    { Army controls...
    Go to     Stop      Attack
    Rotate    Storm     Rotate
    -Column   [Info]    +Column
    Split     Join      Feed }

    Panel_Army_JoinGroups := TKMPanel.Create(Panel_Unit, 0, 160, TB_WIDTH, 182);
    Label_Army_Join_Message := TKMLabel.Create(Panel_Army_JoinGroups, 0, 30, TB_WIDTH, 65, gResTexts[TX_ARMY_JOIN_SELECT], fntOutline, taCenter);
    Button_Army_Join_Cancel := TKMButton.Create(Panel_Army_JoinGroups, 0, 95, TB_WIDTH, 30, gResTexts[TX_ARMY_JOIN_CANCEL], bsGame);

  Button_Army_Join_Cancel.OnClick := Army_HideJoinMenu;
end;


procedure TKMGUIGameUnit.ShowDismissBtn;
const
  DISMISS_PADDING = 32;
begin
  if Button_Unit_Dismiss.Visible then
  begin
    Label_UnitCondition.Left := 65 + DISMISS_PADDING;
    ConditionBar_Unit.Left   := 65 + DISMISS_PADDING;
    Label_UnitCondition.Width := 116 - DISMISS_PADDING;
    ConditionBar_Unit.Width   := 116 - DISMISS_PADDING;
  end else begin
    Label_UnitCondition.Left := 65;
    ConditionBar_Unit.Left   := 65;
    Label_UnitCondition.Width := 116;
    ConditionBar_Unit.Width   := 116;
  end;
end;


procedure TKMGUIGameUnit.Show_Common(aUnit: TKMUnit);
var
  HLabelWidth: Integer;
begin
  Image_PlayerFlag.FlagColor := gHands[aUnit.Owner].FlagColor;
  Image_PlayerFlag.Hint      := Format(gResTexts[TX_PLAYER_FLAG_HINT], [gHands[aUnit.Owner].OwnerName]);

  Inc(fAnimStep);
  Image_PlayerFlag.TexID := UNIT_FLAG_TEX_ID + fAnimStep mod UNIT_FLAG_TEX_ID_FRAME;

  // Common properties
  Label_UnitName.Caption      := gRes.Units[aUnit.UnitType].GUIName;
  Image_UnitPic.TexID         := gRes.Units[aUnit.UnitType].GUIScroll;
  Image_UnitPic.FlagColor     := gHands[aUnit.Owner].FlagColor;

  ConditionBar_Unit.Position  := aUnit.Condition / UNIT_MAX_CONDITION;

  HLabelWidth := gRes.Fonts[fntOutline].GetTextSize(Label_UnitName.Caption).X;
  if HLabelWidth <= TB_WIDTH - 2*Image_PlayerFlag.Width then
    Label_UnitName.Left := 0
  else if HLabelWidth <= TB_WIDTH - Image_PlayerFlag.Width then
    Label_UnitName.Left := Image_PlayerFlag.Width
  else
    Label_UnitName.Left := Max(TB_WIDTH - HLabelWidth, 0);
end;


procedure TKMGUIGameUnit.ShowUnitInfo(aUnit: TKMUnit; aAskDismiss: Boolean = False);
var
  HasSchools: Boolean;
begin
  Assert(gMySpectator.Selected = aUnit);

  fAskDismiss  := aAskDismiss;

  Panel_Unit.Show;

  // Common properties
  Show_Common(aUnit);

  Label_UnitTask.Caption      := aUnit.GetActivityText;

  Button_Unit_Dismiss.Visible := SHOW_DISMISS_UNITS_BTN
                                 and aUnit.Dismissable   // Its possible to block dismiss from scripts
                                 and gMySpectator.IsSelectedMyObj; // Allow to dismiss only our units

  if aUnit.IsDismissing
    or aUnit.DismissInProgress then //Check if we started dismiss process
  begin
    Button_Unit_Dismiss.TexID := 668;
    Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_CANCEL_HINT];
    Button_Unit_Dismiss.Enabled := aUnit.IsDismissCancelAvailable;
    Panel_Unit_Dismiss.Visible := False;
  end else begin
    HasSchools := gMySpectator.Hand.Stats.GetHouseQty(htSchool) > 0;

    if fAskDismiss and not aUnit.IsDismissAvailable then
      fAskDismiss := False; //Hide dismiss panel if dismiss is not available anymore

    Button_Unit_Dismiss.Enabled := not fAskDismiss and HasSchools and not aUnit.IsHungry and aUnit.IsDismissAvailable;
    Button_Unit_Dismiss.TexID := 667;

    if not HasSchools then
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_NOSCHOOLS_HINT]
    else if aUnit.IsHungry then
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_HUNGRY_HINT]   
    else if not aUnit.IsDismissAvailable then
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_NOT_AVAIL_HINT]
    else
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_HINT];

    Panel_Unit_Dismiss.Visible := SHOW_DISMISS_UNITS_BTN and fAskDismiss;
  end;

  ShowDismissBtn;

  Panel_Army.Hide;
  Panel_Army_JoinGroups.Hide;

  Label_UnitDescription.Visible := not Panel_Unit_Dismiss.Visible;

  Label_UnitDescription.Caption := gRes.Units[aUnit.UnitType].Description;
end;


procedure TKMGUIGameUnit.ShowGroupInfo(Sender: TKMUnitGroup; aAskDismiss: Boolean = False);
var
  W: TKMUnitWarrior;
begin
  Assert(gMySpectator.Selected = Sender);

  fAskDismiss := aAskDismiss;

  W := Sender.SelectedUnit;
  Panel_Unit.Show;

  Show_Common(TKMUnit(W));

  // We show what this individual is doing, not the whole group.
  // However this can be useful for debugging: Sender.GetOrderText
  Label_UnitTask.Caption      := W.GetWarriorActivityText(Sender.IsAttackingUnit);

  // While selecting target to join we could get attacked
  // Then we must cancel the dialog
  if not Sender.CanTakeOrders then
    Army_HideJoinMenu(nil); // Cannot be joining while in combat/charging

  Label_UnitDescription.Hide;
  Button_Unit_Dismiss.Visible := SHOW_DISMISS_GROUP_BTN and not fAskDismiss and not fJoiningGroups;
  Panel_Army.Visible := not fAskDismiss and not fJoiningGroups;
  Panel_Army_JoinGroups.Visible := not fAskDismiss and fJoiningGroups;
  Panel_Unit_Dismiss.Visible := SHOW_DISMISS_GROUP_BTN and fAskDismiss and not fJoiningGroups;

  ShowDismissBtn;

  // Update army controls if required
  if Panel_Army.Visible then
  begin
    ImageStack_Army.SetCount(Sender.Count, Sender.UnitsPerRow, Sender.UnitsPerRow div 2);
    Army_ActivateControls(Sender);
    Label_Army_MembersCount.Caption := IntToStr(Sender.Count);
  end;
end;


procedure TKMGUIGameUnit.SendUnitDismissCommand;
begin
  gGame.GameInputProcess.CmdUnit(gicUnitDismiss, TKMUnit(gMySpectator.Selected));
  TKMUnit(gMySpectator.Selected).DismissStarted; //Mark this unit as waiting for dismiss GIC command (so player see proper UI)
end;


procedure TKMGUIGameUnit.Unit_Dismiss(Sender: TObject);
var
  IsGroup: Boolean;
begin
  if (gMySpectator.Selected = nil)
    or not ((gMySpectator.Selected is TKMUnit) or (gMySpectator.Selected is TKMUnitGroup)) then
    Exit;

  IsGroup := gMySpectator.Selected is TKMUnitGroup;

  if Sender = Button_Unit_DismissYes then
  begin
    // DISMISS UNIT
    fAskDismiss := False;
    if IsGroup then
      TKMUnitGroup(gMySpectator.Selected).SelectedUnit.Kill(PLAYER_NONE, True, False) //Debug option
    else
      SendUnitDismissCommand;
  end
  else
  begin
    fAskDismiss := False;
    if IsGroup then
      ShowGroupInfo(TKMUnitGroup(gMySpectator.Selected), False)  // Cancel and return to selected group
    else
      ShowUnitInfo(TKMUnit(gMySpectator.Selected), False);  // Cancel and return to selected unit
  end;
end;


procedure TKMGUIGameUnit.Unit_Scroll_Click(Sender: TObject);
var

  U: TKMUnit;

  G: TKMUnitGroup;

begin

  if (gMySpectator.Selected = nil)

    or not ((gMySpectator.Selected is TKMUnit) or (gMySpectator.Selected is TKMUnitGroup)) then
    Exit;


  U := nil;


  if gMySpectator.Selected is TKMUnitGroup then
  begin
    G := TKMUnitGroup(gMySpectator.Selected);
    if G.SelectedUnit <> nil then
      U := TKMUnit(G.SelectedUnit);
  end else
  if gMySpectator.Selected is TKMUnit then
    U := TKMUnit(gMySpectator.Selected);

  if Assigned(fSetViewportEvent) then
    fSetViewportEvent(U.PositionF);
end;


procedure TKMGUIGameUnit.Dismiss_Click(Sender: TObject);
begin
  if gMySpectator.Selected is TKMUnitGroup then
    ShowGroupInfo(TKMUnitGroup(gMySpectator.Selected), True)
  else if gMySpectator.Selected is TKMUnit then
  begin
    ShowUnitInfo(TKMUnit(gMySpectator.Selected), not TKMUnit(gMySpectator.Selected).IsDismissing);
    if TKMUnit(gMySpectator.Selected).IsDismissCancelAvailable then
      gGame.GameInputProcess.CmdUnit(gicUnitDismissCancel, TKMUnit(gMySpectator.Selected));
  end;
end;


procedure TKMGUIGameUnit.Army_Issue_Order(Sender: TObject);
var
  Group: TKMUnitGroup;
begin
  if (gMySpectator.Selected = nil)
    or not (gMySpectator.Selected is TKMUnitGroup) then Exit;

  Group := TKMUnitGroup(gMySpectator.Selected);

  // if Sender = Button_Army_GoTo    then ; // This command makes no sense unless player has no right-mouse-button
  if Sender = Button_Army_Stop    then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyHalt, Group);
    gSoundPlayer.PlayWarrior(Group.UnitType, spHalt);
  end;
  // if Sender = Button_Army_Attack  then ; // This command makes no sense unless player has no right-mouse-button
  if Sender = Button_Army_RotCW   then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFormation, Group, tdCW, 0);
    gSoundPlayer.PlayWarrior(Group.UnitType, spRotRight);
  end;
  if Sender = Button_Army_Storm   then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyStorm, Group);
    gSoundPlayer.PlayWarrior(Group.UnitType, spStormAttack);
  end;
  if Sender = Button_Army_RotCCW  then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFormation, Group, tdCCW, 0);
    gSoundPlayer.PlayWarrior(Group.UnitType, spRotLeft);
  end;
  if Sender = Button_Army_ForDown then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFormation, Group, tdNone, 1);
    gSoundPlayer.PlayWarrior(Group.UnitType, spFormation);
  end;
  if Sender = Button_Army_ForUp   then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFormation, Group, tdNone, -1);
    gSoundPlayer.PlayWarrior(Group.UnitType, spFormation);
  end;
  if Sender = Button_Army_Split   then
  begin
    if GetKeyState(VK_CONTROL) < 0 then
      gGame.GameInputProcess.CmdArmy(gicArmySplitSingle, Group)
    else
      gGame.GameInputProcess.CmdArmy(gicArmySplit, Group);
    gSoundPlayer.PlayWarrior(Group.UnitType, spSplit);
  end;
  if (Sender = Button_Army_Join)
    and ((gMySpectator.Selected <> nil) and gMySpectator.IsSelectedMyObj) then // Do not allow to command ally's army
  begin
    Panel_Army.Hide;
    Panel_Army_JoinGroups.Show;
    fJoiningGroups := True;
  end;
  if Sender = Button_Army_Feed    then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFeed, Group);
    gSoundPlayer.PlayWarrior(Group.UnitType, spEat);
  end;
end;


procedure TKMGUIGameUnit.Army_ActivateControls(aGroup: TKMUnitGroup);
var AcceptOrders: Boolean;
begin
  AcceptOrders := aGroup.CanTakeOrders and OnArmyCanTakeOrder(nil);

  // Button_Army_GoTo.Enabled    := AcceptOrders;
  Button_Army_Stop.Enabled    := AcceptOrders;
  // Button_Army_Attack.Enabled  := AcceptOrders;
  Button_Army_RotCW.Enabled   := AcceptOrders;
  Button_Army_Storm.Enabled   := AcceptOrders and (aGroup.GroupType = gtMelee);
  Button_Army_RotCCW.Enabled  := AcceptOrders;
  Button_Army_ForUp.Enabled   := AcceptOrders and (aGroup.Count > 1);
  Button_Army_ForDown.Enabled := AcceptOrders and (aGroup.Count > 1);
  Button_Army_Split.Enabled   := AcceptOrders and (aGroup.Count > 1);
  Button_Army_Join.Enabled    := AcceptOrders;
  Button_Army_Feed.Enabled    := AcceptOrders;
end;


procedure TKMGUIGameUnit.Army_HideJoinMenu(Sender: TObject);
begin
  fJoiningGroups := False;
  if gRes.Cursors.Cursor in [kmcJoinYes, kmcJoinNo] then // Do not override non-joining cursors
    gRes.Cursors.Cursor := kmcDefault; // In case this is run with keyboard shortcut, mouse move won't happen
  Panel_Army_JoinGroups.Hide;
  if gMySpectator.Selected is TKMUnitWarrior then
    Panel_Army.Show;
end;


procedure TKMGUIGameUnit.KeyUp(Key: Word; Shift: TShiftState);
begin
  // Standard army shortcuts from KaM
  if Key = gResKeys[SC_ARMY_HALT].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_Stop.Click;
  if Key = gResKeys[SC_ARMY_LINK].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_Join.Click;
  if Key = gResKeys[SC_ARMY_SPLIT].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_Split.Click;

  // Additional hotkeys for all group orders
  if Key = gResKeys[SC_ARMY_FOOD].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_Feed.Click;
  if Key = gResKeys[SC_ARMY_STORM].Key then
    if Panel_Army.Visible and Button_Army_Storm.Enabled and not OnSelectingTroopDirection(nil) then Button_Army_Storm.Click;
  if Key = gResKeys[SC_ARMY_ADD_LINE].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_ForDown.Click;
  if Key = gResKeys[SC_ARMY_DEL_LINE].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_ForUp.Click;
  if Key = gResKeys[SC_ARMY_ROTATE_CW].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_RotCW.Click;
  if Key = gResKeys[SC_ARMY_ROTATE_CCW].Key then
    if Panel_Army.Visible and not OnSelectingTroopDirection(nil) then Button_Army_RotCCW.Click;
end;


function TKMGUIGameUnit.Visible: Boolean;
begin
  Result := Panel_Unit.Visible;
end;


procedure TKMGUIGameUnit.Hide;
begin
  Panel_Unit.Hide;
end;


end.


unit KM_GUIGameUnit;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Controls, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsProgressBar,
  KM_Units, KM_UnitGroup, KM_CommonTypes;

type
  TKMGUIGameUnit = class
  private
    fAnimStep: Cardinal;
    fAskDismiss: Boolean;
    fJoiningGroups: Boolean;
    fSetViewportEvent: TPointFEvent;

    procedure Unit_Kill_Click(Sender: TObject);
    procedure Unit_Dismiss(Sender: TObject);
    procedure Dismiss_Click(Sender: TObject);
    procedure Army_ActivateControls(aGroup: TKMUnitGroup);
    procedure Army_Issue_Order(Sender: TObject; Shift: TShiftState);
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
      Button_Unit_Kill: TKMButton;

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
    OnUnitDismiss: TKMEvent;
    OnSelectingTroopDirection: TBooleanFunc;
    OnArmyCanTakeOrder: TBooleanFunc;

    constructor Create(aParent: TKMPanel; aSetViewportEvent: TPointFEvent);
    property AskDismiss: Boolean read fAskDismiss write fAskDismiss;
    property JoiningGroups: Boolean read fJoiningGroups write fJoiningGroups;

    function Visible: Boolean;
    procedure Hide;
    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure ShowUnitInfo(aUnit: TKMUnit; aAskDismiss: Boolean = False);
    procedure ShowGroupInfo(Sender: TKMUnitGroup; aAskDismiss: Boolean = False);
    procedure Army_HideJoinMenu(Sender: TObject);

    procedure UpdateHotkeys;
  end;


implementation
uses
  Math,
  KM_System, 
  KM_Game, KM_GameInputProcess,
  KM_HandsCollection, KM_Hand, KM_HandSpectator, KM_HandTypes, KM_HandEntity,
  KM_InterfaceGame, KM_InterfaceTypes,
  KM_RenderUI,
  KM_Resource, KM_ResFonts, KM_ResTexts, KM_ResKeys, KM_ResSound, KM_ResUnits, KM_Pics,
  KM_UnitWarrior, KM_Utils, KM_UtilsExt, KM_Defaults, KM_Sound, KM_CommonUtils,
  KM_UnitGroupTypes,
  KM_ResTypes;

const
  UNIT_FLAG_TEX_ID = 1159;
  UNIT_FLAG_TEX_ID_FRAME = 5;


{ TKMGUIGameUnit }
constructor TKMGUIGameUnit.Create(aParent: TKMPanel; aSetViewportEvent: TPointFEvent);
begin
  inherited Create;

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
    Label_UnitTask.WordWrap := True;
    Label_UnitDescription := TKMLabel.Create(Panel_Unit,0,152,TB_WIDTH,200,'',fntGrey,taLeft); // Taken from LIB resource
    Label_UnitDescription.WordWrap := True;

    Button_Unit_Kill   := TKMButton.Create(Panel_Unit, 65, 100, 80, 30, 'DbgKill', bsGame);
    Button_Unit_Kill.OnClick := Unit_Kill_Click;
    Button_Unit_Kill.Visible := SHOW_UNIT_KILL_BTN;

    Panel_Unit_Dismiss := TKMPanel.Create(Panel_Unit, 0, 132, TB_WIDTH, 182);
    Label_Unit_Dismiss             := TKMLabel.Create(Panel_Unit_Dismiss,0,2,TB_WIDTH,20,gResTexts[TX_UNIT_TASK_DISMISS_CONFIRMATION],fntGrey,taCenter);
    Label_Unit_Dismiss.WordWrap    := True;
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
    Button_Army_GoTo.OnClickShift    := Army_Issue_Order;
    Button_Army_Stop.OnClickShift    := Army_Issue_Order;
    Button_Army_Attack.OnClickShift  := Army_Issue_Order;
    Button_Army_RotCW.OnClickShift   := Army_Issue_Order;
    Button_Army_Storm.OnClickShift   := Army_Issue_Order;
    Button_Army_RotCCW.OnClickShift  := Army_Issue_Order;
    Button_Army_ForDown.OnClickShift := Army_Issue_Order;
    Button_Army_ForUp.OnClickShift   := Army_Issue_Order;
    Button_Army_Split.OnClickShift   := Army_Issue_Order;
    Button_Army_Join.OnClickShift    := Army_Issue_Order;
    Button_Army_Feed.OnClickShift    := Army_Issue_Order;

    // Disable not working buttons
    Button_Army_GoTo.Hide;
    Button_Army_Attack.Hide;

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
  hLabelWidth: Integer;
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

  hLabelWidth := gRes.Fonts[fntOutline].GetTextSize(Label_UnitName.Caption).X;
  if hLabelWidth <= TB_WIDTH - 2*Image_PlayerFlag.Width then
    Label_UnitName.Left := 0
  else if hLabelWidth <= TB_WIDTH - Image_PlayerFlag.Width then
    Label_UnitName.Left := Image_PlayerFlag.Width
  else
    Label_UnitName.Left := Max(TB_WIDTH - hLabelWidth, 0);
end;


procedure TKMGUIGameUnit.ShowUnitInfo(aUnit: TKMUnit; aAskDismiss: Boolean = False);
var
  hasSchools: Boolean;
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
    hasSchools := gMySpectator.Hand.Stats.GetHouseQty(htSchool) > 0;

    if fAskDismiss and not aUnit.IsDismissAvailable then
      fAskDismiss := False; //Hide dismiss panel if dismiss is not available anymore

    Button_Unit_Dismiss.Enabled := not fAskDismiss and hasSchools and not aUnit.IsHungry and aUnit.IsDismissAvailable;
    Button_Unit_Dismiss.TexID := 667;

    if not hasSchools then
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_NOSCHOOLS_HINT]
    else if aUnit.IsHungry then
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_HUNGRY_HINT]   
    else if not aUnit.IsDismissAvailable then
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_NOT_AVAIL_HINT]
    else
      Button_Unit_Dismiss.Hint := gResTexts[TX_UNIT_TASK_DISMISS_HINT];

    Panel_Unit_Dismiss.Visible := False; //Do not show dismiss confirmation anymore
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
  Label_UnitTask.Caption := W.GetWarriorActivityText(Sender.IsAttackingUnit);

  // While selecting target to join we could get attacked
  // Then we must cancel the dialog
  if not Sender.CanTakePlayerOrders then
    Army_HideJoinMenu(nil); // Cannot be joining while in combat/charging

  Label_UnitDescription.Hide;
  Button_Unit_Dismiss.Visible := FEAT_DISMISS_GROUP_BTN and not fAskDismiss and not fJoiningGroups;
  Panel_Army.Visible := not fAskDismiss and not fJoiningGroups;
  Panel_Army_JoinGroups.Visible := not fAskDismiss and fJoiningGroups;
  Panel_Unit_Dismiss.Visible := FEAT_DISMISS_GROUP_BTN and fAskDismiss and not fJoiningGroups;

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
  isGroup: Boolean;
begin
  if (gMySpectator.Selected = nil)
    or not ((gMySpectator.Selected is TKMUnit) or (gMySpectator.Selected is TKMUnitGroup)) then
    Exit;

  isGroup := gMySpectator.Selected is TKMUnitGroup;

  if Sender = Button_Unit_DismissYes then
  begin
    // DISMISS UNIT
    fAskDismiss := False;
    if isGroup then
      TKMUnitGroup(gMySpectator.Selected).SelectedUnit.Kill(HAND_NONE, True, False) //Debug option
    else
      SendUnitDismissCommand;
  end
  else
  begin
    fAskDismiss := False;
    if isGroup then
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


procedure TKMGUIGameUnit.UpdateHotkeys;
var
  splitKeyStr: UnicodeString;
begin
  // Hints
  Button_Army_GoTo.Hint     := gResTexts[TX_ARMY_GOTO_HINT];
  Button_Army_Stop.Hint     := GetHintWHotkey(TX_TROOP_HALT_HINT, kfArmyHalt);
  Button_Army_Attack.Hint   := gResTexts[TX_ARMY_ATTACK_HINT];
  Button_Army_RotCW.Hint    := GetHintWHotkey(TX_ARMY_ROTATE_CW_HINT, kfArmyRotateCw);
  Button_Army_Storm.Hint    := GetHintWHotkey(TX_ARMY_STORM_HINT, kfArmyStorm);
  Button_Army_RotCCW.Hint   := GetHintWHotkey(TX_ARMY_ROTATE_CCW_HINT, kfArmyRotateCcw);
  Button_Army_ForDown.Hint  := GetHintWHotkey(TX_ARMY_LINE_ADD_HINT, kfArmyAddLine);
  Button_Army_ForUp.Hint    := GetHintWHotkey(TX_ARMY_LINE_REM_HINT, kfArmyDelLine);

  splitKeyStr := gResKeys.GetKeyNameById(kfArmySplit);

  //Check if we have new hint with separate 1 unit action hint (Ctrl + S)
  if CountOccurrences('%s', gResTexts[TX_TROOP_SPLIT_HINT]) = 2 then
    Button_Army_Split.Hint    := Format(gResTexts[TX_TROOP_SPLIT_HINT], [splitKeyStr, splitKeyStr])
  else
    Button_Army_Split.Hint     := GetHintWHotkey(TX_TROOP_SPLIT_HINT, splitKeyStr); //Old hint

  Button_Army_Join.Hint     := GetHintWHotkey(TX_TROOP_LINK_HINT, kfArmyLink);
  Button_Army_Feed.Hint     := GetHintWHotkey(TX_ARMY_FEED_HINT, kfArmyFood);
end;


procedure TKMGUIGameUnit.Dismiss_Click(Sender: TObject);
begin
  if gMySpectator.Selected is TKMUnitGroup then
    ShowGroupInfo(TKMUnitGroup(gMySpectator.Selected), True)
  else if gMySpectator.Selected is TKMUnit then
  begin
    ShowUnitInfo(TKMUnit(gMySpectator.Selected), not TKMUnit(gMySpectator.Selected).IsDismissing);
    if TKMUnit(gMySpectator.Selected).IsDismissCancelAvailable then
      gGame.GameInputProcess.CmdUnit(gicUnitDismissCancel, TKMUnit(gMySpectator.Selected))
    else
      Unit_Dismiss( Button_Unit_DismissYes ); // Call for Dismiss task immediately
  end;
end;


procedure TKMGUIGameUnit.Army_Issue_Order(Sender: TObject; Shift: TShiftState);
var
  group: TKMUnitGroup;
  rotCnt: ShortInt;
begin
  if (gMySpectator.Selected = nil)
    or not (gMySpectator.Selected is TKMUnitGroup) then Exit;

  group := TKMUnitGroup(gMySpectator.Selected);

  // if Sender = Button_Army_GoTo    then ; // This command makes no sense unless player has no right-mouse-button

  if Sender = Button_Army_Stop    then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyHalt, group);
    gSoundPlayer.PlayWarrior(group.UnitType, spHalt);
  end;

  // if Sender = Button_Army_Attack  then ; // This command makes no sense unless player has no right-mouse-button

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

    gGame.GameInputProcess.CmdArmy(gicArmyFormation, group, rotCnt, 0);

    if Sender = Button_Army_RotCW then
      gSoundPlayer.PlayWarrior(group.UnitType, spRotRight)
    else
      gSoundPlayer.PlayWarrior(group.UnitType, spRotLeft);
  end;

  if Sender = Button_Army_Storm   then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyStorm, group);
    gSoundPlayer.PlayWarrior(group.UnitType, spStormAttack);
  end;

  if Sender = Button_Army_ForDown then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFormation, group, 0, GetMultiplicator(Shift, RMB_ADD_ROWS_CNT));
    gSoundPlayer.PlayWarrior(group.UnitType, spFormation);
  end;

  if Sender = Button_Army_ForUp   then
  begin
    gGame.GameInputProcess.CmdArmy(gicArmyFormation, group, 0, -GetMultiplicator(Shift, RMB_ADD_ROWS_CNT));
    gSoundPlayer.PlayWarrior(group.UnitType, spFormation);
  end;

  if Sender = Button_Army_Split   then
  begin
    if ssCtrl in Shift then
      gGame.GameInputProcess.CmdArmy(gicArmySplitSingle, group)
    else
      gGame.GameInputProcess.CmdArmy(gicArmySplit, group);
    gSoundPlayer.PlayWarrior(group.UnitType, spSplit);
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
    gGame.GameInputProcess.CmdArmy(gicArmyFeed, group);
    gSoundPlayer.PlayWarrior(group.UnitType, spEat);
  end;
end;


procedure TKMGUIGameUnit.Army_ActivateControls(aGroup: TKMUnitGroup);
var
  acceptOrders: Boolean;
begin
  acceptOrders :=     aGroup.CanTakePlayerOrders
                  and OnArmyCanTakeOrder(nil)
                  and (gMySpectator.Selected <> nil) // just in case
                  and gMySpectator.IsSelectedMyObj;  // do not allow orders for allied units (for now)

  // Button_Army_GoTo.Enabled    := acceptOrders;
  Button_Army_Stop.Enabled    := acceptOrders;
  // Button_Army_Attack.Enabled  := acceptOrders;
  Button_Army_RotCW.Enabled   := acceptOrders;
  Button_Army_Storm.Enabled   := acceptOrders and (aGroup.GroupType = gtMelee);
  Button_Army_RotCCW.Enabled  := acceptOrders;
  Button_Army_ForUp.Enabled   := acceptOrders and (aGroup.Count > 1);
  Button_Army_ForDown.Enabled := acceptOrders and (aGroup.Count > 1);
  Button_Army_Split.Enabled   := acceptOrders and (aGroup.Count > 1);
  Button_Army_Join.Enabled    := acceptOrders;
  Button_Army_Feed.Enabled    := acceptOrders;
end;


procedure TKMGUIGameUnit.Army_HideJoinMenu(Sender: TObject);
begin
  fJoiningGroups := False;
  if gSystem.Cursor in [kmcJoinYes, kmcJoinNo] then // Do not override non-joining cursors
    gSystem.Cursor := kmcDefault; // In case this is run with keyboard shortcut, mouse move won't happen
  Panel_Army_JoinGroups.Hide;
  if gMySpectator.Selected is TKMUnitWarrior then
    Panel_Army.Show;
end;


procedure TKMGUIGameUnit.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  // Hotkey press is equal to click with LMB
  Include(Shift, ssLeft);

  // Standard army shortcuts from KaM
  if Key = gResKeys[kfArmyHalt] then
    if Panel_Army.Visible and Button_Army_Stop.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_Stop, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmyLink] then
    if Panel_Army.Visible and Button_Army_Join.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_Join, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmySplit] then
    if Panel_Army.Visible and Button_Army_Split.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_Split, Shift);
      aHandled := True;
    end;

  // Additional hotkeys for all group orders
  if Key = gResKeys[kfArmyFood] then
    if Panel_Army.Visible and Button_Army_Feed.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_Feed, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmyStorm] then
    if Panel_Army.Visible and Button_Army_Storm.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_Storm, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmyAddLine] then
    if Panel_Army.Visible and Button_Army_ForDown.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_ForDown, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmyDelLine] then
    if Panel_Army.Visible and Button_Army_ForUp.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_ForUp, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmyRotateCw] then
    if Panel_Army.Visible and Button_Army_RotCW.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_RotCW, Shift);
      aHandled := True;
    end;

  if Key = gResKeys[kfArmyRotateCcw] then
    if Panel_Army.Visible and Button_Army_RotCCW.Enabled and not OnSelectingTroopDirection(nil) then
    begin
      Army_Issue_Order(Button_Army_RotCCW, Shift);
      aHandled := True;
    end;
end;


// Debug btn to kill unit instantly
procedure TKMGUIGameUnit.Unit_Kill_Click(Sender: TObject);
begin
  if (gMySpectator.Selected = nil)
    or not ((gMySpectator.Selected is TKMUnit) or (gMySpectator.Selected is TKMUnitGroup)) then
    Exit;

  if (gMySpectator.Selected is TKMUnitGroup) then
    TKMUnitGroup(gMySpectator.Selected).SelectedUnit.Kill(HAND_NONE, True, False) //Debug option
  else
  if (gMySpectator.Selected is TKMUnit) then
    TKMUnit(gMySpectator.Selected).Kill(HAND_NONE, True, False); //Debug option
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


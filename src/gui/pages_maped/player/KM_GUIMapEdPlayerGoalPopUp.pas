unit KM_GUIMapEdPlayerGoalPopUp;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes,
  KM_Controls, KM_ControlsBase, KM_ControlsEdit, KM_ControlsSwitch,
  KM_Defaults, KM_Pics, KM_AIGoals;

type
  TKMMapEdPlayerGoal = class
  private
    fOwner: TKMHandID;
    fIndex: Integer;

    procedure Goal_Change(Sender: TObject);
    procedure Goal_Close(Sender: TObject);
    procedure Goal_Refresh(const aGoal: TKMGoal);
    function GetVisible: Boolean;
  protected
    Panel_Goal: TKMPanel;
      Image_GoalFlag: TKMImage;
      Radio_GoalType: TKMRadioGroup;
      Radio_GoalCondition: TKMRadioGroup;
      NumEdit_GoalPlayer: TKMNumericEdit;
      Label_GoalDescription: TKMLabel;
      Button_GoalOk: TKMButton;
      Button_GoalCancel: TKMButton;
  public
    fOnDone: TNotifyEvent;
    constructor Create(aParent: TKMPanel);

    property Visible: Boolean read GetVisible;
    function KeyDown(Key: Word; Shift: TShiftState): Boolean;
    procedure Show(aPlayer: TKMHandID; aIndex: Integer);
  end;


implementation
uses
  KM_HandsCollection, KM_Hand,
  KM_RenderUI,
  KM_ResFonts, KM_ResTexts, KM_ResTypes,
  KM_MapUtilsExt, KM_MapTypes;

{ TKMGUIMapEdGoal }
constructor TKMMapEdPlayerGoal.Create(aParent: TKMPanel);
const
  SIZE_X = 700;
  SIZE_Y = 300;
begin
  inherited Create;

  Panel_Goal := TKMPanel.Create(aParent, (aParent.Width - SIZE_X) div 2, (aParent.Height - SIZE_Y) div 2, SIZE_X, SIZE_Y);
  Panel_Goal.AnchorsCenter;
  Panel_Goal.Hide;

  TKMBevel.Create(Panel_Goal, -2000,  -2000, 5000, 5000);
  with TKMImage.Create(Panel_Goal, -20, -50, SIZE_X+40, SIZE_Y+60, 15, rxGuiMain) do
    ImageStretch;
  TKMBevel.Create(Panel_Goal,   0,  0, SIZE_X, SIZE_Y);
  TKMLabel.Create(Panel_Goal, SIZE_X div 2, 10, gResTexts[TX_MAPED_GOALS_TITLE], fntOutline, taCenter);

  Image_GoalFlag := TKMImage.Create(Panel_Goal, 10, 10, 0, 0, 30, rxGuiMain);

  TKMLabel.Create(Panel_Goal, 20, 40, 160, 0, gResTexts[TX_MAPED_GOALS_TYPE], fntMetal, taLeft);
  Radio_GoalType := TKMRadioGroup.Create(Panel_Goal, 20, 60, 160, 40, fntMetal);
  Radio_GoalType.Add(gResTexts[TX_MAPED_GOALS_TYPE_NONE], False, False);
  Radio_GoalType.Add(gResTexts[TX_MAPED_GOALS_TYPE_VICTORY]);
  Radio_GoalType.Add(gResTexts[TX_MAPED_GOALS_TYPE_SURVIVE]);
  Radio_GoalType.OnChange := Goal_Change;

  TKMLabel.Create(Panel_Goal, 200, 40, 280, 0, gResTexts[TX_MAPED_GOALS_CONDITION], fntMetal, taLeft);
  Radio_GoalCondition := TKMRadioGroup.Create(Panel_Goal, 200, 60, 280, 100, fntMetal);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_NONE], False, False);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_TUTORIAL], False, False);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_TIME], False, False);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_BUILDS]);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_TROOPS]);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_UNKNOWN], False, False);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_ASSETS], False);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_SERFS], False);
  Radio_GoalCondition.Add(gResTexts[TX_MAPED_GOALS_CONDITION_ECONOMY], False);
  Radio_GoalCondition.OnChange := Goal_Change;

  TKMLabel.Create(Panel_Goal, 480, 40, gResTexts[TX_MAPED_GOALS_PLAYER], fntMetal, taLeft);
  NumEdit_GoalPlayer := TKMNumericEdit.Create(Panel_Goal, 480, 60, 1, MAX_HANDS);
  NumEdit_GoalPlayer.OnChange := Goal_Change;

  Label_GoalDescription := TKMLabel.Create(Panel_Goal, 20, 180, SIZE_X - 40, 20, '', fntMetal, taLeft);
  Label_GoalDescription.WordWrap := True;

  Button_GoalOk := TKMButton.Create(Panel_Goal, SIZE_X-20-320-10, SIZE_Y - 50, 160, 30, gResTexts[TX_MAPED_OK], bsMenu);
  Button_GoalOk.OnClick := Goal_Close;
  Button_GoalCancel := TKMButton.Create(Panel_Goal, SIZE_X-20-160, SIZE_Y - 50, 160, 30, gResTexts[TX_MAPED_CANCEL], bsMenu);
  Button_GoalCancel.OnClick := Goal_Close;
end;


procedure TKMMapEdPlayerGoal.Goal_Change(Sender: TObject);
var
  gc: TKMGoalCondition;
begin
  gc := TKMGoalCondition(Radio_GoalCondition.ItemIndex);
  //Settings get saved on close, now we just toggle fields
  //because certain combinations can't coexist
  NumEdit_GoalPlayer.Enabled := gc <> gcTime;

  if NumEdit_GoalPlayer.Enabled then
    Label_GoalDescription.Caption := GetGoalDescription(gMySpectator.HandID, NumEdit_GoalPlayer.Value - 1,
                                                        TKMGoalType(Radio_GoalType.ItemIndex), gc,
                                                        gMySpectator.Hand.FlagTextColor,
                                                        gHands[NumEdit_GoalPlayer.Value - 1].FlagTextColor,
                                                        icRoyalYellow, icLightOrange)
  else
    Label_GoalDescription.Caption := '';
end;


function TKMMapEdPlayerGoal.GetVisible: Boolean;
begin
  Result := Panel_Goal.Visible;
end;


procedure TKMMapEdPlayerGoal.Goal_Close(Sender: TObject);
var
  G: TKMGoal;
begin
  if Sender = Button_GoalOk then
  begin
    //Copy Goal info from controls to Goals
    FillChar(G, SizeOf(G), #0); //Make sure unused fields like Message are zero, not random data
    G.GoalType := TKMGoalType(Radio_GoalType.ItemIndex);
    G.GoalCondition := TKMGoalCondition(Radio_GoalCondition.ItemIndex);
    if G.GoalType = gltSurvive then
      G.GoalStatus := gsTrue
    else
      G.GoalStatus := gsFalse;
    G.HandIndex := NumEdit_GoalPlayer.Value - 1;

    gHands[fOwner].AI.Goals[fIndex] := G;
  end;

  Panel_Goal.Hide;
  fOnDone(Self);
end;


procedure TKMMapEdPlayerGoal.Goal_Refresh(const aGoal: TKMGoal);
begin
  Image_GoalFlag.FlagColor := gHands[fOwner].FlagColor;

  Radio_GoalType.ItemIndex := Byte(aGoal.GoalType);
  Radio_GoalCondition.ItemIndex := Byte(aGoal.GoalCondition);
  NumEdit_GoalPlayer.Value := aGoal.HandIndex + 1;

  //Certain values disable certain controls
  Goal_Change(nil);
end;


function TKMMapEdPlayerGoal.KeyDown(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
  case Key of
    VK_ESCAPE:  if Button_GoalCancel.IsClickable then
                begin
                  Goal_Close(Button_GoalCancel);
                  Result := True;
                end;
    VK_RETURN:  if Button_GoalOk.IsClickable then
                begin
                  Goal_Close(Button_GoalOk);
                  Result := True;
                end;
  end;
end;


procedure TKMMapEdPlayerGoal.Show(aPlayer: TKMHandID; aIndex: Integer);
begin
  fOwner := aPlayer;
  fIndex := aIndex;

  Goal_Refresh(gHands[fOwner].AI.Goals[fIndex]);
  Panel_Goal.Show;
end;


end.

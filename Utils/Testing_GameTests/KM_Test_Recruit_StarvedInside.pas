unit KM_Test_Recruit_StarvedInside;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Issue #300, without a script touching anything. A garrison with no Inn to go to keeps cycling
  // out and back in on TKMTaskGoOutShowHungry while its condition runs down, and TKMUnit.UpdateState
  // kills a unit outright once the condition reaches zero - wherever it happens to be standing.
  //
  // A recruit who dies during the inside half of that cycle is never taken off the barracks list,
  // because the only place that removes him is TKMUnitActionGoInOut.WalkOut. RecruitsCount then
  // counts a recruit who is not there, which is what EquipWarrior breaks on.
  TKMTest_RecruitStarvedInside = class(TKMTest)
  private
    fHasDied: Boolean;
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HouseBarracks,
  KM_ResTypes;


{ TKMTest_RecruitStarvedInside }
procedure TKMTest_RecruitStarvedInside.SetUp;
begin
  inherited;

  fDuration := 700;

  gGameApp.NewGameEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  for var I := 1 to 4 do
    barracks.CreateRecruitInside(False);
  barracks.WareAddToIn(wtAxe, 10);

  // No Inn anywhere, so there is nothing to eat and they only walk out to show it.
  // Condition drops by one per UNIT_CONDITION_PACE ticks, so this runs out well within fDuration
  for var I := 0 to gHands[0].Units.Count - 1 do
    gHands[0].Units[I].Condition := 40;
end;


function TKMTest_RecruitStarvedInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  var barracks := TKMHouseBarracks(gHands[0].Houses[0]);

  var unitsInside := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
    if (gHands[0].Units[I].UnitType = utRecruit)
    and not gHands[0].Units[I].IsDeadOrDying
    and (gHands[0].Units[I].InHouse = barracks) then
      Inc(unitsInside);

  if gHands[0].Stats.GetUnitQty(utRecruit) < 4 then
    fHasDied := True;

  AssertTrue(barracks.RecruitsCount <= unitsInside,
             Format('The barracks lists %d recruits but only %d are alive inside it, at tick %d',
                    [barracks.RecruitsCount, unitsInside, aTick]));
end;


procedure TKMTest_RecruitStarvedInside.CheckResult;
begin
  AssertTrue(fHasDied, 'The recruits were expected to starve without an Inn');
end;


class function TKMTest_RecruitStarvedInside.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit, tcHunger];
end;


class function TKMTest_RecruitStarvedInside.TestDescription: string;
begin
  Result := 'A recruit who starves inside the barracks should not stay on its recruits list.';
end;


initialization
  RegisterTest(TKMTest_RecruitStarvedInside);
end.

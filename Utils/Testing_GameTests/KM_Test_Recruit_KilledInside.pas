unit KM_Test_Recruit_KilledInside;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Issue #300: EquipWarrior takes a recruit off the barracks list and kills him with KillInHouse,
  // which asserts he is inside a house.
  //
  // The list only ever loses an entry in TKMUnitActionGoInOut.WalkOut, so a recruit who dies
  // without walking out - killed by a script, or starved - stays on it. Worse, RecruitsAdd stores
  // a plain pointer and takes no counted reference, so nothing keeps the unit alive on the list's
  // behalf: once it is dead and its PointerCount reaches zero the collection frees it, and the
  // barracks is left pointing at nothing while RecruitsCount still says there is a recruit.
  //
  // Demolish already carries a patch for this, and says so: "Otherwise it can cause crashes while
  // saving under the right conditions when a recruit is then killed". Demolishing is not the only
  // way for a listed recruit to die.
  TKMTest_RecruitKilledInside = class(TKMTest)
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
  KM_GameApp, KM_HandsCollection, KM_HandTypes, KM_HouseBarracks,
  KM_ResTypes;


{ TKMTest_RecruitKilledInside }
procedure TKMTest_RecruitKilledInside.SetUp;
begin
  inherited;

  fDuration := 120;

  gGameApp.NewGameEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  barracks.CreateRecruitInside(False);
  barracks.WareAddToIn(wtAxe, 10);
end;


function TKMTest_RecruitKilledInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick = 10 then
    // Kill recruit where he stands, the way a mission script would
    gHands[0].Units[0].Kill(HAND_NONE, False, False)
  else
  if aTick > 10 then
  begin
    var barracks := TKMHouseBarracks(gHands[0].Houses[0]);

    var unitsInside := 0;
    for var I := 0 to gHands[0].Units.Count - 1 do
      if not gHands[0].Units[I].IsDeadOrDying
      and (gHands[0].Units[I].InHouse = barracks) then
        Inc(unitsInside);

    AssertTrue(barracks.RecruitsCount <= unitsInside,
      Format('The barracks lists %d recruits but only %d are alive inside it, at tick %d', [barracks.RecruitsCount, unitsInside, aTick]));
  end;
end;


procedure TKMTest_RecruitKilledInside.CheckResult;
begin
  AssertEquals(0, gHands[0].Stats.GetUnitQty(utRecruit), 'The recruit was expected to be dead by now');
end;


class function TKMTest_RecruitKilledInside.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit];
end;


class function TKMTest_RecruitKilledInside.TestDescription: string;
begin
  Result := 'A recruit killed inside the barracks should not stay on its recruits list.';
end;


initialization
  RegisterTest(TKMTest_RecruitKilledInside);
end.

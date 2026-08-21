unit KM_Test_Recruit_EquipNotInside;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Issue #300: EquipWarrior took the first recruit off the barracks list and killed him with
  // KillInHouse, which asserts the unit is inside a house. The crash report shows the list can
  // name a recruit who is not, so equipping has to pick one who is - or refuse.
  //
  // The route that leaves such an entry on the list is not known, so this test puts the barracks
  // into that state directly rather than playing towards it. It covers the assertion, not the
  // path to it.
  TKMTest_RecruitEquipNotInside = class(TKMTest)
  private
    fHasTriedToEquip: Boolean;
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
  KM_Defaults,
  KM_GameApp, KM_HandsCollection, KM_HouseBarracks,
  KM_ResTypes;


{ TKMTest_RecruitEquipNotInside }
procedure TKMTest_RecruitEquipNotInside.SetUp;
begin
  inherited;

  gGameApp.NewGameEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  barracks.CreateRecruitInside(False);
  barracks.WareAddToIn(wtAxe, 1); // All a militia costs, so wares are never what stops the equip
end;


function TKMTest_RecruitEquipNotInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < 10 then Exit; // Let the recruit settle in first

  // The recruit stays on the barracks list, but is no longer inside it - the state the crash
  // report was taken in
  gHands[0].Units[0].InHouse := nil;

  var barracks := TKMHouseBarracks(gHands[0].FindHouse(htBarracks));

  // Mark the attempt before making it. CheckResult runs from a finally, so if Equip raises, an
  // assert failing here would replace that exception and hide what actually went wrong
  fHasTriedToEquip := True;

  AssertEquals(0, barracks.Equip(utMilitia, 1), 'A recruit who is not inside the barracks can not be equipped');

  Result := False;
end;


procedure TKMTest_RecruitEquipNotInside.CheckResult;
begin
  AssertTrue(fHasTriedToEquip, 'The equip was expected to be attempted');
  AssertEquals(0, gHands[0].Stats.GetUnitQty(utMilitia), 'No militia should have been made');
end;


class function TKMTest_RecruitEquipNotInside.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit];
end;


class function TKMTest_RecruitEquipNotInside.TestDescription: string;
begin
  Result := 'The barracks should not equip a recruit who is not inside it.';
end;


initialization
  RegisterTest(TKMTest_RecruitEquipNotInside);
end.

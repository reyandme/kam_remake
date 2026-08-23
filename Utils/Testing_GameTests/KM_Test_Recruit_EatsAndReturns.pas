unit KM_Test_Recruit_EatsAndReturns;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Checks that a hungry recruit will leave barracks to go to eat and will come back. When he is back he can be equipped to be Militia
  // and can never be equipped
  TKMTest_RecruitEatsAndReturns = class(TKMTest)
  private
    fRecruitWentToInn: Boolean;
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


{ TKMTest_RecruitEatsAndReturns }
procedure TKMTest_RecruitEatsAndReturns.SetUp;
begin
  inherited;

  fDuration := 2 * 600;

  gGameApp.NewGameEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  barracks.CreateRecruitInside(False);
  barracks.WareAddToIn(wtAxe, 1);

  gHands[0].AddHouse(htInn, 10, 16, False).WareAddToIn(wtBread, 5);

  gHands[0].Units[0].Condition := UNIT_MIN_CONDITION - 1;
end;


function TKMTest_RecruitEatsAndReturns.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  var barracks := TKMHouseBarracks(gHands[0].Houses[0]);

  if barracks.RecruitsCount = 0 then
    fRecruitWentToInn := True;

  if fRecruitWentToInn and (barracks.RecruitsCount = 1) then // He is home again
  begin
    var equipCount := barracks.Equip(utMilitia, 1);
    AssertEquals(1, equipCount, 'A recruit back from the Inn should still be equippable');

    // Test can end now
    Result := False;
  end;
end;


procedure TKMTest_RecruitEatsAndReturns.CheckResult;
begin
  AssertTrue(fRecruitWentToInn, 'The recruit was expected to get hungry and leave for the Inn');
  AssertEquals(1, gHands[0].Stats.GetUnitQty(utMilitia), 'The recruit was expected to come back and be equipped');
end;


class function TKMTest_RecruitEatsAndReturns.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcInn, tcRecruit, tcHunger];
end;


class function TKMTest_RecruitEatsAndReturns.TestDescription: string;
begin
  Result := 'A recruit who left the barracks to eat at the Inn should be equippable again once he is back.';
end;


initialization
  RegisterTest(TKMTest_RecruitEatsAndReturns);
end.

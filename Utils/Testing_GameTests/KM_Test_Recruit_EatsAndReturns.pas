unit KM_Test_Recruit_EatsAndReturns;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // A hungry recruit walks out of the barracks to eat at the Inn and comes back once he is full.
  // The barracks has to take him back, otherwise it is left holding a recruit who sits inside it
  // and can never be equipped
  TKMTest_RecruitEatsAndReturns = class(TKMTest)
  private
    fHasLeftForInn: Boolean;
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
  KM_GameApp, KM_HandsCollection, KM_HouseBarracks, KM_HouseInn,
  KM_ResTypes;


{ TKMTest_RecruitEatsAndReturns }
procedure TKMTest_RecruitEatsAndReturns.SetUp;
begin
  inherited;

  fDuration := 20 * 60;

  gGameApp.NewGameEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  barracks.CreateRecruitInside(False);
  barracks.WareAddToIn(wtAxe, 1); // All a militia costs

  TKMHouseInn(gHands[0].AddHouse(htInn, 10, 16, False)).WareAddToIn(wtBread, 5);

  // The recruit is the only unit around. Starve him, so that he goes looking for the Inn
  gHands[0].Units[0].Condition := UNIT_MIN_CONDITION - 1;
end;


function TKMTest_RecruitEatsAndReturns.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  var barracks := TKMHouseBarracks(gHands[0].Houses[0]);

  // While he is away the barracks lists nobody
  fHasLeftForInn := fHasLeftForInn or (barracks.RecruitsCount = 0);

  if fHasLeftForInn and (barracks.RecruitsCount = 1) then // He is home again
  begin
    AssertEquals(1, barracks.Equip(utMilitia, 1), 'A recruit back from the Inn should still be equippable');
    Result := False;
  end;
end;


procedure TKMTest_RecruitEatsAndReturns.CheckResult;
begin
  AssertTrue(fHasLeftForInn, 'The recruit was expected to get hungry and leave for the Inn');
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

unit KM_Test_Recruit_EquipWhileEating;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Check that Militia cant be equipped when a Recruit is out of the Barracks to go to eat
  TKMTest_RecruitEquipWhileEating = class(TKMTest)
  private
    fHasTriedToEquip: Boolean;
  protected
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
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


{ TKMTest_RecruitEquipWhileEating }
procedure TKMTest_RecruitEquipWhileEating.SetUp;
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


procedure TKMTest_RecruitEquipWhileEating.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  // Visible means he has came out of the Barracks
  if gHands[0].Units[0].Visible then
  begin
    var barracks := TKMHouseBarracks(gHands[0].Houses[0]);
    var equipCount := barracks.Equip(utMilitia, 1);
    AssertEquals(0, equipCount, 'A recruit who is out of the barracks can not be equipped');

    fHasTriedToEquip := True;
    aKeepGoing := False;
  end;
end;


procedure TKMTest_RecruitEquipWhileEating.CheckResult;
begin
  AssertTrue(fHasTriedToEquip, 'The recruit was expected to get hungry and leave the barracks');
end;


class function TKMTest_RecruitEquipWhileEating.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcInn, tcRecruit, tcHunger];
end;


class function TKMTest_RecruitEquipWhileEating.TestDescription: string;
begin
  Result := 'The barracks should not equip a warrior while its only recruit is away eating.';
end;


initialization
  RegisterTest(TKMTest_RecruitEquipWhileEating);
end.

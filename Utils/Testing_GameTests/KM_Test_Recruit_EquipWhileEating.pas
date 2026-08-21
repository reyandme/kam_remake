unit KM_Test_Recruit_EquipWhileEating;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // While the recruit is out of the barracks on his way to the Inn there is nobody inside to turn
  // into a warrior. The barracks has to say so, rather than reach for the recruit who is away
  TKMTest_RecruitEquipWhileEating = class(TKMTest)
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
  KM_GameApp, KM_HandsCollection, KM_HouseBarracks, KM_HouseInn,
  KM_ResTypes;

const
  BREAD_COUNT = 5;


{ TKMTest_RecruitEquipWhileEating }
procedure TKMTest_RecruitEquipWhileEating.SetUp;
begin
  inherited;

  gGameApp.NewGameEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  barracks.CreateRecruitInside(False);
  barracks.WareAddToIn(wtAxe, 1); // All a militia costs, so wares are never what stops the equip

  TKMHouseInn(gHands[0].AddHouse(htInn, 10, 16, False)).WareAddToIn(wtBread, BREAD_COUNT);

  // The recruit is the only unit around. Starve him, so that he goes looking for the Inn
  gHands[0].Units[0].Condition := UNIT_MIN_CONDITION - 1;
end;


function TKMTest_RecruitEquipWhileEating.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  // A unit inside a house is not visible, so being visible means he is through the doorway
  if not gHands[0].Units[0].Visible then Exit;

  var barracks := TKMHouseBarracks(gHands[0].FindHouse(htBarracks));
  AssertEquals(0, barracks.Equip(utMilitia, 1), 'A recruit who is out of the barracks can not be equipped');

  fHasTriedToEquip := True;
  Result := False;
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

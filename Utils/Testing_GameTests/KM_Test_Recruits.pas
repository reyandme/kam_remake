unit KM_Test_Recruits;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_HouseBarracks, KM_Units;


type
  // Recruit is equipped into a militia. The barracks must have owned a counted reference to him
  // while he was listed (see TKMHandEntityPointer.GetPointer) and must release it on unregister
  TKMTest_Recruit_ListOwnsPointer = class(TKMTest)
  private
    fBarracks: TKMHouseBarracks;
    fRecruit: TKMUnit;
    fPointerCnt: Cardinal;
    fEquippedCnt: Integer;
    fEquipTick: Cardinal;
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
  KM_GameApp, KM_HandsCollection,
  KM_ResTypes;

const
  SETTLE_TICKS = 10; // Ticks to let the scene settle down before we touch anything


function FindRecruit: TKMUnit;
begin
  Result := nil;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and not U.IsDead and (U.UnitType = utRecruit) then
      Exit(U);
  end;
end;


// Including the dead ones, which are not freed yet
function RecruitObjectsCnt: Integer;
begin
  Result := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and (U.UnitType = utRecruit) then
      Inc(Result);
  end;
end;


{ TKMTest_Recruit_ListOwnsPointer }
procedure TKMTest_Recruit_ListOwnsPointer.SetUp;
begin
  inherited;

  fDuration := 600;

  gGameApp.NewEmptyMap(32, 32);

  fBarracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  fBarracks.CreateRecruitInside(False);
  fRecruit := FindRecruit;
end;


function TKMTest_Recruit_ListOwnsPointer.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    fPointerCnt := fRecruit.PointerCount;

    // Equip a warrior out of him: that kills the recruit and unregisters him from the barracks
    for var W := WARFARE_MIN to WARFARE_MAX do
      fBarracks.WareAddToIn(W, 1);

    fEquippedCnt := fBarracks.Equip(utMilitia, 1);
    fRecruit := nil; // Equipped recruit is freed as soon as nobody references him

    fEquipTick := aTick;
    Exit;
  end;

  // The equipped recruit is not referenced by anyone anymore, so he must be freed by now.
  // If the reference taken by the barracks list is never released, he would stay forever
  Result := aTick < fEquipTick + 100;
end;


procedure TKMTest_Recruit_ListOwnsPointer.CheckResult;
begin
  AssertTrue(fPointerCnt > 0, 'Recruit inside the barracks is referenced by nobody, ' +
                              'so the barracks recruits list is a raw pointer that can dangle');
  AssertEquals(1, fEquippedCnt, 'Test scene is broken: a militia was expected to be equipped');
  AssertEquals(0, fBarracks.RecruitsCount, 'Equipped recruit should be unregistered from the barracks');
  AssertEquals(0, RecruitObjectsCnt, 'Equipped recruit object should be freed, otherwise his pointer was never released');
end;


class function TKMTest_Recruit_ListOwnsPointer.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit, tcMilitia];
end;


class function TKMTest_Recruit_ListOwnsPointer.TestDescription: string;
begin
  Result := 'Barracks recruits list should own a counted reference to every recruit it lists, and release it on unregister.';
end;


initialization
  RegisterTest(TKMTest_Recruit_ListOwnsPointer);
end.

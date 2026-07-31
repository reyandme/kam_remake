unit KM_Test_Recruits;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Houses, KM_HouseBarracks, KM_Units;


type
  // Recruit is dismissed while sitting inside the barracks: he steps out, walks to the school
  // and is killed there
  TKMTest_Recruit_Dismiss = class(TKMTest)
  private
    fBarracks: TKMHouseBarracks;
    fRecruit: TKMUnit;
    fListedBefore: Integer;
    fDismissStarted: Boolean;
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

  // Barracks with the 'do not accept recruits' flag clears the recruit Home while he is still inside
  // it, so that Home and InHouse diverge - the only divergence the game code admits, see the comment
  // in TKMUnitActionGoInOut.WalkOut. Then the Inn is destroyed before the recruit steps out,
  // and he is left inside with no Home at all
  TKMTest_Recruit_HomeLostWhileInside = class(TKMTest)
  private
    fBarracks: TKMHouseBarracks;
    fRecruit: TKMUnit;
    fInn: TKMHouse;
    fStage: Byte;
    fStageTick: Cardinal;
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

  // Hungry recruit with no Inn around goes out of the barracks to show he is hungry and comes back.
  // Registration in the list is keyed on Home, unregistration on InHouse - check they stay in sync
  TKMTest_Recruit_HungryCycle = class(TKMTest)
  private
    fBarracks: TKMHouseBarracks;
    fRecruit: TKMUnit;
    fStage: Byte;
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

  // Recruit is killed while sitting inside the barracks
  TKMTest_Recruit_KilledInside = class(TKMTest)
  private
    fBarracks: TKMHouseBarracks;
    fRecruit: TKMUnit;
    fWasInside: Boolean;
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

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

  // Barracks with recruits inside is demolished, recruits should be placed outside and survive
  TKMTest_Recruit_BarracksDemolished = class(TKMTest)
  private
    fBarracks: TKMHouseBarracks;
    fListedBefore: Integer;
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
  KM_GameApp, KM_HandsCollection, KM_HandTypes,
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


function AliveRecruitsCnt: Integer;
begin
  Result := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and not U.IsDead and (U.UnitType = utRecruit) then
      Inc(Result);
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


// Recruits standing on the map rather than sitting in a house
function RecruitsOutsideCnt: Integer;
begin
  Result := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and not U.IsDead and (U.UnitType = utRecruit) and (U.InHouse = nil) then
      Inc(Result);
  end;
end;


{ TKMTest_Recruit_Dismiss }
procedure TKMTest_Recruit_Dismiss.SetUp;
begin
  inherited;

  fDuration := 2400;

  gGameApp.NewEmptyMap(32, 32);

  fBarracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  fBarracks.CreateRecruitInside(False);
  fRecruit := FindRecruit;

  gHands[0].AddHouse(htSchool, 8, 8, False);
end;


function TKMTest_Recruit_Dismiss.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    // Precondition: he sits inside the barracks and is listed there
    if fRecruit.InHouse = fBarracks then
      fListedBefore := fBarracks.RecruitsCount;

    fRecruit.Dismiss;
    fDismissStarted := fRecruit.IsDismissing;
    fRecruit := nil; // He is going to die on the way, do not keep a raw pointer to him

    Exit;
  end;

  // Keep running while the dismissed recruit is still around
  Result := AliveRecruitsCnt > 0;
end;


procedure TKMTest_Recruit_Dismiss.CheckResult;
begin
  AssertEquals(1, fListedBefore, 'Test scene is broken: there should be exactly 1 recruit inside the barracks');
  AssertTrue(fDismissStarted, 'Recruit inside the barracks should have started dismissing');
  AssertEquals(0, AliveRecruitsCnt, 'Recruit should have been dismissed');
  AssertEquals(0, fBarracks.RecruitsCount, 'Dismissed recruit should be unregistered from the barracks');
end;


class function TKMTest_Recruit_Dismiss.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit, tcSchool];
end;


class function TKMTest_Recruit_Dismiss.TestDescription: string;
begin
  Result := 'Dismissing a recruit who sits inside the barracks must unregister him from the barracks once he is gone.';
end;


{ TKMTest_Recruit_HomeLostWhileInside }
procedure TKMTest_Recruit_HomeLostWhileInside.SetUp;
begin
  inherited;

  fDuration := 1200;

  gGameApp.NewEmptyMap(32, 32);

  fBarracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  fBarracks.CreateRecruitInside(False);
  fRecruit := FindRecruit;

  fInn := gHands[0].AddHouse(htInn, 8, 20, False);
  fInn.WareAddToIn(wtBread, 3); // Otherwise the Inn is not worth going to
end;


function TKMTest_Recruit_HomeLostWhileInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  case fStage of
    0:  if aTick >= SETTLE_TICKS then
        begin
          fRecruit.Condition := UNIT_MIN_CONDITION - 1; // He will take the Inn and a TKMTaskGoEat
          fStage := 1;
        end;
    1:  if fRecruit.Task <> nil then // Got the eating task, but it did not start walking him out yet
        begin
          // Barracks stops accepting recruits: that clears his Home, while he stays inside and listed
          fBarracks.ToggleAcceptRecruits;
          // And the Inn is gone, so the eating task ends before he steps out of the barracks
          fInn.Demolish(fInn.Owner, True);
          fInn := nil; // Demolished house is freed as soon as nobody references it

          fStage := 2;
          fStageTick := aTick;
        end;
    2:  if aTick > fStageTick + 200 then // Let him try to do whatever he wants with no Home
        begin
          fStage := 3;
          Exit(False);
        end;
  end;
end;


procedure TKMTest_Recruit_HomeLostWhileInside.CheckResult;
begin
  AssertTrue(fStage = 3, 'Recruit was expected to get an eating task and then lose both the Inn and his Home');
  AssertTrue(not fRecruit.IsDead, 'Recruit should be alive');
  AssertTrue(fRecruit.InHouse = fBarracks, 'Recruit should still be inside the barracks');
  AssertEquals(1, fBarracks.RecruitsCount, 'Barracks should list exactly 1 recruit');
end;


class function TKMTest_Recruit_HomeLostWhileInside.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit, tcInn, tcHunger];
end;


class function TKMTest_Recruit_HomeLostWhileInside.TestDescription: string;
begin
  Result := 'Recruit who lost his Home while sitting inside the barracks should stay registered there exactly once.';
end;


{ TKMTest_Recruit_HungryCycle }
procedure TKMTest_Recruit_HungryCycle.SetUp;
begin
  inherited;

  fDuration := 1200;

  gGameApp.NewEmptyMap(32, 32);

  // No Inn on the map, hence the recruit will go out of the barracks just to show that he is hungry
  fBarracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  fBarracks.CreateRecruitInside(False);
  fRecruit := FindRecruit;
end;


function TKMTest_Recruit_HungryCycle.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  case fStage of
    0:  if aTick >= SETTLE_TICKS then
        begin
          fRecruit.Condition := UNIT_MIN_CONDITION - 1;
          fStage := 1;
        end;
    1:  if fRecruit.Visible then // Stepped out of the barracks
          fStage := 2;
    2:  if not fRecruit.Visible then
        begin
          // Got back inside. Stop right here: he is hungry still, so he would go out again,
          // and then the barracks list is allowed to be empty
          fStage := 3;
          Exit(False);
        end;
  end;
end;


procedure TKMTest_Recruit_HungryCycle.CheckResult;
begin
  AssertTrue(fStage = 3, 'Recruit should have gone out to show that he is hungry and got back inside');
  AssertTrue(not fRecruit.IsDead, 'Recruit should be alive');
  AssertTrue(fRecruit.InHouse = fBarracks, 'Recruit should be back inside the barracks');
  AssertEquals(1, fBarracks.RecruitsCount, 'Barracks should list exactly 1 recruit');
end;


class function TKMTest_Recruit_HungryCycle.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit, tcHunger];
end;


class function TKMTest_Recruit_HungryCycle.TestDescription: string;
begin
  Result := 'Recruit going out of the barracks to show that he is hungry and back should be registered there exactly once.';
end;


{ TKMTest_Recruit_KilledInside }
procedure TKMTest_Recruit_KilledInside.SetUp;
begin
  inherited;

  fDuration := 1200;

  gGameApp.NewEmptyMap(32, 32);

  fBarracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  fBarracks.CreateRecruitInside(False);
  fRecruit := FindRecruit;
end;


function TKMTest_Recruit_KilledInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    fWasInside := fRecruit.InHouse = fBarracks;

    fRecruit.Kill(HAND_NONE, True, False);
    fRecruit := nil; // Killed unit is freed as soon as nobody references him

    Exit;
  end;

  // Keep running while the dying recruit is still around
  Result := AliveRecruitsCnt > 0;
end;


procedure TKMTest_Recruit_KilledInside.CheckResult;
begin
  AssertTrue(fWasInside, 'Test scene is broken: there should be a recruit inside the barracks');
  AssertEquals(0, AliveRecruitsCnt, 'Recruit should be dead');
  AssertEquals(0, fBarracks.RecruitsCount, 'Killed recruit should be unregistered from the barracks');
end;


class function TKMTest_Recruit_KilledInside.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit];
end;


class function TKMTest_Recruit_KilledInside.TestDescription: string;
begin
  Result := 'Killing a recruit inside the barracks should unregister him from the barracks recruits list.';
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


{ TKMTest_Recruit_BarracksDemolished }
procedure TKMTest_Recruit_BarracksDemolished.SetUp;
begin
  inherited;

  fDuration := 600;

  gGameApp.NewEmptyMap(32, 32);

  fBarracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, 16, 16, False));
  fBarracks.CreateRecruitInside(False);
  fBarracks.CreateRecruitInside(False);
end;


function TKMTest_Recruit_BarracksDemolished.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    fListedBefore := fBarracks.RecruitsCount;

    fBarracks.Demolish(fBarracks.Owner, True);
    fBarracks := nil; // Demolished house is freed as soon as nobody references it

    Exit;
  end;

  // Give the recruits some time to be placed outside of the demolished barracks
  Result := aTick < SETTLE_TICKS + 100;
end;


procedure TKMTest_Recruit_BarracksDemolished.CheckResult;
begin
  AssertEquals(2, fListedBefore, 'Test scene is broken: there should be 2 recruits inside the barracks');
  AssertEquals(2, AliveRecruitsCnt, 'Both recruits should survive the demolition');
  AssertEquals(2, RecruitsOutsideCnt, 'Both recruits should be placed outside of the demolished barracks');
end;


class function TKMTest_Recruit_BarracksDemolished.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit];
end;


class function TKMTest_Recruit_BarracksDemolished.TestDescription: string;
begin
  Result := 'Recruits of a demolished barracks should be placed outside of it and survive.';
end;


initialization
  RegisterTest(TKMTest_Recruit_Dismiss);
  RegisterTest(TKMTest_Recruit_HomeLostWhileInside);
  RegisterTest(TKMTest_Recruit_HungryCycle);
  RegisterTest(TKMTest_Recruit_KilledInside);
  RegisterTest(TKMTest_Recruit_ListOwnsPointer);
  RegisterTest(TKMTest_Recruit_BarracksDemolished);
end.

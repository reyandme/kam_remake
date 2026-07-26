unit KM_Test_Recruits;
{$I KaM_Remake.inc}
interface
uses
  KM_Test;


type
  // Barracks keep their own list of the recruits sitting inside (TKMHouseBarracks.fRecruitsList).
  // EquipWarrior takes fRecruitsList[0] for granted and calls KillInHouse on it, which asserts
  // that the unit is inside some house. These tests verify that the list stays in sync with reality,
  // since a stale entry means either a killed (and freed) unit or a unit that has left the barracks.
  //
  // Note: no game units are used in the interface section on purpose (as in every other test unit),
  // that keeps the units compilation order intact. Hence barracks is kept by UID, not by pointer,
  // which is safer anyway - a destroyed house could be freed at any moment
  TKMTest_RecruitsBase = class abstract(TKMTest)
  protected
    fBarracksUID: Integer;
    fError: string;

    procedure SetUpScene(aRecruitsCnt: Integer; aAddSchool: Boolean);

    // Errors found while ticking are recorded rather than raised: the framework calls CheckResult
    // from a finally block, so it is safer to report them from CheckResult itself
    procedure RecordError(const aError: string);
    procedure CheckRecordedError;

    // Every listed recruit must be a living recruit inside that very barracks.
    // The opposite is not always true: recruit is unregistered as soon as he starts walking out,
    // but keeps his InHouse until the walk is complete, hence 'less or equal' here
    function CheckNoPhantoms(aTick: Cardinal): Boolean;

    function ListedRecruitsCnt: Integer;
    function AliveRecruitsCnt: Integer;
    function RecruitObjectsCnt: Integer; // Including the dead ones, which are not freed yet
    function BarracksExists: Boolean;
  end;

  // Recruit is dismissed while sitting inside the barracks. If the dismiss does start, he is killed
  // inside the school (TKMTaskDismiss), which never unregisters him from the barracks
  TKMTest_Recruit_Dismiss = class(TKMTest_RecruitsBase)
  private
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
  // it (ProceedHouseClosedForWorker, wGoingForEating branch), so that Home and InHouse diverge -
  // the only divergence the game code admits, see the comment in TKMUnitActionGoInOut.WalkOut.
  // Then the Inn is destroyed before the recruit steps out, and he is left inside with no Home at all
  TKMTest_Recruit_HomeLostWhileInside = class(TKMTest_RecruitsBase)
  private
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
  TKMTest_Recruit_HungryCycle = class(TKMTest_RecruitsBase)
  private
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
  TKMTest_Recruit_KilledInside = class(TKMTest_RecruitsBase)
  protected
    procedure SetUp; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;

  // Barracks keep raw pointers to their recruits in fRecruitsList without taking a counted reference,
  // unlike every other unit reference in the game (see TKMHandEntityPointer.GetPointer). A recruit
  // that gets closed while being listed is then freed right away - TKMUnitsCollection.UpdateState
  // frees the units with PointerCount = 0 - and the barracks are left with a dangling pointer, which
  // EquipWarrior happily dereferences. So: a listed recruit must be referenced by the barracks,
  // and once he is equipped and unregistered, that reference must be released (no leak)
  TKMTest_Recruit_ListOwnsPointer = class(TKMTest_RecruitsBase)
  private
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
  TKMTest_Recruit_BarracksDemolished = class(TKMTest_RecruitsBase)
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
  KM_Defaults, KM_Points,
  KM_GameApp, KM_HandsCollection, KM_HandTypes,
  KM_Houses, KM_HouseBarracks, KM_Units,
  KM_ResTypes;

const
  BARRACKS_LOC: TKMPoint = (X: 16; Y: 16);
  SCHOOL_LOC: TKMPoint = (X: 8; Y: 8);
  INN_LOC: TKMPoint = (X: 8; Y: 20);
  SETTLE_TICKS = 10; // Ticks to let the scene settle down before we touch anything


// Barracks are accessed by UID, since a destroyed house could be freed at any moment
function GetBarracks(aUID: Integer): TKMHouseBarracks;
begin
  Result := nil;

  var H := gHands.GetHouseByUID(aUID);
  if (H <> nil) and not H.IsDestroyed and (H is TKMHouseBarracks) then
    Result := TKMHouseBarracks(H);
end;


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


function RecruitsInHouseCnt(aHouse: TKMHouse): Integer;
begin
  Result := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and not U.IsDead and (U.UnitType = utRecruit) and (U.InHouse = aHouse) then
      Inc(Result);
  end;
end;


{ TKMTest_RecruitsBase }
procedure TKMTest_RecruitsBase.SetUpScene(aRecruitsCnt: Integer; aAddSchool: Boolean);
begin
  gGameApp.NewEmptyMap(32, 32);

  var barracks := TKMHouseBarracks(gHands[0].AddHouse(htBarracks, BARRACKS_LOC.X, BARRACKS_LOC.Y, False));
  fBarracksUID := barracks.UID;

  if aAddSchool then
    gHands[0].AddHouse(htSchool, SCHOOL_LOC.X, SCHOOL_LOC.Y, False);

  for var I := 0 to aRecruitsCnt - 1 do
    barracks.CreateRecruitInside(False);

  fError := '';
end;


procedure TKMTest_RecruitsBase.RecordError(const aError: string);
begin
  if fError = '' then // Keep the first error only, it is the most informative one
    fError := aError;
end;


procedure TKMTest_RecruitsBase.CheckRecordedError;
begin
  AssertTrue(fError = '', fError);
end;


function TKMTest_RecruitsBase.BarracksExists: Boolean;
begin
  Result := GetBarracks(fBarracksUID) <> nil;
end;


function TKMTest_RecruitsBase.ListedRecruitsCnt: Integer;
begin
  var barracks := GetBarracks(fBarracksUID);
  if barracks = nil then
    Result := 0
  else
    Result := barracks.RecruitsCount;
end;


function TKMTest_RecruitsBase.AliveRecruitsCnt: Integer;
begin
  Result := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and not U.IsDead and (U.UnitType = utRecruit) then
      Inc(Result);
  end;
end;


function TKMTest_RecruitsBase.RecruitObjectsCnt: Integer;
begin
  Result := 0;
  for var I := 0 to gHands[0].Units.Count - 1 do
  begin
    var U := gHands[0].Units[I];
    if (U <> nil) and (U.UnitType = utRecruit) then
      Inc(Result);
  end;
end;


function TKMTest_RecruitsBase.CheckNoPhantoms(aTick: Cardinal): Boolean;
begin
  Result := True;

  var barracks := GetBarracks(fBarracksUID);
  if barracks = nil then Exit; // Nothing to check anymore

  var listed := barracks.RecruitsCount;
  var actual := RecruitsInHouseCnt(barracks);

  Result := listed <= actual;
  if not Result then
    RecordError(Format('Tick %d: barracks lists %d recruit(s), while only %d recruit(s) are actually inside it',
                       [aTick, listed, actual]));
end;


{ TKMTest_Recruit_Dismiss }
procedure TKMTest_Recruit_Dismiss.SetUp;
begin
  fDuration := 2400;
  SetUpScene(1, True);

  fDismissStarted := False;
end;


function TKMTest_Recruit_Dismiss.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    var U := FindRecruit;
    if (U = nil) or (U.InHouse <> GetBarracks(fBarracksUID)) or (ListedRecruitsCnt <> 1) then
    begin
      RecordError('Test scene is broken: there should be exactly 1 recruit inside the barracks');
      Exit(False);
    end;

    U.Dismiss;

    // Dismiss can not even start for a unit inside a house: TKMTaskDismiss.FindNewSchool asks for
    // a route from the unit position, which is an unwalkable house tile (unlike TKMHand.FindInn,
    // which asks from the tile below the entrance). Then the recruit must be left alone
    fDismissStarted := U.IsDismissing;
    Result := fDismissStarted;
    Exit;
  end;

  if not CheckNoPhantoms(aTick) then
    Exit(False);

  // Keep running while the dismissed recruit is still around
  Result := AliveRecruitsCnt > 0;
end;


procedure TKMTest_Recruit_Dismiss.CheckResult;
begin
  CheckRecordedError;

  if fDismissStarted then
  begin
    AssertEquals(0, AliveRecruitsCnt, 'Recruit should have been dismissed');
    AssertEquals(0, ListedRecruitsCnt, 'Dismissed recruit should be unregistered from the barracks');
  end
  else
  begin
    AssertEquals(1, AliveRecruitsCnt, 'Recruit should be left alone when the dismiss could not even start');
    AssertEquals(1, ListedRecruitsCnt, 'Barracks should still list the recruit');
  end;
end;


class function TKMTest_Recruit_Dismiss.TestTags: TKMTestTagSet;
begin
  Result := [tcBarracks, tcRecruit, tcSchool];
end;


class function TKMTest_Recruit_Dismiss.TestDescription: string;
begin
  Result := 'Dismissing a recruit who sits inside the barracks must either not start at all or unregister him from the barracks.';
end;


{ TKMTest_Recruit_HomeLostWhileInside }
procedure TKMTest_Recruit_HomeLostWhileInside.SetUp;
begin
  fDuration := 1200;
  SetUpScene(1, False);

  var inn := gHands[0].AddHouse(htInn, INN_LOC.X, INN_LOC.Y, False);
  inn.WareAddToIn(wtBread, 3); // Otherwise the Inn is not worth going to

  fStage := 0;
  fStageTick := 0;
end;


function TKMTest_Recruit_HomeLostWhileInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  var U := FindRecruit;
  if U = nil then
  begin
    RecordError(Format('Tick %d: recruit is gone, while he was only supposed to stay inside the barracks', [aTick]));
    Exit(False);
  end;

  if not CheckNoPhantoms(aTick) then
    Exit(False);

  case fStage of
    0:  if aTick >= SETTLE_TICKS then
        begin
          U.Condition := UNIT_MIN_CONDITION - 1; // He will take the Inn and a TKMTaskGoEat
          fStage := 1;
        end;
    1:  if U.Task <> nil then // Got the eating task, but it did not start walking him out yet
        begin
          var barracks := GetBarracks(fBarracksUID);
          if barracks = nil then
          begin
            RecordError(Format('Tick %d: barracks are gone', [aTick]));
            Exit(False);
          end;

          // Barracks stops accepting recruits: that clears his Home, while he stays inside and listed
          barracks.ToggleAcceptRecruits;
          // And the Inn is gone, so the eating task ends before he steps out of the barracks
          gHands[0].RemHouse(INN_LOC, True);

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
  CheckRecordedError;
  AssertTrue(fStage = 3, 'Recruit was expected to get an eating task and then lose both the Inn and his Home');

  var U := FindRecruit;
  AssertTrue(U <> nil, 'Recruit should be alive');
  AssertTrue(U.InHouse = GetBarracks(fBarracksUID), 'Recruit should still be inside the barracks');
  AssertEquals(1, ListedRecruitsCnt, 'Barracks should list exactly 1 recruit');
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
  fDuration := 1200;
  SetUpScene(1, False);

  fStage := 0;
end;


function TKMTest_Recruit_HungryCycle.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  var U := FindRecruit;
  if U = nil then
  begin
    RecordError(Format('Tick %d: recruit is gone, while he was only supposed to show that he is hungry', [aTick]));
    Exit(False);
  end;

  if not CheckNoPhantoms(aTick) then
    Exit(False);

  case fStage of
    0:  if aTick >= SETTLE_TICKS then
        begin
          // There is no Inn on the map, hence he will go out of the barracks to show that he is hungry
          U.Condition := UNIT_MIN_CONDITION - 1;
          fStage := 1;
        end;
    1:  if U.Visible then // Stepped out of the barracks
          fStage := 2;
    2:  if not U.Visible then
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
  CheckRecordedError;
  AssertTrue(fStage = 3, 'Recruit should have gone out to show that he is hungry and got back inside');

  var U := FindRecruit;
  AssertTrue(U <> nil, 'Recruit should be alive');
  AssertTrue(U.InHouse = GetBarracks(fBarracksUID), 'Recruit should be back inside the barracks');
  AssertEquals(1, ListedRecruitsCnt, 'Barracks should list exactly 1 recruit');
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
  fDuration := 1200;
  SetUpScene(1, False);
end;


function TKMTest_Recruit_KilledInside.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    var U := FindRecruit;
    if (U = nil) or (U.InHouse <> GetBarracks(fBarracksUID)) then
    begin
      RecordError('Test scene is broken: there should be a recruit inside the barracks');
      Exit(False);
    end;

    U.Kill(HAND_NONE, True, False);
    Exit;
  end;

  if not CheckNoPhantoms(aTick) then
    Exit(False);

  // Keep running while the dying recruit is still around
  Result := AliveRecruitsCnt > 0;
end;


procedure TKMTest_Recruit_KilledInside.CheckResult;
begin
  CheckRecordedError;
  AssertEquals(0, AliveRecruitsCnt, 'Recruit should be dead');
  AssertEquals(0, ListedRecruitsCnt, 'Killed recruit should be unregistered from the barracks');
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
  fDuration := 600;
  SetUpScene(1, False);

  fEquipTick := 0;
end;


function TKMTest_Recruit_ListOwnsPointer.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    var U := FindRecruit;
    var barracks := GetBarracks(fBarracksUID);
    if (U = nil) or (barracks = nil) or (U.InHouse <> barracks) then
    begin
      RecordError('Test scene is broken: there should be a recruit inside the barracks');
      Exit(False);
    end;

    if U.PointerCount = 0 then
      RecordError(Format('Recruit inside the barracks is referenced by nobody (PointerCount = %d), ' +
                         'so the barracks recruits list is a raw pointer that can dangle', [U.PointerCount]));

    // Equip a warrior out of him: that kills the recruit and unregisters him from the barracks
    for var W := WARFARE_MIN to WARFARE_MAX do
      barracks.WareAddToIn(W, 1);

    if barracks.Equip(utMilitia, 1) <> 1 then
    begin
      RecordError('Test scene is broken: a militia was expected to be equipped');
      Exit(False);
    end;

    fEquipTick := aTick;
    Exit;
  end;

  if not CheckNoPhantoms(aTick) then
    Exit(False);

  // The equipped recruit is not referenced by anyone anymore, so he must be freed by now.
  // If the reference taken by the barracks list is never released, he would stay forever
  Result := aTick < fEquipTick + 100;
end;


procedure TKMTest_Recruit_ListOwnsPointer.CheckResult;
begin
  CheckRecordedError;
  AssertEquals(0, ListedRecruitsCnt, 'Equipped recruit should be unregistered from the barracks');
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
  fDuration := 600;
  SetUpScene(2, False);
end;


function TKMTest_Recruit_BarracksDemolished.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if not CheckNoPhantoms(aTick) then
    Exit(False);

  if aTick < SETTLE_TICKS then Exit;

  if aTick = SETTLE_TICKS then
  begin
    if ListedRecruitsCnt <> 2 then
    begin
      RecordError('Test scene is broken: there should be 2 recruits inside the barracks');
      Exit(False);
    end;

    gHands[0].RemHouse(BARRACKS_LOC, True);
    Exit;
  end;

  if BarracksExists then
  begin
    RecordError(Format('Tick %d: barracks should have been demolished', [aTick]));
    Exit(False);
  end;

  // Give the recruits some time to be placed outside of the demolished barracks
  Result := aTick < SETTLE_TICKS + 100;
end;


procedure TKMTest_Recruit_BarracksDemolished.CheckResult;
begin
  CheckRecordedError;
  AssertEquals(2, AliveRecruitsCnt, 'Both recruits should survive the demolition');
  AssertEquals(2, RecruitsInHouseCnt(nil), 'Both recruits should be placed outside of the demolished barracks');
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

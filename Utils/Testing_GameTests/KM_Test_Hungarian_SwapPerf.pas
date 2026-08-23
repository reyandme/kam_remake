unit KM_Test_Hungarian_SwapPerf;
{$I KaM_Remake.inc}
interface
uses
  KM_Points, KM_Test;


type
  // A 120 man group loses 10% of its men and the survivors get re-matched to their formation slots.
  // A benchmark rather than a check: sweeps the swap pass cap of TSimpleSolver from 2 to 24 and logs
  // what each cap costs and what it buys. Fails only when the swap loop itself misbehaves.
  TKMTest_HungarianSwapPerf = class(TKMTest)
  private const
    GROUP_SIZE = 120;     // Men in the group before anybody dies
    GROUP_WIDTH = 20;     // Men per rank, so 120 of them make 6 ranks
    KILLED_PERCENT = 10;
    SWAP_COUNT_FROM = 2;
    SWAP_COUNT_TO = 24;
    SOLVE_REPEATS = 50;   // Solves per cap. We keep the fastest
  private type
    // One row of the sweep - what the solver did when its swap loop was capped at Cap SwapCountActual
    TKMSwapRun = record
      SwapCountAllowed: Integer;  // Cap the solver was given, 0 being the greedy first step on its own
      SwapCountActual: Integer;      // SwapCountActual it actually ran, fewer than Cap means the assignment settled
      MinUSec: Int64;       // Fastest of SOLVE_REPEATS solves
      AvgUSec: Int64;
      Cost: Int64;        // Sum of Costs[I, Solution[I]] - the number the solver minimizes
      TotalWalk: Single;  // The same assignment measured in tiles the men would walk
      MaxWalk: Single;    // Longest rearrangement walk
    end;
  private
    fSlots: TKMPointArray;              // Formation slots waiting to be filled (the solver's agents)
    fMen: TKMPointArray;                // Where the survivors stand (the solver's tasks)
    fCosts: array of array of Cardinal; // Cost matrix, built the way HungarianMatchPoints builds it
    fRuns: array of TKMSwapRun;
    fGroupSize: Integer;
    fKilled: Integer;
    procedure KillRandomMembers;
    procedure SampleGroup;
    function ProductionCost: Int64;
    function MeasureCap(aSwapCountAllowed: Integer): TKMSwapRun;
    procedure RunSweep;
    procedure ReportSweep;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    function DoTick(aTick: Cardinal): Boolean; override;
    procedure CheckResult; override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  Math, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_CommonUtils, KM_Defaults, KM_GameApp, KM_HandsCollection,
  KM_HandTypes, KM_Hungarian, KM_Log, KM_ResTypes, KM_Terrain, KM_Units, KM_UnitGroup, KM_UnitWarrior;


{ TKMTest_HungarianSwapPerf }
procedure TKMTest_HungarianSwapPerf.SetUp;
begin
  inherited;

  DYNAMIC_TERRAIN := False;

  fDuration := 60;

  gGameApp.NewGameEmptyMap(64, 64);

  // Player controlled, so that no AI general orders the group about
  gHands[0].HandType := hndHuman;

  gHands[0].AddUnitGroup(utBowman, KMPoint(32, 32), dirE, GROUP_WIDTH, GROUP_SIZE);
end;


procedure TKMTest_HungarianSwapPerf.TearDown;
begin
  inherited;
  DYNAMIC_TERRAIN := True;
  FEAT_HUNGARIAN_GROUP_ORDER := True;
end;


function TKMTest_HungarianSwapPerf.DoTick(aTick: Cardinal): Boolean;
begin
  Result := True;

  if aTick = 10 then
  begin
    // Killing and sampling happen within one tick, so nobody has taken a step in between
    KillRandomMembers;
    SampleGroup;

    RunSweep;
    ReportSweep;

    Result := False;
  end;
end;


procedure TKMTest_HungarianSwapPerf.KillRandomMembers;
begin
  var group := gHands[0].UnitGroups[0];

  fGroupSize := group.Count;
  var toKill := Round(fGroupSize * KILLED_PERCENT / 100);

  // A death sends the group its order again, which re-matches the survivors. Hold that back, so the
  // deaths pile up and the solver gets what it is there for - a formation with holes in it
  FEAT_HUNGARIAN_GROUP_ORDER := False;
  try
    for var I := 0 to toKill - 1 do
    begin
      // Kill random member, never the leader - he carries the flag and HungarianReorderMembers leaves him out of the matching
      var idx := 1 + KaMRandom(group.Count - 1{$IFDEF DBG_RNG_SPY}, 'TKMTest_HungarianSwapPerf.KillRandomMembers'{$ENDIF});

      // No animation and no delay, so the man leaves fMembers before we pick the next one
      group.Members[idx].Kill(HAND_NONE, False, False);
    end;
  finally
    FEAT_HUNGARIAN_GROUP_ORDER := True;
  end;

  fKilled := fGroupSize - group.Count;
end;


// Take down what HungarianReorderMembers hands to the solver - the survivors where they stand,
// and the slots of the formation they are supposed to fill
procedure TKMTest_HungarianSwapPerf.SampleGroup;
var
  canBeReached: Boolean;
begin
  var group := gHands[0].UnitGroups[0];
  var cnt := group.Count - 1; // The leader is not reordered, so he is not in the matching either

  SetLength(fSlots, cnt);
  SetLength(fMen, cnt);
  for var I := 0 to cnt - 1 do
  begin
    // The slot GetMemberLoc would give member I + 1, that one being private to the group
    fSlots[I] := GetPositionInGroup2(group.OrderLoc.Loc.X, group.OrderLoc.Loc.Y, group.OrderLoc.Dir, I + 1, group.UnitsPerRow, gTerrain.MapX, gTerrain.MapY, canBeReached);
    fMen[I] := group.Members[I + 1].Position;
  end;

  // The matrix HungarianMatchPoints builds for huIndividual - costs are squared, so one man walking ten tiles weighs far more than ten men taking a step each
  SetLength(fCosts, cnt, cnt);
  for var I := 0 to cnt - 1 do
    for var J := 0 to cnt - 1 do
      fCosts[I, J] := Round(Sqr(10 * fSlots[I].GetLengthDiag(fMen[J])));
end;


// The cost the game itself would end up with, sampled points fed through the production path.
// Keeps the sweep honest: it measures a matrix this test builds, and that has to be the same matrix
function TKMTest_HungarianSwapPerf.ProductionCost: Int64;
begin
  Result := 0;

  var agents := TKMPointList.Create;
  var tasks := TKMPointList.Create;
  try
    // Same way round as HungarianReorderMembers calls it - slots are the agents, the men are the tasks
    for var I := 0 to High(fSlots) do
      agents.Add(fSlots[I]);
    for var I := 0 to High(fMen) do
      tasks.Add(fMen[I]);

    var order := HungarianMatchPoints(agents, tasks, huIndividual);

    for var I := 0 to High(fSlots) do
      Result := Result + fCosts[I, order[I]];
  finally
    agents.Free;
    tasks.Free;
  end;
end;


// Solve the sampled matrix SOLVE_REPEATS times with the swap loop capped at aCap SwapCountActual
function TKMTest_HungarianSwapPerf.MeasureCap(aSwapCountAllowed: Integer): TKMSwapRun;
begin
  var cnt := Length(fCosts);

  var solver := TSimpleSolver.Create;
  try
    solver.SwapCountAllowed := aSwapCountAllowed;

    // Filling the matrix is not part of the measurement, and Solve only ever reads it, so one fill
    // serves every repeat. Solve resets Solution and TaskClaimedBy itself, so the repeats are identical
    SetLength(solver.Costs, cnt, cnt);
    for var I := 0 to cnt - 1 do
      for var J := 0 to cnt - 1 do
        solver.Costs[I, J] := fCosts[I, J];

    Result.SwapCountAllowed := aSwapCountAllowed;
    Result.MinUSec := High(Int64);
    var totalUSec: Int64 := 0;

    for var R := 0 to SOLVE_REPEATS - 1 do
    begin
      var startedAt := TimeGetUsec;
      solver.Solve;
      var spent := TimeGetUsec - startedAt;

      totalUSec := totalUSec + spent;
      Result.MinUSec := Min(Result.MinUSec, spent);
    end;

    Result.AvgUSec := Round(totalUSec / SOLVE_REPEATS);
    Result.SwapCountActual := solver.SwapCountActual;

    Result.Cost := 0;
    Result.TotalWalk := 0;
    Result.MaxWalk := 0;
    for var I := 0 to cnt - 1 do
    begin
      Result.Cost := Result.Cost + fCosts[I, solver.Solution[I]];

      var walkLength := fSlots[I].GetLengthDiag(fMen[solver.Solution[I]]);
      Result.TotalWalk := Result.TotalWalk + walkLength;
      Result.MaxWalk := Max(Result.MaxWalk, walkLength);
    end;
  finally
    solver.Free;
  end;
end;


procedure TKMTest_HungarianSwapPerf.RunSweep;
begin
  SetLength(fRuns, (SWAP_COUNT_TO - SWAP_COUNT_FROM) + 2);

  // Row 0 is the baseline: the greedy first step and the final comparison, without a single swap
  // pass. What the other rows cost on top of it is the time spent in DoSwaps
  fRuns[0] := MeasureCap(0);

  var idx := 0;
  for var I := SWAP_COUNT_FROM to SWAP_COUNT_TO do
  begin
    if Assigned(fOnProgress) then
      fOnProgress(Format('swap pass cap %d of %d', [I, SWAP_COUNT_TO]));

    Inc(idx);
    fRuns[idx] := MeasureCap(I);
  end;
end;


// The table is the point of this test, so it goes into the log whether the assertions pass or not
procedure TKMTest_HungarianSwapPerf.ReportSweep;
begin
  gLog.AddNoTime('', False);
  gLog.AddNoTime(Format('%s: %d men, %d of them killed, %d survivors matched to their slots (leader aside)', [ClassName, fGroupSize, fKilled, Length(fMen)]), False);
  gLog.AddNoTime(Format('%d solves per cap, the fastest of them reported. The game runs SWAP_COUNT_DEFAULT = %d', [SOLVE_REPEATS, SWAP_COUNT_DEFAULT]), False);
  gLog.AddNoTime('  cap  passes   solve us    avg us   swaps us   us/pass          cost   walk tiles   max walk', False);

  for var I := 0 to High(fRuns) do
  begin
    // Cap 0 does no swapping at all, so whatever a row costs above that baseline is DoSwaps
    var swapsUSec := fRuns[I].MinUSec - fRuns[0].MinUSec;
    var perPass := 0.0;
    if fRuns[I].SwapCountActual > 0 then
      perPass := swapsUSec / fRuns[I].SwapCountActual;

    gLog.AddNoTime(Format('%5d  %6d   %8d  %8d   %8d  %8.1f  %12d   %10.1f   %8.1f',
      [fRuns[I].SwapCountAllowed, fRuns[I].SwapCountActual, fRuns[I].MinUSec, fRuns[I].AvgUSec, swapsUSec, perPass, fRuns[I].Cost, fRuns[I].TotalWalk, fRuns[I].MaxWalk]), False);
  end;
end;


procedure TKMTest_HungarianSwapPerf.CheckResult;
begin
  AssertTrue(Length(fCosts) > 0, 'The group was never sampled, the test did not get as far as its first kill');
  AssertTrue(fGroupSize = GROUP_SIZE, Format('The group came out %d men strong instead of %d', [fGroupSize, GROUP_SIZE]));

  // The loop is meant to stop once nothing improves any more, the cap being only a backstop
  var lastRun := fRuns[High(fRuns)];
  AssertTrue(lastRun.SwapCountActual < lastRun.SwapCountAllowed, Format('The swap loop did not settle within %d passes for %d men', [lastRun.SwapCountAllowed, Length(fCosts)]));

  // Every next swap should make the total cost lower
  for var I := 1 to High(fRuns) do
    AssertTrue(fRuns[I].Cost <= fRuns[I - 1].Cost,
      Format('SwapCount %d produced a worse assignment than SwapCount %d, cost %d against %d', [fRuns[I].SwapCountAllowed, fRuns[I - 1].SwapCountAllowed, fRuns[I].Cost, fRuns[I - 1].Cost]));

  // Check that game cost equals to our run cost
  for var I := 0 to High(fRuns) do
  if fRuns[I].SwapCountAllowed = SWAP_COUNT_DEFAULT then
  begin
    var gameCost := ProductionCost;
    AssertTrue(gameCost = fRuns[I].Cost, Format('HungarianMatchPoints came out at cost %d over the same points, the sweep says %d', [gameCost, fRuns[I].Cost]));
  end;
end;


class function TKMTest_HungarianSwapPerf.TestTags: TKMTestTagSet;
begin
  Result := [tcBowman, tcCombat];
end;


class function TKMTest_HungarianSwapPerf.TestDescription: string;
begin
  Result := 'Times the swap passes that re-match a 120 man group to its formation slots after 10% of it died.';
end;


initialization
  RegisterTest(TKMTest_HungarianSwapPerf);
end.

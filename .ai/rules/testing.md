# Testing

Two separate test projects, with different purposes and different frameworks. Pick the one that
fits and follow what the tests already there do.

| Project | Framework | For |
|---|---|---|
| `Utils/UnitTests` | DUnit | Pure logic with no game around it: utilities, points, streams, containers |
| `Utils/Testing_GameTests` | Own harness (`TKMTest`) | Gameplay behaviour, by running a real game and ticking it |

## Unit tests (`Utils/UnitTests`)

- Descend from `TTestCase`, put the test methods under `published`.
- Register in `initialization` with `RegisterTest(TestKMSomething.Suite);`.
- The runner is `UnitTests.dpr`, GUI by default and console under `CONSOLE_TESTRUNNER`.

## Game tests (`Utils/Testing_GameTests`)

These start a game, tick it forward and check what happened. One class per file.

The game runs with a blind render (`TKMRender` with no render control), not with no render at all:
`gRender` exists, and so does the gameplay interface. Passing `--show-window` gives it a real
window instead, which is useful when you want to watch a test.

### Shape of a test

```pascal
TKMTest_SomethingHappens = class(TKMTest)
private const
  SOME_LIMIT = 10;
protected
  procedure SetUp; override;
  procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
  procedure CheckResult; override;
public
  class function TestTags: TKMTestTagSet; override;
  class function TestDescription: string; override;
end;
```

- `SetUp` - build the world: `gGameApp.NewGameEmptyMap`, place houses and units, set `fDuration`
  (how many ticks to run at most).
- `DoTick(aTick, aKeepGoing)` - called once per tick. `aKeepGoing` comes in `True`, so only touch
  it to stop early. Assert here, as soon as the answer is known.
- `CheckResult` - what must hold once the run is over. May be empty with a comment saying so, if
  everything was checked as it went.
- `TearDown` - only if `SetUp` changed a global, to put it back.
- Register in `initialization` with `RegisterTest(TKMTest_Something);`.

Assertions are `AssertTrue` and `AssertEquals` from `KM_Test`.

### Style

Follow `KM_Test_Archers_GoFar.pas`, which is the fullest example in the suite:

- Constants belong in the class as `private const`, not in a unit level `const` block.
- Helpers that need game types go at unit level in the `implementation` section, above the class
  methods.
- Prefer `Continue` guards over one compound condition when walking units or houses.
- Say what the test builds and when it fails in a comment above the class.
- The test builds its own map, so `gHands[0].Houses[0]` is enough to reach the house it placed.
- Write durations as ticks per minute where that reads better: `fDuration := 3 * 600;`.
- Failure messages should carry the numbers that failed and the tick, so the log is enough to
  understand what went wrong without a debugger.

### Rules for writing them

- One behaviour per test.
- Drive the game, do not reach into internal state to force a situation. A test that assigns a
  field to set up its scenario is testing the assignment, not the game.
- Do not tie a test to a tick the game chooses. Anything that follows from walking, eating or
  pathfinding lands on a different tick for every seed, and the suite is run over several seeds
  with `--cycles`. Watch for the state instead. Ticks the test itself picks are fine.
- Keep no more state on the test than the run actually needs. A `Boolean` field that only restates
  what the current tick or the world already says should not exist.
- Clean up after a test that changes a global, in `TearDown`.

### Two traps in the harness

- **`SetUp` runs outside the `try` in `Run`.** An exception there escapes as a plain exception, not
  as a test failure.
- **`CheckResult` runs from a `finally`.** If it raises while `DoTick` is already raising, its
  exception replaces the original one and the log shows the wrong cause. Record that a step
  happened before the step that can fail, not after.

### What review keeps sending back

Every item below is something a reviewer here has already had to say about an AI-written test.
They cost nothing to get right the first time.

**Do not build scaffolding the test does not need.**

- A helper method that wraps one expression is an overcomplication, not an abstraction. Call the
  expression.
- A field that holds a value only to compare it ten lines later in the same method is not state.
  Compare it where you have it.
- A unit level `const` block in a test is noise - inline the number. If it genuinely needs a name,
  because it is the threshold the test is *about*, put it in the class as `private const`, the way
  `MAX_WALK_DIST` does in `KM_Test_Archers_GoFar`.
- Drop conditions that cannot be false. Filtering units by `UnitType = utRecruit` inside a
  barracks says nothing, because nothing else is in there.

**A test has to be worth the world it builds.**

- Do not assert on a fraction of the state and describe it as the whole. A savegame is megabytes;
  checking a dozen bytes of it and calling the test "the world came back unchanged" claims
  something it never measured.
- Aiming at the whole world in one test is not feasible. Pick the one behaviour the test is really
  about, and let `TestDescription` say exactly that and no more.
- A game test is about gameplay. If what you are checking is a serialization detail or a utility
  function, it belongs in `Utils/UnitTests`.

**Readability is a review criterion, not a preference.**

- If a reviewer has to work at following the control flow, simplify it. Where the test picks the
  moment, drive off `aTick` rather than a state machine of `Boolean` fields.
- `unitsInside`, not `inside`. A name that needs the surrounding line to be understood is too
  short.
- Keep a `Format` call on one line where it fits, and put the tick at the end of the message.
- Put a comment next to the statement it explains, inside the branch, rather than above the whole
  block.

### Naming

`KM_Test_<Area>_<Aspect>.pas` holding `TKMTest_<Area><Aspect>` - the file separates the parts with
an underscore, the class runs them together.

```
KM_Test_Sawmill_DeliveryIn.pas  ->  TKMTest_SawmillDeliveryIn
KM_Test_Bakery.pas              ->  TKMTest_Bakery
```

New test units go in `Testing_GameTests.dpr`, in the existing alphabetical order - see
`coding-rules.md`.

### Running them

```
Testing_GameTests.exe --run-all [--seed=N] [--cycles=N] [--show-window] [--out=<file>]
Testing_GameTests.exe --run=Recruit
```

`--run` takes a case insensitive substring of the test class name. `--cycles=N` runs the selection
N times, incrementing the seed each time, which is how a test that only passes on one seed gets
caught. Results go to `--out`, by default `Testing_GameTests_results.log`. Exit code is 0 when
everything passed and 1 when something did not.

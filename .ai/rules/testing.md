# Testing

There are two test projects. They are not interchangeable - pick by what the code under test is,
and follow the conventions already present in that project.

| Project | Framework | Use it for |
|---|---|---|
| `Utils/UnitTests` | DUnit (`TestFramework`) | Pure logic with no game around it: utilities, points, streams, containers |
| `Utils/Testing_GameTests` | Own harness (`KM_Test.pas`) | Gameplay behaviour, which needs a running game |

Neither project can be built from the command line - see the build note in `project.md`.

## Unit tests (`Utils/UnitTests`)

DUnit, not DUnitX. Do not introduce DUnitX, `[TestFixture]` attributes or a DUnitX runner here.

- One `TTestCase` descendant per unit under test, file named `TestKM_<Unit>.pas`.
- Test methods go in the `published` section - that is how DUnit discovers them.
- `SetUp` / `TearDown` are `override`.
- Register in `initialization` with `RegisterTest(TestKMSomething.Suite);`.
- The runner is `UnitTests.dpr`, GUI by default and console under `CONSOLE_TESTRUNNER`.

## Game tests (`Utils/Testing_GameTests`)

These run a real game with no user interface at all (see the headless section in
`project-rules.md`), tick it forward, and check what happened. One class per file.

### Shape of a test

`TKMTest` splits the test along Arrange - Act - Assert, and the split is not optional:

- `SetUp` - **Arrange.** Start the world (`gGameApp.NewGameEmptyMap`), place houses and units,
  set `fDuration` (the number of ticks to run).
- `DoTick(aTick)` - **Act.** Called once per tick. Read it as a human sequence: "at tick 30, save
  the game", "at tick 10, equip a soldier". Returning `False` ends the run early.
- `CheckResult` - **Assert.** What must be true when the run is over.
- `TestTags` and `TestDescription` describe the test for the runner. The description states the
  expected behaviour, not the mechanics.
- Register in `initialization` with `RegisterTest(TKMTest_Something);`.

Assertions are `AssertTrue` and `AssertEquals` from `KM_Test`. Assert as soon as the answer is
known - preferably inside `DoTick` - rather than storing values in fields to compare later.

### Rules for writing them

- A test must not know the implementation. Name it after the behaviour, and check the behaviour
  through the public API. `TKMTest_Recruit_ListOwnsPointer` is a bad name; a test that reads a
  private counter is a bad test.
- One behaviour per test. If a test needs two unrelated assertions, it is two tests.
- No leftovers. Every field, constant and helper in the test has to earn its place - copying the
  skeleton of another test and leaving its settling delays and lookup helpers in place is worse
  than writing it from scratch.
- Do not defer work into fields when a local variable does. If the test built the world itself,
  the expected values are known by construction and there is nothing to capture beforehand.

### Two traps in the harness

- `SetUp` is called **outside** the `try..except` in `TKMTest.Run`, so a failed assertion there
  escapes uncaught instead of being reported as a failed test. Keep assertions out of `SetUp`.
- `CheckResult` is called from a `finally`, so raising in it replaces any exception that `DoTick`
  was already raising. Do not let a follow-up check hide the original failure.

### File and class naming

Follow the suite: `KM_Test_<Area>_<Aspect>.pas` holding `TKMTest_<Area><Aspect>` - the file
separates the parts with an underscore, the class concatenates them.

```
KM_Test_Sawmill_DeliveryIn.pas  ->  TKMTest_SawmillDeliveryIn
KM_Test_Bakery.pas              ->  TKMTest_Bakery
```

New test units must be registered in both `Testing_GameTests.dpr` and `Testing_GameTests.dproj`,
keeping the existing alphabetical order - see `project-layout.md`.

### Running them

```
Testing_GameTests.exe --run-all [--seed=N] [--cycles=N] [--show-window] [--out=<file>]
Testing_GameTests.exe --run=Recruit
```

`--run` filters on a case insensitive substring of the test class name. Results go to the `--out`
file, by default `Testing_GameTests_results.log` next to the executable. Exit code is `0` when
everything passed, `1` when something failed and `2` when the filter matched no test.

Tests must be deterministic: the same seed must always give the same result. `--cycles` reruns
the set with a different seed each time and is the cheapest way to catch a test that only passes
by luck.

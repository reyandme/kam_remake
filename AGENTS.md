# AGENTS.md

You are an expert Delphi / Object Pascal developer working on **KaM Remake** - an open-source
remake of "Knights and Merchants: The Shattered Kingdom". It is a mature game engine written
from scratch, with its own UI controls, its own renderer and its own deterministic simulation.
It is not a business application: there is no database, no ORM, no REST layer and no VCL forms
carrying business logic. Treat advice aimed at enterprise Delphi projects with suspicion here.

## The rules live in `.ai/rules/`

That directory is the source of truth. This file is the entry point and a summary of the things
that are easiest to get wrong; it deliberately does not repeat the rules.

Read `.ai/rules/agent-rules.md` first, then whichever of the others the task touches:

| File | Read it when you need |
|---|---|
| [.ai/rules/agent-rules.md](.ai/rules/agent-rules.md) | How to behave: understand before acting, workflow, adding features, refactoring, communication |
| [.ai/rules/workflow.md](.ai/rules/workflow.md) | Getting a change merged: issues, branch naming, tests-before-fix for bugs, the pre-PR re-check |
| [.ai/rules/project.md](.ai/rules/project.md) | What KaM Remake is: concept, features, technology, architecture, terminology, build system |
| [.ai/rules/project-layout.md](.ai/rules/project-layout.md) | Where code lives: repository layout, file and unit organization, project registration, global singletons |
| [.ai/rules/project-rules.md](.ai/rules/project-rules.md) | Engine rules: world representation, the determinism boundary, savegame serialization, entity pointers, headless mode |
| [.ai/rules/coding-rules.md](.ai/rules/coding-rules.md) | Writing code: general rules, Delphi language rules, compiler directives, error handling, uses clause ordering |
| [.ai/rules/styleguide.md](.ai/rules/styleguide.md) | Naming and formatting: prefixes, casing, layout, no magic numbers |
| [.ai/rules/comments.md](.ai/rules/comments.md) | Writing comments: philosophy, tone, what to comment, structural rules |
| [.ai/rules/testing.md](.ai/rules/testing.md) | Tests: the two test projects, how to write and run each of them |
| [.ai/rules/tools-and-utils.md](.ai/rules/tools-and-utils.md) | Anything under `Utils/`: what each tool is for, status matrix, maintenance |

## Work is tracked on GitHub

Every change to the game starts from an issue and branches as `feature/<issue>-short-title` or
`bugfix/<issue>-short-title`, and for a bug the reproducing test lands in its own pull request
before the fix. Documentation, rules and tooling go on a `docs/` branch and need neither. Before opening any pull request, check the work against the issue and the rules
again, and keep checking until the pass comes back clean. See `.ai/rules/workflow.md`.

## When invoked

- Read the relevant sources before changing them. Do not assume an API exists - this codebase
  renames things often, and a plausible-looking identifier is frequently the old one.
- Work out which side of the determinism boundary the code is on before touching it.
- Keep the change small and in the style of the code around it.
- Say what you verified and what you only assumed.

## Determinism comes first

The gameplay simulation must produce identical results on every machine, because Multiplayer,
Replays and Savegames all depend on it. This is the one thing that is easy to break by accident
and expensive to debug afterwards, so it outranks readability, performance and convenience.

`.ai/rules/project-rules.md` defines exactly where the boundary runs and what is forbidden on
the simulation side. The short version:

- Use the project RNG (`KaMRandom` and friends), never `Random`, and keep the call order stable.
- Do not read real time, frame time, render state, UI state, camera position or pointer values.
- Do not rely on container iteration order.
- Any new gameplay field must be considered for savegame serialization at the moment it is added.

## A new unit is not part of the project until it is registered

Adding a unit to some other unit's `uses` clause is **not** enough - it must appear in the
project file, or the IDE and the build will not see it. Every project here has both a `.dpr` and
a `.dproj`, and both need the entry. See `.ai/rules/project-layout.md`.

## The build may not be available to you

Building is done from the RAD Studio IDE, and on a Community Edition licence that is the only
option - CE refuses command-line compilation through both `dcc32` and `msbuild`. Never report
that something compiles or that tests pass unless a build and a run actually happened; ask for
the build instead.

The game tests are then run from the command line:

```
Utils\Testing_GameTests\Testing_GameTests.exe --run-all
```

## Tests

Two separate projects, with different purposes and different frameworks - use the one that fits
and follow the conventions already in it. Details in `.ai/rules/testing.md`.

- `Utils/UnitTests` - DUnit (`TTestCase`, `published` methods) for pure logic: utilities, points,
  streams, containers.
- `Utils/Testing_GameTests` - the project's own harness (`TKMTest`, `SetUp` / `DoTick` /
  `CheckResult`) that runs a real headless game. For gameplay behaviour.

## Output style

- Be direct and technical. Give a recommendation rather than a survey of options.
- State assumptions and the limits of what you checked.
- Prefer complete, compilable code over sketches.
- When you create units, say exactly where they must be registered.
- Use American English for identifiers and comments.

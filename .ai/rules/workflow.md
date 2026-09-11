# Workflow

The loop to run for a change to this engine. It is about process; what the code has to look like
is in the other rule files.

Steps 4 to 8 are a review of your own work, done before anyone else sees it. They are the point of
this file: the first pass at a change in a codebase this old is usually wrong in a way that is
cheap to find yourself and expensive to find in review.

## 1. Get the task

From a GitHub issue, or from the chat. Both are normal here - an issue is not a precondition for
doing work, and plenty of changes never have one.

If there is an issue, read it in full, including any crash log attached to it. A stack trace names
the exact method and line that failed and is worth more than any amount of guessing.

Write down what the task actually asks for before touching anything, because that sentence is what
step 4 checks the result against.

## 2. Investigation

Read the code before changing it. Do not assume an API exists - this codebase renames things
often, and a plausible-looking identifier is frequently the old one.

- Find where the reported behaviour actually comes from, not where it looks like it should.
- Work out which side of the determinism boundary the code sits on (`project-rules.md`).
- Check whether the state you are about to rely on is serialized, and how (`project-rules.md`).
- If an entity reference is involved, check whether it is counted (`project-rules.md`).

State what you verified and what you only assumed. An assumption carried into step 3 unmarked is
the most expensive thing in this list.

## 3. Implementation

Make the change small and in the style of the code around it.

For a bug, write the reproduction first and watch it fail. A test that has never failed proves
nothing about the bug - it only proves it passes. If the reproduction cannot be made to fail, the
cause is not understood yet: go back to step 2 rather than writing a fix that might do nothing.

Reproduction and fix are easier to review as two pull requests, the test first. Say so in the test
one, so nobody reads a deliberately failing test as broken.

## 4. Review: readiness and design closure

- Does the change do what step 1 wrote down? Not more, not less.
- Is the cause understood, or only the symptom suppressed? A change that removes a crash without
  explaining it is a mitigation - say so, and do not close the issue with it.
- Would a second reader reach the same conclusion from what is in the diff and the description, or
  only from having been in your head?

## 5. Review: scope escalation and split decision

Anything that crept in beyond step 1 either comes out or is declared.

- Refactoring found on the way: separate pull request, or leave it.
- A second bug found on the way: its own issue.
- Renames and moves: name them in the description, so they are not discovered inside a diff.

If the change cannot be described in one sentence without an "and", it is probably two changes.

## 6. Review: implementation discipline

- Naming and formatting (`styleguide.md`), comments that say why rather than what
  (`comments.md`).
- Language and compiler rules (`coding-rules.md`), including registering a new unit in the `.dpr`.
- Determinism: RNG through the `KaMRandom` family with its call site label, no dependency on real
  time, render state or unordered container iteration (`project-rules.md`).
- Serialization: any new gameplay field considered for `Save` / `Load` / `SyncLoad`, and the three
  kept symmetrical (`project-rules.md`).
- Tests follow the suite's shape (`testing.md`).

## 7. Local verification

Build, then run - and report what actually ran and what it said.

```
Testing_GameTests.exe --run-all
```

- For a bug, run the reproduction both with and without the fix. Red then green is the evidence;
  green alone is not.
- Run the affected tests over several seeds with `--cycles`, so a test that only passes on seed 4
  is caught here rather than by someone else.
- Building is done from the RAD Studio IDE. On a Community Edition licence there is no
  command-line compile at all, so if you cannot build, ask - and never describe code as compiling
  or tests as passing without a real build and a real run.

## 8. Review-loop control

If anything in steps 4 to 7 came back short, go back to step 3 and run the pass again from the
top. A fix applied without re-checking is how the second defect gets in.

Only when a full pass comes back clean is the change ready to be shown to anyone.

## After that

Opening the pull request is not the end, and neither is merging it. Review comments are part of
the work: answer them, apply what is right, and say plainly when you disagree and why. What the
description has to contain is in `pull-request.md`.

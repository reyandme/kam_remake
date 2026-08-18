# Workflow

How a change gets from an idea to a merged pull request. This is about process; what the code
itself has to look like is in the other rule files.

## Every change to the game starts from a GitHub issue

The issue is what the branch is named after and what the pull request closes, and it is where the
problem is described so that the pull request can stay about the solution. If there is no issue
for the task yet, open one before starting.

## Branch naming

```
feature/<issue>-short-title
bugfix/<issue>-short-title
docs/short-title
```

The issue number comes first, then a short lowercase kebab-case title - enough to recognise the
branch in a list, not a summary of the change. As used in the repository:

```
feature/2226-animals-can-block-units
bugfix/300-barracks-recruits-list
docs/ai-agent-rules
```

`docs/` covers documentation, the agent rules themselves, and build, CI and tooling
configuration. It is the one prefix that does not need an issue, since there is often nothing to
describe beyond the change itself - use `docs/<issue>-short-title` when an issue does exist. It is
also the one prefix that is not split into a test pull request and a fix pull request, because
there is no behaviour to reproduce.

That exemption is exactly as narrow as it sounds: a change that touches `src/` is a feature or a
bug fix, whatever else it also does. Infrastructure work on the engine - a new harness capability,
something made testable - carries an issue and follows the rules for its kind. `docs/` is not a
way around writing the test first.

## Bugs: the test comes first, in its own pull request

A bug fix is two pull requests, in this order:

1. **The reproduction.** A test that fails because of the bug. Nothing else - no fix, no cleanup.
   This pull request is expected to be red on `master`: that is what proves the bug is real and
   that the test actually catches it. A test that passes on `master` does not reproduce anything.
2. **The fix**, branched off the first one, so that the same test turns green in it.

The point of the order is that a test written after the fix only proves the fix does what its
author remembers writing. Written first, it proves the bug existed.

If the reproduction turns out to pass on `master`, that is a finding, not a formality to work
around: the bug is somewhere else, or the understanding of it is wrong. Say so instead of
adjusting the test until it goes red.

## Features: tests and implementation in one pull request

There is no bug to reproduce, so splitting them buys nothing. Keep the tests and the code they
cover in the same pull request.

## Before opening a pull request, check the work again

Not a glance over the diff - a fresh pass with the issue open next to it:

- Does the change do what the issue asked for? Not more, not less. Anything extra that crept in
  either belongs in its own issue or comes out.
- Does it follow the rules in `.ai/rules/`? The ones most often missed: naming and formatting
  (`styleguide.md`), the determinism boundary (`project-rules.md`), serialization of new gameplay
  fields (`project-rules.md`), new units registered in both the `.dpr` and the `.dproj`
  (`project-layout.md`), and comments that say why rather than what (`comments.md`).
- Was it built and were the tests run? Report what actually ran and what it said. Never describe
  code as compiling or tests as passing without a real build and a real run - see the build note
  in `project.md`.

**If anything is off, fix it and run the pass again from the top.** The check is repeated until it
comes back clean, not performed once and filed away.

## Review

Answer review comments where they were made, and say what changed rather than only that you
agree. When a comment leads to a different change than the one suggested, or when something else
gets changed along the way, say that in the pull request too - a reviewer should never have to
discover an unexplained rename in a force-push.

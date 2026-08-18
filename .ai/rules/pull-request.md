# Pull Request Description

The pull request body is where a reviewer decides whether to trust the change and where to spend
attention. It should say what to look at, what was already checked and what was not - it should
not restate the diff, which the reviewer can read.

Write it in English, like the rest of the repository.

## Link the issue without closing it

```
Related to #<issue>
```

Use `Closes` or `Fixes` only when merging really should close the issue. A change that removes one
crash path without finding the cause, or that covers part of a problem, is `Related to` - closing
the issue in that case buries the part nobody solved.

## Template

```markdown
Related to #<issue>

## Summary

One paragraph: what changed and why.

- What the issue asked for:
- What this delivers:
- Deliberately left out:

## Review intent

- Look here first:
- Risky:
- Mechanical / low risk:
- Worth challenging:

## Implementation notes

- Decisions and the reasoning behind them:
- Trade-offs:
- Follow-up work, with issue links if any were opened:

## Determinism and savegames

- Gameplay simulation touched, and on which side of the boundary:
- New gameplay fields, and whether they are serialized:
- Savegame, replay or multiplayer sync affected:

## Verification

- Built:
- Tests run, and what they reported:
- Manual check, with the steps taken:
- Not run or blocked, and why:

## Risks and open questions

-
```

## What each section is for

**Summary.** The three bullets matter more than the paragraph. "What the issue asked for" next to
"what this delivers" is what lets a reviewer see a mismatch without reading the whole diff, and
**deliberately left out** is the one a reviewer will otherwise ask about after they have already
read everything. Say up front that the root cause was not found, that a case is not covered, that
a fixture is missing.

**Review intent.** Reviewer attention is the scarce resource. Point it at the parts that can be
wrong, and say plainly which parts are renames, formatting or mechanical follow-through so they
are not read line by line. "Worth challenging" is not modesty - if a decision could reasonably
have gone the other way, name it, because that is where a review earns its keep.

This section is also where anything the issue did not ask for gets declared. A reviewer should
never discover an unexplained rename, a refactor or a moved file in the diff, least of all in a
force-push. Declaring it is not optional; if it cannot be justified in a sentence, take it out and
put it in its own issue.

**Implementation notes.** Why, not what. If an approach was chosen over an obvious alternative,
the reason belongs here rather than in the reviewer's head.

**Determinism and savegames.** These are the two things in this engine that break quietly and
expensively, so they are stated explicitly every time - see `project-rules.md`. If a row does not
apply, say why it cannot apply to this diff. A bare `N/A` is not an answer.

**Verification.** State what actually ran and what it said. Never write that the build is clean or
the tests pass without a real build and a real run behind it - and remember there is no
command-line build on a Community Edition machine, so "built" often means asking someone. Listing
what was **not** run is as important as listing what was: an unrun check that looks run is worse
than an admitted gap.

**Risks and open questions.** Cheap to write, and it is where a reviewer can hand back the one
piece of knowledge the author lacks.

## Keep it in step with the branch

When the branch changes after review has started, say what changed and why in a comment - a
reviewer who already read the diff has no way to tell a rebase from a rewrite. Answer review
comments where they were made, and say what changed, not only that you agree.

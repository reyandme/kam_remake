# Pull request description

Short. The diff says what changed; the description says what a reader cannot get from the diff.

## Template

```markdown
## Title

<!-- TLDR, max 15 words -->

## Description

<!-- One short paragraph: what changed and why. -->
<!-- TLDR, max 50 words -->

### Critical information that is not in the code

<!-- if needed -->
<!-- Link to the issue, or describe the situation when there is none. Max 50 words. -->

<!-- Use the non-closing link by default. Use Closes/Fixes only when this pull request closes the issue. -->
Related to #<issue>
```

## What each part is for

**Title** - what was done, not how. It is the line that shows up in the commit list forever.

**Description** - one paragraph. If it needs more than that, the change is probably two changes;
see the split decision in `workflow.md`.

**Critical information that is not in the code** - the section that earns its place. A crash log
from the issue, why the fix is where it is rather than the obvious place, what was tried and did
not work, which part is a mitigation rather than a cure. Skip it when there is nothing to say.

**Related to / Closes** - `Related to` by default. `Closes` only when the issue is actually
finished by this change. A pull request that removes a crash without explaining its cause does not
close the issue, and saying so is more useful than a green checkmark.

## Two things worth adding when they apply

- **Determinism and savegames.** If the change touches gameplay simulation or anything
  serialized, say what happens to the savegame format and to replay determinism. These break
  quietly, and a reviewer cannot see from a diff that you thought about it.
- **What was verified, and what was not.** Which tests ran and what they reported, over how many
  seeds. Equally, what you did not run - a multiplayer session, a real savegame from a player.
  Building here is manual, so "it compiles" is never implied.

## Keep it in step with the branch

If the branch changes shape after review - a rewritten approach, a dropped file, a rebase that
takes commits with it - update the description too. A description that describes an older version
of the branch is worse than a short one.

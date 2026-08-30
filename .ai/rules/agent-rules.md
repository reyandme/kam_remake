# Agent Rules for AI Assistants

These rules define how AI coding agents should behave when working on this project.

## Core Principles

1. **Understand Before Acting:** Always read the relevant files and understand the existing code structure before making changes. Do not guess or assume APIs exist without verifying them in the source code.
2. **Follow Project Conventions:** Adhere strictly to the coding standards, naming conventions, and style guide defined in this project's `.ai/rules/` directory.
3. **Preserve Determinism:** The game simulation is deterministic for multiplayer and replay support. Never change determinism-affecting logic without explicit approval. Always use the game engine RNG (KaMRandom family) for gameplay randomness.
4. **Test Your Changes:** When making changes, consider the impact on:
   - Savegame serialization (are new fields serialized?)
   - Replay determinism (does the order of operations matter?)
   - Multiplayer sync (will both clients see the same result?)

## Workflow

1. **Analyze:** Read the relevant source files to understand the current implementation.
2. **Plan:** Outline the changes needed and identify potential side effects.
3. **Implement:** Make precise, targeted changes following project conventions.
4. **Verify:** Ensure the code compiles mentally (check types, method signatures, etc.).

This is the per-task loop. The process around it - issues, branch naming, when tests come before
the fix, and the check to run before opening a pull request - is in `workflow.md`.

## When Adding New Features

- Consider savegame serialization immediately when adding new gameplay fields.
- Use the game engine RNG (KaMRandom family) for any randomness in gameplay simulation.
- Route player input through `GameInputProcess`.
- Follow the existing patterns for similar features.

## When Refactoring

- Keep behavior identical unless explicitly told otherwise.
- Update all affected files consistently.
- Do not introduce new bugs while refactoring.

## What review keeps sending back

Collected from review notes on AI-written changes to this repository. None of these are matters of
taste; each one has cost a review round.

- **Do not comment what the code already says.** A line that restates the statement below it gets
  deleted. Comments are for why, and for what is not visible - see `comments.md`.
- **Do not carry unrelated changes.** A readability tidy-up noticed while fixing a bug does not
  belong in that bug's diff, however small. It is its own change or it is nothing.
- **Take the simpler place.** When a guard in one method and one line in a constructor solve the
  same problem, it is the constructor. Look for the fix that removes the condition rather than
  the one that handles it.
- **Put the change where the responsibility is.** If an object needs to tell another object
  something, let it tell it; do not route the news through a third party that then reaches back
  into the first. There is usually a precedent already - find the object that does the same thing
  and follow it.
- **Name things so the line reads on its own**, and prefer the existing name in the codebase over
  a new synonym.
- **When you disagree with a review note, say so and why.** Applying half of it silently is worse
  than either doing it or arguing against it.

## Communication

- Be direct and technical in your responses.
- Explain your reasoning when making non-obvious decisions.
- Point out potential issues or improvements you discover.
- Use the `attempt_completion` tool only when the task is fully complete and verified.

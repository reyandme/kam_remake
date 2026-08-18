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

## Communication

- Be direct and technical in your responses.
- Explain your reasoning when making non-obvious decisions.
- Point out potential issues or improvements you discover.
- Use the `attempt_completion` tool only when the task is fully complete and verified.

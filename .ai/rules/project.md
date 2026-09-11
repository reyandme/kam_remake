# Project Identity

## Project Concept

- Project name is "KaM Remake" (Knights and Merchants Remake).
- This is a remake/mod of the original "Knights and Merchants: The Shattered Kingdom" strategy game.
- Main goal is to keep the original game spirit.
- The Remake uses a custom, open-source engine written from scratch but relies on original KaM resource files.
- Gameplay is relaxed strategy-focused, similar to Settlers 4 in some aspects.
- Development Stage: Mature. Priority is on stability, maintainability, and preserving existing gameplay balance over rapid feature iteration.

## Features

- Single Player missions and campaigns with dynamic scripting support.
- Multiplayer with support for up to 12 players, spectators, map/save transfers in lobby.
- AI opponents (both legacy AI and newAI systems) for scenarios and skirmish maps.
- Online Leaderboard (called "Highscores" in the game code and UI).
- Replay Viewer, so that players can watch their game replay.
- Map Editor, so that players can create their own maps and edit existing ones.
- Dynamic scripting (PascalScript) for deep customization of "special maps".
- Randomly generated maps.
- Modern screen resolution support and zoom in/out.

## Technology

- Main language: Delphi (11 to 13) / Lazarus (FPC). Object Pascal.
- Target platform for main game: 32-bit Windows.
- Target platform for auxiliary tools (e.g. Dedicated Server): Linux x86, Linux x64, Windows.
- Graphics & Rendering: OpenGL with custom engine.
- Networking: TCP via Overbyte ICS.
- Scripting engine: PascalScript.
- Music: libZPlay / OGG Vorbis.
- SFX: OpenAL.
- Memory Management: FastMM4 / FastMM5 (Delphi only).
- Error Handling: madExcept (Delphi Win32 builds).
- Other libraries: zLib, PNGImage.

## Architecture

- Gameplay simulation is Lockstep at 10 ticks per second (100ms per tick).
- Multiplayer works by exchanging player input (commands) via server with each other. Then players perform game simulation. With identical input and full determinism it is guaranteed that the gameplay is identical.
- AI has two systems: legacy AI (`src/ai/`) and newAI (`src/ai/newAI/`). NewAI loosely follows GOAP (Goal-Oriented Action Planning).
- Missions use PascalScript for dynamic scripting.
- Execution Model: Single-threaded main loop. Input -> Simulation Tick -> Rendering. Worker threads used for savegame I/O, asset loading, and other background tasks.
- Rendering: Custom engine using OpenGL.

## Terminology

- "Lockstep" means clients exchange commands, not full game state, during normal Multiplayer simulation.
- "Hand" means players assets during the Gameplay (e.g. units, houses, wares, roads, fields).
- "Dynamic scripting" is PascalScript code written by map makers and executed during missions play.
- "Wares" refers to the resource system (e.g. Wood, Stone, Grain).
- "Tick" is the fundamental unit of simulation time (100ms).
- "Command" is a deterministic input action sent by a player or AI to modify the game state.
- "GIP" stands for GameInputProcess, the single entry point for gameplay input.
- "GIC" stands for Game Input Command.

## References

This document (`project.md`) serves as the root reference for the project. All other rule documents are linked below:

- Project layout is described in `.ai/rules/project-layout.md`.
- Global project rules (Gameplay determinism, savegame logic, and simulation constraints) are described in `.ai/rules/project-rules.md`.
- Coding rules (Language syntax, memory management, and Delphi-specific patterns) are in `.ai/rules/coding-rules.md`.
- Coding style guides (Stylistic preferences) are in `.ai/rules/styleguide.md`.
- Agent operational guidelines are described in `.ai/rules/agent-rules.md`.

# Tools and Utilities Reference

This document describes the purpose, usage, and maintenance of the tools and utilities located in the `.\utils\` directory.

## Overview & Classification

The `utils/` directory contains a wide array of auxiliary projects that support the development, testing, and deployment of KaM Remake.

**Tool Identification:**
The primary identifier for a tool is its name **excluding** any text in parentheses. Information provided in brackets within a folder name (e.g., `(from kp-wiki)`) is strictly metadata for repository management and status tracking.
- It **does not** affect the tool's function, identity, or categorization.
- It **must be ignored** when referring to the tool's name in documentation, discussions, or code.
- Example: A folder named `GameBuilder (from kp-wiki)/` is referred to simply as `GameBuilder`.
Tools whose folder names start with `_` (underscore) are old, moved or obsolete. They should be ignored.

Tools are categorized as follows:

### 1. In-house development tools
Tools used for debugging, visualizing game state, and verifying logic.
- **Visualizers:** `HousePreview`, `uniteditor`.
- **Pathfinding:** `PathFinder` (pathfinding visualization), `RVO2` (Reciprocal Velocity Obstacles collision avoidance).
- **Animation:** `AnimInterp` (animation interpolation tool).

### 2. Simulation and automated testing
Tools for running automated game scenarios and balance analysis.
- **Simulation Runner:** `Runner` (automated gameplay runner with genetic algorithm support via `GeneticAlgorithm.pas`).
- **Parallel Execution:** `RunnerParallelExtension` (enables parallel execution of Runner instances).
- **Game Logic Tests:** `Testing_GameTests` (targeted game logic tests for buildings, units, production chains).

### 3. Unit testing
Dedicated projects for verifying code correctness.
- **Unit Tests:** `UnitTests` (DUnit-based unit tests for common utilities, classes, and core systems).

How to write and run either of the two test projects is covered in `testing.md`.

### 4. Server and multiplayer infrastructure
Tools for managing the online experience and hosting games.
- **Hosting:** `DedicatedServer` (Target: Windows, Linux x86 and Linux x64).
- **Server GUI:** `DedicatedServerGUI` (graphical interface for managing dedicated servers).
- **Central server:** `MasterServer` (PHP-based master server for game server listing, statistics, and announcements).
- **Monitoring:** `Server Poller` (server status polling and monitoring tool).

### 5. Asset pipeline and conversion
Tools for creating and preparing raw assets for use in the game engine.
- **Fonts:** `FontX Generator`, `FontX Editor`, `FontX Collator`.
- **Tiles:** `TileEditor`, `TileResampler`.
- **Data Packaging:** `RXXPacker` (packs game data into .rxx archives), `RXXEditor`.
- **LIB files:** `LIB Decoder`, `LIB Opener`.
- **One-time jobs:** `Batcher`.

### 6. Automated game build tools
Tools for making a game build and processing source code.
- **Building:** `GameBuilder` (from kp-wiki).
- **Scripting synchronization:** `ScriptParser` (from kp-wiki).

### 7. Map and campaign tools
Tools for creating and editing game content.
- **Maps:** `MapUtil`.
- **Campaigns:** `Campaign builder`.

### 8. Proof-of-concept and experimental tools
- **Geometry:** `Delanay Triangulation`.
- **Dependencies analysis:** `DependenciesGrapher` (visualizes project unit dependencies as GraphML).
- **Network testing:** `Network Test`, `Network TestTCP`.
- **HTTP testing:** `HTTPTest`.
- **Video playback:** `DS video playback`, `AVIPlayer`.

### 9. Public tools
Auxiliary tools that are built and distributed with the game to help players use and mod the game.
- **Script validation:** `ScriptValidator`.
- **Localization:** `TranslationManager` (from kp-wiki).
- **Scripting samples:** `Scripting` (PascalScript and DWScript test projects for map makers).

## Status matrix

| Status | Folder Name Pattern | Description | Examples |
| :--- | :--- | :--- | :--- |
| **Active** | `ToolName/` | Currently maintained and used in development. | `Runner/`, `DedicatedServer/` |
| **Submodule** | `ToolName (from source)/` | Tool is imported from external repo (kp-wiki). | `GameBuilder (from kp-wiki)/`, `ScriptParser (from kp-wiki)/` |
| **Obsolete** | `_ToolName (reason)/` | No longer used or replaced. | `_BugParser (moved to CrashReporter repo)/`, `_FontEditor (deprecated)/` |

## Tool-specific guidelines

### Runner suite
The `Runner` tools are used for automated gameplay testing and balance insights.
- `Runner`: The main runner that executes game scenarios, optionally driven by genetic algorithms.
- `RunnerParallelExtension`: Extension enabling parallel execution of multiple Runner instances.

### Preview tools
`HousePreview` and `uniteditor` are standalone applications that render specific game elements in isolation for debugging and design purposes.

## Maintenance and lifecycle

- **Adding Tools:** New tools should be placed in `utils/` and categorized in this document.
- **Deprecation:** When a tool is no longer needed, rename the folder with a leading underscore (e.g., `ToolName` -> `_ToolName`).
- **Externalization:** If a tool moves to a separate repository (like the kp-wiki repo), update the folder name to indicate that it is imported (e.g., `ToolName` -> `ToolName (from kp-wiki)`).

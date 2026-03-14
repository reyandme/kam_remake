# CLAUDE.md — KaM Remake Project Reference

## Project Overview

KaM Remake is an open-source remake of "Knights and Merchants: The Shattered Kingdom" — a medieval real-time strategy game. The project modernizes the original with multiplayer (up to 12 players), improved AI, scripting support, and modern resolution/zoom.

- **Language:** Object Pascal (Delphi / Free Pascal)
- **Platforms:** Windows (primary), Linux (dedicated server + Lazarus builds)
- **Graphics:** OpenGL 1.5+
- **Audio:** OpenAL, Ogg Vorbis, libZPlay
- **Networking:** Overbyte ICS (TCP, port 56789)
- **Scripting:** PascalScript (embedded scripting engine)
- **Website:** https://www.kamremake.com
- **Discord:** https://discord.gg/UkkYceR

## Repository Structure

```
/                        Root — build files, DLLs, compiler config
├── src/                 Main source code (680+ Pascal files)
│   ├── ai/              AI systems (classic + advanced/newAI)
│   ├── common/          Shared types, defaults, utilities
│   ├── controls/        GUI controls framework
│   ├── ext/             External libraries (PascalScript, ICS, FastMM, OpenGL, OpenAL)
│   ├── forms/           VCL/LCL form definitions
│   ├── game/            Core game engine and logic
│   ├── gui/             In-game UI and menus
│   ├── hands/           Player/hand management (units, buildings, deliveries, stats)
│   ├── houses/          Building/house implementations
│   ├── maped/           Map editor functionality
│   ├── media/           Sound and video playback
│   ├── minimap/         Minimap rendering
│   ├── mission/         Campaign and map loading
│   ├── navmesh/         Navigation mesh for AI pathfinding
│   ├── net/             Multiplayer networking (client/server)
│   ├── pathfinding/     Pathfinding algorithms
│   ├── perflog/         Performance logging
│   ├── render/          OpenGL rendering engine
│   ├── res/             Resource management (sprites, fonts, wares, units, houses)
│   ├── scripting/       Scripting engine (actions, events, states)
│   ├── settings/        Game settings
│   ├── terrain/         Terrain and tile system
│   ├── units/           Unit and warrior systems with actions/tasks
│   └── utils/           General utility functions
├── data/                Game data (cursors, fonts, text, tile definitions, locales)
├── Docs/                Documentation, getting-started guides, scripting tutorials
├── Utils/               24+ utility projects (dedicated server, map editor, font tools, etc.)
├── bat/                 Windows build batch scripts
├── Installer/           Inno Setup installer scripts
├── Sounds/              Audio resources (Buildings, Chat, Misc, UI)
└── Modding graphics/    Modding resources
```

## Building the Project

### Prerequisites
- **Delphi:** XE2 through Delphi 12 Yukon (Windows)
- **Lazarus/FPC:** Free Pascal 3.2.0+ with Lazarus IDE (cross-platform)
- Original KaM game files (installer checks for them)

### Delphi (Windows)
```bash
cd bat
build_exe.bat          # Main executable
build_utils.bat        # Utility tools
build_all.bat          # Everything
build_linux_servers.bat # Linux dedicated server (cross-compile)
```
- Project file: `KaM_Remake.dproj`
- Project group: `KaMProjectGroup.groupproj` (24 sub-projects)

### Lazarus/FPC
- Open `KaM_Remake.lpi` in Lazarus IDE and build
- Or compile via FPC command line

### Build Configurations
- **Release** — optimized for distribution
- **Debug** — development with debug info
- **DebugAQ** — debug with async queries
- **DebugAI** — debug with AI diagnostics

### Compiler Defines (`KaM_Remake.inc`)
- `WDC` — Windows Delphi Compiler (auto-detected per version)
- `FPC` — Free Pascal Compiler (auto-defined by Lazarus)
- `USE_MAD_EXCEPT` — exception reporting (Delphi only)
- `VIDEOS` — video playback support (Delphi 32-bit only)
- `LOAD_GAME_RES_ASYNC` — async resource loading
- `DBG_PERFLOG` — performance logging (disable for release)
- `USE_VIRTUAL_TREEVIEW` — VirtualTreeView component (Delphi only)

## Architecture Overview

### Core Game Loop
`KM_Game.pas` — Main game session manager. Handles game state, update/render ticks, saving/loading, speed control, replay system, and scripting engine integration.

### Game Modes
`gmSingle`, `gmCampaign`, `gmMulti`, `gmMapEd`, `gmReplaySingle`, `gmReplayMulti`

### Player System (Hands)
Each player is a **TKMHand** (`src/hands/KM_Hand.pas`):
- Owns units, houses, unit groups
- Has AI controller, delivery logistics, construction planner
- Fog of war, alliances, shared vision
- Up to 12 players (TKMHandID 0-11)
- Hand types: human, AI, spectator

### Input System
Game Input Process (GIP) — deterministic command system for multiplayer sync. All player actions go through GIP commands to ensure identical simulation across clients.

## Key Game Systems

### Units (`src/units/`)
Base class: **TKMUnit** → specialized into workers and warriors

**Workers (citizens):**
`utSerf`, `utWoodcutter`, `utMiner`, `utAnimalBreeder`, `utFarmer`, `utCarpenter`, `utBaker`, `utButcher`, `utFisher`, `utBuilder`, `utStonemason`, `utSmith`, `utMetallurgist`, `utRecruit`

**Warriors:**
`utMilitia`, `utAxeFighter`, `utSwordFighter`, `utBowman`, `utCrossbowman`, `utLanceCarrier`, `utPikeman`, `utScout`, `utKnight`

**Town Hall units:** `utBarbarian`, `utRebel`, `utRogue`, `utWarrior`, `utVagabond`

**Animals:** `utWolf`, `utFish`, `utWatersnake`, `utSeastar`, `utCrab`, `utDuck`

Units have **Tasks** (high-level goals like mining, delivering, building) and **Actions** (animations like walking, working, dying).

### Houses/Buildings (`src/houses/`)
Base class: **TKMHouse** — 30 building types including:
- Production: `htFarm`, `htMill`, `htBakery`, `htSawmill`, `htIronSmithy`, etc.
- Military: `htBarracks`, `htSchool`, `htTownHall`, `htSiegeWorkshop`, `htWatchTower`
- Storage: `htStore`, `htInn`, `htMarket`
- Resource: `htCoalMine`, `htIronMine`, `htGoldMine`, `htQuarry`, `htWoodcutters`

### Wares/Resources (`src/res/KM_ResWares.pas`)
28 ware types organized as:
- **Raw:** trunk, stone, iron ore, gold ore, coal, corn, wine, pig, fish
- **Processed:** timber, iron, gold, bread, flour, leather, sausage, skin
- **Weapons/Armor:** wooden shield, iron shield, leather armor, iron armor, axe, sword, lance, pike, bow, crossbow
- **Special:** horse (for mounted units)

Market system with pricing multipliers and trade ratios.

### AI System (`src/ai/`)
Two parallel AI implementations:
- **Classic AI:** Mayor (city planning) + General (military strategy)
- **Advanced AI (newAI):** Modular system with NavMesh-based pathfinding, influence maps, defense perimeters, and vector fields for combat

AI types: `aitNone`, `aitClassic`, `aitAdvanced`

### Scripting System (`src/scripting/`)
PascalScript-based engine enabling custom map logic:
- **Actions** (`KM_ScriptingActions.pas`) — commands to modify game state
- **States** (`KM_ScriptingStates.pas`) — queries to read game state
- **Events** (`KM_ScriptingEvents.pas`) — callbacks for game events
- **Console Commands** (`KM_ScriptingConsoleCommands.pas`) — debug/admin commands
- Supports preprocessor directives (`{$I include}`, `{$DEFINE}`)

### Map System (`src/mission/`)
- `.map` files — binary terrain data
- `.dat` files — ASCII mission setup (player positions, buildings, units)
- `.script` files — PascalScript mission logic
- Maps repository: https://github.com/reyandme/kam_remake_maps
- Map editor integrated in-game and as utility tool

### Terrain (`src/terrain/`)
- Tile-based terrain with heightmaps
- Procedural map generation support
- Terrain types affect gameplay (passability, resource placement)

### Networking (`src/net/`)
- TCP-based client/server architecture
- Deterministic lockstep simulation
- Server acts as packet hub (no gameplay logic on server)
- Dedicated server available for 24/7 hosting

## Key File Quick Reference

| Purpose | File |
|---------|------|
| Main game session | `src/game/KM_Game.pas` |
| Game types/modes | `src/game/KM_GameTypes.pas` |
| Base unit class | `src/units/KM_Units.pas` |
| Warrior units | `src/units/KM_UnitWarrior.pas` |
| Unit groups | `src/units/KM_UnitGroup.pas` |
| Base house class | `src/houses/KM_Houses.pas` |
| Player/hand | `src/hands/KM_Hand.pas` |
| All players | `src/hands/KM_HandsCollection.pas` |
| Delivery logistics | `src/hands/KM_HandLogistics.pas` |
| Unit specs/stats | `src/res/KM_ResUnits.pas` |
| House specs/costs | `src/res/KM_ResHouses.pas` |
| Ware specs/prices | `src/res/KM_ResWares.pas` |
| Common types | `src/common/KM_CommonTypes.pas` |
| Game defaults | `src/common/KM_Defaults.pas` |
| Terrain system | `src/terrain/KM_Terrain.pas` |
| AI controller | `src/ai/KM_AI.pas` |
| Scripting engine | `src/scripting/KM_Scripting.pas` |
| Map handling | `src/mission/KM_Maps.pas` |
| Mission scripts | `src/mission/KM_MissionScript_Standard.pas` |
| Campaign system | `src/mission/KM_Campaigns.pas` |
| Compiler defines | `KaM_Remake.inc` |
| Text IDs | `KM_TextIDs.inc` |

## Testing

### Unit Tests
- Location: `Utils/UnitTests/`
- Project: `UnitTests.dproj`
- Tests: `TestKM_CommonClasses.pas`, `TestKM_Points.pas`, `TestKM_CommonUtils.pas`, `TestKM_Utils.pas`

### Functional Tests
- Location: `Utils/_TestFunctional/`
- Project: `KaM_RemakeTestFunc.dproj`
- Tests: `TestKM_Terrain.pas`, `TestKM_Scripting.pas`, `TestKM_MissionScript.pas`, `TestKM_AIFields.pas`

## Coding Conventions

- **Class prefix:** `TKM` (e.g., `TKMUnit`, `TKMHouse`, `TKMHand`)
- **File prefix:** `KM_` (e.g., `KM_Units.pas`, `KM_Houses.pas`)
- **Enum prefixes:** `ut` (unit type), `ht` (house type), `wt` (ware type), `gm` (game mode), `ait` (AI type)
- **Collections:** typically named `TKM<Entity>Collection` or `TKM<Entity>s`
- **Specs/Data:** `TKM<Entity>Spec` classes in `KM_Res<Entity>.pas` files
- **Tasks/Actions:** Unit behavior split into `TKMUnitTask` (goal) and `TKMUnitAction` (animation)
- **Pascal style:** Begin/End blocks, PascalCase for types and methods, `f` prefix for private fields

## Localization

28 languages supported via `.libx` binary text files in `data/text/`.
Locale config in `data/locales.txt`. Text IDs defined in `KM_TextIDs.inc`.

## Useful Utilities

| Tool | Location | Purpose |
|------|----------|---------|
| Dedicated Server | `Utils/DedicatedServer/` | 24/7 multiplayer server |
| Map Editor | In-game + `Utils/_KaM Editor/` | Create custom maps |
| Campaign Builder | `Utils/Campaign builder/` | Build campaigns |
| RXX Editor/Packer | `Utils/RXXEditor/`, `Utils/RXXPacker/` | Sprite resource files |
| Font Tools | `Utils/FontX Editor/` | Font editing |
| Script Validator | `Utils/ScriptValidator/` | Validate map scripts |
| Tile Editor | `Utils/TileEditor/` | Edit tilesets |

# Project Rules

## World Representation
- The game world is based on a grid.
- The game simulation is purely 2D.
- The primary coordinate units are game tiles.

## Determinism

### Deterministic simulation boundary

Gameplay simulation means any code that can affect the authoritative game state used by Multiplayer, Replays, or Savegames. This includes, but is not limited to:
- Unit, house, ware, terrain, player, AI, economy, combat, pathfinding, fog-of-war, scripting, mission logic, and command execution.
- Any code executed from the game tick/update loop.
- Any code that changes fields serialized into savegames.
- Any code whose result can later influence gameplay decisions.

Non-gameplay code includes only presentation or tooling code that cannot affect gameplay state, such as rendering, UI layout, sound playback, logging, diagnostics, editor-only tools, and visual effects, unless their result is fed back into the simulation.

When unsure, treat code as gameplay simulation code.

### Deterministic rules

- Gameplay simulation logic must remain deterministic.
- Do not change savegame/replay/network determinism without explicit approval.
- The game must use its own deterministic RNG, accessible via `gRandom`, for all gameplay simulation logic.
- System random is only allowed for non-gameplay things.
- Gameplay `gRandom` should not be used for non-gameplay things.
- Gameplay should behave exactly the same regardless of GFX and SFX settings (even in headless mode or without a soundcard detected).
- Gameplay simulation must not rely on unordered or unspecified execution order. All ordering that can affect gameplay must be explicit and deterministic.
- Gameplay simulation must not depend on memory addresses, pointer values, object allocation order, hash randomization, container bucket order, or unstable sorting.
- Do not depend on real time, frame time, render state, UI state, sound state, player camera position, machine performance, or thread scheduling for gameplay.
- Changes to gameplay assets/specs/scripts must be treated as determinism-affecting changes.
- Presentation Side-Effects: Direct calls to presentation systems (SFX, VFX, UI) from within the simulation are permitted, provided they are strictly "fire-and-forget." These calls must not:
  1. Mutate any gameplay state (including fields used for serialization or logic).
  2. Return values that are used to influence simulation logic.
  3. Trigger any logic that could eventually feed back into the simulation (e.g., a UI callback that modifies a unit's state without going through GameInputProcess).

- Players input during gameplay should go through GameInputProcess, so that it can be recorded for the Replays and relayed to other players in Multiplayer.
- `GameInputProcess` should be the single entry point for all gameplay input.
- AI planning and action selection are gameplay simulation logic, so they must be deterministic, use `gRandom` only, serialize all relevant state.
- It is not needed to route AI player-equivalent commands through `GameInputProcess`, since AI behavior is expected to be fully deterministic.
- Map Editor is often allowed to edit gameplay elements state directly, for simplicity. It is important to guard those places from being used in Gameplay by accident.
- Debug, logging, metrics, assertions, or diagnostics must not mutate gameplay state.

### Determinism & Math

- Primary Type: All gameplay simulation calculations must use integers (e.g. `Byte`, `ShortInt`, `Word`, `Integer`, etc.) or 32-bit floats (only `Single` is allowed). Do not use `Double`, `Real` or `Extended` to prevent precision mismatches. Do not use `Currency` either.
- Consistency: Since the project relies on floating-point determinism on Windows, it is critical that the same sequence of operations is performed on all clients. Avoid logic that might lead to different calculation paths for the same result, as this can cause divergent float values.
- Comparison: Equality checks (`=`, `<>`) are permitted for `Single` values when they result from identical calculation paths. Do not use `Epsilon` unless it is actually needed.
- Rounding: Standard Delphi `Round`, `Trunc` are used for converting values to integers. `Ceil` is also available.
- Library Usage: Use `KM_Math` or `KM_CommonUtils` for common math and utility operations.

### Threading and Execution Model

- Game simulation must be single-threaded. Multithreading is allowed for systems that do not affect game simulation (e.g. asset loading, compressing and saving data to filesystem, etc.). In the future, some game simulation tasks could be performed in background threads provided they guarantee deterministic results in deterministic time.
- UI and game simulation are both performed in the main thread, executed sequentially.
- Worker threads (`KM_WorkerThread`) are used for savegame I/O operations (saves, autosaves, base saves, savepoints).

## Savegame and Progress serialization

- Game Savegames: Tied to the game build number. This means savegames are incompatible between different builds, which simplifies development by removing the need for complex backward compatibility logic.
- Campaign Progress: Must be version-independent and compatible between different builds. This meta-state (e.g. unlocked missions, campaign script state) must be handled with backward compatibility in mind.
- Savegames must include the whole gameplay state.
- Serialization and deserialization must be symmetrical.
- Savegames must not store raw pointers, object addresses, transient handles, thread IDs, UI state, or platform-specific handles as gameplay state.
- Entity references must be serialized by UIDs and relinked after load.
- After loading a savegame, the resulting gameplay state must be equivalent to the original state, including hidden/internal state that can affect future gameplay.
- Do not add non-serialized gameplay-affecting defaults during load unless they are deterministically derived from serialized data.
- Any newly added gameplay field must be considered for savegame serialization, replay determinism, and multiplayer determinism at the time it is added.

## Common Sources of Hard-to-Track Bugs & Mitigations

### Serialization & State Management
- **Incomplete serialization:** Failing to serialize all gameplay-affecting fields causes divergent initial states in replays and multiplayer.
  - *Rule:* Treat every new gameplay field as requiring immediate serialization, replay consideration, and network sync. Verify save/load symmetry regularly.
- **Uninitialized state:** Local variables or object fields left uninitialized can cause silent divergence across machines.
  - *Rule:* Always explicitly initialize local variables. Ensure deserialization fully reconstructs all simulation state without relying on implicit defaults.

### Input & Command Flow
- **Bypassing input recording:** Modifying game state directly instead of routing through `GameInputProcess` breaks replay determinism and multiplayer sync.
  - *Rule:* All player input must pass through `GameInputProcess`. AI commands are exempt but must remain fully deterministic.
- **Out-of-order / lost commands:** Multiplayer desyncs occur when command execution order differs or packets are dropped mid-game.
  - *Rule:* Maintain strict command sequencing and implement robust catch-up/resync logic for disconnected players.

### Randomness & Hidden Dependencies
- **Silent RNG consumption:** Skipping `gRandom` calls (e.g., when sound is off) desynchronizes the RNG sequence for subsequent gameplay events.
  - *Rule:* Always consume `gRandom` in the exact same order, regardless of GFX/SFX settings or visual/audio output.
- **Camera & presentation bleed:** Relying on camera position, frame time, or render state to trigger simulation updates (e.g., fog-of-war chunk loading) causes machine-dependent behavior.
  - *Rule:* Decouple simulation triggers from presentation state. Use fixed tick-based or event-driven updates independent of the viewport.

### Data Structures & Ordering
- **Unordered containers:** `TDictionary` enumeration order depends on hash randomization and pointer values, leading to non-deterministic processing sequences.
  - *Rule:* Never rely on implicit iteration order for gameplay logic. Use `TList<>`, sorted arrays, or explicitly ordered structures when sequence matters.

### Environment & Assets
- **Floating-point environment drift:** Third-party libraries altering the FPU control word (e.g., precision/rounding modes) causes math divergence.
  - *Rule:* Lock and verify the FPU control word at startup. Isolate third-party math from core simulation code.
- **Asset/spec mismatches:** Silent differences in gameplay data files across clients break determinism.
  - *Rule:* Version-lock all gameplay assets and implement checksum validation for critical specs during multiplayer sessions.

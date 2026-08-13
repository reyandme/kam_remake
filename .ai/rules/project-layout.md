# Project Layout

## Repository Layout

- Main game source code is in the `.\src\` and subfolders.
- The game uses own UI controls that live in: `.\src\controls\`.
- The game GUI lives in: `.\src\gui\`.
- Third-party libraries are in `.\src\ext\`.
- Utility tools are in the `.\utils\`. It contains a diverse collection of tools and utilities designed for the game development, debugging, testing, localization and other specialized tasks. They are aimed to enhance the quality of the game being developed. Some of the tools are shipped with the game, but the majority is for the in-house use.

## File & Unit Organization

- Prefer one primary class per file.
- File name should match class name:
  - `KM_Log.pas` - `TKMLog`
  - `KM_AINavMesh.pas` - `TKMAINavMesh`
- All project unit files must use `KM_` prefix (except for third-party).
- Every unit (except third-party) must include compiler directives on line 2:
  - `{$I KaM_Remake.inc}`.
  - or relative path equivalent (e.g. `{$I ../KaM_Remake.inc}`).
- Ignore files in the `__history` folders, they are backups saved by Delphi IDE and are not representative of project history.

## Specific units

- `KM_Log` is a global game logger, accessible via `gLog`. Some utils use it too.
- `KM_Defaults` contains default constants and configuration values used across the project.
- `KM_CommonTypes` defines shared type aliases, event types, and array types.
- `KM_Game` (`src/game/KM_Game.pas`) is the central game session manager class `TKMGame`.
- `KM_GameApp` (`src/KM_GameApp.pas`) is the high-level application controller `TKMGameApp`.
- `KM_Main` (`src/KM_Main.pas`) provides the main loop and window management via `TKMMain`.

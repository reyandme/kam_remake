# Project Coding Standards

## General Rules

- IMPORTANT! Accessing an array of arrays DOES NOT require separate brackets `[][]`. A comma-separated list `[,]` is a valid syntax.
- Avoid pseudo-code; produce compilable code, unless asked.
- Prefer conceptual clarity and long-term maintainability.
- Prefer to follow Single Responsibility Principle.
- Do not do premature optimizations.
- Do not overuse patterns.
- Do not use interface. 
- Rely more on composition rather than deep inheritance chains.
- Ensure all methods have clear, concise logic.
- Use descriptive names to improve readability of variables, classes, records and arguments.
- Never use C-style syntax.
- Do not review or edit third-party code unless specifically asked to do so.
- Avoid using class helpers and record helpers, they reduce clarity of the code.

## Delphi language rules

- Always generate valid modern Delphi/Object Pascal syntax. Code must compile in Delphi 11+ and Lazarus/FPC.
- Prefer modern Delphi syntax and constructs when applicable (e.g. generics, short exits, inline variables, record operators).
- Remember that Delphi is case-insensitive to variable names and type names.
- Unlike many languages, Delphi uses inverse order of RGBA components when they are written as hex. (e.g. `$80FF0000` is a half-transparent Blue, `$00FFFF` is a Yellow).
- Note that division in Delphi is always performed in floating point and result is promoted to floating point. (e.g. `5 / 2` automatically produces `2.5`).
- Do not use `asm` inserts.
- Do not use manual memory management.
- Using pointers and pointer math is okay in some performance-critical places.
- Instance methods work fine on `nil` as long as they don't dereference `Self`.

## Compiler Directives

- Every project unit must include compiler directives on line 2:
  - `{$I KaM_Remake.inc}` — for units in the `src/` root.
  - or relative path equivalent (e.g. `{$I ../KaM_Remake.inc}`) for units in subdirectories.
- Common compiler defines (defined in `KaM_Remake.inc`):
  - `WDC` — Windows Delphi Compiler.
  - `FPC` — Free Pascal Compiler (Lazarus).
  - `MSWindows` / `Unix` — Platform-specific.
  - `USE_MAD_EXCEPT` — madExcept crash reporting enabled.
  - `DBG_PERFLOG` — Performance logging enabled.
  - `DBG_RNG_SPY` — RNG validation checks enabled.

## Error handling

- Prefer to use `try..finally` for memory management, but it is not critical. Sometimes simpler and shorter code is okay.
- Use `try..except` for error handling.
- `FreeAndNil` objects after their lifetime end, especially long-living ones.
- Never swallow exceptions silently, unless it is harmless (e.g. when doing retries in I/O operations).
- Avoid using exceptions for control flow.

## Comments

- Complex logic must be explained.
- Comments should explain WHY something is done, rather than HOW.
- Explanatory comments are allowed but avoid trivial explanations.
- Sometimes complex algorithms could need a small ASCII illustration to better explain them.
- No XML documentation is necessary.
- Documentation blocks are not necessary (unless specifically called for).

## Code generation / Refactoring constraints

- When given partial code: infer missing types carefully.
- Do not invent APIs unless clearly required.
- When refactoring: keep behavior identical unless explicitly told otherwise.

## Uses clause ordering

- Units listed in the `uses` sections should loosely follow this order:
  1. RTL and System units (E.g. `System.Classes`, `System.Hash`).
  2. VCL / WinAPI units (E.g. `Vcl.Forms`, `WinApi.Windows`).
  3. Third-party units (E.g. `OverbyteIcs`, `madExcept`, PascalScript).
  4. Common project units (E.g. `KM_CommonTypes`, `KM_Defaults`, `KM_Colors`).
  5. Common controls units used in game UI (E.g. `KM_Controls`, `KM_ControlsMemo`).
  6. Remaining game-specific units.

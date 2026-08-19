# Style & Formatting

## Naming Conventions

- Use PascalCase for method names (e.g. `GetCount`, `Render`, `UpdateState`, `LoadFromFile`).
- Use camelCase for local variables (e.g. `thisItem`, `wareSpec`, `filename`, `dx`).
- Loop variables may be one-letter uppercase (`I`, `J`, `K`, etc.).
- Method arguments must use prefix `a`.
- Private class fields must use prefix `f`.
- Global variables must use prefix `g`.
- All non-library enum type, class and record names must have prefix `TKM`.
- Constants must be UPPER_CASE (e.g. `MAX_HANDS`, `PI`).
- Do not use abbreviations unless universally understood (`id`, `url`, `html` allowed).
- Enum values use PascalCase with 2-letter prefix:
  - Example: `TKMAlignText = (atLeft, atCenter, atRight)`
- Reserve first enum value for undefined state:
  - Example: `osUndefined`
- Boolean variables must read as predicates (`isValid`, `hasAccess`, `canExecute`).
- Checking object variables for having a value is done via comparison with `nil` for brevity (e.g. `if aUnit <> nil then` instead of `if Assigned(aUnit) then`).
- Prefer to use `FreeAndNil` to release the objects.

## Formatting Rules

- Indentation: 2 spaces.
- Maximum line length: ~180 characters.
- Leave 2 empty lines between methods in implementation section.
- Linebreaks must be Windows style (CRLF).
- Put space after commas and around operators.
- `begin` should be on a new line unless following `else`.
- when dealing with lengthy `if` statements, carry over to the next line and keep the padding on the same level
  ```
    if Something
    or SomethingElse
    or SomeOtherThing then
  ```
- use padding only for the most complex `if` statement with nested conditions:
  ```
  if aDemand.TgtIsHouse
  and aDemand.ToHouse.IsComplete
  and (
    // Spacious houses have individual ware blocks
    (gRes.Houses[aDemand.ToHouse.HouseType].IsSpacious and (aDemand.ToHouse.WareBlock2(aOffer.Ware) <> wbAllow))
    or
    // Common houses have shared ware block
    (not gRes.Houses[aDemand.ToHouse.HouseType].IsSpacious and (aDemand.ToHouse.WaresBlockAll <> wbAllow))
  ) then
  ```

## Readability Practices

- Prefer early returns (guard clauses) to reduce nesting.
- Avoid wrapping logic in unnecessary `else` blocks after a return.

## No Magic Numbers

- Do not use numeric literals directly in logic without a named constant.
- Exceptions: `0`, `1`, `-1`, and common HTTP codes (200, 404, 500).

## Language

- Use American English for naming and comments.

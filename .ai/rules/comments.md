# Commenting Style Guide

This document defines the personality, tone, and structural rules for writing comments in the KaM Remake project. The goal is to maintain a pragmatic, engineering-focused documentation style that prioritizes intent and justification over literal description.

## General Philosophy
Comments should not repeat what the code says. If a method is named `GetNewUID`, a comment saying `// Returns a new UID` is redundant. Instead, comments should explain the "Why", the "Intent", and the "Gotchas".

## Tone and Personality
- **Pragmatic & Direct:** Be concise. Use a professional yet conversational engineering tone.
- **Justification-Driven:** When a specific constant, algorithm, or data type is chosen, explain the reasoning (e.g., "Prime numbers let us generate sequence of non-repeating values").
- **Transparent:** It is okay to express a design trade-off or a "thinking-out-loud" moment (e.g., using a question mark to highlight a potential edge case).
- **Trade-off Transparent:** When a decision is made for a specific reason (e.g., convenience or legacy support), acknowledge the trade-off or the "cost" of that decision (e.g., "Note that generally Strings are faster than AnsiStrings").
- **Empirical:** When possible, back up performance-related decisions with data (e.g., "NoCompression - 11ms, Fast - 66ms").

## What to Comment

### 1. The "Why" and "Intent"
Explain the purpose of a block of code, especially if it's not immediately obvious from the function name.
- **Bad:** `// Increment pointer count`
- **Good:** `// This check allows us to save on each caller checking for Entity <> nil`

### 2. Technical Justifications
Explain why a specific approach was taken over another.
- Mention constraints (e.g., "fit within 24bit so we can use it for RGB colorcoding").
- Mention future-proofing (e.g., "Use common compressor for uniformity... could be used standalone").

### 3. Gotchas and Edge Cases
Explicitly warn about pitfalls or specific behaviors of third-party APIs.
- Example: `// Copy to Tmp stream exact amount of data, otherwise decompressor adds garbage after Eof`

### 4. System Context
Reference other parts of the system to provide a complete picture of the data flow.
- Example: `// scBase comes already compressed (we compressed it right after creation in gGame)`

## Structural Rules

### Simple Steps
For sequential logic, use short, one-line descriptions of the step.
- `// Rollback`
- `// Rewind back to TOC and fill it`

### Complex Properties/Rules
When explaining a set of rules or properties, use a bulleted list format:
```pascal
// UIDs have the following properties:
// - allow const UID_NONE = 0 to indicate no UID
// - fit within 24bit (used for RGB colorcoding)
// - Start from 1 to avoid black colorcode detection issues
```

### Todo Format
Follow the established project todo format:
`//todo -category: Description`
- Example: `//todo -cComplicated: Resolve TDictionary items order consistency.`

Common categories:
- `-cComplicated`: Complex refactoring or architectural issues requiring careful thought.
- `-cPractical`: Practical improvements, code cleanup, straightforward optimizations.
- `-cThink`: Ideas worth considering but not yet decided upon.

## Summary Checklist
Before writing a comment, ask:
1. Does this comment tell me something the code doesn't already say?
2. Does this explain *why* I did this or *what* I was thinking?
3. If I come back in 6 months, will this explain the "trap" I avoided here?

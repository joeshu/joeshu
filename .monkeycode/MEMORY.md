# User Instruction Memory

This file records user instructions, preferences, and teachings for reference in future interactions.

## Format

### User Instruction Entry
User instruction entries should follow this format:

[User Instruction Summary]
- Date: [YYYY-MM-DD]
- Context: [Mentioned scenario or time]
- Instructions:
  - [Content of user teaching or instruction, described line by line]

### Project Knowledge Entry
Entries discovered by the Agent during task execution should follow this format:

[Project Knowledge Summary]
- Date: [YYYY-MM-DD]
- Context: Discovered by Agent while performing [specific task description]
- Category: [Operations & Deployment|Build Methods|Testing Methods|Troubleshooting & Debugging|Workflow & Collaboration|Environment Configuration]
- Instructions:
  - [Specific knowledge points, described line by line]

## Deduplication Strategy
- Before adding a new entry, check for similar or identical instructions.
- If a duplicate is found, skip the new entry or merge it with the existing one.
- When merging, update the context or date information.
- This helps avoid redundant entries and keeps the memory file tidy.

## Entries

[Project Knowledge Summary]
- Date: 2026-08-14
- Context: Discovered by Agent while performing the calendar-quadrant-home feature implementation
- Category: Build Methods
- Instructions:
  - Local environment has no `xcodebuild`; iOS compilation can only be verified via GitHub Actions workflow `PaperTodo iOS Build` (approx 1-1.5 min) after pushing to `main`.
  - Feature work follows `.monkeycode/specs/{FEATURE}/tasklist.md`; tasks marked with `*` are test tasks and are skipped, only development tasks are implemented.

[Project Knowledge Summary]
- Date: 2026-08-14
- Context: Discovered by Agent while performing the calendar-quadrant-home feature implementation
- Category: Workflow & Collaboration
- Instructions:
  - Before committing, run `git diff --check`; after pushing, verify CI runs (`PaperTodo iOS Build`, `Build and Deploy`) with `gh run list` / `gh run watch` before marking tasks complete in the tasklist.

[User Instruction Summary]
- Date: 2026-08-15
- Context: Calendar optimization implementation workflow
- Instructions:
  - Execute the calendar implementation plan in batches, verify each batch, push each completed batch to Git, and report after the full checklist is completed.

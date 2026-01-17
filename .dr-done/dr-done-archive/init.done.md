# Workstream: dr-done-archive

## Goal

Create a `/dr-done:archive <workstream>` command that moves completed workstreams to `.dr-done/.archive/` for cleaner organization.

## Context

As workstreams are completed, the `.dr-done/` directory can become cluttered with old workstreams. An archive command provides a clean way to preserve completed work while keeping the active workspace tidy.

The archive directory uses a leading dot (`.archive`) so it sorts to the top of directory listings and is clearly distinguished from active workstreams.

## Requirements

- Command syntax: `/dr-done:archive <workstream-slug>`
- Move the entire workstream directory from `.dr-done/<workstream>/` to `.dr-done/.archive/<workstream>/`
- Create `.dr-done/.archive/` if it doesn't exist
- Verify the workstream exists before attempting to move
- Warn (but don't block) if there are incomplete tasks (files not ending in `.done.md` or `.stuck.md`)
- Confirm success to the user

## Non-Goals

- Automatic archiving (this is a manual command)
- Restoring archived workstreams (can be done manually with `mv`)
- Deleting workstreams

## Implementation

### 1. Create the command file

Create `plugins/dr-done/commands/archive.md` with:

````markdown
# /dr-done:archive

Archive a completed dr-done workstream.

## Usage

/dr-done:archive <workstream-slug>

- `workstream-slug`: The name of the workstream directory in `.dr-done/` to archive

## Instructions

When the user invokes this command:

1. Validate the workstream exists:
   - Check if `.dr-done/<workstream-slug>/` exists
   - If not, inform the user and stop

2. Check for incomplete tasks:
   - Look for any `.md` files in the workstream directory that don't end with `.done.md` or `.stuck.md`
   - If found, warn the user: "Note: This workstream has incomplete tasks: <list of files>"
   - Continue with archiving (this is a warning, not a blocker)

3. Create archive directory if needed:
   ```bash
   mkdir -p .dr-done/.archive
   ```
````

4. Move the workstream:

   ```bash
   mv ".dr-done/<workstream-slug>" ".dr-done/.archive/<workstream-slug>"
   ```

5. Git commit with a commit message like `[dr-done] Archive <workstream-slug>`

6. Confirm to the user:
   - "Archived workstream '<workstream-slug>' to .dr-done/.archive/"

```

## Acceptance Criteria

- [ ] Command file exists at `plugins/dr-done/commands/archive.md`
- [ ] Command validates workstream existence before archiving
- [ ] Command warns about incomplete tasks but doesn't block
- [ ] Command creates `.dr-done/.archive/` if it doesn't exist
- [ ] Command moves the workstream directory correctly
- [ ] Command provides clear feedback to the user

## Notes

- The command file follows the same pattern as `start.md` and `stop.md`
- No hook or script needed - the command instructions are simple enough to execute directly
- Users can manually restore archived workstreams with: `mv .dr-done/.archive/<workstream> .dr-done/`
```

---

## Completion Summary

Created `/dr-done:archive` command at `plugins/dr-done/commands/archive.md`. The command:
- Validates workstream existence before archiving
- Warns about incomplete tasks (non-.done.md/.stuck.md files) but doesn't block
- Creates `.dr-done/.archive/` directory if needed
- Moves the workstream directory to the archive
- Commits with `[dr-done] Archive <workstream-slug>` message
- Confirms success to the user

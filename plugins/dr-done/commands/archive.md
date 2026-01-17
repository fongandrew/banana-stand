# /dr-done:archive

Archive a completed dr-done workstream.

## Usage

```
/dr-done:archive <workstream-slug>
```

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

4. Move the workstream:
   ```bash
   mv ".dr-done/<workstream-slug>" ".dr-done/.archive/<workstream-slug>"
   ```

5. Git commit with a commit message like `[dr-done] Archive <workstream-slug>`

6. Confirm to the user:
   - "Archived workstream '<workstream-slug>' to .dr-done/.archive/"

## Notes

- Users can manually restore archived workstreams with: `mv .dr-done/.archive/<workstream> .dr-done/`

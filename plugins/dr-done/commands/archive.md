# /dr-done:archive

Archive a completed dr-done workstream.

## Usage

```
/dr-done:archive <workstream-slug>
```

- `workstream-slug`: The name of the workstream directory in `.dr-done/` to archive

## Instructions

When the user invokes this command, run the archive script:

```bash
"$CLAUDE_PLUGIN_ROOT/scripts/archive.sh" <workstream-slug>
```

The script will:
1. Validate the workstream exists
2. Warn about any incomplete tasks (non-blocking)
3. Create the archive directory if needed
4. Move the workstream to `.dr-done/.archive/`
5. Git add and commit the change

Report the script output to the user.

## Notes

- Users can manually restore archived workstreams with: `mv .dr-done/.archive/<workstream> .dr-done/`

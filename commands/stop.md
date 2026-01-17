# /dr-done:stop

Stop the current dr-done workstream.

## Usage

```
/dr-done:stop
```

## Instructions

When the user invokes this command:

1. Delete the state file at `.claude/dr-done.local.yaml` if it exists:

```bash
rm -f .claude/dr-done.local.yaml
```

2. Confirm to the user that dr-done has been stopped.

This will prevent the Stop hook from continuing to spawn new task iterations.

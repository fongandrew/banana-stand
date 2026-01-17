# /dr-done:start

Start a dr-done workstream for automated task processing.

## Usage

```
/dr-done:start [workstream-slug] [--max N]
```

- `workstream-slug`: The name of the workstream directory in `.dr-done/`
- `--max N`: Maximum number of iterations (default: 50)

## Instructions

When the user invokes this command:

1. Run the setup script with the provided arguments:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" $ARGUMENTS
```

2. If a workstream slug was provided and the setup succeeded, spawn a sub-agent to begin processing tasks:

Use the Task tool to spawn a sub-agent with the following prompt:

> Follow the instructions in `.dr-done/prompt.md` to process the next task in the workstream.

The sub-agent will handle task selection, execution, and committing work. The stop hooks will manage the iteration loop automatically.

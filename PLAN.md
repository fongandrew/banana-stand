# Build a Claude Code Plugin: Dr. Done

Build a Claude Code plugin for a "worker" agent that works in a worktree or git branch to process tasks from its designated markdown files.

## Plugin Overview

**Name:** dr-done
**Purpose:** Enable deterministic, file-based task decomposition and execution in a branch.
**Distribution:** Claude Code marketplace

## Plugin Structure

```
dr-done/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   ├── start.md             # /dr-done:start - kick off a workstream
│   └── stop.md              # /dr-done:stop - stop the current workstream
├── hooks/
│   └── hooks.json           # Hook configuration (references shell scripts)
├── scripts/
│   ├── setup.sh             # Setup script called by /dr-done:start
│   ├── stop.sh              # Stop hook script
│   └── subagent-stop.sh     # SubagentStop hook script
└── templates/
    └── prompt.md            # Default sub-agent prompt, copied to .dr-done/
```

### Plugin Manifest (.claude-plugin/plugin.json)

```json
{
  "name": "dr-done",
  "description": "File-based task decomposition and execution for workstreams",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

## Core Concept

- The repo has a `.dr-done` directory with a number of workstreams. Each workstream has its own `.dr-done/{workstream-slug}/` directory
- Inside each workstream directory are a number of task markdown files (e.g., `100-implement-auth.md`)
- A slash command is used to kick off work: `/dr-done:start {workstream-slug}`
- Once working, we process tasks in the workstream dir automatically.
- When a task is complete, it's renamed to a `.done.md` extension (e.g., `100-implement-auth.done.md`)
- A stop hook enforces: (1) all work is committed before proceeding, (2) next task is selected deterministically

## Requirements

### 0. General

Any bash should be written in bash compatible with macOS (bash 3.2+).

### 1. Start Command (commands/start.md)

The expected syntax is `/dr-done:start auth --max 50`, which means "work on the tasks in `.dr-done/auth`, up to a maximum 50 iterations".

The command itself is a prompt (markdown file) that tells Claude to:

1. Pass the arguments to a bash setup script (`scripts/setup.sh`)
2. Spawn a **sub-agent** that follows the instructions in `.dr-done/prompt.md`

The bash setup script (`scripts/setup.sh`) should do the following:

- **Early Commit:** First, check for uncommitted changes. If any exist, commit them with a message like `[dr-done] checkpoint before starting workstream`.
- **Repo Setup:** Create a `.dr-done` directory if it does not already exist and copy `templates/prompt.md` to `.dr-done/prompt.md` (only if it doesn't already exist). This runs first and runs even if no workstream is specified, so the user can call `/dr-done:start` just to trigger setup. The script can use `${CLAUDE_PLUGIN_ROOT}` to locate the templates directory.
- **Workstream Validation:** If a workstream slug is provided, verify that `.dr-done/{slug}/` exists and contains at least one `.md` file (not `.done.md` or `.stuck.md`). If not, exit with an error message.
- **Initial State:** Create a `.claude/dr-done.local.yaml` file. The purpose of this file is to track iteration state. This will be used by the stop hook. See below for more details.

### 1b. Stop Command (commands/stop.md)

The `/dr-done:stop` command removes `.claude/dr-done.local.yaml`, which stops the Stop hook from continuing to run. This is a simple prompt that tells Claude to delete the file.

### 2. Local State (.claude/dr-done.local.yaml)

This is a file used to track iteration state and manage the stop hook (see below). The `.local.yaml` extension keeps it from being checked into Git in normal operation.

The file should look like this:

```yaml
max: 100
iteration: 12
workstream: auth
```

The values are set when `/dr-done:start` is called. The max number of iterations should be 50 unless `--max` is specified. Each time `/dr-done:start` is called, we replace and reset the contents of the yaml file (so `iteration` always goes back to `1`). If the user runs the command twice, the second run simply overwrites the state file.

When `/dr-done:stop` is called, delete the yaml file.

### 3. Sub-agent prompt (templates/prompt.md → .dr-done/prompt.md)

The default prompt lives in the plugin at `templates/prompt.md` and is copied to `.dr-done/prompt.md` by the setup script (if it doesn't already exist). This prompt is meant to be followed by a **sub-agent** kicked off by the `/dr-done:start` command (or by the Stop hook telling the main agent to continue). The prompt should instruct the sub-agent to:

1. Read `.claude/dr-done.local.yaml` and get the current `workstream:`
2. Look for the alphabetically earliest markdown file in that workstream's directory that does _not_ end with `.done.md` or `.stuck.md`.
3. Decide if the task is simple or small enough to complete without having to compact:

   If it is complex:
   - It should decompose the task into smaller tasks in the workstream directory.
   - Each sub-task should be a separate markdown file.
   - Sub-tasks should use sequential numbering based on the parent task's number. For example, if decomposing `100-big-feature.md`, sub-tasks become `101-first-step.md`, `102-second-step.md`, etc.
   - If there are numbering conflicts with existing files, rename/reorder files as needed to maintain a sensible order.
   - After the task has been decomposed, it should append a **concise** summary of the decomposition to the original task.
   - It should rename the original task file to have a `.done.md` extension.
   - It should git commit its work with a meaningful description and the first line being something like `[done] <slug-name>/100-some-task.md`
   - Then it should stop and wait for the next iteration.

   If it is simple:
   - It should do the task.
   - It should run any tests, lint, typechecks, and other forms of validation:
     - If there are failing checks related to its changes, it should fix them.
     - If there are failing checks unrelated to its change, it should create a new task file in the workstream directory to address this.
   - If it succeeds in its task:
     - It should append a brief summary of the work done to the end of the task markdown.
     - It should rename the file to have a `.done.md` extension.
     - It should git commit its work with a meaningful description and the first line being something like `[done] <slug-name>/150-some-task.md`
   - If it is unable to complete the task:
     - It should append a brief explanation of the problem to the end of the task markdown.
     - It should rename the file to have a `.stuck.md` extension.
     - It should git commit its work with a meaningful description and the first line being something like `[stuck] <slug-name>/150-some-task.md`
   - Then it should stop and wait for the next iteration.

It is **critical** that this prompt be run by a sub-agent to minimize context pollution.

This prompt gets created by the `/dr-done:start` command but it should not override an existing one. The purpose of putting it in the repo is to allow the user to edit it -- e.g. they may want to specify validation checks.

### 4. Sub-Agent Stop Hook (scripts/subagent-stop.sh)

The `SubagentStop` hook runs after a sub-agent (Task tool call) finishes responding. This hook enforces that all work is committed before the sub-agent can stop.

**Hook Configuration (hooks/hooks.json):**

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/subagent-stop.sh"
          }
        ]
      }
    ]
  }
}
```

**Script Logic (scripts/subagent-stop.sh):**

1. Check if there are any uncommitted changes in the repository (`git status --porcelain`)
2. If there are uncommitted changes, output JSON to block the sub-agent:
   ```json
   {
     "decision": "block",
     "reason": "You have uncommitted changes. Please commit your work before stopping."
   }
   ```
3. If there are no uncommitted changes, exit with code 0 (allow stop)

### 5. Primary Stop Hook (scripts/stop.sh)

The `Stop` hook runs after the main Claude Code agent finishes responding. This hook manages the iteration loop and decides whether to continue processing tasks.

**Hook Configuration (add to hooks/hooks.json):**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/stop.sh"
          }
        ]
      }
    ],
    "SubagentStop": [...]
  }
}
```

**Script Logic (scripts/stop.sh):**

1. Check if `.claude/dr-done.local.yaml` exists. If not, exit 0 (allow stop - dr-done is not active).

2. Read the yaml file and get `max`, `iteration`, and `workstream` values.

3. Increment `iteration` by 1 and write it back to the yaml file.

4. If `iteration` exceeds `max`:
   - Delete the yaml file (cleanup)
   - Exit 0 (allow stop)

5. Check if all markdown files in `.dr-done/{workstream}/` end with `.done.md` or `.stuck.md`:
   - If yes: delete the yaml file and exit 0 (allow stop - workstream complete)
   - If no: output JSON to block and continue:
     ```json
     {
       "decision": "block",
       "reason": "Tasks remaining in workstream. Spawn a sub-agent to follow the instructions in .dr-done/prompt.md"
     }
     ```

6. On any error or when finally stopping, clean up the yaml file.

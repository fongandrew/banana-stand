# Build a Claude Code Plugin: Dr. Done

Build a Claude Code plugin for a "worker" agent that works in a worktree or git branch to process tasks from its designated markdown files.

You may read https://code.claude.com/docs/en/plugins to learn the latest on plugin setup and https://code.claude.com/docs/en/hooks for hooks info

## Plugin Overview

**Name:** dr-done
**Purpose:** Enable deterministic, file-based task decomposition and execution in a branch.
**Distribution:** Claude Code marketplace

## Core Concept

- The repo has a `.dr-done` directory with a number of workstreams. Each workstream has its own `.dr-done/{workstream-slug}/` directory
- Inside each workstream directory are a number of task markdown files (e.g., `100-implement-auth.md`)
- A slash command is used to kick off work: `/dr-done {workstream-slug}`
- Once working, we process tasks in the workstream dir automatically.
- When a task is complete, it's renamed to a `.done.md` extension (e.g., `100-implement-auth.done.md`)
- A stop hook enforces: (1) all work is committed before proceeding, (2) next task is selected deterministically

## Requirements

### 0. General

Any bash should be written in bash compatible with macOS (bash 3.2+).

### 1. Command

The expected syntax is something like `/dr-done auth --max 50`, which means "work on the tasks in `.dr-done/auth`, up to a maximum 50 iterations".

The command itself can be a prompt that tells Claude to pass the arguments to a bash script to run setup, and then to spawn a **sub-agent** that follows the instructions in a prompt created by that bash script (`.dr-done/prompt.md`).

The bash setup script should do several things things:

- **Repo Setup:** Create a `.dr-done` directory if it does not already exist and create a `prompt.md` prompt in there (see below for what we want in these). This runs first and runs even if no workstream is specified, so the user can call `/dr-done` just to trigger setup.
- **Initial State:** Create a `.claude/dr-done.local.yaml` file. The purpose of this file is to track iteration state. This will be used by the stop hook. See below for more details.
- **Stop:** If `/dr-done --stop` is called, we should remove `dr-done.local.yaml`. This should keep the stop hook from continuing to run.

### 2. Local State (.claude/dr-done.local.yaml)

This is a file used to track iteration state and manage the stop hook (see below). The `.local.yaml` is meant to keep it from being checked into Git in normal operation.

The file should look like something like this:

```yaml
- max: 100 # max iterations
- iteration: 12 # current iteration
- workstream: auth # slug for active workstream
```

The values are set when `/dr-done` is called. The max number of iterations should be 50 unless `--max` is called. Each time the `/dr-done` command is called, we replace and reset the contents of the yaml file (so `iteration` always goes back to `1`)

When `/dr-done --stop` is called, delete the yaml file.

### 3. Sub-agent prompt (`.dr-done/prompt.md`)

This is created/copied by the bash setup script. This prompt is meant to be followed by a **sub-agent** kicked off after the `/dr-done` command (or after the stop hook tells us to, see below). The prompt should instruct the sub-agent to:

1. Read `.claude/dr-done.local.yaml` and get the current `workstream:`
2. Look for the alphabetically earliest markdone file in that workstream's directory that does _not_ end with `.done.md`.
3. Decide if the task is simple or small enough to complete without having to compact:

   If it is complex:
   - It should decompose the task into smaller tasks in workstream directory.
   - Each sub-task should be a separate markdown file.
   - Sub-tasks should be prefixed with a numeric index like `100-` or `110-` and ordered in the order they should be executed.
   - Numbering should start at `100` and spaced out by 10 (so then `110`, then `120`). The purpose is to make it easy for a human to manually re-order tasks as needed by renaming files.
   - After the task has been decomposed, it should append a **concise** summary of the of decomposition to the original task.
   - It should rename the original task file to have a `.done.md` extension.
   - It should git commit its work a meaningulf description and the first line being something like `[done] <slug-name>/100-some-task.md`
   - Then it should stop and wait for the next iteration.

   If it is simple:
   - If the task is small, it should do the task.
   - It should run any tests, lint, typechecks, and other forms of validation:
     - If there are failing checks related to its changes, it should fix them.
     - If there are failing checks unrelated to its change, it should create a new sub-issue in the workstream directory to address this.
   - If it succeeds in its task:
     - It should append a brief summary of the work done to the end of the task markdown.
     - It should rename the file to have a `.done.md` extension.
     - It should git commit its work a meaningulf description and the first line being something like `[done] <slug-name>/150-some-task.md`
   - If it is unable to complete the task:
     - It should append a brief explanation of the problem to the end of the task markdown.
     - It should rename the file to have a `.stuck.md` extension.
     - It should git commit its work a meaningulf description and the first line being something like `[stuck] <slug-name>/150-some-task.md`
   - Then it should stop and wait for the next iteration.

It is **critical** that this prompt be run by a sub-agent to minimize context pollution.

This prompt gets created by the `/dr-done` slash command but it should not override if there an existing one there. The purpose of putting it in the repo is to allow the user to edit it -- e.g. they may want to specific validation checks.

### 4. Sub-Agent Stop Hook (hooks/sub-agent-stop.sh)

Read https://code.claude.com/docs/en/hooks to get the latest information on how stop hooks work.

This `SubagentStop` hook gets run after a sub-agent stops -- i.e. after a single markdown task has been completed. If there are any uncommitted changes in the repository, it blocks the sub-agent and insists it commits changes per the instructions in the prompt.

### 5. Primary Stop Hook (hooks/stop.sh)

Our `Stop` hook gets run after the main agent loop stops (e.g. after it has perhaps run several sub-agent iterations).

It should first check the `dr-done.local.yaml` file:

- It should increment the `iteration` count by 1
- If the `iteration` count exceeds the max, it should allow the agent to stop.

Otherwise, it should check that all markdown tasks in the workstream folder ends with `.stuck.md` or `.done.md` extensions. If they do, it allows the agent to stop. If they do not, it should block the agent and ask it to continue.

When asking it to continue, it should remind the agent of the original prmopt triggered by the `/dr-done` command (i.e. it's job is not to do the task but to just spin up a **sub-agents** to complete the task).

Whenever the agent stops, it should clean up the `dr-done.local.yaml` file (e.g. same as if `/dr-done --stop` was run).

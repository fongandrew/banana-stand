# dr-done

A workstream-based task automation system for Claude Code.

## Overview

dr-done enables autonomous task processing by organizing work into named workstreams. Each workstream contains markdown task files that are processed sequentially by a sub-agent.

## Directory Structure

```
.dr-done/
  prompt.md          # Sub-agent instructions (do not modify)
  README.md          # This file
  {workstream}/      # Workstream directories
    100-first-task.md
    200-second-task.md
    300-completed.done.md
    400-blocked.stuck.md
    init.done.md     # Initial task (see below)
```

## Task File Conventions

- **Processing order**: Files are processed alphabetically within each workstream
- **Completed tasks**: Renamed with `.done.md` suffix
- **Blocked tasks**: Renamed with `.stuck.md` suffix
- **Numbering**: Use numeric prefixes (e.g., `100-`, `200-`) to control execution order

## Creating a New Workstream

1. Create a directory under `.dr-done/` with your workstream name (use kebab-case)
2. Add a single `init.md` markdown files with the initial task description. It will be up to do the sub-agent to decompose this into numbered subtasks.

Example:

```
.dr-done/
  my-feature/
    init.md
```

## Starting a Workstream

Run the following command in Claude Code:

```
/dr-done:start [workstream-name]
```

This will begin processing tasks in the specified workstream, executing them one at a time until all tasks are complete or a task becomes stuck.

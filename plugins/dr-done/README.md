# dr-done

An alternative to the [Ralph Wiggum plugin](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) for long-running autonomous loops ("Ralph Loops") in Claude Code.

Like Ralph Wiggum, it uses stop hooks to create long-running autonomous sessions, but adds queued prompts, automatic git commits, subagent reviews, and permission handling for smoother operation.

Unlike Ralph Wiggum, it does not rely on the agent responding with a completion promise. Instead, the agent must rename all tasks in the `.dr-done/tasks` directory to have a `.done.md` extension (or `.stuck.md`, see below). This avoids the issue where the Ralph Wiggum plugin says something like "I'm not done so I should not say <promise>DONE</promise>" and inadvertently stops the loop.

## Installation

```
/plugin marketplace add fongandrew/banana-stand
/plugin install dr-done@banana-stand
```

## Quick Start

```
/dr-done:do some task description
```

## Commands (Skills)

- `/dr-done:init` - Creates the `.dr-done` with a config file.
- `/dr-done:add <task description>` - Adds a new task to the queue in `.dr-done/tasks` without starting the loop.
- `/dr-done:do <task description>` - Adds a new task and then starts the loop, focusing on the task added here first.
- `/dr-done:start` - Start working on the tasks in the queue, beginning with the oldest first (or however the tasks are lexographically sorted in `.dr-done/tasks`)
- `/dr-done:stop` - Stop working on tasks. The plugin will stop automatically when all tasks are done or stuck, but you can use this to force it.
- `/dr-done:unstick` - Rename all `.stuck.md` tasks to just `.md`. See below.
- `/dr-done:cleanup [criteria]` - Clean up old tasks from the queue. Defaults to cleaning up all done tasks. Supports criteria like "stuck", "review", "all", or time-based like "older than 7 days".

## Task List

Tasks or prompts get written to the `.dr-done/tasks` directory as plain Markdown files. Dr. Done instructs Claude to work on them until completion. Tasks are processed in alphabetical order (with the exception that `/dr-done:do` will always start with the task passed).

The task list is not meant to be a todo space for Claude itself -- it's just your prompts. Dr. Done instructs Claude to use its own task list tools for decomposing large tasks into smaller ones.

The task list is meant as a temporary queue and is git-ignored. If you want some sort of permanent git-managed task system, you should set that up separately and just reference in prompts, e.g. `/dr-done:do implement the plan in /plans/my-new-feature.md`

## Task States

Tasks in `.dr-done/tasks` transition through the following states:

### Pending

`TIMESTAMP-task-slug.md` - Incomplete task

### Awaiting Review

`TIMESTAMP-task-slug.review.md` - First pass on task is complete. If reviews are enabled, Dr. Done will instruct Claude to use a sub-agent to make sure it's _really_ done.

Review agent will check for an optional `.dr-done/REVIEW.md` prompt if you want to specify additional review settings (e.g. "always run unit tests")

### Completed

`TIMESTAMP-task-slug.done.md` - Task is complete. Dr. Done will instruct Claude to append a brief summary to the end of the task for review.

### Stuck

`TIMESTAMP-task-slug.stuck.md` - Claude cannot complete the task without human intervention. Dr. Done will instruct Claude to append a brief explanation to the end of the task for review.

Dr. Done injects a note about stuck tasks when you prompt Claude. In theory, you should be able to just tell Claude how to resolve a stuck task, but you can also use `/dr-done:unstick` (or just edit the file yourself).

The stuck state does not block other tasks. If you have multiple tasks in the queue, Dr. Done will continue working on the next task if it gets stuck on one.

## Configuration

Configuration is stored in `.dr-done/config.json`:

| Option | Default | Description |
| --- | --- | --- |
| `gitCommit` | `true` | Require Git commits after completing each task |
| `maxIterations` | `50` | Maximum number of loop iterations before automatically stopping |
| `review` | `true` | Enable review workflow where tasks transition to `.review.md` for validation |
| `stuckReminder` | `true` | Inject reminders about stuck tasks on user prompt submission (helps with auto-unsticking based on user input) |

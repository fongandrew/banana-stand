# Claude Code Context

This repository is a development workspace for Claude Code plugins and experimental features.

## Project Structure

```
banana-stand/
├── plugins/          # Claude Code plugins
│   └── dr-done/      # Task automation plugin
├── tests/            # Test suite
├── .dr-done/         # Task queue directory
│   ├── tasks/        # Active tasks (.md, .stuck.md, .review.md)
│   ├── done/         # Completed tasks (.done.md)
│   └── config.json   # dr-done configuration
└── .claude/          # Claude Code configuration
```

## Key Components

### dr-done Plugin

A single-queue task automation system with review workflow.

**Task Files:**

- `.md` - Pending tasks
- `.stuck.md` - Stuck tasks needing help
- `.review.md` - Completed tasks awaiting review
- `.done.md` - Fully completed and reviewed tasks

**Commands:**

- `/dr-done:init` - Initialize system
- `/dr-done:add` - Add new task
- `/dr-done:start` - Start processing queue
- `/dr-done:do <prompt>` - Work on specific task
- `/dr-done:stop` - Stop processing
- `/dr-done:unstick` - Recover stuck tasks

## Development Guidelines

### Testing

Run all tests:

```bash
bash tests/run.sh
```

Run specific test:

```bash
bash tests/run.sh tests/dr-done
```

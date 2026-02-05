# Claude Code Context

This repository is a development workspace for Claude Code plugins and experimental features.

## Project Structure

```
banana-stand/
├── plugins/           # Claude Code plugins
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
- `/dr-done:do <ID>` - Work on specific task
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

### Working with Tasks

When working on dr-done tasks:
1. Read the task file to understand requirements
2. Do meaningful work
3. Append work summary to the task file
4. Rename based on status:
   - `.review.md` if complete
   - `.stuck.md` if blocked
   - `.md` if more work needed
5. Commit changes if `gitCommit: true` in config
6. If marked complete, spawn `dr-done:reviewer` agent for review

### Code Style

- Keep solutions simple and focused
- Avoid over-engineering
- Only make necessary changes
- Follow existing patterns in the codebase

## Configuration

**dr-done config** (`.dr-done/config.json`):
```json
{
  "gitCommit": true,      // Require commits after each task
  "maxIterations": 50,    // Max loop iterations
  "review": true          // Enable review workflow
}
```

## Common Workflows

### Adding a New Task
```bash
# Create task file manually
.dr-done/tasks/TIMESTAMP-task-description.md

# Or use skill
/dr-done:add
```

### Processing Tasks
```bash
# Start automated loop
/dr-done:start

# Or work on specific task
/dr-done:do TIMESTAMP-task-slug
```

### Recovering from Issues
```bash
# Unstick tasks
/dr-done:unstick

# Stop the loop
/dr-done:stop
```

## Notes

- This is a development repository for experimenting with Claude Code features
- All plugins follow the Claude Code plugin structure
- Tests are comprehensive and should be run before making changes
- The dr-done plugin works in both git and non-git repositories

# dr-done v2: Session-Based Task Automation

## Overview

This document outlines a redesign of the dr-done plugin from a workstream-based model to a session-based model. The key changes are:

1. **Session-based organization** - Tasks are organized by Claude Code session ID, not named workstreams
2. **No forced subagents for work** - Work happens in the main session; only review uses a subagent
3. **Integrated reviewer flow** - Automatic quality checks when all tasks complete
4. **Better context preservation** - PreCompact hook reminds agent of state after compaction
5. **Sessions are ephemeral** - `.dr-done/sessions/` is gitignored; only source code is committed

---

## Directory Structure

```
.dr-done/
├── config.json                          # Global configuration
├── loop.md                              # User-customizable loop prompt (optional)
├── review.md                            # User-customizable review prompt (optional)
└── sessions/
    └── <session-id>/
        ├── state.json                   # {state, iteration, maxIterations}
        ├── 20260203T145212.md           # Pending prompt
        ├── 20260203T145230.done.md      # Completed prompt
        └── 20260203T145245.stuck.md     # Stuck prompt
```

### Files

#### `.dr-done/config.json`
```json
{
  "gitCommit": true,
  "maxIterations": 50
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `gitCommit` | boolean | `true` | Block stop if uncommitted changes exist |
| `maxIterations` | number | `50` | Maximum loop iterations before auto-stop |

#### `.dr-done/sessions/<session-id>/state.json`
```json
{
  "state": "on",
  "iteration": 3
}
```

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `state` | string | `"off"`, `"on"`, `"review"` | Current processing state |
| `iteration` | number | >= 0 | Current iteration count (incremented on each Stop hook fire, used to prevent infinite loops) |

---

## State Machine

```
                    ┌──────────────────────────────────┐
                    │                                  │
                    ▼                                  │
    [no state] ──► [off] ───/start───► [on] ─────────┤
        │           ▲                    │            │
        │           │                    │ all done   │
        │           │                    ▼            │
        │           │                 [review]        │
        │           │                    │            │
        │           │       ┌────────────┴─────────┐  │
        │           │       │                      │  │
        │           │       ▼                      ▼  │
        │           │   new tasks              all ok │
        │           │       │                      │  │
        │           │       └──► [on] ◄────────────┘  │
        │           │                                  │
        └───────────┴──── max iterations or /stop ────┘
```

### State Transitions

| From | Trigger | To | Action |
|------|---------|-----|--------|
| `off`/none | `/start` or `/do` | `on` | Set iteration=0, begin processing |
| `on` | task incomplete | `on` | Continue with next/same task |
| `on` | all tasks done/stuck | `review` | Spawn review subagent |
| `on` | `/stop` | `off` | Stop processing |
| `on` | max iterations | `off` | Force stop (prevents infinite resource consumption) |
| `review` | review finds issues | `on` | Process new tasks |
| `review` | review passes | `off` | Complete |
| `review` | `/stop` | `off` | Stop processing |

---

## Commands

### `/add <prompt>`

Adds a new task prompt to the current session without starting processing.

**Behavior:**
1. Get current Claude Code session ID from hook input
2. Create `.dr-done/sessions/<session-id>/` if needed
3. Generate timestamp: `YYYYMMDDTHHMMSS` (e.g., `20260203T145212`)
4. Write raw prompt text to `<timestamp>.md` (no wrapper, just the prompt as-is)
5. Do NOT modify state or start processing

**Task File Content:**
The task file contains the raw prompt text exactly as provided. No markdown wrapper or metadata.
```
# Example: /add "Fix the auth bug in login.ts"
# Creates: 20260203T145212.md containing:
Fix the auth bug in login.ts
```

**Implementation:** `commands/add.md` + `scripts/add.sh`

### `/start`

Begins processing tasks in the current session.

**Behavior:**
1. Get current session ID
2. Verify session directory exists with at least one `.md` file
3. Create/update `state.json`: `{state: "on", iteration: 0}`
4. Instruct agent to follow the loop prompt

**Implementation:** `commands/start.md` + `scripts/start.sh`

### `/do <prompt>`

Shorthand for `/add <prompt>` followed by `/start`.

**Behavior:**
1. Run `/add <prompt>` logic
2. Run `/start` logic

**Implementation:** `commands/do.md` (can delegate to add + start scripts)

### `/stop`

Stops the processing loop.

**Behavior:**
1. Get current session ID
2. Set `state.json` to `{state: "off", ...}`
3. Allow agent to stop

**Implementation:** `commands/stop.md` + `scripts/stop-command.sh`

### `/unstick`

Renames all `.stuck.md` files to `.md` and restarts processing.

**Behavior:**
1. Get current session ID
2. Find all `*.stuck.md` files in session directory
3. Rename each to remove `.stuck` suffix
4. Run `/start` logic

**Implementation:** `commands/unstick.md` + `scripts/unstick.sh`

### `/templates`

Creates user-customizable prompt templates.

**Behavior:**
1. Copy `templates/loop.md` to `.dr-done/loop.md` (if not exists)
2. Copy `templates/review.md` to `.dr-done/review.md` (if not exists)
3. Inform user they can edit these files

**Implementation:** `commands/templates.md` + `scripts/templates.sh`

### `/cleanup [N=7] [-f|--force]`

Removes old session directories.

**Behavior:**
1. Find all directories in `.dr-done/sessions/`
2. Check modification time of each
3. By default, only delete sessions that are:
   - Older than N days (default: 7), AND
   - Completed: state is `"off"` (or no state.json), AND all task files are `.done.md` (no pending or stuck)
   - Sessions in `"on"` or `"review"` state are protected without `-f`
4. With `-f` or `--force`: delete ALL sessions older than N days regardless of state
5. Report what was deleted

**Implementation:** `commands/cleanup.md` + `scripts/cleanup.sh`

---

## Hooks

### Stop Hook

**Event:** `Stop`
**Matcher:** None (fires on main agent stops only)

**Important:** This hook only fires when the *main agent* stops, not when subagents stop. Subagents (like the review subagent) exit normally without triggering this hook. After a subagent exits, control returns to the main agent, which then triggers this hook when it attempts to stop.

**Logic (pseudocode):**
```python
session_id = input.session_id
state_file = f".dr-done/sessions/{session_id}/state.json"

# No state file = not active
if not exists(state_file):
    return allow()

state = read_json(state_file)

# Already off
if state.state == "off":
    return allow()

# Increment iteration
state.iteration += 1
write_json(state_file, state)

# Max iterations exceeded
config = read_config()
if state.iteration > config.maxIterations:
    state.state = "off"
    write_json(state_file, state)
    return allow()

# State: on
if state.state == "on":
    # Check for uncommitted changes
    if config.gitCommit and has_uncommitted_changes():
        return block("You have uncommitted changes. Please commit your work before continuing.")

    # Check for pending tasks
    pending = find_pending_tasks(session_id)
    if pending:
        next_task = pending[0]
        loop_prompt = get_loop_prompt()  # User override or default
        return block(f"{loop_prompt}\n\nNext task: {next_task}")
    else:
        # All done, transition to review
        state.state = "review"
        write_json(state_file, state)
        review_prompt_path = get_review_prompt_path()  # .dr-done/review.md or templates/review.md
        return block(f"All tasks complete. Spawn a review subagent to verify the work. The subagent should read and follow the instructions in: {review_prompt_path}")

# State: review
if state.state == "review":
    # Check if review created new tasks
    pending = find_pending_tasks(session_id)
    if pending:
        state.state = "on"
        write_json(state_file, state)
        next_task = pending[0]
        loop_prompt = get_loop_prompt()
        return block(f"Review found issues. {loop_prompt}\n\nNext task: {next_task}")
    else:
        # All done
        state.state = "off"
        write_json(state_file, state)
        return allow()
```

**Implementation:** `scripts/stop-hook.sh`

### UserPromptSubmit Hook

**Event:** `UserPromptSubmit`
**Matcher:** None (fires on all prompts)

**Purpose:**
1. Remind agent of stuck tasks that user input might resolve
2. Provide context reminder after compaction (state, next task, etc.)

**Logic:**
```python
session_id = input.session_id
state_file = f".dr-done/sessions/{session_id}/state.json"

if not exists(state_file):
    return allow()

state = read_json(state_file)
if state.state == "off":
    return allow()

messages = []

# Check for stuck tasks
stuck = find_stuck_tasks(session_id)
if stuck and state.state in ["on", "review"]:
    messages.append(f"[dr-done] There are {len(stuck)} stuck task(s): {', '.join(stuck)}")
    messages.append("If your input helps resolve these, rename them from .stuck.md to .md")

# Context reminder
pending = find_pending_tasks(session_id)
if state.state == "on" and pending:
    messages.append(f"[dr-done] State: on | Iteration: {state.iteration} | Next task: {pending[0]}")
elif state.state == "review":
    messages.append(f"[dr-done] State: review | Verifying completed work")

if messages:
    print("\n".join(messages))
```

**Implementation:** `scripts/user-prompt-submit-hook.sh`

### PreCompact Hook

**Event:** `PreCompact`
**Matcher:** None (fires on both `manual` and `auto`)

**Purpose:** Inject context that survives compaction so agent remembers its task.

**Logic:**
```python
session_id = input.session_id
state_file = f".dr-done/sessions/{session_id}/state.json"

if not exists(state_file):
    return allow()

state = read_json(state_file)
if state.state == "off":
    return allow()

# Build context summary
context = []
context.append(f"[dr-done] Active session: {session_id}")
context.append(f"State: {state.state} | Iteration: {state.iteration}")

pending = find_pending_tasks(session_id)
stuck = find_stuck_tasks(session_id)
done = find_done_tasks(session_id)

context.append(f"Tasks: {len(pending)} pending, {len(done)} done, {len(stuck)} stuck")

if state.state == "on" and pending:
    context.append(f"\nNext task: {pending[0]}")
    loop_prompt = get_loop_prompt()
    context.append(f"\n{loop_prompt}")
elif state.state == "review":
    review_prompt = get_review_prompt()
    context.append(f"\n{review_prompt}")

# Output as additionalContext (if supported) or stdout
print("\n".join(context))
```

**Implementation:** `scripts/precompact-hook.sh`

---

## Prompts

### Loop Prompt (Default)

**Location:** `templates/loop.md` (default) or `.dr-done/loop.md` (user override)

**Template Variables:**
- `{{session_dir}}` - Path to session directory
- `{{next_task}}` - Path to next pending task file
- `{{iteration}}` - Current iteration number
- `{{pending_count}}` - Number of pending tasks
- `{{done_count}}` - Number of completed tasks
- `{{stuck_count}}` - Number of stuck tasks

**Content:**
```markdown
# dr-done Work Loop

You are in an automated work loop. Follow these instructions carefully.

## Current Task

Read and work on: {{next_task}}

## Instructions

1. **Read the task file** to understand what needs to be done.

2. **Do meaningful work** on the task. This means:
   - Make real progress (write code, fix bugs, implement features)
   - Run tests/linting if appropriate
   - Commit your changes with a descriptive message

3. **Update the task file** by appending a summary of what you did:
   ```
   ---
   ## Work Summary (Iteration {{iteration}})
   - What was done
   - What remains (if anything)
   ```

4. **Update the file extension** based on status:
   - Rename to `.done.md` if the task is **complete**
   - Rename to `.stuck.md` if you **need user help** to continue
   - Leave as `.md` if **more work is needed** (you'll continue next iteration)

5. **Commit your changes** if you made any code modifications.

6. **Call `stop`** to end this iteration.

## Session Info

- Directory: {{session_dir}}
- Iteration: {{iteration}}
- Pending: {{pending_count}} | Done: {{done_count}} | Stuck: {{stuck_count}}

## Important

- Do NOT spawn subagents for the work itself
- Focus on ONE task per iteration
- Always commit before stopping
- If blocked, mark as stuck with clear explanation
```

### Review Prompt (Default)

**Location:** `templates/review.md` (default) or `.dr-done/review.md` (user override)

**Template Variables:**
- `{{session_dir}}` - Path to session directory
- `{{done_files}}` - List of .done.md files to review
- `{{done_count}}` - Number of completed tasks

**Content:**
```markdown
# dr-done Review

You are a reviewer verifying that all work has been completed correctly.

## Session Directory

{{session_dir}}

## Completed Tasks to Review

{{done_files}}

## Instructions

1. **Run quality checks:**
   - Run linting (`npm run lint` or equivalent)
   - Run type checking (`npm run typecheck` or equivalent)
   - Run tests (`npm test` or equivalent)
   - Fix any failures yourself if they are minor

2. **Review each `.done.md` file:**
   - Read the original task and the work summary
   - Verify the work described was actually done
   - Check that the implementation is correct and complete

3. **If you find issues:**
   - Do NOT fix them yourself (you are a reviewer, not an implementer)
   - Create a new task file in {{session_dir}} describing what needs to be fixed
   - Use timestamp format: `YYYYMMDDTHHMMSS.md`
   - Be specific about what's wrong and what needs to change

4. **When review is complete:**
   - Call `stop` to end the review
   - The system will automatically continue if you created new tasks

## Important

- Your job is to VERIFY, not to IMPLEMENT
- Create task files for issues; don't fix them yourself
- Be thorough but fair
- Minor style issues don't need new tasks
```

---

## Setup & Initialization

### First-Time Setup

When any command runs for the first time, ensure:

1. `.dr-done/` directory exists
2. `.dr-done/sessions/` directory exists
3. `.gitignore` includes `sessions/`:
   ```
   # .dr-done/.gitignore
   sessions/
   ```

### Session Initialization

When `/add`, `/start`, or `/do` runs:

1. Get session ID from hook input (`input.session_id`)
2. Create `.dr-done/sessions/<session-id>/` if needed
3. Initialize `state.json` if needed (for `/start` or `/do`)

---

## Plugin Structure

```
plugins/dr-done/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── add.md
│   ├── start.md
│   ├── do.md
│   ├── stop.md
│   ├── unstick.md
│   ├── templates.md
│   └── cleanup.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── add.sh
│   ├── start.sh
│   ├── do.sh
│   ├── stop-command.sh        # For /stop command
│   ├── stop-hook.sh           # For Stop hook
│   ├── unstick.sh
│   ├── templates.sh
│   ├── cleanup.sh
│   ├── user-prompt-submit-hook.sh
│   ├── precompact-hook.sh
│   └── lib/
│       ├── common.sh          # Shared functions
│       └── template.sh        # Template variable substitution
├── templates/
│   ├── loop.md
│   └── review.md
└── PLAN.md                    # This file
```

### hooks.json

```json
{
  "description": "dr-done: Session-based task automation",
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/stop-hook.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/user-prompt-submit-hook.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/precompact-hook.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Implementation Notes

### Dependencies

- **Bash 3.2+** (macOS default)
- **jq** - Required for JSON parsing. Scripts assume `jq` is available in PATH.
- **git** - Required for repository root detection and commit status checks

### Script Header

All scripts should start with:
```bash
#!/bin/bash
# <script-name>.sh - Brief description
# Part of dr-done v2 plugin

set -e  # Exit on error

# Read input from stdin (for hooks)
INPUT=$(cat)

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$REPO_ROOT" ]]; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi
```

### Getting Session ID

All hooks receive `session_id` in their JSON input. Scripts must validate this and fail early if missing:
```bash
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
if [[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]]; then
    echo "Error: session_id not provided in input" >&2
    exit 1
fi
```

### Timestamp Generation

```bash
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
```

### Finding Tasks

```bash
# Pending tasks (not .done.md or .stuck.md)
find "$SESSION_DIR" -maxdepth 1 -name "*.md" \
    ! -name "*.done.md" \
    ! -name "*.stuck.md" \
    ! -name "state.json" \
    | sort

# Done tasks
find "$SESSION_DIR" -maxdepth 1 -name "*.done.md" | sort

# Stuck tasks
find "$SESSION_DIR" -maxdepth 1 -name "*.stuck.md" | sort
```

### Template Variable Substitution

```bash
substitute_template() {
    local template="$1"
    local session_dir="$2"
    local next_task="$3"
    local iteration="$4"
    # ... etc

    sed -e "s|{{session_dir}}|$session_dir|g" \
        -e "s|{{next_task}}|$next_task|g" \
        -e "s|{{iteration}}|$iteration|g" \
        # ... etc
        "$template"
}
```

### Prompt Resolution

```bash
get_loop_prompt_path() {
    if [[ -f "$REPO_ROOT/.dr-done/loop.md" ]]; then
        echo "$REPO_ROOT/.dr-done/loop.md"
    else
        echo "${CLAUDE_PLUGIN_ROOT}/templates/loop.md"
    fi
}

get_review_prompt_path() {
    if [[ -f "$REPO_ROOT/.dr-done/review.md" ]]; then
        echo "$REPO_ROOT/.dr-done/review.md"
    else
        echo "${CLAUDE_PLUGIN_ROOT}/templates/review.md"
    fi
}
```

### Review Subagent Pattern

When transitioning to review state, the Stop hook instructs the main agent to spawn a subagent. The main agent must pass the session ID to the subagent so the review operates on the correct session.

**Flow:**
1. Main agent finishes all tasks and calls stop
2. Stop hook transitions to `"review"` state and blocks with review instructions
3. Main agent spawns a review subagent, passing the session ID
4. Review subagent performs verification, optionally creates new task files
5. Review subagent exits (subagent stops do NOT trigger the Stop hook)
6. Main agent regains control and calls stop
7. Stop hook fires, checks for new tasks, and either continues or allows stop

```bash
REVIEW_PROMPT=$(substitute_template "$REVIEW_PROMPT_PATH" ...)
cat << EOF
{
  "decision": "block",
  "reason": "All tasks complete. Spawn a review subagent to verify the work. Pass the session ID ($SESSION_ID) to the subagent.\n\n$REVIEW_PROMPT"
}
EOF
```

The main agent will then spawn a subagent, ensuring the session ID is included in the subagent's context so it operates on the correct session directory.

**Template Substitution Strategy:**

Always attempt variable substitution on templates. If a template doesn't use certain variables, the substitution is a no-op.

For the **loop prompt**, the Stop hook:
1. Reads the template file
2. Substitutes all variables ({{next_task}}, {{iteration}}, etc.)
3. Includes the substituted content in the block reason

For the **review prompt**, the Stop hook:
1. Reads the template file
2. Substitutes all variables ({{session_dir}}, {{done_files}}, etc.)
3. Tells the agent to spawn a subagent, passing the session ID and substituted prompt content

### Git Status Check

```bash
has_uncommitted_changes() {
    # Check for changes, excluding .dr-done/sessions/
    git status --porcelain | grep -v "^.. .dr-done/sessions/" | grep -q .
}
```

---

## Migration from v1

The v2 plugin is a complete redesign and not backwards-compatible with v1.

### Key Differences

| Aspect | v1 | v2 |
|--------|----|----|
| Organization | Named workstreams | Session IDs |
| Task files | `100-task-name.md` | `20260203T145212.md` |
| Loop mechanism | Subagent spawning | Single session + Stop hook |
| Review | None | Automatic reviewer subagent |
| Git tracking | Workstreams committed | Sessions gitignored |
| State file | `.claude/dr-done.local.yaml` | `.dr-done/sessions/<id>/state.json` |
| Customization | Fixed prompts | User-overridable templates |

### What to Keep from v1

**Reusable patterns:**
- `CLAUDE_PLUGIN_ROOT` environment variable handling (setup.sh:7-11)
- YAML/JSON parsing approach with sed for bash 3.2+ compatibility
- Git status checking with `git status --porcelain` (subagent-stop.sh:21)
- Gitignore management pattern (setup.sh:114-132)
- Task file discovery with `find` and filtering (stop.sh:51-54)
- JSON output format for hook responses (stop.sh:64-69)

**Files to remove:**
- `scripts/subagent-stop.sh` - Git commit check moves to stop-hook.sh
- `scripts/permission-request.sh` - No longer needed (no forced subagents)
- `scripts/archive.sh` - Replaced by `/cleanup`
- `scripts/setup.sh` - Replaced by session auto-initialization
- `commands/archive.md` - Replaced by `/cleanup`
- `templates/prompt.md` - Replaced by `loop.md` and `review.md`
- `templates/README.md` - No longer needed

**Files to migrate:**
- `hooks/hooks.json` - Rewrite with new hook structure
- `commands/start.md` - Update for session-based model
- `commands/stop.md` - Update for session-based model

Users should archive any existing workstreams before switching to v2.

---

## Future Considerations

### Not in Scope for v2

1. **Native TaskList integration** - Decided to keep file-based system for simplicity and reviewability
2. **Multiple concurrent sessions** - Each Claude Code session has its own task list
3. **Cross-session task sharing** - Sessions are isolated by design

### Potential v2.1 Enhancements

1. **Session naming** - Allow `/start --name feature-x` to create human-readable session aliases
2. **Task priorities** - Support `!` prefix for high-priority tasks processed first
3. **Dependency tracking** - Allow tasks to specify blockers
4. **Progress reporting** - `/status` command to show current state
5. **Export/import** - Move tasks between sessions

---

## Testing Plan

Tests follow the pattern established in `tests/faq-check/test.sh`:
- Phase-based organization (setup, unit tests, integration)
- `pass()` / `fail()` helper functions for consistent output
- `TEST_TMP` directory passed as first argument
- Unit tests run without Claude CLI
- Integration tests skipped if Claude CLI not available

### Test Directory Structure

```
tests/dr-done-v2/
├── test.sh                    # Main test script
└── fixtures/
    └── sample-session/        # Pre-populated session for testing
        ├── state.json
        ├── 20260101T120000.md
        └── 20260101T120001.done.md
```

### Phase 1: Setup Verification

```bash
# Verify plugin structure
- .claude-plugin/plugin.json exists
- hooks/hooks.json exists and is valid JSON
- All scripts in scripts/ are executable
- Templates exist in templates/

# Verify fixtures
- Sample session fixtures copied correctly
```

### Phase 2: Unit Tests (Bash Scripts)

**stop-hook.sh:**
```bash
run_test "stop-hook.sh: No state file allows stop"
# Input: JSON with session_id but no state.json
# Expected: exit 0, no output

run_test "stop-hook.sh: State off allows stop"
# Input: state.json with state="off"
# Expected: exit 0, no output

run_test "stop-hook.sh: State on with pending tasks blocks"
# Input: state.json with state="on", pending .md files exist
# Expected: JSON with decision="block", reason contains loop prompt path

run_test "stop-hook.sh: State on with uncommitted changes blocks"
# Setup: Create uncommitted file
# Input: state.json with state="on", config.gitCommit=true
# Expected: JSON with decision="block", reason mentions commit

run_test "stop-hook.sh: State on with no pending tasks transitions to review"
# Input: state.json with state="on", only .done.md files
# Expected: JSON with decision="block", state.json updated to review

run_test "stop-hook.sh: State review with no new tasks allows stop"
# Input: state.json with state="review", only .done.md files
# Expected: exit 0, state.json updated to off

run_test "stop-hook.sh: State review with new tasks transitions to on"
# Input: state.json with state="review", new .md file created
# Expected: JSON with decision="block", state.json updated to on

run_test "stop-hook.sh: Max iterations reached allows stop"
# Input: state.json with iteration >= maxIterations
# Expected: exit 0, state.json updated to off
```

**user-prompt-submit-hook.sh:**
```bash
run_test "user-prompt-submit: No state file, no output"
run_test "user-prompt-submit: State off, no output"
run_test "user-prompt-submit: State on with stuck tasks, outputs reminder"
run_test "user-prompt-submit: State on, outputs context"
run_test "user-prompt-submit: State review, outputs review context"
```

**precompact-hook.sh:**
```bash
run_test "precompact: No state file, no output"
run_test "precompact: State off, no output"
run_test "precompact: State on, outputs full context with loop prompt"
run_test "precompact: State review, outputs full context with review prompt"
```

**add.sh:**
```bash
run_test "add.sh: Creates session directory if needed"
run_test "add.sh: Creates timestamp-named .md file"
run_test "add.sh: File contains raw prompt text"
run_test "add.sh: Multiple adds create sequential files"
run_test "add.sh: Creates .gitignore for sessions/"
```

**start.sh:**
```bash
run_test "start.sh: Creates state.json with state=on, iteration=0"
run_test "start.sh: Fails if no pending tasks"
run_test "start.sh: Outputs instruction to follow loop prompt"
```

**unstick.sh:**
```bash
run_test "unstick.sh: Renames .stuck.md to .md"
run_test "unstick.sh: Handles multiple stuck files"
run_test "unstick.sh: Starts processing after unsticking"
```

**cleanup.sh:**
```bash
run_test "cleanup.sh: Deletes completed sessions older than N days"
run_test "cleanup.sh: Preserves active sessions by default"
run_test "cleanup.sh: Force flag deletes all old sessions"
run_test "cleanup.sh: Default N=7 days"
```

**lib/common.sh:**
```bash
run_test "find_pending_tasks: Returns sorted list"
run_test "find_done_tasks: Returns sorted list"
run_test "find_stuck_tasks: Returns sorted list"
run_test "has_uncommitted_changes: Excludes sessions/"
run_test "read_state: Parses state.json correctly"
run_test "write_state: Writes valid JSON"
run_test "read_config: Returns defaults if no config.json"
```

**lib/template.sh:**
```bash
run_test "substitute_template: Replaces all variables"
run_test "substitute_template: Handles missing variables gracefully"
run_test "get_loop_prompt_path: Prefers .dr-done/loop.md"
run_test "get_loop_prompt_path: Falls back to templates/loop.md"
run_test "get_review_prompt_path: Prefers .dr-done/review.md"
run_test "get_review_prompt_path: Falls back to templates/review.md"
```

### Phase 3: Integration Tests (Claude CLI)

Skip if Claude CLI not available.

```bash
run_test "Integration: /add creates task file"
run_test "Integration: /start begins processing"
run_test "Integration: /do creates and starts"
run_test "Integration: /stop halts processing"
run_test "Integration: /unstick resumes stuck tasks"
run_test "Integration: Full loop completes"
```

### Test Helpers

```bash
# Standard test helpers (reuse from faq-check)
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    ((++TESTS_PASSED))
    echo "  PASS: $1"
}

fail() {
    ((++TESTS_FAILED))
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && echo "        Expected: $2"
    [[ -n "${3:-}" ]] && echo "        Got: $3"
}

run_test() {
    ((++TESTS_RUN))
    echo ""
    echo "Test $TESTS_RUN: $1"
    echo "$(printf '=%.0s' {1..60})"
}

# dr-done specific helpers
create_test_session() {
    local session_id="$1"
    mkdir -p "$TEST_TMP/.dr-done/sessions/$session_id"
}

create_state_file() {
    local session_id="$1"
    local state="$2"
    local iteration="${3:-0}"
    cat > "$TEST_TMP/.dr-done/sessions/$session_id/state.json" << EOF
{"state": "$state", "iteration": $iteration}
EOF
}

create_task_file() {
    local session_id="$1"
    local name="$2"
    local content="${3:-Test task}"
    echo "$content" > "$TEST_TMP/.dr-done/sessions/$session_id/$name"
}

mock_hook_input() {
    local session_id="$1"
    cat << EOF
{"session_id": "$session_id", "cwd": "$TEST_TMP"}
EOF
}
```

---

## Implementation Order

Suggested order for implementation:

### Phase 1: Core Infrastructure
1. `scripts/lib/common.sh` - Shared functions (read/write state, find tasks, git checks)
2. `scripts/lib/template.sh` - Template resolution and substitution
3. `templates/loop.md` - Default loop prompt
4. `templates/review.md` - Default review prompt

### Phase 2: Commands
5. `scripts/add.sh` + `commands/add.md` - Add task without starting
6. `scripts/start.sh` + `commands/start.md` - Start processing
7. `scripts/do.sh` + `commands/do.md` - Add + start shortcut
8. `scripts/stop-command.sh` + `commands/stop.md` - Manual stop

### Phase 3: Hooks
9. `scripts/stop-hook.sh` - Main loop control (most complex)
10. `scripts/user-prompt-submit-hook.sh` - Stuck task reminders
11. `scripts/precompact-hook.sh` - Context preservation
12. `hooks/hooks.json` - Hook registration

### Phase 4: Utilities
13. `scripts/unstick.sh` + `commands/unstick.md` - Unstick tasks
14. `scripts/templates.sh` + `commands/templates.md` - Export templates
15. `scripts/cleanup.sh` + `commands/cleanup.md` - Session cleanup

### Phase 5: Testing
16. `tests/dr-done-v2/test.sh` - Full test suite
17. `tests/dr-done-v2/fixtures/` - Test fixtures

### Phase 6: Cleanup
18. Remove obsolete v1 files
19. Update `.claude-plugin/plugin.json`
20. Update plugin README

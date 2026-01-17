# FAQ Check Plugin

A Claude Code plugin that nudges agents toward repo-specific FAQs when they encounter known issues.

## Overview

When agents hit common problems (port conflicts, wrong test commands, linting quirks), the plugin detects patterns in Bash output and points them to relevant FAQ docs via `additionalContext` injection.

## Directory Structure

```
plugins/faq-check/
  hooks/
    hooks.json           # PostToolUse hook registration
  scripts/
    post-tool-use.sh     # Main hook script
  commands/
    add.md               # /faq-check:add skill

.faq-check/              # Repo-level FAQ storage (user creates this)
  README.md              # Format documentation
  port-conflicts.md      # Example FAQ
  playwright-tests.md    # Example FAQ
  smart-quotes.md        # Example FAQ
```

## FAQ File Format

Each FAQ is a markdown file with YAML frontmatter:

```markdown
---
match_on: failure        # optional: "failure" (default), "success", or "any"
triggers:
  - EADDRINUSE           # literal substring match
  - /address already in use/i   # regex (/ delimited, optional flags)
---
# Port Conflicts

When tests fail due to port conflicts, don't try to kill the existing process.
Instead, set the PORT environment variable:

\`\`\`bash
PORT=3001 npm test
\`\`\`
```

### Trigger Syntax

- **Literal**: `EADDRINUSE` - plain substring match
- **Regex**: `/pattern/flags` - regex with optional flags (i, m, s)

### match_on Values

- `failure` (default): Only trigger on non-zero exit code
- `success`: Only trigger on zero exit code
- `any`: Trigger regardless of exit code

## Hook Behavior

### PostToolUse (Bash commands)

1. Check exit code against `match_on` criteria
2. Scan `.faq-check/*.md` files for matching triggers
3. If matches found:
   - 1 match: Inject filename + first non-frontmatter paragraph as teaser
   - N matches: Inject list of filenames only
4. Output via `additionalContext` (non-blocking)

### Example Output

Single match:
```
💡 FAQ match: .faq-check/port-conflicts.md
   "When tests fail due to port conflicts, don't try to kill the existing process..."
```

Multiple matches:
```
💡 FAQ matches found:
   - .faq-check/port-conflicts.md
   - .faq-check/testing-setup.md
```

## Skill: /faq-check:add

Interactive skill that helps create new FAQ entries:

1. Prompts for trigger patterns
2. Prompts for match_on behavior (default: failure)
3. Prompts for title and content
4. Creates file in `.faq-check/` with proper frontmatter format

## Implementation Tasks

1. Create plugin directory structure (`plugins/faq-check/`)
2. Implement `hooks/hooks.json` with PostToolUse matcher for Bash
3. Implement `scripts/post-tool-use.sh`:
   - Parse tool input (command) and output (stdout, stderr, exit code)
   - Find and parse `.faq-check/*.md` files
   - Match triggers against output using literal/regex logic
   - Filter by match_on vs exit code
   - Format and return additionalContext if matches found
4. Create `commands/add.md` skill template
5. Create `.faq-check/README.md` documenting the format for users
6. Create example FAQ files for the three scenarios discussed:
   - Port conflicts (EADDRINUSE, use PORT env var)
   - Playwright tests (use pnpm run test:e2e)
   - Smart quotes (use linter fixer, avoid exact string matching in tests)

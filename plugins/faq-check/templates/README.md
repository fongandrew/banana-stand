# FAQ Check Plugin

This directory contains FAQ files that are automatically matched against commands and their output during Claude Code sessions. When matching patterns are found, the FAQ content is surfaced as additional context to help Claude understand and resolve issues.

## File Format

FAQ files are Markdown files with YAML frontmatter. Place them in this directory with a `.md` extension.

### Basic Structure

```markdown
---
command_match: /npm (install|ci)/i
triggers:
  - error message to match
  - /regex pattern/i
match_on: failure
---

# FAQ Title

Explanation and guidance for the user when this FAQ matches.
```

## Frontmatter Fields

### command_match (optional)

A pattern to match against the command being executed. If specified, the FAQ will only be considered when the command matches this pattern.

**Literal strings** - Match as exact substrings:
```yaml
command_match: npm install
```

**Regex patterns** - Use `/pattern/flags` syntax:
```yaml
command_match: /npm (install|ci)/i
```

When `command_match` is specified, **both** the command pattern AND at least one trigger pattern must match for the FAQ to activate. If `command_match` is omitted, only the output triggers are checked.

### triggers (required)

A list of patterns to match against command output (stdout and stderr combined).

**Literal strings** - Match as exact substrings:
```yaml
triggers:
  - EADDRINUSE
  - "port already in use"
```

**Regex patterns** - Use `/pattern/flags` syntax:
```yaml
triggers:
  - /EADDRINUSE.*:\d+/i
  - /error: cannot find module/i
```

Supported regex flags:
- `i` - Case-insensitive matching

### match_on (optional)

Controls when the FAQ should be considered based on command exit code.

| Value | Description |
|-------|-------------|
| `failure` | Only match when exit code is non-zero (default) |
| `success` | Only match when exit code is zero |
| `any` | Match regardless of exit code |

```yaml
match_on: failure  # default
```

## How Matching Works

The FAQ check system uses a two-stage matching approach:

1. **Exit code check**: First, the `match_on` condition is evaluated against the command's exit code
2. **Command matching** (if `command_match` is specified): The command string is checked against the pattern
3. **Output matching**: The combined stdout/stderr is checked against trigger patterns

An FAQ activates only when **all applicable conditions** are met:
- The exit code matches `match_on` (always checked)
- The command matches `command_match` (if specified)
- At least one trigger matches the output (always checked)

## Opting Out of FAQ Checking

To run a command without FAQ checking, prefix it with `FAQ_CHECK=0`:

```bash
FAQ_CHECK=0 npm install
```

This is useful when:
- You know an error is expected and don't need FAQ suggestions
- You want to see raw output without FAQ annotations
- You're debugging the FAQ check system itself

## Example FAQ Files

### Command + Output Matching

This FAQ only triggers for npm commands that fail with permission errors:

```markdown
---
command_match: /npm (install|ci)/i
triggers:
  - EACCES
  - /permission denied/i
match_on: failure
---

# NPM Permission Errors

This error occurs when npm doesn't have write access to the required directories.

Try running with sudo or fix npm permissions:

\`\`\`bash
sudo chown -R $(whoami) ~/.npm
\`\`\`
```

### Output-Only Matching

This FAQ triggers for any command that produces port conflict errors:

```markdown
---
triggers:
  - EADDRINUSE
  - /address already in use/i
match_on: failure
---

# Port Conflicts

If you see port conflicts, try using a different port:

\`\`\`bash
PORT=3001 npm start
\`\`\`

Or find and kill the process using the port:

\`\`\`bash
lsof -i :3000 | grep LISTEN
\`\`\`
```

### Success Matching

This FAQ triggers when a specific success message appears:

```markdown
---
command_match: /deploy/
triggers:
  - "Deployment complete"
match_on: success
---

# Post-Deployment Steps

Don't forget to verify the deployment and update the changelog!
```

## How It Works Internally

1. The plugin wraps Bash commands using a `PreToolUse` hook
2. The wrapper captures stdout, stderr, and the exit code
3. After the command completes, the match checker scans all `.md` files in `.faq-check/`
4. Matching FAQ context is appended to stderr so it appears after the command output
5. The original exit code is preserved

When FAQs match:
- **Single match**: Shows the FAQ filename and a brief teaser (first paragraph)
- **Multiple matches**: Lists all matching FAQ filenames

## Tips

- Use `command_match` to scope FAQs to specific tools (npm, pip, docker, etc.)
- Put the most important information in the first paragraph (it's used as the teaser)
- Keep trigger patterns specific enough to avoid false matches
- Use `match_on: any` sparingly - most FAQs should only trigger on failures
- Use descriptive filenames that indicate what the FAQ addresses

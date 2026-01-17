# FAQ Check Plugin

This directory contains FAQ files that are automatically matched against tool output during Claude Code sessions. When a trigger pattern matches, the FAQ content is surfaced as additional context.

## File Format

FAQ files are Markdown files with YAML frontmatter. Place them in this directory with a `.md` extension.

### Basic Structure

```markdown
---
triggers:
  - error message to match
  - /regex pattern/i
match_on: failure
---

# FAQ Title

Explanation and guidance for the user when this FAQ matches.
```

## Frontmatter Fields

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

## Example FAQ File

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

## How It Works

1. When a Bash command runs, the plugin scans all `.md` files in this directory (except README.md)
2. For each file, it checks if the `match_on` condition is satisfied (based on exit code)
3. If satisfied, it tests each trigger pattern against the combined stdout/stderr
4. If any trigger matches:
   - **Single match**: Shows the FAQ filename and a brief teaser (first paragraph)
   - **Multiple matches**: Lists all matching FAQ filenames

## Tips

- Use descriptive filenames that indicate what the FAQ addresses
- Put the most important information in the first paragraph (it's used as the teaser)
- Keep trigger patterns specific enough to avoid false matches
- Use `match_on: any` sparingly - most FAQs should only trigger on failures

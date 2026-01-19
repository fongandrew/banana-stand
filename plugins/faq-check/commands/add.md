# /faq-check:add

Create a new FAQ entry for automatic error/output matching.

## Usage

```
/faq-check:add
```

## Instructions

When the user invokes this command, guide them through creating a new FAQ entry.

### Step 0: Initialize FAQ directory (if needed)

Before starting, check if the `.faq-check` directory exists in the project root. If it does not exist:

1. Create the `.faq-check` directory
2. Copy the README template from `plugins/faq-check/templates/README.md` to `.faq-check/README.md`
3. Inform the user: "I've created the `.faq-check` directory and added a README with documentation on the FAQ format."

Then proceed with the FAQ creation:

### Step 1: Explain the two-pattern matching system

Briefly explain to the user:

> The FAQ check system uses two types of pattern matching:
>
> 1. **Command pattern** (optional): Matches against the command being executed. This lets you scope your FAQ to specific tools (e.g., only npm commands, only docker commands).
>
> 2. **Output triggers** (required): Matches against the command's stdout/stderr output. This is what identifies the specific error or message.
>
> If you specify both, the FAQ will only trigger when BOTH the command pattern AND at least one output trigger match.

### Step 2: Ask about command pattern

Ask the user:

> Should this FAQ be scoped to a specific command or tool? (optional)
>
> Examples:
> - `npm install` - Matches commands containing "npm install"
> - `/npm (install|ci)/i` - Regex: matches npm install or npm ci (case-insensitive)
> - `/docker build/` - Regex: matches docker build commands
> - `/pip install/i` - Regex: matches pip install (case-insensitive)
>
> Leave blank to match any command (only output will be checked).

If the user provides a pattern, store it for the `command_match` field. If they skip or leave blank, omit the `command_match` field entirely.

### Step 3: Gather output trigger patterns

Ask the user:

> What output patterns should trigger this FAQ? These can be:
> - Literal strings (e.g., `ECONNREFUSED`, `permission denied`)
> - Regex patterns with `/pattern/flags` syntax (e.g., `/error.*not found/i`)
>
> You can specify multiple triggers (the FAQ will match if ANY trigger matches).

### Step 4: Ask about match_on behavior

Ask the user:

> When should this FAQ be shown?
> - `failure` (default): Only when the command fails (non-zero exit code)
> - `success`: Only when the command succeeds (zero exit code)
> - `any`: Regardless of exit code

If the user doesn't specify, default to `failure`.

### Step 5: Gather title and content

Ask the user:

> What title should this FAQ have?
>
> What explanation or solution should be shown when the FAQ matches?

### Step 6: Create the FAQ file

Create a file in `.faq-check/` with a descriptive filename (kebab-case, e.g., `npm-econnrefused.md`).

Use this format (include `command_match` only if the user specified one):

**With command_match:**

```markdown
---
command_match: /npm (install|ci)/i
triggers:
  - pattern1
  - pattern2
match_on: failure
---

# Title

Explanation content goes here. The first paragraph after the title
will be used as a teaser when the FAQ matches.

Additional details, examples, and solutions can follow.
```

**Without command_match (output-only matching):**

```markdown
---
triggers:
  - pattern1
  - pattern2
match_on: failure
---

# Title

Explanation content goes here. The first paragraph after the title
will be used as a teaser when the FAQ matches.

Additional details, examples, and solutions can follow.
```

### Step 7: Confirm creation

Confirm to the user that the FAQ was created and explain:

> The FAQ has been created at `.faq-check/{filename}.md`
>
> It will automatically trigger when:

If command_match was specified:
> - The command matches your pattern (e.g., npm install commands)
> - AND the output matches one of your trigger patterns

If command_match was not specified:
> - Any command produces output matching one of your trigger patterns

Then add:
> You can edit the file directly to modify patterns or content.

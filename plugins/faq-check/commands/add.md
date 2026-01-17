# /faq-check:add

Create a new FAQ entry for automatic error/output matching.

## Usage

```
/faq-check:add
```

## Instructions

When the user invokes this command, guide them through creating a new FAQ entry:

### Step 1: Gather trigger patterns

Ask the user:

> What patterns should trigger this FAQ? These can be:
> - Literal strings (e.g., `ECONNREFUSED`, `permission denied`)
> - Regex patterns with `/pattern/flags` syntax (e.g., `/error.*not found/i`)
>
> You can specify multiple triggers (the FAQ will match if ANY trigger matches).

### Step 2: Ask about match_on behavior

Ask the user:

> When should this FAQ be shown?
> - `failure` (default): Only when the command fails (non-zero exit code)
> - `success`: Only when the command succeeds (zero exit code)
> - `any`: Regardless of exit code

If the user doesn't specify, default to `failure`.

### Step 3: Gather title and content

Ask the user:

> What title should this FAQ have?
>
> What explanation or solution should be shown when the FAQ matches?

### Step 4: Create the FAQ file

Create a file in `.faq-check/` with a descriptive filename (kebab-case, e.g., `npm-econnrefused.md`).

Use this format:

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

### Step 5: Confirm creation

Confirm to the user that the FAQ was created and explain:

> The FAQ has been created at `.faq-check/{filename}.md`
>
> It will automatically trigger when a command output matches your patterns.
> You can edit the file directly to modify triggers or content.

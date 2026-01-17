# Create /faq-check:add Skill

Create `plugins/faq-check/commands/add.md` skill template.

The skill should guide the agent to:
1. Prompt for trigger patterns
2. Prompt for match_on behavior (default: failure)
3. Prompt for title and content
4. Create file in `.faq-check/` with proper frontmatter format

---

## Summary

Created `plugins/faq-check/commands/add.md` skill template that guides agents through:
1. Gathering trigger patterns (literal strings or regex)
2. Selecting match_on behavior (failure/success/any, defaults to failure)
3. Collecting title and explanation content
4. Creating the FAQ file with proper YAML frontmatter format
5. Confirming creation with usage guidance

Removed `.gitkeep` placeholder from the commands directory.

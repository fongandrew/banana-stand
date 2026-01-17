# Implement post-tool-use.sh

Create `plugins/faq-check/scripts/post-tool-use.sh` that:

1. Parses tool input (command) and output (stdout, stderr, exit code) from stdin JSON
2. Finds and parses `.faq-check/*.md` files in the repo root
3. Extracts YAML frontmatter to get triggers and match_on values
4. Matches triggers against output using:
   - Literal substring matching for plain strings
   - Regex matching for `/pattern/flags` syntax
5. Filters matches by match_on vs exit code:
   - `failure` (default): only match on non-zero exit
   - `success`: only match on zero exit
   - `any`: match regardless of exit code
6. Formats and returns additionalContext JSON if matches found:
   - Single match: filename + first non-frontmatter paragraph as teaser
   - Multiple matches: list of filenames only

---

## Summary

Implemented `plugins/faq-check/scripts/post-tool-use.sh` with all requested features:

- Parses JSON from stdin to extract `tool_result.stdout`, `tool_result.stderr`, and `tool_result.exit_code`
- Scans `.faq-check/*.md` files (skipping README.md)
- Extracts YAML frontmatter for `match_on` and `triggers` values
- Supports both literal substring matching and regex patterns (`/pattern/flags` syntax with `i` flag for case-insensitive)
- Filters by match_on: "failure" (default), "success", or "any"
- Returns `additionalContext` JSON:
  - Single match: includes filename and first paragraph teaser (truncated to ~100 chars)
  - Multiple matches: lists filenames only
- Removed `.gitkeep` placeholder from scripts directory

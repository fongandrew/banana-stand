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

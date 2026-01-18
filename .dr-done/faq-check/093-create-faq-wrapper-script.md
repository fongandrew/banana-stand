# Create Runtime FAQ Wrapper Script

Create `plugins/faq-check/scripts/faq-wrapper.sh` that runs at command execution time:

1. Accept the original command as an argument
2. Execute the original command, capturing stdout/stderr separately
3. Output stdout to stdout, stderr to stderr (preserving streams)
4. Preserve and propagate the original exit code (use temp file or PIPESTATUS)
5. After command completes, check output against FAQ patterns using match-checker.sh
6. If a match is found, append context message to stderr

Must handle:
- Complex commands with pipes, redirections, subshells
- Binary output (don't corrupt it)
- Proper exit code preservation

Example flow:
```
faq-wrapper.sh 'npm install'
-> runs: npm install
-> captures output
-> checks FAQs
-> if match: echo "[FAQ] See .faq-check/xyz.md for guidance" >&2
-> exits with npm's exit code
```

Reference the parent task `090-refactor.md` for full context.

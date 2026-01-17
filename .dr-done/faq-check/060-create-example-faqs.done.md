# Create Example FAQ Files

Create three example FAQ files in `.faq-check/`:

1. `port-conflicts.md` - EADDRINUSE errors, advise using PORT env var
2. `playwright-tests.md` - Use `pnpm run test:e2e` for Playwright tests
3. `smart-quotes.md` - Use linter fixer, avoid exact string matching in tests

---

## Summary

Created three example FAQ files in `.faq-check/`:

1. **port-conflicts.md** - Triggers on EADDRINUSE and port-in-use errors. Advises using PORT env var, shows how to find/kill conflicting processes.

2. **playwright-tests.md** - Triggers on Playwright-related errors. Instructs to use `pnpm run test:e2e` instead of npx, includes browser installation and debugging tips.

3. **smart-quotes.md** - Triggers on curly/smart quote characters. Advises using linter fixer and avoiding exact string matching in tests. Uses `match_on: any` since smart quotes may appear in successful output too.

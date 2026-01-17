---
triggers:
  - /playwright.*not found/i
  - /Cannot find module.*playwright/i
  - /npx playwright test/i
  - browserType.launch
  - /Error:.*Playwright/i
match_on: failure
---

# Running Playwright Tests

This project uses pnpm for Playwright end-to-end tests. Don't use `npx playwright test` directly.

## Correct Command

```bash
pnpm run test:e2e
```

## Common Issues

**Browsers not installed**: Run `pnpm exec playwright install` to install required browsers.

**Test isolation**: Playwright tests may require a clean environment. Stop any running dev servers before running tests.

**Headless mode**: By default, tests run headless. Use `--headed` flag for debugging:

```bash
pnpm run test:e2e -- --headed
```

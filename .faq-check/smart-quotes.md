---
triggers:
  - /[""'']/
  - /curly.*quote/i
  - /smart.*quote/i
  - /typographic.*quote/i
match_on: any
---

# Smart Quotes / Curly Quotes

Smart quotes (", ", ', ') can cause issues in code. They often appear when copying from documentation, Slack, or word processors.

## Fix with Linter

If the project has a linter configured to detect smart quotes, run the fixer:

```bash
pnpm run lint --fix
```

or

```bash
npm run lint -- --fix
```

## Avoid in Tests

When writing tests, avoid exact string matching that includes quotes from external sources. The quotes may render differently depending on the environment.

Instead of:
```javascript
expect(text).toBe("Hello "World"")
```

Use a regex or partial match:
```javascript
expect(text).toMatch(/Hello.*World/)
```

## Manual Replacement

Replace smart quotes with straight quotes:
- `"` and `"` -> `"`
- `'` and `'` -> `'`

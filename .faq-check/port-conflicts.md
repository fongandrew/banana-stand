---
triggers:
  - EADDRINUSE
  - /address already in use/i
  - /port.*already.*in.*use/i
match_on: failure
---

# Port Conflicts

The port your application is trying to use is already occupied by another process.

## Quick Fix

Use the `PORT` environment variable to run on a different port:

```bash
PORT=3001 npm start
```

## Find the Conflicting Process

To see what's using the port:

```bash
lsof -i :3000 | grep LISTEN
```

Then kill it if needed:

```bash
kill -9 <PID>
```

## Common Causes

- A previous dev server didn't shut down cleanly
- Another application is using the default port
- Running multiple instances of the same server

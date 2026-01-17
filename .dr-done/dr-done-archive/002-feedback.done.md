There was an error when attempting to run the script:

> /dr-done:archive dr-done-git

```
Bash("$CLAUDE_PLUGIN_ROOT/scripts/archive.sh" dr-done-git)
Error: Exit code 127
/bin/bash: /scripts/archive.sh: No such file or directory
```

The CLAUDE_PLUGIN_ROOT environment variable doesn't appear to be set.

Is there something we're doing wrong in our script or prompt?

---

## Summary

The `$CLAUDE_PLUGIN_ROOT` environment variable is not available in the Claude Code runtime context. Fixed by changing the archive command prompt to use a repository-relative path (`./plugins/dr-done/scripts/archive.sh`) instead of relying on the undefined environment variable.

#!/bin/bash
# generate-add-instructions.sh - Generate instructions for adding a task
# Part of dr-done v2 plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get timestamp
TIMESTAMP=$("$SCRIPT_DIR/generate-timestamp.sh")

cat << 'EOF'
Create a file with this content:

```
$ARGUMENTS
```

EOF

echo "Filename: \`.dr-done/tasks/${TIMESTAMP}-<slug>.md\`"

cat << 'EOF'

Replace `<slug>` with a short, descriptive slug from the task description (lowercase, hyphens, 2-5 words, e.g., `fix-auth-bug`, `add-user-profile`).

Report the filename you created.
EOF

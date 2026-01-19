#!/bin/bash
# Runtime wrapper for faq-check plugin
# Executes a command, captures output, checks for FAQ matches, and preserves exit code
#
# Usage: faq-wrapper.sh 'original command'
#
# This script:
# 1. Executes the original command capturing stdout/stderr
# 2. Outputs stdout to stdout and stderr to stderr (preserving streams)
# 3. Preserves the original exit code
# 4. Checks output against FAQ patterns using match-checker.sh
# 5. If a match is found, appends context message to stderr

# Debug logging
LOG_FILE="/tmp/claude/faq-check-debug.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [faq-wrapper] $*" >> "$LOG_FILE"
}

log "=== faq-wrapper.sh started ==="
log "Args: $*"

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATCH_CHECKER="$SCRIPT_DIR/match-checker.sh"

# The command to execute is passed either directly or base64 encoded
if [[ "$1" == "--base64" ]]; then
    # Decode base64 encoded command
    ORIGINAL_COMMAND=$(echo -n "$2" | base64 -d)
    log "Decoded base64 command"
else
    ORIGINAL_COMMAND="$1"
fi
log "ORIGINAL_COMMAND: $ORIGINAL_COMMAND"

if [[ -z "$ORIGINAL_COMMAND" ]]; then
    echo "Error: No command provided" >&2
    exit 1
fi

# Create temp files for capturing output
# Use a subdir under /tmp to ensure uniqueness
TEMP_DIR=$(mktemp -d)
STDOUT_FILE="$TEMP_DIR/stdout"
STDERR_FILE="$TEMP_DIR/stderr"
EXIT_CODE_FILE="$TEMP_DIR/exit_code"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Execute the command, capturing stdout and stderr separately
# We use a subshell to run the command and capture both streams
# The exit code is saved to a file since we can't get it through pipes

# Run the command in a subshell, capturing outputs to temp files
# Using eval to properly handle complex commands with pipes, redirections, etc.
log "Executing command..."
(
    eval "$ORIGINAL_COMMAND"
) > "$STDOUT_FILE" 2> "$STDERR_FILE"
COMMAND_EXIT_CODE=$?
echo "$COMMAND_EXIT_CODE" > "$EXIT_CODE_FILE"
log "Command finished with exit code: $COMMAND_EXIT_CODE"

# Read captured output for FAQ matching
STDOUT_CONTENT=""
STDERR_CONTENT=""
STDOUT_IS_BINARY=0
STDERR_IS_BINARY=0

# Function to check if a file contains null bytes (binary)
is_binary() {
    local file="$1"
    # Compare file with version where nulls are stripped
    # If they differ, the file contains null bytes
    ! tr -d '\0' < "$file" | cmp -s - "$file"
}

# Check if stdout is binary (contains null bytes)
if [[ -s "$STDOUT_FILE" ]]; then
    if is_binary "$STDOUT_FILE"; then
        STDOUT_IS_BINARY=1
        STDOUT_CONTENT="[binary output]"
    else
        STDOUT_CONTENT=$(cat "$STDOUT_FILE")
    fi
    # Output stdout exactly as captured (preserving binary and trailing whitespace)
    cat "$STDOUT_FILE"
fi

# Check if stderr is binary (contains null bytes)
if [[ -s "$STDERR_FILE" ]]; then
    if is_binary "$STDERR_FILE"; then
        STDERR_IS_BINARY=1
        STDERR_CONTENT="[binary output]"
    else
        STDERR_CONTENT=$(cat "$STDERR_FILE")
    fi
    # Output stderr exactly as captured (preserving binary and trailing whitespace)
    cat "$STDERR_FILE" >&2
fi

# Check for FAQ matches if the match-checker script exists
if [[ -x "$MATCH_CHECKER" ]]; then
    # Combine stdout and stderr for matching (match-checker will handle this)
    COMBINED_OUTPUT="$STDOUT_CONTENT
$STDERR_CONTENT"

    # Call match-checker with command, output, and exit code
    # Pass data via environment variables to handle special characters
    FAQ_MATCH=$(
        FAQ_COMMAND="$ORIGINAL_COMMAND" \
        FAQ_OUTPUT="$COMBINED_OUTPUT" \
        FAQ_EXIT_CODE="$COMMAND_EXIT_CODE" \
        "$MATCH_CHECKER" 2>/dev/null
    )

    # If match-checker returned content, append to stderr
    if [[ -n "$FAQ_MATCH" ]]; then
        echo "" >&2
        echo "$FAQ_MATCH" >&2
    fi
fi

# Exit with the original command's exit code
log "Exiting with code: $COMMAND_EXIT_CODE"
exit "$COMMAND_EXIT_CODE"

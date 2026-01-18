#!/bin/bash
# Match checker utility for faq-check plugin
# Checks command and output against FAQ patterns and outputs matching FAQ content
#
# Input via environment variables:
#   FAQ_COMMAND   - The command that was executed
#   FAQ_OUTPUT    - Combined stdout/stderr from the command
#   FAQ_EXIT_CODE - Exit code from the command
#
# Output:
#   Prints FAQ context message to stdout if a match is found
#   Exit code 0 if match found, 1 if no match
#
# This script is called by faq-wrapper.sh at runtime

set -e

# Find the project directory by looking for .faq-check/
# Start from current working directory and walk up
find_faq_dir() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.faq-check" ]]; then
            echo "$dir/.faq-check"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

FAQ_DIR=$(find_faq_dir) || exit 1

# Read input from environment variables
COMMAND="${FAQ_COMMAND:-}"
OUTPUT="${FAQ_OUTPUT:-}"
EXIT_CODE="${FAQ_EXIT_CODE:-0}"

# Determine if command succeeded or failed
if [[ "$EXIT_CODE" == "0" ]]; then
    RESULT_TYPE="success"
else
    RESULT_TYPE="failure"
fi

# Function to check if a trigger matches the output
check_trigger() {
    local trigger="$1"
    local text="$2"

    # Check if trigger is a regex (starts and ends with /)
    if [[ "$trigger" =~ ^/(.+)/([imsg]*)$ ]]; then
        local pattern="${BASH_REMATCH[1]}"
        local flags="${BASH_REMATCH[2]}"

        # Build grep flags
        local grep_flags="-q"
        if [[ "$flags" == *"i"* ]]; then
            grep_flags="$grep_flags -i"
        fi

        # Use grep for regex matching
        if echo "$text" | grep -E $grep_flags "$pattern" 2>/dev/null; then
            return 0
        fi
    else
        # Literal substring match
        if [[ "$text" == *"$trigger"* ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to extract YAML frontmatter value
get_frontmatter_value() {
    local file="$1"
    local key="$2"
    local default="$3"

    # Extract frontmatter between --- markers
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

    if [[ -z "$frontmatter" ]]; then
        echo "$default"
        return
    fi

    # Get the value for the key
    local value
    value=$(echo "$frontmatter" | grep "^${key}:" | sed "s/^${key}:[[:space:]]*//" | head -1)

    if [[ -z "$value" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Function to extract triggers array from frontmatter
get_triggers() {
    local file="$1"

    # Extract frontmatter between --- markers
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

    if [[ -z "$frontmatter" ]]; then
        return
    fi

    # Extract triggers - handle both array formats
    # Look for lines starting with "  -" after "triggers:" until next key or end
    local in_triggers=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^triggers: ]]; then
            in_triggers=1
            continue
        fi
        if [[ $in_triggers -eq 1 ]]; then
            # Stop if we hit another top-level key (no leading whitespace)
            if [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
            # Extract trigger value from "  - value" format
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+)$ ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
        fi
    done <<< "$frontmatter"
}

# Function to extract command_match from frontmatter
get_command_match() {
    local file="$1"
    get_frontmatter_value "$file" "command_match" ""
}

# Function to get first non-frontmatter paragraph (teaser)
get_teaser() {
    local file="$1"

    # Skip frontmatter and find first paragraph
    local in_frontmatter=0
    local found_content=0
    local teaser=""

    while IFS= read -r line; do
        if [[ "$line" == "---" ]] && [[ $in_frontmatter -eq 0 ]]; then
            in_frontmatter=1
            continue
        fi
        if [[ "$line" == "---" ]] && [[ $in_frontmatter -eq 1 ]]; then
            in_frontmatter=0
            continue
        fi
        if [[ $in_frontmatter -eq 1 ]]; then
            continue
        fi

        # Skip empty lines and headers before first paragraph
        if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
            if [[ $found_content -eq 1 ]]; then
                # End of paragraph
                break
            fi
            continue
        fi

        found_content=1
        if [[ -n "$teaser" ]]; then
            teaser="$teaser $line"
        else
            teaser="$line"
        fi
    done < "$file"

    # Truncate if too long (keep first ~100 chars)
    if [[ ${#teaser} -gt 100 ]]; then
        teaser="${teaser:0:100}..."
    fi

    echo "$teaser"
}

# Find matching FAQ files
declare -a MATCHES=()

for faq_file in "$FAQ_DIR"/*.md; do
    # Skip if no files found (glob didn't match)
    [[ -e "$faq_file" ]] || continue

    # Skip README.md
    [[ "$(basename "$faq_file")" == "README.md" ]] && continue

    # Get match_on value (default: failure)
    match_on=$(get_frontmatter_value "$faq_file" "match_on" "failure")

    # Check if this FAQ should be considered based on exit code
    case "$match_on" in
        failure)
            [[ "$RESULT_TYPE" != "failure" ]] && continue
            ;;
        success)
            [[ "$RESULT_TYPE" != "success" ]] && continue
            ;;
        any)
            # Always consider
            ;;
        *)
            # Unknown value, treat as failure
            [[ "$RESULT_TYPE" != "failure" ]] && continue
            ;;
    esac

    # Check command_match first (if specified)
    command_match=$(get_command_match "$faq_file")
    if [[ -n "$command_match" ]]; then
        if ! check_trigger "$command_match" "$COMMAND"; then
            # Command doesn't match, skip this FAQ
            continue
        fi
    fi

    # Check output triggers
    matched=0
    while IFS= read -r trigger; do
        [[ -z "$trigger" ]] && continue
        if check_trigger "$trigger" "$OUTPUT"; then
            matched=1
            break
        fi
    done <<< "$(get_triggers "$faq_file")"

    if [[ $matched -eq 1 ]]; then
        MATCHES+=("$faq_file")
    fi
done

# If no matches, exit with code 1
if [[ ${#MATCHES[@]} -eq 0 ]]; then
    exit 1
fi

# Build output based on number of matches
if [[ ${#MATCHES[@]} -eq 1 ]]; then
    # Single match: include teaser
    faq_file="${MATCHES[0]}"
    rel_path=".faq-check/$(basename "$faq_file")"
    teaser=$(get_teaser "$faq_file")

    echo "[FAQ] Match: $rel_path"
    if [[ -n "$teaser" ]]; then
        echo "   \"$teaser\""
    fi
else
    # Multiple matches: list filenames only
    echo "[FAQ] Multiple matches found:"
    for faq_file in "${MATCHES[@]}"; do
        rel_path=".faq-check/$(basename "$faq_file")"
        echo "   - $rel_path"
    done
fi

# Exit with code 0 to indicate match found
exit 0

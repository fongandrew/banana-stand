#!/bin/bash
# Phase 1: Setup verification tests

set -e

PLUGIN_ROOT="$1"

echo "Phase 1: Setup verification"
echo "==========================="

# Verify plugin structure
if [[ ! -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]]; then
    echo "FAIL: .claude-plugin/plugin.json not found"
    exit 1
fi
echo "OK: .claude-plugin/plugin.json exists"

if [[ ! -f "$PLUGIN_ROOT/hooks/hooks.json" ]]; then
    echo "FAIL: hooks/hooks.json not found"
    exit 1
fi
echo "OK: hooks/hooks.json exists"

# Verify hooks.json is valid JSON
if ! jq empty "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null; then
    echo "FAIL: hooks/hooks.json is not valid JSON"
    exit 1
fi
echo "OK: hooks/hooks.json is valid JSON"

# Verify lib scripts exist
for script in common.sh template.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/lib/$script" ]]; then
        echo "FAIL: scripts/lib/$script not found"
        exit 1
    fi
    echo "OK: scripts/lib/$script exists"
done

# Verify hook scripts exist and are executable
for script in stop-hook.sh session-start-hook.sh user-prompt-submit-hook.sh permission-request-hook.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script not found"
        exit 1
    fi
    if [[ ! -x "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script is not executable"
        exit 1
    fi
    echo "OK: scripts/$script exists and is executable"
done

# Verify helper scripts exist and are executable
for script in init.sh generate-timestamp.sh read-state.sh find-tasks.sh set-looper.sh generate-loop-prompt.sh; do
    if [[ ! -f "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script not found"
        exit 1
    fi
    if [[ ! -x "$PLUGIN_ROOT/scripts/$script" ]]; then
        echo "FAIL: scripts/$script is not executable"
        exit 1
    fi
    echo "OK: scripts/$script exists and is executable"
done

# Verify skills exist
for skill in init add start do stop unstick; do
    if [[ ! -f "$PLUGIN_ROOT/skills/$skill/SKILL.md" ]]; then
        echo "FAIL: skills/$skill/SKILL.md not found"
        exit 1
    fi
    echo "OK: skills/$skill/SKILL.md exists"
done

# Verify reviewer subagent exists
if [[ ! -f "$PLUGIN_ROOT/agents/reviewer.md" ]]; then
    echo "FAIL: agents/reviewer.md not found"
    exit 1
fi
echo "OK: agents/reviewer.md exists"

echo ""
echo "Phase 1 PASSED: Setup verification complete"
echo ""

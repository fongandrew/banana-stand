#!/bin/bash
# dr-done specific test helpers

setup_dr_done() {
    mkdir -p "$TEST_TMP/.dr-done/tasks"
    echo "tasks/" > "$TEST_TMP/.dr-done/.gitignore"
}

create_state_file() {
    local looper="$1"
    local iteration="${2:-0}"
    mkdir -p "$TEST_TMP/.dr-done"
    if [[ "$looper" == "null" ]]; then
        cat > "$TEST_TMP/.dr-done/state.json" << EOF
{"looper": null, "iteration": $iteration}
EOF
    else
        cat > "$TEST_TMP/.dr-done/state.json" << EOF
{"looper": "$looper", "iteration": $iteration}
EOF
    fi
}

create_config_file() {
    local git_commit="${1:-true}"
    local max_iterations="${2:-50}"
    local review="${3:-true}"
    mkdir -p "$TEST_TMP/.dr-done"
    cat > "$TEST_TMP/.dr-done/config.json" << EOF
{"gitCommit": $git_commit, "maxIterations": $max_iterations, "review": $review}
EOF
}

create_task_file() {
    local name="$1"
    local content="${2:-Test task}"
    mkdir -p "$TEST_TMP/.dr-done/tasks"
    echo "$content" > "$TEST_TMP/.dr-done/tasks/$name"
}

mock_hook_input() {
    local session_id="$1"
    cat << EOF
{"session_id": "$session_id", "cwd": "$TEST_TMP"}
EOF
}

cleanup_dr_done() {
    rm -rf "$TEST_TMP/.dr-done"
}

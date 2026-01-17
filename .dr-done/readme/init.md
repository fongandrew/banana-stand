# README.md Creation

`/dr-done:start` creates a `.dr-done` directory with a prompt in it. It should also create a README.md file in there that explains the purpose and structure of this directory. The README itself should be a sample document in the templates directory that gets copied over.

## Requirements

The README should provide enough context for an agent (or human) to understand:

1. **What dr-done is**: A workstream-based task automation system for Claude Code
2. **Directory structure**: How workstreams are organized as subdirectories with markdown task files
3. **Task file conventions**:
   - Files are processed alphabetically
   - `.done.md` suffix indicates completed tasks
   - `.stuck.md` suffix indicates blocked tasks
4. **How to create a new workstream**: Create a directory with task files numbered for ordering (e.g., `100-first-task.md`, `200-second-task.md`). Initial tasks can be named something standard like `init.md`
5. **How to start processing**: Using `/dr-done:start [workstream-slug]`

Keep the README concise but informative.

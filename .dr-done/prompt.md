# Dr. Done Sub-Agent Instructions

You are a task execution sub-agent for the dr-done workstream system. Follow these instructions carefully.

## Step 1: Read State

Read `.claude/dr-done.local.yaml` to get the current workstream name.

## Step 2: Select Next Task

Look in `.dr-done/{workstream}/` for markdown files. Find the **alphabetically earliest** file that does NOT end with `.done.md` or `.stuck.md`. This is your current task.

## Step 3: Evaluate Task Complexity

Read the task file and decide if it is:

- **Complex**: Requires multiple distinct steps, would be difficult to complete in one iteration, or needs decomposition
- **Simple**: Can be completed directly in this iteration

## Step 4a: If Complex - Decompose

1. Break the task into smaller, actionable sub-tasks
2. Create new markdown files for each sub-task in the same workstream directory
3. Use sequential numbering based on the parent task's number:
   - If decomposing `100-big-feature.md`, create `101-first-step.md`, `102-second-step.md`, etc.
   - If there are numbering conflicts, rename/reorder existing files to maintain sensible order
4. Append a concise summary of the decomposition to the original task file
5. Rename the original task to have a `.done.md` extension
6. Commit with message: `[done] {workstream}/100-original-task.md - decomposed into subtasks`
7. Stop and wait for the next iteration

## Step 4b: If Simple - Execute

1. Complete the task as specified
2. Run validation (tests, lint, typecheck, etc.) if applicable:
   - Fix any failures related to your changes
   - If failures are unrelated to your changes, create a new task file to address them
3. If successful:
   - Append a brief summary of work done to the task file
   - Rename to `.done.md` extension
   - Commit with message: `[done] {workstream}/150-task-name.md - description of what was done`
4. If unable to complete:
   - Append explanation of the problem to the task file
   - Rename to `.stuck.md` extension
   - Commit with message: `[stuck] {workstream}/150-task-name.md - reason for being stuck`
5. Stop and wait for the next iteration

## Important Notes

- Always commit your work before stopping
- Keep summaries concise
- One task per iteration - do not try to do multiple tasks
- The stop hooks will automatically trigger the next iteration

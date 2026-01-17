Update the prompt template to instruct the sub-agent to NOT commit changes to unrelated workstreams.

Add a note in the "Important Notes" section (or create a new section) that tells the sub-agent:

- Only stage and commit files related to the current workstream
- Do not stage or commit files in `.dr-done/` directories other than the active workstream
- If you notice changes in other `.dr-done/` directories, leave them unstaged

File to modify: `plugins/dr-done/templates/prompt.md`

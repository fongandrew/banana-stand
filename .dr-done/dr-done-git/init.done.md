We want to change how the dr-done plugin interacts with git:

- The sub-agent stop hook ensures that there are no uncommited files, but this should only kick in if the `dr-done.local.yaml` file is present and active.
- The sub-agent stop hook should ignore uncommited git changes in .dr-done (other than the ones in the currently active workstream). The idea here is that we want to allow the user to stage additional work in the `.dr-done` director while the agent is working. Let's also tweak the default prompt to tell the subagent to not git commit unrelated workstreams as well.
- We should ensure that the `dr-done.local.yaml` file itself doesn't get committed. As part of .dr-done setup, in the bash script, after creatign the initial `dr-done.local.yaml`, we should see if git picks it up. If it does, it should look for a `.claude/.gitignore`, create it if it doesn't exist, and add `dr-done.local.yaml` if it's not already there (and then commit it with a comit line like `[dr-done] Ignore dr-done.local.yaml`).

---

## Decomposition Summary

This task has been decomposed into the following subtasks:

1. **101-update-subagent-stop-hook.md**: Modify subagent-stop.sh to only enforce uncommitted file checks when dr-done.local.yaml is present, and to ignore changes in .dr-done directories other than the active workstream.

2. **102-update-prompt-template.md**: Update the prompt template to instruct sub-agents not to commit changes to unrelated workstreams.

3. **103-gitignore-dr-done-local-yaml.md**: Update setup.sh to automatically add dr-done.local.yaml to .claude/.gitignore if git would track it.

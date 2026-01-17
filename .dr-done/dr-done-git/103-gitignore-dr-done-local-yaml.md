Update the setup.sh script to ensure `dr-done.local.yaml` is not committed to git.

After creating the `dr-done.local.yaml` file, the script should:

1. Check if git would track the file (using `git check-ignore` or similar)
2. If git would track it:
   a. Check if `.claude/.gitignore` exists; if not, create it
   b. Check if `dr-done.local.yaml` is already in `.claude/.gitignore`
   c. If not present, add `dr-done.local.yaml` to the gitignore
   d. Commit the gitignore change with message: `[dr-done] Ignore dr-done.local.yaml`

File to modify: `plugins/dr-done/scripts/setup.sh`

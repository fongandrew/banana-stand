Update the setup.sh script to ensure `dr-done.local.yaml` is not committed to git.

After creating the `dr-done.local.yaml` file, the script should:

1. Check if git would track the file (using `git check-ignore` or similar)
2. If git would track it:
   a. Check if `.claude/.gitignore` exists; if not, create it
   b. Check if `dr-done.local.yaml` is already in `.claude/.gitignore`
   c. If not present, add `dr-done.local.yaml` to the gitignore
   d. Commit the gitignore change with message: `[dr-done] Ignore dr-done.local.yaml`

File to modify: `plugins/dr-done/scripts/setup.sh`

---

## Summary

Updated `plugins/dr-done/scripts/setup.sh` to ensure `dr-done.local.yaml` is gitignored:

- Added logic after state file creation to check if git would track the file using `git check-ignore`
- If not ignored, creates `.claude/.gitignore` if it doesn't exist, or appends to it if it does
- Uses `grep -qxF` to check for exact line match to avoid duplicate entries
- Commits the gitignore change with message `[dr-done] Ignore dr-done.local.yaml`

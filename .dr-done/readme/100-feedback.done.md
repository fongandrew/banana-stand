You created a `.dr-done/README.md` file, but what we want is to also:

- Create the same file in Dr. Done's template directory
- As part of setting up a new .dr-done directory, copy that README over.

---

## Done

- Created `plugins/dr-done/templates/README.md` with the same content as `.dr-done/README.md`
- Updated `plugins/dr-done/scripts/setup.sh` to copy the README template to `.dr-done/README.md` when setting up a new directory

# banana-stand

Development repository for Claude Code plugins and experimental features.

## Installation

```
/plugin marketplace add fongandrew/banana-stand
/plugin install dr-done@banana-stand
```

## Plugins

### dr-done

An alternative to the [Ralph Loop plugin](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) for autonomous task automation in Claude Code.

[Full documentation →](plugins/dr-done/README.md)

## Development

### Quick Start

Run the dr-done plugin with debug logging to `$TMPDIR/claude-dr-done`:

```bash
./dev.sh
```

### Running Tests

Run all tests:

```bash
bash tests/run.sh
```

Run specific test suite (currently just one):

```bash
bash tests/run.sh tests/dr-done
```

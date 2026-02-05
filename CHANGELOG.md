# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-02-05

## Fixed
- Added clarification that `/dr-done:add` should not start task.

## [1.0.1] - 2025-02-05

### Fixed
- Fixed hard-coded directory references in scripts
- Clarify that renames should be to extension, not in new folders

## [1.0.0] - 2025-02-05

### Added
- Initial release of dr-done plugin with single-queue task automation:
    - `/dr-done:init` command to initialize the system
    - `/dr-done:add` command to add new tasks
    - `/dr-done:start` command to begin processing queue
    - `/dr-done:do <prompt>` command for specific task work
    - `/dr-done:stop` command to stop processing
    - `/dr-done:unstick` command to recover stuck tasks
    - `/dr-done:cleanup` commmand to remove old tasks from queue
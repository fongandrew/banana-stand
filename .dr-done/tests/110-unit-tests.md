We've previously attempted completely E2E automated testing with Claude but this was a mistake because a sandboxed Claude can't run another instance of Claude effectively since the latter may also write to `~/.claude.json`.

Let's try a different approach:

- Unit tests: These test scripts specifically. The tests should be co-located alongside the script being tested (so, e.g., something like permission-request.test.sh colocated alongside permission.sh). The unit test setup should create a new directory in our `.tmp` folder and `echo` content into the folder to setup the expected environment. It should set any environment variables before calling the underlying shell script and then verifying side effects or output.

- E2E tests: These should exist largely as they do today (script that copies a setup directory and then executes claude with `--plugin-dir`) but the expectation is now that the user calls them to verify output, rather than Claude directly.

Let's create the co-located unit tests for each shell script in the dr-done and faq-check plugins. Verify they pass.

Then reduce the E2E test cases to a minimal happy path state than the human end user can run. Make `--output-format stream-json` conditional upon the presence of a verbose flag passed to the test runner.

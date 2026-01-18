---
command_match: /echo|printf/
triggers:
  - BANANA_STAND_TEST_ERROR
  - /banana.*stand.*error/i
match_on: failure
---

# Test Error FAQ

This FAQ triggers when the test error message is detected.

You should see this message if the faq-check plugin is working correctly.

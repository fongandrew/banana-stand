---
command_match: /echo|printf/
triggers:
  - BANANA_STAND_TEST_SUCCESS
  - /banana.*stand.*success/i
match_on: success
---

# Test Success FAQ

This FAQ triggers when the test success message is detected.

You should see this message if the faq-check plugin is working correctly on success.

# Add Tests for faq-check Plugin

Create tests for the faq-check plugin to verify:
- Literal substring matching
- Regex matching with flags
- match_on filtering (failure, success, any)
- Single vs multiple match output formats
- stderr matching
- Missing FAQ directory handling

---

## Summary

Created `tests/faq-check/test.sh` with 12 comprehensive test cases:

1. **No match** - verifies silent exit when no triggers match
2. **Literal match on failure** - EADDRINUSE literal trigger
3. **Regex match with case-insensitive flag** - /address already in use/i
4. **match_on: failure + exit 0** - verifies failure FAQs don't match on success
5. **match_on: success + exit 0** - verifies success FAQs match correctly
6. **match_on: success + exit 1** - verifies success FAQs don't match on failure
7. **match_on: any + exit 0** - verifies any FAQs match on success
8. **match_on: any + exit 1** - verifies any FAQs match on failure
9. **Multiple matches** - verifies "FAQ matches found:" format with list
10. **Single match with teaser** - verifies "FAQ match:" format with teaser text
11. **stderr matching** - verifies triggers match in stderr output
12. **Missing FAQ directory** - verifies silent exit when .faq-check is missing

All tests pass successfully.

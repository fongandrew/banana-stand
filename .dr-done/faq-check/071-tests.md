Your work in 070-tests is more unit test than E2E. We really do want to test against an actual live instance of Claude. Look at how the test for dr-done-multi works.

Also, the test doesn't need to write content out. We can just create the contents we expect in an .faq directory and the test runner will copy everything as needd.

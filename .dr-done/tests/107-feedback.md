The changes made in turn 106-feedback are not good. It passes, but it exits way too quickly, which suggests it is skipping some sort of work (basically recreation the conditions from 105-feedback).

Also, when I run the test, there's no console output from the test itself. We just get this:

```
$ ./tests/run.sh
=== Running: dr-done-multi ===
PASSED: dr-done-multi

=== Results: 1 passed, 0 failed ===
```

However, `tests/dr-done-multi/test.sh` is echo-ing a fair bit of stuff. I should be able to see that so I can see what's going on (e.g. did all three phases of the text actually run? It seems unlikely right now).

# std.algorithm.find is too slow

At least for short strings like in this benchmark.
This also makes
[splitter slow](https://issues.dlang.org/show_bug.cgi?id=9646).

Run benchmark via `make dmd` or `make ldc`.
There are no requirements apart from the compilers.

Current output example:

```d
$ make dmd
./benchmark.dmd
E: Chris find wrong
std find:    173 ±32
manual find: 133 ±26
qznc find:   103 ±6
Chris find:  158 ±30
 (avg slowdown vs fastest; absolute deviation)
```

The line `E: Chris find wrong` means one run of "Chris find"
returned a wrong result.
This should not happen, of course.
It means the benchmark is somewhat invalid,
although this is only 1 run of 10000.

It generates a random scenario (haystack length, needle length, alphabet, etc)
and runs it once with all algorithms.
Instead of recording the absolute runtime,
it records the slowdown compared to the fastest one.
Average those over many iterations and
also compute the absolute deviation (the second number).

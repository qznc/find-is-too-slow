# std.algorithm.find is too slow

At least for short strings like in this benchmark.
This also makes
[splitter slow](https://issues.dlang.org/show_bug.cgi?id=9646).

Current output example:

```d
$ make ldc
ldc2 -O -release benchmark.d && ./benchmark
std find    took   4485192516
boyer find  took   6818024101
manual find took   1095723912
```

.PHONY: default dmd ldc

default:
	echo "Run benchmark via 'dmd' or 'ldc' goals"

# Building
benchmark.dmd: benchmark.d my_searching.d Makefile
	dmd -O -release -inline -noboundscheck *.d -of$@

benchmark.ldc: benchmark.d my_searching.d Makefile
	ldmd2 -O -release -inline -noboundscheck *.d -of$@

# Running
dmd: benchmark.dmd
	./$<

ldc: benchmark.ldc
	./$<

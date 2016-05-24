.PHONY: dmd ldc

default:
	echo "Run benchmark via 'dmd' or 'ldc' goals"

dmd: benchmark.d
	dmd -O -release -inline -noboundscheck $< && ./benchmark

ldc: benchmark.d my_searching.d
	ldmd2 -O -release -inline -noboundscheck $^ && ./benchmark

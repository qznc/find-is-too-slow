.PHONY: dmd ldc

default:
	echo "Run benchmark via 'dmd' or 'ldc' goals"

dmd: benchmark.d
	dmd -O -release -inline -noboundscheck $< && ./benchmark

ldc: benchmark.d
	ldc2 -O -release $< && ./benchmark

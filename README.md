# TL;DR
The single-core kernel of GUPS (aka RandomAccess) from the HPC Challenge benchmark suite.

# How to build and run
Simply invoke `make` to build the `gups` executable.

To run GUPS on a 1GB array (== 2^27 cells of unsigned 64-bit integers):
```
$ ./gups --log2_length 27
```

# Motivation
According to its [website](https://icl.utk.edu/hpcc/), the HPC Challenge (HPCC) suite measures a range memory access patterns and consists of seven benchmarks: HPL, DGEMM, STREAM, PTRANS, RandomAccess, FFT, and Communication bandwidth and latency. Strangely, the suite links all these benchmarks into a single, monolithic executable that runs them one by one.
This repo extracts one of the seven benchmarks -- RandomAccess -- so it can be run alone.
Most of our code borrows from the file `RandomAccess/core_single_cpu.c` of the official github repo: https://github.com/icl-utk-edu/hpcc (the original copyright notice is included).
We additionally clean the code and remove MPI and OpenMP dependencies.

# Summary of changes
The changes with respect to the original code are:
1. Specify the array size through a command-line argument.
2. Specify the number of iterations through a command-line argument. A single iteration goes over the array 4x (like in the original HPCC implementation) without running the initialization phase (array[i] = i). The default number of iterations is set to one, compatible to the HPCC implementation.
3. Scrape off the MPI and openMP related functions.
4. Migrate the code to C++ and build it with g++.
5. Introduce a new-command line flag, "--verify", that enables the final verification step. Verification is disabled by default because the comments in `core_single_cpu.c` say it is optional.


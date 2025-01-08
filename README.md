# TL;DR
The single-core kernel of GUPS (aka RandomAccess) from the HPC Challenge benchmark suite.

# How to build and run
Simply invoke `make` to build the `gups` executable, which runs the multi-threaded version (implemented with OpenMP).

To run GUPS on a 1GB array (== 2^27 cells of unsigned 64-bit integers):
```
$ OMP_NUM_THREADS=1 ./gups --log2_length 27
```
To run GUPS with four threads on a 2GB array:
```
$ OMP_NUM_THREADS=4 ./gups --log2_length 28
```

# Motivation
According to its [website](https://icl.utk.edu/hpcc/), the HPC Challenge (HPCC) suite measures a range memory access patterns and consists of seven benchmarks: HPL, DGEMM, STREAM, PTRANS, RandomAccess, FFT, and Communication bandwidth and latency. Strangely, the suite links all these benchmarks into a single, monolithic executable that runs them one by one.
This repo extracts one of the seven benchmarks -- RandomAccess -- so it can be run alone.
Most of our code borrows from the file `RandomAccess/core_single_cpu.c` of the official github repo: https://github.com/icl-utk-edu/hpcc (the original copyright notice is included).
We additionally clean the code and remove MPI dependencies.

# Summary of changes
The changes with respect to the original code are:
1. Specify the array size through a command-line argument.
2. Specify the number of iterations through a command-line argument. A single iteration goes over the array 4x (like in the original HPCC implementation) without running the initialization phase (array[i] = i). The default number of iterations is set to one, compatible to the HPCC implementation.
3. Scrape off the MPI related functions.
4. Migrate the code to C++ and build it with g++.
5. Introduce a new-command line flag, "--verify", that enables the final verification step. Verification is disabled by default because the comments in `core_single_cpu.c` say it is optional.

# Validation against the original HPCC benchmark
`make validation` validates the performance of this new implementation against the reference HPCC implementation. My tests on my Intel i7-6600U CPU (Skylake) produced the following performance numbers (giga updates per second):


# Scalability tests
GUPS seems like an embarrassingly parallel workload because it can issue many threads that randomly accesses the big array. However, it turned out that the parellel implementation provided in the HPCC suite does not scale well with the number of threads; The table below shows that GUPS throughput is ~50% higher with 4 threads. Additionally, Intel VTune reported that the application achieves 33% of the available memory bandwidth.


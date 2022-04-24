# TL;DR
The single-core kernel of GUPS (aka RandomAccess) from the HPC Challenge benchmark suite.

# How to build and run
Simply invoke `make` to build the two executables: `serial`, which runs a single thread of GUPS, and `parallel`, which runs a multi-threaded version implemented with OpenMP.

To run GUPS on a 1GB array (== 2^27 cells of unsigned 64-bit integers):
```
$ ./serial --log2length 27
```
To run GUPS with four threads on a 1GB array:
```
$ OMP_NUM_THREADS=3 ./parallel --log2length 27
```

# Motivation
According to its [website](https://icl.utk.edu/hpcc/), the HPC Challenge (HPCC) suite measures a range memory access patterns and consists of seven benchmarks: HPL, DGEMM, STREAM, PTRANS, RandomAccess, FFT, and Communication bandwidth and latency. Strangely, the suite links all these benchmarks into a single, monolithic executable that runs them one by one.
This repo re-implements one of the seven benchmarks -- RandomAccess -- so it can be run alone. Additionally, this repo cleans the original code and remove MPI dependencies. The original code can be cloned from the official github repo: https://github.com/icl-utk-edu/hpcc . My code mostly borrows from the file `RandomAccess/core_single_cpu.c` in this repo. I therefore included the original copyright notice.

# Summary of changes
The changes with respect to the original code are:
1. Specify the array size through a command-line argument.
2. Specify the number of iterations through a command-line argument. A single iteration goes over the array 4x (like in the original HPCC implementation) without running the initialization phase (array[i] = i). The default number of iterations is set to one, compatible to the HPCC implementation.
3. Scrape off the MPI related functions.
4. Migrate the code to C++ and build it with g++.
5. Introduce a new-command line flag, "--verify", that enables the final verification step. Verification is disabled by default because the comments in `core_single_cpu.c` say it is optional.

# Validation against the original HPCC benchmark
`make compare` validates the performance of this new implementation against the reference HPCC implementation. My tests on my Intel i7-6600U CPU (Skylake) produced the following performance numbers (giga updates per second):

|           | serial	| reference |
|-----------|-----------|-----------|
| repeat1   | 0.0295	| 0.0297    |
| repeat2   | 0.0305	| 0.0321    |
| repeat3   | 0.0304	| 0.0299    |
| repeat4   | 0.0311	| 0.0301    |
| repeat5   | 0.0308	| 0.0302    |
|-----------|-----------|-----------|
| average   | 0.0305	| 0.0304    |
| std_dev   | 0.0006	| 0.0010    |

In conclusion: the new implementation is similar to the original HPCC implementation because the difference between the average numbers is well below the standard deviation. (This statistical procedure is similar to the Z-test or the t-test).

# Scalability tests
GUPS seems like an embarrassingly parallel workload because it can issue many threads that randomly accesses the big array. However, it turned out that the parellel implementation provided in the HPCC suite does not scale well with the number of threads; The table below shows that GUPS throughput is ~50% higher with 4 threads. Additionally, Intel VTune reported that the application achieves 33% of the available memory bandwidth.

My first guess was that the problem is false sharing of the random number array, which is accessed in the main loop like this:
```
#ifdef _OPENMP
#pragma omp parallel for
#endif
    for (j=0; j<128; j++) {
      ran[j] = (ran[j] << 1) ^ ((s64Int) ran[j] < 0 ? POLY : 0);
      Table[ran[j] & (TableSize-1)] ^= ran[j];
    }
  }
}
```

To fix the problem, I padded the `ran` array such that each cell lies in a separate 64-byte cache line. The performance results on Intel Xeon E5-2660 v4 CPU (Broadwell) were similar, as shown below. This trend was true for other machines and array sizes. It seems like the problem lies somewhere else...

| threads   | original	| no false sharing  |
|-----------|-----------|-------------------|
| 1     	| 0.0283	| 0.0287            |
| 2     	| 0.0393	| 0.0382            |
| 3     	| 0.0406	| 0.0402            |
| 4     	| 0.0419	| 0.0425            |


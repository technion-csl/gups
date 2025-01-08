/*
 * This code has been contributed by the DARPA HPCS program.  Contact
 * David Koester <dkoester@mitre.org> or Bob Lucas <rflucas@isi.edu>
 * if you have questions.
 *
 * GUPS (Giga UPdates per Second) is a measurement that profiles the memory
 * architecture of a system and is a measure of performance similar to MFLOPS.
 * The HPCS HPCchallenge RandomAccess benchmark is intended to exercise the
 * GUPS capability of a system, much like the LINPACK benchmark is intended to
 * exercise the MFLOPS capability of a computer.  In each case, we would
 * expect these benchmarks to achieve close to the "peak" capability of the
 * memory system. The extent of the similarities between RandomAccess and
 * LINPACK are limited to both benchmarks attempting to calculate a peak system
 * capability.
 *
 * GUPS is calculated by identifying the number of memory locations that can be
 * randomly updated in one second, divided by 1 billion (1e9). The term "randomly"
 * means that there is little relationship between one address to be updated and
 * the next, except that they occur in the space of one half the total system
 * memory.  An update is a read-modify-write operation on a table of 64-bit words.
 * An address is generated, the value at that address read from memory, modified
 * by an integer operation (add, and, or, xor) with a literal value, and that
 * new value is written back to memory.
 *
 * We are interested in knowing the GUPS performance of both entire systems and
 * system subcomponents --- e.g., the GUPS rating of a distributed memory
 * multiprocessor the GUPS rating of an SMP node, and the GUPS rating of a
 * single processor.  While there is typically a scaling of FLOPS with processor
 * count, a similar phenomenon may not always occur for GUPS.
 *
 * For additional information on the GUPS metric, the HPCchallenge RandomAccess
 * Benchmark,and the rules to run RandomAccess or modify it to optimize
 * performance -- see http://icl.cs.utk.edu/hpcc/
 *
 */

/*
 * This file contains the computational core of the single cpu version
 * of GUPS.  The inner loop should easily be vectorized by compilers
 * with such support.
 *
 * This core is used by both the single_cpu and star_single_cpu tests.
 */

#include <iostream>
#include <fstream>
#include <exception>
#include <algorithm>
#include <string>
#include <cstring>
#include <cinttypes>
#include <cassert>
#include <chrono>

char* GetOption(char ** begin, char ** end, const std::string & option) {
    char ** itr = std::find(begin, end, option);
    if (itr != end && ++itr != end) {
        return *itr;
    }
    return nullptr;
}

bool DoesOptionExist(char** begin, char** end, const std::string& option) {
    return std::find(begin, end, option) != end;
}

#define POLY 0x0000000000000007UL
#define PERIOD 1317624576693539401L
/* utility routine to create a seed for the n-th parallel access */
uint64_t random_seed(int64_t n) {
    int i, j;
    uint64_t m2[64];
    uint64_t temp, random_index;

    while (n < 0) n += PERIOD;
    while (n > PERIOD) n -= PERIOD;
    if (n == 0) return 0x1;

    temp = 0x1;
    for (i=0; i<64; i++) {
        m2[i] = temp;
        temp = (temp << 1) ^ ((int64_t) temp < 0 ? POLY : 0);
        temp = (temp << 1) ^ ((int64_t) temp < 0 ? POLY : 0);
    }

    for (i=62; i>=0; i--)
        if ((n >> i) & 1)
            break;

    random_index = 0x2;
    while (i > 0) {
        temp = 0;
        for (j=0; j<64; j++)
            if ((random_index >> j) & 1)
                temp ^= m2[j];
        random_index = temp;
        i -= 1;
        if ((n >> i) & 1)
            random_index = (random_index << 1) ^ ((int64_t) random_index < 0 ? POLY : 0);
    }

    return random_index;
}

bool verify(uint64_t array[], uint64_t array_length, uint64_t num_updates) {
    /* Verify the results in "safe" mode: single-thread, deterministic loop */
    uint64_t temp = 0x1;
    for (uint64_t i = 0; i < num_updates; i++) {
        temp = (temp << 1) ^ (((int64_t) temp < 0) ? POLY : 0);
        array[temp & (array_length-1)] ^= temp;
    }

    uint64_t errors = 0;
    for (uint64_t i = 0; i < array_length; i++) {
        if (array[i] != i) {
            errors++;
        }
    }
    std::cout << "Summary: " << errors << " errors were found.\n";

    double error_tolerance = 0.01 * array_length;
    if (errors >= error_tolerance) {
        std::cout << "Failed: should have < " << error_tolerance << " errors.\n";
        return false;
    } else {
        std::cout << "Passed.\n";
        return true;
    }
}

int main(int argc, char* argv[]) {
    /* Parse command line options */
    if (DoesOptionExist(argv, argv+argc, "-h") ||
            DoesOptionExist(argv, argv+argc, "--help")) {
        std::cout << "Usage: " << argv[0] << " [--log2_length L] [--log2_iterations I] [--verify]\n";
        return 0;
    }

    // Default array length = 128M (==> 1GB sized array)
    uint64_t log2_array_length = 27ul;
    if (DoesOptionExist(argv, argv+argc, "--log2_length")) {
        std::string log2_length_string = GetOption(argv, argv+argc, "--log2_length");
        try {
            log2_array_length = std::stoul(log2_length_string);
        } catch (const std::exception& e) {
            std::cerr << "Invalid number for the --log2_length option!\n";
            return 1;
        }
    }
    std::cout << "Array length = 2^" << log2_array_length << " cells\n";

    // Default number of iterations = 1
    uint64_t log2_iterations = 0ul;
    if (DoesOptionExist(argv, argv+argc, "--log2_iterations")) {
        std::string log2_iterations_string = GetOption(argv, argv+argc, "--log2_iterations");
        try {
            log2_iterations = std::stoul(log2_iterations_string);
        } catch (const std::exception& e) {
            std::cerr << "Invalid number for the --log2_iterations option!\n";
            return 1;
        }
    }
    std::cout << "Number of iterations = 2^" << log2_iterations << "\n";

    // Verification is off by default
    bool has_to_verify = false;
    if (DoesOptionExist(argv, argv+argc, "--verify")) {
        char* verify_option_value = GetOption(argv, argv+argc, "--verify");
        if (verify_option_value != nullptr) {
            std::cerr << "Invalid value for the --verify option!\n";
            return 1;
        }
        has_to_verify = true;
        std::cout << "Verification is enabled\n";
    } else {
        std::cout << "Verification is disabled\n";
    }

    uint64_t array_length = 1ul<<log2_array_length;
    /* Number of updates to table (suggested: 4x number of table entries) */
    uint64_t num_updates = array_length<<2ul; /* 4x the array size */
    const uint64_t num_parallel_accesses = 128;
    uint64_t num_iterations = 1ul<<log2_iterations;

    uint64_t* array = new (std::nothrow) uint64_t[array_length];
    assert(array != nullptr);

    /* Initialize main table */
    for (uint64_t i = 0; i < array_length; i++) {
        array[i] = i;
    }

    // Start time measurement
    auto start = std::chrono::steady_clock::now();

    /* Calculate the initial seeds only once for all iterations */
    uint64_t seeds[num_parallel_accesses];
    for (uint64_t j = 0; j < num_parallel_accesses; j++) {
        seeds[j] = random_seed((num_updates / num_parallel_accesses) * j);
    }

    /* Iterate over the original HPCC loop */
    for (uint64_t k = 0; k < num_iterations; k++) {
        /* Perform updates to main table */
        for (uint64_t i = 0; i < num_updates / num_parallel_accesses; i++) {
#pragma omp parallel for
            for (uint64_t j = 0; j < num_parallel_accesses; j++) {
                seeds[j] = (seeds[j] << 1) ^ ((int64_t) seeds[j] < 0 ? POLY : 0);
                array[seeds[j] & (array_length-1)] ^= seeds[j];
            }
        }
    }

    // Stop time measurement
    auto stop = std::chrono::steady_clock::now();
    auto microseconds_elapsed = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
    double seconds_elapsed = 1e-6 * microseconds_elapsed.count();
    double giga_updates = 1e-9 * num_iterations * num_updates;
    double gups = giga_updates / seconds_elapsed;
    std::cout << "giga updates = " << giga_updates << "\n";
    std::cout << "seconds elapsed = " << seconds_elapsed << "\n";
    std::cout << "GUPS (Giga updates per second) = " << gups << "\n";

    if (has_to_verify) {
        bool success = verify(array, array_length, num_updates);
        if (! success) return -1;
    }

    /* Free the allocated array */
    delete[] array;

    return 0;
}


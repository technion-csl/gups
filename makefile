# The commands in a recipe are passed to a single invocation of the Bash shell.
SHELL := /bin/bash
# run all lines of a recipe in a single invocation of the shell rather than each line being invoked separately
.ONESHELL:
# invoke recipes as if the shell had been passed the -e flag: the first failing command in a recipe will cause the recipe to fail immediately
.POSIX:

##### Constants #####
CXX := g++
CXXFLAGS := -Wall -Werror -Wextra -pedantic -O3 -std=c++11 -fopenmp
ifdef DEBUG
	CXXFLAGS += -g
endif
source_files := main.cc
header_files :=
reference_dir := reference
validation_dir := validation
scalability_dir := scalability

##### Targets #####
reference_makefile := $(reference_dir)/makefile
reference := $(reference_dir)/single_random_access
binary := gups

##### Recipes #####
.PHONY: all test clean

all: $(binary)

$(binary): $(source_files) $(header_files)
	$(CXX) $(CXXFLAGS) -o $@ $(source_files)

test: $(binary)
	OMP_NUM_THREADS=1 ./$< --log2_length 27 --verify

$(reference): $(reference_makefile)
	cd $(reference_dir) && $(MAKE)

$(reference_makefile):
	git submodule update --init --progress $(reference_dir)

clean: validation/clean scalability/clean
	rm -f $(binary) $(reference)
	cd $(reference_dir) && $(MAKE) clean

include $(validation_dir)/module.mk
include $(scalability_dir)/module.mk


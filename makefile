# The commands in a recipe are passed to a single invocation of the Bash shell.
SHELL := /bin/bash
# run all lines of a recipe in a single invocation of the shell rather than each line being invoked separately
.ONESHELL:
# invoke recipes as if the shell had been passed the -e flag: the first failing command in a recipe will cause the recipe to fail immediately
.POSIX:

##### Constants #####
CXX := g++
CXXFLAGS := -Wall -Werror -Wextra -pedantic -O3 -std=c++11
ifdef DEBUG
	CXXFLAGS += -g
endif
source_files := main.cc
header_files :=

##### Targets #####
binary := gups

##### Recipes #####
.PHONY: all test clean

all: $(binary)

$(binary): $(source_files) $(header_files)
	$(CXX) $(CXXFLAGS) -o $@ $(source_files)

test: $(binary)
	./$< --log2_length 27 --verify


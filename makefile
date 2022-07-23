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
SOURCE_FILES := main.cc
HEADER_FILES :=
REFERENCE_DIR := reference
VALIDATION_DIR := validation
SCALABILITY_DIR := scalability

##### Targets #####

REFERENCE_MAKEFILE := $(REFERENCE_DIR)/makefile
REFERENCE := $(REFERENCE_DIR)/single_random_access
BINARY := gups

##### Recipes #####

.PHONY: all test clean

all: $(BINARY)

$(BINARY): $(SOURCE_FILES) $(HEADER_FILES)
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCE_FILES)

test: $(BINARY)
	OMP_NUM_THREADS=1 ./$< --log2_length 27 --verify

$(REFERENCE): $(REFERENCE_MAKEFILE)
	cd $(REFERENCE_DIR) && $(MAKE)

$(REFERENCE_MAKEFILE):
	git submodule update --init --progress $(REFERENCE_DIR)

clean:
	rm -f $(BINARY) $(REFERENCE)

include $(VALIDATION_DIR)/module.mk
include $(SCALABILITY_DIR)/module.mk


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
SOURCE_FILES := main.cc
HEADER_FILES :=
REFERENCE_DIR := reference
VALIDATION_DIR := validation
SCALABILITY_DIR := scalability

##### Targets #####

SERIAL := serial
PARALLEL := parallel
REFERENCE_MAKEFILE := $(REFERENCE_DIR)/makefile
REFERENCE := $(REFERENCE_DIR)/single_random_access
BINARIES := $(SERIAL) $(PARALLEL)

##### Recipes #####

.PHONY: all test clean

all: $(BINARIES)

$(BINARIES): $(SOURCE_FILES) $(HEADER_FILES)
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCE_FILES)

$(PARALLEL): CXXFLAGS += -DOPENMP -fopenmp

test: $(BINARIES)
	./$(SERIAL) --log2length 27 --verify
	./$(PARALLEL) --log2length 27 --verify

$(REFERENCE): $(REFERENCE_MAKEFILE)
	cd $(REFERENCE_DIR)
	make

$(REFERENCE_MAKEFILE):
	git submodule update --init --progress $(REFERENCE_DIR)

clean:
	rm -f $(BINARIES) $(REFERENCE)

include $(VALIDATION_DIR)/module.mk
include $(SCALABILITY_DIR)/module.mk


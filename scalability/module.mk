##### Targets #####

SCALABILITY_RESULTS := $(SCALABILITY_DIR)/results.txt

##### Recipes #####

.PHONY: scale

scale: $(SCALABILITY_RESULTS)

$(SCALABILITY_RESULTS): $(PARALLEL)
	(for i in $$(seq 1 4) ; do OMP_NUM_THREADS=$$i numactl -m0 -N0 ./$< --log2length 27 ; done) | grep GUPS | cut -d"=" -f2 | tr -d " " > $@


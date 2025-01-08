##### Targets #####

scalability_results := $(scalability_dir)/results.txt

##### Recipes #####

.PHONY: scalability scalability/clean

scalability: $(scalability_results)

$(scalability_results): $(binary)
	(for i in $$(seq 1 4) ; do OMP_NUM_THREADS=$$i numactl -m0 -N0 ./$< --log2length 27 ; done) | grep GUPS | cut -d"=" -f2 | tr -d " " > $@

scalability/clean:
	rm -f $(scalability_results)


##### Constants #####
repeats := 5

##### Targets #####
our_results := $(validation_dir)/our_results.txt
ref_results := $(validation_dir)/ref_results.txt
all_results := $(validation_dir)/results.txt

##### Recipes #####
.PHONY: validation validation/clean

validation: $(all_results)
	$(validation_dir)/compare.py < $(all_results)

$(all_results): $(our_results) $(ref_results)
	paste -d ',' $^ > $@

$(our_results): $(binary)
	(
	for i in $$(seq 1 $(repeats)); do OMP_NUM_THREADS=1 ./$(binary) --log2_length 26 ; done
	) | grep GUPS | cut -d"=" -f2 | tr -d " " > $@

$(ref_results): $(reference)
	cd $(validation_dir)
	echo "Total=1024" > hpccmemf.txt
	for i in $$(seq 1 $(repeats)); do ../$(reference) ; done
	grep "Single GUP/s" hpccoutf.txt | cut -d" " -f3 > $(notdir $@)

validation/clean:
	rm -f $(our_results) $(ref_results) $(all_results) $(validation_dir)/hpccoutf.txt


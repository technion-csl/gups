##### Targets #####
our_results := $(validation_dir)/our_results.txt
ref_results := $(validation_dir)/ref_results.txt
all_results := $(validation_dir)/results.txt

##### Recipes #####

.PHONY: validate validate/clean

validate: $(all_results)

$(all_results): $(our_results) $(ref_results)
	paste $^ > $@

$(our_results): $(binary)
	(for i in $$(seq 1 5); do ./$(binary) --log2length 27 ; done) | grep GUPS | cut -d"=" -f2 | tr -d " " > $@

$(ref_results): $(reference)
	cd $(validation_dir)
	echo "Total=2048" > hpccmemf.txt
	for i in $$(seq 1 5); do ../$(reference) ; done
	grep "Single GUP/s" hpccoutf.txt | cut -d" " -f3 > $(notdir $@)

validate/clean:
	rm -f $(our_results) $(ref_results) $(all_results) hpccoutf.txt


##### Targets #####

SERIAL_RESULTS := $(VALIDATION_DIR)/serial_results.txt
REFERENCE_RESULTS := $(VALIDATION_DIR)/reference_results.txt

##### Recipes #####

.PHONY: validate

validate: $(SERIAL_RESULTS) $(REFERENCE_RESULTS)
	cat $<

$(SERIAL_RESULTS): $(SERIAL)
	(for i in $$(seq 1 5); do ./$(SERIAL) --log2length 27 ; done) | grep GUPS | cut -d"=" -f2 | tr -d " " > $@

$(REFERENCE_RESULTS): $(REFERENCE)
	cd $(VALIDATION_DIR)
	echo "Total=2048" > hpccmemf.txt
	for i in $$(seq 1 5); do ../$(REFERENCE) ; done
	grep "Single GUP/s" hpccoutf.txt | cut -d" " -f3 > $(notdir $@)


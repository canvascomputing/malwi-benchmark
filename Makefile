# Benchmark runner
# Usage: make run "<command> @" <model> <tool>
#
#   Iterates over all sample ZIPs, unpacks each, replaces @ with the
#   unpacked path, runs the command, and reports timing.
#   Results are written to results/<date>_<model>_<tool>.md.
#
#   The command must print a JSON object to stdout:
#     { "label": "malicious", "input_tokens": 12500, "output_tokens": 830 }

SHELL := /bin/bash

SAMPLES_DIR := samples
ZIP_PASSWORD := malwi
ZIPS := $(shell find $(SAMPLES_DIR) -name '*.zip' 2>/dev/null | sort)
DATE := $(shell date +%m-%d-%Y)

# Parse positional args from command line goals:
#   make run "<cmd> @" <model> <tool>
#   GOALS = run <cmd-words...> <model> <tool>
GOALS := $(MAKECMDGOALS)
NUM_GOALS := $(words $(GOALS))
TOOL := $(word $(NUM_GOALS),$(GOALS))
MODEL_POS := $(shell echo $$(( $(NUM_GOALS) - 1 )))
MODEL := $(word $(MODEL_POS),$(GOALS))
CMD_END := $(shell echo $$(( $(NUM_GOALS) - 2 )))
CMD_TEMPLATE := $(wordlist 2,$(CMD_END),$(GOALS))

RESULTS_DIR := results
RESULTS_FILE := $(RESULTS_DIR)/$(DATE)_$(MODEL)_$(TOOL).md

.PHONY: run

run:
	@if [ $(NUM_GOALS) -lt 4 ]; then \
		echo "Usage: make run \"<command> @\" <model> <tool>"; \
		echo ""; \
		echo "  @ is replaced with the unpacked sample path"; \
		echo ""; \
		echo "  The command must print JSON to stdout:"; \
		echo '    { "label": "malicious", "input_tokens": 12500, "output_tokens": 830 }'; \
		exit 1; \
	fi; \
	if [ -z '$(ZIPS)' ]; then \
		echo "No .zip samples found in $(SAMPLES_DIR)/"; \
		exit 1; \
	fi; \
	mkdir -p $(RESULTS_DIR); \
	TMPDIR=$$(mktemp -d); \
	trap 'rm -rf "$$TMPDIR"' EXIT; \
	\
	TOTAL=0; \
	TP=0; FP=0; FN=0; TN=0; \
	SUM_INPUT=0; SUM_OUTPUT=0; SUM_TIME=0; \
	ROWS=""; \
	\
	for ZIP in $(ZIPS); do \
		NAME=$$(basename "$$ZIP" .zip); \
		ZIPDIR=$$(dirname "$$ZIP"); \
		YAML="$$ZIPDIR/$$NAME.yaml"; \
		EXPECTED=""; \
		if [ -f "$$YAML" ]; then \
			EXPECTED=$$(grep '^label:' "$$YAML" | awk '{print $$2}'); \
		fi; \
		DEST="$$TMPDIR/$$NAME"; \
		mkdir -p "$$DEST"; \
		unzip -q -P $(ZIP_PASSWORD) -o "$$ZIP" -d "$$DEST" 2>/dev/null; \
		CMD=$$(echo '$(CMD_TEMPLATE)' | sed "s|@|$$DEST|g"); \
		START=$$(perl -MTime::HiRes=time -e 'printf "%f", time()'); \
		OUTPUT=$$(eval "$$CMD" 2>/dev/null); \
		STATUS=$$?; \
		END=$$(perl -MTime::HiRes=time -e 'printf "%f", time()'); \
		ELAPSED=$$(perl -e "printf '%.2f', $$END - $$START"); \
		\
		PREDICTED=$$(echo "$$OUTPUT" | perl -MJSON::PP -e 'my $$j=decode_json(join "",<STDIN>); print $$j->{label}//"error"' 2>/dev/null || echo "error"); \
		INPUT_TOK=$$(echo "$$OUTPUT" | perl -MJSON::PP -e 'my $$j=decode_json(join "",<STDIN>); print $$j->{input_tokens}//0' 2>/dev/null || echo "0"); \
		OUTPUT_TOK=$$(echo "$$OUTPUT" | perl -MJSON::PP -e 'my $$j=decode_json(join "",<STDIN>); print $$j->{output_tokens}//0' 2>/dev/null || echo "0"); \
		\
		if [ "$$PREDICTED" = "$$EXPECTED" ]; then MATCH="yes"; else MATCH="no"; fi; \
		if [ "$$EXPECTED" = "malicious" ] && [ "$$MATCH" = "yes" ]; then TP=$$((TP + 1)); fi; \
		if [ "$$EXPECTED" = "malicious" ] && [ "$$MATCH" = "no" ];  then FN=$$((FN + 1)); fi; \
		if [ "$$EXPECTED" != "malicious" ] && [ "$$PREDICTED" = "malicious" ]; then FP=$$((FP + 1)); fi; \
		if [ "$$EXPECTED" != "malicious" ] && [ "$$PREDICTED" != "malicious" ] && [ "$$MATCH" = "yes" ]; then TN=$$((TN + 1)); fi; \
		\
		TOTAL=$$((TOTAL + 1)); \
		SUM_INPUT=$$((SUM_INPUT + INPUT_TOK)); \
		SUM_OUTPUT=$$((SUM_OUTPUT + OUTPUT_TOK)); \
		SUM_TIME=$$(perl -e "printf '%.2f', $$SUM_TIME + $$ELAPSED"); \
		\
		ROWS="$$ROWS| $$NAME | $$EXPECTED | $$PREDICTED | $$MATCH | $$INPUT_TOK | $$OUTPUT_TOK | $${ELAPSED}s |\n"; \
		echo "$$NAME  expected=$$EXPECTED  predicted=$$PREDICTED  match=$$MATCH  time=$${ELAPSED}s"; \
		rm -rf "$$DEST"; \
	done; \
	\
	if [ $$((TP + FP)) -gt 0 ]; then \
		PRECISION=$$(perl -e "printf '%.1f', $$TP / ($$TP + $$FP) * 100"); \
	else \
		PRECISION="n/a"; \
	fi; \
	if [ $$((TP + FN)) -gt 0 ]; then \
		RECALL=$$(perl -e "printf '%.1f', $$TP / ($$TP + $$FN) * 100"); \
	else \
		RECALL="n/a"; \
	fi; \
	AVG_TIME=$$(perl -e "printf '%.2f', $$SUM_TIME / $$TOTAL"); \
	AVG_INPUT=$$(perl -e "printf '%.0f', $$SUM_INPUT / $$TOTAL"); \
	AVG_OUTPUT=$$(perl -e "printf '%.0f', $$SUM_OUTPUT / $$TOTAL"); \
	\
	{ \
		echo "# Benchmark Results"; \
		echo ""; \
		echo "- **Date:** $(DATE)"; \
		echo "- **Model:** $(MODEL)"; \
		echo "- **Tool:** $(TOOL)"; \
		echo ""; \
		echo "## Summary"; \
		echo ""; \
		echo "| Metric | Value |"; \
		echo "|--------|-------|"; \
		echo "| Samples | $$TOTAL |"; \
		echo "| Precision | $${PRECISION}% |"; \
		echo "| Recall | $${RECALL}% |"; \
		echo "| Avg. input tokens | $$AVG_INPUT |"; \
		echo "| Avg. output tokens | $$AVG_OUTPUT |"; \
		echo "| Total input tokens | $$SUM_INPUT |"; \
		echo "| Total output tokens | $$SUM_OUTPUT |"; \
		echo "| Avg. time | $${AVG_TIME}s |"; \
		echo "| Total time | $${SUM_TIME}s |"; \
		echo ""; \
		echo "## Results"; \
		echo ""; \
		echo "| Sample | Expected | Predicted | Match | Input tokens | Output tokens | Time |"; \
		echo "|--------|----------|-----------|-------|--------------|---------------|------|"; \
		printf "$$ROWS"; \
	} > $(RESULTS_FILE); \
	\
	echo ""; \
	echo "Results written to $(RESULTS_FILE)"

# Catch-all: prevent make from treating command words as targets
%:
	@:

SHELL := /bin/bash

GOALS := $(MAKECMDGOALS)
NUM_GOALS := $(words $(GOALS))
TOOL := $(word $(NUM_GOALS),$(GOALS))
MODEL_POS := $(shell echo $$(( $(NUM_GOALS) - 1 )))
MODEL := $(word $(MODEL_POS),$(GOALS))
CMD_END := $(shell echo $$(( $(NUM_GOALS) - 2 )))
CMD_TEMPLATE := $(wordlist 2,$(CMD_END),$(GOALS))

.PHONY: run

run:
	@scripts/run "$(CMD_TEMPLATE)" "$(MODEL)" "$(TOOL)"

%:
	@:

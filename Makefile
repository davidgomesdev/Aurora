HOST ?= "http://l3n"
MODEL ?= amalia-poeta:fp16

PROMPT = $(filter-out ask ask-quick,$(MAKECMDGOALS))

.PHONY: ask ask-quick create create-quick

# make ask 'Quem foi Fernando Pessoa?'  (needs create once)
ask:
	@jq -n --arg p "$(PROMPT)" '{model:"$(MODEL)", prompt:$$p, stream:false}' \
	  | curl -s "$(HOST):11434/api/generate" -d @- \
	  | jq -r .response

# make ask-quick 'Quem foi Fernando Pessoa?'
ask-quick: MODEL = amalia-poeta:q4
ask-quick: ask

create:
	ollama create amalia-poeta:fp16 -f model/FP16.Modelfile

create-quick:
	ollama create amalia-poeta:q4 -f model/Q4_K_M.Modelfile

# ponytail: swallows the prompt words so make doesn't treat them as targets
%:
	@:

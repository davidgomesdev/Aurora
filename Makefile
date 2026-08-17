HOST ?= "http://127.0.0.1"
MODEL ?= amalia-poeta:fp16

PROMPT = $(filter-out ask ask-quick ask-stream ask-quick-stream,$(MAKECMDGOALS))

.PHONY: ask ask-quick ask-stream ask-quick-stream create create-quick

# make ask 'Quem foi Fernando Pessoa?'  (needs create once)
ask:
	@jq -n --arg p "$(PROMPT)" '{model:"$(MODEL)", prompt:$$p, stream:false}' \
	  | curl -s "$(HOST):11434/api/generate" -d @- \
	  | jq -r .response

# make ask-quick 'Quem foi Fernando Pessoa?'
ask-quick: MODEL = amalia-poeta:q4
ask-quick: ask

# make ask-stream 'Quem foi Fernando Pessoa?'  (prints tokens as they arrive)
ask-stream:
	@jq -n --arg p "$(PROMPT)" '{model:"$(MODEL)", prompt:$$p, stream:true}' \
	  | curl -s -N "$(HOST):11434/api/generate" -d @- \
	  | jq -j --unbuffered .response
	@echo

# make ask-quick-stream 'Quem foi Fernando Pessoa?'
ask-quick-stream: MODEL = amalia-poeta:q4
ask-quick-stream: ask-stream

create:
	ollama create amalia-poeta:fp16 -f model/FP16.Modelfile

create-quick:
	ollama create amalia-poeta:q4 -f model/Q4_K_M.Modelfile

# ponytail: swallows the prompt words so make doesn't treat them as targets
%:
	@:

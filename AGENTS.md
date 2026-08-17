# AGENTS.md — Aurora

## What this is

Aurora: Ollama models that write poetry in European Portuguese. Home Assistant calls the
Ollama endpoint directly (rest_command / conversation agent) and speaks the reply
through TTS on a speaker.

Two paths, two models — this is the thing to keep straight:

- **Scheduled quote — fp16.** Generated ahead of time and spoken at a set hour.
  Nobody is waiting on it, so it gets the slow, better model. Never generate it
  at speak time; pre-load it.
- **Live chat — q4.** Someone asked a question out loud and is standing there.
  Latency is the requirement; quality comes second.

This repo owns both sides: the models/prompts and the Home Assistant YAML that
calls them. The Makefile exists so a human (or you) can test a prompt without
going through HA.

## Layout

    model/FP16.Modelfile     amalia-poeta:fp16  — the scheduled quote
    model/Q4_K_M.Modelfile   amalia-poeta:q4    — live chat
    homeassistant/           HA YAML: rest_command, automation, TTS script
    Makefile                 local testing + model builds

The `homeassistant/` YAML is a package, included from HA's `configuration.yaml`.
Editing it here changes nothing until HA reloads.

Both Modelfiles are the same file except the `FROM` quant tag and `num_ctx`.
Change one, change the other — but leave `num_ctx` alone: fp16 runs at 32768
(EuroLLM-9B's native max), q4 stays at 8192 on purpose. The live-chat path pays
for a bigger KV cache in first-token latency, and a poem never needs the room.

## Working here

    make ask 'Quem foi Fernando Pessoa?'        # fp16, the scheduled-quote path
    make ask-quick 'Quem foi Fernando Pessoa?'  # q4, the live-chat path
    make create        # rebuild fp16 (~18GB pull the first time)
    make create-quick  # rebuild q4

`HOST` defaults to `http://l3n`; override on the command line.

Editing a Modelfile does nothing until you re-run the matching `create` target.
Always re-run `ask` after a prompt change and read the actual output — prompt
edits fail silently, they just produce worse poems.

## The output is spoken, not read

Everything the model returns goes straight to a speaker. So:

- European Portuguese only. No Brazilian vocabulary or constructions. This is the
  point of the SYSTEM prompt — don't weaken it.
- No markdown, headings, bullets, emoji, or stage directions. TTS reads them out.
- It comes out of an Alexa Echo (`notify.echo_speak`, SSML). Alexa has no European
  Portuguese voice — `<lang xml:lang="pt-BR">` is what makes it speak Portuguese at
  all. Brazilian accent, European words: that trade is deliberate, leave it.
- Model output goes into SSML, so it must be escaped (`| e`) before any `<break/>`
  tags are inserted.
- Short. A few lines. Nobody wants a sonnet at 8am.

## Constraints

- Shell and Make only. No Python, no new dependencies, no framework.
- Sampling params (`temperature`, `top_p`, `repeat_penalty`, `num_ctx`) live in the
  Modelfiles. Tune them there, not in the request body.
- Model names are load-bearing: the HA config references `amalia-poeta:q4` from
  both rest_commands. Rename a model and you rename it in `homeassistant/` too.
  The scheduled quote is *supposed* to use `amalia-poeta:fp16` — it points at q4
  only because fp16 is broken and unbuilt (see `troubleshooting/`). Put it back
  when that is fixed.
- Test a prompt change on both models. They share a Modelfile body, so a prompt
  that only behaves on fp16 is a broken prompt.

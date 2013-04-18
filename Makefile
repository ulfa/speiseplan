
PREFIX:=../
DEST:=$(PREFIX)$(PROJECT)
ERL=erl
REBAR=./rebar
SESSION_CONFIG_DIR=priv/test_session_config

.PHONY: deps get-deps

all:
	@$(REBAR) get-deps
	@$(REBAR) compile

clean:
	@$(REBAR) clean

get-deps:
	@$(REBAR) get-deps

deps:
	@$(REBAR) compile

test:
	@$(REBAR) skip_deps=true eunit

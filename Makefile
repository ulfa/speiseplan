PROJECT = speiseplan
DIALYZER = dialyzer
REBAR = rebar
REPO = ../repository
REPOSRC = ../../repository
TARGET = ~/kantine



all: app

tar:  
	cd ..; tar --exclude=$(PROJECT)/.git --exclude=$(PROJECT)/Mnesia.speiseplan* --exclude=$(PROJECT)/priv/static/billing/* --exclude=$(PROJECT)/*/.DS_Store --exclude=$(PROJECT)/.DS_Store --exclude=$(PROJECT)/log/* -cvf $(REPO)/$(PROJECT).$(VERSION).tar $(PROJECT)

cpall: tar
	cd ..;scp $(REPOSRC)/$(PROJECT).src.$(VERSION).tar $(USR)@$(HOST):$(TARGET)
	ssh $(USR)@$(HOST) 'cd $(TARGET); tar xf $(TARGET)/$(PROJECT).src.$(VERSION).tar'

cp: 
	scp $(REPOSRC)/$(PROJECT).$(VERSION).tar $(USR)@$(HOST):$(TARGET)

release: app
	@$(REBAR) generate

app: deps
	@$(REBAR) compile

deps:
	@$(REBAR) get-deps

clean:
	@$(REBAR) clean
	rm -f test/*.beam
	rm -f erl_crash.dump
	rm -f log/*

tests: clean app eunit ct

eunit:
	@$(REBAR) eunit skip_deps=true


docs:
	@$(REBAR) doc skip_deps=true

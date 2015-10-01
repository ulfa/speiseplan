PROJECT = speiseplan
DIALYZER = dialyzer
REBAR = ./rebar
REPO = ../repository
REPOSRC = ../../repository
TARGET = ~/kantine
LOG_DIR = ../../innoq_icook
DATE = `date +%Y-%m-%d`



all: app

tar: app 
	cd ..; tar --exclude=$(PROJECT)/.git --exclude=$(PROJECT)/Mnesia.speiseplan* --exclude=$(PROJECT)/priv/static/billing/* --exclude=$(PROJECT)/*/.DS_Store --exclude=$(PROJECT)/.DS_Store --exclude=$(PROJECT)/log/* -cvf $(REPO)/$(PROJECT).$(VERSION).tar $(PROJECT)

cpall: tar
	scp $(REPOSRC)/$(PROJECT).$(VERSION).tar $(USR)@$(HOST):$(TARGET)
	ssh $(USR)@$(HOST) 'cd $(TARGET); tar xf $(TARGET)/$(PROJECT).$(VERSION).tar'

cp: tar
	scp $(REPOSRC)/$(PROJECT).$(VERSION).tar $(USR)@$(HOST):$(TARGET)

cp_log: 
	mkdir -p $(LOG_DIR)/$(DATE)
	scp $(USR)@$(HOST):$(TARGET)/$(PROJECT)/log/*.log* $(LOG_DIR)/$(DATE)/

cp_db:
		mkdir -p $(LOG_DIR)/db/$(DATE)
		scp -r $(USR)@$(HOST):$(TARGET)/$(PROJECT)/Mnesia.* $(LOG_DIR)/db/$(DATE)/

cp_backup:
		mkdir -p $(LOG_DIR)/backup/$(DATE)
		scp -r $(USR)@$(HOST):$(TARGET)/backup/mnesia.backup $(LOG_DIR)/backup/$(DATE)/

cp_backup_latest:
		mkdir -p ./backup/latest
		scp -r $(USR)@$(HOST):$(TARGET)/backup/mnesia.backup ./backup/latest/

cp_boss_config:
		mkdir -p $(LOG_DIR)/config/$(DATE)
		scp -r $(USR)@$(HOST):$(TARGET)/$(PROJECT)/boss.config $(LOG_DIR)/config/$(DATE)/

cp_boss_config_latest:
		mkdir -p $(LOG_DIR)/config/latest
		scp -r $(USR)@$(HOST):$(TARGET)/$(PROJECT)/boss.config $(LOG_DIR)/config/latest/
		
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

install:
	find . -name '._*'|xargs rm
tests: clean app eunit ct

eunit:
	@$(REBAR) eunit skip_deps=true


docs:
	@$(REBAR) doc skip_deps=true

show_logs:
	git log `git describe --tags --abbrev=0`..HEAD --oneline

REBAR := ./rebar

all: get-deps compile compile-app

get-deps:
	$(REBAR) get-deps

compile:
	$(REBAR) compile

compile-app:
	$(REBAR) boss c=compile

test:
	$(REBAR) boss c=test_functional

help:
	@echo 'Makefile for your chicagoboss app                                      '
	@echo '                                                                       '
	@echo 'Usage:                                                                 '
	@echo '   make help                        displays this help text            '
	@echo '   make get-deps                    updates all dependencies           '
	@echo '   make compile                     compiles dependencies              '
	@echo '   make compile-app                 compiles only your app             '
	@echo '                                    (so you can reload via init.sh)    '
	@echo '   make test                        runs functional tests              '
	@echo '   make all                         get-deps compile compile-app       '
	@echo '                                                                       '
	@echo 'DEFAULT:                                                               '
	@echo '   make all                                                            '
	@echo '                                                                       '

.PHONY: all get-deps compile compile-app help test

show_logs:
	git shortlog `git describe --tags --abbrev=0`..HEAD --oneline

tar: 
	rm -f erl_crash.dump
	cd ..; tar --exclude=$(PROJECT)/.git --exclude=$(PROJECT)/Mnesia.speiseplan* --exclude=$(PROJECT)/priv/static/billing/* --exclude=$(PROJECT)/*/.DS_Store --exclude=$(PROJECT)/.DS_Store --exclude=$(PROJECT)/log/* -cvf $(REPO)/$(PROJECT).$(VERSION).tar $(PROJECT)

dist_qa: tar
	scp $(REPOSRC)/$(PROJECT).$(VERSION).tar $(USR)@$(HOST):$(TARGET)
	ssh $(USR)@$(HOST) 'cd $(TARGET); tar xf $(TARGET)$(PROJECT).$(VERSION).tar'
	ssh $(USR)@$(HOST) 'cd $(TARGET)/speiseplan; make install'

dist: tar
	scp $(REPOSRC)/$(PROJECT).$(VERSION).tar $(USR)@$(HOST):~/

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
		mkdir -p ./config/latest
		scp -r $(USR)@$(HOST):$(TARGET)/$(PROJECT)/boss.config ./config/latest/

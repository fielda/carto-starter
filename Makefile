.PHONY: rebuild up down logs all_logs query
.DEFAULT_GOAL := help

# Set defaults
c?=nginx
q?="error"

BIN=docker-compose
# BIN=docker-compose -f docker-compose.yml

help:
	@echo "Usage: make [OPTION] [c=\"container\"] [q=\"query\"]"
	@echo ""
	@echo "Options"
	@echo "  help        -- print this help"
	@echo "  rebuild     -- bring down, then build"
	@echo "  up          -- bring up"
	@echo "  down        -- bring down"
	@echo "  logs        -- get Docker logs for the specified container"
	@echo "  query       -- search Docker logs of all containers (case insensitive)"
	@echo ""
	@echo "* 'help' is the default [OPTION]"
	@echo "* 'nginx' is the default [container]"
	@echo "* 'error' is the default [query]"

rebuild:
	$(BIN) down && $(BIN) build && $(BIN)

up:
	$(BIN) up -d $(c)

down:
	$(BIN) down

logs:
	$(BIN) logs --follow --tail="all" $(c)

all_logs:
	$(BIN) logs --follow --tail="all"

query:
	$(BIN) logs | grep -i -B 1 -A 1 --color=always "$(q)"

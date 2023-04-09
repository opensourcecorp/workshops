SHELL := /usr/bin/env bash

pyvenv = source ./venv/bin/activate

# This target should be invoked on first clone to ensure the developer
# workstation is setup correctly with dependencies
setup:
	@printf 'Initializing submodules...\n'
	@make -s -C proto submodules
	@printf 'Getting Go package deps...\n'
	@go mod tidy
	@printf 'Getting Go tool deps from tools.go...\n'
	@grep -E -o '".*"' tools.go | xargs -I{} go install {}
	@printf 'Setting up Python dependencies...\n'
	@python3 -m venv --clear venv && $(pyvenv) && python3 -m pip install -r requirements.txt

# This target is just here to make regeneration easier without changing
# directories
gen:
	@make -s -C ./proto generate

server-go:
	@go run ./servers/server.go

server-py:
	@$(pyvenv) && python3 ./servers/server.py

client-go:
	@go run ./clients/client.go $(name)

client-py:
	@$(pyvenv) && python3 ./clients/client.py $(name)

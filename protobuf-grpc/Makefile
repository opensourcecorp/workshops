SHELL := /usr/bin/env bash

pyvenv = source ./venv/bin/activate

# This target should be invoked on first clone to ensure the developer
# workstation is setup correctly with dependencies
setup:
	@printf 'Initializing protobuf dependencies...\n'
	@make -s -C proto get-proto-deps
	@printf 'Getting Go package deps...\n'
	@go mod tidy
	@printf 'Getting Go tool deps from tools.go...\n'
	@grep -E -o '".*"' tools.go | xargs -I{} go install {}
	@printf 'Setting up Python dependencies...\n'
	@python3 -m venv --clear venv && $(pyvenv) && python3 -m pip install -r requirements.txt

# This target is just here to make regeneration easier without changing
# directories
gen:
	@make -s -C ./proto gen gen-custom

# Wrappers for running clients & servers of each language
server-go:
	@go run ./servers/server.go

server-py:
	@$(pyvenv) && python3 ./servers/server.py

client-go:
	@go run ./clients/client.go $(name)

client-py:
	@$(pyvenv) && python3 ./clients/client.py $(name)

# Shows how to use grpcurl as well
client-grpcurl:
	@printf 'Echo("Hello, gRPC!"):\n'
	@grpcurl -plaintext -protoset=./proto/protoset -d '{"msg": "Hello, gRPC!"}' localhost:8080 echo.v1.EchoService/Echo
	@printf 'ListEmployees():\n'
	@grpcurl -plaintext -protoset=./proto/protoset localhost:8080 employees.v1.EmployeesService/ListEmployees
	@printf 'GetEmployee($(name)):\n'
	@grpcurl -plaintext -protoset=./proto/protoset -d '{"short_name": "$(name)"}' localhost:8080 employees.v1.EmployeesService/GetEmployee

# Verifies behavior of tooling & other code in the repo
test-docker:
	@docker build -t opensourcecorp.org/workshops/protobuf-grpc:latest .

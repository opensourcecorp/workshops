SHELL = /usr/bin/env bash -euo pipefail

outdir := ../pb

# These are the input proto files, i.e. what is going to be compiled
proto_files := ./*/*/*.proto

# Helper vars for proto dependencies (i.e. what are used in any referenced imports)
proto_deps_rootdir := /tmp/proto-deps
proto_deps_sources :=	github.com/googleapis/googleapis \
											github.com/google/protobuf
proto_deps_import_flags :=	-I=. \
														-I=$(proto_deps_rootdir)/github.com/googleapis/googleapis \
														-I=$(proto_deps_rootdir)/github.com/google/protobuf/src

# So that the Python generation works off of the virtual environment's dependencies
pyvenv = source ../venv/bin/activate

get-proto-deps:
	@mkdir -p /tmp/proto-deps
	@for dep in $(proto_deps_sources) ; do git clone --depth=1 https://"$${dep}" $(proto_deps_rootdir)/"$${dep}" || true ; done

ensure-outdir:
	@mkdir -p $(outdir)

# Most langs code can be generated directly by protoc
generate: ensure-outdir
	@printf 'Generating protobuf code...\n'
	@$(pyvenv) && \
	protoc \
		$(proto_deps_import_flags) \
		--go_out=$(outdir) \
		--go_opt=paths=source_relative \
		--go-grpc_out=$(outdir) \
		--go-grpc_opt=paths=source_relative \
		--go-grpc_opt=require_unimplemented_servers=false \
		--grpc-gateway_out=$(outdir) \
		--grpc-gateway_opt=logtostderr=true \
    --grpc-gateway_opt=paths=source_relative \
    --grpc-gateway_opt=generate_unbound_methods=true \
		--python_out=$(outdir) \
		--descriptor_set_out=./protoset \
		--include_imports \
		$(proto_files)
# ... but Python gRPC seems to be an angry elf, so we have to use a protoc
# distro that's in the grpcio_tools Python module
	@printf 'Generating Python gRPC code, specifically...\n'
	@$(pyvenv) && \
	python3 -m grpc_tools.protoc \
		$(proto_deps_import_flags) \
		--grpc_python_out=$(outdir) \
		$(proto_files)
# AND ALSO we need to modify an import line in the generated code, or else that
# code's module pathing won't work as-generated. It would work if the proto
# file(s) AND the generated output were in the same directory, but we don't have
# our tree set up that way
	@printf 'Fixing Python import statements...\n'
	@find $(outdir) -type f -name '*.py' | xargs -I{} sed -E -i 's/^from .*\.v[0-9]+ import (.*)/from . import \1/g' {}

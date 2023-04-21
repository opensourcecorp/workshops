.PHONY: build gen

build:
	@go build -o ./build/ .

gen: build
	@mkdir -p ./pb
	@printf 'Generating code using custom protoc plugin...\n'
	@protoc \
		--plugin=./build/protoc-gen-list-messages \
		-I../proto \
		--list-messages_out=./pb \
		--list-messages_opt=paths=source_relative \
		../proto/echo/v1/*.proto

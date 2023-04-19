.PHONY: build gen

build:
	@go build -o ./build/ .

gen: build
	@mkdir -p ./pb
	@protoc \
		--plugin=./build/protoc-gen-list-messages \
		-I../proto \
		--list-messages_out=./pb \
		--list-messages_opt=paths=source_relative \
		../proto/echo/v1/*.proto

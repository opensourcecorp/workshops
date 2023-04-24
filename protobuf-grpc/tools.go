//go:build tools

package tools

import (
	_ "github.com/bufbuild/buf/cmd/buf" // currently only for linting proto files
	_ "github.com/fullstorydev/grpcurl/cmd/grpcurl"
	_ "github.com/google/gnostic/cmd/protoc-gen-openapi" // note that the commit pinned in go.mod is the earliest that this was usable in a way that allowed per-proto-package output
	_ "github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway"
	_ "google.golang.org/grpc/cmd/protoc-gen-go-grpc"
	_ "google.golang.org/protobuf/cmd/protoc-gen-go"
)

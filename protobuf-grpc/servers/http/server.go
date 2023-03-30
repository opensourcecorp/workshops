package main

import (
	"context"
	"fmt"
	"log"
	"net"

	examplepb "github.com/ryapric/workshops/protobuf-grpc/pb/example/v1"
	httppb "github.com/ryapric/workshops/protobuf-grpc/pb/http/v1"
	"google.golang.org/grpc"
)

const addr = "127.0.0.1:8080"

type exampleServiceServer struct {
	// You can make this embedded struct required via a `protoc` Go option,
	// which essentially allows you to NOT fully implement the generated
	// interface (i.e. optionally leave out method definitions). We're removing
	// it here because it makes it more clear when we've NOT implemented the
	// interface easier (i.e. the compiler will complain if any methods are
	// missing), but including it is considered 'best-practice' at the time of
	// this writing.

	pb.UnimplementedExampleServer
}

// The Echo method here implements the Echo part of the ExampleServiceServer
// interface, as defined in the proto file
func (s *exampleServiceServer) Echo(ctx context.Context, req *examplepb.EchoRequest) (*examplepb.EchoResponse, error) {
	msg := fmt.Sprintf("rpc call to 'Echo', received msg: '%s'", req.Msg)
	log.Printf(msg + " -- responding in kind\n")
	return &examplepb.EchoResponse{Msg: req.Msg}, nil
}

// The GetRecord method here implements the GetRecord part of the
// ExampleServiceServer interface, as defined as the proto file
func (s *exampleServiceServer) GetRecord(ctx context.Context, req *httppb.GetRecordRequest) (*httppb.GetRecordResponse, error) {
	log.Printf("Received the following request on 'GetRecord' --> %v", req)

	return &httppb.GetRecordResponse{
		Id:       1,
		Name:     req.GetName(),
		Birthday: "1991-01-01",
		Details:  []string{"some", "other", "stuff", "about", req.GetName()},
	}, nil
}

// This function contains the actual logic to run our gRPC server
func runServer(addr string) {
	listen, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatalf("Failed to listen on %s\n", addr)
	}
	var opts []grpc.ServerOption

	grpcServer := grpc.NewServer(opts...)
	httppb.RegisterHttpServiceServer(grpcServer, &exampleServiceServer{})

	log.Printf("starting server on %s...\n", listen.Addr())
	err = grpcServer.Serve(listen)
	if err != nil {
		log.Fatalln(err)
	}
}

func main() {
	runServer(addr)
}

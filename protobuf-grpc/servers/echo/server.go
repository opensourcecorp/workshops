package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"

	gwruntime "github.com/grpc-ecosystem/grpc-gateway/v2/runtime"

	echopb "github.com/ryapric/workshops/protobuf-grpc/pb/echo/v1"
	httppb "github.com/ryapric/workshops/protobuf-grpc/pb/http/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

const grpcAddr = "localhost:8080"
const httpAddr = "localhost:8081"

type echoServiceServer struct {
	// You can make this embedded struct required via a `protoc` Go option,
	// which essentially allows you to NOT fully implement the generated
	// interface (i.e. optionally leave out method definitions). We're removing
	// it here because it makes it more clear when we've NOT implemented the
	// interface (i.e. the compiler will complain if any methods are missing),
	// but including it is considered 'best-practice' at the time of this
	// writing.

	// echopb.UnimplementedEchoServiceServer
}

type httpServiceServer struct {
	// httppb.UnimplementedHttpServiceServer
}

// Echo implements the Echo message of the EchoServiceServer interface, as
// defined in the relevant proto file
func (s *echoServiceServer) Echo(ctx context.Context, req *echopb.EchoRequest) (*echopb.EchoResponse, error) {
	msg := fmt.Sprintf("rpc call to 'Echo', received msg: '%s' -- responding in kind\n", req.Msg)
	log.Println(msg)
	return &echopb.EchoResponse{Msg: req.Msg}, nil
}

// GetRecord implements the GetRecord message of the HttpServiceServer
// interface, as defined in the relevant proto file
func (s *httpServiceServer) GetRecord(ctx context.Context, req *httppb.GetRecordRequest) (*httppb.GetRecordResponse, error) {
	log.Printf("Received the following request on 'GetRecord' --> %+v", req)

	return &httppb.GetRecordResponse{
		Id:       1,
		Name:     req.GetName(),
		Birthday: "1991-01-01",
		Details:  []string{"some", "other", "stuff", "about", req.GetName()},
	}, nil
}

// TODO: put better docs here. I must have read tens of blogs, etc. (since the
// docs on some of this stuff are so sparse), but the latest that I pulled from
// & got working was this one:
// https://adevait.com/go/transcoding-of-http-json-to-grpc-using-go
func main() {
	listen, err := net.Listen("tcp", grpcAddr)
	if err != nil {
		log.Fatalf("Failed to listen on %s", grpcAddr)
	}

	var serveOpts []grpc.ServerOption
	grpcServer := grpc.NewServer(serveOpts...)
	echopb.RegisterEchoServiceServer(grpcServer, &echoServiceServer{})
	httppb.RegisterHttpServiceServer(grpcServer, &httpServiceServer{})

	// Since we're going to support gRPC calls, but *also* proxy HTTP calls to
	// this gRPC server, we send it off on its own goroutine
	go func() {
		log.Printf("starting gRPC server on %s...\n", listen.Addr())
		err = grpcServer.Serve(listen)
		if err != nil {
			log.Fatalf("error starting gRPC server: %v", err)
		}
	}()

	////////////////////////////////////////////////////////////////////////////
	// Now, for the gRPC-HTTP gateway server, we need to create a connection to
	// the now-running gRPC server, because that's where the gateway will proxy
	// requests
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	dialOpts := []grpc.DialOption{
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	}

	gwmux := gwruntime.NewServeMux()

	conn, err := grpc.DialContext(
		context.Background(),
		grpcAddr,
		dialOpts...,
	)
	if err != nil {
		log.Fatalf("error dialing gRPC server: %v", err)
	}

	err = httppb.RegisterHttpServiceHandler(ctx, gwmux, conn)
	if err != nil {
		log.Fatalf("error registering HTTP service handler: %v", err)
	}

	gwServer := &http.Server{
		Addr:    httpAddr,
		Handler: gwmux,
	}

	log.Printf("starting HTTP server on %s...\n", httpAddr)
	err = gwServer.ListenAndServe()
	if err != nil {
		log.Fatalf("error starting HTTP server: %v", err)
	}
}

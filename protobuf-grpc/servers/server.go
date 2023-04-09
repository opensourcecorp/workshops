package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"

	gwruntime "github.com/grpc-ecosystem/grpc-gateway/v2/runtime"

	echopb "github.com/ryapric/workshops/protobuf-grpc/pb/echo/v1"
	employeespb "github.com/ryapric/workshops/protobuf-grpc/pb/employees/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
)

const grpcAddr = "localhost:8080"
const httpAddr = "localhost:8081"

// Used to simulate a database of employee records
var employeeData = map[string]*employeespb.GetRecordResponse{
	// Tom is the current defaultcdoded in client.go
	"Tom": {
		Name:     "Thomas Anderson",
		Id:       1,
		Birthday: "1999-03-31",
	},
	"Michelle": {
		Name:     "Michelle Yeoh",
		Id:       2,
		Birthday: "1962-08-06",
	},
}

type echoServiceServer struct {
	// You can make the following embedded struct required via a `protoc` Go
	// option, which essentially allows you to NOT fully implement the generated
	// interface (i.e. optionally leave out method definitions). We're removing
	// it here because it makes it more clear when we've NOT implemented the
	// interface (i.e. the compiler will complain if any methods are missing),
	// but including it is considered 'best-practice' at the time of this
	// writing.

	// echopb.UnimplementedEchoServiceServer
}

type employeesServiceServer struct {
	// employeespb.UnimplementedEmployeesServiceServer
}

// Echo implements the Echo message of the EchoServiceServer interface, as
// defined in the relevant proto file
func (s *echoServiceServer) Echo(ctx context.Context, req *echopb.EchoRequest) (*echopb.EchoResponse, error) {
	log.Printf("rpc call to 'Echo', received msg: '%s' -- responding in kind\n", req.Msg)
	return &echopb.EchoResponse{Msg: req.Msg}, nil
}

// GetRecord implements the GetRecord message of the HttpServiceServer
// interface, as defined in the relevant proto file
func (s *employeesServiceServer) GetRecord(ctx context.Context, req *employeespb.GetRecordRequest) (*employeespb.GetRecordResponse, error) {
	log.Printf("Received the following request on 'GetRecord' --> %+v", req)

	if req.Name == "*" {
		return employeeData, nil
	}

	data, ok := employeeData[req.GetName()]
	if ok {
		return data, nil
	} else {
		return nil, status.Error(codes.NotFound, fmt.Sprintf("no employee data available for provided name '%s'", req.GetName()))
	}
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
	employeespb.RegisterEmployeesServiceServer(grpcServer, &employeesServiceServer{})

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

	err = employeespb.RegisterEmployeesServiceHandler(ctx, gwmux, conn)
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

// Code generated by protoc-gen-grpc-gateway. DO NOT EDIT.
// source: employees/v1/employees.proto

/*
Package v1 is a reverse proxy.

It translates gRPC into RESTful JSON APIs.
*/
package v1

import (
	"context"
	"io"
	"net/http"

	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"github.com/grpc-ecosystem/grpc-gateway/v2/utilities"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/grpclog"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
)

// Suppress "imported and not used" errors
var _ codes.Code
var _ io.Reader
var _ status.Status
var _ = runtime.String
var _ = utilities.NewDoubleArray
var _ = metadata.Join

func request_EmployeesService_GetEmployee_0(ctx context.Context, marshaler runtime.Marshaler, client EmployeesServiceClient, req *http.Request, pathParams map[string]string) (proto.Message, runtime.ServerMetadata, error) {
	var protoReq GetEmployeeRequest
	var metadata runtime.ServerMetadata

	var (
		val string
		ok  bool
		err error
		_   = err
	)

	val, ok = pathParams["short_name"]
	if !ok {
		return nil, metadata, status.Errorf(codes.InvalidArgument, "missing parameter %s", "short_name")
	}

	protoReq.ShortName, err = runtime.String(val)
	if err != nil {
		return nil, metadata, status.Errorf(codes.InvalidArgument, "type mismatch, parameter: %s, error: %v", "short_name", err)
	}

	msg, err := client.GetEmployee(ctx, &protoReq, grpc.Header(&metadata.HeaderMD), grpc.Trailer(&metadata.TrailerMD))
	return msg, metadata, err

}

func local_request_EmployeesService_GetEmployee_0(ctx context.Context, marshaler runtime.Marshaler, server EmployeesServiceServer, req *http.Request, pathParams map[string]string) (proto.Message, runtime.ServerMetadata, error) {
	var protoReq GetEmployeeRequest
	var metadata runtime.ServerMetadata

	var (
		val string
		ok  bool
		err error
		_   = err
	)

	val, ok = pathParams["short_name"]
	if !ok {
		return nil, metadata, status.Errorf(codes.InvalidArgument, "missing parameter %s", "short_name")
	}

	protoReq.ShortName, err = runtime.String(val)
	if err != nil {
		return nil, metadata, status.Errorf(codes.InvalidArgument, "type mismatch, parameter: %s, error: %v", "short_name", err)
	}

	msg, err := server.GetEmployee(ctx, &protoReq)
	return msg, metadata, err

}

func request_EmployeesService_ListEmployees_0(ctx context.Context, marshaler runtime.Marshaler, client EmployeesServiceClient, req *http.Request, pathParams map[string]string) (proto.Message, runtime.ServerMetadata, error) {
	var protoReq ListEmployeesRequest
	var metadata runtime.ServerMetadata

	msg, err := client.ListEmployees(ctx, &protoReq, grpc.Header(&metadata.HeaderMD), grpc.Trailer(&metadata.TrailerMD))
	return msg, metadata, err

}

func local_request_EmployeesService_ListEmployees_0(ctx context.Context, marshaler runtime.Marshaler, server EmployeesServiceServer, req *http.Request, pathParams map[string]string) (proto.Message, runtime.ServerMetadata, error) {
	var protoReq ListEmployeesRequest
	var metadata runtime.ServerMetadata

	msg, err := server.ListEmployees(ctx, &protoReq)
	return msg, metadata, err

}

// RegisterEmployeesServiceHandlerServer registers the http handlers for service EmployeesService to "mux".
// UnaryRPC     :call EmployeesServiceServer directly.
// StreamingRPC :currently unsupported pending https://github.com/grpc/grpc-go/issues/906.
// Note that using this registration option will cause many gRPC library features to stop working. Consider using RegisterEmployeesServiceHandlerFromEndpoint instead.
func RegisterEmployeesServiceHandlerServer(ctx context.Context, mux *runtime.ServeMux, server EmployeesServiceServer) error {

	mux.Handle("GET", pattern_EmployeesService_GetEmployee_0, func(w http.ResponseWriter, req *http.Request, pathParams map[string]string) {
		ctx, cancel := context.WithCancel(req.Context())
		defer cancel()
		var stream runtime.ServerTransportStream
		ctx = grpc.NewContextWithServerTransportStream(ctx, &stream)
		inboundMarshaler, outboundMarshaler := runtime.MarshalerForRequest(mux, req)
		var err error
		var annotatedContext context.Context
		annotatedContext, err = runtime.AnnotateIncomingContext(ctx, mux, req, "/employees.v1.EmployeesService/GetEmployee", runtime.WithHTTPPathPattern("/employees/v1/get_employee/{short_name}"))
		if err != nil {
			runtime.HTTPError(ctx, mux, outboundMarshaler, w, req, err)
			return
		}
		resp, md, err := local_request_EmployeesService_GetEmployee_0(annotatedContext, inboundMarshaler, server, req, pathParams)
		md.HeaderMD, md.TrailerMD = metadata.Join(md.HeaderMD, stream.Header()), metadata.Join(md.TrailerMD, stream.Trailer())
		annotatedContext = runtime.NewServerMetadataContext(annotatedContext, md)
		if err != nil {
			runtime.HTTPError(annotatedContext, mux, outboundMarshaler, w, req, err)
			return
		}

		forward_EmployeesService_GetEmployee_0(annotatedContext, mux, outboundMarshaler, w, req, resp, mux.GetForwardResponseOptions()...)

	})

	mux.Handle("GET", pattern_EmployeesService_ListEmployees_0, func(w http.ResponseWriter, req *http.Request, pathParams map[string]string) {
		ctx, cancel := context.WithCancel(req.Context())
		defer cancel()
		var stream runtime.ServerTransportStream
		ctx = grpc.NewContextWithServerTransportStream(ctx, &stream)
		inboundMarshaler, outboundMarshaler := runtime.MarshalerForRequest(mux, req)
		var err error
		var annotatedContext context.Context
		annotatedContext, err = runtime.AnnotateIncomingContext(ctx, mux, req, "/employees.v1.EmployeesService/ListEmployees", runtime.WithHTTPPathPattern("/employees/v1/list_employees"))
		if err != nil {
			runtime.HTTPError(ctx, mux, outboundMarshaler, w, req, err)
			return
		}
		resp, md, err := local_request_EmployeesService_ListEmployees_0(annotatedContext, inboundMarshaler, server, req, pathParams)
		md.HeaderMD, md.TrailerMD = metadata.Join(md.HeaderMD, stream.Header()), metadata.Join(md.TrailerMD, stream.Trailer())
		annotatedContext = runtime.NewServerMetadataContext(annotatedContext, md)
		if err != nil {
			runtime.HTTPError(annotatedContext, mux, outboundMarshaler, w, req, err)
			return
		}

		forward_EmployeesService_ListEmployees_0(annotatedContext, mux, outboundMarshaler, w, req, resp, mux.GetForwardResponseOptions()...)

	})

	return nil
}

// RegisterEmployeesServiceHandlerFromEndpoint is same as RegisterEmployeesServiceHandler but
// automatically dials to "endpoint" and closes the connection when "ctx" gets done.
func RegisterEmployeesServiceHandlerFromEndpoint(ctx context.Context, mux *runtime.ServeMux, endpoint string, opts []grpc.DialOption) (err error) {
	conn, err := grpc.DialContext(ctx, endpoint, opts...)
	if err != nil {
		return err
	}
	defer func() {
		if err != nil {
			if cerr := conn.Close(); cerr != nil {
				grpclog.Infof("Failed to close conn to %s: %v", endpoint, cerr)
			}
			return
		}
		go func() {
			<-ctx.Done()
			if cerr := conn.Close(); cerr != nil {
				grpclog.Infof("Failed to close conn to %s: %v", endpoint, cerr)
			}
		}()
	}()

	return RegisterEmployeesServiceHandler(ctx, mux, conn)
}

// RegisterEmployeesServiceHandler registers the http handlers for service EmployeesService to "mux".
// The handlers forward requests to the grpc endpoint over "conn".
func RegisterEmployeesServiceHandler(ctx context.Context, mux *runtime.ServeMux, conn *grpc.ClientConn) error {
	return RegisterEmployeesServiceHandlerClient(ctx, mux, NewEmployeesServiceClient(conn))
}

// RegisterEmployeesServiceHandlerClient registers the http handlers for service EmployeesService
// to "mux". The handlers forward requests to the grpc endpoint over the given implementation of "EmployeesServiceClient".
// Note: the gRPC framework executes interceptors within the gRPC handler. If the passed in "EmployeesServiceClient"
// doesn't go through the normal gRPC flow (creating a gRPC client etc.) then it will be up to the passed in
// "EmployeesServiceClient" to call the correct interceptors.
func RegisterEmployeesServiceHandlerClient(ctx context.Context, mux *runtime.ServeMux, client EmployeesServiceClient) error {

	mux.Handle("GET", pattern_EmployeesService_GetEmployee_0, func(w http.ResponseWriter, req *http.Request, pathParams map[string]string) {
		ctx, cancel := context.WithCancel(req.Context())
		defer cancel()
		inboundMarshaler, outboundMarshaler := runtime.MarshalerForRequest(mux, req)
		var err error
		var annotatedContext context.Context
		annotatedContext, err = runtime.AnnotateContext(ctx, mux, req, "/employees.v1.EmployeesService/GetEmployee", runtime.WithHTTPPathPattern("/employees/v1/get_employee/{short_name}"))
		if err != nil {
			runtime.HTTPError(ctx, mux, outboundMarshaler, w, req, err)
			return
		}
		resp, md, err := request_EmployeesService_GetEmployee_0(annotatedContext, inboundMarshaler, client, req, pathParams)
		annotatedContext = runtime.NewServerMetadataContext(annotatedContext, md)
		if err != nil {
			runtime.HTTPError(annotatedContext, mux, outboundMarshaler, w, req, err)
			return
		}

		forward_EmployeesService_GetEmployee_0(annotatedContext, mux, outboundMarshaler, w, req, resp, mux.GetForwardResponseOptions()...)

	})

	mux.Handle("GET", pattern_EmployeesService_ListEmployees_0, func(w http.ResponseWriter, req *http.Request, pathParams map[string]string) {
		ctx, cancel := context.WithCancel(req.Context())
		defer cancel()
		inboundMarshaler, outboundMarshaler := runtime.MarshalerForRequest(mux, req)
		var err error
		var annotatedContext context.Context
		annotatedContext, err = runtime.AnnotateContext(ctx, mux, req, "/employees.v1.EmployeesService/ListEmployees", runtime.WithHTTPPathPattern("/employees/v1/list_employees"))
		if err != nil {
			runtime.HTTPError(ctx, mux, outboundMarshaler, w, req, err)
			return
		}
		resp, md, err := request_EmployeesService_ListEmployees_0(annotatedContext, inboundMarshaler, client, req, pathParams)
		annotatedContext = runtime.NewServerMetadataContext(annotatedContext, md)
		if err != nil {
			runtime.HTTPError(annotatedContext, mux, outboundMarshaler, w, req, err)
			return
		}

		forward_EmployeesService_ListEmployees_0(annotatedContext, mux, outboundMarshaler, w, req, resp, mux.GetForwardResponseOptions()...)

	})

	return nil
}

var (
	pattern_EmployeesService_GetEmployee_0 = runtime.MustPattern(runtime.NewPattern(1, []int{2, 0, 2, 1, 2, 2, 1, 0, 4, 1, 5, 3}, []string{"employees", "v1", "get_employee", "short_name"}, ""))

	pattern_EmployeesService_ListEmployees_0 = runtime.MustPattern(runtime.NewPattern(1, []int{2, 0, 2, 1, 2, 2}, []string{"employees", "v1", "list_employees"}, ""))
)

var (
	forward_EmployeesService_GetEmployee_0 = runtime.ForwardResponseMessage

	forward_EmployeesService_ListEmployees_0 = runtime.ForwardResponseMessage
)
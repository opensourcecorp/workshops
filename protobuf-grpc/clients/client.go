package main

import (
	"context"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	echopb "github.com/ryapric/workshops/protobuf-grpc/pb/echo/v1"
	employeespb "github.com/ryapric/workshops/protobuf-grpc/pb/employees/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

const grpcAddr = "localhost:8080"
const httpAddr = "http://localhost:8081"
const cliArgsMsg = "warning: not calling GetEmployee() because you must provide an employee's short name on the CLI. Did you look at the output of the ListEmployees() call?"

func callGRPCServer() {
	ctx := context.Background()

	dialOpts := []grpc.DialOption{
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	}

	conn, err := grpc.Dial(grpcAddr, dialOpts...)
	if err != nil {
		log.Fatalf("error dialing gRPC: %v\n", err)
	}
	defer conn.Close()

	// Echo call just returns the same message back
	echoClient := echopb.NewEchoServiceClient(conn)
	msg := "Hello, gRPC!"
	echoResponse, err := echoClient.Echo(ctx, &echopb.EchoRequest{Msg: msg})
	if err != nil {
		log.Fatalf("error calling gRPC Echo(): %v\n", err)
	}
	log.Printf("gRPC Echo('%s'): received Echo back: '%s'\n", msg, echoResponse.Msg)

	// This client is used for all the Employees Service calls
	employeesClient := employeespb.NewEmployeesServiceClient(conn)

	// ListEmployees returns a list of all employees' short names
	shortNames, err := employeesClient.ListEmployees(ctx, &employeespb.ListEmployeesRequest{})
	if err != nil {
		log.Fatalf("error calling gRPC ListEmployees(): %v\n", err)
	}
	log.Printf("gRPC ListEmployees(): got the following short names: '%s'\n", strings.Join(shortNames.ShortNames, ", "))

	// GetEmployee returns a single employee by their short name
	var shortNameToGet string
	if len(os.Args) < 2 {
		log.Printf("gRPC: %s", cliArgsMsg)
		return
	} else {
		shortNameToGet = os.Args[1]
	}
	getEmployeeResponse, err := employeesClient.GetEmployee(ctx, &employeespb.GetEmployeeRequest{ShortName: shortNameToGet})
	if err != nil {
		log.Fatalf("error calling gRPC GetEmployee('%s'): %v\n", shortNameToGet, err)
	}
	log.Printf("gRPC GetEmployee(%s): { %+v }\n", shortNameToGet, getEmployeeResponse)
}

// Now, let's call the same gRPC services, but over HTTP!
func callHTTPServer() {
	listResp, err := http.Get(httpAddr + "/employees/v1/list_employees")
	if err != nil {
		log.Fatalf("error calling ListEmployees service over HTTP: %v", err)
	}

	listBody, err := io.ReadAll(listResp.Body)
	if err != nil {
		log.Fatalf("error reading ListEmployees response body: %v", err)
	}

	log.Printf("HTTP ListEmployees(): %s", listBody)

	if len(os.Args) < 2 {
		log.Printf("HTTP: %s", cliArgsMsg)
		return
	} else {
		shortNameToGet := os.Args[1]
		getResp, err := http.Get(httpAddr + "/employees/v1/get_employee/" + shortNameToGet)
		if err != nil {
			log.Fatalf("error calling GetEmployee('%s') over HTTP: %v", shortNameToGet, err)
		}

		getBody, err := io.ReadAll(getResp.Body)
		if err != nil {
			log.Fatalf("error reading GetEmployee('%s') response body: %v", shortNameToGet, err)
		}
		defer getResp.Body.Close()

		log.Printf("HTTP GetEmployee('%s'): %s", shortNameToGet, getBody)
	}
}

func main() {
	callGRPCServer()
	callHTTPServer()
}

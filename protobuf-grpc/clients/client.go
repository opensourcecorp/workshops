package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	echopb "github.com/ryapric/workshops/protobuf-grpc/pb/echo/v1"
	employeespb "github.com/ryapric/workshops/protobuf-grpc/pb/employees/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

const grpcAddr = "localhost:8080"
const httpAddr = "localhost:8081"

func main() {
	ctx := context.Background()

	dialOpts := []grpc.DialOption{
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	}

	conn, err := grpc.Dial(grpcAddr, dialOpts...)
	if err != nil {
		log.Fatalf("error dialing grpc: %v\n", err)
	}
	defer conn.Close()

	echoClient := echopb.NewEchoServiceClient(conn)
	echoResponse, err := echoClient.Echo(context.TODO(), &echopb.EchoRequest{Msg: "hello grpc"})
	if err != nil {
		log.Fatalf("error calling rpc Echo(): %v\n", err)
	}
	fmt.Printf("called rcp Echo(): received Echo back: %s\n", echoResponse.Msg)

	employeeNames := make([]string, 1)
	if len(os.Args) > 1 {
		employeeNames = os.Args[1:]
	} else {
		employeeNames[0] = "Tom"
	}

	employeesClient := employeespb.NewEmployeesServiceClient(conn)
	var responses []*employeespb.GetRecordResponse
	for _, name := range employeeNames {
		getRecordResponse, err := employeesClient.GetRecord(ctx, &employeespb.GetRecordRequest{Name: name})
		if err != nil {
			log.Fatalf("error calling rpc GetRecord(): %v\n", err)
		}
		responses = append(responses, getRecordResponse)
	}
	out, err := json.MarshalIndent(responses, "", "  ")
	if err != nil {
		log.Fatalf("could not marshal json from response: %v", err)
	}
	fmt.Printf("called rpc GetRecord(): Got the following JSON record(s) back for the name query for '%s':\n", strings.Join(employeeNames, ", "))
	fmt.Println(string(out))
}

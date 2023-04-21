"""
Example Python gRPC client that calls the gRPC server
"""
# Need to modify path search for protobuf output dir, because... Python.
# sys.path is modified to be able to be called from either this, or the
# parent/root dir. That way, we can import starting from the 'pb' package as
# intended.
import os
import sys
sys.path.append(os.path.abspath("."))
sys.path.append(os.path.abspath(".."))

import grpc
import pb.echo.v1.echo_pb2 as echo_pb2
import pb.echo.v1.echo_pb2_grpc as echo_pb2_grpc
import pb.employees.v1.employees_pb2 as employees_pb2
import pb.employees.v1.employees_pb2_grpc as employees_pb2_grpc

# Note that if you did NOT specify --pyi_out in the protoc call, you won't get
# editor help like tab completion for the generated code -- everything comes out
# as a metaclass unless you also generate those .pyi files
if __name__ == "__main__":
    with grpc.insecure_channel("127.0.0.1:8080") as channel:
        echo_stub = echo_pb2_grpc.EchoServiceStub(channel)

        echo_request = echo_pb2.EchoRequest(msg = "Hello, gRPC!")
        echo_response = echo_stub.Echo(echo_request)
        print(echo_response)

        employees_stub = employees_pb2_grpc.EmployeesServiceStub(channel)
        list_request = employees_pb2.ListEmployeesRequest()
        list_response = employees_stub.ListEmployees(list_request)
        print(list_response)

        if len(sys.argv) < 2:
            print("warning: not calling GetEmployee() because you must provide an employee's short name on the CLI. Did you look at the output of the ListEmployees() call?")
        else:
            get_request = employees_pb2.GetEmployeeRequest(short_name = sys.argv[1])
            get_response = employees_stub.GetEmployee(get_request)
            print(get_response)

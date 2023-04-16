"""
Python gRPC server that implements the Echo Service
"""
from concurrent import futures
import grpc
import logging
import os
import sys

# Need to modify path search for protobuf output dir, because... Python.
# sys.path is modified to be able to be called from either this, or the
# parent/root dir. That way, we can import starting from the 'pb' package as
# intended.
sys.path.append(os.path.abspath("."))
sys.path.append(os.path.abspath(".."))

import pb.echo.v1.echo_pb2 as echo_pb2
import pb.echo.v1.echo_pb2_grpc as echo_pb2_grpc
import pb.employees.v1.employees_pb2 as employees_pb2
import pb.employees.v1.employees_pb2_grpc as employees_pb2_grpc

addr = "127.0.0.1:8080"

# Used to simulate a database of employee records
employee_data = {
	"Tom": {
		"full_name": "Thomas Anderson",
		"id":       1,
		"birthday": "1999-03-31",
	},
	"Michelle": {
		"full_name": "Michelle Yeoh",
		"id":       2,
		"birthday": "1962-08-06",
	},
	"Sabrina": {
		"full_name": "Sabrina Spellman",
		"id":       3,
		"birthday": "1980-09-27",
	},
}

# gRPC server implementations in Python work by subclassing the generated
# Servicers (it's best to use identical names), and defining methods that each
# correspond to a protobuf Service definition
class EchoServiceServicer(echo_pb2_grpc.EchoServiceServicer):
    def Echo(self, request, context):
        print(f"rpc call to 'Echo': received msg: '{request.msg}' -- responding in kind")
        return echo_pb2.EchoResponse(msg = request.msg)

class EmployeesServiceServicer(employees_pb2_grpc.EmployeesServiceServicer):
    def GetEmployee(self, request, context):
        print(f"rcp call to 'GetEmployee': {request}")
        return employees_pb2.GetEmployeeResponse(employee = employee_data[request.short_name])
    def ListEmployees(self, request, context):
        print("rcp call to 'ListEmployees' (no request data)")
        return employees_pb2.ListEmployeesResponse(short_names = employee_data)

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers = 10))
    echo_pb2_grpc.add_EchoServiceServicer_to_server(EchoServiceServicer(), server)
    employees_pb2_grpc.add_EmployeesServiceServicer_to_server(EmployeesServiceServicer(), server)
    server.add_insecure_port(addr)
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    print(f"Starting server on {addr}...")
    serve()

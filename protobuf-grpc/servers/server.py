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
# import pb.employees.v1.employees_pb2 as employees_pb2
# import pb.employees.v1.employees_pb2_grpc as employees_pb2_grpc

addr = "127.0.0.1:8080"

# gRPC server implementations in Python work by subclassing the generated
# Servicers (it's best to use identical names), and defining methods that each
# correspond to a protobuf Service definition
class EchoServiceServicer(echo_pb2_grpc.EchoServiceServicer):
    def Echo(self, request, context):
        return echo_pb2.EchoResponse(msg = request.msg)

# class EmployeesServiceServicer(employees_pb2_grpc.EmployeesServiceServicer):
#     def GetEmployee(self, request, context):
#         return employees_pb2.GetEmployeeResponse(None)
#     def ListEmployees(self, request, context):
#         return employees_pb2.ListEmployeesResponse(None)

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers = 10))
    echo_pb2_grpc.add_EchoServiceServicer_to_server(EchoServiceServicer(), server)
    server.add_insecure_port(addr)
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    print(f"Starting server on {addr}...")
    serve()

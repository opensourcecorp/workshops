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

import pb.echo.v1.echo_pb2 as echopb2
import pb.echo.v1.echo_pb2_grpc as echopb2_grpc

addr = "127.0.0.1:8080"

class Example(echopb2_grpc.EchoServiceStub):
    def Echo(self, request, context):
        return echopb2.EchoResponse(msg = request.msg)

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers = 10))
    echopb2_grpc.add_EchoServiceServicer_to_server(echopb2_grpc.EchoServiceServicer, server)
    server.add_insecure_port(addr)
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    print(f"Starting server on {addr}...")
    serve()

"""
Example Python gRPC server that can be called by any lang's gRPC client
"""
# Need to modify path search for protobuf output dir, because... Python.
# sys.path is modified to be able to be called from either this, or the
# parent/root dir. That way, we can import starting from the 'pb' package as
# intended.
import os
import sys

sys.path.append(os.path.abspath("."))
sys.path.append(os.path.abspath(".."))

import logging
from concurrent import futures

import grpc
import pb.example.v1.example_pb2 as example_pb2
import pb.example.v1.example_pb2_grpc as example_pb2_grpc

addr = "127.0.0.1:8080"

class Example(example_pb2_grpc.ExampleService):
    def Echo(self, request, context):
        return example_pb2.EchoResponse(msg = request.msg)

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers = 10))
    example_pb2_grpc.add_ExampleServiceServicer_to_server(Example(), server)
    server.add_insecure_port(addr)
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    print(f"Starting server on {addr}...")
    serve()

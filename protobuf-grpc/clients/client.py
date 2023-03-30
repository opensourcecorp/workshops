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
import pb.example.v1.example_pb2 as example_pb2
import pb.example.v1.example_pb2_grpc as example_pb2_grpc

if __name__ == "__main__":
    with grpc.insecure_channel("127.0.0.1:8080") as channel:
        stub = example_pb2_grpc.ExampleServiceStub(channel)

        # This is pretty infuriating -- Python protobuf code isn't generated
        # directly, it generates a *Python* generator to generate the code at
        # runtime (in *_pb2.py). As such, you don't get completion hints in
        # editors because there's no data types to autofill etc. So, look at
        # your proto file and determine how you should be setting up your
        # requests!
        echo_request = example_pb2.EchoRequest(msg = "hello grpc")
        echo_response = stub.Echo(echo_request)
        print(echo_response)

        getrecord_request = example_pb2.GetRecordRequest(name = "Thomas Anderson")
        getrecord_response = stub.GetRecord(getrecord_request)
        print(getrecord_response)

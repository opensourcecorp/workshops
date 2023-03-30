Protocol Buffers & gRPC
=======================

TODO: THIS WORKSHOP IS NOT READY YET
------------------------------------

This directory contains samples that generate [protocol
buffers](https://developers.google.com/protocol-buffers) from a `.proto` file in
two different languages, and defines a server & client in both to demonstrate
[gRPC](https://grpc.io) calls against the server regardless of which language
it's running in.

The proto definitions are found under the `proto/` directory, organized
according to what is deemed best-practice -- the proto package name, and version
number. Protocol buffers themselves are generated via:

    make gen

run from either this root directory or the `proto/` directory. You can inspect
the `proto/Makefile` to see the commands needed to generate the code.

The generated protobufs themselves are stored in the `pb/` directory.

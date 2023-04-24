# This Dockerfile is here to validate that the workshop contents & instructions
# behave as expected on a fresh machine. It's not meant to deploy or run
# anything for use in the actual workshop

FROM debian:unstable

RUN mkdir -p /root/protobuf-grpc
WORKDIR /root/protobuf-grpc

ENV PATH="/root/go/bin:${PATH}"

COPY ./proto ./proto
COPY go.* .
COPY *.go .
COPY requirements.txt .

RUN apt-get update && apt-get install -y \
      git \
      golang \
      make \
      procps \
      protobuf-compiler \
      psmisc \
      python3 \
      python3-pip \
      python3-venv

COPY Makefile .
RUN make setup
COPY ./protoc-gen-bash ./protoc-gen-bash
RUN make gen

# We copy these up last because they depend on the generated code (which you
# will note we did not copy into this image)
COPY ./clients ./clients
COPY ./servers ./servers

# These actually run the test cases. You can ignore the errors shown for killed
# processes
RUN for serverlang in go py ; do \
      for clientlang in go py grpcurl ; do \
        printf 'Running server for %s\n' "${serverlang}" && \
        sleep 1 && \
        (make server-"${serverlang}" &) && \
        sleep 2 && \
        printf 'Running client for %s\n' "${clientlang}" && \
        sleep 1 && \
        make client-"${clientlang}" name=Tom && \
        sleep 2 && \
        (pgrep -fa server | grep -v 'sh -c' | awk '{ print $1 }' | xargs -I{} kill {}) && \
        sleep 2 ; \
      done ; \
    done
RUN bash ./pb/echo/v1/echo_bash.pb.sh && \
    bash ./pb/employees/v1/employees_bash.pb.sh

FROM golang:1.12.6 as builder

ENV PROTOC_VER 3.8.0
ENV RELEASE_DIR /app
WORKDIR $GOPATH/src/github.com/nvogel/echogrpc
COPY . .

RUN apt-get update -y && \
    apt-get install -y apt-utils zip unzip; \
    wget -q -P /tmp/temp/ https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VER}/protoc-${PROTOC_VER}-linux-x86_64.zip; \
    cd /usr && unzip /tmp/temp/protoc-${PROTOC_VER}-linux-x86_64.zip; \
    go get -u -v github.com/golang/protobuf/protoc-gen-go \
    github.com/golang/dep/cmd/dep;

RUN make linux

FROM centos:7.6.1810

COPY --from=builder /app/echo-grpc-server* /server
COPY --from=builder /app/echo-grpc-server* /client
RUN chmod +x client && chmod +x server
CMD ["/server"]

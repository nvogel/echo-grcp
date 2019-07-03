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

# Create appuser
RUN useradd -U appuser

RUN make linux

FROM scratch

# Copy our static executable
COPY --from=builder /app/echogrpc-server* /server
COPY --from=builder /app/echogrpc-client* /client

# Copy /etc/passwd so the user will list with his name instead of an Id
COPY --from=builder /etc/passwd /etc/passwd

# Use an unprivileged user.
USER appuser

ENTRYPOINT ["/server"]

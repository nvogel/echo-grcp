// Package main implements a server for Greeter service.
package main

import (
	"context"
	"log"
	"net"
	"os"
	"google.golang.org/grpc"
	pb "github.com/nvogel/echogrpc/helloworld"
)

const (
	port = ":50051"
)

// server is used to implement helloworld.GreeterServer.
type server struct{}

// SayHello implements helloworld.GreeterServer
func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
    hostname, err := os.Hostname()

    if err != nil {
        log.Printf("Could not get hostname: %v", err)
		hostname = "unknown"
    }

	log.Printf("Received %v", in.Name)
	return &pb.HelloReply{Message: "Hello " + in.Name + " from " + hostname}, nil
}

func main() {
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	log.Printf("Welcome to the Grcp server")
	pb.RegisterGreeterServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

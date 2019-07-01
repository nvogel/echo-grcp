/*
 *
 * Copyright 2015 gRPC authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

// Package main implements a client for Greeter service.
package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/sercand/kuberesolver"
	"google.golang.org/grpc/balancer/roundrobin"
	"google.golang.org/grpc"
    pb "github.com/nvogel/echogrpc/helloworld"
)

const (
	defaultName = "world"
)

func getEnv(key, fallback string) string {
    if value, ok := os.LookupEnv(key); ok {
        return value
    }
    log.Print(key + "env not set")
    return fallback
}

func main() {

	address := getEnv("SERVER", "localhost:50051")
	mode := getEnv("MODE", "k8s")

	// Set up a connection to the server.
    var err error
	var conn *grpc.ClientConn

	if mode == "k8s" {
		kuberesolver.RegisterInCluster()
		conn, err = grpc.Dial("kubernetes:///" + address,grpc.WithBalancerName(roundrobin.Name), grpc.WithInsecure())

	} else {
		conn, err = grpc.Dial(address, grpc.WithInsecure())
	}

	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}

	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	// Contact the server and print out its response.
	name := defaultName
	if len(os.Args) > 1 {
		name = os.Args[1]
	}

	for {
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		r, err := c.SayHello(ctx, &pb.HelloRequest{Name: name})
		if err != nil {
			log.Fatalf("could not greet: %v", err)
		}
		log.Printf("Greeting: %s", r.Message)
		time.Sleep(2 * time.Second)
		cancel()
	}
}

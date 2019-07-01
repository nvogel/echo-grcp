# App parameters
APP?=echogrpc
PROJECT?=github.com/nvogel/${APP}
RELEASE_DIR?=release
RELEASE=$(shell git symbolic-ref -q --short HEAD 2> /dev/null || git describe --tags --exact-match 2> /dev/null || echo $(TRAVIS_BRANCH))
COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Go parameters
BIN_DIR := $(GOPATH)/bin
GOMETALINTER := $(BIN_DIR)/gometalinter
PROTOCGENGO := $(BIN_DIR)/protoc-gen-go

PLATFORMS := windows linux darwin
os = $(word 1, $@)

# Docker parameters
NS ?= nvgl
DOCKER_USERNAME ?= nvgl+travis
DOCKER_REGISTRY ?= quay.io
IMAGE_BUILD=$(APP):$(RELEASE)-$(COMMIT)
IMAGE_RELEASE=$(DOCKER_REGISTRY)/$(NS)/$(NAME):$(RELEASE)

proto: $(PROTOCGENGO) helloworld/helloworld.proto ### lenerate a go file from protocol buffers
	protoc -I helloworld/ helloworld/helloworld.proto --go_out=plugins=grpc:helloworld

.PHONY: release
release: $(PLATFORMS) ### Release

.PHONY: $(PLATFORMS)
$(PLATFORMS): proto dep ### Build per platform
	mkdir -p ${RELEASE_DIR}
	GOOS=$(os) GOARCH=amd64 go build \
		-ldflags "-s -w \
		-X ${PROJECT}/version.Release=${RELEASE} \
		-X ${PROJECT}/version.Commit=${COMMIT} \
		-X ${PROJECT}/version.BuildTime=${BUILD_TIME}" \
		-o ${RELEASE_DIR}/${APP}-server-$(RELEASE)-$(os)-amd64 ./server
	GOOS=$(os) GOARCH=amd64 go build \
		-ldflags "-s -w \
		-X ${PROJECT}/version.Release=${RELEASE} \
		-X ${PROJECT}/version.Commit=${COMMIT} \
		-X ${PROJECT}/version.BuildTime=${BUILD_TIME}" \
		-o ${RELEASE_DIR}/${APP}-client-$(RELEASE)-$(os)-amd64 ./client
.PHONY: dep
dep: ### init dependencies
	dep ensure --vendor-only

.PHONY: build
build-images: ### Build docker image
        docker build -t ${IMAGE_BUILD} .

.PHONY: push
push: ### Push image to registry
	@echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin $(DOCKER_REGISTRY)
	docker tag $(IMAGE_BUILD) $(IMAGE_RELEASE)
	docker push ${IMAGE_RELEASE}

.PHONY: clean
clean: ### Clean
	rm -rf "release"

.PHONY: test
test: ### Tests
	go test -race -v ./...

.PHONY: lint
lint: $(GOMETALINTER) ### Lint
	gometalinter --vendor --disable-all --enable=errcheck --enable=vet --enable=deadcode ./...

$(GOMETALINTER): ### Install Gometalinter if needed
	go get -u github.com/alecthomas/gometalinter
	gometalinter --install

$(PROTOCGENGO): ### Install protoc-gen-go
	go get -u github.com/golang/protobuf/protoc-gen-go

.PHONY: help
help: ## Help
	@echo '--------------------------------------------------------------------------'
	@grep -E '### .*$$' $(MAKEFILE_LIST) | grep -v '@grep' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "---"
	@echo "Platforms are $(PLATFORMS)"
	@echo "GOMETALINTER is $(GOMETALINTER)"
	@echo '--------------------------------------------------------------------------'

PROTO_DIR=proto
GEN_DIR=grpc
GOOGLEAPIS_DIR=googleapis

GIT_HASH?=$(shell git rev-parse --short HEAD)
GIT_TAG?=$(shell git tag | tail -1)
GIT_BRANCH?=$(shell git rev-parse --abbrev-ref HEAD)
GIT_BRANCH_CLR?=$(shell echo "$(GIT_BRANCH)" | sed -r 's/\//-/g')
OS=$(shell go env GOOS)
GOLANG_IMAGE := reg-ci.works.prod.sbt/sbt_dev/synd/golang/golang-builder:1.24.2

pr-build:
	git config --global --add safe.directory /go/src && go build main.go

test: pr-build
	go test main.go -coverprofile cov.out

build:
	docker run --rm -v $(shell pwd):/go/src/ -w /go/src/ $(GOLANG_IMAGE) make test


.PHONY: generate
generate:
	@echo "Generating protobuf files..."
	@mkdir -p $(GEN_DIR)
	# Генерация для spec.proto
	@protoc -I $(PROTO_DIR) \
	   -I $(GOOGLEAPIS_DIR) \
	   --go_out=$(GEN_DIR) --go_opt=paths=source_relative \
	   $(PROTO_DIR)/io/cloudevents/v1/*.proto
	# Генерация для ControlPlaneService.proto и EventAdapterService.proto
	@protoc -I $(PROTO_DIR) \
	   -I $(GOOGLEAPIS_DIR) \
	   --go_out=$(GEN_DIR) --go_opt=paths=source_relative \
	   --go-grpc_out=$(GEN_DIR) --go-grpc_opt=paths=source_relative \
	   --grpc-gateway_out=$(GEN_DIR) --grpc-gateway_opt=paths=source_relative \
	   $(PROTO_DIR)/synes/adapter/v1/*.proto
	@echo "Formatting generated code..."
	@gofmt -w $(GEN_DIR)
	@echo "Generation complete!"

.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	@rm -rf $(GEN_DIR)
	@echo "Clean complete!"

.PHONY: deps
deps:
	@echo "Installing protoc plugins..."
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
	@echo "Dependencies installed!"
# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)
SRCFILES=$(shell find . -type f -name '*.go' -not -path "./vendor/*")
BUILDTAGS=

.PHONY: clean all fmt vet lint build test install static
.DEFAULT: default

all: clean build fmt lint test vet install

build:
	@echo "==> Running $@..."
	@go build -tags "$(BUILDTAGS) cgo" -o replicator-local .

static:
	@echo "==> Running $@..."
	CGO_ENABLED=1 go build -tags "$(BUILDTAGS) cgo static_build" -ldflags "-w -extldflags -static" -o ghb0t .

fmt:
	@echo "==> Running $@..."
	@if [ -n "$$(gofmt -s -l $(SRCFILES) )" ]; then \
		echo 'Please run go fmt on your code before submitting the code for reviewal.' \
		&& exit 1; fi

lint:
	@echo "==> Running $@..."
	@golint ./... | grep -v vendor | tee /dev/stderr

test: fmt lint vet
	@echo "==> Running $@..."
	@go test -race -v -tags "$(BUILDTAGS) cgo" $(shell go list ./... | grep -v vendor)

vet:
	@echo "==> Running $@..."
	@go list ./... \
	| grep -v /vendor/ \
	| cut -d '/' -f 4- \
	| xargs -n1 \
	go tool vet ;\
	if [ $$? -ne 0 ]; then \
	echo ""; \
	echo "Vet found suspicious constructs. Please check the reported constructs"; \
	echo "and fix them if necessary before submitting the code for reviewal."; \
	fi

clean:
	@echo "==> Running $@..."
	@rm -rf ghb0t

install:
	@echo "==> Running $@..."
	@go install .

release:
	@echo "==> Running $@..."
	@echo "Latest 3 tags: "; \
	git ls-remote --tags | awk '{print $$2}' | sort -V | tail -n 3; \
	read -p "Enter New Tag:" tag; \
	echo "Releasing new tag: $$tag"; \
	git tag $$tag; \
	git push origin $$tag -f; \
	goreleaser --rm-dist

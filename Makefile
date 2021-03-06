BIN := ide
PKG := github.com/nrocco/ide
VERSION := $(shell git describe --tags --always --dirty)
COMMIT := $(shell git describe --always --dirty)
DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
PKG_LIST := $(shell go list ${PKG}/... | grep -v ${PKG}/vendor/)
GO_FILES := $(shell git ls-files '*.go')

GOOS := $(shell go env GOOS)
GOARCH := $(shell go env GOARCH)
LDFLAGS = "-d -s -w -X ${PKG}/cmd.version=${VERSION} -X ${PKG}/cmd.commit=${COMMIT} -X ${PKG}/cmd.buildDate=${DATE}"
BUILD_ARGS = -a -tags netgo -installsuffix netgo -ldflags $(LDFLAGS)

PREFIX = /usr

.DEFAULT_GOAL: build

build/${BIN}-$(GOOS)-$(GOARCH): $(GO_FILES)
	mkdir -p build
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=0 go build ${BUILD_ARGS} -o $@ ${PKG}

.PHONY: deps
deps:
	dep ensure

server/server.pb.go: server/server.proto
	protoc -I server/ server/server.proto --go_out=plugins=grpc:server

.PHONY: lint
lint: server/server.pb.go
	golint -set_exit_status ${PKG_LIST}

.PHONY: vet
vet: server/server.pb.go
	go vet -v ${PKG_LIST}

.PHONY: test
test: server/server.pb.go
	go test -short ${PKG_LIST}

.PHONY: coverage
coverage:
	mkdir -p coverage && rm -rf coverage/*
	for package in ${PKG_LIST}; do go test -covermode=count -coverprofile "coverage/$${package##*/}.cov" "$$package"; done
	echo mode: count > coverage/coverage.cov
	tail -q -n +2 coverage/*.cov >> coverage/coverage.cov
	go tool cover -func=coverage/coverage.cov

.PHONY: version
version:
	@echo ${VERSION}

.PHONY: clean
clean:
	rm -rf build

.PHONY: build
build: build/${BIN}-${GOOS}-${GOARCH}

.PHONY: build-all
build-all:
	$(MAKE) build GOOS=linux GOARCH=amd64
	$(MAKE) build GOOS=darwin GOARCH=amd64

.PHONY: releases
releases: build-all
	mkdir -p "build/${BIN}-${VERSION}"
	cp bin/rgit "build/${BIN}-${VERSION}/rgit"
	build/${BIN}-${GOOS}-${GOARCH} completion > "build/${BIN}-${VERSION}/completion.zsh"
	mv build/${BIN}-linux-amd64 "build/${BIN}-${VERSION}/${BIN}"
	tar czf "build/${BIN}-${VERSION}-linux-amd64.tar.gz" -C build/ "${BIN}-${VERSION}"
	mv build/${BIN}-darwin-amd64 "build/${BIN}-${VERSION}/${BIN}"
	tar czf "build/${BIN}-${VERSION}-darwin-amd64.tar.gz" -C build/ "${BIN}-${VERSION}"
	rm -rf "build/${BIN}-${VERSION}"

.PHONY: install
install: build/$(BIN)-$(GOOS)-$(GOARCH)
	mkdir -p "$(DESTDIR)$(PREFIX)/bin"
	cp "$<" "$(DESTDIR)$(PREFIX)/bin/$(BIN)"
	build/${BIN}-${GOOS}-${GOARCH} completion > "$(DESTDIR)$(PREFIX)/share/zsh/site-functions/_$(BIN)"
	cp bin/rgit "$(DESTDIR)$(PREFIX)/bin/rgit"

.PHONY: uninstall
uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/$(BIN)"
	rm -f "$(DESTDIR)$(PREFIX)/share/zsh/site-functions/_$(BIN)"
	rm -f "$(DESTDIR)$(PREFIX)/bin/rgit"

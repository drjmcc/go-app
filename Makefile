.DEFAULT_GOAL = help

APP := davidmcc99/go-app
PKG := $(shell go list ./internal/...)

COMPOSE_FILE := deployments/compose/docker-compose.yml
COMPOSE_PROJECT_NAME := $(APP)
IMAGE := $(APP)

export COMPOSE_FILE
export COMPOSE_PROJECT_NAME

ENVFILE := .env
ifeq ("$(wildcard $(ENVFILE))","")
	ENVFILE := env.dist
endif
include $(ENVFILE)

# Go tools
BIN_DIR := ${GOPATH}/bin
COVER   := $(BIN_DIR)/cover
LINTER  := $(BIN_DIR)/golangci-lint

$(COVER):
	@go get -u golang.org/x/tools/cmd/cover

$(LINTER):
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(BIN_DIR) v1.23.7

.env: # Environment file imported by make and docker-compose
	@[ -f .env ] || cp env.dist .env

go.mod:
	@go mod tidy
	@go mod verify

## help: List available build targets and descriptions
.PHONY: help
help: Makefile
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'

## version: Display the current version
#VERSION := $(shell git describe --tags --always --dirty || development)
ifeq "$(strip $(VERSION))" ""
 VERSION := $(shell git describe --always --tags --dirty)
ifeq "$(findstring -dirty,$(VERSION))" ""
 VERSION := $(VERSION)$(if $(shell git status --porcelain),-dirty,)
endif
endif

.PHONY: version
version:
	@echo $(VERSION)

ifeq "$(strip $(SHORTHASH))" ""
 SHORTHASH := $(shell git rev-parse --short HEAD)
endif

.PHONY: shorthash
shorthash:
	@echo $(SHORTHASH)

## build: Build and tag an application Docker image
.PHONY: build

DOCKERFILE := build/package/docker/app/Dockerfile
DATE       := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
TS         := $(shell date +%s)
PLATFORM_AMD64 := amd64
PLATFORM_ARM64 := arm64

build:
	@go mod vendor
	docker build --network=host \
	  --file=$(DOCKERFILE) \
	  --build-arg PLATFORM="$(PLATFORM_AMD64)" \
	  --build-arg TITLE="$(APP)" \
	  --build-arg DATE="${DATE}" \
	  --build-arg VERSION="${VERSION}" \
	  --tag=$(IMAGE):$(VERSION) \
	  --tag=$(IMAGE):$(SHORTHASH) \
	  --tag=$(IMAGE):latest \
	  .
	@rm -rf vendor

build-arm64:
	@go mod vendor
	docker build --network=host \
	  --file=$(DOCKERFILE) \
	  --build-arg PLATFORM="$(PLATFORM_ARM64)" \
	  --build-arg TITLE="$(APP)" \
	  --build-arg DATE="${DATE}" \
	  --build-arg VERSION="${VERSION}" \
	  --tag=$(IMAGE):$(VERSION) \
	  --tag=$(IMAGE):$(SHORTHASH) \
	  --tag=$(IMAGE):latest \
	  .
	@rm -rf vendor

## push: Upload the most recent application image to the Docker registry
.PHONY: push
push:
	docker tag $(IMAGE):$(SHORTHASH) $(IMAGE):$(VERSION)
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):$(SHORTHASH)
ifeq ($(ENVIRONMENT),prod)	
ifneq "$(strip $(SERVICE_TAG))" ""
	docker push $(IMAGE):latest
	docker tag $(IMAGE):$(VERSION) $(IMAGE):prod-$(SERVICE_TAG)-$(VERSION)-$(TS)
	docker push $(IMAGE):prod-$(SERVICE_TAG)-$(VERSION)-$(TS)
endif
else ifeq ($(ENVIRONMENT),dev)
ifneq "$(strip $(SERVICE_TAG))" ""
	docker tag $(IMAGE):$(VERSION) $(IMAGE):dev-$(SERVICE_TAG)-$(VERSION)-$(TS)
	docker push $(IMAGE):dev-$(SERVICE_TAG)-$(VERSION)-$(TS)
endif
endif

## start: Start application container(s) with Docker Compose
.PHONY: start
start: .env
	@IMAGE=$(IMAGE) TAG=latest docker-compose up -d

## stop: Stop application container(s) with Docker Compose
.PHONY: stop
stop:
	@IMAGE=$(IMAGE) TAG=latest docker-compose down

## restart: Restart application container(s) with Docker Compose
.PHONY: restart
restart: stop start

## test: Run tests
.PHONY: test
test:
	@go test $(PKG)

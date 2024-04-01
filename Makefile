.PHONY: start

VERSION := v0.1.0

ifneq ("$(wildcard .env)","")
	include .env
endif

development:
	go run main.go

clean:
	go clean

build:
	go build -o main

run:
	./main

lint:
	golangci-lint run

test:
	go clean -testcache
	go test -timeout 30s ./...

sync:
	go run main.go --sync

# migrations-up:
# 	migrate -database postgres://$(PSQL_AUTH_USER):$(PSQL_AUTH_PASS)@$(PSQL_AUTH_HOST):$(PSQL_AUTH_PORT)/$(PSQL_AUTH_DB)?sslmode=disable -path ./database/auth/migrations up

# migrations-down:
# 	migrate -database postgres://$(PSQL_AUTH_USER):$(PSQL_AUTH_PASS)@$(PSQL_AUTH_HOST):$(PSQL_AUTH_PORT)/$(PSQL_AUTH_DB)?sslmode=disable -path ./database/auth/migrations down

swagger-regen:
	swag init --output ./swagger

release:
	go clean
	go clean -testcache
	go test -timeout 30s ./...
	go build -o main

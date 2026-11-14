.PHONY: all test race vet build build-windows build-linux build-apk proto aar app-deps app-test app-run clean

# Every build output lands in builds/ at the repo root.
BIN := builds
SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
VERSION := 0.1.0
# One stamp per make run: the app and the daemon built together share it, so
# the app can tell when it talks to a daemon from another build.
STAMP := $(shell date +%m%d.%H%M%S)
BUILD_ID := $(SHA)-$(STAMP)
DEFINES := --dart-define=APP_VERSION=$(VERSION) --dart-define=BUILD_SHA=$(SHA) --dart-define=BUILD_ID=$(BUILD_ID) --dart-define=ENV=$(or $(ENV),dev)
GO_LDFLAGS := -X cloudsync/core/rpc.Version=$(VERSION) -X cloudsync/core/rpc.Build=$(BUILD_ID)
NDK ?= $(lastword $(sort $(wildcard $(HOME)/Android/Sdk/ndk/*)))
PROTOC_DART := $(HOME)/.pub-cache/bin/protoc-gen-dart

all: vet test build

# --- Go core -------------------------------------------------------------

test:
	go test ./core/...

race:
	go test -race ./core/...

vet:
	go vet ./...

# Linux build links FUSE 2 (libfuse.so.2). Use FUSE_TAGS=-tags=fuse3 on
# systems where libfuse3.so.3 exists.
build:
	go build $(FUSE_TAGS) -ldflags '$(GO_LDFLAGS)' -o $(BIN)/ ./cmd/cs ./cmd/cloudsyncd

# APKs only for arm64 (phones) and x86_64 (emulators): the Go core is built for these.
build-apk: aar app-deps
	cd app && flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 $(DEFINES)
	mkdir -p $(BIN)/android
	cp app/build/app/outputs/flutter-apk/*-release.apk $(BIN)/android/
	@ls -lh $(BIN)/android/*.apk

# Desktop app; cloudsyncd is put next to it, the app starts it when needed.
build-linux: build app-deps
	cd app && flutter build linux --release $(DEFINES)
	cp $(BIN)/cloudsyncd app/build/linux/x64/release/bundle/
	rm -rf $(BIN)/linux && mkdir -p $(BIN)/linux
	cp -r app/build/linux/x64/release/bundle/. $(BIN)/linux/
	@echo "app: $(BIN)/linux/cloudsync"

# Windows needs no cgo: cgofuse talks to WinFsp directly.
build-windows:
	GOOS=windows GOARCH=amd64 go build -ldflags '$(GO_LDFLAGS)' -o $(BIN)/windows/ ./cmd/cs ./cmd/cloudsyncd

# Go and Dart code from proto/cloudsync.proto (protoc-gen-go, -go-grpc and
# "dart pub global activate protoc_plugin").
proto:
	protoc -I proto \
		--go_out=core/rpc/pb --go_opt=paths=source_relative \
		--go-grpc_out=core/rpc/pb --go-grpc_opt=paths=source_relative \
		proto/cloudsync.proto
	protoc -I proto --plugin=protoc-gen-dart=$(PROTOC_DART) --dart_out=grpc:app/lib/data/rpc/gen proto/cloudsync.proto

# The core for Android (gomobile, NDK from ~/Android/Sdk/ndk).
aar:
	ANDROID_NDK_HOME=$(NDK) gomobile bind -target=android/arm64,android/amd64 -androidapi 26 \
		-javapkg dev.cloudsync -ldflags='-s -w $(GO_LDFLAGS)' -o app/android/app/libs/cloudsync.aar ./mobilebind

# --- Flutter app ---------------------------------------------------------

app-deps:
	cd app && flutter pub get

app-test: app-deps
	cd app && flutter analyze && flutter test

app-run: build app-deps
	cd app && CLOUDSYNCD=$(CURDIR)/$(BIN)/cloudsyncd flutter run $(DEFINES)

clean:
	rm -rf $(BIN) app/build app/android/app/libs/cloudsync.aar app/android/app/libs/cloudsync-sources.jar

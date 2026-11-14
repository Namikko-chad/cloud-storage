package rpc

// Version and Build identify the core binary; make sets them with
// -ldflags -X (see Makefile), the same values the app gets as defines.
var (
	Version = "dev"
	Build   = "dev"
)

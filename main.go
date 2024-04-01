package main

import (
	"cloud-storage/app"
	"os"
	"os/signal"
	"syscall"

	"golang.org/x/exp/slices"
)

func main() {
	argsWithoutProg := os.Args[1:]
	if slices.Contains(argsWithoutProg, "--sync") {
		app.Sync()
	} else {
		app.StartServer()
		exit := make(chan os.Signal, 1)
		signal.Notify(exit, os.Interrupt, syscall.SIGTERM)
		<-exit
		close(exit)
		app.StopServer()
		os.Exit(0)
	}
}

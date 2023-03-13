package main

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"

	"github.com/opensourcecorp/workshops/linux/score-fetcher/server"
)

func main() {
	http.HandleFunc("/", server.Root)

	addr := net.JoinHostPort("127.0.0.1", "8080")
	fmt.Printf("Starting server on %s\n", addr)

	err := http.ListenAndServe(addr, nil)
	if errors.Is(err, http.ErrServerClosed) {
		fmt.Println("server closed")
	} else if err != nil {
		fmt.Println("Error starting server")
		os.Exit(1)
	}
}

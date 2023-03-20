package main

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"

	fetchserver "github.com/opensourcecorp/workshops/linux/score-fetcher/pkg/fetch-server"
	teamserver "github.com/opensourcecorp/workshops/linux/score-fetcher/pkg/team-server"
)

func main() {
	http.HandleFunc("/dashboard", fetchserver.Dashboard)
	http.HandleFunc("/score", teamserver.Score)

	addr := net.JoinHostPort("0.0.0.0", "8080")
	fmt.Printf("Starting server on %s\n", addr)

	err := http.ListenAndServe(addr, nil)
	if errors.Is(err, http.ErrServerClosed) {
		fmt.Println("Server closed")
	} else if err != nil {
		fmt.Println("Error starting server")
		os.Exit(1)
	}
}

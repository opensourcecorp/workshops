package main

import (
	"errors"
	"net"
	"net/http"

	fetchserver "github.com/opensourcecorp/workshops/linux/score-server/pkg/fetch-server"
	"github.com/sirupsen/logrus"
)

func main() {
	http.HandleFunc("/", fetchserver.Root)

	addr := net.JoinHostPort("0.0.0.0", "8080")
	logrus.Infof("Starting server on %s\n", addr)

	err := http.ListenAndServe(addr, nil)
	if errors.Is(err, http.ErrServerClosed) {
		logrus.Info("Server closed")
	} else if err != nil {
		logrus.Fatalf("Error starting server: %v\n", err)
	}
}

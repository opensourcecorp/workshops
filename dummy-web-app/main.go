package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/sirupsen/logrus"
)

func getRoot(w http.ResponseWriter, r *http.Request) {
	log.Println("hit on /")
	_, err := fmt.Fprint(w, "You fixed it! But we're busy printing money over here, so... get lost.\n")
	if err != nil {
		logrus.Fatalf("writing to RepsonseWriter: %v", err)
	}
}

func getHealth(w http.ResponseWriter, r *http.Request) {
	log.Println("hit on /health")
	_, err := fmt.Fprint(w, "ok\n")
	if err != nil {
		logrus.Fatalf("writing to RepsonseWriter: %v", err)
	}
}

func main() {
	addr := ":8000"

	http.HandleFunc("/", getRoot)
	http.HandleFunc("/health", getHealth)

	log.Printf("starting server on %s\n", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		logrus.Fatalf("starting server: %v", err)
	}
}

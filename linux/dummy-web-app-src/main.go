package main

import (
	"io"
	"log"
	"net/http"
)

func getRoot(w http.ResponseWriter, r *http.Request) {
	log.Println("hit on /")
	io.WriteString(w, "You fixed it! But we're busy printing money over here, so... get lost.\n")
}

func getHealth(w http.ResponseWriter, r *http.Request) {
	log.Println("hit on /health")
	io.WriteString(w, "ok\n")
}

func main() {
	addr := ":8000"

	http.HandleFunc("/", getRoot)
	http.HandleFunc("/health", getHealth)

	log.Printf("starting server on %s\n", addr)
	http.ListenAndServe(addr, nil)
}

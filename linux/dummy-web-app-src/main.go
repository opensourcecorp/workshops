package main

import (
	"io"
	"log"
	"net/http"
)

func getHealth(w http.ResponseWriter, r *http.Request) {
	log.Println("hit on /health")
	io.WriteString(w, "ok")
}

func main() {
	addr := ":8080"
	http.HandleFunc("/health", getHealth)

	log.Printf("starting server on %s\n", addr)
	http.ListenAndServe(addr, nil)
}

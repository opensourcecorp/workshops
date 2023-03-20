// Package teamserver implements server-side logic for returning score &
// associated data for the team's machine
package teamserver

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	_ "modernc.org/sqlite"
)

const dbFilepath = "/.ws/main.db"

func Score(w http.ResponseWriter, req *http.Request) {
	fmt.Printf("%s: got request on /score from %s\n", time.Now(), req.Host)

	score, err := getScore()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Score:getScore: %v\n", err)
	}

	scoreJSON, err := json.Marshal(map[string]int{"score": score})
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Score:json.Marshal: %v\n", err)
	}

	fmt.Fprint(w, string(scoreJSON)+"\n")
}

func getScore() (int, error) {
	var score int

	db, err := sql.Open("sqlite3", dbFilepath)
	if err != nil {
		return 0, fmt.Errorf("error opening DB file: %v", err)
	}

	err = db.QueryRow("SELECT SUM(score) FROM scoring").Scan(&score)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, fmt.Errorf("table may not yet have rows -- details: %v", err)
	} else if err != nil {
		return 0, fmt.Errorf("unhandled DB query error: %v", err)
	}

	return score, nil
}

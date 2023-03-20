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

type scoreResponse struct {
	Score int    `json:"score"`
	Msg   string `json:"msg"`
}

// marshalResponse just wraps a json.Marshal call so we don't have to keep
// repeating ourselves. If we fail even *this*, the callers just send back a
// static JSON string
func marshalResponse(resp scoreResponse) (string, error) {
	respJSON, err := json.Marshal(resp)
	if err != nil {
		return "", fmt.Errorf("Score:marshalResponse: %v", err)
	}
	return string(respJSON), nil
}

func Score(w http.ResponseWriter, req *http.Request) {
	fmt.Printf("%s: got request on /score from %s\n", time.Now(), req.Host)
	resp := scoreResponse{}

	score, err := getScore()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		resp.Msg = fmt.Sprintf("Score:getScore: %v", err)
		respJSON, err := marshalResponse(resp)
		if err != nil {
			respJSON = `{"msg": "internal server error"}`
		}
		fmt.Fprint(w, respJSON+"\n")
		return
	}
	resp.Score = score

	respJSON, err := marshalResponse(resp)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		respJSON = fmt.Sprintf(`{"msg": "Score:json.Marshal: %v"}`, err)
		fmt.Fprint(w, respJSON+"\n")
		return
	}

	fmt.Fprint(w, respJSON+"\n")
}

func getScore() (int, error) {
	var score int

	db, err := sql.Open("sqlite", dbFilepath)
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

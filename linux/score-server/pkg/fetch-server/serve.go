// Package fetchserver implements server-side and template-rendering logic for
// the score fetcher service
package fetchserver

import (
	"bytes"
	"database/sql"
	"fmt"
	"html/template"
	"net/http"
	"sort"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/opensourcecorp/workshops/linux/score-fetcher/content"
	"github.com/sirupsen/logrus"
)

const dbDriver = "pgx"
const dbConn = "postgresql://postgres@localhost:5432/postgres" // app is expected to be running on the DB server

type teamData struct {
	Name              string
	Score             int
	Position          int
	LastStepCompleted int
}

func Root(w http.ResponseWriter, req *http.Request) {
	logrus.Infof("%s: got request on %s from %s\n", time.Now(), req.URL, req.Host)

	tplBytes, err := content.Content.ReadFile("www/index.html")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Dashboard:os.ReadFile: %v\n", err)
		return
	}

	tpl, err := template.New("index").Parse(string(tplBytes))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Dashboard:template.Parse: %v\n", err)
		return
	}

	data, err := getScoreData(dbConn)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Dashboard:%v\n", err)
		return
	}

	data = rankTeams(data)

	resp, err := renderHTMLTemplate(tpl, data)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Dashboard:%v\n", err)
		return
	}

	fmt.Fprint(w, resp)
}

func renderHTMLTemplate(t *template.Template, data []teamData) (string, error) {
	var rendered bytes.Buffer
	err := t.Execute(&rendered, data)
	if err != nil {
		return "", fmt.Errorf("renderHTMLTemplate: %v", err)
	}

	return rendered.String(), nil
}

func getScoreData(dbConn string) ([]teamData, error) {
	db, err := sql.Open(dbDriver, dbConn)
	if err != nil {
		return nil, fmt.Errorf("error opening DB connection: %v", err)
	}
	defer db.Close()

	rows, err := db.Query("SELECT team_name, SUM(score), MAX(last_step_completed) FROM scoring GROUP BY team_name")
	if err != nil {
		return nil, fmt.Errorf("unhandled DB query error: %v", err)
	}
	defer rows.Close()

	var data []teamData
	for rows.Next() {
		var (
			teamName          string
			score             int
			lastStepCompleted int
		)

		if err = rows.Scan(&teamName, &score, &lastStepCompleted); err != nil {
			return nil, fmt.Errorf("error scanning row for team score data: %v", err)
		}

		data = append(data, teamData{
			Name:              teamName,
			Score:             score,
			LastStepCompleted: lastStepCompleted,
		})
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error at some point during row scans: %v", err)
	}

	return data, nil
}

func rankTeams(data []teamData) []teamData {
	sort.SliceStable(data, func(i, j int) bool { return data[i].Score > data[j].Score })
	for pos := range data {
		data[pos].Position = pos + 1
	}
	return data
}

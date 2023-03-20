// Package fetchserver implements server-side and template-rendering logic for
// the score fetcher service
package fetchserver

import (
	"bytes"
	"fmt"
	"html/template"
	"math/rand"
	"net/http"
	"sort"
	"time"

	"github.com/opensourcecorp/workshops/linux/score-fetcher/content"
)

type teamData struct {
	Name  string
	Score int
}

func Dashboard(w http.ResponseWriter, req *http.Request) {
	fmt.Printf("%s: got request on /dashboard from %s\n", time.Now(), req.Host)

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

	data, err := getScoresFromServers() // TODO: provide server IPs, etc.
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Dashboard:%v\n", err)
		return
	}

	resp, err := renderHTMLTemplateBytes(tpl, data)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Dashboard:%v\n", err)
		return
	}

	fmt.Fprint(w, resp)
}

func renderHTMLTemplateBytes(t *template.Template, data any) (string, error) {
	var rendered bytes.Buffer
	err := t.Execute(&rendered, data)
	if err != nil {
		return "", fmt.Errorf("renderHTMLTemplateBytes: %v", err)
	}

	return rendered.String(), nil
}

func getScoresFromServers() ([]teamData, error) {
	// TODO: this is dummy data, obviously
	data := []teamData{
		{"Team 1", rand.Intn(100_000)},
		{"Team 2", rand.Intn(100_000)},
	}

	data = rankTeams(data)
	return data, nil
}

func rankTeams(data []teamData) []teamData {
	sort.SliceStable(data, func(i, j int) bool { return data[i].Score > data[j].Score })
	return data
}

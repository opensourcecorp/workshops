// Package server implements server-side and template-rendering logic
package server

import (
	"bytes"
	"fmt"
	"net/http"
	"text/template"

	"github.com/opensourcecorp/workshops/linux/score-fetcher/content"
)

func Root(w http.ResponseWriter, req *http.Request) {
	tplBytes, err := content.Content.ReadFile("www/index.html")
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w, "Root:os.ReadFile: %v\n", err)
	}

	tpl, err := template.New("index").Parse(string(tplBytes))
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w, "Root:template.Parse: %v\n", err)
	}

	data, err := getScoresFromServers() // TODO: provide server IPs, etc.
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w, "Root:%v\n", err)
	}

	resp, err := renderHTMLTemplateBytes(tpl, data)
	if err != nil {
		w.WriteHeader(500)
		fmt.Fprintf(w, "Root:%v\n", err)
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

func getScoresFromServers() (map[string]int, error) {
	scoreMap := make(map[string]int)
	return scoreMap, nil
}

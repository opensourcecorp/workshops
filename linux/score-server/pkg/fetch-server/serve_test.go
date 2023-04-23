package fetchserver

import (
	"reflect"
	"testing"
)

func TestRankTeams(t *testing.T) {
	data := []teamData{
		{"Team 1", 100, 3},
		{"Team 3", 300, 1},
		{"Team 2", 200, 2},
	}

	want := []teamData{
		{"Team 3", 300, 1},
		{"Team 2", 200, 2},
		{"Team 1", 100, 3},
	}

	got := rankTeams(data)

	if !reflect.DeepEqual(want, got) {
		t.Errorf("\nwant: %v\ngot:  %v", want, got)
	}
}

// func TestGetScores(t *testing.T) {
// 	t.Error("TODO: test with common.containertest")
// }

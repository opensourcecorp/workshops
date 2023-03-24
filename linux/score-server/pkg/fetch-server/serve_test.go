package fetchserver

import (
	"reflect"
	"testing"
)

func TestRankTeams(t *testing.T) {
	data := []teamData{
		{"Team 1", 100},
		{"Team 3", 300},
		{"Team 2", 200},
	}

	want := []teamData{
		{"Team 3", 300},
		{"Team 2", 200},
		{"Team 1", 100},
	}

	got := rankTeams(data)

	if !reflect.DeepEqual(want, got) {
		t.Errorf("\nwant: %v\ngot:  %v", want, got)
	}
}

// func TestGetScores(t *testing.T) {
// 	t.Error("TODO: test with common.containertest")
// }

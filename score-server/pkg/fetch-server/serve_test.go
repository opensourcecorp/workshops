package fetchserver

import (
	"reflect"
	"testing"
)

func TestRankTeams(t *testing.T) {
	data := []teamData{
		{Name: "Team 1", Score: 100, Position: 3},
		{Name: "Team 3", Score: 300, Position: 1},
		{Name: "Team 2", Score: 200, Position: 2},
	}

	want := []teamData{
		{Name: "Team 3", Score: 300, Position: 1},
		{Name: "Team 2", Score: 200, Position: 2},
		{Name: "Team 1", Score: 100, Position: 3},
	}

	got := rankTeams(data)

	if !reflect.DeepEqual(want, got) {
		t.Errorf("\nwant: %v\ngot:  %v", want, got)
	}
}

// func TestGetScores(t *testing.T) {
// 	t.Error("TODO: test with common.containertest")
// }

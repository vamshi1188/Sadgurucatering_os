package app

import "testing"

func TestNew(t *testing.T) {
	application := New()

	if application == nil {
		t.Fatal("expected application to be initialized")
	}
}

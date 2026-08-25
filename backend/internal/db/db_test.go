package db

import "testing"

func TestOpenRequiresDatabaseURL(t *testing.T) {
	_, err := Open("")

	if err == nil {
		t.Fatal("expected error when database URL is empty")
	}

	if err.Error() != "database URL is required" {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCloseNilDB(t *testing.T) {
	var database *DB

	if err := database.Close(); err != nil {
		t.Fatalf("expected nil close error, got: %v", err)
	}
}

func TestCloseEmptyDB(t *testing.T) {
	database := &DB{}

	if err := database.Close(); err != nil {
		t.Fatalf("expected nil close error, got: %v", err)
	}
}

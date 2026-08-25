package httpserver

import (
	"net/http"
	"testing"
	"time"
)

func TestNew(t *testing.T) {
	// handler := http.NewServeMux()

	server := New(
		"127.0.0.1",
		8080,
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}),
	)

	if server == nil {
		t.Fatal("expected server to be initialized")
	}

	if server.server == nil {
		t.Fatal("expected HTTP server to be initialized")
	}

	if server.server.Addr != "127.0.0.1:8080" {
		t.Fatalf("unexpected server address: %s", server.server.Addr)
	}

	if server.server.ReadHeaderTimeout != 5*time.Second {
		t.Fatal("unexpected read header timeout")
	}

	if server.server.ReadTimeout != 15*time.Second {
		t.Fatal("unexpected read timeout")
	}

	if server.server.WriteTimeout != 15*time.Second {
		t.Fatal("unexpected write timeout")
	}

	if server.server.IdleTimeout != 60*time.Second {
		t.Fatal("unexpected idle timeout")
	}
}

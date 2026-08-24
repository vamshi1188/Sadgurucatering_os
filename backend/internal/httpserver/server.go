package httpserver

import (
	"context"
	"net/http"
	"time"
)

type Server struct {
	server *http.Server
}

func New(host, port string, handler http.Handler) *Server {
	return &Server{
		server: &http.Server{
			Addr:              host + ":" + port,
			Handler:           handler,
			ReadHeaderTimeout: 5 * time.Second,
			ReadTimeout:       15 * time.Second,
			WriteTimeout:      15 * time.Second,
			IdleTimeout:       60 * time.Second,
		},
	}
}

func (s *Server) Start() error {
	return s.server.ListenAndServe()
}

func (s *Server) Shutdown(ctx context.Context) error {
	return s.server.Shutdown(ctx)
}

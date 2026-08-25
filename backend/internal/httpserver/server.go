package httpserver

import (
	"context"
	"net/http"
	"strconv"
	"time"
)

type Server struct {
	server *http.Server
}

func New(host string, port int, handler http.Handler) *Server {
	return &Server{
		server: &http.Server{
			Addr:              host + ":" + strconv.Itoa(port),
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

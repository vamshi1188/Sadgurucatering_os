package router

import "net/http"

func New() http.Handler {
	mux := http.NewServeMux()

	api := http.NewServeMux()
	v1 := http.NewServeMux()

	registerV1Routes(v1)

	api.Handle("/v1/", http.StripPrefix("/v1", v1))
	mux.Handle("/api/", http.StripPrefix("/api", api))

	return mux
}

func registerV1Routes(mux *http.ServeMux) {
	// Future v1 routes will be registered here.
}

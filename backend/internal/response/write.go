package response

import (
	"encoding/json"
	"net/http"
)

func Write(
	w http.ResponseWriter,
	status int,
	data any,
	requestID string,
) {
	meta := Meta{
		RequestID: requestID,
	}

	WriteWithMeta(
		w,
		status,
		data,
		meta,
	)
}

func WriteWithMeta(
	w http.ResponseWriter,
	status int,
	data any,
	meta Meta,
) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	_ = json.NewEncoder(w).Encode(
		SuccessWithMeta(data, meta),
	)
}

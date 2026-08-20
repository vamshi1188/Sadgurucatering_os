package response

import (
	"encoding/json"
	"net/http"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
)

func WriteError(w http.ResponseWriter, err error) {
	status := appErrors.HTTPStatus(err)

	code := appErrors.CodeInternal
	message := "An unexpected error occurred"

	if appErr, ok := err.(*appErrors.Error); ok {
		code = appErr.PublicCode()
		message = appErr.PublicMessage()
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	_ = json.NewEncoder(w).Encode(
		Failure(code, message),
	)
}

package errors

import "net/http"

func HTTPStatus(err error) int {
	appErr, ok := err.(*Error)
	if !ok {
		return http.StatusInternalServerError
	}

	if appErr.Status == 0 {
		return http.StatusInternalServerError
	}

	return appErr.Status
}

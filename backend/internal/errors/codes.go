package errors

import (
	"net/http"
)

const (
	CodeInvalidRequest = "INVALID_REQUEST"
	CodeUnauthorized   = "UNAUTHORIZED"
	CodeForbidden      = "FORBIDDEN"
	CodeNotFound       = "NOT_FOUND"
	CodeConflict       = "CONFLICT"
	CodeInternal       = "INTERNAL_ERROR"
)

func InvalidRequest(message string) *Error {
	return New(CodeInvalidRequest, message, http.StatusBadRequest)
}

func UnauthorizedError(message string) *Error {
	return New(CodeUnauthorized, message, http.StatusUnauthorized)
}

func ForbiddenError(message string) *Error {
	return New(CodeForbidden, message, http.StatusForbidden)
}

func NotFoundError(message string) *Error {
	return New(CodeNotFound, message, http.StatusNotFound)
}

func ConflictError(message string) *Error {
	return New(CodeConflict, message, http.StatusConflict)
}

func InternalError(message string) *Error {
	return New(CodeInternal, message, http.StatusInternalServerError)
}

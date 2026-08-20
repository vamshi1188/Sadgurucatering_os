package errors

type Error struct {
	Code    string
	Message string
	Status  int
	Err     error
}

func New(code, message string, status int) *Error {
	return &Error{
		Code:    code,
		Message: message,
		Status:  status,
	}
}

func Wrap(err error, code, message string, status int) *Error {
	return &Error{
		Code:    code,
		Message: message,
		Status:  status,
		Err:     err,
	}
}

func (e *Error) Error() string {
	if e.Err != nil {
		return e.Message + ": " + e.Err.Error()
	}

	return e.Message
}

func (e *Error) Unwrap() error {
	return e.Err
}

func (e *Error) PublicCode() string {
	return e.Code
}

func (e *Error) PublicMessage() string {
	return e.Message
}

package response

type Response struct {
	Data any   `json:"data"`
	Meta *Meta `json:"meta,omitempty"`
}

type Meta struct {
	RequestID  string      `json:"request_id,omitempty"`
	Pagination *Pagination `json:"pagination,omitempty"`
}

type Pagination struct {
	Page       int `json:"page"`
	PageSize   int `json:"page_size"`
	Total      int `json:"total"`
	TotalPages int `json:"total_pages"`
}

type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type ErrorResponse struct {
	Error APIError `json:"error"`
}

func Success(data any) Response {
	return Response{
		Data: data,
	}
}

func SuccessWithMeta(data any, meta Meta) Response {
	return Response{
		Data: data,
		Meta: &meta,
	}
}

func SuccessWithPagination(
	data any,
	pagination Pagination,
) Response {
	return Response{
		Data: data,
		Meta: &Meta{
			Pagination: &pagination,
		},
	}
}

func Failure(code, message string) ErrorResponse {
	return ErrorResponse{
		Error: APIError{
			Code:    code,
			Message: message,
		},
	}
}

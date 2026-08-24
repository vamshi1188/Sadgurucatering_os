package health

type Response struct {
	Status string `json:"status"`
}

func NewResponse() Response {
	return Response{
		Status: "ok",
	}
}

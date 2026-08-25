FROM golang:1.27-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /out/api ./cmd/api

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /out/migrate ./cmd/migrate

FROM alpine:3.22

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=builder /out/api /app/api
COPY --from=builder /out/migrate /app/migrate
COPY --from=builder /src/migrations /app/migrations

USER app

EXPOSE 8080

ENTRYPOINT ["/app/api"]
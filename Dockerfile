FROM golang:1.14-alpine as builder

COPY go.mod /service/
COPY go.sum /service/

WORKDIR /service

RUN go mod download

COPY src/ ./src

RUN GOOS=linux GOARCH=amd64 go build -o sample-app ./src

FROM alpine

WORKDIR /service

COPY --from=builder /service/sample-app ./sample-app
COPY --from=builder /service/src/static ./src/static


ENTRYPOINT ["./sample-app"]
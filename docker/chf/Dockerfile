FROM golang:1.26 AS builder

WORKDIR /src
COPY . .

WORKDIR /src/NFs/chf

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /bin/chf ./cmd

FROM alpine:3.19

WORKDIR /free5gc
COPY --from=builder /bin/chf /free5gc/chf

CMD ["/free5gc/chf"]

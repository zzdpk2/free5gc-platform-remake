FROM golang:1.26 AS builder

WORKDIR /src
COPY . .

WORKDIR /src/NFs/nrf

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /bin/nrf ./cmd

FROM alpine:3.19

WORKDIR /free5gc
COPY --from=builder /bin/nrf /free5gc/nrf

CMD ["/free5gc/nrf"]

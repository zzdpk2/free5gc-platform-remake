FROM golang:1.26 AS builder

ARG NF
WORKDIR /src
COPY . .

WORKDIR /src/NFs/${NF}
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/${NF} ./cmd

FROM alpine:3.19

ARG NF
ENV NF=${NF}
WORKDIR /free5gc

RUN apk add --no-cache ca-certificates iproute2 iptables
COPY --from=builder /out/${NF} /free5gc/bin/${NF}
COPY config /free5gc/config
COPY cert /free5gc/cert
COPY docker/free5gc/entrypoint.sh /free5gc/entrypoint.sh
RUN chmod +x /free5gc/entrypoint.sh

ENTRYPOINT ["/free5gc/entrypoint.sh"]

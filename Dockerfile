FROM golang:1.25-alpine3.23 AS builder

RUN apk update
RUN apk add make
WORKDIR /go
COPY . compliance
RUN cd compliance && make clean && make

FROM alpine:3.23
COPY --from=builder /go/compliance/compliance /usr/bin/compliance

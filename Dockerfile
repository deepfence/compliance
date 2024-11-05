FROM golang:1.23-alpine3.20 AS builder
MAINTAINER DeepFence

RUN apk update
RUN apk add make
WORKDIR /go
COPY . compliance
RUN cd compliance && make clean && make

FROM alpine:3.20
MAINTAINER DeepFence
COPY --from=builder /go/compliance/compliance /usr/bin/compliance

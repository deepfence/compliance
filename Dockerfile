FROM golang:1.20-alpine3.18 AS builder
MAINTAINER DeepFence

RUN apk update
RUN apk add make
WORKDIR /go
COPY . compliance
RUN cd compliance && make clean && make

FROM alpine:3.18
MAINTAINER DeepFence
COPY --from=builder /go/compliance/compliance /usr/bin/compliance

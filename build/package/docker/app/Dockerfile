FROM golang:1.19-alpine as app

WORKDIR /go/src/app
RUN apk add --no-cache binutils ca-certificates

# ENV PROBE_BASEDIR=https://github.com/grpc-ecosystem/grpc-health-probe/releases/download
# ENV PROBE_VERSION=v0.3.6

ARG PLATFORM

# RUN wget -qO/bin/grpc_health_probe ${PROBE_BASEDIR}/${PROBE_VERSION}/grpc_health_probe-linux-$PLATFORM \
#   && chmod +x /bin/grpc_health_probe

ENV GOOS=linux GOARCH=$PLATFORM CGO_ENABLED=0

COPY . ./
ARG VERSION
RUN go build -ldflags="-w -s -X main.version=$VERSION" -o /bin/app ./cmd/app \
  && strip --strip-unneeded /bin/app

ENTRYPOINT ["/bin/app"]

# FROM golang:1.16 AS grpcurl
# RUN go get github.com/fullstorydev/grpcurl/...
# RUN CGO_ENABLED=0 GOOS=linux GOARCH=$PLATFORM go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

FROM scratch

COPY --from=app /etc/ssl/certs /etc/ssl/certs
# COPY --from=app /bin/grpc_health_probe /bin/grpc_health_probe
# COPY --from=grpcurl /go/bin/grpcurl /usr/local/bin/
COPY --from=app /bin/app /bin/app

ARG TITLE
ARG VERSION
ARG DATE

LABEL \
  org.opencontainers.image.title=$TITLE \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.created=$DATE 

EXPOSE 8000

ENTRYPOINT ["/bin/app"]

FROM golang:1.27.4-alpine3.23@sha256:f70850ef6ce341e8b6427f677049145d63c0b7ce002d4d7e3d464828b1b96dcd AS build

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .

ARG VERSION=development
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w -X github.com/echovisionlab/go-open-discogs-batch/cmd.version=${VERSION}" \
    -o /out/go-open-discogs-batch \
    .
RUN mkdir -p /out/home/nonroot/.cache/open-discogs-batch && \
    chown -R 65532:65532 /out/home/nonroot

FROM scratch

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/go-open-discogs-batch /go-open-discogs-batch
COPY --from=build --chown=65532:65532 /out/home/nonroot /home/nonroot

ENV HOME=/home/nonroot
USER 65532:65532
WORKDIR /home/nonroot
ENTRYPOINT ["/go-open-discogs-batch"]

FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o ./CLIProxyAPI ./cmd/server/

FROM alpine:3.22.0

RUN apk add --no-cache tzdata ca-certificates

RUN mkdir -p /CLIProxyAPI && \
    mkdir -p /root/.cliproxy && \
    mkdir -p /root/.config && \
    mkdir -p /tmp && \
    chmod -R 777 /root && \
    chmod -R 777 /CLIProxyAPI && \
    chmod -R 777 /tmp

RUN cat > /CLIProxyAPI/config.yaml << 'EOF'
server:
  port: 8317
  host: 0.0.0.0

proxy:
  timeout: 300
  
auth:
  enabled: false
  
log:
  level: info
EOF

COPY --from=builder /app/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI

WORKDIR /CLIProxyAPI

EXPOSE 8317

ENV TZ=Asia/Shanghai
ENV HOME=/root
ENV CLIPROXY_AUTH_DIR=/root/.cliproxy

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

CMD ["./CLIProxyAPI"]

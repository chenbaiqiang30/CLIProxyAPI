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

RUN apk add --no-cache tzdata

# 创建目录并设置权限
RUN mkdir -p /CLIProxyAPI && \
    mkdir -p /root/.cliproxy && \
    chmod -R 777 /root/.cliproxy && \
    chmod -R 777 /CLIProxyAPI

# 先复制配置文件到绝对路径
COPY config.yaml /CLIProxyAPI/config.yaml

# 再复制程序
COPY --from=builder /app/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI

# 设置工作目录
WORKDIR /CLIProxyAPI

EXPOSE 8317

ENV TZ=Asia/Shanghai

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

# 确保文件存在(调试用)
RUN ls -la /CLIProxyAPI/

CMD ["./CLIProxyAPI"]
```

---

## 🔑 **关键修改**

1. **第 26 行**:直接指定 `config.yaml`,不用通配符 `*`
2. **第 24 行**:给 `/CLIProxyAPI` 目录也加上 777 权限
3. **第 39 行**:添加 `ls -la` 命令,在构建时列出文件,方便我们确认文件是否真的在那里

---

## 📋 **提交后,请查看构建日志**

当你提交后,Render 重新构建时,请找到这一行:
```
RUN ls -la /CLIProxyAPI/
```

它下面应该会显示:
```
total XX
-rwxrwxrwx ... config.yaml
-rwxrwxrwx ... CLIProxyAPI

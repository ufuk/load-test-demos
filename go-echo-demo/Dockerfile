# Build stage
FROM golang:1.27-alpine AS builder

WORKDIR /app

# Cache dependencies layer
COPY go.mod go.sum ./
RUN go mod download

# Compile static, stripped, reproducible binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -trimpath -o server main.go

# Runtime stage - minimal and secure
FROM alpine:3

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/server .

USER appuser

EXPOSE 8080
ENTRYPOINT ["./server"]

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy mod files
COPY go.mod go.sum ./

# Cache mount dengan format khusus Railway
ARG RAILWAY_CACHE_KEY
RUN --mount=type=cache,id=railway-cache-${RAILWAY_CACHE_KEY}-go-mod,target=/go/pkg/mod \
    --mount=type=cache,id=railway-cache-${RAILWAY_CACHE_KEY}-go-build,target=/root/.cache/go-build \
    go mod download

# Copy source code
COPY . .

# Build aplikasi
RUN CGO_ENABLED=0 GOOS=linux go build -o teldrive

# Runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/teldrive .
EXPOSE 8080
CMD ["./teldrive"]

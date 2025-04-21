# Build stage
FROM golang:1.21-bullseye AS builder

WORKDIR /app

# Copy mod files dengan permission yang benar
COPY go.mod go.sum ./
RUN chmod 644 go.mod go.sum && \
    git config --global --add safe.directory /app

# Setup environment untuk Go modules
ENV GOPROXY=https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org
ENV GO111MODULE=on

# Verifikasi dan download dependencies dengan retry
RUN go mod download -x || \
    (echo "Retrying module download..." && \
     go clean -modcache && \
     go mod download -x) || \
    { echo "Failed to verify modules"; go list -m all; exit 1; }

# Copy source code
COPY . .

# Build aplikasi
RUN CGO_ENABLED=0 GOOS=linux go build -o teldrive

# Runtime stage tetap sama

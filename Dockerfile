# Build stage menggunakan Debian untuk kompatibilitas library yang lebih baik
FROM golang:1.21-bullseye AS builder

WORKDIR /app

# Set environment variables untuk Go modules
ENV GOPROXY=https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org
ENV GO111MODULE=on

# Copy dan verifikasi mod files
COPY go.mod go.sum ./
RUN go mod verify

# Download dependencies dengan retry mechanism
RUN git config --global http.sslVerify true && \
    go mod download -x || \
    (sleep 5 && go mod download -x) || \
    (sleep 10 && go mod download -x)

# Copy seluruh source code
COPY . .

# Build aplikasi dengan optimasi
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o teldrive

# --------------------------------------------
# Runtime stage yang lebih ringan
FROM debian:bookworm-slim

# Setup runtime environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Setup user dan permissions
RUN useradd -m appuser
WORKDIR /home/appuser
USER appuser

# Copy binary dari builder
COPY --from=builder --chown=appuser:appuser /app/teldrive .

# Expose port dan setup healthcheck
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/health || exit 1

# Entrypoint
ENTRYPOINT ["./teldrive"]

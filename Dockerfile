FROM golang:1.21-alpine AS builder

WORKDIR /app

# Enable Go modules
ENV GO111MODULE=on

# Copy mod files
COPY go.mod go.sum ./

# Download dependencies dengan cache
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

# Copy source code
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o myapp

FROM alpine:latest
COPY --from=builder /app/myapp /myapp
CMD ["/myapp"]

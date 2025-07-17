# Multi-stage build for smaller final image
FROM haskell:9.4 as dependencies

WORKDIR /app

# Update package lists and install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgmp-dev \
    zlib1g-dev \
    libtinfo-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy cabal configuration
COPY *.cabal cabal.project* ./

# Update cabal and build dependencies
RUN cabal update
RUN cabal build --dependencies-only

# Build stage
FROM dependencies as builder

# Copy source code
COPY . .

# Build the application
RUN cabal build --enable-executable-static

# Get the name of your executable from cabal file
RUN cabal list-bin . > /tmp/binpath

# Copy the executable
RUN cp $(cat /tmp/binpath) /app/main

# Runtime stage
FROM debian:bookworm-slim

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libgmp10 \
    netbase \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy executable
COPY --from=builder /app/main /usr/local/bin/main
RUN chmod +x /usr/local/bin/main

# Switch to app user
USER appuser

# Expose port
EXPOSE 3000

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["main", "--port=3000", "--host=0.0.0.0"]

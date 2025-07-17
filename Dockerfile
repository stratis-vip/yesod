# Use Ubuntu as base and install Haskell manually
FROM ubuntu:22.04 as builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install system dependencies and GHC
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libgmp-dev \
    zlib1g-dev \
    libtinfo-dev \
    libffi-dev \
    libncurses-dev \
    libncurses5 \
    libtinfo5 \
    ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install GHCup (Haskell toolchain installer)
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Add GHCup to PATH
ENV PATH="/root/.ghcup/bin:$PATH"

# Install GHC and Cabal
RUN ghcup install ghc 9.4.8 && \
    ghcup install cabal latest && \
    ghcup set ghc 9.4.8

# Update cabal
RUN cabal update

# Copy cabal files first for better caching
COPY *.cabal cabal.project* ./

# Install dependencies
RUN cabal build --dependencies-only

# Copy source code
COPY . .

# Build the application
RUN cabal build

# Get the executable path
RUN cabal list-bin . > /tmp/binpath && \
    cp $(cat /tmp/binpath) /app/main

# Runtime stage
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgmp10 \
    libtinfo5 \
    libffi8 \
    ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash appuser

# Copy executable
COPY --from=builder /app/main /usr/local/bin/main
RUN chmod +x /usr/local/bin/main

# Switch to app user
USER appuser

# Expose port
EXPOSE 3000

# Run the application
CMD ["main", "--port=3000", "--host=0.0.0.0"]

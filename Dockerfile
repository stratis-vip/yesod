# Try with a different Haskell base image
FROM haskell:9.4.8-buster

WORKDIR /app

# Copy cabal files first
COPY *.cabal cabal.project* ./

# Update cabal
RUN cabal update

# Install dependencies
RUN cabal build --dependencies-only

# Copy source code
COPY . .

# Build the application
RUN cabal build

# Get the executable
RUN cabal list-bin . > /tmp/binpath && \
    cp $(cat /tmp/binpath) /app/main

# Expose port
EXPOSE 3000

# Run the application
CMD ["./main", "--port=3000", "--host=0.0.0.0"]

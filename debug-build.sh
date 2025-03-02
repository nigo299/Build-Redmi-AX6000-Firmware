#!/bin/bash

# Script to run the build with increased verbosity for debugging

cd "$(dirname "$0")"

# Ensure we have the latest code
git pull

# Update feeds to get latest packages
./scripts/feeds update -a
./scripts/feeds install -a

# Clean old build artifacts
make clean

# Run the build with increased verbosity
make -j1 V=s

echo "Build complete. If errors occurred, check the output for detailed information."

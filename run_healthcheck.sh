#!/bin/bash

# exit if any command != 0
set -e

# Check file path arg
if [ -z "$1" ]; then
  echo "Usage: $0 <endpoints_file_path>"
  exit 1
fi

# Assign Docker variable
ENDPOINTS_PATH="$1"

# Validate file provided exists
if [ ! -f "$ENDPOINTS_PATH" ]; then
  echo "Error: File '$ENDPOINTS_PATH' does not exist."
  exit 1
fi

# Export Docker variable
export ENDPOINTS_PATH

# Run docker compose with variable
echo "Starting Docker Compose with ENDPOINTS_PATH='$ENDPOINTS_PATH'..."
docker compose up --build

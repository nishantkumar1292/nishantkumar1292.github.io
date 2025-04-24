#!/bin/bash

# Ensure Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed. Please install Docker and retry."
  exit 1
fi

# Serve the site entirely within the Jekyll Docker container
echo "🚀 Launching Jekyll in Docker and serving at http://localhost:4000"
docker run --rm -it --platform linux/arm64 \
  -p 4000:4000 \
  -v "$PWD":/site \
  bretfisher/jekyll-serve:latest
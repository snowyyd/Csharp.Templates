#!/bin/bash
set -euo pipefail

LLVM_VERSION="20"

# Install system dependencies
sudo apt-get update && sudo apt-get install -y "clang-${LLVM_VERSION}" "lld-${LLVM_VERSION}" "llvm-${LLVM_VERSION}"

# Create symlinks
shopt -s nullglob
for bin in /usr/bin/*-"${LLVM_VERSION}"; do
  target=$(basename "$bin" "-${LLVM_VERSION}")
  sudo ln -snf "$bin" "/usr/local/bin/$target"
done
shopt -u nullglob

# Check if xwin binary is already installed
if command -v xwin &>/dev/null; then
  echo "xwin is already installed. Skipping download."
else
  echo "Fetching the latest xwin release..."
  LATEST_URL=$(curl -s https://api.github.com/repos/Jake-Shadle/xwin/releases/latest \
    | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-musl.tar.gz")) | .browser_download_url')

  # Verify that the download URL was found
  if [ -z "$LATEST_URL" ] || [ "$LATEST_URL" == "null" ]; then
    echo "Error: Could not retrieve download URL for the latest xwin release." >&2
    exit 1
  fi

  # Create a secure temporary directory and set automatic cleanup on exit
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  # Download and extract the binary
  echo "Downloading xwin from: $LATEST_URL"
  curl -sSL "$LATEST_URL" | tar -xz -C "$TMP_DIR"

  # Move binary to path
  XWIN_SRC=$(echo "$TMP_DIR"/xwin-*/xwin)
  echo "Moving $XWIN_SRC to /usr/local/bin/xwin..."
  sudo mv "$XWIN_SRC" /usr/local/bin/
fi

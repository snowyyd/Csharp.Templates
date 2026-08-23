#!/bin/bash
set -euo pipefail

LLVM_VERSION="20"

# Install system dependencies
sudo apt-get update && sudo apt-get install -y "clang-${LLVM_VERSION}" "lld-${LLVM_VERSION}" "llvm-${LLVM_VERSION}"

# Create symlinks
for bin in /usr/bin/*-"${LLVM_VERSION}"; do
  target=$(basename "$bin" "-${LLVM_VERSION}")
  sudo ln -sf "$bin" "/usr/local/bin/$target"
done

# Install and execute xwin toolchain
# Fetch and install the latest xwin binary directly from GitHub releases
echo "Fetching the latest xwin release..."
LATEST_URL=$(curl -s https://api.github.com/repos/Jake-Shadle/xwin/releases/latest \
  | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-musl.tar.gz")) | .browser_download_url')

# Verify that the download URL was found
if [ -z "$LATEST_URL" ] || [ "$LATEST_URL" == "null" ]; then
  echo "Error: Could not retrieve download URL for the latest xwin release." >&2
  exit 1
fi

# Download and extract the binary
echo "Downloading xwin from: $LATEST_URL"
curl -sSL "$LATEST_URL" | tar -xz -C /tmp

# Move binary to path and clean up temporary files
sudo mv /tmp/xwin-*/xwin /usr/local/bin/
rm -rf /tmp/xwin-*

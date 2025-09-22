#!/bin/bash
set -e

# Set up environment variables to handle TUF connectivity issues
export COSIGN_EXPERIMENTAL=1

echo "🔐 Setting up cosign for image signing..."

# Check if cosign is available
if command -v cosign >/dev/null 2>&1; then
    echo "✅ Cosign already installed"
    cosign version


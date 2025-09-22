#!/bin/bash
set -e

chmod +x cosign-linux-amd64
./cosign-linux-amd64 version

# Generate a keypair for signing (if not exists)
if [ ! -f "cosign.key" ]; then
    ./cosign-linux-amd64 generate-key-pair
    echo "✅ Keypair generated: cosign.key (private) and cosign.pub (public)"
else
    echo "🔑 Cosign keypair already exists"
fi


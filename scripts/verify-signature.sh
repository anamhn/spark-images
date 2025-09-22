#!/bin/bash

# Script to verify cosign signatures and download SBOMs
# Usage: ./verify-signatures.sh <image-name> <image-tag>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <image-name> <image-tag>"
    echo "Example: $0 spark-base spark-3.5.1-scala-2.13-java-17"
    exit 1
fi

IMAGE_NAME=$1
IMAGE_TAG=$2
FULL_IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

# Check if cosign is available
if [ ! -x "./cosign-linux-amd64" ]; then
    echo "❌ cosign-linux-amd64 not found or not executable"
    exit 1
fi

# Check if the public key exists
if [ ! -f "cosign.pub" ]; then
    echo "❌ cosign.pub not found"
    exit 1
fi

# Verify the signature
echo "🔍 Verifying image signature..."
if ./cosign-linux-amd64 verify --key cosign.pub "${FULL_IMAGE_REF}"; then
    echo "✅ Signature verification successful!"
else
    echo "❌ Signature verification failed!"
    exit 1
fi

# Download and display SBOM information
echo ""
echo "📋 Checking for SBOM attestation..."
if ./cosign-linux-amd64 download attestation "${FULL_IMAGE_REF}" >/dev/null 2>&1; then
    echo "✅ SBOM attestation found!"

    # Download SBOM to a temporary file
    SBOM_TEMP=$(mktemp)
    ./cosign-linux-amd64 download attestation "${FULL_IMAGE_REF}" > "${SBOM_TEMP}"

    # Extract basic information from the SBOM
    if command -v jq >/dev/null 2>&1; then
        echo "📦 Package count: $(jq '.packages | length' "${SBOM_TEMP}")"
        echo "📅 Created: $(jq -r '.creationInfo.created' "${SBOM_TEMP}")"
        echo "🛠️  Tool: $(jq -r '.creationInfo.creators[0].creator' "${SBOM_TEMP}")"
        echo ""
        echo "📦 Top 10 packages:"
        jq -r '.packages[0:10][] | "\(.name)@\(.versionInfo)"' "${SBOM_TEMP}"
    else
        echo "💡 Install jq to see detailed SBOM information"
    fi

    # Clean up
    rm -f "${SBOM_TEMP}"
else
    echo "ℹ️  No SBOM attestation found for this image"
fi


#!/bin/bash

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <image-name> <image-tag>"
    echo "Example: $0 spark-base spark-3.5.1-scala-2.13-java-17"
    exit 1
fi

IMAGE_NAME=$1
IMAGE_TAG=$2
FULL_IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

echo "🔐 Signing and attaching SBOM to ${FULL_IMAGE_REF}"

# Check if cosign is available
if [ ! -x "./cosign-linux-amd64" ]; then
    echo "❌ cosign-linux-amd64 not found or not executable"
    exit 1
fi

# Check if the image exists locally
if ! docker image inspect "${FULL_IMAGE_REF}" >/dev/null 2>&1; then
    echo "❌ Image ${FULL_IMAGE_REF} not found locally"
    echo "💡 Build the image first using the GitHub Actions workflow"
    exit 1
fi

# Generate SBOM using syft (if available) or fallback to cosign's built-in SBOM generation
# Sanitize image name for filename by replacing / with -
SBOM_FILENAME=$(echo "${IMAGE_NAME}" | tr '/' '-')

if command -v syft >/dev/null 2>&1; then
    syft "${FULL_IMAGE_REF}" -o spdx-json > "${SBOM_FILENAME}-${IMAGE_TAG}.sbom.json"
    SBOM_FILE="${SBOM_FILENAME}-${IMAGE_TAG}.sbom.json"
else
    SBOM_FILE=""
fi

# Sign the image and attach SBOM
if [ -n "${SBOM_FILE}" ] && [ -f "${SBOM_FILE}" ]; then
    ./cosign-linux-amd64 attest --yes --predicate "${SBOM_FILE}" --type spdx --key cosign.key "${FULL_IMAGE_REF}"
    ./cosign-linux-amd64 sign --yes --key cosign.key "${FULL_IMAGE_REF}"
else
    ./cosign-linux-amd64 sign --yes --key cosign.key "${FULL_IMAGE_REF}"
fi

echo "✅ Successfully signed ${FULL_IMAGE_REF}"

# Verify the signature
./cosign-linux-amd64 verify --key cosign.pub "${FULL_IMAGE_REF}"

if [ -n "${SBOM_FILE}" ] && [ -f "${SBOM_FILE}" ]; then
    echo "📋 SBOM attached successfully"
    echo "📄 SBOM file: ${SBOM_FILE}"
fi

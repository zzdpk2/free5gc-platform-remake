#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-192.168.122.202}"
PROJECT="${PROJECT:-free5gc}"
TAG="${TAG:-source-$(git rev-parse --short HEAD)}"
BUILDKIT_ADDR="${BUILDKIT_ADDR:-tcp://buildkitd.buildkit.svc.cluster.local:1234}"
NF_LIST="${NF_LIST:-amf ausf bsf nrf nssf pcf smf udm udr upf chf nef}"

BUILDCTL="${BUILDCTL:-buildctl}"
if ! command -v "${BUILDCTL}" >/dev/null 2>&1; then
  if [ -x /tmp/buildctl ]; then
    BUILDCTL=/tmp/buildctl
  fi
fi

if ! command -v "${BUILDCTL}" >/dev/null 2>&1; then
  echo "buildctl is required" >&2
  exit 1
fi

for nf in ${NF_LIST}; do
  image="${REGISTRY}/${PROJECT}/${nf}:${TAG}"
  echo "Building and pushing ${image}"
  "${BUILDCTL}" \
    --addr "${BUILDKIT_ADDR}" \
    build \
    --frontend dockerfile.v0 \
    --local context=. \
    --local dockerfile=docker/free5gc \
    --opt build-arg:NF="${nf}" \
    --output "type=image,name=${image},push=true,registry.insecure=true"
done

echo "TAG=${TAG}"

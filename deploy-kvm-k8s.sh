#!/usr/bin/env bash
set -euo pipefail

KVM_HOST="${KVM_HOST:-rex@192.168.122.101}"
REMOTE_DIR="${REMOTE_DIR:-~/free5gc-platform-source}"
REGISTRY="${REGISTRY:-192.168.122.202}"
PUSH_REGISTRY="${PUSH_REGISTRY:-harbor.harbor.svc.cluster.local}"
PROJECT="${PROJECT:-free5gc}"
TAG="${TAG:-source-$(git rev-parse --short HEAD)}"
RELEASE="${RELEASE:-free5gc-source}"
NAMESPACE="${NAMESPACE:-free5gc}"

echo "Syncing source tree to ${KVM_HOST}:${REMOTE_DIR} ..."
ssh "${KVM_HOST}" "sudo rm -rf ${REMOTE_DIR}/log ${REMOTE_DIR}/run.pid 2>/dev/null || true"
rsync -az --delete \
  --exclude .git \
  --exclude log \
  --exclude run.pid \
  --exclude node_modules \
  --exclude webconsole/frontend/node_modules \
  ./ "${KVM_HOST}:${REMOTE_DIR}/"

echo "Building and pushing NF images from inside the KVM control node..."
ssh "${KVM_HOST}" "set -e
cd ${REMOTE_DIR}
if [ ! -x /tmp/buildctl ]; then
  curl -sL https://github.com/moby/buildkit/releases/download/v0.13.2/buildkit-v0.13.2.linux-amd64.tar.gz | tar -xz -C /tmp/ bin/buildctl --strip-components=1
fi
mkdir -p /tmp/free5gc-docker-config
HARBOR_PASS=\$(kubectl -n harbor get secret harbor-core -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d)
AUTH=\$(printf 'admin:%s' \"\${HARBOR_PASS}\" | base64 | tr -d '\n')
cat > /tmp/free5gc-docker-config/config.json <<EOF
{\"auths\":{\"${PUSH_REGISTRY}\":{\"auth\":\"\${AUTH}\"},\"${REGISTRY}\":{\"auth\":\"\${AUTH}\"}}}
EOF
BUILDKIT_IP=\$(kubectl -n buildkit get svc buildkitd -o jsonpath='{.spec.clusterIP}')
DOCKER_CONFIG=/tmp/free5gc-docker-config BUILDKIT_NO_CLIENT_TOKEN=true REGISTRY='${PUSH_REGISTRY}' PROJECT='${PROJECT}' TAG='${TAG}' BUILDKIT_ADDR=\"tcp://\${BUILDKIT_IP}:1234\" /bin/bash scripts/build-push-free5gc-images.sh
"

echo "Deploying Helm release ${RELEASE} into ${NAMESPACE} ..."
ssh "${KVM_HOST}" "cd ${REMOTE_DIR} && helm upgrade --install ${RELEASE} charts/free5gc-source -n ${NAMESPACE} --create-namespace --set image.registry=${REGISTRY} --set image.project=${PROJECT} --set image.tag=${TAG}"

echo "Waiting for free5GC workloads..."
ssh "${KVM_HOST}" "kubectl -n ${NAMESPACE} get pods -o wide"

echo "Done. Image tag: ${TAG}"

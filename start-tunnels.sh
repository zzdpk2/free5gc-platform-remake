#!/bin/bash
set -e

K8S_CP="192.168.122.101"
HARBOR_IP="192.168.122.202"

echo "Killing old local SSH tunnels..."
pkill -f "ssh -L" 2>/dev/null || true

echo "Killing old remote kubectl port-forwards..."
ssh rex@${K8S_CP} "pkill -f 'kubectl.*port-forward'" 2>/dev/null || true

sleep 2

echo "Starting Gitea..."
ssh -L 0.0.0.0:3001:localhost:3001 rex@${K8S_CP} \
  "kubectl -n gitea port-forward svc/gitea-http 3001:3000" &

echo "Starting Jenkins..."
ssh -L 0.0.0.0:8080:localhost:8080 rex@${K8S_CP} \
  "kubectl -n jenkins port-forward svc/jenkins 8080:8080" &

echo "Starting Harbor..."
ssh -L 0.0.0.0:8088:${HARBOR_IP}:80 rex@${K8S_CP} -N &

echo "Starting Grafana..."
ssh -L 0.0.0.0:3000:localhost:3000 rex@${K8S_CP} \
  "kubectl -n monitoring port-forward svc/kube-prometheus-grafana 3000:80" &

echo "Starting Prometheus..."
ssh -L 0.0.0.0:9090:localhost:9090 rex@${K8S_CP} \
  "kubectl -n monitoring port-forward svc/kube-prometheus-kube-prome-prometheus 9090:9090" &

echo "Starting SonarQube..."
ssh -L 0.0.0.0:9000:localhost:9000 rex@${K8S_CP} \
  "kubectl -n sonarqube port-forward svc/sonarqube-sonarqube 9000:9000" &

echo "Starting Kiali..."
ssh -L 0.0.0.0:20001:localhost:20001 rex@${K8S_CP} \
  "kubectl -n istio-system port-forward svc/kiali 20001:20001" &

echo "Starting AlertManager..."
ssh -L 0.0.0.0:9093:localhost:9093 rex@${K8S_CP} \
  "kubectl -n monitoring port-forward svc/kube-prometheus-kube-prome-alertmanager 9093:9093" &

echo "All tunnels started. Wait 5 seconds..."
sleep 5

echo "Listening ports:"
ss -lnt | egrep '3000|3001|8080|8443|9000|9090|9093|20001' || true

echo "Done."

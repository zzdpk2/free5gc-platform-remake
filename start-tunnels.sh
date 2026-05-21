#!/bin/bash
pkill -f "ssh -L 0.0.0.0" 2>/dev/null
pkill -f "port-forward" 2>/dev/null
sleep 2

ssh -L 0.0.0.0:3001:localhost:3001 rex@192.168.122.101 "kubectl -n gitea port-forward svc/gitea-http 3001:3000" &
ssh -L 0.0.0.0:8080:localhost:8080 rex@192.168.122.101 "kubectl -n jenkins port-forward svc/jenkins 8080:8080" &
ssh -L 0.0.0.0:8088:192.168.122.202:80 rex@192.168.122.101 -N &
ssh -L 0.0.0.0:3000:localhost:3000 rex@192.168.122.101 "kubectl -n monitoring port-forward svc/kube-prometheus-grafana 3000:80" &
ssh -L 0.0.0.0:9090:localhost:9090 rex@192.168.122.101 "kubectl -n monitoring port-forward svc/kube-prometheus-kube-prome-prometheus 9090:9090" &
ssh -L 0.0.0.0:9000:localhost:9000 rex@192.168.122.101 "kubectl -n sonarqube port-forward svc/sonarqube-sonarqube 9000:9000" &
ssh -L 0.0.0.0:20001:localhost:20001 rex@192.168.122.101 "kubectl -n istio-system port-forward svc/kiali 20001:20001" &
ssh -L 0.0.0.0:9093:localhost:9093 rex@192.168.122.101 "kubectl -n monitoring port-forward svc/kube-prometheus-kube-prome-alertmanager 9093:9093" &

echo "All tunnels started. Wait 5 seconds..."
sleep 5
echo "Done."

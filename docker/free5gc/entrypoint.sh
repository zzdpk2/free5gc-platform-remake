#!/bin/sh
set -eu

nf="${NF:?NF is required}"
pod_ip="${POD_IP:-127.0.0.1}"
node_ip="${NODE_IP:-${pod_ip}}"
cfg="/tmp/free5gc/config/${nf}cfg.yaml"

mkdir -p /tmp/free5gc/config /tmp/free5gc/cert /tmp/free5gc/log
cp -R /free5gc/config/. /tmp/free5gc/config/
cp -R /free5gc/cert/. /tmp/free5gc/cert/

replace_all() {
  old="$1"
  new="$2"
  find /tmp/free5gc/config -type f -name '*.yaml' -exec sed -i "s#${old}#${new}#g" {} +
}

replace_all "mongodb://localhost:27017" "mongodb://free5gc-mongodb:27017"
replace_all "mongodb://127.0.0.1:27017" "mongodb://free5gc-mongodb:27017"
replace_all "http://127.0.0.10:8000" "http://free5gc-nrf:8000"

case "${nf}" in
  nrf)
    sed -i \
      -e "s/registerIPv4: .*/registerIPv4: ${pod_ip}/" \
      -e "s/bindingIPv4: .*/bindingIPv4: 0.0.0.0/" \
      "${cfg}"
    ;;
  upf)
    sed -i \
      -e "s/addr: 127.0.0.8/addr: ${node_ip}/g" \
      -e "s/nodeID: 127.0.0.8/nodeID: ${node_ip}/g" \
      "${cfg}"
    ;;
  smf)
    sed -i \
      -e "s/registerIPv4: .*/registerIPv4: ${pod_ip}/" \
      -e "s/bindingIPv4: .*/bindingIPv4: 0.0.0.0/" \
      -e "s/nodeID: 127.0.0.1/nodeID: ${pod_ip}/" \
      -e "s/listenAddr: 127.0.0.1/listenAddr: 0.0.0.0/" \
      -e "s/externalAddr: 127.0.0.1/externalAddr: ${pod_ip}/" \
      -e "s/nodeID: 127.0.0.8/nodeID: free5gc-upf/" \
      -e "s/addr: 127.0.0.8/addr: free5gc-upf/" \
      -e "s/- 127.0.0.8/- free5gc-upf/" \
      "${cfg}"
    ;;
  amf)
    sed -i \
      -e "s/- 127.0.0.18/- 0.0.0.0/" \
      -e "s/registerIPv4: .*/registerIPv4: ${pod_ip}/" \
      -e "s/bindingIPv4: .*/bindingIPv4: 0.0.0.0/" \
      "${cfg}"
    ;;
  *)
    sed -i \
      -e "s/registerIPv4: .*/registerIPv4: ${pod_ip}/" \
      -e "s/bindingIPv4: .*/bindingIPv4: 0.0.0.0/" \
      "${cfg}"
    ;;
esac

cd /tmp/free5gc
exec "/free5gc/bin/${nf}" -c "${cfg}" -l "/tmp/free5gc/log/${nf}.log"

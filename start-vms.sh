#!/bin/bash
set -e

echo "Starting all KVM virtual machines..."

for vm in $(virsh list --all --name); do
  if [ -n "$vm" ]; then
    echo "Starting $vm ..."
    virsh start "$vm" >/dev/null 2>&1 || true
  fi
done

echo
echo "Current VM status:"
virsh list

echo
echo "Done."

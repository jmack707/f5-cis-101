#!/usr/bin/env bash
# Lab 2.1 — remove the CIS controller. Static routes withdraw when CIS stops.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 2.1 — remove the CIS controller =="
step "delete deployment k8s-bigip-ctlr"
kdelete 03-cluster-deployment.yaml
echo "CIS removed. Static routes withdraw when CIS stops. SA/RBAC/secret left in place."

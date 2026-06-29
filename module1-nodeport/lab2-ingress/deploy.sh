#!/usr/bin/env bash
# Lab 1.2 — publish the hello-world app via a Kubernetes Ingress (NodePort).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 1.2 — Publish hello-world via Ingress (NodePort) =="
lab_apply "$HERE"
step "waiting for endpoints + the CIS-programmed virtual server"
settle_ingress default f5-hello-world-web "$NODEPORT_VIP" "$BIGIP_PARTITION" 90
echo; echo "✓ deployed.  Next:  bash verify.sh"

#!/usr/bin/env bash
# Lab 2.3 — publish the hello-world app via a ConfigMap/AS3 declaration (ClusterIP).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 2.3 — Publish hello-world via ConfigMap/AS3 (ClusterIP) =="
echo "   Note: this uses VIP $CLUSTER_VIP in partition AS3. Lab 2.2 publishes the"
echo "   same VIP via Ingress — run 'bash ../lab2-ingress/cleanup.sh' first if it's up."
lab_apply "$HERE"
step "waiting for endpoints + the AS3-programmed virtual server"
settle_ingress default f5-hello-world-web "$CLUSTER_VIP" AS3 90
echo; echo "✓ deployed.  Next:  bash verify.sh"

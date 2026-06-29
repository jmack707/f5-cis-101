#!/usr/bin/env bash
# Lab 3.2 — app behind the NGINX IC, with CIS publishing the IC to the BIG-IP.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 3.2 — Publish the app behind NGINX, fronted by CIS =="
lab_apply "$HERE"
step "waiting for endpoints + the CIS-programmed virtual server"
settle_ingress nginx-ingress nginx-ingress-hello-world "$NGINX_FRONT_VIP" "$AS3_TENANT" 120
echo; echo "✓ deployed.  Next:  bash verify.sh"

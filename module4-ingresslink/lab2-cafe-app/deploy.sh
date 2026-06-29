#!/usr/bin/env bash
# Lab 4.2 — deploy the cafe app (coffee/tea) for the end-to-end IngressLink test.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 4.2 — Deploy the Cafe app (end-to-end IngressLink test) =="
echo "   Requires lab 4.1 (IngressLink configured) and the NGINX IC from module 3 lab1."
lab_apply "$HERE"
step "waiting for the coffee and tea pods to be ready"
kubectl -n default rollout status deploy/coffee --timeout=120s || true
kubectl -n default rollout status deploy/tea --timeout=120s || true
# Pods Ready isn't enough — the NGINX IC needs a moment to pick up the new
# endpoints, so poll the actual data path through the IngressLink VIP until 200.
R="cafe.example.com:443:$INGRESSLINK_VIP"
wait_http_ok "https://cafe.example.com/coffee" 90 --resolve "$R" -k
wait_http_ok "https://cafe.example.com/tea"    90 --resolve "$R" -k
echo; echo "✓ deployed.  Next:  bash verify.sh"

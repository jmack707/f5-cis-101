#!/usr/bin/env bash
# Lab 2.1 — SA, RBAC, BIG-IP secret (idempotent). Creds from lab-vars.env.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
kubectl create serviceaccount k8s-bigip-ctlr -n "$CIS_NAMESPACE" || true
kubectl create clusterrolebinding k8s-bigip-ctlr-clusteradmin \
  --clusterrole=cluster-admin --serviceaccount="$CIS_NAMESPACE:k8s-bigip-ctlr" || true
kubectl create secret generic f5-bigip-ctlr-login -n "$CIS_NAMESPACE" \
  --from-literal=username="$BIGIP_USER" \
  --from-literal=password="$BIGIP_PASS" \
  --from-literal=url="$BIGIP_MGMT" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Prereqs ready in $CIS_NAMESPACE."

#!/usr/bin/env bash
# Module 1 — CIS (NodePort) + Ingress demo (lab 1.2). Idempotent; re-runnable.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
echo "== BIG-IP partition =="
ssh "${BIGIP_USER}@${BIGIP_MGMT}" "tmsh create auth partition ${BIGIP_PARTITION}" 2>/dev/null || true
echo "== Lab 1.1: prereqs + CIS =="
bash lab1-install-cis/01-setup.sh || true
kapply lab1-install-cis/02-nodeport-deployment.yaml
kubectl -n "$CIS_NAMESPACE" rollout status deploy/k8s-bigip-ctlr-deployment --timeout=120s || true
echo "== Lab 1.2: Ingress demo =="
kapply lab2-ingress/01-deployment-hello-world.yaml
kapply lab2-ingress/02-nodeport-service-hello-world.yaml
kapply lab2-ingress/03-ingress-hello-world.yaml
echo "== Verify =="
settle_ingress default f5-hello-world-web "$NODEPORT_VIP" "$BIGIP_PARTITION" 90
bash lab2-ingress/verify.sh || true

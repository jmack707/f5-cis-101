#!/usr/bin/env bash
# Module 2 — CIS (ClusterIP/static routes) + Ingress demo. Idempotent.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
echo "== Remove any module 1 CIS (one controller at a time) =="
kubectl delete -f ../module1-nodeport/lab1-install-cis/02-nodeport-deployment.yaml --ignore-not-found 2>/dev/null || true
echo "== Lab 2.1: BIG-IP prep + prereqs + CIS =="
bash lab1-install-cis/01-bigip-setup.sh || true
bash lab1-install-cis/02-setup.sh || true
kapply lab1-install-cis/03-cluster-deployment.yaml
kubectl -n "$CIS_NAMESPACE" rollout status deploy/k8s-bigip-ctlr --timeout=120s || true
echo "== Lab 2.2: Ingress demo =="
kapply lab2-ingress/01-deployment-hello-world.yaml
kapply lab2-ingress/02-clusterip-service-hello-world.yaml
kapply lab2-ingress/03-ingress-hello-world.yaml
echo "== Verify =="
settle_ingress default f5-hello-world-web "$CLUSTER_VIP" "$BIGIP_PARTITION" 90
bash lab1-install-cis/verify.sh || true; bash lab2-ingress/verify.sh || true

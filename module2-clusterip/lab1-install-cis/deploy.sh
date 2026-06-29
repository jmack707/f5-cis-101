#!/usr/bin/env bash
# Lab 2.1 — install CIS in ClusterIP / static-route mode. Leaves a Running CIS pod.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 2.1 — Install CIS (ClusterIP + static routes) =="
remove_other_cis k8s-bigip-ctlr
step "BIG-IP prep: ensure partition (iControl REST — no SSH/password)"
bash 01-bigip-setup.sh
step "prereqs: ServiceAccount, ClusterRoleBinding, BIG-IP login Secret"
bash 02-setup.sh
step "apply  03-cluster-deployment.yaml (the CIS controller)"
kapply 03-cluster-deployment.yaml
step "waiting for the CIS controller pod to be ready"
if kubectl -n "$CIS_NAMESPACE" rollout status deploy/k8s-bigip-ctlr --timeout=120s; then
  echo; echo "✓ CIS is running.  Next:  bash verify.sh"
else
  echo; echo "⚠ CIS not ready in 120s. Check:  kubectl -n $CIS_NAMESPACE logs deploy/k8s-bigip-ctlr"
fi

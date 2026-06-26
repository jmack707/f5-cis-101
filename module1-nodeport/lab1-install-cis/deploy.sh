#!/usr/bin/env bash
# Lab 1.1 — install CIS in NodePort mode. Run this; it leaves a Running CIS pod.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 1.1 — Install CIS (NodePort mode) =="
remove_other_cis k8s-bigip-ctlr-deployment
step "prereqs: ServiceAccount, ClusterRoleBinding, BIG-IP login Secret"
bash 01-setup.sh
step "ensure BIG-IP partition ${BIGIP_PARTITION} (iControl REST — no SSH/password)"
ensure_partition
step "apply  02-nodeport-deployment.yaml (the CIS controller)"
kapply 02-nodeport-deployment.yaml
step "waiting for the CIS controller pod to be ready"
if kubectl -n "$CIS_NAMESPACE" rollout status deploy/k8s-bigip-ctlr-deployment --timeout=120s; then
  echo; echo "✓ CIS is running.  Next:  bash verify.sh"
else
  echo; echo "⚠ CIS not ready in 120s. Check:  kubectl -n $CIS_NAMESPACE logs deploy/k8s-bigip-ctlr-deployment"
fi

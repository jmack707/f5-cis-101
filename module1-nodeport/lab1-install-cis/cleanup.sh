#!/usr/bin/env bash
# Lab 1.1 — remove the CIS controller. SA/RBAC/secret are left (shared by modules).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 1.1 — remove the CIS controller =="
step "delete deployment k8s-bigip-ctlr-deployment"
kdelete 02-nodeport-deployment.yaml
echo "CIS controller removed. SA/RBAC/secret left in place (shared across modules)."

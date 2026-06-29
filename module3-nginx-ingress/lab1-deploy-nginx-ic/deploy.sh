#!/usr/bin/env bash
# Lab 3.1 — install the NGINX Ingress Controller (upstream OSS manifests).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Lab 3.1 — Install the NGINX Ingress Controller =="
# Third-party manifests carry $(POD_*) tokens that must NOT be envsubst'd, so
# lab_apply delegates to install-nginx-ic.sh — which applies them in order AND
# waits for the controller rollout, so no extra wait is needed here.
lab_apply "$HERE"
echo; echo "✓ NGINX IC is running.  Next:  bash verify.sh"

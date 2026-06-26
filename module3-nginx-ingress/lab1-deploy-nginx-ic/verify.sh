#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 3.1 — NGINX Ingress Controller =="
assert_pod_running nginx-ingress "app=nginx-ingress"
assert_ingressclass nginx
vsummary

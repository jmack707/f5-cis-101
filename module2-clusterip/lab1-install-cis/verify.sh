#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 2.1 — CIS (ClusterIP / static routes) =="
assert_bigip_reachable
assert_pod_running "$CIS_NAMESPACE" "app=k8s-bigip-ctlr"
assert_static_routes
assert_cis_logs_clean "$CIS_NAMESPACE"
vsummary

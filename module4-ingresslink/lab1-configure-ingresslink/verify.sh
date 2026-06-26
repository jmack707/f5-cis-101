#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 4.1 — IngressLink =="
assert_pod_running "$CIS_NAMESPACE" "app=k8s-bigip-ctlr"
assert_svc_endpoints nginx-ingress nginx-ingress-ingresslink
assert_vs_with_vip "$INGRESSLINK_VIP" "$BIGIP_PARTITION"
assert_pool_members_up "$BIGIP_PARTITION"
vsummary

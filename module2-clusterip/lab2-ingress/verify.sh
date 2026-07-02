#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 2.2 — Ingress (ClusterIP) =="
assert_ingressclass f5
assert_svc_endpoints default f5-hello-world-web
assert_vs_with_vip "$CLUSTER_VIP" "$BIGIP_PARTITION"
assert_pool_members_up "$BIGIP_PARTITION"
assert_code 200 "http://$CLUSTER_VIP/"
assert_lb_rotation "http://$CLUSTER_VIP/" 2
vsummary

#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 1.3 — ConfigMap/AS3 (NodePort) =="
assert_svc_endpoints default f5-hello-world-web
assert_vs_with_vip "$NODEPORT_VIP" AS3
assert_pool_members_up AS3
assert_code 200 "http://$NODEPORT_VIP/"
vsummary

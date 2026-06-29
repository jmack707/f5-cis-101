#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 3.2 — App behind NGINX, published by CIS =="
assert_svc_endpoints default f5-hello-world-web
assert_svc_endpoints nginx-ingress nginx-ingress-hello-world
assert_vs_with_vip "$NGINX_FRONT_VIP" "$AS3_TENANT"
assert_pool_members_up "$AS3_TENANT"
assert_code 200 "http://$NGINX_FRONT_VIP/" -H "Host: mysite.f5demo.com"
vsummary

#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
echo "== Verify Lab 4.2 — Cafe app (end-to-end) =="
R="cafe.example.com:443:$INGRESSLINK_VIP"
assert_code 200 "https://cafe.example.com/coffee" --resolve "$R" -k
assert_code 200 "https://cafe.example.com/tea"    --resolve "$R" -k
info "Manual: confirm X-Real-IP / X-Forwarded-For in the response shows your client IP (proves PROXY protocol)."
vsummary

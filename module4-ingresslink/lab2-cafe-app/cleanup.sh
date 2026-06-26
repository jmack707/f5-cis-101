#!/usr/bin/env bash
# Lab 4.2 — remove the cafe app (deployments, services, secret, ingress).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 4.2 — remove the cafe app =="
lab_delete "$HERE"
echo "Cafe app removed. IngressLink (lab 4.1) left in place."

#!/usr/bin/env bash
# Lab 3.1 — remove the NGINX Ingress Controller. NOTE: module 4 reuses this IC.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 3.1 — remove the NGINX Ingress Controller =="
lab_delete "$HERE"
echo "NGINX IC removed. (Module 4 IngressLink reuses this IC — only remove it when"
echo "you're done with module 4, or you'll need to re-run this lab first.)"

#!/usr/bin/env bash
# Lab 3.2 — remove the demo. NGINX IC (lab 3.1) is left running.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 3.2 — remove the demo =="
lab_delete "$HERE"
echo "Demo removed. NGINX IC left running."

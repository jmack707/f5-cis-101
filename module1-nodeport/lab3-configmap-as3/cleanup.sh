#!/usr/bin/env bash
# Lab 1.3 — remove the ConfigMap/AS3 demo (deployment, service, AS3 ConfigMap).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 1.3 — remove the ConfigMap/AS3 demo =="
lab_delete "$HERE"
echo "Demo removed."

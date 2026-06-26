#!/usr/bin/env bash
# Lab 4.1 — remove IngressLink + CIS. NGINX IC and the CRDs are left in place.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"

echo "== Cleanup Lab 4.1 — remove IngressLink + CIS =="
step "delete 05-vs-ingresslink.yaml"
kdelete 05-vs-ingresslink.yaml
step "delete 04-ingresslink-deployment.yaml"
kdelete 04-ingresslink-deployment.yaml
step "delete 02-nginx-service.yaml"
kdelete 02-nginx-service.yaml
echo "IngressLink + CIS removed. NGINX IC and CRDs left in place."

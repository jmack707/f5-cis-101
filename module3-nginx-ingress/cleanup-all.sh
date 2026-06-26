#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
kdelete lab2-hello-world-nginx/05-cis-configmap.yaml
kdelete lab2-hello-world-nginx/04-cis-service.yaml
kdelete lab2-hello-world-nginx/03-nginx-ingress-hello-world.yaml
kdelete lab2-hello-world-nginx/02-clusterip-service-hello-world.yaml
kdelete lab2-hello-world-nginx/01-deployment-hello-world.yaml
echo "Demo removed. NGINX IC left running (module 4 reuses it)."

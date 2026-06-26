#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
kdelete lab2-cafe-app/03-cafe-ingress.yaml
kdelete lab2-cafe-app/02-cafe-secret.yaml
kdelete lab2-cafe-app/01-cafe.yaml
kdelete lab1-configure-ingresslink/05-vs-ingresslink.yaml
kdelete lab1-configure-ingresslink/04-ingresslink-deployment.yaml
kdelete lab1-configure-ingresslink/02-nginx-service.yaml
echo "IngressLink + CIS removed. NGINX IC and CRDs left in place."

#!/usr/bin/env bash
# Module 3 — NGINX IC (lab 3.1) + CIS-published demo (lab 3.2). Requires module 2 CIS.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
echo "== Lab 3.1: NGINX Ingress Controller =="
bash lab1-deploy-nginx-ic/install-nginx-ic.sh || true
echo "== Lab 3.2: app behind NGINX, published by CIS =="
kapply lab2-hello-world-nginx/01-deployment-hello-world.yaml
kapply lab2-hello-world-nginx/02-clusterip-service-hello-world.yaml
kapply lab2-hello-world-nginx/03-nginx-ingress-hello-world.yaml
kapply lab2-hello-world-nginx/04-cis-service.yaml
kapply lab2-hello-world-nginx/05-cis-configmap.yaml
echo "== Verify =="
settle_ingress nginx-ingress nginx-ingress-hello-world "$NGINX_FRONT_VIP" AS3 120
bash lab1-deploy-nginx-ic/verify.sh || true; bash lab2-hello-world-nginx/verify.sh || true

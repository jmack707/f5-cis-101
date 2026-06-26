#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
kdelete lab2-ingress/03-ingress-hello-world.yaml
kdelete lab2-ingress/02-clusterip-service-hello-world.yaml
kdelete lab2-ingress/01-deployment-hello-world.yaml
kdelete lab3-configmap-as3/03-configmap-hello-world.yaml
kdelete lab3-configmap-as3/02-clusterip-service-hello-world.yaml
kdelete lab3-configmap-as3/01-deployment-hello-world.yaml
kdelete lab1-install-cis/03-cluster-deployment.yaml
echo "CIS + demos removed. Static routes withdraw when CIS stops."

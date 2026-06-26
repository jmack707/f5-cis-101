#!/usr/bin/env bash
# Lab 4.1 — configure F5 IngressLink (CIS CRD mode + IngressLink CR).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
CIS_CRD_VERSION="${CIS_CRD_VERSION:-2.x-master}"

echo "== Lab 4.1 — Configure F5 IngressLink =="
echo "   PREREQUISITES (do these first):"
echo "    • NGINX IC from module 3 lab1 must be running (this lab reuses it)."
echo "    • On the BIG-IP, create iRule 'Proxy_Protocol_iRule' from 01-Proxy_Protocol_iRule.tcl"
echo "      (TMUI ▸ Local Traffic ▸ iRules ▸ Create) — needed for the real client IP."
echo
remove_other_cis k8s-bigip-ctlr
step "install the IngressLink CRD bundle (${CIS_CRD_VERSION})"
kubectl apply -f "https://raw.githubusercontent.com/F5Networks/k8s-bigip-ctlr/${CIS_CRD_VERSION}/docs/config_examples/customResourceDefinitions/customresourcedefinitions.yml"
step "apply  02-nginx-service.yaml + 03-nginx-config.yaml (NGINX IC svc + PROXY protocol)"
kapply 02-nginx-service.yaml
kapply 03-nginx-config.yaml
step "apply  04-ingresslink-deployment.yaml (CIS in CRD mode)"
kapply 04-ingresslink-deployment.yaml
step "waiting for the CIS controller pod to be ready"
kubectl -n "$CIS_NAMESPACE" rollout status deploy/k8s-bigip-ctlr --timeout=120s || true
step "apply  05-vs-ingresslink.yaml (the IngressLink CR)"
kapply 05-vs-ingresslink.yaml
echo; echo "✓ IngressLink configured.  Next:  bash verify.sh"

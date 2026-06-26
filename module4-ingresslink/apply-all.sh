#!/usr/bin/env bash
# Module 4 — IngressLink. Create the BIG-IP iRule (lab1/01-*.tcl) FIRST.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
cd "$HERE"
CIS_CRD_VERSION="${CIS_CRD_VERSION:-2.x-master}"
echo "== Remove any prior cluster/NodePort CIS =="
kubectl delete -f ../module2-clusterip/lab1-install-cis/03-cluster-deployment.yaml --ignore-not-found 2>/dev/null || true
echo "== CIS CRDs (unified bundle, ${CIS_CRD_VERSION}) =="
kubectl apply -f "https://raw.githubusercontent.com/F5Networks/k8s-bigip-ctlr/${CIS_CRD_VERSION}/docs/config_examples/customResourceDefinitions/customresourcedefinitions.yml"
echo "== Lab 4.1: NGINX svc/config + CRD-mode CIS + IngressLink CR =="
kapply lab1-configure-ingresslink/02-nginx-service.yaml
kapply lab1-configure-ingresslink/03-nginx-config.yaml
kapply lab1-configure-ingresslink/04-ingresslink-deployment.yaml
kubectl -n "$CIS_NAMESPACE" rollout status deploy/k8s-bigip-ctlr --timeout=120s || true
kapply lab1-configure-ingresslink/05-vs-ingresslink.yaml
echo "== Verify =="
settle_ingress nginx-ingress nginx-ingress-ingresslink "$INGRESSLINK_VIP" "$BIGIP_PARTITION" 120
bash lab1-configure-ingresslink/verify.sh || true
echo "Run lab2-cafe-app/ then 'bash lab2-cafe-app/verify.sh' for the end-to-end test."

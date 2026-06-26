#!/usr/bin/env bash
# Lab 3.1 - Install NGINX Ingress Controller (OSS), pinned to v3.7.2.
# Self-contained manifest install from the files in this folder.
# Run from kube-master1.
set -euo pipefail
cd "$(dirname "$0")"

kubectl apply -f 00-crds.yaml
kubectl apply -f 01-ns-and-sa.yaml
kubectl apply -f 02-rbac.yaml
kubectl apply -f 03-default-server-secret.yaml
kubectl apply -f 04-nginx-config.yaml
kubectl apply -f 05-ingress-class.yaml
kubectl apply -f 06-nginx-ingress-deployment.yaml
kubectl apply -f 07-service-nodeport.yaml

kubectl -n nginx-ingress rollout status deploy/nginx-ingress --timeout=120s
kubectl get pods,svc -n nginx-ingress
kubectl get ingressclass
echo
echo "NGINX IC v3.7.2 ready in namespace nginx-ingress (IngressClass: nginx)."
echo "Continue to ../lab2-hello-world-nginx/."

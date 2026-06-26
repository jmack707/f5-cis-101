#!/usr/bin/env bash
# CIS NodePort lab — prerequisites. Reads BIG-IP creds from lab-vars.env (no
# hardcoded password). Credentials secret feeds --credentials-directory.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"

# 1) Service account
kubectl create serviceaccount k8s-bigip-ctlr -n "$CIS_NAMESPACE" || true

# 2) Cluster role binding (lab uses cluster-admin; tighten for non-lab use)
kubectl create clusterrolebinding k8s-bigip-ctlr-clusteradmin \
  --clusterrole=cluster-admin \
  --serviceaccount="$CIS_NAMESPACE:k8s-bigip-ctlr" || true

# 3) BIG-IP credentials secret (username + password + url)
kubectl create secret generic f5-bigip-ctlr-login -n "$CIS_NAMESPACE" \
  --from-literal=username="$BIGIP_USER" \
  --from-literal=password="$BIGIP_PASS" \
  --from-literal=url="$BIGIP_MGMT" \
  --dry-run=client -o yaml | kubectl apply -f -

# 4) (Optional, recommended over --insecure) Trust the BIG-IP cert instead:
#   echo | openssl s_client -showcerts -servername "$BIGIP_MGMT" \
#     -connect "$BIGIP_MGMT":443 2>/dev/null | openssl x509 -outform PEM > server_cert.pem
#   kubectl create configmap trusted-certs --from-file=./server_cert.pem -n "$CIS_NAMESPACE"

echo "Prereqs ready in namespace $CIS_NAMESPACE."

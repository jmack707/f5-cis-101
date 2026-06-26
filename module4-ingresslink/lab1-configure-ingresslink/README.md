# Lab 4.1 — Configure F5 IngressLink

Wires a BIG-IP VS (CIS IngressLink CRD) to the NGINX IC pods with PROXY protocol.

## Files
| File | Purpose | Apply with |
|------|---------|-----------|
| `01-Proxy_Protocol_iRule.tcl` | iRule pasted into BIG-IP (name: `Proxy_Protocol_iRule`) | TMUI |
| `02-nginx-service.yaml` | NGINX IC service on 80/443 (+ optional 8081 readiness) | `kubectl create` |
| `03-nginx-config.yaml` | enables PROXY protocol on the IC | `kubectl apply` |
| `04-ingresslink-deployment.yaml` | CIS in CRD mode (static routes) | `kubectl create` |
| `05-vs-ingresslink.yaml` | IngressLink CR (VIP 10.1.1.4) | `kubectl create` |

## Step 0 — install the IngressLink CRD (unified bundle)
```bash
export CIS_VERSION=2.x-master      # or a pinned tag, e.g. v2.20.0
kubectl create -f https://raw.githubusercontent.com/F5Networks/k8s-bigip-ctlr/${CIS_VERSION}/docs/config_examples/customResourceDefinitions/customresourcedefinitions.yml
```

## Deploy
```bash
# 1. BIG-IP: create iRule 'Proxy_Protocol_iRule' from 01-Proxy_Protocol_iRule.tcl
#    (TMUI ▸ Local Traffic ▸ iRules ▸ Create)
# 2. Remove any prior cluster/NodePort CIS:
kubectl delete -f ../../module2-clusterip/lab1-install-cis/03-cluster-deployment.yaml 2>/dev/null || true
# 3. NGINX IC service + proxy-protocol config:
kubectl create -f 02-nginx-service.yaml
kubectl apply  -f 03-nginx-config.yaml
# 4. CIS in CRD mode, then the IngressLink resource:
kubectl create -f 04-ingresslink-deployment.yaml
kubectl get pods -A | grep k8s-bigip-ctlr
kubectl create -f 05-vs-ingresslink.yaml
```

## Verify
TMUI ▸ Local Traffic ▸ **kubernetes** partition: two virtual servers,
`ingress_link_crd_10_1_1_4_80` and `_443`, with a pool member = the NGINX IC pod IP:
```bash
kubectl describe svc nginx-ingress-ingresslink -n nginx-ingress
```

## Cleanup
```bash
kubectl delete -f 05-vs-ingresslink.yaml
kubectl delete -f 04-ingresslink-deployment.yaml
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

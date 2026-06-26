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

## Deploy
**Prerequisites:** the NGINX IC from module 3 lab 3.1 must be running, and on the
BIG-IP you must create iRule `Proxy_Protocol_iRule` from `01-Proxy_Protocol_iRule.tcl`
(TMUI ▸ Local Traffic ▸ iRules ▸ Create) for the real client IP to pass through.

```bash
bash deploy.sh     # CRDs + NGINX svc/config + CRD-mode CIS + IngressLink CR (removes other CIS first)
bash verify.sh     # PASS/FAIL checks
```
`deploy.sh` installs the IngressLink CRD bundle for you; override the version with
`CIS_CRD_VERSION=v2.20.0 bash deploy.sh`.

## Verify
TMUI ▸ Local Traffic ▸ **kubernetes** partition: two virtual servers,
`ingress_link_crd_10_1_1_4_80` and `_443`, with a pool member = the NGINX IC pod IP:
```bash
kubectl describe svc nginx-ingress-ingresslink -n nginx-ingress
```

## Cleanup
```bash
bash cleanup.sh    # removes IngressLink + CIS; leaves the NGINX IC and CRDs in place
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

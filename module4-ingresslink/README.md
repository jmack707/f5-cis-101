# Module 4 — F5 IngressLink

IngressLink is the BIG-IP↔NGINX integration: a BIG-IP virtual server (via a CIS
CRD) load-balances the NGINX Ingress Controller pods, with PROXY protocol passing
the real client IP through to the app. CIS runs in **CRD mode**.

## Labs
| Lab | Folder | What it does |
|-----|--------|--------------|
| 4.1 | `lab1-configure-ingresslink/` | iRule, NGINX service/config, CRD-mode CIS, IngressLink CR |
| 4.2 | `lab2-cafe-app/` | End-to-end test with the bundled cafe app (coffee/tea over TLS) |

## Run the labs (in order)
Each lab folder is self-contained: `bash deploy.sh` → `bash verify.sh` → `bash cleanup.sh`.
Lab 4.1's `deploy.sh` creates the `Proxy_Protocol_iRule` on the BIG-IP for you (iControl REST).

```bash
# Lab 4.1 — CRDs + NGINX svc/config + CRD-mode CIS + IngressLink CR
cd lab1-configure-ingresslink && bash deploy.sh && bash verify.sh && cd ..

# Lab 4.2 — end-to-end test with the cafe app
cd lab2-cafe-app              && bash deploy.sh && bash verify.sh && bash cleanup.sh && cd ..

# Tear down IngressLink + CIS when finished:
cd lab1-configure-ingresslink && bash cleanup.sh && cd ..
```

## Compatibility (current docs)
CIS v2.4+ · BIG-IP v13.1+ · NGINX+ IC v1.10+ · AS3 3.18+

## Prerequisites
- NGINX Ingress Controller running in `nginx-ingress` (module 3 / lab 3.1).
- Any prior CIS controller (NodePort or cluster) deleted — module 4 uses its own
  CRD-mode CIS.

## The key modernization
The original lab passed both `--custom-resource-mode=true` and
`--ingress-link-mode=true`. Current CIS folds IngressLink into CRD mode —
`--ingress-link-mode` is gone from the config-parameters reference, so only
`--custom-resource-mode=true` is needed. The networking also uses static routes
(`--static-routing-mode=true` + `--orchestration-cni=flannel`) like module 2.

> Source: https://clouddocs.f5.com/training/community/containers/html/class1/module4/module4.html
> IngressLink: https://clouddocs.f5.com/containers/latest/userguide/ingresslink/

## Common errors
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `no matches for kind "IngressLink"` | CRDs not installed | apply the unified `customresourcedefinitions.yml` (lab 4.1 `deploy.sh` does this) |
| IngressLink VS not created | leftover non-CRD CIS, or wrong mode | delete prior CIS; confirm `--custom-resource-mode=true` (no `--ingress-link-mode`) |
| App reachable but client IP wrong | PROXY protocol not end-to-end | iRule `Proxy_Protocol_iRule` present + referenced; `proxy-protocol: "True"` in `nginx-config` |
| iRule reference error on the VS | iRule name/path mismatch | create the iRule as `Proxy_Protocol_iRule` in `/Common` |

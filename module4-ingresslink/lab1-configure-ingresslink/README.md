# Lab 4.1 — Configure F5 IngressLink

Wires a BIG-IP VS (CIS IngressLink CRD) to the NGINX IC pods with PROXY protocol.

## Files
| File | Purpose | Apply with |
|------|---------|-----------|
| `01-Proxy_Protocol_iRule.tcl` | iRule body (name: `Proxy_Protocol_iRule`) | `deploy.sh` (iControl REST) |
| `02-nginx-service.yaml` | NGINX IC service on 80/443 (+ optional 8081 readiness) | `kubectl create` |
| `03-nginx-config.yaml` | enables PROXY protocol on the IC | `kubectl apply` |
| `04-ingresslink-deployment.yaml` | CIS in CRD mode (static routes) | `kubectl create` |
| `05-vs-ingresslink.yaml` | IngressLink CR (VIP 10.1.1.4) | `kubectl create` |

## Anatomy — IngressLink = the NGINX-aware way to publish the IC
Module 3 published the NGINX IC with a hand-written AS3 ConfigMap (lab 3.2). **IngressLink
replaces that** with a purpose-built CRD: you declare one `IngressLink` object and CIS
builds the BIG-IP VS, tracks the NGINX pods, and attaches the PROXY-protocol iRule for
you. Four pieces have to line up:

**1. CRD-mode CIS** (`04-ingresslink-deployment.yaml`) — the enabler:

| Field | Why it matters |
|-------|----------------|
| `--custom-resource-mode=true` | **The mode decision.** CIS now watches CRDs (incl. `IngressLink`) instead of Ingress/ConfigMap objects. Modules 1–3 used `false`. (The old `--ingress-link-mode=true` is gone — folded into CRD mode.) |
| `--pool-member-type=cluster` + `--static-routing-mode=true` | Same cluster-mode data path as module 2 — pool members are NGINX **pod IPs** over CIS-written routes. |

**2. The IngressLink CR** (`05-vs-ingresslink.yaml`) — the declaration CIS acts on:

```yaml
apiVersion: cis.f5.com/v1
kind: IngressLink
metadata:
  name: vs-ingresslink
  namespace: nginx-ingress
spec:
  virtualServerAddress: "${INGRESSLINK_VIP}"   # the BIG-IP VIP CIS creates (lab uses 10.1.1.4)
  iRules:
    - /Common/Proxy_Protocol_iRule             # iRule CIS attaches -> emits PROXY protocol to NGINX
  selector:
    matchLabels:
      app: nginx-ingress                       # which pods become pool members = the NGINX IC pods
```

| Field | Why it matters |
|-------|----------------|
| `virtualServerAddress` | The VIP CIS stands up. CIS creates **two** virtual servers from it — `ingress_link_crd_<vip>_80` and `_443` — so the BIG-IP fronts both HTTP and HTTPS. |
| `iRules` | CIS attaches this iRule to the VS. It prepends a **PROXY protocol** header so NGINX learns the real client IP across the BIG-IP hop (see piece 4). |
| `selector.matchLabels` | The pod selector — `app: nginx-ingress` matches the NGINX IC pods from lab 3.1, so the BIG-IP pool tracks them automatically as they scale. |

**3. PROXY protocol on NGINX** (`03-nginx-config.yaml`) — the receiving end:
`proxy-protocol: "True"` + `real-ip-header: "proxy_protocol"` tell NGINX to *parse* the
PROXY header the iRule sends and surface the real client IP as `X-Real-IP` to the app.

**4. The iRule** (`01-Proxy_Protocol_iRule.tcl`) — applied to the BIG-IP via iControl REST
by `deploy.sh` (no TMUI step). This is the *sender* the CR's `iRules` field references.

**Flow:** client → **BIG-IP VS** (from the CR's `virtualServerAddress`) → iRule prepends
PROXY header → **NGINX IC pod** (selected by `app: nginx-ingress`, parses PROXY → real
client IP) → **app pod**. One CRD wires all of it; CIS keeps the pool in sync with the
NGINX pods.

> **vs. module 3:** lab 3.2 also put a BIG-IP VS in front of NGINX, but you wrote the AS3
> by hand and got no client-IP preservation. IngressLink is the supported, NGINX-aware
> path — declarative CR, two VS (80/443), and PROXY protocol built in.

## Deploy
**Prerequisite:** the NGINX IC from module 3 lab 3.1 must be running.

```bash
bash deploy.sh     # iRule + CRDs + NGINX svc/config + CRD-mode CIS + IngressLink CR
bash verify.sh     # PASS/FAIL checks
```
`deploy.sh` creates the `Proxy_Protocol_iRule` on the BIG-IP (iControl REST) and
installs the IngressLink CRD bundle for you — no TMUI step. Override the CRD
version with `CIS_CRD_VERSION=v2.20.0 bash deploy.sh`.

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

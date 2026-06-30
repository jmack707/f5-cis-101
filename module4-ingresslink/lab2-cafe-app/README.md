# Lab 4.2 — Deploy the Cafe Application (end-to-end IngressLink test)

End-to-end IngressLink test with the NGINX "cafe" example (coffee/tea behind TLS).
Manifests are the real upstream IngressLink example files (already use
`ingressClassName: nginx`), bundled here. Requires lab 4.1 (IngressLink configured)
and the NGINX IC from lab 3.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-cafe.yaml` | coffee (2 replicas) + tea (3 replicas) deployments and services |
| `02-cafe-secret.yaml` | TLS secret `cafe-secret` for `cafe.example.com` (example cert) |
| `03-cafe-ingress.yaml` | NGINX Ingress routing `/coffee` and `/tea` (TLS) |

## Anatomy — the whole chain, exercised end-to-end
Lab 4.1 built the plumbing (BIG-IP VS → PROXY iRule → NGINX). This lab drops a **real app
with TLS and path routing** on top so you can prove every hop works. Nothing here touches
CIS or IngressLink — it's a standard NGINX workload that rides the IngressLink VIP:

| File | Who reads it | What it does |
|------|--------------|--------------|
| `01-cafe.yaml` | (the apps) | Two services behind NGINX: `coffee` (2 replicas) + `tea` (3 replicas), `nginxdemos/nginx-hello` so each response names its serving pod. |
| `02-cafe-secret.yaml` | **NGINX IC** | TLS secret `cafe-secret` for `cafe.example.com` — NGINX **terminates TLS** (the BIG-IP just passes L4). |
| `03-cafe-ingress.yaml` (`ingressClassName: nginx`, host `cafe.example.com`, `/coffee` → coffee, `/tea` → tea) | **NGINX IC** | The L7 routing + TLS rule. Claimed by the `nginx` IngressClass — CIS never sees it; it only knows about the NGINX pods via the IngressLink CR. |

**Flow (the full module-4 chain):**
```
client ──TLS──▶ BIG-IP VS (IngressLink, :443)
        │        └─ PROXY iRule prepends real client IP
        ▼
     NGINX IC pod  ── terminates TLS, parses PROXY header
        │            ── matches host cafe.example.com + path /coffee|/tea
        ▼
   coffee / tea pod  ── sees real client IP as X-Real-IP
```

**What each test assertion proves:**
- **Server name = a coffee/tea pod** → NGINX path routing + the BIG-IP pool (IngressLink
  selecting the NGINX pods) both work.
- **X-Real-IP / X-Forwarded-For = your client IP** → PROXY protocol carried the real
  source IP the whole way (BIG-IP iRule → NGINX → pod). Without lab 4.1's iRule +
  `nginx-config` patch, this would show the BIG-IP's IP instead.

## Deploy
```bash
bash deploy.sh     # renders + applies the cafe manifests, waits for the coffee/tea pods
bash verify.sh     # PASS/FAIL checks
```

## Test
The Ingress routes on host `cafe.example.com`. Point that name at the IngressLink
VIP (10.1.1.4 from lab 4.1) — add to your client hosts file or use curl's
`--resolve`. From a host on the lab network:
```bash
curl --resolve cafe.example.com:443:10.1.1.4 -k https://cafe.example.com/coffee
curl --resolve cafe.example.com:443:10.1.1.4 -k https://cafe.example.com/tea
```
In the response, confirm:
- **Server name / address** = a coffee or tea pod
- **X-Real-IP / X-Forwarded-For** = your client IP — proves PROXY protocol is
  carrying the real client IP BIG-IP → NGINX → pod.

## Notes
- The TLS cert in `02-cafe-secret.yaml` is the upstream self-signed example for
  `cafe.example.com` — fine for the lab; replace for anything real.
- `01-cafe.yaml` uses `nginxdemos/nginx-hello` (the styled HTML page, listens on
  **:8080**), which shows the serving pod's name/address — handy for confirming load
  balancing in a browser. The upstream NGINX example ships the `:plain-text` tag;
  we use the default (webpage) tag, consistent with the rest of the repo.

## Cleanup
```bash
bash cleanup.sh                                  # remove the cafe app
bash ../lab1-configure-ingresslink/cleanup.sh    # then tear down IngressLink + CIS
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

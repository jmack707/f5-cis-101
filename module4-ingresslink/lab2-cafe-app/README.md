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
- `01-cafe.yaml` uses `nginxdemos/hello:plain-text` (listens on :80), which echoes
  the server name and request headers (handy for confirming load balancing). The
  upstream NGINX example ships `nginxdemos/nginx-hello:plain-text` (:8080) — same
  app, swapped here so the whole repo mirrors a single demo image.

## Cleanup
```bash
bash cleanup.sh                                  # remove the cafe app
bash ../lab1-configure-ingresslink/cleanup.sh    # then tear down IngressLink + CIS
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

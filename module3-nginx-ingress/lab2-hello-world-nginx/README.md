# Lab 3.2 — Hello-World behind NGINX IC, published by CIS

The app sits behind the NGINX Ingress Controller (L7, host-based routing); CIS
publishes a BIG-IP VS whose pool members are the NGINX IC pods.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app |
| `02-clusterip-service-hello-world.yaml` | backend service for NGINX |
| `03-nginx-ingress-hello-world.yaml` | Ingress for **NGINX** (`ingressClassName: nginx`) |
| `04-cis-service.yaml` | service CIS watches (namespace `nginx-ingress`) |
| `05-cis-configmap.yaml` | AS3 decl → BIG-IP VS targeting NGINX pods |

## Deploy
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks
```

## Verify
TMUI ▸ Local Traffic ▸ **AS3** partition: `serviceMain` VS with `web_pool` members =
the NGINX IC pod IP(s). Test with the Host header (NGINX routes on host, not IP):
```bash
curl -H 'Host: mysite.f5demo.com' http://10.1.10.101/
```

## What changed vs the lab
- `kubernetes.io/ingress.class: "nginx"` annotation → `spec.ingressClassName: nginx`.
- AS3 `schemaVersion` 3.10.0 → 3.50.0 (3.10.0 was below the 3.18+ minimum).
- Service/ConfigMap namespace match and `servicePort` = service `port` retained
  (required since CIS v2.1 / v2.2.2).

## Cleanup
```bash
bash cleanup.sh    # removes the demo; leaves the NGINX IC and CIS running
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

# Lab 2.2 — Deploy Hello-World via Ingress (ClusterIP)

Same Ingress flow as lab 1.2, but in cluster mode: pool members are pod overlay
IPs reached over the static routes from lab 2.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app |
| `02-clusterip-service-hello-world.yaml` | ClusterIP service |
| `03-ingress-hello-world.yaml` | Ingress (`virtual-server.f5.com` annotations) |

## Deploy
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **kubernetes** partition: VS on 10.1.10.101:80 and a pool
whose members are **pod IPs** (not NodePorts) — the difference from module 1.

## Cleanup (do not skip)
```bash
bash cleanup.sh
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

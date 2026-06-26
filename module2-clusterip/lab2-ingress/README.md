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
kubectl create -f 01-deployment-hello-world.yaml
kubectl create -f 02-clusterip-service-hello-world.yaml
kubectl create -f 03-ingress-hello-world.yaml
kubectl describe svc f5-hello-world-web    # note the pod Endpoints
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **kubernetes** partition: VS on 10.1.10.101:80 and a pool
whose members are **pod IPs** (not NodePorts) — the difference from module 1.

## Cleanup (do not skip)
```bash
kubectl delete -f 03-ingress-hello-world.yaml
kubectl delete -f 02-clusterip-service-hello-world.yaml
kubectl delete -f 01-deployment-hello-world.yaml
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

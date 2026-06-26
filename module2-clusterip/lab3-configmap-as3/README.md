# Lab 2.3 — Deploy Hello-World via ConfigMap/AS3 (ClusterIP)

ConfigMap/AS3 flow in cluster mode. Pool members are pod IPs over the static
routes. Demonstrates that scaling the app updates pool members directly (in
NodePort mode they stayed fixed at the node count).

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app |
| `02-clusterip-service-hello-world.yaml` | ClusterIP service with AS3 labels |
| `03-configmap-hello-world.yaml` | AS3 declaration (VIP 10.1.10.101) |

## Deploy
```bash
kubectl create -f 01-deployment-hello-world.yaml
kubectl create -f 02-clusterip-service-hello-world.yaml
kubectl create -f 03-configmap-hello-world.yaml
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **AS3** partition: `serviceMain` VS on 10.1.10.101:80 and
`web_pool` with pod IP members. Scale up and watch members grow:
```bash
kubectl scale --replicas=10 deployment/f5-hello-world-web -n default
```

## Notes
- `schemaVersion` 3.50.0 (set `<=` the AS3 build on your BIG-IP).

## Cleanup
```bash
kubectl delete -f 03-configmap-hello-world.yaml
kubectl delete -f 02-clusterip-service-hello-world.yaml
kubectl delete -f 01-deployment-hello-world.yaml
```
Continuing to module 3? Leave the cluster-mode CIS running. Otherwise:
`kubectl delete -f ../lab1-install-cis/03-cluster-deployment.yaml`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

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
> Publishes the same VIP as lab 2.2, so run `bash ../lab2-ingress/cleanup.sh`
> first if lab 2.2 is still up.
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks
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
bash cleanup.sh
```
Continuing to module 3? Leave the cluster-mode CIS running. Otherwise remove it:
`bash ../lab1-install-cis/cleanup.sh`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

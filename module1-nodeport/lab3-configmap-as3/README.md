# Lab 1.3 — Deploy Hello-World via ConfigMap/AS3 (NodePort)

Same app as lab 1.2, but published through an **AS3 ConfigMap** instead of an
Ingress. CIS reads the `cis.f5.com/as3-*` service labels to populate `web_pool`.
Requires the CIS controller from lab 1.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app (same as lab 1.2) |
| `02-nodeport-service-hello-world.yaml` | NodePort service with AS3 discovery labels |
| `03-configmap-hello-world.yaml` | AS3 declaration (Service_HTTP + web_pool) |

## Deploy
```bash
kubectl create -f 01-deployment-hello-world.yaml
kubectl create -f 02-nodeport-service-hello-world.yaml
kubectl create -f 03-configmap-hello-world.yaml
kubectl get pods -o wide
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **AS3** partition (auto-created, named after the tenant):
a `serviceMain` virtual server on 10.1.1.4:80 and a `web_pool`. Scale the app
(`kubectl scale --replicas=10 deployment/f5-hello-world-web`) and watch members
update.

## Notes
- `schemaVersion` is set to `3.50.0` (up from the lab's 3.18.0 floor). Set it `<=`
  the AS3 build installed on your BIG-IP.
- AS3 v2.20+ removes the old need for a "blank declaration" to tear down — deleting
  the ConfigMap removes the objects.

## Cleanup
```bash
kubectl delete -f 03-configmap-hello-world.yaml
kubectl delete -f 02-nodeport-service-hello-world.yaml
kubectl delete -f 01-deployment-hello-world.yaml
```
Verify the AS3 partition is gone on BIG-IP (can take ~30s). If you're done with
NodePort mode, remove CIS:
`kubectl delete -f ../lab1-install-cis/02-nodeport-deployment.yaml`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

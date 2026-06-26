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
# App + NGINX front door
kubectl create -f 01-deployment-hello-world.yaml
kubectl create -f 02-clusterip-service-hello-world.yaml
kubectl create -f 03-nginx-ingress-hello-world.yaml

# CIS publishes the BIG-IP VS for the NGINX pods
kubectl create -f 04-cis-service.yaml
kubectl create -f 05-cis-configmap.yaml
kubectl describe svc nginx-ingress-hello-world -n nginx-ingress
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
kubectl delete -f 05-cis-configmap.yaml
kubectl delete -f 04-cis-service.yaml
kubectl delete -f 03-nginx-ingress-hello-world.yaml
kubectl delete -f 02-clusterip-service-hello-world.yaml
kubectl delete -f 01-deployment-hello-world.yaml
# Remove CIS only if you're not going to module 4:
# kubectl delete -f ../../module2-clusterip/lab1-install-cis/03-cluster-deployment.yaml
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

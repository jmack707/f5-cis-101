# Module 3 — Expose Service with NGINX Ingress Controller

Two-tier ingress: the in-cluster **NGINX Ingress Controller** does L7 routing, and
CIS publishes a BIG-IP virtual server that load-balances the NGINX pods. Reuses the
cluster-mode (static-route) CIS from module 2.

## Labs
| Lab | Folder | What it does |
|-----|--------|--------------|
| 3.1 | `lab1-deploy-nginx-ic/` | Install NGINX Ingress Controller v3.7.2 (bundled manifests + script) |
| 3.2 | `lab2-hello-world-nginx/` | App → NGINX IC → BIG-IP VS (via CIS/AS3) |

## Prerequisites
- Module 2's cluster-mode CIS (`module2-clusterip/lab1-install-cis/03-cluster-deployment.yaml`) running.

## Quick run
```bash
bash apply-all.sh      # installs NGINX IC (3.1) + the CIS-published demo (3.2)
bash cleanup-all.sh    # removes the demo (leaves the IC for module 4)
```

> Source: https://clouddocs.f5.com/training/community/containers/html/class1/module3/module3.html

## Common errors
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Ingress ignored by NGINX | IngressClass missing/mismatched | `kubectl get ingressclass` shows `nginx`; manifest uses `ingressClassName: nginx` |
| CIS VS has no members | service/configmap namespace mismatch | both must be in `nginx-ingress`; `servicePort` must equal the service `port` |
| 404 from the VIP | missing `Host` header | NGINX routes on host: `curl -H 'Host: mysite.f5demo.com' http://<vip>/` |
| AS3 rejected, log `schemaVersion` error | AS3 on BIG-IP older than declaration | lower `AS3_SCHEMA_VERSION` in `lab-vars.env` to the installed build |

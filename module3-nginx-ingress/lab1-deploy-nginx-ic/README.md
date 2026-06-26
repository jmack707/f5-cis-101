# Lab 3.1 — Deploy the NGINX Ingress Controller

Installs the **NGINX Ingress Controller (OSS), pinned to v3.7.2** into the
`nginx-ingress` namespace. These are the upstream `nginxinc/kubernetes-ingress`
manifests (Apache-2.0), bundled here so the lab runs without fetching anything.

## Files (applied in order by the script)
| File | Purpose |
|------|---------|
| `00-crds.yaml` | NGINX IC custom resource definitions |
| `01-ns-and-sa.yaml` | `nginx-ingress` namespace + service account |
| `02-rbac.yaml` | ClusterRole + binding |
| `03-default-server-secret.yaml` | default TLS secret for the catch-all server |
| `04-nginx-config.yaml` | `nginx-config` ConfigMap (module 4 patches this for PROXY protocol) |
| `05-ingress-class.yaml` | IngressClass `nginx` (controller `nginx.org/ingress-controller`) |
| `06-nginx-ingress-deployment.yaml` | the controller Deployment (image `nginx/nginx-ingress:3.7.2`) |
| `07-service-nodeport.yaml` | NodePort service (80/443) |
| `install-nginx-ic.sh` | applies all of the above in order and waits for rollout |

## Install
```bash
bash install-nginx-ic.sh
# or manually: kubectl apply -f 00-crds.yaml ; kubectl apply -f 01-... (in order)
```

## Verify
```bash
kubectl get pods -n nginx-ingress
kubectl get ingressclass            # expect 'nginx'
```

## Notes
- Pod template carries both `app: nginx-ingress` and `app.kubernetes.io/name:
  nginx-ingress`, so the `app: nginx-ingress` selectors used in lab 3.2 and in
  module 4 match correctly.
- To bump the version, change the tag in `install-nginx-ic.sh`'s source repo or
  re-pull the same file paths at a newer tag; keep the image tag in
  `06-nginx-ingress-deployment.yaml` in sync.
- **Air-gapped note (for your closed-network work):** the manifests are local, but
  the controller image `nginx/nginx-ingress:3.7.2` still pulls from a registry.
  Mirror it into your local registry and update the `image:` line for a true
  air-gapped install.

## Uninstall
```bash
kubectl delete -f 07-service-nodeport.yaml -f 06-nginx-ingress-deployment.yaml \
  -f 05-ingress-class.yaml -f 04-nginx-config.yaml -f 03-default-server-secret.yaml \
  -f 02-rbac.yaml -f 01-ns-and-sa.yaml --ignore-not-found
# CRDs last (removes any NGINX VirtualServer CRs too):
kubectl delete -f 00-crds.yaml --ignore-not-found
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

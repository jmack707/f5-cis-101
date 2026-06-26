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
bash deploy.sh     # applies the upstream NGINX IC manifests (via install-nginx-ic.sh), waits for rollout
bash verify.sh     # expect the IC pod Running + IngressClass 'nginx'
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
bash cleanup.sh    # NOTE: module 4 reuses this NGINX IC — only remove it when you're done with module 4
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

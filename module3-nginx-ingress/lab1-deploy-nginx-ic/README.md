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

## Anatomy — the second tier, and why it exists
Modules 1–2 had **one tier**: CIS published apps straight to the BIG-IP. Module 3 adds a
**second tier** — the NGINX Ingress Controller — *in front of* the apps. From here on the
roles split:

- **NGINX IC does the L7 work** — host/path routing, TLS termination, rewrites — using
  standard Kubernetes `Ingress` objects (lab 3.2).
- **CIS does the L4 work** — it publishes a BIG-IP VS whose pool members are the **NGINX
  IC pods** (lab 3.2), so the BIG-IP load-balances *into* NGINX, and NGINX routes onward.

This lab just installs that second tier. The pieces that matter:

| Object | Why it matters |
|--------|----------------|
| `IngressClass nginx` (`05-ingress-class.yaml`, controller `nginx.org/ingress-controller`) | The **claim ticket.** An app Ingress with `ingressClassName: nginx` (lab 3.2) is handled by *this* controller — and ignored by CIS. This is what keeps the two tiers from fighting over the same Ingress. |
| the controller Deployment (`06-…deployment.yaml`, image `nginx/nginx-ingress:3.7.2`) | The actual NGINX data plane — the pods that will become CIS pool members in lab 3.2 and the IngressLink target in module 4. |
| pod labels `app: nginx-ingress` | The handle everything downstream selects on — lab 3.2's CIS service and module 4's IngressLink both match `app: nginx-ingress` to find these pods. |
| `nginx-config` ConfigMap (`04-…`) | Global NGINX tuning. Inert here; **module 4 patches it** to enable PROXY protocol so the real client IP survives the BIG-IP → NGINX hop. |

**Flow (completed across labs):** client → **BIG-IP VS** (CIS, L4) → **NGINX IC pods**
(L7 routing on host/path) → **app pods**. This lab stands up the middle box; lab 3.2
wires the BIG-IP in front of it.

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

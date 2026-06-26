# Lab 1.1 — Install & Configure CIS (NodePort)

Brings up the CIS controller in NodePort mode and the BIG-IP/Kubernetes objects it
needs (partition, service account, RBAC, credentials secret).

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-setup.sh` | ServiceAccount, ClusterRoleBinding, BIG-IP credentials secret (+ optional trusted-certs) |
| `02-nodeport-deployment.yaml` | CIS controller, NodePort mode (hardened) |

## BIG-IP prep
- `deploy.sh` creates the `kubernetes` partition for you via iControl REST (uses the
  credentials in `lab-vars.env` — no SSH, no password prompt).
- Just confirm AS3 3.18+ is installed (iApps ▸ Package Management LX).

## Deploy
```bash
bash deploy.sh     # prereqs (01-setup.sh) + CIS controller, waits for the pod to be Running
bash verify.sh     # confirms the pod is up and reached the BIG-IP
```
Under the hood `deploy.sh` runs `01-setup.sh` then renders and applies
`02-nodeport-deployment.yaml`. To watch it yourself:
```bash
kubectl get pods -n kube-system | grep k8s-bigip-ctlr
kubectl logs deploy/k8s-bigip-ctlr-deployment -n kube-system
```

## What changed vs the lab
- `--credentials-directory=/tmp/creds` with a volume-mounted secret
  (`f5-bigip-ctlr-login`, incl. `url`) instead of env-var credential injection.
- Added `securityContext` (non-root, drop ALL caps, seccomp RuntimeDefault) and
  `/health` liveness/readiness probes.
- Dropped redundant `--agent=as3` (AS3 is the default).
- `--insecure=true` kept for the lab; `01-setup.sh` has the trusted-certs
  alternative commented in for non-prod.

## Cleanup
Leave CIS running for labs 1.2 / 1.3. To remove the controller entirely: `bash cleanup.sh`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

# Lab 1.1 — Install & Configure CIS (NodePort)

Brings up the CIS controller in NodePort mode and the BIG-IP/Kubernetes objects it
needs (partition, service account, RBAC, credentials secret).

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-setup.sh` | ServiceAccount, ClusterRoleBinding, BIG-IP credentials secret (+ optional trusted-certs) |
| `02-nodeport-deployment.yaml` | CIS controller, NodePort mode (hardened) |

## BIG-IP prep (once)
- Create the `kubernetes` partition: `ssh admin@10.1.1.5 tmsh create auth partition kubernetes`
- Confirm AS3 3.18+ is installed (iApps ▸ Package Management LX).

## Deploy
```bash
bash 01-setup.sh
kubectl create -f 02-nodeport-deployment.yaml
kubectl get deploy k8s-bigip-ctlr-deployment -n kube-system
kubectl get pods -n kube-system | grep k8s-bigip-ctlr   # wait for Running (~30s)
kubectl logs <cis-pod> -n kube-system                   # confirm it reached BIG-IP
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
Leave CIS running for labs 1.2 / 1.3. To remove entirely:
`kubectl delete -f 02-nodeport-deployment.yaml`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`./lab.sh apply <dir>` or the module `apply-all.sh`, not raw `kubectl create`.

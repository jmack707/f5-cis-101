# Lab 2.1 — Install & Configure CIS (ClusterIP, Static Routes)

Brings up CIS in cluster mode using static routes. No VXLAN — the only BIG-IP prep
is the partition; CIS programs the pod routes itself once running.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-bigip-setup.sh` | Ensure `kubernetes` partition (no VXLAN objects) |
| `02-setup.sh` | ServiceAccount, ClusterRoleBinding, BIG-IP secret (skip if done in module 1) |
| `03-cluster-deployment.yaml` | CIS controller, cluster mode + static routes |

## Deploy
```bash
bash deploy.sh     # BIG-IP prep + prereqs + CIS controller (removes any other module's CIS first)
bash verify.sh     # PASS/FAIL checks, incl. CIS-written static routes
```
`deploy.sh` runs `01-bigip-setup.sh` (partition) and `02-setup.sh` (SA/RBAC/secret),
then renders and applies `03-cluster-deployment.yaml`. To confirm the routes yourself:
```bash
ssh admin@<bigip> 'tmsh list net route | grep k8s-'
```

## Key args (vs the lab)
- `--static-routing-mode=true` + `--orchestration-cni=flannel` **replace**
  `--flannel-name=/Common/fl-tunnel`.
- `--pool-member-type=cluster`, hardened pod spec, credentials-directory secret.
- `--as3-validation=true` (lab 2.1 used `false`).

## Troubleshooting static routes
CIS reads podCIDR/nodeIP from the node object — for flannel that's
`node.Spec.PodCIDR` and `node.Status.Addresses`. If routes are missing:
`kubectl describe node <name>` and confirm the cluster assigns pod CIDRs
(`kube-controller-manager --allocate-node-cidrs=true`).

## Cleanup
Leave running for labs 2.2 / 2.3 (and module 3). To remove the controller: `bash cleanup.sh`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

# Lab 2.1 — Install & Configure CIS (ClusterIP, Static Routes)

Brings up CIS in cluster mode using static routes. No VXLAN — the only BIG-IP prep
is the partition; CIS programs the pod routes itself once running.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-bigip-setup.sh` | Ensure `kubernetes` partition (no VXLAN objects) |
| `02-setup.sh` | ServiceAccount, ClusterRoleBinding, BIG-IP secret (skip if done in module 1) |
| `03-cluster-deployment.yaml` | CIS controller, cluster mode + static routes |

## Anatomy — what makes this "cluster mode," and why
Same CIS controller as module 1, but three args change *where the pool members live*
and *how the BIG-IP reaches them*. Everything else (RBAC, credentials-directory,
`--bigip-partition`, `--custom-resource-mode=false`) is identical to lab 1.1.

| Field | Why it matters |
|-------|----------------|
| `--pool-member-type=cluster` | **The mode decision.** Pool members become **pod IPs** on the cluster overlay network — not `<nodeIP>:<nodePort>`. Scaling the app changes the member list directly (module 1's NodePort members stayed fixed at the node count). |
| `--static-routing-mode=true` | CIS **writes routes onto the BIG-IP** (named `k8s-<node>-<nodeip>`) so it can reach pod CIDRs. This replaces the old flannel VXLAN tunnel — no `--flannel-name`, no BIG-IP flannel node, no overlay encapsulation. |
| `--orchestration-cni=${ORCHESTRATION_CNI}` | Tells CIS which CNI the cluster runs so it reads pod CIDR / node IP from the right node fields (`node.Spec.PodCIDR`, `node.Status.Addresses`) when building those routes. Set in `lab-vars.env` (defaults to `flannel`); change it to `calico-k8s` / `cilium-k8s` / `antrea` to run the same manifest on another CNI. |
| `--bigip-partition` / `--custom-resource-mode=false` / credentials-directory | Unchanged from lab 1.1 — same control channel, same partition ownership, same Ingress + ConfigMap processing. |

**Flow:** CIS starts → reads each node's pod CIDR + node IP → writes a static route per
node onto the BIG-IP → publishes VS/pools whose members are **pod IPs** reachable over
those routes. Confirm the routes with `tmsh list net route | grep k8s-`.

> **NodePort vs cluster:** NodePort (module 1) hides pods behind `node:nodePort` and
> needs no pod-network routing; cluster mode sends BIG-IP traffic **straight to the pod
> IP**, so members track pods 1:1 — but the BIG-IP must have a route to the pod network,
> which is exactly what `--static-routing-mode` provides.

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
- `--static-routing-mode=true` + `--orchestration-cni=${ORCHESTRATION_CNI}` **replace**
  `--flannel-name=/Common/fl-tunnel` (CNI value comes from `lab-vars.env`).
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

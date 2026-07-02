# Lab 2.2 — Deploy Hello-World via Ingress (ClusterIP)

Same Ingress flow as lab 1.2, but in cluster mode: pool members are pod overlay
IPs reached over the static routes from lab 2.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `00-ingressclass-f5.yaml` | `f5` IngressClass (controller `f5.com/cntr-ingress-svcs`) — CIS's claim ticket |
| `01-deployment-hello-world.yaml` | the app |
| `02-clusterip-service-hello-world.yaml` | ClusterIP service |
| `03-ingress-hello-world.yaml` | Ingress (`virtual-server.f5.com` annotations, `ingressClassName: f5`) |

> **IngressClass (required):** like lab 1.2, CIS 2.x only builds a virtual server for an
> Ingress bound to the `f5` IngressClass. `00-ingressclass-f5.yaml` creates it and the
> Ingress sets `spec.ingressClassName: f5`. Without it CIS logs
> `[CORE] Ingress class resource not found` and programs nothing on the BIG-IP.

## Anatomy — same Ingress, different pool members
The Ingress and its `virtual-server.f5.com/*` annotations work **exactly** as in lab 1.2
(see that README's anatomy table for what each annotation does) — CIS still turns them
into a BIG-IP VS + pool. The **one difference is in the pool members**, and it comes
from lab 2.1's CIS mode, not from anything in this manifest:

| | Module 1 (NodePort) | Module 2 (cluster) |
|---|---|---|
| Service type | `NodePort` | `ClusterIP` |
| Pool member address | `<nodeIP>:<nodePort>` | **pod IP** on the overlay |
| Reachability | BIG-IP → node IP | BIG-IP → pod IP over CIS's **static routes** |
| Scaling the app | members fixed at node count | members track pods 1:1 |

**Flow:** Ingress annotations → CIS builds the VS at the VIP → pool members = the backend
Service's **pod endpoints** (not node:nodePort) → BIG-IP reaches them over the routes
CIS wrote in lab 2.1. Browse the VIP and refresh to watch load balancing across pods.

## Deploy
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **kubernetes** partition: VS on 10.1.10.101:80 and a pool
whose members are **pod IPs** (not NodePorts) — the difference from module 1.

## Cleanup (do not skip)
```bash
bash cleanup.sh
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

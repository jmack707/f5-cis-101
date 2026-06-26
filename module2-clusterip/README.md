# Module 2 — CIS Using ClusterIP Mode (Static Routes)

CIS deployed in **cluster** mode: BIG-IP pool members are pod overlay IPs. The
original lab used a flannel VXLAN tunnel; this version uses **static routing mode**
instead — CIS writes `k8s-<node>-<nodeip>` routes directly onto BIG-IP, so there's
no VXLAN tunnel, no tunnel self-IP, and BIG-IP does not join the cluster as a
flannel node.

## Labs
| Lab | Folder | What it does |
|-----|--------|--------------|
| 2.1 | `lab1-install-cis/` | BIG-IP partition + CIS controller (cluster mode, static routes) |
| 2.2 | `lab2-ingress/` | Publish f5-hello-world via **Ingress** (ClusterIP) |
| 2.3 | `lab3-configmap-as3/` | Publish via **ConfigMap/AS3** (ClusterIP) |

## Prerequisites
- BIG-IP licensed, AS3 3.18+ installed, `kubernetes` partition.
- **BIG-IP has L3 reachability to the cluster node IPs** (an existing data self-IP
  on the node network). The CIS-managed static routes resolve pod CIDRs through
  those node IPs. No VXLAN objects required.
- CIS 2.13.0+ for `--static-routing-mode` (the `:latest` image satisfies this).
- If module 1's CIS controller is still running, delete it first — only one CIS
  controller at a time.

## Order
Lab 2.1 (CIS up) → 2.2 and 2.3 (each deploys app, verifies, cleans up). Leave the
cluster-mode CIS running if you're continuing to module 3 (it reuses it).

## CNI note
`--orchestration-cni=flannel` matches the lab cluster's CNI. For other CNIs swap
the value (`cilium-k8s`, `ovn-k8s`, `antrea`, `calico-k8s`). Calico additionally
needs `blockaffinities` read permission on the CIS service account.

> Source: https://clouddocs.f5.com/training/community/containers/html/class1/module2/module2.html
> Static routes: https://clouddocs.f5.com/containers/latest/userguide/static-route-support.html

## Common errors
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `verify.sh`: "no k8s-* static routes" | static routing not programmed | confirm `--static-routing-mode=true` + `--orchestration-cni=flannel`; check `kubectl describe node` has `PodCIDR` |
| Routes exist but data-path FAIL | BIG-IP can't reach node IPs at L3 | BIG-IP needs a self-IP on the node network; verify with `ping`/`tmsh show net route` |
| Pool members are NodePorts, not pod IPs | controller still in NodePort mode | ensure `--pool-member-type=cluster` and that module 1's CIS was deleted |
| Empty `node.Spec.PodCIDR` | cluster doesn't allocate CIDRs | `kube-controller-manager --allocate-node-cidrs=true` |
| Calico instead of flannel | wrong CNI value / missing RBAC | set `--orchestration-cni=calico-k8s`; grant the SA read on `blockaffinities` |

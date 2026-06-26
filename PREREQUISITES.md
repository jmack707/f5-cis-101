# Prerequisites & Reproducing This Lab on Your Own Network

This class is portable — the manifests, scripts, and verification harness are
network-agnostic and driven entirely by `lab-vars.env`. What you must supply is the
surrounding infrastructure the F5 UDF normally provides. Run **`./preflight.sh`**
first; it checks everything below and tells you exactly what's missing.

## TL;DR reproducibility

| Modules | Reproducible with… |
|---------|--------------------|
| **1 & 3** | A BIG-IP (VE is fine) + any Kubernetes cluster on a routable network. Lowest bar. |
| **2** | The above **plus** BIG-IP L3 reachability to your node IPs and node `podCIDR`s populated. |
| **4** | The above **plus NGINX *Plus* Ingress Controller** (not the OSS IC used in Module 3). |
| Air-gapped | All of the above **plus** mirrored container images and a local copy of the CIS CRD bundle. |

## Hard requirements (preflight FAILs without these)

1. **A reachable, licensed BIG-IP** with **LTM provisioned** and **AS3 RPM 3.18+**
   installed (iApps ▸ Package Management LX). BIG-IP VE trial / non-prod tier works.
2. **A Kubernetes cluster** you can reach with `kubectl`, at least one node Ready.
   Your k3d homelab is fine for Modules 1, 3, 4.
3. **Tooling on the runner** (kube-master equivalent): `kubectl`, `curl`,
   `python3`, and `envsubst`. Install per your runner's OS:
   - Ubuntu/Debian: `sudo apt-get install -y gettext-base`
   - RHEL/Rocky/Alma 8–9: `sudo dnf install -y gettext`

   The scripts auto-detect the package manager and print the correct command if
   anything is missing — they run on both Ubuntu and RHEL/Rocky/Alma (8/9). The
   manifests are OS-agnostic (they run in Kubernetes).

## Per-module specifics

### Module 2 — ClusterIP / static routes
- BIG-IP needs an **L3 path to the node IPs** and a self-IP on the node network;
  CIS writes pod-CIDR-via-nodeIP routes, so no tunnel, but plain routing must exist.
- Nodes must have `spec.podCIDR` set (`kube-controller-manager
  --allocate-node-cidrs=true`). Preflight WARNs if any node lacks it.
- Different CNI? Set `--orchestration-cni` accordingly (`cilium-k8s` for your
  `cni-net-lab`); Calico also needs `blockaffinities` read on the CIS service account.

### Module 4 — IngressLink
- **Requires NGINX Plus IC.** The OSS controller installed in Module 3 (lab 3.1)
  does **not** support IngressLink. Without a Plus subscription you can complete
  Modules 1–3 and read through 4.
- `apply-all.sh` fetches the CIS CRD bundle from GitHub at apply time — needs
  internet, or drop a pinned `customresourcedefinitions.yml` locally and point the
  script at it.

### VIPs
The four VIPs in `lab-vars.env` (`NODEPORT_VIP`, `CLUSTER_VIP`, `NGINX_FRONT_VIP`,
`INGRESSLINK_VIP`) must be **free addresses your clients can route to**. Replace the
`10.1.x.x` defaults with addresses valid on your network. They won't answer until a
lab creates the virtual server, so preflight only echoes them — it can't test them live.

## Adapting to your network

Edit **only `lab-vars.env`**:
```bash
BIGIP_MGMT=<your BIG-IP mgmt IP>
BIGIP_USER=<admin user>
BIGIP_PASS=<password>
BIGIP_PARTITION=kubernetes
CIS_IMAGE=f5networks/k8s-bigip-ctlr:2.20.0   # pin to a tag you've mirrored, if air-gapped
NODEPORT_VIP=<free VIP on a routable subnet>
CLUSTER_VIP=<free VIP>
NGINX_FRONT_VIP=<free VIP>
INGRESSLINK_VIP=<free VIP>
AS3_SCHEMA_VERSION=<= your installed AS3 build>
```
Everything else renders from these. Then:
```bash
./preflight.sh                       # gate: confirms your environment is ready
cd module1-nodeport && bash apply-all.sh
```

## Air-gapped reproduction (your closed-network case)
- **Mirror images** into your local registry: the CIS image in `lab-vars.env`
  (`f5networks/k8s-bigip-ctlr:…`), `nginx/nginx-ingress:3.7.2` (Module 3), and the
  demo/cafe app image `nginxdemos/hello` (Modules 1–4). Update the `image:` fields /
  `lab-vars.env` to your registry.
- **Localize the CIS CRD bundle** for Module 4 instead of the GitHub fetch.
- This maps directly onto a Zarf/mirrored-registry workflow — the manifests are
  already local; only the images and the one CRD fetch need handling.

## What preflight cannot check for you
- Live VIP routability (no VS exists yet at preflight time).
- Whether your NGINX IC is OSS vs Plus (Module 4 needs Plus) — it can't tell until
  installed; preflight only reminds you.
- BIG-IP ↔ node data-plane reachability beyond the mgmt REST path (it verifies the
  management plane; the data path is proven by each lab's `verify.sh`).

# Class 1 — Kubernetes with F5 Container Ingress Services (CIS)

A modernized, verified rebuild of the F5 Agility "Containers" Class 1 labs. Every
manifest here was checked against the current CIS docs
(`https://clouddocs.f5.com/containers/latest`) and hardened/updated where the
original lab content had drifted. Use this as a hands-on path from a bare BIG-IP +
Kubernetes cluster to a full BIG-IP↔NGINX IngressLink integration.

> Original course: https://clouddocs.f5.com/training/community/containers/html/class1/class1.html

## What you'll build, module by module

| Module | Folder | Teaches | Pool member path |
|--------|--------|---------|------------------|
| 1 | `module1-nodeport/` | CIS in **NodePort** mode, exposed via Ingress and via ConfigMap/AS3 | Node IP : NodePort |
| 2 | `module2-clusterip/` | CIS in **ClusterIP/cluster** mode using **static routes** (no VXLAN) | Pod overlay IP (L3 routed) |
| 3 | `module3-nginx-ingress/` | Front the app with the **NGINX Ingress Controller**, published to BIG-IP by CIS | NGINX pod IP |
| 4 | `module4-ingresslink/` | **F5 IngressLink** — BIG-IP VS bound to NGINX IC with PROXY protocol | NGINX pod IP (CRD) |

Each module has a `README.md`; each lab folder has its own `README.md` with the
exact deploy / verify / cleanup steps for that lab.

## Lab environment (UDF defaults)

| Hostname | IP | Credentials |
|----------|----|-------------|
| ocp-provisioner | 10.1.1.4 | ubuntu / HelloUDF |
| bigip1 | 10.1.1.5 | admin / F5site02@ |
| kube-master1 | 10.1.1.11 | ubuntu / ubuntu (root/default) |
| kube-node1 | 10.1.1.12 | ubuntu / ubuntu (root/default) |
| kube-node2 | 10.1.1.13 | ubuntu / ubuntu (root/default) |

Run `kubectl` commands from **kube-master1**. Run BIG-IP `tmsh`/setup over SSH to
**10.1.1.5**. These IPs and the `F5site02@` password are baked into the setup
scripts and secrets — change them in one place (`lab1` of each module) if your
topology differs.

## Global prerequisites (once)

**Before anything else, run `./preflight.sh`** — it checks your tooling, cluster,
and BIG-IP (licensing, LTM, AS3 version, partition, node podCIDRs) and prints
exactly what's missing, with per-module readiness. See **`PREREQUISITES.md`** for
the full list and for adapting the class to your own network (it's portable — edit
`lab-vars.env` only). In brief, you need:

- Kubernetes cluster up; `kubectl` working from kube-master1.
- BIG-IP licensed (LTM VE is enough), **AS3 RPM 3.18+** installed
  (iApps ▸ Package Management LX).
- A BIG-IP partition named **kubernetes** (created in each module's lab 1; the
  script is idempotent so it's safe to re-run).
- For non-lab use, replace `--insecure=true` with a trusted-certs ConfigMap
  (`--trusted-certs-cfgmap=kube-system/trusted-certs`); see `module1/lab1`.

## Recommended path

Modules are largely independent but share the BIG-IP partition and the CIS
credentials secret. Suggested order:

```
module1-nodeport/lab1 → lab2 → lab3        (NodePort fundamentals)
module2-clusterip/lab1 → lab2 → lab3       (ClusterIP + static routes)
module3-nginx-ingress/lab1 → lab2          (NGINX IC behind CIS; reuses module 2 CIS)
module4-ingresslink/lab1 → lab2            (IngressLink; CRD-mode CIS)
```

**Only run one CIS controller at a time.** Each module's lab 1 deploys a CIS
controller configured for that module's mode (NodePort vs cluster/static vs CRD).
Before starting a new module, delete the previous module's CIS deployment. Each
lab README's cleanup section calls this out.

## Quick start (per-module scripts)

Every module has `apply-all.sh` / `cleanup-all.sh` that bring the module up to a
"ready + one demo running" state and tear it all down again. They handle the
"one CIS at a time" swap for you.

```bash
cd module1-nodeport   && bash apply-all.sh     # CIS (NodePort) + Ingress demo
# ...inspect on BIG-IP, then:
bash cleanup-all.sh

cd ../module2-clusterip && bash apply-all.sh   # CIS (ClusterIP/static) + Ingress demo
cd ../module3-nginx-ingress && bash apply-all.sh  # NGINX IC + CIS-published demo
cd ../module4-ingresslink   && bash apply-all.sh  # IngressLink (create the iRule first)
```

The set is **self-contained** — NGINX IC (v3.7.2, lab 3.1) and the cafe app
(lab 4.2) manifests are bundled, so nothing needs to be fetched at lab time except
container images (and, for module 4's `apply-all.sh`, the CIS CRD bundle — swap in
a pinned copy for fully offline use).

## Repository setup & Claude Code

This project is a Git repo. First time on a fresh clone, create your local
variables file (the real one is gitignored — it holds your BIG-IP password):

```bash
cp lab-vars.env.example lab-vars.env
$EDITOR lab-vars.env          # BIG-IP IP/creds, VIPs, image tag
./validate.sh                 # static checks (no cluster needed)
./preflight.sh                # environment gate (needs cluster + BIG-IP)
```

`CLAUDE.md` orients Claude Code on the architecture, conventions, and the
validate/test loop. `./validate.sh` is the pre-commit gate (also run in CI via
`.github/workflows/validate.yml`); it lints YAML, renders templates, and guards
against committed secrets and the `\&\&` heredoc bug.

To create the private GitHub repo and push (from the repo root):
```bash
git init -b main
git add .
git status                    # confirm lab-vars.env is NOT listed (gitignored)
git commit -m "Initial commit: F5 CIS Class 1 labs (modernized, verified)"
gh repo create jmack707/f5-cis-101 --private --source=. --remote=origin --push
# (or without gh:)
# git remote add origin git@github.com:jmack707/f5-cis-101.git && git push -u origin main
```

## Configuration & tooling (read this once)

Everything topology-specific lives in **`lab-vars.env`** at the repo root — BIG-IP
IP/creds, the **pinned** CIS image, the per-module VIPs, and the AS3 schema
version. Change it there and nowhere else.

Topology-bearing manifests are **templated** with `${VARS}`; they're rendered with
`envsubst` at apply time, so the YAML and the docs can't drift (this is what fixed
the old Module 1 VIP mismatch). Plain manifests with no topology values are applied
as-is.

Three entry points:

- **Per-module** `apply-all.sh` / `cleanup-all.sh` — bring a module up to
  "ready + one demo + verify" and tear it down. Idempotent (safe to re-run).
- **Per-lab driver** — from the repo root:
  ```bash
  ./lab.sh apply  module1-nodeport/lab2-ingress     # render + kubectl apply, in order
  ./lab.sh verify module1-nodeport/lab2-ingress     # run that lab's checks
  ./lab.sh delete module1-nodeport/lab2-ingress     # reverse-order teardown
  ./lab.sh render module1-nodeport/lab2-ingress     # preview rendered YAML, no apply
  ```
- **Manual** (any single file):
  ```bash
  set -a; source lab-vars.env; set +a
  envsubst < module1-nodeport/lab2-ingress/03-ingress-hello-world.yaml | kubectl apply -f -
  ```

### Verification

Every lab has a **`verify.sh`** that checks all three layers and prints
`PASS`/`FAIL`, exiting nonzero if anything is wrong (so it works as a self-check
*and* a CI gate). It asserts: the Kubernetes side (CIS pod Running, Service has
endpoints, IngressClass present), the **BIG-IP side over iControl REST** (the
expected virtual server exists in the right partition, pool members are active,
CIS static routes are present), and the **data path** (the VIP returns HTTP 200 and
load-balances across pods). `apply-all.sh` runs the relevant `verify.sh` for you.

Requirements on the runner (kube-master1): `kubectl`, `curl`, `python3`, and
`envsubst` (Ubuntu/Debian: `sudo apt-get install -y gettext-base` · RHEL/Rocky/Alma:
`sudo dnf install -y gettext`). The scripts run on both Ubuntu and RHEL/Rocky and
auto-detect the package manager when printing install hints.

## How the app labs are structured

Modules 1 and 2 reuse the same two app manifests (`*-deployment-hello-world.yaml`
and the service) across their Ingress lab and their ConfigMap/AS3 lab. Those files
are **intentionally duplicated into each lab folder** so every lab folder is
self-contained and copy-pasteable. They are byte-identical between labs in the same
module — edit both if you change one.

## What was modernized vs. the original labs

These apply across the set; per-lab READMEs note which touch each lab.

- **CIS controller hardening** — non-root (`runAsNonRoot`, uid/gid), `drop: [ALL]`
  capabilities, `seccompProfile: RuntimeDefault`, and `/health` liveness/readiness
  probes, matching the current `sample-k8s-bigip-ctlr.yaml`.
- **Credentials** — switched from env-var injection to `--credentials-directory`
  with a volume-mounted secret (`f5-bigip-ctlr-login`, now including `url`).
- **Module 2 networking** — **flannel VXLAN replaced with static routing mode**
  (`--static-routing-mode=true` + `--orchestration-cni=flannel`). No VXLAN
  tunnel/self-IP and no BIG-IP flannel node; CIS writes `k8s-<node>-<nodeip>`
  routes onto BIG-IP. Requires BIG-IP L3 reachability to node IPs (CIS 2.13.0+).
- **Module 3** — deprecated `kubernetes.io/ingress.class: "nginx"` annotation
  replaced with `spec.ingressClassName: nginx`; AS3 `schemaVersion` raised from
  3.10.0 (below the 3.18+ floor) to 3.50.0.
- **Module 4** — dropped the obsolete `--ingress-link-mode=true` flag (IngressLink
  is now part of CRD mode; only `--custom-resource-mode=true` is required), and
  switched to the unified CRD bundle for installation.
- **Reproducibility** — the CIS image is **pinned** in `lab-vars.env` (was
  `:latest`), and all topology values are centralized there and rendered into the
  manifests, so the class behaves identically on every run and is portable to any
  topology by editing one file.
- **AS3 schemaVersion** raised off the 3.18.0 floor to 3.50.0 throughout; set it to
  match the AS3 build actually installed on your BIG-IP.

## Verifying as you go

- CIS pod healthy: `kubectl get pods -n kube-system | grep k8s-bigip-ctlr`
- CIS logs: `kubectl logs <cis-pod> -n kube-system`
- BIG-IP objects: TMUI ▸ Local Traffic ▸ Virtual Servers / Pools — **select the
  right partition** (`kubernetes` for Ingress, `AS3` for ConfigMap/AS3 labs).
- Static routes (module 2+): `ssh admin@10.1.1.5 tmsh list net route | grep k8s-`

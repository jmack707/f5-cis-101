# CLAUDE.md — guide for Claude Code

F5 Container Ingress Services (CIS) on Kubernetes — a modernized, verified rebuild
of the Agility "Containers" Class 1 labs. This file orients Claude Code; read it
before making changes.

## What this repo is
Four modules, each split into labs, that deploy CIS against a BIG-IP and publish
apps via **Ingress** and **ConfigMap/AS3** (the patterns customers actually use —
not VirtualServer CRDs). Module 3 fronts apps with the NGINX Ingress Controller;
Module 4 is F5 IngressLink. Everything is driven by one variables file and a small
shell harness; manifests are templated so the same files run on any topology.

## Architecture (how it fits together)
- **`lab-vars.env`** — single source of truth (BIG-IP creds, pinned CIS image,
  per-module VIPs, AS3 schema). **Gitignored**; `lab-vars.env.example` is the
  committed template. Change topology here and nowhere else.
- **Templated manifests** — topology values appear as `${VARS}`; rendered with
  `envsubst` at apply time. This is what prevents YAML/doc drift.
- **`lib/labkit.sh`** — sourced by every script. Provides `kapply`/`kdelete`
  (envsubst-render + idempotent `kubectl apply`/`delete`), the verification
  assertions (k8s + BIG-IP iControl REST + data path), `pass/warn/fail/vsummary`,
  and `pkg_hint` (distro-aware install hints: apt→gettext-base, dnf→gettext).
- **`lab.sh`** — per-lab driver: `apply | delete | verify | render <labdir>`.
- **`preflight.sh`** — environment gate (tooling, cluster, BIG-IP license/LTM/AS3,
  node podCIDRs). Run before the labs.
- **`lab*/deploy.sh` / `cleanup.sh`** — student-facing per-lab entrypoints. `deploy.sh`
  renders + applies the lab's `NN-*.yaml` in order (via `lab_apply`/`kapply`) and waits
  until ready; `cleanup.sh` tears it down (`lab_delete`). Each `lab1/deploy.sh` also calls
  `remove_other_cis` first (only one CIS controller runs at a time). There is NO
  module-level `apply-all.sh` — labs are run in order, lab-by-lab.
- **`verify.sh`** in every lab — PASS/FAIL checks, nonzero exit on failure.

## Hard conventions (follow these)
1. **Never hardcode topology** (IPs, VIPs, image tags, partition) in a manifest.
   Add a variable to `lab-vars.env.example` (and your local `lab-vars.env`),
   reference it as `${VAR}`, and add it to the `LABKIT_SUBST` allowlist in
   `lib/labkit.sh`. Otherwise it won't be rendered.
2. **Apply templated files only via `kapply`/`lab.sh`/`deploy.sh`** — never raw
   `kubectl create -f` (it would send literal `${VAR}` to the cluster).
3. **Do NOT envsubst third-party manifests** that use `$(POD_NAMESPACE)` etc.
   (the NGINX IC set in `module3/lab1`). They're applied by `install-nginx-ic.sh`
   with plain `kubectl`; `lab.sh` delegates to that script automatically. The
   `LABKIT_SUBST` allowlist also protects them.
4. **Every lab folder** has: ordered `NN-*.yaml`, a `deploy.sh`, a `verify.sh`, a
   `cleanup.sh`, and a `README.md`. `deploy.sh`/`cleanup.sh` are thin wrappers over
   the `lab_apply`/`lab_delete` helpers in `lib/labkit.sh`.
5. **Scripts** start with `#!/usr/bin/env bash` and the root-locator block:
   ```bash
   HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
   source "$ROOT/lib/labkit.sh"
   ```
6. **One CIS controller at a time** — each module's lab1 runs CIS in a different
   mode (NodePort / cluster+static-routes / CRD). Delete the previous before the next.

## Validate / test
- **Static (no infra, run before every commit):** `./validate.sh`
  — bash -n all scripts, render+lint all YAML and embedded AS3 JSON, guard against
  the `\&\&` heredoc bug and committed passwords.
- **Against real infra:** `./preflight.sh`, then run a module's labs in order, e.g.
  `cd module1-nodeport/lab1-install-cis && bash deploy.sh && bash verify.sh`.
  Needs a BIG-IP (VE ok, AS3 3.18+, LTM) + a Kubernetes cluster. CI cannot do this.
- Requirements on the runner: `kubectl curl python3 envsubst` (+ `ssh` for BIG-IP
  setup). `pyyaml` for `validate.sh`. Runs on Ubuntu and RHEL/Rocky/Alma.

## Definition of done (new/changed lab)
- Topology values centralized in `lab-vars.env.example` + allowlist.
- `./validate.sh` passes.
- Lab folder has ordered manifests + `verify.sh` + `README.md`; module README and
  the master `README.md` updated if the lab list changed.
- the lab's `deploy.sh`/`cleanup.sh` still cover the files if any were added/removed
  (they iterate `NN-*.yaml` automatically; only special-cased steps need edits).

## Known pitfalls (already hit — don't reintroduce)
- **`\&\&` in heredocs:** when generating scripts via `cat <<EOF` with a variable
  holding the locator block, write `&&` literally — escaping it as `\&\&` produces
  a broken `cd ... \&\& pwd` that `bash -n` does NOT catch (`cd a b` is valid
  syntax). `validate.sh` step [2] guards this.
- **AS3 ConfigMap pool members need `"shareNodes": true`** (a boolean): when CIS
  injects discovered members into an AS3-ConfigMap pool, it sets `shareNodes` on the
  member, and if the template doesn't declare it as a boolean the BIG-IP rejects the
  whole declaration with `422 … /web_pool/members/0/shareNodes: should be boolean`
  (no VS/pool created). Every AS3-ConfigMap member block must include it.
- **AS3 `schemaVersion`** must be `<=` the AS3 build on the BIG-IP; the lab default
  3.50.0 is in `lab-vars.env`. Module 3's original lab used 3.10.0 (below the 3.18
  floor) — fixed.
- **Module 4 needs NGINX *Plus*** IC (not the OSS IC from Module 3) and the CIS CRD
  bundle (fetched from GitHub unless mirrored).
- **Air-gapped:** mirror `CIS_IMAGE`, `nginx/nginx-ingress:3.7.2`, and
  `nginxdemos/hello` (the demo/cafe app across Modules 1–4); localize the CIS
  CRD bundle.

## Layout
```
lab-vars.env(.example)  lab.sh  preflight.sh  validate.sh  lib/labkit.sh
module{1..4}-*/         README + lab*/ (NN-*.yaml, deploy.sh, verify.sh, cleanup.sh, README)
PREREQUISITES.md        README.md (master guide)
```
See `PREREQUISITES.md` for environment requirements and per-network adaptation.

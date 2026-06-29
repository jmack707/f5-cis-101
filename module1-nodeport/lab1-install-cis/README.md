# Lab 1.1 — Install & Configure CIS (NodePort)

Brings up the CIS controller in NodePort mode and the BIG-IP/Kubernetes objects it
needs (partition, service account, RBAC, credentials secret).

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-setup.sh` | ServiceAccount, ClusterRoleBinding, BIG-IP credentials secret (+ optional trusted-certs) |
| `02-nodeport-deployment.yaml` | CIS controller, NodePort mode (hardened) |

## Anatomy — what makes CIS work, and why
CIS (`02-nodeport-deployment.yaml`) is just a pod that **watches the Kubernetes API
and programs the BIG-IP**. It creates nothing until you give it an Ingress (1.2) or
an AS3 ConfigMap (1.3) to act on. The fields that matter:

| Field | Why it matters |
|-------|----------------|
| `serviceAccountName: k8s-bigip-ctlr` (+ the ClusterRoleBinding from `01-setup.sh`) | RBAC so CIS can **watch** Services, Endpoints, Ingresses and ConfigMaps. No permission → CIS sees nothing to publish. |
| `--credentials-directory=/tmp/creds` (the volume-mounted `f5-bigip-ctlr-login` secret) | How CIS authenticates to the BIG-IP over **iControl REST** (username / password / url). This is the CIS→BIG-IP control channel. |
| `--bigip-partition=${BIGIP_PARTITION}` | The BIG-IP partition CIS **owns** — it freely adds/removes objects there, so keep it dedicated. |
| `--pool-member-type=nodeport` | **The mode decision.** Pool members become `<nodeIP>:<nodePort>`, so the BIG-IP only needs to reach node IPs — no pod-network routing. (Module 2 uses `cluster` = pod IPs.) |
| `--custom-resource-mode=false` | CIS processes **Ingress + AS3 ConfigMaps** (labs 1.2 / 1.3), *not* VirtualServer CRDs. Set `true` only for CRD / IngressLink (Module 4). |
| `--as3-validation=true` / `--log-as3-response=true` | CIS validates the AS3 it builds and logs the BIG-IP's response — your first stop when a VS doesn't appear (`kubectl logs deploy/k8s-bigip-ctlr-deployment -n kube-system`). |
| `--insecure=true` | Skip BIG-IP cert validation — **lab only**; production uses a trusted-certs ConfigMap. |
| `replicas: 1` | Only **one** CIS may manage a partition; multiple controllers fight over it. |

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

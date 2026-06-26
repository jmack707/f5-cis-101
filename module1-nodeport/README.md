# Module 1 — CIS Using NodePort Mode

CIS deployed in **NodePort** mode: BIG-IP pool members are `<nodeIP>:<nodePort>`,
so no overlay networking or BIG-IP-side routing is required. The simplest way to
get started.

## Labs
| Lab | Folder | What it does |
|-----|--------|--------------|
| 1.1 | `lab1-install-cis/` | Install + configure the CIS controller (NodePort) |
| 1.2 | `lab2-ingress/` | Publish f5-hello-world via a Kubernetes **Ingress** |
| 1.3 | `lab3-configmap-as3/` | Publish the same app via a **ConfigMap/AS3** declaration |

## Prerequisites
- BIG-IP licensed, AS3 3.18+ installed.
- `kubernetes` partition (lab 1.1 creates it; idempotent).

## Order
Run lab 1.1 first (it brings up CIS). Then lab 1.2 and lab 1.3 are independent —
each deploys the app, verifies on BIG-IP, then cleans up. Lab 1.3 removes the CIS
controller at the end if you're done with NodePort mode; leave it running only if
you have a reason to.

> Source: https://clouddocs.f5.com/training/community/containers/html/class1/module1/module1.html

## Common errors
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| CIS pod `CrashLoopBackOff`, log `authentication failed` | wrong BIG-IP creds in the secret | fix `BIGIP_PASS` in `lab-vars.env`, re-run `lab1-install-cis/01-setup.sh`, restart the pod |
| Log: `partition kubernetes does not exist` | partition not created on BIG-IP | `ssh admin@<bigip> tmsh create auth partition kubernetes` |
| Log: `Unauthorized` / RBAC denied | service account / clusterrolebinding missing | re-run `lab1-install-cis/01-setup.sh` |
| No VS appears on BIG-IP | wrong partition in TMUI view, or Ingress not processed | check the **kubernetes** partition; confirm `--custom-resource-mode=false`; `kubectl logs` the CIS pod |
| `verify.sh` data-path FAIL but VS exists | NodePort not reachable from BIG-IP, or app not ready | `kubectl get pods -o wide`; check node firewall/security groups for the NodePort range |

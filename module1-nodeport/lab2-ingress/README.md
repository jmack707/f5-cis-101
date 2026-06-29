# Lab 1.2 — Deploy Hello-World via Ingress (NodePort)

Publishes the hello-world app (`nginxdemos/nginx-hello`, which echoes its pod name so
you can watch load balancing) to BIG-IP using a Kubernetes **Ingress** with
`virtual-server.f5.com/*` annotations. Requires the CIS controller from lab 1.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app (2 replicas) |
| `02-nodeport-service-hello-world.yaml` | NodePort service |
| `03-ingress-hello-world.yaml` | Ingress (legacy `virtual-server.f5.com` annotations) |

## Deploy
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks (Kubernetes + BIG-IP + data path)
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **kubernetes** partition: a virtual server on the Ingress
VIP and a pool whose members are `<nodeIP>:<nodePort>`. Browse the VIP from a host
on the lab network and refresh to watch load balancing.

## Notes
- VIP: the manifest uses `virtual-server.f5.com/ip: 10.1.10.101`; the original lab
  narrative references `10.1.1.4`. Set it to a free VIP that matches your topology.
- Ingress is legacy-but-supported in current CIS (requires
  `--custom-resource-mode=false`, which lab 1.1 sets). The `cis.f5.com/as3-*`
  labels on the service are inert here (carried over for lab 1.3).

## Cleanup (do not skip)
```bash
bash cleanup.sh
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

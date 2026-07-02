# Lab 1.2 — Deploy Hello-World via Ingress (NodePort)

Publishes the hello-world app (`nginxdemos/nginx-hello`, which echoes its pod name so
you can watch load balancing) to BIG-IP using a Kubernetes **Ingress** with
`virtual-server.f5.com/*` annotations. Requires the CIS controller from lab 1.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `00-ingressclass-f5.yaml` | `f5` IngressClass (controller `f5.com/cntr-ingress-svcs`) — CIS's claim ticket |
| `01-deployment-hello-world.yaml` | the app (2 replicas) |
| `02-nodeport-service-hello-world.yaml` | NodePort service |
| `03-ingress-hello-world.yaml` | Ingress (legacy `virtual-server.f5.com` annotations, `ingressClassName: f5`) |

## Anatomy — how an Ingress becomes a BIG-IP virtual server
CIS watches Ingress objects and turns the `virtual-server.f5.com/*` annotations into
a BIG-IP virtual server + pool. **The annotations *are* the BIG-IP config:**

| Annotation / field | What CIS does with it |
|--------------------|-----------------------|
| `virtual-server.f5.com/ip` | The **VIP** — the address CIS creates the BIG-IP virtual server on. The single most important value. |
| `virtual-server.f5.com/partition` | Which BIG-IP partition to build it in (matches `--bigip-partition`). |
| `virtual-server.f5.com/http-port: "80"` | The **listener port** of the virtual server. |
| `virtual-server.f5.com/balance: round-robin` | The BIG-IP load-balancing method for the pool. |
| `virtual-server.f5.com/health` | The BIG-IP **health monitor** CIS attaches to the pool (send / interval / timeout) — what marks members up or down. |
| `spec.rules…backend.service.name` | The **Service whose endpoints become the pool members.** This is the link from the Ingress to your app. |
| `…service.port.number: 80` | The Service `port` (80) to target — *not* the pod port. In NodePort mode CIS resolves it to each node's `nodePort`. |

**Flow:** Ingress annotations → CIS builds the VS at the VIP → pool members =
the backend Service's `node:nodePort` → BIG-IP health-monitors them. Browse the VIP
and refresh — the `nginxdemos/nginx-hello` page shows a different pod name as the
BIG-IP rotates across backends.

> **IngressClass (required):** CIS 2.x only builds a virtual server for an Ingress that
> references the `f5` IngressClass. `00-ingressclass-f5.yaml` creates that cluster-scoped
> resource and `03-ingress-hello-world.yaml` sets `spec.ingressClassName: f5`. Without it
> CIS logs `[CORE] Ingress class resource not found` on every reconcile and programs
> nothing on the BIG-IP (no VS, no pools) — even though the Ingress and endpoints exist.
> The `f5` IngressClass is cluster-scoped and shared, so it is safe to leave in place
> across modules; it is deliberately **not** the cluster default, so Module 3's `nginx`
> IngressClass keeps its own Ingresses.

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

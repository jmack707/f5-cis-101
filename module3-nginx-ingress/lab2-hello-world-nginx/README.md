# Lab 3.2 — Hello-World behind NGINX IC, published by CIS

The app sits behind the NGINX Ingress Controller (L7, host-based routing); CIS
publishes a BIG-IP VS whose pool members are the NGINX IC pods.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app |
| `02-clusterip-service-hello-world.yaml` | backend service for NGINX |
| `03-nginx-ingress-hello-world.yaml` | Ingress for **NGINX** (`ingressClassName: nginx`) |
| `04-cis-service.yaml` | service CIS watches (namespace `nginx-ingress`) |
| `05-cis-configmap.yaml` | AS3 decl → BIG-IP VS targeting NGINX pods |

## Anatomy — two controllers, two jobs, one request
Five manifests, but they split cleanly between the two tiers. The trick is noticing which
controller reads which file — they **never read the same one**:

| File | Who reads it | What it does |
|------|--------------|--------------|
| `03-nginx-ingress-hello-world.yaml` (`ingressClassName: nginx`, host `mysite.f5demo.com`) | **NGINX IC** | The L7 rule: "for host `mysite.f5demo.com`, route to the `f5-hello-world-web` service." CIS ignores this — it's claimed by the `nginx` IngressClass. |
| `02-clusterip-service-hello-world.yaml` | **NGINX IC** | The backend NGINX routes *to* — the actual app pods. |
| `04-cis-service.yaml` (`namespace: nginx-ingress`, `selector: app: nginx-ingress`, `cis.f5.com/as3-*` labels) | **CIS** | The pivot. It selects the **NGINX IC pods** (not the app) and its `as3-*` labels tell CIS to inject those pod endpoints into `web_pool`. This is how the BIG-IP pool ends up pointing at NGINX. |
| `05-cis-configmap.yaml` (AS3 declaration) | **CIS** | Builds the BIG-IP VS `hello_world_nginx_vs` at the front VIP with `web_pool` — the same AS3 ConfigMap pattern as lab 1.3, but the discovered members are NGINX pods. |
| `01-deployment-hello-world.yaml` | (the app) | The pods NGINX ultimately forwards to. |

**Two key joins to see:**
- `04-cis-service.yaml`'s `selector: app: nginx-ingress` → it watches **NGINX**, so
  `web_pool` members are NGINX pod IPs. (Contrast lab 1.3, where the service selected the
  app directly.)
- The service's `as3-*` labels (`tenant`/`app`/`pool: web_pool`) must match the names in
  `05-cis-configmap.yaml`, exactly as in lab 1.3 — that's the wiring that puts the
  discovered endpoints into the right pool.

**Flow:** request → **BIG-IP VS** (built by `05`, members = NGINX pods via `04`) →
**NGINX IC pod** → matches the host rule in `03` → **app pod** in `02`. Because NGINX
routes on the **Host header**, you test with one:
```bash
curl -H 'Host: mysite.f5demo.com' http://10.1.10.101/
```

## Deploy
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks
```

## Verify
TMUI ▸ Local Traffic ▸ **AS3** partition: a `hello_world_nginx_vs` VS with `web_pool`
members = the NGINX IC pod IP(s). Test with the Host header (NGINX routes on host, not IP):
```bash
curl -H 'Host: mysite.f5demo.com' http://10.1.10.101/
```

## What changed vs the lab
- `kubernetes.io/ingress.class: "nginx"` annotation → `spec.ingressClassName: nginx`.
- AS3 `schemaVersion` 3.10.0 → 3.50.0 (3.10.0 was below the 3.18+ minimum).
- Service/ConfigMap namespace match and `servicePort` = service `port` retained
  (required since CIS v2.1 / v2.2.2).

## Cleanup
```bash
bash cleanup.sh    # removes the demo; leaves the NGINX IC and CIS running
```

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

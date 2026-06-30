# Lab 1.3 — Deploy Hello-World via ConfigMap/AS3 (NodePort)

Same app as lab 1.2, but published through an **AS3 ConfigMap** instead of an
Ingress. CIS reads the `cis.f5.com/as3-*` service labels to populate `web_pool`.
Requires the CIS controller from lab 1.1.

## Files (apply in order)
| File | Purpose |
|------|---------|
| `01-deployment-hello-world.yaml` | the app (same as lab 1.2) |
| `02-nodeport-service-hello-world.yaml` | NodePort service with AS3 discovery labels |
| `03-configmap-hello-world.yaml` | AS3 declaration (Service_HTTP + web_pool) |

## Anatomy — the AS3 ConfigMap + label-based discovery
This lab reaches the **same** BIG-IP VS+pool as 1.2, but instead of annotations you
author the BIG-IP config explicitly as an **AS3 declaration** and let CIS fill in the
live pool members. Two pieces work together:

**1. The Service labels** (`02-…service…yaml`) tell CIS *where* to inject endpoints:

| Label | Meaning |
|-------|---------|
| `cis.f5.com/as3-tenant: ${AS3_TENANT}` | inject into this **Tenant** (= the BIG-IP partition) |
| `cis.f5.com/as3-app: A1` | …this **Application** |
| `cis.f5.com/as3-pool: web_pool` | …this **Pool** — must match the pool name in the declaration |

**2. The ConfigMap** (`03-configmap…yaml`) is the AS3 declaration itself. The labels
`f5type: virtual-server` + `as3: "true"` flag it as "an AS3 declaration to post." It
nests **Tenant → Application → (virtual server + pool)**, and each level maps to a
BIG-IP object. Here's the declaration, abbreviated (the `//` notes are added for
clarity — real AS3 JSON has no comments):

```jsonc
{
  "class": "AS3",
  "declaration": {
    "class": "ADC",
    "schemaVersion": "3.50.0",            // must be <= your BIG-IP's AS3 build
    "${AS3_TENANT}": {                    // Tenant  ->  a BIG-IP PARTITION (the key is the name)
      "class": "Tenant",
      "A1": {                             // Application — a folder for the objects below
        "class": "Application",
        "template": "generic",            // 'generic' lets you name the virtual server anything
        "hello_world_vs": {               // ->  the BIG-IP VIRTUAL SERVER
          "class": "Service_HTTP",
          "virtualAddresses": ["<VIP>"],  // the address it listens on
          "virtualPort": 80,
          "pool": "web_pool"              // which pool to load-balance to
        },
        "web_pool": {                     // ->  the BIG-IP POOL
          "class": "Pool",
          "monitors": ["http"],           // health monitor
          "members": [
            { "servicePort": 80, "shareNodes": true, "serverAddresses": [] }
          ]
        }
      }
    }
  }
}
```

- `serverAddresses: []` is **empty on purpose** — CIS fills it from the labeled
  Service's discovered endpoints (that's the "discovery" part).
- `shareNodes: true` is **required** (a boolean); without it the BIG-IP rejects the
  whole declaration with `422 … shareNodes: should be boolean`.
- The Tenant name becomes a BIG-IP **partition** — keep it distinct from
  `BIGIP_PARTITION` (the one CIS itself manages for Ingress).

**Flow:** static declaration (ConfigMap) + live endpoints (Service labels) → CIS
merges them and posts AS3 → BIG-IP creates the partition / VS / pool. Scale the
Deployment and watch the pool members track the pods.

**Ingress (1.2) vs ConfigMap/AS3 (1.3):** same outcome, different control surface.
Ingress = a few annotations and CIS authors the AS3 for you; ConfigMap/AS3 = you write
the full declaration (more direct control of the BIG-IP objects) and CIS only fills in
the members.

## Deploy
> Publishes the same VIP as lab 1.2 (a different way), so run
> `bash ../lab2-ingress/cleanup.sh` first if lab 1.2 is still up.
```bash
bash deploy.sh     # renders + applies the manifests above, in order, then waits until ready
bash verify.sh     # PASS/FAIL checks
```

## Verify on BIG-IP
TMUI ▸ Local Traffic ▸ **AS3** partition (auto-created, named after the tenant):
a `hello_world_vs` virtual server on 10.1.1.4:80 and a `web_pool`. Scale the app
(`kubectl scale --replicas=10 deployment/f5-hello-world-web`) and watch members
update.

## Notes
- `schemaVersion` is set to `3.50.0` (up from the lab's 3.18.0 floor). Set it `<=`
  the AS3 build installed on your BIG-IP.
- AS3 v2.20+ removes the old need for a "blank declaration" to tear down — deleting
  the ConfigMap removes the objects.

## Cleanup
```bash
bash cleanup.sh
```
Verify the AS3 partition is gone on BIG-IP (can take ~30s). If you're done with
NodePort mode, remove CIS too: `bash ../lab1-install-cis/cleanup.sh`

---
**Verify this lab:** `./lab.sh verify <this-lab-dir>` (from repo root) or
`bash verify.sh` here. Manifests are templated from `lab-vars.env` — apply with
`bash deploy.sh` here (it renders the templates), not raw `kubectl create`. Tear down with `bash cleanup.sh`.

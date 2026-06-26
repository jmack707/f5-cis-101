#!/usr/bin/env bash
# ============================================================================
# preflight.sh — checks your environment BEFORE you start the labs.
# Reads lab-vars.env, probes tooling, the Kubernetes cluster, and the BIG-IP,
# then prints a per-module readiness summary. Exits nonzero if a hard
# requirement (FAIL) is missing; WARN means "fine for some modules".
#
#   ./preflight.sh
# ============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/labkit.sh"

# ---------------------------------------------------------------------------
echo "============================================================"
echo " F5 CIS Class 1 — Preflight"
echo " BIG-IP=$BIGIP_MGMT  partition=$BIGIP_PARTITION  image=$CIS_IMAGE"
echo "============================================================"

# ---- 1. Tooling -----------------------------------------------------------
echo "[1] Tooling"
for t in kubectl curl python3; do
  command -v "$t" >/dev/null 2>&1 && pass "$t present" || fail "$t missing — $(pkg_hint "$t")"
done
command -v envsubst >/dev/null 2>&1 && pass "envsubst present" \
  || fail "envsubst missing — $(pkg_hint envsubst)"
command -v ssh >/dev/null 2>&1 && pass "ssh present" \
  || warn "ssh missing — BIG-IP setup scripts (partition/VXLAN) won't run; do those steps manually"

# ---- 2. Kubernetes --------------------------------------------------------
echo "[2] Kubernetes cluster"
if kubectl version >/dev/null 2>&1 && kubectl get nodes >/dev/null 2>&1; then
  ready=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 ~ /(^|,)Ready/ {n++} END{print n+0}')
  total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  [ "$ready" -ge 1 ] && pass "cluster reachable — $ready/$total node(s) Ready" \
                     || fail "cluster reachable but no Ready nodes"
  # Pod CIDRs (needed for Module 2 static routing)
  nocidr=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.podCIDR}{"\n"}{end}' 2>/dev/null | awk 'NF<2{n++} END{print n+0}')
  if [ "$nocidr" -eq 0 ]; then pass "all nodes have spec.podCIDR (Module 2 static routes OK)"
  else warn "$nocidr node(s) lack spec.podCIDR — Module 2 static routes need --allocate-node-cidrs=true"; fi
  # CNI sanity: any non-running kube-system networking pods?
  command -v kubectl >/dev/null && kubectl get pods -A >/dev/null 2>&1 && pass "able to list pods (RBAC OK)" \
    || warn "could not list pods across namespaces — check your kubeconfig/RBAC"
else
  fail "cannot reach a Kubernetes cluster (check kubeconfig / current-context)"
fi

# ---- 3. BIG-IP ------------------------------------------------------------
echo "[3] BIG-IP ($BIGIP_MGMT)"
if bigip_rest "tm/sys/version" | grep -q '"kind"'; then
  pass "iControl REST reachable + credentials accepted"

  # licensed / provisioned / config ready
  ready_json="$(bigip_rest 'tm/sys/ready')"
  for k in licenseReady provisionReady configReady; do
    v=$(printf '%s' "$ready_json" | python3 -c "import sys,json;print(json.load(sys.stdin).get('entries',{}).get('https://localhost/mgmt/tm/sys/ready/0',{}).get('nestedStats',{}).get('entries',{}).get('$k',{}).get('description',''))" 2>/dev/null)
    [ "$v" = "yes" ] && pass "$k = yes" || warn "$k = '${v:-unknown}' (BIG-IP may not be fully licensed/provisioned)"
  done

  # LTM provisioned?
  ltm=$(bigip_get "sys/provision" | python3 -c "import sys,json;print(next((i.get('level','none') for i in json.load(sys.stdin).get('items',[]) if i.get('name')=='ltm'),'none'))" 2>/dev/null)
  [ -n "$ltm" ] && [ "$ltm" != "none" ] && pass "LTM provisioned (level: $ltm)" || fail "LTM not provisioned — CIS requires LTM"

  # AS3 installed + version >= 3.18
  as3=$(bigip_rest "shared/appsvcs/info" | python3 -c "import sys,json;print(json.load(sys.stdin).get('version',''))" 2>/dev/null)
  if [ -z "$as3" ]; then
    fail "AS3 not responding — install AS3 RPM 3.18+ (iApps > Package Management LX)"
  else
    ok=$(python3 -c "v='$as3'.split('.');import sys;sys.exit(0 if (int(v[0]),int(v[1]))>=(3,18) else 1)" 2>/dev/null && echo yes || echo no)
    [ "$ok" = yes ] && pass "AS3 $as3 (>= 3.18)" || fail "AS3 $as3 is below the 3.18 minimum — upgrade AS3"
    # schemaVersion sanity vs lab-vars.env
    sv_ok=$(python3 -c "a='$as3'.split('.');s='$AS3_SCHEMA_VERSION'.split('.');import sys;sys.exit(0 if (int(s[0]),int(s[1]),int(s[2]))<=(int(a[0]),int(a[1]),int(a[2])) else 1)" 2>/dev/null && echo yes || echo no)
    [ "$sv_ok" = yes ] && pass "AS3_SCHEMA_VERSION ($AS3_SCHEMA_VERSION) <= installed AS3" \
      || warn "AS3_SCHEMA_VERSION ($AS3_SCHEMA_VERSION) > installed AS3 ($as3) — lower it in lab-vars.env"
  fi

  # partition
  has_part=$(bigip_get "auth/partition" | python3 -c "import sys,json;print('yes' if any(i.get('name')=='$BIGIP_PARTITION' for i in json.load(sys.stdin).get('items',[])) else 'no')" 2>/dev/null)
  [ "$has_part" = yes ] && pass "partition '$BIGIP_PARTITION' exists" \
    || warn "partition '$BIGIP_PARTITION' missing — apply-all.sh / setup scripts will create it"
else
  fail "BIG-IP iControl REST not reachable at $BIGIP_MGMT — check BIGIP_MGMT/BIGIP_USER/BIGIP_PASS in lab-vars.env and L3 connectivity"
fi

# ---- 4. VIP reachability (informational) ----------------------------------
echo "[4] Virtual server addresses (from lab-vars.env)"
info "Module 1 NodePort VIP    : $NODEPORT_VIP"
info "Module 2 ClusterIP VIP   : $CLUSTER_VIP"
info "Module 3 NGINX-front VIP : $NGINX_FRONT_VIP"
info "Module 4 IngressLink VIP : $INGRESSLINK_VIP"
info "These must be free addresses your clients can route to. They won't answer"
info "until a lab creates the VS — preflight does not test them live."

# ---- 5. Per-module readiness ----------------------------------------------
echo "[5] Per-module notes"
info "Modules 1 & 3 : need BIG-IP + cluster + (M3) reachable NodePorts. Lowest bar."
info "Module 2      : additionally needs BIG-IP L3 reachability to NODE IPs and node podCIDRs."
info "Module 4      : requires NGINX *Plus* Ingress Controller (not the OSS IC from M3)"
info "                and internet (or a pinned local copy) for the CIS CRD bundle."
info "Air-gapped    : mirror the CIS image ($CIS_IMAGE) and nginx/nginx-ingress into a local registry."

echo
vsummary
rc=$?
echo
[ $rc -eq 0 ] && echo "Preflight OK — no blocking failures. WARNs above are per-module, not fatal." \
             || echo "Preflight found blocking FAIL(s) above — resolve them before starting."
exit $rc

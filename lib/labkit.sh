#!/usr/bin/env bash
# ============================================================================
# lib/labkit.sh — sourced by every script.
#  - loads lab-vars.env
#  - kapply/kdelete: idempotent, envsubst-rendered kubectl
#  - verification helpers (kubernetes side + BIG-IP iControl REST + data path)
# Source it: source "$(...)/lib/labkit.sh"   (scripts use the locator below)
# ============================================================================

# Resolve repo root from this file's location (lib/ is directly under root).
_LABKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(dirname "$_LABKIT_DIR")"

# Load variables
if [ -f "$LAB_ROOT/lab-vars.env" ]; then
  set -a; . "$LAB_ROOT/lab-vars.env"; set +a
else
  echo "FATAL: lab-vars.env not found at $LAB_ROOT" >&2
  echo "       Create it from the template:  cp lab-vars.env.example lab-vars.env" >&2
  echo "       then edit it for your network (BIG-IP IP/creds, VIPs)." >&2
  exit 1
fi

# Backward-compatible default: the AS3 tenant name (= the BIG-IP partition the AS3
# labs create). lab-vars.env files that predate this var fall back to AS3.
: "${AS3_TENANT:=AS3}"; export AS3_TENANT

# The envsubst allowlist (LABKIT_SUBST) lives in one place, shared with validate.sh.
source "$_LABKIT_DIR/labkit-subst.sh"

# ---- colored status + counters -------------------------------------------
_GRN=$'\033[32m'; _RED=$'\033[31m'; _YEL=$'\033[33m'; _RST=$'\033[0m'
PASS_N=0; FAIL_N=0; WARN_N=0
pass() { PASS_N=$((PASS_N+1)); echo "  ${_GRN}PASS${_RST}  $*"; }
fail() { FAIL_N=$((FAIL_N+1)); echo "  ${_RED}FAIL${_RST}  $*"; }
warn() { WARN_N=$((WARN_N+1)); echo "  ${_YEL}WARN${_RST}  $*"; }
info() { echo "  ${_YEL}··${_RST}    $*"; }
vsummary() {
  echo "----------------------------------------"
  echo "  ${PASS_N} passed, ${WARN_N} warning(s), ${FAIL_N} failed"
  [ "$FAIL_N" -eq 0 ] || return 1
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1 ($(pkg_hint "$1"))" >&2; exit 1; }; }

# Distro-aware install hint. Maps a binary to the right package + manager for the
# runner's OS (Ubuntu/Debian, RHEL/Rocky/Alma, Fedora, SUSE).
pkg_hint() {  # binary
  local bin="$1" mgr pkg
  if   command -v apt-get >/dev/null 2>&1; then mgr="sudo apt-get install -y"
  elif command -v dnf     >/dev/null 2>&1; then mgr="sudo dnf install -y"
  elif command -v yum     >/dev/null 2>&1; then mgr="sudo yum install -y"
  elif command -v zypper  >/dev/null 2>&1; then mgr="sudo zypper install -y"
  else mgr="install"; fi
  case "$bin" in
    envsubst)
      # binary is shipped by gettext-base on Debian/Ubuntu, gettext elsewhere
      if command -v apt-get >/dev/null 2>&1; then pkg="gettext-base"; else pkg="gettext"; fi ;;
    python3) pkg="python3" ;;
    *)       pkg="$bin" ;;
  esac
  echo "$mgr $pkg"
}

# ---- render + apply -------------------------------------------------------
# kapply FILE  — envsubst (allowlisted) then kubectl apply (idempotent)
kapply()  { need envsubst; envsubst "$LABKIT_SUBST" < "$1" | kubectl apply -f - ; }
kdelete() { envsubst "$LABKIT_SUBST" < "$1" | kubectl delete --ignore-not-found=true -f - ; }

# ---- per-lab deploy / cleanup (student-facing) ----------------------------
# Each lab folder has a thin deploy.sh / cleanup.sh that call these. They render
# and apply the folder's ordered NN-*.yaml; third-party NGINX IC manifests (which
# carry $(POD_*) tokens that must NOT be envsubst'd) are delegated to the lab's
# install-nginx-ic.sh, exactly as lab.sh does.
step()  { echo "  ${_GRN}▸${_RST} $*"; }       # narrate a deploy/cleanup step
lab_apply() {   # dir — render + apply NN-*.yaml in order
  local dir="$1" f
  if [ -x "$dir/install-nginx-ic.sh" ]; then bash "$dir/install-nginx-ic.sh"; return; fi
  while IFS= read -r f; do step "apply  ${f##*/}"; kapply "$f"; done \
    < <(find "$dir" -maxdepth 1 -name '[0-9][0-9]-*.yaml' | sort)
}
lab_delete() {  # dir — delete NN-*.yaml in reverse order
  local dir="$1" files i
  mapfile -t files < <(find "$dir" -maxdepth 1 -name '[0-9][0-9]-*.yaml' | sort)
  # NGINX IC manifests are applied raw (no envsubst), so delete them raw too.
  if [ -f "$dir/install-nginx-ic.sh" ]; then
    for ((i=${#files[@]}-1;i>=0;i--)); do step "delete ${files[$i]##*/}"; kubectl delete --ignore-not-found -f "${files[$i]}"; done
    return
  fi
  for ((i=${#files[@]}-1;i>=0;i--)); do step "delete ${files[$i]##*/}"; kdelete "${files[$i]}"; done
}
# Each module runs CIS in a different mode — only one controller may run at a
# time. A module's lab1 calls this to remove any other module's CIS first.
remove_other_cis() {  # keep_deployment_name
  local keep="$1" d
  for d in k8s-bigip-ctlr-deployment k8s-bigip-ctlr; do
    [ "$d" = "$keep" ] && continue
    if kubectl -n "$CIS_NAMESPACE" get deploy "$d" >/dev/null 2>&1; then
      step "removing other CIS controller ($d) — one at a time"
      kubectl -n "$CIS_NAMESPACE" delete deploy "$d" --ignore-not-found >/dev/null 2>&1 || true
    fi
  done
}
# Create the CIS BIG-IP partition via iControl REST — uses the same creds as
# lab-vars.env, so no SSH and no interactive password prompt. Idempotent (409 =
# already exists). Replaces the old `ssh ... tmsh create auth partition`.
ensure_partition() {
  local code
  code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 12 \
    -u "${BIGIP_USER}:${BIGIP_PASS}" -H 'Content-Type: application/json' \
    -X POST "https://${BIGIP_MGMT}/mgmt/tm/auth/partition" \
    -d "{\"name\":\"${BIGIP_PARTITION}\"}" 2>/dev/null || true)
  case "$code" in
    200|201) step "BIG-IP partition '${BIGIP_PARTITION}' created (iControl REST)" ;;
    409)     step "BIG-IP partition '${BIGIP_PARTITION}' already exists" ;;
    *)       warn "partition create on ${BIGIP_MGMT} returned HTTP ${code:-000} (continuing)" ;;
  esac
}
# Create/update a BIG-IP iRule in /Common from a .tcl file via iControl REST — no
# TMUI step. Used by Module 4 (IngressLink references /Common/Proxy_Protocol_iRule).
ensure_irule() {  # name tcl_file
  python3 - "$1" "$2" "$BIGIP_MGMT" "$BIGIP_USER" "$BIGIP_PASS" <<'PY' || warn "iRule create failed (continuing)"
import sys, json, ssl, base64, urllib.request, urllib.error
name, path, mgmt, user, pw = sys.argv[1:6]
body = open(path).read()
ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
auth = base64.b64encode(f"{user}:{pw}".encode()).decode()
def call(method, url, payload):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), method=method,
        headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=15) as r: return r.status
    except urllib.error.HTTPError as e: return e.code
st = call("POST", f"https://{mgmt}/mgmt/tm/ltm/rule", {"name": name, "apiAnonymous": body})
if st in (200, 201):
    print(f"  \033[32m▸\033[0m iRule '{name}' created (iControl REST)")
elif st == 409:
    st2 = call("PUT", f"https://{mgmt}/mgmt/tm/ltm/rule/{name}", {"apiAnonymous": body})
    print(f"  \033[32m▸\033[0m iRule '{name}' " + ("updated" if st2 in (200,201) else f"exists (update HTTP {st2})"))
else:
    print(f"  \033[33m··\033[0m iRule '{name}' create returned HTTP {st}")
PY
}

# ---- kubernetes-side assertions ------------------------------------------
assert_pod_running() {   # ns label
  local ns="$1" label="$2" n
  n=$(kubectl get pods -n "$ns" -l "$label" --field-selector=status.phase=Running -o name 2>/dev/null | wc -l)
  [ "$n" -ge 1 ] && pass "pod running ($ns $label)" || fail "no Running pod ($ns $label)"
}
assert_svc_endpoints() { # ns svc
  local ns="$1" svc="$2" eps
  eps=$(kubectl get endpoints "$svc" -n "$ns" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
  [ "$eps" -ge 1 ] && pass "service has $eps endpoint(s) ($ns/$svc)" || fail "service has no endpoints ($ns/$svc)"
}
assert_ingressclass() {  # name
  kubectl get ingressclass "$1" >/dev/null 2>&1 && pass "IngressClass '$1' exists" || fail "IngressClass '$1' missing"
}
assert_cis_logs_clean() { # ns
  local ns="${1:-$CIS_NAMESPACE}" pod errs
  pod=$(kubectl get pods -n "$ns" -l app -o name 2>/dev/null | grep -i bigip | head -1)
  [ -z "$pod" ] && pod=$(kubectl get pods -n "$ns" -o name | grep -i bigip | head -1)
  if [ -z "$pod" ]; then fail "CIS pod not found in $ns"; return; fi
  errs=$(kubectl logs "$pod" -n "$ns" --tail=200 2>/dev/null | grep -iE 'authentication failed|unauthorized|connection refused|x509|error creating' | wc -l)
  [ "$errs" -eq 0 ] && pass "CIS logs show no auth/connect errors" || fail "CIS logs show $errs error line(s) — check 'kubectl logs $pod -n $ns'"
}

# ---- BIG-IP iControl REST -------------------------------------------------
bigip_rest() { curl -sk --max-time 12 -u "${BIGIP_USER}:${BIGIP_PASS}" "https://${BIGIP_MGMT}/mgmt/${1}"; }
bigip_get()  { bigip_rest "tm/${1}"; }

assert_bigip_reachable() {
  bigip_get "sys/version" | grep -q '"kind"' && pass "BIG-IP REST reachable ($BIGIP_MGMT)" \
    || fail "BIG-IP REST not reachable at $BIGIP_MGMT (check creds/mgmt IP)"
}
assert_vs_with_vip() {   # vip partition
  local vip="$1" part="$2"
  bigip_get "ltm/virtual" | python3 -c "
import sys,json
d=json.load(sys.stdin); items=d.get('items',[])
hit=[i for i in items if i.get('partition')=='$part' and '$vip:' in i.get('destination','')]
sys.exit(0 if hit else 1)" 2>/dev/null \
    && pass "virtual server on $vip found in /$part" \
    || fail "no virtual server on $vip in partition /$part"
}
assert_pool_members_up() {  # partition
  local part="$1" total=0 fp enc up names
  names=$(bigip_get "ltm/pool" | python3 -c "
import sys,json
for i in json.load(sys.stdin).get('items',[]):
    if i.get('partition')=='$part': print(i['fullPath'])" 2>/dev/null)
  if [ -z "$names" ]; then fail "no pools in /$part"; return; fi
  while IFS= read -r fp; do
    [ -z "$fp" ] && continue
    enc=$(printf '%s' "$fp" | sed 's#/#~#g')
    up=$(bigip_get "ltm/pool/${enc}/members" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(sum(1 for m in d.get('items',[]) if m.get('state')!='down'))" 2>/dev/null || echo 0)
    total=$((total+up))
  done <<< "$names"
  [ "$total" -gt 0 ] && pass "$total pool member(s) active in /$part" || fail "no active pool members in /$part"
}
assert_static_routes() {  # expect CIS-written routes named k8s-*
  local n
  n=$(bigip_get "net/route" | python3 -c "
import sys,json
print(sum(1 for i in json.load(sys.stdin).get('items',[]) if i.get('name','').startswith('k8s-')))" 2>/dev/null || echo 0)
  [ "$n" -ge 1 ] && pass "$n CIS static route(s) on BIG-IP" || fail "no k8s-* static routes on BIG-IP"
}

# ---- data path ------------------------------------------------------------
http_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$@"; }
assert_code() {  # expected URL [extra curl args...]
  local exp="$1" url="$2"; shift 2
  local got; got=$(http_code "$url" "$@")
  [ "$got" = "$exp" ] && pass "HTTP $got from $url" || fail "expected $exp, got $got from $url"
}
assert_lb_rotation() {  # url min_distinct [extra curl args...]
  local url="$1" min="${2:-2}"; shift 2 || true
  local seen
  # The demo apps (nginxdemos/hello and nginxdemos/nginx-hello) echo the serving
  # pod as "Server name: <pod>". Hit the VIP a dozen times and count distinct pods.
  seen=$(for _ in $(seq 1 12); do curl -s --max-time 5 "$url" "$@" 2>/dev/null; done \
         | grep -oiE 'Server name:[[:space:]]*[^<[:space:]]+' | sort -u | wc -l)
  [ "$seen" -ge "$min" ] && pass "load-balanced across $seen backends" \
    || fail "saw $seen distinct backend(s), expected >= $min"
}

# ---- settle: poll until app + BIG-IP config are programmed (pre-verify) ----
# CIS programs the BIG-IP a few seconds after the Service/Ingress exist, and k8s
# endpoints take a moment to populate. each lab's deploy.sh calls settle_ingress before
# verify so a fresh run doesn't report false failures while things converge.
_svc_has_endpoints() {  # ns svc  -> true once >=1 endpoint address exists
  local ips
  ips=$(kubectl -n "$1" get endpoints "$2" \
        -o jsonpath='{range .subsets[*].addresses[*]}{.ip}{" "}{end}' 2>/dev/null)
  [ -n "${ips// /}" ]
}
_vs_exists() {  # vip partition  -> true once CIS has programmed the VS
  bigip_get "ltm/virtual" | python3 -c "
import sys,json
d=json.load(sys.stdin); items=d.get('items',[])
sys.exit(0 if [i for i in items if i.get('partition')=='$2' and '$1:' in i.get('destination','')] else 1)" 2>/dev/null
}
_pool_members_active() {  # partition -> true once >=1 pool member is not 'down'
  local part="$1" names fp enc up total=0
  names=$(bigip_get "ltm/pool" | python3 -c "
import sys,json
for i in json.load(sys.stdin).get('items',[]):
    if i.get('partition')=='$part': print(i['fullPath'])" 2>/dev/null)
  [ -z "$names" ] && return 1
  while IFS= read -r fp; do
    [ -z "$fp" ] && continue
    enc=$(printf '%s' "$fp" | sed 's#/#~#g')
    up=$(bigip_get "ltm/pool/${enc}/members" | python3 -c "
import sys,json
print(sum(1 for m in json.load(sys.stdin).get('items',[]) if m.get('state')!='down'))" 2>/dev/null || echo 0)
    total=$((total+up))
  done <<< "$names"
  [ "$total" -ge 1 ]
}
# settle_ingress <ns> <svc> <vip> <partition> [timeout_secs]
# Waits (bounded) for the service endpoints AND the CIS-programmed VS, then returns.
# On timeout it returns nonzero but does NOT abort — verify still runs and reports.
settle_ingress() {
  local ns="$1" svc="$2" vip="$3" part="$4" timeout="${5:-90}" t0=$SECONDS
  printf '  %s··%s    settling: %s/%s endpoints + VS %s + pool members in /%s ' "$_YEL" "$_RST" "$ns" "$svc" "$vip" "$part"
  while :; do
    if _svc_has_endpoints "$ns" "$svc" && _vs_exists "$vip" "$part" && _pool_members_active "$part"; then echo "ready"; return 0; fi
    if [ $((SECONDS - t0)) -ge "$timeout" ]; then echo "timeout after ${timeout}s (verifying anyway)"; return 1; fi
    printf '.'; sleep 3
  done
}

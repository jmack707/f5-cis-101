#!/usr/bin/env bash
# ============================================================================
# validate.sh — static checks for the whole repo. No cluster/BIG-IP needed,
# so it runs locally and in CI. Run before every commit.
#   - bash -n on every script
#   - guard against the literal "\&\&" heredoc bug
#   - guard against a committed real BIG-IP password
#   - render every templated manifest (envsubst) and lint YAML + embedded AS3 JSON
# Exits nonzero on any failure.
# ============================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
rc=0
say() { printf '%s\n' "$*"; }
ok()  { printf '  OK   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; rc=1; }

say "[1] shell syntax (bash -n)"
while IFS= read -r s; do bash -n "$s" 2>/dev/null && ok "$s" || bad "$s"; done \
  < <(find . -name '*.sh' -not -path './.git/*' | sort)

say "[2] no literal backslash-&& (heredoc bug guard)"
if grep -rIl '\\&\\&' --include='*.sh' --exclude='validate.sh' . >/dev/null 2>&1; then
  grep -rIl '\\&\\&' --include='*.sh' --exclude='validate.sh' . | sed 's/^/  FAIL /'; rc=1
else ok "none found"; fi

say "[3] no committed real password"
# lab-vars.env is gitignored; flag a known/real-looking password anywhere tracked
if grep -rIn "F5site02@" --include='*.env' --include='*.sh' --include='*.yaml' --exclude='validate.sh' . 2>/dev/null \
     | grep -v 'lab-vars.env:' >/dev/null; then
  bad "real-looking password found in a tracked file"
  grep -rIn "F5site02@" --include='*.env' --include='*.sh' --include='*.yaml' --exclude='validate.sh' . | grep -v 'lab-vars.env:'
else ok "none found in tracked files"; fi
[ -f lab-vars.env.example ] && ok "lab-vars.env.example present" || bad "lab-vars.env.example missing"

say "[4] render + lint manifests"
# Use lab-vars.env if present, else the committed example (CI has no real one).
VARS_FILE=lab-vars.env; [ -f "$VARS_FILE" ] || VARS_FILE=lab-vars.env.example
set -a; . "./$VARS_FILE"; set +a
: "${AS3_TENANT:=AS3}"    # backward-compat default for older lab-vars.env files
. ./lib/labkit-subst.sh  # single source of truth for the allowlist (shared with labkit.sh)
SUBST="$LABKIT_SUBST"
if ! command -v envsubst >/dev/null 2>&1; then bad "envsubst missing (install gettext/gettext-base)"; fi
python3 - "$SUBST" <<'PY' || rc=1
import subprocess, glob, sys
try:
    import yaml
except Exception:
    print("  FAIL pyyaml not installed (pip install pyyaml)"); sys.exit(1)
import json
subst=sys.argv[1]; bad=0; n=0
for f in sorted(glob.glob('**/*.yaml', recursive=True)):
    if f.startswith('./.git/'): continue
    n+=1; raw=open(f).read()
    r=subprocess.run(['envsubst',subst],input=raw,capture_output=True,text=True).stdout if '${' in raw else raw
    if '${' in r:
        print(f"  FAIL unresolved token in {f}"); bad+=1; continue
    try:
        for d in yaml.safe_load_all(r):
            if d and d.get('kind')=='ConfigMap' and isinstance(d.get('data'),dict) and 'template' in d['data']:
                json.loads(d['data']['template'])
    except Exception as e:
        print(f"  FAIL {f}: {str(e)[:80]}"); bad+=1
print(f"  {'OK  ' if not bad else 'FAIL'} {n} manifests, {bad} bad (vars from {__import__('os').environ.get('VARS_FILE','example')})")
sys.exit(1 if bad else 0)
PY

echo "----------------------------------------"
[ $rc -eq 0 ] && echo "validate.sh: PASS" || echo "validate.sh: FAIL"
exit $rc

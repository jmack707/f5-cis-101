#!/usr/bin/env bash
# ============================================================================
# lab.sh — driver for a single lab folder.
#   ./lab.sh apply  <labdir>   render + kubectl apply all NN-*.yaml in order
#   ./lab.sh delete <labdir>   delete in reverse order
#   ./lab.sh verify <labdir>   run <labdir>/verify.sh
#   ./lab.sh render <labdir>   print rendered manifests (no apply)
#
# If <labdir> contains install-nginx-ic.sh (NGINX IC, has $(POD_*) tokens that
# must NOT be envsubst'd), apply/delete delegate to that script instead.
# ============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/labkit.sh"

cmd="${1:-}"; dir="${2:-}"
[ -n "$cmd" ] && [ -n "$dir" ] || { echo "usage: lab.sh {apply|delete|verify|render} <labdir>"; exit 2; }
[ -d "$dir" ] || { echo "no such lab dir: $dir"; exit 2; }

mapfile -t FILES < <(find "$dir" -maxdepth 1 -name '[0-9][0-9]-*.yaml' | sort)

case "$cmd" in
  apply)
    if [ -x "$dir/install-nginx-ic.sh" ]; then bash "$dir/install-nginx-ic.sh"; exit $?; fi
    for f in "${FILES[@]}"; do echo "apply  $f"; kapply "$f"; done
    ;;
  delete)
    if [ -f "$dir/install-nginx-ic.sh" ]; then
      # reverse the IC files
      for ((i=${#FILES[@]}-1;i>=0;i--)); do echo "delete ${FILES[$i]}"; kubectl delete --ignore-not-found -f "${FILES[$i]}"; done
      exit $?
    fi
    for ((i=${#FILES[@]}-1;i>=0;i--)); do echo "delete ${FILES[$i]}"; kdelete "${FILES[$i]}"; done
    ;;
  render)
    for f in "${FILES[@]}"; do echo "# --- $f ---"; envsubst "$LABKIT_SUBST" < "$f"; echo; done
    ;;
  verify)
    [ -x "$dir/verify.sh" ] || { echo "no verify.sh in $dir"; exit 2; }
    bash "$dir/verify.sh"
    ;;
  *) echo "unknown command: $cmd"; exit 2 ;;
esac

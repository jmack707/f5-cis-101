#!/usr/bin/env bash
# Module 2 — BIG-IP prep for CIS ClusterIP with STATIC ROUTES (no VXLAN).
# CIS writes pod-CIDR-via-nodeIP routes onto BIG-IP, so the only BIG-IP
# requirements are: (1) the partition exists, and (2) BIG-IP has L3 reachability
# to the node IPs (an existing data self-IP on the node network).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE"; while [ ! -f "$ROOT/lab-vars.env" ] && [ "$ROOT" != / ]; do ROOT="$(dirname "$ROOT")"; done
source "$ROOT/lib/labkit.sh"
# Partition (idempotent) via iControl REST — no SSH, no password prompt; uses the
# BIG-IP credentials already in lab-vars.env.
ensure_partition
echo "Done. No VXLAN objects needed for static-route mode."
echo "After CIS starts, verify on BIG-IP:  tmsh list net route | grep k8s-"

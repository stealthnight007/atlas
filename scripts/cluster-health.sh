#!/usr/bin/env bash

set -u

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl is not installed or is not available in PATH." >&2
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Error: unable to connect to the configured Kubernetes cluster." >&2
  exit 1
fi

section() {
  printf '\n============================================================\n'
  printf '%s\n' "$1"
  printf '============================================================\n'
}

section "Atlas Kubernetes Cluster Health"

printf 'Context: %s\n' "$(kubectl config current-context)"
printf 'Checked: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

section "Nodes"
kubectl get nodes -o wide

section "Control Plane and System Pods"
kubectl get pods -n kube-system -o wide

section "Non-Running Pods"
non_running="$(
  kubectl get pods --all-namespaces \
    --field-selector=status.phase!=Running,status.phase!=Succeeded \
    --no-headers 2>/dev/null || true
)"

if [[ -n "$non_running" ]]; then
  printf '%s\n' "$non_running"
else
  echo "No non-running pods found."
fi

section "Recent Warning Events"
warnings="$(
  kubectl get events --all-namespaces \
    --field-selector=type=Warning \
    --sort-by=.metadata.creationTimestamp \
    --no-headers 2>/dev/null | tail -20 || true
)"

if [[ -n "$warnings" ]]; then
  printf '%s\n' "$warnings"
else
  echo "No warning events found."
fi

section "Resource Metrics"
if kubectl top nodes >/dev/null 2>&1; then
  kubectl top nodes
else
  echo "Metrics are unavailable. Metrics Server may not be installed yet."
fi

section "Health Check Complete"

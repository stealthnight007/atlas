#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Project Atlas: Calico Installation and Validation
#
# Installs a pinned Calico release through the Tigera Operator.
# The Kubernetes pod network is read from kubeadm's live cluster
# configuration so no Atlas network values are stored in Git.
# ------------------------------------------------------------

CALICO_VERSION="v3.32.1"
CALICO_RELEASE_BASE="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests"
CALICO_CRDS_SHA256="192f8b2d934ef24b62e86b7e1a6e1762d1c8af26a916f78057bc13fa5ed60f71"
TIGERA_OPERATOR_SHA256="f18e073794207d372606bc3ea6f8fd73972f86d6828f4ba666dfe0d4aa8ab07f"

PREFLIGHT_ONLY=false
VALIDATE_ONLY=false
WORK_DIR=""

usage() {
  cat <<'EOF'
Usage:
  install-calico.sh [options]

Options:
  --preflight-only  Validate a fresh cluster and upstream artifacts; make no changes
  --validate-only   Validate an existing operator-managed Calico installation
  -h, --help        Show this help

The pod network is read from kubeadm's live ClusterConfiguration. This script
does not accept or persist environment-specific network values.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

cleanup() {
  if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
    rm -rf -- "${WORK_DIR}"
  fi
}

trap cleanup EXIT

while (($# > 0)); do
  case "$1" in
    --preflight-only)
      PREFLIGHT_ONLY=true
      shift
      ;;
    --validate-only)
      VALIDATE_ONLY=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

if [[ "${PREFLIGHT_ONLY}" == true && "${VALIDATE_ONLY}" == true ]]; then
  fail "--preflight-only and --validate-only cannot be used together."
fi

if ((EUID == 0)); then
  fail "Run this script as the Kubernetes operator account, not as root."
fi

required_commands=(
  awk
  curl
  grep
  hostname
  kubectl
  mktemp
  rm
  sha256sum
  sleep
  sudo
)

for required_command in "${required_commands[@]}"; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    fail "Required command not found: ${required_command}"
  fi
done

if ! kubectl get --raw='/readyz' >/dev/null 2>&1; then
  fail "The Kubernetes API readiness check failed."
fi

if [[ "$(kubectl auth can-i '*' '*' --all-namespaces)" != "yes" ]]; then
  fail "The active kubeconfig does not have cluster-admin access."
fi

cluster_configuration="$(
  kubectl -n kube-system get configmap kubeadm-config \
    -o jsonpath='{.data.ClusterConfiguration}'
)"

pod_network_cidr="$(
  grep 'podSubnet:' <<<"${cluster_configuration}" |
    tr -d ' ' |
    awk -F: '{print substr($0, index($0, ":") + 1)}' || true
)"

if [[ -z "${pod_network_cidr}" ]]; then
  fail "kubeadm ClusterConfiguration does not contain a podSubnet."
fi

mapfile -t control_plane_nodes < <(
  kubectl get nodes -l node-role.kubernetes.io/control-plane \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
)

if ((${#control_plane_nodes[@]} != 1)); then
  fail "Expected exactly one control-plane node for this Atlas workflow."
fi

control_plane_node="${control_plane_nodes[0]}"

if [[ "$(hostname)" != "${control_plane_node}" ]]; then
  fail "Run this script on the Atlas control-plane host (${control_plane_node})."
fi

installation_exists=false
if kubectl get installation.operator.tigera.io default >/dev/null 2>&1; then
  installation_exists=true
fi

tigera_status_available() {
  local status_name="$1"
  local available

  available="$(
    kubectl get tigerastatus "${status_name}" \
      -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' \
      2>/dev/null || true
  )"

  [[ "${available}" == "True" ]]
}

node_is_ready() {
  local node_name="$1"
  local ready

  ready="$(
    kubectl get node "${node_name}" \
      -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
  )"

  [[ "${ready}" == "True" ]]
}

wait_for_tigera_status() {
  local status_name="$1"
  local attempts=120

  log "Waiting for TigeraStatus/${status_name}"

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if tigera_status_available "${status_name}"; then
      log "TigeraStatus/${status_name} is available"
      return 0
    fi
    sleep 5
  done

  kubectl get tigerastatus "${status_name}" -o yaml 2>/dev/null || true
  fail "TigeraStatus/${status_name} did not become available within ten minutes."
}

wait_for_node_ready() {
  local node_name="$1"
  local attempts=120

  log "Waiting for node/${node_name} to become Ready"

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if node_is_ready "${node_name}"; then
      log "node/${node_name} is Ready"
      return 0
    fi
    sleep 5
  done

  kubectl describe node "${node_name}" || true
  fail "node/${node_name} did not become Ready within ten minutes."
}

wait_for_deployment_available() {
  local namespace="$1"
  local deployment="$2"
  local attempts=120
  local desired available

  log "Waiting for deployment/${deployment} in ${namespace}"

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    desired="$(
      kubectl get deployment "${deployment}" -n "${namespace}" \
        -o jsonpath='{.spec.replicas}' 2>/dev/null || true
    )"
    available="$(
      kubectl get deployment "${deployment}" -n "${namespace}" \
        -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true
    )"

    if [[ -n "${desired}" && "${desired}" == "${available}" ]]; then
      log "deployment/${deployment} is available"
      return 0
    fi
    sleep 5
  done

  kubectl describe deployment "${deployment}" -n "${namespace}" || true
  fail "deployment/${deployment} did not become available within ten minutes."
}

validate_installation() {
  local installed_node_image
  local expected_image_suffix

  if [[ "${installation_exists}" != true ]]; then
    fail "Installation/default does not exist."
  fi

  for status_name in calico apiserver ippools tiers; do
    if ! tigera_status_available "${status_name}"; then
      kubectl get tigerastatus "${status_name}" 2>/dev/null || true
      fail "TigeraStatus/${status_name} is not available."
    fi
  done

  if ! node_is_ready "${control_plane_node}"; then
    fail "The control-plane node is not Ready."
  fi

  wait_for_deployment_available kube-system coredns

  installed_node_image="$(
    kubectl get daemonset calico-node -n calico-system \
      -o jsonpath='{.spec.template.spec.containers[0].image}'
  )"
  expected_image_suffix=":${CALICO_VERSION}"

  if [[ "${installed_node_image}" != *"${expected_image_suffix}" ]]; then
    fail "Installed Calico node image does not match ${CALICO_VERSION}."
  fi

  if ! sudo -n test -f /etc/cni/net.d/10-calico.conflist; then
    fail "Calico CNI configuration was not written to /etc/cni/net.d."
  fi

  if ! sudo -n test -f /etc/cni/net.d/calico-kubeconfig; then
    fail "Calico kubeconfig was not written to /etc/cni/net.d."
  fi

  kubectl get --raw='/readyz?verbose'
  echo
  kubectl get tigerastatus
  kubectl get nodes
  kubectl get pods -n calico-system
  kubectl get pods -n kube-system

  log "Calico ${CALICO_VERSION} validation complete"
}

if [[ "${VALIDATE_ONLY}" == true ]]; then
  validate_installation
  exit 0
fi

if [[ "${installation_exists}" == true ]]; then
  fail "Installation/default already exists. Use --validate-only instead."
fi

partial_state=()

if kubectl get namespace tigera-operator >/dev/null 2>&1; then
  partial_state+=("namespace/tigera-operator")
fi

if kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; then
  partial_state+=("crd/installations.operator.tigera.io")
fi

if ((${#partial_state[@]} > 0)); then
  fail "Partial Calico state detected (${partial_state[*]}). Review it before retrying."
fi

WORK_DIR="$(mktemp -d)"
crds_manifest="${WORK_DIR}/v1_crd_projectcalico_org.yaml"
operator_manifest="${WORK_DIR}/tigera-operator.yaml"
custom_resources="${WORK_DIR}/atlas-calico-resources.yaml"

log "Downloading pinned Calico ${CALICO_VERSION} manifests"
curl -fsSLo "${crds_manifest}" \
  "${CALICO_RELEASE_BASE}/v1_crd_projectcalico_org.yaml"
curl -fsSLo "${operator_manifest}" \
  "${CALICO_RELEASE_BASE}/tigera-operator.yaml"

printf '%s  %s\n' "${CALICO_CRDS_SHA256}" "${crds_manifest}" | sha256sum --check --status ||
  fail "Calico CRD manifest checksum verification failed."
printf '%s  %s\n' "${TIGERA_OPERATOR_SHA256}" "${operator_manifest}" | sha256sum --check --status ||
  fail "Tigera Operator manifest checksum verification failed."

log "Pinned manifest checksums validated"

cat >"${custom_resources}" <<EOF
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
      - name: default-ipv4-ippool
        blockSize: 26
        cidr: ${pod_network_cidr}
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

kubectl create --dry-run=server -f "${crds_manifest}" >/dev/null
kubectl create --dry-run=server -f "${operator_manifest}" >/dev/null

log "Fresh-cluster preflight validation passed"

if [[ "${PREFLIGHT_ONLY}" == true ]]; then
  log "Preflight-only validation complete; no changes were made"
  exit 0
fi

log "Creating Calico CRDs"
kubectl create -f "${crds_manifest}"

log "Creating the Tigera Operator"
kubectl create -f "${operator_manifest}"
wait_for_deployment_available tigera-operator tigera-operator

log "Validating and creating Atlas Calico resources"
kubectl create --dry-run=server -f "${custom_resources}" >/dev/null
kubectl create -f "${custom_resources}"

for status_name in ippools calico apiserver tiers; do
  wait_for_tigera_status "${status_name}"
done

wait_for_node_ready "${control_plane_node}"
wait_for_deployment_available kube-system coredns

installation_exists=true
validate_installation

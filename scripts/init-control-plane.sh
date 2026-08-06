#!/usr/bin/env bash

# Exit immediately if a command fails.
# Treat unset variables as errors.
# Fail a pipeline if any command in the pipeline fails.
set -euo pipefail

# ------------------------------------------------------------
# Project Atlas: Kubernetes Control-Plane Initialization
#
# Purpose:
#   Initialize a fresh Atlas Kubernetes control-plane node after
#   scripts/bootstrap-node.sh has prepared the operating system.
#
# This script:
#   - Refuses existing Kubernetes control-plane state
#   - Validates the node foundation before making changes
#   - Requires the pod network CIDR at runtime
#   - Pulls the required Kubernetes images
#   - Initializes the control plane with kubeadm
#   - Configures owner-only kubectl access for the operator
#   - Validates the Kubernetes API and control-plane pods
#
# Public repository safety:
#   - No environment-specific IP addresses or network ranges
#   - No passwords or SSH key material
#   - No persisted Kubernetes join tokens
#   - No certificates or kubeconfig contents
# ------------------------------------------------------------

POD_NETWORK_CIDR=""
REQUESTED_KUBERNETES_VERSION=""
PREFLIGHT_ONLY=false

usage() {
  cat <<'EOF'
Usage:
  init-control-plane.sh --pod-network-cidr CIDR [options]

Required:
  --pod-network-cidr CIDR       Private, non-overlapping IPv4 CIDR for pods

Options:
  --kubernetes-version VERSION  Exact version to initialize (default: installed kubeadm version)
  --preflight-only              Validate without pulling images or running kubeadm init
  -h, --help                    Show this help

Examples use placeholders intentionally. Supply environment-specific values
at runtime and never commit them to the repository.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_value() {
  local option_name="$1"
  local option_value="${2:-}"

  if [[ -z "${option_value}" || "${option_value}" == -* ]]; then
    fail "${option_name} requires a value."
  fi
}

validate_ipv4_cidr() {
  local cidr="$1"
  local address prefix octet
  local -a octets

  if [[ ! "${cidr}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
    return 1
  fi

  address="${cidr%/*}"
  prefix="${cidr#*/}"

  if ((10#${prefix} > 32)); then
    return 1
  fi

  IFS='.' read -r -a octets <<<"${address}"
  for octet in "${octets[@]}"; do
    if ((10#${octet} > 255)); then
      return 1
    fi
  done
}

is_private_ipv4_cidr() {
  local cidr="$1"
  local address prefix first_octet second_octet

  address="${cidr%/*}"
  prefix="${cidr#*/}"
  IFS='.' read -r first_octet second_octet _ <<<"${address}"

  if ((10#${first_octet} == 10 && 10#${prefix} >= 8)); then
    return 0
  fi

  if ((10#${first_octet} == 172 && 10#${second_octet} >= 16 && 10#${second_octet} <= 31 && 10#${prefix} >= 12)); then
    return 0
  fi

  if ((10#${first_octet} == 192 && 10#${second_octet} == 168 && 10#${prefix} >= 16)); then
    return 0
  fi

  return 1
}

pod_network_overlaps_host_route() {
  local cidr="$1"

  ip -4 route show | python3 -c '
import ipaddress
import sys

pod_network = ipaddress.ip_network(sys.argv[1], strict=False)
route_types = {
    "blackhole",
    "broadcast",
    "local",
    "multicast",
    "nat",
    "prohibit",
    "throw",
    "unreachable",
}

for line in sys.stdin:
    fields = line.split()
    if not fields:
        continue

    destination_index = 1 if fields[0] in route_types else 0
    if destination_index >= len(fields):
        continue

    destination = fields[destination_index]
    if destination == "default":
        continue

    if "/" not in destination:
        destination = f"{destination}/32"

    try:
        host_route = ipaddress.ip_network(destination, strict=False)
    except ValueError:
        continue

    if pod_network.overlaps(host_route):
        sys.exit(0)

sys.exit(1)
' "${cidr}"
}

run_as_root() {
  sudo "$@"
}

while (($# > 0)); do
  case "$1" in
    --pod-network-cidr)
      require_value "$1" "${2:-}"
      POD_NETWORK_CIDR="$2"
      shift 2
      ;;
    --kubernetes-version)
      require_value "$1" "${2:-}"
      REQUESTED_KUBERNETES_VERSION="$2"
      shift 2
      ;;
    --preflight-only)
      PREFLIGHT_ONLY=true
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

if [[ -z "${POD_NETWORK_CIDR}" ]]; then
  usage >&2
  fail "--pod-network-cidr is required."
fi

if ! validate_ipv4_cidr "${POD_NETWORK_CIDR}"; then
  fail "--pod-network-cidr must be a valid IPv4 CIDR."
fi

if ! is_private_ipv4_cidr "${POD_NETWORK_CIDR}"; then
  fail "--pod-network-cidr must use an RFC 1918 private address range."
fi

if ((EUID == 0)); then
  fail "Run this script as the operator account, not as root. The script uses sudo when required."
fi

# ------------------------------------------------------------
# Step 1: Refuse existing cluster state
#
# Re-running kubeadm init against a configured node can damage a
# working control plane. Stop and require deliberate recovery.
# ------------------------------------------------------------

existing_state_paths=(
  /etc/kubernetes/admin.conf
  /etc/kubernetes/manifests/kube-apiserver.yaml
  /var/lib/kubelet/config.yaml
)

for state_path in "${existing_state_paths[@]}"; do
  if [[ -e "${state_path}" ]]; then
    fail "Existing Kubernetes state detected at ${state_path}. Refusing to initialize this node."
  fi
done

echo "==> Existing-state validation passed"

# ------------------------------------------------------------
# Step 2: Verify required commands and operating system
# ------------------------------------------------------------

required_commands=(
  awk
  containerd
  grep
  id
  ip
  install
  kubeadm
  kubelet
  kubectl
  mkdir
  python3
  sudo
  swapon
  sysctl
  systemctl
  tr
  uname
  wc
)

for required_command in "${required_commands[@]}"; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    fail "Required command not found: ${required_command}"
  fi
done

# shellcheck source=/etc/os-release
source /etc/os-release

if [[ "${ID}" != "ubuntu" || "${VERSION_ID}" != "24.04" ]]; then
  fail "This script requires Ubuntu 24.04 LTS. Detected: ${PRETTY_NAME}"
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
  fail "This Atlas script requires the ARM64 architecture."
fi

echo "==> Required commands, operating system, and architecture validated"

# ------------------------------------------------------------
# Step 3: Verify Kubernetes version alignment
# ------------------------------------------------------------

INSTALLED_KUBERNETES_VERSION="$(kubeadm version -o short)"
KUBERNETES_VERSION="${REQUESTED_KUBERNETES_VERSION:-${INSTALLED_KUBERNETES_VERSION}}"

if [[ ! "${KUBERNETES_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  fail "Kubernetes version must use the form vMAJOR.MINOR.PATCH."
fi

if [[ "${KUBERNETES_VERSION}" != "${INSTALLED_KUBERNETES_VERSION}" ]]; then
  fail "Requested Kubernetes version ${KUBERNETES_VERSION} does not match installed kubeadm ${INSTALLED_KUBERNETES_VERSION}."
fi

if [[ "$(kubelet --version | awk '{print $2}')" != "${KUBERNETES_VERSION}" ]]; then
  fail "Installed kubelet does not match kubeadm ${KUBERNETES_VERSION}."
fi

echo "==> Kubernetes version alignment validated: ${KUBERNETES_VERSION}"

# ------------------------------------------------------------
# Step 4: Verify the node foundation
# ------------------------------------------------------------

if [[ -n "$(swapon --show --noheadings)" ]]; then
  fail "Swap is enabled. Disable it before initializing Kubernetes."
fi

if [[ "$(systemctl is-active containerd)" != "active" ]]; then
  fail "containerd is not active."
fi

if ! grep -Eq '^[[:space:]]*SystemdCgroup = true[[:space:]]*$' \
  /etc/containerd/config.toml; then
  fail "containerd is not configured with SystemdCgroup = true."
fi

for kernel_module in overlay br_netfilter; do
  if [[ ! -d "/sys/module/${kernel_module}" ]]; then
    fail "Required kernel module is not loaded: ${kernel_module}"
  fi
done

required_sysctls=(
  net.bridge.bridge-nf-call-iptables
  net.bridge.bridge-nf-call-ip6tables
  net.ipv4.ip_forward
)

for required_sysctl in "${required_sysctls[@]}"; do
  if [[ "$(sysctl -n "${required_sysctl}")" != "1" ]]; then
    fail "Required sysctl is not set to 1: ${required_sysctl}"
  fi
done

if [[ "$(ip -4 route show default | wc -l | tr -d ' ')" != "1" ]]; then
  fail "Expected exactly one IPv4 default route for kubeadm address detection."
fi

if [[ "$(ip -4 -o address show scope global | wc -l | tr -d ' ')" != "1" ]]; then
  fail "Expected exactly one global IPv4 address for kubeadm address detection."
fi

if grep -q '^ENABLED=yes' /etc/ufw/ufw.conf 2>/dev/null; then
  fail "UFW is enabled. Review Kubernetes and CNI port policy before initialization."
fi

if pod_network_overlaps_host_route "${POD_NETWORK_CIDR}"; then
  fail "The requested pod network CIDR overlaps a host route."
fi

echo "==> Swap, containerd, kernel, sysctl, firewall, and host networking validated"

if [[ "${PREFLIGHT_ONLY}" == true ]]; then
  echo "==> Preflight-only validation complete; no changes were made"
  exit 0
fi

# ------------------------------------------------------------
# Step 5: Obtain sudo authorization
#
# Ask only after all unprivileged, non-mutating checks pass.
# ------------------------------------------------------------

echo "==> Requesting sudo authorization"
sudo -v

# ------------------------------------------------------------
# Step 6: Pull images and initialize the control plane
#
# kubeadm prints a temporary worker join command. Treat that
# output as sensitive and do not copy it into Git or Linear.
# ------------------------------------------------------------

echo "==> Pulling Kubernetes ${KUBERNETES_VERSION} control-plane images"
run_as_root kubeadm config images pull \
  --kubernetes-version="${KUBERNETES_VERSION}"

echo "==> Initializing the Kubernetes control plane"
run_as_root kubeadm init \
  --kubernetes-version="${KUBERNETES_VERSION}" \
  --pod-network-cidr="${POD_NETWORK_CIDR}"

# ------------------------------------------------------------
# Step 7: Configure local kubectl access
#
# Keep the generated kubeconfig only on the control-plane node
# with owner-only permissions.
# ------------------------------------------------------------

echo "==> Configuring local kubectl access"
mkdir -p "${HOME}/.kube"

run_as_root install \
  -o "$(id -u)" \
  -g "$(id -g)" \
  -m 0600 \
  /etc/kubernetes/admin.conf \
  "${HOME}/.kube/config"

# ------------------------------------------------------------
# Step 8: Validate the control plane
# ------------------------------------------------------------

echo "==> Validating the Kubernetes API and control-plane pods"
kubectl get --raw='/readyz?verbose'
echo
kubectl get nodes
kubectl get pods -n kube-system -l tier=control-plane

echo
echo "============================================================"
echo "Atlas control-plane initialization complete."
echo "The node will remain NotReady until a CNI is installed."
echo "Treat the kubeadm join command as a secret."
echo "============================================================"

#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Project Atlas: Kubernetes Worker Join
#
# Run this script on one prepared worker node. For a real join,
# pipe a short-lived `kubeadm join` command through standard input.
# The command is parsed into an argument array and is never evaluated
# as shell code or written to disk by this script.
# ------------------------------------------------------------

PREFLIGHT_ONLY=false
VALIDATE_ONLY=false
JOIN_COMMAND=""
JOIN_TOKEN=""
DISCOVERY_HASH=""
JOIN_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  join-worker.sh --preflight-only
  join-worker.sh --validate-only
  printf '%s' "$JOIN_COMMAND" | join-worker.sh

Options:
  --preflight-only  Validate a fresh worker without joining it
  --validate-only   Validate local state on an already joined worker
  -h, --help        Show this help

Security:
  Generate a short-lived token on the control plane, pipe the resulting
  kubeadm join command through SSH standard input, and revoke the token as
  soon as the node becomes Ready. Never place join data in shell history,
  source control, logs, or project tracking.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

clear_sensitive_values() {
  JOIN_COMMAND=""
  JOIN_TOKEN=""
  DISCOVERY_HASH=""
  JOIN_ARGS=()
}

trap clear_sensitive_values EXIT

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
  fail "Run this script as the worker operator account, not as root."
fi

required_commands=(
  awk
  containerd
  find
  grep
  hostname
  kubeadm
  kubelet
  seq
  sleep
  sudo
  swapon
  sysctl
  systemctl
  uname
)

for required_command in "${required_commands[@]}"; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    fail "Required command not found: ${required_command}"
  fi
done

if ! sudo -n true; then
  fail "Passwordless sudo is required for the Atlas worker workflow."
fi

# shellcheck source=/etc/os-release
source /etc/os-release

if [[ "${ID}" != "ubuntu" || "${VERSION_ID}" != "24.04" ]]; then
  fail "This script requires Ubuntu 24.04 LTS. Detected: ${PRETTY_NAME}"
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
  fail "This Atlas script requires the ARM64 architecture."
fi

installed_kubeadm_version="$(kubeadm version -o short)"
installed_kubelet_version="$(kubelet --version | awk '{print $2}')"

if [[ "${installed_kubeadm_version}" != "${installed_kubelet_version}" ]]; then
  fail "Installed kubeadm and kubelet versions do not match."
fi

validate_joined_state() {
  local cni_ready=false

  if ! sudo -n test -f /etc/kubernetes/kubelet.conf; then
    fail "Worker kubelet credentials are missing."
  fi

  if ! sudo -n test -f /var/lib/kubelet/config.yaml; then
    fail "Worker kubelet configuration is missing."
  fi

  if [[ "$(systemctl is-active containerd)" != "active" ]]; then
    fail "containerd is not active."
  fi

  if [[ "$(systemctl is-active kubelet)" != "active" ]]; then
    fail "kubelet is not active."
  fi

  for attempt in $(seq 1 120); do
    if sudo -n test -f /etc/cni/net.d/10-calico.conflist &&
      sudo -n test -f /etc/cni/net.d/calico-kubeconfig; then
      cni_ready=true
      break
    fi
    sleep 5
  done

  if [[ "${cni_ready}" != true ]]; then
    fail "Calico CNI files did not appear within ten minutes."
  fi

  log "Joined worker validation complete"
  printf 'node=%s kubeadm=%s containerd=active kubelet=active cni=ready\n' \
    "$(hostname)" "${installed_kubeadm_version}"
}

if [[ "${VALIDATE_ONLY}" == true ]]; then
  validate_joined_state
  exit 0
fi

existing_state_paths=(
  /etc/kubernetes/kubelet.conf
  /var/lib/kubelet/config.yaml
  /var/lib/kubelet/instance-config.yaml
)

for state_path in "${existing_state_paths[@]}"; do
  if sudo -n test -e "${state_path}"; then
    fail "Existing Kubernetes worker state detected at ${state_path}."
  fi
done

existing_cni_files="$(
  sudo -n find /etc/cni/net.d -maxdepth 1 -type f \
    \( -name '*.conf' -o -name '*.conflist' -o -name '*kubeconfig*' \) \
    -print 2>/dev/null || true
)"

if [[ -n "${existing_cni_files}" ]]; then
  fail "Existing CNI configuration detected. Review it before joining this worker."
fi

if [[ "$(systemctl is-active containerd)" != "active" ]]; then
  fail "containerd is not active."
fi

if ! grep -Eq '^[[:space:]]*SystemdCgroup = true[[:space:]]*$' \
  /etc/containerd/config.toml; then
  fail "containerd is not configured with SystemdCgroup = true."
fi

if [[ -n "$(swapon --show --noheadings)" ]]; then
  fail "Swap is enabled."
fi

for kernel_module in overlay br_netfilter; do
  if [[ ! -d "/sys/module/${kernel_module}" ]]; then
    fail "Required kernel module is not loaded: ${kernel_module}"
  fi
done

for required_sysctl in \
  net.bridge.bridge-nf-call-iptables \
  net.bridge.bridge-nf-call-ip6tables \
  net.ipv4.ip_forward; do
  if [[ "$(sysctl -n "${required_sysctl}")" != "1" ]]; then
    fail "Required sysctl is not set to 1: ${required_sysctl}"
  fi
done

log "Fresh worker preflight validation passed"

if [[ "${PREFLIGHT_ONLY}" == true ]]; then
  log "Preflight-only validation complete; no changes were made"
  exit 0
fi

if [[ -t 0 ]]; then
  fail "Join data must be piped through standard input."
fi

IFS= read -r JOIN_COMMAND || true

if [[ -z "${JOIN_COMMAND}" ]]; then
  fail "No kubeadm join command was received on standard input."
fi

if IFS= read -r extra_line && [[ -n "${extra_line}" ]]; then
  fail "Join input must contain exactly one command line."
fi

read -r -a JOIN_ARGS <<<"${JOIN_COMMAND}"

if ((${#JOIN_ARGS[@]} < 6)); then
  fail "The kubeadm join command is incomplete."
fi

if [[ "${JOIN_ARGS[0]}" != "kubeadm" || "${JOIN_ARGS[1]}" != "join" ]]; then
  fail "Standard input must begin with: kubeadm join"
fi

if [[ ! "${JOIN_ARGS[2]}" =~ ^[^[:space:]]+:[0-9]+$ ]]; then
  fail "The kubeadm API endpoint is malformed."
fi

for ((index = 3; index < ${#JOIN_ARGS[@]}; index++)); do
  case "${JOIN_ARGS[index]}" in
    --token)
      if [[ -n "${JOIN_TOKEN}" ]]; then
        fail "The kubeadm join command contains duplicate --token options."
      fi
      ((index++))
      if ((index >= ${#JOIN_ARGS[@]})); then
        fail "--token is missing its value."
      fi
      JOIN_TOKEN="${JOIN_ARGS[index]}"
      ;;
    --discovery-token-ca-cert-hash)
      if [[ -n "${DISCOVERY_HASH}" ]]; then
        fail "The kubeadm join command contains duplicate discovery hashes."
      fi
      ((index++))
      if ((index >= ${#JOIN_ARGS[@]})); then
        fail "--discovery-token-ca-cert-hash is missing its value."
      fi
      DISCOVERY_HASH="${JOIN_ARGS[index]}"
      ;;
    --control-plane | --control-plane=* | \
      --certificate-key | --certificate-key=* | \
      --ignore-preflight-errors | --ignore-preflight-errors=* | \
      --skip-phases | --skip-phases=*)
      fail "Forbidden kubeadm join option: ${JOIN_ARGS[index]}"
      ;;
    --cri-socket | --cri-socket=*)
      fail "The script manages --cri-socket explicitly."
      ;;
    --*)
      fail "Unexpected kubeadm join option: ${JOIN_ARGS[index]}"
      ;;
    *)
      fail "Unexpected kubeadm join argument."
      ;;
  esac
done

if [[ ! "${JOIN_TOKEN}" =~ ^[a-z0-9]{6}\.[a-z0-9]{16}$ ]]; then
  fail "The kubeadm bootstrap token format is invalid."
fi

if [[ ! "${DISCOVERY_HASH}" =~ ^sha256:[a-f0-9]{64}$ ]]; then
  fail "The kubeadm CA discovery hash format is invalid."
fi

log "Joining this worker to the Kubernetes cluster"
sudo -n "${JOIN_ARGS[@]}" \
  --cri-socket=unix:///run/containerd/containerd.sock

clear_sensitive_values
validate_joined_state

echo
echo "The worker joined successfully. Revoke its bootstrap token on the control plane now."

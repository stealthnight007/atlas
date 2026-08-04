#!/usr/bin/env bash

# Exit immediately if a command fails.
# Treat unset variables as errors.
# Fail a pipeline if any command in the pipeline fails.
set -euo pipefail

# ------------------------------------------------------------
# Project Atlas: Kubernetes Node Bootstrap
#
# Purpose:
#   Prepare a fresh Ubuntu 24.04 Raspberry Pi to become a
#   Kubernetes node.
#
# This script:
#   - Updates Ubuntu
#   - Installs required packages
#   - Enables iSCSI for Longhorn
#   - Loads Kubernetes kernel modules
#   - Enables Linux packet forwarding
#   - Installs and configures containerd
#   - Installs Kubernetes 1.35 packages
#   - Runs validation checks
#
# Public repository safety:
#   - No passwords
#   - No SSH private keys
#   - No Kubernetes join tokens
#   - No certificates
#   - No kubeconfig files
# ------------------------------------------------------------

# Select the Kubernetes minor-version repository.
# The installed patch version will be the latest available
# within this supported minor release.
KUBERNETES_MINOR="v1.35"

# ------------------------------------------------------------
# Step 1: Verify the operating system
#
# Atlas v2 is designed for Ubuntu 24.04 LTS.
# Stop instead of silently running against an unexpected OS.
# ------------------------------------------------------------

source /etc/os-release

if [[ "${ID}" != "ubuntu" || "${VERSION_ID}" != "24.04" ]]; then
  echo "ERROR: This script requires Ubuntu 24.04 LTS."
  echo "Detected: ${PRETTY_NAME}"
  exit 1
fi

echo "==> Operating system validated: ${PRETTY_NAME}"

# ------------------------------------------------------------
# Step 2: Confirm swap is disabled
#
# Kubernetes expects swap to remain disabled unless kubelet is
# explicitly configured to tolerate it. Atlas uses no swap.
# ------------------------------------------------------------

if [[ -n "$(swapon --show --noheadings)" ]]; then
  echo "ERROR: Swap is enabled."
  echo "Disable swap before running this script."
  swapon --show
  exit 1
fi

echo "==> Swap validation passed"

# ------------------------------------------------------------
# Step 3: Update Ubuntu
#
# Refresh package metadata and install all available upgrades
# from the supported Ubuntu repositories.
# ------------------------------------------------------------

echo "==> Updating Ubuntu"

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y

# ------------------------------------------------------------
# Step 4: Install required packages
#
# apt-transport-https:
#   Supports package repositories accessed over HTTPS.
#
# ca-certificates:
#   Provides trusted certificate authorities for TLS.
#
# curl:
#   Downloads repository signing keys.
#
# gpg:
#   Converts and stores the Kubernetes signing key.
#
# open-iscsi:
#   Required later by Longhorn to attach block volumes.
#
# containerd:
#   Container runtime used by Kubernetes.
# ------------------------------------------------------------

echo "==> Installing required packages"

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gpg \
  open-iscsi \
  containerd

# ------------------------------------------------------------
# Step 5: Enable iSCSI
#
# Longhorn uses iSCSI to present persistent block devices to
# Kubernetes nodes.
# ------------------------------------------------------------

echo "==> Enabling iSCSI"

sudo systemctl enable --now iscsid

# ------------------------------------------------------------
# Step 6: Configure required kernel modules
#
# overlay:
#   Supports layered container filesystems.
#
# br_netfilter:
#   Allows iptables to inspect traffic crossing Linux bridges.
#
# The modules-load file ensures both modules load after reboot.
# ------------------------------------------------------------

echo "==> Configuring Kubernetes kernel modules"

cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf >/dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# ------------------------------------------------------------
# Step 7: Configure Linux networking
#
# bridge-nf-call-iptables:
#   Makes bridged IPv4 traffic visible to iptables.
#
# bridge-nf-call-ip6tables:
#   Makes bridged IPv6 traffic visible to ip6tables.
#
# ip_forward:
#   Allows the node to route traffic between interfaces, pods,
#   and Kubernetes networks.
# ------------------------------------------------------------

echo "==> Configuring Kubernetes networking"

cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf >/dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system >/dev/null

# ------------------------------------------------------------
# Step 8: Configure containerd
#
# Generate a clean default containerd configuration.
#
# SystemdCgroup must be true so containerd and kubelet use the
# same cgroup manager. This prevents the configuration mismatch
# discovered during the Atlas v1 recovery.
# ------------------------------------------------------------

echo "==> Configuring containerd"

sudo mkdir -p /etc/containerd

containerd config default \
  | sudo tee /etc/containerd/config.toml >/dev/null

sudo sed -i \
  's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd

# ------------------------------------------------------------
# Step 9: Configure the Kubernetes package repository
#
# pkgs.k8s.io replaces the retired apt.kubernetes.io repository.
# The repository is pinned to Kubernetes 1.35.
# ------------------------------------------------------------

echo "==> Adding Kubernetes ${KUBERNETES_MINOR} repository"

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
  "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor --yes \
  -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

# ------------------------------------------------------------
# Step 10: Install Kubernetes node packages
#
# kubelet:
#   Runs pods and manages containers on the node.
#
# kubeadm:
#   Initializes control planes and joins nodes to clusters.
#
# kubectl:
#   Kubernetes command-line client.
#
# apt-mark hold:
#   Prevents unattended package upgrades from changing the
#   Kubernetes minor or patch version without deliberate review.
# ------------------------------------------------------------

echo "==> Installing Kubernetes packages"

sudo apt update

sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  kubelet \
  kubeadm \
  kubectl

sudo apt-mark hold kubelet kubeadm kubectl

# ------------------------------------------------------------
# Step 11: Validate the node
#
# These checks prove that the operating system, container
# runtime, kernel, networking, iSCSI, and Kubernetes packages
# are prepared correctly.
#
# kubelet may remain inactive or restart repeatedly until the
# node joins a Kubernetes cluster. That is expected.
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Atlas node validation"
echo "============================================================"

echo
echo "Hostname:"
hostname

echo
echo "Operating system:"
echo "${PRETTY_NAME}"

echo
echo "Architecture:"
uname -m

echo
echo "IPv4 addresses:"
ip -4 -br address

echo
echo "Swap:"
if [[ -z "$(swapon --show --noheadings)" ]]; then
  echo "Disabled"
else
  swapon --show
fi

echo
echo "Required kernel modules:"
lsmod | grep -E '^(overlay|br_netfilter)' || true

echo
echo "Required networking values:"
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables

echo
echo "iSCSI:"
iscsiadm --version
systemctl is-active iscsid

echo
echo "Container runtime:"
containerd --version
systemctl is-active containerd
grep 'SystemdCgroup = true' /etc/containerd/config.toml

echo
echo "Kubernetes:"
kubeadm version -o short
kubectl version --client
kubelet --version

echo
echo "============================================================"
echo "Node bootstrap complete."
echo "This node is ready for kubeadm initialization or join."
echo "============================================================"

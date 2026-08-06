# Atlas Cluster Reconstitution

## Objective

Reconstitute the Kubernetes control plane and worker nodes on the supported
Ubuntu 24.04 LTS foundation established during the Atlas platform rebuild.

## Why It Matters

The platform rebuild prepared four consistent Kubernetes hosts, but it did not
yet produce a functioning cluster. Control-plane initialization is the point
where the rebuilt operating-system and container-runtime foundation becomes an
operational Kubernetes platform again.

This step also tests whether the documented bootstrap process produced a
repeatable foundation. A successful initialization validates the interaction
between Linux networking, containerd, kubelet, kubeadm, certificates, etcd,
and the Kubernetes API before networking and worker capacity are added.

## Session Safety Boundaries

- Verify live node state before running cluster initialization commands.
- Keep passwords, SSH key material, IP addresses, Kubernetes tokens,
  certificates, and kubeconfig files out of the public repository.
- Validate the manual procedure before turning it into reusable automation.
- Do not reconnect or modify external storage until the storage phase.

## Management Access Preparation

The first connectivity attempt originated from a network without a route to
the Atlas infrastructure. After moving the management workstation to the
correct network, all four nodes responded on SSH.

The rebuilt nodes still required interactive password authentication. The
workstation's existing public SSH key was installed through a one-time,
user-entered password flow. Passwords and key material were never captured in
the project history. Key-based access was then validated on all four nodes.

## Read-Only Node Audit

The following baseline was validated across `master`, `worker1`, `worker2`,
and `worker3`:

| Check | Result |
|---|---|
| Host identity | Expected hostname on every node |
| Operating system | Ubuntu 24.04.4 LTS |
| Architecture | ARM64 |
| Kubernetes tooling | kubeadm, kubelet, and kubectl v1.35.7 |
| Container runtime | containerd active and enabled |
| Cgroup configuration | systemd cgroups enabled |
| Kubernetes packages | kubeadm, kubelet, and kubectl held |
| Swap | Disabled |
| Kernel modules | `overlay` and `br_netfilter` loaded |
| Network sysctls | Bridge filtering and IPv4 forwarding enabled |
| Longhorn prerequisite | iSCSI active and enabled |
| Time synchronization | Active and synchronized |
| Pending reboot | None |
| Existing control-plane state | None |
| Existing worker-join state | None |
| Existing etcd data | None |

Before initialization, kubelet was restarting on each node because kubeadm had
not generated `/var/lib/kubelet/config.yaml`. This is expected before
control-plane initialization or worker join and was not evidence of stale
cluster state.

Only the operating-system disks were visible during this audit. The external
Seagate and LaCie storage devices were not attached or mounted and remain out
of scope until the planned Longhorn storage phase.

## Network Design Review

Atlas will retain the previously validated private pod network. Live route
checks confirmed that the selected range does not overlap the node network on
any of the four hosts. The default Kubernetes service range also has no
host-route overlap.

Each node has one default route and one primary IPv4 address. Networking is
managed by `systemd-networkd`; NetworkManager and UFW are not enabled. No
Calico-specific NetworkManager exception is required.

The current Calico documentation identifies Calico 3.32 as tested with
Kubernetes 1.35 and ARM64. It recommends the Tigera Operator for new Calico
installations instead of a raw manifest because the operator manages the
installation and lifecycle.

References:

- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Calico system requirements](https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
- [Installing Calico on on-premises deployments](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises)

## Implementation

The control plane was initialized on `master` using kubeadm and the Kubernetes
version installed consistently across all four nodes. Kubeadm performed its
preflight checks, pulled the required ARM64 control-plane images, generated the
control-plane configuration, created the local etcd datastore, and registered
the first node.

Operator access was configured locally on the control-plane host. The
generated kubeconfig remains on that node with owner-only permissions; its
contents were never copied into the repository or external project tracking.

## Current Status

The control plane was initialized successfully on `master` with Kubernetes
v1.35.7 and the reviewed private pod network. The generated kubeconfig remains
on the control-plane node with owner-only permissions and is excluded from the
repository.

Validation confirmed:

- The Kubernetes API readiness endpoint passed all checks.
- etcd and its readiness check passed.
- The API server, controller manager, scheduler, and etcd static pods are
  running.
- The control-plane node registered with the expected Kubernetes version.
- CoreDNS is pending and the node is `NotReady`, as expected before installing
  a CNI.

No bootstrap token, certificate, kubeconfig content, node address, or internal
network range was captured in this log.

## Reusable Initialization Automation

The validated manual procedure is now captured in
`scripts/init-control-plane.sh`. The script requires the pod network at
runtime so Atlas-specific network details remain outside version control. It
uses the installed kubeadm version by default and supports an explicit version
only when it exactly matches the installed tooling.

Before making changes, the script verifies:

- The node has no existing Kubernetes control-plane or kubelet state.
- Ubuntu, ARM64, kubeadm, and kubelet match the supported Atlas foundation.
- Swap is disabled and containerd uses systemd cgroups.
- Required kernel modules and network sysctls are active.
- Host routing is unambiguous and does not overlap the requested pod network.
- The host firewall is not enabled in a way that conflicts with bootstrap.

The `--preflight-only` mode performs these checks without requesting elevated
access, pulling images, or initializing Kubernetes. It passed on all three
fresh worker nodes. A deliberately overlapping private range was rejected,
and the initialized control-plane node was rejected because existing state was
detected. These refusal tests confirm that the script fails before mutation in
both unsafe conditions.

For a fresh node, the execution path pre-pulls the required images, runs
`kubeadm init`, installs the generated kubeconfig only into the invoking
operator's home directory with owner-only permissions, and validates the API,
node registration, and control-plane pods. Join commands remain transient and
must never be written to source control or project tracking.

## Lessons Learned

- Verify the management workstation's network path before diagnosing all
  nodes as unavailable.
- Establish key-based access without recording passwords or key material in
  project artifacts.
- A restarting kubelet is expected before kubeadm writes its configuration;
  service state must be interpreted in the context of the bootstrap phase.
- Slow image pulls should be validated through container-runtime evidence
  before interrupting kubeadm or assuming initialization is stuck.
- Validate the control plane independently before introducing CNI and
  worker-node variables.

## Next Steps

1. Deploy and validate Calico through the Tigera Operator.
2. Join and validate all three worker nodes.
3. Continue converting the networking, worker-join, storage, startup, and
   shutdown procedures into reusable Atlas scripts.

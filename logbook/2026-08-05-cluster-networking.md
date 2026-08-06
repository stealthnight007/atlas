# Atlas Cluster Networking

## Objective

Install and validate the Kubernetes container network interface on the rebuilt
Atlas control plane, then capture the proven procedure as guarded automation.

This phase turns the initialized control plane into a node capable of assigning
pod addresses, routing workload traffic, enforcing network policy, and running
cluster DNS. It is also a prerequisite for joining workers and restoring
distributed storage.

## Design Decisions

Atlas uses Calico Open Source 3.32.1, installed through the Tigera Operator.
This release was selected because the current Calico requirements identify the
3.32 release line as tested with Kubernetes 1.35, ARM64, and supported Ubuntu
versions.

The operator installation method was selected for lifecycle management and
future upgrades. The installation is pinned to an exact Calico release rather
than an unversioned URL.

The deployed resources include:

- The Tigera Operator and its custom resource definitions.
- `Installation/default` for Calico networking and network policy.
- `APIServer/default` for the Calico API and healthy policy-tier status.

Goldmane flow aggregation and the Whisker observability interface were left out
of this phase. They are optional additions with their own resource and security
considerations, not requirements for cluster networking.

The Calico address pool is derived from kubeadm's live
`ClusterConfiguration`. No Atlas network value is stored in the repository.
The pool uses cross-subnet VXLAN encapsulation, outbound NAT, and automatic
selection of Kubernetes nodes.

References:

- [Calico system requirements](https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
- [Installing Calico on on-premises deployments](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises)
- [Calico installation API](https://docs.tigera.io/calico/latest/reference/installation/api)

## Pre-install Validation

The live control plane was inspected before mutation. Validation confirmed:

- The Kubernetes API was accessible through the owner-only operator kubeconfig.
- The node was `NotReady`, as expected before a CNI was installed.
- Both CoreDNS replicas were pending, as expected without pod networking.
- No Tigera Operator, Calico namespace, Calico CRDs, or Installation resource
  existed.
- kubeadm contained the reviewed current pod network and had assigned a node
  pod CIDR.
- The host had no active CNI configuration.

The CNI configuration directory contained only a zero-byte bootstrap marker.
It had no `.conf`, `.conflist`, or CNI kubeconfig and did not represent an
existing network provider.

Pinned upstream manifests were downloaded and hashed before installation. The
operator resource was also submitted through a server-side dry run before it
was created.

## Operator Installation

The Calico CRDs and Tigera Operator were created from the pinned 3.32.1 release.
The operator deployment reached full availability before Atlas created its
Installation resource.

The Installation resource was first validated with a server-side dry run. Its
pod network was read directly from the live kubeadm ConfigMap. The resource was
then created, allowing the operator to install Calico controllers, the node
agent, Typha, and the CNI node driver.

The Calico API server was added after the policy-tier status reported that it
was waiting for that component. This completed the standard Calico policy API
without enabling the optional observability stack.

## Transient Control-plane Latency

During the initial image-unpack and reconciliation burst, the Kubernetes API
temporarily failed its etcd readiness check. The scheduler and controller
manager restarted while etcd requests exceeded their normal latency budget.

The incident was investigated before any service was restarted. Evidence
showed:

- Substantial free memory and disk capacity remained.
- containerd and kubelet remained active.
- The kernel reported no storage-device, filesystem, or I/O errors.
- etcd reported multi-second request latency and a slow synchronous write.
- Calico and operator images were being downloaded and unpacked concurrently.

The control plane recovered without intervention after the write burst
subsided. API and etcd readiness then passed, and the static control-plane pods
returned to full readiness. This behavior is consistent with transient storage
latency on the control-plane system disk, not corruption or a Calico
configuration error.

Future heavyweight installations should be monitored for etcd write latency
and should avoid unnecessary parallel image operations on the control-plane
host.

## Functional Validation

Final platform checks confirmed:

- The Kubernetes API readiness endpoint passed every check, including etcd.
- The control-plane node became `Ready`.
- Calico, its API server, IP pools, and policy tiers all reported available,
  not progressing, and not degraded.
- The Calico node agent, controllers, Typha, API server, and CNI node driver
  were running.
- Both CoreDNS replicas were running.
- Calico wrote the host CNI configuration and kubeconfig with owner-only
  permissions.

Two temporary BusyBox pods performed the functional data-plane test. The test
pod resolved the Kubernetes service through cluster DNS and exchanged three
ICMP packets with a second pod without packet loss. Pod-scoped tolerations were
used for the test; the control-plane node taint was not removed or weakened.
Both temporary pods were deleted after validation.

Inter-node routing will be tested again after the three workers join the
cluster.

## Reusable Automation

The validated procedure is captured in `scripts/install-calico.sh`.

The script:

- Pins Calico to an exact release and verifies upstream manifest SHA-256
  checksums.
- Reads the pod network from kubeadm instead of accepting or persisting a
  private network value.
- Requires a healthy API, a single Atlas control plane, and cluster-admin
  authorization.
- Refuses existing or partial Calico state during installation.
- Supports `--preflight-only` for a fresh cluster without changes.
- Supports `--validate-only` for an installed cluster without changes.
- Uses polling instead of relying on a long-lived CRD watch while the API is
  under initial reconciliation load.
- Validates Tigera status, node readiness, CoreDNS, the installed Calico image
  version, host CNI files, and API readiness.

Local Bash syntax, option-refusal, mode-conflict, whitespace, and sensitive
value checks passed. The live `--validate-only` mode passed against the running
cluster. The normal installation mode also refused the existing installation
before downloading or creating resources.

ShellCheck was not installed on the management workstation and was not run.

## Security Boundaries

- No host address, pod-network CIDR, service-network CIDR, password, SSH key,
  token, certificate, or kubeconfig content is stored in Git.
- The operator kubeconfig remains on the control-plane node with owner-only
  permissions.
- Generated installation resources exist only in a temporary directory and
  are removed when the script exits.
- Test workloads are temporary and cleaned up after use.
- The control-plane scheduling taint remains in place.

## Current State

Atlas now has a healthy operator-managed Calico data plane on the control-plane
node. Kubernetes networking, service discovery, pod addressing, and pod-to-pod
traffic are operational.

## Next Steps

1. Join all three rebuilt worker nodes.
2. Confirm Calico node agents and CNI files on every worker.
3. Test DNS and pod traffic across nodes.
4. Complete the cluster-networking issue after inter-node validation.
5. Begin the Longhorn storage restoration phase.

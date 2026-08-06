# Atlas Worker Reconstitution

## Objective

Join all three rebuilt worker nodes to the Atlas Kubernetes control plane,
validate node-local Kubernetes and Calico state, and prove that DNS and pod
traffic work across physical nodes.

This phase restores the cluster's distributed compute capacity and completes
the multi-node acceptance criteria for cluster networking.

## Safety Boundaries

- Audit every worker before generating join credentials.
- Join one worker at a time and require full node readiness before continuing.
- Use a different short-lived kubeadm bootstrap token for each worker.
- Stream join data through encrypted SSH standard input without printing or
  writing it to disk.
- Revoke each worker token immediately after that node becomes `Ready`.
- Remove the older initialization token after all workers have joined.
- Keep token values, discovery hashes, node addresses, network ranges,
  certificates, and kubeconfig contents out of Git and Linear.

## Pre-join Audit

The control plane was healthy before worker mutation:

- The control-plane node was `Ready`.
- All Tigera status resources were available and not degraded.
- CoreDNS and the operator-managed Calico components were running.
- Only the control-plane node was registered.

Each worker passed the following checks:

| Check | Result |
|---|---|
| Existing kubelet credentials | Absent |
| Existing kubelet configuration | Absent |
| containerd | Active |
| kubeadm and kubelet | v1.35.7 and aligned |
| Swap | Disabled |
| SSH authentication | Key-based and non-interactive |

The previous node-foundation audit had already confirmed Ubuntu 24.04 LTS,
ARM64, systemd cgroups, required kernel modules, forwarding sysctls, and time
synchronization across the fleet.

## Secure Join Procedure

Workers were joined sequentially. For each worker, the management workstation:

1. Requested a new kubeadm join command with a fifteen-minute lifetime.
2. Kept the command only in shell process memory.
3. Extracted the token identifier only for cleanup tracking.
4. Streamed the join command to the selected worker through SSH standard input.
5. Added the explicit containerd CRI socket at execution time.
6. Waited until Kubernetes reported the node `Ready`.
7. Revoked the token and verified that it no longer existed.
8. Waited until that worker's Calico node agent was fully ready.

A cleanup trap revoked the active token if any join or readiness check failed.
No token or join command was displayed, written to a file, or added to project
tracking.

Kubeadm successfully completed preflight checks, wrote the worker kubelet
configuration, started kubelet, performed TLS bootstrap, and established the
secure node connection on all three workers.

## First-pull Behavior

Each newly joined worker initially appeared as `NotReady` while it downloaded
the Calico ARM64 images. The Calico node pod progressed through its flex-volume,
bootstrap, and CNI installation init containers before the node became ready.

The first pull took several minutes per worker. Events showed successful image
downloads and container starts. Memory, disk capacity, containerd, and kubelet
remained healthy, so no services were restarted.

After all workers joined, the unused bootstrap token created during control-
plane initialization was also revoked. The cluster ended the session with no
active kubeadm bootstrap tokens.

## Four-node Validation

Final infrastructure checks confirmed:

- `master`, `worker1`, `worker2`, and `worker3` are all `Ready`.
- All four nodes run Kubernetes v1.35.7.
- The Calico node daemon set is ready and available on all four nodes.
- The Calico CNI node driver is ready and available on all four nodes.
- kube-proxy is ready and available on all four nodes.
- All Tigera status resources are available and not degraded.
- Both CoreDNS replicas are available.
- Every worker has the Calico CNI configuration and kubeconfig with restrictive
  host permissions.

## Cross-node Network Validation

Three temporary BusyBox pods were pinned to different workers:

- A target pod on `worker1`.
- A checker pod on `worker2`.
- A checker pod on `worker3`.

Both checker pods resolved the Kubernetes service through cluster DNS. Each
then sent three ICMP packets to the target pod on `worker1`; every packet was
returned successfully. This validated Calico routing from two independent
workers to a workload on a third worker.

Pod placement was verified before results were accepted. All temporary test
pods were deleted synchronously afterward.

## Reusable Worker Automation

The worker-side procedure is captured in `scripts/join-worker.sh`.

The script:

- Supports `--preflight-only` for a fresh worker without changes.
- Supports `--validate-only` for an already joined worker without changes.
- Requires Ubuntu 24.04 LTS, ARM64, aligned kubeadm and kubelet versions,
  containerd, systemd cgroups, disabled swap, required modules, and forwarding
  sysctls.
- Refuses existing kubelet or CNI state.
- Accepts join data only through standard input.
- Validates the API endpoint, bootstrap-token format, and CA discovery-hash
  format.
- Accepts only the token and CA discovery-hash options emitted by the approved
  kubeadm workflow; all other join options and positional arguments are
  rejected.
- Parses join arguments into a Bash array and executes kubeadm directly without
  `eval`.
- Clears sensitive shell variables after kubeadm returns.
- Waits for local kubelet and Calico CNI state before declaring success.

Bash syntax, option-refusal, contradictory-mode, existing-state, whitespace,
and sensitive-value checks passed. Live `--validate-only` checks passed on all
three workers.

Token creation, remote node-readiness validation, and token revocation remain
the responsibility of the control-plane orchestration layer. The worker script
reminds the operator to revoke the token immediately after a successful join.

ShellCheck was not installed on the management workstation and was not run.

## Current State

Atlas is again a healthy four-node Kubernetes cluster with one control-plane
node and three worker nodes. Control-plane services, Calico, CoreDNS, kube-
proxy, node registration, cluster DNS, and cross-worker pod traffic are
operational.

## Next Steps

1. Verify the external storage devices and stable device identifiers without
   mounting or formatting them.
2. Prepare the Longhorn storage paths on the selected workers.
3. Install Longhorn through a pinned, documented deployment method.
4. Validate replicas, volumes, persistence, and node-failure behavior.

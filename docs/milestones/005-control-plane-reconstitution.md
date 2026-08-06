# Milestone 005 — Control Plane Reconstitution

## Capability Added

Atlas now has a newly initialized Kubernetes v1.35.7 control plane running on
the supported Ubuntu 24.04 LTS foundation established in Milestone 004.

This milestone restored the Kubernetes API and core control-plane services
without reusing stale cluster state or exposing sensitive bootstrap material in
the repository.

## Why It Matters

The platform modernization produced four consistent Kubernetes-capable hosts,
but not a functioning cluster. Control-plane initialization is the point where
that host foundation becomes an operational Kubernetes platform.

Validating the control plane independently also isolates kubeadm, containerd,
kubelet, certificates, and etcd from the separate variables introduced by the
CNI and worker joins.

## Safety Boundaries

- Live node state was audited before initialization.
- Passwords, SSH private keys, bootstrap tokens, certificates, kubeconfig
  contents, internal addresses, and network ranges were kept out of Git.
- External storage remained disconnected and out of scope.
- The manual procedure was validated before being converted into reusable
  automation.

## Implementation

Before making changes, all four rebuilt hosts were checked for consistent OS,
Kubernetes tooling, container runtime, kernel, swap, time synchronization, and
network configuration. The audit also confirmed that no prior control-plane,
worker-join, or etcd state remained.

The control plane was then initialized on `master` with kubeadm. Kubeadm:

- Completed its preflight checks
- Pulled the required ARM64 control-plane images
- Generated the control-plane configuration and certificates
- Created the local etcd datastore
- Registered the control-plane node

Operator access was configured locally on the control-plane host. The generated
kubeconfig remains there with owner-only permissions.

## Validation

The following checks passed after initialization:

- Kubernetes API readiness
- etcd health and readiness
- API server, controller manager, scheduler, and etcd static pods running
- Control-plane node registered at Kubernetes v1.35.7
- No sensitive cluster bootstrap material captured in project artifacts

The control-plane node was `NotReady`, and CoreDNS remained pending, because a
CNI had not yet been installed. That was the correct and expected boundary for
this milestone—not a control-plane initialization failure.

## Lessons Learned

- Verify the management workstation's network path before treating several
  unreachable nodes as infrastructure failures.
- A restarting kubelet is expected before kubeadm creates its configuration;
  service state must be interpreted in context.
- Slow image pulls should be checked through container-runtime evidence before
  interrupting kubeadm.
- Validating the control plane before adding networking and workers makes
  failures easier to isolate.
- Security-sensitive bootstrap material belongs on the infrastructure, not in
  public documentation or issue tracking.

## Artifacts

- [`logbook/2026-08-05-cluster-reconstitution.md`](../../logbook/2026-08-05-cluster-reconstitution.md)

## Next Milestone

Install and validate Calico, join all three worker nodes, and verify that the
four-node Kubernetes cluster reaches a healthy operational state. External
storage and Longhorn remain a later, separately validated capability.

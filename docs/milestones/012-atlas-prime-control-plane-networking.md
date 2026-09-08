# Milestone 012 — Atlas Prime Control Plane and Networking

Status: **Complete**

Atlas Prime has crossed the boundary from commissioned hardware to a working
Kubernetes control plane. Its API, local datastore, container runtime, node
agent, cluster network, and cluster DNS now form a healthy standalone system.

## What changed

- The control plane was initialized from one validated configuration.
- Its stable API name was included in the serving certificate before the
  cluster was created.
- The datastore and container runtime use their dedicated filesystems.
- The pinned Calico release was installed through its operator.
- Atlas Prime transitioned from its expected pre-network `NotReady` state to
  `Ready`.
- Temporary pods proved local routing and cluster DNS, then were removed.

The legacy Pi cluster remained healthy and separate throughout construction.
No worker was moved merely to make the topology look finished.

## Failure preserved: the first real worker canary

The first ARM64 worker canary successfully drained from the legacy cluster,
joined Atlas Prime, became Ready, and passed cross-machine pod routing. The
public DNS acceptance test then failed with a deliberate refusal.

The fault was not the worker or the network overlay. An end-to-end DNS
dependency was missing from the accepted foundational policy. The prepared
transaction restored the worker to the legacy cluster and stopped before any
second worker moved.

This is precisely why Atlas uses canaries. A node being `Ready` is necessary,
but it is not enough: real service paths must also work before migration can
expand.

## Resolution and handoff

The policy was corrected privately and validated independently with a pinned
DNS client before migration resumed. The worker canary later passed the
complete functional suite, enabling sequential expansion and eventual
retirement of the legacy control plane. The full migration outcome continues in
[Milestone 013](013-canary-gated-worker-migration.md).

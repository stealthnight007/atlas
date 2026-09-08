# Milestone 008 — Architecture Pivot and Atlas Prime Commissioning

Status: **Complete**

## Capability Added

Atlas now has a commissioned AMD64 system that can become the next Kubernetes
control-plane foundation while the existing Raspberry Pi cluster remains
operational and recoverable.

## Why the Architecture Changed

The recovered Pi cluster was healthy, but preparing Longhorn exposed a more
important constraint: replicated storage cannot compensate for a weak storage
medium. Historical etcd latency and microSD performance made a Pi-only control
plane a poor foundation for the platform Atlas was becoming.

The response was not to discard the working cluster immediately. Atlas instead adopted a
staged migration model:

- keep the Pi control plane as the protected rollback authority;
- commission a substantially stronger AMD64 host beside it;
- validate each prerequisite independently;
- move control-plane responsibility only after the successor passes its gates.

This separates platform evolution from an all-at-once rebuild.

## Commissioning Boundary

Commissioning established a supported Ubuntu LTS baseline, stable networking,
time synchronization, disabled swap, remote observability, and clean reboot
recovery. Kubernetes, containerd, and Longhorn were intentionally excluded.

Foundational DNS was established outside Kubernetes before the host became a
control plane. This made it possible to validate bootstrap name resolution
without coupling it to an unfinished cluster.

## Outcome

At this milestone boundary, Atlas had two deliberately different states:

- a stable ARM64 Kubernetes cluster that continues to serve as the recovery
  point; and
- a validated AMD64 foundation being prepared for future control-plane duty.

The mixed architecture is intentional. Bootstrap logic, images, DaemonSets,
and workload placement must now be validated for both ARM64 and AMD64.

The later migration completed this plan: Atlas Prime became the sole control
plane and the former Pi control-plane host was repurposed as a worker.

## Related Decisions

- [Decision 002 — Heterogeneous Control-Plane Migration](../decisions/002-heterogeneous-control-plane-migration.md)
- [Decision 005 — Dedicated Control-Plane Storage](../decisions/005-dedicated-control-plane-storage.md)

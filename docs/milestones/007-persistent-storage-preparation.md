# Milestone 007 — Persistent Storage Preparation

Status: **Complete historical milestone; design later superseded**

## Capability Added

Atlas proved that removable storage could be identified durably, mounted with
stable filesystem semantics, and validated across a node reboot without relying
on kernel-assigned device names.

The experiment prepared storage on a worker first and then on the legacy
control-plane host. Longhorn itself was not installed in this milestone.

## Canary-First Rollout

The worker was the canary:

1. Identify the intended filesystem without modifying it.
2. Validate filesystem type, emptiness, and mount safety.
3. Add one persistent mount definition with a captured rollback.
4. Reboot the worker and require host and Kubernetes recovery.
5. Repeat on the control-plane host only after the canary passed.

This sequencing limited the first failure domain and proved that persistence
meant more than “the mount works right now.”

## Safety Boundaries

The implementation rejected missing or ambiguous devices, conflicting mounts,
unexpected data, and unsupported hosts. It did not format, wipe, repartition,
install Longhorn, or mutate Kubernetes resources. Detailed device identifiers,
host mappings, paths, mount records, and rollback commands remain in the
private operations repository.

## What We Learned Later

Successful mounting did not make the storage architecture correct. Subsequent
performance evidence showed that the original microSD-centered Pi foundation
was not suitable for the latency and endurance demands of the platform Atlas
was becoming. The Longhorn experiment was abandoned, its empty configuration
was removed during migration, and the physical disks were retained without
being silently adopted by the new cluster.

This milestone remains complete because it produced a valid capability and an
important result: durable device handling was proven, while the proposed
distributed-storage architecture was rejected by evidence.

## Next Step

Milestone 014 will begin a fresh persistent-storage architecture from workload,
failure-domain, backup, and recovery requirements. It remains intentionally
paused at the v1 boundary.

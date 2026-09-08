# Decision 005 — Dedicated Control-Plane Storage

## Status

Accepted and implemented.

## Context

The future control plane has one internal NVMe device with substantial unused
capacity. etcd and containerd have different operational roles from the root
filesystem and from future replicated workload storage.

## Decision

Retain the existing root volume, create dedicated ext4 logical volumes for the
Kubernetes datastore and container runtime, mount them by stable filesystem
identity with latency-conscious options, and leave substantial capacity
unallocated.

The internal NVMe remains excluded from Longhorn. Logical volumes provide
capacity, path, and filesystem isolation but are not represented as independent
physical failure domains.

## Consequences

- etcd and container-runtime growth cannot silently consume the root
  filesystem's allocation.
- The mounts survive device-name changes and reboot through stable filesystem
  identity.
- Unallocated capacity remains available for decisions based on observed
  workloads instead of forecasts.
- A single-device failure still affects root, etcd, and containerd; backups and
  control-plane recovery remain necessary.

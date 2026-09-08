# Milestone 011 — Atlas Prime Storage Foundation

Status: **Complete**

## Capability Added

Atlas Prime now has dedicated, reboot-persistent filesystems for the future
Kubernetes datastore and container runtime.

## Validation Before Allocation

The internal NVMe device was inventoried before any layout change. Read-only
health data showed no media or integrity errors, no critical warnings, and no
recorded error entries. A complete non-destructive read of the device finished
without I/O, filesystem, thermal, or controller errors, and health indicators
remained clean afterward.

The evidence also preserved historical observations rather than deleting
them: lifetime unsafe-shutdown events and one unrelated correctable PCIe event
were recorded, investigated, and left available for future comparison.

## Storage Layout

The approved layout keeps the existing operating-system volume unchanged and
adds:

| Purpose | Approximate size | Filesystem |
|---|---:|---|
| Kubernetes datastore | 32 GiB | ext4 |
| container runtime | 256 GiB | ext4 |

Both mounts use stable filesystem identity and latency-conscious mount options.
Approximately 540 GiB remains
deliberately unallocated for later evidence-based decisions.

This design provides capacity and path isolation, not a separate physical
failure domain: both logical volumes share one NVMe device. The internal device
also remains excluded from Longhorn so control-plane state and future
distributed workload storage are not casually mixed.

## Staged Implementation

The gate captured the disk, LVM, filesystem, mount, and system baseline before
mutation. It then created only the two approved logical volumes, formatted only
those new volumes, added only their stable mount entries, and validated the
remaining free capacity.

A controlled reboot proved that both filesystems passed startup checks and
mounted with the expected options. Networking, time, DNS, remote automation,
system health, and the existing Kubernetes cluster all remained healthy.

## Outcome

The physical storage foundation for the new control plane is ready. No
container runtime or Kubernetes package was installed, no control plane was
initialized, and the retained Pi cluster was not changed.

## Related Decision

- [Decision 005 — Dedicated Control-Plane Storage](../decisions/005-dedicated-control-plane-storage.md)

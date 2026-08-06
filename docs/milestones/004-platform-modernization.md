# Milestone 004 — Platform Modernization

## Capability Added

Atlas now has a supported, consistent, and reproducible operating-system and
Kubernetes host foundation across all four Raspberry Pi nodes.

This milestone replaced the unsupported Ubuntu 22.10 environment with Ubuntu
24.04.4 LTS and converted the manual host preparation process into a reusable
bootstrap workflow.

## Why It Matters

The original Atlas cluster was running an end-of-life operating system. Its
obsolete repositories and unsupported packages made maintenance increasingly
fragile and would have made every later platform capability harder to operate.

Rebuilding the hosts before restoring Kubernetes removed that inherited risk
and established a known baseline for the next version of the platform.

## Engineering Decisions

- Rebuild every node instead of continuing to patch an unsupported release.
- Standardize all nodes on Ubuntu 24.04.4 LTS and ARM64 Kubernetes packages.
- Pin Kubernetes tooling consistently at v1.35.7.
- Use containerd with systemd cgroups.
- Preserve external storage and leave it disconnected during the host rebuild.
- Automate repeatable host preparation while validating each node independently.

The reasoning behind the modernization is recorded in
[`docs/decisions/001-platform-modernization.md`](../decisions/001-platform-modernization.md).

## Implementation

The reusable [`scripts/bootstrap-node.sh`](../../scripts/bootstrap-node.sh)
workflow configures the common Kubernetes prerequisites on a clean Ubuntu host,
including:

- Required kernel modules and networking sysctls
- Swap disablement
- containerd installation and systemd cgroup configuration
- Kubernetes package installation and version holds
- iSCSI support for the future Longhorn storage phase

The process was run and validated independently on `master`, `worker1`,
`worker2`, and `worker3`.

## Validation

All four hosts passed the operating-system and tooling bootstrap with the same
baseline:

| Check | Result |
|---|---|
| Operating system | Ubuntu 24.04.4 LTS |
| Architecture | ARM64 |
| Kubernetes tooling | v1.35.7 on every node |
| Container runtime | containerd active and enabled |
| Cgroup configuration | systemd cgroups enabled |
| Swap | Disabled |
| Kubernetes packages | Held at the selected version |
| Longhorn prerequisite | iSCSI active and enabled |

At the end of this milestone, “ready” meant that each host had passed the OS
and tooling bootstrap. Kubernetes had not yet been initialized, so the four
systems were not yet Kubernetes nodes reporting `Ready` through `kubectl`.

## Lessons Learned

- A supported base platform is a prerequisite for reliable higher-level
  automation.
- Rebuilding one node first provides a safe proving ground for a reusable
  bootstrap process.
- Identical versioning and runtime configuration reduce cluster-wide drift.
- Storage preservation needs an explicit boundary during infrastructure
  rebuilds; the external Seagate and LaCie devices were not formatted or
  modified.

## Artifacts

- [`scripts/bootstrap-node.sh`](../../scripts/bootstrap-node.sh)
- [`docs/decisions/001-platform-modernization.md`](../decisions/001-platform-modernization.md)
- [`logbook/2026-08-03-platform-rebuild.md`](../../logbook/2026-08-03-platform-rebuild.md)

## Next Milestone

Reconstitute the Kubernetes control plane on the modernized host foundation,
then validate the API server, etcd, scheduler, and controller manager before
introducing cluster networking or worker nodes.

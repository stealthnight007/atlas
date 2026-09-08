# Milestone 004 — Platform Modernization

Status: **Complete**

## Capability added

All four Raspberry Pi hosts moved from an end-of-life operating system to a
supported Ubuntu LTS baseline with consistent Kubernetes tooling, containerd,
systemd cgroups, and persistent swap policy.

## Why the architecture changed

The recovered cluster was healthy, but its unsupported repositories made
future maintenance fragile. Team Atlas chose a deliberate rebuild rather than
stacking new capabilities on a foundation that could no longer receive normal
updates.

One host acted as the canary. The same private bootstrap and validation model
was then applied across the remaining fleet while external storage stayed
disconnected and preserved.

## Lessons

- Operational health does not make an unsupported platform sustainable.
- A repeatable host baseline reduces drift before cluster state is introduced.
- Preserved storage needs an explicit boundary during rebuilds.
- Architecture automation belongs in the private operations repository; the
  public record preserves decisions and outcomes.

## Outcome

The Pi fleet became a supported and reproducible foundation for control-plane
reconstitution. See [Decision 001](../decisions/001-platform-modernization.md)
and the [migration-era journal](../journal/atlas-prime-migration-era.md).


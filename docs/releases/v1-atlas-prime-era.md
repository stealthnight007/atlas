# Project Atlas v1 — Atlas Prime Migration Era

Release: `v1.0.0-atlas-prime-era`

Project Atlas v1 closes the transition from a recovered Pi-only Kubernetes lab
to one heterogeneous personal-infrastructure platform with an AMD64 control
plane and four ARM64 workers.

## Highlights

- Recovered and modernized the original Pi platform before replacing it.
- Used storage latency and endurance evidence to drive an architecture change.
- Commissioned Atlas Prime as a stronger control-plane foundation.
- Established foundational DNS outside Kubernetes and corrected a router-proxy
  forwarding loop through canary rollback.
- Added a dedicated, attributable automation identity while keeping approval
  human-owned.
- Validated NVMe health and created dedicated etcd/containerd filesystems while
  retaining unallocated capacity.
- Generalized bootstrap and preflight logic for AMD64 and ARM64.
- Installed Kubernetes, initialized the new control plane, deployed Calico, and
  made Atlas Prime Ready.
- Corrected a missing end-to-end DNS dependency and replaced ambiguous
  validation with a pinned DNS client.
- Migrated workers through canary, rollback, scheduler-aware, and autoscaler-
  aware gates.
- Switched deliberately from learning mode to rollout mode once the migration
  path was repeatable and remaining experiments were declared disposable.
- Retired the legacy Pi control plane irreversibly and reused its host as the
  fourth worker without formatting its preserved external disk.
- Proved a dependency-ordered shutdown and cold start, corrected a durable
  worker-identity defect exposed by reboot, and restored all five nodes.
- Added a dedicated human Kubernetes identity so Ruben can inspect the current
  platform independently of the automation identity.

## What the failures taught

- A successful private DNS answer does not prove public recursion.
- A Ready node does not prove application-level routing and DNS.
- A verifier can be wrong while infrastructure is healthy.
- Scheduler placement and autoscaler targets are state, not constants.
- Rollback evidence must be owned, unique, and created before mutation.
- Canary rigor creates knowledge, but repeating it forever can become its own
  risk and delivery cost.
- Software recovery cannot compensate for a host that stays powered off after
  AC returns.
- A live hostname change is incomplete until every persistent identity source
  has survived a cold start.
- Management-workstation overrides can cross network boundaries even when the
  infrastructure itself is behaving correctly.

## Current boundary

Persistent-storage design will restart from workload, failure-domain, backup,
and recovery requirements. The earlier Longhorn work is historical evidence,
not the architecture being carried forward. Automatic power-on after AC
restoration also remains an accepted requirement awaiting an attended firmware
and physical-power test. Resource metrics are not yet installed on the new
cluster and remain future platform work.

## Next chapter

Atlas will use this foundation for deliberate persistent storage, network
services, observability, application delivery, websites and personal projects,
demo environments, edge services, hybrid-cloud integration, and future AI/model
workloads.

See the [migration-era journal](../journal/atlas-prime-migration-era.md),
[architecture diagrams](../architecture/migration-era-diagrams.md), and
[milestone 013](../milestones/013-canary-gated-worker-migration.md).

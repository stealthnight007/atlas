# Project Atlas

> A human-led, AI-assisted personal infrastructure and mini-datacenter platform.

Atlas is a long-term engineering project for building, operating, breaking,
recovering, automating, and documenting real infrastructure. Kubernetes is its
current orchestration substrate—not the project’s endpoint.

The platform is intended to grow into a home for persistent storage,
applications and microservices, network services, observability, websites and
personal projects, interview/demo environments, edge services, hybrid-cloud
integration, load balancing, and future AI/model workloads.

## Current architecture

Atlas now runs one heterogeneous Kubernetes cluster:

- one AMD64 control plane on Atlas Prime;
- four ARM64 Raspberry Pi workers;
- containerd and Calico networking;
- cluster DNS plus foundational DNS that remains independent of Kubernetes;
- dedicated control-plane filesystems for etcd and containerd; and
- a management workstation that operates approved gates and preserves evidence.

The original Pi control plane was intentionally retired after every worker had
migrated and the replacement cluster had proved independent health. External
worker disks were preserved without inheriting the abandoned storage
experiment. Fresh persistent-storage design will begin as a new architecture,
driven by workload, failure-domain, backup, and recovery requirements.

See the [sanitized migration-era diagrams](docs/architecture/migration-era-diagrams.md).

## The Atlas Prime migration era

Atlas began as a Pi-only Kubernetes lab. Recovering that platform taught the
interactions among Linux, containerd, kubelet, etcd, Calico, metrics, and
storage. Longhorn preparation then exposed a deeper limitation: replicated
software cannot turn latency-sensitive microSD media into the foundation the
next platform needed.

Atlas Prime introduced stronger AMD64 compute and NVMe storage without
discarding the working Pi cluster. The successor was built in bounded gates:

1. Commission the host and prove reboot recovery.
2. Establish foundational DNS and correct a router-proxy forwarding loop.
3. Create an auditable automation path.
4. Validate NVMe health and allocate dedicated etcd/containerd filesystems.
5. Generalize bootstrap logic for AMD64 and ARM64.
6. Install the container runtime and Kubernetes foundation.
7. Initialize the control plane from one validated configuration.
8. Install Calico and make Atlas Prime Ready.
9. Use one worker as a reversible migration canary.
10. Expand sequentially, then transition from learning mode to rollout mode.
11. Retire the legacy control plane and reuse its host as the fourth worker.
12. Shut the environment down cleanly, cold-start it, correct the persistence
    defects exposed by reboot, and give the human operator independent access.

Failures remain part of the record. DHCP/DNS cutover rolled back when public
resolution exposed a circular dependency. A worker canary rolled back when an
end-to-end DNS dependency was missing from the accepted policy. Several stops
proved that validators can be wrong even when infrastructure is healthy:
limited test clients, resolver ambiguity, scheduler placement, command
identity, evidence paths, Metrics Server movement, and Typha autoscaling all
needed explicit treatment.

The resulting principle is simple: validators and rollback automation are part
of the production system. Test them with the same skepticism as the change.

The migration era closed with a cold-start recovery test. The foundational
services, Kubernetes control plane, and four-worker fleet came
back without rebuilding the platform. The test did expose one valuable defect:
the former control-plane Pi's live rename had not updated every durable
cloud-init identity source. That worker returned under its historical name,
and Kubernetes correctly rejected the identity mismatch. The persistent source
was corrected, rebooted, and proved before the five-node recovery was accepted.

The same recovery also disproved an early network hypothesis. The independent
wireless network and router configuration were healthy; a management-workstation
DNS override was crossing network boundaries. Returning the workstation to
DHCP-derived DNS restored the intended separation without changing the network.

## Team Atlas

Atlas is neither a solo implementation story nor an autonomous AI project.

- **Ruben** is the architecture/product owner and operator. He sets the vision,
  chooses and controls the physical infrastructure, approves architecture and
  execution gates, decides what must be preserved, and steers priorities and
  tradeoffs.
- **ChatGPT** is the architecture, platform-strategy, and review partner. It
  helps translate goals into designs, reason through tradeoffs, define gates
  and operating policy, explain behavior, and keep the platform aligned with
  the long-term vision.
- **Codex** is the infrastructure and automation engineering arm. It implements
  scripts and configuration, executes approved operations, builds validators
  and rollback paths, collects evidence, and maintains durable checkpoints.

Human authorization and physical control remain explicit. AI assistance adds
implementation speed, structured review, and operational evidence; it does not
replace ownership.

## Current capabilities

- ✅ Supported Ubuntu host baseline
- ✅ Kubernetes v1.35 heterogeneous control plane and worker fleet
- ✅ Independent foundational DNS with safe client cutover
- ✅ Dedicated and attributable infrastructure automation
- ✅ Reboot-proven network and time policy
- ✅ Validated NVMe and dedicated etcd/containerd storage
- ✅ Architecture-aware AMD64/ARM64 bootstrap
- ✅ Canonical control-plane initialization and certificate endpoint
- ✅ Calico pod networking and cluster DNS
- ✅ Canary-tested worker migration with automatic rollback
- ✅ Complete retirement of the legacy Pi control plane
- ✅ Five-node cold-start recovery and worker identity persistence
- ✅ Separate human operator and automation access paths
- ℹ️ Historical resource-metrics milestone retained; Metrics Server is not yet
  installed on the new cluster
- ⏸️ Fresh persistent-storage design, intentionally paused for review

## Milestones

| Status | Milestone |
|---|---|
| ✅ | [001 — Lab Discovery](docs/milestones/001-lab-discovery.md) |
| ✅ | [002 — Kubernetes Foundation](docs/milestones/002-kubernetes-foundation.md) |
| ✅ | [003 — Resource Metrics](docs/milestones/003-resource-metrics.md) |
| ✅ | [004 — Platform Modernization](docs/milestones/004-platform-modernization.md) |
| ✅ | [005 — Control Plane Reconstitution](docs/milestones/005-control-plane-reconstitution.md) |
| ✅ | [006 — Cluster Networking and Worker Rejoin](docs/milestones/006-cluster-networking-and-worker-rejoin.md) |
| ✅ | [007 — Persistent Storage Preparation](docs/milestones/007-persistent-storage-preparation.md) |
| ✅ | [008 — Architecture Pivot and Atlas Prime Commissioning](docs/milestones/008-atlas-prime-commissioning.md) |
| ✅ | [009 — Independent DNS and Safe Client Cutover](docs/milestones/009-independent-dns-cutover.md) |
| ✅ | [010 — Safe Automation and Worker Hardening](docs/milestones/010-safe-automation-and-worker-hardening.md) |
| ✅ | [011 — Atlas Prime Storage Foundation](docs/milestones/011-atlas-prime-storage-foundation.md) |
| ✅ | [012 — Atlas Prime Control Plane and Networking](docs/milestones/012-atlas-prime-control-plane-networking.md) |
| ✅ | [013 — Canary-Gated Worker and Control-Plane Migration](docs/milestones/013-canary-gated-worker-migration.md) |
| ⏸️ | 014 — Fresh Persistent-Storage Architecture |
| ⏳ | 015 — Load Balancing and Ingress |
| ⏳ | 016 — GitOps, Observability, and Platform Applications |

Milestones 001–007 describe recovery and modernization of the original Pi
platform. Milestones 008–013 form the Atlas Prime migration era. Their existing
numbers are chronological and deliberately retained.

## Engineering records

- [Architecture decisions](docs/decisions/)
- [Build and migration journal](docs/journal/atlas-prime-migration-era.md)
- [Migration-era architecture](docs/architecture/migration-era-diagrams.md)
- [v1 migration-era release notes](docs/releases/v1-atlas-prime-era.md)
- [Publication boundary and security policy](SECURITY.md)

## Engineering philosophy

- Understand systems before changing them.
- Build one capability at a time.
- Preserve failures and recoveries, not just final screenshots.
- Use fresh preflight, bounded mutation, acceptance checks, and rollback.
- Distinguish infrastructure failure from verifier failure.
- Protect valuable state; classify disposable experiments honestly.
- Automate repetitive work while keeping authorization human-owned.
- Leave capacity and architectural choices open until evidence justifies them.

## Roadmap

The control-plane migration is complete. The next platform chapter begins only
after a fresh storage design is approved.

- Persistent storage and recovery
- Network services, including a deliberately redesigned DNS-filtering service
- Load balancing and ingress
- GitOps and deployment workflows
- Metrics, logs, traces, and alerting
- Applications, microservices, websites, and demo environments
- Edge delivery and hybrid-cloud integration
- Future AI/model workloads
- Additional compute and storage expansion

Public material is intentionally sanitized. Live addresses, credentials,
authorization policy, device identifiers, recovery procedures, and raw
operational evidence remain private.

> **Build. Break. Learn. Recover. Improve.**

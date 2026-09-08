# Milestone 013 — Canary-Gated Worker and Control-Plane Migration

Status: **Complete — heterogeneous cluster consolidated on Atlas Prime**

After a sequence of reversible trials, the ARM64 canary completed the full
migration path. The remaining workers then crossed through the hardened
process, the legacy control plane was retired, and its host became the fourth
worker in the new heterogeneous cluster.

## Why the first crossing took time

The migration mechanics worked before the overall gate passed. Earlier trials
successfully drained the worker, changed its cluster membership, joined the new
control plane, and proved cross-machine pod routing. Acceptance still stopped
when independent checks exposed gaps around resolver policy and assumptions in
the validation harness.

Each failed trial returned the worker to the legacy cluster before another
node moved. The fixes were deliberately narrow:

- correct the missing foundational DNS dependency;
- replace a limited DNS test client with a pinned, purpose-built client;
- separate foundational DNS tests from Kubernetes service-discovery tests;
- replace a capability-dependent network probe with unprivileged HTTP; and
- use a fully qualified Kubernetes Service name for explicit DNS testing.

The history matters. The infrastructure was not declared healthy merely
because a node reported `Ready`, and the validators were not treated as
infallible merely because they returned an error.

## Accepted result

The accepted canary passed:

- ARM64 join to the AMD64-hosted control plane;
- Calico, CSI, and node-proxy convergence;
- direct cross-node pod routing without Service translation;
- separate ClusterIP Service connectivity;
- fully qualified Kubernetes Service discovery;
- authoritative and public DNS over UDP and TCP;
- external HTTPS connectivity; and
- host, new-cluster, and reduced legacy-cluster health checks.

Temporary credentials and validation workloads were removed. The canary was
left on Atlas Prime, while the legacy control plane and remaining workers stayed
healthy and available for rollback.

## Engineering lesson

A migration bridge is not proven when a node can cross it once. It is proven
when the node can cross, exercise real traffic, remain healthy, and leave both
sides in a known recoverable state. Atlas now has that evidence for one worker.

Expansion remains sequential. Each additional worker is reconciled against
the proven canary first, and any material host or storage difference creates a
new review boundary rather than being normalized away.

## First sequential expansion

The second ARM64 migration also preserved its failed attempts instead of
hiding them. The node drained safely more than once, while validators initially
misread valid scheduler placement, command identity, evidence ownership, and
autoscaler behavior. Every attempt stopped before irreversible progress or
returned the node to the legacy cluster.

The accepted transaction classified allowed workloads rather than assuming a
fixed placement, validated the network component against its autoscaler's
declared replica target after drain, and used a fresh evidence path without
overwriting prior runs. The node then completed reset, join, cross-node routing,
Service, DNS, HTTPS, host-health, and both-cluster checks.

## From canary mode to rollout mode

Canary rigor has diminishing returns. The first two workers were intentionally
used to discover scheduler behavior, resolver boundaries, credential handling,
rollback gaps, and false assumptions in the validation harness. Once those
paths were repeatable, continuing to preserve explicitly disposable lab state
would have added ceremony without reducing meaningful risk.

Atlas therefore changed modes. The remaining worker used the same hardened
reset, join, networking, service, DNS, and health checks, but discarded an old
test workload and empty storage remnants instead of designing a migration for
them. It joined successfully, leaving the new heterogeneous cluster with its
AMD64 control plane and all three original ARM64 workers.

The broader lesson is not to abandon rigor. It is to concentrate rigor where
it still buys information: protect valuable data, identity, networking, and
recovery access; classify known experiments honestly; then let proven rollout
automation finish the repetitive work.

## Retiring the old control plane

After the last original worker crossed, the old control plane stood alone with
no required application or storage state. Its retirement was treated as an
explicit architectural boundary: verify the replacement cluster independently,
declare the old state disposable, preserve the reusable host and physical disk,
and acknowledge that destroying the old datastore ends the normal rollback
path.

The host was then rebuilt in place as another ARM64 worker. Its address,
operating system, network policy, clock policy, and container runtime survived;
its control-plane identity did not. The physical storage device was retained
without formatting so the later storage architecture can make a deliberate
choice rather than inherit an experiment.

Atlas now runs one heterogeneous Kubernetes cluster: an AMD64 control plane and
four ARM64 workers. The legacy cluster is gone by design.

## Closing the era with a cold start

The migration was not considered complete at “five nodes Ready.” Team Atlas
shut the environment down in dependency order, preserved the final checkpoint,
and later started it from a cold state with the control plane first.

The control-plane host, foundational DNS, dedicated filesystems, API, datastore,
cluster network, and three workers recovered normally. The former Pi control
plane did not: it booted with its historical hostname even though its Kubernetes
credential correctly represented the new worker identity. Kubernetes rejected
the mismatch instead of silently accepting two identities.

The defect was in persistence, not migration membership. A live rename had not
reached every durable cloud-init source. The source and cached state were
reconciled, the worker was rebooted again, and recovery was accepted only when
its operating-system identity, Node Lease, network components, and Kubernetes
Ready state agreed. No reset or rejoin was needed.

The same recovery disproved an early DNS hypothesis. The independent wireless
network and router configuration were still correct; the management workstation
carried a manual resolver override across wireless networks. Returning that
workstation to DHCP-derived DNS restored the intended network separation.

## Returning operations to the human

Automation made the migration repeatable, but Atlas is not intended to become
a black box. After cold-start recovery passed, the human operator received a
dedicated Kubernetes client identity and a single current-cluster context,
separate from the infrastructure automation identity.

Direct human inspection then proved nodes, Pods, namespaces, Services, events,
cluster information, and API readiness. Resource-metrics commands remain
unavailable because Metrics Server has not yet been installed on the new
cluster. The earlier metrics milestone remains part of the history; restoring
telemetry is future platform work rather than a hidden migration dependency.

The final v1 result is therefore stronger than a successful migration: Atlas
can be shut down, cold-started, inspected by its owner, and understood without
using the automation identity.

## Resilience debt carried forward

The migration also preserved one physical-infrastructure lesson. During a power
interruption, the worker class restarted automatically but the control-plane
class did not. After manual startup, the platform recovered normally. It still
requires an
attended firmware and physical-power test proving automatic startup after AC
restoration.

## Related decisions

- [Decision 002 — Heterogeneous Control-Plane Migration](../decisions/002-heterogeneous-control-plane-migration.md)
- [Decision 006 — Transition from Canary Learning to Rollout](../decisions/006-canary-to-rollout-transition.md)
- [Decision 007 — Automatic Power Recovery Is a Platform Requirement](../decisions/007-power-recovery-requirement.md)
- [Decision 008 — Separate Human and Automation Operator Identities](../decisions/008-human-and-automation-operator-identities.md)

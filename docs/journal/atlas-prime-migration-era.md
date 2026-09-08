# Atlas Prime Migration: From Architecture Pivot to One Cluster

## Why this chapter exists

Atlas reached the end of a distinct engineering era: a recovered Raspberry Pi
cluster gave way to a stronger heterogeneous platform without an all-at-once
rebuild. This entry preserves the sequence, including the failures that changed
the architecture and the validators that had to learn alongside it.

## The Pi cluster was the right place to begin

The original Pi-only cluster was not a mistake. It created a real environment
for learning host recovery, container runtimes, kubelet behavior, Calico,
metrics, etcd, and persistent-storage preparation. Restoring it before replacing
it produced evidence that a green node list alone cannot provide.

That work also exposed the platform’s limits. Longhorn preparation and earlier
datastore latency showed that replicated storage software could not remove the
performance and endurance characteristics of microSD media. The storage problem
became an architecture problem.

## Atlas Prime changed the direction

Atlas Prime was introduced as an AMD64 system with substantially stronger
compute, networking, and NVMe storage. The Pi cluster remained operational as a
protected recovery authority while its successor was built gate by gate.

Commissioning proved the operating system, network, time, swap policy, remote
access, system health, and reboot recovery before Kubernetes was installed.
Read-only NVMe inventory and a full non-destructive read established a storage
health baseline. Dedicated ext4 logical volumes were then created for etcd and
containerd, while the root allocation stayed unchanged and substantial capacity
was deliberately left unallocated.

Logical separation did not become a fictional failure domain. The records make
clear that root, etcd, and containerd still share one physical device, and that
the internal device is excluded from future distributed workload storage.

## DNS had to exist before the cluster

The future API needed a stable name during installation and recovery, so Atlas
established foundational authoritative DNS outside Kubernetes.

The first client cutover failed safely. Private answers worked, but public
questions followed an inherited forwarding path through the router’s DNS proxy.
Once the router began distributing Atlas DNS to clients, that path became a
circular dependency. The canary rolled back to the captured DHCP state.

Atlas DNS was corrected to forward directly to explicit external recursive
resolvers. Packet observation, authoritative and public answers, negative
answers, UDP/TCP behavior, HTTPS, health endpoints, and a one-client DHCP canary
all passed before the broader cutover was accepted.

## Execution access became an architecture decision

Early construction still depended on a person relaying administrative work.
That approach did not scale across repeated, reviewed build phases.

The durable answer was an automation identity separate from the human
operator. It preserved attribution while keeping approval as a human decision.
The access mechanism and authorization controls remain private.

This mattered operationally: Team Atlas could approve a bounded gate, Codex
could execute and validate it directly, and the result could enter the durable
checkpoint without turning Ruben into command transport.

## One bootstrap path for two architectures

The original automation assumed ARM64 because every node was a Pi. Atlas Prime
made those assumptions unsafe. Bootstrap and preflight logic was generalized to
normalize Linux and package architecture names, verify architecture-appropriate
packages and images, and preserve worker-only restrictions.

Control-plane initialization produced one canonical configuration. The stable
API endpoint, serving-certificate name, advertise address, dedicated mounts,
unused API port, package/image architecture, and absence of old cluster state
were validated before use. The same bytes drove image selection and
initialization.

The foundation installation pinned the container runtime and Kubernetes
packages, enabled the required modules and sysctls, configured systemd cgroups,
and survived a controlled reboot. One attempt stopped because the running
container runtime tightened its data-directory permissions more than the empty
pre-install contract expected. The correction taught the gate to distinguish
valid lifecycle states instead of weakening the check.

Another initialization attempt stopped on the filesystem-created recovery
directory in the otherwise empty dedicated etcd volume. The exact directory was
verified and removed; no ignore flag or alternate data path was used. Atlas
Prime then initialized successfully, and Calico brought the node and cluster DNS
from their expected pre-CNI state to Ready.

## The first worker found the real trust boundary

The ARM64 canary drained, reset, joined Atlas Prime, became Ready, and passed
cross-node traffic. An end-to-end DNS check was still refused.

Evidence showed that one dependency path was missing from the accepted
foundational policy. The worker returned automatically to the legacy cluster.
The policy correction was isolated from worker migration and validated from
the real service path before another worker moved. Exact trust rules remain
private.

The first validator could not reliably express every required DNS query. It was
replaced with a pinned, purpose-built client with explicit status parsing,
timeouts, TCP coverage, and immutable artifact identity. A later correction
split foundational DNS queries from Kubernetes Service discovery so each
question went to the resolver responsible for answering it.

## The verifier was part of the migration

Worker migration repeatedly showed that infrastructure and its acceptance
harness can fail independently.

The canary reset initially hit an over-escaped remote command. A staged,
syntax-checked helper replaced it. An unprivileged checker could not use ICMP
without a capability the security context deliberately removed, so direct
Pod-IP HTTP proved the same routing property without broadening privilege. An
explicit DNS test needed the fully qualified Service name rather than relying on
interactive search behavior.

The next worker revealed scheduler and autoscaler assumptions. Metrics Server
could move between allowed nodes. Typha could legitimately change its desired
replica count after a drain. Evidence directories had to be unique, owned by the
transaction, and created before credentials. A verifier intended for the legacy
operator could not be wrapped in a root invocation. Each defect stopped before
irreversible progress or triggered a proven rollback.

The lesson was not that the gates were too strict. It was that strict gates must
model the real system rather than one frozen observation of it.

## From learning mode to rollout mode

After two workers had exercised drain, reset, join, rollback, routing, DNS,
service, scheduler, and evidence behavior, more preservation machinery stopped
buying useful information.

Team Atlas explicitly classified the remaining Pi-hole deployment, its local
test data, abandoned Longhorn state, and legacy cluster objects as disposable.
Host operating systems, identities, addressing, DNS, time policy, operator
access, hardware, and reusable container-runtime baselines remained valuable.

The third worker then used the hardened path without inventing a workload
migration for an experiment. It joined Atlas Prime and passed the established
acceptance suite.

With the old control plane standing alone, Atlas Prime and all migrated workers
were verified independently. Team Atlas explicitly accepted the irreversible
boundary: destroying the old datastore meant the legacy cluster would not have
a normal worker rollback path. The control-plane host was reset, its abandoned
storage configuration removed, its physical disk preserved unformatted, and
the machine reintroduced as the fourth worker.

## Physical recovery is part of availability

A power interruption during the migration exposed one unresolved dependency.
The worker class powered back on automatically, but the control-plane class did
not. Software persistence could not help until foundational hardware started.

After manual power-on, networking, storage mounts, time, DNS, etcd, Calico,
CoreDNS, and system health recovered normally. The durable requirement is now
to enable and physically prove automatic power-on after AC restoration in a
separately attended gate.

## Cold start closed the migration era

Team Atlas deliberately shut the platform down in dependency order and later
started it from a cold state with the control plane first. Foundational DNS,
the Kubernetes control plane, dedicated filesystems, cluster networking, and
the worker fleet recovered without rebuilding the platform.

The cold start exposed one durable identity defect on the former Pi control
plane. Its Kubernetes identity represented its new worker role, but a
persistent operating-system source restored the historical hostname. Kubernetes
rejected the mismatch. Team Atlas corrected only the persistent identity
source and its trusted cache, rebooted that worker, and accepted recovery only
after the operating system and Kubernetes agreed. No reset or rejoin was
needed.

The same recovery corrected a mistaken network diagnosis. The infrastructure
was healthy; a manual resolver override on the management workstation was
crossing wireless-network boundaries. Returning the workstation to
network-provided DNS restored the intended separation without changing the
router or foundational resolver.

## The human operator returned to the center

Automation made construction repeatable, but it was never intended to become
the only way to understand Atlas. Ruben received a dedicated Kubernetes client
identity and one current-cluster context, separate from infrastructure
automation. Human inspection then proved the core cluster inventory, workloads,
Services, events, cluster information, and API readiness.

Resource metrics are not yet installed on the new cluster. The historical
metrics milestone remains valid, while renewed observability belongs to the
next platform chapter.

## Where Atlas stands

Atlas now has one cluster: one AMD64 control plane and four ARM64 workers. The
legacy control plane is gone by design. The old storage experiment is not being
carried forward merely because it existed.

The next storage architecture will start from the workloads and recovery
properties Atlas actually needs, not from the assumptions of the abandoned
experiment.

Most importantly, Atlas remains larger than Kubernetes. Kubernetes currently
coordinates the platform, but the project’s horizon includes durable storage,
network services, observability, application delivery, websites, demo
environments, edge services, hybrid cloud, and future AI workloads.

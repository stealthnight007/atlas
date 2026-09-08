# Decision 002 — Heterogeneous Control-Plane Migration

## Status

Accepted and implemented.

## Context

Atlas began as an ARM64 Raspberry Pi cluster. Recovery work made that cluster
healthy, but storage latency and microSD endurance made it an unsuitable place
to concentrate future datastore and platform responsibilities.

An AMD64 system with substantially stronger CPU, memory, networking, and NVMe
storage was introduced as a future control-plane foundation.

## Decision

Atlas will operate as a heterogeneous ARM64/AMD64 Kubernetes platform. The Pi
control plane remains the protected operational and rollback authority only
while the AMD64 successor is commissioned and worker migration is proven in
bounded gates.

Bootstrap automation must normalize the architecture names reported by Linux
and Kubernetes tooling, select architecture-correct packages and images, and
refuse unsupported architectures. Multi-architecture artifacts are preferred;
architecture-specific workloads must use explicit scheduling constraints.

Control-plane migration is not an in-place experiment on the legacy
control-plane host.
The successor must first pass operating-system, DNS, automation, storage,
bootstrap, endpoint, certificate, initialization, and recovery validation.

## Consequences

- The healthy Pi cluster remains available during construction and canary
  migration, then is intentionally retired after the successor is independent.
- Bootstrap and validation code becomes architecture-aware rather than ARM64-
  only.
- Every platform image and DaemonSet requires multi-architecture validation.
- The new host adds capacity but does not remove the need for explicit failure-
  domain and disaster-recovery design.
- The former Pi control-plane host becomes an ARM64 worker only after every
  prior worker has migrated and the replacement API and datastore are healthy.

## Implemented Outcome

Atlas Prime became the sole AMD64 control plane. Four Pi hosts now operate as
ARM64 workers, including the former legacy control-plane host. The old datastore
and control-plane state were explicitly declared disposable and destroyed only
after the new cluster passed independent health and functional validation.

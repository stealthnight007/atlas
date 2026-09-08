# Milestone 006 — Cluster Networking and Worker Rejoin

Status: **Complete historical milestone**

## Capability added

Calico restored pod networking, the three Pi workers joined sequentially, and
cluster DNS plus cross-node workload traffic were validated. The Pi platform
again operated as one healthy four-node cluster.

## Rollout model

Each worker used a separate short-lived bootstrap credential. Team Atlas
required node and network convergence before moving to the next worker, revoked
temporary access after use, and removed validation workloads afterward.

The resource-metrics certificate limitation from milestone 003 remained an
explicit isolated-lab exception. It was not treated as a networking success
criterion or silently carried into the future Atlas Prime design.

## Lessons

- Sequential joins reduce the number of changing variables.
- Node readiness must be paired with real DNS and cross-node traffic tests.
- Temporary credentials and validation workloads need explicit cleanup.

## Outcome

The recovered Pi cluster was healthy enough to support the storage experiment
that ultimately drove the Atlas Prime architecture pivot. See the
[migration-era journal](../journal/atlas-prime-migration-era.md).


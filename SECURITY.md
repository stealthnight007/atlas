# Publication Boundary and Security Policy

Project Atlas publishes its engineering story, architecture decisions, and
lessons learned. It does not publish enough operational detail to become a map
or recovery guide for the live lab.

## Public content

Public material may describe component roles, high-level trust relationships,
failure modes, validation principles, architectural tradeoffs, completed
milestones, and clearly labeled future work. Diagrams must show logical roles,
not the live network.

## Private content

The following remain private:

- scripts, infrastructure configuration, runbooks, checkpoints, and reports;
- credentials, tokens, keys, certificates, fingerprints, and kubeconfigs;
- exact addresses, VLANs, subnets, ACLs, DNS zones, and live topology;
- device identifiers, serials, disk UUIDs, configuration hashes, and object IDs;
- authentication, authorization, privilege, and recovery mechanics;
- local filesystem locations, backup locations, evidence, logs, and packet data;
- private Git history and unpublished operational artifacts; and
- photographs or metadata that reveal people, locations, labels, screens,
  codes, identifiers, documents, or reflections.

General technology names, architecture families, platform roles, approximate
capacity, and lessons from failures may be public when they do not reveal a
live control or operational target.

## Exact v1 allowlist

The `v1.0.0-atlas-prime-era` publication contains exactly these files:

```text
README.md
SECURITY.md
docs/architecture/migration-era-diagrams.md
docs/decisions/001-platform-modernization.md
docs/decisions/002-heterogeneous-control-plane-migration.md
docs/decisions/003-independent-foundational-dns.md
docs/decisions/004-dedicated-automation-identity.md
docs/decisions/005-dedicated-control-plane-storage.md
docs/decisions/006-canary-to-rollout-transition.md
docs/decisions/007-power-recovery-requirement.md
docs/decisions/008-human-and-automation-operator-identities.md
docs/journal/atlas-prime-migration-era.md
docs/milestones/001-lab-discovery.md
docs/milestones/002-kubernetes-foundation.md
docs/milestones/003-resource-metrics.md
docs/milestones/004-platform-modernization.md
docs/milestones/005-control-plane-reconstitution.md
docs/milestones/006-cluster-networking-and-worker-rejoin.md
docs/milestones/007-persistent-storage-preparation.md
docs/milestones/008-atlas-prime-commissioning.md
docs/milestones/009-independent-dns-cutover.md
docs/milestones/010-safe-automation-and-worker-hardening.md
docs/milestones/011-atlas-prime-storage-foundation.md
docs/milestones/012-atlas-prime-control-plane-networking.md
docs/milestones/013-canary-gated-worker-migration.md
docs/releases/v1-atlas-prime-era.md
```

Anything not listed is excluded by default. Changing the allowlist requires a
new publication review and a fresh exposure scan.

## Reviewed additions after v1

The v1 release allowlist above remains an immutable record of that release.
The following later public file has passed the same publication-boundary
review for the current main branch:

```text
docs/milestones/014-durable-storage-and-recovery.md
```

## History and reporting

Removing sensitive material from a later commit does not remove it from Git
history. Public releases must therefore be assembled from the reviewed
allowlist in a new repository with no inherited private history.

If public material appears to reveal a live credential, identifier, topology,
or security control, do not open a public issue containing the detail. Contact
the repository owner privately and identify only the affected public file.

# Decision 004 — Dedicated Infrastructure Automation Identity

## Status

Accepted and implemented.

## Context

Atlas construction required approved administrative work across host and
Kubernetes boundaries. Reusing a human identity for automation would have
blurred attribution and ownership.

## Decision

Use an automation identity distinct from the human operator so activity remains
attributable. Capability is separate from authorization: every mutating gate
still requires human approval, bounded scope, validation, and rollback where
feasible.

Identity implementation, access paths, credential form, privileges, source
restrictions, lifecycle controls, and recovery mechanics remain private.

## Alternatives Considered

- Human-only execution kept a person in every implementation loop.
- Per-action wrappers fragmented the construction workflow.
- Reusing the human identity weakened attribution.
- A separate identity added lifecycle work but created the clearest ownership
  boundary.

## Consequences

- Approved gates can be implemented without a person relaying commands.
- Human and automated activity remain distinguishable.
- Access design and lifecycle review remain continuing private responsibilities.

This decision governs host and infrastructure automation. The separate
Kubernetes identity used by the human operator is covered by
[Decision 008](008-human-and-automation-operator-identities.md).

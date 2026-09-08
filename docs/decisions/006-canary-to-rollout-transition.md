# Decision 006 — Transition from Canary Learning to Rollout

## Status

Accepted and implemented.

## Context

The first worker migrations were deliberately conservative. They exposed a
resolver trust-boundary omission and several defects in validation and
orchestration assumptions. Automatic rollback kept the legacy cluster usable
while the team corrected each issue.

By the third worker, the reset, join, credential, networking, DNS, service, and
health paths had been exercised repeatedly. The remaining application and
storage remnants were experiments with no preservation value. Continuing to
design migration machinery for them would have increased complexity without
protecting useful state.

## Decision

Use the first workers as the canary and learning phase. Once the migration path
is repeatable and remaining state is explicitly classified as disposable,
switch to rollout semantics:

- preserve host identity, operating system, network, time, access, hardware,
  and reusable runtime state;
- discard obsolete Kubernetes membership and experimental application/storage
  remnants;
- retain essential functional and control-plane health validation; and
- stop only for new architectural risk, unexpected valuable data, loss of host
  access, or target-cluster degradation.

The legacy control plane may be retired irreversibly only after the replacement
cluster is independently healthy and the loss of normal rollback is explicitly
accepted.

## Consequences

- Canary rigor produces reusable evidence instead of permanent ceremony.
- Disposable state must be classified explicitly; it is never inferred merely
  because preservation is inconvenient.
- The final rollout is shorter but retains the proven acceptance suite.
- The old datastore is not kept as an accidental second source of truth.
- Failed experiments and validator defects remain part of the public record.

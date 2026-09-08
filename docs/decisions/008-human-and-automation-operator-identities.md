# Decision 008 — Separate Human and Automation Operator Identities

## Status

Accepted and implemented.

## Context

Atlas construction needed a dedicated automation path, but the finished
platform also needed to remain directly understandable and operable by its
owner. Reusing one identity for both purposes would blur attribution and make
credential lifecycle decisions harder.

[Decision 004](004-dedicated-automation-identity.md) established the host-side
automation boundary. This decision extends that separation into Kubernetes and
adds an independent human inspection path.

## Decision

Maintain separate Kubernetes identities for the human operator and the
infrastructure automation plane.

The human context targets only the current Atlas Prime cluster and supports
normal inspection of nodes, workloads, Services, events, health, and future
platform resources. The automation identity retains its separate operating
purpose and remains subject to explicit human approval before mutating gates.

Credential material, certificate metadata, authorization mechanics, source
restrictions, filesystem locations, and recovery procedures remain private.

## Consequences

- Ruben can inspect and learn the platform without impersonating automation.
- Human and automated activity remain distinguishable in audit evidence.
- Retiring the legacy cluster also means removing stale human contexts rather
  than leaving multiple apparent sources of truth.
- Credential renewal and least-privilege review become explicit maintenance
  responsibilities.
- Automation can accelerate execution without becoming the only way to
  understand Atlas.

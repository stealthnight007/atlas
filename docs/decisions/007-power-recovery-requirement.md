# Decision 007 — Automatic Power Recovery Is a Platform Requirement

## Status

Requirement accepted; firmware implementation and physical validation pending.

## Context

A physical power interruption demonstrated an asymmetry in the platform. The
worker class returned automatically, while the control-plane class required
manual intervention. Normal software persistence is not enough if foundational
hardware does not boot after power returns.

Temporary resolver changes made during incident recovery were treated as
operator workarounds, not durable architecture. After power was restored, DNS,
Kubernetes, storage mounts, time, and system health recovered normally.

A later controlled shutdown and cold start proved software and cluster
recovery after Atlas Prime was manually powered on. That test does not close
the AC-restore requirement: unattended hardware power-on remains unproven.

## Decision

The control-plane class must support and enable the platform mechanism that
automatically powers the system on after AC restoration. The setting and its
behavior must be validated in a separately approved, attended physical-power
gate.

The public record describes the requirement and failure mode. Exact firmware
navigation, device identifiers, management interfaces, and recovery procedures
remain private.

## Consequences

- Reboot persistence and service enablement are necessary but insufficient
  resilience evidence.
- Physical power behavior becomes part of platform acceptance testing.
- A future UPS can reduce interruptions but does not replace power-restore
  configuration.
- Until the attended test passes, automatic recovery after a full outage is an
  acknowledged platform gap.
- Controlled cold-start recovery is now proven once a human has powered on the
  control-plane host.

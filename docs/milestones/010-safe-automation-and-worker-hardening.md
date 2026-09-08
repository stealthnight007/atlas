# Milestone 010 — Safe Automation and Worker Hardening

Status: **Complete**

## Capability Added

Atlas can now execute approved construction gates through a dedicated,
auditable automation identity, and all three Pi workers have a persistent
time-synchronization policy validated across reboot.

## Worker Time Synchronization

DHCP was supplying a local time source that was not part of the intended node
policy. The workers were changed sequentially to ignore DHCP-provided NTP while
continuing to use the operating system's approved external sources.

Every worker had to retain its network identity, remain synchronized, return
to Kubernetes `Ready`, and preserve cluster, API, metrics, and DNS health. The
policy was also tested across both normal DHCP renewal and reboot.

The legacy control-plane node was deliberately excluded. It remains the
rollback authority during migration, and configuration uniformity alone was not
a sufficient reason to change it.

## Harness Failures Were Not Infrastructure Failures

Several early attempts stopped even though the intended node behavior was
healthy. The causes included an incorrect listener target, a privileged file
being checked from the wrong context, stale lease metadata being mistaken for
effective policy, and a validation window shorter than the complete protected
test sequence.

These were verifier and transaction-harness defects. Atlas did not waive the
gates: the prepared rollback ran, the original state was proven, and the
harness was corrected before retrying. That distinction matters—automation is
part of the system and must be validated as rigorously as the change it makes.

## Durable Automation Plane

Repeated construction phases crossed host, storage, service, and Kubernetes
boundaries. Atlas therefore separated the automation identity from the human
operator so implementation activity remained attributable. Capability did not
imply authorization: every mutating gate still required explicit approval and
a fresh preflight.

The identity's access paths, credential form, privileges, restrictions, and
lifecycle controls remain private.

## Outcome

All three original workers were reboot-proven under the intended NTP policy,
and approved Atlas Prime gates could be executed directly without using a
person as command transport. The legacy control plane remained unchanged during
construction; when it was later retired and became the fourth worker, it
received the same proven worker time policy.

The migration era is now complete. Access lifecycle and least-privilege review
continue privately as normal platform responsibilities.

## Related Decision

- [Decision 004 — Dedicated Infrastructure Automation Identity](../decisions/004-dedicated-automation-identity.md)

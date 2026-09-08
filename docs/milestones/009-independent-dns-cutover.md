# Milestone 009 — Independent DNS and Safe Client Cutover

Status: **Complete**

## Capability Added

Atlas now has an internal authoritative DNS service outside Kubernetes and a
validated client-distribution path.

## Design

The durable request path is:

```text
lab client -> Atlas DNS -> external recursive resolvers
```

Atlas DNS answers the private lab zone authoritatively and forwards public
questions directly to explicitly selected external resolvers. It does not
depend on the router's DNS proxy.

The service runs independently of Kubernetes so name resolution remains
available while the future control plane is installed, restarted, or recovered.

## The First Cutover Failed Safely

The first DHCP canary received the intended Atlas DNS server and private names
worked, but public lookups failed. The infrastructure evidence showed that
Atlas DNS was forwarding public questions back to the router's DNS proxy. Once
clients were pointed at Atlas DNS, that inherited forwarding path became an
unreliable circular dependency.

The acceptance gate treated failed public resolution as a hard stop. DHCP was
restored to its captured pre-change state, the canary renewed its lease, and
normal service was revalidated before further work continued.

## Correction and Retry

Only the upstream forwarding destination was changed. Direct queries, health
endpoints, authoritative answers, UDP and TCP behavior, public HTTPS, and
bounded packet observation then proved:

- public requests left Atlas DNS for the approved external resolvers;
- no DNS traffic returned to the router proxy; and
- all other authoritative and caching behavior remained intact.

After a fresh preflight, the DHCP change was retried. One canary was renewed
first, followed by the remaining approved clients one at a time. Each client
had to preserve its address and route while passing private DNS, public DNS,
HTTPS, packet-path, and platform-health checks.

## Outcome

The corrected cutover passed and the rollback remained available but unused.
The failed first attempt is retained because it demonstrates the value of a
canary, complete acceptance criteria, and automatic recovery over accepting a
partially working network change.

## Power-Recovery Lesson

A later physical outage exposed a foundational-host power dependency. The
worker class returned automatically, while the control-plane class required
manual power-on. The software stack recovered normally afterward. Automatic
power-on after AC restoration is therefore a platform requirement, not merely
a convenience.

## Related Decision

- [Decision 003 — Keep Foundational DNS Independent](../decisions/003-independent-foundational-dns.md)

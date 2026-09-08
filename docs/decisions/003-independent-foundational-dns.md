# Decision 003 — Keep Foundational DNS Independent

## Status

Accepted and implemented.

## Context

Atlas needs stable private names before Kubernetes control-plane initialization
and during later cluster recovery. The first client cutover also revealed that
forwarding public requests through the router's DNS proxy created an unreliable
dependency once the router began distributing Atlas DNS to clients.

## Decision

Run authoritative Atlas DNS in the foundational platform layer, outside
Kubernetes during bootstrap. Forward public questions to external recursive
resolvers rather than back through the router proxy.

Change DHCP distribution with a single-client canary, complete DNS and HTTPS
acceptance checks, and a prepared rollback to the captured prior state.

## Consequences

- Kubernetes can be installed or recovered without making its own API name
  dependent on an already healthy cluster.
- The router remains responsible for DHCP but not recursive DNS proxying for
  Atlas clients.
- Foundational service recovery and startup ordering become acceptance
  criteria.
- DNS filtering and analytics may be added later only if they do not introduce
  a loop or a Kubernetes dependency.

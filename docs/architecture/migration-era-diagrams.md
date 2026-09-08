# Atlas Migration-Era Architecture

These diagrams deliberately show roles and trust relationships rather than the
live network. Addresses, VLAN identifiers, device identifiers, credentials,
security-policy values, and recovery paths are omitted.

## 1. Original Pi-only cluster

```mermaid
flowchart LR
    O[Human operator] --> P[Pi control-plane role]
    P --> W[Pi worker fleet]
    W -. storage experiment .-> S[Removable storage class]
```

The original platform was valuable precisely because it was real: small,
resource-constrained machines exposed operating-system, networking, datastore,
and storage behavior that a disposable tutorial cluster would have hidden.

## 2. Transitional dual-cluster migration

```mermaid
flowchart TB
    GC[Management client] --> L[Legacy cluster<br/>rollback authority]
    GC --> P[Successor cluster<br/>new control-plane role]
    DNS[Foundational DNS<br/>outside Kubernetes] --> GC
    L --> A[Worker awaiting migration]
    P --> B[Accepted canary worker]
    A -. drain / reset / join .-> P
    P --> V[Functional validation]
    V -->|pass| C[Commit membership]
    V -->|fail| R[Return canary to legacy cluster]
```

Both clusters existed intentionally. A node was not considered migrated merely
because it became Ready; service, routing, DNS, host, and both-cluster health
had to pass before legacy recovery access was surrendered.

## 3. Final heterogeneous cluster

```mermaid
flowchart TB
    O[Human and automation clients] --> P[AMD64 control-plane role]
    P --> W[ARM64 worker fleet<br/>four nodes]
    F[Foundational services<br/>outside Kubernetes] --> O
    P --> E[Dedicated control-plane storage role]
    W -. future design boundary .-> X[Preserved storage class]
```

Atlas Prime carries the sole control-plane role, and the four Pis form the
worker fleet. The fourth worker is the former Pi control plane. Preserved
storage remains outside the active platform until a fresh design is approved.
The diagram intentionally aggregates hosts and does not show the live network,
service placement, or recovery path.

## 4. Team Atlas operating model

```mermaid
flowchart LR
    R[Ruben<br/>vision, architecture ownership,<br/>hardware and approvals]
    C[ChatGPT<br/>strategy, tradeoffs,<br/>gate and policy review]
    X[Codex<br/>implementation, execution,<br/>validation and evidence]
    I[Atlas infrastructure]
    K[Durable checkpoint]

    R --> C
    C --> R
    R -->|approved gate| X
    C -->|reviewed design| X
    X --> I
    I -->|observations| X
    X --> K
    K --> R
    K --> C
```

Atlas is human-led and AI-assisted. Architecture authority and physical control
remain with Ruben; ChatGPT supports reasoning and review; Codex acts as the
infrastructure and automation engineering arm after a gate is approved.

## 5. Future platform vision

```mermaid
flowchart TB
    F[Atlas foundation<br/>compute, network, DNS, automation]
    F --> K[Kubernetes orchestration]
    F --> S[Persistent storage]
    K --> P[Platform services<br/>ingress, observability, GitOps]
    S --> P
    P --> N[Network services]
    P --> A[Applications and microservices]
    P --> W[Websites and personal projects]
    P --> D[Interview and demo environments]
    P --> AI[Future AI/model workloads]
    P --> E[Edge services]
    P --> C[Hybrid-cloud integration]
    E <--> C
```

Kubernetes is a current substrate, not the definition of Project Atlas. The
project is a growing personal infrastructure and mini-datacenter platform that
can combine on-premises compute, storage, networking, edge delivery, and cloud
services over time.

# Milestone 001 — Lab Discovery

## Capability Added

Established the engineering baseline for Atlas by documenting the existing home lab before making architectural or operational changes.

Rather than immediately rebuilding infrastructure, the initial objective was to understand the environment, verify what already existed, and create a structured foundation for future engineering work.

---

## Why Atlas Exists

Atlas is a long-term platform engineering lab designed to explore modern infrastructure through hands-on experience.

The goal is not to complete tutorials or collect certifications, but to build, operate, troubleshoot, document, and continuously improve real systems over time.

Every milestone represents a new platform capability.

---

## Initial Environment

The lab initially consisted of:

- Raspberry Pi Kubernetes cluster

- Ubuntu Server

- Cisco Meraki networking

- Ubiquiti networking

- macOS development workstation

- GitHub repository

- Visual Studio Code

The Kubernetes cluster already existed but had not yet been fully documented or validated.

---

## Initial Objectives

The first phase of Atlas focused on:

- Inventorying existing infrastructure

- Understanding cluster architecture

- Verifying networking

- Organizing project documentation

- Establishing Git version control

- Defining engineering milestones

No major architectural changes were made during this phase.

---

## Repository Organization

The repository was organized to support long-term engineering documentation and operational knowledge.

```text

atlas/

├── docs/

│   ├── milestones/

│   ├── runbooks/

│   └── troubleshooting/

├── diagrams/

├── inventory/

├── kubernetes/

├── network/

├── scripts/

├── terraform/

└── README.md

```

---

## Engineering Principles

Atlas is built around several guiding principles:

- Understand systems before changing them.

- Build one capability at a time.

- Recover failures instead of rebuilding immediately.

- Automate repetitive operational work.

- Document engineering decisions.

- Keep infrastructure reproducible.

---

## Outcome

Atlas now has:

- A structured GitHub repository

- A documented engineering roadmap

- A repeatable documentation framework

- A clear baseline for future platform capabilities

---

## Next Milestone

Recover, stabilize, and validate the Kubernetes platform.
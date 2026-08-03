# Decision 001 — Platform Modernization

## Context

Atlas began by recovering and validating an existing Raspberry Pi Kubernetes cluster rather than immediately rebuilding it.

The objective was to understand an inherited platform, recover degraded components, and document the engineering process before deciding whether the existing foundation was suitable for long-term development.

## What Was Accomplished

During the recovery effort we successfully:

- Restored all Kubernetes nodes to a healthy Ready state.

- Corrected containerd and kubelet cgroup configuration.

- Permanently disabled swap across all nodes.

- Restored Metrics Server functionality.

- Validated Calico networking.

- Investigated etcd health.

- Prepared dedicated storage for Longhorn on multiple nodes.

- Documented the recovery process as Atlas milestones.

By the end of the recovery effort, the cluster itself was healthy and stable.

## Discovery

While preparing to deploy Longhorn, package installation failed.

Investigation revealed that the underlying operating system was Ubuntu 22.10 (Kinetic), an end-of-life release whose package repositories had been retired.

Additional investigation showed that the Kubernetes package repository had also been deprecated.

Although the Kubernetes cluster had been successfully recovered, the underlying platform could no longer reliably support new software installation or long-term maintenance.

## Engineering Decision

Rather than continue adding new capabilities on top of an unsupported operating system, Atlas will transition to a fully rebuilt platform.

The existing recovery work was not discarded.

Instead, it served its intended purpose:

- Understand an inherited platform.

- Recover production-like failures.

- Learn the interaction between Linux, containerd, Kubernetes, Calico, Metrics Server, storage, and cluster health.

- Identify the architectural limitations of the existing foundation.

These lessons directly inform the design of Atlas v2.

## Next Phase

Atlas will be rebuilt on a supported Ubuntu LTS release using a fully documented and repeatable installation process.

The rebuild will prioritize:

- Reproducibility

- Automation

- Documentation

- Platform engineering best practices

The goal is not simply to recreate the previous cluster, but to build a platform that can be reliably reproduced from bare hardware.
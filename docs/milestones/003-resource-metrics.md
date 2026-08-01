# Milestone 003 — Cluster Resource Metrics

## Capability Added

Atlas now provides cluster-wide CPU and memory visibility using the Kubernetes Metrics API.

This capability enables administrators to observe resource utilization across nodes and workloads using native Kubernetes tooling.

## Why It Matters

Resource metrics are a foundational operational capability for Kubernetes.

They enable:

- Capacity planning

- Resource troubleshooting

- Horizontal Pod Autoscaling (HPA)

- Cluster health validation

- Performance analysis

Without Metrics Server, commands such as `kubectl top` are unavailable.

## Implementation

Metrics Server was deployed using the upstream Kubernetes SIG release.

Following deployment, Metrics Server was unable to collect metrics because the kubelet serving certificates on the lab cluster did not include IP Subject Alternative Names (SANs).

The deployment was updated with the `--kubelet-insecure-tls` flag to allow Metrics Server to securely communicate with kubelets within this isolated home lab.

> This configuration is appropriate for a private learning environment. Production clusters should use properly signed kubelet certificates rather than disabling certificate validation.

## Validation

The deployment was validated using:

```bash

kubectl get apiservice v1beta1.metrics.k8s.io

kubectl top nodes

kubectl top pods -A
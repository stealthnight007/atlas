# Milestone 002 — Kubernetes Foundation

## Capability Added

Atlas now has a stable, multi-node Kubernetes foundation running across Raspberry Pi hardware.

This milestone focused on recovering and validating the existing cluster rather than rebuilding it from scratch.

## Environment

The platform includes:

- One Kubernetes control-plane node

- Three Kubernetes worker nodes

- Ubuntu Server

- Kubernetes installed with `kubeadm`

- containerd as the container runtime

- Calico for pod networking

- etcd as the Kubernetes datastore

Environment-specific addresses, credentials, certificates, tokens, and backup files are intentionally excluded from this public repository.

## Initial State

The cluster was partially degraded and several worker nodes were unhealthy.

Observed issues included:

- Nodes reporting `NotReady`

- kubelet repeatedly failing

- containerd and kubelet using inconsistent cgroup drivers

- Swap enabled on Kubernetes nodes

- Calico readiness failures

- BGP peering delays between nodes

- A high historical etcd restart count

- Slow etcd storage operations

## Recovery Work

### Container Runtime Alignment

Kubelet was configured to use the systemd cgroup driver, while containerd was using a different configuration.

Containerd was updated to use:

```text

SystemdCgroup = true
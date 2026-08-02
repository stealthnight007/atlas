# Milestone 002 — Kubernetes Foundation

## Capability Added

Established a stable, production-inspired multi-node Kubernetes platform running across four Raspberry Pi systems.

Rather than rebuilding the cluster from scratch, this milestone focused on understanding the existing environment, recovering failed components, correcting configuration drift, and validating long-term operational stability.

---

## Environment

The platform consists of:

- One Kubernetes control-plane node

- Three Kubernetes worker nodes

- Ubuntu Server

- Kubernetes installed with `kubeadm`

- containerd as the container runtime

- Calico for pod networking

- etcd as the Kubernetes datastore

Environment-specific IP addresses, credentials, certificates, tokens, and backup files are intentionally excluded from this public repository.

---

## Initial State

The cluster was partially degraded following configuration inconsistencies and subsequent testing.

Observed issues included:

- Nodes reporting `NotReady`

- kubelet repeatedly failing to start

- Mismatched cgroup driver configuration between kubelet and containerd

- Swap enabled on Kubernetes nodes

- Calico readiness failures

- Delayed BGP peering between cluster nodes

- High historical restart counts for etcd

- Slow etcd storage operations

---

## Recovery Activities

### Container Runtime Alignment

Kubelet was configured to use the `systemd` cgroup driver while containerd was configured differently.

Containerd was updated to use:

```text

SystemdCgroup = true

```

The container runtime and kubelet were restarted and the cluster returned to a consistent runtime configuration.

---

### Cluster Recovery

Recovery activities included:

- Restarting kubelet and containerd

- Restoring Calico networking

- Verifying node registration

- Confirming Kubernetes control-plane health

- Validating etcd functionality

- Confirming inter-node communication

All four Raspberry Pi nodes successfully returned to a healthy cluster state.

---

### Metrics Server

Metrics Server was deployed and validated to provide cluster resource utilization.

An initial deployment failed because kubelet certificates did not contain IP Subject Alternative Names (SANs).

The deployment was updated to use:

```text

--kubelet-insecure-tls

```

After rollout, Kubernetes successfully exposed:

- Node CPU utilization

- Node memory utilization

- Pod CPU utilization

- Pod memory utilization

through the Metrics API.

---

### etcd Validation

The control-plane datastore was inspected and validated.

Activities included:

- Verifying etcd health

- Confirming endpoint status

- Creating a disaster recovery snapshot

- Validating snapshot integrity

This establishes a repeatable recovery point for the Kubernetes control plane.

---

### Permanent Swap Remediation

During initial recovery, swap was disabled using:

```bash

sudo swapoff -a

```

This restored cluster functionality but only for the current boot session.

After a full rack power cycle, Ubuntu automatically recreated and enabled `/swapfile`, causing kubelet to fail again.

Investigation determined the behavior was controlled by the following systemd units:

```text

mkswap.service

swapfile.swap

```

The permanent solution was applied to every Kubernetes node:

```bash

sudo swapoff -a

sudo systemctl mask mkswap.service

sudo systemctl mask swapfile.swap

sudo rm -f /swapfile

sudo systemctl daemon-reload

```

Each Raspberry Pi was rebooted individually and validated.

Verification included:

```bash

swapon --show

systemctl is-active kubelet

kubectl get nodes

```

Following the remediation, all four nodes successfully rebooted with swap remaining disabled and Kubernetes recovered automatically without additional intervention.

---

## Outcome

Atlas now provides:

- Stable four-node Kubernetes cluster

- Healthy control plane

- Healthy worker nodes

- Functional Calico networking

- Consistent container runtime configuration

- Metrics Server

- etcd disaster recovery snapshot

- Permanent Kubernetes-compatible node configuration

- Repeatable operational recovery procedures

---

## Lessons Learned

Several important engineering principles emerged during this milestone:

- Understand the root cause before applying a workaround.

- Validate changes by performing real reboot testing.

- Document operational recovery procedures alongside infrastructure.

- Small configuration differences can prevent an entire Kubernetes cluster from functioning correctly.

---

## Next Milestone

Add distributed persistent storage using Longhorn and introduce Kubernetes Persistent Volumes and Persistent Volume Claims.
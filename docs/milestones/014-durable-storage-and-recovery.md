# Milestone 014 — Durable Storage and Recovery

Status: **Complete — first application storage tier proven through failure**

Atlas has crossed from storage preparation into real persistent platform
capability. Two dedicated worker-attached disks now provide a Longhorn V1 tier
for applications, while control-plane storage and worker boot media remain
outside the replica pool.

The application class is deliberately non-default. Workloads must opt in to
two replicas, hard node and disk separation, ext4, retained volumes, expansion,
and a conservative logical capacity budget of roughly 650 GiB. New volumes are
not allowed to begin life degraded.

## Persistence is a test result

A real PVC-backed workload wrote an identity record and checksum-bearing
payload. Team Atlas then moved the workload between two compute-only workers.
The replacement Pod had a different identity but read the same bytes and
reproduced the checksum.

The running data replicas landed on the two intended storage workers. The
other workers received no Longhorn disk, and the control plane remained
outside the Longhorn workload and storage surface.

That distinction matters: a storage diagram is a proposal. A checksum after a
new Pod and a new attachment node is evidence.

## The bounded failure

One storage worker's Kubernetes and Longhorn data plane was deliberately made
unavailable. The volume changed from healthy to degraded and its engine showed
only one writable replica on the surviving storage worker.

The application stayed Ready. Its identity, byte count, and checksum remained
unchanged. The Kubernetes API, datastore, DNS, and networking on the remaining
nodes stayed healthy.

The failed worker then rebooted. Its stable disk mount returned automatically,
Longhorn revalidated the disk, rebuilt the missing copy, and returned the
volume to two writable replicas and healthy status.

## The capability Atlas does not claim

This is not full high availability across an arbitrary node failure.

With only two eligible storage nodes, losing one leaves the surviving replica
available but leaves nowhere to recreate the second copy. Two-copy redundancy
returns only when the failed node comes back or another eligible storage disk
or node is added.

Replication is not backup either. Before valuable application data is placed
on this tier, Atlas still requires an independent NFS or S3-compatible backup
target and a proven restore.

## What the test harness taught us

The storage system was not the only thing under test.

- A syntactically valid configuration value used the wrong data type and was
  normalized to an upstream default. Live-state verification caught it before
  the first PVC.
- A diagnostic rewrite raced the workload's checksum loop and damaged its own
  disposable evidence. The validator now uses atomic initialization.
- A one-second probe timeout failed on a CPU-capped checksum even while the
  data was correct. The final probes measure the work they actually ask the
  node to perform.
- Stopping containerd did not stop a shim-managed storage process. The failure
  was accepted only after the engine truly lost that replica.

The lesson is familiar but important: verify the validator, verify the failure,
and verify recovery all the way back to the intended replica count.

The small disposable validator remains available as the first telemetry target
for Milestone 015 — Atlas Can See Itself.

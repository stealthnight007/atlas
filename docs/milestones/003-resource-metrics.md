# Milestone 003 — Cluster Resource Metrics

Status: **Complete historical milestone; current-cluster restoration pending**

## Capability added

The original Pi cluster gained node and workload CPU and memory visibility
through the Kubernetes Metrics API. This supported capacity planning,
troubleshooting, health validation, and future autoscaling experiments.

## Security lesson

The legacy kubelet serving certificates lacked the identity fields needed for
strict verification over the path used by Metrics Server. Atlas temporarily
accepted an isolated-lab certificate-verification exception while preserving
transport encryption and documenting the limitation.

That exception was not promoted into a general recommendation. A production
design should issue appropriate serving certificates and retain full peer
verification.

## Migration-era status

The Pi cluster that carried this capability was later retired. Metrics Server
has not yet been installed on the Atlas Prime cluster, so resource telemetry is
an explicit next-era gap rather than an implied current feature. Any new
deployment requires a fresh design and security review.

## Outcome

Atlas learned to treat observability as a platform capability with its own
trust assumptions, not simply as a dashboard add-on.


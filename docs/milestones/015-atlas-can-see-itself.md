# Milestone 015 — Atlas Can See Itself

Status: **Complete — first Ground Control dashboard proven through a live workload change**

Atlas now has a coherent metrics-first observability foundation and a usable
human dashboard. The platform can show node, workload, storage, and core-
service state together, retain a short operational history, evaluate alerts,
and accept application metrics through OpenTelemetry.

## Secure resource metrics

Metrics Server provides current CPU and memory through the Kubernetes resource
metrics API for the control plane and all four workers. Both the automation
identity and the separate human operator path can use `kubectl top nodes`; the
human path can also inspect Pods across namespaces.

Kubelet certificates are verified against explicit trust, and the Kubernetes
aggregation layer verifies Metrics Server's serving certificate. Atlas did not
carry forward insecure kubelet TLS or disabled aggregation verification.

## The first Ground Control surface

The initial observability stack is deliberately small:

- Prometheus Operator and one Prometheus;
- kube-state-metrics and one node-exporter per node;
- one Alertmanager;
- one authenticated Grafana; and
- one internal OpenTelemetry Collector gateway.

Prometheus keeps roughly seven days of disposable operational history on a
30 GiB claim in the Longhorn application tier. Grafana dashboards, data
sources, monitors, and alert rules are declarative so the visual layer can be
rebuilt without treating its local database as valuable data.

The curated **Atlas / Ground Control** dashboard shows all five nodes, Ready
state, named CPU and memory histories, workload and Pod health, restart
signals, PV/PVC state, Longhorn capacity and volume health, active alerts, the
retained storage validator, and core platform-service scrape health. Initial
access is authenticated and restricted to the internal operator boundary; no
public endpoint or household-network dependency was introduced.

## OpenTelemetry from the beginning

Infrastructure metrics remain a Prometheus responsibility. The internal
Collector gateway provides the vendor-neutral OTLP contract for future
applications, MCP services, agents, and security experiments without running a
second Kubernetes/node collector.

The first bounded start taught an important packaging lesson: the smaller
Kubernetes Collector distribution did not include the Prometheus exporter
required for the reviewed bridge. Atlas reconciled to the official contrib
distribution at the same version, with only the required metrics pipeline
enabled. A disposable workload then sent a sanitized OTLP metric, Prometheus
scraped it with Kubernetes context, and the sender was removed.

Loki and Tempo remain deferred until real workloads produce useful logs and
traces. Mimir, Thanos, Cortex, Elasticsearch/OpenSearch, Kafka, distributed
telemetry backends, and overlapping collection agents remain outside this
phase.

## The visible recovery proof

The retained PVC-backed validator began Ready with its original identity,
exact payload size, and checksum. With the dashboard already open, Team Atlas
deleted exactly that disposable Pod.

Grafana then displayed the old and replacement Pod as separate creation and
readiness series. At the same time, its Longhorn volume remained healthy and
attached. The replacement became Ready, read the same identity and byte count,
and reproduced the original checksum.

Afterward, every Prometheus target was up; the Collector, Prometheus,
Alertmanager, Grafana, exporters, DNS, networking, API, datastore, and all five
nodes were healthy. The alert view showed the intentional always-on watchdog
and an informational CPU-throttling signal from the disposable validator, with
no Atlas critical or warning condition firing.

This is the milestone's real change: Atlas health is no longer available only
as pasted command output. Ground Control can see a workload change while it
happens and correlate it with the storage and platform state that carried the
workload through recovery.

## What comes next

Current human access remains internal and deliberately narrow. A future
application-delivery milestone will add durable private HTTPS delivery,
stronger named identity, and network policy without exposing the UI to
household networking or the public Internet.

Milestone 016 can now introduce the first small read-only Atlas MCP service on
top of durable storage, workload identity, internal networking, and an
observable application path.

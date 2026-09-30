# DEEP MECHANICS · AKS Monitoring

> Level 2 — the observability stack (Container Insights, Managed Prometheus,
> Grafana), what to watch, and the control-plane vs workload split.

---

## 0. The precise mental model
AKS monitoring = **observing the cluster at three layers**: **control plane** (API server, etcd — Microsoft-managed, surfaced via diagnostic logs), **nodes/infrastructure** (CPU/mem/disk), and **workloads/Pods** (app health, restarts, latency). Azure's managed stack: **Container Insights** (logs/metrics), **Azure Monitor Managed Prometheus** (metrics), and **Managed Grafana** (dashboards) → the golden-signals view without running your own stack.

---

## 1. The three layers to watch
- **Control plane** — API server latency/throttling, etcd health → **AKS diagnostic settings** to Log Analytics (kube-apiserver, kube-scheduler logs).
- **Nodes** — CPU/memory/disk pressure, node NotReady, PLEG.
- **Workloads** — Pod restarts/CrashLoopBackOff, OOMKills, readiness failures, HPA behavior, request latency/errors.

## 2. The managed stack
- **Container Insights** — collects **container logs (stdout/stderr)** + inventory + metrics into **Log Analytics**; query with **KQL**.
- **Azure Monitor Managed Prometheus** — scrapes Prometheus metrics (cluster + app) at scale, managed (no self-hosted Prometheus).
- **Azure Managed Grafana** — dashboards over Prometheus/Log Analytics.
- **Defender for Containers** — security/runtime signals.

## 3. Metrics vs logs (route correctly)
- **Metrics (Prometheus)** — numeric time series for dashboards/alerts (CPU, request rate, HPA metrics). Low-cardinality.
- **Logs (Container Insights/Log Analytics)** — container stdout + K8s events for forensics (KQL).
- **Traces** — app-level via OpenTelemetry → App Insights (see Observability deep dive).

## 4. Key signals & alerts
- **Golden signals** per service (latency, traffic, errors, saturation).
- Node: CPU/mem/disk pressure, node not ready.
- Pod: restart count, CrashLoopBackOff, OOMKilled, pending (scheduling failures → CA), readiness failing.
- Alert on **symptoms/SLO burn**, not raw CPU (avoid noise).

## 5. Cost of monitoring
Log ingestion/retention is a real cost → sample/scope (basic logs tier, table transformations, drop noisy namespaces). Same cardinality/retention discipline as general observability.

## 6. The hard follow-ups (with answers)
1. **"How do you monitor an AKS cluster?"** → Container Insights (logs) + Managed Prometheus (metrics) + Managed Grafana (dashboards) across control-plane/node/workload layers. (§1,2)
2. **"See control-plane health?"** → diagnostic settings → kube-apiserver/scheduler logs to Log Analytics. (§1)
3. **"Metrics vs logs?"** → Prometheus numeric time series for dashboards/alerts vs Log Analytics/KQL for forensics. (§3)
4. **"Debug a CrashLoopBackOff?"** → Pod restart metric + container logs (Container Insights) + events; check OOMKilled/readiness. (§4)
5. **"Control monitoring cost?"** → scope/sample log ingestion, basic-logs tier, drop noisy data (cardinality discipline). (§5)

## 7. One-screen recall
- Monitor **3 layers**: **control plane** (API/etcd via diagnostic logs), **nodes** (CPU/mem/disk/NotReady), **workloads** (restarts/OOM/latency/HPA).
- Managed stack: **Container Insights** (container logs→Log Analytics/KQL) + **Managed Prometheus** (metrics) + **Managed Grafana** (dashboards) + **Defender for Containers**.
- **Metrics** (Prometheus, dashboards/alerts) vs **logs** (Log Analytics, forensics) vs **traces** (OTel→App Insights).
- Alert on **golden signals / SLO burn**; watch CrashLoopBackOff/OOMKilled/Pending.
- **Cost**: scope/sample ingestion (cardinality/retention discipline).

> Next: AKS Cost Optimization.

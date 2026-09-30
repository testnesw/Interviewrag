# DEEP MECHANICS · Horizontal Pod Autoscaler (HPA)

> Level 2 — the scaling formula, metrics sources, KEDA for event-driven scaling,
> and HPA vs VPA vs Cluster Autoscaler.

---

## 0. The precise mental model
HPA **automatically adjusts the number of Pod replicas** to match observed load, using a **control loop**: measure a metric (CPU/memory/custom), compare to a **target**, and compute the desired replica count via a simple ratio formula. It scales **out/in** (more/fewer Pods) — distinct from VPA (bigger Pods) and Cluster Autoscaler (more nodes).

---

## 1. The scaling formula (know it)
```
desiredReplicas = ceil( currentReplicas × (currentMetric / targetMetric) )
```
E.g., 3 replicas at 80% CPU, target 40% → ceil(3 × 80/40) = **6**. The HPA controller re-evaluates every ~15s.

## 2. Metrics sources
- **Resource metrics** (CPU/memory) via **metrics-server** — the basics.
- **Custom metrics** (requests/sec, queue length) via the custom/external metrics API (Prometheus Adapter).
- **External metrics** (cloud queue depth) — leads to KEDA.

## 3. Stabilization & behavior (avoid thrashing)
- **Cooldown/stabilization windows** (esp. scale-down) prevent flapping.
- **behavior** policies cap how fast it scales up/down (pods or % per period).
- Requires Pod **resource requests** set (HPA needs them to compute utilization %).

## 4. KEDA — event-driven autoscaling (the modern add-on)
**KEDA** extends HPA to scale on **external event sources** (Service Bus/queue length, Kafka lag, Event Hub, cron, Prometheus) — and uniquely **scale to zero** when idle (HPA alone can't go to 0). On AKS, KEDA is the standard for event-driven workloads. It creates an HPA under the hood driven by its **scalers**.

## 5. The three autoscalers (don't conflate)
- **HPA** — more/fewer **Pods** (horizontal).
- **VPA** — right-size **Pod CPU/memory requests** (vertical); usually not with HPA on same metric.
- **Cluster Autoscaler** — more/fewer **nodes** when Pods can't schedule / nodes idle.
Chain: HPA adds Pods → if no room, **Cluster Autoscaler adds nodes**.

## 6. The hard follow-ups (with answers)
1. **"How does HPA decide replica count?"** → desired = ceil(current × currentMetric/targetMetric). (§1)
2. **"What metrics can it use?"** → CPU/memory (metrics-server) + custom/external (Prometheus/KEDA). (§2)
3. **"Scale to zero?"** → not plain HPA; use **KEDA** (event-driven, scale-to-0). (§4)
4. **"HPA vs VPA vs Cluster Autoscaler?"** → more Pods vs bigger Pods vs more nodes. (§5)
5. **"HPA flapping — fix?"** → stabilization windows + behavior policies; ensure requests set. (§3)
6. **"Scale on queue length?"** → KEDA scaler (Service Bus/Kafka/Event Hub). (§4)

## 7. One-screen recall
- HPA = autoscale **replica count** via loop: **desired = ceil(current × metric/target)** (~15s).
- Metrics: CPU/mem (**metrics-server**) + custom/external (Prometheus adapter). **Requests required** for %.
- **Stabilization windows + behavior policies** prevent thrashing.
- **KEDA** = event-driven scaling (queue/Kafka/Event Hub/cron) + **scale-to-zero** (HPA can't).
- **HPA (pods) vs VPA (pod size) vs Cluster Autoscaler (nodes)**; HPA→no room→CA adds nodes.

> Next: Cluster Autoscaler.

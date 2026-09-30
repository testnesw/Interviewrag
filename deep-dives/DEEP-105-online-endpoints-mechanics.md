# DEEP MECHANICS · Online & Batch Endpoints

> Level 2 — managed online endpoints, deployments + traffic splitting, blue-green/
> canary, autoscaling, and online vs batch scoring.

---

## 0. The precise mental model
An **endpoint** is the stable HTTPS front for serving a model; **deployments** sit behind it holding the actual model+compute. This **endpoint/deployment split** is what enables **safe rollout**: put a new deployment behind the same endpoint, shift a slice of traffic, validate, then cut over — all without changing the client URL. **Online** = low-latency real-time; **Batch** = high-throughput scoring of large datasets.

---

## 1. Endpoint vs deployment (the key abstraction)
- **Endpoint** — stable URL + auth (key/token/Entra). Clients only ever see this.
- **Deployment** — a versioned model + environment + compute (instance type/count) behind the endpoint. Multiple deployments can coexist under one endpoint with a **traffic split** (e.g., blue 90 / green 10).

## 2. Managed online endpoints
Fully managed real-time serving:
- Scoring script (`init()` loads model, `run()` scores) + environment + compute SKU.
- **Autoscaling** (rules on CPU/latency/requests).
- Built-in **auth, logging (App Insights), health probes**.
- No cluster to manage (vs Kubernetes online endpoints if you need AKS control).

## 3. Blue-green & canary via traffic split
```
Endpoint  ── 100% → blue (v1)
Deploy green (v2) at 0% → smoke test → shift 10% → watch metrics
→ 50% → 100% → delete blue        (rollback = shift back to blue)
```
Because the endpoint URL is constant and traffic is a dial, rollout/rollback is instant and low-risk.

## 4. Online vs batch
| | **Online endpoint** | **Batch endpoint** |
|---|---|---|
| Latency | ms, real-time | minutes/hours |
| Input | single/small request | large datasets/files |
| Compute | always-on (or scale) | on-demand cluster, scale-to-0 |
| Use | user-facing inference | nightly scoring, ETL predictions |

## 5. Scaling & cost
- Online: right-size SKU + autoscale; keep min instances for latency, cap max for cost.
- Batch: uses a compute cluster that **scales to 0** when idle → pay per job.
- GPU only where needed (deep models); CPU for classical.

## 6. The hard follow-ups (with answers)
1. **"Endpoint vs deployment?"** → endpoint = stable URL/auth; deployment = model+env+compute behind it; enables traffic split. (§1)
2. **"How do you do zero-downtime rollout?"** → new deployment under same endpoint, shift traffic %, validate, cut over; rollback = shift back. (§3)
3. **"Online vs batch endpoint?"** → real-time low-latency vs high-throughput dataset scoring (scale-to-0). (§4)
4. **"How does autoscaling work?"** → rules on CPU/latency/RPS scale deployment instances; min for latency, max for cost. (§2,5)
5. **"Secure the endpoint?"** → key/token/Entra auth + private endpoint/VNet + managed identity to pull model. (§2)

## 7. One-screen recall
- **Endpoint** = stable URL+auth (clients see this) → **Deployments** (model+env+compute) behind it with **traffic split**.
- **Managed online endpoint**: scoring script (init/run), autoscale, auth, App Insights, health probes; no cluster mgmt.
- **Blue-green/canary** = dial traffic 0→10→50→100 across deployments; instant rollback.
- **Online** (ms real-time, always-on) vs **Batch** (bulk scoring, cluster scale-to-0).
- Scale/cost: right-size SKU, min instances for latency, GPU only where needed.

> Next: Data Engineering.

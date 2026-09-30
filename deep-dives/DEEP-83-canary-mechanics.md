# DEEP MECHANICS · Canary Deployment

> Level 2 — progressive traffic shifting, metric-based promotion, automated
> rollback, and tooling.

---

## 0. The precise mental model
Canary exposes the new version to a **small % of real traffic first**, watches **health/business metrics**, and **gradually increases** the share if healthy — or **auto-rolls back** if metrics degrade. It trades speed for **blast-radius control**: only a few users hit a bad release before it's caught.

---

## 1. The mechanism
```
100% → v1
  5% → v2 (canary), 95% → v1   → observe metrics
 25% → v2 ...                   → observe
 50% → v2 ...                   → observe
100% → v2 (promote); retire v1  (or rollback if metrics bad)
```
- Traffic split at a **smart router / service mesh / ingress** by weight.
- Each step gated on **metric analysis** (error rate, latency, saturation, business KPIs).

## 2. Why use it
- **Minimal blast radius**: bad release affects only the canary %.
- **Real-traffic validation** (catches issues synthetic tests miss).
- **Data-driven promotion** + automated rollback on SLO breach.

## 3. Metric-based analysis (the heart of it)
- Compare **canary vs baseline** (v2 subset vs v1 subset) on the **golden signals**: error rate, latency (p95/p99), traffic, saturation, plus KPIs (conversion).
- Statistical comparison → promote / hold / rollback automatically.
- Requires **good observability** (metrics/traces) — canary without metrics is just a slow rollout.

## 4. Tooling
- **Service mesh** (Istio/Linkerd) for precise traffic weighting + telemetry.
- **Argo Rollouts / Flagger** → automate steps + metric analysis + rollback on Kubernetes.
- **Azure**: Front Door / App Gateway weighted backends; AKS + Flagger.

## 5. Canary vs blue-green vs rolling
| | Exposure | Rollback | Extra infra | Needs metrics |
|---|---|---|---|---|
| Canary | gradual % | route back / halt | ~1× | **yes (key)** |
| Blue-green | all at once | flip env | 2× | optional |
| Rolling | pod-by-pod | slow | ~1× | optional |

## 6. Considerations
- **Session affinity**: a user should stick to one version during a session.
- **DB compatibility**: like blue-green, both versions share the DB → backward-compatible schema (expand-contract).
- **Enough traffic** needed for statistical signal; low-traffic services → longer windows.
- Guardrails: max unavailable, automatic abort thresholds.

## 7. The hard follow-ups (with answers)
1. **"Canary vs blue-green?"** → canary = gradual % with metric gates; blue-green = instant 100% switch. (§5)
2. **"What makes canary 'smart'?"** → **automated metric analysis** (canary vs baseline on golden signals) → promote/rollback. (§3)
3. **"Prerequisite?"** → strong **observability**; otherwise it's just slow rolling. (§3)
4. **"K8s tooling?"** → **Argo Rollouts / Flagger** (+ service mesh for traffic split). (§4)
5. **"Low-traffic service problem?"** → insufficient statistical signal → longer analysis windows. (§6)
6. **"Shared DB during canary?"** → backward-compatible schema (expand-contract). (§6)

## 8. One-screen recall
- **Gradual %** to v2 (5→25→50→100) gated on **metrics**; auto-rollback on breach.
- **Win**: minimal blast radius + real-traffic, **data-driven** promotion.
- **Analysis**: canary vs baseline on **golden signals** (error/latency/saturation/KPIs) → needs observability.
- **Tools**: Istio/Linkerd + **Argo Rollouts/Flagger**; Azure Front Door/App Gateway weights.
- **Watch**: session affinity, backward-compatible DB, enough traffic for signal.
- **vs blue-green**: gradual+metrics vs instant switch.

> Next: GitOps.

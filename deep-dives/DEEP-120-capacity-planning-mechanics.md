# DEEP MECHANICS · Capacity Planning

> Level 2 — demand forecasting, headroom, scaling strategy, quotas/limits, and
> performance modeling.

---

## 0. The precise mental model
Capacity planning = **matching provisioned resources to forecasted demand** at acceptable **performance + cost + risk**. You estimate load (peak, growth, spikes), model resource needs with **headroom** for failures/bursts, and design **elasticity** so the system scales without over-provisioning. It's a continuous cycle: **forecast → provision → measure → adjust**.

---

## 1. Inputs (know the demand)
- **Baseline + peak** load (RPS, concurrent users, data volume), **growth rate**, **seasonality/spikes** (Black Friday), **latency/SLO targets**.
- Derive from historical metrics + business projections.

## 2. Headroom & the N+1 principle
- Never provision to 100% — keep **headroom** (e.g., target 60–70% utilization) for spikes + failures.
- **N+1 / N+2 redundancy**: size so the system survives losing 1 (or 2) nodes/zones at peak (a failed AZ shouldn't tip you over).
- Buffer for **autoscale lag** (cold start / provisioning time).

## 3. Scaling strategy
- **Vertical** (bigger instance — simple, limited, has a ceiling + restart) vs **horizontal** (more instances — elastic, needs statelessness).
- **Reactive autoscale** (metric-triggered) vs **predictive/scheduled** (known patterns, pre-warm for spikes autoscale can't react to fast enough).
- Design **stateless** + queue-based load leveling to absorb bursts.

## 4. Quotas & limits (the gotcha)
- Azure **subscription/region quotas** (vCPU cores, public IPs, API rate limits, PTU for AOAI) cap scale → **request increases ahead of time**.
- Service limits (e.g., Cosmos RU/s, Event Hubs TUs, AKS node limits) → plan + raise proactively.
- Regional capacity constraints for specialized SKUs (GPUs).

## 5. Performance modeling
- **Little's Law**: $L = \lambda W$ (concurrency = arrival rate × latency) → estimate needed concurrency/instances.
- **Load/stress testing** to find the per-instance throughput → derive instance count = peak load ÷ per-instance capacity ÷ target utilization.
- Identify the **bottleneck resource** (CPU/memory/IO/DB connections) — capacity is gated by the tightest one.

## 6. Cost trade-off
- Over-provision = wasted spend; under-provision = SLO breach/outage.
- Combine **baseline reserved capacity** (cheap, committed) + **elastic on-demand/spot** for peaks → cost-efficient elasticity (ties to FinOps/pricing).

## 7. The hard follow-ups (with answers)
1. **"How much capacity?"** → forecast peak × growth, size to target utilization (~60–70%) with **headroom + N+1**. (§1/§2)
2. **"Why not run at 100%?"** → no room for spikes/failures/autoscale lag → outages. (§2)
3. **"Vertical vs horizontal?"** → vertical = bigger box (ceiling, restart); horizontal = more boxes (elastic, needs stateless). (§3)
4. **"Autoscale can't react fast enough?"** → **predictive/scheduled** pre-warming for known spikes. (§3)
5. **"Hit a scaling wall in Azure?"** → **subscription/service quotas** → request increases proactively. (§4)
6. **"Estimate instance count?"** → **Little's Law** + load test per-instance throughput ÷ target util. (§5)
7. **"Balance cost vs capacity?"** → reserved baseline + elastic/spot peaks. (§6)

## 8. One-screen recall
- **Match resources to forecast** at target perf/cost/risk; cycle: forecast→provision→measure→adjust.
- **Inputs**: baseline/peak load, growth, spikes, SLOs.
- **Headroom**: ~60–70% util + **N+1/N+2** + autoscale-lag buffer.
- **Scale**: vertical (ceiling) vs horizontal (elastic/stateless); reactive vs **predictive/scheduled**.
- **Quotas**: Azure subscription/service limits → raise proactively (vCPU, RU/s, TU, PTU, GPU).
- **Model**: **Little's Law** ($L=\lambda W$) + load test → instance count; find bottleneck.
- **Cost**: reserved baseline + elastic/spot peaks.

> Next: Solution Architecture.

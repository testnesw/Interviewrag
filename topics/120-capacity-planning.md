# 120 · Capacity Planning

> Domain: FinOps · Level: Principal Cloud / FinOps Architect

## 1. Beginner Explanation
Capacity planning means **making sure you have enough resources to handle demand — but not too much**. You forecast how much compute, storage, and throughput you'll need, so the system performs well under load without wasting money on idle capacity.

## 2. Architect-Level Explanation
Forecasting and provisioning resources to meet demand at target performance + cost:
- **Goal**: balance **performance/reliability** vs **cost** — avoid both under-provisioning (outages, SLA breaches) and over-provisioning (waste).
- **Inputs**: historical usage/metrics, growth trends, seasonality, business forecasts (campaigns, launches), SLOs (latency/throughput/availability), peak vs average.
- **Methods**: baseline + peak analysis, trend/regression forecasting, load/stress testing, **headroom** buffers, percentile-based sizing (p95/p99).
- **Elastic vs fixed**: cloud shifts capacity planning from static sizing to **autoscaling policies** + **limits/quotas** — plan the *scaling envelope* (min/max), not a fixed box. Still need base capacity + burst strategy.
- **Constraints**: **subscription/region quotas** (vCPU limits), service limits, reservation coverage, GPU/SKU availability in region.
- **Reliability**: N+1 redundancy, zone/region capacity for DR, failover headroom, avoiding single points.
- **Commitment alignment**: size Reservations/Savings Plans to the forecasted **steady baseline**; use on-demand/Spot for variable/peak.
- **Continuous**: monitor → forecast → adjust (scaling policies, quotas, reservations) as an ongoing loop.
- **Techniques**: queuing theory, Little's Law, load testing (k6/JMeter/Locust), chaos testing for capacity limits.

## 3. Real Enterprise Use Case
A retailer plans for **Black Friday**: analyzes prior peaks + growth, load-tests to find breaking points, sets AKS/App Service **autoscale envelopes** (min for baseline, max for peak) with pre-scaled warm capacity, raises **regional vCPU + GPU quotas** ahead of time, ensures **N+1 zone redundancy** and DR capacity, buys Reservations for the steady baseline and uses **Spot/on-demand** for burst — hitting p99 latency SLOs at 10x traffic without permanent over-provisioning.

## 4. Architecture Diagram (ASCII)
```
   Inputs: history + growth + seasonality + business forecast + SLOs
        ▼
   Forecast (trend/regression, peak vs avg, p95/p99) + Load testing
        ▼
   Plan the SCALING ENVELOPE (not a fixed box):
      base capacity (Reservations) ── autoscale min ──► max (Spot/on-demand burst)
   Constraints: region/sub QUOTAS · SKU/GPU availability · service limits
   Reliability: N+1 · zone/region DR headroom · failover
        ▼  monitor ─► forecast ─► adjust  (continuous loop)
```

## 5. Interview Questions
1. What is capacity planning and its goal?
2. How does cloud change capacity planning (vs on-prem)?
3. What inputs and methods do you use to forecast?
4. How do quotas and reservations factor in?
5. How do you plan for peak events and DR?

## 6. Strong Interview Answers
- **Goal**: "Provision enough capacity to meet demand at target SLOs without over-paying for idle resources. It's a balance — under-provisioning risks outages and SLA breaches; over-provisioning wastes money. I size to sustained + peak needs with sensible headroom."
- **Cloud vs on-prem**: "On-prem you buy fixed hardware for peak (expensive, slow). Cloud shifts you to planning a **scaling envelope** — autoscale min/max policies + quotas — so you provision elastically to demand. But it's not 'infinite': I still plan base capacity, burst strategy, and watch **quotas** and regional SKU availability. Capacity planning becomes designing scaling behavior, not sizing a static box."
- **Inputs/methods**: "Historical metrics, growth trends, seasonality, and business events (launches/campaigns), tied to SLOs. Methods: peak vs average analysis, percentile sizing (p95/p99), trend/regression forecasting, and **load/stress testing** to find real breaking points, plus headroom buffers. Little's Law/queuing theory for throughput/concurrency."
- **Quotas/reservations**: "I pre-check and **raise subscription/region quotas** (vCPU, GPU) before scale events — quotas are a common cause of failed scale-outs. I align **Reservations/Savings Plans** to the forecasted steady baseline (max discount on what I always run) and use on-demand/Spot for variable peak — so commitments don't lock in over-provisioning."
- **Peak/DR**: "For peaks: load-test, pre-scale warm capacity, raise quotas, and set autoscale max high enough. For DR: ensure the failover region/zones have **reserved headroom** to absorb full load (N+1), test failover at capacity, and account for correlated demand. Plan capacity for the failure scenario, not just steady state."

## 7. Common Mistakes
- Hitting **quota limits** during scale-out (not raised ahead).
- Sizing to average, not peak/p99 → SLA breaches under load.
- Over-provisioning "for safety" → chronic waste.
- No load testing → unknown breaking points.
- No DR/failover capacity headroom → cascading outage on failover.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| High headroom | safe under spikes | costly idle |
| Aggressive autoscale | cost-efficient | scale-up lag risk |
| Reserve baseline | discount | commitment risk if demand drops |

## 9. Production Best Practices
- Forecast from metrics + business events; size to p95/p99 + headroom.
- Plan autoscale envelopes (min/max) + warm/pre-scale for known peaks.
- Raise quotas ahead; verify regional SKU/GPU availability.
- Reservations for baseline, Spot/on-demand for burst.
- N+1 + zone/region DR headroom; load + failover testing; monitor→forecast→adjust loop.

## 10. Security Considerations
- Don't under-provision security/logging capacity under load.
- Ensure DR capacity meets compliance RTO/RPO.
- Quota governance (prevent both starvation and uncontrolled sprawl).

## 11. Cost Optimization
- Right-size envelopes (avoid excess headroom); scale-to-zero off-peak.
- Reservations/Savings Plans on the true baseline; Spot for burst/batch.
- Autoscale to demand instead of static peak provisioning; review forecasts.

## 12. Troubleshooting Scenarios
- **Scale-out fails at peak** → quota limit; raise vCPU/GPU quota proactively.
- **Latency SLO breached under load** → sized to average; resize to p99 + autoscale.
- **Idle over-capacity** → too much headroom/static peak; move to autoscale + right-size.
- **Failover overwhelmed** → no DR headroom; reserve N+1 capacity.
- **Slow scale-up** → cold start/provisioning lag; pre-warm/predictive scaling.

## 13. Hands-on Example
```bash
# Check + raise regional vCPU quota before a scale event
az vm list-usage --location eastus -o table
az quota update --resource-name standardDSv3Family --scope $LOCATION_SCOPE --limit 500
```

## 14. Terraform Example
```hcl
# Plan the scaling envelope (min baseline → max burst) + reserved-style baseline
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name = "app" kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size = "Standard_D4s_v5"
  enable_auto_scaling = true min_count = 3 max_count = 30   # envelope for peak
}
```

## 15. Azure Example
```bash
# Autoscale envelope for App Service; pre-scale before a known peak window
az monitor autoscale create -g rg --resource $PLAN --resource-type Microsoft.Web/serverfarms \
  --name peak --min-count 4 --max-count 40 --count 6
az monitor autoscale rule create -g rg --autoscale-name peak \
  --condition "CpuPercentage > 70 avg 5m" --scale out 4
```

## 16. FastAPI / Python Example
```python
# Simple capacity forecast: project required instances from growth + p99 throughput
def instances_needed(current_rps: float, growth: float, rps_per_instance: float,
                     headroom: float = 0.3) -> int:
    projected = current_rps * (1 + growth)          # forecast demand
    import math
    return math.ceil(projected / rps_per_instance * (1 + headroom))  # + headroom buffer
```

## 17. AKS Example
AKS capacity planning combines **Cluster Autoscaler** (node envelope min/max), **HPA/KEDA** (pod scaling on CPU/RPS/queue), right-sized requests/limits (drives bin-packing + scaling accuracy), pre-checked **regional vCPU/GPU quotas**, and **N+1 across zones**. Load-test to set the max node count; reserve baseline nodes, burst on Spot — meeting SLOs at peak without idle waste.

## 18. How to Remember
**"Enough but not too much: forecast (history+growth+peak, p99) + load test; plan the scaling ENVELOPE (min/max) not a fixed box; watch QUOTAS; reserve baseline + Spot burst; N+1 DR headroom; monitor→forecast→adjust."**

## 19. Real-World Analogy
Planning staff for a restaurant: you study past busy nights and upcoming holidays (forecast), keep a core team always on (baseline/Reservations), and call in on-call staff for rushes (autoscale/Spot) rather than hiring everyone full-time (over-provisioning). You confirm you're *allowed* enough staff (quotas), keep backups for no-shows (N+1), and adjust the schedule every week based on how busy it actually was.

## 20. One-Page Cheat Sheet
- **Goal**: meet demand at SLOs without over-paying — avoid under- and over-provisioning.
- **Inputs**: history + growth + seasonality + business events + SLOs; size to **p95/p99** + headroom.
- **Cloud shift**: plan the **scaling envelope** (autoscale min/max) + burst strategy, not a fixed box.
- **Constraints**: region/subscription **quotas** (vCPU/GPU) — raise ahead; SKU availability; service limits.
- **Cost**: Reservations for baseline, **Spot/on-demand** for burst; scale-to-zero off-peak.
- **Reliability**: N+1 + zone/region **DR headroom**; **load + failover testing**; continuous monitor→forecast→adjust.

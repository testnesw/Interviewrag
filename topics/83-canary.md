# 83 · Canary Deployment

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
Canary deployment releases a new version to a **small percentage of users first** (say 5%), watches how it behaves, and gradually increases traffic if all looks good — or rolls back if problems appear. It limits the impact of a bad release.

## 2. Architect-Level Explanation
Progressive delivery that shifts traffic incrementally while monitoring health:
- **Steps**: deploy new version alongside stable → route small % (5%) → **analyze metrics** (error rate, latency, saturation, business KPIs) → progressively increase (5→25→50→100) → or **auto-rollback** on breach.
- **Traffic splitting**: service mesh (Istio VirtualService weights), ingress annotations, **Argo Rollouts** / **Flagger**, or gateway/Front Door weighting.
- **Automated analysis**: compare canary vs baseline metrics (Prometheus, App Insights); metric-based promotion/abort — the key to safe automation.
- **vs blue-green**: canary limits blast radius (only a % affected) and enables real-user validation, at the cost of more complexity and running mixed versions simultaneously.
- **Session/DB**: same expand-contract DB compatibility needed; sticky sessions or version-safe contracts.
- **Feature flags** complement canary (decouple deploy from release; per-user targeting).
- **Metrics gates + bake time** prevent premature promotion.

## 3. Real Enterprise Use Case
A high-traffic API uses **Argo Rollouts** with Prometheus analysis: 5% canary for 10 min, auto-checks error rate < 1% and p99 < 250 ms, then steps to 25/50/100%. A regression in the canary trips the analysis and auto-rolls back within minutes — only ~5% of users ever saw the bad version.

## 4. Architecture Diagram (ASCII)
```
        Traffic splitter (mesh/ingress/Argo Rollouts)
             │ 95% ─► STABLE (v1)
             │  5% ─► CANARY (v2)
                        │ analysis: error rate/p99/KPIs vs baseline
             ┌──────────┴───────────┐
       pass → 25% → 50% → 100%   fail → AUTO-ROLLBACK (0%)
   Feature flags target specific users | DB expand-contract compatible
```

## 5. Interview Questions
1. How does canary deployment work?
2. Canary vs blue-green?
3. How do you automate canary promotion/rollback?
4. What metrics decide promotion?
5. How do feature flags relate to canary?

## 6. Strong Interview Answers
- **How**: "Deploy the new version alongside stable, route a small traffic slice to it, analyze health metrics against the baseline, and progressively increase traffic if healthy — or automatically roll back if a threshold is breached."
- **vs blue-green**: "Canary limits blast radius — only a small percentage of users hit v2 initially, and I validate with real traffic before full rollout. Blue-green switches everyone at once. Canary is safer for risk but more complex and runs mixed versions concurrently."
- **Automate**: "Tools like **Argo Rollouts** or **Flagger** with metric analysis (Prometheus/App Insights): they define steps and analysis templates, query metrics during a bake time, and promote or abort automatically — no human watching dashboards."
- **Metrics**: "Error rate, latency (p95/p99), saturation, plus business KPIs (conversion, checkout success). I compare canary vs stable baseline, not just absolute values, to catch regressions."
- **Feature flags**: "Flags decouple deploy from release — I can ship code dark and enable it for a cohort independent of traffic weighting. Combined with canary, I get both infrastructure-level and feature-level progressive exposure and instant kill-switch."

## 7. Common Mistakes
- Promoting on absolute metrics without a baseline comparison.
- Too-short bake time (miss slow-burn issues).
- No automated analysis (manual, error-prone).
- Breaking DB changes incompatible with mixed versions.
- No business-metric gating (only infra metrics).

## 8. Trade-offs
| Aspect | Canary | Blue-Green |
|--------|--------|-----------|
| Blast radius | small % | all at flip |
| Complexity | higher | lower |
| Real-user validation | yes, gradual | after full flip |
| Mixed versions | yes | brief |

## 9. Production Best Practices
- Automated metric analysis (Argo Rollouts/Flagger) + bake time.
- Compare canary vs baseline; gate on infra + business KPIs.
- Progressive steps (5→25→50→100) with auto-rollback.
- Expand-contract DB compatibility for mixed versions.
- Pair with feature flags (kill switch, targeting).

## 10. Security Considerations
- Canary gets same security controls/secrets.
- Limit exposure of new attack surface during ramp.
- Audit rollout decisions; secure metric sources.

## 11. Cost Optimization
- Only a small extra replica set during ramp (cheaper than blue-green duplication).
- Auto-rollback avoids costly full-blast incidents.
- Scale canary minimally; reuse stable capacity.

## 12. Troubleshooting Scenarios
- **Bad version reached many users** → steps too fast / no analysis gate.
- **Flapping promote/rollback** → noisy metrics; tune thresholds/bake time.
- **Mixed-version errors** → incompatible DB/API contract.
- **Analysis can't query metrics** → Prometheus/App Insights integration.
- **Sticky-session issues** → user bounces between versions; add affinity.

## 13. Hands-on Example
```bash
kubectl argo rollouts get rollout api --watch     # live canary status
kubectl argo rollouts promote api                 # manual promote if needed
kubectl argo rollouts abort api                   # rollback
```

## 14. Terraform Example
```hcl
# Deploy Argo Rollouts controller via Helm for progressive delivery
resource "helm_release" "argo_rollouts" {
  name = "argo-rollouts" namespace = "argo-rollouts" create_namespace = true
  repository = "https://argoproj.github.io/argo-helm" chart = "argo-rollouts"
}
```

## 15. Azure Example
On AKS with the managed Istio add-on, a **Flagger** canary shifts weights via Istio VirtualService and queries **Azure Monitor Managed Prometheus** for analysis — auto-promoting or rolling back based on error-rate/latency SLOs.

## 16. FastAPI / Python Example
```python
# Expose the signals the canary analysis compares against baseline
from prometheus_client import Counter, Histogram
errors = Counter("http_errors_total", "errors", ["version"])
latency = Histogram("http_request_seconds", "latency", ["version"])

@app.middleware("http")
async def observe(req, call_next):
    with latency.labels(VERSION).time():
        resp = await call_next(req)
    if resp.status_code >= 500: errors.labels(VERSION).inc()
    return resp
```

## 17. AKS Example (Argo Rollouts canary spec)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata: { name: api, namespace: app }
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5
        - pause: { duration: 10m }
        - analysis: { templates: [{ templateName: success-rate }] }
        - setWeight: 25
        - pause: { duration: 5m }
        - setWeight: 50
        - setWeight: 100
```

## 18. How to Remember
**"Small % → analyze vs baseline → ramp up or auto-rollback."** Limits blast radius; automate with Argo Rollouts/Flagger; pair with feature flags.

## 19. Real-World Analogy
The "canary in a coal mine": send a small sentinel (5% of traffic) into the new version first. If it stays healthy, bring everyone in gradually; if it shows distress (metrics breach), everyone retreats immediately — only the canary was ever at risk.

## 20. One-Page Cheat Sheet
- **What**: shift traffic incrementally (5→25→50→100%) to the new version, analyzing health at each step.
- **Automate**: Argo Rollouts/Flagger + metric analysis (Prometheus/App Insights) + bake time → promote or auto-rollback.
- **Metrics**: error rate, p95/p99 latency, saturation, business KPIs — vs baseline.
- **vs blue-green**: small blast radius + real-user validation, but more complex + mixed versions.
- **DB**: expand-contract compatible; pair with **feature flags** (kill switch/targeting).
- **Splitting**: service mesh weights / ingress / gateway / Front Door.

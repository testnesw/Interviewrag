# 82 · Blue-Green Deployment

> Domain: DevOps & CI/CD · Level: Principal DevOps Architect

## 1. Beginner Explanation
Blue-green deployment runs **two identical environments** — "blue" (current live) and "green" (new version). You deploy the new version to green, test it, then switch all traffic from blue to green instantly. If something's wrong, you switch back.

## 2. Architect-Level Explanation
A release strategy using two parallel production environments with an instant traffic cutover:
- **Blue = live**, **green = new version** (fully deployed + validated before any user traffic).
- **Cutover**: flip a router/load balancer/Service/ingress/DNS to send 100% traffic to green.
- **Instant rollback**: switch back to blue (kept warm) — fast recovery, minimal MTTR.
- **Zero-downtime**: users never hit a half-deployed state.
- **vs canary**: blue-green is an all-at-once switch (simple, but full blast radius on the flip); canary is gradual (see topic 83).
- **Challenges**: **double resources** during overlap (cost); **stateful concerns** — database schema must be backward/forward compatible (expand-contract migrations) since both versions may touch the same DB; session/state draining.
- **Implementation**: two deployments + Service selector swap, two ingress backends, App Gateway/Front Door backend swap, or **Azure App Service deployment slots** (native blue-green).

## 3. Real Enterprise Use Case
A payments API uses App Service slots: the new version deploys to the "staging" slot (green), runs smoke/integration tests against production config, then **slot swap** flips it to production instantly with warm-up. If error rates spike, they swap back in seconds — zero downtime, instant rollback.

## 4. Architecture Diagram (ASCII)
```
        Router / LB / Service selector / Slot swap
                     │ 100% traffic
        ┌────────────┴────────────┐
   BLUE (v1, live)          GREEN (v2, new)
   ▲ keep warm for          ▲ deploy + test here first
     instant rollback         then flip 100% → GREEN
   Shared DB ─► must be backward/forward compatible (expand-contract)
   Rollback = flip back to BLUE
```

## 5. Interview Questions
1. How does blue-green work?
2. Blue-green vs canary?
3. How do you handle database changes with blue-green?
4. What are the cost/resource implications?
5. How do you implement it on Azure?

## 6. Strong Interview Answers
- **How**: "Two identical prod environments. The new version goes to green, gets validated with real prod config but no user traffic, then I flip the router to send 100% to green. Blue stays warm so rollback is an instant switch back."
- **vs canary**: "Blue-green switches everyone at once — simple and instant to roll back, but the flip exposes all users to v2 immediately. Canary shifts a small percentage first to limit blast radius but is more complex and slower. I pick blue-green for fast atomic cutover, canary when I want gradual risk reduction."
- **Database**: "The hard part — both versions may share one database across the cutover/rollback, so schema changes must be **backward and forward compatible** using expand-contract: add columns/tables first (expand), deploy code that works with both, then remove old ones later (contract). Never do a breaking migration in one step."
- **Cost**: "You run two full environments during the overlap, roughly doubling resources temporarily. I mitigate with autoscaling, tearing down blue after green is confirmed stable, or slots that are cheaper than full duplicates."
- **Azure**: "App Service **deployment slots** with slot swap are native blue-green with warm-up. On AKS I swap a Service selector or ingress/App Gateway backend between two deployments; Front Door backend switching for multi-region."

## 7. Common Mistakes
- Breaking DB migrations that make rollback impossible.
- Tearing down blue too early (no rollback path).
- Not warming green before the swap (cold-start errors).
- Ignoring in-flight sessions/connections at cutover.
- Forgetting the temporary double-cost.

## 8. Trade-offs
| Aspect | Blue-Green | Canary |
|--------|-----------|--------|
| Cutover | instant, atomic | gradual |
| Blast radius on flip | all users | small % first |
| Rollback | instant swap | shift back |
| Cost | double (overlap) | small extra |

## 9. Production Best Practices
- Expand-contract DB migrations (backward/forward compatible).
- Validate green with prod config + smoke tests before flip.
- Warm up green; drain blue connections gracefully.
- Keep blue warm until green is proven; then scale down.
- Automate swap + health-based auto-rollback.

## 10. Security Considerations
- Green gets same security controls/secrets as blue.
- Don't expose green publicly before validation (internal test route).
- Audit swaps; ensure both slots use least-privilege identity.

## 11. Cost Optimization
- Autoscale; tear down blue after confirmation.
- Use slots (cheaper than duplicate infra) where applicable.
- Short overlap window to minimize double-run cost.

## 12. Troubleshooting Scenarios
- **Errors right after swap** → green not warmed / config diff.
- **Rollback impossible** → breaking DB migration; use expand-contract.
- **Dropped requests at cutover** → no connection draining.
- **Double cost lingering** → blue not torn down.
- **DNS-based flip slow** → TTL caching; prefer LB/slot swap.

## 13. Hands-on Example
```bash
# AKS: swap Service selector from blue to green
kubectl patch service api -p '{"spec":{"selector":{"version":"green"}}}'
# rollback:
kubectl patch service api -p '{"spec":{"selector":{"version":"blue"}}}'
```

## 14. Terraform Example
```hcl
# App Service with a staging slot (native blue-green)
resource "azurerm_linux_web_app_slot" "green" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.api.id
  site_config { always_on = true }
}
# swap performed via: az webapp deployment slot swap
```

## 15. Azure Example
```bash
az webapp deployment slot swap -g rg -n api \
  --slot staging --target-slot production        # blue-green swap w/ warm-up
# rollback: swap again
```

## 16. FastAPI / Python Example
```python
# Health endpoint the deploy checks on green before the swap
@app.get("/health/ready")
async def ready():
    ok = await db_ok() and await deps_ok()
    return ({"status": "ready", "version": VERSION}, 200) if ok else ({"status":"warming"}, 503)
```

## 17. AKS Example
```yaml
# Two deployments (blue/green), one Service; flip the selector to cut over
apiVersion: v1
kind: Service
metadata: { name: api }
spec:
  selector: { app: api, version: green }   # was: blue
  ports: [{ port: 80, targetPort: 8080 }]
```

## 18. How to Remember
**"Two envs, flip all traffic, keep the old one warm to roll back."** DB must be backward/forward compatible (expand-contract).

## 19. Real-World Analogy
Two identical stages at a concert: the band sets up and sound-checks on stage B (green) while the audience watches stage A (blue). At the right moment the spotlight (traffic) swings entirely to stage B — and if the mic fails, it swings instantly back to stage A.

## 20. One-Page Cheat Sheet
- **What**: two identical prod envs (blue=live, green=new); validate green, flip 100% traffic, keep blue warm.
- **Pros**: zero-downtime, instant atomic rollback.
- **Cons**: double resources during overlap; full blast radius on flip.
- **DB**: expand-contract, backward/forward compatible (rollback-safe).
- **Cutover**: Service selector / ingress / App Gateway backend / **App Service slot swap** / Front Door.
- **vs canary**: all-at-once vs gradual; warm + drain + auto-rollback on health.

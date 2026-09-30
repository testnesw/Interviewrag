# DEEP MECHANICS · Blue-Green Deployment

> Level 2 — the two-environment switch, traffic cutover, rollback, and DB
> compatibility.

---

## 0. The precise mental model
Blue-green runs **two identical production environments** — **Blue** (live) and **Green** (idle/new). You deploy the new version to Green, verify it, then **flip all traffic** from Blue to Green at the router/load balancer. Rollback = flip back. Payoff = **near-zero downtime** + **instant rollback**; cost = **double infrastructure** during the switch.

---

## 1. The mechanism
```
Users → [Router/LB] → Blue (v1, live)
                       Green (v2, deployed + tested, idle)
   switch → Router → Green (v2 live);  Blue kept as instant rollback
```
- Cutover happens at a **traffic director**: LB, App Gateway, Front Door, DNS, or K8s Service selector.
- Old env stays warm briefly → **instant rollback** by switching back.

## 2. Why use it
- **Zero/near-zero downtime** (switch is instant).
- **Instant, tested rollback** (no redeploy).
- Full **smoke/validation** on Green with real prod config before exposing users.

## 3. Cutover mechanics
- **All-at-once** switch (vs canary's gradual %). Blue-green = binary; canary = gradual.
- After switch + confidence window, Blue is decommissioned or becomes the next Green.

## 4. The hard parts
- **Cost**: 2× environment during overlap.
- **Database / shared state**: both versions may hit the same DB → schema changes must be **backward compatible** (expand/contract).
  - **Expand-contract**: add new columns (nullable) → deploy code using both → migrate data → remove old → keeps Blue AND Green working.
- **In-flight sessions / connection draining** during switch; sticky sessions complicate.
- Stateful components and long-running jobs need care.

## 5. On Azure / K8s
- **App Service deployment slots** = built-in blue-green (swap slots; warm-up + instant swap-back).
- **Front Door / App Gateway** weighted backends.
- **Kubernetes**: two Deployments + switch the **Service selector** label (or use Argo Rollouts).

## 6. Blue-green vs canary vs rolling
| | Traffic shift | Rollback | Cost | Risk exposure |
|---|---|---|---|---|
| Blue-green | 100% instant | instant (flip) | 2× | all users at once |
| Canary | gradual % | halt/route back | ~1× | few users first |
| Rolling | pod-by-pod | slow (roll back) | ~1× | mixed during roll |

## 7. The hard follow-ups (with answers)
1. **"How is rollback instant?"** → old (Blue) env stays live-capable → just switch the router back. (§1/§2)
2. **"Biggest challenge?"** → **DB schema compatibility** (both versions share DB) → expand-contract migrations. (§4)
3. **"Blue-green vs canary?"** → blue-green = all traffic at once (binary); canary = gradual % (progressive exposure). (§6)
4. **"Azure built-in way?"** → **App Service deployment slots** (swap). (§5)
5. **"Downside?"** → 2× infra cost + in-flight session/connection handling. (§4)
6. **"K8s implementation?"** → two Deployments, flip **Service selector** (or Argo Rollouts). (§5)

## 8. One-screen recall
- **Two identical prod envs**: Blue (live) + Green (new); deploy+test Green → **flip router** → Green live.
- **Wins**: ~zero downtime + **instant rollback** (flip back).
- **Costs**: 2× infra; **DB must be backward-compatible** (expand-contract); drain in-flight.
- **Switch point**: LB/App Gateway/Front Door/DNS/K8s Service selector.
- **Azure**: App Service **slots**. **vs canary**: all-at-once vs gradual.

> Next: Canary Deployment.

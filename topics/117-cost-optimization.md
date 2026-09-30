# 117 · Cloud Cost Optimization

> Domain: FinOps · Level: Principal Cloud / FinOps Architect

## 1. Beginner Explanation
Cloud cost optimization means **paying less for the cloud without hurting performance** — by turning off what you don't use, right-sizing resources, buying discounts for steady workloads, and picking the cheapest option that meets your needs.

## 2. Architect-Level Explanation
Systematic reduction of cloud spend while preserving performance/reliability:
- **Right-sizing**: match SKU/tier to actual utilization (CPU/mem/IOPS); downsize over-provisioned VMs/DBs/clusters.
- **Elasticity / scale-to-zero**: autoscaling, serverless (Functions/Container Apps), stop non-prod off-hours (schedules), scale down at night/weekends.
- **Pricing models**: **pay-as-you-go** vs **Reservations** (1/3-yr, ~40–60% off steady workloads) vs **Savings Plans** (flexible compute commitment) vs **Spot** (up to ~90% off, evictable — batch/fault-tolerant) vs **Azure Hybrid Benefit** (reuse Windows/SQL licenses).
- **Storage**: tiering (Hot/Cool/Cold/Archive) + lifecycle, delete orphaned disks/snapshots/IPs, right redundancy.
- **Waste elimination**: unattached disks, idle resources, zombie/dev leftovers, over-provisioned PaaS tiers, egress reduction (CDN/caching).
- **Architecture-level**: serverless/managed over always-on, caching, efficient data formats, region choice, consolidation.
- **Governance**: **tagging** (cost allocation), budgets + alerts, **Azure Advisor** cost recommendations, Cost Management analysis, showback/chargeback.
- **Continuous**: cost is an ongoing engineering practice (FinOps), not a one-time cleanup.

## 3. Real Enterprise Use Case
An enterprise cuts ~35% cloud spend: **right-sizes** over-provisioned VMs/AKS node pools via Advisor + metrics, moves batch/ML training to **Spot**, buys **Reservations/Savings Plans** for steady prod baseload, applies **Azure Hybrid Benefit** for SQL/Windows, **schedules** non-prod to stop nights/weekends, tiers cold Blob data to Archive with lifecycle rules, deletes orphaned disks/IPs, and enforces **tagging + budgets + alerts** — tracked continuously via Cost Management.

## 4. Architecture Diagram (ASCII)
```
   Cost Optimization Levers
   ┌──────────────┬───────────────┬────────────────┬──────────────┐
   Right-size     Elasticity       Pricing model     Eliminate waste
   (match SKU)    (autoscale/      (Reserve/Savings  (orphaned disks,
                   scale-to-0,      Plan/Spot/AHB)    idle, egress)
                   stop off-hours)
        │              │                │                 │
        └──────────────┴──── Governance ─┴─────────────────┘
   Tagging · Budgets+alerts · Azure Advisor · Cost Management (showback)
   Continuous practice (FinOps), not one-time
```

## 5. Interview Questions
1. What are the main cost-optimization levers?
2. Reservations vs Savings Plans vs Spot vs Hybrid Benefit?
3. How do you find and eliminate waste?
4. How does architecture affect cost?
5. How do you govern and sustain cost optimization?

## 6. Strong Interview Answers
- **Levers**: "Right-size to actual usage, use elasticity (autoscale/serverless/scale-to-zero and stop non-prod off-hours), choose the right pricing model (Reservations/Savings Plans/Spot/Hybrid Benefit), tier storage, and eliminate waste (orphaned/idle resources, egress). Then govern with tagging, budgets, and continuous review."
- **Pricing models**: "**Reservations** commit to specific resources (1/3-yr) for ~40–60% off steady workloads; **Savings Plans** commit to an hourly compute spend with flexibility across VM families/regions; **Spot** offers up to ~90% off surplus capacity but is evictable — great for fault-tolerant batch/ML; **Azure Hybrid Benefit** reuses existing Windows/SQL licenses. I layer them: Reservations/Savings Plans for baseload, Spot for elastic batch, PAYG for spiky."
- **Waste**: "I use **Azure Advisor**, Cost Management, and metrics to find over-provisioned SKUs, unattached disks, idle VMs/IPs, orphaned snapshots, empty AKS node pools, and untiered cold storage. Automated policies + regular reviews clean these up. Egress waste is cut with CDN/caching and regional placement."
- **Architecture**: "Design drives cost — serverless/managed services with scale-to-zero beat always-on VMs for spiky loads; caching (Redis/CDN) reduces DB/egress; efficient data formats (Parquet) + partitioning reduce scan/compute; right region and consolidation matter. The cheapest resource is the one you don't run."
- **Govern/sustain**: "**Tagging** for cost allocation, **budgets + alerts** to catch overruns, Advisor recommendations, and showback/chargeback to make teams accountable. It's a continuous FinOps practice with engineering ownership — not a one-off cleanup."

## 7. Common Mistakes
- Over-provisioning "just in case" → chronic waste.
- No Reservations/Savings Plans for obvious steady workloads.
- Leaving non-prod running 24/7.
- No tagging → can't allocate/attribute cost.
- One-time cleanup instead of continuous practice.

## 8. Trade-offs
| Lever | Pro | Con |
|-------|-----|-----|
| Reservations | big savings | commitment/lock-in |
| Spot | cheapest | eviction risk |
| Aggressive right-size | lower cost | headroom/perf risk |

## 9. Production Best Practices
- Right-size continuously (Advisor + metrics); scale-to-zero non-prod off-hours.
- Reservations/Savings Plans for baseload; Spot for batch; Hybrid Benefit.
- Storage tiering + lifecycle; delete orphaned resources (automation/policy).
- Tagging + budgets + alerts; Cost Management dashboards; showback/chargeback.
- Architect for elasticity + caching; review in sprint/FinOps cadence.

## 10. Security Considerations
- Don't sacrifice security/HA for cost (keep backups, redundancy, logging).
- RBAC on cost data + budget management; avoid risky under-provisioning of security tooling.
- Governance policies prevent unauthorized expensive/insecure resources.

## 11. Cost Optimization
- (This is the topic) — combine right-sizing + commitments + elasticity + waste removal + tiering + governance for compounding savings; measure savings realized.

## 12. Troubleshooting Scenarios
- **Unexpected bill spike** → check Cost Management by tag/resource; find new/egress/scaled resource.
- **Low reservation utilization** → wrong SKU/region committed; adjust/exchange.
- **Perf regression after right-size** → too aggressive; add headroom/autoscale.
- **Can't attribute cost** → missing tags; enforce tagging policy.
- **Spot evictions hurting jobs** → make workloads checkpoint/fault-tolerant or mix on-demand.

## 13. Hands-on Example
```bash
az advisor recommendation list --category Cost -o table          # find savings
az consumption budget create --budget-name prod --amount 50000 \
  --time-grain Monthly --category Cost                            # budget + alerts
```

## 14. Terraform Example
```hcl
resource "azurerm_consumption_budget_resource_group" "rg_budget" {
  name = "rg-monthly" resource_group_id = azurerm_resource_group.app.id
  amount = 20000 time_grain = "Monthly"
  notification { enabled = true threshold = 80 operator = "GreaterThan"
    contact_emails = ["finops@acme.com"] }   # alert at 80%
}
```

## 15. Azure Example
```bash
# Auto-shutdown non-prod VMs off-hours; use Spot for AKS batch node pool
az vm auto-shutdown -g rg -n devvm --time 1900
az aks nodepool add -g rg --cluster-name aks -n spotbatch \
  --priority Spot --eviction-policy Delete --spot-max-price -1
```

## 16. FastAPI / Python Example
```python
# Cost dashboard endpoint: pull spend by tag from Cost Management
from azure.mgmt.costmanagement import CostManagementClient
from azure.identity import DefaultAzureCredential

@app.get("/cost/by-team")
async def cost_by_team(scope: str):
    client = CostManagementClient(DefaultAzureCredential())
    # query grouped by 'team' tag → showback/chargeback
    return run_cost_query(client, scope, group_by="team")
```

## 17. AKS Example
Cut AKS cost with **Cluster Autoscaler** + scale-to-zero node pools, **Spot** node pools for fault-tolerant workloads, right-sized requests/limits (avoid over-request), **KEDA** scale-to-zero for event-driven pods, bin-packing, and **Reservations/Savings Plans** for the steady baseline node pool — plus Container Insights to spot idle/over-provisioned nodes.

## 18. How to Remember
**"Right-size + elasticity + right pricing (Reserve/Savings/Spot/AHB) + kill waste + tier storage + govern (tag/budget). Cheapest resource = one you don't run. Continuous, not one-time."**

## 19. Real-World Analogy
Managing a household's utility bills: turn off lights in empty rooms (scale-to-zero/stop off-hours), buy in bulk for what you always use (Reservations), grab discounted off-peak deals for flexible chores (Spot), cancel unused subscriptions (orphaned resources), insulate to cut waste (efficiency), and check the meter monthly with a budget alert (governance) — an ongoing habit, not a single spring cleaning.

## 20. One-Page Cheat Sheet
- **Levers**: right-size · elasticity (autoscale/serverless/scale-to-zero, stop non-prod) · pricing model · kill waste · storage tiering.
- **Pricing**: Reservations (steady, big discount) · **Savings Plans** (flexible compute) · **Spot** (cheapest, evictable) · **Hybrid Benefit** (license reuse).
- **Waste**: orphaned disks/IPs/snapshots, idle VMs, over-provisioned tiers, egress (use CDN/cache).
- **Govern**: **tagging** (allocation), budgets + alerts, **Azure Advisor**, Cost Management, showback/chargeback.
- **Architecture**: managed/serverless + caching + efficient data = structural savings.
- **Mindset**: continuous FinOps practice with engineering ownership.

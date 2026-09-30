# 119 · Azure Pricing & Cost Management

> Domain: FinOps · Level: Principal Cloud / FinOps Architect

## 1. Beginner Explanation
This is about **how Azure charges you and the tools to track it**. Azure bills based on what you use (compute hours, storage GB, data transfer), and Azure Cost Management lets you see, analyze, forecast, and control that spending.

## 2. Architect-Level Explanation
Understanding Azure's billing model + the Cost Management toolset:
- **Billing hierarchy**: **Billing account** (EA/MCA/CSP/PAYG) → **billing profile / invoice sections** → **subscriptions** → **resource groups** → resources. Management groups organize subscriptions for governance.
- **Pricing dimensions**: compute (vCPU-hours by SKU), storage (GB + tier + transactions + redundancy), **egress/data transfer** (inter-region/internet — often overlooked), IOPS, requests/operations, licensing.
- **Purchase models**: **PAYG**, **EA** (Enterprise Agreement), **MCA** (Microsoft Customer Agreement), **CSP** (partner). Affect discounts + billing.
- **Discount mechanisms**: **Reservations**, **Savings Plans for compute**, **Spot**, **Azure Hybrid Benefit**, negotiated/EA discounts, dev/test pricing.
- **Cost Management + Billing**: **Cost Analysis** (slice by dimension/tag/time), **Budgets** (+ alerts + action groups), **Cost alerts/anomaly detection**, **forecasting**, **exports** (to Storage), **recommendations** (via Advisor), **FOCUS** open cost format.
- **Cost allocation**: **tags**, subscriptions/RGs as boundaries, management-group rollups, cost-allocation rules for shared costs.
- **Azure Pricing Calculator** + **TCO Calculator** for estimation/planning.
- **APIs**: Cost Management API, Consumption API, Retail Prices API (programmatic cost).
- **Amortization**: amortized vs actual cost view (spreads reservation upfront cost).

## 3. Real Enterprise Use Case
An enterprise on an **MCA** organizes spend via management groups + subscriptions per business unit, enforces **tagging** for allocation, and uses **Cost Analysis** dashboards + **budgets with alerts** per team; a central team manages **Reservations/Savings Plans** and reviews **Advisor** recommendations; **anomaly detection** flags spikes; daily **exports** feed a FinOps data warehouse for unit-economics reporting; the **Pricing Calculator** sizes new projects before build.

## 4. Architecture Diagram (ASCII)
```
   Billing account (EA/MCA/CSP) ─► billing profile ─► Subscriptions
        │ Management Groups (governance rollup)
        ▼
   Resource Groups ─► Resources  (tags = cost allocation)
   Pricing dims: compute · storage(+tier/redundancy) · EGRESS · ops · license
   Discounts: Reservations · Savings Plans · Spot · Hybrid Benefit · EA
   ┌──────── Cost Management + Billing ────────┐
   Cost Analysis · Budgets+alerts · Anomaly · Forecast · Exports · Advisor
   Calculators (Pricing/TCO) · APIs (Cost/Consumption/Retail) · amortized view
```

## 5. Interview Questions
1. Explain Azure's billing hierarchy.
2. What cost dimensions do you watch (what's often missed)?
3. What does Cost Management provide?
4. EA vs MCA vs PAYG; how do discounts apply?
5. Actual vs amortized cost?

## 6. Strong Interview Answers
- **Hierarchy**: "Billing account (EA/MCA/CSP/PAYG) → billing profiles/invoice sections → subscriptions → resource groups → resources, with **management groups** organizing subscriptions for governance and cost rollup. This structure is how I allocate and govern spend across an org."
- **Dimensions**: "Compute (vCPU-hours by SKU), storage (GB + tier + redundancy + transactions), operations/requests, IOPS, licensing — and critically **data egress/transfer**, which is frequently overlooked and can dominate costs for chatty cross-region or internet-facing architectures. I design to minimize egress (co-locate, CDN, caching)."
- **Cost Management**: "**Cost Analysis** to slice spend by tag/RG/service/time; **Budgets** with alerts and automated actions; **anomaly detection** for spikes; **forecasting**; **exports** to storage for BI; and **Advisor** recommendations. It's the visibility + control layer that makes FinOps possible."
- **EA/MCA/PAYG**: "PAYG is retail pricing; **EA** (Enterprise Agreement) and **MCA** (Microsoft Customer Agreement) offer negotiated discounts and consolidated billing for larger orgs; **CSP** is via a partner. Discount mechanisms (Reservations/Savings Plans/Hybrid Benefit) apply on top regardless, but agreement type affects base rates and commitment terms."
- **Actual vs amortized**: "**Actual** cost shows charges as billed (e.g., a reservation's upfront payment appears as a lump sum). **Amortized** spreads that upfront cost evenly across the reservation term and distributes it to the resources that used it — giving a truer per-day/per-team unit cost for chargeback and trend analysis."

## 7. Common Mistakes
- Ignoring **egress/data transfer** costs in architecture.
- No tagging → can't allocate/analyze spend.
- No budgets/anomaly alerts → surprise bills.
- Using actual (not amortized) view for chargeback → distorted per-team costs.
- Not estimating with Pricing/TCO calculators before building.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| EA/MCA | discounts, consolidated | commitment/negotiation |
| Amortized view | true unit cost | less intuitive than actual |
| Tag-based allocation | granular | needs tag discipline |

## 9. Production Best Practices
- Structured billing hierarchy (MGs + subs per BU) + enforced tagging.
- Cost Analysis dashboards + budgets + alerts + anomaly detection per scope.
- Central Reservation/Savings Plan management; Advisor reviews.
- Daily exports to a FinOps warehouse; amortized view for chargeback.
- Estimate new workloads (Pricing/TCO calculators); minimize egress by design.

## 10. Security Considerations
- RBAC on Cost Management + billing scopes (least privilege).
- Protect exported cost data (business-sensitive).
- Governance (Azure Policy) to block unauthorized expensive/insecure SKUs/regions.

## 11. Cost Optimization
- Use Cost Analysis + Advisor to target waste; budgets to cap.
- Layer discounts (Reservations/Savings Plans/Hybrid Benefit) appropriately.
- Design to minimize egress/transactions; right tier/redundancy for storage.

## 12. Troubleshooting Scenarios
- **Surprise bill** → Cost Analysis by service/tag/time; often egress or a scaled/new resource.
- **Can't attribute costs** → missing tags; enforce tagging policy + allocation rules.
- **Reservation not applying** → scope/SKU/region mismatch; check utilization/scope.
- **Budget alert didn't fire** → threshold/scope/action group misconfig.
- **Per-team costs look wrong** → using actual not amortized; switch view.

## 13. Hands-on Example
```bash
az costmanagement query --type ActualCost --scope $SUB \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe MonthToDate                                  # analyze spend by RG
az consumption budget list --scope $SUB -o table
```

## 14. Terraform Example
```hcl
resource "azurerm_consumption_budget_subscription" "sub_budget" {
  name = "sub-monthly" subscription_id = data.azurerm_subscription.s.id
  amount = 100000 time_grain = "Monthly"
  notification { enabled = true threshold = 90 operator = "GreaterThan"
    contact_emails = ["finops@acme.com"] threshold_type = "Forecasted" }  # forecast alert
}
```

## 15. Azure Example
```bash
# Buy a compute Savings Plan / reservation recommendation review
az reservations reservation-order-recommendation list --scope $SUB
# Programmatic retail pricing (no auth) for estimation
curl "https://prices.azure.com/api/retail/prices?\$filter=serviceName eq 'Virtual Machines'"
```

## 16. FastAPI / Python Example
```python
# Estimate a workload's monthly cost via the Retail Prices API (planning tool)
import httpx
@app.get("/estimate/vm")
async def estimate(sku: str, hours: float):
    async with httpx.AsyncClient() as c:
        r = await c.get("https://prices.azure.com/api/retail/prices",
                        params={"$filter": f"armSkuName eq '{sku}' and priceType eq 'Consumption'"})
    rate = r.json()["Items"][0]["retailPrice"]
    return {"estimated_monthly": rate * hours}
```

## 17. AKS Example
AKS cost visibility uses Cost Analysis + **cost allocation by namespace/label** (OpenCost/Kubecost). Watch **egress** (cross-zone/region pod traffic, load balancer data), right node-pool SKUs, and apply **Savings Plans** to the steady node baseline + **Spot** for batch — with budgets/anomaly alerts scoped to the cluster's resource group.

## 18. How to Remember
**"Billing hierarchy (account→sub→RG→resource) + tags; watch EGRESS; discounts (Reserve/Savings/Spot/AHB); Cost Management = analysis + budgets + anomaly + forecast + export; amortized for chargeback."**

## 19. Real-World Analogy
A detailed utility bill + budgeting app for a large company campus: charges break down by building and meter (billing hierarchy + tags), including easy-to-miss items like water pumped between buildings (egress). The app shows usage trends, warns before you blow the budget (alerts/forecast), and spreads annual prepayments evenly so each department sees its true monthly share (amortized).

## 20. One-Page Cheat Sheet
- **Hierarchy**: billing account (EA/MCA/CSP/PAYG) → billing profile → **subscriptions → RGs → resources**; MGs for governance.
- **Dimensions**: compute · storage (tier/redundancy) · **egress/data transfer (often missed)** · ops · license.
- **Discounts**: Reservations · Savings Plans · Spot · Hybrid Benefit · EA/MCA.
- **Cost Management**: Cost Analysis · Budgets + alerts · anomaly detection · forecasting · exports · Advisor.
- **Allocation**: tags + subs/RGs + MG rollups; **amortized** view for chargeback.
- **Plan**: Pricing/TCO calculators + Retail Prices API; design to minimize egress.

# DEEP MECHANICS · FinOps

> Level 2 — the cultural practice, Inform/Optimize/Operate, unit economics,
> showback/chargeback, and cost accountability.

---

## 0. The precise mental model
FinOps is a **cultural + operational practice** bringing **financial accountability to the variable spend of cloud**. It makes **engineering, finance, and business** jointly own cost, using **near-real-time data** to make trade-offs between **cost, speed, and quality**. Cloud cost is a **shared, continuously-optimized** responsibility — not a quarterly finance report.

---

## 1. The three phases (iterative lifecycle)
- **Inform** — **visibility + allocation**: tag/label resources, cost dashboards, showback/chargeback, forecasting, budgets. "You can't optimize what you can't see."
- **Optimize** — **act**: rightsizing, reservations/savings plans, autoscaling, killing idle/orphaned resources, storage tiering.
- **Operate** — **govern continuously**: policies, automation, KPIs, cultural adoption, continuous improvement.
- The cycle repeats (a crawl → walk → run maturity model).

## 2. Cost allocation (foundation)
- **Tagging/labeling** (owner, cost center, env, project) → attribute every cost.
- **Showback** (report costs to teams for awareness) vs **Chargeback** (actually bill teams) → drives accountability.
- Management group / subscription / RG hierarchy for natural allocation.

## 3. Unit economics (maturity marker)
- Move beyond total spend to **cost per unit of value**: **$/transaction**, $/customer, $/API call, cost-of-goods-sold per feature.
- Lets you judge efficiency as you scale (is spend growth justified by value?).

## 4. Optimization levers
- **Rightsizing** (match SKU to real utilization), **reservations/savings plans** (commit → discount), **spot** for interruptible, **autoscale**, **schedule** non-prod off-hours, **delete orphaned** (unattached disks, idle IPs), **storage lifecycle tiering**.

## 5. Principles (FinOps Foundation)
- Teams **own their usage**; **business value** (not just lowest cost) drives decisions; **accessible, timely** cost data; a **central FinOps team enables** (doesn't gatekeep); take advantage of the **variable cost model**.

## 6. Roles & tooling
- Cross-functional: engineers, finance, product, leadership.
- Azure tooling: **Cost Management + Billing**, **Budgets + alerts**, **Advisor** recommendations, tags/policy; anomaly detection.

## 7. The hard follow-ups (with answers)
1. **"Is FinOps just cost-cutting?"** → no — it's **value optimization** + shared accountability; sometimes spending more is right if value justifies. (§0/§5)
2. **"The three phases?"** → **Inform → Optimize → Operate** (iterative). (§1)
3. **"Where does it start?"** → **Inform**: visibility + **tagging/allocation** (can't optimize what you can't see). (§2)
4. **"Showback vs chargeback?"** → showback = report for awareness; chargeback = actually bill teams. (§2)
5. **"Sign of maturity?"** → **unit economics** ($/transaction) not just total spend. (§3)
6. **"Who owns cloud cost?"** → **everyone** — engineering owns usage, enabled by a central FinOps team. (§5)
7. **"Concrete levers?"** → rightsizing, reservations/savings plans, spot, autoscale, kill idle, tiering. (§4)

## 8. One-screen recall
- **Culture + practice**: financial accountability for variable cloud spend; eng+finance+business shared ownership.
- **Phases**: **Inform** (visibility/tagging/showback) → **Optimize** (rightsize/reservations/kill idle) → **Operate** (govern/automate).
- **Allocation**: tags + showback/chargeback → accountability.
- **Maturity**: **unit economics** ($/transaction).
- **Principles**: value-driven, teams own usage, timely data, central team enables.
- **Azure**: Cost Management, Budgets, Advisor.

> Next: Azure Pricing.

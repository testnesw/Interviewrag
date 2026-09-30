# DEEP MECHANICS · Log Analytics & KQL

> Level 2 — the workspace, KQL query structure, tables, joins/summarize, and
> retention/cost.

---

## 0. The precise mental model
Log Analytics is the **log data platform** behind Azure Monitor: a **workspace** stores structured logs in **tables**, queried with **KQL (Kusto Query Language)** — a fast, pipe-based read-only analytics language. It's where you **correlate, aggregate, and investigate** telemetry across resources.

---

## 1. Workspace
- A **workspace** = the storage + query boundary (region, retention, access, cost).
- **Design choice**: centralized (one workspace, easier correlation + RBAC) vs distributed (per team/region for isolation/sovereignty).
- Data lands in **tables** (e.g., `Heartbeat`, `AzureActivity`, `AppRequests`, `ContainerLog`, custom).

## 2. KQL structure (pipe model)
```kql
Table
| where TimeGenerated > ago(1h)     // filter early (performance)
| summarize count() by bin(TimeGenerated, 5m), Computer
| order by count_ desc
| take 10
```
- Read **top-to-bottom**, data flows left→right through `|` operators.
- **Filter first** (`where`) to cut data scanned → faster + cheaper.

## 3. Key operators
- `where` (filter), `project`/`extend` (select/compute columns), `summarize` (aggregate + `by` groups), `bin()` (time buckets), `join`/`union`, `sort/order`, `take/top`, `parse`, `make-series`, `render` (chart).
- **Aggregations**: `count()`, `avg()`, `sum()`, `percentile()`, `dcount()`, `arg_max()`.

## 4. Joins & correlation
- `join kind=inner/leftouter/...` correlate across tables (e.g., requests ↔ exceptions).
- `union` combine tables; `lookup` for dimension enrichment.
- Correlating across sources is the whole point of a SIEM/observability query.

## 5. Where KQL is used
- Azure Monitor logs, **Application Insights**, **Sentinel** analytics/hunting, Azure Data Explorer, Resource Graph — same language everywhere.

## 6. Retention, tiers & cost
- **Cost = ingestion (per GB) + retention**. Control with:
  - **Table-level retention** / interactive vs **Archive** tier (cheap long-term, slower queries).
  - **Basic/Auxiliary logs** (cheap ingest, limited query) for high-volume verbose logs vs **Analytics** logs.
  - **Data collection transformations** (DCR) to drop/trim noisy fields at ingest.
  - **Commitment tiers** for volume discounts.

## 7. The hard follow-ups (with answers)
1. **"What is KQL?"** → pipe-based read-only query language over Log Analytics tables. (§2)
2. **"Make a query fast/cheap?"** → **filter early** (`where` on time first), project only needed columns. (§2)
3. **"Correlate requests with failures?"** → `join`/`union` across tables. (§4)
4. **"Group errors over time?"** → `summarize count() by bin(TimeGenerated, 5m)`. (§3)
5. **"One or many workspaces?"** → centralized (correlation/RBAC) vs distributed (isolation/sovereignty) trade-off. (§1)
6. **"Cut log costs?"** → **Basic/Archive tiers**, retention tuning, **DCR transformations** to drop fields. (§6)
7. **"Where else is KQL used?"** → App Insights, **Sentinel**, ADX, Resource Graph. (§5)

## 8. One-screen recall
- **Workspace** = store + query + retention + RBAC boundary; data in **tables**.
- **KQL** = pipe model (`Table | where | summarize | order`); **filter first**.
- **Operators**: where/project/extend/**summarize by bin()**/join/union/render; aggs count/avg/percentile/dcount.
- **Correlate** with join/union (the point of observability).
- **Everywhere**: Monitor, App Insights, **Sentinel**, ADX, Resource Graph.
- **Cost** = ingest + retention → Basic/Archive tiers, DCR transforms, commitment tiers.

> Next: Application Insights.

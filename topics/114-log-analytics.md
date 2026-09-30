# 114 · Log Analytics

> Domain: Observability · Level: Principal Observability / SRE Architect

## 1. Beginner Explanation
Log Analytics is the part of Azure Monitor that **stores and queries log data**. All your logs land in a workspace, and you use a query language (KQL) to search, filter, and analyze them — to investigate issues, build dashboards, and detect problems.

## 2. Architect-Level Explanation
The log data store + analytics engine behind Azure Monitor (and Sentinel):
- **Workspace**: the container for log data — a Log Analytics **workspace** (built on Azure Data Explorer/Kusto). Design: centralized vs per-team; region; RBAC; access modes (resource-context vs workspace-context).
- **Tables/schema**: data organized into **tables** (e.g., `AzureDiagnostics`, `AppRequests`, `Perf`, `SigninLogs`, custom tables). Schema-on-read with strong typing.
- **KQL (Kusto Query Language)**: read-optimized language — filter (`where`), project, `summarize`, `join`, time `bin`, aggregations, `parse`, functions; powerful for large-scale analytics.
- **Ingestion**: diagnostic settings, Azure Monitor Agent + **DCRs**, App Insights, Logs Ingestion API, custom logs.
- **Table plans/tiers**: **Analytics** (full query + alerting), **Basic** (cheap, high-volume, limited query/8-day interactive), **Auxiliary** (very cheap, low-touch), **Archive** (long-term, restore/search jobs). Choose per table to control cost.
- **Retention**: interactive retention + long-term archive per table; total retention up to years.
- **Consumers**: Azure Monitor alerts (log query rules), Workbooks, Sentinel (SIEM sits on top), Grafana, Power BI, dashboards.
- **Cross-workspace/resource** queries; **functions** (saved KQL) for reuse.
- **Cost model**: pay per **GB ingested** + retention; commitment (capacity) tiers for discounts.

## 3. Real Enterprise Use Case
An enterprise runs a **centralized Log Analytics workspace** as the observability + security data lake: diagnostic settings + DCRs feed platform, app, and AKS logs; noisy high-volume tables use **Basic/Auxiliary** tiers, security tables stay in **Analytics** for Sentinel; **KQL** powers alert rules, Workbooks, and hunting; per-table retention + **archive** meets compliance cheaply; RBAC + resource-context access scopes team visibility.

## 4. Architecture Diagram (ASCII)
```
   Ingestion: diagnostic settings · AMA+DCR · App Insights · Logs API · custom
        ▼
   Log Analytics Workspace (Kusto engine)
   ┌──────────────── Tables ────────────────┐
   AppRequests · AzureDiagnostics · Perf · SigninLogs · Custom_CL
   Table plans: Analytics | Basic | Auxiliary | Archive  (per-table cost)
        │ KQL (where/summarize/join/bin/parse)
        ▼
   Consumers: Alerts (log rules) · Workbooks · Sentinel · Grafana · Power BI
   Cost = GB ingested + retention (commitment tiers)
```

## 5. Interview Questions
1. What is a Log Analytics workspace?
2. What is KQL and what can it do?
3. Explain table plans/tiers (Analytics/Basic/Auxiliary/Archive).
4. Centralized vs decentralized workspace design?
5. How do you optimize Log Analytics cost?

## 6. Strong Interview Answers
- **Workspace**: "It's the container and query engine for log data, built on Kusto/Azure Data Explorer. It holds tables of logs from many sources and is the foundation for Azure Monitor log alerts, Workbooks, and Microsoft Sentinel. Workspace design — how many, where, and access model — is a key architectural decision."
- **KQL**: "Kusto Query Language — a read-optimized, pipe-based language. You filter with `where`, shape with `project`, aggregate with `summarize`, correlate with `join`, bucket time with `bin`, and parse unstructured fields. It handles huge volumes fast and is the lingua franca across Monitor and Sentinel."
- **Tiers**: "**Analytics** tier is full-featured (interactive query + alerting) but priciest; **Basic** is cheaper for high-volume logs you rarely query interactively (limited KQL, short interactive retention); **Auxiliary** is even cheaper/low-touch; **Archive** stores data long-term cheaply, accessed via search/restore jobs. I assign plans per table to balance cost vs access needs."
- **Centralized vs decentralized**: "Centralized (one/few workspaces) simplifies cross-resource queries, correlation, and governance (good for Sentinel). Decentralized gives teams isolation and data residency but fragments queries. I usually favor a **centralized** design with RBAC + resource-context access, unless residency/isolation demands separation."
- **Cost**: "Cost is GB ingested + retention. I filter with DCRs, route noisy tables to **Basic/Auxiliary**, archive for compliance, set per-table retention, avoid duplicate ingestion, sample where possible, and use **commitment tiers** for volume discounts — keeping actionable data in Analytics."

## 7. Common Mistakes
- Everything in Analytics tier → high cost.
- Sprawl of workspaces → fragmented queries/correlation.
- Long retention on all tables regardless of value.
- Inefficient KQL (no time filter, scanning huge ranges).
- No RBAC/access scoping → over-broad log visibility.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Centralized workspace | correlation, governance | RBAC complexity |
| Basic/Auxiliary tier | cheap | limited query/alerting |
| Long retention | compliance/forensics | storage cost |

## 9. Production Best Practices
- Centralized workspace(s) + RBAC + resource-context access.
- Per-table tiers (Basic/Auxiliary/Archive) + retention for cost.
- Efficient KQL (time filters, summarize); saved functions for reuse.
- DCR filtering at source; commitment tiers; usage monitoring.
- Workbooks/alerts on top; integrate Sentinel where security data lives.

## 10. Security Considerations
- RBAC (workspace vs resource-context); least-privilege log access.
- Protect sensitive logs (PII); data residency/retention compliance.
- Managed Identity for ingestion; private link for query/ingest.
- Audit access; security tables → Sentinel analytics tier.

## 11. Cost Optimization
- Right table plan per table (Analytics vs Basic vs Auxiliary vs Archive).
- DCR filtering + sampling; per-table retention; archive old data.
- Commitment/capacity tiers; eliminate duplicate/low-value ingestion; monitor `Usage`.

## 12. Troubleshooting Scenarios
- **Query too slow/expensive** → add `where TimeGenerated > ago(...)`, summarize, reduce columns.
- **Missing data** → ingestion delay / DCR / diagnostic setting not sending to this table.
- **High cost** → wrong tier/retention; move noisy tables to Basic/Auxiliary + archive.
- **Can't alert on a table** → Basic-tier limitation; keep alertable data in Analytics.
- **Access denied** → RBAC/resource-context scoping.

## 13. Hands-on Example
```kql
// Top failing operations in the last hour with p95 latency
AppRequests
| where TimeGenerated > ago(1h) and Success == false
| summarize failures = count(), p95 = percentile(DurationMs, 95) by OperationName
| top 10 by failures desc
```

## 14. Terraform Example
```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name = "law-central" resource_group_name = var.rg location = "eastus"
  sku = "PerGB2018" retention_in_days = 90
  daily_quota_gb = 50                         # cost guardrail
}
# Basic-tier custom table for high-volume, low-query logs
resource "azurerm_log_analytics_workspace_table" "verbose" {
  workspace_id = azurerm_log_analytics_workspace.law.id
  name = "VerboseApp_CL" plan = "Basic" retention_in_days = 8
}
```

## 15. Azure Example
```bash
# Create a saved KQL function for reuse across alerts/workbooks
az monitor log-analytics workspace saved-search create -g rg \
  --workspace-name law-central -n FailedRequests \
  --category Ops --display-name "Failed Requests" \
  --saved-query "AppRequests | where Success == false"
```

## 16. FastAPI / Python Example
```python
# Query Log Analytics from an app (custom SRE dashboard) with Managed Identity
from azure.monitor.query import LogsQueryClient
from azure.identity import DefaultAzureCredential
from datetime import timedelta

def error_rate(workspace_id: str):
    client = LogsQueryClient(DefaultAzureCredential())
    kql = ("AppRequests | summarize total=count(), "
           "errors=countif(Success==false) | extend rate=todouble(errors)/total")
    return client.query_workspace(workspace_id, kql, timespan=timedelta(hours=1)).tables[0].rows
```

## 17. AKS Example
Container Insights and control-plane diagnostic logs land in Log Analytics tables (`ContainerLogV2`, `KubeEvents`, `AKSAudit`). High-volume container stdout goes to the **Basic** tier to save cost, while audit logs stay in **Analytics** for Sentinel detections; KQL powers crashloop/OOM alerts and Grafana dashboards.

## 18. How to Remember
**"Workspace = Kusto log store; tables + KQL (where/summarize/join/bin); per-table tiers (Analytics/Basic/Auxiliary/Archive) control cost; feeds alerts/Workbooks/Sentinel/Grafana."**

## 19. Real-World Analogy
A giant, indexed library archive: every document (log) is filed into labeled sections (tables). A skilled research assistant (KQL) instantly finds and summarizes exactly what you ask. Frequently referenced books stay on open shelves (Analytics tier), rarely used ones go to cheap deep storage you can still request (Archive) — so you pay for accessibility only where you need it.

## 20. One-Page Cheat Sheet
- **What**: log data store + analytics engine (Kusto) behind Azure Monitor + Sentinel.
- **Workspace**: container for **tables**; centralized design favored for correlation/governance + RBAC.
- **KQL**: pipe-based query (`where`/`project`/`summarize`/`join`/`bin`/`parse`) over large volumes.
- **Table plans**: Analytics (full) / Basic / Auxiliary (cheap high-volume) / **Archive** (long-term) — per table.
- **Consumers**: Monitor log alerts, Workbooks, **Sentinel**, Grafana, Power BI.
- **Cost**: GB ingested + retention → DCR filter + tiers + retention + commitment tiers.

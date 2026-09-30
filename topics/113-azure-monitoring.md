# 113 · Azure Monitor

> Domain: Observability · Level: Principal Observability / SRE Architect

## 1. Beginner Explanation
Azure Monitor is Azure's **built-in monitoring platform**. It collects data about how your applications and resources are performing (metrics, logs), lets you visualize it, and alerts you when something goes wrong — so you know the health of everything you run in Azure.

## 2. Architect-Level Explanation
The unified observability platform for Azure (and hybrid/multi-cloud):
- **Two fundamental data types**: **Metrics** (numeric time-series, near-real-time, cheap, good for alerting/trends) and **Logs** (structured/semi-structured events in **Log Analytics**, queried with **KQL**, richer/diagnostic).
- **Sources**: platform metrics, **resource/diagnostic settings** (route logs/metrics to Log Analytics/Storage/Event Hub), Activity Log (control-plane), guest OS (Azure Monitor Agent + **Data Collection Rules**), App Insights (apps), Prometheus (managed).
- **Pillars**: metrics, logs, **traces** (distributed via App Insights/OTel), and changes.
- **Alerting**: **alert rules** (metric, log/KQL, activity log) → **action groups** (email/SMS/webhook/Logic App/ITSM/auto-remediation) with **severity**; dynamic thresholds.
- **Visualization**: **Workbooks**, **Dashboards**, metrics explorer, **Managed Grafana**.
- **Specialized**: **Application Insights** (APM), **Container Insights** (AKS), **VM Insights**, **Network Insights**, **Managed Prometheus** + Managed Grafana (cloud-native).
- **Autoscale**: metric-driven scaling of VMSS/App Service/AKS.
- **Cost**: primarily **log ingestion + retention** (GB) — table tiers (analytics/basic/auxiliary), DCR filtering, retention/archive.
- **Concepts**: SLI/SLO/SLA, the "three pillars" (metrics/logs/traces), correlation via `operation_Id`.

## 3. Real Enterprise Use Case
An enterprise centralizes observability in Azure Monitor: diagnostic settings route all resource logs to a **Log Analytics workspace**; **Managed Prometheus + Grafana** and **Container Insights** monitor AKS; **App Insights** traces app requests; **alert rules → action groups** page on-call and trigger auto-remediation Logic Apps; **Workbooks** dashboard SLIs/SLOs; DCRs + table tiers control cost — a single pane for metrics, logs, and traces across the estate.

## 4. Architecture Diagram (ASCII)
```
   Sources ─► Azure Monitor
   ┌───────────┬──────────────┬────────────┬─────────────┐
   Platform    Diagnostic      AMA + DCR    App Insights   Managed
   metrics     settings(logs)  (guest OS)   (traces/APM)   Prometheus
        │            │              │            │            │
        ▼            ▼──────────────┴────────────┴────────────▼
   Metrics DB (time-series)     Log Analytics workspace (KQL)
        │ alert rules (metric/log/activity)         │ queries/workbooks
        ▼                                            ▼
   Action Groups (page/webhook/Logic App/auto-remediate) · Grafana/Dashboards
   Cost = GB ingested/retained → table tiers + DCR filter
```

## 5. Interview Questions
1. Metrics vs Logs in Azure Monitor?
2. What are diagnostic settings and DCRs?
3. How do alerts and action groups work?
4. What specialized monitoring experiences exist (AKS/apps)?
5. How do you control Azure Monitor cost?

## 6. Strong Interview Answers
- **Metrics vs Logs**: "**Metrics** are lightweight numeric time-series, near-real-time and cheap — ideal for dashboards, trends, and fast alerting. **Logs** are richer structured events stored in Log Analytics and queried with **KQL** — for diagnostics, correlation, and complex analysis. I use metrics for 'is it healthy now?' and logs for 'why did it break?'."
- **Diagnostic settings/DCR**: "**Diagnostic settings** route a resource's platform logs/metrics to destinations (Log Analytics, Storage, Event Hub). **Data Collection Rules** define what guest-OS/agent data to collect and where to send it (with filtering/transformation) via the Azure Monitor Agent — the modern, centralized, cost-controllable collection model."
- **Alerts/action groups**: "**Alert rules** evaluate metrics, KQL log queries, or activity log events against thresholds (static or dynamic) and fire alerts with a **severity**. **Action groups** define the response — notify (email/SMS/push), webhook, Logic App, ITSM, or automation runbook. This separates 'what's wrong' from 'who/what responds'."
- **Specialized**: "**Application Insights** for app APM/tracing, **Container Insights** + **Managed Prometheus/Grafana** for AKS, **VM Insights** and **Network Insights** for infra. They're curated experiences on top of the same metrics/logs foundation."
- **Cost**: "Cost is dominated by **log ingestion + retention**. I filter at the source with **DCRs**, use **basic/auxiliary** table tiers for high-volume low-query logs, set retention per table (+ archive), avoid duplicate collection, and use commitment tiers for volume — collecting what's actionable, not everything."

## 7. Common Mistakes
- Collecting everything → runaway ingestion cost + noise.
- Only metrics or only logs (missing correlation/diagnostics).
- Alert fatigue (too many/untuned alerts, no severity discipline).
- No action groups/automation → slow response.
- Not using DCRs/table tiers to control cost.

## 8. Trade-offs
| Data | Pro | Con |
|------|-----|-----|
| Metrics | fast, cheap, real-time | limited dimensions/history |
| Logs (KQL) | rich, flexible | ingestion cost, latency |
| Dynamic thresholds | less tuning | can mask real shifts |

## 9. Production Best Practices
- Centralized Log Analytics workspace(s); diagnostic settings everywhere.
- DCRs + table tiers + retention for cost; collect actionable data.
- Metric + log alerts with severity → action groups + auto-remediation.
- Workbooks/Grafana for SLI/SLO dashboards; correlate via operation_Id.
- Managed Prometheus/Container Insights for AKS; IaC the monitoring.

## 10. Security Considerations
- RBAC on workspace; protect log data (may contain sensitive info).
- Managed Identity for agents/collection; private links for ingestion.
- Audit + Activity Log to Sentinel; alert on security-relevant events.
- Data residency + retention compliance.

## 11. Cost Optimization
- DCR filtering at source; basic/auxiliary tiers for noisy logs.
- Per-table retention + archive; commitment (capacity) tiers.
- Avoid duplicate ingestion; sample high-volume telemetry; review usage (Usage/Estimated Costs).

## 12. Troubleshooting Scenarios
- **High bill** → over-ingestion; apply DCR filters + tiering + retention.
- **No data from a resource** → diagnostic setting/DCR/agent not configured.
- **Missed alert** → rule threshold/evaluation window or action group misconfig.
- **Slow KQL** → narrow time range, summarize, index/parse efficiently.
- **Autoscale not triggering** → wrong metric/threshold/cooldown.

## 13. Hands-on Example
```bash
# Route resource logs to Log Analytics; create a metric alert → action group
az monitor diagnostic-settings create -n toLAW --resource $RES_ID \
  --workspace $LAW_ID --logs '[{"category":"AllLogs","enabled":true}]'
az monitor metrics alert create -n cpu-high -g rg --scopes $VM_ID \
  --condition "avg Percentage CPU > 80" --action $ACTION_GROUP_ID
```

## 14. Terraform Example
```hcl
resource "azurerm_monitor_diagnostic_setting" "diag" {
  name = "toLAW" target_resource_id = azurerm_app_service.web.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  enabled_log { category_group = "allLogs" }
  metric { category = "AllMetrics" }
}
resource "azurerm_monitor_metric_alert" "cpu" {
  name = "cpu-high" resource_group_name = var.rg scopes = [azurerm_linux_virtual_machine.vm.id]
  criteria { metric_namespace = "Microsoft.Compute/virtualMachines"
             metric_name = "Percentage CPU" aggregation = "Average" operator = "GreaterThan" threshold = 80 }
  action { action_group_id = azurerm_monitor_action_group.oncall.id }
}
```

## 15. Azure Example
```bash
# Enable managed Prometheus + Container Insights for AKS
az aks update -g rg -n prod-aks --enable-azure-monitor-metrics    # managed Prometheus
az aks enable-addons -g rg -n prod-aks --addons monitoring        # Container Insights
```

## 16. FastAPI / Python Example
```python
# Emit custom metrics/logs to Azure Monitor via OpenTelemetry exporter
from azure.monitor.opentelemetry import configure_azure_monitor
configure_azure_monitor(connection_string="InstrumentationKey=...")  # App Insights/Monitor
# requests, dependencies, logs auto-collected; add custom metrics via OTel meters
```

## 17. AKS Example
AKS observability = **Container Insights** (node/pod/container metrics + logs) + **Managed Prometheus** (scrapes app/K8s metrics) + **Managed Grafana** dashboards, with control-plane logs via diagnostic settings. Alert rules page on-call for pod crashloops/node pressure; DCRs limit log volume to control cost.

## 18. How to Remember
**"Metrics (fast/cheap/alerting) + Logs (KQL/diagnostics) + Traces; diagnostic settings + DCRs collect; alert rules → action groups; cost = GB ingested (DCR + tiers)."**

## 19. Real-World Analogy
A hospital's patient-monitoring system: bedside monitors show live vitals (metrics — instant, cheap), while detailed charts and test results go in the medical record (logs — rich, searchable). Alarms trigger the right response team (alert rules → action groups), and administrators manage which tests to run to control costs (DCRs/tiers) rather than testing everything constantly.

## 20. One-Page Cheat Sheet
- **What**: unified Azure observability platform (metrics + logs + traces).
- **Metrics**: numeric time-series (fast, cheap, alerting). **Logs**: Log Analytics + **KQL** (rich diagnostics).
- **Collect**: diagnostic settings (route logs/metrics) + **DCRs** (AMA guest data, filtered).
- **Alert**: rules (metric/log/activity, dynamic thresholds) → **action groups** (notify/webhook/auto-remediate).
- **Experiences**: App Insights (APM), Container Insights + **Managed Prometheus/Grafana** (AKS), VM/Network Insights; autoscale.
- **Cost**: GB ingested/retained → DCR filtering + table tiers (basic/auxiliary) + retention/archive.

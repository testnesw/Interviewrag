# 115 · Application Insights

> Domain: Observability · Level: Principal Observability / SRE Architect

## 1. Beginner Explanation
Application Insights is Azure's **application performance monitoring (APM)** tool. It automatically tracks your app's requests, dependencies, errors, and performance, and shows how users experience it — so you can find slow spots, failures, and their root causes.

## 2. Architect-Level Explanation
APM built on Azure Monitor / Log Analytics for application-level observability:
- **Telemetry types**: **requests** (incoming), **dependencies** (outgoing calls — DB, HTTP, queues), **exceptions**, **traces** (logs), **custom events/metrics**, **page views**, **availability** tests.
- **Distributed tracing**: correlates a transaction across services via **operation_Id** / trace context (W3C); **application map** visualizes service topology + health; **transaction search / end-to-end** views.
- **Instrumentation**: **auto-instrumentation** (codeless for App Service/Functions/AKS) or SDK / **OpenTelemetry** (the recommended path — Azure Monitor OTel Distro); **connection string** (not just ikey).
- **Data**: stored in Log Analytics tables (`AppRequests`, `AppDependencies`, `AppExceptions`, `AppTraces`), queried with **KQL**.
- **Features**: **Live Metrics** (real-time), **Failures/Performance** blades, **Smart Detection** (anomaly), **Availability** (URL ping/standard tests), **Profiler** + **Snapshot Debugger**, **Usage** analytics (funnels/retention/cohorts), **sampling** (adaptive/fixed) to control volume/cost.
- **Workspace-based**: modern App Insights stores data in a Log Analytics workspace (unified).
- **SLIs/SLOs**: latency, error rate, throughput, availability; correlate with infra metrics.
- **Cost**: ingestion-based → **sampling** + telemetry filtering.

## 3. Real Enterprise Use Case
A microservices platform instruments all services with **OpenTelemetry → Application Insights**: the **application map** shows the topology and failing dependencies; **distributed tracing** follows a checkout across API → payment → DB via operation_Id; **Live Metrics** + **Smart Detection** surface anomalies; **availability tests** watch endpoints; **adaptive sampling** controls cost; SLO dashboards (latency/error rate) and alerts drive the SRE on-call — full application observability tied to infra in one workspace.

## 4. Architecture Diagram (ASCII)
```
   App services (OpenTelemetry / auto-instrument) ─► Application Insights
   Telemetry: requests · dependencies · exceptions · traces · custom · availability
        │ correlate by operation_Id (W3C trace context)
        ▼
   Application Map (topology + health) · End-to-end transaction view
   Live Metrics · Failures/Performance · Smart Detection · Profiler/Snapshot
        │ stored in Log Analytics tables (AppRequests/AppDependencies/…) → KQL
        ▼
   Alerts (latency/error-rate SLOs) · Workbooks · Grafana | sampling = cost control
```

## 5. Interview Questions
1. What telemetry does App Insights collect?
2. How does distributed tracing / correlation work?
3. Auto-instrumentation vs SDK vs OpenTelemetry?
4. What is sampling and why use it?
5. How do you define SLIs/SLOs with App Insights?

## 6. Strong Interview Answers
- **Telemetry**: "Requests (incoming), dependencies (outgoing calls to DBs/APIs/queues), exceptions, traces (logs), custom events/metrics, page views, and availability results. Together they give a full picture of app performance, failures, and usage."
- **Distributed tracing**: "Each transaction carries a correlation id (**operation_Id**) propagated via W3C trace context across services. App Insights stitches the spans into an **end-to-end transaction** and renders an **application map** of service dependencies with health — so I can pinpoint which hop in a multi-service request failed or was slow."
- **Instrumentation options**: "**Auto-instrumentation** is codeless (enable on App Service/Functions/AKS) — quick but less custom. The **SDK** gives full control. **OpenTelemetry** (Azure Monitor OTel Distro) is now the recommended, vendor-neutral approach — standard instrumentation that exports to App Insights, avoiding lock-in while keeping the rich Azure experience."
- **Sampling**: "Sampling reduces telemetry volume (and cost) while preserving statistical accuracy and keeping correlated items together. **Adaptive sampling** auto-adjusts to a target rate; fixed/ingestion sampling gives predictable control. Essential for high-traffic apps to manage ingestion cost without losing insight."
- **SLIs/SLOs**: "I define SLIs from telemetry — request **latency** (p95/p99), **error rate** (failed requests), throughput, and **availability** (ping tests) — set SLO targets, build Workbooks/alerts against them, and correlate with infra metrics. This drives error budgets and on-call priorities."

## 7. Common Mistakes
- No distributed tracing/correlation across services (siloed telemetry).
- No sampling on high-traffic apps → huge ingestion cost.
- Classic (ikey-only, non-workspace) setup instead of workspace-based + connection string.
- Over-logging traces (noise + cost) or logging sensitive data (PII).
- Ignoring dependencies (only requests) → miss root cause.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Auto-instrument | fast, no code | less control |
| OpenTelemetry | standard, portable | setup effort |
| Sampling | cost control | some data dropped |

## 9. Production Best Practices
- **OpenTelemetry** instrumentation; workspace-based App Insights + connection string.
- Propagate correlation; use application map + end-to-end views.
- Adaptive sampling + telemetry filtering (no PII).
- SLI/SLO dashboards + alerts (latency/error rate/availability).
- Availability tests; Profiler/Snapshot for deep diagnosis; correlate with infra.

## 10. Security Considerations
- Don't log secrets/PII; scrub sensitive fields (telemetry processors).
- RBAC on the workspace; connection string (not exposed ikey) management.
- Managed Identity where applicable; private link for ingestion.
- Data residency + retention compliance.

## 11. Cost Optimization
- Adaptive/fixed **sampling**; filter low-value telemetry at source.
- Reduce verbose trace logging; per-table retention/tier in the workspace.
- Cap daily volume; monitor ingestion; commitment tiers on the workspace.

## 12. Troubleshooting Scenarios
- **Broken trace correlation** → context not propagated; ensure OTel/W3C headers flow.
- **High ingestion cost** → enable sampling + filter traces.
- **Missing dependency data** → auto-collection/OTel instrumentation gap.
- **Can't find root cause** → use end-to-end transaction + application map + exceptions.
- **No availability alerts** → availability test/alert not configured.

## 13. Hands-on Example
```python
# Python: enable OpenTelemetry → Application Insights (auto requests/deps/logs)
from azure.monitor.opentelemetry import configure_azure_monitor
configure_azure_monitor(connection_string="InstrumentationKey=...;IngestionEndpoint=...")
# FastAPI/requests/DB calls now traced + correlated automatically
```

## 14. Terraform Example
```hcl
resource "azurerm_application_insights" "ai" {
  name = "ai-orders" resource_group_name = var.rg location = "eastus"
  application_type = "web"
  workspace_id = azurerm_log_analytics_workspace.law.id   # workspace-based
  sampling_percentage = 20                                 # cost control
}
```

## 15. Azure Example
```bash
# Codeless auto-instrumentation for an App Service (no code change)
az webapp config appsettings set -g rg -n web-app --settings \
  APPLICATIONINSIGHTS_CONNECTION_STRING=$AI_CONN \
  ApplicationInsightsAgent_EXTENSION_VERSION="~3"
```

## 16. FastAPI / Python Example
```python
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
configure_azure_monitor(connection_string=CONN)
tracer = trace.get_tracer(__name__)

@app.post("/checkout")
async def checkout(order: dict):
    with tracer.start_as_current_span("process-payment"):   # custom span in the trace
        await charge(order)                                  # dependency auto-traced
    return {"status": "ok"}
```

## 17. AKS Example
AKS workloads use the **OpenTelemetry** SDK/auto-instrumentation (or the OTel Operator) exporting to Application Insights; combined with Container Insights + Managed Prometheus, you get app traces + infra metrics correlated. The application map spans microservices; distributed tracing follows requests across pods/services for root-cause analysis.

## 18. How to Remember
**"APM: requests + dependencies + exceptions + traces; correlate by operation_Id → application map + end-to-end; OpenTelemetry to instrument; sampling for cost; SLIs = latency/errors/availability."**

## 19. Real-World Analogy
A flight tracker for every passenger's journey: it follows each traveler through connecting flights across airlines (services), showing exactly where a delay or missed connection happened (distributed tracing), maps the whole route network's health (application map), and — since tracking every single passenger is expensive — samples a representative set while still spotting systemic delays (sampling).

## 20. One-Page Cheat Sheet
- **What**: APM on Azure Monitor/Log Analytics for application-level observability.
- **Telemetry**: requests, **dependencies**, exceptions, traces, custom, page views, availability.
- **Tracing**: correlate by **operation_Id** (W3C) → **application map** + end-to-end transactions.
- **Instrument**: **OpenTelemetry** (recommended) / auto-instrument / SDK; workspace-based + connection string.
- **Features**: Live Metrics, Smart Detection, Availability tests, Profiler/Snapshot, Usage analytics.
- **Cost**: **sampling** (adaptive/fixed) + filtering; SLIs = latency (p95/p99) / error rate / availability.

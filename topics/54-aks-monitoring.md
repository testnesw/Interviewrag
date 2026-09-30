# 54 · AKS Monitoring & Observability

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
AKS monitoring means collecting **metrics, logs, and traces** from your cluster and apps so you can see health, performance, and problems — and get alerted when something breaks.

## 2. Architect-Level Explanation
The three pillars of observability, mapped to Azure-native + CNCF tooling:
- **Metrics**: **Managed Prometheus** (Azure Monitor) scrapes cluster/app metrics → **Managed Grafana** dashboards. Node/pod metrics via metrics-server + Prometheus.
- **Logs**: **Container Insights** ships stdout/stderr + Kubernetes events to **Log Analytics** (query with KQL); control cost with data-collection filtering / Basic Logs.
- **Traces**: **OpenTelemetry** SDK → App Insights / Tempo for distributed tracing across microservices.
- **Alerting**: Azure Monitor alerts / Prometheus alert rules → Action Groups (Teams/PagerDuty).
- **Health**: liveness/readiness probes, Deployment status, KEDA/HPA metrics.
- **Golden signals**: latency, traffic, errors, saturation (RED/USE methods).
- **Security signals**: Defender + audit logs → Sentinel.

## 3. Real Enterprise Use Case
An enterprise enables **Managed Prometheus + Managed Grafana + Container Insights**: golden-signal dashboards per service, KQL log queries for incident triage, OpenTelemetry traces flowing to App Insights, and alert rules on p99 latency/error rate/pod restarts routed to PagerDuty. SLOs tracked with error budgets.

## 4. Architecture Diagram (ASCII)
```
   Pods/Nodes ─► metrics ─► Managed Prometheus ─► Managed Grafana (dashboards)
        │ stdout/stderr + events ─► Container Insights ─► Log Analytics (KQL)
        │ OTel traces ─► App Insights / Tempo
   Alert rules (latency/errors/restarts) ─► Action Groups ─► Teams/PagerDuty
   Golden signals: Latency · Traffic · Errors · Saturation
   Defender + audit ─► Sentinel (security)
```

## 5. Interview Questions
1. What are the three pillars of observability?
2. How do you monitor AKS with Azure-native tools?
3. What are the golden signals / RED / USE?
4. How do you control log/monitoring cost?
5. How do you implement distributed tracing?

## 6. Strong Interview Answers
- **Pillars**: "Metrics (what/how much), logs (detailed events), and traces (request flow across services). Together they let you detect, triage, and root-cause issues."
- **Azure-native**: "Managed Prometheus for metrics, Managed Grafana for dashboards, Container Insights → Log Analytics for logs (KQL), and OpenTelemetry → App Insights for traces — fully managed, less operational burden than self-hosting."
- **Signals**: "Golden signals = latency, traffic, errors, saturation. RED (Rate, Errors, Duration) for request-driven services; USE (Utilization, Saturation, Errors) for resources. I build dashboards and SLOs around these."
- **Cost control**: "Filter data collection in Container Insights, use Basic Logs for high-volume low-query data, sample traces, and set retention policies — logging cost can dwarf compute if unmanaged."
- **Tracing**: "Instrument services with OpenTelemetry, propagate context (W3C traceparent), export to App Insights/Tempo — so I can follow a request across microservices and find the slow hop."

## 7. Common Mistakes
- No readiness/liveness probes → bad health signals.
- Collecting everything → runaway Log Analytics cost.
- Metrics without traces (can't find root cause).
- Alert fatigue (too many noisy alerts).
- No SLOs/error budgets.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Managed Prometheus/Grafana | low ops | Azure cost |
| Self-hosted stack | control/portable | ops burden |
| Verbose logging | rich data | expensive |

## 9. Production Best Practices
- Managed Prometheus + Grafana + Container Insights.
- Golden-signal dashboards + SLOs/error budgets.
- OpenTelemetry tracing across services.
- Actionable, deduplicated alerts (Action Groups).
- Cost controls: filtering, Basic Logs, sampling, retention.

## 10. Security Considerations
- Audit logs + Defender → Sentinel; alert on anomalies.
- Protect telemetry endpoints; RBAC on Grafana/Log Analytics.
- Avoid logging secrets/PII (scrubbing).

## 11. Cost Optimization
- Filter/sample telemetry; Basic Logs for cheap ingestion.
- Right retention per table; commitment tiers for Log Analytics.
- Drop noisy high-cardinality metrics.

## 12. Troubleshooting Scenarios
- **No metrics** → Managed Prometheus scrape config / DCR misconfig.
- **Pod restarts (CrashLoop)** → check logs + liveness probe settings.
- **High latency** → trace to find slow dependency; check saturation.
- **Missing logs** → Container Insights data-collection rule / namespace filter.
- **Bill spike** → verbose logging / high-cardinality metrics.

## 13. Hands-on Example
```bash
kubectl top pods -n app
kubectl logs -f deploy/api -n app
kubectl get events -n app --sort-by=.lastTimestamp
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  # ...
  monitor_metrics {}          # Managed Prometheus
  oms_agent {                 # Container Insights
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }
}
```

## 15. Azure Example
```bash
az aks enable-addons -g rg-aks -n prod-aks -a monitoring \
  --workspace-resource-id $LAW_ID
az aks update -g rg-aks -n prod-aks --enable-azure-monitor-metrics  # Prometheus
```

## 16. FastAPI / Python Example
```python
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from prometheus_client import Histogram, make_asgi_app

FastAPIInstrumentor.instrument_app(app)          # traces → App Insights
latency = Histogram("http_request_seconds", "latency", ["route"])
app.mount("/metrics", make_asgi_app())           # scraped by Managed Prometheus
```

## 17. AKS Example (Prometheus alert rule via PrometheusRule)
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata: { name: api-slo, namespace: app }
spec:
  groups:
    - name: api.rules
      rules:
        - alert: HighErrorRate
          expr: sum(rate(http_requests_total{code=~"5.."}[5m])) /
                sum(rate(http_requests_total[5m])) > 0.02
          for: 5m
          labels: { severity: page }
```

## 18. How to Remember
**"Metrics, Logs, Traces + Golden Signals."** Managed Prometheus + Grafana + Container Insights + OTel — and watch the log bill.

## 19. Real-World Analogy
A hospital patient monitor: vital signs on screen (metrics), the detailed chart notes (logs), and the timeline of the patient's journey through departments (traces) — with alarms (alerts) when a vital crosses a threshold.

## 20. One-Page Cheat Sheet
- **Pillars**: Metrics + Logs + Traces.
- **Azure-native**: Managed Prometheus → Managed Grafana; Container Insights → Log Analytics (KQL); OTel → App Insights.
- **Signals**: Golden (latency/traffic/errors/saturation), RED, USE.
- **Alerting**: Azure Monitor / Prometheus rules → Action Groups.
- **Health**: liveness/readiness probes + SLOs/error budgets.
- **Cost**: filter, Basic Logs, sample traces, tune retention.

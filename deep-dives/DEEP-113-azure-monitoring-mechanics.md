# DEEP MECHANICS · Azure Monitor

> Level 2 — metrics vs logs, the data pipeline, alerts, autoscale, and the
> observability stack.

---

## 0. The precise mental model
Azure Monitor is the **umbrella platform** for collecting and acting on telemetry across Azure. Two fundamental data types: **Metrics** (numeric time-series, cheap, fast, for alerting/dashboards) and **Logs** (structured events in **Log Analytics**, queried with **KQL**, for deep analysis). Everything — alerts, autoscale, dashboards, App Insights — sits on top of these.

---

## 1. Metrics vs logs (core distinction)
| | Metrics | Logs |
|---|---|---|
| Shape | numeric time-series | structured records |
| Store | time-series DB | **Log Analytics** workspace |
| Query | metrics explorer | **KQL** |
| Latency | near-real-time | seconds–minutes |
| Cost | cheap | per-GB ingest/retention |
| Use | alerting, autoscale, dashboards | investigation, correlation, audit |

## 2. Data sources / pipeline
```
Resources → [Platform metrics, Activity log, Resource/Diagnostic logs, Agents, App Insights]
         → Azure Monitor → (Metrics store | Log Analytics) → alerts/dashboards/autoscale/export
```
- **Diagnostic settings** route resource logs/metrics to Log Analytics / Storage / Event Hub.
- **Activity log** = subscription-level control-plane events (who did what).
- **Azure Monitor Agent (AMA)** / **Data Collection Rules (DCR)** collect from VMs.

## 3. Alerts
- **Metric alerts** (threshold/dynamic), **log alerts** (KQL result count), **activity log alerts**.
- **Alert rule** → **action group** (email/SMS/webhook/Logic App/ITSM/Functions) → notify or auto-remediate.
- **Severity 0–4**; smart groups reduce noise.

## 4. Autoscale
- Rules on metrics (CPU, queue length, custom) → scale out/in VMSS/App Service/AKS.
- Schedule-based + metric-based; cooldown to avoid flapping.

## 5. The observability stack (built on Monitor)
- **Application Insights** — APM (requests, dependencies, traces, exceptions) for apps.
- **Log Analytics** — KQL query engine + workspace.
- **VM insights / Container insights** — curated experiences for VMs/AKS.
- **Workbooks** — interactive reports; **dashboards**; **Grafana** integration.

## 6. Three pillars mapping
- **Metrics** (is it healthy?), **Logs** (what happened?), **Traces** (App Insights distributed tracing — where's the latency?). Aligns with **OpenTelemetry**.

## 7. The hard follow-ups (with answers)
1. **"Metrics vs logs?"** → metrics = cheap numeric time-series (alert/autoscale); logs = structured, KQL, deep analysis. (§1)
2. **"Get a VM's logs into Monitor?"** → **diagnostic settings / AMA + DCR** → Log Analytics. (§2)
3. **"Who deleted a resource?"** → **Activity log**. (§2)
4. **"Alert → action?"** → alert rule → **action group** (notify/webhook/Logic App). (§3)
5. **"Scale on CPU?"** → **autoscale** rule on the metric. (§4)
6. **"Find slow dependency in an app?"** → **Application Insights** traces/dependency map. (§5)
7. **"Query language?"** → **KQL** over Log Analytics. (§1)

## 8. One-screen recall
- **Umbrella platform**; two data types: **Metrics** (numeric TS, cheap, alert/autoscale) + **Logs** (KQL in **Log Analytics**, deep analysis).
- **Pipeline**: diagnostic settings/AMA+DCR/Activity log/App Insights → Monitor → metrics|logs.
- **Alerts**: metric/log/activity → **action groups**.
- **Autoscale** on metrics (cooldown).
- **Stack**: **App Insights** (APM/traces), Log Analytics, VM/Container insights, Workbooks/Grafana.
- **Pillars**: metrics + logs + traces (OpenTelemetry).

> Next: Log Analytics.

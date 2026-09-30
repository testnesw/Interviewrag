# DEEP MECHANICS · Application Insights

> Level 2 — APM telemetry types, distributed tracing, sampling, live metrics,
> and the App Map.

---

## 0. The precise mental model
Application Insights is Azure's **APM** (Application Performance Monitoring) — the **traces pillar** of observability for your app. An **SDK/auto-instrumentation** captures requests, dependencies, exceptions, and custom events, correlates them across services via **distributed tracing**, and stores them in Log Analytics (KQL) → you see **where latency/errors originate** end-to-end.

---

## 1. Telemetry types
- **Requests** — incoming operations (HTTP requests) + duration + result code.
- **Dependencies** — outgoing calls (DB, HTTP, queue) + duration/success → find slow downstreams.
- **Exceptions** — captured errors + stack traces.
- **Traces** — log lines; **Custom events/metrics** — business telemetry.
- **Page views / availability** (browser + synthetic tests).

## 2. Distributed tracing (the key feature)
- Each operation gets an **operation_Id**; calls propagate **trace context** (W3C Trace Context) across services.
- Reconstructs the **end-to-end transaction** across microservices → pinpoint which hop is slow/failing.
- **App Map** visualizes components + call volumes + failure rates.

## 3. Instrumentation
- **Auto-instrumentation** (codeless for App Service/Functions/AKS) vs **SDK** (manual, richer custom telemetry).
- Now aligns with **OpenTelemetry** (vendor-neutral) → export to App Insights.
- Connection string (with instrumentation key) wires app → workspace.

## 4. Sampling (cost + volume control)
- **Adaptive sampling** (auto-reduce volume keeping statistical accuracy), **fixed-rate**, **ingestion sampling**.
- Keeps related telemetry together (same operation sampled in/out) → traces stay coherent.
- Trade **cost/volume** vs **fidelity**.

## 5. Analysis features
- **Live Metrics** — real-time stream (sub-second) for deploys/incidents.
- **Failures / Performance** blades — top failing operations, slowest dependencies.
- **Smart Detection** — ML anomaly alerts (failure spikes, latency degradation).
- **Usage** analytics (funnels, retention, cohorts); **Workbooks**.
- Query everything with **KQL** (it's a Log Analytics-based resource).

## 6. The hard follow-ups (with answers)
1. **"What pillar is App Insights?"** → **traces/APM** (with metrics + logs) for applications. (§0)
2. **"Find which microservice causes latency?"** → **distributed tracing** (operation_Id correlation) + **App Map**. (§2)
3. **"Request vs dependency telemetry?"** → request = inbound op; dependency = outbound call (DB/HTTP). (§1)
4. **"High telemetry cost?"** → **adaptive sampling** (keeps coherent traces). (§4)
5. **"Watch a deploy live?"** → **Live Metrics** stream. (§5)
6. **"Vendor-neutral instrumentation?"** → **OpenTelemetry** → App Insights exporter. (§3)
7. **"How do you query it?"** → KQL (Log Analytics-backed). (§5)

## 7. One-screen recall
- **APM / traces pillar**: requests, **dependencies**, exceptions, traces, custom events.
- **Distributed tracing**: operation_Id + W3C context → end-to-end transaction; **App Map**.
- **Instrument**: auto (codeless) or SDK; **OpenTelemetry**-aligned.
- **Sampling**: adaptive (coherent traces) to control cost/volume.
- **Analyze**: **Live Metrics**, Failures/Performance, **Smart Detection**, Usage; **KQL**.

> Next: FinOps.

# 116 · OpenTelemetry (OTel)

> Domain: Observability · Level: Principal Observability / SRE Architect

## 1. Beginner Explanation
OpenTelemetry (OTel) is an **open standard for collecting telemetry** — traces, metrics, and logs — from your applications. You instrument your code once using OTel, and you can send that data to any monitoring backend (Azure Monitor, Prometheus, Jaeger, Datadog) without rewriting — no vendor lock-in.

## 2. Architect-Level Explanation
A vendor-neutral, **CNCF** observability framework and standard:
- **Three signals**: **traces** (distributed request spans), **metrics** (numeric measurements), **logs** — with a unified data model + **semantic conventions** (standard attribute names).
- **Context propagation**: **W3C Trace Context** (`traceparent`) links spans across services/processes — the backbone of distributed tracing.
- **Components**: **API** (instrumentation surface), **SDK** (implementation — samplers, processors, exporters), **instrumentation libraries** (auto-instrument frameworks: FastAPI, requests, SQL, etc.), **exporters** (OTLP, Prometheus, Jaeger, Azure Monitor), **OTLP** (the standard wire protocol).
- **OpenTelemetry Collector**: a standalone agent/gateway that receives, **processes** (batch, filter, transform, sample, redact), and **exports** telemetry to one or many backends — decouples apps from backends (agent per-node + gateway pattern).
- **Value**: **no vendor lock-in** (swap backends by changing exporter config), consistent instrumentation across polyglot services, standardized conventions, future-proof.
- **Azure**: **Azure Monitor OpenTelemetry Distro** is the recommended way to instrument apps for Application Insights; managed Prometheus consumes OTel metrics.
- **Sampling**: head-based (at source) vs **tail-based** (in Collector, decide after seeing the full trace).
- **Maturity**: tracing + metrics stable; logs converging; broad ecosystem adoption.

## 3. Real Enterprise Use Case
A polyglot microservices estate (Python/Java/Node on AKS) standardizes on **OpenTelemetry**: services auto-instrument with OTel, propagate W3C trace context, and export **OTLP** to an **OTel Collector** (DaemonSet + gateway) that batches, redacts PII, tail-samples, and fans out to **Azure Monitor/App Insights** (traces) and **Managed Prometheus** (metrics) — one instrumentation standard, multiple backends, zero lock-in, consistent across languages.

## 4. Architecture Diagram (ASCII)
```
   Polyglot services (OTel API + SDK + auto-instrumentation)
        │ traces + metrics + logs (semantic conventions)
        │ W3C trace context (traceparent) propagated
        ▼  OTLP
   OpenTelemetry Collector (receive ─► process ─► export)
      processors: batch · filter · redact PII · tail-sampling
        │ fan-out to many backends (swap = config change)
   ┌────────────┬───────────────┬──────────────┬───────────┐
   Azure Monitor  Managed Prom.   Jaeger        Datadog/…
   (App Insights)  (metrics)      (traces)      (any)
```

## 5. Interview Questions
1. What is OpenTelemetry and why does it matter?
2. What are the three signals and semantic conventions?
3. How does context propagation enable distributed tracing?
4. What is the OTel Collector and why use it?
5. Head-based vs tail-based sampling?

## 6. Strong Interview Answers
- **What/why**: "OpenTelemetry is a CNCF vendor-neutral standard + toolkit for generating traces, metrics, and logs. It matters because you instrument once and can send telemetry to any backend — no lock-in — with consistent, standardized instrumentation across polyglot services. It's become the industry standard for observability."
- **Signals/conventions**: "The three signals are **traces** (request spans), **metrics** (measurements), and **logs**. **Semantic conventions** standardize attribute names (e.g., `http.request.method`, `db.system`) so telemetry is consistent and portable across services and backends — dashboards/queries work regardless of language."
- **Context propagation**: "Distributed tracing relies on propagating **W3C Trace Context** (`traceparent` header) across service boundaries. Each service creates spans under the same trace id, so the backend reconstructs the full end-to-end request path — essential for root-causing latency/failures in microservices."
- **Collector**: "The **OTel Collector** is a standalone pipeline (receivers → processors → exporters) that sits between apps and backends. It offloads batching, filtering, PII redaction, transformation, and sampling from apps, and can export to multiple backends — so switching or adding a backend is a config change, not a code change. Common pattern: agent (per node) + gateway (central)."
- **Sampling**: "**Head-based** sampling decides at the start (in the app/SDK) — cheap but may drop the interesting (error) traces. **Tail-based** sampling (in the Collector) buffers a full trace and decides after seeing it — so you can keep all error/slow traces and sample the rest. Tail-based is more powerful but needs Collector resources."

## 7. Common Mistakes
- Not propagating context → broken/partial traces.
- Vendor-specific instrumentation (defeats OTel's portability).
- No Collector → apps tightly coupled to a backend; no central processing.
- Ignoring semantic conventions → inconsistent attributes.
- No sampling strategy → cost/volume blowup.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Direct exporter (no Collector) | simpler | app-backend coupling |
| Collector | flexible, decoupled | extra component to run |
| Tail sampling | keep interesting traces | Collector resource cost |

## 9. Production Best Practices
- Auto-instrument + follow semantic conventions; propagate W3C context.
- Deploy a **Collector** (agent + gateway) for processing + fan-out.
- Tail-based sampling for errors/slow traces; batch + redact PII.
- OTLP everywhere; export to Azure Monitor + Prometheus.
- Version instrumentation; correlate traces/metrics/logs via trace id.

## 10. Security Considerations
- Redact/scrub PII + secrets in the Collector (processors) before export.
- Secure OTLP (TLS/mTLS, auth); protect the Collector endpoint.
- Least-privilege exporter credentials (Managed Identity to Azure Monitor).
- Control what attributes are captured (avoid sensitive data).

## 11. Cost Optimization
- Sampling (tail-based to keep only valuable traces); batch to reduce overhead.
- Filter/drop low-value telemetry in the Collector before backend ingestion.
- One pipeline → multiple backends avoids duplicate agents/cost.

## 12. Troubleshooting Scenarios
- **Partial/broken traces** → context not propagated across a hop; check headers/instrumentation.
- **No data in backend** → exporter/OTLP endpoint/auth misconfig.
- **Too much telemetry/cost** → add sampling + Collector filtering.
- **Inconsistent dashboards** → not following semantic conventions.
- **Collector dropping data** → under-resourced/queue full; scale + tune batch.

## 13. Hands-on Example
```python
# OTel SDK: trace + export via OTLP to a Collector (backend-agnostic)
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="http://otel-collector:4317")))
trace.set_tracer_provider(provider)
```

## 14. Terraform Example
```hcl
# Deploy the OpenTelemetry Collector to AKS via Helm (agent + gateway)
resource "helm_release" "otel_collector" {
  name = "otel-collector" namespace = "observability" create_namespace = true
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart = "opentelemetry-collector"
  values = [file("otel-collector-values.yaml")]   # receivers/processors/exporters config
}
```

## 15. Azure Example
```python
# Azure Monitor OpenTelemetry Distro — OTel instrumentation → Application Insights
from azure.monitor.opentelemetry import configure_azure_monitor
configure_azure_monitor(connection_string=CONN)   # standard OTel, Azure backend, no lock-in
```

## 16. FastAPI / Python Example
```python
# Auto-instrument FastAPI with OTel; spans propagate W3C context to downstream calls
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
FastAPIInstrumentor.instrument_app(app)      # incoming requests → spans
HTTPXClientInstrumentor().instrument()       # outgoing calls carry traceparent
```

## 17. AKS Example
Deploy the **OTel Collector** as a DaemonSet (node agent) + Deployment (gateway); apps export OTLP to the local agent, which forwards to the gateway for tail-sampling + PII redaction, then fans out to **Azure Monitor** (traces) and **Managed Prometheus** (metrics). The **OpenTelemetry Operator** can auto-inject instrumentation into pods — standardized observability across the cluster.

## 18. How to Remember
**"Open standard, 3 signals (traces/metrics/logs) + semantic conventions; W3C context propagation; instrument once → any backend (no lock-in); Collector = receive/process/export; tail-sample the interesting traces."**

## 19. Real-World Analogy
A universal power adapter + standardized shipping containers for observability: you package telemetry in a standard container (OTel/OTLP) once, and it fits any ship, truck, or port (backend) worldwide. A central sorting hub (Collector) inspects, labels, and reroutes shipments to any destination — so switching carriers (monitoring vendors) doesn't require repackaging your goods (re-instrumenting code).

## 20. One-Page Cheat Sheet
- **What**: CNCF vendor-neutral standard + toolkit for **traces + metrics + logs** — instrument once, any backend.
- **Model**: unified signals + **semantic conventions**; **W3C Trace Context** propagation = distributed tracing.
- **Components**: API + SDK + auto-instrumentation + exporters; **OTLP** wire protocol.
- **Collector**: receivers → processors (batch/filter/redact/sample) → exporters; fan-out, decouples app↔backend.
- **Sampling**: head-based (source) vs **tail-based** (Collector — keep errors/slow).
- **Azure**: Azure Monitor OTel Distro → App Insights; Managed Prometheus for metrics; no lock-in.

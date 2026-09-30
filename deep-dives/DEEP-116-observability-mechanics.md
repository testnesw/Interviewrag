# DEEP MECHANICS · Observability & OpenTelemetry

> Level 2 — the three signals and how they differ, the OTel pipeline
> (SDK→collector→backend), context propagation & trace correlation, sampling
> math, cardinality traps, and the golden signals — plus how you'd debug a
> latency spike across microservices.

---

## 0. The precise mental model
**Monitoring** = watching known metrics (is CPU high?). **Observability** = being able to ask **new questions about unknown failures** from your telemetry — *without shipping new code*. It rests on **three signals**: **metrics** (aggregates, "what/how much"), **logs** (discrete events, "what happened"), **traces** (request path across services, "where/why slow"). **OpenTelemetry (OTel)** is the vendor-neutral **standard + SDK** to generate and export all three, so you're not locked to one backend. The architect's job: instrument once (OTel), correlate signals via **trace/correlation IDs**, and control **cost/cardinality** with sampling.

---

## 1. The three signals — what each is FOR (don't conflate them)
| Signal | Answers | Shape | Cost driver |
|---|---|---|---|
| **Metrics** | "how much / is it healthy?" | numeric time series (counter/gauge/histogram) | **cardinality** (label combos) |
| **Logs** | "what exactly happened here?" | timestamped structured events | volume/retention |
| **Traces** | "where did the request spend time?" | tree of **spans** across services | span volume × sampling |

- **Metrics** are cheap and aggregated → dashboards & alerts. Bad for high-cardinality (per-user).
- **Logs** are rich but expensive at volume → detail/forensics. Make them **structured (JSON)** so they're queryable.
- **Traces** show the **causal path** → the only signal that explains cross-service latency.

**Deep follow-up: "You have metrics AND logs — why traces?"**
Metrics tell you *that* p99 latency rose; logs tell you what one service did; only **traces** stitch a single request across all services to show **which hop** consumed the time and the causal chain. Distributed systems need the request-level view.

---

## 2. Traces & spans — the anatomy
- A **trace** = one request's journey, identified by a **trace_id**.
- A **span** = one unit of work (a service call, a DB query) with start/end, attributes, status, and a **parent span_id** → spans form a **tree**.
- **Context propagation**: the trace_id + span_id travel between services in **headers** (W3C `traceparent`). Each service creates child spans under the incoming context → the full tree reassembles at the backend.

```
traceparent: 00-<trace_id>-<parent_span_id>-01   ← passed in HTTP/messaging headers
Gateway span ─┬─ AuthSvc span
              ├─ OrderSvc span ─── DB span   ← this one is slow → root cause
              └─ PaymentSvc span
```

**Deep follow-up: "How does the trace survive across service boundaries?"**
Context propagation: the W3C `traceparent` header carries trace_id + span_id. Each service reads it, starts child spans, and forwards it downstream (and across message brokers). OTel does this automatically for instrumented libraries.

---

## 3. The OpenTelemetry pipeline — SDK → Collector → Backend
```
[App + OTel SDK/auto-instrumentation]
      │ generates spans/metrics/logs (OTLP protocol)
      ▼
[OTel Collector]  ← receive → process (batch, sample, filter, enrich, redact) → export
      │
      ▼
[Backends]  App Insights / Azure Monitor / Prometheus / Jaeger / Grafana ...
```
- **Instrumentation** — auto (libraries) + manual (custom spans/attributes).
- **OTLP** — the standard wire protocol.
- **Collector** — a **decoupling layer**: one place to batch, **sample**, redact PII, add resource attributes, and **fan out to multiple backends**. Swap backends without touching app code.
- **Value:** instrument **once**, avoid vendor lock-in, change backends centrally.

**Deep follow-up: "Why run a Collector instead of exporting straight to the backend?"**
The Collector centralizes batching, sampling, filtering/PII redaction, enrichment, and multi-backend export — so apps stay simple and vendor-agnostic, and you tune telemetry cost/policy in one place.

---

## 4. Correlation — tying logs, traces, and metrics together
The power move: **inject trace_id into logs** (and exemplars into metrics). Then one request's spans, its log lines, and the relevant metric spikes are all joinable by **trace_id / correlation id**. In practice:
- Add trace_id + span_id to every structured log line.
- Propagate a **correlation id** end-to-end (incl. through queues).
- Backends (App Insights) auto-correlate when you use OTel.

**Deep follow-up: "A user reports one failed request — how do you find everything about it?"**
Grab its **correlation/trace id**, pull the full **trace** (all spans across services), and pivot to **logs filtered by that trace_id**. One id → the whole story across every service.

---

## 5. Sampling — controlling cost without going blind
Tracing everything at scale is too expensive. **Sampling** keeps a representative/important subset:
- **Head sampling** — decide at the start (e.g., keep 10%). Cheap, but may drop the rare error trace.
- **Tail sampling** — decide **after** the trace completes (in the Collector): **keep all errors + slow traces**, sample the boring successes. Smarter, needs buffering.
- **Rule of thumb:** keep **100% of errors/slow requests**, sample the healthy majority.

Simple math: 10k req/s × avg 20 spans = 200k spans/s; at 5% head sampling → 10k spans/s stored. Tail sampling lets you additionally guarantee every error is retained.

**Deep follow-up: "Sampling at 5% — won't you miss the failure you care about?"**
Not with **tail-based sampling**: decide after completion and always retain error/slow traces, sampling only successful ones. You cut cost on noise while keeping every interesting trace.

---

## 6. Cardinality — the metric cost/perf trap
A metric's cost explodes with **label cardinality** = product of distinct label values. Putting `user_id` or `request_id` on a metric → millions of time series → blows up storage and query cost (and can crash Prometheus).
- **Rule:** metric labels must be **low-cardinality** (status, region, endpoint). Put high-cardinality identifiers in **logs/traces**, not metric labels.

**Deep follow-up: "Someone added user_id as a metric label and costs exploded — why?"**
Each unique user_id creates a new time series → cardinality explosion → storage/query cost and memory blow up. High-cardinality IDs belong in traces/logs (indexed per-request), never as metric dimensions.

---

## 7. The Golden Signals / RED / USE — what to actually alert on
- **Golden Signals (Google SRE)**: **Latency, Traffic, Errors, Saturation.**
- **RED** (services): **Rate, Errors, Duration.**
- **USE** (resources): **Utilization, Saturation, Errors.**
- **Alert on symptoms** (SLO burn: error rate, p99 latency) **not causes** (CPU 80%) — page humans only for user-impacting problems to avoid alert fatigue.

**Deep follow-up: "What do you alert on?"**
User-facing **SLO burn rate** (error ratio, p99 latency) — symptom-based. CPU/memory are diagnostic dashboards, not pages. This keeps on-call focused on real impact.

---

## 8. Worked scenario: p99 latency spiked 10× — debug flow
1. **Metrics/dashboard** — confirm which service/endpoint and when (RED/golden signals). Traffic change? Error spike?
2. **Traces** — pull slow exemplar traces; find the **span** that grew (which hop: DB? downstream API?).
3. **Logs** — filter by that trace_id/service around that time for the concrete error/query.
4. **Correlate** with deploys/config changes/saturation.
→ Metrics localize *when/where*, traces localize *which hop*, logs give *the exact why*. That three-signal drilldown is the answer they want.

---

## 9. The hard follow-up questions (with answers)
1. **"Monitoring vs observability?"** → monitoring = known metrics; observability = ask new questions of telemetry without new code. (§0)
2. **"Metrics vs logs vs traces?"** → aggregates vs discrete events vs cross-service request path; use all three. (§1)
3. **"How does a trace cross services?"** → W3C `traceparent` context propagation, child spans. (§2)
4. **"Why OTel + a Collector?"** → instrument once, vendor-neutral; Collector centralizes batch/sample/redact/multi-export. (§3)
5. **"Find everything about one bad request?"** → correlation/trace id → full trace → logs by trace_id. (§4)
6. **"Sample 5% but keep failures?"** → tail sampling: retain all errors/slow, sample successes. (§5)
7. **"Why did user_id as a metric label blow up cost?"** → cardinality explosion; IDs go in traces/logs. (§6)
8. **"What do you alert on?"** → SLO burn (latency/errors) symptom-based, not raw CPU. (§7)

---

## 10. One-screen deep-recall sheet
- **Observability = ask new questions of telemetry w/o new code** (vs monitoring known metrics). Pillars: **metrics** (aggregate/how-much) · **logs** (discrete/what) · **traces** (cross-service/where-slow).
- **Trace** = trace_id; **span** = unit of work w/ parent → tree. Cross-service via **W3C `traceparent` context propagation**.
- **OTel pipeline**: App+SDK →(OTLP)→ **Collector** (batch, **sample**, redact PII, enrich, fan-out) → backends (App Insights/Prometheus/Jaeger). Instrument **once**, no lock-in.
- **Correlation**: inject **trace_id into logs**; one id → trace + logs across all services.
- **Sampling**: head (upfront, cheap) vs **tail** (after completion, keep all errors/slow). Rule: **100% of errors**, sample the healthy.
- **Cardinality trap**: high-cardinality labels (user_id) explode metric series → put IDs in logs/traces, keep metric labels low-cardinality.
- **Alerting**: **Golden Signals** (Latency/Traffic/Errors/Saturation), RED, USE → alert on **SLO burn (symptoms)** not CPU (causes).
- **Latency debug**: metrics (when/where) → traces (which hop) → logs (why).

---

> Next: **Cost Optimization / FinOps**.

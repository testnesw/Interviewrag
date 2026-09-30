# DEEP MECHANICS · Azure Functions

> Level 2 — triggers/bindings, hosting plans, cold starts, scaling, and
> durable functions.

---

## 0. The precise mental model
Azure Functions is **event-driven serverless compute**: a function runs in response to a **trigger**, with **bindings** declaratively wiring inputs/outputs (no boilerplate SDK code). The platform **auto-scales** based on event volume and (on Consumption) you **pay per execution**. Functions should be **small, stateless, idempotent, and fast**.

---

## 1. Triggers & bindings (the core abstraction)
- **Trigger** = what invokes the function (exactly one): HTTP, Timer, Queue/Service Bus, Event Grid, Event Hub, Blob, Cosmos change feed.
- **Bindings** = declarative I/O (input/output) → e.g., read from Blob, write to Queue — no manual SDK plumbing.
- Result: focus on business logic; platform handles connection/retry scaffolding.

## 2. Hosting plans (big decision)
| Plan | Scaling | Cold start | Use |
|---|---|---|---|
| **Consumption** | 0→N, event-driven | yes | spiky/low volume, pay-per-use |
| **Premium (EP)** | pre-warmed, VNet | minimal | avoid cold start + VNet + long runs |
| **Dedicated (App Service)** | manual/auto | none | predictable load, reuse existing plan |
| **Flex Consumption** | fast elastic + VNet | reduced | modern serverless w/ networking |

## 3. Cold starts
- On Consumption, idle → no instances → first call pays **cold start** (load runtime + app).
- Mitigate: **Premium** (pre-warmed instances / always-ready), keep deps small, choose fast runtimes, avoid heavy init.

## 4. Scaling
- **Consumption/Premium** scale via the **scale controller** monitoring trigger backlog (queue length, event lag) → adds instances.
- Each instance processes multiple concurrent executions; **max scale-out** limits configurable.
- Design **stateless** so any instance handles any event.

## 5. Durable Functions (stateful orchestration)
- Extension for **stateful workflows** in serverless via an **orchestrator function** (code-defined) + **activity functions**.
- Patterns: **function chaining**, **fan-out/fan-in**, **async HTTP (polling)**, **human interaction/approval**, **monitor**.
- State persisted automatically (event sourcing in storage) → survives restarts; orchestrator code must be **deterministic** (no direct I/O/time).

## 6. Best practices
- **Idempotent** (events may deliver at-least-once → duplicates).
- Short execution (Consumption has timeout ~ up to 10 min default); offload long work to Durable/queues.
- **Managed Identity** for downstream auth; secrets in Key Vault.
- Monitor with **Application Insights**.

## 7. The hard follow-ups (with answers)
1. **"Trigger vs binding?"** → trigger invokes (one); bindings = declarative input/output I/O plumbing. (§1)
2. **"Which plan and why?"** → Consumption (spiky/cheap, cold starts) vs Premium (pre-warmed + VNet) vs Dedicated (predictable). (§2)
3. **"Kill cold starts?"** → **Premium** always-ready instances + small deps. (§3)
4. **"How does it scale?"** → scale controller watches trigger backlog → adds stateless instances. (§4)
5. **"Stateful workflow in serverless?"** → **Durable Functions** (orchestrator + activities; deterministic). (§5)
6. **"Why idempotency?"** → at-least-once delivery → duplicate events possible. (§6)
7. **"Fan-out/fan-in?"** → Durable pattern: parallel activities then aggregate. (§5)

## 8. One-screen recall
- **Event-driven serverless**: **trigger** (1) + **bindings** (declarative I/O).
- **Plans**: Consumption (cheap/cold), **Premium** (pre-warmed+VNet), Dedicated, Flex.
- **Cold start** on Consumption → Premium/always-ready to avoid.
- **Scale**: scale controller on trigger backlog → stateless instances.
- **Durable Functions**: stateful orchestration (chaining, fan-out/in, approval); deterministic orchestrator.
- **Practices**: idempotent, short, MI + Key Vault, App Insights.

> Next: Service Bus.

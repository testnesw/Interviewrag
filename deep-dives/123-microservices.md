# Deep Dive · Microservices Architecture

> Phase 5 (Senior/architect breadth) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Microservices structure an application as a set of **small, independently deployable services**, each owning a **single business capability** and its **own data**, communicating over the network (sync REST/gRPC or async messaging/events). The payoff is **independent deploy/scale, team autonomy, and fault isolation**; the price is **distributed-systems complexity** (network failures, eventual consistency, observability, data consistency). The architect's rule: **don't start with microservices** — start with a well-modularized monolith and split along **bounded contexts (DDD)** only when scaling/team pressure justifies it.

---

## 2. Architect-Level Explanation
Core principles:
- **Single responsibility / bounded context**: one service = one business capability (DDD).
- **Database-per-service**: each service owns its data; no shared DB → loose coupling.
- **Independent deployability**: deploy/scale/version services separately.
- **Decentralized**: teams own services end-to-end ("you build it, you run it").
- **Communication**: **sync** (REST/gRPC) for queries; **async** (events/queues) for decoupling and resilience.
- **Smart endpoints, dumb pipes**: logic in services, not the bus.
- **Design for failure**: retries, timeouts, circuit breakers, bulkheads.

Key patterns: **API Gateway**, **Service Discovery**, **Saga** (distributed transactions), **CQRS/Event Sourcing**, **Circuit Breaker/Bulkhead**, **Strangler Fig** (migration), **Sidecar/Service Mesh**.

---

## 3. Why It Exists
- **Problem with monoliths at scale**: one huge codebase → slow deploys, coupled teams, whole-app redeploy for one change, can't scale hot paths independently, one bug can crash everything.
- **Microservices solve**: independent deploy/scale, team autonomy, fault isolation, tech heterogeneity, targeted scaling.
- **But introduce**: network latency/failure, distributed data consistency, harder debugging, operational overhead — so it's a **tradeoff, not an upgrade**.
- **When justified**: large orgs/teams, need to scale parts independently, high deploy frequency.

---

## 4. Internal Working
```
Client ─► API Gateway (auth, routing, rate limit, aggregation)
              │            │              │
          Order svc    Payment svc    Inventory svc
          (own DB)      (own DB)       (own DB)
              │  events (async, decoupled)  │
              └──────► Message Broker ◄──────┘
                    (Service Bus / Kafka)
```
Mechanics:
- **Gateway** is the single entry (routing, cross-cutting concerns, aggregation).
- **Sync calls** (REST/gRPC) for immediate queries; wrapped in **timeout + retry + circuit breaker**.
- **Async events** for cross-service workflows → **eventual consistency**; use **Saga** to coordinate multi-service transactions with compensating actions.
- **Service discovery** (DNS/mesh) resolves instances; **service mesh** (Istio/Linkerd) handles mTLS, retries, observability via sidecars.
- **Idempotency + outbox pattern** to avoid duplicate/lost events.

---

## 5. Enterprise Use Case
An e-commerce GenAI platform splits into: **Catalog**, **Cart**, **Order**, **Payment**, **Recommendation (GenAI)**, **Notification**. The GenAI recommendation service scales independently on GPU/AOAI load without touching checkout. Checkout uses a **Saga**: Order → reserve Inventory → charge Payment; if payment fails, compensating events release inventory and cancel the order. Everything communicates via **Service Bus** for decoupling; an **API Gateway (APIM)** fronts it all with Entra auth.

---

## 6. Real Production Architecture
```
 Front Door(WAF) ─► APIM (API Gateway: auth, routing, rate-limit)
        │
   AKS cluster (service mesh: mTLS, retries, tracing)
   ┌──────────┬───────────┬───────────┬───────────────┐
   │ Order    │ Payment   │ Inventory │ GenAI-Reco     │
   │ (own DB) │ (own DB)  │ (own DB)  │ (AOAI via MI)  │
   └────┬─────┴─────┬─────┴─────┬─────┴───────┬─────────┘
        └────────── Service Bus / Event Grid ──────────┘
                (async events, Saga orchestration)
        │
   OpenTelemetry ─► App Insights (distributed tracing across services)
```

---

## 7. Security Best Practices
- **Zero trust between services**: **mTLS** (service mesh) — authenticate service-to-service.
- **Gateway-enforced authn/authz** (Entra JWT) + per-service authorization; **defense in depth**.
- **Managed Identity** per service to Azure resources; secrets in **Key Vault**.
- **Network isolation**: private endpoints, network policies (namespace/pod), no public service-to-service.
- **Token propagation** carefully (avoid over-privileged tokens); validate at each service.
- **Per-service least privilege**; audit + distributed tracing for forensics.

---

## 8. Scaling Strategy
- **Scale each service independently** (HPA per deployment) based on its own load.
- **Async messaging** absorbs spikes (queue buffering) and decouples producers/consumers.
- **Stateless services** + externalized state (DB/Redis) → easy horizontal scale.
- **CQRS** to scale reads separately from writes.
- **Gateway rate limiting**; **caching** at gateway/service; **gRPC** for efficient internal calls.

---

## 9. High Availability Strategy
- **Multiple replicas per service across zones**; health probes.
- **Design for failure**: timeouts + retries (idempotent) + **circuit breakers** + **bulkheads** to stop cascading failures.
- **Async decoupling** → a down service doesn't block others (messages queue).
- **Graceful degradation** (e.g., serve cached recommendations if GenAI service down).
- **No single shared DB** → no single point of failure.

---

## 10. Disaster Recovery Strategy
- **IaC-deployable** services + images → rebuild region fast.
- **Per-service data replication** (geo-replicated DBs) drives RPO.
- **Message broker geo-DR** (Service Bus geo-DR / Kafka mirror) so in-flight events survive.
- **Saga/outbox** ensures consistency after recovery; idempotent consumers handle replays.
- Front Door regional failover; test failover including event flows.

---

## 11. Cost Optimization Strategy
- **Right-size per service** — scale only hot services (not the whole app) → big savings vs monolith over-provisioning.
- **Scale-to-zero** for spiky services (Container Apps/KEDA).
- **Async > sync** where possible (fewer always-on connections).
- **Watch the hidden costs**: network egress, broker throughput, per-service infra overhead — microservices can cost *more* if over-fragmented.
- **Consolidate** nano-services that don't need independence.

---

## 12. Common Production Challenges
- **Distributed data consistency** → Saga + eventual consistency + idempotency (no 2PC across services).
- **Cascading failures** → circuit breakers + bulkheads + timeouts.
- **Distributed debugging** → correlation IDs + distributed tracing (OTel) mandatory.
- **Chatty sync calls / latency** → aggregate, cache, prefer async/gRPC.
- **Too-fine granularity (nano-services)** → excessive network + ops overhead.
- **Versioning/contract breakage** → API versioning + consumer-driven contract tests.
- **Duplicate/lost events** → outbox pattern + idempotent consumers.

---

## 13. Monitoring and Observability
- **Distributed tracing** (OpenTelemetry) with correlation IDs across every hop — non-negotiable.
- **Per-service golden signals**: latency, traffic, errors, saturation.
- **Service map** (App Insights) to visualize dependencies + failures.
- **Broker metrics**: queue depth, dead-letter counts, lag.
- **Alerts** per service + on saga failures/dead-letters; centralized logging.

---

## 14. Troubleshooting Scenarios
- **One slow service degrades others** → missing circuit breaker/timeout; add resilience + bulkhead.
- **Data inconsistent across services** → saga compensation gap or non-idempotent consumer; add outbox + idempotency.
- **Requests fail intermittently** → retries without idempotency causing dupes, or transient network; add idempotency keys + retry.
- **Hard to find root cause** → no tracing; add OTel correlation across services.
- **Dead-letter growing** → poison messages/schema mismatch; inspect DLQ, fix contract.

---

## 15. Tradeoffs
| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| Deploy | one unit | independent |
| Scale | whole app | per service |
| Complexity | low | high (distributed) |
| Consistency | easy (ACID) | eventual (saga) |
| Team autonomy | limited | high |
| Debugging | simple | needs tracing |

**Rule: start monolith (modular), split when justified.**

---

## 16. When NOT to use it
- **Small team / early product** → monolith is faster and cheaper (don't pay distributed tax).
- **Simple app** without independent scaling/team needs.
- **Strong transactional consistency** required everywhere (microservices force eventual consistency).
- **Org can't do the ops** (no CI/CD, tracing, on-call maturity) → microservices will hurt.
- **Premature decomposition** before bounded contexts are understood → distributed monolith (worst of both).

---

## 17. Comparison with Alternatives
| Style | Coupling | Best for |
|-------|----------|----------|
| Monolith | tight | small teams, simple apps, start here |
| Modular monolith | modular, one deploy | most apps; split later |
| Microservices | loose, distributed | large orgs, independent scale/deploy |
| Serverless functions | event-driven | spiky, glue, event handlers |

---

## 18. Interview Questions
1. When would you choose microservices over a monolith?
2. How do you handle transactions across services?
3. Sync vs async communication — when each?
4. How do you prevent cascading failures?
5. Database-per-service — why, and how to query across?
6. What is a distributed monolith and how to avoid it?
7. How do you observe/debug microservices?
8. Explain the Saga pattern (orchestration vs choreography).
9. Role of an API Gateway and service mesh?
10. How do you decide service boundaries?

---

## 19. Strong Interview Answers
- **When**: "When independent scaling, deploy frequency, and team autonomy justify the distributed-systems tax. I start with a modular monolith and split along bounded contexts once pain is real — premature microservices create a distributed monolith."
- **Transactions**: "No 2PC across services — I use the **Saga** pattern: a sequence of local transactions with **compensating actions** on failure, coordinated via orchestration or choreography over events, with **idempotent** consumers and the **outbox** pattern for reliable events. Consistency is eventual."
- **Cascading failures**: "Every remote call gets timeout + retry (idempotent) + **circuit breaker**, plus **bulkheads** to isolate resource pools, and async messaging to decouple. Graceful degradation serves fallbacks when a dependency is down."
- **Boundaries**: "By bounded context (DDD) around business capabilities that change together and own their data — not by technical layers. High cohesion inside, loose coupling between, database-per-service."
- **Distributed monolith**: "Services that must deploy together, share a DB, or make chatty sync calls — you get microservice cost with monolith coupling. I avoid it with clear contracts, async decoupling, and independent data."

---

## 20. Architecture Diagrams
**Saga (choreography):**
```
Order.Created ─► Inventory reserves ─► Inventory.Reserved
     ─► Payment charges ─► Payment.Succeeded ─► Order.Confirmed
  (on Payment.Failed) ─► Inventory.Release + Order.Cancelled  (compensation)
```

---

## 21. Real Project Example
**Retail GenAI platform** decomposed into Catalog, Cart, Order, Payment, Inventory, GenAI-Recommendation, Notification. GenAI-Recommendation scales on AOAI load independently — Black Friday spikes there didn't touch checkout. Checkout is a **choreographed saga** over Service Bus with compensating events; consumers are idempotent (outbox + dedup). A **service mesh** provides mTLS + retries; **OpenTelemetry** gives end-to-end traces. Migration from the legacy monolith used the **Strangler Fig** pattern — routing slices to new services behind APIM until the monolith was retired.

---

## 22. Whiteboard Design Question
> *"Design a microservices e-commerce checkout with a GenAI recommendation service."*

Cover: API Gateway (APIM, Entra auth) → services (Catalog/Cart/Order/Payment/Inventory/GenAI-Reco), **database-per-service** → **Saga** (order→reserve inventory→charge payment, compensations) over **Service Bus** → resilience (timeout/retry/circuit breaker/bulkhead) → **service mesh** (mTLS) → **CQRS** for read scaling → per-service HPA autoscaling → **OpenTelemetry** distributed tracing → outbox + idempotency. Justify boundaries via bounded contexts; note eventual consistency.

---

## 23. Design Review Questions
- **Boundaries** by bounded context (not tech layers)? Database-per-service?
- **Cross-service transactions** via **Saga** + compensation + idempotency + outbox?
- **Resilience** on every remote call (timeout/retry/CB/bulkhead)?
- **Sync vs async** chosen deliberately (async for decoupling)?
- **Gateway + mesh** (mTLS, routing, rate limit)?
- **Distributed tracing** (correlation IDs) everywhere?
- **Not a distributed monolith** (no shared DB / deploy coupling / chatty sync)?
- **Contract versioning + tests**?

---

## 24. Hands-on Example
```csharp
// Reliable event publish via Outbox + idempotent consumer (avoid lost/dup events)
// Producer: write state + event in the SAME local transaction (outbox table)
await using var tx = await db.Database.BeginTransactionAsync();
db.Orders.Add(order);
db.OutboxMessages.Add(new OutboxMessage("Order.Created", Serialize(order)));
await db.SaveChangesAsync();
await tx.CommitAsync();
// A relay reads Outbox and publishes to Service Bus (at-least-once)

// Consumer: idempotent (dedupe by message id)
if (await processed.ExistsAsync(msg.Id)) return;   // already handled → skip
await ReserveInventoryAsync(msg);
await processed.AddAsync(msg.Id);
```

---

## 25. Terraform Example
```hcl
# Service Bus topic for decoupled events + per-service subscription
resource "azurerm_servicebus_topic" "orders" {
  name = "order-events" namespace_id = var.sb_namespace_id
}
resource "azurerm_servicebus_subscription" "inventory" {
  name = "inventory-svc" topic_id = azurerm_servicebus_topic.orders.id
  max_delivery_count = 10          # dead-letter poison messages after retries
  dead_lettering_on_message_expiration = true
}
# Each service = its own AKS deployment with its own identity + DB (not shown)
```

---

## 26. Azure Example
```bash
# Deploy independently scalable services on Container Apps (per-service scale rules)
az containerapp create -n order-svc -g rg --environment cae \
  --image acr.azurecr.io/order:1.0 --min-replicas 2 --max-replicas 20 \
  --scale-rule-name sb --scale-rule-type azure-servicebus \
  --scale-rule-metadata queueName=orders messageCount=20   # scale on queue depth (KEDA)
```

---

## 27. Code Example
```python
# Choreographed saga consumer with compensation (Python pseudo-service)
async def on_payment_failed(event):
    # compensating actions — undo prior steps
    await publish("Inventory.Release", {"order_id": event["order_id"]})
    await publish("Order.Cancelled", {"order_id": event["order_id"]})

async def on_order_created(event):
    ok = await reserve_inventory(event)        # local transaction
    if ok:
        await publish("Inventory.Reserved", event)
    else:
        await publish("Order.Cancelled", event)  # nothing to compensate yet
```

---

## 28. Things Architects Must Remember
- **Don't start with microservices** — modular monolith first; split on bounded contexts when justified.
- **Database-per-service**; no shared DB → loose coupling.
- **No distributed transactions (2PC)** — use **Saga** + compensation + **idempotency** + **outbox**; consistency is **eventual**.
- **Design for failure**: timeout + retry + **circuit breaker** + **bulkhead** on every remote call.
- **Async for decoupling**, sync (gRPC/REST) for immediate queries.
- **Distributed tracing (OTel) is mandatory** — you can't debug without it.
- **mTLS + gateway auth + Managed Identity + Key Vault**.
- **Avoid the distributed monolith** (shared DB / deploy coupling / chatty sync).

---

## 29. Mnemonics and Memory Tricks
- **"Microservices = distributed tax"** — only pay it when the benefit is real.
- **Saga "C-C-I-O"**: **C**ompensate, **C**horeograph/orchestrate, **I**dempotent, **O**utbox.
- **Resilience "T-R-C-B"**: **T**imeout, **R**etry, **C**ircuit breaker, **B**ulkhead.
- **"DB per service"** — share nothing.
- **"Trace or you're blind"** — correlation IDs everywhere.
- **"Boundaries = bounded contexts"** (DDD, not tech layers).

---

## 30. One-Page Interview Revision Sheet
- **What**: small, independently deployable services, one business capability each, own data, network comms.
- **Why**: independent deploy/scale, team autonomy, fault isolation — at the cost of distributed complexity.
- **Boundaries**: bounded contexts (DDD); database-per-service.
- **Comms**: sync (REST/gRPC) for queries, async (events/broker) for decoupling.
- **Transactions**: **Saga** + compensation + idempotency + **outbox**; eventual consistency (no 2PC).
- **Resilience**: **T-R-C-B** (timeout/retry/circuit breaker/bulkhead) + graceful degradation.
- **Cross-cutting**: API Gateway (auth/routing/rate-limit), service mesh (mTLS/retries/tracing).
- **Observability**: OpenTelemetry distributed tracing + correlation IDs (mandatory).
- **Security**: zero trust + mTLS, Managed Identity, Key Vault, network isolation.
- **Anti-pattern**: distributed monolith; nano-services.
- **Rule**: modular monolith first → split when justified.
- **Remember**: distributed tax; **C-C-I-O** saga; **T-R-C-B**; DB per service; trace or you're blind.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Justify choosing microservices over a modular monolith — and when you wouldn't.
2. Walk a checkout **Saga** end-to-end, including compensations and idempotency.
3. Why no 2PC across services? What replaces it?
4. How do you stop one failing service from taking down the system?
5. Explain database-per-service and how you query/report across services.
6. What is a distributed monolith and how do you avoid creating one?
7. Sync vs async between services — give a concrete decision for a GenAI reco flow.
8. How do you make event delivery reliable (outbox) and consumers safe (idempotent)?
9. How do you debug a latency spike spanning 5 services?
10. How do you decide service boundaries for a new domain?

---

> Next Phase 5 topic: **Enterprise System Design**.

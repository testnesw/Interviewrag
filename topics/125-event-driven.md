# 125 · Event-Driven Architecture (EDA)

> Domain: Architecture Patterns · Level: Principal Solution Architect

## 1. Beginner Explanation
Event-Driven Architecture is a design where components communicate by **producing and reacting to events** ("something happened") instead of directly calling each other. When an event occurs, interested services react — making the system loosely coupled and responsive.

## 2. Architect-Level Explanation
An architecture style where **events** are the primary means of communication + integration:
- **Event**: an immutable fact that something happened (`OrderPlaced`) — past tense, carries data/reference.
- **Producers/consumers**: producers emit events without knowing who consumes; consumers react independently → **loose coupling** + temporal decoupling.
- **Topologies**: **Broker/pub-sub** (events flow through a broker to interested subscribers — most common, decentralized) vs **Mediator/orchestration** (a central component coordinates a workflow).
- **Patterns**: **event notification** (thin — just "it happened", consumer fetches details), **event-carried state transfer** (event carries the data, reducing callbacks), **event sourcing** (store state as a sequence of events — the log is the source of truth, rebuild state by replay, full audit + temporal queries), **CQRS** (topic 126, often paired).
- **Infra**: message brokers/streaming — Service Bus, Event Grid, Event Hubs/Kafka; schemas + a **schema registry**; **CloudEvents** standard.
- **Delivery**: usually at-least-once → **idempotent consumers**; ordering via partitions/sessions; **outbox** for reliable publishing; saga for workflows.
- **Benefits**: loose coupling, scalability, resilience (buffering absorbs spikes/outages), real-time responsiveness, extensibility (add consumers without touching producers).
- **Challenges**: eventual consistency, harder debugging/tracing, event versioning/schema evolution, duplicate/ordering handling, "event soup" if overused.
- **Fits**: microservices, real-time processing, IoT/telemetry, reactive systems.

## 3. Real Enterprise Use Case
An e-commerce platform is event-driven: `OrderPlaced` flows through **Service Bus/Event Grid**; inventory, billing, shipping, and analytics each react independently (add a new fraud-check consumer without changing the producer). High-volume clickstream uses **Event Hubs** streaming; the order service uses **event sourcing** for a full audit trail + temporal queries; **sagas** coordinate checkout with compensations; **idempotent** consumers + **outbox** ensure reliability under at-least-once delivery.

## 4. Architecture Diagram (ASCII)
```
   Producer ──emit event (OrderPlaced, immutable fact)──► Broker (pub/sub)
        (doesn't know/care who listens)
   ┌──────────┬──────────┬──────────┬───────────┐
   Inventory  Billing    Shipping   Analytics    Fraud(new — no producer change)
   each reacts independently → loose coupling + real-time
   Delivery: at-least-once → idempotent consumers; outbox; saga (workflow)
   Event Sourcing: state = replay of event log (audit + temporal); + CQRS
   Brokers: Service Bus (commands) · Event Grid (notify) · Event Hubs (stream)
```

## 5. Interview Questions
1. What is EDA and its benefits/challenges?
2. Broker vs mediator topology?
3. Notification vs event-carried state transfer?
4. What is event sourcing?
5. How do you handle reliability (idempotency/ordering/consistency)?

## 6. Strong Interview Answers
- **EDA/benefits**: "Components communicate via **events** — immutable facts about what happened — rather than direct calls. Producers don't know consumers, giving loose coupling, independent scaling, resilience (brokers buffer spikes/outages), real-time responsiveness, and extensibility (add consumers without touching producers). The costs are eventual consistency, harder debugging, and event/schema management."
- **Broker vs mediator**: "**Broker/pub-sub** is decentralized — events flow through a broker to any interested subscriber, maximizing decoupling (choreography). **Mediator/orchestration** has a central coordinator driving a workflow, giving visibility and control. I use choreography for loose coupling and orchestration (e.g., a saga orchestrator or Durable Functions) when I need clear, controllable multi-step workflows."
- **Notification vs state transfer**: "**Event notification** is thin — 'OrderPlaced, id=123' — and consumers call back for details (less coupling to data, but more calls). **Event-carried state transfer** puts the needed data in the event, so consumers don't call back — reducing coupling/load at the cost of larger events and some data duplication. I choose based on payload size and how much consumers need."
- **Event sourcing**: "Instead of storing current state, you store the full **sequence of events** as the source of truth; current state is derived by replaying them. Benefits: complete audit trail, temporal queries ('state as of last Tuesday'), and easy rebuilds/projections. Trade-offs: complexity, event versioning, and needing snapshots/CQRS for read performance. I use it where audit/history is critical (finance)."
- **Reliability**: "Delivery is typically at-least-once, so consumers must be **idempotent** (dedupe by event id). Ordering comes from partitions/sessions where needed. I use the **outbox** pattern for reliable publishing (no dual-write loss), **sagas** with compensations for cross-service consistency, and schema/versioning discipline. Consistency is eventual, so I design UX + processes for that."

## 7. Common Mistakes
- Non-idempotent consumers (at-least-once → duplicates).
- Dual-write (DB + broker) without outbox → lost/phantom events.
- "Event soup" — too many fine-grained events, no clear flows.
- No schema/versioning strategy → breaking consumers.
- Assuming ordering/exactly-once without designing for it.
- No distributed tracing → undebuggable event flows.

## 8. Trade-offs
| Aspect | Pro | Con |
|--------|-----|-----|
| Choreography | loose coupling | hard to see whole flow |
| Orchestration | visibility/control | central coupling |
| Event sourcing | audit + temporal | complexity |

## 9. Production Best Practices
- Idempotent consumers; **outbox** for reliable publishing; saga for workflows.
- Choose notification vs state-transfer deliberately; CloudEvents + schema registry + versioning.
- Right broker (Service Bus/Event Grid/Event Hubs) per semantics.
- Distributed tracing (OTel) + correlation across events; DLQ + backoff.
- Design for eventual consistency; document event flows/catalog.

## 10. Security Considerations
- Authn/authz on producers/consumers; least-privilege send/listen.
- Don't put sensitive data in events (use claim-check/references); encrypt.
- Validate/verify event source + schema; protect DLQ (poison payloads).
- Audit event flows for compliance.

## 11. Cost Optimization
- Async buffering enables scale-to-zero consumers (KEDA) → pay per work.
- Right broker/tier per volume; batch; event-carried state transfer reduces callbacks.
- Avoid over-eventing (event soup) → wasted processing.

## 12. Troubleshooting Scenarios
- **Duplicate side effects** → non-idempotent consumer.
- **Lost/phantom events** → dual-write; adopt outbox.
- **Broken consumers after change** → no event versioning; add schema evolution.
- **Can't trace a flow** → no correlation/tracing; add OTel + correlation IDs.
- **Out-of-order processing** → need partitions/sessions for ordering.

## 13. Hands-on Example
```python
# Producer emits an immutable event; consumers react independently (idempotent)
event = {"id": "evt-123", "type": "OrderPlaced", "data": {"order_id": "o-9", "total": 50}}
await broker.publish("orders", event)     # producer doesn't know consumers

async def on_order_placed(e):
    if seen(e["id"]): return              # idempotent (at-least-once)
    await reserve_inventory(e["data"]["order_id"])
```

## 14. Terraform Example
```hcl
# Pub/sub topic + independent subscriptions (each consumer reacts) with DLQ
resource "azurerm_servicebus_topic" "orders" { name = "order-events" namespace_id = var.ns }
resource "azurerm_servicebus_subscription" "inventory" {
  name = "inventory" topic_id = azurerm_servicebus_topic.orders.id
  max_delivery_count = 5 dead_lettering_on_message_expiration = true
}
resource "azurerm_servicebus_subscription" "analytics" {
  name = "analytics" topic_id = azurerm_servicebus_topic.orders.id max_delivery_count = 5
}
```

## 15. Azure Example
Azure EDA building blocks by intent: **Event Grid** (reactive notifications/routing), **Service Bus** (reliable commands/workflows, ordering, DLQ), **Event Hubs/Kafka** (high-throughput streaming/event sourcing log), **Durable Functions** (saga orchestration), **CloudEvents** schema — composed into a full event-driven platform.

## 16. FastAPI / Python Example
```python
# Outbox pattern: state + event committed atomically, then relayed (reliable publish)
@app.post("/orders")
async def place_order(o: OrderIn):
    async with db.transaction():
        oid = await orders.insert(o)
        await outbox.insert({"type": "OrderPlaced", "order_id": oid})  # same tx = no dual-write
    return {"order_id": oid}
# background relay publishes unsent outbox rows to the broker
```

## 17. AKS Example
On AKS, event-driven consumers scale with **KEDA** (scale-to-zero → N on Service Bus/Event Hub/Kafka lag), each service reacting to events independently. A service mesh + **OTel** propagate trace context across async hops for end-to-end tracing; DLQ + outbox ensure reliability during pod restarts/upgrades — elastic, resilient event processing.

## 18. How to Remember
**"Communicate via events (immutable facts); producers don't know consumers = loose coupling; broker(choreography) vs mediator(orchestration); idempotent + outbox + saga; event sourcing = state as replayable log; eventual consistency."**

## 19. Real-World Analogy
A newsroom with a wire service: reporters (producers) publish stories (events) to the wire without knowing who'll use them; any outlet (consumer) — TV, radio, websites, a brand-new blog — picks up and reacts to what's relevant, independently. Adding a new outlet doesn't require the reporter to change anything. The archive of every story ever filed (event sourcing) lets you reconstruct exactly what was known at any past moment.

## 20. One-Page Cheat Sheet
- **What**: components communicate via **events** (immutable facts); producers unaware of consumers → loose coupling + real-time + extensible.
- **Topologies**: **broker/pub-sub** (choreography) vs **mediator** (orchestration).
- **Event styles**: notification (thin) vs **event-carried state transfer** (data in event); **event sourcing** (state = replayable log; audit + temporal) + often **CQRS**.
- **Reliability**: at-least-once → **idempotent consumers**; **outbox** (no dual-write); **saga** + compensations; ordering via partitions/sessions.
- **Infra**: Service Bus (commands) · Event Grid (notify) · Event Hubs/Kafka (stream); CloudEvents + schema registry.
- **Challenges**: eventual consistency, tracing/debugging, event versioning, "event soup".

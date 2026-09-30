# DEEP MECHANICS · Event-Driven Architecture

> Level 2 — brokers vs their guarantees, ordering, delivery semantics,
> idempotency, event sourcing, CQRS, and the failure modes (dead-letter,
> poison messages, duplicate delivery) interviewers drill.

---

## 0. The precise mental model
Event-driven = components communicate by **producing and consuming events** through a **broker**, instead of synchronous request/response. Benefits: **decoupling** (producer doesn't know consumers), **elasticity** (buffer spikes), **resilience** (broker survives consumer downtime). Costs: **eventual consistency**, **harder debugging** (no linear call stack), and you must engineer **ordering, delivery, and idempotency** yourself. The whole game is picking the right broker for your **delivery + ordering** needs and making consumers **idempotent**.

---

## 1. The three Azure messaging services — pick the right one
| | **Service Bus** | **Event Grid** | **Event Hubs** |
|---|---|---|---|
| Pattern | **enterprise messaging** (commands/queues) | **reactive event routing** | **high-volume streaming/telemetry** |
| Model | queue / topic-subscription | pub-sub, HTTP push | partitioned log (Kafka-like) |
| Throughput | moderate, rich features | event-notification | **millions/sec** |
| Ordering | **FIFO via sessions** | no | per-partition |
| Delivery | at-least-once (+ dup detection) | at-least-once | at-least-once |
| Retention | until consumed/TTL | ~24h retry | time-based replay |
| Use when | transactions, workflows, DLQ | glue services, react to Azure events | IoT, logs, event sourcing, analytics |

**One-liner:** Service Bus = **reliable business messaging**; Event Grid = **lightweight reactive routing**; Event Hubs = **firehose ingestion/streaming**.

**Deep follow-up: "Order processing that must not lose or reorder messages?"**
Service Bus **queue with sessions** (FIFO per session key = orderId), **duplicate detection**, **PeekLock** + explicit complete, and a **dead-letter queue** for poison messages. Not Event Grid (no ordering/durability guarantees for that use case).

---

## 2. Delivery semantics — the three, and why exactly-once is a lie
- **At-most-once** — fire and forget; may lose messages. Rare.
- **At-least-once** — **the default reality**; broker retries until ack → **duplicates possible**. You handle dups.
- **Exactly-once** — *end-to-end* is effectively unachievable across a network; what systems offer is **at-least-once delivery + idempotent processing** = "effectively once." Kafka/Event Hubs "exactly-once" is scoped to specific transactional read-process-write within the platform.

**The rule:** design for **at-least-once → make consumers idempotent.** (§4)

**Deep follow-up: "Does your broker guarantee exactly-once?"**
No broker gives true end-to-end exactly-once across services. I get at-least-once from the broker and make processing idempotent (dedupe by message id / business key). That's "effectively once."

---

## 3. Ordering — why it's hard and how it's actually done
Global ordering across a scaled-out topic is expensive/impossible. Real mechanisms:
- **Partition/session key** — messages with the same key (e.g., accountId) go to the **same partition/session** → ordered *within that key*, parallel across keys. This is how Event Hubs/Kafka and Service Bus sessions do it.
- Trade-off: **ordering vs parallelism**. One session = one consumer at a time for that key. Choose a key granular enough to parallelize but coarse enough to preserve the order you need.

**Deep follow-up: "Guarantee per-customer order but still scale?"**
Partition by customerId. Order is preserved within each customer's partition; different customers process in parallel. Never require global order — it kills throughput.

---

## 4. Idempotency — the non-negotiable consumer property
Because delivery is at-least-once, **the same event may arrive twice** (consumer crashed after processing but before ack). Consumers must produce the **same result on reprocessing**. Techniques:
- **Dedup by id** — store processed message ids; skip if seen (inbox pattern).
- **Idempotent operations** — `SET status='paid'` (safe to repeat) not `balance = balance - 10` (not safe).
- **Upsert** on a natural/business key.
- **Conditional writes** (ETag/version) to reject stale/duplicate updates.

**Deep follow-up: "Payment consumer gets the same event twice — no double charge, how?"**
Idempotency key = paymentId. Before charging, check an inbox/dedup store in the **same transaction** as the charge; if the id exists, ack and skip. So reprocessing is a no-op.

---

## 5. Failure handling — retries, DLQ, poison messages
- **PeekLock/visibility timeout** — message is hidden while a consumer works; if it doesn't complete in time, it reappears (redelivery).
- **Retry with backoff** — for transient failures.
- **Dead-Letter Queue (DLQ)** — after N failed deliveries, move the **poison message** off the main queue so it doesn't block others; alert + inspect separately.
- **Max delivery count** — the threshold that triggers dead-lettering.

**Deep follow-up: "One malformed message keeps failing and blocks the queue — fix?"**
Set max delivery count → after N attempts it dead-letters (poison message isolation). Alert on DLQ depth, inspect/repair/replay. The main queue keeps flowing.

---

## 6. The Outbox pattern — the dual-write problem
**Problem:** you must update the DB **and** publish an event. Two separate systems = they can diverge (DB commits, publish fails → lost event; or vice versa). You **cannot** atomically write to DB and broker.
**Solution — Transactional Outbox:** write the event into an **outbox table in the same DB transaction** as the business change. A separate **relay/CDC** process reads the outbox and publishes to the broker (at-least-once), marking rows sent.
```
[Business write + Outbox insert]  ← ONE DB transaction (atomic)
        → Relay/CDC reads outbox → publish to broker → mark sent
```
Guarantees the event is published **iff** the business change committed. Pair with idempotent consumers.

---

## 7. Event Sourcing & CQRS internals
- **Event Sourcing** — store the **sequence of events** (facts: `OrderPlaced`, `ItemAdded`) as the source of truth, not just current state. Rebuild state by **replaying** events. Gives full audit + time-travel; costs: querying current state is hard (→ snapshots), schema/versioning of events, replay complexity.
- **CQRS** — separate the **write model** (commands, normalized, validation) from the **read model** (queries, denormalized, fast). They're synced via events. Lets you scale/optimize reads and writes independently.
- **Together:** commands append events (write side) → projections build read models (query side). Reads are **eventually consistent** with writes.

**Deep follow-up: "Downside of event sourcing?"**
Complexity: event versioning/schema evolution, rebuilding read models, snapshotting for performance, and eventual consistency. Only use it where audit/temporal queries justify the cost — not everywhere.

---

## 8. The hard follow-up questions (with answers)
1. **"Service Bus vs Event Grid vs Event Hubs?"** → reliable business messaging vs reactive routing vs high-volume streaming. (§1)
2. **"Exactly-once — real?"** → no end-to-end; at-least-once + idempotency = effectively once. (§2)
3. **"How do you get ordering at scale?"** → partition/session key; ordered per key, parallel across keys. (§3)
4. **"Make a consumer idempotent?"** → dedup by id (inbox), idempotent ops/upserts, conditional writes. (§4)
5. **"Poison message handling?"** → max delivery count → DLQ, alert, inspect/replay. (§5)
6. **"Update DB and publish event atomically?"** → you can't dual-write; use the **outbox pattern** + relay/CDC. (§6)
7. **"Event sourcing vs CQRS?"** → ES stores events as truth (replay); CQRS splits read/write models; often combined, eventually consistent. (§7)
8. **"Biggest downside of EDA?"** → eventual consistency + debugging difficulty (no linear stack) → need tracing/correlation ids. (§0)

---

## 9. One-screen deep-recall sheet
- **EDA** = produce/consume events via broker → decoupling, elasticity, resilience; cost = eventual consistency + harder debugging.
- **Brokers**: **Service Bus** (reliable messaging, sessions=FIFO, DLQ, dup-detect) · **Event Grid** (reactive routing) · **Event Hubs** (partitioned streaming firehose, replay).
- **Delivery** = **at-least-once** (reality) → duplicates → **make consumers idempotent**. Exactly-once end-to-end = myth; "effectively once."
- **Ordering** via **partition/session key**: ordered per key, parallel across keys. Trade ordering vs parallelism.
- **Idempotency**: dedup by id (inbox), idempotent ops/upsert, conditional (ETag) writes.
- **Failure**: PeekLock/visibility timeout → retry+backoff → **max delivery count → DLQ** (poison isolation) → alert/replay.
- **Outbox pattern** solves dual-write: event row in **same DB txn** as business change → relay/CDC publishes → mark sent. Publish iff committed.
- **Event Sourcing** = events as source of truth, replay to rebuild (audit/time-travel; needs snapshots+versioning). **CQRS** = separate write/read models synced by events, eventually consistent.

---

> Next: **Managed Identity / Entra ID**.

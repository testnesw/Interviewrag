# DEEP MECHANICS · Microservices (Distributed Systems Internals)

> Level 2 — the hard parts: how Saga actually works step by step, the outbox
> pattern mechanics, idempotency, delivery guarantees, boundary decisions, and
> the resilience internals that prevent cascading failure.

---

## 0. The precise mental model
Microservices trade **in-process function calls (reliable, transactional, fast)** for **network calls (unreliable, non-transactional, slow)**. Everything hard about microservices flows from that one trade: the network can fail, messages can duplicate or arrive out of order, and you **cannot have ACID transactions across services**. The patterns (Saga, outbox, idempotency, circuit breaker) all exist to manage those specific consequences. Master those four and you can answer almost anything.

---

## 1. Why no distributed transactions (2PC) — the root constraint

**Two-phase commit (2PC)** *could* span services (prepare → commit) but is avoided in practice because:
- It's a **blocking protocol**: participants hold locks during "prepare"; if the coordinator dies, participants are stuck (blocked/uncertain) → availability killer.
- It **doesn't scale** and couples services to a coordinator.
- Many cloud data stores/queues don't support it.

**So consistency becomes eventual**, coordinated by the **Saga pattern** — a sequence of **local** transactions (each ACID within its own service) plus **compensating** transactions to undo on failure.

---

## 2. Saga — step by step, both flavors

**Choreography (event-driven, decentralized):** each service reacts to events and emits new events — no central coordinator.
```
OrderService: create Order(PENDING) → emit Order.Created
InventoryService: on Order.Created → reserve stock → emit Inventory.Reserved
                  (if out of stock) → emit Inventory.Failed
PaymentService: on Inventory.Reserved → charge → emit Payment.Succeeded / Payment.Failed
OrderService: on Payment.Succeeded → Order(CONFIRMED)
COMPENSATION on failure (e.g., Payment.Failed):
  InventoryService: on Payment.Failed → release stock
  OrderService: on Payment.Failed → Order(CANCELLED)
```
Pros: loose coupling, no coordinator SPOF. Cons: **hard to see the whole flow**; cyclic event dependencies; harder to debug.

**Orchestration (central coordinator):** a **saga orchestrator** explicitly calls each step and issues compensations on failure.
```
Orchestrator: reserve inventory → charge payment → confirm order
   if payment fails → call inventory.release, order.cancel (compensate in reverse)
```
Pros: flow is explicit, easier to reason/debug, centralized error handling. Cons: the orchestrator is a component to build/run.

**Key property — compensations, not rollbacks:** you can't "roll back" a committed local transaction; you run a **semantically compensating** action (release the reserved stock, refund the charge). Compensations must themselves be **idempotent** and should always eventually succeed (retry).

**Deep follow-up: "What if the compensating transaction itself fails?"**
Retry it (it's idempotent); if it keeps failing, it goes to a **dead-letter queue** and raises an alert for manual/automated intervention. Sagas assume compensations eventually succeed — you must monitor and handle stuck compensations, or you get inconsistent state.

---

## 3. The dual-write problem & the Outbox pattern

**The bug everyone hits:** a service needs to **update its DB** *and* **publish an event**. If you do them as two separate operations:
```
db.save(order)          # succeeds
broker.publish(event)   # CRASH here → DB updated but event LOST → inconsistent
```
You can't wrap a DB write and a broker publish in one atomic transaction (different systems). This is the **dual-write problem**.

**Outbox pattern (the fix):**
1. In the **same local DB transaction** as the business write, insert the event into an **`outbox` table**. Now both commit atomically (one DB, one transaction).
2. A separate **relay/poller** (or **CDC** on the outbox table) reads unpublished outbox rows and publishes them to the broker, marking them sent.
3. If publishing fails, the relay retries (the row is still there) → **at-least-once** delivery, never lost.

**Deep follow-up: "Outbox guarantees the event is sent at least once — so consumers may see duplicates. How do you handle that?"**
Make consumers **idempotent** (next section). At-least-once + idempotent consumer = effectively-once processing. That pairing is the standard reliable-messaging answer.

---

## 4. Delivery guarantees & idempotency

**Delivery semantics:**
- **At-most-once** — may lose messages (fire and forget). Rarely acceptable.
- **At-least-once** — never lost, **may duplicate** (retries, redelivery after a consumer crash before ack). **The practical default** (Service Bus, Kafka).
- **Exactly-once** — very hard end-to-end; usually *simulated* as at-least-once + idempotent consumer.

**Idempotency (the mechanism):** processing the same message twice yields the same result as once. Implement with:
- An **idempotency key** (message ID / business key) + a **processed-messages table**: check "have I seen this ID?" → skip if yes, else process + record ID (in the same transaction).
- Naturally idempotent operations (`SET status = 'PAID'` is idempotent; `balance += 10` is **not**).

**Ordering:** most brokers only guarantee order **within a partition/session**, not globally. If order matters (events for one order), route them to the **same partition/session key**.

**Deep follow-up: "Retries cause a customer to be charged twice — root cause and fix?"**
The charge operation isn't idempotent and there's no dedup. Fix: attach an **idempotency key** to the payment; the payment service records processed keys and returns the prior result on a duplicate — so a retry doesn't double-charge. (This is exactly how Stripe's idempotency keys work.)

---

## 5. Service boundaries — how to actually decide

**By bounded context (DDD), not technical layers.** A service should own a **business capability** whose data and rules **change together**. Signals:
- **High cohesion inside, loose coupling outside** — things that change together live together.
- **Owns its data** (database-per-service); no other service reads its tables directly.
- Communicates only via **APIs/events**, never shared DB.

**Anti-pattern — the distributed monolith:** services that must **deploy together**, **share a database**, or make **chatty synchronous** call chains. You pay the distributed cost (latency, failure modes) with none of the independence. Worse than a monolith.

**Deep follow-up: "How do you avoid a distributed monolith?"**
Database-per-service (no shared tables), async decoupling where possible, versioned contracts + consumer-driven contract tests, and boundaries drawn on bounded contexts so services can deploy independently. If two services always change/deploy together, they're really one service.

---

## 6. Communication: sync vs async (deliberate choice)
- **Sync (REST/gRPC)** — for **queries** needing an immediate response. Every sync hop adds latency and a failure dependency → wrap in **timeout + retry + circuit breaker**. **gRPC** for internal high-perf (binary, streaming, contracts).
- **Async (events/commands via broker)** — for **decoupling, resilience, spike absorption**. Producer doesn't wait; consumer processes when able; a down consumer just means messages queue. Enables Saga choreography.

**Rule:** prefer async between services where latency allows; reserve sync for genuine request/response.

---

## 7. Resilience internals — stopping cascading failure

- **Timeout** — never wait forever on a remote call; bound it (else threads pile up waiting).
- **Retry (with backoff + jitter)** — for **transient** faults; only on **idempotent** operations; jitter avoids synchronized retry storms.
- **Circuit breaker** — tracks failure rate to a dependency; on threshold **opens** (fail fast, don't call) for a cooldown, then **half-opens** to test recovery. Prevents hammering a dead service and frees resources.
- **Bulkhead** — isolate resource pools (e.g., separate thread/connection pools per dependency) so one slow dependency can't exhaust everything (like ship compartments).
- **Backpressure** — queues absorb load; shed or throttle when overwhelmed.
- **Graceful degradation** — serve a fallback (cached/partial) when a dependency is down.

**Deep follow-up: "One slow downstream service is taking the whole system down — why and fix?"**
Without timeouts/circuit breakers, callers block waiting on the slow service, exhausting their threads/connections → they become unresponsive → the failure **cascades** upstream. Fix: **timeout + circuit breaker + bulkhead** so the slow dependency is isolated and fails fast, plus graceful degradation.

---

## 8. The hard follow-up questions (with answers)
1. **"Why not 2PC across services?"** → blocking protocol, holds locks, coordinator SPOF, doesn't scale → use **Saga** + eventual consistency. (§1)
2. **"Walk a checkout Saga incl. a payment failure."** → order pending → reserve inventory → charge; on failure **compensate** (release stock, cancel order); orchestration or choreography. (§2)
3. **"Compensation fails — then what?"** → retry (idempotent) → DLQ + alert; monitor stuck compensations. (§2)
4. **"You updated the DB but the event was lost on a crash — what pattern fixes it?"** → **Outbox**: write event to outbox in the same DB transaction; relay publishes at-least-once. (§3)
5. **"At-least-once means duplicates — how do you not double-process?"** → **idempotent consumer** (idempotency key + processed table). (§4)
6. **"Customer charged twice on retry — root cause/fix?"** → non-idempotent charge; add idempotency key + dedup. (§4)
7. **"How do you pick service boundaries?"** → bounded contexts / business capabilities that change together; database-per-service; avoid distributed monolith. (§5)
8. **"One slow service cascades — stop it."** → timeout + circuit breaker + bulkhead + graceful degradation. (§7)

---

## 9. One-screen deep-recall sheet
- **Root trade**: in-process (ACID, reliable) → network (no ACID, can fail/dup/reorder). All patterns manage this.
- **No 2PC** (blocking, coordinator SPOF) → **Saga** = local transactions + **compensations** (not rollbacks); compensations must be idempotent + eventually succeed (retry→DLQ).
- **Saga flavors**: **choreography** (events, loose, hard to trace) vs **orchestration** (central coordinator, explicit, debuggable).
- **Dual-write problem** → **Outbox**: event into outbox table in the **same DB transaction**; relay/CDC publishes → at-least-once, never lost.
- **Delivery**: at-least-once is the default → **duplicates** → **idempotent consumer** (idempotency key + processed table) = effectively-once. Order only within partition/session key.
- **Boundaries**: bounded contexts / capabilities that change together; **database-per-service**; comms via API/events only. **Distributed monolith** (shared DB / deploy-coupled / chatty sync) = the anti-pattern.
- **Comms**: sync (REST/gRPC) for queries (wrap in timeout/retry/CB); async (broker) for decoupling/resilience/spikes.
- **Resilience**: **timeout + retry(backoff,jitter,idempotent) + circuit breaker(open/half-open) + bulkhead + backpressure + graceful degradation** stop cascading failure.

---

> Next: **System Design**.

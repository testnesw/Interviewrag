# DEEP MECHANICS · Messaging Patterns

> Level 2 — pub/sub, competing consumers, delivery guarantees, idempotency,
> outbox, saga, and DLQ.

---

## 0. The precise mental model
Asynchronous messaging **decouples** producers from consumers in **time, space, and rate** → resilience + independent scaling. The patterns are the standard vocabulary for building reliable distributed systems: how messages are **distributed** (queue vs pub/sub), **delivered** (semantics + idempotency), and **coordinated** across services (outbox, saga).

---

## 1. Distribution patterns
- **Point-to-point (queue)** + **competing consumers**: one message → one of N workers → **load leveling** + horizontal scale.
- **Publish/subscribe (topic)**: one event → many subscribers (fan-out); producers don't know consumers.
- **Request/reply**: async command with a correlation id + reply queue.

## 2. Delivery semantics
- **At-most-once** (fire-forget, may lose), **at-least-once** (may duplicate — most common), **exactly-once** (hard; usually = at-least-once + **idempotency/dedup**).
- Real systems pick **at-least-once + idempotent consumers**.

## 3. Idempotency (essential)
- Consumer must handle **duplicate** delivery safely → use **idempotency keys / dedup store / upserts** so reprocessing has no extra effect. (Retries + at-least-once make duplicates inevitable.)

## 4. Reliability patterns
- **Dead-letter queue**: park poison/undeliverable messages after N retries → inspect/replay without blocking.
- **Retry with exponential backoff + jitter**; **circuit breaker** on failing downstream.
- **Message TTL** + **deferral**; **poison message** handling.

## 5. Data consistency across services
- **Transactional Outbox**: write business data + an "event" row in the **same DB transaction**; a relay publishes it → avoids the dual-write problem (DB commit but broker publish fails).
- **Saga**: manage a distributed transaction as a sequence of local transactions + **compensating actions** on failure (choreography via events, or orchestration via a coordinator).
- **CDC / change feed** as an alternative event source.

## 6. Ordering & routing
- Global ordering is expensive → order **per key/partition** (Service Bus sessions, Event Hubs partitions).
- **Content-based routing / message filters** (topic subscriptions) → subscribers get only relevant messages.
- **Claim-check**: store large payload externally, pass a reference in the message.

## 7. The hard follow-ups (with answers)
1. **"Why async messaging?"** → decouple producer/consumer in time/space/rate → resilience, buffering, independent scaling. (§0)
2. **"Queue vs pub/sub?"** → queue = one consumer (competing); pub/sub = fan-out to many. (§1)
3. **"Exactly-once — real?"** → practically **at-least-once + idempotency/dedup**. (§2/§3)
4. **"Dual-write problem fix?"** → **transactional outbox** (business data + event in one tx). (§5)
5. **"Distributed transaction without 2PC?"** → **saga** with compensating actions. (§5)
6. **"Poison message?"** → retries with backoff → **dead-letter queue**. (§4)
7. **"Order guarantee?"** → per-key/partition (sessions/partitions), not global. (§6)
8. **"Huge payloads?"** → **claim-check** (store externally, send reference). (§6)

## 8. One-screen recall
- **Decouple** in time/space/rate → resilience + scale.
- **Distribute**: queue (**competing consumers**) vs **pub/sub** (fan-out); request/reply.
- **Semantics**: at-least-once (default) → **idempotent consumers** (dedup keys).
- **Reliability**: **DLQ** + retry(backoff+jitter) + circuit breaker + TTL.
- **Consistency**: **outbox** (dual-write fix) + **saga** (compensation).
- **Ordering**: per key/partition; **content routing/filters**; **claim-check** for big payloads.

> Next: Entra ID.

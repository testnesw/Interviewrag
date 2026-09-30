# DEEP MECHANICS · Azure Service Bus

> Level 2 — queues vs topics, delivery semantics, sessions, dead-lettering, and
> ordering.

---

## 0. The precise mental model
Service Bus is an **enterprise message broker** for **reliable, decoupled, transactional** messaging (commands/events between services). It guarantees **at-least-once** delivery with **competing consumers**, supports **pub/sub (topics)**, **ordering (sessions)**, **dead-lettering**, and **transactions** — the tool when you need *guaranteed, ordered, or transactional* delivery (not raw throughput).

---

## 1. Queues vs topics
- **Queue** = point-to-point; multiple consumers **compete** (each message to one consumer) → load leveling.
- **Topic + subscriptions** = **publish/subscribe**; each subscription gets its own copy; **filters/rules** route messages per subscription.

## 2. Delivery & receive modes
- **At-least-once** by default → design **idempotent** consumers.
- **Peek-Lock** (default): message locked → consumer processes → **Complete** (removes) / **Abandon** (retry) / **Dead-letter**. Lock renewal for long work.
- **Receive-and-Delete**: removes on read (at-most-once, faster, risk of loss).

## 3. Ordering — sessions
- Queues don't globally guarantee order across competing consumers.
- **Sessions** (`SessionId`) → all messages with same session go to **one consumer in order** → FIFO per session (e.g., per-order events).

## 4. Dead-letter queue (DLQ)
- Sub-queue for messages that **can't be processed**: exceed **max delivery count**, expired TTL, or filter/processing errors.
- Lets you inspect/replay poison messages without blocking the main queue.

## 5. Reliability features
- **Duplicate detection** (dedupe by MessageId within a window).
- **Transactions** (atomic send/complete across entities).
- **Scheduled** + **deferred** messages; **TTL**; **auto-forward**.
- **Prefetch** for throughput; **partitioning** for scale (Premium).

## 6. Tiers & when to use
- **Standard** (shared, pay-per-op) vs **Premium** (dedicated capacity, predictable latency, VNet/private endpoint, larger messages).
- **Use Service Bus** when you need: guaranteed delivery, ordering, transactions, DLQ, pub/sub with filters.
- **Not** for high-volume telemetry streaming → that's **Event Hubs**; simple reactive events → **Event Grid**.

## 7. The hard follow-ups (with answers)
1. **"Queue vs topic?"** → queue = competing consumers (1 gets it); topic = pub/sub (each subscription a copy, with filters). (§1)
2. **"Delivery guarantee?"** → **at-least-once** → idempotent consumers; peek-lock + Complete. (§2)
3. **"Guarantee order?"** → **sessions** (FIFO per SessionId to one consumer). (§3)
4. **"Poison message handling?"** → **dead-letter queue** after max delivery count. (§4)
5. **"Avoid processing duplicates?"** → duplicate detection + idempotency. (§5)
6. **"Service Bus vs Event Hubs vs Event Grid?"** → SB = enterprise messaging (order/txn/DLQ); Event Hubs = high-volume streaming; Event Grid = lightweight reactive events. (§6)
7. **"Peek-lock vs receive-delete?"** → peek-lock = safe (complete/abandon); receive-delete = fast but can lose. (§2)

## 8. One-screen recall
- **Enterprise broker**: reliable, ordered, transactional messaging.
- **Queue** (competing consumers) vs **Topic+subscriptions** (pub/sub + filters).
- **At-least-once** → idempotent; **peek-lock** (Complete/Abandon/DLQ) vs receive-delete.
- **Sessions** = FIFO ordering per SessionId.
- **DLQ** = poison/expired messages (max delivery count).
- **Extras**: dup detection, transactions, scheduled/deferred, TTL.
- **vs**: Event Hubs (streaming), Event Grid (reactive events).

> Next: Event Grid.

# DEEP MECHANICS · Azure Event Hubs

> Level 2 — partitions, consumer groups, offsets/checkpointing, throughput
> units, and Kafka compatibility.

---

## 0. The precise mental model
Event Hubs is a **high-throughput event streaming platform** ("big data pipe") — ingest **millions of events/sec** (telemetry, logs, IoT, clickstream). Events are appended to **partitions** (ordered logs), **retained** for a window, and read by **consumer groups** that track their own **offset** via **checkpointing**. It's a *stream* (replayable log), not a queue (no per-message ack/delete).

---

## 1. The log + partitions
- An Event Hub = a **partitioned append-only log**.
- **Partition** = ordered sequence; ordering guaranteed **within a partition** only.
- **Partition key** → same key routes to same partition (per-key ordering, e.g., per-device).
- Partition count is set at creation (scales parallelism); more partitions = more parallel consumers.

## 2. Consumer groups
- A **consumer group** = an independent "view"/read cursor over the whole hub → multiple pipelines read the same stream independently (e.g., real-time dashboard + archival).
- Within a group, **one consumer per partition** (ownership) → parallel consumption.

## 3. Offsets & checkpointing
- Consumers track position via **offset/sequence number**; **checkpoint** persists progress (to Blob storage).
- On restart, resume from last checkpoint → at-least-once (may reprocess since last checkpoint → **idempotent** needed).
- Events are **not deleted on read** → replayable within retention.

## 4. Throughput & scaling
- **Throughput Units (TU)** (Standard) / **Processing Units** (Premium) / **Capacity Units** (Dedicated) gate ingress/egress.
- **Auto-inflate** raises TUs under load.
- 1 TU ≈ 1 MB/s or 1000 events/s in; 2 MB/s out (guideline).

## 5. Capture & Kafka
- **Event Hubs Capture** → auto-archive stream to Blob/Data Lake (Avro) for batch/analytics — no code.
- **Kafka endpoint**: Event Hubs speaks the **Kafka protocol** → existing Kafka apps connect without code changes.

## 6. When to use
- **Streaming ingestion** (telemetry, logs, IoT, events for analytics / Stream Analytics / Spark).
- **Not** for per-message commands/transactions → that's **Service Bus**; not for discrete reactive events → **Event Grid**.

## 7. The hard follow-ups (with answers)
1. **"Event Hubs vs Service Bus?"** → EH = high-volume replayable **stream** (offsets, no delete); SB = reliable **messaging** (ack/complete, DLQ, order via sessions). (§0/§6)
2. **"How is ordering guaranteed?"** → **within a partition**; use partition key for per-key order. (§1)
3. **"Multiple independent readers?"** → **consumer groups** (separate cursors). (§2)
4. **"How do consumers resume?"** → **checkpointing** offsets to storage; at-least-once → idempotent. (§3)
5. **"Scale ingest?"** → **Throughput Units** (+ auto-inflate) / partitions for parallelism. (§4)
6. **"Archive stream cheaply?"** → **Event Hubs Capture** to Blob/ADLS. (§5)
7. **"Reuse Kafka apps?"** → **Kafka protocol endpoint**. (§5)

## 8. One-screen recall
- **High-throughput streaming** (millions/sec): partitioned **append-only log**, replayable.
- **Partition** = ordered log (order only within); **partition key** = per-key order.
- **Consumer groups** = independent read cursors; 1 consumer/partition.
- **Offsets + checkpointing** (to Blob) → resume; **at-least-once** → idempotent; not deleted on read.
- **Scale**: Throughput/Processing Units + auto-inflate + partitions.
- **Capture** → Blob/ADLS (Avro); **Kafka** protocol compatible.
- **vs**: Service Bus (messaging), Event Grid (reactive events).

> Next: Messaging Patterns.

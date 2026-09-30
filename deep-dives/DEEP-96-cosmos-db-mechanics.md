# DEEP MECHANICS · Azure Cosmos DB

> Level 2 — partitioning, the 5 consistency levels, RUs, global distribution,
> and why partition-key choice makes or breaks it.

---

## 0. The precise mental model
Cosmos DB = **globally distributed, horizontally partitioned NoSQL** with **guaranteed low latency** and **tunable consistency**. It scales by spreading data across **physical partitions** keyed by your **partition key**, bills by **Request Units (RUs)**, and lets you trade **consistency vs latency/availability** across 5 levels. The single most important decision is the **partition key** — get it wrong and you get hot partitions and throttling.

---

## 1. Partitioning (the make-or-break)
- Each item has a **partition key**; Cosmos hashes it to a **logical partition**, mapped onto **physical partitions**.
- **Good partition key** = high cardinality + even access distribution → spreads data and RUs evenly.
- **Bad key** = **hot partition** (one key gets most traffic) → throttling (429) even though total RU is fine.
- A single logical partition caps at 20 GB and a throughput ceiling → choose keys that distribute (e.g., userId not country).

## 2. Request Units (RUs) — the currency
- Every operation (read/write/query) costs **RUs** (a point read of 1KB ≈ 1 RU; writes/queries cost more).
- You provision **RU/s** (or **autoscale** / **serverless**). Exceed it → **429 throttled** (SDK retries).
- Cost + performance = RU management. Provisioned throughput is shared across partitions → hot partitions waste it.

## 3. The 5 consistency levels (strong → eventual)
| Level | Guarantee | Latency/availability |
|---|---|---|
| **Strong** | linearizable, latest write | highest latency, single-region-write feel |
| **Bounded Staleness** | lag bounded by K versions / T time | tunable |
| **Session** (default) | consistent **within a client session** (read-your-writes) | great balance |
| **Consistent Prefix** | reads never see out-of-order writes | |
| **Eventual** | no order guarantee, converges | lowest latency, highest availability |
**Session** is the sweet spot for most apps. This is the classic CAP/PACELC trade-off made a dial.

## 4. Global distribution
- **Turnkey multi-region replication** — add regions with a click; data replicated globally.
- **Multi-region writes (multi-master)** — write to any region, low local latency; needs **conflict resolution** (last-write-wins or custom).
- **Automatic/manual failover** for regional outages → high availability (up to 99.999%).

## 5. APIs & indexing
- **APIs**: Core (SQL/NoSQL, default), MongoDB, Cassandra, Gremlin (graph), Table → wire-compatibility for migrations.
- **Automatic indexing** of all fields (tune with indexing policy to save RUs/storage).
- **Change feed** — ordered log of changes per partition → event-driven/materialized views/ETL.

## 6. When to use Cosmos vs SQL
Cosmos: global scale, low-latency, high-throughput, flexible schema, key-based access. Azure SQL: relational, complex joins/transactions, strong consistency by default. Don't use Cosmos for heavy relational/analytical queries.

## 7. The hard follow-ups (with answers)
1. **"Why is partition key the most important choice?"** → determines data/RU distribution; bad key → hot partition → 429 throttling. (§1)
2. **"What's an RU?"** → normalized cost unit per operation; provisioned/autoscale/serverless; exceed → throttled. (§2)
3. **"Five consistency levels?"** → strong, bounded staleness, **session (default)**, consistent prefix, eventual — latency/consistency dial. (§3)
4. **"Multi-region writes trade-off?"** → low local write latency but **conflict resolution** needed (LWW/custom). (§4)
5. **"What's the change feed for?"** → ordered per-partition change log → event-driven, materialized views, ETL. (§5)
6. **"Cosmos vs Azure SQL?"** → global low-latency NoSQL/key-access vs relational joins/strong-consistency. (§6)

## 8. One-screen recall
- Cosmos = **globally distributed, partitioned NoSQL**, guaranteed low latency, **tunable consistency**.
- **Partition key** = make/break: high cardinality + even access → no **hot partition (429)**. Logical partition ≤20GB.
- **RUs** = per-op currency; provisioned/autoscale/serverless; exceed→**429** (SDK retries).
- **5 consistency**: Strong → Bounded Staleness → **Session (default, read-your-writes)** → Consistent Prefix → Eventual (latency/consistency dial = PACELC).
- **Global**: turnkey replication, **multi-region writes** (conflict resolution LWW/custom), auto failover (99.999%).
- **APIs**: Core/Mongo/Cassandra/Gremlin/Table; auto-indexing; **change feed** for events.
- Use for scale/low-latency/flexible schema; not heavy relational.

> Next: Redis.

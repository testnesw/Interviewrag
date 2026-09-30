# DEEP MECHANICS · Azure Cache for Redis

> Level 2 — why in-memory, caching patterns, eviction/expiry, data structures,
> clustering/persistence, and cache pitfalls (stampede, invalidation).

---

## 0. The precise mental model
Redis is an **in-memory key-value store** used mainly as a **cache** to cut latency and offload databases. Because data lives in RAM, reads are **sub-millisecond**. The architecture questions are: **which caching pattern**, **how to expire/evict**, **how to stay consistent with the source of truth**, and **how to scale/persist**. Caching is fundamentally a **consistency vs speed** trade-off.

---

## 1. Why a cache (and what it costs)
- **Speed** — RAM reads ~microseconds vs DB milliseconds.
- **Offload** — absorb read traffic so the DB isn't hammered.
- **Cost of caching** — **staleness** (cache can diverge from source) and **invalidation complexity** ("one of the two hard problems").

## 2. Caching patterns
- **Cache-aside (lazy loading)** — app checks cache; miss → read DB → populate cache. Most common. Only caches what's used; stale until TTL/invalidation.
- **Read-through** — cache library loads from DB on miss transparently.
- **Write-through** — write to cache + DB synchronously → cache always fresh, slower writes.
- **Write-behind** — write to cache, async to DB → fast writes, risk of loss.
Pick by read/write ratio + staleness tolerance.

## 3. Expiry & eviction
- **TTL** — per-key expiry; primary staleness control.
- **Eviction policy** when memory full: **LRU**, **LFU**, random, TTL-based, or `noeviction` (reject writes). `allkeys-lru` is common for caches.
- Right-size memory + eviction to your working set.

## 4. Data structures (Redis is more than strings)
Strings, **hashes** (objects), **lists** (queues), **sets**, **sorted sets** (leaderboards/rate-limiting), streams (event log), HyperLogLog, geospatial, pub/sub. Enables rate limiters, leaderboards, session stores, distributed locks, queues.

## 5. Scaling & persistence
- **Clustering** — shard keys across nodes (hash slots) → scale beyond one node's RAM/throughput.
- **Replication** — primary + replicas for read scale + HA (automatic failover).
- **Persistence** — **RDB** (snapshots) / **AOF** (append-only log) for durability (Azure tiers: Premium+ support persistence, zones, VNet).
- Azure tiers: Basic (single node), Standard (replicated), Premium (clustering/persistence/VNet), Enterprise (Redis modules, active geo-replication).

## 6. Cache pitfalls (interviewers probe)
- **Cache stampede/thundering herd** — many misses hit DB at once (e.g., key expiry) → use locking/single-flight, staggered TTLs, or refresh-ahead.
- **Stale data** — TTL + explicit invalidation on writes.
- **Hot keys** — one key overwhelms a node → replicate/split.
- **Cache penetration** — queries for non-existent keys bypass cache → cache negatives / bloom filter.

## 7. The hard follow-ups (with answers)
1. **"Cache-aside vs write-through?"** → lazy populate on miss (stale until TTL) vs sync write to cache+DB (fresh, slower writes). (§2)
2. **"How do you keep cache consistent with the DB?"** → TTL + explicit invalidation on write; write-through for freshness. (§2,6)
3. **"Eviction when full?"** → LRU/LFU/TTL/noeviction; size to working set. (§3)
4. **"Cache stampede — what/fix?"** → mass misses hammer DB → locking/single-flight, staggered TTL, refresh-ahead. (§6)
5. **"Scale Redis beyond one node?"** → clustering (hash-slot sharding) + replicas. (§5)
6. **"Use beyond caching?"** → session store, rate limiter (sorted sets), leaderboard, distributed lock, pub/sub, queue. (§4)

## 8. One-screen recall
- Redis = **in-memory KV cache**, sub-ms reads; offloads DB; cost = **staleness + invalidation**.
- **Patterns**: **cache-aside** (lazy, common), read-through, **write-through** (fresh, slower), write-behind (fast, risky).
- **Expiry/eviction**: **TTL** + policy (**LRU/LFU**/noeviction) sized to working set.
- **Structures**: strings, hashes, lists, sets, **sorted sets** (leaderboard/rate-limit), streams, pub/sub → locks, sessions, queues.
- **Scale**: **clustering** (hash slots) + replicas (HA); **persistence** RDB/AOF (Premium+).
- **Pitfalls**: **stampede** (lock/stagger/refresh-ahead), stale (invalidate), hot keys, penetration (cache negatives/bloom).

> Next: Batch C — Networking & Resilience.

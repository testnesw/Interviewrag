# 97 · Azure Cache for Redis

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Azure Cache for Redis is a **fast in-memory data store** used to speed up applications. Frequently used data (like sessions or query results) is kept in memory so apps read it in microseconds instead of hitting a slower database every time.

## 2. Architect-Level Explanation
Managed Redis (in-memory key-value store) for caching + more:
- **Use cases**: cache-aside, session store, output/page caching, rate limiting, leaderboards, distributed locks, pub/sub, message queues (streams), real-time analytics.
- **Data structures**: strings, hashes, lists, sets, sorted sets, streams, bitmaps, HyperLogLog, geospatial.
- **Patterns**: **cache-aside (lazy loading)** — app checks cache, on miss loads DB + populates cache with TTL; write-through/write-behind; read-through.
- **Tiers**: Basic (single node, no SLA), Standard (replicated, 2-node HA), **Premium** (clustering, persistence, VNet, geo-replication, larger), **Enterprise / Enterprise Flash** (Redis Enterprise — RediSearch, RedisJSON, active geo-replication, higher throughput, NVMe flash).
- **Scale**: clustering (sharding) in Premium/Enterprise; scale up (bigger) / out (shards).
- **HA/DR**: replicas, zone redundancy, geo-replication (Premium/Enterprise active-active).
- **Persistence** (Premium): RDB snapshots / AOF for recovery.
- **Eviction**: maxmemory policies (LRU/LFU/TTL); set TTLs to avoid stale/unbounded growth.
- **Security**: Entra ID auth + Managed Identity, private endpoints, TLS, no public access.

## 3. Real Enterprise Use Case
A high-traffic web platform uses Premium Redis (clustered, zone-redundant) for **cache-aside** on product catalog reads (cutting DB load ~80%), distributed **session store** for stateless app servers, **rate limiting** on APIs, and a **leaderboard** via sorted sets — with Entra ID auth, private endpoints, and geo-replication for DR.

## 4. Architecture Diagram (ASCII)
```
   App ── read ──► Redis (hit: µs) ─┐
     │  miss                        │ populate + TTL
     └──► Database (slow) ──────────┘   (cache-aside)
   Uses: session store · rate limit · leaderboard (sorted set) · pub/sub · locks
   Tiers: Basic│Standard(HA)│Premium(cluster/persist/VNet/geo)│Enterprise
   Eviction: LRU/LFU + TTL | Entra ID auth + private endpoint + TLS
```

## 5. Interview Questions
1. What is cache-aside and why is it common?
2. Which tier for clustering/persistence/VNet?
3. How do you prevent stale data and cache stampede?
4. What non-cache uses does Redis have?
5. How do you secure Redis?

## 6. Strong Interview Answers
- **Cache-aside**: "The app checks the cache first; on a miss it reads the database, writes the result into the cache with a TTL, and returns it. It's simple, resilient (cache failure just means DB reads), and only caches what's actually used. The trade-off is potential staleness, managed via TTL and invalidation on writes."
- **Tier**: "**Premium** for clustering (sharding), data persistence, VNet injection, zone redundancy, and geo-replication. **Enterprise/Enterprise Flash** for Redis modules (RediSearch, RedisJSON), active-active geo, and NVMe flash economics at large scale. Standard for basic HA; Basic only for dev."
- **Staleness/stampede**: "Use TTLs and invalidate/update cache on writes for freshness. Prevent **cache stampede** (many misses hammering the DB when a hot key expires) with request coalescing/locking, staggered/jittered TTLs, or background refresh. Use LFU/LRU eviction under memory pressure."
- **Non-cache uses**: "Session store, distributed locks, rate limiting (INCR + expiry), leaderboards (sorted sets), pub/sub messaging, Redis Streams as a lightweight queue, and real-time counters/analytics — Redis is a versatile data-structure server, not just a cache."
- **Secure**: "Entra ID auth + Managed Identity (over access keys), private endpoints, TLS-only, disable non-TLS + public access, and firewall/VNet. Rotate keys if used; least privilege."

## 7. Common Mistakes
- No TTLs → stale data + unbounded memory.
- Caching everything (low hit ratio, wasted memory).
- Ignoring cache stampede on hot-key expiry.
- Basic tier (no SLA) in production.
- Storing large blobs in Redis (memory pressure).

## 8. Trade-offs
| Pattern | Pro | Con |
|---------|-----|-----|
| Cache-aside | simple, resilient | possible staleness |
| Write-through | fresh cache | write latency |
| Clustering | scale-out | multi-key op limits |

## 9. Production Best Practices
- Always set TTLs; jittered expiry; invalidate on write.
- Premium+ for HA/clustering/persistence; zone redundancy.
- Right eviction policy (allkeys-lru/lfu); monitor hit ratio + memory.
- Prevent stampede (locking/coalescing); connection pooling/multiplexing.
- Entra ID + private endpoints + TLS.

## 10. Security Considerations
- Entra ID + Managed Identity; disable access keys where possible.
- Private endpoints; TLS-only; no public/non-TLS access.
- Don't store sensitive data unencrypted; network isolation.
- Rotate keys; least-privilege.

## 11. Cost Optimization
- Right-size memory + tier; scale out only when needed.
- High hit ratio (cache the right data) maximizes value.
- Enterprise Flash (NVMe) for large datasets cheaper than all-RAM.
- Reserved capacity for steady workloads.

## 12. Troubleshooting Scenarios
- **Low hit ratio** → wrong data cached / TTL too short.
- **Memory maxed / evictions** → size up, tune eviction, add TTLs.
- **Latency spikes** → big keys / blocking ops (KEYS) / no clustering.
- **DB overload on expiry** → cache stampede; add coalescing/jitter.
- **Connection errors** → pool/multiplex; avoid connection churn.

## 13. Hands-on Example
```bash
az redis create -g rg -n redis-prod --sku Premium --vm-size P1 \
  --shard-count 2 --redis-configuration maxmemory-policy=allkeys-lru \
  --minimum-tls-version 1.2 --zones 1 2 3
```

## 14. Terraform Example
```hcl
resource "azurerm_redis_cache" "redis" {
  name = "redis-prod" resource_group_name = var.rg location = "eastus"
  capacity = 1 family = "P" sku_name = "Premium"
  minimum_tls_version = "1.2" public_network_access_enabled = false
  redis_configuration { maxmemory_policy = "allkeys-lru" }
  zones = ["1","2","3"]
}
```

## 15. Azure Example
```bash
# Enable Entra ID (passwordless) authentication for Redis
az redis identity assign -g rg -n redis-prod --mi-system-assigned
az redis access-policy-assignment create -g rg --cache-name redis-prod \
  --access-policy-name "Data Contributor" --object-id $APP_MI_ID --object-id-alias app
```

## 16. FastAPI / Python Example
```python
import redis.asyncio as redis, json
r = redis.Redis(host="redis-prod.redis.cache.windows.net", port=6380, ssl=True)

async def get_product(pid: str):
    key = f"prod:{pid}"
    if cached := await r.get(key):          # cache hit
        return json.loads(cached)
    product = await db_fetch(pid)           # miss → DB
    await r.set(key, json.dumps(product), ex=300)   # populate + TTL (cache-aside)
    return product
```

## 17. AKS Example
AKS pods share a Redis session store so any pod can serve any user (stateless scaling). Redis-backed **rate limiting** protects backends, and KEDA can scale consumers on **Redis Streams/list** length. Workload Identity + private endpoint secure access without keys.

## 18. How to Remember
**"In-memory µs store: cache-aside (miss→DB→populate+TTL); more than cache (sessions, locks, rate limit, leaderboards); Premium=cluster/persist/VNet; always TTL."**

## 19. Real-World Analogy
A barista's front counter with the most-ordered drinks pre-made (cache): regulars get served instantly; if something's not ready (miss), they make it fresh and keep one on the counter for next time (populate). Old drinks get tossed after a while (TTL) so nothing goes stale.

## 20. One-Page Cheat Sheet
- **What**: managed in-memory Redis key-value store; µs latency.
- **Pattern**: cache-aside (check cache → miss → DB → populate + **TTL**).
- **Beyond cache**: sessions, distributed locks, rate limiting, leaderboards (sorted sets), pub/sub, streams.
- **Tiers**: Basic (dev) / Standard (HA) / **Premium** (cluster, persist, VNet, geo, zones) / Enterprise (modules, active-active, Flash).
- **Watch**: TTLs + eviction (LRU/LFU), cache stampede (coalesce/jitter), hit ratio, big keys.
- **Secure**: Entra ID + Managed Identity, private endpoint, TLS-only.

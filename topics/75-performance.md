# 75 · Python / API Performance

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Performance is about making your API fast and able to handle many users at once — by using async properly, caching results, tuning the database, and running enough worker processes.

## 2. Architect-Level Explanation
API performance is a full-stack concern across concurrency, I/O, and resources:
- **Concurrency model**: async for I/O-bound (many connections per worker); multiple **Uvicorn workers** (via Gunicorn) to use all CPU cores; process pools for CPU-bound.
- **Don't block the loop**: any sync/blocking call kills async throughput → use async drivers or executors.
- **Caching**: in-process (LRU), distributed (Redis), and HTTP caching (ETag/CDN) to cut repeated work.
- **Database**: connection pooling, indexes, avoid N+1, pagination, read replicas.
- **Payloads**: pagination, compression (gzip/brotli), efficient serialization (Pydantic v2, orjson).
- **Resource tuning**: right requests/limits; HPA on CPU/concurrency; keep-alive/timeouts.
- **Profiling & metrics**: measure p50/p95/p99, use profilers (py-spy, cProfile), load test (Locust/k6).
- **Scale-out vs up**: horizontal (more pods) for stateless async services.
- **GIL awareness**: threads don't parallelize CPU; use processes.

## 3. Real Enterprise Use Case
A high-traffic API cuts p99 from 800 ms to 180 ms: converts blocking calls to async, adds Redis caching for hot reads, fixes N+1 with eager loading + indexes, enables orjson + gzip, runs Gunicorn with N Uvicorn workers per pod, and autoscales on concurrency — handling 10× traffic at lower cost.

## 4. Architecture Diagram (ASCII)
```
   Client ─► CDN/ETag cache ─► Gunicorn (N Uvicorn workers = cores)
                                   │ async handlers (I/O-bound)
        ┌──────────────┬──────────┴───────────┐
   Redis cache     DB (pool, indexes,     CPU work ─► process pool
   (hot reads)      no N+1, replicas)
   Metrics: p50/p95/p99 · profile (py-spy) · load test (k6)
   Scale-out: HPA on CPU/concurrency (stateless pods)
```

## 5. Interview Questions
1. How do you scale a Python API?
2. Why can one blocking call ruin async performance?
3. How do you use caching effectively?
4. How do you find and fix bottlenecks?
5. Threads vs processes vs async for performance?

## 6. Strong Interview Answers
- **Scale**: "Async for I/O concurrency, multiple Uvicorn workers per pod to use all cores, and horizontal pod autoscaling since the service is stateless. Add caching and DB tuning to reduce work per request."
- **Blocking call**: "asyncio runs on one thread; a sync/blocking call doesn't yield, so it freezes the event loop and every concurrent request waits. That single call can collapse throughput — I use async libs or `run_in_executor`."
- **Caching**: "Layered — in-process LRU for tiny hot data, Redis for shared cached results, and HTTP caching (ETag/CDN) for cacheable responses. I set TTLs and invalidation carefully to avoid stale data."
- **Bottlenecks**: "Measure first — p95/p99 latency, then profile with py-spy/cProfile and check DB query plans. Common culprits: N+1 queries, blocking calls, missing indexes, oversized payloads. I load-test with k6/Locust to validate."
- **Threads/processes/async**: "async and threads help I/O-bound work; only processes give true CPU parallelism because of the GIL. So: async for I/O, process pool for CPU-bound, multiple worker processes to use cores."

## 7. Common Mistakes
- Blocking calls in async handlers.
- Single worker process (one core used).
- No caching → repeated expensive work.
- N+1 queries / missing indexes.
- Optimizing without profiling (guesswork).

## 8. Trade-offs
| Lever | Pro | Con |
|-------|-----|-----|
| Caching | fast, less load | staleness/invalidation |
| More workers | uses cores | more memory |
| Read replicas | scale reads | replication lag |

## 9. Production Best Practices
- Async end-to-end; Gunicorn + N Uvicorn workers (~cores).
- Layered caching (LRU/Redis/HTTP) with sane TTLs.
- DB pooling, indexes, no N+1, pagination.
- orjson + compression; efficient Pydantic v2.
- Profile + load-test; HPA on CPU/concurrency; set timeouts.

## 10. Security Considerations
- Rate limiting/throttling to protect under load.
- Timeouts + circuit breakers to avoid cascading failures.
- Cache poisoning protection (key on auth/tenant).
- Bound payload sizes to prevent DoS.

## 11. Cost Optimization
- Caching + async → fewer pods for same traffic.
- Right worker count/resources (avoid overprovision).
- Efficient serialization/compression reduces CPU + egress.
- Scale-to-zero for spiky/event workloads (KEDA).

## 12. Troubleshooting Scenarios
- **High p99 under load** → blocking call / N+1 / GC pauses.
- **Only one core used** → single worker; add workers.
- **DB slow** → missing index / pool exhaustion.
- **Memory growth** → unbounded cache / leaked sessions.
- **Latency spikes** → no timeouts; slow downstream.

## 13. Hands-on Example
```bash
# Load test and profile
k6 run --vus 200 --duration 1m load.js
py-spy top --pid $(pgrep -f uvicorn)     # live profiler
```

## 14. Terraform Example
```hcl
# Redis cache for hot reads
resource "azurerm_redis_cache" "cache" {
  name = "api-cache" resource_group_name = var.rg location = "eastus"
  capacity = 1 family = "C" sku_name = "Standard" minimum_tls_version = "1.2"
}
```

## 15. Azure Example
```dockerfile
# Multi-worker production server (Gunicorn + Uvicorn workers)
CMD ["gunicorn", "main:app", "-k", "uvicorn.workers.UvicornWorker", \
     "-w", "4", "-b", "0.0.0.0:8080", "--timeout", "60"]
```

## 16. FastAPI / Python Example
```python
import orjson, redis.asyncio as redis
from functools import lru_cache
r = redis.from_url("redis://cache:6379")

@app.get("/product/{pid}")
async def product(pid: int):
    if cached := await r.get(f"p:{pid}"):
        return orjson.loads(cached)                 # cache hit (fast)
    data = await db_fetch_product(pid)              # miss → DB
    await r.set(f"p:{pid}", orjson.dumps(data), ex=60)
    return data
```

## 17. AKS Example
```yaml
resources:
  requests: { cpu: "500m", memory: "512Mi" }
  limits:   { cpu: "1",    memory: "1Gi" }
# HPA scales on CPU 60%; each pod runs 4 Uvicorn workers → cores fully used
```

## 18. How to Remember
**"Async + workers + cache + DB tuning — and measure."** Never block the loop; processes for CPU, async for I/O.

## 19. Real-World Analogy
A busy coffee shop: async is one barista juggling many orders while drinks brew (I/O waits); more baristas (workers) use the whole counter (cores); a pre-made stock of popular drinks (cache) speeds service; and a well-organized supply shelf (DB indexes) avoids trips to the back room.

## 20. One-Page Cheat Sheet
- **Concurrency**: async for I/O; N Uvicorn workers (~cores); processes for CPU (GIL).
- **Never** block the event loop → async drivers / `run_in_executor`.
- **Cache**: LRU + Redis + HTTP/ETag/CDN with TTLs.
- **DB**: pool, indexes, no N+1, pagination, replicas.
- **Payload**: orjson + gzip/brotli; Pydantic v2.
- **Measure**: p95/p99, py-spy/cProfile, k6/Locust; HPA + right-sized resources.

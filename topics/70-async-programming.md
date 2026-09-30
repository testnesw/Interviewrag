# 70 · Async Programming (Python asyncio)

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Async programming lets your code do other work while waiting for slow operations (like network or database calls) instead of sitting idle. In Python you write `async def` functions and use `await` to pause without blocking everything else.

## 2. Architect-Level Explanation
Python `asyncio` provides cooperative concurrency on a single-threaded event loop:
- **Coroutines**: `async def` functions; `await` yields control back to the event loop during I/O waits.
- **Event loop**: schedules ready coroutines; achieves high concurrency for **I/O-bound** work without threads/processes.
- **Concurrency ≠ parallelism**: asyncio interleaves tasks on one thread — great for I/O, not for CPU-bound work (GIL blocks it).
- **CPU-bound**: offload to `run_in_executor` (threads) or process pools / separate services.
- **Primitives**: `asyncio.gather` (concurrent awaits), `TaskGroup` (structured concurrency, 3.11+), `Semaphore` (limit concurrency), `timeout`.
- **Async libraries required**: use async DB drivers (asyncpg), `httpx`/`aiohttp` — a single blocking call stalls the whole loop.
- **Blocking = poison**: never call sync/blocking functions in the event loop.

## 3. Real Enterprise Use Case
A FastAPI service aggregates data from 5 downstream APIs and a database per request. Using `asyncio.gather`, it fires all calls concurrently — cutting p95 latency from ~1.5 s (sequential) to ~350 ms — and handles thousands of concurrent connections per pod without thread explosion.

## 4. Architecture Diagram (ASCII)
```
   Event Loop (single thread)
    ├─ coroutine A ─ await DB ──┐ (yields)
    ├─ coroutine B ─ await HTTP─┤ loop runs others while waiting
    └─ coroutine C ─ await LLM ─┘
   gather([A,B,C]) → run concurrently, resume when I/O ready
   CPU-bound? ─► run_in_executor (threads) / process pool
   One blocking sync call ─► STALLS the whole loop ✗
```

## 5. Interview Questions
1. Concurrency vs parallelism in Python?
2. What does `await` actually do?
3. Why is asyncio bad for CPU-bound work?
4. How do you run tasks concurrently?
5. What happens if you call a blocking function in async code?

## 6. Strong Interview Answers
- **Concurrency vs parallelism**: "Concurrency is dealing with many tasks by interleaving them (asyncio on one thread); parallelism is doing many at once on multiple cores. asyncio gives concurrency for I/O-bound work; for parallelism you need processes."
- **await**: "`await` suspends the coroutine at an I/O point and returns control to the event loop, which runs other ready coroutines. When the awaited operation completes, the coroutine resumes — no blocking, no threads."
- **CPU-bound**: "The GIL means only one thread runs Python bytecode at a time, and a CPU-bound coroutine never yields — it blocks the loop. Offload CPU work to a process pool or a separate service; asyncio won't speed it up."
- **Concurrent tasks**: "`asyncio.gather()` or a `TaskGroup` (3.11+ structured concurrency) to await multiple coroutines concurrently; a `Semaphore` bounds concurrency to protect downstreams."
- **Blocking call**: "It stalls the entire event loop — every other request waits. That's the #1 async bug. Use async libraries or `run_in_executor` to push blocking work off the loop."

## 7. Common Mistakes
- Blocking/sync calls (requests, time.sleep, sync DB) in async handlers.
- Using asyncio for CPU-bound work.
- Forgetting `await` (coroutine never runs).
- Unbounded concurrency overwhelming downstreams.
- Mixing sync and async DB sessions.

## 8. Trade-offs
| Model | Best for | Weakness |
|-------|----------|----------|
| asyncio | I/O-bound, high concurrency | CPU-bound (GIL) |
| threads | blocking I/O libs | GIL, overhead |
| processes | CPU-bound | memory, IPC cost |

## 9. Production Best Practices
- Async all the way (async DB drivers, httpx).
- `gather`/`TaskGroup` for concurrency; `Semaphore` to bound it.
- Offload CPU/blocking work to executors/process pools.
- Timeouts on all external awaits.
- Shared clients/pools created in lifespan, reused.

## 10. Security Considerations
- Timeouts + bounded concurrency prevent resource exhaustion/DoS.
- Careful cancellation handling (clean up on timeout).
- Don't leak connections on exceptions (async context managers).

## 11. Cost Optimization
- High concurrency per pod → fewer pods for I/O-bound load.
- Connection pooling reduces overhead.
- Right-size executor/process pools.

## 12. Troubleshooting Scenarios
- **Everything slow under load** → blocking call on the loop.
- **Coroutine "was never awaited"** → missing `await`.
- **Downstream overwhelmed** → add Semaphore/limit.
- **CPU pegged, no concurrency gain** → CPU-bound in asyncio; offload.
- **Hanging requests** → no timeout on external await.

## 13. Hands-on Example
```python
import asyncio, httpx, time

async def fetch(client, url): 
    r = await client.get(url); return r.status_code

async def main():
    async with httpx.AsyncClient() as c:
        urls = ["https://example.com"] * 10
        results = await asyncio.gather(*(fetch(c, u) for u in urls))  # concurrent
        print(results)

asyncio.run(main())
```

## 14. Terraform Example
```hcl
# Scale async I/O-bound service on concurrency (KEDA/HPA)
resource "kubernetes_horizontal_pod_autoscaler_v2" "api" {
  metadata { name = "api" namespace = "app" }
  spec {
    min_replicas = 2 max_replicas = 30
    scale_target_ref { kind = "Deployment" name = "api" api_version = "apps/v1" }
    metric { type = "Resource"
      resource { name = "cpu" target { type = "Utilization" average_utilization = 60 } } }
  }
}
```

## 15. Azure Example
Async FastAPI on Azure Container Apps scales on concurrent HTTP requests (KEDA HTTP scaler) — each replica handles many concurrent awaits to Azure OpenAI/Cosmos DB, so you need fewer replicas than a sync stack.

## 16. FastAPI / Python Example
```python
from fastapi import FastAPI
import asyncio
app = FastAPI()

@app.get("/dashboard")
async def dashboard(uid: int):
    # fire concurrent I/O with bounded concurrency
    sem = asyncio.Semaphore(5)
    async def guarded(coro):
        async with sem: return await coro
    profile, orders, recs = await asyncio.gather(
        guarded(get_profile(uid)), guarded(get_orders(uid)), guarded(get_recs(uid)))
    return {"profile": profile, "orders": orders, "recs": recs}
```

## 17. AKS Example
```python
# CPU-bound work (e.g., PDF render) offloaded so it doesn't block the loop
import asyncio
from concurrent.futures import ProcessPoolExecutor
pool = ProcessPoolExecutor()

@app.post("/render")
async def render(doc: dict):
    loop = asyncio.get_running_loop()
    result = await loop.run_in_executor(pool, cpu_heavy_render, doc)  # off the loop
    return {"bytes": len(result)}
```

## 18. How to Remember
**"await = pause for I/O, let others run."** asyncio = concurrency for I/O-bound; CPU-bound → processes. Never block the loop.

## 19. Real-World Analogy
A single skilled waiter (event loop) serving many tables: after taking an order they don't stand at the kitchen waiting (blocking) — they serve other tables and return when food is ready (await). But if one task needs heavy chopping (CPU-bound), they hand it to the kitchen staff (process pool) rather than doing it at the table.

## 20. One-Page Cheat Sheet
- **asyncio**: cooperative concurrency on a single-threaded event loop.
- **await**: yields at I/O; loop runs other coroutines meanwhile.
- **Great for**: I/O-bound (DB, HTTP, LLM); **bad for**: CPU-bound (GIL) → use processes.
- **Concurrency**: `gather`/`TaskGroup`; bound with `Semaphore`; always set timeouts.
- **Golden rule**: never call blocking/sync code on the loop → `run_in_executor`.
- **Prod**: async drivers, pooled clients in lifespan, right-sized executors.

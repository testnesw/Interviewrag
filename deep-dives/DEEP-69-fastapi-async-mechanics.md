# DEEP MECHANICS · FastAPI & Python Async

> Level 2 — how the event loop actually works, what "blocking the loop" means
> mechanically, the GIL, concurrency primitives, and the FastAPI internals that
> decide throughput. This is where most Python backend interviews get deep.

---

## 0. The precise mental model
Async Python runs **one thread** with an **event loop** that juggles many **coroutines**. A coroutine runs until it hits `await` on an I/O operation, then **yields control** back to the loop, which runs *other* coroutines while that I/O is pending. This gives massive **I/O concurrency** with one thread — but the moment you run **blocking or CPU-bound code without awaiting**, the single thread is stuck and **every** request stalls. The whole game is: **never block the loop.**

---

## 1. The event loop — what actually happens

- The loop maintains a queue of **ready** tasks and a set of **pending** I/O (registered with the OS via `epoll`/`kqueue`/IOCP).
- It runs a ready coroutine until it `await`s something not-yet-ready → the coroutine's state machine **suspends** (saves its stack position) and returns control to the loop.
- The loop asks the OS "which I/O is ready?" and resumes the corresponding coroutines.
- **Cooperative multitasking**: coroutines must *voluntarily* yield (via `await`). There's no preemption — a coroutine that never awaits **hogs the thread**.

**`async`/`await` mechanically:** `async def` creates a **coroutine object** (doesn't run yet). `await x` means "suspend me until awaitable `x` completes, and let the loop run others meanwhile." The compiler builds a resumable **state machine** under the hood.

**Deep follow-up: "How does one thread handle 10,000 concurrent requests?"**
Because requests are **I/O-bound** — most of each request's wall-clock time is *waiting* (DB, HTTP, AOAI). While one request awaits its network I/O, the loop runs thousands of others. The thread is only busy during the tiny CPU slices between awaits. Concurrency ≠ parallelism.

---

## 2. The GIL — why threads don't give CPU parallelism

The **Global Interpreter Lock** allows only **one thread to execute Python bytecode at a time** (CPython). Consequences:
- **Threads do NOT parallelize CPU-bound Python** — they time-slice under one lock.
- **Threads DO help I/O-bound work** — the GIL is released during blocking I/O (and C extensions), so other threads run while one waits.
- **True CPU parallelism** requires **multiprocessing** (separate interpreters/processes, each own GIL) or native/C extensions (NumPy releases the GIL for array math).

**The decision matrix (memorize):**
| Workload | Use | Why |
|---|---|---|
| **I/O-bound, high concurrency** | **asyncio** | one thread, thousands of awaits |
| I/O-bound, simple/blocking libs | threads | GIL released on I/O |
| **CPU-bound** | **multiprocessing** | bypass the GIL |
| Mixed | async + offload CPU to process pool | keep loop free |

---

## 3. Blocking the loop — the cardinal sin, mechanically

If inside an `async def` you call **synchronous blocking code** — `time.sleep(5)`, a **sync DB driver**, `requests.get()`, a heavy CPU loop — you **do not yield** to the loop. The single thread is frozen for that whole duration → **all other requests wait** → throughput collapses, latency spikes for everyone.

**Symptoms in prod:** p99 latency explodes under load, health checks time out, the app "hangs" even though CPU looks low (it's blocked on one sync call).

**The fixes:**
- Use **async libraries** (`httpx`/`aiohttp` not `requests`; `asyncpg`/async SQLAlchemy not sync drivers; `asyncio.sleep` not `time.sleep`).
- **Offload blocking/CPU work** to a pool: `await asyncio.to_thread(fn)` / `loop.run_in_executor(ThreadPoolExecutor, ...)` for blocking I/O; **`ProcessPoolExecutor`** for CPU-bound (embedding math, parsing) so the GIL is bypassed and the loop stays free.

**Deep follow-up: "You have a CPU-heavy embedding computation in an async endpoint — what happens and what do you do?"**
It blocks the loop → every concurrent request stalls for its duration. Offload to a **ProcessPoolExecutor** (or a separate worker service) via `run_in_executor`, so the CPU work runs in another process and the loop keeps serving.

---

## 4. FastAPI internals — sync vs async endpoints

FastAPI is built on **Starlette (ASGI)**. Crucial behavior:
- **`async def` endpoint** → runs **directly on the event loop**. Fast — *but* if it blocks, it stalls everything. Use for async I/O.
- **`def` (sync) endpoint** → FastAPI runs it in an **external threadpool** (so it can't block the loop). Safe for blocking libraries, but limited by threadpool size (default ~40).

**The trap:** putting **blocking code in an `async def`** — worst of both worlds (blocks the loop, no threadpool protection). Either make it truly async, or make the endpoint `def` so it gets the threadpool.

**Deep follow-up: "When should an endpoint be `def` vs `async def`?"**
`async def` when you can `await` async I/O all the way down. `def` when you must call blocking/sync libraries and can't avoid it (FastAPI isolates it in a thread). Never blocking-in-async.

---

## 5. Workers × the loop — how you actually scale

- **Uvicorn** = the ASGI server running **one event loop per worker process**.
- One loop uses **one CPU core** (async gives concurrency, not multi-core). To use all cores you run **multiple workers** (Uvicorn `--workers N` or Gunicorn managing Uvicorn workers), roughly `N ≈ cores`.
- **Total capacity ≈ workers × per-loop concurrency.** In containers, the common pattern is **1–few workers per pod + horizontal pod autoscaling (HPA)** — let Kubernetes scale pods rather than cramming workers.

**Deep follow-up: "Async is single-threaded — how do you use a 16-core node?"**
Run multiple Uvicorn workers (processes), each with its own loop, and/or scale pods horizontally. Async handles concurrency *within* a core; processes/pods give parallelism *across* cores.

---

## 6. Concurrency primitives you must know
- **`asyncio.gather(*coros)`** — run many awaitables **concurrently**, await all (e.g., fan-out to several AOAI/DB calls at once instead of sequentially).
- **`asyncio.Semaphore(n)`** — cap concurrent operations (e.g., limit in-flight AOAI calls to respect rate limits) — *shape load before you get 429s*.
- **`asyncio.TaskGroup`** (3.11+) — structured concurrency with clean cancellation/error propagation.
- **timeouts** (`asyncio.wait_for`) — never await external I/O without a timeout.

**Deep follow-up: "Call 50 downstream services efficiently but don't overwhelm them?"**
`gather` for concurrency + a `Semaphore(k)` to cap simultaneous calls + per-call timeouts + retry/backoff (tenacity). Concurrency with a governor.

---

## 7. FastAPI request lifecycle & DI
- **ASGI middleware** wraps every request (CORS, auth, tracing, timing).
- **Dependency injection** (`Depends`) resolves per request — DB session, current user, settings. Dependencies can be async; a DB-session dependency yields a scoped session and closes it after (like a context manager).
- **Pydantic** validates/parses request bodies into typed models (Rust-backed in v2 → fast) and serializes responses.
- **Streaming**: `StreamingResponse` with an **async generator** streams LLM tokens (SSE) — pair with an async client; ensure no buffering proxy in front.

---

## 8. The hard follow-up questions (with answers)
1. **"How does one thread serve thousands of concurrent requests?"** → I/O-bound: coroutines `await` and yield; the loop runs others during waits. Concurrency ≠ parallelism. (§1)
2. **"Why don't threads speed up CPU-bound Python?"** → the **GIL**: one thread runs bytecode at a time; use **multiprocessing** for CPU. (§2)
3. **"What exactly happens if you put `time.sleep(5)` in an async endpoint?"** → blocks the single loop thread for 5s → all concurrent requests stall. Use `asyncio.sleep` / offload. (§3)
4. **"`def` vs `async def` endpoint — how does FastAPI treat each?"** → `async def` on the loop; `def` in a threadpool. Blocking-in-async is the trap. (§4)
5. **"Async is single-threaded — how do you use 16 cores?"** → multiple Uvicorn workers (processes) + HPA pods. (§5)
6. **"Fan out to many AOAI calls without hitting rate limits?"** → `gather` + `Semaphore` + timeouts + backoff. (§6)
7. **"CPU-bound work in an async service — where does it go?"** → **ProcessPoolExecutor** via `run_in_executor` (bypass GIL, keep loop free). (§3)
8. **"App hangs under load, CPU low — diagnose."** → the loop is **blocked** on a sync call (sync DB driver / `requests` / CPU loop); find and make async or offload. (§3)

---

## 9. One-screen deep-recall sheet
- **Event loop**: one thread, cooperative multitasking; coroutine runs until `await` (I/O) then **yields**; loop runs others; resumes on OS I/O readiness. **Concurrency ≠ parallelism.**
- **GIL**: one thread executes bytecode at a time → threads help **I/O** (GIL released on I/O), not **CPU**. CPU parallelism = **multiprocessing** / C ext (NumPy releases GIL).
- **Decision**: I/O+high concurrency → **asyncio**; CPU → **multiprocessing**; blocking lib → `def` endpoint / `run_in_executor`.
- **Never block the loop**: no `time.sleep`, `requests`, sync DB, CPU loops inside `async def`. Use `httpx`/`asyncpg`/`asyncio.sleep`; offload CPU to **ProcessPoolExecutor**.
- **FastAPI**: `async def` = on loop (fast, but blocking stalls all); `def` = threadpool (safe for blocking). **Blocking-in-async = worst case.**
- **Scale**: Uvicorn = 1 loop/worker = 1 core; **workers × pods (HPA)** for multi-core/parallelism.
- **Primitives**: `gather` (concurrent fan-out), **`Semaphore`** (cap in-flight → respect 429s), timeouts, TaskGroup, tenacity retries.
- **Lifecycle**: ASGI middleware → `Depends` DI (scoped async sessions) → Pydantic v2 validation → `StreamingResponse` (SSE, no buffering proxy).
- **Prod hang, low CPU** = blocked loop → find the sync call.

---

> ✅ Batch 2 complete (Vector Search · Terraform State · FastAPI/Async).
> Remaining high-ROI: Agentic AI, Semantic Kernel, Microservices, Event-driven,
> System Design, Managed Identity/Entra, Observability/OTel, Cost/FinOps.
> Say "continue" for the next batch.

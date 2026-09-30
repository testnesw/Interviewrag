# DEEP MECHANICS · Python Performance

> Level 2 — the GIL, concurrency models, profiling, caching, DB/IO, and when to
> reach for C/Rust.

---

## 0. The precise mental model
Python performance is about **matching the concurrency model to the workload**: **I/O-bound** → async or threads (the GIL is released during I/O); **CPU-bound** → multiprocessing or native extensions (the GIL serializes Python bytecode). Optimize only after **profiling** — find the real hot path, don't guess.

---

## 1. The GIL (Global Interpreter Lock)
- One lock → only **one thread executes Python bytecode at a time** (in CPython).
- **I/O-bound**: GIL is **released during I/O** → threads/async give real concurrency.
- **CPU-bound**: threads **don't** speed up (GIL serializes) → use **multiprocessing** or native code.
- (Python 3.13+ has experimental **free-threaded / no-GIL** builds.)

## 2. Concurrency model choice
| Workload | Best tool | Why |
|---|---|---|
| Many network/DB calls | **asyncio** | single thread, event loop, huge concurrency, low overhead |
| Blocking I/O libs | **threads** (`ThreadPoolExecutor`) | GIL released on I/O |
| CPU crunching | **multiprocessing** | separate interpreters/processes → true parallelism |
| Heavy numeric | **NumPy / native** | vectorized C, releases GIL |

## 3. Profiling (measure first)
- **`cProfile`** (function-level time/calls), **`line_profiler`** (per-line), **`py-spy`** (sampling, prod-safe, no code change).
- **`tracemalloc`** / `memory_profiler` for memory.
- Rule: **profile → find hot path → optimize that** → re-measure. Avoid premature optimization.

## 4. Common wins
- **Caching**: `functools.lru_cache` (pure functions); external cache (**Redis**) for cross-process/expensive results.
- **Algorithmic**: right data structure (set/dict O(1) lookup vs list O(n)); avoid O(n²).
- **Batch**: bulk DB ops, fewer round-trips; **connection pooling**.
- **Avoid N+1** DB queries (eager-load).
- **Generators** / streaming for large data → constant memory vs building huge lists.

## 5. I/O & DB
- Use **async drivers** (asyncpg/httpx) for high-concurrency I/O.
- **Connection pooling** (avoid per-request connect cost).
- Push work to the DB (indexes, set-based queries) instead of Python loops.

## 6. Interpreter-level
- **Local variable** access faster than global/attribute lookups; hoist lookups out of tight loops.
- **`__slots__`** to cut per-instance memory/attr overhead.
- Offload hot loops to **C extensions / Cython / Rust (PyO3)** or **NumPy**; consider **PyPy** (JIT) for pure-Python CPU code.

## 7. The hard follow-ups (with answers)
1. **"What is the GIL and why does it matter?"** → one lock → one thread runs bytecode at a time → threads help I/O, not CPU. (§1)
2. **"CPU-bound speedup?"** → **multiprocessing** or native/NumPy (bypass GIL), not threads. (§1/§2)
3. **"10k concurrent API calls?"** → **asyncio** + async HTTP client (event loop, low overhead). (§2)
4. **"How do you find the bottleneck?"** → **profile** (cProfile/py-spy) first, optimize the hot path, re-measure. (§3)
5. **"Cache expensive function?"** → `lru_cache` (in-proc) or Redis (cross-process). (§4)
6. **"Process a 50GB file?"** → **generators/streaming** → constant memory. (§4)
7. **"threads vs async for I/O?"** → async = one thread + event loop (scales to many, no thread overhead); threads = simpler with blocking libs (GIL released on I/O). (§2)

## 8. One-screen recall
- **GIL**: 1 thread runs bytecode → **I/O-bound = threads/async** (GIL freed on I/O); **CPU-bound = multiprocessing/native**.
- **Pick**: asyncio (many I/O) · threads (blocking I/O) · multiprocessing (CPU) · NumPy (numeric).
- **Profile first**: cProfile / line_profiler / **py-spy** / tracemalloc → optimize hot path.
- **Wins**: `lru_cache`/Redis, right data structures, batch + pooling, kill N+1, generators.
- **Deep**: `__slots__`, local vars, Cython/Rust/NumPy, PyPy.

> Next: pytest.

# Question Bank · Top 50 Python & FastAPI Architect Questions

> Architect-level answers focused on backend/GenAI services. Say them aloud.

---

## Language Core (1–14)

**1. What is the GIL and why does it matter?**
The Global Interpreter Lock lets only one thread execute Python bytecode at a time (CPython). So threads don't parallelize CPU-bound work — use **multiprocessing** or native/C extensions for CPU parallelism; threads/async still help **I/O-bound** work. (I-B-C: I/O→async, CPU→processes.)

**2. Async vs threads vs multiprocessing — when each?**
Async (single thread, event loop) for high-concurrency **I/O** (APIs, DB, AOAI calls); threads for blocking I/O with simple libs; multiprocessing for **CPU-bound** parallelism (bypasses GIL).

**3. How does async/await work in Python?**
`async def` defines coroutines; `await` yields control to the event loop during I/O so other coroutines run. Single-threaded concurrency — **never block the loop** with sync/CPU work.

**4. What breaks an async app?**
Calling blocking/sync code (sync DB drivers, `time.sleep`, CPU loops) in the event loop stalls everything. Use async libraries or offload to a thread/process pool (`run_in_executor`).

**5. Mutable default argument pitfall?**
`def f(x=[])` shares one list across calls (evaluated once). Use `None` + create inside. Classic interview gotcha.

**6. `__init__` vs `__new__`?**
`__new__` creates the instance; `__init__` initializes it. Rarely override `__new__` (immutable types, singletons/metaclasses).

**7. Decorators — what and why?**
Functions wrapping functions to add behavior (logging, auth, caching, retry) without changing the wrapped code — cross-cutting concerns; use `functools.wraps`.

**8. Context managers (`with`)?**
Guarantee setup/teardown (files, DB sessions, locks) via `__enter__`/`__exit__` or `@contextmanager` — deterministic resource cleanup even on exceptions.

**9. Generators and `yield`?**
Lazy iterators producing values on demand — memory-efficient for large/streaming data (e.g., streaming LLM tokens or large files).

**10. List comprehension vs generator expression?**
List builds all in memory (`[...]`); generator (`(...)`) yields lazily — use generators for large/streamed data to save memory.

**11. `*args` / `**kwargs`?**
Variadic positional/keyword arguments — flexible signatures, wrappers/decorators, forwarding.

**12. Shallow vs deep copy?**
Shallow copies references to nested objects; deep copy recursively duplicates. Deep copy for independent nested mutable structures (`copy.deepcopy`).

**13. Type hints — value in production?**
Static checking (mypy/pyright), better IDE/tooling, self-documentation, and runtime validation (Pydantic/FastAPI). Essential for large codebases.

**14. How does Python memory management work?**
Reference counting + a cyclic garbage collector for reference cycles. Watch for leaks via lingering references (caches, globals, closures).

---

## FastAPI & Web (15–30)

**15. Why FastAPI for GenAI backends?**
Async-native (high concurrency for I/O-bound AOAI/DB calls), Pydantic validation, auto OpenAPI docs, dependency injection, and strong performance (Starlette + Uvicorn). ("Don't block the loop.")

**16. How does FastAPI achieve high throughput?**
ASGI + async I/O: while awaiting external calls, the event loop serves other requests — one worker handles many concurrent requests. Scale with Uvicorn/Gunicorn workers × pods (W×P).

**17. Uvicorn vs Gunicorn — how do you run FastAPI?**
Uvicorn = ASGI server (event loop); Gunicorn manages multiple Uvicorn workers (processes) for multi-core. In containers: Uvicorn workers + horizontal pod scaling.

**18. Sync vs async endpoints in FastAPI?**
Async endpoints run on the loop (use for async I/O); sync endpoints run in a threadpool (safe for blocking libs). Mixing wrong (blocking in async) stalls the loop.

**19. What is Pydantic and why use it?**
Data validation + serialization via type hints; parses/validates request bodies, enforces schemas, and gives clear errors — the backbone of FastAPI request/response models.

**20. FastAPI dependency injection?**
`Depends()` injects reusable components (DB session, auth, settings) per request — clean separation, testability, and shared logic (e.g., current user).

**21. How do you stream responses (LLM tokens)?**
`StreamingResponse` / SSE / WebSockets yield tokens as generated — cut time-to-first-token; use async generators.

**22. How do you handle background tasks?**
`BackgroundTasks` for lightweight post-response work; Celery/queue (Service Bus) for heavy/reliable async jobs — don't block the request.

**23. How do you handle blocking libraries in async FastAPI?**
Run them in a thread/process pool (`run_in_executor` / `anyio.to_thread`) or use a sync endpoint (threadpool) — never call blocking code directly on the loop.

**24. How do you secure a FastAPI service?**
OAuth2/JWT (Entra) via dependencies, HTTPS, input validation (Pydantic), rate limiting, CORS locked down, secrets via Key Vault + Managed Identity, no secrets in code.

**25. How do you validate and handle errors cleanly?**
Pydantic models for validation, exception handlers for consistent error responses, and HTTPException with proper status codes.

**26. How do you connect FastAPI to a database async?**
Async driver + SQLAlchemy async / asyncpg, connection pooling, session-per-request via dependency; avoid sync ORMs on the loop.

**27. How do you test FastAPI apps?**
`TestClient`/`httpx` + pytest, dependency overrides for mocking (DB/auth), async test support; contract tests for APIs.

**28. Middleware in FastAPI?**
ASGI middleware for cross-cutting concerns (logging, auth, CORS, tracing, timing) wrapping every request/response.

**29. How do you add observability to FastAPI?**
OpenTelemetry instrumentation (traces/metrics) → App Insights, structured logging with correlation IDs, health endpoints; for GenAI add token/cost metrics.

**30. How do you rate-limit / protect from abuse?**
Gateway (APIM) token/rate limits + app-level limiter (slowapi/redis), auth, and quotas — protect expensive AOAI calls.

---

## Architecture & Production (31–42)

**31. How do you structure a large FastAPI project?**
Layered/modular: routers, services (business logic), repositories (data), schemas (Pydantic), dependencies, config — separation of concerns for testability.

**32. How do you manage configuration and secrets?**
Pydantic Settings from env vars, secrets from Key Vault via Managed Identity — never hardcode; different values per environment.

**33. Packaging and dependency management?**
`pyproject.toml` + Poetry/uv/pip-tools, pinned/locked versions, virtual envs; reproducible builds; audit dependencies for CVEs.

**34. How do you containerize a Python service well?**
Multi-stage build, slim base, non-root user, pinned deps, `.dockerignore`, no secrets in layers, run Uvicorn workers; keep images small for fast scale.

**35. How do you scale a Python GenAI backend?**
Async for I/O concurrency + horizontal pod scaling (HPA), externalize state (Redis), offload heavy work to queues/workers, cache (semantic), and gateway rate limits.

**36. Threading vs asyncio for calling multiple LLM APIs?**
asyncio with `asyncio.gather` for concurrent async HTTP calls (I/O-bound) — efficient single-threaded concurrency; use an async HTTP client (httpx/aiohttp).

**37. How do you handle retries/resilience in Python?**
`tenacity` (retry + backoff + jitter), timeouts on all external calls, circuit breaker, and idempotency — essential for AOAI 429s.

**38. How do you avoid blocking the event loop with CPU work (e.g., embeddings math)?**
Offload to a process pool (`ProcessPoolExecutor`) or a dedicated service/worker; keep the loop for I/O.

**39. Memory leaks in long-running Python services?**
Unbounded caches, growing globals, lingering references, or large objects retained. Bound caches (LRU with maxsize), profile (tracemalloc), and monitor RSS.

**40. How do you do dependency-injected, testable design?**
FastAPI `Depends` + interfaces/protocols for services, dependency overrides in tests, and constructor injection — decouples logic from framework/IO.

**41. Celery / task queue — when and why?**
For reliable, long-running, or scheduled async work (batch embedding, notifications) decoupled from the request via a broker (Redis/Service Bus) with retries.

**42. How do you deploy Python services on Azure?**
Container (AKS/Container Apps) with Managed Identity, private endpoints, OTel, HPA/KEDA autoscale, Key Vault secrets, CI/CD building slim images.

---

## Data & GenAI Specifics (43–50)

**43. Which Python libs for a GenAI stack?**
openai/azure SDK, LangChain/LlamaIndex or Semantic Kernel, Pydantic, FastAPI, httpx, tenacity, numpy, a vector client (Azure AI Search) — plus OTel.

**44. NumPy — why fast?**
Vectorized operations in C over contiguous arrays (no Python-loop overhead); essential for embedding math and numerical work.

**45. Pandas at scale — pitfalls?**
Memory-heavy (loads all in RAM); for big data use chunking, dtypes optimization, or distributed engines (Spark/Dask/Polars).

**46. How do you process large files without OOM?**
Stream/iterate (generators), chunked reads, and process incrementally — don't load everything into memory.

**47. How do you validate LLM structured output in Python?**
Pydantic models + function calling / JSON mode, parse-and-validate, retry on invalid — enforce a schema on model output.

**48. How do you cache expensive GenAI calls?**
`functools.lru_cache` for pure functions; Redis + embedding-based semantic cache for near-duplicate queries; TTL to manage staleness.

**49. How do you handle concurrency limits to AOAI?**
`asyncio.Semaphore` to cap in-flight requests + retries/backoff + queueing — respect rate limits without overwhelming.

**50. Design a scalable Python GenAI API.**
FastAPI (async) behind APIM (auth, token limits) → async orchestrator calling AOAI/AI Search via httpx with semaphore + tenacity retries → semantic cache (Redis) → streaming responses → OTel + token metrics → containerized on Container Apps/AKS with HPA, Managed Identity, Key Vault. Offload heavy/batch work to a queue + workers.

---

## Practice Tips
- The #1 theme: **don't block the event loop** — know async vs threads vs processes cold (I-B-C).
- Tie every backend answer to **concurrency, resilience (tenacity), and observability**.
- Know the **GIL implications** and when to reach for multiprocessing.

---

> Next: Top 50 .NET Core.

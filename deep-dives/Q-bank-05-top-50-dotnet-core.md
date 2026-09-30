# Question Bank · Top 50 .NET Core & ASP.NET Core Architect Questions

> Architect-level answers. Say them aloud.

---

## Runtime & Language (1–14)

**1. What happens from C# source to running code?**
Compiles to **IL** (intermediate language) in an assembly; at runtime CoreCLR **JIT**-compiles hot IL to native (tiered compilation), and a **generational GC** manages memory. AOT/ReadyToRun precompile for fast startup.

**2. How does the .NET garbage collector work?**
Generational: gen0 (short-lived, cheap collects), gen1, gen2 (long-lived, expensive), plus the **Large Object Heap**. Objects promote across generations. **Server GC** maximizes throughput (multi-threaded, per-core heaps); Workstation GC for latency/desktop.

**3. Value types vs reference types?**
Value types (struct) live on the stack/inline (copied by value); reference types (class) on the heap (copied by reference). Structs avoid heap allocs for small data but cost on copies.

**4. What are `Span<T>` and `Memory<T>`?**
Allocation-free views over contiguous memory (arrays, stackalloc, strings) enabling high-perf, low-GC parsing/slicing without copies — key for hot paths.

**5. async/await — how does it work?**
`await` on an I/O operation frees the thread back to the pool until completion, giving high concurrency without blocking threads. The compiler builds a state machine. "Async all the way."

**6. What breaks async (deadlocks/starvation)?**
Blocking on async with `.Result`/`.Wait()` blocks a thread-pool thread waiting on work that needs the pool → deadlock/starvation under load. Fix: async all the way.

**7. Task vs Thread vs ValueTask?**
Task = async operation abstraction (thread-pool scheduled); Thread = OS thread (heavy); ValueTask avoids allocation when results often complete synchronously (hot paths).

**8. What is the TPL?**
Task Parallel Library — Tasks, `Parallel.For/ForEach`, PLINQ for CPU-bound parallelism across cores; complements async (which is for I/O).

**9. IEnumerable vs IQueryable?**
IEnumerable executes in-memory (LINQ-to-objects); IQueryable builds an expression tree translated to the data source (SQL via EF Core) — filtering runs in the DB. Wrong choice pulls all rows to memory.

**10. Deferred vs immediate LINQ execution?**
LINQ queries are lazy until enumerated (`ToList`/`foreach`); side effects/changes before enumeration affect results. Materialize deliberately.

**11. `IDisposable` and `using`?**
Deterministic cleanup of unmanaged/expensive resources (DB connections, streams); `using` calls `Dispose` even on exceptions. Implement for owned resources.

**12. `record` vs `class` vs `struct`?**
record = immutable-by-default reference type with value equality (great for DTOs); class = mutable reference; struct = value type. Pick by mutability/equality/allocation needs.

**13. What is tiered compilation / ReadyToRun / AOT?**
Tiered JIT compiles quickly then re-optimizes hot code; ReadyToRun precompiles to reduce JIT at startup; Native AOT produces a native binary (fast start, small, no JIT) with reflection limits.

**14. How do you reduce GC pressure in a hot path?**
Reuse buffers (ArrayPool), use `Span`/`stackalloc`, avoid unnecessary allocations/boxing, stream large data, and prefer structs/ValueTask where appropriate.

---

## ASP.NET Core (15–30)

**15. What is Kestrel?**
The cross-platform async web server hosting ASP.NET Core; handles connections on the thread pool with async I/O, typically behind a reverse proxy/ingress.

**16. Explain the middleware pipeline.**
An ordered chain of request delegates — exception handling → HTTPS → auth → routing → authorization → endpoint. Order matters; each can short-circuit. (E-A-A-E.)

**17. Dependency injection lifetimes?**
Singleton (whole app), Scoped (per request), Transient (per resolve). DbContext is scoped. (S-S-T.)

**18. What is a captive dependency?**
Injecting a shorter-lived service (Scoped) into a longer-lived one (Singleton) — it gets "captured," causing stale state or runtime errors. Match lifetimes.

**19. Minimal APIs vs Controllers?**
Minimal APIs = lean, fast, less ceremony (great for microservices/GenAI endpoints); Controllers = more structure/conventions for large apps. Both supported.

**20. When gRPC vs REST vs SignalR?**
gRPC for high-perf internal service-to-service (binary, streaming, contracts); REST for public/interoperable APIs; SignalR for real-time bidirectional (token streaming, notifications).

**21. What is the Generic Host?**
Bootstraps DI, configuration, logging, and app lifetime — the composition root for the app/services.

**22. How do you secure an ASP.NET Core API?**
Entra JWT bearer auth + policy authorization, HTTPS/HSTS, Managed Identity + Key Vault, input validation, parameterized EF, rate limiting, CORS, secure headers.

**23. How does configuration work?**
Layered providers (appsettings, env vars, Key Vault, command line) merged; bind to strongly typed Options; secrets from Key Vault (no secrets in appsettings).

**24. What is the Options pattern?**
Bind config sections to typed classes injected via `IOptions<T>` — strongly typed, validated, testable configuration.

**25. How do you handle exceptions globally?**
Exception-handling middleware (first in pipeline) / `UseExceptionHandler` producing consistent problem-details responses; log with correlation IDs.

**26. Health checks?**
`AddHealthChecks` + `/health` endpoints for liveness/readiness probes; check dependencies (DB, AOAI) — wired to Kubernetes probes.

**27. How do you stream LLM tokens from ASP.NET Core?**
`IAsyncEnumerable` streaming, SignalR, or server-sent events — push tokens to the client as generated for low perceived latency.

**28. HttpClient best practice?**
Use `IHttpClientFactory` (typed/named clients) — manages pooling/lifetime and avoids socket exhaustion from `new HttpClient()` per call.

**29. How do you add resilience?**
Polly (via `AddStandardResilienceHandler` or policies): retry + exponential backoff + circuit breaker + timeout + bulkhead on downstream calls (AOAI 429s).

**30. Rate limiting in ASP.NET Core?**
Built-in rate-limiting middleware (fixed/sliding window, token bucket, concurrency) to protect expensive endpoints; combine with gateway limits.

---

## EF Core & Data (31–40)

**31. What is EF Core?**
An async ORM: LINQ queries → SQL, change tracking, migrations, and mapping. Productive but needs care for performance.

**32. The N+1 query problem?**
Lazy/loop-loading related data issues one query per item. Fix with eager loading (`Include`), projections (`Select`), or explicit batching.

**33. `AsNoTracking` — when?**
For read-only queries — skips change tracking, reducing memory/CPU. Use for reporting/GET paths.

**34. How do EF Core migrations work?**
Model changes generate versioned migration files applied to the DB (`dotnet ef migrations add` / `database update`); apply via pipeline, not app startup in prod.

**35. How do you prevent SQL injection?**
Parameterized queries (EF does this by default); never concatenate user input into raw SQL. Use `FromSqlInterpolated` (parameterized) if raw SQL needed.

**36. DbContext lifetime?**
Scoped (per request) — it's not thread-safe and tracks a unit of work. Never share across requests/threads or make it a singleton.

**37. How do you optimize EF Core performance?**
Projections (`Select` only needed columns), `AsNoTracking`, `Include` wisely, batching/`AsSplitQuery`, compiled queries, proper indexes, and avoid loading whole entities.

**38. Transactions and unit of work?**
`SaveChanges` is a single transaction; use explicit transactions for multi-step operations; combine with the **outbox** pattern for reliable events in microservices.

**39. Connection pooling / DbContext pooling?**
`AddDbContextPool` reuses DbContext instances to cut allocation; ADO.NET pools connections — improves throughput under load.

**40. When would you not use EF Core?**
Ultra-high-perf/complex queries → Dapper or raw SQL; bulk operations → dedicated bulk libraries. EF for productivity, micro-ORM/raw for perf-critical paths.

---

## Architecture & Production (41–50)

**41. How do you structure a large ASP.NET Core solution?**
Clean/onion layering: API → Application (use cases) → Domain → Infrastructure; DI wires implementations; dependencies point inward (domain independent of frameworks).

**42. .NET vs Python for a GenAI backend?**
.NET for MS-centric, performance-sensitive backends with strong typing, gRPC/SignalR, and **native Semantic Kernel**; Python for ML/data-science-heavy work. Often mixed.

**43. What is Semantic Kernel in .NET?**
Microsoft's .NET-first orchestration SDK: kernel + plugins/functions + planners to build GenAI apps with native Azure OpenAI + DI integration.

**44. How do you call Azure OpenAI securely from .NET?**
Azure SDK client with `DefaultAzureCredential` (Managed Identity, no keys), RBAC role, private endpoint; add Polly resilience for 429s.

**45. How do you containerize .NET for fast startup?**
ReadyToRun/AOT + trimming for small images and quick cold start, non-root, multi-stage build, Server GC env var for throughput.

**46. How do you scale a .NET service?**
Async all the way for I/O concurrency + horizontal scaling (HPA/Container Apps), stateless design, Redis for shared state, output/response caching, Server GC.

**47. How do you observe a .NET service?**
Native OpenTelemetry → App Insights (traces/metrics/logs), GC and thread-pool metrics, `ILogger` structured logging with correlation IDs, health checks; alert on latency/exceptions/GC pauses.

**48. How do you handle background/long-running work?**
`IHostedService`/`BackgroundService` for in-process workers; a queue (Service Bus) + worker service for reliable, scalable async jobs.

**49. How do you implement graceful shutdown?**
Honor `IHostApplicationLifetime`/SIGTERM: stop accepting new work, drain in-flight requests, dispose resources — pairs with Kubernetes preStop/readiness.

**50. Design a high-performance .NET GenAI backend.**
ASP.NET Core Minimal APIs behind APIM (auth, token limits) → middleware (exception/HTTPS/Entra JWT/OTel/rate-limit) → DI (Semantic Kernel + AOAI via Managed Identity, EF Core scoped) → gRPC internal + SignalR streaming → Polly resilience → Redis cache → EF Core + geo-replicated SQL → health checks → HPA on AKS/Container Apps → Server GC + ReadyToRun → OpenTelemetry. Async all the way, correct DI lifetimes, GC tuning.

---

## Practice Tips
- Nail the fundamentals: **IL→JIT→native + generational GC**, **async all the way**, **DI lifetimes (S-S-T)**, **middleware order (E-A-A-E)**.
- Always mention **IHttpClientFactory**, **Polly**, and **Managed Identity** for production questions.
- Know **EF Core pitfalls** (N+1, tracking, DbContext scope) cold.

---

> Next: Top 50 Terraform.

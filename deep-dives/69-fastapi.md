# Deep Dive · FastAPI

> Phase 2 (Platform & apps) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
FastAPI is a modern, high-performance **Python web framework** for building APIs, built on **Starlette** (ASGI, async) and **Pydantic** (validation). You declare request/response models with **type hints**, and FastAPI gives you **automatic validation, serialization, dependency injection, and OpenAPI/Swagger docs** for free. It's **async-native**, making it ideal for **I/O-bound GenAI workloads** (calling Azure OpenAI, vector DBs) where you await many external calls concurrently. In GenAI architecture it's the go-to **orchestrator/API layer** (RAG endpoints, agent runtimes).

---

## 2. Architect-Level Explanation
FastAPI is the **API/orchestration layer** on the **ASGI** stack:
- **ASGI** (vs WSGI): async server interface → true concurrency for I/O-bound work; served by **Uvicorn/Gunicorn** workers (often behind Gunicorn managing Uvicorn workers).
- **Pydantic models**: typed schemas → automatic validation, coercion, serialization, and docs.
- **Dependency Injection**: `Depends()` provides testable, reusable components (auth, DB sessions, clients) with lifecycle management.
- **Concurrency model**: `async def` endpoints run on an event loop; blocking/CPU work must go to threadpools or separate workers to avoid stalling the loop.
- **Cross-cutting**: middleware, exception handlers, background tasks, lifespan events, streaming responses (great for token streaming).

Architecturally: **thin, async, well-typed API surface** in front of models/data, scaled horizontally behind an ingress/gateway, with observability and resilience baked in.

---

## 3. Why It Exists
- **Problem**: Flask/Django REST were productive but **sync-first** (WSGI) and required manual validation/serialization/docs.
- **Breakthrough**: combine **ASGI async** + **Pydantic type-driven validation** + **auto OpenAPI** → fast to write, fast at runtime, self-documenting.
- **Why GenAI loves it**: GenAI calls are **I/O-bound** (network to AOAI, Search, DBs); async lets one worker handle many concurrent requests efficiently; **streaming** suits token-by-token responses.
- **Enterprise driver**: Python is the ML/GenAI lingua franca; FastAPI gives production-grade APIs without leaving the Python ecosystem.

---

## 4. Internal Working
**Request lifecycle:**
1. **Uvicorn (ASGI)** receives the HTTP request on the event loop.
2. **Middleware** runs (CORS, auth, tracing).
3. **Routing** matches the path/method → endpoint function.
4. **Dependencies** (`Depends`) resolve (auth, DB session, AOAI client) — cached per-request.
5. **Pydantic** validates/parses the request body/query into typed models (422 on failure).
6. Endpoint executes: `async def` awaits I/O (AOAI/Search) without blocking the loop; sync/CPU work should offload to a threadpool/process.
7. Return value → Pydantic serializes to JSON (or a **StreamingResponse** for token streaming).
8. **Background tasks** run after response; **lifespan** manages startup/shutdown (client pools).

Key: **one event loop per worker**; **never block it**. Scale = more Uvicorn workers × more pods.

---

## 5. Enterprise Use Case
A GenAI **RAG orchestrator** exposes `/chat`: it validates the request (Pydantic), authenticates via Entra JWT (dependency), embeds the query and calls **Azure AI Search** and **Azure OpenAI** concurrently with `async`, applies guardrails, and **streams** the answer back token-by-token. It runs as multiple Uvicorn workers per pod on AKS, autoscaled by HPA, with OpenTelemetry tracing token/latency/cost and Managed Identity for passwordless AOAI access.

---

## 6. Real Production Architecture
```
 Front Door(WAF) ─► APIM (authN, rate/token quota) ─► AKS Ingress
        │
   ┌──────────── FastAPI (Uvicorn workers) ────────────┐
   │  Middleware: CORS · Entra JWT auth · OTel tracing  │
   │  Routes: /chat /health /ready                      │
   │  Depends(): auth, AOAI client, Search client, DB   │
   │  async I/O: AOAI + Search (concurrent) → guardrails│
   │  StreamingResponse (SSE) for tokens                │
   └────────────────────────────────────────────────────┘
        │ Managed Identity (no keys)
        ▼
   Azure OpenAI (PE) · Azure AI Search (PE) · Redis (state) · Postgres
        │
   OpenTelemetry ─► App Insights (tokens, latency, cost, traces)
```

---

## 7. Security Best Practices
- **Entra ID / OAuth2 JWT validation** as a dependency; enforce scopes/roles per route.
- **Pydantic validates all input** — reject malformed early (defense in depth), plus explicit size limits.
- **No secrets in code/env** — Managed Identity + Key Vault; clients use `DefaultAzureCredential`.
- **Rate limiting + quotas** (at APIM and/or app) — protect models from abuse/cost blowups.
- **CORS** locked to known origins; **HTTPS only** (TLS at ingress).
- **Prompt-injection/PII handling** for GenAI routes (guardrails, Content Safety, PII scrub).
- **Dependency scanning** (pip-audit), pinned requirements; avoid dynamic `eval`.

---

## 8. Scaling Strategy
- **Horizontal**: more **Uvicorn workers** per pod (CPU cores) × more **pods** (HPA/KEDA).
- **Async for I/O concurrency** — one worker serves many awaiting requests; **offload CPU/blocking** to threadpools (`run_in_threadpool`) or separate services.
- **Connection pooling / reuse clients** (create AOAI/HTTP/DB clients once via lifespan).
- **Streaming** to reduce perceived latency and memory for long responses.
- **Cache** (Redis) for embeddings/retrieval/idempotent results.

---

## 9. High Availability Strategy
- **Multiple pods across zones** behind ingress; **readiness/liveness** probes (`/ready`, `/health`).
- **Graceful shutdown** (drain in-flight, close pools via lifespan) to avoid dropped requests.
- **Retries with backoff + circuit breakers** on downstream calls (AOAI 429s).
- **Timeouts** on every external call; **bulkheads** to isolate slow dependencies.
- Multi-region behind Front Door for regional failover.

---

## 10. Disaster Recovery Strategy
- **Stateless app** → state in Redis/DB (replicated); redeploy via container image + IaC.
- **Multi-region deployment**; Front Door failover; AOAI multi-region with retry.
- **Config/secrets in Key Vault** (geo-available); reproducible image by digest.
- Define RTO/RPO; the app itself is trivially rebuildable — data stores drive RPO.

---

## 11. Cost Optimization Strategy
- **Async efficiency** → fewer pods for the same I/O-bound load (big saving vs sync).
- **Right-size workers/pods**; **scale-to-zero** off-peak (KEDA/Container Apps).
- **Cache** retrieval/embeddings; **stream + cap max_tokens** on GenAI calls.
- **Model routing** at the app layer (cheap vs premium) for GenAI cost control.
- Efficient serialization + gzip; avoid oversized payloads.

---

## 12. Common Production Challenges
- **Blocking the event loop** (sync DB/CPU work in `async def`) → latency collapse; offload properly.
- **Wrong worker count** (too many → memory; too few → underutilized).
- **Un-pooled clients** created per request → socket exhaustion; use lifespan singletons.
- **Missing timeouts** on AOAI/Search → cascading hangs.
- **429 storms** from AOAI → backoff + queue + capacity planning.
- **Large sync serialization** of big responses → stream instead.
- **DI misuse** (heavy work in dependencies) → slow requests.

---

## 13. Monitoring and Observability
- **OpenTelemetry** (FastAPI/ASGI instrumentation) → traces (per-route, downstream spans), metrics (RPS, latency, errors), logs → App Insights.
- **GenAI metrics**: tokens in/out, cost per request, time-to-first-token (streaming), model, retrieval hit rate.
- **Health endpoints** `/health` (liveness) + `/ready` (dependencies ready).
- **Alerts**: p95 latency, error rate, 429s, event-loop lag, saturation.

---

## 14. Troubleshooting Scenarios
- **Latency spikes under load** → event loop blocked by sync/CPU code; move to threadpool/worker.
- **Socket/connection errors** → clients not pooled; create once via lifespan.
- **Random 422s** → Pydantic schema mismatch; check model + client payload.
- **Hangs on AOAI** → missing timeout/retry; add both + circuit breaker.
- **High memory** → buffering large responses; switch to StreamingResponse.
- **Auth failures** → JWT audience/issuer/scope config; verify Entra settings.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| async vs sync | high I/O concurrency | must not block loop; harder mental model |
| FastAPI vs Django | fast, typed, async, light | fewer batteries (no ORM/admin) |
| Streaming | low TTFT, less memory | more complex clients |
| More workers | throughput | memory footprint |

---

## 16. When NOT to use it
- **CPU-bound heavy compute** (not I/O) → async doesn't help; use multiprocessing/dedicated services (or a different runtime).
- **Full-stack app needing ORM/admin/templating out of the box** → Django may fit better.
- **Tiny script/one endpoint** → Flask/Functions may be simpler.
- **Team with zero async experience under tight deadline** → risk of blocking-loop bugs.

---

## 17. Comparison with Alternatives
| Framework | Model | Strength | Best for |
|-----------|-------|----------|----------|
| **FastAPI** | ASGI async | speed, typing, auto-docs | GenAI/I/O-bound APIs |
| Flask | WSGI sync | simple, flexible | small/sync apps |
| Django REST | WSGI (async-ish) | batteries, ORM, admin | full-stack apps |
| .NET Minimal API | async | perf, enterprise | .NET shops |
| Node/Express | async | JS ecosystem | JS teams |

---

## 18. Interview Questions
1. Why is FastAPI fast, and what is ASGI vs WSGI?
2. How does async help GenAI workloads specifically?
3. What happens if you block the event loop? How do you avoid it?
4. How does Pydantic validation/serialization work?
5. Explain dependency injection in FastAPI.
6. How do you stream LLM tokens to clients?
7. How do you scale FastAPI in AKS?
8. How do you secure a FastAPI GenAI API?
9. How do you manage clients/connections efficiently?
10. When would you NOT choose FastAPI?

---

## 19. Strong Interview Answers
- **Why fast / ASGI**: "FastAPI runs on ASGI (async) via Uvicorn, so a single worker handles many concurrent I/O-bound requests on one event loop — unlike WSGI's one-request-per-worker sync model. Plus Pydantic does validation in optimized code. For GenAI, where we await AOAI and Search, that concurrency is exactly what we need."
- **Blocking the loop**: "If I put a sync DB call or CPU-heavy work in an `async def`, it blocks the event loop and tanks throughput for everyone. I offload blocking work with `run_in_threadpool` or a separate worker/process, and use async clients for I/O."
- **DI**: "`Depends()` injects reusable, testable components — auth, DB sessions, AOAI clients — resolved per request and easily overridden in tests. It centralizes cross-cutting logic and lifecycle."
- **Streaming**: "I return a StreamingResponse (SSE) and yield tokens as they arrive from AOAI. It cuts time-to-first-token, lowers memory, and improves UX — critical for chat."
- **Scaling in AKS**: "Multiple Uvicorn workers per pod (per CPU) × HPA/KEDA pods, pooled clients via lifespan, offloaded CPU work, caching, and streaming. Async means I need far fewer pods than a sync framework for the same I/O load."

---

## 20. Architecture Diagrams
**Concurrency model:**
```
Uvicorn worker (1 event loop)
  req1 ─► await AOAI ─┐  (loop free)
  req2 ─► await Search┤ → many concurrent I/O awaits on ONE loop
  req3 ─► await DB ───┘
  CPU/blocking work ─► threadpool/process (must NOT run on loop)
Scale = workers × pods (HPA)
```

---

## 21. Real Project Example
**Streaming RAG API on AKS.** `/chat` validates via Pydantic, authenticates with Entra JWT (dependency), and concurrently embeds + queries Azure AI Search while preparing the prompt; it calls AOAI with streaming and yields tokens over SSE. Clients (AOAI/Search/Redis) are created once in the lifespan handler and pooled. HPA scales pods on CPU + custom RPS; OpenTelemetry reports tokens/cost/TTFT to App Insights. Switching from a sync Flask prototype to async FastAPI cut pod count ~3× at equal load.

---

## 22. Whiteboard Design Question
> *"Design a scalable, secure FastAPI RAG service handling 5k concurrent chats with streaming."*

Cover: Front Door(WAF) → APIM (auth/quota) → AKS ingress → FastAPI (Uvicorn workers, async) → Entra JWT dependency → concurrent AOAI+Search calls → guardrails → SSE streaming → pooled clients (lifespan) → Redis cache/state → HPA/KEDA scaling → retries/timeouts/circuit breakers → OpenTelemetry → App Insights → multi-region/DR. Emphasize *don't block the loop*, pooling, streaming, and cost via async efficiency + caching.

---

## 23. Design Review Questions
- Are endpoints truly **async** and free of blocking calls?
- Are clients **pooled** via lifespan (not per-request)?
- **Timeouts + retries + circuit breakers** on every downstream?
- **Auth** (Entra JWT) enforced per route with scopes?
- **Streaming** for long GenAI responses?
- **Worker/pod sizing** and HPA metrics correct?
- **Observability**: tokens/cost/TTFT/latency traced?
- **Rate limiting/quota** to protect model cost?

---

## 24. Hands-on Example
```python
# Async RAG endpoint: concurrent I/O, DI, streaming, pooled clients via lifespan
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import asyncio

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.aoai = make_aoai_client()      # pooled, created once
    app.state.search = make_search_client()
    yield
    await app.state.aoai.close(); await app.state.search.close()

app = FastAPI(lifespan=lifespan)

class ChatRequest(BaseModel):               # Pydantic validation
    query: str
    top_k: int = 5

async def get_user(token: str = Depends(oauth2_scheme)):
    return verify_entra_jwt(token)          # auth dependency

@app.post("/chat")
async def chat(req: ChatRequest, user=Depends(get_user)):
    # concurrent I/O: embed+retrieve while nothing blocks the loop
    ctx = await app.state.search.retrieve(req.query, k=req.top_k)
    async def gen():
        async for tok in app.state.aoai.stream(req.query, ctx):  # token streaming
            yield tok
    return StreamingResponse(gen(), media_type="text/event-stream")

@app.get("/health")
async def health(): return {"status": "ok"}
```

---

## 25. Terraform Example
```hcl
# Run FastAPI on Container Apps with Managed Identity + autoscale (or use AKS)
resource "azurerm_container_app" "api" {
  name                         = "genai-fastapi"
  resource_group_name          = var.rg
  container_app_environment_id = var.cae_id
  revision_mode                = "Single"
  identity { type = "SystemAssigned" }
  template {
    min_replicas = 2
    max_replicas = 30
    container {
      name   = "api"
      image  = "${var.acr}/genai-fastapi:1.0.0"
      cpu    = 1.0
      memory = "2Gi"
      env { name = "AOAI_ENDPOINT" value = var.aoai_endpoint }
    }
    http_scale_rule { name = "http" concurrent_requests = 50 }  # scale on concurrency
  }
  ingress { external_enabled = true target_port = 8000
            traffic_weight { percentage = 100 latest_revision = true } }
}
```

---

## 26. Azure Example
```bash
# Deploy FastAPI and grant its Managed Identity access to Azure OpenAI (no keys)
az containerapp create -n genai-fastapi -g rg \
  --environment cae --image myacr.azurecr.io/genai-fastapi:1.0.0 \
  --system-assigned --min-replicas 2 --max-replicas 30 \
  --target-port 8000 --ingress external --env-vars AOAI_ENDPOINT=$AOAI
MI=$(az containerapp show -n genai-fastapi -g rg --query identity.principalId -o tsv)
az role assignment create --assignee $MI --role "Cognitive Services OpenAI User" \
  --scope $(az cognitiveservices account show -n my-aoai -g rg --query id -o tsv)
```

---

## 27. Code Example
```python
# Resilient downstream call: timeout + retry/backoff, offload blocking work
from fastapi.concurrency import run_in_threadpool
import httpx, backoff

@backoff.on_exception(backoff.expo, httpx.HTTPStatusError, max_tries=4)  # handle 429s
async def call_aoai(client, payload):
    r = await client.post("/chat/completions", json=payload, timeout=30)  # always timeout
    r.raise_for_status()
    return r.json()

@app.post("/summarize")
async def summarize(doc: str):
    tokens = await run_in_threadpool(cpu_bound_tokenize, doc)  # don't block the loop
    return await call_aoai(app.state.aoai, build_payload(tokens))
```

---

## 28. Things Architects Must Remember
- **FastAPI = async + Pydantic + auto-docs on ASGI** — built for I/O-bound GenAI.
- **Never block the event loop** — offload sync/CPU work; use async clients.
- **Pool clients via lifespan** — not per request (avoids socket exhaustion).
- **Stream tokens** for chat — better TTFT, memory, UX.
- **Every downstream call needs timeout + retry/backoff + circuit breaker** (AOAI 429s).
- **Scale = workers × pods** (HPA/KEDA); async means fewer pods than sync.
- **Security**: Entra JWT dependency, Managed Identity, input validation, rate limits.
- **Not for CPU-bound** heavy compute — that needs multiprocessing/other runtimes.

---

## 29. Mnemonics and Memory Tricks
- **"Async loves waiting, not working"** — great for I/O, bad for CPU.
- **"Don't block the loop"** — the #1 FastAPI rule.
- **"Type it, and it validates + documents itself"** (Pydantic + OpenAPI).
- **Resilience "T-R-C"**: **T**imeout, **R**etry/backoff, **C**ircuit breaker.
- **Scale "W×P"**: **W**orkers × **P**ods.

---

## 30. One-Page Interview Revision Sheet
- **What**: async Python API framework on Starlette(ASGI)+Pydantic; auto validation/serialization/OpenAPI.
- **Why fast**: ASGI async → many concurrent I/O awaits per worker; Pydantic optimized validation.
- **GenAI fit**: I/O-bound (AOAI/Search) + token **streaming** (SSE) → low TTFT.
- **Key rule**: never block the event loop; offload CPU/sync work; pool clients via lifespan.
- **DI**: `Depends()` for auth/clients/db — testable, reusable.
- **Security**: Entra JWT dependency, Managed Identity + Key Vault, input validation, rate limits, CORS/HTTPS.
- **Scale**: workers × pods (HPA/KEDA); cache; stream; scale-to-zero off-peak.
- **Resilience**: timeouts + retry/backoff + circuit breakers on all downstreams (429s).
- **When NOT**: CPU-bound compute, full-stack ORM/admin needs, trivial single scripts.
- **Remember**: *don't block the loop*; *async loves waiting*; *T-R-C* resilience; *W×P* scaling; pool clients.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Explain ASGI vs WSGI and why it matters for a GenAI RAG service.
2. Precisely, what happens if you run a synchronous DB query inside an `async def` under load?
3. How do you stream LLM tokens to a browser, and why is it worth the complexity?
4. Show how you'd inject and reuse an Azure OpenAI client without creating one per request.
5. Design timeout/retry/circuit-breaker handling for AOAI 429 storms.
6. How do you decide worker count per pod and pod count in AKS?
7. Secure a FastAPI GenAI endpoint end-to-end — auth, secrets, input, cost.
8. Your p95 latency collapsed at 500 RPS though CPU is low. Diagnose it.
9. When is FastAPI the wrong choice, and what would you pick instead?
10. How does async let you run the same load on far fewer pods than Flask — quantify the intuition.

---

> Next Phase 2 topic: **Python Architecture (internals, async, concurrency)**.

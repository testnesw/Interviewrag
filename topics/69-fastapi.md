# 69 · FastAPI

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
FastAPI is a modern Python web framework for building **APIs quickly**. You write simple functions with type hints, and it automatically validates requests, serializes responses, and generates interactive API docs.

## 2. Architect-Level Explanation
FastAPI is a high-performance ASGI framework built on Starlette (web) + Pydantic (validation):
- **ASGI**: async-native — runs under Uvicorn/Hypercorn/Gunicorn workers; handles high concurrency for I/O-bound workloads.
- **Type-driven**: Python type hints drive request parsing, validation, serialization, and **auto OpenAPI/Swagger** docs.
- **Dependency Injection**: first-class `Depends()` for auth, DB sessions, config — testable and composable.
- **Standards**: OpenAPI + JSON Schema + OAuth2/JWT support built in.
- **Performance**: among the fastest Python frameworks (comparable to Node/Go for I/O-bound) due to async + Pydantic v2 (Rust core).
- **Ecosystem**: background tasks, WebSockets, middleware, lifespan events, routers for modular apps.
- Ideal for microservices, ML/GenAI inference APIs, and I/O-bound backends.

## 3. Real Enterprise Use Case
A company builds all microservices and GenAI inference endpoints in FastAPI: async calls to Azure OpenAI, Pydantic-validated request/response contracts, JWT auth via Entra ID, auto-generated OpenAPI for the developer portal, and containerized deployment to AKS with HPA scaling on concurrency.

## 4. Architecture Diagram (ASCII)
```
   Client ─► Uvicorn/Gunicorn (ASGI workers)
                │
        FastAPI app (routers)
          ├─ Pydantic models (validate in/out)
          ├─ Depends() (auth, DB session, config)
          ├─ async handlers ─► await DB / Azure OpenAI / HTTP
          └─ auto OpenAPI /docs (Swagger) + /redoc
   Middleware (CORS, auth, tracing) wraps requests
```

## 5. Interview Questions
1. Why FastAPI over Flask/Django?
2. What makes FastAPI fast?
3. How does automatic validation/docs work?
4. What is ASGI and why does it matter?
5. How do you structure a large FastAPI app?

## 6. Strong Interview Answers
- **vs Flask/Django**: "FastAPI is async-native (ASGI) with built-in validation, serialization, and auto OpenAPI docs from type hints — less boilerplate than Flask and lighter/faster than Django for APIs. Django still wins for full-stack + admin; Flask is simpler but sync-first."
- **Fast**: "It's built on Starlette's async core and Pydantic v2 (Rust-backed) — async handles many concurrent I/O-bound requests without threads, and validation/serialization are highly optimized."
- **Validation/docs**: "Type hints + Pydantic models define the schema; FastAPI validates incoming requests, serializes responses, and generates OpenAPI/JSON Schema automatically, giving Swagger UI and ReDoc for free."
- **ASGI**: "Asynchronous Server Gateway Interface — the async successor to WSGI. It lets a single worker handle many concurrent connections via an event loop, ideal for I/O-bound APIs (DB, HTTP, LLM calls)."
- **Structure**: "APIRouters per domain, a dependencies module, Pydantic schemas separate from ORM models, settings via Pydantic Settings, and lifespan events for startup/shutdown — modular and testable."

## 7. Common Mistakes
- Blocking (sync) calls inside async handlers (blocks the event loop).
- Mixing ORM models and API schemas.
- No dependency injection → hard-to-test code.
- Ignoring lifespan/startup for resource setup.
- Running a single worker in production.

## 8. Trade-offs
| Framework | Pro | Con |
|-----------|-----|-----|
| FastAPI | async, validation, docs | younger ecosystem |
| Flask | simple, mature | manual validation, sync-first |
| Django | batteries-included | heavier for pure APIs |

## 9. Production Best Practices
- Gunicorn + Uvicorn workers (multi-process); async all the way.
- Pydantic schemas separate from ORM; strict validation.
- DI for auth/DB/config; lifespan for pools/clients.
- Middleware for CORS, auth, tracing; structured logging.
- Health/readiness endpoints; OpenAPI published.

## 10. Security Considerations
- OAuth2/JWT (Entra ID); validate scopes/roles.
- Input validation via Pydantic (prevent injection/oversized payloads).
- CORS restricted; rate limiting; secrets via Key Vault.
- Don't leak stack traces; secure headers.

## 11. Cost Optimization
- Async concurrency → fewer pods for I/O-bound load.
- Right worker count (CPU cores); avoid over-provisioning.
- Efficient serialization (Pydantic v2) reduces CPU.

## 12. Troubleshooting Scenarios
- **High latency under load** → blocking call in async path; offload/await properly.
- **422 errors** → request fails Pydantic validation; check schema.
- **Slow startup / connection storms** → move client/pool init to lifespan.
- **Docs missing** → response_model/type hints absent.
- **CORS errors** → middleware misconfigured.

## 13. Hands-on Example
```bash
pip install "fastapi[standard]" uvicorn
uvicorn main:app --reload
# Interactive docs at http://127.0.0.1:8000/docs
```

## 14. Terraform Example
```hcl
# Deploy the FastAPI container to Azure Container Apps
resource "azurerm_container_app" "api" {
  name = "fastapi" container_app_environment_id = var.env_id
  resource_group_name = var.rg revision_mode = "Single"
  template {
    container { name = "api" image = "myacr.azurecr.io/api:1.0"
      cpu = 0.5 memory = "1Gi" }
    min_replicas = 2 max_replicas = 20
  }
  ingress { external_enabled = true target_port = 8080 }
}
```

## 15. Azure Example
```bash
az acr build -r myacr -t fastapi:1.0 .
az containerapp create -g rg -n fastapi --image myacr.azurecr.io/fastapi:1.0 \
  --target-port 8080 --ingress external --min-replicas 2
```

## 16. FastAPI / Python Example
```python
from fastapi import FastAPI, Depends
from pydantic import BaseModel

app = FastAPI(title="Orders API")

class Order(BaseModel):
    id: int
    total: float

@app.get("/orders/{oid}", response_model=Order)
async def get_order(oid: int):
    return await fetch_order(oid)   # async I/O; auto-validated + documented
```

## 17. AKS Example
```yaml
spec:
  containers:
    - name: api
      image: myacr.azurecr.io/fastapi:1.0
      ports: [{ containerPort: 8080 }]
      readinessProbe: { httpGet: { path: /health, port: 8080 } }
# HPA scales on CPU/concurrency; async lets each pod handle many requests
```

## 18. How to Remember
**"Type hints → validation + docs; async → speed; Depends → testable."** ASGI (Uvicorn) under the hood.

## 19. Real-World Analogy
A smart reception desk: you hand it a form (request), it instantly checks the form is filled correctly (Pydantic validation), routes you to the right department (routing), and even prints a clear instruction sheet for future visitors (auto docs) — all while handling many visitors at once (async).

## 20. One-Page Cheat Sheet
- **What**: modern async (ASGI) Python API framework on Starlette + Pydantic.
- **Type-driven**: validation, serialization, auto OpenAPI/Swagger from hints.
- **DI**: `Depends()` for auth/DB/config — testable.
- **Fast**: async + Pydantic v2 (Rust); great for I/O-bound + GenAI APIs.
- **Prod**: Gunicorn+Uvicorn workers, lifespan for pools, middleware, health checks.
- **Avoid**: blocking calls in async handlers; mixing ORM and API schemas.

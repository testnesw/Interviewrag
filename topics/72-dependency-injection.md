# 72 · Dependency Injection (FastAPI)

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Dependency Injection (DI) means giving a function the things it needs (like a database connection or the current user) from the outside, instead of creating them inside. FastAPI does this cleanly with `Depends()`.

## 2. Architect-Level Explanation
DI is a pattern for providing dependencies externally to improve testability and reuse. In FastAPI:
- **`Depends()`**: declares a dependency; FastAPI resolves and injects it into the handler, and it appears in OpenAPI.
- **Uses**: DB sessions, auth/current-user, config/settings, pagination params, feature flags, shared clients.
- **Sub-dependencies**: dependencies can depend on others → a resolved graph, deduplicated per request (cached).
- **Lifecycle**: `yield` dependencies provide setup/teardown (e.g., open/close a DB session) — like context managers.
- **Scopes**: per-request by default; app-level resources (pools, clients) created in **lifespan** and referenced.
- **Overrides**: `app.dependency_overrides` swap real deps for fakes in tests — the key testability win.
- **Security**: auth as a dependency composes cleanly (`Depends(require_role("admin"))`).

## 3. Real Enterprise Use Case
A service injects a per-request async DB session (yield dependency), the authenticated Entra ID user (validating JWT), and typed settings via DI. Tests override the DB and auth dependencies with in-memory fakes, enabling fast, isolated unit tests of endpoints without a real database or token.

## 4. Architecture Diagram (ASCII)
```
   Request ─► handler(order, db=Depends(get_db), user=Depends(current_user))
                        │ FastAPI resolves dependency graph
   get_db (yield): open session ─► inject ─► close after response
   current_user ─► validate JWT ─► User   (sub-dep: get_settings)
   Cached per request (same dep resolved once)
   Tests: app.dependency_overrides[get_db] = fake_db
```

## 5. Interview Questions
1. What is DI and why use it?
2. How does `Depends()` work in FastAPI?
3. What are `yield` dependencies for?
4. How do you inject app-level resources (pools)?
5. How does DI help testing?

## 6. Strong Interview Answers
- **Why DI**: "It decouples a function from how its dependencies are built, improving testability, reuse, and separation of concerns. You inject a DB session or current user rather than constructing them inline."
- **Depends()**: "You declare `param = Depends(provider)`; FastAPI calls the provider, injects the result, caches it per request, and documents it in OpenAPI. Providers can be functions or callables."
- **yield deps**: "For setup/teardown — code before `yield` runs on entry (open a session), code after runs on exit (close it), even on exceptions. It's DI + resource lifecycle, like a context manager per request."
- **App-level resources**: "Create pools/clients once in the **lifespan** handler (startup), store on `app.state`, and reference them from dependencies — you don't recreate a connection pool per request."
- **Testing**: "`app.dependency_overrides[real_dep] = fake` swaps real dependencies (DB, auth) for fakes, so I test endpoints in isolation without external systems — fast, deterministic tests."

## 7. Common Mistakes
- Creating DB sessions/clients globally instead of via DI.
- Not closing resources (missing `yield` teardown).
- Recreating pools per request instead of lifespan.
- Business logic in dependencies (keep them thin).
- Not using overrides for tests (slow, brittle).

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| DI (`Depends`) | testable, reusable | learning curve |
| Global objects | simple | hard to test, hidden coupling |
| yield deps | clean lifecycle | ordering nuances |

## 9. Production Best Practices
- DB session as a `yield` dependency (per-request open/close).
- Pools/clients in lifespan; reference via dependencies.
- Compose auth as dependencies (`require_role`).
- Keep dependencies thin (wiring, not business logic).
- Use overrides in tests.

## 10. Security Considerations
- Auth/authorization as reusable dependencies (consistent enforcement).
- Validate tokens/scopes in one place.
- Don't leak sensitive config through injected settings.

## 11. Cost Optimization
- Shared pooled clients (lifespan) reduce connection overhead.
- Per-request dedup avoids redundant work.
- Faster tests → cheaper CI.

## 12. Troubleshooting Scenarios
- **Leaked connections** → missing teardown in yield dep.
- **New pool each request** → should be in lifespan, not a dep.
- **Auth inconsistent** → not centralized as a dependency.
- **Tests hitting real DB** → missing dependency_overrides.
- **Dep runs twice** → not the same callable (cache miss).

## 13. Hands-on Example
```python
# Override a dependency in a test
from fastapi.testclient import TestClient
def fake_user(): return {"id": 1, "role": "admin"}
app.dependency_overrides[current_user] = fake_user
client = TestClient(app)
assert client.get("/admin/report").status_code == 200
```

## 14. Terraform Example
```hcl
# Inject config via env (consumed by a Settings dependency in the app)
resource "kubernetes_config_map" "app" {
  metadata { name = "app-config" namespace = "app" }
  data = { DB_URL = var.db_url, FEATURE_X = "true" }
}
```

## 15. Azure Example
A `get_settings` dependency reads config from environment (ConfigMap) and secrets from Key Vault (via Workload Identity), caching per process — endpoints just declare `settings = Depends(get_settings)`.

## 16. FastAPI / Python Example
```python
from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncSession:            # yield dependency
    async with SessionLocal() as session:
        yield session                          # teardown closes it

def require_role(role: str):
    async def checker(user=Depends(current_user)):
        if user["role"] != role:
            raise HTTPException(403, "forbidden")
        return user
    return checker

@app.get("/admin/report")
async def report(db: AsyncSession = Depends(get_db),
                 user=Depends(require_role("admin"))):
    return await build_report(db)
```

## 17. AKS Example
The DB session dependency uses a pool created in lifespan sized to the pod's connection budget; when HPA scales pods, total DB connections stay bounded (pool size × pods) — DI centralizes this so it's tunable in one place.

## 18. How to Remember
**"Declare what you need with `Depends`; FastAPI builds it, injects it, and you swap it in tests."** yield = setup/teardown.

## 19. Real-World Analogy
A hospital where equipment and staff are provided to a surgeon per operation (injected) rather than the surgeon sourcing their own — and for a drill (training), you can swap in a dummy patient (override) instead of a real one, testing the procedure safely.

## 20. One-Page Cheat Sheet
- **DI**: provide dependencies externally → testable, reusable, decoupled.
- **`Depends()`**: resolves + injects + caches per request + documents in OpenAPI.
- **yield deps**: per-request setup/teardown (DB session open/close).
- **App resources**: pools/clients in **lifespan**, referenced by deps (don't recreate).
- **Auth**: compose as dependencies (`require_role`).
- **Testing**: `app.dependency_overrides` swap real deps for fakes.

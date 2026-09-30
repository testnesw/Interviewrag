# 78 · Integration Testing

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Integration testing checks that **different parts of your system work together** — for example, your API talking to a real database or message queue — rather than testing each piece alone. It catches problems in the "wiring" between components.

## 2. Architect-Level Explanation
Integration tests verify real collaborations across boundaries:
- **Scope**: multiple units + real (or realistic) external dependencies — DB, message broker, cache, HTTP APIs.
- **Realistic deps**: **testcontainers** (spin up real Postgres/Redis/Kafka in Docker), ephemeral cloud resources, or local emulators (Azurite for Storage, Cosmos emulator).
- **What they catch**: SQL/migration issues, serialization mismatches, transaction behavior, config/wiring, auth flows — things mocks hide.
- **FastAPI**: exercise the ASGI app end-to-end via `TestClient`/httpx `AsyncClient` against a real test DB with migrations applied.
- **External APIs**: use **contract testing** (Pact) or recorded responses (VCR) / a mock server to avoid flakiness and third-party coupling.
- **Data management**: isolate per test (transactions rolled back, or fresh schema/container) for determinism.
- **Slower** than unit → fewer of them (middle of the pyramid); run in CI with real services.
- **Test environments**: ephemeral, disposable, production-like.

## 3. Real Enterprise Use Case
A team runs integration tests with testcontainers Postgres: Alembic migrations apply to a fresh container, the FastAPI app is exercised via httpx against real endpoints, each test runs in a rolled-back transaction, and external payment/OpenAI calls use a mock server with contract tests — catching N+1, migration, and serialization bugs before deploy.

## 4. Architecture Diagram (ASCII)
```
   Integration test
     ┌───────────────────────────────────┐
     │ FastAPI app (real routers + DI)    │
     │   ▲ httpx AsyncClient / TestClient │
     └───┬───────────────┬────────────────┘
   real Postgres     real Redis      external API
   (testcontainers)  (container)     ─► mock server / Pact contract
   Migrations applied · per-test transaction rollback · disposable env
```

## 5. Interview Questions
1. Unit vs integration testing — key differences?
2. How do you get realistic dependencies in tests?
3. How do you handle external third-party APIs?
4. How do you keep integration tests deterministic?
5. Where do integration tests fit in the pyramid/CI?

## 6. Strong Interview Answers
- **Unit vs integration**: "Unit tests isolate one component with doubles; integration tests exercise multiple components together with real dependencies (DB, queue) to verify the wiring, queries, and serialization that mocks would hide."
- **Realistic deps**: "I use **testcontainers** to spin up real Postgres/Redis/Kafka in Docker per test session, or cloud emulators (Azurite, Cosmos emulator). This gives real behavior — actual SQL, transactions, indexes — instead of mocked approximations."
- **External APIs**: "I don't hit real third parties in CI — flaky and rate-limited. I use **contract testing (Pact)** to verify both sides agree, or a mock server / recorded responses (VCR). Contract tests catch breaking changes without live calls."
- **Deterministic**: "Fresh schema/container, per-test transaction rollback or truncation, seeded data, frozen time/seeded randomness, and no shared mutable state — so tests are repeatable and parallelizable."
- **Pyramid/CI**: "Fewer than unit tests (they're slower), more than E2E. In CI they run after unit tests, spinning up real services via containers, in a disposable production-like environment."

## 7. Common Mistakes
- Calling real third-party APIs (flaky, rate-limited, costly).
- Shared/persistent test DB state → order-dependent flaky tests.
- Not applying migrations → tests diverge from prod schema.
- Treating everything as integration (slow pyramid inversion).
- No cleanup → data bleed between tests.

## 8. Trade-offs
| Approach | Pro | Con |
|----------|-----|-----|
| testcontainers | real behavior | needs Docker, slower |
| emulators | fast-ish, local | not 100% parity |
| contract tests | no live calls | setup effort |

## 9. Production Best Practices
- Real deps via testcontainers/emulators; apply migrations.
- Isolate data per test (transaction rollback / fresh schema).
- Contract testing (Pact) or mock servers for external APIs.
- Exercise the real ASGI app (httpx/TestClient), not internals.
- Disposable, production-like ephemeral environments in CI.

## 10. Security Considerations
- Test auth/authz flows end-to-end (JWT validation, RBAC).
- No prod data/secrets; synthetic test data only.
- Verify private-network/connection-string handling in a safe env.

## 11. Cost Optimization
- Ephemeral containers/resources destroyed after run (no idle cost).
- Keep integration set focused (not a bloated pyramid).
- Parallelize with isolated data; cache container images.

## 12. Troubleshooting Scenarios
- **Flaky/order-dependent** → shared DB state; isolate per test.
- **Passes locally, fails CI** → missing service/emulator or migration.
- **Slow suite** → too many integration tests; push logic to unit.
- **Third-party breakage** → add contract tests; use mock server.
- **Schema drift** → migrations not applied to test DB.

## 13. Hands-on Example
```bash
pip install testcontainers httpx pytest-asyncio
pytest tests/integration -q          # spins up real Postgres/Redis in Docker
```

## 14. Terraform Example
```hcl
# Ephemeral integration-test resources, destroyed after the CI run
resource "azurerm_servicebus_namespace" "test" {
  name = "sb-itest-${var.run_id}" location = "eastus"
  resource_group_name = var.rg sku = "Standard"
}
# pipeline: terraform apply → pytest tests/integration → terraform destroy
```

## 15. Azure Example
Use the **Azurite** (Storage) and **Cosmos DB** emulators as container services in the CI job so integration tests exercise real SDK code paths against emulated Azure services — no real cloud resources, fast and free.

## 16. FastAPI / Python Example
```python
import pytest, httpx
from testcontainers.postgres import PostgresContainer
from app.main import app
from app.db import init_engine, run_migrations

@pytest.fixture(scope="session")
async def client():
    with PostgresContainer("postgres:16") as pg:
        init_engine(pg.get_connection_url())
        run_migrations()                      # real schema
        async with httpx.AsyncClient(app=app, base_url="http://test") as c:
            yield c

@pytest.mark.asyncio
async def test_create_and_get_order(client):
    created = (await client.post("/v1/orders",
               json={"total": 42.0, "currency": "USD"},
               headers={"Idempotency-Key": "k1"})).json()
    got = await client.get(f"/v1/orders/{created['id']}")
    assert got.status_code == 200            # real DB round-trip verified
```

## 17. AKS Example
A CI pipeline deploys the service + real dependencies to an ephemeral namespace on a test AKS cluster (or via testcontainers on the runner), runs integration tests against the live endpoints, then tears the namespace down — validating real Kubernetes wiring (config, secrets, networking) before promoting to prod.

## 18. How to Remember
**"Real deps, real wiring — testcontainers for DBs, contracts for external APIs, isolate the data."** Middle of the pyramid.

## 19. Real-World Analogy
After bench-testing each car part (unit tests), you assemble the engine, transmission, and wheels and run them together on a test rig (integration) to confirm they actually connect and work as a system — before the full road trip (E2E).

## 20. One-Page Cheat Sheet
- **Integration**: multiple components + real deps (DB/queue/cache) working together — catches wiring/SQL/serialization bugs mocks hide.
- **Real deps**: testcontainers (Postgres/Redis/Kafka) or emulators (Azurite, Cosmos); apply migrations.
- **External APIs**: contract testing (Pact) / mock server / VCR — no live third-party calls.
- **Deterministic**: fresh schema or transaction rollback, seeded data, no shared state.
- **App**: exercise real ASGI app via httpx/TestClient.
- **CI**: after unit tests; ephemeral, production-like, disposable; fewer than unit, more than E2E.

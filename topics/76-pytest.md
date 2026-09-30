# 76 · Pytest

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Pytest is the most popular Python testing framework. You write test functions that check your code behaves correctly, and pytest runs them and reports what passed or failed — with minimal boilerplate.

## 2. Architect-Level Explanation
Pytest is a powerful, plugin-rich testing framework:
- **Plain functions + `assert`**: no boilerplate; rich assertion introspection shows why a test failed.
- **Fixtures**: reusable setup/teardown via `@pytest.fixture`, with **scopes** (function/class/module/session) and dependency injection into tests; `yield` for teardown.
- **Parametrization**: `@pytest.mark.parametrize` runs a test across many inputs.
- **Markers**: tag/select tests (`@pytest.mark.slow`, `-m`), `skip`/`xfail`.
- **Plugins**: `pytest-asyncio` (async tests), `pytest-cov` (coverage), `pytest-mock`, `pytest-xdist` (parallel), `httpx`/`TestClient` for FastAPI.
- **conftest.py**: shared fixtures/config across a test tree.
- **Isolation**: fixtures + FastAPI dependency overrides create fast, deterministic tests without external systems.
- Integrates with CI (JUnit XML, coverage gates).

## 3. Real Enterprise Use Case
A team tests a FastAPI service with pytest: fixtures spin up an in-memory/SQLite or testcontainers DB, dependency overrides inject fakes for auth and external clients, parametrized tests cover validation edge cases, `pytest-asyncio` tests async endpoints, and CI enforces a coverage threshold with parallel runs via xdist.

## 4. Architecture Diagram (ASCII)
```
   conftest.py (shared fixtures: db, client, auth)
        │ injected by name
   test_orders.py
     @pytest.fixture(scope="session") db
     @pytest.mark.parametrize(inputs) test_validation
     @pytest.mark.asyncio            test_async_endpoint
        │ app.dependency_overrides → fakes (no real DB/API)
   pytest -m "not slow" -n auto --cov  ─► CI (JUnit + coverage gate)
```

## 5. Interview Questions
1. Why pytest over unittest?
2. What are fixtures and fixture scopes?
3. How do you parametrize tests?
4. How do you test async FastAPI endpoints?
5. How do you isolate tests from external systems?

## 6. Strong Interview Answers
- **vs unittest**: "Pytest uses plain functions and `assert` with detailed introspection, has powerful fixtures and parametrization, and a huge plugin ecosystem — far less boilerplate than unittest's class-based style, while still able to run unittest tests."
- **Fixtures/scopes**: "Fixtures provide reusable setup/teardown and are injected by name into tests. Scopes control lifetime — function (default), class, module, or session — so expensive resources (a DB container) are created once per session, cheap ones per test. `yield` handles teardown."
- **Parametrize**: "`@pytest.mark.parametrize` runs the same test across many input/expected pairs — great for validation and edge cases, keeping tests DRY and clearly reporting which case failed."
- **Async**: "`pytest-asyncio` with `@pytest.mark.asyncio` lets me `await` in tests; for FastAPI I use the `TestClient` (sync) or httpx `AsyncClient` against the ASGI app to exercise endpoints."
- **Isolation**: "Fixtures + FastAPI `dependency_overrides` swap real DB/auth/external clients for fakes or test doubles, so unit tests are fast and deterministic. Integration tests use testcontainers for real dependencies when needed."

## 7. Common Mistakes
- Overusing session-scoped mutable fixtures → test coupling.
- Real external calls in unit tests (slow, flaky).
- No teardown → leaked resources/state bleed.
- Not parametrizing → duplicated tests.
- Forgetting `pytest-asyncio` for async tests.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Fakes/overrides | fast, isolated | less realistic |
| testcontainers | realistic | slower |
| session fixtures | fast reuse | shared-state risk |

## 9. Production Best Practices
- Fixtures in conftest.py; appropriate scopes; `yield` teardown.
- Parametrize edge cases; markers to segment (unit/integration/slow).
- Dependency overrides for external systems in unit tests.
- Coverage gate + parallel runs (`-n auto`) in CI; JUnit output.
- Deterministic tests (seed randomness, freeze time).

## 10. Security Considerations
- No real secrets in tests; use fakes/env.
- Test authz/validation paths (negative tests).
- Isolate test data; never point tests at prod.

## 11. Cost Optimization
- Fast isolated tests → cheaper, quicker CI.
- Parallelization (xdist) cuts pipeline time.
- Session-scoped expensive resources reduce setup cost.

## 12. Troubleshooting Scenarios
- **Flaky tests** → shared state / real network / time dependence.
- **Async test not running** → missing asyncio marker/plugin.
- **Slow suite** → real deps; use fakes + parallelize.
- **Fixture errors** → wrong scope / teardown order.
- **State bleed** → mutable session fixture; scope down.

## 13. Hands-on Example
```bash
pip install pytest pytest-asyncio pytest-cov pytest-xdist
pytest -m "not slow" -n auto --cov=app --cov-fail-under=85
```

## 14. Terraform Example
```hcl
# CI runs pytest; infra for a throwaway test DB (or use testcontainers)
resource "azurerm_postgresql_flexible_server" "test" {
  name = "pg-test" resource_group_name = var.rg location = "eastus"
  version = "16" sku_name = "B_Standard_B1ms" storage_mb = 32768
}
```

## 15. Azure Example
In Azure DevOps/GitHub Actions, run `pytest --junitxml=results.xml --cov` and publish test + coverage results; gate the pipeline on coverage and green tests before building/pushing the image to ACR.

## 16. FastAPI / Python Example
```python
import pytest
from fastapi.testclient import TestClient
from app.main import app, current_user

@pytest.fixture
def client():
    app.dependency_overrides[current_user] = lambda: {"id": 1, "role": "admin"}
    yield TestClient(app)
    app.dependency_overrides.clear()

@pytest.mark.parametrize("total,expected", [(10, 201), (-5, 422)])
def test_create_order(client, total, expected):
    r = client.post("/orders", json={"total": total, "currency": "USD"})
    assert r.status_code == expected
```

## 17. AKS Example
```python
# Integration test against a real Postgres via testcontainers (CI on AKS runners)
import pytest
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def pg():
    with PostgresContainer("postgres:16") as p:
        yield p.get_connection_url()
```

## 18. How to Remember
**"Functions + assert + fixtures + parametrize + plugins."** Overrides isolate; asyncio plugin for async; coverage gate in CI.

## 19. Real-World Analogy
A factory QA line: fixtures set up the test bench (and clean it after), parametrization runs the same check on many product variants, and stand-in dummy parts (overrides/fakes) let you test one component without the whole assembly — catching defects before shipping.

## 20. One-Page Cheat Sheet
- **Style**: plain functions + `assert` (rich introspection); runs unittest too.
- **Fixtures**: reusable setup/teardown, scopes (function→session), `yield` teardown, in conftest.py.
- **Parametrize**: `@pytest.mark.parametrize` for many cases.
- **Async/FastAPI**: `pytest-asyncio` + `TestClient`/httpx `AsyncClient`.
- **Isolate**: `app.dependency_overrides` + fakes; testcontainers for integration.
- **CI**: `-n auto` parallel, `--cov` gate, JUnit XML; deterministic tests.

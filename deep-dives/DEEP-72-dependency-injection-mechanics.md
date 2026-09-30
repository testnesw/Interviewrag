# DEEP MECHANICS · Dependency Injection

> Level 2 — IoC, DI containers, scopes, FastAPI `Depends`, and testability.

---

## 0. The precise mental model
**Dependency Injection** = a component **receives** its collaborators from the outside instead of **creating** them itself. This is **Inversion of Control**: the framework/container owns object construction + wiring. Payoff = **loose coupling + testability** (swap real deps for fakes) + **single place for lifecycles**.

---

## 1. Why DI
- Without DI: class `new`s its own DB/HTTP client → tightly coupled, hard to test (can't substitute).
- With DI: dependency passed in (constructor/param) → **swap implementations** (real vs mock), centralize config.
- **Depend on abstractions** (interfaces/protocols), not concretes (Dependency Inversion Principle — the "D" in SOLID).

## 2. Injection styles
- **Constructor injection** (preferred) — deps required at construction; object always valid.
- **Setter/property injection** — optional deps.
- **Interface/parameter injection** — e.g., FastAPI passes deps per-request.

## 3. DI containers
- A **container** builds the object graph: you register bindings (interface → impl + lifetime), it resolves + injects transitively.
- Handles **lifecycle/scopes**:
  - **Singleton** — one instance app-wide (stateless services, config).
  - **Scoped** — one per request/unit of work (DB session).
  - **Transient** — new each resolution.

## 4. FastAPI `Depends` (Python example)
```python
def get_db():                       # dependency provider
    db = SessionLocal()
    try: yield db                   # yield → teardown after request
    finally: db.close()

@app.get("/users/{id}")
def read(id: int, db: Session = Depends(get_db)):
    return db.get(User, id)
```
- `Depends` resolves the provider per-request; **`yield`** gives setup/teardown (like scoped lifetime).
- Dependencies can depend on other dependencies (nested graph); FastAPI **caches** a dependency within one request.
- **Override** in tests: `app.dependency_overrides[get_db] = fake_db`.

## 5. Testability (the main win)
- Inject a **mock/fake** instead of the real service → fast, deterministic unit tests, no network/DB.
- Enables **contract-based** design: code against the interface.

## 6. Trade-offs
- Adds indirection/complexity; over-DI can obscure flow.
- Container misconfiguration (wrong scope) → bugs (e.g., singleton holding a request-scoped DB session → leaks/threading issues).

## 7. The hard follow-ups (with answers)
1. **"DI vs IoC?"** → IoC = general principle (framework controls flow/construction); DI = one technique to achieve it (inject deps). (§0)
2. **"Why improves testing?"** → substitute real deps with **mocks/fakes** → isolated, fast tests. (§5)
3. **"Constructor vs setter injection?"** → constructor preferred (object always valid, deps explicit/required). (§2)
4. **"What do scopes solve?"** → correct lifetime: singleton (shared), scoped (per-request DB session), transient (new each time). (§3)
5. **"How does FastAPI do DI?"** → **`Depends`** resolves providers per-request; `yield` for teardown; `dependency_overrides` for tests. (§4)
6. **"Danger of wrong scope?"** → e.g., singleton capturing a request-scoped session → state leaks / concurrency bugs. (§6)

## 8. One-screen recall
- **DI** = receive deps from outside (not `new` internally) → **IoC**, loose coupling, testable.
- **Depend on abstractions** (SOLID "D").
- **Styles**: constructor (preferred), setter, parameter.
- **Container**: registers bindings + **lifetimes** — singleton / scoped / transient.
- **FastAPI**: `Depends(provider)`, `yield` teardown, nested + cached per request, `dependency_overrides` in tests.
- **Win**: swap real ↔ mock. **Risk**: wrong scope (singleton ↔ scoped session).

> Next: Pydantic.

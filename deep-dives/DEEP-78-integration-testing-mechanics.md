# DEEP MECHANICS · Integration Testing

> Level 2 — the test pyramid, real dependencies, Testcontainers, contract
> testing, and test data management.

---

## 0. The precise mental model
Integration tests verify that **components work together against real (or realistic) dependencies** — DB, message broker, HTTP services — catching the wiring/serialization/query bugs that isolated unit tests (with mocks) can't. They're **slower and fewer** than unit tests; you spin up **real dependencies in containers** and verify end-to-end behavior of a slice.

---

## 1. Where they sit — the test pyramid
```
      /\   E2E (few, slow, full system)
     /  \  Integration (some, real deps, a slice)
    /____\ Unit (many, fast, isolated)
```
- Many unit, fewer integration, fewest E2E → fast feedback + confidence balance.
- **Anti-pattern: inverted pyramid** (mostly slow E2E) → flaky, slow CI.

## 2. What integration tests catch (that unit can't)
- Real **SQL / ORM mapping / migrations** correctness.
- **Serialization** (JSON ↔ model), HTTP routing/middleware, auth.
- Config/wiring, connection pooling, transaction behavior.
- Because unit tests mock these, mocks can lie → integration verifies reality.

## 3. Real dependencies via Testcontainers
- **Testcontainers** = spin up throwaway Docker containers (Postgres, Redis, Kafka) per test run → real engine, isolated, reproducible.
- Better than shared test DB (no cross-test pollution) or in-memory fakes (behavior differs from prod engine).

## 4. Test data management
- **Isolation strategies**: transaction rollback per test (fast), truncate/recreate, or fresh container.
- **Seed** deterministic fixtures; avoid order dependence; each test owns its data.
- Run **migrations** against the test DB (validates schema too).

## 5. API / service integration
- Spin up the app (e.g., FastAPI `TestClient`/httpx) hitting a real test DB.
- Mock only **third-party external** services you don't own (with **WireMock**/responses) — but verify the contract (§6).

## 6. Contract testing (for microservices)
- **Consumer-driven contracts** (e.g., **Pact**): consumer defines expectations → provider verifies it meets them.
- Catches breaking API changes **without** spinning the whole system → decouples service test pipelines.

## 7. CI considerations
- Slower → run on merge / nightly / separate stage; parallelize; ensure **deterministic** (no shared state, fixed clock/seeds) to avoid flakiness.
- Clean up containers/resources.

## 8. The hard follow-ups (with answers)
1. **"Unit vs integration — when each?"** → unit for logic/branches (fast, mocked); integration for wiring/DB/serialization against real deps. (§2)
2. **"Why not just mock the DB?"** → mocks can't validate real SQL/migrations/mapping → false confidence; use real DB via Testcontainers. (§3)
3. **"Realistic isolated DB in CI?"** → **Testcontainers** (throwaway Docker), migrations + per-test rollback/truncate. (§3/§4)
4. **"Test two microservices' compatibility without full deploy?"** → **consumer-driven contract testing (Pact)**. (§6)
5. **"Integration tests are flaky — why?"** → shared state/order dependence/time/network → isolate data, deterministic seeds, fresh containers. (§7)
6. **"Test pyramid?"** → many unit, some integration, few E2E; avoid inverted pyramid. (§1)

## 9. One-screen recall
- **Integration** = components + **real deps** together → catches SQL/mapping/serialization/wiring bugs mocks hide.
- **Pyramid**: many unit → some integration → few E2E.
- **Testcontainers** = throwaway real Docker deps (Postgres/Redis/Kafka), reproducible + isolated.
- **Data**: migrations + per-test rollback/truncate, deterministic seeds, no order dependence.
- **Mock only external third-parties** (WireMock); verify via **contract testing (Pact)** for microservices.
- **CI**: separate/nightly stage, deterministic to avoid flakiness, clean up.

> Next: back to the deep-dive index.

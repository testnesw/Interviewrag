# DEEP MECHANICS · API-First Design

> Level 2 — contract-first workflow, OpenAPI, design-time governance, mocking,
> and code generation.

---

## 0. The precise mental model
API-First means the **API contract is designed *before* implementation** and treated as a **first-class product**. The **OpenAPI spec** becomes the single source of truth that teams (frontend, backend, partners) build against **in parallel** — generating mocks, clients, servers, docs, and tests from it. Contrast with **code-first**, where the API is whatever the code happens to expose.

---

## 1. API-first vs code-first
| | API-first | Code-first |
|---|---|---|
| Contract | designed first (spec) | derived from code after |
| Parallelism | teams build against spec at once | consumers wait for impl |
| Consistency | enforced by design/governance | drifts per team |
| Best for | platforms, partners, many consumers | small internal/single-team |

## 2. The workflow
```
Design spec (OpenAPI) → review/govern → mock server → 
  parallel: frontend (against mock) + backend (implements to spec)
  → generate clients/SDKs, docs, tests → validate impl matches spec
```
- Design + agree the contract → **mock** immediately → everyone unblocked.

## 3. OpenAPI (the contract)
- **OpenAPI Specification** (YAML/JSON) describes paths, methods, schemas, params, responses, auth, examples.
- Single source of truth → drives tooling. (AsyncAPI = the equivalent for event-driven APIs.)

## 4. What the contract generates
- **Mock servers** (Prism) → consumers develop before backend exists.
- **Client SDKs** + **server stubs** (OpenAPI Generator) → less boilerplate, consistency.
- **Interactive docs** (Swagger UI / Redoc).
- **Contract tests** → verify implementation conforms to spec; **linting** (Spectral) for style/governance.

## 5. Design principles enforced
- Consistent **resource naming**, verbs, status codes, **versioning**, pagination, error format (RFC 7807) → org **API style guide**.
- **Design-time governance** (review + linting) catches issues before code exists (cheap to change).
- **Backward compatibility** rules; deprecation policy.

## 6. Benefits & costs
- **Benefits**: parallel dev, consistent DX, reusable/composable APIs, early feedback, better partner/integration story, fits **microservices** (clear contracts between services).
- **Costs**: upfront design effort + governance discipline; risk of over-designing before learning.

## 7. The hard follow-ups (with answers)
1. **"API-first vs code-first?"** → API-first designs the **contract before code** (parallel dev, governed); code-first derives API from implementation. (§1)
2. **"Single source of truth?"** → the **OpenAPI spec**. (§3)
3. **"How do teams work in parallel?"** → **mock server** from the spec → frontend/consumers build immediately. (§2/§4)
4. **"Ensure implementation matches contract?"** → **contract testing** + spec validation in CI. (§4)
5. **"Enforce consistency across many APIs?"** → **design-time governance** + **linting (Spectral)** + style guide. (§5)
6. **"Reduce boilerplate?"** → **code generation** (SDKs, server stubs) from OpenAPI. (§4)
7. **"Event-driven equivalent?"** → **AsyncAPI**. (§3)
8. **"Downside?"** → upfront design cost + risk of over-designing. (§6)

## 8. One-screen recall
- **Contract designed first**, API as a **product**; **OpenAPI** = single source of truth.
- **vs code-first**: parallel dev + governed consistency vs derived-from-code drift.
- **Workflow**: design spec → govern/lint → **mock** → parallel build → generate SDKs/docs/tests → validate.
- **Generates**: mocks (Prism), clients/stubs (OpenAPI Generator), docs (Swagger/Redoc), contract tests.
- **Governance**: naming/versioning/errors style guide + **Spectral** linting at design time.
- **Fits microservices**; cost = upfront design discipline. (Events → **AsyncAPI**.)

> Next: back to the deep-dive index — full coverage complete.

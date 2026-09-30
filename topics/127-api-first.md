# 127 · API-First Design

> Domain: Architecture Patterns · Level: Principal Solution Architect

## 1. Beginner Explanation
API-First means **designing your API contract before writing any code**. You agree on how the API will look and behave (its endpoints, inputs, outputs) up front — treating the API as a product — so teams and consumers can build against it in parallel with confidence.

## 2. Architect-Level Explanation
A design approach where the **API contract is the first-class artifact**, designed before implementation:
- **Contract-first**: define the API with a specification (**OpenAPI/Swagger** for REST, **AsyncAPI** for events, **Protobuf** for gRPC, **GraphQL SDL**) before coding — the spec is the single source of truth.
- **API as a product**: designed for consumers with versioning, docs, SLAs, discoverability, developer experience (DX) — not an afterthought of the implementation.
- **Parallel development**: from the contract you generate server stubs, client SDKs, and **mock servers**, so frontend/consumers and backend build **simultaneously** against the agreed contract.
- **Design principles**: consistent REST semantics (resources, HTTP verbs/status codes), clear naming, pagination/filtering, error formats (RFC 7807 Problem Details), idempotency, HATEOAS (optional), **versioning** strategy (UR/header), backward compatibility.
- **Governance**: **API style guides**, linting (Spectral), design reviews, a central **API catalog/portal**, standards — API governance at scale.
- **Lifecycle**: design → mock → review → implement → test (contract testing) → publish → version → deprecate.
- **Tooling/gateway**: **APIM** (or Apigee/Kong) for publishing, security, throttling, analytics, developer portal.
- **Benefits**: parallel work, consistency, better DX, reuse, decoupling, faster integration, fewer breaking surprises.
- **Fits**: microservices (contracts between services), platform/ecosystem plays, partner/public APIs.

## 3. Real Enterprise Use Case
A platform team adopts API-First: every service's **OpenAPI** contract is designed + reviewed (against a style guide, linted with Spectral) before coding; **mock servers** let frontend + partner teams build in parallel; **contract tests** ensure implementations match the spec; APIs publish through **APIM** with a **developer portal**, versioning, and rate limits. Result: consistent, well-documented APIs, parallel delivery, and smooth partner integration — APIs treated as products.

## 4. Architecture Diagram (ASCII)
```
   DESIGN the contract first (OpenAPI / AsyncAPI / Protobuf)  ── single source of truth
        │  review (style guide + Spectral lint)
        ├──────────────┬──────────────┬───────────────┐
        ▼              ▼              ▼               ▼
   Mock server   Server stubs   Client SDKs      Docs/portal
   (consumers build in PARALLEL with backend)
        │ implement ─► contract tests (impl matches spec)
        ▼
   Publish via API Gateway (APIM): security · throttle · versioning · analytics
   Lifecycle: design→mock→review→build→test→publish→version→deprecate
```

## 5. Interview Questions
1. What is API-First and how does it differ from code-first?
2. What does "API as a product" mean?
3. How does API-First enable parallel development?
4. How do you version and evolve APIs without breaking consumers?
5. How do you govern APIs at scale?

## 6. Strong Interview Answers
- **API-First vs code-first**: "API-First designs the **contract (OpenAPI/AsyncAPI/etc.) before implementation** — the spec is the source of truth. Code-first generates the contract *from* the implementation as an afterthought, which tends to leak internal design and produce inconsistent APIs. API-First forces deliberate, consumer-focused design up front."
- **API as a product**: "It means treating the API like a product with real customers (internal/partner/public devs): great developer experience, clear docs, versioning, SLAs, discoverability, stability, and support. The API's design serves consumers' needs, not just the implementation's convenience — because the API *is* the interface people build businesses on."
- **Parallel development**: "Once the contract is agreed, I generate **mock servers**, server stubs, and client SDKs from it. Frontend, mobile, partner, and backend teams all build **simultaneously** against the same contract and mocks, integrating smoothly at the end. This removes the sequential 'wait for the backend' bottleneck."
- **Versioning/evolution**: "I version explicitly (URI like `/v2` or headers), maintain **backward compatibility** (additive changes only within a version — new optional fields, never remove/rename), use a clear deprecation policy with timelines, and run **contract tests** to catch breaking changes. Consumers should never be surprised by a breaking change."
- **Governance**: "**Style guides** + automated linting (Spectral) enforce consistency; design reviews catch issues early; a central **API catalog/developer portal** (via APIM) gives discoverability; and standards for auth, errors (Problem Details), pagination, and versioning apply across all APIs. This scales quality across many teams."

## 7. Common Mistakes
- Code-first → inconsistent, implementation-leaking APIs.
- No versioning/deprecation policy → breaking consumers.
- Treating the API as an afterthought (poor DX/docs).
- No style guide/linting → every team's API looks different.
- Breaking changes within a version (removing/renaming fields).
- No contract testing → implementation drifts from spec.

## 8. Trade-offs
| Aspect | Pro | Con |
|--------|-----|-----|
| API-First | parallel, consistent, DX | upfront design effort |
| Strict versioning | stability | maintain multiple versions |
| Governance | consistency at scale | process overhead |

## 9. Production Best Practices
- Contract-first (OpenAPI/AsyncAPI) as source of truth; generate mocks/stubs/SDKs.
- Style guide + Spectral linting + design reviews; API catalog/portal.
- Explicit versioning + backward compatibility + deprecation policy.
- Contract testing (spec ↔ implementation); RFC 7807 errors; pagination/idempotency.
- Publish via APIM (security, throttling, analytics, DX portal).

## 10. Security Considerations
- Design auth into the contract (OAuth2/OIDC scopes, API keys) from the start.
- Input validation from schema; rate limiting/throttling (gateway).
- Least-privilege scopes; don't expose internal fields; threat-model the API.
- Gateway (APIM) enforces JWT validation, WAF, IP filtering.

## 11. Cost Optimization
- Parallel development shortens delivery time (lower cost).
- Reuse (SDKs, consistent APIs) reduces duplicate effort.
- Gateway caching + throttling reduce backend load/cost; mocks cut integration rework.

## 12. Troubleshooting Scenarios
- **Consumers broke after a change** → breaking change within a version; enforce compatibility + versioning.
- **Inconsistent APIs across teams** → no style guide/linting; introduce governance.
- **Backend/frontend integration pain** → not building against a shared contract/mock.
- **Spec ≠ implementation** → no contract tests; add them to CI.
- **Poor adoption** → bad DX/docs; treat API as a product + portal.

## 13. Hands-on Example
```yaml
# Design the contract FIRST (OpenAPI) — source of truth before any code
openapi: 3.0.3
info: { title: Orders API, version: 1.0.0 }
paths:
  /orders/{id}:
    get:
      parameters: [{ name: id, in: path, required: true, schema: { type: string } }]
      responses:
        "200": { description: OK, content: { application/json:
          { schema: { $ref: "#/components/schemas/Order" } } } }
        "404": { description: Not Found }   # RFC7807 problem+json in practice
```

## 14. Terraform Example
```hcl
# Publish the designed contract to APIM (contract → gateway, versioned)
resource "azurerm_api_management_api" "orders" {
  name = "orders-v1" resource_group_name = var.rg api_management_name = var.apim
  revision = "1" path = "orders" protocols = ["https"]
  version = "v1" version_set_id = azurerm_api_management_api_version_set.orders.id
  import { content_format = "openapi" content_value = file("orders.openapi.yaml") }
}
```

## 15. Azure Example
```bash
# Import the OpenAPI contract into APIM; generate a mock for parallel dev
az apim api import -g rg -n apim-prod --api-id orders --path orders \
  --specification-format OpenApi --specification-path orders.openapi.yaml
# APIM 'mock-response' policy serves stubbed responses before backend exists
```

## 16. FastAPI / Python Example
```python
# FastAPI generates OpenAPI automatically — but API-First means design the schema first,
# then implement to match (contract-first), validated by contract tests.
from pydantic import BaseModel
class Order(BaseModel):          # matches the agreed OpenAPI schema (source of truth)
    id: str
    total: float
    status: str

@app.get("/orders/{id}", response_model=Order, responses={404: {"description": "Not Found"}})
async def get_order(id: str) -> Order:
    return await repo.get(id)     # implementation conforms to the pre-agreed contract
```

## 17. AKS Example
In an AKS microservices platform, **API-First contracts define the boundaries between services**: each service publishes its OpenAPI/AsyncAPI spec, consumers build against generated SDKs + mocks, contract tests run in CI (GitOps), and **APIM/ingress** fronts the services with versioning + security. Contracts decouple teams so services evolve independently without breaking each other.

## 18. How to Remember
**"Contract before code (OpenAPI/AsyncAPI = source of truth); API as a product (DX/docs/versioning/SLA); generate mocks+stubs+SDKs → parallel dev; govern with style guide + lint + portal; version without breaking."**

## 19. Real-World Analogy
Agreeing on the blueprints and electrical/plumbing standards before construction starts: because everyone works from the same detailed plans (contract), the electrician, plumber, and carpenter can all work in parallel and everything fits together at the end. Standard socket shapes (API standards) mean any appliance (consumer) just plugs in — versus building the house first and hoping the wiring matches later (code-first).

## 20. One-Page Cheat Sheet
- **What**: design the **API contract first** (OpenAPI/AsyncAPI/Protobuf/GraphQL SDL) — spec = single source of truth, before code.
- **API as a product**: consumer-focused DX, docs, versioning, SLAs, discoverability.
- **Parallel dev**: generate **mocks + server stubs + client SDKs** → frontend/partners/backend build simultaneously.
- **Evolution**: explicit **versioning** + backward compatibility (additive only) + deprecation policy; **contract testing**.
- **Govern**: style guide + **Spectral lint** + design reviews + API catalog/portal; RFC 7807 errors.
- **Publish**: via **APIM** (security/throttle/analytics/DX portal); ideal for microservices + partner/public APIs.

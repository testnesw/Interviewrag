# 71 · REST APIs

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
A REST API is a standard way for applications to talk over HTTP using resources (like `/orders`) and HTTP methods (GET to read, POST to create, etc.). It's the most common way to build web APIs.

## 2. Architect-Level Explanation
REST is an architectural style over HTTP built on resources and constraints:
- **Resources + verbs**: nouns as URLs (`/orders/123`), HTTP methods for actions (GET/POST/PUT/PATCH/DELETE).
- **Statelessness**: each request self-contained (auth token included) → horizontal scalability.
- **Status codes**: semantic (200, 201, 204, 400, 401, 403, 404, 409, 422, 429, 500).
- **Idempotency & safety**: GET/PUT/DELETE idempotent, POST not; use idempotency keys for safe retries.
- **Versioning**: URI (`/v1`), header, or media-type; evolve without breaking clients.
- **HATEOAS** (full REST maturity) rarely fully adopted; most APIs are "pragmatic REST."
- **Cross-cutting**: pagination, filtering, rate limiting, caching (ETag/Cache-Control), consistent error envelopes, OpenAPI contract.
- **Alternatives**: GraphQL (flexible queries), gRPC (high-perf internal), REST (ubiquitous, cacheable).

## 3. Real Enterprise Use Case
A company exposes versioned REST APIs (`/v1/orders`) via an API gateway: OAuth2/JWT auth, standardized error envelopes, cursor pagination, idempotency keys on POST for safe retries, ETag caching, and rate limiting — documented via OpenAPI in a developer portal for internal and partner consumption.

## 4. Architecture Diagram (ASCII)
```
   Client ─► API Gateway (auth, rate limit, routing)
                │
        REST service /v1/orders
          GET  200/404      POST 201 (Location + idempotency key)
          PUT  200/204      DELETE 204
          400/401/403/409/422/429/500 (semantic)
          pagination · filtering · ETag caching · error envelope
   Stateless (token per request) → scales horizontally
```

## 5. Interview Questions
1. What makes an API RESTful?
2. PUT vs PATCH vs POST; which are idempotent?
3. How do you version APIs?
4. How do you handle safe retries?
5. REST vs GraphQL vs gRPC?

## 6. Strong Interview Answers
- **RESTful**: "Resource-oriented URLs, correct HTTP methods and status codes, statelessness, and a uniform interface. Pragmatically: consistent contracts, proper codes, pagination, and versioning — full HATEOAS is rare."
- **PUT/PATCH/POST**: "PUT replaces a resource (idempotent), PATCH partially updates (can be idempotent), POST creates (not idempotent — repeating creates duplicates). GET/PUT/DELETE are idempotent; POST isn't."
- **Versioning**: "URI versioning (`/v1`) is simplest and most visible; header/media-type versioning is cleaner but harder to test. Key is never breaking existing clients — additive changes, deprecate with notice."
- **Safe retries**: "Idempotency keys — the client sends a unique key on POST; the server dedupes so a retried request doesn't double-create. Combined with retries + exponential backoff for resilience."
- **REST/GraphQL/gRPC**: "REST is ubiquitous, cacheable, simple — great for public APIs. GraphQL lets clients fetch exactly what they need (flexible, avoids over/under-fetching). gRPC is fast, binary, contract-first — ideal for internal service-to-service. I pick per use case."

## 7. Common Mistakes
- Verbs in URLs (`/getOrders`) instead of nouns + methods.
- Wrong/blanket status codes (200 for everything).
- Non-idempotent POST without idempotency keys.
- Breaking changes without versioning.
- No pagination on large collections.

## 8. Trade-offs
| Style | Pro | Con |
|-------|-----|-----|
| REST | simple, cacheable, ubiquitous | over/under-fetching |
| GraphQL | flexible queries | caching/complexity |
| gRPC | fast, typed | not browser-native |

## 9. Production Best Practices
- Resource nouns + correct methods + semantic status codes.
- Versioning + additive, backward-compatible changes.
- Idempotency keys; retries with backoff.
- Pagination/filtering; ETag/Cache-Control caching.
- Consistent error envelope; OpenAPI contract + rate limiting.

## 10. Security Considerations
- OAuth2/JWT auth + scope/role checks; HTTPS only.
- Input validation (Pydantic); avoid over-exposing fields.
- Rate limiting + throttling; consistent, non-leaky errors.
- CORS restricted; protect against IDOR (authorization per resource).

## 11. Cost Optimization
- Caching (ETag/CDN) cuts backend load.
- Pagination avoids large payloads/egress.
- Efficient serialization; gzip/brotli compression.

## 12. Troubleshooting Scenarios
- **Duplicate records** → non-idempotent POST retried; add idempotency keys.
- **Client breakage** → non-versioned breaking change.
- **429s** → rate limit hit; backoff / raise limits.
- **Large slow responses** → missing pagination.
- **Wrong error handling** → inconsistent status codes/envelope.

## 13. Hands-on Example
```bash
curl -X POST https://api/v1/orders \
  -H "Authorization: Bearer $T" -H "Idempotency-Key: abc-123" \
  -H "Content-Type: application/json" -d '{"total":42.0}'
# 201 Created, Location: /v1/orders/123
```

## 14. Terraform Example
```hcl
# API Management: versioned API + rate limit policy
resource "azurerm_api_management_api" "orders" {
  name = "orders" api_management_name = var.apim resource_group_name = var.rg
  revision = "1" path = "orders" protocols = ["https"]
  import { content_format = "openapi" content_value = file("openapi.yaml") }
}
```

## 15. Azure Example
Front the FastAPI service with **Azure API Management**: JWT validation, rate limiting, response caching, versioning, and a developer portal — offloading cross-cutting concerns from the service.

## 16. FastAPI / Python Example
```python
from fastapi import FastAPI, Header, HTTPException, status
app = FastAPI()
_seen: dict[str, dict] = {}

@app.post("/v1/orders", status_code=status.HTTP_201_CREATED)
async def create_order(order: dict, idempotency_key: str = Header(...)):
    if idempotency_key in _seen:
        return _seen[idempotency_key]          # safe retry → same result
    created = await save_order(order)
    _seen[idempotency_key] = created
    return created
```

## 17. AKS Example
```yaml
# Ingress exposing versioned REST API with rate limiting annotations
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: orders
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "20"
spec:
  rules:
    - http: { paths: [{ path: /v1/orders, pathType: Prefix,
        backend: { service: { name: orders, port: { number: 80 } } } }] }
```

## 18. How to Remember
**"Nouns + HTTP verbs + right status codes + versioning + idempotency."** Stateless = scalable.

## 19. Real-World Analogy
A well-run restaurant menu system: dishes are items (resources), and standard actions apply — order (POST), check status (GET), change order (PATCH), cancel (DELETE). A ticket number (idempotency key) ensures the kitchen doesn't cook your meal twice if the waiter re-submits.

## 20. One-Page Cheat Sheet
- **Design**: resource nouns + HTTP verbs (GET/POST/PUT/PATCH/DELETE) + semantic status codes.
- **Idempotency**: GET/PUT/DELETE idempotent; POST not → idempotency keys for safe retries.
- **Stateless**: token per request → horizontal scale.
- **Evolve**: versioning (URI `/v1`), additive changes, deprecate gracefully.
- **Cross-cutting**: pagination, filtering, ETag caching, rate limiting, error envelope, OpenAPI.
- **vs**: GraphQL (flexible), gRPC (fast internal), REST (ubiquitous/cacheable).

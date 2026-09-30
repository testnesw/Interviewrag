# DEEP MECHANICS · REST APIs

> Level 2 — REST constraints, verbs/status codes, idempotency, versioning,
> pagination, and design trade-offs.

---

## 0. The precise mental model
REST is an **architectural style**: resources identified by **URIs**, manipulated via a **uniform interface** (HTTP verbs), **stateless** requests, with **representations** (JSON) transferred. The server exposes *nouns* (resources); *verbs* express intent. Correct **status codes + idempotency + versioning** are what make an API predictable and evolvable.

---

## 1. Core constraints
- **Client–server**, **stateless** (no server session; each request self-contained → scalable).
- **Cacheable**, **uniform interface**, **layered system**, (optional) **code-on-demand**.
- **Statelessness** is the big lever: any server instance can handle any request → horizontal scale.

## 2. Resources & verbs
| Verb | Purpose | Idempotent | Safe |
|---|---|---|---|
| GET | read | ✅ | ✅ |
| POST | create / action | ❌ | ❌ |
| PUT | full replace/upsert | ✅ | ❌ |
| PATCH | partial update | ✅* | ❌ |
| DELETE | remove | ✅ | ❌ |
- **Idempotent** = repeat has same effect (PUT/DELETE/GET). **Safe** = no state change (GET).
- Resource-oriented URIs: `/orders/123/items` (nouns, plural, hierarchy), not `/getOrderItems`.

## 3. Status codes (know these cold)
- **2xx**: 200 OK, 201 Created (+`Location`), 202 Accepted (async), 204 No Content.
- **3xx**: 301/302 redirect, 304 Not Modified (caching).
- **4xx client**: 400 bad request, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict, 422 validation, 429 rate-limited.
- **5xx server**: 500 internal, 502 bad gateway, 503 unavailable, 504 timeout.

## 4. Idempotency (critical for reliability)
- Retries on network failure must not double-charge/double-create.
- GET/PUT/DELETE naturally idempotent; **POST is not** → use an **idempotency key** (client-sent unique header; server dedupes).

## 5. Versioning
- **URI**: `/v1/orders` (simple, visible, cache-friendly) — most common.
- **Header**: `Accept: application/vnd.api.v2+json` (cleaner URIs, harder to test).
- **Query**: `?version=2`.
- Version to avoid breaking clients; deprecate with sunset headers.

## 6. Pagination & filtering
- **Offset/limit** (`?page=2&size=50`) — simple, but drifts on inserts, slow deep pages.
- **Cursor/keyset** (`?after=<token>`) — stable + fast for large data (recommended).
- Filtering/sorting via query params; return total/next-links.

## 7. Other essentials
- **HATEOAS** (links in responses) = full REST maturity (Richardson L3) — rarely fully adopted.
- **Errors**: consistent body (RFC 7807 problem+json). **Auth**: OAuth2/JWT bearer.
- **Caching**: ETag/If-None-Match → 304; Cache-Control. **Rate limiting**: 429 + Retry-After.

## 8. The hard follow-ups (with answers)
1. **"Why stateless?"** → any instance serves any request → horizontal scalability + resilience. (§1)
2. **"PUT vs PATCH vs POST?"** → PUT full replace (idempotent), PATCH partial (idempotent-ish), POST create/action (not idempotent). (§2)
3. **"Make POST safe to retry?"** → **idempotency key** header; server dedupes. (§4)
4. **"201 vs 202?"** → 201 created (resource exists now, `Location`); 202 accepted (async, not done yet). (§3)
5. **"Paginate 10M rows?"** → **cursor/keyset** pagination, not offset. (§6)
6. **"Version an API?"** → URI `/v1` (common) or Accept header; deprecate gracefully. (§5)
7. **"409 vs 422?"** → 409 state conflict (e.g., duplicate/version clash); 422 semantic validation failure. (§3)

## 9. One-screen recall
- **Style**: resources (nouns) + uniform verbs + **stateless** + cacheable.
- **Verbs**: GET(safe/idem), POST(create/not-idem), PUT(replace/idem), PATCH(partial), DELETE(idem).
- **Codes**: 200/201/202/204 · 301/304 · 400/401/403/404/409/422/429 · 500/502/503/504.
- **Idempotency**: PUT/DELETE/GET yes; POST → **idempotency key**.
- **Versioning**: URI `/v1` (common) or Accept header.
- **Pagination**: **cursor/keyset** > offset for scale.
- **Extras**: ETag caching, RFC7807 errors, OAuth2/JWT, 429+Retry-After.

> Next: Dependency injection.

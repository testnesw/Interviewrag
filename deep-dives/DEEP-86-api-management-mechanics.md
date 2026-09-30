# DEEP MECHANICS · Azure API Management (APIM)

> Level 2 — the gateway, policies, products/subscriptions, versioning, and
> security patterns.

---

## 0. The precise mental model
APIM is a **managed API gateway** that sits in front of your backends and provides a **façade**: a single entry point that handles **auth, rate limiting, transformation, caching, routing, and observability** via a **policy pipeline**. It decouples consumers from backend implementation and centralizes cross-cutting API concerns.

---

## 1. Components
- **Gateway** — runtime that proxies requests, executes policies (managed, self-hosted, or consumption).
- **Developer portal** — auto-generated docs + API key signup.
- **Management plane** — define APIs, products, policies.
- **APIs / Operations** — imported (OpenAPI/WSDL/backend) and exposed.

## 2. The policy pipeline (the heart)
```
inbound → backend → outbound → on-error
```
- Policies run in stages; XML-based. Examples:
  - **inbound**: validate JWT, rate-limit, IP filter, rewrite, set headers, cache-lookup.
  - **backend**: route, retry, circuit-break.
  - **outbound**: transform response, cache-store, mask fields.
- Scoped at global / product / API / operation levels (inheritance).

## 3. Products & subscriptions
- **Product** = bundle of APIs with a policy + access rules; can be **open** or require **subscription**.
- **Subscription** → issues **subscription keys**; enables **per-subscriber quotas/rate limits** + usage tracking.

## 4. Security patterns
- **Frontend auth**: subscription keys, **OAuth2/JWT validation** (`validate-jwt`), client certs, IP allowlist.
- **Backend auth**: **Managed Identity** to call backends/Key Vault; mTLS; hide backend credentials.
- APIM shields backends (backends only reachable via private network / private endpoint).

## 5. Traffic management
- **Rate-limit** (per period) + **quota** (per subscription over longer window).
- **Caching** (response cache → offload backend).
- **Load balancing / backends pools**, retry, circuit breaker.
- **Versioning** (path/header/query) + **revisions** (non-breaking staged changes).

## 6. Tiers & networking
- Tiers: Consumption (serverless), Developer, Basic/Standard/Premium (VNet integration, multi-region in Premium), plus the newer **v2** tiers.
- **VNet injection / private endpoint** → internal APIs, backends not public.

## 7. The hard follow-ups (with answers)
1. **"What problem does APIM solve?"** → centralizes cross-cutting API concerns (auth/throttle/transform/observe) + façade decoupling consumers from backends. (§0)
2. **"How is behavior customized?"** → **policy pipeline** (inbound/backend/outbound/on-error), scoped with inheritance. (§2)
3. **"Per-customer rate limits?"** → **products + subscriptions** (subscription keys → quotas). (§3)
4. **"Validate a JWT at the gateway?"** → `validate-jwt` inbound policy. (§4)
5. **"Call backend securely?"** → **Managed Identity** + private endpoint; hide creds. (§4)
6. **"Version APIs without breaking clients?"** → **versions** (path/header) + **revisions**. (§5)
7. **"Multi-region / VNet?"** → **Premium** tier (multi-region + VNet injection). (§6)

## 8. One-screen recall
- **Managed API gateway / façade**: auth, throttle, transform, cache, route, observe.
- **Policy pipeline**: **inbound → backend → outbound → on-error**; scoped (global/product/API/op) + inheritance.
- **Products + subscriptions** → keys + **per-subscriber quotas**.
- **Security**: validate-jwt, subscription keys, client certs; **MI** to backend + private endpoint.
- **Traffic**: rate-limit/quota, caching, retry/CB; **versions + revisions**.
- **Premium** = multi-region + VNet injection.

> Next: Azure Functions.

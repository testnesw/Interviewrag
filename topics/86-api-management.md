# 86 · Azure API Management (APIM)

> Domain: Integration & Messaging · Level: Principal Integration Architect

## 1. Beginner Explanation
Azure API Management (APIM) is a **gateway that sits in front of your APIs**. It handles authentication, rate limiting, caching, and monitoring, and gives developers a portal to discover and use your APIs — so backend services don't each reinvent these concerns.

## 2. Architect-Level Explanation
A managed API gateway + management plane for publishing, securing, and governing APIs:
- **Components**: **Gateway** (runtime data plane), **management plane** (config), **Developer Portal** (discovery/docs/keys).
- **Policies**: XML policy pipeline at inbound/backend/outbound/on-error — JWT validation, rate-limit/quota, caching, transformation, rewrite, CORS, IP filtering, mock.
- **Products & subscriptions**: bundle APIs, gate with subscription keys, quotas, approval.
- **Security**: OAuth2/JWT (Entra ID), subscription keys, mTLS, client certs, **Managed Identity** to backends, IP allow-lists, WAF (via App Gateway/Front Door in front).
- **Tiers**: Consumption (serverless, per-call), Developer, Basic/Standard/Premium (VNet, multi-region, scale), **v2 tiers** (faster provisioning, VNet). Premium = multi-region + VNet injection.
- **Backends**: any HTTP API, Azure Functions, Logic Apps, AKS services; internal (VNet) or external.
- **Observability**: App Insights, request logging, analytics.
- **Versioning/revisions**: manage API versions + non-breaking revisions.

## 3. Real Enterprise Use Case
An enterprise fronts dozens of microservices (AKS + Functions) with Premium APIM in a VNet: Entra ID JWT validation, per-product rate limits/quotas for partners, response caching, request/response transformation for legacy backends, multi-region gateways for low latency, and a branded Developer Portal for internal + partner onboarding.

## 4. Architecture Diagram (ASCII)
```
   Clients / Partners
        │ (Front Door + WAF)
   ┌────▼─────────── APIM Gateway (VNet, multi-region) ───────────┐
   │ inbound policies: JWT validate · rate-limit/quota · IP filter │
   │ caching · transform/rewrite · CORS                            │
   └──────────────┬───────────────────────────────────────────────┘
        backend (Managed Identity / mTLS)
   ┌──────────────┼──────────────┬───────────────┐
   AKS services   Azure Functions Logic Apps   legacy APIs
   Developer Portal (docs, keys) | App Insights (analytics)
```

## 5. Interview Questions
1. What problems does APIM solve?
2. How does the policy pipeline work?
3. How do you secure APIs with APIM?
4. What are products and subscriptions?
5. Which tier for VNet + multi-region?

## 6. Strong Interview Answers
- **Problems**: "It centralizes cross-cutting API concerns — auth, rate limiting, caching, transformation, versioning, analytics, and developer onboarding — so backends stay focused on business logic and policy is consistent."
- **Policy pipeline**: "Policies run in stages — inbound (before backend), backend, outbound (before client), and on-error. I compose JWT validation, rate-limit, caching, and transformations declaratively in XML, scoped globally/per-product/per-API/per-operation."
- **Security**: "Validate Entra ID JWTs (`validate-jwt`), enforce subscription keys, rate-limit/quota, IP filtering and client certs/mTLS, and use **Managed Identity** to call backends. I put a WAF (App Gateway/Front Door) in front and inject APIM into a VNet for private backends."
- **Products/subscriptions**: "A product bundles APIs with access rules; consumers get a subscription (keys, quota, maybe approval). It's how I package APIs for different audiences — e.g., a partner product with strict quotas vs an internal product."
- **Tier**: "**Premium** for VNet injection + multi-region + high scale and SLA; the newer **v2 tiers** provision faster with VNet support; Consumption is serverless/per-call for light or spiky workloads. Developer tier for non-prod."

## 7. Common Mistakes
- Using APIM as the only auth layer (no defense in depth/WAF).
- Heavy transformations creating a "smart gateway" bottleneck.
- No caching/rate limits → backend overload.
- Ignoring VNet needs (public backends) for private services.
- Not versioning APIs → breaking consumers.

## 8. Trade-offs
| Tier | Pro | Con |
|------|-----|-----|
| Consumption | serverless, cheap idle | cold start, fewer features |
| Premium | VNet, multi-region, scale | costly |
| v2 | fast provision + VNet | newer |

## 9. Production Best Practices
- Centralize cross-cutting policies (JWT, rate-limit, cache).
- Products/subscriptions with quotas per audience.
- Managed Identity to backends; VNet for private services.
- WAF (Front Door/App Gateway) in front; IP allow-lists.
- Versioning + revisions; App Insights monitoring; IaC the config.

## 10. Security Considerations
- Entra ID JWT validation + scopes; subscription keys.
- mTLS/client certs; Managed Identity to backends (no secrets).
- WAF + IP filtering; rate-limit to blunt abuse/DoS.
- Named values from Key Vault; private (internal) gateway mode.

## 11. Cost Optimization
- Consumption tier for spiky/low volume.
- Caching cuts backend calls/compute.
- Right-size units/regions; quotas prevent runaway partner usage.

## 12. Troubleshooting Scenarios
- **401/403** → JWT policy config / missing subscription key.
- **429** → rate-limit/quota hit; adjust or backoff.
- **Backend unreachable** → VNet/private endpoint/DNS; NSG.
- **High latency** → heavy policies/transforms; cache; scale units.
- **CORS errors** → outbound CORS policy missing.

## 13. Hands-on Example
```xml
<!-- inbound policy: validate Entra ID JWT + rate limit -->
<inbound>
  <validate-jwt header-name="Authorization" require-scheme="Bearer">
    <openid-config url="https://login.microsoftonline.com/<tenant>/v2.0/.well-known/openid-configuration"/>
    <required-claims><claim name="aud"><value>api://orders</value></claim></required-claims>
  </validate-jwt>
  <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)"/>
</inbound>
```

## 14. Terraform Example
```hcl
resource "azurerm_api_management" "apim" {
  name = "apim-prod" resource_group_name = var.rg location = "eastus"
  publisher_name = "ACME" publisher_email = "api@acme.com"
  sku_name = "Premium_1"
  identity { type = "SystemAssigned" }
  virtual_network_type = "Internal"       # VNet injection
}
```

## 15. Azure Example
```bash
az apim api import -g rg -n apim-prod --api-id orders \
  --path orders --specification-format OpenApi --specification-path openapi.yaml
```

## 16. FastAPI / Python Example
```python
# Backend FastAPI trusts APIM to have validated JWT; still checks a forwarded claim
from fastapi import Header, HTTPException
@app.get("/orders")
async def orders(x_client_id: str = Header(default="")):
    if not x_client_id:                      # APIM injects verified identity header
        raise HTTPException(401, "missing client identity")
    return await list_orders(x_client_id)
```

## 17. AKS Example
APIM (Internal/VNet mode) fronts AKS services exposed via internal ingress; it validates JWTs, rate-limits partners, and calls the private ingress over the VNet. AKS services only accept traffic from the APIM subnet (NSG/network policy) — APIM is the single controlled entry point.

## 18. How to Remember
**"Gateway + policies + products + portal."** Policy pipeline: inbound → backend → outbound → on-error. Premium = VNet + multi-region.

## 19. Real-World Analogy
A building's reception + security desk for all visitors (API calls): it checks IDs (JWT), enforces visitor limits (rate-limit/quota), hands out badges (subscription keys), keeps a visitor log (analytics), and directs people to the right office (routing) — so each office doesn't need its own guard.

## 20. One-Page Cheat Sheet
- **What**: managed API gateway + management plane + Developer Portal.
- **Policies**: inbound/backend/outbound/on-error — JWT, rate-limit/quota, cache, transform, CORS, IP filter.
- **Packaging**: products + subscriptions (keys, quotas, approval).
- **Security**: Entra ID JWT, mTLS, Managed Identity to backends, WAF in front, VNet (internal).
- **Tiers**: Consumption (serverless), Premium (VNet + multi-region), v2 (fast + VNet).
- **Ops**: versioning/revisions, App Insights, IaC the config.

# 123 · Microservices

> Domain: Architecture Patterns · Level: Principal Solution Architect

## 1. Beginner Explanation
Microservices is an architecture style where an application is built as **many small, independent services** that each do one thing and talk to each other over the network — instead of one big program (a monolith). Each can be built, deployed, and scaled separately.

## 2. Architect-Level Explanation
Decomposing a system into independently deployable, loosely coupled services organized around business capabilities:
- **Core principles**: single responsibility (per business capability), **independent deployability**, **decentralized data** (database-per-service), loose coupling + high cohesion, autonomy (teams own services end-to-end).
- **Boundaries**: define via **Domain-Driven Design** bounded contexts (topic 124) — the hardest and most important part.
- **Communication**: **sync** (REST/gRPC) vs **async** (events/messaging — Service Bus/Event Grid/Kafka); prefer async for decoupling/resilience.
- **Data**: each service owns its data; consistency via **eventual consistency**, **saga** pattern, **outbox**, CQRS — no shared database.
- **Cross-cutting infra**: **API gateway** (APIM), **service discovery**, **service mesh** (Istio/Linkerd — mTLS, traffic, observability), config, centralized logging/tracing (OTel).
- **Resilience patterns**: retry, **circuit breaker**, bulkhead, timeout, fallback, idempotency.
- **Deployment**: containers + Kubernetes/AKS, independent CI/CD per service, versioning.
- **Trade-offs**: gains independent scaling/deployment/tech-diversity/team autonomy/fault isolation, but adds **distributed-system complexity** (network, consistency, testing, observability, operational overhead).
- **When NOT**: small teams/simple domains — **start with a modular monolith**, extract services when justified (avoid premature/distributed-monolith).

## 3. Real Enterprise Use Case
An e-commerce platform splits into services by capability — catalog, cart, orders, payments, inventory, shipping — each with its own database, deployed independently on **AKS**. They communicate async via **Service Bus** (order events) with **sagas** for the checkout workflow, sync via REST behind **APIM**, use a **service mesh** for mTLS + traffic control + tracing, and apply circuit breakers/retries for resilience — enabling teams to ship independently and scale hot services (catalog, payments) separately.

## 4. Architecture Diagram (ASCII)
```
   Clients ─► API Gateway (APIM)
   ┌──────────┬──────────┬──────────┬──────────┬──────────┐
   Catalog    Cart       Orders     Payments   Inventory   (each: own DB)
     │DB        │DB         │DB        │DB         │DB
   async events (Service Bus/Kafka) ── saga/outbox ── eventual consistency
   Service Mesh: mTLS · traffic · retries/circuit breaker · tracing (OTel)
   Deploy: containers on AKS, independent CI/CD per service
   ⚠ distributed-system complexity: network, consistency, observability
```

## 5. Interview Questions
1. What are microservices and their core principles?
2. How do you define service boundaries?
3. Sync vs async communication; how handle data consistency?
4. What resilience patterns do you apply?
5. When should you NOT use microservices?

## 6. Strong Interview Answers
- **Principles**: "Small services organized around **business capabilities**, each independently deployable with its **own data**, loosely coupled and highly cohesive, owned end-to-end by autonomous teams. The goal is independent deployment + scaling + team autonomy — not just 'small'."
- **Boundaries**: "I use **Domain-Driven Design** — bounded contexts define service boundaries around cohesive business subdomains. Getting boundaries right is the hardest part; wrong boundaries create chatty, tightly-coupled services (a distributed monolith). I look for high cohesion within and loose coupling across, aligned to how the business actually works."
- **Comms/consistency**: "Sync (REST/gRPC) is simple but couples availability; **async** (events/messaging) decouples and improves resilience, so I prefer it for inter-service flows. Since each service owns its data, I use **eventual consistency** with **sagas** (compensating transactions) for cross-service workflows and the **outbox** pattern for reliable event publishing — no distributed 2PC, no shared DB."
- **Resilience**: "Retry with backoff + idempotency, **circuit breakers** to stop cascading failures, **bulkheads** to isolate resource pools, timeouts, and fallbacks. A service mesh or resilience library (Polly) implements these. The network is unreliable, so I design for partial failure."
- **When not**: "For small teams or simple/uncertain domains, microservices' distributed complexity outweighs the benefits — I start with a **modular monolith** (clean internal boundaries) and extract services only when there's a real driver (independent scaling, team scaling, differing release cadence). Premature microservices create a painful distributed monolith."

## 7. Common Mistakes
- **Distributed monolith** — services too coupled/chatty (wrong boundaries).
- Shared database across services (breaks independence).
- Sync everywhere → cascading failures + tight coupling.
- No resilience patterns (retry/circuit breaker) → fragile.
- Premature microservices on a simple domain/small team.
- Weak observability → undebuggable distributed system.

## 8. Trade-offs
| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| Deploy | one unit | independent |
| Scaling | whole app | per service |
| Complexity | low | high (distributed) |
| Consistency | easy (ACID) | eventual/saga |

## 9. Production Best Practices
- DDD bounded contexts for boundaries; database-per-service.
- Async/event-driven + saga + outbox; idempotent handlers.
- API gateway + service mesh (mTLS, traffic, resilience, tracing).
- Resilience patterns (retry/circuit breaker/bulkhead/timeout).
- Independent CI/CD + versioning; centralized observability (OTel); start monolith-first.

## 10. Security Considerations
- **mTLS** between services (service mesh); Zero Trust internal network.
- Per-service least-privilege identity (Workload Identity); API gateway authN/Z.
- Secrets in Key Vault; network policies; validate at boundaries.
- Distributed audit/tracing for security investigation.

## 11. Cost Optimization
- Scale only hot services (not the whole app); scale-to-zero idle ones (KEDA).
- Right-size per service; avoid over-provisioning many small services.
- Watch inter-service **egress**/chattiness (cost + latency) — coarser APIs.

## 12. Troubleshooting Scenarios
- **Cascading failure** → no circuit breakers; add them + bulkheads + timeouts.
- **Cross-service data inconsistency** → missing saga/outbox; implement.
- **Chatty/coupled services** → wrong boundaries (distributed monolith); re-model via DDD.
- **Hard to debug** → no distributed tracing; add OTel + correlation IDs.
- **Duplicate message effects** → non-idempotent handlers.

## 13. Hands-on Example
```python
# Resilient inter-service call: timeout + retry + circuit breaker (idempotent)
import httpx, tenacity
@tenacity.retry(stop=tenacity.stop_after_attempt(3),
                wait=tenacity.wait_exponential())
async def get_inventory(sku: str):
    async with httpx.AsyncClient(timeout=2.0) as c:      # timeout
        r = await c.get(f"http://inventory/stock/{sku}") # circuit breaker via mesh
        r.raise_for_status()
        return r.json()
```

## 14. Terraform Example
```hcl
# Each microservice: independent AKS deployment + its own database
module "orders_service" {
  source = "./modules/microservice"
  name = "orders" image = "acr.azurecr.io/orders:v2"
  database = "azuresql"          # database-per-service
  min_replicas = 2 max_replicas = 20   # independent scaling
}
```

## 15. Azure Example
Azure microservices stack: **AKS** or **Container Apps** (with Dapr for service invocation/pub-sub/state), **APIM** (gateway), **Service Bus/Event Grid** (async), **Azure SQL/Cosmos per service**, **service mesh** (Istio) or Container Apps built-in mTLS, and **App Insights + OTel** for distributed tracing.

## 16. FastAPI / Python Example
```python
# A microservice owns its data + publishes events (outbox), never shares DB
@app.post("/orders")
async def create_order(order: OrderIn):
    async with db.transaction():                 # own database
        order_id = await orders_repo.insert(order)
        await outbox_repo.insert("OrderPlaced", order_id)   # outbox → reliable publish
    return {"order_id": order_id}                # other services react to the event
```

## 17. AKS Example
AKS is the canonical microservices platform: each service is a Deployment + Service, scaled by HPA/KEDA independently, with **Istio/Linkerd** service mesh for mTLS + traffic splitting (canary) + retries/circuit breaking + tracing, **APIM/ingress** at the edge, Workload Identity per service, and network policies isolating traffic — independent CI/CD via GitOps (ArgoCD).

## 18. How to Remember
**"Small independent services per business capability; own data (no shared DB); async + saga/outbox = eventual consistency; gateway + mesh + resilience (circuit breaker); DDD for boundaries; distributed complexity — start monolith-first."**

## 19. Real-World Analogy
A food court vs one giant restaurant: instead of a single kitchen (monolith) where one problem shuts everything down, independent stalls (microservices) each specialize, run their own operations, open/close and expand independently, and a busy stall can add staff without affecting others. But now you need shared infrastructure — signage, a directory, and coordination (gateway, mesh, messaging) — and it's more complex to manage overall.

## 20. One-Page Cheat Sheet
- **What**: independently deployable, loosely-coupled services per **business capability**.
- **Principles**: single responsibility, **database-per-service**, autonomy, high cohesion / loose coupling.
- **Boundaries**: **DDD bounded contexts** (get these right — else distributed monolith).
- **Comms/data**: prefer **async** (events); **eventual consistency** via **saga + outbox**; no shared DB.
- **Infra**: API gateway + **service mesh** (mTLS/traffic/tracing) + resilience (retry/**circuit breaker**/bulkhead) on AKS.
- **Caveat**: high distributed complexity — **start with a modular monolith**, extract when justified.

# 126 · CQRS (Command Query Responsibility Segregation)

> Domain: Architecture Patterns · Level: Principal Solution Architect

## 1. Beginner Explanation
CQRS means **separating the code that changes data (commands/writes) from the code that reads data (queries)**. Instead of one model doing both, you have a write side and a read side, each optimized for its job — which can improve performance, scalability, and clarity.

## 2. Architect-Level Explanation
A pattern that separates **writes (commands)** from **reads (queries)** into distinct models:
- **Command side**: handles state changes — commands (`PlaceOrder`) → validated → domain model/aggregates enforce invariants → persist. Optimized for consistency + business rules.
- **Query side**: handles reads — returns DTOs from **read models/projections** optimized for query shapes (denormalized, per-view). No business logic.
- **Separate models** (not necessarily separate databases): can range from two models on one DB → **separate write and read stores** (e.g., SQL write + Cosmos/Redis/Elastic read) synced via events.
- **Synchronization**: write side emits **events**; **projections** update read models → **eventual consistency** between write and read.
- **Pairs with**: **Event Sourcing** (write store = event log; read models = projections) — powerful together but not required; **DDD** (aggregates on the command side); **event-driven**.
- **Benefits**: independent scaling (reads usually dominate → scale read side separately), optimized read/write models, security separation, flexibility, performance.
- **Costs**: complexity, eventual consistency (read may lag write), more moving parts, data duplication.
- **When**: high read/write asymmetry, complex domains, collaborative/high-performance systems — **not** simple CRUD (overkill). Often applied to specific bounded contexts, not everywhere.

## 3. Real Enterprise Use Case
An order system uses CQRS: the **command side** (Azure SQL + DDD aggregates) enforces order/payment invariants on writes; on each change it emits events that update **read projections** — a denormalized Cosmos DB "order summary" and a Redis cache — powering fast, high-volume customer + dashboard reads. The read side scales independently for heavy query traffic, while writes stay consistent and rule-driven; teams accept slight read lag (eventual consistency).

## 4. Architecture Diagram (ASCII)
```
   Command (PlaceOrder) ─► Command Handler ─► Domain/Aggregate (invariants)
                                     │ persist
                                     ▼
                         Write Store (normalized, consistent)
                                     │ emits events
                                     ▼  projection
                         Read Store(s) (denormalized per view: Cosmos/Redis/Elastic)
                                     ▲
   Query (GetOrderSummary) ─► Query Handler ─► read model (DTO, no logic)
   Write ⟂ Read (scale independently) | eventual consistency (read lags write)
   Optional: Write Store = Event Log (Event Sourcing)
```

## 5. Interview Questions
1. What is CQRS and why use it?
2. Does CQRS require separate databases?
3. How do read and write sides stay in sync (consistency)?
4. How does CQRS relate to Event Sourcing and DDD?
5. When should you NOT use CQRS?

## 6. Strong Interview Answers
- **What/why**: "CQRS separates the write model (commands that change state, enforce business rules) from the read model (queries returning view-optimized DTOs). You use it when reads and writes have very different requirements — e.g., reads massively outnumber writes and need different shapes — so each side can be optimized and scaled independently."
- **Separate DBs?**: "No — CQRS is fundamentally about separate **models**, not necessarily separate stores. It's a spectrum: two models over one database (simplest), up to fully **separate write and read stores** synchronized via events (most scalable). I choose the level of separation the requirements justify."
- **Sync/consistency**: "The write side emits **events**; **projections** consume them to update read models. This makes read/write consistency **eventual** — the read side may briefly lag the write. I design for that: return the command result directly, use versioning/'read-your-writes' techniques where needed, and set UX expectations. Reliable projection (outbox/idempotency) is essential."
- **ES/DDD**: "CQRS pairs naturally with **Event Sourcing** — the event log is the write store and read models are projections rebuilt by replaying events — though CQRS doesn't require ES. It also fits **DDD**: aggregates live on the command side enforcing invariants, while the query side is a thin read model. Together (DDD + CQRS + ES + event-driven) they're a coherent toolkit for complex domains."
- **When not**: "For simple CRUD apps it's over-engineering — the added complexity and eventual consistency aren't worth it. I apply CQRS selectively to specific bounded contexts with real read/write asymmetry or complexity, not blanket across a system."

## 7. Common Mistakes
- Applying CQRS everywhere / to simple CRUD (over-engineering).
- Assuming it always needs separate databases + event sourcing.
- Ignoring eventual consistency in UX (users confused by read lag).
- Unreliable projections (no outbox/idempotency) → read/write drift.
- Putting business logic on the query side.

## 8. Trade-offs
| Aspect | Pro | Con |
|--------|-----|-----|
| Separate read/write | independent scale + optimization | complexity |
| Separate stores | fast tailored reads | sync + eventual consistency |
| + Event Sourcing | audit + rebuildable | more complexity |

## 9. Production Best Practices
- Apply selectively to bounded contexts with read/write asymmetry/complexity.
- Start simple (shared DB, two models); separate stores only when justified.
- Reliable projections (outbox + idempotent) + monitoring of read lag.
- Design UX for eventual consistency (return command result, read-your-writes).
- Pair with DDD (command-side aggregates); optionally Event Sourcing for audit.

## 10. Security Considerations
- Separate read/write permissions (command side stricter).
- Validate/enforce invariants on the command side only.
- Read models expose only needed fields (avoid leaking write-model internals).
- Reliable, auditable event flow for projections.

## 11. Cost Optimization
- Scale the read side (usual hotspot) independently — cheaper than scaling both.
- Cheap read stores (Redis/Cosmos) for hot queries; scale-to-zero write side if low write volume.
- Don't over-adopt (complexity = cost) — use only where it pays off.

## 12. Troubleshooting Scenarios
- **Read shows stale data** → eventual consistency lag; check projection pipeline/backlog.
- **Read/write drift** → projection failures/non-idempotent; add outbox + monitoring + replay.
- **Over-complex for the domain** → CQRS on simple CRUD; simplify.
- **Users confused by lag** → UX not designed for eventual consistency; add read-your-writes.
- **Slow reads despite CQRS** → read model not denormalized to the query shape.

## 13. Hands-on Example
```python
# Command side (write) vs Query side (read) — separate models
async def handle_place_order(cmd: PlaceOrder):           # COMMAND
    order = Order.create(cmd)          # aggregate enforces invariants
    await write_store.save(order)
    await publish("OrderPlaced", order.to_event())        # → updates read model

async def get_order_summary(order_id: str) -> dict:      # QUERY
    return await read_store.get(order_id)  # denormalized DTO, no business logic
```

## 14. Terraform Example
```hcl
# Separate write store (SQL, consistent) and read store (Cosmos, fast reads)
resource "azurerm_mssql_database" "write" { name = "orders-write" server_id = var.sql_id }
resource "azurerm_cosmosdb_sql_container" "read" {
  name = "order-summaries" account_name = var.cosmos_acct database_name = "reads"
  partition_key_paths = ["/customerId"]   # optimized for query shape
}
```

## 15. Azure Example
Azure CQRS: **command side** on Azure SQL (transactional writes + DDD aggregates), events via **Service Bus/Event Grid**, an **Azure Function** projecting into **Cosmos DB/Redis/Cognitive Search** read models; the **change feed** or outbox drives projections. Read APIs (behind APIM) scale independently from write APIs.

## 16. FastAPI / Python Example
```python
# Clean separation in the API: commands mutate, queries read (different endpoints/models)
@app.post("/orders")                       # COMMAND (write model)
async def place_order(cmd: PlaceOrder):
    oid = await command_bus.handle(cmd)     # validates + persists + emits event
    return {"order_id": oid}

@app.get("/orders/{oid}/summary")          # QUERY (read model, denormalized)
async def order_summary(oid: str):
    return await read_store.get(oid)        # fast, no domain logic
```

## 17. AKS Example
On AKS, deploy **command** and **query** services as separate Deployments scaled independently (query side gets many more replicas via HPA for read traffic). A projection worker (KEDA-scaled on event lag) updates the read store from write-side events; the read store (Redis/Cosmos) serves low-latency queries — write and read paths isolated and independently elastic.

## 18. How to Remember
**"Split writes (commands → aggregates/invariants) from reads (queries → denormalized DTOs); separate models (maybe separate stores) synced by events = eventual consistency; scale reads independently; pairs with DDD + Event Sourcing; not for simple CRUD."**

## 19. Real-World Analogy
A restaurant separating the kitchen from the menu display: the kitchen (command side) carefully prepares and controls every dish following strict recipes (invariants), while the front-of-house menu boards and photos (read models) are optimized purely for customers to browse quickly. Updates to the kitchen eventually refresh the displays. You can add more menu boards for a crowd (scale reads) without changing the kitchen.

## 20. One-Page Cheat Sheet
- **What**: separate **write model** (commands, enforce invariants) from **read model** (queries, view-optimized DTOs).
- **Spectrum**: two models / one DB → **separate write + read stores** synced via **events** → **eventual consistency**.
- **Sync**: write emits events → **projections** update read models (outbox + idempotent + monitor lag).
- **Pairs with**: **DDD** (command-side aggregates), **Event Sourcing** (log = write store), event-driven.
- **Benefits**: independent scaling (reads dominate), optimized models, security separation.
- **Avoid**: simple CRUD (over-engineering); apply selectively to asymmetric/complex bounded contexts.

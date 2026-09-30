# DEEP MECHANICS · CQRS

> 🧠 **Hook:** *Separate in/out doors* — writes go one way (commands), reads another (queries), each optimized independently.
>
> Level 2 — command/query separation, read/write models, consistency,
> event sourcing pairing, and when to use it.

---

## 0. The precise mental model
CQRS (**Command Query Responsibility Segregation**) **splits the write model from the read model**. Commands (change state, return nothing) go through one path; queries (return data, change nothing) through another — often with **separate data stores** optimized independently. It lets reads and writes **scale + model separately**, at the cost of **complexity + eventual consistency** between them.

---

## 1. The core split
- **Command** = intent to change state (`PlaceOrder`) → validated → mutates write model → returns ack/void.
- **Query** = request for data → reads a **read model** optimized for that view → no side effects.
- Different models for writing (normalized, invariant-enforcing) vs reading (denormalized, view-shaped).

## 2. Levels of CQRS
- **Light**: same DB, separate command/query code paths + separate DTOs.
- **Full**: **separate read + write stores** — write store (normalized/aggregate) + one or more **read stores** (denormalized, per-view, e.g., Cosmos/Redis/search index).
- More separation = more power + more complexity. Don't jump to full CQRS by default.

## 3. Synchronizing read & write
- After a write, the read model is updated — often **asynchronously** via **domain/integration events** → **eventual consistency** (read may briefly lag write).
- Projections/handlers build read models from events.
- Must design UX for eventual consistency (e.g., optimistic UI, read-your-writes tricks).

## 4. CQRS + Event Sourcing (common pairing, not required)
- **Event Sourcing**: persist state as an **append-only log of events** (not current state); rebuild state by replaying.
- Pairs naturally with CQRS: events are the write side; **projections** build read models.
- Benefits: full audit/history, temporal queries, rebuild read models anytime. Costs: versioning events, snapshots, complexity.
- **CQRS ≠ event sourcing** — you can do either alone.

## 5. Benefits & costs
- **Benefits**: independent **read/write scaling** (reads usually dominate), optimized models per side, security separation, fits complex domains + collaboration.
- **Costs**: more moving parts, eventual consistency, code duplication, harder debugging → **only where justified**.

## 6. When to use
- Use for: **read/write asymmetry**, complex domains (with DDD), high-scale reads, audit needs, collaborative/contended data.
- Avoid for: simple CRUD (adds needless complexity).

## 7. The hard follow-ups (with answers)
1. **"What does CQRS separate?"** → the **write model (commands)** from the **read model (queries)** — code and optionally storage. (§1)
2. **"Main downside?"** → complexity + **eventual consistency** between write and read stores. (§3/§5)
3. **"How do read models stay updated?"** → async via **events/projections** → eventually consistent. (§3)
4. **"Is event sourcing required?"** → no — they pair well but are independent. (§4)
5. **"Why bother?"** → reads/writes scale & model **independently** (read-heavy systems). (§5)
6. **"When NOT to use it?"** → simple CRUD — overhead outweighs benefit. (§6)
7. **"Full vs light CQRS?"** → light = same DB separate paths; full = separate read/write stores. (§2)

## 8. One-screen recall
- **Split writes (commands, mutate) from reads (queries, return)** — separate models, optionally separate stores.
- **Levels**: light (same DB, separate paths) → full (separate read/write stores, denormalized read views).
- **Sync**: async **events/projections** → **eventual consistency**.
- **+ Event Sourcing** (append-only event log, replay) pairs naturally but is optional.
- **Benefit**: independent read/write scaling + optimized models; **cost**: complexity + eventual consistency.
- Use for **read/write asymmetry + complex domains**, not simple CRUD.

> Next: API-First Design.

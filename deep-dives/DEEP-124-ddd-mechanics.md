# DEEP MECHANICS · Domain-Driven Design (DDD)

> Level 2 — ubiquitous language, bounded contexts, aggregates, and strategic vs
> tactical design.

---

## 0. The precise mental model
DDD tackles **complex business domains** by modeling software around the **domain**, in close collaboration with **domain experts**, using a shared **ubiquitous language**. Its biggest idea is **bounded contexts**: split a large model into **explicit boundaries** where terms have one precise meaning — this is also the natural way to find **microservice boundaries**.

---

## 1. Strategic design (the high-value part)
- **Ubiquitous language** — one shared vocabulary (experts + devs + code) per context → no translation loss; the language *is* the model.
- **Bounded Context** — an explicit boundary within which a model/term is consistent (e.g., "Customer" means different things in Sales vs Support → separate contexts).
- **Context Map** — how contexts relate/integrate: **Partnership, Shared Kernel, Customer-Supplier, Conformist, Anti-Corruption Layer (ACL), Open Host Service, Published Language**.
- **ACL** = translation layer protecting your model from an external/legacy model.

## 2. Subdomains
- **Core domain** (the competitive differentiator — invest most here), **Supporting** (needed but not special), **Generic** (buy/off-the-shelf, e.g., auth).
- Focus modeling effort on the **core domain**.

## 3. Tactical building blocks
- **Entity** — identity + lifecycle (same id = same thing even if attributes change).
- **Value Object** — defined by attributes, **immutable**, no identity (Money, Address).
- **Aggregate** — cluster of entities/VOs with an **Aggregate Root** as the only entry point; enforces **invariants** + is the **transactional consistency boundary**.
- **Domain Event** — something significant happened (past tense) → decouples contexts.
- **Repository** — collection-like persistence abstraction for aggregates.
- **Domain Service** — domain logic that doesn't belong to one entity.
- **Factory** — complex aggregate construction.

## 4. Aggregate design rules (commonly asked)
- **One aggregate = one transaction/consistency boundary**; keep aggregates **small**.
- Reference other aggregates **by id**, not object reference.
- Update **one aggregate per transaction**; cross-aggregate consistency = **eventual** via domain events.

## 5. DDD & microservices / architecture
- **Bounded context ≈ microservice boundary** → high cohesion, loose coupling, independent deployability.
- Pairs with **event-driven** (domain events), **CQRS**, **event sourcing**.

## 6. When (not) to use
- Worth it for **complex core domains**; overkill for simple CRUD (ceremony without payoff).

## 7. The hard follow-ups (with answers)
1. **"Most important DDD concept?"** → **bounded context** (+ ubiquitous language) — where a model/term is consistent. (§1)
2. **"What's an aggregate?"** → cluster with a root enforcing invariants; the **transactional consistency boundary**; keep small. (§3/§4)
3. **"Entity vs value object?"** → entity = identity + lifecycle; VO = immutable, attribute-defined, no identity. (§3)
4. **"How do aggregates stay consistent with each other?"** → one aggregate per tx; **eventual consistency via domain events**. (§4)
5. **"Protect from a legacy system's model?"** → **Anti-Corruption Layer**. (§1)
6. **"DDD ↔ microservices?"** → bounded contexts map to service boundaries. (§5)
7. **"Where to invest modeling effort?"** → the **core domain** (differentiator). (§2)
8. **"When not to use DDD?"** → simple CRUD apps (overhead > value). (§6)

## 8. One-screen recall
- **Model the domain** with experts via **ubiquitous language**.
- **Strategic**: **bounded contexts** (consistent meaning) + **context map** (ACL, conformist…); **core/supporting/generic** subdomains.
- **Tactical**: Entity (identity), **Value Object** (immutable), **Aggregate**(+root = **consistency boundary**, small), Domain Event, Repository, Domain Service, Factory.
- **Aggregate rules**: one per tx, reference by id, cross-aggregate = **eventual** via events.
- **Bounded context ≈ microservice**; pairs with event-driven/CQRS.
- Use for **complex core domains**, not simple CRUD.

> Next: CQRS.

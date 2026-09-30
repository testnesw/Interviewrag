# DEEP MECHANICS · SQLAlchemy

> Level 2 — Core vs ORM, session/unit-of-work, identity map, lazy loading &
> N+1, transactions, and async.

---

## 0. The precise mental model
SQLAlchemy has two layers: **Core** (SQL Expression Language — explicit, schema-centric) and the **ORM** (map classes ↔ tables). The ORM's engine is the **Session**, which implements the **Unit of Work**: it tracks object changes and **flushes** them as batched, ordered SQL inside a transaction. Understanding **identity map, lazy loading, and N+1** is what separates correct from slow code.

---

## 1. Core vs ORM
- **Core**: build SQL with Python expressions (`select(users).where(...)`) → close to SQL, great for bulk/analytics/complex queries.
- **ORM**: work with objects (`session.get(User, 1)`); changes tracked + persisted automatically.
- ORM is built on Core; you can drop to Core anytime.

## 2. Engine, connection, pool
- **Engine** = factory + **connection pool** (reuses TCP/auth connections → avoids per-query connect cost).
- Pool settings: `pool_size`, `max_overflow`, `pool_pre_ping` (detect dead conns), `pool_recycle`.

## 3. Session = Unit of Work
- Tracks **new / dirty / deleted** objects.
- **Flush** = emit SQL (auto before queries or on commit); **commit** = flush + COMMIT; **rollback** on error.
- **Identity map**: one object per PK per session → `session.get(User,1)` twice returns the *same* instance (dedup + consistency).
- Lifecycle states: **transient → pending → persistent → detached**.

## 4. Lazy loading & the N+1 problem
- **Lazy** (default): related collection loaded on first access → looping over N parents triggers **N extra queries** (the **N+1 problem**).
- Fixes:
  - **`selectinload`** — separate `IN` query for children (great for collections).
  - **`joinedload`** — single JOIN (good for many-to-one/one-to-one).
  - Set relationship `lazy=` strategy appropriately.
- Always suspect N+1 when a loop over ORM objects is slow.

## 5. Transactions
- Session works within a transaction; `commit()`/`rollback()`.
- Context manager: `with Session() as s, s.begin(): ...` → auto commit/rollback.
- Isolation handled by the DB; use `with_for_update()` for pessimistic locks; **version_id** column for optimistic concurrency.

## 6. Async (2.0)
```python
async with AsyncSession(engine) as s:
    r = await s.execute(select(User).where(User.id==1))
```
- `create_async_engine` + `AsyncSession`; requires an **async driver** (asyncpg/aiomysql).
- **No implicit lazy loading** in async (would need hidden I/O) → must **eager-load** (`selectinload`) or use `AsyncAttrs`.

## 7. Migrations
- **Alembic** = schema migration tool (autogenerate diffs from models → versioned upgrade/downgrade scripts).

## 8. The hard follow-ups (with answers)
1. **"Core vs ORM?"** → Core = explicit SQL expressions; ORM = object mapping + change tracking (built on Core). (§1)
2. **"What is the Session?"** → Unit of Work: tracks changes, flushes batched SQL in a transaction; holds identity map. (§3)
3. **"What's the identity map?"** → one object per PK per session → same instance returned, ensures consistency. (§3)
4. **"N+1 problem + fix?"** → lazy loading fires 1 query per parent in a loop → use **selectinload/joinedload** (eager). (§4)
5. **"joinedload vs selectinload?"** → joinedload = single JOIN (to-one); selectinload = separate IN query (collections, avoids row explosion). (§4)
6. **"Async gotcha?"** → no implicit lazy load → must eager-load relationships. (§6)
7. **"Migrations?"** → **Alembic** (autogenerate + versioned scripts). (§7)

## 9. One-screen recall
- **Two layers**: Core (SQL expressions) + ORM (objects); ORM on Core.
- **Engine** = pooled connection factory (`pool_pre_ping`, recycle).
- **Session = Unit of Work**: new/dirty/deleted → **flush** (SQL) → **commit**; **identity map** (1 obj/PK).
- **N+1**: lazy default → loop = N queries → fix **selectinload** (collections) / **joinedload** (to-one).
- **Tx**: `begin()` context; `with_for_update` (pessimistic), version_id (optimistic).
- **Async**: `AsyncSession` + async driver, **must eager-load**.
- **Migrations**: **Alembic**.

> Next: Performance optimization.

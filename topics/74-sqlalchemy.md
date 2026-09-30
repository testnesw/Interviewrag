# 74 · SQLAlchemy

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
SQLAlchemy is Python's most popular way to talk to relational databases. It lets you work with database rows as Python objects (ORM) instead of writing raw SQL for everything, while still allowing raw SQL when you need it.

## 2. Architect-Level Explanation
SQLAlchemy has two layers — Core (SQL expression) and ORM (object mapping):
- **Core**: a SQL expression language / connection + pooling layer.
- **ORM**: maps classes to tables; `Session` is a unit-of-work tracking changes and flushing them.
- **2.0 style**: unified `select()` API; **async** via `AsyncSession` + async drivers (asyncpg for PostgreSQL).
- **Engine + pool**: connection pooling (size, overflow, recycle, pre-ping) — critical for scaling.
- **Session lifecycle**: per-request session (via DI `yield`), commit/rollback, then close.
- **Migrations**: **Alembic** for schema versioning/migrations.
- **Performance**: eager vs lazy loading (avoid N+1 with `selectinload`/`joinedload`), batching, indexing, streaming.
- **Async caveat**: lazy loading doesn't work transparently in async → load relationships explicitly.

## 3. Real Enterprise Use Case
A FastAPI service uses async SQLAlchemy 2.0 with asyncpg against Azure Database for PostgreSQL: per-request `AsyncSession` via DI, a tuned connection pool sized to pod count, `selectinload` to avoid N+1 on order→items, and Alembic migrations run in a CI/CD job before rollout.

## 4. Architecture Diagram (ASCII)
```
   FastAPI handler ─ Depends(get_db) ─► AsyncSession (per request)
        │ unit of work (track changes)
   Engine + Connection Pool (size/overflow/recycle/pre-ping)
        │ async driver (asyncpg)
   Azure Database for PostgreSQL (private endpoint)
   Alembic migrations ─► schema versioning (CI job)
   Avoid N+1: selectinload/joinedload | index hot queries
```

## 5. Interview Questions
1. Core vs ORM; when to use each?
2. What is the Session / unit of work?
3. How do you use async SQLAlchemy correctly?
4. What is the N+1 problem and how do you fix it?
5. How do you handle schema migrations?

## 6. Strong Interview Answers
- **Core vs ORM**: "Core is a SQL expression + connection layer; ORM maps objects to rows with change tracking. I use the ORM for most CRUD/domain logic and drop to Core/raw SQL for complex analytical queries or bulk operations where the ORM adds overhead."
- **Session**: "The Session is a unit of work — it tracks object changes and flushes them as SQL on commit, managing identity and transactions. In web apps I scope one session per request and always commit/rollback + close."
- **Async**: "Use `AsyncSession` with an async driver (asyncpg), `await` all DB ops, and load relationships explicitly (`selectinload`) since lazy loading isn't transparent in async. Sessions aren't shared across tasks."
- **N+1**: "Lazy-loading a relationship in a loop fires one query per row. I fix it with eager loading — `selectinload` (separate IN query) or `joinedload` (JOIN) — turning N+1 into 1–2 queries."
- **Migrations**: "Alembic autogenerates and versions migrations; I review the generated scripts, run them in CI/CD before app rollout, and make them backward-compatible for zero-downtime deploys."

## 7. Common Mistakes
- Lazy loading in async (fails / N+1).
- Sharing a session across requests/tasks.
- No connection pool tuning (exhaustion under scale).
- Forgetting commit/rollback/close.
- Manual schema changes instead of Alembic.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| ORM | productivity, safety | overhead, N+1 traps |
| Core/raw SQL | performance, control | more code |
| joinedload vs selectinload | 1 query / no dup rows | wide rows / extra query |

## 9. Production Best Practices
- Async 2.0 style; per-request session via DI.
- Tune pool (size, max_overflow, pool_recycle, pool_pre_ping).
- Eager-load to avoid N+1; index hot queries.
- Alembic migrations in CI/CD; backward-compatible.
- Handle transactions explicitly; retry transient errors.

## 10. Security Considerations
- Parameterized queries (ORM/Core) → prevents SQL injection.
- Least-privilege DB credentials via Key Vault/Workload Identity.
- Private endpoint to the database (no public).
- Avoid logging queries with sensitive values.

## 11. Cost Optimization
- Right-sized pool → fewer DB connections (managed DB cost).
- Efficient queries/indexes reduce DB compute.
- Batch operations; avoid N+1 chatter.

## 12. Troubleshooting Scenarios
- **N+1 / slow lists** → add eager loading + indexes.
- **Pool exhausted / timeouts** → tune pool size vs pods; leaked sessions.
- **Async lazy-load error** → load relationships explicitly.
- **Stale connections** → enable `pool_pre_ping`/`pool_recycle`.
- **Migration failure** → review Alembic script; ensure backward compatibility.

## 13. Hands-on Example
```bash
alembic revision --autogenerate -m "add orders table"
alembic upgrade head
```

## 14. Terraform Example
```hcl
resource "azurerm_postgresql_flexible_server" "db" {
  name = "pg-app" resource_group_name = var.rg location = "eastus"
  version = "16" sku_name = "GP_Standard_D2s_v3"
  storage_mb = 32768 zone = "1"
  authentication { active_directory_auth_enabled = true }
  public_network_access_enabled = false     # private endpoint
}
```

## 15. Azure Example
Connect async SQLAlchemy to Azure Database for PostgreSQL using **Entra ID token auth** (Workload Identity) instead of a password — the driver uses a rotating token, no static DB credentials stored.

## 16. FastAPI / Python Example
```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

engine = create_async_engine(DB_URL, pool_size=10, max_overflow=5,
                             pool_pre_ping=True, pool_recycle=1800)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def get_db() -> AsyncSession:
    async with SessionLocal() as s:
        yield s

@app.get("/orders/{oid}")
async def get_order(oid: int, db: AsyncSession = Depends(get_db)):
    stmt = select(Order).where(Order.id == oid).options(selectinload(Order.items))
    return (await db.execute(stmt)).scalar_one()   # no N+1
```

## 17. AKS Example
Total DB connections = pool_size × number of pods. When HPA scales pods, tune pool_size so peak pods stay within the PostgreSQL connection limit (or front with PgBouncer) — preventing connection exhaustion during scale-out.

## 18. How to Remember
**"ORM = objects + unit-of-work Session; async needs explicit loading; Alembic for migrations; kill N+1 with eager loading."**

## 19. Real-World Analogy
A diligent personal assistant (Session) who notes every change you make to documents (objects) during a meeting and files them all at once when you say "done" (commit) — and knows to fetch related folders in advance (eager loading) instead of running back to the archive for each one (N+1).

## 20. One-Page Cheat Sheet
- **Layers**: Core (SQL expression + pooling) + ORM (objects, `Session` unit of work).
- **2.0 async**: `AsyncSession` + asyncpg; `await` everything; load relationships explicitly.
- **Pool**: size/max_overflow/pool_recycle/pool_pre_ping; connections = pool × pods.
- **N+1**: fix with `selectinload`/`joinedload` + indexes.
- **Migrations**: Alembic, reviewed, in CI/CD, backward-compatible.
- **Secure**: parameterized queries, Entra ID/Key Vault creds, private endpoint.

# DEEP MECHANICS · Azure Databricks

> Level 2 — the lakehouse platform: Delta Lake internals, Unity Catalog, clusters/
> photon, workflows, and how it unifies data engineering + ML.

---

## 0. The precise mental model
Databricks = a **managed Spark + lakehouse platform** that unifies **data engineering, analytics, and ML** on one governed copy of data in the lake. Its two pillars: **Delta Lake** (ACID tables on cheap object storage) and **Unity Catalog** (unified governance). It turns a raw data lake into a reliable, governed, warehouse-grade system.

---

## 1. Delta Lake internals (the core tech)
Delta = **Parquet data files + a transaction log** (`_delta_log`, ordered JSON commits):
- **ACID transactions** — the log is the source of truth; readers see a consistent snapshot; concurrent writes use optimistic concurrency.
- **Time travel** — query old versions (`VERSION AS OF`) via the log.
- **MERGE/UPSERT/DELETE** — mutate lake data (impossible with plain Parquet) → CDC, GDPR deletes.
- **Schema enforcement + evolution.**
- **OPTIMIZE + Z-ORDER** — compact small files + co-locate data by column → faster queries. **VACUUM** removes old files.

## 2. Unity Catalog (governance)
Centralized governance across workspaces: **three-level namespace** `catalog.schema.table`, fine-grained access control, **data lineage**, auditing, and discovery. One place to govern data + ML assets → enterprise-grade security.

## 3. Compute
- **Clusters** — Spark clusters (all-purpose for interactive, **job clusters** for scheduled jobs — cheaper, ephemeral).
- **Photon** — vectorized C++ engine → much faster SQL/DataFrame execution.
- **SQL Warehouses** — for BI/SQL analytics.
- **Autoscaling + auto-termination** → cost control.
- **Serverless** options remove cluster management.

## 4. Workflows & DLT
- **Workflows/Jobs** — orchestrate multi-task pipelines (notebooks, scripts, dbt).
- **Delta Live Tables (DLT)** — declarative pipelines with built-in data quality (expectations), auto-managed dependencies + medallion layers.

## 5. ML on Databricks
Managed **MLflow** (tracking/registry), feature store, model serving, and collaborative notebooks — data eng + ML on one platform, no data movement.

## 6. Why it wins (the pitch)
One governed copy of data (lakehouse) serves BI + ML; Delta gives warehouse reliability on lake economics; Unity Catalog gives governance; Spark/Photon gives scale. Eliminates copying between lake and warehouse.

## 7. The hard follow-ups (with answers)
1. **"What makes Delta ACID on a lake?"** → transaction log (`_delta_log`) + optimistic concurrency → consistent snapshots, MERGE, time travel. (§1)
2. **"Optimize Delta query performance?"** → OPTIMIZE (compaction) + Z-ORDER + VACUUM; partition pruning. (§1)
3. **"What's Unity Catalog?"** → central governance: catalog.schema.table, access control, lineage, audit across workspaces. (§2)
4. **"All-purpose vs job cluster?"** → interactive shared vs ephemeral per-job (cheaper). Photon speeds execution. (§3)
5. **"What's DLT?"** → declarative pipelines with data-quality expectations + managed dependencies/medallion. (§4)
6. **"Why lakehouse over lake+warehouse?"** → one governed copy for BI+ML, warehouse reliability on lake cost, no ETL copies. (§6)

## 8. One-screen recall
- Databricks = managed **Spark + lakehouse**, unifies data eng + analytics + ML on one governed copy.
- **Delta Lake** = Parquet + **transaction log** → **ACID**, **time travel**, **MERGE/DELETE**, schema enforce/evolve; **OPTIMIZE/Z-ORDER/VACUUM** for perf.
- **Unity Catalog** = central governance (`catalog.schema.table`, ACL, **lineage**, audit).
- **Compute**: all-purpose vs **job clusters**, **Photon** (vectorized engine), SQL Warehouses, autoscale/auto-terminate, serverless.
- **Workflows + DLT** (declarative, data-quality expectations, medallion).
- Managed **MLflow** + feature store + serving → ML without data movement.

> Next: Azure Storage.

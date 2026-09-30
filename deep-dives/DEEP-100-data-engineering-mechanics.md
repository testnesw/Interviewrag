# DEEP MECHANICS · Data Engineering

> Level 2 — batch vs streaming, ETL vs ELT, the medallion architecture, data
> lake vs warehouse vs lakehouse, and partitioning/file formats.

---

## 0. The precise mental model
Data engineering = **building reliable pipelines that move and shape data** from sources into forms usable for analytics/ML. The core decisions are **batch vs streaming**, **ETL vs ELT**, **where data lands** (lake/warehouse/lakehouse), and **how it's organized** (partitioning, formats, medallion layers) for cost and query performance.

---

## 1. Batch vs streaming
- **Batch** — process bounded chunks on a schedule (nightly ETL). Simple, high-throughput, higher latency. Tools: ADF, Spark/Databricks.
- **Streaming** — process unbounded events in near-real-time (Event Hubs → Stream Analytics/Spark Structured Streaming). Low latency, more complex (windowing, late data, exactly-once).
- **Lambda/Kappa** architectures combine/unify them.

## 2. ETL vs ELT
- **ETL** — transform **before** loading (classic warehouse). Good when target is rigid/expensive.
- **ELT** — load raw first, transform **in** the powerful target (lake/warehouse compute). Modern default — cheap storage, scalable compute, keep raw for reprocessing.

## 3. Lake vs Warehouse vs Lakehouse
| | **Data Lake** | **Data Warehouse** | **Lakehouse** |
|---|---|---|---|
| Data | raw, any format | structured, modeled | raw+structured on the lake |
| Schema | on read | on write | on read + ACID tables |
| Cost | cheap storage | pricier | cheap storage + warehouse features |
| Tech | ADLS Gen2 | Synapse/SQL DW | **Databricks Delta**, Synapse |
Lakehouse = lake economics + warehouse reliability (**ACID via Delta/Parquet**).

## 4. Medallion architecture (Bronze/Silver/Gold)
```
Bronze → raw ingested data (immutable, as-is)
Silver → cleaned, deduped, conformed, joined
Gold   → business-level aggregates / features for BI & ML
```
Progressive refinement; each layer is queryable and reprocessable. Standard on Databricks/lakehouse.

## 5. File formats & partitioning (performance/cost)
- **Parquet** — columnar, compressed → fast analytics, cheap scans (read only needed columns). Default for analytics.
- **Delta** — Parquet + transaction log → ACID, time travel, upserts (MERGE).
- **Avro/JSON** — row-based, for streaming/ingestion.
- **Partitioning** — split data by column (date/region) → **partition pruning** skips irrelevant files → big cost/perf win. Avoid too many tiny files (small-file problem → compaction).

## 6. Pipeline concerns
Idempotency, incremental loads (watermarks/CDC), schema evolution, data quality checks, orchestration (ADF/Airflow/Databricks Workflows), lineage/catalog (Purview/Unity Catalog).

## 7. The hard follow-ups (with answers)
1. **"ETL vs ELT?"** → transform before vs after load; ELT modern (cheap storage, scalable compute, keep raw). (§2)
2. **"Lake vs warehouse vs lakehouse?"** → raw/schema-on-read vs modeled/schema-on-write vs both with ACID (Delta). (§3)
3. **"Medallion layers?"** → Bronze(raw)→Silver(clean)→Gold(aggregate/features). (§4)
4. **"Why Parquet + partitioning?"** → columnar compressed + partition pruning → scan less → faster/cheaper. (§5)
5. **"Batch vs streaming?"** → scheduled bounded vs real-time unbounded (windowing/late data). (§1)
6. **"Small-file problem?"** → too many tiny files kill performance → compaction/optimize. (§5)

## 8. One-screen recall
- Data eng = reliable pipelines source→usable. Decisions: batch/stream, ETL/ELT, landing zone, organization.
- **Batch** (scheduled, high-throughput) vs **streaming** (real-time, windowing/late data).
- **ELT** (load raw, transform in target) is modern default; keep raw for reprocess.
- **Lake** (raw, schema-on-read) / **Warehouse** (modeled, schema-on-write) / **Lakehouse** (both + **ACID Delta**).
- **Medallion**: Bronze(raw)→Silver(clean)→Gold(aggregate/features).
- **Parquet** (columnar) / **Delta** (ACID+time-travel) / Avro-JSON (row/stream); **partition pruning** = cost/perf; avoid small files.

> Next: Databricks.

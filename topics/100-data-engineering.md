# 100 · Data Engineering

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Data engineering is the practice of **building the pipelines and systems that move, clean, and organize data** so analysts, dashboards, and ML models can use it reliably. Data engineers make raw data trustworthy and available.

## 2. Architect-Level Explanation
Designing reliable, scalable data platforms end to end:
- **Pipelines**: **ETL** (transform before load) vs **ELT** (load raw, transform in the warehouse/lake — modern default with cloud compute).
- **Ingestion**: batch (scheduled), **streaming** (Event Hubs/Kafka), **CDC** (change data capture), API pulls. Orchestration via **Azure Data Factory / Synapse Pipelines / Fabric / Airflow**.
- **Storage/modeling**: data lake (ADLS Gen2) + **lakehouse** (Delta) + warehouse (Synapse/Fabric); **medallion** (Bronze/Silver/Gold); dimensional modeling (star schema, facts/dims), SCD.
- **Processing**: Spark/Databricks, SQL, dbt-style transformations.
- **Data quality**: validation, deduplication, schema enforcement/evolution, expectations, reconciliation.
- **Governance**: catalog + lineage (Purview/Unity Catalog), classification, access control, **data contracts**, master data.
- **Orchestration/scheduling**: DAGs, dependencies, retries, backfills, idempotent + incremental loads, watermarking.
- **Observability**: freshness, volume, schema, distribution, lineage — **data observability**; SLAs/SLOs.
- **Patterns**: idempotency, incremental/CDC, slowly changing dimensions, partitioning, late-arriving data, exactly-once via checkpoints.
- **Reliability**: DataOps/CI-CD, testing, monitoring, cost governance.

## 3. Real Enterprise Use Case
A retail data platform ingests transactions via **CDC** and clickstream via **Event Hubs** into Bronze, Databricks/Spark cleans and conforms to Silver, builds Gold star-schema marts (dimensional model with SCD Type 2) for BI + ML features, **Data Factory** orchestrates dependencies with retries/backfills, **Unity Catalog/Purview** governs lineage + access, and data-quality checks + freshness SLAs gate publishing to dashboards.

## 4. Architecture Diagram (ASCII)
```
   Sources (DBs/APIs/events) ─► Ingestion (batch│stream│CDC)
        │  orchestrated by ADF/Synapse/Fabric/Airflow (DAG, retries, backfill)
   Bronze (raw) ─► Silver (clean/conform) ─► Gold (marts/features)  [medallion]
        │  Spark/SQL/dbt transforms + data-quality checks
   Warehouse/Lakehouse (Delta) ─► BI (Power BI) · ML · reverse-ETL
   Governance: catalog + lineage + contracts | Observability: freshness/volume/schema
```

## 5. Interview Questions
1. ETL vs ELT — when each?
2. How do you design an ingestion strategy (batch/stream/CDC)?
3. What is the medallion architecture and dimensional modeling?
4. How do you ensure data quality and idempotent/incremental loads?
5. How do you handle governance, lineage, and observability?

## 6. Strong Interview Answers
- **ETL vs ELT**: "ETL transforms before loading (good when the target is expensive or transformations must happen pre-load). **ELT** loads raw first, then transforms using scalable cloud compute (Spark/warehouse) — the modern default because storage is cheap, it preserves raw data for reprocessing, and it decouples ingestion from transformation."
- **Ingestion**: "I match method to need — batch for periodic bulk, streaming (Event Hubs/Kafka) for real-time, and **CDC** to capture DB changes incrementally without full reloads. I make loads **incremental** (watermarks/high-water marks) and **idempotent** so re-runs don't duplicate data."
- **Medallion/modeling**: "Medallion layers data by quality — Bronze (raw/immutable), Silver (cleansed/conformed/deduped), Gold (curated business marts). For serving, I use dimensional models — star schemas with fact and dimension tables, and **SCD Type 2** to track history — optimized for BI queries."
- **Quality/idempotency**: "I enforce schema, validate with expectations (nulls, ranges, uniqueness, referential integrity), dedupe, and reconcile counts. Loads are idempotent (MERGE/upsert keyed by business key + partition overwrite) and incremental with watermarks, handling late-arriving and out-of-order data with checkpoints."
- **Governance/observability**: "A catalog (Unity Catalog/Purview) for discovery, automated **lineage**, classification, and access control, plus **data contracts** between producers and consumers. **Data observability** monitors freshness, volume, schema drift, and distribution against SLAs so I catch broken pipelines before consumers do."

## 7. Common Mistakes
- Non-idempotent pipelines → duplicates on retry/backfill.
- Full reloads where CDC/incremental would do (cost/time).
- No data-quality gates → bad data reaches dashboards/ML.
- No lineage/catalog → "where did this number come from?".
- Tight coupling / no data contracts → breaking schema changes.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| ELT | flexible, keeps raw | transform cost in target |
| Streaming | real-time | complexity, exactly-once effort |
| SCD2 | full history | storage + complexity |

## 9. Production Best Practices
- ELT + medallion + lakehouse (Delta); incremental/CDC + idempotent MERGE.
- Data-quality gates + reconciliation before publishing.
- Orchestrate with retries/backfills; watermarking for late data.
- Governance: catalog, lineage, contracts, classification.
- Data observability + SLAs; DataOps CI/CD + testing; cost tagging.

## 10. Security Considerations
- Least-privilege access per zone (ACLs, RBAC); Managed Identity.
- PII classification + masking/tokenization; encryption in transit + at rest.
- Private networking; audit + lineage for compliance (GDPR).
- Secrets in Key Vault; data contracts enforce boundaries.

## 11. Cost Optimization
- ELT with scalable compute + auto-terminate; incremental over full loads.
- Tier/lifecycle raw data; columnar formats + partition pruning.
- Right-size clusters/warehouses; spot; monitor per-pipeline cost.

## 12. Troubleshooting Scenarios
- **Duplicate rows** → non-idempotent load; use MERGE/keyed upsert.
- **Stale dashboards** → pipeline freshness SLA breached; check orchestration/failures.
- **Schema drift breaks job** → enforce schema + contracts + evolution strategy.
- **Late/out-of-order data** → watermarking + reprocessing window.
- **Slow/expensive job** → full reload; switch to incremental/CDC + partitioning.

## 13. Hands-on Example
```python
# Idempotent incremental load with Delta MERGE + watermark
from delta.tables import DeltaTable
new = spark.read.parquet(src).where(f"updated_at > '{last_watermark}'")   # incremental
tgt = DeltaTable.forName(spark, "silver.customers")
(tgt.alias("t").merge(new.alias("s"), "t.id = s.id")   # idempotent upsert
   .whenMatchedUpdateAll().whenNotMatchedInsertAll().execute())
```

## 14. Terraform Example
```hcl
resource "azurerm_data_factory" "adf" {
  name = "adf-prod" resource_group_name = var.rg location = "eastus"
  identity { type = "SystemAssigned" }        # Managed Identity to sources/sinks
}
resource "azurerm_data_factory_pipeline" "ingest" {
  name = "ingest-orders" data_factory_id = azurerm_data_factory.adf.id
}
```

## 15. Azure Example
Azure stack: **Data Factory / Fabric Data Pipelines** (orchestration + CDC), **Event Hubs** (streaming), **ADLS Gen2** (lake), **Databricks/Synapse/Fabric** (transform), **Synapse/Fabric Warehouse** (serve), **Purview/Unity Catalog** (governance), **Power BI** (BI) — all with Managed Identity + private endpoints.

## 16. FastAPI / Python Example
```python
# API triggers a pipeline run and exposes data-quality/freshness status
@app.post("/pipelines/{name}/run")
async def run_pipeline(name: str):
    run_id = await adf_client.pipelines.create_run("adf-prod", name)
    return {"run_id": run_id.run_id}

@app.get("/datasets/{name}/health")
async def health(name: str):
    return {"freshness_minutes": await freshness(name), "row_count": await volume(name)}
```

## 17. AKS Example
AKS can host **Airflow** (orchestration), Spark jobs (Spark Operator), and dbt runners for a Kubernetes-native data platform — pipelines as pods scaled by the autoscaler, reading/writing ADLS Gen2 with Workload Identity, while heavy analytics offloads to Databricks/Synapse.

## 18. How to Remember
**"Ingest (batch/stream/CDC) → medallion (Bronze/Silver/Gold) → serve; ELT + idempotent incremental MERGE; quality gates + governance/lineage + observability."**

## 19. Real-World Analogy
A water utility: it collects water from many sources (ingestion), runs it through progressive treatment stages — settling, filtering, purifying (Bronze→Silver→Gold) — tests quality at each stage (data quality), tracks where every drop came from (lineage), and only then pipes clean water to homes (dashboards/ML). A broken stage is caught before it reaches taps (observability).

## 20. One-Page Cheat Sheet
- **What**: build reliable pipelines that make data trustworthy + available.
- **Pattern**: **ELT** + **medallion** (Bronze/Silver/Gold) on a lakehouse (Delta).
- **Ingest**: batch / streaming (Event Hubs) / **CDC**; incremental + **idempotent** (MERGE) + watermarks.
- **Model**: dimensional (star schema, facts/dims, SCD2) for serving.
- **Trust**: data-quality gates, **governance** (catalog + lineage + contracts), **observability** (freshness/volume/schema).
- **Azure**: Data Factory/Fabric, Event Hubs, ADLS Gen2, Databricks/Synapse, Purview; Managed Identity.

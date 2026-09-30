# 98 · Azure Databricks

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Azure Databricks is a **cloud analytics platform built on Apache Spark**. It gives data engineers and scientists collaborative notebooks and powerful clusters to process huge datasets, build data pipelines, and train machine-learning models — all managed.

## 2. Architect-Level Explanation
A managed **lakehouse** platform (Spark + Delta Lake) with Azure integration:
- **Lakehouse**: combines data-lake scale (ADLS Gen2) with data-warehouse reliability via **Delta Lake** (ACID transactions, schema enforcement, time travel, upserts/MERGE).
- **Compute**: **clusters** (all-purpose interactive vs job clusters), **SQL warehouses** (serverless SQL), **pools** (warm instances), **Photon** (vectorized C++ engine for speed), autoscaling + auto-termination.
- **Unity Catalog**: centralized **governance** — data catalog, fine-grained access control, lineage, audit, across workspaces (three-level namespace catalog.schema.table).
- **Medallion architecture**: Bronze/Silver/Gold Delta layers.
- **Workloads**: ETL/ELT pipelines (**Delta Live Tables / Lakeflow**), streaming (Structured Streaming), SQL analytics/BI, ML (MLflow, feature store), GenAI.
- **Integration**: ADLS Gen2, Event Hubs/Kafka, Azure ML, Power BI, Synapse/Fabric; Entra ID SSO; Managed Identity/credential passthrough.
- **Architecture**: **control plane** (Databricks-managed) + **compute/data plane** (in your Azure subscription/VNet — VNet injection, private endpoints, no public compute).
- **Cost**: **DBU** (Databricks Unit) + underlying VM; spot instances, autoscaling, serverless.

## 3. Real Enterprise Use Case
An enterprise builds a lakehouse: **Delta Live Tables** ingest streaming + batch into Bronze, transform to Silver/Gold Delta tables on ADLS Gen2, **Unity Catalog** governs access + lineage across teams, **Photon-accelerated SQL warehouses** power Power BI dashboards, and MLflow trains/serves models on the same governed data — with VNet injection and Managed Identity, autoscaling clusters with spot VMs for cost.

## 4. Architecture Diagram (ASCII)
```
   Control Plane (Databricks-managed: notebooks, jobs, UI)
        │  orchestrates
   Compute/Data Plane (YOUR VNet: clusters, SQL warehouses, Photon)
        │  reads/writes Delta
   ADLS Gen2:  Bronze ─► Silver ─► Gold   (medallion, Delta ACID)
   Governance: Unity Catalog (catalog.schema.table, lineage, ACLs)
   Sources: Event Hubs/Kafka · ML: MLflow · BI: Power BI · Entra ID SSO
```

## 5. Interview Questions
1. What is the lakehouse and how does Delta Lake enable it?
2. Explain the control plane vs data plane.
3. What does Unity Catalog provide?
4. Cluster types and Photon?
5. How do you optimize Databricks cost/performance?

## 6. Strong Interview Answers
- **Lakehouse/Delta**: "The lakehouse unifies the cheap scale of a data lake with warehouse reliability. **Delta Lake** is the enabler — a transaction log over Parquet giving ACID transactions, schema enforcement/evolution, time travel, and efficient upserts/MERGE — so I get warehouse-grade correctness directly on the lake, no separate warehouse copy."
- **Control vs data plane**: "The control plane (notebooks, job scheduling, UI, metadata) is Databricks-managed. The compute/data plane runs in **my Azure subscription and VNet** — clusters process my data in place. This keeps data in my tenant, supports VNet injection + private endpoints, and means my data never leaves my control."
- **Unity Catalog**: "Centralized governance across workspaces — a three-level namespace (catalog.schema.table), fine-grained access control, automated **lineage**, auditing, and data discovery. It replaces per-workspace hive metastores with one governed, consistent security + catalog layer."
- **Clusters/Photon**: "All-purpose clusters for interactive/collaborative work, job clusters (ephemeral, per-job, cheaper) for scheduled pipelines, and serverless SQL warehouses for BI. **Photon** is a vectorized native engine that dramatically speeds SQL/DataFrame workloads. I add pools for warm start and autoscaling + auto-termination to save cost."
- **Optimize**: "Job clusters + auto-termination + spot instances, autoscaling, Photon, Delta optimizations (OPTIMIZE/Z-ORDER, file compaction, partitioning), caching, and right-sizing. Serverless where it fits. Monitor DBU consumption."

## 7. Common Mistakes
- All-purpose clusters for scheduled jobs (should use job clusters).
- No auto-termination → idle clusters burn cost.
- Small-file problem / no OPTIMIZE on Delta.
- Skipping Unity Catalog governance/lineage.
- Public compute plane (no VNet injection).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Job cluster | cheap, isolated | cold start |
| Serverless SQL | instant, managed | less control |
| Spot VMs | cheap | eviction risk |

## 9. Production Best Practices
- Job clusters + auto-termination + spot; pools for warm start.
- Delta + medallion; OPTIMIZE/Z-ORDER + compaction; partitioning.
- Unity Catalog governance, lineage, ACLs (Entra ID groups).
- VNet injection + private endpoints + Managed Identity.
- Delta Live Tables / Lakeflow for declarative reliable pipelines; CI/CD notebooks.

## 10. Security Considerations
- Entra ID SSO + SCIM; Unity Catalog fine-grained ACLs.
- VNet injection, private endpoints, no public compute; secrets in Key Vault-backed scopes.
- Managed Identity/credential passthrough to ADLS (no keys).
- Audit logs; data classification/masking.

## 11. Cost Optimization
- Job clusters, autoscaling, auto-terminate, spot instances.
- Photon + Delta optimizations reduce runtime = fewer DBUs.
- Serverless for bursty SQL; right-size; monitor DBU + tag by team.

## 12. Troubleshooting Scenarios
- **Slow jobs** → small files; run OPTIMIZE/compaction; enable Photon.
- **Runaway cost** → idle all-purpose clusters; enforce auto-terminate/job clusters.
- **Access denied** → Unity Catalog grants / storage credential misconfig.
- **Spot evictions** → mix on-demand for driver; retry.
- **Skew/OOM** → data skew; repartition/salt keys.

## 13. Hands-on Example
```python
# Delta MERGE (upsert) — warehouse-style correctness on the lake
from delta.tables import DeltaTable
tgt = DeltaTable.forName(spark, "gold.customers")
(tgt.alias("t").merge(updates.alias("s"), "t.id = s.id")
   .whenMatchedUpdateAll().whenNotMatchedInsertAll().execute())
spark.sql("OPTIMIZE gold.customers ZORDER BY (region)")   # performance
```

## 14. Terraform Example
```hcl
resource "azurerm_databricks_workspace" "dbx" {
  name = "dbx-prod" resource_group_name = var.rg location = "eastus"
  sku = "premium"
  custom_parameters {                          # VNet injection (secure cluster)
    virtual_network_id  = azurerm_virtual_network.vnet.id
    private_subnet_name = azurerm_subnet.dbx_private.name
    public_subnet_name  = azurerm_subnet.dbx_public.name
  }
}
```

## 15. Azure Example
```python
# Structured Streaming from Event Hubs into a Bronze Delta table
(spark.readStream.format("eventhubs").options(**eh_conf).load()
   .writeStream.format("delta").option("checkpointLocation", chk)
   .toTable("bronze.events"))
```

## 16. FastAPI / Python Example
```python
# App queries a Databricks SQL Warehouse (Gold) via the SQL connector
from databricks import sql
def top_products():
    with sql.connect(server_hostname=HOST, http_path=WAREHOUSE_PATH,
                     access_token=token) as conn:          # Entra ID token
        with conn.cursor() as cur:
            cur.execute("SELECT name, sales FROM gold.product_sales ORDER BY sales DESC LIMIT 10")
            return cur.fetchall()
```

## 17. AKS Example
While Databricks manages its own compute, downstream AKS microservices consume **Gold** Delta tables via Databricks SQL warehouses (JDBC/connector) or read curated Parquet/Delta from ADLS Gen2 with Workload Identity — separating heavy analytics (Databricks) from serving (AKS) while sharing one governed lakehouse.

## 18. How to Remember
**"Managed Spark + Delta = lakehouse; control plane (theirs) + data plane (yours/VNet); Unity Catalog governs; Photon speeds; job clusters + spot + auto-terminate save cost."**

## 19. Real-World Analogy
A high-tech shared research lab (control plane = the institution's booking/management system) where your experiments run on equipment inside your own secured wing (data plane in your VNet). Delta Lake is the lab's rigorous logbook ensuring every result is consistent and reproducible (ACID/time travel), and Unity Catalog is the master access registry controlling who can open which cabinet.

## 20. One-Page Cheat Sheet
- **What**: managed Spark + Delta Lake **lakehouse** on Azure.
- **Delta**: ACID, schema enforcement, time travel, MERGE/upsert on the lake.
- **Compute**: all-purpose vs **job clusters**, SQL warehouses (serverless), pools, **Photon**; autoscale + auto-terminate.
- **Governance**: **Unity Catalog** (catalog.schema.table, ACLs, lineage, audit).
- **Architecture**: control plane (Databricks) + data plane (your VNet); Managed Identity to ADLS.
- **Cost**: job clusters + spot + auto-terminate + Photon + Delta OPTIMIZE; DBU-based.

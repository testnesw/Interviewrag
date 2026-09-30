# 94 · Azure Data Lake Storage Gen2 (ADLS Gen2)

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Data Lake Storage Gen2 is **Blob Storage optimized for big-data analytics**. It adds a real folder structure (hierarchical namespace) and fine-grained permissions, so analytics engines like Spark and Databricks can efficiently read and write huge datasets.

## 2. Architect-Level Explanation
Blob Storage + **Hierarchical Namespace (HNS)** for analytics workloads:
- **HNS**: real directories (not virtual) → atomic directory rename/move/delete, faster analytics operations, POSIX-like paths.
- **Access control**: **RBAC** (coarse) + **POSIX ACLs** (fine-grained per file/directory) + Entra ID. ACLs enable data-lake security zones.
- **Multi-protocol**: same data via Blob API, **ABFS** (`abfss://`) driver, and NFS 3.0.
- **Analytics engines**: Databricks, Synapse/Fabric, HDInsight, Spark read/write directly.
- **Zones (medallion)**: **Bronze** (raw), **Silver** (cleansed/conformed), **Gold** (curated/aggregated) — organize the lake for governance and reuse.
- **File formats**: columnar **Parquet/Delta**, ORC, Avro for efficient analytics; partitioning by date/key.
- **Security**: private endpoints, CMK, Entra ID + Managed Identity, ACLs; firewall.
- **Cost**: same tiers (Hot/Cool/Cold/Archive) + lifecycle; storage separated from compute (scale independently).
- **Lakehouse**: combine with **Delta Lake** for ACID transactions on the lake.

## 3. Real Enterprise Use Case
An enterprise lakehouse lands raw ingestion in a **Bronze** container, Databricks transforms to cleansed **Silver** and curated **Gold** Delta tables, partitioned by date. HNS enables fast directory operations, **ACLs** enforce zone-level access per team, and analytics (Synapse/Fabric, Power BI) query Gold — all on private endpoints with Managed Identity.

## 4. Architecture Diagram (ASCII)
```
   Sources ─► Ingest ─► ADLS Gen2 (HNS on)
   ┌──────────────┬───────────────┬──────────────┐
   Bronze (raw)   Silver (clean)  Gold (curated)   ← medallion zones
   Delta/Parquet, partitioned by date/key
   Access: Entra ID RBAC + POSIX ACLs (per dir/file)
   Engines: Databricks/Spark · Synapse/Fabric · Power BI (abfss://)
   Storage ⟂ Compute (scale independently) | private endpoint + CMK
```

## 5. Interview Questions
1. How does ADLS Gen2 differ from plain Blob?
2. What is the hierarchical namespace and why does it matter?
3. RBAC vs ACLs for data-lake security?
4. What is the medallion architecture?
5. Why Parquet/Delta and partitioning?

## 6. Strong Interview Answers
- **vs Blob**: "ADLS Gen2 is Blob with the **hierarchical namespace** enabled — real directories give atomic rename/move/delete and much faster analytics operations, plus POSIX ACLs. It's purpose-built for big-data engines while keeping Blob's scale and tiers."
- **HNS**: "Instead of a flat namespace with virtual folders, HNS stores actual directory objects, so operations like renaming a folder of millions of files are atomic and cheap — critical for Spark job commit performance and directory-level security."
- **RBAC vs ACLs**: "RBAC grants coarse access at container/account level (e.g., Blob Data Reader). POSIX **ACLs** add fine-grained per-directory/per-file permissions for users/groups. I combine them — RBAC for broad roles, ACLs to enforce zone/team boundaries in the lake."
- **Medallion**: "A layered design — Bronze (raw, immutable ingest), Silver (cleansed, conformed, deduped), Gold (business-level curated/aggregated). It gives lineage, reusability, and clear quality/governance boundaries."
- **Parquet/Delta + partitioning**: "Columnar Parquet compresses well and enables column pruning + predicate pushdown for fast scans. Delta adds ACID transactions, time travel, and schema enforcement (lakehouse). Partitioning by date/key prunes files so queries read less data."

## 7. Common Mistakes
- Forgetting to enable HNS at creation (can't toggle easily later).
- Row-based formats (CSV/JSON) for analytics instead of Parquet/Delta.
- Tiny files problem (many small files kill Spark performance).
- Over-permissioning (no ACLs / broad RBAC).
- No partitioning → full scans.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| HNS on | fast dir ops, ACLs | slightly higher txn cost |
| Delta | ACID, time travel | extra metadata/compaction |
| Fine ACLs | precise security | management complexity |

## 9. Production Best Practices
- Enable HNS; medallion zones (Bronze/Silver/Gold).
- Parquet/Delta + partitioning; compact small files (OPTIMIZE).
- RBAC + ACLs via Entra ID groups; private endpoints + CMK.
- Lifecycle tiering for raw/cold zones; Managed Identity access.
- Governance/catalog (Purview/Unity Catalog) + lineage.

## 10. Security Considerations
- Entra ID + Managed Identity; POSIX ACLs per zone/team.
- Private endpoints; CMK; firewall/VNet; no account keys.
- Immutable raw (Bronze) where required; audit access.
- Sensitive-data classification + masking downstream.

## 11. Cost Optimization
- Separate storage/compute — scale independently, pause clusters.
- Tier raw/cold data (Cool/Archive) + lifecycle.
- Compact small files; efficient Parquet/Delta reduces scan/compute.

## 12. Troubleshooting Scenarios
- **Slow Spark commits** → small-file/virtual-dir issues; ensure HNS + compaction.
- **Access denied** → ACL missing on directory path (ACLs not inherited retroactively).
- **Full scans** → no partitioning / wrong partition column.
- **abfss auth fails** → Managed Identity/RBAC not granted.
- **Can't enable HNS** → must be set at account creation.

## 13. Hands-on Example
```bash
az storage account create -g rg -n stlake --sku Standard_ZRS --kind StorageV2 \
  --hns true --public-network-access Disabled     # enable hierarchical namespace
az storage fs create -n bronze --account-name stlake --auth-mode login
```

## 14. Terraform Example
```hcl
resource "azurerm_storage_account" "lake" {
  name = "stlake" resource_group_name = var.rg location = "eastus"
  account_tier = "Standard" account_replication_type = "ZRS"
  is_hns_enabled = true                       # ADLS Gen2
  identity { type = "SystemAssigned" }
}
resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name = "bronze" storage_account_id = azurerm_storage_account.lake.id
}
```

## 15. Azure Example
```python
# Databricks reads/writes Delta on ADLS Gen2 via abfss:// (Managed Identity)
df = spark.read.format("delta").load("abfss://silver@stlake.dfs.core.windows.net/orders")
(df.write.format("delta").mode("overwrite").partitionBy("order_date")
   .save("abfss://gold@stlake.dfs.core.windows.net/orders_curated"))
```

## 16. FastAPI / Python Example
```python
from azure.storage.filedatalake.aio import DataLakeServiceClient
from azure.identity.aio import DefaultAzureCredential

async def list_zone(fs: str, path: str):
    svc = DataLakeServiceClient("https://stlake.dfs.core.windows.net",
                                credential=DefaultAzureCredential())  # Managed Identity
    async with svc:
        fsc = svc.get_file_system_client(fs)
        return [p.name async for p in fsc.get_paths(path=path)]
```

## 17. AKS Example
AKS-hosted Spark (or Databricks pools) reads/writes ADLS Gen2 via the **ABFS** driver using **Workload Identity** — no keys. Storage is decoupled from the ephemeral compute pods, so clusters scale/terminate independently while the lake persists.

## 18. How to Remember
**"Blob + HNS = analytics lake; real dirs + ACLs; medallion Bronze/Silver/Gold; Parquet/Delta + partition; storage ⟂ compute."**

## 19. Real-World Analogy
Upgrading a giant warehouse (Blob) with a real aisle-and-shelf system (HNS): now you can relocate a whole aisle instantly (atomic rename), lock specific shelves per team (ACLs), and organize goods from raw pallets (Bronze) to packaged products (Gold). Forklifts (Spark) move faster because everything is properly indexed.

## 20. One-Page Cheat Sheet
- **What**: Blob + **Hierarchical Namespace** for big-data analytics (lakehouse).
- **HNS**: real directories → atomic rename/move, POSIX **ACLs**, fast Spark ops.
- **Security**: RBAC (coarse) + ACLs (fine) + Entra ID/Managed Identity; private endpoints + CMK.
- **Medallion**: Bronze (raw) → Silver (clean) → Gold (curated).
- **Formats**: Parquet/**Delta** (ACID, time travel) + partitioning; compact small files.
- **Design**: storage ⟂ compute; multi-protocol (Blob/ABFS/NFS); enable HNS at creation.

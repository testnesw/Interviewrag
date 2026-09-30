# 92 · Azure Storage (Account & Fundamentals)

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
An Azure Storage account is a **cloud storage container** that holds several data services — Blobs (files/objects), Files (SMB shares), Queues (simple messaging), and Tables (key-value). It's durable, scalable, and pay-as-you-go.

## 2. Architect-Level Explanation
The foundational storage resource grouping four services under one account:
- **Services**: **Blob** (objects), **File** (SMB/NFS shares), **Queue** (basic messaging), **Table** (NoSQL key-value), plus **Data Lake Gen2** (Blob + hierarchical namespace).
- **Account kinds**: StorageV2 (general-purpose v2, default), premium (BlockBlob/FileStorage/PageBlob).
- **Redundancy**: **LRS** (3 copies, one datacenter), **ZRS** (across zones), **GRS/RA-GRS** (secondary region, read access), **GZRS** (zone + geo).
- **Performance tiers**: Standard (HDD) vs Premium (SSD, low latency).
- **Access tiers** (Blob): Hot / Cool / Cold / Archive — cost vs access-latency trade-off; lifecycle management auto-tiers.
- **Security**: encryption at rest (Microsoft or **CMK** in Key Vault), **private endpoints**, firewall/VNet rules, **Entra ID RBAC** + Managed Identity (vs account keys/SAS), infrastructure encryption, immutable (WORM) storage.
- **Access**: account keys, **SAS** (shared access signatures — scoped, time-bound), Entra ID.
- **Scale**: massive; throughput/IOPS targets per account; partitioning matters.

## 3. Real Enterprise Use Case
An enterprise data platform uses one storage strategy: Blob (Hot/Cool/Archive with lifecycle rules) for documents and backups, Data Lake Gen2 for analytics, File shares for lift-and-shift apps, all with **GZRS** redundancy, **private endpoints**, **CMK** encryption, and **Entra ID + Managed Identity** access — no account keys, audited via diagnostic logs.

## 4. Architecture Diagram (ASCII)
```
        Storage Account (StorageV2)
   ┌────────┬────────┬────────┬────────┬────────────┐
   Blob     File     Queue    Table    Data Lake Gen2
   (objects)(SMB)   (msgs)  (KV NoSQL) (Blob + HNS)
   Tiers: Hot/Cool/Cold/Archive  ── lifecycle mgmt
   Redundancy: LRS│ZRS│GRS│GZRS   Encryption: CMK (Key Vault)
   Access: Entra ID RBAC + Managed Identity | SAS | private endpoint
```

## 5. Interview Questions
1. What services does a storage account provide?
2. Explain the redundancy options.
3. Blob access tiers — when to use each?
4. How do you secure a storage account?
5. Account keys vs SAS vs Entra ID?

## 6. Strong Interview Answers
- **Services**: "One account exposes Blob (objects), File (SMB/NFS shares), Queue (basic messaging), Table (key-value NoSQL), and Data Lake Gen2 (Blob with hierarchical namespace for analytics)."
- **Redundancy**: "LRS keeps 3 copies in one datacenter; ZRS spreads across availability zones; GRS/RA-GRS replicate to a paired region (RA gives read access to the secondary); GZRS combines zone + geo. I pick by RPO/RTO and compliance — GZRS for critical data needing zone + regional resilience."
- **Tiers**: "Hot for frequently accessed data, Cool for infrequent (30+ days), Cold for rarely accessed, Archive for long-term retention with hours-long rehydration. Lifecycle rules auto-move blobs (e.g., Hot→Cool→Archive by age) to cut cost."
- **Secure**: "Private endpoints + firewall/VNet rules, disable public access and account-key access, use **Entra ID RBAC + Managed Identity**, CMK encryption in Key Vault, immutable (WORM) for compliance, and diagnostic logging."
- **Keys vs SAS vs Entra**: "Account keys are all-powerful — avoid. SAS is scoped, time-bound delegated access (prefer **user-delegation SAS** signed by Entra). Entra ID + RBAC + Managed Identity is best — no secrets, fine-grained, auditable."

## 7. Common Mistakes
- Using account keys instead of Entra ID/Managed Identity.
- Public network access left open.
- Wrong redundancy (LRS for critical data) or over-paying (GRS when not needed).
- No lifecycle management → paying Hot for cold data.
- Long-lived, broad SAS tokens.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| GZRS | zone + geo resilience | higher cost |
| Archive tier | cheapest storage | slow rehydration |
| SAS | delegated access | secret to manage |

## 9. Production Best Practices
- Entra ID RBAC + Managed Identity; disable key/public access.
- Private endpoints + firewall; CMK; infrastructure encryption.
- Lifecycle policies for tiering; soft delete + versioning.
- Right redundancy per data criticality; diagnostic logs.
- IaC + naming/tagging conventions.

## 10. Security Considerations
- Disable shared-key + public access; user-delegation SAS only.
- Private endpoints; CMK in Key Vault; immutable/WORM for compliance.
- Soft delete + versioning (ransomware/accidental delete).
- Least-privilege RBAC (Blob Data Reader/Contributor).

## 11. Cost Optimization
- Lifecycle tiering (Hot→Cool→Cold→Archive).
- Right redundancy (LRS/ZRS where geo not required).
- Reserved capacity for predictable volume; delete orphaned data/versions.

## 12. Troubleshooting Scenarios
- **403 AuthorizationFailure** → missing RBAC role / firewall blocks / key access disabled.
- **Cannot reach from VNet** → private endpoint/DNS not configured.
- **Slow archive access** → Archive tier rehydration delay.
- **Throttling (503)** → exceeding account IOPS/throughput; partition/scale.
- **Unexpected cost** → cold data in Hot tier; add lifecycle rules.

## 13. Hands-on Example
```bash
az storage account create -g rg -n stprod --sku Standard_GZRS \
  --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
  --public-network-access Disabled --assign-identity
```

## 14. Terraform Example
```hcl
resource "azurerm_storage_account" "sa" {
  name = "stprod" resource_group_name = var.rg location = "eastus"
  account_tier = "Standard" account_replication_type = "GZRS"
  min_tls_version = "TLS1_2" public_network_access_enabled = false
  shared_access_key_enabled = false          # force Entra ID
  blob_properties { versioning_enabled = true delete_retention_policy { days = 30 } }
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```bash
# Lifecycle rule: Hot → Cool after 30d, Archive after 90d, delete after 365d
az storage account management-policy create --account-name stprod -g rg \
  --policy @lifecycle.json
```

## 16. FastAPI / Python Example
```python
from azure.storage.blob.aio import BlobServiceClient
from azure.identity.aio import DefaultAzureCredential

async def upload(container: str, name: str, data: bytes):
    svc = BlobServiceClient("https://stprod.blob.core.windows.net",
                            credential=DefaultAzureCredential())   # Managed Identity
    async with svc:
        await svc.get_blob_client(container, name).upload_blob(data, overwrite=True)
```

## 17. AKS Example
AKS pods mount Azure Files (SMB/NFS) via the CSI driver for shared state, and Blob CSI for object data — authenticated with **Workload Identity** (no keys). Private endpoints keep traffic on the VNet; storage classes provision PVCs dynamically.

## 18. How to Remember
**"One account, four services (Blob/File/Queue/Table) + Data Lake; redundancy L/Z/G; tiers Hot→Archive; secure with Entra ID + private endpoint."**

## 19. Real-World Analogy
A bank with different vaults under one roof: safe-deposit boxes (Blob), shared filing rooms (File), a message pigeonhole (Queue), an index ledger (Table). You choose how many branches keep copies (redundancy) and whether valuables sit in the quick-access drawer (Hot) or deep storage (Archive).

## 20. One-Page Cheat Sheet
- **Account (StorageV2)** groups: Blob, File, Queue, Table, Data Lake Gen2.
- **Redundancy**: LRS < ZRS < GRS/RA-GRS < GZRS (zone + geo).
- **Blob tiers**: Hot / Cool / Cold / Archive + lifecycle mgmt.
- **Secure**: Entra ID RBAC + Managed Identity, disable keys/public, private endpoints, CMK, soft delete + versioning, WORM.
- **Access**: avoid account keys; prefer Entra ID; user-delegation SAS if needed.
- **Optimize**: lifecycle tiering, right redundancy, reserved capacity.

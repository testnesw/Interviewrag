# 93 · Azure Blob Storage

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Azure Blob Storage stores **unstructured objects** — files like images, videos, backups, logs, and documents — accessed over HTTP(S). It scales to petabytes and is the go-to for cloud object storage.

## 2. Architect-Level Explanation
Massively scalable object store:
- **Hierarchy**: account → **container** → **blob**. Flat namespace with virtual folders (Data Lake Gen2 adds real hierarchy).
- **Blob types**: **Block blobs** (files/objects, most common), **Append blobs** (logging), **Page blobs** (random-access, VM disks).
- **Access tiers**: Hot / Cool / Cold / Archive (per-blob) + **lifecycle management** for auto-tiering/expiry.
- **Data protection**: soft delete (blob + container), **versioning**, **blob snapshots**, **point-in-time restore**, **immutable/WORM** (legal hold, time-based retention), object replication.
- **Access**: Entra ID RBAC + Managed Identity, user-delegation SAS, account keys (avoid), anonymous (usually disabled).
- **Performance**: Standard vs **Premium block blob** (low latency, high transaction); parallel/chunked upload; **CDN / Front Door** for edge caching.
- **Events**: Event Grid `BlobCreated/Deleted` for reactive processing.
- **Static website hosting**; SFTP support; NFS 3.0 (with HNS).
- **Encryption**: at rest (CMK), in transit (TLS), infrastructure encryption.

## 3. Real Enterprise Use Case
A media platform stores originals as block blobs (Hot), auto-tiers to Cool/Archive by age via lifecycle rules, serves via **Front Door/CDN**, triggers thumbnail Functions via **Event Grid** on upload, protects with versioning + soft delete + immutable WORM for compliance, and secures everything with **private endpoints + Managed Identity**.

## 4. Architecture Diagram (ASCII)
```
   Account ─► Container ─► Blob (block/append/page)
   Upload ─► Event Grid (BlobCreated) ─► Function (process/thumbnail)
   Tiers: Hot ─(lifecycle)─► Cool ─► Cold ─► Archive ─► delete
   Protect: soft delete + versioning + snapshots + WORM (immutable)
   Serve: Front Door/CDN (edge cache) | Access: Entra ID + SAS + private endpoint
```

## 5. Interview Questions
1. Blob types and when to use each?
2. How do access tiers and lifecycle management work?
3. How do you protect blobs from deletion/ransomware?
4. How do you secure and serve blobs?
5. How do you handle event-driven blob processing?

## 6. Strong Interview Answers
- **Types**: "Block blobs for general files/objects (uploaded in blocks, most common); append blobs optimized for append-only logging; page blobs for random read/write like VM disks. Almost all app data uses block blobs."
- **Tiers/lifecycle**: "Per-blob Hot/Cool/Cold/Archive trade storage cost for access cost/latency. Lifecycle policies automatically move blobs by age (Hot→Cool→Archive) and expire old versions/snapshots — big savings on cold data. Archive needs rehydration (hours) before read."
- **Protection**: "Soft delete recovers deleted blobs/containers within a retention window; versioning keeps prior versions; snapshots capture point-in-time; **immutable WORM** with time-based retention or legal hold blocks modification/deletion for compliance and ransomware resilience."
- **Secure/serve**: "Entra ID RBAC + Managed Identity, private endpoints, disable public/anonymous access, user-delegation SAS for scoped sharing. Serve globally via Front Door/CDN with cached edge delivery."
- **Event-driven**: "Event Grid emits BlobCreated/Deleted events; I subscribe a Function or Logic App (filtered by container/suffix) to react — thumbnailing, virus scan, indexing — with dead-lettering for reliability."

## 7. Common Mistakes
- Anonymous/public access left enabled.
- No lifecycle rules → cold data billed at Hot.
- No versioning/soft delete (no recovery from mistakes/ransomware).
- Reading Archive without accounting for rehydration latency.
- Serving large files direct from Blob without CDN.

## 8. Trade-offs
| Aspect | Choice | Trade-off |
|--------|--------|-----------|
| Access tier | Archive | cheap store / slow read |
| Protection | versioning | recovery / extra cost |
| Delivery | CDN | fast/cache / invalidation |

## 9. Production Best Practices
- Lifecycle tiering + version/snapshot expiry.
- Versioning + soft delete + WORM for critical data.
- Private endpoints + Entra ID + Managed Identity.
- Event Grid for reactive pipelines (dead-letter).
- Front Door/CDN for delivery; parallel chunked upload.

## 10. Security Considerations
- Disable anonymous/public + shared-key; user-delegation SAS.
- Private endpoints; CMK encryption; TLS 1.2+.
- Immutable WORM + legal hold for compliance.
- Least-privilege RBAC; audit access logs.

## 11. Cost Optimization
- Lifecycle to Cool/Cold/Archive; expire stale versions/snapshots.
- Premium only where low latency needed.
- CDN reduces egress from origin; reserved capacity.

## 12. Troubleshooting Scenarios
- **403** → RBAC/firewall/key-access disabled.
- **Archive read fails/slow** → rehydrate first (hours).
- **Deleted blob gone** → soft delete/versioning not enabled.
- **High egress cost** → serve via CDN, not origin.
- **Event not firing** → Event Grid subscription filter/handshake.

## 13. Hands-on Example
```bash
az storage blob upload --account-name stprod -c media -n photo.jpg \
  -f ./photo.jpg --tier Hot --auth-mode login       # Entra ID auth
```

## 14. Terraform Example
```hcl
resource "azurerm_storage_container" "media" {
  name = "media" storage_account_name = azurerm_storage_account.sa.name
  container_access_type = "private"
}
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.sa.id
  rule { name = "tiering" enabled = true
    filters { blob_types = ["blockBlob"] }
    actions { base_blob {
      tier_to_cool_after_days_since_modification_greater_than = 30
      tier_to_archive_after_days_since_modification_greater_than = 90
      delete_after_days_since_modification_greater_than = 365 } }
  }
}
```

## 15. Azure Example
```bash
az eventgrid event-subscription create --name on-upload \
  --source-resource-id $STORAGE_ID --endpoint $FN --endpoint-type azurefunction \
  --included-event-types Microsoft.Storage.BlobCreated --subject-ends-with .jpg
```

## 16. FastAPI / Python Example
```python
# Generate a short-lived user-delegation SAS for secure client download
from datetime import datetime, timedelta, timezone
from azure.storage.blob import generate_blob_sas, BlobSasPermissions

def download_url(svc, container, blob, key):
    sas = generate_blob_sas(svc.account_name, container, blob,
        user_delegation_key=key, permission=BlobSasPermissions(read=True),
        expiry=datetime.now(timezone.utc) + timedelta(minutes=15))   # time-bound
    return f"https://{svc.account_name}.blob.core.windows.net/{container}/{blob}?{sas}"
```

## 17. AKS Example
AKS workloads use the **Blob CSI driver** to mount containers as volumes or access via SDK with **Workload Identity** (no keys). Large ML datasets stream from Blob; private endpoints keep traffic internal; lifecycle rules archive processed outputs.

## 18. How to Remember
**"Object store: container→blob; block/append/page; Hot→Archive + lifecycle; protect with versioning+soft delete+WORM; react via Event Grid; serve via CDN."**

## 19. Real-World Analogy
A giant self-storage facility: units (containers) hold boxes (blobs). Frequently needed boxes stay by the entrance (Hot), rarely used ones go to the deep warehouse (Archive, slow to retrieve). Security cameras and a "no-remove" seal (versioning/WORM) protect against theft or mistakes, and a courier network (CDN) delivers copies fast worldwide.

## 20. One-Page Cheat Sheet
- **What**: massively scalable object store (account→container→blob).
- **Types**: block (files), append (logs), page (VM disks).
- **Tiers**: Hot/Cool/Cold/Archive + lifecycle; Archive needs rehydration.
- **Protect**: soft delete, versioning, snapshots, PITR, immutable WORM.
- **Secure**: Entra ID + Managed Identity, private endpoints, user-delegation SAS, CMK; disable public/keys.
- **Integrate**: Event Grid (BlobCreated), Front Door/CDN, Blob CSI on AKS.

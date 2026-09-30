# DEEP MECHANICS · Azure Storage & Blob

> Level 2 — account types, blob tiers, redundancy (LRS→GZRS), access control,
> and performance/consistency characteristics.

---

## 0. The precise mental model
Azure Storage is the **foundational object/file/queue/table store**. For an architect the decisions are: **redundancy** (how many copies, where → durability vs cost), **access tier** (Hot/Cool/Cold/Archive → storage vs retrieval cost), **security** (private endpoints, Entra/SAS, encryption), and **performance tier** (Standard vs Premium). Everything is durability + cost + access-pattern trade-offs.

---

## 1. Services in a storage account
**Blob** (objects), **Files** (SMB/NFS shares), **Queues** (simple messaging), **Tables** (NoSQL key-value). Blob is the big one for data/AI.

## 2. Redundancy — durability vs cost (know the ladder)
| Option | Copies | Scope | Survives |
|---|---|---|---|
| **LRS** | 3 | one datacenter | disk/rack failure |
| **ZRS** | 3 | across **zones** in region | zone failure |
| **GRS** | 6 | region + **paired region** | region failure (async) |
| **GZRS** | 6 | zones + paired region | zone **and** region |
- **RA-GRS/RA-GZRS** — add **read access** to the secondary.
- 11 nines durability baseline; pick based on RTO/RPO + cost. Secondary replication is **async** → possible data loss on failover (RPO > 0).

## 3. Blob access tiers — storage vs retrieval cost
- **Hot** — frequent access; highest storage cost, lowest access cost.
- **Cool** — infrequent (30+ days); lower storage, higher access.
- **Cold** — rarely (90+ days).
- **Archive** — offline, cheapest storage, **hours to rehydrate**, high retrieval cost.
**Lifecycle management** auto-tiers/deletes blobs by age → big savings. Match tier to access pattern.

## 4. Blob types
- **Block blobs** — files/objects (most common).
- **Append blobs** — logs.
- **Page blobs** — random-access, back VM disks.

## 5. Security & access
- **Encryption at rest** (SSE, Microsoft- or customer-managed keys) always on; **TLS** in transit.
- **Access**: **Entra ID + RBAC** (data-plane roles like Storage Blob Data Reader — preferred), **SAS tokens** (scoped, time-limited), account keys (avoid).
- **Private Endpoint** → keep traffic off public internet; disable public access; firewall rules.
- **Managed Identity** for apps to access blobs keylessly.

## 6. Performance
- **Standard** (HDD-backed, cheap) vs **Premium** (SSD, low latency, high IOPS — Premium block blob for hot small-object workloads).
- Scale targets per account; partition naming for throughput; use CDN for read-heavy public content.

## 7. The hard follow-ups (with answers)
1. **"LRS vs ZRS vs GRS vs GZRS?"** → 3 local / 3 zonal / 6 cross-region async / 6 zonal+cross-region. Durability vs cost. (§2)
2. **"RPO on GRS failover?"** → >0 — secondary replication is async, some recent writes may be lost. (§2)
3. **"Cut storage cost on old data?"** → lifecycle policy → Cool/Cold/Archive; Archive cheapest but slow rehydrate. (§3)
4. **"Secure blob access?"** → Entra RBAC + Managed Identity (keyless) + Private Endpoint + disable public + SAS when needed. (§5)
5. **"Standard vs Premium blob?"** → HDD cheap bulk vs SSD low-latency/high-IOPS hot workloads. (§6)

## 8. One-screen recall
- Storage account: **Blob / Files / Queues / Tables**. Blob = objects.
- **Redundancy ladder**: **LRS**(3 local) → **ZRS**(3 zonal) → **GRS**(6, cross-region async) → **GZRS**(zonal+cross-region); RA- = read secondary. Async secondary → **RPO>0**.
- **Tiers**: Hot→Cool→Cold→**Archive** (cheapest storage, slow/costly retrieval); **lifecycle mgmt** auto-tiers.
- **Blob types**: block (files), append (logs), page (VM disks).
- **Security**: SSE at rest + TLS; **Entra RBAC + Managed Identity (keyless)** > SAS > account keys; **Private Endpoint** + disable public.
- **Performance**: Standard (HDD) vs **Premium** (SSD low-latency); CDN for read-heavy.

> Next: Blob deep (covered) → Data Lake Gen2.

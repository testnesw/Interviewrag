# DEEP MECHANICS · Blob Storage (deep-focus)

> Level 2 companion to Azure Storage — blob-specific mechanics: blob types,
> upload internals, tiers, access, and data-lake overlap.

---

## 0. The precise mental model
Blob = Azure's **massively scalable object store** for unstructured data (files, images, backups, logs, ML datasets). Organized as **account → container → blob**. Everything else is choosing the **blob type**, **access tier**, **redundancy**, and **secure access** for your pattern. (See also: Azure Storage, Data Lake Gen2.)

---

## 1. Hierarchy & blob types
- **Account → Container → Blob** (flat namespace unless HNS/ADLS Gen2).
- **Block blob** — the default; files/objects uploaded as **blocks** (up to 4000 MiB blocks) then committed → enables **parallel, resumable** large uploads.
- **Append blob** — optimized for append-only (logging, audit).
- **Page blob** — 512-byte pages, random read/write → backs **VM disks**.

## 2. Upload internals (block blob)
Large files split into **blocks**, uploaded in parallel (each with a block ID), then a **Put Block List** commits them atomically. Benefits: parallelism (throughput), retry only failed blocks, resumable uploads. SDKs do this automatically.

## 3. Tiers, redundancy, lifecycle
- **Tiers**: Hot / Cool / Cold / **Archive** (offline, rehydrate hours). Set per-blob.
- **Redundancy**: LRS/ZRS/GRS/GZRS (see Storage deep dive).
- **Lifecycle policies**: auto-transition (Hot→Cool→Archive) + delete by age → cost control.

## 4. Access & security
- **Entra ID + RBAC** data-plane roles (Storage Blob Data Reader/Contributor) + **Managed Identity** = keyless (preferred).
- **SAS** (scoped, time-limited, revocable via stored access policy) for delegated access.
- **Private Endpoint** + disable public network access + firewall.
- **Encryption at rest** (SSE, always on) + TLS; optional CMK, immutable (WORM) blobs for compliance.

## 5. Features for apps/AI
- **Blob events** (Event Grid) → trigger functions on upload (event-driven ingest).
- **Change feed / soft delete / versioning / snapshots** for data protection.
- **CDN / static website** for public read-heavy content.
- Primary landing zone for **ML datasets** and RAG source documents.

## 6. The hard follow-ups (with answers)
1. **"Block vs append vs page blob?"** → objects/files (parallel blocks) / append-only logs / random-access VM disks. (§1)
2. **"How are large files uploaded reliably?"** → split into blocks, parallel upload, Put Block List commit → resumable, retry failed blocks. (§2)
3. **"Trigger processing on upload?"** → Blob event via Event Grid → Azure Function. (§5)
4. **"Secure + keyless access?"** → Entra RBAC + Managed Identity, Private Endpoint, SAS when delegated. (§4)
5. **"Protect against accidental delete?"** → soft delete + versioning + snapshots; immutability (WORM) for compliance. (§5)

## 7. One-screen recall
- Blob = scalable object store; **account→container→blob**.
- Types: **block** (files, parallel blocks + Put Block List commit), **append** (logs), **page** (VM disks).
- **Tiers** Hot/Cool/Cold/**Archive** + **lifecycle** auto-tiering; **LRS→GZRS** redundancy.
- **Access**: Entra RBAC + **Managed Identity (keyless)** > SAS > keys; **Private Endpoint** + disable public; SSE+TLS, CMK, WORM.
- **Features**: Event Grid **blob events** (event-driven), soft delete/versioning/snapshots, CDN; ML/RAG data landing zone.

> Next: Batch C — Networking & Resilience.

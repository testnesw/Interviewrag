# DEEP MECHANICS · Azure SQL Database

> Level 2 — deployment options, purchasing models (DTU vs vCore), HA/replicas,
> scaling, and security — the managed relational engine.

---

## 0. The precise mental model
Azure SQL Database = **fully managed SQL Server engine (PaaS)**: Microsoft runs patching, backups, HA, and replication; you get a relational database with **ACID transactions** and **strong consistency**. Architect decisions: **deployment model**, **purchasing model (DTU vs vCore)**, **HA/DR tier**, and **scaling** approach.

---

## 1. Deployment options
- **Single database** — isolated, its own resources.
- **Elastic pool** — many databases share a resource pool → cost-efficient for variable/multi-tenant workloads.
- **Managed Instance** — near-100% SQL Server compatibility (SQL Agent, cross-DB queries, CLR) for lift-and-shift.
(vs SQL Server on a VM = IaaS, full control, you manage everything.)

## 2. Purchasing models
- **DTU** — bundled compute+memory+IO as one simple metric. Easy but coarse.
- **vCore** (recommended) — choose cores + memory + storage independently; supports **Azure Hybrid Benefit** and **serverless**. Tiers:
  - **General Purpose** — balanced, remote storage.
  - **Business Critical** — local SSD + built-in replicas → low latency + HA.
  - **Hyperscale** — decoupled storage, scales to 100 TB, fast backups/restores, many read replicas.
- **Serverless** — auto-pause/resume + autoscale compute → cheap for intermittent workloads.

## 3. High availability & replicas
- Built-in HA (99.99%); Business Critical uses an **Always On-style replica set** (local SSD) for higher SLA + a readable secondary.
- **Active geo-replication / Failover groups** — async replicas in other regions for DR + read scale-out; failover group gives a stable listener endpoint + automatic failover.
- **Backups** — automatic, PITR (point-in-time restore), geo-redundant.

## 4. Scaling
- **Vertical** — change tier/vCores (quick, some downtime/failover).
- **Read scale-out** — route read-only queries to replicas (Business Critical/Hyperscale).
- **Hyperscale** — near-instant storage scaling + rapid replica adds.
- Sharding/elastic pools for horizontal patterns.

## 5. Security
- **Entra ID auth** (preferred) + SQL auth.
- **Private Endpoint** / VNet, firewall rules; disable public access.
- **TDE** (encryption at rest, on by default), **Always Encrypted** (client-side column encryption), **Dynamic Data Masking**, **Row-Level Security**.
- **Auditing + Microsoft Defender for SQL** (threat detection).
- Managed Identity for app access (keyless).

## 6. The hard follow-ups (with answers)
1. **"Single DB vs elastic pool vs Managed Instance?"** → isolated vs shared-pool (variable/multi-tenant) vs near-full SQL Server compat (lift-shift). (§1)
2. **"DTU vs vCore?"** → bundled simple metric vs independent cores/mem/storage (+ Hybrid Benefit, serverless) — vCore preferred. (§2)
3. **"General Purpose vs Business Critical vs Hyperscale?"** → balanced/remote storage vs local-SSD+replicas(HA/low-latency) vs decoupled storage to 100TB + read replicas. (§2)
4. **"DR across regions?"** → active geo-replication / failover groups (async) + stable listener + auto failover; RPO>0. (§3)
5. **"Secure it?"** → Entra auth + Managed Identity, Private Endpoint, TDE/Always Encrypted/RLS, Defender for SQL. (§5)
6. **"Cheap for intermittent load?"** → serverless (auto-pause/autoscale). (§2)

## 7. One-screen recall
- Azure SQL = **managed SQL Server PaaS**; ACID + strong consistency; MS runs HA/backup/patch.
- **Deploy**: single DB / **elastic pool** (shared, variable) / **Managed Instance** (compat, lift-shift).
- **Purchasing**: **DTU** (bundled) vs **vCore** (independent + Hybrid Benefit + serverless). Tiers: **General Purpose** (remote storage), **Business Critical** (local SSD + replicas, HA), **Hyperscale** (decoupled storage→100TB, read replicas).
- **HA/DR**: built-in 99.99%; **failover groups / geo-replication** (async, RPO>0); PITR backups.
- **Scale**: vertical, read scale-out replicas, Hyperscale rapid storage.
- **Security**: Entra + MI, Private Endpoint, **TDE/Always Encrypted/RLS/DDM**, Defender for SQL.

> Next: Cosmos DB.

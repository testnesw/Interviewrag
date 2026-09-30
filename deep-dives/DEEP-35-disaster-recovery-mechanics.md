# DEEP MECHANICS · Disaster Recovery

> Level 2 — the DR strategies, multi-region architecture, failover/failback
> mechanics, data replication, and testing.

---

## 0. The precise mental model
DR = **the plan + architecture to recover a whole workload after a major failure** (region outage, data corruption, ransomware). It's driven by **RTO/RPO** (previous topic) and implemented through **redundancy across regions, data replication, and an automated failover/failback process**. HA keeps you running through *component* failures; **DR gets you back after a *catastrophic* one.**

---

## 1. DR strategies (by RTO/RPO + cost)
- **Backup & Restore** — restore from backups in another region. Cheapest, slowest (hours+).
- **Pilot Light** — core (DB replica, minimal infra) always on in the DR region; scale up on disaster.
- **Warm Standby** — a scaled-down but running copy; scale up + shift traffic on failover.
- **Active-Active (Multi-region)** — both regions serve live; failure = drop one region. ~Zero RTO/RPO, priciest.
(See RTO/RPO deep dive for the mapping table.)

## 2. Multi-region architecture
```
Front Door / Traffic Manager (global routing + health)
     ├── Region A (primary)  — app + DB primary
     └── Region B (secondary)— app + DB replica (async)
Data: geo-replication (SQL failover group / Cosmos / GZRS storage)
```
- Use **region pairs** (Azure replicates some platform services between pairs; staggered maintenance).
- **Global router** (Front Door/Traffic Manager) detects failure and reroutes.

## 3. Data replication (the hard part)
- **Async geo-replication** — standard for cross-region (RPO>0): SQL failover groups, Cosmos multi-region, GRS/GZRS.
- **Sync** — only for zero-RPO within close distance (latency-limited).
- **Backups** (geo-redundant, PITR) protect against **corruption/ransomware** (replication alone copies bad data → keep point-in-time backups too).

## 4. Failover & failback
- **Failover** — promote secondary to primary, repoint traffic (DNS/Front Door/failover group listener). Automatic or manual (manual avoids false-positive flip-flops).
- **Failback** — after primary recovers, **re-sync** data back and return (carefully, avoid data divergence). Failback is often harder than failover.
- **Idempotent, documented runbooks** + automation reduce RTO and human error.

## 5. Beyond region loss
- **Data corruption / ransomware** — replication won't save you; need **immutable/geo backups + PITR**.
- **Accidental deletion** — soft delete, resource locks.
DR covers more than region outages.

## 6. Testing & governance
- **Regular DR drills** (planned failover) validate RTO/RPO and runbooks.
- **Chaos/failover testing**; keep DR config in **IaC** so the DR region is reproducible and not drifted.

## 7. The hard follow-ups (with answers)
1. **"Design DR for a critical app?"** → set RTO/RPO → pick pattern (backup→pilot→warm→active-active) → multi-region + async geo-replication + global router failover + backups + drills. (§1-3)
2. **"Replication protects against ransomware?"** → no — it copies corruption; need immutable/PITR backups. (§3,5)
3. **"Automatic vs manual failover?"** → auto = low RTO but risk false flip; manual = controlled; failover groups support both. (§4)
4. **"Why is failback hard?"** → must re-sync without data divergence after primary returns. (§4)
5. **"How do you ensure DR actually works?"** → scheduled failover drills + DR infra as IaC. (§6)
6. **"What are region pairs?"** → Azure-paired regions with replicated platform services + staggered updates. (§2)

## 8. One-screen recall
- DR = recover a whole workload after catastrophe; driven by **RTO/RPO**; HA(component) vs DR(catastrophe).
- **Strategies**: Backup/Restore → Pilot Light → Warm Standby → **Active-Active** (cheap→$$$$, slow→~0).
- **Architecture**: multi-region (**region pairs**) + **async geo-replication** (SQL failover groups/Cosmos/GZRS) + **Front Door/Traffic Manager** failover routing.
- **Backups (immutable/PITR)** for corruption/ransomware — replication alone copies bad data.
- **Failover** (promote+repoint, auto/manual) + **failback** (re-sync, harder).
- **Test with drills**; DR infra in **IaC**.

> Next: Batch D — Kubernetes/AKS/Containers.

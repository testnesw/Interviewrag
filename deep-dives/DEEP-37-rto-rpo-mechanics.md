# DEEP MECHANICS · RTO / RPO

> Level 2 — the precise definitions, how they drive DR strategy and cost, and the
> four DR patterns mapped to them.

---

## 0. The precise mental model
**RTO** and **RPO** are the **two numbers that define your DR requirements** and therefore your architecture and cost. **RPO** = how much **data** you can afford to lose (time); **RTO** = how long you can afford to be **down** (time). They're **business decisions** that dictate the technical DR pattern — lower numbers cost exponentially more.

---

## 1. The definitions (don't mix them up)
```
        ← RPO →        DISASTER        ← RTO →
  last good backup        |         service restored
   (data loss window)              (downtime window)
```
- **RPO (Recovery Point Objective)** — max acceptable **data loss**, measured backward from the disaster to the last recoverable state. RPO of 1h → you may lose up to 1h of data → backup/replicate at least hourly.
- **RTO (Recovery Time Objective)** — max acceptable **downtime**, measured forward → how fast you must restore service. RTO of 1h → recovery must complete within an hour.

## 2. How they drive cost
- **Lower RPO** → more frequent/continuous replication (sync replication → near-zero RPO, but latency + cost).
- **Lower RTO** → warmer standby (hot standby = instant, costs full duplicate; cold = cheap, slow).
- Near-zero RTO+RPO ≈ **active-active multi-region** = most expensive. Set them by **business impact**, not aspiration.

## 3. The four DR patterns (map to RTO/RPO)
| Pattern | RTO | RPO | Cost |
|---|---|---|---|
| **Backup & Restore** | hours–days | hours | $ |
| **Pilot Light** | ~hour | minutes | $$ (core running, scale up on DR) |
| **Warm Standby** | minutes | seconds–min | $$$ (scaled-down live copy) |
| **Active-Active (Multi-site)** | ~zero | ~zero | $$$$ (full duplicate serving) |
Choose the cheapest pattern that meets the required RTO/RPO.

## 4. Sync vs async replication (the RPO lever)
- **Synchronous** — write confirmed only after replica commits → **RPO ≈ 0**, but adds latency and limits distance. For zero-data-loss.
- **Asynchronous** — replica lags → **RPO > 0** (lose in-flight writes on failover), but no latency penalty, any distance. Most cross-region DR is async → accept some data loss.

## 5. Azure services mapped
- **Azure Backup** — backup & restore (high RTO/RPO, cheap).
- **Azure Site Recovery (ASR)** — replicate VMs to another region (warm-ish).
- **GRS/GZRS storage**, **SQL failover groups / geo-replication** (async), **Cosmos multi-region** (low RPO/RTO).
- **Traffic Manager / Front Door** for regional failover routing.

## 6. Testing (the often-missed point)
A DR plan is worthless untested. **Regular DR drills** (failover tests) validate RTO/RPO are actually achievable and keep runbooks current.

## 7. The hard follow-ups (with answers)
1. **"RTO vs RPO?"** → RTO = downtime tolerance (time to restore); RPO = data-loss tolerance (time before disaster). (§1)
2. **"RPO of zero — how?"** → synchronous replication (commit to replica before ack) — costs latency/distance. (§4)
3. **"How do RTO/RPO drive architecture?"** → pick DR pattern (backup→pilot light→warm→active-active) by required numbers vs cost. (§3)
4. **"Cheapest way to meet a 4-hour RTO?"** → likely pilot light or warm standby depending on RPO; not full active-active. (§3)
5. **"Why does cross-region DR usually have RPO>0?"** → async replication (latency/distance) → some in-flight data lost on failover. (§4)
6. **"How do you know your DR works?"** → scheduled failover drills validating RTO/RPO. (§6)

## 8. One-screen recall
- **RPO = data-loss window** (backward, → replication frequency). **RTO = downtime window** (forward, → standby warmth).
- **Lower = exponentially costlier**; set by **business impact**.
- **DR patterns** (cheap→expensive): **Backup/Restore** (hrs) → **Pilot Light** → **Warm Standby** → **Active-Active** (~0/~0).
- **Sync replication → RPO≈0** (latency-limited); **async → RPO>0** (most cross-region DR).
- Azure: Backup, **ASR**, GRS/GZRS, **SQL failover groups**, Cosmos multi-region, Front Door/Traffic Manager failover.
- **Test with DR drills** or it doesn't count.

> Next: Disaster Recovery.

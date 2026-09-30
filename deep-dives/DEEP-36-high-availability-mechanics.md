# DEEP MECHANICS · High Availability

> Level 2 — availability math, zones vs regions, redundancy patterns, and
> eliminating single points of failure.

---

## 0. The precise mental model
High availability = **designing so the system keeps serving despite component failures**, measured as **uptime %** against an SLA. The method: **eliminate single points of failure** through **redundancy** at every layer, spread across **fault domains** (zones/regions), with **health checks + automatic failover**. HA is about **surviving failures**; DR (next) is about **recovering from disasters**.

---

## 1. Availability math (know this)
- **"Nines"**: 99.9% = ~8.76h/yr down; 99.99% = ~52.6 min/yr; 99.999% = ~5.26 min/yr.
- **Series (dependency) composition** — components in series **multiply**: 99.9% × 99.9% = 99.8% (worse). Every hard dependency lowers availability.
- **Redundancy (parallel)** — two 99% instances in parallel: 1 − (0.01 × 0.01) = **99.99%** (better). Redundancy raises availability.
- Design implication: reduce serial dependencies, add parallel redundancy on critical paths.

## 2. Fault domains: zones vs regions
- **Availability Zone** — physically separate datacenter within a region (independent power/cooling/network). Spread instances across **≥3 zones** → survive a datacenter failure. **Zone-redundant** services do this automatically.
- **Region** — geographic area; **region pairs** for DR. Multi-region = survive a whole-region outage (see DR).
- **Availability Set** (legacy, within a datacenter) — spreads VMs across fault + update domains.

## 3. Redundancy patterns
- **Active-active** — all instances serve traffic; load-balanced; failure just removes capacity. Best RTO, higher cost/complexity.
- **Active-passive (standby)** — standby takes over on failure. Cheaper, some failover time.
- **N+1 / N+M** — provision spare capacity beyond peak need.

## 4. Eliminating SPOFs (the checklist)
Redundancy at every layer: multiple app instances (VMSS/AKS across zones), **zone-redundant load balancer**, replicated database (zone/geo), redundant gateways, multiple storage copies (ZRS/GZRS), health probes to remove bad instances, and **no shared single dependency**.

## 5. Health checks & self-healing
Load balancers/orchestrators use **health probes** to detect and **remove/replace** unhealthy instances automatically (AKS reschedules pods, VMSS heals instances). Automation, not humans, restores capacity.

## 6. Stateless design
Make app tiers **stateless** (externalize session/state to Redis/DB) → any instance can serve any request → trivial horizontal scaling + failover. State is the enemy of easy HA.

## 7. The hard follow-ups (with answers)
1. **"What's 99.99% in downtime?"** → ~52 minutes/year. (§1)
2. **"Two components in series — availability?"** → multiply (lower); each dependency reduces it. (§1)
3. **"Zones vs regions for HA?"** → zones = separate datacenters in a region (survive DC failure); regions = geographic (survive region outage/DR). (§2)
4. **"Active-active vs active-passive?"** → all serve (best RTO, costlier) vs standby takes over (cheaper, failover delay). (§3)
5. **"How does the system self-heal?"** → health probes remove/replace unhealthy instances automatically. (§5)
6. **"Why stateless?"** → any instance serves any request → easy scale + failover. (§6)

## 8. One-screen recall
- HA = keep serving through failures; **eliminate SPOFs via redundancy across fault domains** + health checks + auto failover.
- **Math**: 99.9%=8.76h, 99.99%=52min, 99.999%=5min/yr. **Series multiplies (worse)**; **parallel redundancy improves**.
- **Zones** (separate DCs in region, spread ≥3) vs **regions** (geographic, DR). Zone-redundant services.
- **Active-active** (best RTO, costly) vs **active-passive** (standby) vs N+1.
- Redundancy every layer + **health probes self-heal** (AKS/VMSS) + **stateless** app (externalize state).

> Next: RTO/RPO.

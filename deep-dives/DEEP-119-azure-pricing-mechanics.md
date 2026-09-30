# DEEP MECHANICS · Azure Pricing & Cost Optimization

> Level 2 — pricing models, reservations vs savings plans vs spot, Hybrid
> Benefit, and cost tooling.

---

## 0. The precise mental model
Azure pricing is **consumption-based** by default (pay per second/GB/request), but you **trade flexibility for discount** via **commitment** (reservations/savings plans) or **trade reliability for discount** via **spot**. Optimization = pick the right **purchase model** for each workload's **predictability** + **rightsize** + **eliminate waste**.

---

## 1. Purchase models
| Model | Discount | Commitment | Best for |
|---|---|---|---|
| **Pay-as-you-go** | 0 | none | spiky/unpredictable, dev |
| **Reservations** (RI) | up to ~72% | 1/3-yr, specific SKU/region | steady, known resource (VM, SQL, Cosmos) |
| **Savings Plans** | up to ~65% | 1/3-yr, $/hr compute spend | steady but **flexible** across VM types/regions |
| **Spot** | up to ~90% | none (evictable) | fault-tolerant, batch, stateless |

- **Reservation** = commit to a **specific** resource (best rate, least flexible).
- **Savings plan** = commit to an **hourly spend amount** (flexible across compute).

## 2. Azure Hybrid Benefit (AHB)
- Reuse on-prem **Windows Server / SQL Server** licenses (with Software Assurance) on Azure → big savings (don't pay for the OS/SQL license again). Stackable with reservations.

## 3. What drives cost (per service)
- **Compute**: size × hours × region; disks; bandwidth.
- **Storage**: GB stored × **tier** (Hot/Cool/Cold/Archive) + transactions + egress.
- **Networking**: **egress** (data out) is the sneaky cost; inter-region/zone transfer.
- **Managed services**: per request/RU/throughput unit (Cosmos RU/s, Service Bus ops, AOAI tokens).

## 4. Optimization levers
- **Rightsize** (Advisor: match SKU to utilization), **autoscale**, **schedule** non-prod off-hours.
- **Commit** (reservations/savings plans) for steady baseline; **spot** for interruptible.
- **Storage lifecycle** → auto-tier cold data to Cool/Archive.
- **Delete orphaned** (unattached disks, idle public IPs, old snapshots); **AHB**.
- Minimize **egress** (co-locate, caching/CDN, private peering).

## 5. Tooling
- **Pricing Calculator** (estimate), **TCO Calculator** (on-prem vs Azure), **Cost Management + Billing** (actuals, budgets, alerts, anomaly detection), **Azure Advisor** (cost recommendations).

## 6. The hard follow-ups (with answers)
1. **"Reservation vs savings plan?"** → RI = commit to specific SKU (max discount, rigid); savings plan = commit to $/hr compute spend (flexible across VM types). (§1)
2. **"Steady prod DB — cheapest?"** → **reservation** (1/3-yr). (§1)
3. **"Batch job that can be interrupted?"** → **spot** (up to ~90% off). (§1)
4. **"Already own Windows/SQL licenses?"** → **Azure Hybrid Benefit**. (§2)
5. **"Surprise bill culprit?"** → **egress** / untiered storage / orphaned resources. (§3/§4)
6. **"Find savings automatically?"** → **Advisor** + Cost Management anomaly alerts. (§5)
7. **"Estimate before building?"** → **Pricing / TCO Calculator**. (§5)

## 7. One-screen recall
- **Default consumption**; discount via **commitment** or **spot**.
- **Models**: PAYG (flex) · **Reservation** (specific SKU, max discount) · **Savings Plan** ($/hr, flexible) · **Spot** (evictable, ~90% off).
- **Azure Hybrid Benefit**: reuse Windows/SQL licenses.
- **Cost drivers**: compute hours, storage tier, **egress**, per-request managed services (RU/tokens).
- **Optimize**: rightsize + autoscale + schedule + commit + spot + tier storage + kill orphans + AHB + cut egress.
- **Tools**: Pricing/TCO Calculator, **Cost Management + Budgets**, **Advisor**.

> Next: Capacity Planning.

# DEEP MECHANICS · Cost Optimization & FinOps

> Level 2 — the FinOps operating model, the commitment-discount math
> (Reserved vs Savings Plan vs Spot), the real cost levers on compute/storage/
> egress, and how to control **GenAI token spend** — with the numbers.

---

## 0. The precise mental model
**FinOps** = a **cultural + operational practice** that brings **financial accountability** to the variable spend of cloud, so engineering, finance, and business make **data-driven trade-offs** between cost, speed, and quality. It's not "spend less" — it's **maximize business value per dollar**. The engine is a continuous loop: **Inform → Optimize → Operate.** As an architect you own the levers: **right-sizing, commitment discounts, elasticity/scale-to-zero, storage tiering, egress design**, and for GenAI, **token economics**.

---

## 1. The FinOps loop — the operating model
```
INFORM   → visibility & allocation: tagging, showback/chargeback,
           budgets, who-spends-what, unit cost ($/request, $/customer)
OPTIMIZE → right-size, commitments (RI/SP), autoscale/scale-to-zero,
           storage tiering, kill idle/orphaned resources
OPERATE  → continuous governance: policies, anomaly alerts, budget
           enforcement, forecasting, embed cost in engineering culture
```
**Phases of maturity:** Crawl → Walk → Run. The key idea: **cost is an engineering metric**, owned continuously — not a quarterly finance cleanup.

**Deep follow-up: "How do you make teams accountable for spend?"**
**Tagging** for allocation → **showback/chargeback** so each team sees its cost → **budgets + anomaly alerts** → put **unit-cost** ($/request) on dashboards next to latency. Accountability comes from visibility + ownership, not a central cost police.

---

## 2. Commitment discounts — the math (Reserved vs Savings Plan vs Spot)
This is the highest-value cost lever and the most-tested.

| | **Reserved Instances (RI)** | **Savings Plan** | **Spot** | **Pay-As-You-Go** |
|---|---|---|---|---|
| Commit | 1 or 3 yr, **specific** VM/family/region | 1 or 3 yr, **$/hr** across compute | none | none |
| Discount | up to ~**72%** | up to ~**65%** | up to ~**90%** | 0% (baseline) |
| Flexibility | low (locked to type) | **high** (any region/family) | high but **evictable** | total |
| Risk | underuse = wasted commit | underuse = wasted commit | **can be reclaimed anytime** | none |
| Use for | steady, predictable baseline | steady but changing mix | **fault-tolerant/batch** | spiky/unknown |

**The strategy — layer them by workload shape:**
```
Baseline (always-on)  → Reserved / Savings Plan   (deep discount, committed)
Variable steady       → Savings Plan               (flexible discount)
Bursty fault-tolerant → Spot                        (cheapest, interruptible)
Unpredictable spikes  → Pay-as-you-go / autoscale   (no commit)
```

**Worked example:** A VM at $1.00/hr PAYG runs 24/7 = **$8,760/yr**.
- 3-yr Reserved at ~65% off → ~$0.35/hr → **~$3,066/yr** (save ~$5,700/yr).
- Break-even: as long as utilization stays high (~>60–70%), the commitment wins. Below that, you've over-committed.

**Deep follow-up: "RI vs Savings Plan — when each?"**
RI when the workload is **stable and specific** (won't change VM family/region) for max discount. **Savings Plan** when you want the discount but need **flexibility** to change instance types/regions — you commit to $/hr, not a specific VM. Cover the **predictable baseline** with commitments; never commit for spiky/unknown load.

**Deep follow-up: "Why not put production on Spot to save 90%?"**
Spot VMs can be **reclaimed with ~30s notice** → only for **interruptible, fault-tolerant, stateless/batch** work (CI, batch inference, worker pools with checkpointing). Stateful/latency-critical production needs on-demand + commitments.

---

## 3. Compute levers beyond commitments
- **Right-sizing** — match SKU to actual utilization (metrics-driven); most cloud waste is oversized/idle VMs.
- **Autoscaling + scale-to-zero** — pay for what you use; serverless (Functions/Container Apps) and KEDA scale-to-zero eliminate idle cost for bursty/event work.
- **Kill orphans** — unattached disks, idle public IPs, old snapshots, stopped-but-allocated VMs, dev environments running nights/weekends (auto-shutdown).
- **Consolidation/bin-packing** — pack pods onto fewer nodes (AKS), use the cluster autoscaler to remove empty nodes.

**Deep follow-up: "Biggest source of cloud waste?"**
**Idle/oversized resources** — over-provisioned VMs, orphaned disks/IPs, non-prod running 24/7. Right-sizing + autoscaling + auto-shutdown + killing orphans usually beats chasing pricing discounts first.

---

## 4. Storage & egress — the quieter costs
- **Storage tiering** — Hot / Cool / Cold / Archive by access frequency; **lifecycle policies** auto-move old blobs to Archive → big savings on cold data. Archive is cheap to store, costly/slow to retrieve.
- **Data egress** — data **leaving** a region/cloud is charged (ingress is usually free). Design to **keep traffic in-region/same-zone**, use **Private Link/peering**, cache/CDN at the edge to cut egress. Cross-region chatty architectures leak money.
- **Retention** — logs/telemetry retention is a real cost (see observability sampling) — tier or expire old data.

**Deep follow-up: "Surprise $$ on the bill from data transfer — how do you cut it?"**
Localize traffic (same region/zone), use **Private Endpoints/peering** instead of public egress, add a **CDN/cache** for repeated reads, and consolidate cross-region chatter. Egress + inter-zone transfer are classic hidden costs.

---

## 5. GenAI cost control — token economics (the architect-differentiator)
LLM cost ≈ **(input tokens + output tokens) × price/token**, and output tokens usually cost **more**. Levers:
- **Model routing** — use a **small/cheap model** for easy requests, escalate to GPT-4-class only when needed. Biggest single saver.
- **Prompt/context trimming** — RAG retrieves **only top-k** relevant chunks instead of stuffing context; shorter system prompts.
- **Caching** — cache identical/similar responses (and use **prompt caching** where the provider discounts repeated prefixes) → avoid re-paying for the same tokens.
- **Cap output** — `max_tokens`, concise-output instructions.
- **PTU vs PAYG** — for **steady high volume**, **Provisioned Throughput Units** give predictable cost + latency; **PAYG** for spiky/low volume. (Same commit-vs-on-demand logic as VMs.)
- **Batch** where latency-tolerant (cheaper batch tiers).

**Deep follow-up: "Your GenAI app's bill is exploding — first moves?"**
Measure **cost per request** and token distribution. Then: **route** cheap requests to a small model, **trim context** (tighter RAG top-k + shorter prompts), **cache** repeats, **cap max_tokens**, and if volume is steady move to **PTU**. Attack tokens (input+output) — that's the cost.

---

## 6. Governance — keeping savings from eroding
- **Azure Budgets + Cost Management** — budgets with alert thresholds, cost analysis by tag.
- **Anomaly detection** — alert on unexpected spikes (a runaway job, a leaked key mining crypto).
- **Azure Policy** — enforce tagging, restrict expensive SKUs/regions, require auto-shutdown on dev.
- **Forecasting** — trend spend, feed capacity planning.
- **Unit economics** — track **$/transaction, $/customer, $/1k tokens** so cost scales with *value*, not just usage.

---

## 7. The hard follow-up questions (with answers)
1. **"What is FinOps?"** → cultural+operational practice for financial accountability of cloud spend; maximize value/$, loop Inform→Optimize→Operate. (§0–1)
2. **"RI vs Savings Plan vs Spot?"** → RI=locked specific (max discount), SP=flexible $/hr, Spot=cheapest but evictable; layer by workload shape. (§2)
3. **"Would you run prod on Spot?"** → only fault-tolerant/batch; reclaimable ~30s. (§2)
4. **"Biggest cloud waste?"** → idle/oversized resources → right-size + autoscale + kill orphans + auto-shutdown. (§3)
5. **"Cut a surprise data-transfer bill?"** → localize traffic, Private Link/peering, CDN/cache. (§4)
6. **"Control GenAI cost?"** → model routing, context trim, caching, cap output, PTU for steady volume. (§5)
7. **"Make teams accountable?"** → tagging → showback/chargeback → budgets/anomaly alerts → unit cost on dashboards. (§1,6)
8. **"Break-even on a reservation?"** → commit when baseline utilization stays high (~>60–70%); spiky load stays on-demand. (§2)

---

## 8. One-screen deep-recall sheet
- **FinOps** = financial accountability for variable cloud spend; **maximize value/$**, not just cut. Loop: **Inform (visibility/tagging/showback) → Optimize (right-size, commit, autoscale, tier) → Operate (govern, alert, forecast).** Crawl→Walk→Run.
- **Commitments**: **RI** (1/3yr, specific VM, ~72% off, low flex) · **Savings Plan** ($/hr, flexible, ~65%) · **Spot** (~90%, **evictable ~30s**, batch only) · **PAYG** (baseline). **Layer: baseline→commit, bursty-tolerant→Spot, spiky→PAYG/autoscale.**
- **Break-even**: commit for **high-utilization predictable baseline**; underuse wastes the commitment.
- **Compute waste**: oversized/idle VMs, orphaned disks/IPs, non-prod 24/7 → **right-size + autoscale/scale-to-zero + auto-shutdown + kill orphans**.
- **Storage/egress**: Hot/Cool/Archive **tiering + lifecycle**; **egress (leaving region) is charged** → localize, Private Link/peering, CDN/cache.
- **GenAI tokens** (cost = (in+out tokens)×price, output pricier): **model routing** (small→large), **context trim (RAG top-k)**, **caching/prompt caching**, **cap max_tokens**, **PTU** for steady volume, batch tiers.
- **Governance**: Budgets + Cost Mgmt, **anomaly alerts**, Azure **Policy** (tagging/SKU/region), forecasting, **unit economics ($/req, $/customer, $/1k tokens)**.

---

> You've reached the end of the Level-2 high-ROI deep dives. Cycle back through the
> §9/§10 recall sheets — those are your day-before-interview crib.

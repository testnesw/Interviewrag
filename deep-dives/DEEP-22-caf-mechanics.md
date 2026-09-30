# DEEP MECHANICS · Cloud Adoption Framework (CAF)

> Level 2 — what CAF actually is, its methodologies, and how it differs from
> WAF and landing zones.

---

## 0. The precise mental model
CAF = Microsoft's **end-to-end guidance for the cloud journey at an organizational level** — people, process, and governance from "why cloud" to "operate at scale." It answers **"how does an enterprise adopt Azure responsibly?"** WAF (next topic) is about **one workload's technical quality**; CAF is about **the whole estate and organization**.

---

## 1. The methodologies (the lifecycle)
```
Strategy → Plan → Ready → Adopt (Migrate/Innovate) → Govern → Manage → Secure
```
- **Strategy** — business motivations, outcomes.
- **Plan** — digital estate inventory, skilling, roadmap.
- **Ready** — the **landing zone** (foundation environment).
- **Adopt** — **Migrate** (move workloads) + **Innovate** (build new).
- **Govern** — policies, cost, security, compliance guardrails (continuous).
- **Manage** — operations, monitoring, reliability (continuous).
- **Secure** — security posture across the estate.

## 2. Governance disciplines
Cost management, security baseline, identity baseline, resource consistency, deployment acceleration. Enforced via **Azure Policy, management groups, RBAC, blueprints** → guardrails not gates.

## 3. CAF vs WAF vs Landing Zone
- **CAF** — organizational adoption journey (broad, process + governance).
- **Landing Zone** — the **implementation** of CAF's "Ready" phase: the pre-built, governed environment.
- **WAF** — technical best practices for **individual workloads** (5 pillars).
They nest: CAF (org) → Landing Zone (foundation) → WAF (each workload).

## 4. The hard follow-ups (with answers)
1. **"What is CAF?"** → org-level cloud-adoption guidance across the lifecycle (Strategy→Manage). (§1)
2. **"CAF vs WAF?"** → whole-org adoption/governance vs single-workload technical quality. (§3)
3. **"Where do landing zones fit?"** → CAF's "Ready" phase implementation. (§3)
4. **"How is governance enforced?"** → Policy + management groups + RBAC (guardrails). (§2)

## 5. One-screen recall
- **CAF** = org-level adoption journey: **Strategy→Plan→Ready→Adopt(Migrate/Innovate)→Govern→Manage→Secure**.
- **Ready = landing zone**; **Govern/Manage/Secure** are continuous.
- Governance disciplines via **Policy + mgmt groups + RBAC** (guardrails).
- Nesting: **CAF (org) → Landing Zone (foundation) → WAF (workload)**.

> Next: Well-Architected Framework.

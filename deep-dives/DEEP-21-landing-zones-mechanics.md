# DEEP MECHANICS · Azure Landing Zones

> Level 2 — management group hierarchy, platform vs application landing zones,
> subscription democratization, and policy-driven governance.

---

## 0. The precise mental model
A landing zone = a **pre-provisioned, governed Azure environment** built to CAF standards so teams can deploy workloads **safely and consistently from day one**. It's "the foundation slab + utilities" before you build houses: **identity, networking, governance, security, and management** are already wired, enforced by **policy** at the **management-group** level. Scale unit = the **subscription**.

---

## 1. The management group hierarchy
```
Tenant Root
└─ Contoso (top mgmt group)
   ├─ Platform         → Identity, Management, Connectivity subscriptions
   ├─ Landing Zones    → Corp (internal), Online (internet-facing) app subs
   ├─ Sandbox          → experimentation
   └─ Decommissioned
```
- **Management groups** organize subscriptions and are where **Azure Policy + RBAC** are assigned → **inherited** downward.
- **Platform** = shared services; **Landing Zones** = where apps live.

## 2. Platform vs application landing zones
- **Platform landing zone** — shared foundation: **Connectivity** (hub VNet, firewall, ExpressRoute/VPN, DNS), **Identity** (DCs/Entra), **Management** (Log Analytics, automation).
- **Application (workload) landing zone** — a subscription handed to a team, pre-governed, where they deploy their workload.

## 3. Subscription democratization
Subscriptions become the **unit of scale/isolation** given to teams, but pre-wired with guardrails (policy, networking peered to hub, monitoring). Teams move fast **within** guardrails → autonomy + governance.

## 4. The design areas (8)
Enterprise enrollment, identity, **network topology (hub-spoke/vWAN)**, **resource organization (mgmt groups)**, **governance (policy)**, operations/management, **security**, platform automation (IaC/Bicep/Terraform). These are the pillars you configure.

## 5. Policy-driven guardrails
**Azure Policy** enforces standards automatically: allowed regions, required tags, deny public IPs, enforce encryption, deploy diagnostics (DeployIfNotExists). Assigned at mgmt-group scope → applies to all child subs → **governance at scale** without manual review.

## 6. Implementation options
- **Accelerator** (portal/Bicep/Terraform reference implementation) deploys the whole hierarchy.
- Start small (a few mgmt groups) and expand.

## 7. The hard follow-ups (with answers)
1. **"What's a landing zone?"** → pre-governed foundation environment (identity/network/governance) for safe day-1 deploys. (§0)
2. **"Platform vs application landing zone?"** → shared foundation (connectivity/identity/mgmt) vs per-team workload subscription. (§2)
3. **"Where is governance enforced?"** → Azure Policy + RBAC at **management-group** scope, inherited to subscriptions. (§1,5)
4. **"What is subscription democratization?"** → subs as scale/isolation units handed to teams within pre-wired guardrails. (§3)
5. **"How do you enforce standards at scale?"** → Policy (allowed regions, tags, deny public IP, DeployIfNotExists diagnostics). (§5)

## 8. One-screen recall
- Landing zone = **pre-governed Azure foundation** (identity/network/governance/security/mgmt) for safe day-1 deploys, CAF "Ready".
- **Management-group hierarchy** (Platform / Landing Zones / Sandbox / Decommissioned) → **Policy + RBAC inherited** downward.
- **Platform LZ** (Connectivity/Identity/Management shared subs) vs **Application LZ** (per-team workload sub).
- **Subscription democratization** = subs as scale/isolation units within guardrails.
- **8 design areas**; **Azure Policy** = automated guardrails (regions/tags/deny public IP/DeployIfNotExists).
- Deploy via **accelerator** (Bicep/Terraform).

> Next: Hub-Spoke.

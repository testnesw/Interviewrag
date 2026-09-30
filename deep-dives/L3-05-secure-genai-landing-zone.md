# LEVEL 3 · System Design — Secure & Compliant GenAI Landing Zone

> Synthesis scenario. Combines: landing zones · networking · Entra · Key Vault ·
> private endpoints · Defender · policy · data residency.

---

## 0. The prompt
> *"A regulated bank wants to adopt GenAI. Design the secure Azure foundation (landing zone) so any team can build AI apps that are compliant by default: no data exfiltration, full audit, data stays in-region, least privilege."*

---

## 1. Clarify — requirements
**Functional**: multiple teams deploy AI workloads (RAG, agents, APIs) onto a shared secure platform.
**Non-functional**: **compliance** (data residency, audit, encryption), **network isolation** (no public data paths), least privilege, centralized governance + cost.
**Killer constraints**: **"compliant by default"** + **no data leaves the boundary** (AOAI + data all private).

## 2. Architecture — hub-spoke landing zone
```
Management Group hierarchy (Azure Policy enforced)
  │
  ├─ HUB VNet: Azure Firewall, DNS, ExpressRoute/VPN, shared services
  │     └─ private DNS zones for AOAI/Storage/Search/Key Vault
  │
  └─ SPOKE VNets (per team/workload), peered to hub:
        AOAI (private endpoint) · AI Search (PE) · Storage (PE)
        · Key Vault (PE) · compute (AKS/Container Apps)
        egress forced through Firewall (no direct internet)
```

## 3. Key design decisions (with "why")
- **Landing zone via CAF**: management groups + **Azure Policy** → guardrails enforced org-wide (deny public IPs, require private endpoints, allowed regions, required tags, encryption). "Compliant by default" = policy, not hope.
- **Hub-spoke networking**: shared security (firewall, DNS, connectivity) in hub; isolated workloads in spokes → blast-radius isolation + central egress control.
- **Everything private**: **private endpoints** on AOAI, AI Search, Storage, Key Vault → traffic never touches public internet; **private DNS** resolves them internally.
- **Forced tunneling**: spoke egress → **Azure Firewall** → allow-list only approved FQDNs → prevents data exfiltration.
- **Identity**: **Entra ID** + **Managed Identity** everywhere (zero stored secrets); **RBAC least privilege**; **PIM** for admin JIT.
- **Data residency**: pin all services to the required region; AOAI in-region; confirm no training on customer data.

## 4. Security layers (defense in depth)
- **Perimeter**: Firewall + WAF (Front Door/App Gateway) + DDoS.
- **Identity**: Entra + Conditional Access (MFA, device compliance) + PIM + RBAC/ABAC.
- **Data**: encryption at rest (CMK in **Key Vault**), TLS in transit, **Content Safety** on AI I/O.
- **Secrets**: Key Vault (private endpoint, soft-delete, RBAC).
- **Posture**: **Defender for Cloud** (secure score, compliance dashboard mapping to PCI/ISO) + **Sentinel** SIEM.

## 5. Governance & operations
- **Azure Policy** initiatives (regulatory compliance built-in) → auto-audit + deny non-compliant deploys.
- **Central logging**: all diagnostic logs → central Log Analytics; **immutable audit** of AI usage (who asked what, sources).
- **Cost**: subscription-per-workload + tags → chargeback (FinOps); budgets + alerts.
- **IaC**: everything as **Terraform/Bicep** (reviewed, scanned with tfsec, policy-gated) → reproducible + auditable.

## 6. AI-specific compliance
- **Content Safety** mandatory (guardrails); prompt-injection shields.
- **Audit every prompt/response** + retrieved sources → traceability for regulators.
- **Responsible AI**: fairness/groundedness eval, human oversight for high-impact decisions, model/version registry.
- **Data governance**: classify/label source data; permission trimming in retrieval; PII detection/redaction.

## 7. The follow-ups
1. **"How is it 'compliant by default'?"** → **Azure Policy** guardrails deny non-compliant resources org-wide (private endpoints, regions, encryption, tags). (§3)
2. **"Stop data exfiltration?"** → private endpoints + **forced tunneling through Firewall** with FQDN allow-list. (§3)
3. **"No secrets anywhere?"** → **Managed Identity** + Key Vault (private). (§3)
4. **"Prove PCI/ISO compliance?"** → **Defender for Cloud** regulatory compliance dashboard + audit logs. (§4/§5)
5. **"Data residency?"** → pin services to region + AOAI in-region + no-training confirmation. (§3)
6. **"Isolate teams?"** → spoke-per-workload + RBAC + subscription boundaries. (§2)
7. **"Regulator asks 'who saw this data?'"** → immutable audit of prompts/responses/sources + retrieval ACL trimming. (§6)
8. **"Admin access safely?"** → **PIM** JIT + Conditional Access + MFA. (§4)

## 8. One-screen recall
- **CAF landing zone**: management groups + **Azure Policy** = compliant-by-default guardrails.
- **Hub-spoke**: shared firewall/DNS/connectivity in hub; isolated spokes; **forced tunneling** egress control.
- **All private**: **private endpoints** + private DNS on AOAI/Search/Storage/Key Vault → no public paths.
- **Identity**: Entra + **MI** (no secrets) + RBAC/ABAC + **PIM** + Conditional Access.
- **Data**: CMK encryption, **Content Safety**, PII redaction, **audit every prompt/source**.
- **Posture**: **Defender** (compliance dashboard) + **Sentinel**; **IaC** policy-gated; tags → FinOps.

> Next L3: LLMOps / Evaluation Platform.

# Deep Dive · Azure Security (Entra ID · Managed Identity · Key Vault · RBAC · Defender)

> Phase 3 (Azure foundation) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Azure security is built on **zero trust**: verify explicitly, use least privilege, assume breach. The pillars are **Entra ID** (identity/authN — SSO, MFA, Conditional Access), **RBAC** (authorization — who can do what, at what scope), **Managed Identity** (passwordless service-to-service auth — no secrets), **Key Vault** (secrets/keys/certs with access policies/RBAC), **PIM** (just-in-time privileged access), and **Defender for Cloud + Sentinel** (posture management + SIEM/threat detection). For GenAI you combine these to make Azure OpenAI/data **private, identity-gated, keyless, and monitored**.

---

## 2. Architect-Level Explanation
Layered controls:
- **Identity (Entra ID)**: users/groups/service principals/managed identities; **MFA + Conditional Access** (device/location/risk-based); **OAuth2/OIDC** tokens for apps.
- **Authorization (RBAC)**: role assignments (built-in/custom) at **management group → subscription → resource group → resource** scope; least privilege.
- **Managed Identity**: system- or user-assigned; app gets Entra tokens with **no stored credentials** — the keyless standard (Workload Identity on AKS).
- **Key Vault**: central store for secrets/keys/certs; **RBAC or access policies**; **soft-delete + purge protection**; private endpoint; HSM (Premium).
- **PIM**: eligible vs active roles; time-bound, approval-gated, audited elevation.
- **Defender for Cloud**: CSPM (secure score, misconfig), workload protection (servers, containers, DBs, AI).
- **Sentinel**: cloud-native SIEM/SOAR — analytics, hunting, automated response.
- **Policy** (from ALZ) enforces the above at scale.

Goal: **defense in depth + zero trust** across identity, network, data, and workload.

---

## 3. Why It Exists
- **Problem**: passwords/keys leak, over-permissioned identities and flat trust cause breaches; cloud scale makes manual security impossible.
- **Breakthrough**: **identity as the control plane** (zero trust) + **passwordless (Managed Identity)** + **centralized secrets** + **automated posture/threat detection**.
- **Why enterprises adopt it**: eliminate stored secrets, enforce least privilege and MFA everywhere, prove compliance, and detect/respond to threats.
- **GenAI/regulated angle**: keyless access to AOAI, private data paths, audited privileged access, and continuous compliance are typically mandatory.

---

## 4. Internal Working
**Keyless service-to-service (the core pattern):**
```
1. App runs with a Managed Identity (system/user-assigned; on AKS = Workload Identity federation)
2. App requests a token from the Entra token endpoint (via IMDS / federated cred) — no secret
3. Entra issues a scoped OAuth2 token for the target (e.g., Azure OpenAI, Key Vault)
4. App calls the resource with the bearer token
5. RBAC on the resource authorizes the identity (e.g., "Cognitive Services OpenAI User")
6. Access is logged (Entra sign-ins, resource logs) → Sentinel/Log Analytics
```
Other mechanics:
- **Conditional Access** evaluates each sign-in (risk/device/location) → allow/MFA/block.
- **PIM** activation: eligible → request → (approval/MFA) → time-bound active role → auto-expire.
- **Key Vault**: RBAC/policy checks per operation; soft-delete keeps deleted secrets recoverable.

---

## 5. Enterprise Use Case
A GenAI platform: app pods on AKS use **Workload Identity** (no secrets) to call **Azure OpenAI** (RBAC: *Cognitive Services OpenAI User*) and **Key Vault** (RBAC: *Key Vault Secrets User*) — both via **Private Endpoints**. Human access to prod is **eligible-only via PIM** (JIT, MFA, approval, audited). **Conditional Access** enforces MFA + compliant devices. **Defender for Cloud** watches posture (and Defender for AI flags prompt-injection/anomalies); **Sentinel** correlates sign-in + resource logs for threat detection. Zero stored secrets, least privilege, full audit.

---

## 6. Real Production Architecture
```
 User ─► Entra ID (MFA + Conditional Access) ─► app
 Admin ─► PIM (JIT, approval, MFA, time-bound) ─► elevated role
        │
   App (Managed Identity / Workload Identity — NO secrets)
        │ Entra token (scoped, RBAC-authorized)
        ▼
   Azure OpenAI (PE) · Key Vault (PE, soft-delete) · Storage/SQL (PE)
        │ all logs
        ▼
   Defender for Cloud (CSPM + workload) · Sentinel (SIEM) · Log Analytics (audit)
   Azure Policy (from ALZ) enforces: no keys, encryption, private, MFA
```

---

## 7. Security Best Practices (the checklist)
- **Passwordless**: Managed/Workload Identity everywhere; **eliminate keys/connection strings**.
- **Least privilege RBAC**: assign at the narrowest scope; prefer built-in roles; custom roles sparingly; **no standing Owner/Contributor**.
- **PIM** for all privileged roles: eligible + JIT + approval + MFA + expiry + audit.
- **Conditional Access**: require MFA, compliant/managed devices, block risky sign-ins/legacy auth.
- **Key Vault**: RBAC data plane, **soft-delete + purge protection**, private endpoint, rotation, HSM for high-value keys.
- **Encryption** at rest (CMK where required) + in transit (TLS1.2+).
- **Private networking** (Private Endpoints, disable public access).
- **Defender for Cloud** on all workloads + **Sentinel** for detection/response; centralized logging + retention.
- **Secret scanning** in CI; no secrets in code/images.

---

## 8. Scaling Strategy
- **Groups + RBAC at management-group scope** (via ALZ) scale authorization to hundreds of subscriptions.
- **User-assigned Managed Identities** shared across workloads where appropriate.
- **Policy-as-code** enforces security posture automatically as new resources appear.
- **Sentinel** scales analytics across the estate; automation (playbooks) for response.
- **Central Key Vaults per environment** with RBAC (avoid vault sprawl).

---

## 9. High Availability Strategy
- **Entra ID** is a global, highly-available Microsoft service.
- **Key Vault**: regionally redundant + **failover**; use availability zones; multiple vaults per region if needed.
- **Managed Identity/token endpoints** are platform-HA.
- Design apps to **retry token acquisition** and cache tokens appropriately.

---

## 10. Disaster Recovery Strategy
- **Key Vault soft-delete + purge protection + backup** (per-secret backup/restore) and geo-redundancy.
- **RBAC/policy as IaC** → reapply in secondary region.
- **Entra config** (Conditional Access, PIM) exported/version-controlled where possible.
- **Sentinel/Log Analytics** retention + export for post-incident/DR forensics.

---

## 11. Cost Optimization Strategy
- **Right-size Defender plans** (enable per resource type that needs it; not blanket if budget-constrained).
- **Sentinel ingestion cost**: filter/route noisy logs, use basic logs tier, commitment tiers.
- **Log Analytics** retention tuning + archive for cheap long-term storage.
- **Key Vault Standard vs Premium (HSM)** — HSM only for keys that need it.
- **Managed Identity is free** and removes secret-management overhead/cost.

---

## 12. Common Production Challenges
- **Over-permissioned identities** (standing Owner) → least privilege + PIM.
- **Leaked keys/secrets in code/repos** → go keyless (Managed Identity) + secret scanning.
- **RBAC at wrong scope** → too broad access; assign narrowly.
- **Key Vault throttling** under high secret fetch → cache secrets, use Managed Identity token caching.
- **Conditional Access lockouts** (break-glass missing) → maintain emergency access accounts.
- **Alert fatigue** in Sentinel/Defender → tune analytics, automate triage.
- **Public access left on PaaS** → policy deny + private endpoints.

---

## 13. Monitoring and Observability
- **Entra sign-in + audit logs** → Log Analytics/Sentinel (who/where/risk).
- **Defender for Cloud secure score + recommendations + regulatory compliance** dashboards.
- **Sentinel** analytics rules, hunting, incidents, SOAR playbooks.
- **Key Vault/resource diagnostic logs** (access, operations).
- **Alerts**: risky sign-ins, privilege escalations, secret access anomalies, policy non-compliance.

---

## 14. Troubleshooting Scenarios
- **App gets 403 to AOAI/Key Vault** → missing/incorrect RBAC role on the Managed Identity; assign correct role at right scope; check token audience.
- **Managed Identity token fails** → IMDS/Workload Identity federation misconfig (issuer/subject/service account); verify federation.
- **Key Vault access denied** → RBAC vs access-policy mismatch or private DNS; align model + network.
- **User blocked** → Conditional Access policy; check sign-in logs for the failing control.
- **PIM activation fails** → not eligible/approval pending/MFA; verify assignment + approver.
- **Secret suddenly missing** → deleted but recoverable via soft-delete; restore.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| PIM (JIT) | least standing privilege | activation friction |
| Strict Conditional Access | strong authN | user friction/lockout risk |
| Private everything | no exposure | DNS/network complexity |
| Full Defender/Sentinel | detection | cost |

---

## 16. When NOT to use (or over-apply)
- **Access policies over RBAC on Key Vault** for new deployments → prefer RBAC (simpler at scale) unless legacy.
- **Custom roles** when a built-in role fits → avoid maintenance burden.
- **Blanket Defender plans** on a tight budget → enable where risk warrants.
- **Over-strict CA without break-glass** → operational risk.
- Security is rarely "not used" — but **right-size** to risk/compliance.

---

## 17. Comparison with Alternatives
| Concern | Azure-native | Alternative | When |
|---------|--------------|-------------|------|
| Identity | Entra ID | Okta/Auth0 | existing IdP/federation |
| Secrets | Key Vault | HashiCorp Vault | multi-cloud/advanced |
| Passwordless | Managed Identity | Service Principal + secret | non-Azure callers only |
| SIEM | Sentinel | Splunk/QRadar | existing SOC tooling |
| Posture | Defender for Cloud | Wiz/Prisma | multi-cloud CNAPP |

---

## 18. Interview Questions
1. Explain zero trust and how Azure implements it.
2. Managed Identity vs Service Principal — when each?
3. How does keyless access to Azure OpenAI work end-to-end?
4. RBAC scopes and least-privilege design?
5. What is PIM and why use it?
6. Conditional Access — what and why?
7. Key Vault security (RBAC, soft-delete, private endpoint)?
8. Defender for Cloud vs Sentinel?
9. How do you secure a GenAI platform end-to-end?
10. How do you eliminate secrets entirely?

---

## 19. Strong Interview Answers
- **Zero trust**: "Verify explicitly, least privilege, assume breach. In Azure: Entra + MFA + Conditional Access for identity, RBAC least privilege for authorization, Managed Identity to remove secrets, Private Endpoints for network, and Defender/Sentinel assuming breach with detection and response."
- **Managed Identity vs SP**: "Managed Identity is an Entra identity Azure manages for you — no credentials to store or rotate; ideal for Azure-hosted workloads (Workload Identity on AKS). A Service Principal needs a secret/cert you must protect and rotate — I only use it for non-Azure or external callers. Default to Managed Identity."
- **Keyless AOAI**: "The app's Managed Identity requests a scoped Entra token (no secret), calls Azure OpenAI, and RBAC (*Cognitive Services OpenAI User*) authorizes it. No keys anywhere; every call is attributable and logged."
- **PIM**: "Privileged roles are *eligible*, not permanently active. Admins activate just-in-time with MFA and approval, time-bound and fully audited — eliminating standing privilege, the biggest blast-radius risk."
- **Defender vs Sentinel**: "Defender for Cloud is CSPM + workload protection — secure score, misconfig, threat protection for resources. Sentinel is the SIEM/SOAR — correlates logs across the estate, hunts, and automates response. They complement: posture + detection/response."

---

## 20. Architecture Diagrams
**Zero-trust access flow:**
```
Identity (Entra+MFA+CA) ─► token ─► RBAC check (scope) ─► Resource (private)
Managed Identity = no secret · PIM = JIT elevation · everything logged → Sentinel
```

---

## 21. Real Project Example
**Keyless, audited GenAI platform.** Every service uses Workload Identity — zero secrets in code/images (verified by CI secret scanning). RBAC grants each identity only its needed role at resource scope. Human prod access is PIM-only (JIT + approval + MFA), Conditional Access enforces compliant devices + MFA. AOAI/Key Vault/Storage are private. Defender for Cloud drove secure score from 62%→94%; Sentinel playbooks auto-disable risky sign-ins. An audit passed cleanly: no standing privilege, no secrets, full traceability.

---

## 22. Whiteboard Design Question
> *"Design end-to-end security (zero trust) for a regulated GenAI platform."*

Cover: Entra + MFA + Conditional Access → RBAC least privilege at MG/RG scope → Managed/Workload Identity (keyless) to AOAI/Key Vault/data → Private Endpoints + disable public → Key Vault (RBAC, soft-delete, purge protection, rotation, HSM) → PIM for all privileged access → Defender for Cloud (posture + AI/containers) + Sentinel (SIEM/SOAR) → Policy enforcing all of it (ALZ) → central logging + retention for audit → break-glass accounts. Map controls to compliance (encryption, residency, audit).

---

## 23. Design Review Questions
- Any **stored secrets/keys**? Can they be replaced by **Managed Identity**?
- **RBAC** least privilege at correct scope; any standing Owner/Contributor?
- **PIM** on all privileged roles; break-glass accounts exist?
- **Conditional Access**: MFA + device compliance + legacy-auth blocked?
- **Key Vault**: RBAC + soft-delete + purge protection + private endpoint + rotation?
- **Private endpoints** + public access disabled on sensitive PaaS?
- **Defender + Sentinel** enabled; logs centralized + retained?
- **Policy** enforcing the posture automatically?

---

## 24. Hands-on Example
```bash
# Keyless: give a workload's Managed Identity least-privilege access to AOAI + Key Vault
APP_MI=$(az identity show -g rg -n genai-wi --query principalId -o tsv)
az role assignment create --assignee $APP_MI --role "Cognitive Services OpenAI User" \
  --scope $(az cognitiveservices account show -n my-aoai -g rg --query id -o tsv)
az role assignment create --assignee $APP_MI --role "Key Vault Secrets User" \
  --scope $(az keyvault show -n genai-kv --query id -o tsv)
# Harden the vault
az keyvault update -n genai-kv --enable-purge-protection true --enable-soft-delete true \
  --public-network-access Disabled --enable-rbac-authorization true
```

---

## 25. Terraform Example
```hcl
resource "azurerm_key_vault" "kv" {
  name = "genai-kv" resource_group_name = var.rg location = var.location
  tenant_id = var.tenant_id  sku_name = "premium"          # HSM-backed keys
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  public_network_access_enabled = false
}
# Least-privilege, keyless access for the workload identity
resource "azurerm_role_assignment" "kv_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_principal_id
}
# Code (no secrets): use DefaultAzureCredential in the app to auth via Managed Identity
```

---

## 26. Azure Example
```bash
# Make a privileged role eligible via PIM (JIT) instead of a standing assignment
az role assignment create --assignee $ADMIN_OID --role "Contributor" \
  --scope /subscriptions/$SUB --description "temp" # (replace with PIM eligible assignment in portal/Graph)
# Require MFA + compliant device via a Conditional Access policy (Graph/portal)
# Enable Defender for Cloud plan for AI + containers
az security pricing create -n CloudPosture --tier Standard
az security pricing create -n Containers   --tier Standard
```

---

## 27. Code Example
```python
# Passwordless access to Azure OpenAI + Key Vault using DefaultAzureCredential (no secrets)
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from openai import AzureOpenAI

cred = DefaultAzureCredential()              # uses Managed/Workload Identity in Azure
kv = SecretClient(vault_url="https://genai-kv.vault.azure.net", credential=cred)

def token_provider():                        # keyless bearer token for AOAI
    return cred.get_token("https://cognitiveservices.azure.com/.default").token

client = AzureOpenAI(
    azure_endpoint="https://my-aoai.openai.azure.com",
    azure_ad_token_provider=token_provider,  # RBAC authorizes the identity
    api_version="2024-08-01-preview",
)
```

---

## 28. Things Architects Must Remember
- **Zero trust**: verify explicitly, least privilege, assume breach.
- **Go keyless**: Managed/Workload Identity everywhere — the #1 secret-elimination move.
- **Least-privilege RBAC** at the narrowest scope; no standing Owner/Contributor.
- **PIM** for JIT privileged access + break-glass accounts.
- **Conditional Access**: MFA + device compliance + block legacy/risky sign-ins.
- **Key Vault**: RBAC + soft-delete + purge protection + private endpoint + rotation; HSM for high-value keys.
- **Private-by-default** PaaS + encryption (CMK where required).
- **Defender (posture) + Sentinel (detection/response)** + central logging = assume-breach.

---

## 29. Mnemonics and Memory Tricks
- **Zero trust "V-L-A"**: **V**erify explicitly, **L**east privilege, **A**ssume breach.
- **"Managed Identity = no password to lose."**
- **Key Vault "R-S-P-P"**: **R**BAC, **S**oft-delete, **P**urge protection, **P**rivate endpoint.
- **PIM = "borrow power, then give it back"** (JIT).
- **"Defender watches posture; Sentinel hunts threats."**

---

## 30. One-Page Interview Revision Sheet
- **Identity**: Entra ID + MFA + Conditional Access (device/location/risk); OAuth2/OIDC.
- **AuthZ**: RBAC least privilege at MG→sub→RG→resource; built-in roles preferred.
- **Keyless**: Managed Identity (system/user) / Workload Identity (AKS) → no secrets; SP only for external.
- **Secrets**: Key Vault — RBAC, soft-delete, purge protection, private endpoint, rotation, HSM (Premium).
- **Privileged access**: PIM (eligible + JIT + approval + MFA + expiry + audit); break-glass accounts.
- **Detection**: Defender for Cloud (CSPM + workload + AI/containers) + Sentinel (SIEM/SOAR); central logs.
- **Network/data**: Private Endpoints, disable public, TLS1.2+, encryption (CMK).
- **Enforcement**: Azure Policy (ALZ) makes it automatic.
- **Remember**: **V-L-A** zero trust; go keyless; **R-S-P-P** Key Vault; PIM = borrow power; Defender posture / Sentinel hunts.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Define zero trust and map each principle to a concrete Azure control.
2. Managed Identity vs Service Principal — when is an SP unavoidable?
3. Walk keyless AOAI access from token request to RBAC authorization.
4. Design least-privilege RBAC for a 10-team GenAI platform without standing admins.
5. What is PIM and how does it shrink blast radius? Include break-glass.
6. Your app gets 403 from Key Vault. Full diagnostic path.
7. Harden a Key Vault to regulated standard — list every setting.
8. Defender for Cloud vs Sentinel — responsibilities and how they work together.
9. Prove to an auditor there are no stored secrets and no standing privilege.
10. Design Conditional Access that's strong but won't lock the company out.

---

> 🎉 **Phase 3 complete!** Next: **Phase 4 — Terraform, GitHub Actions, Azure DevOps.**

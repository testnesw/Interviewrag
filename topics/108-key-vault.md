# 108 · Azure Key Vault

> Domain: Security & Identity · Level: Principal Security / Identity Architect

## 1. Beginner Explanation
Azure Key Vault is a **secure store for secrets, keys, and certificates** — like API keys, passwords, connection strings, and encryption keys. Apps fetch what they need at runtime instead of hard-coding sensitive values, and access is controlled and audited.

## 2. Architect-Level Explanation
A managed service for centralized secrets, key, and certificate management:
- **Three object types**: **Secrets** (passwords, connection strings, API keys), **Keys** (asymmetric/symmetric crypto keys — encrypt/decrypt/sign, wrap/unwrap, CMK for other services), **Certificates** (TLS certs with lifecycle + auto-renewal via integrated CAs).
- **Access models**: **RBAC** (recommended — Entra roles like Key Vault Secrets User/Officer) vs legacy **access policies**.
- **Authentication**: **Managed Identity** (no bootstrap secret) → the pattern that closes the "secret-zero" problem.
- **Tiers**: Standard (software-protected) vs **Premium** (**HSM**-backed, FIPS 140-2 Level 2/3); **Managed HSM** (dedicated single-tenant HSM pool) for high compliance.
- **Security**: **private endpoints**, firewall/VNet, **soft delete + purge protection** (mandatory-ish), RBAC least privilege, logging/audit.
- **Integrations**: App Service/Functions **Key Vault references**, AKS **CSI Secrets Store driver**, disk encryption, TLS for App Gateway/APIM, CMK for Storage/SQL/Cosmos/Databricks.
- **Rotation**: automated secret/key rotation + event notifications (Event Grid) for near-expiry.
- **Versioning**: every secret/key/cert is versioned; reference latest or pinned version.
- **Not for**: high-throughput per-request secret reads without caching (throttling) — cache tokens/secrets.

## 3. Real Enterprise Use Case
An enterprise centralizes all secrets/keys/certs in Key Vault (Premium/HSM): apps and AKS pods use **Managed Identity** to fetch DB connection strings and certs (no secrets in code/pipelines), Storage/SQL use **CMK** from the vault, TLS certs auto-renew, secrets **auto-rotate** with Event Grid alerts, and access is RBAC least-privilege behind **private endpoints** with full audit to Sentinel — soft delete + purge protection prevent tampering.

## 4. Architecture Diagram (ASCII)
```
   App / AKS pod ──(Managed Identity, no secret)──► Key Vault (private endpoint)
        │ RBAC: Key Vault Secrets User
        ▼
   ┌──────────┬──────────┬───────────────┐
   Secrets    Keys        Certificates
   (conn str) (CMK/HSM)   (TLS, auto-renew)
   Soft delete + purge protection | versioning | audit ─► Sentinel
   Consumers: App Service KV refs · AKS CSI driver · Storage/SQL CMK · Event Grid (rotation)
```

## 5. Interview Questions
1. What are the three object types in Key Vault?
2. RBAC vs access policies?
3. How do you authenticate to Key Vault without a secret?
4. Standard vs Premium vs Managed HSM?
5. How do you handle rotation, soft delete, and throttling?

## 6. Strong Interview Answers
- **Objects**: "Secrets (arbitrary sensitive strings like connection strings/API keys), Keys (cryptographic keys for encrypt/sign/wrap and as CMK for other services), and Certificates (TLS certs with managed lifecycle and auto-renewal). Different object types with tailored operations and permissions."
- **RBAC vs policies**: "**RBAC** (Entra roles scoped to vault or object) is recommended — consistent with Azure-wide RBAC, granular, and auditable. Legacy **access policies** are per-vault permission lists, harder to manage at scale. I use RBAC with least-privilege roles like Secrets User (read) vs Secrets Officer (manage)."
- **No secret auth**: "**Managed Identity** — the app gets an Entra token via its managed identity and calls Key Vault, which authorizes via RBAC. This solves the **secret-zero / bootstrap** problem: you don't need a secret to get your secrets."
- **Tiers**: "Standard is software-protected; **Premium** is HSM-backed (FIPS 140-2 L2) for keys needing hardware protection; **Managed HSM** is a dedicated single-tenant HSM pool (FIPS L3) for strict compliance/sovereign-key scenarios. I pick by regulatory + key-protection requirements."
- **Rotation/soft delete/throttling**: "Enable **automated rotation** with Event Grid near-expiry events, and integrate auto-renewing certs. **Soft delete + purge protection** guard against accidental/malicious deletion (recoverable within retention). Key Vault has request limits, so I **cache** secrets/tokens in the app rather than fetching per request to avoid throttling."

## 7. Common Mistakes
- Secrets in code/config instead of Key Vault + Managed Identity.
- Legacy access policies over RBAC at scale.
- Fetching secrets per request → throttling (no caching).
- No purge protection/soft delete → irrecoverable deletion.
- Public network access; over-broad roles.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Premium/HSM | hardware protection, compliance | higher cost |
| RBAC | granular, consistent | migration from policies |
| Caching secrets | avoids throttling | staleness on rotation |

## 9. Production Best Practices
- Managed Identity + RBAC least privilege; no secrets in code.
- Private endpoints + firewall; soft delete + purge protection.
- Automated rotation + Event Grid alerts; auto-renew certs.
- Cache secrets/tokens (respect throttling); reference latest carefully.
- CMK for data services; audit logs → Sentinel; IaC.

## 10. Security Considerations
- Managed Identity (no bootstrap secret); RBAC + least privilege.
- Private endpoints; HSM (Premium/Managed HSM) for sensitive keys.
- Purge protection + soft delete; separate vaults per env/blast radius.
- Full audit logging; rotate compromised secrets; monitor access anomalies.

## 11. Cost Optimization
- Standard vault where HSM not required; Premium/Managed HSM only when needed.
- Cache to reduce operation count (also avoids throttling cost/latency).
- Consolidate sensibly but separate by blast radius; clean up stale versions.

## 12. Troubleshooting Scenarios
- **403 Forbidden** → RBAC role/access policy missing for the identity.
- **429 throttling** → per-request fetches; add caching.
- **Can't reach vault** → private endpoint/DNS/firewall.
- **Deleted secret gone** → soft delete window/purge protection; recover.
- **Cert expired despite renewal** → issuer/auto-rotation misconfig; check events.

## 13. Hands-on Example
```bash
az keyvault create -g rg -n kv-prod --enable-rbac-authorization true \
  --enable-purge-protection true --public-network-access Disabled
az role assignment create --assignee <appPrincipalId> \
  --role "Key Vault Secrets User" --scope $KEYVAULT_ID
```

## 14. Terraform Example
```hcl
resource "azurerm_key_vault" "kv" {
  name = "kv-prod" resource_group_name = var.rg location = "eastus"
  tenant_id = data.azurerm_client_config.c.tenant_id sku_name = "premium"
  enable_rbac_authorization = true purge_protection_enabled = true
  soft_delete_retention_days = 90 public_network_access_enabled = false
}
resource "azurerm_role_assignment" "app" {
  scope = azurerm_key_vault.kv.id role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_user_assigned_identity.app.principal_id
}
```

## 15. Azure Example
```bash
# App Service Key Vault reference — secret injected as env var, no code change
az webapp config appsettings set -g rg -n web-app --settings \
  "DbConn=@Microsoft.KeyVault(SecretUri=https://kv-prod.vault.azure.net/secrets/db-conn/)"
```

## 16. FastAPI / Python Example
```python
# Fetch + cache secret at startup (avoid per-request throttling), Managed Identity
from azure.identity.aio import DefaultAzureCredential
from azure.keyvault.secrets.aio import SecretClient
_cache: dict[str, str] = {}

async def get_secret(name: str) -> str:
    if name not in _cache:                    # cache to respect throttling limits
        async with SecretClient("https://kv-prod.vault.azure.net",
                                DefaultAzureCredential()) as kv:
            _cache[name] = (await kv.get_secret(name)).value
    return _cache[name]
```

## 17. AKS Example
AKS uses the **Secrets Store CSI driver** with the Key Vault provider + **Workload Identity**: secrets/certs are mounted as files (or synced to K8s secrets) into pods without storing them in the cluster. Rotation is picked up automatically; access is per-workload identity, audited centrally.

## 18. How to Remember
**"Vault for Secrets + Keys + Certs; auth with Managed Identity (solves secret-zero); RBAC least privilege; private endpoint + purge protection; rotate + cache; HSM for compliance."**

## 19. Real-World Analogy
A bank's safe-deposit vault: you don't keep valuables (secrets) at your desk. You prove your identity with a biometric (Managed Identity — no key to lose), staff let you access only your assigned box (RBAC), everything is logged, and the bank guarantees items can't be destroyed without recovery (soft delete/purge protection). The strongest boxes are in a hardened room (HSM).

## 20. One-Page Cheat Sheet
- **What**: managed store for **Secrets**, **Keys**, **Certificates** (centralized, audited).
- **Auth**: **Managed Identity** (no bootstrap secret) + **RBAC** least privilege (over legacy access policies).
- **Tiers**: Standard (software) / Premium (**HSM**) / **Managed HSM** (dedicated, FIPS L3).
- **Secure**: private endpoints + firewall, **soft delete + purge protection**, versioning, audit → Sentinel.
- **Ops**: automated rotation + Event Grid alerts, auto-renew certs, **cache** secrets (avoid throttling).
- **Consume**: App Service KV references, AKS **CSI driver**, CMK for Storage/SQL/Cosmos.

# DEEP MECHANICS · Azure Key Vault

> Level 2 — secrets/keys/certs, access models (RBAC vs policies), managed
> identity access, soft-delete, and HSM.

---

## 0. The precise mental model
Key Vault is a **centralized, access-controlled store for secrets, keys, and certificates**, backed by hardware-protected boundaries. It removes secrets from code/config: apps authenticate with a **Managed Identity** and fetch secrets at runtime over TLS, with **RBAC**, **audit logging**, **versioning**, and **soft-delete** protecting them. Keys can stay in an **HSM** and never leave.

---

## 1. Three object types
- **Secrets** — arbitrary strings (connection strings, passwords, API keys).
- **Keys** — cryptographic keys (RSA/EC) for **encrypt/decrypt/sign/wrap**; key material can be **non-exportable** (crypto happens *in* the vault/HSM).
- **Certificates** — X.509 certs with lifecycle mgmt (issuance, auto-renewal with integrated CAs).

## 2. Access models (know both)
- **Azure RBAC** (recommended) → roles like *Key Vault Secrets User* scoped at vault/subscription; unified with Azure RBAC + PIM.
- **Vault access policies** (legacy) → per-identity permission lists on the vault.
- Two **planes**: **management plane** (manage the vault, via Azure RBAC) vs **data plane** (read secrets, via RBAC or access policies).

## 3. Accessing from apps (the pattern)
```
App (Managed Identity) → Entra token → Key Vault (RBAC check) → secret over TLS
```
- **No secret to bootstrap** (MI eliminates the "secret-zero" problem).
- Cache secrets in memory (rate limits); use Key Vault references in App Service/Functions or CSI driver in AKS.

## 4. Protection features
- **Soft-delete** (recoverable for retention period) + **purge protection** (block permanent delete) → guard against accidental/malicious deletion.
- **Versioning** — each update = new version; reference latest or pinned.
- **Rotation** — auto-rotation policies / Event Grid notifications → rotate secrets/keys/certs.
- **RBAC + audit logs** (to Log Analytics) — who accessed what.

## 5. Network & HSM tiers
- **Private endpoint** + firewall → vault not public.
- Tiers: **Standard** (software-protected keys) vs **Premium** (**HSM-backed**, FIPS 140-2 L2); **Managed HSM** = dedicated single-tenant FIPS L3 for high assurance.
- **Keyless crypto**: Key Vault performs sign/wrap so private keys never leave the boundary.

## 6. Common uses
- App secrets, TLS certs, **Customer-Managed Keys (CMK)** for encrypting Storage/SQL/Disks, signing.

## 7. The hard follow-ups (with answers)
1. **"How does an app get a secret without a secret?"** → **Managed Identity** → Entra token → Key Vault (solves secret-zero). (§3)
2. **"RBAC vs access policies?"** → RBAC (recommended, unified + PIM) vs legacy per-vault access policy lists. (§2)
3. **"Mgmt vs data plane?"** → manage vault (RBAC) vs read secrets (data-plane perms). (§2)
4. **"Recover a deleted secret?"** → **soft-delete** (+ purge protection blocks permanent delete). (§4)
5. **"Keys that never leave?"** → **Premium/Managed HSM**, non-exportable, crypto in-vault. (§5)
6. **"Lock down network?"** → **private endpoint** + firewall. (§5)
7. **"Encrypt Storage with your own key?"** → **CMK** stored in Key Vault. (§6)

## 8. One-screen recall
- **Central store**: **secrets / keys / certs**; keys can be non-exportable (HSM).
- **Access**: **Azure RBAC** (recommended) vs legacy access policies; mgmt vs **data plane**.
- **Pattern**: app **Managed Identity** → token → Key Vault over TLS (no secret-zero); cache.
- **Protect**: **soft-delete + purge protection**, versioning, auto-rotation, audit logs.
- **Tiers**: Standard (SW) / Premium (**HSM**) / Managed HSM (L3); **private endpoint**.
- **Uses**: app secrets, TLS certs, **CMK** encryption, signing.

> Next: RBAC.

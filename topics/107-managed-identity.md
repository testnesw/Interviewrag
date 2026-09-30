# 107 · Managed Identity

> Domain: Security & Identity · Level: Principal Security / Identity Architect

## 1. Beginner Explanation
A managed identity gives an Azure resource (like a VM, app, or function) **its own identity in Entra ID automatically** — so it can securely access other Azure services without you storing any passwords, keys, or secrets in code or config.

## 2. Architect-Level Explanation
An Entra ID identity for Azure resources with fully managed credentials (no secrets to handle):
- **Two types**: **System-assigned** (tied 1:1 to a resource's lifecycle — created/deleted with it) vs **User-assigned** (standalone resource, reusable across many resources, independent lifecycle).
- **How it works**: Azure provisions a **service principal**; the platform rotates credentials automatically. The resource requests a **token** from the **Instance Metadata Service (IMSS)** endpoint and uses it to call Azure AD-protected services.
- **Authorization**: grant the identity **RBAC roles** (e.g., Key Vault Secrets User, Storage Blob Data Reader) — least privilege.
- **Eliminates**: connection strings, keys, client secrets, certificates in code/config → removes the #1 secret-leak risk.
- **Supported by**: VMs, App Service/Functions, AKS (**Workload Identity**), Container Apps, Logic Apps, Data Factory, VMSS, API Management, etc.
- **Consumers**: Key Vault, Storage, SQL, Cosmos, Service Bus, Event Hubs, ACR, Graph — anything Entra-auth-capable.
- **SDK**: `DefaultAzureCredential` / `ManagedIdentityCredential` acquire tokens transparently.
- **AKS**: **Workload Identity** federates a Kubernetes service account to a user-assigned managed identity via OIDC (replaces deprecated pod identity).

## 3. Real Enterprise Use Case
A microservices platform uses managed identities everywhere: App Service/Functions and AKS pods authenticate to **Key Vault** (fetch secrets/certs), **Storage/ADLS**, **SQL** (passwordless), **Service Bus**, and **ACR** (image pull) — zero secrets in code or pipelines. A shared **user-assigned** identity grants consistent RBAC across a service group; AKS uses **Workload Identity** federation — fully passwordless, auditable, Zero Trust.

## 4. Architecture Diagram (ASCII)
```
   Azure Resource (App/Func/VM/AKS pod)
        │ request token (no secret) ── IMDS/OIDC endpoint
        ▼
   Entra ID ── issues token (auto-rotated creds) ──► service principal
        │ token
        ▼  (RBAC role assigned to identity)
   Key Vault · Storage · SQL · Service Bus · ACR · Graph
   Types: System-assigned (1:1 lifecycle) | User-assigned (reusable)
   AKS: K8s ServiceAccount ⇄ Workload Identity (OIDC federation)
```

## 5. Interview Questions
1. What is a managed identity and what problem does it solve?
2. System-assigned vs user-assigned — when each?
3. How does a resource get a token without a secret?
4. How do you authorize a managed identity?
5. How does AKS Workload Identity work?

## 6. Strong Interview Answers
- **What/why**: "It's an Entra ID identity automatically created and managed for an Azure resource, with credentials the platform rotates. It solves the secret-management problem — no connection strings, keys, or client secrets in code/config — eliminating the most common cause of breaches (leaked secrets)."
- **System vs user**: "**System-assigned** is bound 1:1 to a resource and deleted with it — simple for single-resource scenarios. **User-assigned** is a standalone identity you can attach to many resources and manage independently — better for shared RBAC across a service group, pre-provisioning, and avoiding re-granting roles when resources are recreated."
- **Token without secret**: "The resource calls the local Instance Metadata Service (or OIDC for Workload Identity) to request a token for a target audience. The platform, which holds the managed credentials, returns a short-lived Entra token the app uses to call the service. No secret ever lives in the app."
- **Authorize**: "Assign **RBAC roles** to the identity, scoped least-privilege — e.g., 'Key Vault Secrets User' on a specific vault, 'Storage Blob Data Reader' on a container. Authentication (identity) is separate from authorization (RBAC), so I grant only what's needed."
- **AKS Workload Identity**: "The cluster has an OIDC issuer; a Kubernetes **service account** is federated to a **user-assigned managed identity**. Pods using that service account get a projected token, exchange it with Entra ID for an Azure token, and access resources — no secrets in the cluster. It replaced the older, less secure pod identity."

## 7. Common Mistakes
- Still using secrets/keys where managed identity would work.
- Over-permissioning the identity (not least privilege).
- System-assigned where a shared user-assigned is needed (role churn on recreate).
- Forgetting RBAC (identity exists but no role → 403).
- Using deprecated AAD Pod Identity instead of Workload Identity on AKS.

## 8. Trade-offs
| Type | Pro | Con |
|------|-----|-----|
| System-assigned | simple, auto lifecycle | not reusable, re-grant on recreate |
| User-assigned | reusable, stable RBAC | manage its lifecycle |

## 9. Production Best Practices
- Managed identity as default for all Azure-to-Azure auth (no secrets).
- User-assigned for shared/consistent RBAC; least-privilege roles.
- `DefaultAzureCredential` in code (works local → cloud).
- AKS Workload Identity (federated); Key Vault refs for any residual secrets.
- Audit role assignments; IaC the identities + roles.

## 10. Security Considerations
- No secrets to leak/rotate (platform-managed) → major risk reduction.
- Least-privilege RBAC scoped tightly; separate identity per workload.
- Conditional Access / token audience validation; monitor token usage.
- Avoid over-broad user-assigned identities shared too widely.

## 11. Cost Optimization
- Free (no cost for the identity itself) + removes secret-store/rotation overhead.
- Reduces breach/incident cost; fewer moving parts to operate.

## 12. Troubleshooting Scenarios
- **403 from Key Vault/Storage** → RBAC role not assigned to the identity.
- **Token acquisition fails locally** → `DefaultAzureCredential` falls back to dev login; check env.
- **Wrong identity used** → multiple user-assigned attached; specify client ID.
- **AKS pod can't get token** → Workload Identity not enabled / SA not annotated / federation missing.
- **Role works after recreate broke** → system-assigned recreated with new principal; use user-assigned.

## 13. Hands-on Example
```bash
az functionapp identity assign -g rg -n orders-fn        # system-assigned
az role assignment create --assignee <principalId> \
  --role "Key Vault Secrets User" --scope $KEYVAULT_ID   # least-privilege authz
```

## 14. Terraform Example
```hcl
resource "azurerm_user_assigned_identity" "app" {
  name = "id-orders" resource_group_name = var.rg location = "eastus"
}
resource "azurerm_role_assignment" "kv" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_user_assigned_identity.app.principal_id   # authorize identity
}
```

## 15. Azure Example
```bash
# Enable AKS Workload Identity + federate a K8s service account to a managed identity
az aks update -g rg -n prod-aks --enable-oidc-issuer --enable-workload-identity
az identity federated-credential create --name orders --identity-name id-orders -g rg \
  --issuer $OIDC_URL --subject system:serviceaccount:default:orders-sa
```

## 16. FastAPI / Python Example
```python
# Passwordless access to Key Vault + Storage via DefaultAzureCredential
from azure.identity.aio import DefaultAzureCredential
from azure.keyvault.secrets.aio import SecretClient

async def get_secret(name: str):
    cred = DefaultAzureCredential()          # managed identity in Azure, dev login locally
    async with SecretClient("https://kv-prod.vault.azure.net", cred) as kv:
        return (await kv.get_secret(name)).value   # no secret to authenticate with the vault
```

## 17. AKS Example
Annotate a Kubernetes ServiceAccount with the managed identity's client ID and label the pod for **Workload Identity**; the pod's projected OIDC token is exchanged for an Entra token to reach Key Vault/Storage/SQL — no Kubernetes secrets, no connection strings, fully auditable per workload.

## 18. How to Remember
**"Azure identity with no secrets to manage; system (1:1) vs user (reusable); token from IMDS/OIDC; grant RBAC to authorize; AKS = Workload Identity federation."**

## 19. Real-World Analogy
A building keycard that's issued and auto-renewed by the building itself (no one carries a master password): each employee (resource) taps to enter authorized rooms (RBAC), the card updates automatically (rotation), and if an employee leaves, their card deactivates (system-assigned lifecycle) — no shared keys to copy or lose.

## 20. One-Page Cheat Sheet
- **What**: Entra ID identity for Azure resources with platform-managed (auto-rotated) credentials — **no secrets**.
- **Types**: **system-assigned** (1:1 lifecycle) vs **user-assigned** (reusable, stable RBAC).
- **Token**: resource requests from IMDS (or OIDC for AKS) → short-lived Entra token.
- **Authorize**: assign least-privilege **RBAC roles** to the identity (authN ≠ authZ).
- **Use**: Key Vault, Storage, SQL (passwordless), Service Bus, ACR, Graph; `DefaultAzureCredential`.
- **AKS**: **Workload Identity** (K8s SA ⇄ managed identity via OIDC); replaces pod identity.

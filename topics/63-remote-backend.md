# 63 · Terraform Remote Backend

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
A remote backend stores your Terraform state in a shared, secure location (like Azure Blob Storage) instead of on your laptop — so your whole team uses the same state, and it's safe, locked, and backed up.

## 2. Architect-Level Explanation
The backend determines where state lives and how operations run:
- **Local vs remote**: local = a file on disk (no sharing/locking); remote = shared store (Azure Storage, S3, Terraform Cloud/HCP, Consul).
- **Azure backend (`azurerm`)**: state in a Blob container; **state locking via blob lease** (native, prevents concurrent applies); encryption at rest; **blob versioning** for recovery.
- **Auth**: managed identity / OIDC / service principal — never store keys in code.
- **Isolation**: one state file (key) per env/component within the container.
- **Terraform Cloud/HCP**: managed backend + remote runs, RBAC, policy, run history.
- **Partial config**: backend settings supplied at `init` (via `-backend-config`) to avoid hardcoding secrets/environments.
- Enables safe team collaboration + CI/CD.

## 3. Real Enterprise Use Case
An enterprise stores all Terraform state in a hardened Azure Storage account (private endpoint, versioning, RBAC), one blob key per environment/component. CI authenticates via OIDC (no secrets), blob-lease locking prevents concurrent applies, and versioning allows rollback if a state gets corrupted.

## 4. Architecture Diagram (ASCII)
```
   Dev / CI runners
        │ terraform init -backend-config=...
        ▼
   Azure Storage Account (private endpoint)
     └─ container: tfstate
          ├─ networking/prod.tfstate   ◄─ blob lease = LOCK
          ├─ platform/prod.tfstate
          └─ apps/prod.tfstate
     versioning = rollback | RBAC + encryption at rest
   Auth: OIDC / Managed Identity (no keys in code)
```

## 5. Interview Questions
1. Why use a remote backend?
2. How does locking work with the Azure backend?
3. How do you authenticate to the backend securely?
4. How do you isolate state per environment?
5. How do you recover a corrupted state?

## 6. Strong Interview Answers
- **Why remote**: "Shared team access, locking to prevent concurrent-apply corruption, encryption, versioning/backup, and CI/CD integration. Local state doesn't scale beyond one person."
- **Locking**: "The azurerm backend uses a **blob lease** on the state blob as a native lock — while one apply holds the lease, others wait or fail, preventing simultaneous writes. No separate lock table needed (unlike S3+DynamoDB)."
- **Auth**: "OIDC/workload federation or managed identity so CI gets short-lived tokens — no storage keys or service-principal secrets in code. Grant least-privilege RBAC on the storage account."
- **Isolation**: "Separate blob keys per environment/component (e.g., `platform/prod.tfstate`), or separate storage accounts/containers, so a change to one doesn't risk another and plans stay fast."
- **Recovery**: "Enable blob versioning/soft-delete so I can restore a previous state version if it's corrupted; back up before risky operations, and use `force-unlock` only after confirming no active run."

## 7. Common Mistakes
- Local state on laptops (no locking, lost easily).
- Storage keys/secrets hardcoded in backend block.
- No versioning/soft-delete (no recovery path).
- Public storage account (no private endpoint).
- Sharing one state for all environments.

## 8. Trade-offs
| Backend | Pro | Con |
|---------|-----|-----|
| Azure Storage | native, cheap, blob-lock | self-manage account |
| Terraform Cloud/HCP | runs+RBAC+policy | cost, external |
| Local | simple | no team/lock/backup |

## 9. Production Best Practices
- Azure Storage backend: private endpoint, RBAC, versioning, soft-delete.
- OIDC/managed identity auth (no keys).
- Per-env/component state keys.
- `-backend-config` for environment-specific init (no hardcoded secrets).
- Enable locking; document `force-unlock` procedure.

## 10. Security Considerations
- Encrypt at rest (+ optional CMK); private network only.
- Least-privilege RBAC; no account keys in code/CI logs.
- State holds secrets → tightest access controls + audit.
- Enable soft-delete + versioning for tamper recovery.

## 11. Cost Optimization
- Blob storage is cheap; lifecycle rules on old versions.
- Split state speeds plans → less CI compute.
- One shared hardened account vs many (governance + cost).

## 12. Troubleshooting Scenarios
- **Lock stuck** → confirm no run, `force-unlock <lock-id>`.
- **403 on init** → RBAC/OIDC misconfig on storage account.
- **State corrupted** → restore prior blob version.
- **Wrong state loaded** → wrong `key`/backend-config.
- **Private endpoint DNS** → `privatelink.blob.core.windows.net` resolution.

## 13. Hands-on Example
```bash
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=sttfstateprod" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=platform/prod.tfstate"
```

## 14. Terraform Example
```hcl
terraform {
  backend "azurerm" {
    use_oidc = true                 # secretless CI auth
    # resource_group_name / storage_account_name / container_name / key
    # supplied via -backend-config at init (no secrets in code)
  }
}
```

## 15. Azure Example
```bash
az storage account create -g rg-tfstate -n sttfstateprod \
  --sku Standard_LRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false
az storage account blob-service-properties update \
  -g rg-tfstate --account-name sttfstateprod \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 30
az storage container create --account-name sttfstateprod -n tfstate
```

## 16. FastAPI / Python Example
```python
# Platform API that initializes a workspace against the shared backend
import subprocess
@app.post("/infra/init")
def init(component: str, env: str):
    key = f"{component}/{env}.tfstate"
    r = subprocess.run(
        ["terraform", "init", "-reconfigure",
         f"-backend-config=key={key}"], capture_output=True, text=True)
    return {"key": key, "ok": r.returncode == 0}
```

## 17. AKS Example
Store the AKS cluster's Terraform state at key `platform/aks-prod.tfstate` in the shared backend; CI running in a GitHub Actions/Azure DevOps pipeline authenticates via OIDC to the storage account and applies with blob-lease locking — no static credentials on runners.

## 18. How to Remember
**"Remote backend = shared + locked + encrypted + versioned."** Azure = Blob + blob-lease lock; auth via OIDC, config via `-backend-config`.

## 19. Real-World Analogy
A shared bank vault with a single-key checkout: only one person can hold the key (blob lease) to update the ledger at a time, the vault is encrypted and access-controlled (RBAC), and every previous ledger version is archived (versioning) in case of mistakes.

## 20. One-Page Cheat Sheet
- **Why**: shared state + locking + encryption + versioning + CI/CD.
- **Azure**: `backend "azurerm"` → Blob container; **blob lease = native lock**.
- **Auth**: OIDC/managed identity (no keys); `-backend-config` for env-specific init.
- **Isolate**: one blob `key` per env/component.
- **Harden**: private endpoint, RBAC, versioning + soft-delete, CMK.
- **Recover**: restore prior blob version; `force-unlock` only when safe.

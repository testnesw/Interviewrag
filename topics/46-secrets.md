# 46 · Secrets

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A Secret stores **sensitive data** (passwords, API keys, tokens, certs) in Kubernetes so your Pods can use them without hardcoding them into images or manifests.

## 2. Architect-Level Explanation
A namespaced object for confidential data:
- **Encoding ≠ encryption**: Secret values are base64-encoded, *not* encrypted by default — must enable **etcd encryption at rest** (or KMS).
- **Consumption**: as env vars or mounted volumes (files); volumes update on change, env vars don't.
- **Types**: Opaque, `kubernetes.io/dockerconfigjson` (registry), `tls`, service-account tokens.
- **Enterprise pattern**: don't store real secrets in Git; use **external secret stores** — **Azure Key Vault + CSI Secrets Store driver**, External Secrets Operator, or sealed-secrets/SOPS.
- **RBAC**: tightly control who can read Secrets.

## 3. Real Enterprise Use Case
An AKS app pulls DB credentials and API keys from Azure Key Vault via the **Key Vault CSI driver** using Workload Identity — secrets are mounted as files, rotated centrally in Key Vault, never stored in Git or the cluster's etcd as the source of truth.

## 4. Architecture Diagram (ASCII)
```
   Azure Key Vault (source of truth, rotation, audit)
        ▲ Workload Identity (no stored creds)
   [ CSI Secrets Store driver ]
        │ mounts as files (or syncs to K8s Secret)
      Pod: /mnt/secrets/db-password
   Alt: External Secrets Operator / sealed-secrets (GitOps-safe)
   etcd encryption at rest protects native Secrets
```

## 5. Interview Questions
1. Are Kubernetes Secrets encrypted?
2. Env var vs volume mount for secrets?
3. How do you manage secrets with GitOps?
4. What is the Key Vault CSI driver?
5. How do you secure and rotate secrets?

## 6. Strong Interview Answers
- **Encrypted?**: "By default they're only base64-encoded in etcd — not encrypted. I enable etcd encryption at rest (or KMS/HSM) and rely on RBAC. For real security I use an external store like Key Vault."
- **Env vs volume**: "Volume mounts are safer (not exposed in `printenv`/crash dumps) and update when the secret changes; env vars are convenient but static and more leak-prone. I prefer mounted files."
- **GitOps**: "Never commit plaintext secrets. Use External Secrets Operator / Key Vault CSI to pull at runtime, or sealed-secrets/SOPS to store encrypted references in Git."
- **CSI driver**: "The Secrets Store CSI driver mounts Key Vault secrets into Pods as files (optionally syncing to a K8s Secret), authenticated via Workload Identity — central rotation and audit in Key Vault."
- **Rotate/secure**: "Rotate in the external store; auto-reflect via CSI/reloader; scope RBAC; enable etcd encryption; audit access."

## 7. Common Mistakes
- Assuming base64 = encryption.
- Plaintext secrets in Git/manifests.
- Secrets as env vars leaked in logs/crash dumps.
- Broad RBAC on Secrets.
- No rotation strategy.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Native Secret | simple | base64, in etcd, RBAC-only |
| Key Vault CSI | central, rotation, audit | driver + identity setup |
| Sealed-secrets | GitOps-safe | key management |

## 9. Production Best Practices
- External store (Key Vault CSI) as source of truth.
- Mount as files; use a reloader to pick up rotations.
- Enable etcd encryption at rest.
- Least-privilege RBAC; per-app service accounts.
- Never commit plaintext; scan repos for leaks.

## 10. Security Considerations
- etcd encryption / KMS; restrict etcd access.
- Workload Identity (no stored cloud creds).
- Audit secret access; short-lived tokens.
- Avoid env vars for high-sensitivity secrets.

## 11. Cost Optimization
- Key Vault operations are cheap; batch/cached mounts.
- Avoid per-pod excessive secret polling intervals.

## 12. Troubleshooting Scenarios
- **Secret not found** → wrong name/namespace, RBAC.
- **CSI mount fails** → Workload Identity binding, SecretProviderClass, KV access policy/RBAC.
- **Stale secret** → no reloader; env vars don't auto-update.
- **Leaked in logs** → move from env to volume; scrub logs.

## 13. Hands-on Example
```bash
kubectl create secret generic db-cred \
  --from-literal=password='s3cr3t' -n app
kubectl get secret db-cred -o jsonpath='{.data.password}' | base64 -d
```

## 14. Terraform Example
```hcl
# Prefer referencing Key Vault; native secret shown for completeness
resource "kubernetes_secret" "db" {
  metadata { name = "db-cred" namespace = "app" }
  data = { password = var.db_password }   # sourced from KV/TF vars, not Git
  type = "Opaque"
}
```

## 15. Azure Example
```bash
az aks enable-addons -g rg-aks -n prod-aks \
  -a azure-keyvault-secrets-provider    # installs CSI driver
```

## 16. FastAPI / Python Example
```python
# Read secret from mounted file (CSI), not env var
def db_password() -> str:
    with open("/mnt/secrets/db-password") as f:
        return f.read().strip()

@app.get("/health/db")
def db_health():
    return {"connected": connect(password=db_password())}
```

## 17. AKS Example (SecretProviderClass)
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata: { name: kv-secrets, namespace: app }
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: <workload-identity-client-id>
    keyvaultName: myvault
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
    tenantId: <tenant-id>
```

## 18. How to Remember
**"Base64 is not encryption."** Use Key Vault CSI + Workload Identity, mount as files, rotate centrally.

## 19. Real-World Analogy
A hotel safe: don't tape the combination to the door (Git) or shout it in the lobby (env var/logs). Store valuables in a managed vault (Key Vault) and give staff temporary, audited access (Workload Identity).

## 20. One-Page Cheat Sheet
- **What**: object for sensitive data (passwords, keys, certs).
- **Not encrypted by default** — base64 only → enable etcd encryption.
- **Consume**: prefer volume mounts (auto-update, less leaky) over env vars.
- **Enterprise**: Azure Key Vault + CSI driver + Workload Identity (central rotation/audit).
- **GitOps-safe**: External Secrets / sealed-secrets / SOPS — never plaintext.
- **Secure**: least-privilege RBAC, audit, rotation.

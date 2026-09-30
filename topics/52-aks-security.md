# 52 · AKS Security

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
AKS security is about protecting your Kubernetes cluster on Azure — controlling who can access it, securing the network, protecting secrets, hardening workloads, and detecting threats.

## 2. Architect-Level Explanation
Defense-in-depth across identity, network, workload, and data:
- **Identity**: Entra ID integration + Kubernetes RBAC (or Azure RBAC for K8s); disable local accounts; **Workload Identity** for pods (no secrets).
- **Network**: **private cluster** (private API server), authorized IP ranges, network policies (Cilium/Calico), egress via Firewall.
- **Workload**: **Azure Policy/Gatekeeper** (Pod Security Standards, no privileged, allowed registries), image scanning, signed images.
- **Data/secrets**: Key Vault CSI, etcd encryption, CMK.
- **Detection**: **Defender for Containers** (runtime threats, vuln scanning), audit logs to Log Analytics/Sentinel.
- Keep cluster + node images patched (upgrades).

## 3. Real Enterprise Use Case
A regulated fintech runs private AKS: Entra ID + Azure RBAC, Workload Identity (zero secrets), Cilium network policies (default-deny), Gatekeeper blocking privileged pods and non-ACR images, Key Vault CSI for secrets, Defender for Containers, and all logs to Sentinel.

## 4. Architecture Diagram (ASCII)
```
   Entra ID + Azure RBAC ─► API server (PRIVATE cluster, authorized IPs)
        │ Workload Identity (pods → Azure, no secrets)
   Node pools: hardened images, patched
   Gatekeeper/Azure Policy: no privileged, ACR-only, PSS
   Cilium NetworkPolicy (default-deny) + Firewall egress
   Key Vault CSI (secrets) ; etcd encryption
   Defender for Containers ─► Sentinel (threats/audit)
```

## 5. Interview Questions
1. How do you secure the AKS control plane/API?
2. How do pods access Azure resources securely?
3. How do you enforce workload security policies?
4. How do you secure networking in AKS?
5. How do you detect runtime threats?

## 6. Strong Interview Answers
- **Control plane**: "Private cluster (private API endpoint), authorized IP ranges if public, Entra ID auth + Azure RBAC, and disable local accounts so all access is identity-based and audited."
- **Pod → Azure**: "**Workload Identity** — federate a Kubernetes ServiceAccount to a Managed Identity so pods get short-lived Entra tokens; no stored secrets. (AAD Pod Identity is deprecated.)"
- **Policy**: "Azure Policy / OPA Gatekeeper enforce Pod Security Standards, block privileged/hostPath, restrict to ACR images, and require resource limits — admission-time guardrails."
- **Network**: "Network policies (Cilium/Calico) for default-deny east-west, private cluster, egress through Azure Firewall with FQDN allow-listing, Private Endpoints for ACR/Key Vault/DB."
- **Detection**: "Defender for Containers for runtime threat detection + image vulnerability scanning, plus audit logs to Log Analytics/Sentinel with alerting."

## 7. Common Mistakes
- Public API server for sensitive clusters.
- Secrets in manifests instead of Key Vault/Workload Identity.
- No network policies (flat pod network).
- Privileged pods / running as root.
- Skipping image scanning and cluster upgrades.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Private cluster | secure API | needs jumpbox/VPN for kubectl |
| Strict policies | safer | dev friction |
| Defender | threat detection | added cost |

## 9. Production Best Practices
- Private cluster + Entra ID + Azure RBAC; no local accounts.
- Workload Identity everywhere (no secrets).
- Gatekeeper/Azure Policy: PSS, ACR-only, no privileged.
- Default-deny network policies; Firewall egress.
- Key Vault CSI; etcd encryption; Defender + Sentinel.
- Regular node/K8s upgrades; scan images in ACR.

## 10. Security Considerations
- Least-privilege RBAC (namespace-scoped roles).
- Rotate/short-lived credentials (Workload Identity).
- Runtime protection + admission control.
- Supply-chain: signed images, trusted registries.

## 11. Cost Optimization
- Defender/Sentinel scoped sensibly (data ingestion cost).
- Policy prevents costly misconfig; right-size logging retention.

## 12. Troubleshooting Scenarios
- **Pod can't reach Azure** → Workload Identity federation/role.
- **Deploy blocked** → Gatekeeper/Azure Policy denial.
- **kubectl unreachable** → private cluster access (VPN/jumpbox/authorized IPs).
- **Traffic blocked** → network policy default-deny missing allow rule.

## 13. Hands-on Example
```bash
az aks create -g rg-aks -n prod-aks --enable-private-cluster \
  --enable-aad --enable-azure-rbac --disable-local-accounts \
  --enable-oidc-issuer --enable-workload-identity \
  --network-policy cilium --network-plugin azure --network-plugin-mode overlay
```

## 14. Terraform Example
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name = "prod-aks" location = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = "prodaks"
  private_cluster_enabled   = true
  local_account_disabled    = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_active_directory_role_based_access_control { azure_rbac_enabled = true }
  network_profile { network_plugin = "azure" network_policy = "cilium"
    network_plugin_mode = "overlay" }
  default_node_pool { name = "system" vm_size = "Standard_D4s_v5"
    node_count = 3 only_critical_addons_enabled = true }
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```bash
az aks enable-addons -g rg-aks -n prod-aks -a azure-policy
az aks update -g rg-aks -n prod-aks --enable-defender
```

## 16. FastAPI / Python Example
```python
# Pod uses Workload Identity — no secrets in the app
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
kv = SecretClient("https://myvault.vault.azure.net", DefaultAzureCredential())

@app.get("/health/secret")
def secret_ok():
    return {"ok": bool(kv.get_secret("db-password").value)}
```

## 17. AKS Example (Gatekeeper constraint)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata: { name: acr-only }
spec:
  match: { kinds: [{ apiGroups: [""], kinds: ["Pod"] }] }
  parameters: { repos: ["myacr.azurecr.io/"] }   # only ACR images
```

## 18. How to Remember
**"Private + Identity + Policy + Network + Detect."** Private cluster, Workload Identity, Gatekeeper, network policies, Defender.

## 19. Real-World Analogy
A secure bank branch: locked private entrance (private cluster), badge access (Entra ID/RBAC), staff with temporary vault keys (Workload Identity), rulebook enforced at the door (Gatekeeper), internal door locks (network policies), and CCTV/guards (Defender).

## 20. One-Page Cheat Sheet
- **Identity**: Entra ID + Azure RBAC, disable local accounts, **Workload Identity** (no secrets).
- **Network**: private cluster, authorized IPs, network policies (default-deny), Firewall egress.
- **Workload**: Azure Policy/Gatekeeper (PSS, no privileged, ACR-only).
- **Data**: Key Vault CSI, etcd encryption, CMK.
- **Detect**: Defender for Containers + audit logs → Sentinel.
- **Maintain**: patch/upgrade nodes + K8s; scan images.

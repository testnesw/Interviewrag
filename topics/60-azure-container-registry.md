# 60 · Azure Container Registry (ACR)

> Domain: Docker & Containers · Level: Principal Container Architect

## 1. Beginner Explanation
Azure Container Registry (ACR) is Azure's **private, managed container registry** — a secure place to store, build, and distribute your Docker/OCI images and Helm charts, tightly integrated with AKS and Azure security.

## 2. Architect-Level Explanation
ACR is a managed OCI registry with Azure-native integration:
- **Tiers**: Basic, Standard, **Premium** (geo-replication, private endpoints, content trust, higher throughput, customer-managed keys).
- **Build in the cloud**: **ACR Tasks** (`az acr build`) build images without local Docker; **base-image update triggers** auto-rebuild on CVE patches; multi-step tasks for CI.
- **Security**: **Microsoft Defender** vulnerability scanning, **content trust / signing** (Notation), **Private Endpoints** (no public), **CMK** encryption, RBAC + **AcrPull/AcrPush** roles, disable admin account.
- **AKS integration**: `--attach-acr` grants the cluster's managed identity AcrPull → secretless pulls; Workload Identity for finer scope.
- **Distribution**: geo-replication (single registry, regional replicas), **connected registry** for edge/on-prem, artifact caching / pull-through cache for upstream (Docker Hub) with rate-limit relief.
- **Artifacts**: images, Helm charts (OCI), SBOMs, and OCI artifacts.

## 3. Real Enterprise Use Case
An enterprise standardizes on Premium ACR: ACR Tasks build/sign images in-cloud, base-image triggers auto-patch on CVEs, Defender gates vulnerabilities, geo-replication serves AKS clusters in 3 regions, Private Endpoints keep it off the public internet, and AKS pulls via managed identity — a secure, automated supply chain.

## 4. Architecture Diagram (ASCII)
```
   Git ─► ACR Task (az acr build, cloud) ─► Image (signed)
             ▲ base-image trigger (CVE patch → rebuild)
        Defender scan | Notation sign | CMK encryption
             │ geo-replicated: East US / West EU / SE Asia
   Private Endpoint (no public) ◄── VNet
             │ AcrPull via Managed/Workload Identity (no secret)
   AKS clusters (multi-region) ── pull ──┘
   Cache rule: Docker Hub ─► ACR (rate-limit relief)
```

## 5. Interview Questions
1. What do ACR tiers (esp. Premium) offer?
2. What are ACR Tasks and base-image triggers?
3. How does AKS pull from ACR securely?
4. How do you secure and privatize ACR?
5. How does geo-replication / caching work?

## 6. Strong Interview Answers
- **Tiers**: "Basic/Standard differ mainly by storage/throughput; Premium unlocks geo-replication, Private Endpoints, content trust, CMK, and connected registries — that's what enterprises need for security and global scale."
- **ACR Tasks**: "Server-side builds — `az acr build` builds and pushes without local Docker. Base-image update triggers automatically rebuild dependent images when the base gets a security patch, keeping the supply chain current. Multi-step tasks can build, test, and push."
- **Secure AKS pull**: "`az aks update --attach-acr` grants the cluster's managed identity the AcrPull role, so nodes pull images without any stored pull secret. For finer control I use Workload Identity scoped per workload."
- **Secure/privatize**: "Disable the admin account, use RBAC (AcrPull/AcrPush), enable Defender scanning and image signing, put it behind a Private Endpoint (no public network), and encrypt with customer-managed keys."
- **Geo-replication/cache**: "Premium geo-replication keeps a single logical registry with regional replicas so each region pulls locally (fast, resilient). Cache rules pull-through upstream registries (e.g., Docker Hub) into ACR to avoid rate limits and reduce external dependency."

## 7. Common Mistakes
- Admin account enabled + static creds instead of identity.
- Basic/Standard when Premium features (PE, geo, signing) are needed.
- No Defender scanning / no signing.
- Public network exposure (no Private Endpoint).
- No base-image triggers → stale, vulnerable images.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Premium | geo/PE/signing/CMK | higher cost |
| ACR Tasks | no local Docker, auto-patch | Azure-specific |
| Geo-replication | fast/resilient | per-region cost |

## 9. Production Best Practices
- Premium tier; disable admin; RBAC (AcrPull/AcrPush).
- `--attach-acr` / Workload Identity (secretless pulls).
- Defender scanning + Notation signing + admission verification.
- Private Endpoints + CMK; geo-replicate needed regions.
- ACR Tasks + base-image triggers; retention for untagged.

## 10. Security Considerations
- Identity-based auth (no admin creds); least-privilege roles.
- Private Endpoint (no public), firewall rules.
- Vulnerability scanning + signed images enforced at AKS admission.
- CMK encryption; audit logs to Log Analytics.

## 11. Cost Optimization
- Retention policy purges untagged manifests.
- Geo-replicate only required regions.
- Cache rules cut upstream egress + avoid rate-limit retries.
- Right tier — don't over-buy Premium if features unused.

## 12. Troubleshooting Scenarios
- **ImagePullBackOff from ACR** → AcrPull role missing / not attached; Private Endpoint DNS.
- **401/403 push** → RBAC (AcrPush) / disabled admin without role.
- **Can't reach ACR privately** → Private DNS zone `privatelink.azurecr.io` misconfig.
- **Stale base image CVEs** → no base-image trigger task.
- **Docker Hub rate limits** → add ACR cache rule.

## 13. Hands-on Example
```bash
az acr create -g rg -n myacr --sku Premium --admin-enabled false
az acr build -r myacr -t api:1.0 .
az acr repository show-tags -n myacr --repository api
```

## 14. Terraform Example
```hcl
resource "azurerm_container_registry" "acr" {
  name                          = "myacr"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = "eastus"
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false          # private only
  georeplications { location = "westeurope" }
  retention_policy { days = 30 enabled = true }
}

resource "azurerm_role_assignment" "aks_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

## 15. Azure Example
```bash
az aks update -g rg-aks -n prod-aks --attach-acr myacr     # secretless pull
az acr cache create -r myacr -n dockerhub \
  --source-repo "docker.io/library/*" \
  --target-repo "cached/*"                                 # pull-through cache
```

## 16. FastAPI / Python Example
```python
# CI: build & push to ACR then deploy by digest (reproducible)
import subprocess
def build_push(tag="api:1.0"):
    subprocess.run(["az", "acr", "build", "-r", "myacr", "-t", tag, "."], check=True)
    digest = subprocess.check_output(
        ["az", "acr", "repository", "show", "-n", "myacr",
         "--image", tag, "--query", "digest", "-o", "tsv"]).decode().strip()
    return f"myacr.azurecr.io/{tag.split(':')[0]}@{digest}"
```

## 17. AKS Example (deployment referencing ACR image by digest)
```yaml
spec:
  containers:
    - name: api
      image: myacr.azurecr.io/api@sha256:<digest>   # immutable, secretless pull
```

## 18. How to Remember
**"Premium = geo + private + signing; attach-acr = secretless pull; ACR Tasks = cloud build + auto-patch."**

## 19. Real-World Analogy
A high-security regional distribution network for a manufacturer: factories (ACR Tasks) produce and stamp verified goods, warehouses in each region (geo-replication) hold local stock, only badge-holders (managed identity) collect shipments, and products are auto-recalled/rebuilt when a defect is found upstream (base-image triggers).

## 20. One-Page Cheat Sheet
- **What**: Azure managed private OCI registry (images, Helm, artifacts).
- **Tiers**: Premium = geo-replication, Private Endpoints, signing, CMK, connected registry.
- **Build**: ACR Tasks (`az acr build`, no local Docker) + base-image triggers (auto CVE patch).
- **Secure pull**: `--attach-acr` / Workload Identity → AcrPull, no secrets.
- **Secure**: disable admin, RBAC, Defender scan, Notation sign, Private Endpoint, CMK.
- **Scale**: geo-replication + cache rules (Docker Hub rate-limit relief); retention for untagged.

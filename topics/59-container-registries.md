# 59 · Container Registries

> Domain: Docker & Containers · Level: Principal Container Architect

## 1. Beginner Explanation
A container registry is a **storage and distribution service for container images** — like a Git repository but for Docker images. You push images to it from CI and pull them when deploying.

## 2. Architect-Level Explanation
A registry stores OCI images/artifacts and serves push/pull:
- **Structure**: registry → repositories → tags + immutable **digests** (`sha256:...`). Layers are content-addressable and deduplicated.
- **Types**: public (Docker Hub, GHCR) vs private/managed (ACR, ECR, GAR).
- **Auth**: token/OAuth; enterprise uses **managed identity / Workload Identity** so clusters pull without stored creds.
- **Security**: vulnerability scanning, **image signing/attestations** (cosign, Notation), content trust, admission policies (only signed/trusted images).
- **Distribution**: geo-replication, pull-through cache, CDN for global/edge pulls.
- **Governance**: retention/cleanup of untagged manifests, quotas, RBAC per repo.
- **Beyond images**: OCI registries also store Helm charts, OCI artifacts, SBOMs.

## 3. Real Enterprise Use Case
An enterprise runs a private **ACR** with geo-replication across 3 regions: CI builds and pushes signed images, Defender scans them, AKS pulls via Workload Identity (no secrets), admission control (Ratify/Gatekeeper) blocks unsigned images, and retention policies purge old untagged manifests to control cost.

## 4. Architecture Diagram (ASCII)
```
   CI build ─► push (signed) ─► Registry (ACR)
                                repo:tag + digest(sha256)
                                geo-replicated (region A/B/C)
        scan (Defender) + sign (Notation/cosign)
                                │ pull (Workload Identity, no creds)
   AKS nodes ◄─── admission: only signed/trusted images (Ratify)
   Retention purges untagged manifests | RBAC per repo
```

## 5. Interview Questions
1. What is a registry vs repository vs tag vs digest?
2. Why prefer digests over tags in production?
3. How do you secure image supply chain?
4. How does a cluster authenticate to a private registry?
5. How do you distribute images globally?

## 6. Strong Interview Answers
- **Terminology**: "A registry hosts repositories; a repository holds tagged versions of an image; a tag (e.g., `1.0`) is a mutable pointer, while a digest (`sha256:...`) is an immutable content hash of the exact image."
- **Digests**: "Tags can be overwritten (`latest` today ≠ tomorrow). Pinning by digest guarantees you deploy the exact bytes you tested — reproducible, tamper-evident deployments."
- **Supply chain**: "Scan images for CVEs, sign them (cosign/Notation) with attestations/SBOMs, and enforce admission policies so only signed, scanned images from trusted registries run. Rebuild on base-image patches."
- **Cluster auth**: "For ACR + AKS I attach the registry to the cluster identity or use Workload Identity/managed identity — no long-lived pull secrets stored in the cluster."
- **Global distribution**: "Geo-replication puts image copies near each region (fast pulls, resilience), plus pull-through cache to avoid rate limits and reduce egress from upstream registries."

## 7. Common Mistakes
- Deploying by mutable `latest` tag (non-reproducible).
- Storing static registry credentials in the cluster.
- No scanning/signing (supply-chain risk).
- Never cleaning untagged manifests (storage bloat).
- Public images without pinning/verification.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Managed (ACR) | integrated, secure | Azure cost |
| Public (Docker Hub) | convenient | rate limits, trust |
| Geo-replication | fast/resilient | cost per region |

## 9. Production Best Practices
- Private managed registry (ACR) + RBAC per repo.
- Deploy by digest; sign + scan; enforce via admission.
- Workload Identity/managed identity for pulls (no secrets).
- Geo-replication / pull-through cache for scale.
- Retention policies for untagged manifests.

## 10. Security Considerations
- Vulnerability scanning (Defender) + fail gates.
- Image signing + attestations + SBOM; verify at admission.
- Private endpoints (no public exposure); least-privilege tokens.
- Quarantine unscanned images.

## 11. Cost Optimization
- Retention/purge of old untagged manifests.
- Right SKU/tier; geo-replicate only needed regions.
- Deduplicated layers reduce storage; cache to cut egress.

## 12. Troubleshooting Scenarios
- **ImagePullBackOff** → auth (identity/secret), wrong tag, network/private endpoint DNS.
- **Rate limited** → public registry limits → use ACR/pull-through cache.
- **Unsigned image blocked** → admission policy; sign properly.
- **Storage growing** → no retention on untagged manifests.
- **Slow pulls in region X** → add geo-replication.

## 13. Hands-on Example
```bash
docker tag myapp:1.0 myacr.azurecr.io/myapp:1.0
az acr login -n myacr
docker push myacr.azurecr.io/myapp:1.0
docker pull myacr.azurecr.io/myapp@sha256:<digest>   # pull by digest
```

## 14. Terraform Example
```hcl
resource "azurerm_container_registry" "acr" {
  name                = "myacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  sku                 = "Premium"        # geo-replication, private endpoints
  admin_enabled       = false            # use identity, not admin creds
  georeplications {
    location = "westeurope"
  }
  retention_policy { days = 30 enabled = true }
}
```

## 15. Azure Example
```bash
# Attach ACR to AKS so nodes pull via managed identity (no secret)
az aks update -g rg-aks -n prod-aks --attach-acr myacr
az acr repository list -n myacr
```

## 16. FastAPI / Python Example
```python
# CI helper: resolve immutable digest for reproducible deploys
import subprocess, json
def image_digest(ref: str) -> str:
    out = subprocess.check_output(
        ["az", "acr", "repository", "show", "-n", "myacr",
         "--image", ref, "-o", "json"])
    return json.loads(out)["digest"]   # pin deploy to this sha256
```

## 17. AKS Example (only signed images via Ratify/Gatekeeper)
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireSignedImages
metadata: { name: signed-only }
spec:
  match: { kinds: [{ apiGroups: [""], kinds: ["Pod"] }] }
  parameters: { registries: ["myacr.azurecr.io"] }   # verify signatures/attestations
```

## 18. How to Remember
**"Push signed, pull by digest, verify at admission."** Registry → repo → tag (mutable) vs digest (immutable).

## 19. Real-World Analogy
A bonded warehouse for goods: items are catalogued with exact serial numbers (digests), inspected before storage (scanning), sealed with tamper-proof tags (signing), and distributed to regional depots (geo-replication) — only verified goods leave the gate (admission control).

## 20. One-Page Cheat Sheet
- **Model**: registry → repository → tag (mutable) + digest `sha256` (immutable).
- **Prod**: deploy by digest; sign + scan; enforce trusted/signed at admission.
- **Auth**: Workload Identity / `--attach-acr` — no stored pull secrets.
- **Scale**: geo-replication + pull-through cache; private endpoints.
- **Govern**: retention/purge untagged, RBAC per repo, quotas.
- **Also stores**: Helm charts, SBOMs, OCI artifacts.

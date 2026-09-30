# DEEP MECHANICS · Azure Container Registry (ACR)

> Level 2 — SKUs, ACR Tasks, geo-replication, AKS integration (keyless pull),
> Private Link, and content trust.

---

## 0. The precise mental model
ACR = Microsoft's **managed private container registry** (OCI-compliant) with Azure-native **security (Entra, Private Link, scanning)**, **build automation (ACR Tasks)**, and **geo-replication**. The interview focus: **SKU choice**, **keyless AKS integration**, **private networking**, and **image build/patch automation**.

---

## 1. SKUs (Basic / Standard / Premium)
- **Basic** — dev, limited storage/throughput.
- **Standard** — most production (more storage/throughput).
- **Premium** — **geo-replication, Private Link, content trust/signing, customer-managed keys, higher throughput, availability zones, repository-scoped tokens**. Enterprise features live here.

## 2. AKS integration (keyless pull — the common question)
- **Attach ACR to AKS** (`az aks update --attach-acr`) → grants the cluster's **managed identity** the **AcrPull** role → nodes pull images **without stored credentials** (no imagePullSecret). This is the recommended pattern.
- Alternative: Workload Identity / repository-scoped tokens for finer control.

## 3. ACR Tasks (build automation)
- **Quick tasks** — cloud build (`az acr build`) without local Docker.
- **Triggered tasks** — rebuild on **git commit**, **base image update** (auto-patch when the OS base gets a CVE fix), or schedule.
- Multi-step tasks for build→test→push pipelines. Keeps images patched automatically.

## 4. Security
- **Entra RBAC** — AcrPull/AcrPush roles; **disable admin user** (use identities).
- **Private Link/Private Endpoint** (Premium) — registry reachable only privately; disable public access.
- **Microsoft Defender for Containers** — vulnerability scanning on push + registry posture.
- **Content trust / signing** + **repository-scoped tokens** (Premium) for least privilege.
- **Customer-managed keys** for encryption.

## 5. Geo-replication & resilience
- **Premium geo-replication** — one registry, multiple regions → **local low-latency pulls**, single management, regional resilience. Ideal for multi-region AKS.
- **Zone redundancy** for HA within a region.

## 6. The hard follow-ups (with answers)
1. **"How does AKS pull from ACR without credentials?"** → attach ACR → cluster managed identity gets AcrPull → keyless. (§2)
2. **"Which SKU for geo-replication/Private Link?"** → Premium. (§1)
3. **"Auto-patch images for base-image CVEs?"** → ACR Tasks base-image-update trigger rebuilds automatically. (§3)
4. **"Make ACR private?"** → Private Endpoint (Premium) + disable public access + Entra RBAC. (§4)
5. **"Fast pulls in multiple regions?"** → Premium geo-replication (one registry, regional replicas). (§5)
6. **"Least-privilege registry access?"** → AcrPull vs AcrPush roles, repository-scoped tokens, disable admin user. (§4)

## 7. One-screen recall
- ACR = managed private **OCI registry** with Azure-native security/build/replication.
- **SKUs**: Basic (dev) / Standard (prod) / **Premium** (geo-replication, **Private Link**, signing, CMK, zones, scoped tokens).
- **AKS keyless pull**: **attach ACR** → cluster **managed identity + AcrPull** (no imagePullSecret).
- **ACR Tasks**: cloud build + triggers (**git / base-image-update auto-patch / schedule**).
- **Security**: Entra RBAC (AcrPull/AcrPush), disable admin user, **Private Endpoint**, **Defender scanning**, content trust/scoped tokens, CMK.
- **Premium geo-replication** = local pulls + resilience; zone-redundant.

> Next: Batch E — IaC / Python / API.

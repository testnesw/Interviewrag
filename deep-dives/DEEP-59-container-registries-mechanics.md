# DEEP MECHANICS · Container Registries

> Level 2 — how registries store images (manifests/layers/digests), tags vs
> digests, pull/push flow, and registry security.

---

## 0. The precise mental model
A container registry is a **versioned store for container images** built on **content-addressable** storage: an image = a **manifest** that references **layer blobs** by **digest (SHA256)**. Registries handle push/pull, tagging, auth, scanning, and replication. The key mental model: **tags are mutable pointers; digests are immutable identities**.

---

## 1. How images are stored (OCI model)
- **Manifest** — JSON describing the image: config + ordered list of **layer digests** + platform. A **manifest list/index** points to per-architecture manifests (multi-arch).
- **Layer blobs** — the actual filesystem layers, stored **once** and **shared** across images (content-addressable by digest → dedup).
- **Digest** — `sha256:...` = cryptographic hash of content → immutable, verifiable identity.

## 2. Tags vs digests (critical)
- **Tag** (`myapp:1.2`, `:latest`) — a **mutable** human label pointing to a manifest; can be **moved** to a new image.
- **Digest** (`myapp@sha256:abc...`) — **immutable**; always the exact same image.
- **Best practice:** deploy by **digest** (or immutable version tags) for reproducibility/security; **never rely on `latest`** in prod (it moves).

## 3. Push/pull flow
```
push: client uploads layer blobs (skips ones registry already has) → uploads manifest → applies tag
pull: client gets manifest → downloads missing layers (cached ones skipped) → assembles image
```
Layer sharing + local cache → only changed layers transfer (fast deploys).

## 4. Security
- **Auth** — Entra/token/service principal; least privilege (pull vs push roles).
- **Private registries** — no public exposure; **Private Endpoint** for network isolation.
- **Vulnerability scanning** — Defender/Trivy on push.
- **Content trust / signing** (Notary/cosign) + **admission control** to allow only signed/scanned images.
- **Immutable tags** setting to prevent tag overwrites.

## 5. Features
- **Geo-replication** — same registry replicated across regions → fast local pulls, resilience.
- **Retention/cleanup** policies (untagged manifests) to control cost.
- **Webhooks** → trigger CI/CD on push.
- Can also store **Helm charts / OCI artifacts**.

## 6. The hard follow-ups (with answers)
1. **"How does a registry store an image?"** → manifest referencing layer blobs by digest; layers content-addressed + shared/deduped. (§1)
2. **"Tag vs digest?"** → mutable label vs immutable SHA256 identity; deploy by digest for reproducibility. (§2)
3. **"Why not use `latest` in prod?"** → it's a movable tag → non-reproducible/unsafe deploys. (§2)
4. **"Why are pushes/pulls fast?"** → only missing layers transfer (content-addressable dedup + cache). (§3)
5. **"Secure a registry?"** → private + Entra RBAC (pull/push) + Private Endpoint + scanning + signed-image admission. (§4)
6. **"Fast pulls across regions?"** → geo-replication. (§5)

## 7. One-screen recall
- Registry = versioned **content-addressable** image store: **manifest → layer blobs by digest**; manifest **index** = multi-arch.
- **Tag (mutable pointer)** vs **digest (immutable SHA256)** → deploy by **digest/immutable tag**, never `latest` in prod.
- Push/pull transfer **only missing layers** (dedup + cache) → fast.
- Security: private + **Entra RBAC (pull/push)** + **Private Endpoint** + **scanning** + **signing/admission** + immutable tags.
- Features: **geo-replication**, retention, webhooks, OCI artifacts/Helm.

> Next: Azure Container Registry.

# Deep Dive · Docker & Containerization

> Phase 2 (Platform & apps) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Docker is the standard tooling for **containers** — a way to package an app with all its dependencies into a single, portable **image** that runs identically anywhere ("build once, run anywhere"). A container is an **isolated process** sharing the host kernel (via Linux **namespaces + cgroups**), far lighter than a VM. Images are **layered and immutable**; containers are their running instances. Containers solve "works on my machine," enable **microservices**, and are the **unit of deployment** for Kubernetes/AKS.

---

## 2. Architect-Level Explanation
Containers = **OS-level virtualization**:
- **Namespaces** isolate what a process *sees* (PID, network, mount, user, IPC).
- **cgroups** limit what it *uses* (CPU, memory, I/O).
- **Union filesystem** gives **layered images** (each Dockerfile instruction = a cached layer).
- **Image** = immutable template (from a registry like **ACR**); **container** = a writable runtime instance.
- **OCI standard**: images/runtimes are standardized; Docker builds them, but **containerd/runc** (and Kubernetes) run them — Docker the daemon isn't required in prod.

Architecturally, containers give **immutable, portable, reproducible deployment artifacts** — the foundation for CI/CD, microservices, and orchestration. The architect's focus: **small, secure, reproducible images** and a trusted **supply chain**.

---

## 3. Why It Exists
- **Problem**: apps behaved differently across dev/test/prod due to dependency/environment drift; VMs were heavy and slow.
- **Breakthrough**: package app + deps + runtime into one **portable, immutable image**; start in milliseconds, dense packing.
- **Why enterprises adopt it**: reproducibility, faster delivery, microservices, and orchestration (K8s) — plus a standardized artifact (OCI) across the whole toolchain.
- **Why not VMs**: containers share the kernel → lighter, faster, denser; VMs isolate at hardware level → heavier but stronger isolation.

---

## 4. Internal Working
**Build → ship → run:**
1. **Dockerfile** → `docker build` → **layered image** (each instruction cached as a layer).
2. Image pushed to a **registry** (ACR/Docker Hub).
3. Runtime (**containerd/runc**) pulls the image, creates **namespaces + cgroups**, mounts the union FS, and starts the process (PID 1 = your app).
4. Container gets an isolated view (own filesystem, network, processes) but shares the host kernel.
5. Writes go to a thin **writable layer** (ephemeral); persistent data needs **volumes**.

Key mechanics:
- **Layer caching**: unchanged layers are reused → fast builds; order Dockerfile for cache efficiency (deps before code).
- **Multi-stage builds**: build in a fat image, copy only artifacts into a slim runtime image.
- **Immutability**: images don't change; you rebuild + redeploy (no in-place patching).

---

## 5. Enterprise Use Case
A bank containerizes its microservices: each service ships as a **multi-stage, distroless image** built in CI, scanned for CVEs, **signed**, and pushed to **ACR** (private endpoint). Kubernetes pulls these images by digest for reproducible, tamper-evident deploys. The same image promotes from dev → stage → prod unchanged, satisfying auditability and change control.

---

## 6. Real Production Architecture
```
 Dev ─► git push ─► CI (build)
                     │ docker build (multi-stage) → scan (Trivy/Defender) → sign (cosign)
                     ▼
             Azure Container Registry (private, geo-replicated)
                     │ pull by digest (Workload Identity)
                     ▼
             AKS nodes (containerd) ─► run Pods
                     │
              Volumes (PV) for state · Key Vault CSI for secrets
```

---

## 7. Security Best Practices
- **Minimal base images** (distroless/alpine/chiseled) — smaller attack surface.
- **Run as non-root**, read-only root filesystem, drop Linux capabilities.
- **Multi-stage builds** — no build tools/secrets in the final image.
- **No secrets in images/ENV** — inject at runtime (Key Vault CSI).
- **Scan images** (Trivy/Defender for Containers) in CI; **fail on critical CVEs**.
- **Sign images** (cosign/Notation) + verify at admission; **pull by digest**, not mutable tags.
- **Private registry (ACR)** with RBAC + private endpoint; **pin base image versions**.

---

## 8. Scaling Strategy
- Containers scale via the **orchestrator** (K8s HPA/replicas), not Docker itself.
- **Small images** → faster pulls, faster scale-out, less cold-start.
- **Image caching** on nodes + **registry proximity** (ACR in-region, geo-replication).
- **Stateless containers** scale horizontally; externalize state to volumes/managed services.

---

## 9. High Availability Strategy
- Containers are ephemeral — **HA comes from the orchestrator** (multiple replicas across nodes/zones).
- **Health checks** (K8s probes) restart/replace unhealthy containers.
- **Registry HA**: ACR geo-replication so pulls survive a regional issue.
- **Immutable images by digest** ensure identical instances everywhere.

---

## 10. Disaster Recovery Strategy
- **Registry geo-replication** (ACR) + retention of image digests.
- **Dockerfiles + build pipelines in Git** → rebuild any image deterministically.
- **Reproducible builds** (pinned base + deps) so recovery yields identical artifacts.
- Combine with K8s GitOps/IaC for full-stack rebuild.

---

## 11. Cost Optimization Strategy
- **Smaller images** = less storage, faster pulls, less egress, denser packing.
- **Multi-stage + slim bases** cut image size dramatically.
- **Layer cache** in CI to speed builds (less compute cost).
- **Registry cleanup**: purge untagged/old digests; lifecycle policies.
- Efficient images → better node bin-packing → fewer nodes.

---

## 12. Common Production Challenges
- **Bloated images** (build tools, full OS) → multi-stage + distroless.
- **Running as root** → privilege risk; enforce non-root.
- **Mutable `:latest` tags** → non-reproducible deploys; pin digests.
- **Secrets baked into layers** (leak in history) → runtime injection only.
- **Cache invalidation** from bad Dockerfile order → deps before code.
- **Large layers / slow pulls** at scale → optimize + cache + geo-replicate.
- **CVE drift** in base images → rebuild/patch regularly.

---

## 13. Monitoring and Observability
- **Container metrics** (CPU/mem/restarts) via orchestrator + cAdvisor/Prometheus.
- **Logs to stdout/stderr** → collected by node agents (Fluent Bit) → Log Analytics/Loki.
- **Image provenance**: track digests, SBOMs, scan results.
- **Runtime security** (Defender for Containers) for anomalous behavior.

---

## 14. Troubleshooting Scenarios
- **Container exits immediately** → PID 1 crashed/bad CMD; check logs, ensure long-running process.
- **Image too big/slow pull** → audit layers (`docker history`), adopt multi-stage/slim base.
- **Permission denied** → running non-root but files owned by root; fix ownership/USER.
- **Works locally, fails in K8s** → env/secret/network differences; check config injection.
- **CVE flagged in prod** → rebuild from patched base, re-scan, redeploy by new digest.

---

## 15. Tradeoffs
| Lever | Pro | Con |
|-------|-----|-----|
| Containers vs VMs | light, fast, dense | weaker isolation (shared kernel) |
| Distroless base | tiny, secure | harder to debug (no shell) |
| Multi-stage | small images | slightly complex Dockerfile |
| Pin by digest | reproducible | manual updates |

---

## 16. When NOT to use it
- **Workloads needing strong kernel isolation / untrusted multi-tenant** → VMs or sandboxed runtimes (Kata, gVisor).
- **Monolith with no delivery/scaling pain** → containerizing adds little.
- **Desktop/GUI or OS-specific kernel features** → containers may not fit.
- **Heavy stateful DBs** — prefer managed services over DIY containers.

---

## 17. Comparison with Alternatives
| Option | Isolation | Weight | Best for |
|--------|-----------|--------|----------|
| **Container** | process (namespaces) | light | microservices, CI/CD, K8s |
| VM | hardware/hypervisor | heavy | strong isolation, legacy OS |
| Sandboxed container (Kata/gVisor) | stronger | medium | untrusted multi-tenant |
| Serverless | provider-managed | none (to you) | event-driven, no infra |

---

## 18. Interview Questions
1. Container vs VM — how and when?
2. What are namespaces and cgroups?
3. Image vs container? What's immutable?
4. Explain layers and build caching.
5. What is a multi-stage build and why use it?
6. How do you secure a container image?
7. Why avoid `:latest` in production?
8. How do you handle secrets in containers?
9. How do containers scale and achieve HA?
10. OCI — why does it matter that Docker isn't the only runtime?

---

## 19. Strong Interview Answers
- **Container vs VM**: "A container is an isolated process sharing the host kernel via namespaces and cgroups — light, fast, dense. A VM virtualizes hardware with its own kernel — heavier but stronger isolation. I use containers for microservices/CI-CD, VMs when I need kernel-level isolation."
- **Image vs container**: "The image is an immutable, layered template; the container is a running instance with a thin writable layer. I never patch a running container — I rebuild the image and redeploy. Immutability is what makes deploys reproducible."
- **Multi-stage**: "Build in a fat stage with compilers/SDKs, then copy only the artifact into a slim/distroless runtime stage. Result: tiny, secure images with no build tools or secrets — faster pulls and smaller attack surface."
- **Secrets**: "Never bake secrets into layers or ENV — they persist in image history. Inject at runtime via Key Vault CSI/secrets manager. In CI, use build secrets that aren't committed to layers."
- **No `:latest`**: "`latest` is mutable — two deploys can pull different images, breaking reproducibility and rollback. I pin by immutable digest for tamper-evident, repeatable deploys."

---

## 20. Architecture Diagrams
**Layers & multi-stage:**
```
[build stage]  FROM sdk → restore → compile → /app/out
      │ copy artifact only
[runtime stage] FROM distroless → COPY /app/out → USER nonroot → ENTRYPOINT
Image = ordered layers (cached); container = image + writable layer
```

---

## 21. Real Project Example
**Supply-chain-hardened images.** Every service builds via multi-stage into a **distroless, non-root** image in CI; Trivy scans and fails on criticals; cosign signs; the image pushes to **ACR** and is deployed **by digest**. AKS admission (Kyverno) verifies the signature and rejects unsigned/mutable-tag images. Image size dropped ~70% vs the original single-stage build, pull times and node density improved, and every prod artifact is provably built from source.

---

## 22. Whiteboard Design Question
> *"Design a secure container build-and-supply-chain pipeline for a regulated enterprise."*

Cover: Git → CI multi-stage build (pinned base) → SBOM generation → CVE scan (fail-gate) → sign (cosign) → push to ACR (private, geo-replicated) → admission verification (Kyverno: signed + non-root + no `:latest`) → deploy by digest → runtime protection (Defender) → registry lifecycle/cleanup. Emphasize reproducibility, provenance, and change control for audit.

---

## 23. Design Review Questions
- **Base image** minimal, pinned, non-root?
- **Multi-stage** with no build tools/secrets in final image?
- **Scanned + signed**, deployed by **digest**?
- **Secrets injected at runtime**, not baked?
- **Registry** private + geo-replicated + lifecycle policy?
- **Admission policy** enforcing signatures/non-root?
- **SBOM/provenance** captured for audit?

---

## 24. Hands-on Example
```dockerfile
# Multi-stage, non-root, slim runtime for a FastAPI app
FROM python:3.12-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt   # deps layer (cached)
COPY . .

FROM python:3.12-slim AS runtime
RUN useradd -m appuser
COPY --from=build /install /usr/local
COPY --from=build /app /app
WORKDIR /app
USER appuser                       # non-root
EXPOSE 8000
ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 25. Terraform Example
```hcl
# Private, geo-replicated ACR with admin disabled (use RBAC/Workload Identity)
resource "azurerm_container_registry" "acr" {
  name                = "genaiacr"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Premium"          # required for geo-replication + private link
  admin_enabled       = false

  georeplications { location = "westeurope" }
  georeplications { location = "eastus2" }

  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"
}
```

---

## 26. Azure Example
```bash
# Build in the cloud (ACR Tasks — no local Docker), scan, and enable content trust
az acr build -r genaiacr -t orchestrator:1.0.0 .          # remote build + push
az acr repository show-tags -n genaiacr --repository orchestrator
# Grant AKS/Workload Identity pull access (no admin creds)
az role assignment create --assignee $WORKLOAD_MI_ID --role AcrPull \
  --scope $(az acr show -n genaiacr --query id -o tsv)
```

---

## 27. Code Example
```yaml
# Kyverno policy: only signed, non-root, non-:latest images from ACR are admitted
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: { name: image-supply-chain }
spec:
  validationFailureAction: Enforce
  rules:
  - name: require-acr-digest
    match: { any: [{ resources: { kinds: [Pod] } }] }
    validate:
      message: "Images must come from ACR and be pinned by digest (no :latest)."
      pattern:
        spec:
          containers:
          - image: "genaiacr.azurecr.io/*@sha256:*"
```

---

## 28. Things Architects Must Remember
- **Container = isolated process (namespaces + cgroups)**, not a mini-VM.
- **Images are immutable + layered** — rebuild & redeploy, never patch live.
- **Small, non-root, distroless** images = security + speed + density.
- **Multi-stage builds** keep build tools/secrets out of runtime images.
- **Never bake secrets**; inject at runtime.
- **Pin by digest**, ban `:latest` — reproducibility + rollback.
- **Sign + scan + SBOM** — the software supply chain is an attack surface.
- **HA/scaling comes from the orchestrator**, not Docker.

---

## 29. Mnemonics and Memory Tricks
- **"Namespaces = what you see, cgroups = what you use."**
- **Image security "S-N-P-S"**: **S**can, **N**on-root, **P**in-by-digest, **S**ign.
- **"Build once, run anywhere"** — the container promise (via OCI).
- **"Multi-stage = fat build, slim ship."**
- **"latest lies"** — never trust a mutable tag in prod.

---

## 30. One-Page Interview Revision Sheet
- **What**: package app+deps into an immutable, layered, portable image; run as an isolated process (namespaces + cgroups).
- **Image vs container**: template vs running instance (+ thin writable layer).
- **Build**: Dockerfile → layers (cached); **multi-stage** = slim, secure final image.
- **Security**: minimal/distroless base, non-root, read-only rootfs, drop caps, scan + sign + SBOM, no baked secrets, pin by digest.
- **Registry**: ACR private + geo-replicated; pull via Workload Identity (AcrPull).
- **Scale/HA/DR**: from the orchestrator (replicas/zones); reproducible builds + geo-replicated registry.
- **Cost**: small images → less storage/egress, faster pulls, denser packing; registry cleanup.
- **OCI**: standardized images/runtimes; containerd/runc run them (Docker daemon not needed in prod).
- **When NOT**: strong-isolation/untrusted multi-tenant → VMs/sandboxed runtimes.
- **Remember**: *namespaces see / cgroups use*; *images immutable*; *S-N-P-S* security; *latest lies*.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Explain exactly how a container isolates a process. Which kernel features and what do they each do?
2. Container vs VM — give a scenario where you'd deliberately choose a VM.
3. Walk through what happens from `docker build` to a running pod in AKS.
4. Why are multi-stage builds important? Show the before/after security impact.
5. A teammate ships images tagged `:latest`. Explain the production risk and your fix.
6. How do you keep secrets out of images across build and runtime?
7. Design an image supply-chain pipeline that satisfies auditors in a regulated firm.
8. Your image is 1.2 GB and scaling is slow. How do you diagnose and shrink it?
9. What is OCI and why does it matter that Kubernetes doesn't use the Docker daemon?
10. How do containers achieve HA and scaling if they're ephemeral?

---

> Next Phase 2 topic: **FastAPI**.

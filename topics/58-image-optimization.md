# 58 · Docker Image Optimization

> Domain: Docker & Containers · Level: Principal Container Architect

## 1. Beginner Explanation
Image optimization means making your container images **smaller, faster to build, and more secure** — by choosing lean base images, removing unnecessary files, and structuring the Dockerfile well.

## 2. Architect-Level Explanation
Optimize across three axes — **size, build speed, security**:
- **Multi-stage builds**: compile/build in a "builder" stage, copy only artifacts into a tiny runtime stage (no compilers/dev deps in the final image).
- **Minimal base images**: `slim`, `alpine`, or **distroless** (no shell/package manager → tiny + secure); scratch for static binaries.
- **Layer caching & ordering**: put rarely-changing steps (deps install) before frequently-changing steps (app code) to maximize cache hits.
- **Reduce layers/size**: combine RUN commands, clean package caches in the same layer, use `.dockerignore` to exclude junk (`.git`, tests, node_modules).
- **BuildKit**: parallel builds, cache mounts, secrets at build time (no leaking).
- **Non-root + read-only**: security by construction.
- **Reproducibility**: pin versions/digests; scan and (optionally) sign.

## 3. Real Enterprise Use Case
A team shrinks a Python image from 1.2 GB to 90 MB using multi-stage builds + distroless, cutting pull time and autoscaling cold-starts dramatically, reducing ACR storage/egress cost, and lowering CVE count by dropping the shell and OS packages — all enforced in CI with image scanning gates.

## 4. Architecture Diagram (ASCII)
```
   Stage 1: builder (full toolchain)
     COPY reqs ─► install/compile ─► artifacts
                    │ copy ONLY artifacts
   Stage 2: runtime (distroless/slim, non-root)
     COPY --from=builder /app  ─►  tiny final image
   .dockerignore trims context | layers ordered deps→code
   Result: 1.2GB ─► 90MB  (faster pulls, fewer CVEs)
```

## 5. Interview Questions
1. How do multi-stage builds reduce image size?
2. What base images do you choose and why?
3. How do you maximize layer cache hits?
4. What is distroless and its trade-off?
5. How do you handle build-time secrets safely?

## 6. Strong Interview Answers
- **Multi-stage**: "Build with the full toolchain in one stage, then copy only the compiled artifacts/runtime deps into a minimal final stage — the compilers, dev packages, and intermediate files never ship, so the image is far smaller and more secure."
- **Base choice**: "I pick the smallest base that works: `slim` for convenience, `distroless` for security (no shell/pkg manager), `scratch` for static binaries. Smaller base = fewer CVEs, faster pulls."
- **Cache**: "Order instructions least-to-most changing — copy dependency manifests and install deps before copying app code, so code changes don't invalidate the dependency layer. Use BuildKit cache mounts for package caches."
- **Distroless**: "A base with just your app + runtime, no shell or package manager — tiny attack surface and size. Trade-off: harder to debug (no `sh`), so I use ephemeral debug containers or a debug image variant."
- **Build secrets**: "Use BuildKit `--secret` mounts (or multi-stage) so secrets are available during build but never persisted in a layer — never `COPY` a secret or bake it into an env layer."

## 7. Common Mistakes
- Single-stage builds shipping compilers/dev deps.
- Using `latest` / unpinned bases (non-reproducible).
- `COPY . .` before installing deps (busts cache).
- Secrets baked into layers (recoverable via history).
- No `.dockerignore` (huge build context).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Distroless/scratch | tiny, secure | no shell to debug |
| Alpine | small | musl libc edge cases |
| Slim | balanced | larger than distroless |

## 9. Production Best Practices
- Multi-stage + minimal/distroless base.
- Order layers deps→code; combine RUN + clean caches.
- `.dockerignore`; pin versions/digests.
- BuildKit (cache mounts, secret mounts).
- Non-root, read-only rootfs; scan images in CI (fail on high CVEs).

## 10. Security Considerations
- Smaller surface (distroless) → fewer CVEs.
- No secrets/creds in layers; scan `docker history`.
- Non-root, drop capabilities; sign images (cosign/Notation).
- Regularly rebuild to pick up base image patches.

## 11. Cost Optimization
- Smaller images → less ACR storage + egress, faster pulls/scaling.
- Shared cached layers reduce registry footprint.
- Faster builds → lower CI compute cost.

## 12. Troubleshooting Scenarios
- **Image too big** → single-stage / fat base / dev deps → multi-stage + distroless.
- **Slow builds** → cache-busting order; add BuildKit cache mounts.
- **Can't debug distroless** → use `kubectl debug`/ephemeral container.
- **Secret leaked** → found in layer history; switch to BuildKit secrets, rotate.
- **Huge context** → missing `.dockerignore`.

## 13. Hands-on Example
```bash
DOCKER_BUILDKIT=1 docker build -t myapp:1.0 .
docker history myapp:1.0            # inspect layer sizes
docker images myapp:1.0            # check final size
dive myapp:1.0                     # analyze wasted space
```

## 14. Terraform Example
```hcl
# Enforce scanning gate conceptually; ACR task triggers on base image update
resource "azurerm_container_registry_task" "build" {
  name                  = "build-api"
  container_registry_id = azurerm_container_registry.acr.id
  platform { os = "Linux" }
  docker_step {
    dockerfile_path = "Dockerfile"
    context_path    = "https://github.com/org/api.git"
    image_names     = ["api:{{.Run.ID}}"]
  }
  base_image_trigger { name = "base" type = "Runtime" }   # rebuild on base CVE patch
}
```

## 15. Azure Example
```bash
az acr build -r myacr -t api:1.0 .          # cloud build (BuildKit)
az acr repository show-manifests -n myacr --repository api  # sizes
# Defender scans pushed images for vulnerabilities automatically
```

## 16. FastAPI / Python Example (optimized multi-stage Dockerfile)
```dockerfile
# ---- builder ----
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- runtime (distroless, non-root) ----
FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
USER 1000
EXPOSE 8080
CMD ["-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

## 17. AKS Example
Smaller images = faster image pulls on new nodes during Cluster Autoscaler scale-up and quicker HPA scale-out (less cold-start), directly improving elasticity and reducing spot-node churn impact.

## 18. How to Remember
**"Multi-stage + distroless + cache order + .dockerignore."** Build fat, ship thin, order layers deps→code.

## 19. Real-World Analogy
Packing for a trip: you use a big workshop to prepare (builder stage) but only pack the finished, essential items in a compact carry-on (runtime stage) — leaving the tools, packaging, and scraps behind.

## 20. One-Page Cheat Sheet
- **Multi-stage**: build with toolchain, ship only artifacts.
- **Base**: distroless/scratch (secure/tiny) > slim > full.
- **Cache**: order deps→code; BuildKit cache mounts.
- **Trim**: `.dockerignore`, combine RUN + clean caches, pin versions/digests.
- **Secure**: non-root, read-only, no secrets in layers, scan + sign, rebuild for patches.
- **Payoff**: faster pulls/scaling, less ACR cost, fewer CVEs.

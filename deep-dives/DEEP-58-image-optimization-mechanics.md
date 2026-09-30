# DEEP MECHANICS · Image Optimization

> Level 2 — multi-stage builds, layer caching, minimal base images, and the
> security/size/speed wins.

---

## 0. The precise mental model
Image optimization = making images **small, fast to build/pull, and secure** by controlling **layers, base image, and build stages**. Smaller images = faster deploys/scaling, less attack surface, lower storage/egress. The two biggest techniques: **multi-stage builds** (ship only the artifact, not the toolchain) and **minimal base images** (distroless/alpine).

---

## 1. Multi-stage builds (the #1 technique)
```dockerfile
# Stage 1: build (has compilers/SDK)
FROM golang:1.22 AS build
WORKDIR /src
COPY . .
RUN go build -o app

# Stage 2: runtime (tiny, only the binary)
FROM gcr.io/distroless/static
COPY --from=build /src/app /app
ENTRYPOINT ["/app"]
```
Build tools stay in the discarded build stage; the final image ships **only the artifact** → from GBs to MBs, far less attack surface.

## 2. Layer caching & ordering
- Each instruction = a cached layer; **order stable→volatile**: copy dependency manifests and install deps **before** copying source, so code changes don't bust the dependency cache.
- Combine related `RUN` commands (`&&`) to reduce layers and clean up in the same layer (`apt-get ... && rm -rf /var/lib/apt/lists/*`) — deleting in a later layer doesn't shrink the image.
- Use **`.dockerignore`** to avoid copying junk (node_modules, .git) into the build context.

## 3. Minimal base images
- **distroless** (no shell/package manager → smallest attack surface) > **alpine** (tiny, musl libc) > **slim** > full OS.
- Smaller base = fewer CVEs, smaller size. Distroless also **hardens** (no shell for attackers).
- Pin by **digest** (not `latest`) for reproducibility.

## 4. Security wins
- Fewer packages = fewer vulnerabilities.
- **Run as non-root** (`USER`), read-only filesystem.
- **Scan images** (Trivy/Defender) in CI; rebuild to patch (immutable — no in-place updates).
- No secrets baked into layers (they persist in history even if deleted later).

## 5. Other techniques
- **Squash/optimize** layers; use **BuildKit** (parallel, cache mounts, secrets at build without baking).
- Multi-arch builds; smaller runtimes (JRE→JLink, node slim).

## 6. The hard follow-ups (with answers)
1. **"How do you shrink an image?"** → multi-stage build (ship artifact only) + minimal/distroless base + fewer layers. (§1,3)
2. **"Why order Dockerfile steps?"** → layer cache; deps before source so code changes don't rebuild deps. (§2)
3. **"Why does deleting files in a later layer not shrink the image?"** → layers are additive; clean up in the same RUN. (§2)
4. **"distroless vs alpine?"** → no shell/pkg-mgr (smallest, hardened) vs tiny with shell (musl). (§3)
5. **"Secret accidentally added then removed — safe?"** → no, it persists in image history; rebuild without it. (§4)
6. **"Reduce vulnerabilities?"** → minimal base, non-root, scan in CI, rebuild to patch. (§4)

## 7. One-screen recall
- Optimize = **small + fast + secure** via layers/base/stages.
- **Multi-stage build**: build stage (toolchain) → runtime stage ships **only the artifact** (MBs, low attack surface).
- **Layer cache**: order **stable→volatile** (deps before source); combine RUN + clean in **same layer**; **.dockerignore**.
- **Minimal base**: **distroless** (no shell, hardened) > alpine > slim; pin by **digest**.
- **Security**: non-root, read-only FS, **scan (Trivy/Defender)**, rebuild to patch, no baked secrets (persist in history).
- **BuildKit** (cache mounts, build secrets).

> Next: Container Registries.

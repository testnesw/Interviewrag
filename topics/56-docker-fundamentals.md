# 56 · Docker Fundamentals

> Domain: Docker & Containers · Level: Principal Container Architect

## 1. Beginner Explanation
Docker packages your app and everything it needs (code, runtime, libraries) into a **container** — a lightweight, portable unit that runs the same way on any machine. "Works on my machine" becomes "works everywhere."

## 2. Architect-Level Explanation
Docker is a container platform built on Linux kernel primitives:
- **Namespaces** (isolation: PID, network, mount, user) + **cgroups** (resource limits: CPU/memory) + **union filesystems** (layered images).
- **Image**: immutable, layered, read-only template (built from a Dockerfile). **Container**: a running instance with a thin writable layer on top.
- **Architecture**: Docker CLI → **dockerd** daemon → **containerd** → **runc** (OCI runtime). Images/runtime follow **OCI standards** (portable across Docker, Podman, containerd).
- **Layers**: each Dockerfile instruction = a cached layer → fast rebuilds, shared storage.
- **Registry**: stores/distributes images (Docker Hub, ACR).
- Containers share the host kernel (unlike VMs) → lightweight, fast, dense.

## 3. Real Enterprise Use Case
A company containerizes 50 microservices: identical images promote from dev → staging → prod (build once, run anywhere), CI builds OCI images pushed to ACR, and Kubernetes/AKS runs them at scale — eliminating environment drift and enabling fast, consistent deployments.

## 4. Architecture Diagram (ASCII)
```
   Dockerfile ─► docker build ─► Image (layered, immutable)
        │                            │ push
   docker CLI ─► dockerd ─► containerd ─► runc ─► Container
                                              │ (namespaces+cgroups)
   Registry (Docker Hub / ACR) ◄── push/pull ─┘
   VM: full OS per app  |  Container: shares host kernel (light)
```

## 5. Interview Questions
1. Container vs virtual machine?
2. Image vs container?
3. What kernel features make containers work?
4. What is OCI / containerd / runc?
5. How do image layers and caching work?

## 6. Strong Interview Answers
- **Container vs VM**: "VMs virtualize hardware and run a full guest OS per app (heavy, slow boot); containers virtualize the OS and share the host kernel via namespaces/cgroups — lightweight, fast, dense. VMs give stronger isolation; containers give speed and portability."
- **Image vs container**: "An image is an immutable, layered template; a container is a running instance of that image with a thin writable layer. Many containers can run from one image."
- **Kernel features**: "Namespaces isolate what a process sees (PID, net, mount, user); cgroups limit what it can use (CPU, memory, I/O); union filesystems provide layered images. That's the whole magic — no hypervisor."
- **OCI/containerd/runc**: "OCI defines standard image and runtime specs so tools interoperate. containerd is the high-level runtime managing image/container lifecycle; runc is the low-level OCI runtime that actually spawns the container. Kubernetes talks to containerd via CRI (Docker Engine itself was removed as a runtime)."
- **Layers/cache**: "Each Dockerfile instruction creates a cached layer. Unchanged layers are reused across builds and shared across images, so ordering instructions from least- to most-frequently-changing maximizes cache hits."

## 7. Common Mistakes
- Confusing image (template) with container (instance).
- Treating containers like VMs (SSH-ing in, stateful pets).
- Running as root inside containers.
- Poor layer ordering → cache busting → slow builds.
- Storing state in the container writable layer.

## 8. Trade-offs
| Aspect | Container | VM |
|--------|-----------|----|
| Weight/boot | light/seconds | heavy/minutes |
| Isolation | shared kernel | strong (own kernel) |
| Density | high | lower |

## 9. Production Best Practices
- One process/concern per container; stateless where possible.
- Non-root user; minimal base images.
- Pin image versions (avoid `latest`).
- Externalize state (volumes/DB) and config (env/ConfigMap).
- Health checks; graceful shutdown (handle SIGTERM).

## 10. Security Considerations
- Run as non-root; drop capabilities; read-only rootfs.
- Scan images for vulnerabilities; use trusted/minimal bases.
- No secrets baked into images.
- Keep daemon/runtime patched; consider rootless/Podman.

## 11. Cost Optimization
- Smaller images → faster pulls, less storage/egress.
- Higher density than VMs → better hardware utilization.
- Shared layers reduce registry storage.

## 12. Troubleshooting Scenarios
- **Container exits immediately** → main process ends/crashes; check `docker logs`.
- **Image huge** → too many layers/dev deps; multi-stage build.
- **Permission denied** → non-root user vs file ownership.
- **Port unreachable** → not published (`-p`) / wrong bind address.
- **Slow builds** → cache-busting layer order.

## 13. Hands-on Example
```bash
docker build -t myapp:1.0 .
docker run -d -p 8080:8080 --name api myapp:1.0
docker ps && docker logs -f api
docker exec -it api sh
```

## 14. Terraform Example
```hcl
# Build & push handled in CI, but Terraform can manage a local image/container
resource "docker_image" "api" { name = "myapp:1.0" }
resource "docker_container" "api" {
  name  = "api"
  image = docker_image.api.image_id
  ports { internal = 8080 external = 8080 }
}
```

## 15. Azure Example
```bash
# Build in the cloud (no local Docker) and push to ACR
az acr build -r myacr -t myapp:1.0 .
```

## 16. FastAPI / Python Example (Dockerfile)
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt   # deps layer (cached)
COPY . .                                              # code layer (changes often)
USER 1000                                             # non-root
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

## 17. AKS Example
The same OCI image built above runs unchanged in AKS — Kubernetes pulls it from ACR via containerd (CRI). Build once, run in Docker locally and AKS in prod.

## 18. How to Remember
**"Namespaces isolate, cgroups limit, layers stack."** Image = template, container = running instance, shares the host kernel.

## 19. Real-World Analogy
Shipping containers: standardized boxes (images) that hold goods (your app + deps) and fit any ship, truck, or crane (any host) — versus building a custom truck for each shipment (a VM per app).

## 20. One-Page Cheat Sheet
- **Container**: app + deps sharing the host kernel (namespaces + cgroups); light, portable.
- **Image vs container**: immutable layered template vs running instance (+writable layer).
- **Stack**: CLI → dockerd → containerd → runc (OCI); K8s uses containerd via CRI.
- **Layers**: cached per instruction; order least→most changing.
- **Best practice**: non-root, minimal base, pinned versions, stateless, health checks.
- **Cloud**: `az acr build` to build/push without local Docker.

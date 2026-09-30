# 57 · Containerization (App Design & Packaging)

> Domain: Docker & Containers · Level: Principal Container Architect

## 1. Beginner Explanation
Containerization is the process of taking an application and packaging it — with its dependencies and configuration — so it runs reliably as a container. It's not just "make a Dockerfile"; it's designing the app to behave well in a container world.

## 2. Architect-Level Explanation
Containerizing well means adopting **cloud-native / 12-factor** design:
- **Stateless processes**: no local state; externalize to DB/cache/object storage; state via volumes only when unavoidable.
- **Config in the environment**: env vars / ConfigMaps / Secrets, not baked into the image (build once, run anywhere).
- **Ephemeral & disposable**: fast startup, graceful shutdown (handle **SIGTERM**), crash-safe, no reliance on the writable layer.
- **One concern per container**; sidecars for cross-cutting concerns.
- **Health endpoints**: liveness/readiness for orchestrators.
- **Logs to stdout/stderr** (not files) — collected by the platform.
- **Image hygiene**: small base, non-root, pinned deps, multi-stage builds, `.dockerignore`.
- **Port binding**: app self-contained, listens on a port.

## 3. Real Enterprise Use Case
A team modernizes a monolith: extracts stateless services, moves sessions to Redis and files to Blob Storage, externalizes config to ConfigMaps/Key Vault, adds `/healthz` probes and SIGTERM handling for zero-downtime rollouts, and standardizes multi-stage Dockerfiles — enabling reliable AKS deployments and autoscaling.

## 4. Architecture Diagram (ASCII)
```
   12-Factor container:
   ┌─────────────────────────────┐
   │ App process (stateless)     │ ← config via env/ConfigMap/Secret
   │ listens :8080               │ ← logs to stdout/stderr
   │ /healthz /ready             │ ← probes
   │ handles SIGTERM (graceful)  │
   └─────────────────────────────┘
   State ─► DB / Redis / Blob (external, not local disk)
   Image: small base · non-root · multi-stage · pinned deps
```

## 5. Interview Questions
1. What makes an app "container-ready" (12-factor)?
2. How do you handle state in containers?
3. Why handle SIGTERM / graceful shutdown?
4. Where should logs and config go?
5. How do you keep images small and secure?

## 6. Strong Interview Answers
- **Container-ready**: "12-factor: stateless disposable processes, config in the environment, logs to stdout, port binding, fast startup/graceful shutdown. The app shouldn't assume a persistent local disk or a fixed host."
- **State**: "Keep containers stateless — push state to external services (DB, Redis, Blob). If truly stateful, use StatefulSets + persistent volumes, but avoid relying on the container's writable layer, which is ephemeral."
- **SIGTERM**: "On rollout/scale-down the orchestrator sends SIGTERM then waits (termination grace period). Handling it lets the app drain in-flight requests and close connections cleanly — enabling zero-downtime deploys. Ignoring it causes dropped requests/errors."
- **Logs/config**: "Logs to stdout/stderr so the platform (Container Insights) collects them — don't write log files inside the container. Config via env vars/ConfigMaps/Secrets so the same image runs in every environment."
- **Small/secure images**: "Multi-stage builds, minimal/distroless base, non-root user, pinned dependencies, `.dockerignore`, and vulnerability scanning — smaller attack surface, faster pulls."

## 7. Common Mistakes
- Storing state on local disk / writable layer.
- Baking environment-specific config into images.
- Ignoring SIGTERM → dropped requests on rollout.
- Logging to files instead of stdout.
- Fat images with build tools/dev deps in runtime.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Stateless | scalable, disposable | needs external state stores |
| Distroless base | tiny/secure | harder to debug (no shell) |
| Sidecar concerns | reusable | extra resource/complexity |

## 9. Production Best Practices
- 12-factor: stateless, env config, stdout logs, port binding.
- Graceful shutdown (SIGTERM) + liveness/readiness probes.
- Multi-stage builds, non-root, minimal base, pinned deps.
- Externalize state and secrets.
- `.dockerignore`, reproducible builds, image scanning in CI.

## 10. Security Considerations
- Non-root, read-only rootfs, dropped capabilities.
- No secrets in image layers or env baked at build.
- Minimal/distroless base; scan + sign images.

## 11. Cost Optimization
- Small images → less storage/egress, faster autoscaling.
- Stateless → easy scale-to-zero and spot usage.
- Right-size per-container resources.

## 12. Troubleshooting Scenarios
- **Requests dropped on deploy** → no SIGTERM handling / short grace period.
- **Data lost on restart** → state on writable layer/local disk.
- **Config wrong per env** → baked into image instead of env.
- **No logs in platform** → app logging to file, not stdout.
- **Slow scale-up** → oversized image / slow startup.

## 13. Hands-on Example
```bash
# Verify graceful shutdown
docker run -d --name api myapp:1.0
docker stop api      # sends SIGTERM then SIGKILL after grace
docker logs api      # should show "draining... shutdown complete"
```

## 14. Terraform Example
```hcl
# Deployment wiring config as env (build-once image), external state via DB URL
resource "kubernetes_deployment" "api" {
  metadata { name = "api" namespace = "app" }
  spec {
    template {
      spec {
        container {
          name  = "api" image = "myacr.azurecr.io/api:1.0"
          env { name = "REDIS_URL" value = var.redis_url }   # external state
          readiness_probe { http_get { path = "/ready" port = 8080 } }
        }
        termination_grace_period_seconds = 30
      }
    }
  }
}
```

## 15. Azure Example
Externalize state with Azure services: **Azure Cache for Redis** (sessions), **Blob Storage** (files), **Azure SQL/PostgreSQL** (data), config via **App Configuration** + **Key Vault** — containers stay stateless.

## 16. FastAPI / Python Example (graceful shutdown + probes)
```python
import signal, asyncio
draining = False

@app.get("/ready")
def ready(): return ("draining", 503) if draining else {"status": "ok"}

@app.on_event("shutdown")
async def on_shutdown():
    global draining; draining = True     # fail readiness, drain traffic
    await asyncio.sleep(5)               # let in-flight requests finish
```

## 17. AKS Example (probes + grace period)
```yaml
spec:
  terminationGracePeriodSeconds: 30
  containers:
    - name: api
      image: myacr.azurecr.io/api:1.0
      readinessProbe: { httpGet: { path: /ready, port: 8080 }, periodSeconds: 5 }
      livenessProbe:  { httpGet: { path: /healthz, port: 8080 }, periodSeconds: 10 }
      lifecycle: { preStop: { exec: { command: ["sleep", "5"] } } }
```

## 18. How to Remember
**"12-factor: stateless, config-in-env, logs-to-stdout, graceful shutdown."** Design the app for the container, not just wrap it.

## 19. Real-World Analogy
A food truck vs a fixed restaurant: the truck (container) carries everything it needs, plugs into any location's utilities (env config), keeps no perishables onboard overnight (stateless), and can pack up cleanly in minutes when told to move (SIGTERM).

## 20. One-Page Cheat Sheet
- **Goal**: design app to be container-ready (12-factor), not just Dockerized.
- **Stateless**: externalize state → DB/Redis/Blob; avoid writable layer.
- **Config**: env/ConfigMap/Secret — build once, run anywhere.
- **Lifecycle**: fast start + graceful SIGTERM drain + liveness/readiness.
- **Logs**: stdout/stderr (platform collects).
- **Image**: multi-stage, non-root, minimal base, pinned deps, scanned.

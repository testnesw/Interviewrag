# 47 · ConfigMaps

> Domain: Kubernetes & AKS · Level: Principal Kubernetes Architect

## 1. Beginner Explanation
A ConfigMap stores **non-sensitive configuration** (settings, URLs, feature flags, config files) separately from your container image, so you can change config without rebuilding the image.

## 2. Architect-Level Explanation
A namespaced key-value store for configuration:
- **Consumption**: env vars, command args, or mounted files (whole config files supported).
- **Decoupling**: implements the 12-factor "config in the environment" principle — same image, different config per environment.
- **Updates**: mounted volumes update automatically (with delay); env vars do **not** update until Pod restart.
- **vs Secret**: same mechanics, but ConfigMaps are for non-sensitive data (no base64/encryption semantics).
- **Limits**: ~1 MiB size; immutable ConfigMaps improve performance/safety.

## 3. Real Enterprise Use Case
A microservice loads its `appsettings.json`, feature flags, and downstream service URLs from a ConfigMap mounted as files. Per-environment ConfigMaps (dev/stage/prod) let the same image run everywhere; a config change + rollout updates behavior with no rebuild.

## 4. Architecture Diagram (ASCII)
```
   ConfigMap (app-config)
     LOG_LEVEL=info
     appsettings.json: {...}
        │ consumed as
   ┌────┴─────────────┐
 env vars          mounted files (/etc/config/appsettings.json)
 (static)          (auto-update, delayed)
   Same image + different ConfigMap per environment
```

## 5. Interview Questions
1. ConfigMap vs Secret?
2. Env var vs volume-mounted ConfigMap?
3. Do ConfigMap changes take effect automatically?
4. How do you manage per-environment config?
5. What is an immutable ConfigMap?

## 6. Strong Interview Answers
- **vs Secret**: "Same key-value mechanics, but ConfigMaps are for non-sensitive config; Secrets are for confidential data (and should be encrypted). Don't put credentials in a ConfigMap."
- **Env vs volume**: "Env vars are simple but static — they need a Pod restart to change. Volume mounts update automatically (with a sync delay) and support whole config files — better for dynamic config."
- **Auto-effect**: "Only for volume mounts, and the app must re-read the file (or a reloader restarts the Pod). Env-var-based config requires a rollout to pick up changes."
- **Per-env**: "Separate ConfigMaps per environment (or Helm values/Kustomize overlays) so one image runs everywhere with environment-specific config."
- **Immutable**: "`immutable: true` prevents accidental changes and reduces API server load (no watch) — good for stable config; you replace rather than edit."

## 7. Common Mistakes
- Storing secrets in ConfigMaps.
- Expecting env-var config to update without restart.
- Giant configs (>1 MiB limit).
- App not re-reading mounted files on change.
- Baking config into images instead.

## 8. Trade-offs
| Consumption | Pro | Con |
|-------------|-----|-----|
| Env vars | simple | static, needs restart |
| Volume files | auto-update, whole files | app must re-read |
| Immutable | performance/safety | replace to change |

## 9. Production Best Practices
- Config via ConfigMap (12-factor), not baked images.
- Volume mounts for dynamic config; reloader for restarts.
- Per-env ConfigMaps via Helm/Kustomize.
- Immutable ConfigMaps for stable config.
- Version config with the app (GitOps).

## 10. Security Considerations
- Never store secrets here — use Secrets/Key Vault.
- RBAC on ConfigMap edits.
- Validate config to prevent injection/misconfig.

## 11. Cost Optimization
- Immutable ConfigMaps reduce API watch overhead.
- Keep configs lean; avoid duplicating large blobs.

## 12. Troubleshooting Scenarios
- **Config not applied** → env var needs restart; check mount path.
- **Old values** → app not re-reading file / no reloader.
- **Pod won't start** → missing ConfigMap reference.
- **Too large** → exceeds 1 MiB; externalize.

## 13. Hands-on Example
```bash
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=info \
  --from-file=appsettings.json -n app
kubectl describe configmap app-config -n app
```

## 14. Terraform Example
```hcl
resource "kubernetes_config_map" "app" {
  metadata { name = "app-config" namespace = "app" }
  data = {
    LOG_LEVEL         = "info"
    "appsettings.json" = file("config/appsettings.prod.json")
  }
}
```

## 15. Azure Example
Pair ConfigMaps (non-sensitive) with Key Vault CSI (secrets); or use **Azure App Configuration** + provider for centralized, dynamic feature flags across AKS.

## 16. FastAPI / Python Example
```python
import os, json
LOG_LEVEL = os.getenv("LOG_LEVEL", "info")          # from ConfigMap env
with open("/etc/config/appsettings.json") as f:      # from mounted ConfigMap
    settings = json.load(f)

@app.get("/config")
def config(): return {"log_level": LOG_LEVEL, "settings": settings}
```

## 17. AKS Example (mount ConfigMap)
```yaml
spec:
  containers:
    - name: api
      image: myacr.azurecr.io/api:1.0
      envFrom: [{ configMapRef: { name: app-config } }]
      volumeMounts:
        - name: config
          mountPath: /etc/config
  volumes:
    - name: config
      configMap: { name: app-config }
```

## 18. How to Remember
**"ConfigMap = config; Secret = secrets."** Same mechanics; mounts auto-update, env vars need a restart.

## 19. Real-World Analogy
A settings menu separate from the app itself: you tweak preferences (config) without reinstalling the app (rebuilding the image) — and some settings apply instantly (mounts) while others need a restart (env vars).

## 20. One-Page Cheat Sheet
- **What**: non-sensitive key-value config, decoupled from the image (12-factor).
- **Consume**: env vars (static, need restart) or volume files (auto-update).
- **Not for secrets** → use Secrets/Key Vault.
- **Per-env**: separate ConfigMaps / Helm values / Kustomize.
- **Immutable ConfigMaps**: safer + less API load.
- **Limit**: ~1 MiB; app must re-read mounted files on change.

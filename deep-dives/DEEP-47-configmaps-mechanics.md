# DEEP MECHANICS · ConfigMaps

> Level 2 — externalizing config, consumption methods, update propagation, and
> ConfigMap vs Secret.

---

## 0. The precise mental model
A ConfigMap externalizes **non-sensitive configuration** (settings, URLs, feature flags, config files) out of the container image, so the **same image runs in every environment** with different config injected at runtime. It's the "12-factor config" mechanism — decouple config from code.

---

## 1. What it holds & consumption
Key-value pairs or whole config files. Consumed as:
- **Environment variables** (`valueFrom.configMapKeyRef` or `envFrom`).
- **Volume mount** — each key becomes a file (mount a full config file like `appsettings.json`/`nginx.conf`).
- **Command args**.

## 2. Update propagation (the gotcha)
- **Mounted** ConfigMaps **update automatically** in the Pod (eventually, with a delay) — but the **app must re-read the file**; most apps don't → need a reload mechanism or restart.
- **Env var** ConfigMaps are **injected once at start** → changes require a **Pod restart** to take effect.
- Common pattern: roll the Deployment (checksum annotation) on config change to force a restart.

## 3. ConfigMap vs Secret
| | **ConfigMap** | **Secret** |
|---|---|---|
| Data | non-sensitive config | sensitive (passwords/tokens) |
| Encoding | plaintext | base64 (+ can encrypt at rest) |
| RBAC | normal | tighter, separate |
| Use | URLs, flags, config files | credentials, certs |
Same mechanics; Secret adds sensitivity handling.

## 4. Best practices
- Keep image env-agnostic; inject per-env ConfigMaps.
- Version/track ConfigMaps (GitOps).
- Use **checksum annotations** on the Pod template so config changes trigger a rollout.
- Don't put secrets in ConfigMaps.

## 5. The hard follow-ups (with answers)
1. **"What's a ConfigMap for?"** → externalize non-sensitive config so one image runs everywhere. (§0)
2. **"How are they consumed?"** → env vars, volume-mounted files, or args. (§1)
3. **"Does changing a ConfigMap update running Pods?"** → mounted files auto-update (app must re-read); env vars need a Pod restart. (§2)
4. **"Force apps to pick up config changes?"** → restart via checksum annotation rollout. (§2,4)
5. **"ConfigMap vs Secret?"** → non-sensitive plaintext vs sensitive base64/encrypted with tighter RBAC. (§3)

## 6. One-screen recall
- ConfigMap = externalize **non-sensitive config** → one image, per-env config (12-factor).
- Consume via **env vars**, **mounted files**, or args.
- **Updates**: mounted files auto-refresh (app must re-read); **env vars need Pod restart** → use **checksum-annotation rollout**.
- **vs Secret**: plaintext config vs sensitive base64/encrypted (tighter RBAC); never put secrets in ConfigMaps.

> Next: HPA.

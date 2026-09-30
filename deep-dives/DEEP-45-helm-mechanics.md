# DEEP MECHANICS · Helm

> Level 2 — charts/templates/values, releases and revisions, templating engine,
> and why Helm vs Kustomize.

---

## 0. The precise mental model
Helm = the **package manager for Kubernetes**: it bundles a set of parameterized manifests into a **chart**, renders them with **values**, and installs/upgrades/rolls back them as a versioned **release**. It solves "managing dozens of related YAML files across environments" by making them **templated, reusable, and versioned**.

---

## 1. Anatomy of a chart
```
mychart/
  Chart.yaml        # metadata (name, version, appVersion)
  values.yaml       # default configuration values
  templates/        # Go-templated K8s manifests
    deployment.yaml
    service.yaml
    _helpers.tpl    # reusable template snippets
  charts/           # dependency subcharts
```
Templates use `{{ .Values.x }}`, `{{ .Release.Name }}` → rendered into real manifests at install.

## 2. Values & environment overrides
- `values.yaml` = defaults; override with `-f prod-values.yaml` or `--set key=val`.
- Same chart → dev/staging/prod by swapping values → **DRY multi-environment** deployment.

## 3. Releases & revisions
- Installing a chart = a **release** (a named, tracked instance).
- Each `upgrade` creates a **revision**; **`helm rollback`** reverts to a prior revision.
- Release state stored as Secrets in the cluster (Helm 3 — no Tiller).

## 4. Templating power
Go templates + Sprig functions: conditionals (`if`), loops (`range`), named templates (`_helpers.tpl`), and built-in objects (`.Release`, `.Chart`, `.Capabilities`). Enables one chart to adapt to many scenarios.

## 5. Dependencies & repos
- **Subcharts** (`charts/` + `dependencies` in Chart.yaml) compose apps.
- **Chart repositories** (or OCI registries like ACR) host/version/share charts.

## 6. Helm vs Kustomize
- **Helm** — templating + packaging + release lifecycle (install/upgrade/rollback); great for distributing apps + complex parameterization.
- **Kustomize** — **template-free overlays** (patch base YAML per environment); built into kubectl. Simpler, no templating language, no release tracking.
Many use **Kustomize for own apps, Helm for third-party**; they can combine.

## 7. The hard follow-ups (with answers)
1. **"What problem does Helm solve?"** → managing/parameterizing/versioning many related manifests across envs. (§0)
2. **"Chart vs release vs revision?"** → package vs installed instance vs a version of that install. (§1,3)
3. **"Deploy same app to dev/prod?"** → one chart + per-env values files/overrides. (§2)
4. **"How do you roll back?"** → `helm rollback` to a prior revision (state in cluster Secrets). (§3)
5. **"Helm vs Kustomize?"** → templating+packaging+lifecycle vs template-free overlays (kubectl-native). (§6)
6. **"Where does Helm 3 store state?"** → Secrets in-cluster (no Tiller). (§3)

## 8. One-screen recall
- Helm = **K8s package manager**: **chart** (templated manifests) + **values** → rendered → versioned **release**.
- Chart: **Chart.yaml**, **values.yaml**, **templates/** (Go templates + `_helpers.tpl`), `charts/` deps.
- **Values overrides** (`-f`/`--set`) → DRY multi-env.
- **Releases/revisions**: `upgrade` → new revision, **`rollback`**; state in **Secrets** (Helm 3, no Tiller).
- **Repos/OCI (ACR)** host charts; subcharts compose.
- **vs Kustomize**: templating+lifecycle vs template-free overlays (kubectl-native).

> Next: Secrets.

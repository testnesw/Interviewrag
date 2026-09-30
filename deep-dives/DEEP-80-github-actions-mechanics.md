# DEEP MECHANICS · GitHub Actions

> Level 2 — events/workflows/jobs, runners, OIDC to Azure, reusable workflows,
> and secrets/environments.

---

## 0. The precise mental model
GitHub Actions is **event-driven CI/CD** living in the repo: an **event** (push, PR, schedule, manual) triggers a **workflow** → **jobs** (on runners) → **steps** (shell or **actions**). Auth to cloud should be **keyless via OIDC**. Reuse comes from **composite/reusable workflows** and the **Marketplace**.

---

## 1. Workflow anatomy
```yaml
on: [push, pull_request]        # event triggers
jobs:
  build:
    runs-on: ubuntu-latest      # runner
    steps:
      - uses: actions/checkout@v4
      - run: pytest             # shell step
```
- File in `.github/workflows/*.yml`.
- **Event → Workflow → Jobs → Steps**. Jobs run in **parallel** by default; order via `needs:`.

## 2. Events/triggers
- `push`, `pull_request`, `schedule` (cron), `workflow_dispatch` (manual), `workflow_call` (reusable), `release`, etc.
- Path/branch filters scope triggers.

## 3. Runners
- **GitHub-hosted** (fresh VM: ubuntu/windows/macos) vs **self-hosted** (your infra — private network, GPUs, custom tools).
- Matrix builds: `strategy.matrix` → run across versions/OSes in parallel.

## 4. Actions & reuse
- **Action** = reusable step unit (`uses:`), from Marketplace or your repo (JS, Docker, or **composite**).
- **Reusable workflows** (`workflow_call`) → call one workflow from another (DRY across repos).
- **Caching** (`actions/cache`) speeds deps; **artifacts** pass files between jobs.

## 5. Secrets & OIDC (keyless auth)
- **Secrets** stored encrypted (repo/org/environment scope), masked in logs.
- **OIDC**: workflow requests a short-lived token → Azure/AWS federated credential → **no stored cloud secrets** (best practice).
- `permissions:` block → least-privilege `GITHUB_TOKEN`.

## 6. Environments & protection
- **Environments** (e.g., prod) → **required reviewers**, wait timers, environment secrets → gated deployments.
- Concurrency control (`concurrency:`) to cancel/queue overlapping runs.

## 7. Actions vs Azure DevOps (quick)
- Actions = repo-native, huge Marketplace, event-driven, YAML only.
- ADO = broader suite (Boards/Artifacts), richer classic release/approvals UI.

## 8. The hard follow-ups (with answers)
1. **"Workflow structure?"** → event → workflow → jobs (parallel, `needs` for order) → steps (run/uses). (§1)
2. **"Auth to Azure without secrets?"** → **OIDC** federated credentials → short-lived token. (§5)
3. **"Test across Python 3.9–3.12?"** → **matrix** strategy. (§3)
4. **"DRY across repos?"** → **reusable workflows** (`workflow_call`) / composite actions. (§4)
5. **"Gate production?"** → **environments** with required reviewers/wait timers. (§6)
6. **"Speed up builds?"** → `actions/cache` for deps; artifacts between jobs. (§4)
7. **"Limit token power?"** → `permissions:` least-privilege on `GITHUB_TOKEN`. (§5)

## 9. One-screen recall
- **Event → workflow → jobs (parallel, `needs`) → steps (`run`/`uses`)**; `.github/workflows`.
- **Triggers**: push/PR/schedule/dispatch/workflow_call.
- **Runners**: hosted vs self-hosted; **matrix** for combos.
- **Reuse**: Marketplace actions, composite, **reusable workflows**; cache + artifacts.
- **Secrets**: encrypted + masked; **OIDC** = keyless cloud auth; least-priv `permissions`.
- **Environments**: reviewers/wait timers = gated deploys; `concurrency`.

> Next: CI/CD Architecture.

# DEEP MECHANICS · Azure DevOps

> Level 2 — Boards/Repos/Pipelines/Artifacts, YAML pipelines, agents, and
> environments/approvals.

---

## 0. The precise mental model
Azure DevOps is an **end-to-end SDLC suite**: **Boards** (work tracking), **Repos** (Git), **Pipelines** (CI/CD), **Artifacts** (package feeds), **Test Plans**. The core engine is **YAML pipelines** running on **agents**, promoting builds through **environments** guarded by **approvals + checks**.

---

## 1. The five services
- **Boards** — backlogs, sprints, work items (Agile/Scrum/Kanban).
- **Repos** — Git repos + PR policies (branch protection, required reviewers/builds).
- **Pipelines** — CI/CD (YAML or classic).
- **Artifacts** — hosted feeds (NuGet/npm/Maven/PyPI) with upstream sources.
- **Test Plans** — manual/exploratory testing.

## 2. Pipeline anatomy (YAML)
```
trigger → Pipeline → Stages → Jobs → Steps (tasks/scripts)
```
- **Stage** = major phase (Build, Test, Deploy) → maps to environments.
- **Job** = unit run on one agent; jobs parallelize.
- **Step** = task or script.
- `trigger`/`pr` define CI triggers; `pool` selects agents.

## 3. Agents & pools
- **Microsoft-hosted** agents (fresh VM per job, maintained by MS) vs **self-hosted** (your infra — for private network access, custom tooling, caching).
- **Pools** group agents; **demands/capabilities** match jobs to agents.

## 4. Environments, approvals, checks
- **Environment** = deploy target (records deployment history) — enables **approvals**, **branch control**, **gates** (e.g., query Azure Monitor before promote).
- **Deployment jobs** (`strategy: runOnce/rolling/canary`) target environments.

## 5. Variables & security
- Variables, **variable groups** (shareable), linked to **Key Vault** for secrets.
- **Service connections** (to Azure/registries) ideally via **Workload Identity Federation (OIDC)** → no stored secrets.
- Secrets masked in logs; secure files for certs.

## 6. Reuse
- **Templates** (YAML) for DRY pipelines; **each stage/job/step** can be templated + parameterized.
- Multi-repo checkout; pipeline **artifacts** pass outputs between stages.

## 7. The hard follow-ups (with answers)
1. **"Stage vs job vs step?"** → stage = phase (env), job = runs on one agent (parallel unit), step = task/script. (§2)
2. **"Hosted vs self-hosted agent?"** → hosted = clean MS VM; self-hosted = private network/custom tools/caching. (§3)
3. **"Gate a prod deploy?"** → **environment** with approvals + checks/gates. (§4)
4. **"Secrets without storing them?"** → service connection via **OIDC/workload identity**, Key Vault-linked variable groups. (§5)
5. **"DRY across many pipelines?"** → YAML **templates** + parameters. (§6)
6. **"Enforce PR quality?"** → Repos **branch policies** (required reviewers + build validation). (§1)

## 8. One-screen recall
- **Suite**: Boards · Repos · **Pipelines** · Artifacts · Test Plans.
- **Pipeline**: trigger → **stages → jobs → steps**; YAML.
- **Agents**: MS-hosted (clean) vs self-hosted (private/custom); pools.
- **Environments** = deploy targets + **approvals/checks/gates**; deployment strategies.
- **Secrets**: variable groups + **Key Vault**, **OIDC** service connections.
- **Reuse**: templates + parameters.

> Next: GitHub Actions.

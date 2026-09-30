# DEEP MECHANICS · Model Registry

> Level 2 — versioning, stages/lifecycle, lineage, and how the registry is the
> hand-off point between training and deployment.

---

## 0. The precise mental model
A model registry is the **versioned system of record for trained models** — the governed hand-off between **training** (data science) and **serving** (ops). It stores each model **version** with its **metadata, metrics, lineage, and stage**, and drives **promotion/rollback**. It's the "artifact repository + release management" for models.

---

## 1. What it stores per version
- The model artifact (MLflow format/flavor) + **signature** (I/O schema).
- **Metadata**: metrics, params, tags, description.
- **Lineage**: which run → which data/code/env produced it (reproducibility + audit).
- **Stage/label**: Staging / Production / Archived (or custom).

## 2. Versioning & immutability
Every registration creates a new **immutable version** (v1, v2...). You never mutate a version; you register a new one and **promote** it. This gives deterministic rollback (repoint production to the previous version).

## 3. Stage transitions / lifecycle
```
Register → Staging → (validation/approval) → Production → Archived
```
Transitions can require **approval** and can **trigger CD** (a Production transition kicks off deployment). Rollback = move traffic back to the prior Production version.

## 4. Lineage & governance
Registry links model → training run → dataset version → code commit → environment. Enables: audit ("what data trained the model in prod?"), reproducibility, compliance, and impact analysis when data issues surface.

## 5. Where it lives
- **Azure ML registry** (workspace-scoped or **org-wide registry** to share models/components/environments across workspaces/regions).
- Backed by MLflow model registry semantics.

## 6. The hard follow-ups (with answers)
1. **"Why a model registry?"** → versioned system of record + governed training→serving hand-off with promotion/rollback. (§0)
2. **"What's stored per version?"** → artifact+signature, metrics/params/tags, **lineage**, stage. (§1)
3. **"How is rollback done?"** → versions are immutable; repoint Production to a prior version. (§2,3)
4. **"How do transitions drive deployment?"** → stage change (→Production) with approval triggers CD. (§3)
5. **"Share models across teams/regions?"** → org-wide Azure ML registry (not just workspace-scoped). (§5)

## 7. One-screen recall
- Model registry = **versioned system of record** + governed **training→serving** hand-off.
- Per **immutable version**: artifact+**signature**, metrics/params/tags, **lineage** (run→data→code→env), **stage**.
- Lifecycle: Register → **Staging** →(approval)→ **Production** → Archived; transition can **trigger CD**; rollback = repoint to prior version.
- **Lineage** → audit/reproducibility/compliance.
- **Azure ML registry** (workspace or **org-wide**), MLflow-backed.

> Next: Online Endpoints.

# DEEP MECHANICS · Azure Machine Learning

> Level 2 — the AML workspace, compute, jobs, pipelines, environments, and how
> training→registration→deployment actually flows.

---

## 0. The precise mental model
Azure ML is the **managed platform for the classic ML lifecycle**: prepare data → train (jobs on managed compute) → track (experiments/MLflow) → register models → deploy (endpoints) → monitor. Everything is organized under a **Workspace** and driven by **assets** (data, environments, models, components) that are **versioned and reproducible**. Think "**the MLOps control plane**."

---

## 1. The Workspace & assets
- **Workspace** — top-level container tying together compute, data, models, endpoints, and linked resources (Storage, Key Vault, Container Registry, App Insights).
- **Versioned assets**: **Data** (data assets), **Environments** (conda/docker definitions), **Models**, **Components** (reusable pipeline steps), **Jobs**. Versioning = reproducibility.

## 2. Compute types
- **Compute instance** — a personal dev VM (notebooks).
- **Compute cluster** — auto-scaling training cluster (scales to 0 when idle) → cost-efficient training.
- **Inference cluster (AKS)** / **managed online endpoints** — serving.
- **Attached compute** — bring your own (Databricks, VMs).

## 3. Jobs — how training runs
A **job** = a run of your code on compute with a defined **environment** + **inputs/outputs**:
- **command job** — run a script with params.
- **sweep job** — hyperparameter tuning (grid/random/Bayesian + early termination).
- **pipeline job** — DAG of **components** (steps) with data flowing between them → reproducible, cacheable, reusable ML workflows.
Jobs log metrics/artifacts (MLflow) to the workspace for comparison.

## 4. Environments — reproducibility
An **environment** = the docker image + conda/pip deps your job runs in, **versioned**. Guarantees training and serving use the same dependencies → no "works on my machine." Curated + custom environments.

## 5. The end-to-end flow
```
Data asset → (pipeline job: prep → train → evaluate) → metrics logged (MLflow)
   → register best Model (versioned) → deploy to Online Endpoint (blue/green)
   → monitor (data drift, performance) → retrain trigger
```

## 6. SDK/CLI & IaC
- **v2 SDK/CLI** — YAML-defined jobs/endpoints → GitOps-friendly, scriptable in CI/CD.
- Everything as code → integrate with Azure DevOps/GitHub Actions for MLOps.

## 7. The hard follow-ups (with answers)
1. **"What's the AML workspace?"** → central container for compute/data/models/endpoints + linked Storage/KV/ACR/App Insights. (§1)
2. **"How do you train at scale cheaply?"** → compute cluster that autoscales to 0 when idle; sweep jobs for HPO. (§2,3)
3. **"Make training reproducible?"** → versioned data assets + versioned environments + pipeline components. (§1,4)
4. **"What's a pipeline job?"** → DAG of reusable components with data passing, caching → reproducible workflows. (§3)
5. **"How does AML fit MLOps/CI-CD?"** → v2 YAML jobs/endpoints as code + registry + endpoints wired into pipelines. (§6)

## 8. One-screen recall
- Azure ML = managed **classic-ML lifecycle** control plane under a **Workspace** (+ Storage/KV/ACR/App Insights).
- **Versioned assets**: data, **environments**, models, components, jobs → reproducibility.
- **Compute**: instance (dev), **cluster (autoscale→0 train)**, online endpoint/AKS (serve), attached.
- **Jobs**: command, **sweep (HPO)**, **pipeline (DAG of components)**; log metrics via MLflow.
- Flow: data → pipeline(prep/train/eval) → **register model** → **online endpoint (blue/green)** → monitor(drift) → retrain.
- **v2 YAML SDK/CLI** = everything as code → MLOps CI/CD.

> Next: MLflow.

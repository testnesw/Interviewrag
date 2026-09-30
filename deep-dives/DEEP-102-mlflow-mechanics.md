# DEEP MECHANICS · MLflow

> Level 2 — the four components, tracking internals, the model flavor/registry
> concept, and how MLflow underpins reproducible MLOps.

---

## 0. The precise mental model
MLflow is the **open-source standard for the ML experiment + model lifecycle**: it **tracks** runs (params/metrics/artifacts), **packages** models in a standard format, and **manages** their versions/stages. Azure ML uses MLflow as its **native tracking + model API**, so the same code runs locally and in the cloud. Think "**git + registry for ML experiments**."

---

## 1. The four components
- **Tracking** — log **params, metrics, artifacts, and models** per **run**, grouped into **experiments**. Query/compare runs to pick the best.
- **Models** — a standard **packaging format** with **flavors** (sklearn, pytorch, pyfunc...) so any tool can load/serve it uniformly.
- **Model Registry** — versioned store with **stages** (Staging/Production/Archived) + lineage → promotion workflow.
- **Projects** — reproducible packaging of code + environment (less used in the Azure flow).

## 2. Tracking internals
```
mlflow.start_run() → log_param / log_metric / log_artifact / log_model
```
Each run stores to a **tracking server** (Azure ML workspace acts as one). Metrics are time-series (per epoch); artifacts go to blob storage. Runs are comparable in the UI → reproducibility + experiment governance.

## 3. Model flavors & pyfunc
A logged model saves the model + its **flavor(s)** + a **conda/requirements** env + signature (input/output schema). **pyfunc** is the universal flavor → `mlflow.pyfunc.load_model()` gives a uniform `predict()` regardless of framework → deploy anywhere.

## 4. Registry & stage transitions
Register a run's model → creates **versions**. Transition versions through **stages** (Staging → Production) with approvals → clean promotion + rollback (point production traffic to a version). Lineage links model → run → data/code.

## 5. Why it matters for MLOps
- **Reproducibility** — every model traces to params/data/code/env.
- **Comparability** — pick best model objectively.
- **Portability** — standard format deploys to AML endpoints, Docker, batch.
- **Automation** — registry stage transitions trigger CI/CD deploys.

## 6. The hard follow-ups (with answers)
1. **"Four MLflow components?"** → Tracking, Models, Registry, Projects. (§1)
2. **"What does tracking log?"** → params, metrics (time-series), artifacts, models per run/experiment. (§1,2)
3. **"What's a model flavor / pyfunc?"** → framework-specific packaging; pyfunc = universal predict() interface for portable deploy. (§3)
4. **"How does promotion/rollback work?"** → registry versions + stages (Staging/Production); point traffic to a version. (§4)
5. **"How does AML use MLflow?"** → workspace = tracking server + model registry; same code local↔cloud. (§0,2)

## 7. One-screen recall
- MLflow = open standard for **experiment + model lifecycle**; "git+registry for ML."
- **Tracking**: params/metrics/artifacts/models per **run**→**experiment**, comparable.
- **Models**: standard format with **flavors**; **pyfunc** = universal `predict()` → portable.
- **Registry**: versions + **stages** (Staging/Production/Archived) + lineage → promotion/rollback.
- **Projects**: reproducible code+env packaging.
- **Azure ML = native MLflow tracking server + registry** → local↔cloud parity; drives MLOps automation.

> Next: MLOps.

# 102 · MLflow

> Domain: ML Platform · Level: Principal GenAI / MLOps Architect

## 1. Beginner Explanation
MLflow is an **open-source tool for managing the machine-learning lifecycle**. It tracks your experiments (parameters, metrics, results), packages models in a standard format, and stores them in a registry — so ML work is organized, comparable, and reproducible.

## 2. Architect-Level Explanation
An open-source ML lifecycle platform with four components:
- **Tracking**: log **params, metrics, artifacts, and code version** per **run**, grouped into **experiments**; compare runs; a tracking server (backend store for metadata + artifact store for files).
- **Models**: standard packaging format (**MLmodel** + **flavors** — sklearn, pytorch, tensorflow, xgboost, pyfunc) so any model deploys uniformly; signatures + input examples.
- **Model Registry**: central store with **versioning**, **stages/aliases** (Staging/Production/Archived or aliases like `@champion`), annotations, lineage, and transitions.
- **Projects**: reproducible packaging (entry points + environment).
- **Newer**: MLflow Recipes, **LLM/GenAI tracing + evaluation**, prompt management, MLflow AI Gateway.
- **Integration**: native in **Azure ML** and **Databricks** (managed MLflow); framework-agnostic; autologging.
- **Deployment**: `mlflow models serve`, or deploy the pyfunc model to any target (Azure ML endpoints, containers, AKS).
- **Reproducibility**: pins environment + params + data version + git commit per run.

## 3. Real Enterprise Use Case
A team standardizes on MLflow (managed via Azure ML/Databricks): every training run auto-logs params/metrics/artifacts, data scientists compare runs in the UI, the best model is registered with a version and promoted via **aliases** (`@champion`), CI/CD reads the registry to deploy the Production model, and LLM app experiments use MLflow tracing/evaluation to compare prompts — full lineage and reproducibility.

## 4. Architecture Diagram (ASCII)
```
   Training code ──(autolog)──► MLflow Tracking
        │ run: params + metrics + artifacts + git + data ver
   Experiment (many runs) ─► compare in UI
        │ best run ─► register
   Model Registry: model v1, v2, v3 ...  aliases/stages
        │  @champion / Production
   CI/CD reads registry ─► deploy (Azure ML endpoint / AKS / container)
   Model format: MLmodel + flavors (pyfunc) → deploy anywhere
```

## 5. Interview Questions
1. What are MLflow's four components?
2. What does tracking log and why does it matter?
3. What is the model registry and stages/aliases?
4. What are MLflow flavors / pyfunc?
5. How does MLflow enable reproducibility + MLOps?

## 6. Strong Interview Answers
- **Components**: "Tracking (log runs — params/metrics/artifacts), Models (standard packaging format), Model Registry (versioning + stage/alias promotion), and Projects (reproducible packaging). Together they cover experiment management through deployment."
- **Tracking**: "Each run logs hyperparameters, metrics, artifacts (model files, plots), and the code/git version, grouped into experiments. This makes runs comparable and reproducible — I can see exactly which config produced which metric, essential for iterating and auditing."
- **Registry/stages**: "The registry is a central catalog of registered models with numbered **versions**, plus **stages** (Staging/Production/Archived) or the newer **aliases** (e.g., `@champion`, `@challenger`). Promotion transitions a version, and deployment pipelines reference the alias/stage — decoupling 'which model is production' from the code."
- **Flavors/pyfunc**: "A saved MLflow model includes an MLmodel file describing **flavors** — framework-specific representations (sklearn, pytorch) plus a generic **pyfunc** interface. Pyfunc means anything can load and score the model the same way (`predict`), so deployment tooling is framework-agnostic."
- **Reproducibility/MLOps**: "MLflow captures params, environment, data version, and git commit per run, so I can reproduce any result. In MLOps, CI/CD reads the registry to deploy a specific governed version, and drift/retraining registers new versions — MLflow is the backbone linking experimentation to production."

## 7. Common Mistakes
- Not logging enough (params/metrics/artifacts) → can't compare/reproduce.
- Manual model files instead of the registry → no versioning/lineage.
- Deploying by copying files, not referencing registry stage/alias.
- Ignoring model signatures → schema mismatches in serving.
- No data/git versioning alongside runs.

## 8. Trade-offs
| Aspect | Pro | Con |
|--------|-----|-----|
| Self-hosted tracking | control | ops burden |
| Managed (Azure ML/DBX) | zero ops | platform coupling |
| Aliases | flexible promotion | governance discipline needed |

## 9. Production Best Practices
- Autolog + explicit key metrics/params; log signatures + input examples.
- Register models; promote via stages/aliases; reference them in CI/CD.
- Managed MLflow (Azure ML/Databricks) for scale + security.
- Version data + git commit per run; tag runs.
- Reproducible environments (conda/Docker) with the model.

## 10. Security Considerations
- Secure tracking server + artifact store (private, RBAC).
- Managed Identity to artifact storage; no keys.
- Access control on registry (who can promote to Production).
- Audit model transitions; scan model artifacts.

## 11. Cost Optimization
- Managed MLflow avoids self-hosting cost/ops.
- Prune/archive stale runs + artifacts; lifecycle artifact storage.
- Autologging avoids re-runs (reproducibility saves compute).

## 12. Troubleshooting Scenarios
- **Can't reproduce a run** → missing env/data/git version; enforce logging.
- **Serving schema errors** → no model signature; log signature + example.
- **Wrong model in prod** → deploy referenced a version not alias; use alias/stage.
- **Artifact access denied** → identity lacks storage RBAC.
- **UI can't compare** → metrics not logged consistently across runs.

## 13. Hands-on Example
```python
import mlflow, mlflow.sklearn
mlflow.set_experiment("fraud")
with mlflow.start_run():
    mlflow.autolog()                          # auto params/metrics/model
    model.fit(X_train, y_train)
    mlflow.log_metric("auc", auc)
    mlflow.sklearn.log_model(model, "model",
        signature=mlflow.models.infer_signature(X_train, model.predict(X_train)))
```

## 14. Terraform Example
```hcl
# Azure ML workspace provides managed MLflow tracking (set as tracking URI)
resource "azurerm_machine_learning_workspace" "mlw" {
  name = "mlw-prod" resource_group_name = var.rg location = "eastus"
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id = azurerm_key_vault.kv.id
  storage_account_id = azurerm_storage_account.sa.id
  container_registry_id = azurerm_container_registry.acr.id
  identity { type = "SystemAssigned" }
}
# mlflow.set_tracking_uri(azureml://...) points to this workspace
```

## 15. Azure Example
```python
# Register + promote via alias, then deploy the aliased version
import mlflow
mlflow.set_tracking_uri("azureml://...")      # Azure ML managed MLflow
client = mlflow.MlflowClient()
mv = mlflow.register_model("runs:/<run_id>/model", "fraud")
client.set_registered_model_alias("fraud", "champion", mv.version)  # promote
```

## 16. FastAPI / Python Example
```python
# Load the aliased Production model once and serve predictions
import mlflow.pyfunc
model = mlflow.pyfunc.load_model("models:/fraud@champion")   # alias reference

@app.post("/predict")
async def predict(features: list[dict]):
    return {"predictions": model.predict(features).tolist()}  # pyfunc = uniform interface
```

## 17. AKS Example
CI/CD builds a container embedding the MLflow **pyfunc** model (`mlflow models build-docker`) and deploys it to AKS as a scalable inference service. The pipeline pulls the `@champion` version from the registry, so promoting a new champion + re-running the pipeline rolls out the new model cleanly.

## 18. How to Remember
**"4 parts: Tracking (runs: params/metrics/artifacts), Models (MLmodel + flavors/pyfunc), Registry (versions + stages/aliases), Projects. Log → register → promote → deploy."**

## 19. Real-World Analogy
A meticulous lab notebook + parts catalog for science experiments: every experiment records its exact recipe and results (tracking), successful formulas get catalog numbers and versions (registry), and a standard packaging means any lab can reproduce and use them (flavors/pyfunc). You stamp the current best formula "approved for production" (alias) so the factory always knows which to make.

## 20. One-Page Cheat Sheet
- **What**: open-source ML lifecycle tool (also managed in Azure ML/Databricks).
- **Tracking**: log params/metrics/artifacts/git per **run** in **experiments**; autolog.
- **Models**: MLmodel + **flavors** + generic **pyfunc** (deploy anywhere, uniform `predict`).
- **Registry**: versioned models + **stages/aliases** (`@champion`/Production) for promotion.
- **MLOps**: CI/CD references registry alias/stage; reproducibility via env + data + git.
- **Serve**: `models:/name@alias`, `mlflow models serve`, or build-docker → AKS/endpoint.

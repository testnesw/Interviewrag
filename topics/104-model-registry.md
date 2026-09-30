# 104 · Model Registry

> Domain: ML Platform · Level: Principal GenAI / MLOps Architect

## 1. Beginner Explanation
A model registry is a **central catalog for trained ML models**. It stores each model with a version number, tracks which one is in production, keeps its history and metadata, and lets teams promote or roll back models in a controlled way.

## 2. Architect-Level Explanation
The system of record for ML models — governance + lifecycle for model artifacts:
- **Registered model**: a named entity with multiple **versions** (immutable snapshots of the model artifact + metadata).
- **Promotion**: **stages** (None/Staging/Production/Archived) or **aliases** (`@champion`, `@challenger`) to mark which version serves — decoupling "which model is prod" from deployment code.
- **Metadata/lineage**: source run, params/metrics, data version, git commit, environment, signature/schema, author, timestamps, tags, model card.
- **Governance**: **approvals/gates** for promotion, RBAC (who can promote to Production), audit trail, reproducibility.
- **Integration**: CI/CD references the registry (deploy `models:/name@champion`); triggers on transitions (webhooks/events).
- **Where**: MLflow Model Registry, Azure ML model registry (+ cross-workspace **registries** for sharing across teams/environments), Databricks Unity Catalog models, SageMaker, Vertex.
- **Formats**: framework flavors + generic interface (pyfunc) for uniform deployment.
- **Rollback**: repoint alias/stage to a previous version instantly.
- **Feature/artifact linkage**: connect to feature store + datasets for full lineage.

## 3. Real Enterprise Use Case
A platform team runs a shared **Azure ML registry** across dev/test/prod workspaces: models are registered with lineage (run, data version, metrics), promoted through Staging→Production only after evaluation gates + human approval, deployment pipelines reference the `@champion` alias, transitions emit events that trigger CD, and rollback is a one-line alias repoint to the prior version — full audit for compliance.

## 4. Architecture Diagram (ASCII)
```
   Training run ─► register ─► Registered Model "fraud"
        ┌───────────────┬───────────────┬──────────────┐
        v1              v2              v3   (immutable versions)
        Archived        Staging      Production/@champion
   Metadata/lineage: run · metrics · data ver · git · signature · model card
   Promotion (RBAC + approval gate) ─► CD deploys models:/fraud@champion
   Rollback = repoint alias to v2  |  transition event ─► trigger pipeline
```

## 5. Interview Questions
1. What is a model registry and why is it essential?
2. Stages vs aliases for promotion?
3. What metadata/lineage should a registry hold?
4. How does the registry enable CI/CD and rollback?
5. How do you govern promotion to Production?

## 6. Strong Interview Answers
- **What/why**: "It's the system of record for models — named models with immutable, numbered versions and metadata. It's essential because it decouples 'which model is production' from code, provides lineage + reproducibility for audit, and gives a single governed control point for promotion and rollback."
- **Stages vs aliases**: "Stages (Staging/Production/Archived) are the classic model; **aliases** (`@champion`, `@challenger`) are the newer, more flexible approach — arbitrary named pointers to a version. Deployments reference the alias/stage, so promoting a new version is just moving the pointer, no code change."
- **Metadata**: "Source run and its params/metrics, the **data version**, git commit, environment, model **signature/schema**, author, timestamps, tags, and a model card (intended use, fairness, limitations). This lineage makes any production model fully reproducible and auditable."
- **CI/CD/rollback**: "Deployment pipelines reference `models:/name@champion` rather than a file, so promotion drives deployment. Transitions can emit events/webhooks that trigger CD. **Rollback** is instant — repoint the alias to the previous good version and redeploy — no rebuild needed."
- **Governance**: "RBAC controls who can promote to Production, gated by evaluation thresholds (beats baseline) and human approval for high-risk models. Every transition is audited. This turns promotion into a controlled, compliant process rather than an ad-hoc file copy."

## 7. Common Mistakes
- Deploying model files directly (no registry) → no versioning/lineage/rollback.
- Mutable "latest" model instead of immutable versions.
- No promotion gates/approvals → bad models to prod.
- Missing lineage (data/git) → irreproducible.
- No RBAC on Production promotion.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Aliases | flexible pointers | needs naming discipline |
| Strict gates/approvals | safe | slower promotion |
| Cross-team registry | sharing/reuse | governance overhead |

## 9. Production Best Practices
- Immutable versions + aliases/stages; deployments reference the alias.
- Rich lineage (run, data version, git, metrics, signature, model card).
- Promotion gates (baseline eval) + RBAC + approvals + audit.
- Event-driven CD on transitions; instant alias rollback.
- Shared registry for cross-environment reuse.

## 10. Security Considerations
- RBAC on register/promote (esp. Production); audit trail.
- Managed Identity to artifact storage; scan model artifacts.
- Signature/schema enforcement (prevent malformed serving).
- Access control + lineage for compliance (model provenance).

## 11. Cost Optimization
- Archive/prune stale versions + artifacts (lifecycle storage).
- Reuse shared registry (avoid duplicate models per team).
- Instant rollback avoids costly re-training after a bad deploy.

## 12. Troubleshooting Scenarios
- **Wrong model in prod** → deployment pinned a version, not alias; use alias.
- **Can't reproduce** → missing data/git lineage on the version.
- **Bad model shipped** → no eval gate; add baseline threshold + approval.
- **Serving schema error** → no signature registered.
- **Unauthorized promotion** → missing RBAC on Production transition.

## 13. Hands-on Example
```python
from mlflow import MlflowClient
c = MlflowClient()
mv = c.create_model_version("fraud", source="runs:/<run_id>/model", run_id="<run_id>")
c.set_registered_model_alias("fraud", "champion", mv.version)   # promote
# rollback: c.set_registered_model_alias("fraud", "champion", prev_version)
```

## 14. Terraform Example
```hcl
# Azure ML shared registry (cross-workspace model sharing/governance)
resource "azapi_resource" "ml_registry" {
  type = "Microsoft.MachineLearningServices/registries@2024-04-01"
  name = "shared-ml-registry" location = "eastus" parent_id = var.rg_id
  body = jsonencode({ properties = { regionDetails = [{ location = "eastus" }] } })
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```bash
# Register to a shared registry; promotion governed by RBAC + pipeline gates
az ml model create --name fraud --version 3 --path ./model \
  --registry-name shared-ml-registry
```

## 16. FastAPI / Python Example
```python
# Service resolves the current champion at startup; rollback needs no redeploy of code
import mlflow.pyfunc
def load_champion():
    return mlflow.pyfunc.load_model("models:/fraud@champion")   # registry alias
model = load_champion()

@app.post("/reload")            # ops endpoint to pick up a new champion
async def reload():
    global model; model = load_champion(); return {"status": "reloaded"}
```

## 17. AKS Example
An AKS inference deployment references the registry alias; a promotion event (new `@champion`) triggers an ArgoCD/CD pipeline that rolls out the new model version with canary traffic. Rollback is repointing the alias to the previous version and re-syncing — no image rebuild, fast and auditable.

## 18. How to Remember
**"System of record for models: named model → immutable versions → alias/stage says which is prod; lineage + gates + RBAC; deploy references alias; rollback = repoint."**

## 19. Real-World Analogy
A library's official catalog with edition numbers: each book edition is preserved unchanged (immutable versions), a "currently recommended edition" placard points readers to the right one (alias/Production), a librarian approves what gets recommended (governance gate), and if a new edition has errors you instantly move the placard back to the trusted edition (rollback).

## 20. One-Page Cheat Sheet
- **What**: system of record / governed catalog for trained models.
- **Structure**: named model → immutable **versions** + metadata/lineage.
- **Promotion**: **stages** (Staging/Production) or **aliases** (`@champion`) — deployments reference these.
- **Governance**: RBAC + eval gates + approvals + audit; signature/schema.
- **CI/CD**: deploy `models:/name@alias`; transition events trigger CD; **rollback = repoint alias**.
- **Where**: MLflow, Azure ML (+ cross-workspace registries), Databricks Unity Catalog.

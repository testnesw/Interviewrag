# 101 · Azure Machine Learning (Azure ML)

> Domain: ML Platform · Level: Principal GenAI / MLOps Architect

## 1. Beginner Explanation
Azure Machine Learning is a **managed platform for building, training, and deploying ML models**. It gives data scientists compute, experiment tracking, model management, and one-click deployment — so they don't manage infrastructure themselves.

## 2. Architect-Level Explanation
An end-to-end managed ML platform (the MLOps control plane on Azure):
- **Workspace**: top-level resource tying together compute, datastores, models, endpoints, experiments; backed by Storage, Key Vault, Container Registry, App Insights.
- **Compute**: **compute instances** (dev), **compute clusters** (auto-scaling training, spot), **serverless compute**, **attached** AKS/Kubernetes for inference.
- **Assets**: **datastores/data assets** (ADLS/Blob), **environments** (curated/custom Docker + conda), **models** (registry + versioning), **components/pipelines**, **jobs**.
- **Authoring**: SDK v2 (Python), CLI v2 (YAML), Designer (drag-drop), notebooks; **AutoML**; **prompt flow** for LLM apps.
- **Training**: submit **jobs** to clusters; distributed training; sweep (hyperparameter tuning); experiment tracking via **MLflow** (native).
- **Deployment**: **managed online endpoints** (real-time, autoscale, blue-green), **batch endpoints** (scoring large data), or to AKS.
- **MLOps**: pipelines, model registry, CI/CD (GitHub Actions/Azure DevOps), data/model versioning, monitoring (data drift), **responsible AI** (fairness, explainability).
- **Security**: Entra ID RBAC + **Managed Identity**, private endpoints/managed VNet, CMK, no-public-egress.
- **GenAI**: prompt flow, model catalog (foundation models), fine-tuning, integration with Azure OpenAI/AI Foundry.

## 3. Real Enterprise Use Case
A bank builds fraud detection in Azure ML: data assets on ADLS Gen2, training on auto-scaling **compute clusters** (spot), experiments tracked via MLflow, models versioned in the **registry**, an Azure ML **pipeline** retrains on schedule, deployment to a **managed online endpoint** with blue-green rollout and autoscale, **data-drift monitoring** triggering retraining, all inside a managed VNet with private endpoints + Managed Identity + Responsible AI dashboards.

## 4. Architecture Diagram (ASCII)
```
        Azure ML Workspace  (+ Storage, Key Vault, ACR, App Insights)
   ┌───────────┬────────────┬─────────────┬──────────────┐
   Data assets  Environments  Compute        Models (registry, versioned)
   (ADLS/Blob) (Docker+conda) clusters/spot
        │ submit jobs / pipelines (MLflow tracking, sweep, AutoML)
   Train ─► register model ─► Deploy
        ├─► Managed Online Endpoint (real-time, autoscale, blue-green)
        └─► Batch Endpoint (large-scale scoring)
   MLOps: CI/CD · drift monitoring · Responsible AI | managed VNet + Managed Identity
```

## 5. Interview Questions
1. What is an Azure ML workspace and its components?
2. Compute instance vs cluster vs attached AKS?
3. How does experiment tracking / model registry work?
4. Managed online vs batch endpoints?
5. How do you implement MLOps in Azure ML?

## 6. Strong Interview Answers
- **Workspace**: "It's the central resource that ties everything together — compute, datastores, environments, models, endpoints, and experiments — backed by a Storage account, Key Vault, ACR, and App Insights. It's the collaboration + governance boundary for a team's ML work."
- **Compute**: "Compute **instances** are personal dev boxes; compute **clusters** auto-scale for training jobs (and can use spot for cost, scaling to zero when idle); **serverless compute** removes cluster management; and I can attach **AKS** for high-scale or custom inference. I separate training compute from serving."
- **Tracking/registry**: "Azure ML uses **MLflow** natively — every job logs params, metrics, and artifacts for comparison and reproducibility. Trained models are registered in the **model registry** with versioning, lineage, and stage/tags, so deployment always references a specific, governed model version."
- **Online vs batch**: "**Managed online endpoints** serve real-time low-latency predictions with autoscaling and safe **blue-green** deployment (traffic split across deployments). **Batch endpoints** score large datasets asynchronously (files in → results out) — cost-efficient for offline/bulk scoring. I pick by latency vs throughput needs."
- **MLOps**: "Git-backed pipelines for repeatable training, model registry for versioned artifacts, CI/CD (GitHub Actions/Azure DevOps) to test and promote models, automated deployment to endpoints with blue-green, and monitoring for data/model **drift** that triggers retraining — all with Managed Identity, private networking, and Responsible AI checks."

## 7. Common Mistakes
- Training on compute instances instead of scalable clusters.
- Not versioning data/models → irreproducible results.
- Manual deployment (no CI/CD) → drift between envs.
- No drift monitoring → silent model degradation.
- Secrets/keys instead of Managed Identity; public workspace.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Managed online endpoint | simple, autoscale, blue-green | less low-level control than AKS |
| Batch endpoint | cheap, high throughput | not real-time |
| Spot clusters | cheap training | eviction risk |

## 9. Production Best Practices
- Clusters (spot + scale-to-zero) for training; separate serving.
- MLflow tracking + model registry versioning + lineage.
- Pipelines + CI/CD; blue-green endpoint deployments.
- Drift monitoring → automated retraining; Responsible AI.
- Managed VNet + private endpoints + Managed Identity + CMK.

## 10. Security Considerations
- Entra ID RBAC + Managed Identity (no keys); private endpoints/managed VNet.
- CMK; Key Vault for secrets; no public egress.
- Data access via Managed Identity to ADLS; audit + lineage.
- Responsible AI: fairness, explainability, content safety for GenAI.

## 11. Cost Optimization
- Spot + auto-scale + scale-to-zero clusters; auto-shutdown instances.
- Batch endpoints for bulk scoring; right-size online endpoint instances.
- Reuse cached pipeline steps; monitor per-experiment cost.

## 12. Troubleshooting Scenarios
- **Job stuck/queued** → cluster at max / quota; scale or raise quota.
- **Endpoint 5xx / OOM** → under-sized instance / model memory; scale up.
- **Irreproducible run** → unversioned data/env; pin data asset + environment.
- **Drift alerts** → input distribution shifted; retrain/rollback.
- **Auth to storage fails** → Managed Identity lacks RBAC on datastore.

## 13. Hands-on Example
```bash
az ml job create -f train-job.yml -g rg -w mlw-prod        # submit training job
az ml model create -n fraud -v 3 --path ./model -w mlw-prod  # register model
```

## 14. Terraform Example
```hcl
resource "azurerm_machine_learning_workspace" "mlw" {
  name = "mlw-prod" resource_group_name = var.rg location = "eastus"
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id = azurerm_key_vault.kv.id
  storage_account_id = azurerm_storage_account.sa.id
  container_registry_id = azurerm_container_registry.acr.id
  public_network_access_enabled = false          # managed VNet
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```yaml
# managed online endpoint deployment (YAML, CLI v2) with blue-green traffic
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: blue
endpoint_name: fraud-endpoint
model: azureml:fraud:3
instance_type: Standard_DS3_v2
instance_count: 2      # `az ml online-endpoint update --traffic "blue=90 green=10"`
```

## 16. FastAPI / Python Example
```python
# Client app calling an Azure ML managed online endpoint (Entra ID token)
import httpx
async def score(payload: dict, token: str):
    async with httpx.AsyncClient() as c:
        r = await c.post("https://fraud-endpoint.eastus.inference.ml.azure.com/score",
                         json=payload, headers={"Authorization": f"Bearer {token}"})
        return r.json()
```

## 17. AKS Example
For custom or high-scale inference, attach **AKS** to the workspace and deploy models as Kubernetes online endpoints — reusing cluster autoscaling, GPU node pools, and network policies while Azure ML manages the model lifecycle, versioning, and rollout.

## 18. How to Remember
**"Workspace ties it together; clusters train (spot/scale-to-zero), registry versions models, online/batch endpoints serve, MLflow tracks, pipelines + CI/CD + drift = MLOps."**

## 19. Real-World Analogy
A fully equipped auto factory: design studios (notebooks), an assembly line that scales up for big orders (compute clusters), a parts catalog with version numbers (model registry), quality tracking of every build (MLflow), and a showroom that swaps in new models without closing (blue-green endpoints) — while the factory manager watches for defects to trigger a redesign (drift → retrain).

## 20. One-Page Cheat Sheet
- **What**: managed end-to-end ML platform / MLOps control plane on Azure.
- **Workspace**: ties compute + data + environments + models + endpoints (Storage/KV/ACR/AppInsights).
- **Compute**: instance (dev), cluster (train, spot, scale-to-zero), serverless, attached AKS (serve).
- **Lifecycle**: jobs/pipelines + **MLflow** tracking → **model registry** (versioned) → deploy.
- **Endpoints**: managed **online** (real-time, autoscale, blue-green) vs **batch** (bulk).
- **MLOps**: CI/CD + drift monitoring + Responsible AI; managed VNet + Managed Identity + private endpoints.

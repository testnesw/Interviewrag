# 103 · MLOps

> Domain: ML Platform · Level: Principal GenAI / MLOps Architect

## 1. Beginner Explanation
MLOps is **DevOps for machine learning** — the practices and automation to build, test, deploy, and monitor ML models reliably in production. It turns one-off notebook experiments into repeatable, governed, continuously improving systems.

## 2. Architect-Level Explanation
Engineering discipline for the end-to-end ML lifecycle:
- **Beyond DevOps**: adds **data** and **models** as versioned first-class artifacts — you version code + data + model + environment (the extra dimensions vs software).
- **CI/CD/CT**: **CI** (test code + data validation + model tests), **CD** (deploy model/pipeline), **CT** (continuous training — automated retraining on new data/drift).
- **Pipelines**: automated, reproducible training pipelines (Azure ML pipelines, Kubeflow, Databricks Workflows) — feature eng → train → evaluate → register → deploy.
- **Model registry + versioning**: governed promotion (Staging→Production), lineage, approvals.
- **Deployment strategies**: blue-green, canary, shadow, A/B for models; online/batch serving.
- **Monitoring**: **data drift**, **concept drift**, model performance, prediction quality, latency, and feedback loops → trigger retraining/rollback.
- **Feature store**: consistent features for training + serving (avoid train/serve skew).
- **Governance/Responsible AI**: reproducibility, audit, fairness, explainability, approvals, model cards.
- **Maturity levels** (Google/MS): Level 0 (manual) → 1 (automated pipeline/CT) → 2 (full CI/CD automation).
- **Tooling**: MLflow, Azure ML, GitHub Actions/Azure DevOps, feature stores, monitoring.

## 3. Real Enterprise Use Case
A bank operationalizes fraud + credit models with MLOps: Git-triggered CI validates data + runs model tests, an Azure ML **pipeline** retrains, evaluates against baselines, and registers a new version; CD deploys via **canary** to an online endpoint with automatic rollback on metric regression; **drift monitoring** triggers **continuous training**; a **feature store** guarantees train/serve consistency; and every model has lineage, approvals, and a model card for audit/compliance.

## 4. Architecture Diagram (ASCII)
```
   Git (code + config)         Data (versioned)      Feature Store
        │ CI: tests + data validation + model eval        │ (train=serve)
   Training Pipeline: featurize ─► train ─► evaluate ─► register (registry)
        │ CD (approval)
   Deploy: canary/blue-green ─► Online/Batch Endpoint
        │
   Monitor: data/concept drift + perf + latency ──► trigger CT (retrain) / rollback
   Governance: lineage · approvals · Responsible AI · model cards
```

## 5. Interview Questions
1. How does MLOps differ from DevOps?
2. What is continuous training (CT)?
3. What is data drift vs concept drift?
4. What is a feature store and train/serve skew?
5. Describe MLOps maturity levels.

## 6. Strong Interview Answers
- **vs DevOps**: "MLOps extends DevOps with two extra versioned artifacts: **data** and **models**. Software is deterministic; ML behavior depends on data that changes over time, so I need data validation, model testing, reproducibility across data+code+model, and continuous monitoring/retraining — not just build/deploy."
- **CT**: "**Continuous Training** automates retraining when triggered by a schedule, new data, or detected drift. The pipeline retrains, evaluates against the current production baseline, and only promotes if it's better — keeping models fresh without manual intervention, with guardrails against regressions."
- **Drift**: "**Data drift** is when input feature distributions change (e.g., new customer behavior); **concept drift** is when the relationship between inputs and the target changes (what predicted fraud last year no longer does). Both degrade models silently, so I monitor distributions and live performance and trigger retraining/rollback."
- **Feature store**: "A centralized system serving consistent, versioned features for both training and inference. It prevents **train/serve skew** — where features computed differently offline vs online cause production failures — and enables feature reuse, point-in-time correctness, and governance."
- **Maturity**: "Level 0 is manual (notebooks, hand deployment); Level 1 automates the training pipeline with continuous training; Level 2 adds full CI/CD automation of pipelines and deployment. I assess where a team is and move them up incrementally — usually starting with tracking + registry + a repeatable pipeline."

## 7. Common Mistakes
- Versioning code but not data/models → irreproducible.
- No monitoring → silent model decay (drift).
- Manual deployment → train/serve skew, inconsistency.
- No baseline gate → shipping worse models.
- Ignoring Responsible AI/governance/audit.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Continuous training | fresh models | pipeline + monitoring cost |
| Canary/shadow | safe rollout | infra complexity |
| Feature store | consistency/reuse | added platform |

## 9. Production Best Practices
- Version code + data + model + environment; reproducible pipelines.
- CI (data validation + model tests) + CD (gated, canary/blue-green) + CT.
- Registry-driven promotion with approvals + lineage.
- Drift + performance monitoring → automated retrain/rollback.
- Feature store; Responsible AI (fairness/explainability); model cards.

## 10. Security Considerations
- Managed Identity, private networking, secrets in Key Vault.
- Access control on registry promotion (who ships to prod).
- Model + data lineage for audit/compliance; PII governance.
- Scan artifacts/containers; adversarial + content-safety checks (GenAI).

## 11. Cost Optimization
- Spot + scale-to-zero training; cache pipeline steps.
- Retrain on drift/trigger (not blindly frequent).
- Right-size serving; batch for offline; monitor per-model cost.

## 12. Troubleshooting Scenarios
- **Prod accuracy dropped** → drift; check monitors, retrain/rollback.
- **Works in training, fails live** → train/serve skew; use feature store.
- **Can't reproduce prod model** → unversioned data/env; enforce versioning.
- **Bad model shipped** → missing baseline gate; add eval threshold + approval.
- **Slow retraining loop** → manual steps; automate pipeline (CT).

## 13. Hands-on Example
```yaml
# GitHub Actions: CI trains + evaluates + registers only if it beats baseline
jobs:
  train-and-gate:
    steps:
      - run: az ml job create -f pipeline.yml -w mlw-prod   # train + evaluate
      - run: python gate.py --min-auc 0.92                  # baseline gate
      - run: az ml model create -n fraud --path model -w mlw-prod  # register if passed
```

## 14. Terraform Example
```hcl
# Provision the MLOps platform: workspace + endpoint for automated deploys
resource "azurerm_machine_learning_workspace" "mlw" { /* ...as topic 101... */ }
# CI/CD (GitHub OIDC) deploys models to this managed online endpoint with canary traffic
```

## 15. Azure Example
```bash
# Canary deploy: shift 10% traffic to the new model, auto-rollback on regression
az ml online-deployment create -f green.yml -e fraud-endpoint -w mlw-prod
az ml online-endpoint update -n fraud-endpoint --traffic "blue=90 green=10"
```

## 16. FastAPI / Python Example
```python
# Serving app logs predictions + features for drift monitoring (feedback loop)
@app.post("/predict")
async def predict(features: dict):
    pred = model.predict([features])[0]
    await log_for_monitoring(features, pred)   # captures inputs → drift detection later
    return {"prediction": pred}
```

## 17. AKS Example
An AKS-based MLOps platform runs training as **Kubeflow/Argo** pipeline pods, serves models via KServe/online endpoints with canary rollout, and scales inference with HPA/KEDA. Drift monitors (from logged predictions) trigger a pipeline that retrains, registers, and progressively rolls out the new model — GitOps-managed via ArgoCD.

## 18. How to Remember
**"DevOps + data + models; CI/CD/CT; version code+data+model+env; registry-driven promotion; monitor drift → retrain/rollback; feature store stops train/serve skew."**

## 19. Real-World Analogy
Running a restaurant kitchen with a quality system: recipes are versioned (code), ingredients tracked by batch (data), and finished dishes graded (models). New recipes are taste-tested against the current favorite before going on the menu (baseline gate + canary), and if customers stop enjoying a dish (drift), the kitchen automatically revises it (continuous training).

## 20. One-Page Cheat Sheet
- **What**: DevOps for ML — reliable, automated, governed model lifecycle.
- **Extra artifacts**: version code + **data** + **model** + environment (vs plain DevOps).
- **CI/CD/CT**: test/validate → deploy → **continuous training** (retrain on drift/new data).
- **Deploy**: blue-green / canary / shadow; online + batch; registry-driven, gated promotion.
- **Monitor**: data drift + concept drift + performance → retrain/rollback; feedback loops.
- **Enablers**: **feature store** (no train/serve skew), lineage, Responsible AI, model cards; maturity L0→L2.

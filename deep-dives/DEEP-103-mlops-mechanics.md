# DEEP MECHANICS · MLOps

> Level 2 — the maturity levels, CI/CD/CT pipelines, data/model versioning,
> drift monitoring and automated retraining — the full operating model.

---

## 0. The precise mental model
MLOps = **DevOps for ML** plus two things software doesn't have: **data** and **models** as versioned, drifting assets. The goal is **reproducible, automated, monitored** delivery of ML systems. Beyond CI/CD you add **CT (Continuous Training)** — pipelines that retrain and redeploy when data/performance changes. The discipline exists because **models decay** as the world drifts away from training data.

---

## 1. Maturity levels (Google's model)
- **Level 0** — manual: notebooks, hand-deploy. No automation.
- **Level 1** — automated **training pipeline** + CT: retrain on new data automatically, but pipeline deployment is manual.
- **Level 2** — full **CI/CD for pipelines**: automated build/test/deploy of the pipeline itself → rapid, reliable iteration.
Know where an org sits and the next step.

## 2. The three pipelines
```
CI  → lint, unit test, data validation, train, evaluate, package model
CD  → deploy model/endpoint (blue-green/canary), integration test
CT  → trigger retraining on: schedule | new data | drift | perf drop
```

## 3. What gets versioned (the ML-specific part)
- **Code** (git), **Data** (data versioning/snapshots), **Model** (registry versions), **Environment** (container/conda), **Params/metrics** (MLflow).
- **Reproducibility** = pin all five. A model = f(code, data, params, env).

## 4. Testing in ML (beyond unit tests)
- **Data validation** — schema, ranges, nulls, distribution (catch bad input).
- **Model validation** — meets metric threshold, beats baseline, no regression on slices, fairness checks.
- **Infra tests** — endpoint loads, latency SLO.
Gate deployment on these.

## 5. Monitoring & drift (the reason CT exists)
- **Data drift** — input distribution shifts from training → statistical tests (PSI, KS).
- **Concept drift** — the input→output relationship changes → performance drops.
- **Performance monitoring** — accuracy/business metric when labels arrive.
On drift/decay → **alert → retrain (CT) → validate → canary deploy**.

## 6. Deployment strategies
Blue-green (instant switch/rollback), canary (small % first), shadow (run new model on live traffic without serving) — validate a new model safely before full cutover. (See CI/CD deep dive.)

## 7. The hard follow-ups (with answers)
1. **"MLOps vs DevOps?"** → adds **data + model** as versioned/drifting assets and **CT** (retraining). (§0)
2. **"What's Continuous Training?"** → pipeline retrains+redeploys on schedule/new data/drift/perf drop. (§2,5)
3. **"What do you version for reproducibility?"** → code, data, model, environment, params/metrics. (§3)
4. **"How is ML testing different?"** → data validation + model validation (threshold/slices/fairness) + infra. (§4)
5. **"Data vs concept drift?"** → input distribution shift vs input→output relationship change; both trigger retrain. (§5)
6. **"Deploy a new model safely?"** → blue-green/canary/shadow + validation gates + rollback. (§6)

## 8. One-screen recall
- MLOps = **DevOps + data + models + CT**; exists because **models decay** (drift).
- **Maturity**: L0 manual → L1 automated training+CT → L2 CI/CD for pipelines.
- **Pipelines**: **CI** (test+train+eval+package), **CD** (deploy blue-green/canary), **CT** (retrain on schedule/new-data/drift/perf).
- **Version all five**: code, data, model, env, params. Model = f(code,data,params,env).
- **Testing**: data validation, model validation (threshold/slices/fairness), infra/latency.
- **Monitoring**: **data drift** (PSI/KS), **concept drift**, perf → alert→retrain→validate→canary.

> Next: Model Registry.

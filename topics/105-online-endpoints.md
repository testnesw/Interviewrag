# 105 · Online Endpoints (Real-Time Model Serving)

> Domain: ML Platform · Level: Principal GenAI / MLOps Architect

## 1. Beginner Explanation
Online endpoints are **live web APIs that serve model predictions in real time**. An app sends input data, the endpoint runs the model, and returns a prediction instantly (milliseconds) — used for things like fraud checks or recommendations during a user request.

## 2. Architect-Level Explanation
Real-time model serving infrastructure (Azure ML managed online endpoints, KServe, etc.):
- **Endpoint vs deployment**: an **endpoint** is a stable HTTPS URL + auth; it hosts one or more **deployments** (a model version + environment + compute), with **traffic splitting** across them.
- **Safe rollout**: **blue-green** (0→100 cutover) and **canary** (gradual traffic %) by shifting traffic between deployments; **mirror/shadow** traffic to test without affecting responses.
- **Scaling**: autoscale on CPU/GPU/RPS/latency; min/max instances; scale-to-zero (serverless) for spiky loads; GPU instances for deep learning/LLMs.
- **Serving stack**: scoring script (`init` + `run`) or no-code (MLflow model), inference server, container from ACR, health/liveness probes.
- **Performance**: batching, concurrency, model optimization (ONNX/quantization), caching, warm instances (avoid cold start).
- **Auth/security**: key or Entra ID token auth, private endpoints/managed VNet, Managed Identity, RBAC.
- **Observability**: App Insights — latency, throughput, errors, and **data collection** of inputs/outputs for drift monitoring.
- **vs batch endpoints**: online = low-latency per-request; batch = high-throughput offline scoring of large datasets.
- **Contract**: model **signature/schema** validates inputs; versioned.

## 3. Real Enterprise Use Case
A payment system serves a fraud model on an Azure ML **managed online endpoint**: two deployments (blue = current, green = new) behind one URL; new models roll out via **canary** (10%→50%→100%) with automatic rollback if latency/error SLOs regress; GPU autoscale handles peak traffic; inputs/outputs are collected for **drift monitoring**; access is via Entra ID + private endpoint — single-digit-ms predictions inside the checkout flow.

## 4. Architecture Diagram (ASCII)
```
   App ──(Entra ID / key)──► Endpoint (stable HTTPS URL)
                                │ traffic split
              ┌─────────────────┴─────────────────┐
         Deployment: blue (model v2, 90%)   Deployment: green (model v3, 10%)  ← canary
              │ autoscale (min/max, GPU)          │ mirror/shadow (test)
   Health probes · batching · warm instances (no cold start)
   App Insights: latency/errors + data collection ─► drift monitoring
   Online (low-latency/request)  vs  Batch endpoint (bulk/offline)
```

## 5. Interview Questions
1. Endpoint vs deployment; how does traffic splitting work?
2. How do you do safe rollout (blue-green/canary/shadow)?
3. How do you scale and handle cold starts?
4. Online vs batch endpoints?
5. How do you secure and monitor an endpoint?

## 6. Strong Interview Answers
- **Endpoint vs deployment**: "The **endpoint** is the stable URL + auth clients call; it can host multiple **deployments**, each being a specific model version + environment + compute. **Traffic splitting** routes a configurable percentage to each deployment, which is what enables canary and blue-green under one unchanging URL."
- **Safe rollout**: "**Blue-green**: run the new deployment alongside the old, then flip 100% traffic once validated (instant rollback by flipping back). **Canary**: gradually shift traffic (10→50→100%) watching SLOs, auto-rolling back on regression. **Shadow/mirror**: copy live traffic to the new deployment without returning its responses, to validate safely on real data."
- **Scale/cold start**: "Autoscale on RPS/CPU/GPU/latency with min/max instances; keep a warm minimum to avoid cold starts on latency-sensitive paths, or scale-to-zero for spiky, latency-tolerant workloads. For LLMs/DL I use GPU SKUs, batching, and optimized runtimes (ONNX/quantization) to hit latency + cost targets."
- **Online vs batch**: "Online endpoints serve real-time, low-latency per-request predictions (in the user flow). **Batch endpoints** asynchronously score large datasets (files in → results out) cost-efficiently. I choose by whether predictions are needed synchronously in a request or offline in bulk."
- **Secure/monitor**: "Entra ID token or key auth, private endpoints/managed VNet, Managed Identity, RBAC. I monitor latency, throughput, and errors in App Insights and enable **data collection** of inputs/outputs to feed drift monitoring and a retraining loop."

## 7. Common Mistakes
- One deployment only → no safe rollout/rollback.
- No warm instances → cold-start latency spikes.
- No autoscale → outages under load or wasted cost.
- Ignoring model signature → bad-input failures.
- No input/output logging → can't detect drift.

## 8. Trade-offs
| Strategy | Pro | Con |
|----------|-----|-----|
| Blue-green | instant rollback | 2x resources during cutover |
| Canary | gradual, low risk | slower, needs metrics |
| Scale-to-zero | cheap idle | cold starts |

## 9. Production Best Practices
- Multiple deployments + canary/blue-green + auto-rollback on SLOs.
- Autoscale with warm minimum; GPU + batching for DL/LLM.
- Enforce model signature; version deployments.
- Data collection → drift monitoring → retrain loop.
- Entra ID + private endpoints + Managed Identity; App Insights SLOs.

## 10. Security Considerations
- Entra ID token auth (over keys); private endpoints/managed VNet.
- Managed Identity to storage/registry; RBAC on endpoint.
- Input validation; rate limiting (APIM in front); content safety for GenAI.
- Protect collected inputs/outputs (may be PII).

## 11. Cost Optimization
- Scale-to-zero / min instances for spiky loads; right-size SKU.
- Batching + optimized runtime (ONNX/quantization) → fewer instances.
- Batch endpoints for offline; GPU only where needed; spot for batch.

## 12. Troubleshooting Scenarios
- **Latency spikes** → cold starts / no warm min / under-scaled; add warm instances/autoscale.
- **5xx / OOM** → model too big for SKU; scale up / GPU.
- **Bad predictions post-deploy** → wrong model version; canary + rollback.
- **429/throttling** → autoscale max too low; raise limits.
- **Drift undetected** → data collection off; enable input/output logging.

## 13. Hands-on Example
```bash
az ml online-endpoint create -n fraud-ep -w mlw-prod
az ml online-deployment create -f blue.yml -e fraud-ep --all-traffic -w mlw-prod
az ml online-deployment create -f green.yml -e fraud-ep -w mlw-prod
az ml online-endpoint update -n fraud-ep --traffic "blue=90 green=10"   # canary
```

## 14. Terraform Example
```hcl
resource "azurerm_machine_learning_online_endpoint" "ep" {
  name = "fraud-ep" location = "eastus"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.mlw.id
  auth_mode = "AADToken"                     # Entra ID auth
}
# deployments (blue/green) + traffic split managed via CLI/YAML or azapi
```

## 15. Azure Example
```yaml
# managed online deployment with autoscale + warm minimum (no cold start)
name: green
endpoint_name: fraud-ep
model: azureml:fraud:3
instance_type: Standard_NC4as_T4_v3        # GPU for DL/LLM
scale_settings: { type: target_utilization, min_instances: 2, max_instances: 10 }
```

## 16. FastAPI / Python Example
```python
# FastAPI gateway fronts the endpoint: validates input, adds auth, rate-limits
import httpx
@app.post("/fraud-check")
async def fraud_check(tx: dict, token: str = Depends(get_aad_token)):
    async with httpx.AsyncClient() as c:
        r = await c.post(ENDPOINT_URL, json={"data": [tx]},
                         headers={"Authorization": f"Bearer {token}"})
    return r.json()
```

## 17. AKS Example
Deploy the model as a Kubernetes online endpoint (KServe/Azure ML AKS) — pods behind a service, autoscaled by **HPA/KEDA** on RPS/GPU, with canary via traffic split (Istio/rollouts). GPU node pools serve LLMs; Workload Identity secures access; App Insights + Prometheus track latency/SLOs and feed the drift/retrain loop.

## 18. How to Remember
**"Endpoint = stable URL; deployments = model versions behind it; traffic split → canary/blue-green/shadow; autoscale + warm; collect I/O for drift. Online=real-time, batch=bulk."**

## 19. Real-World Analogy
A drive-through with one order window (endpoint) but two kitchens behind it (deployments). You quietly route a few cars to the new kitchen to test its food (canary); if customers complain, you instantly send everyone back to the proven kitchen (rollback). Extra cooks come on during rush (autoscale), and you keep some always on so there's no wait for the first car (warm instances).

## 20. One-Page Cheat Sheet
- **What**: real-time HTTPS model serving (low-latency per request).
- **Structure**: **endpoint** (stable URL + auth) hosts multiple **deployments** (model version + env + compute) with **traffic splitting**.
- **Rollout**: blue-green (flip), canary (gradual %), shadow/mirror (test on live traffic); auto-rollback on SLOs.
- **Scale**: autoscale (RPS/CPU/GPU) + warm min (no cold start) or scale-to-zero; GPU + batching for DL/LLM.
- **Secure**: Entra ID auth, private endpoints, Managed Identity; APIM in front for rate limiting.
- **Monitor**: App Insights SLOs + input/output collection → drift → retrain. Online vs **batch** (bulk/offline).

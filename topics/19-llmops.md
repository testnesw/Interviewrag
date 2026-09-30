# 19 · LLMOps

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
LLMOps is **DevOps/MLOps for LLM apps** — the practices and tooling to build, test, deploy, monitor, and improve GenAI systems reliably and safely in production.

## 2. Architect-Level Explanation
The operational lifecycle for LLM-powered systems:
- **Versioning**: prompts, models, retrieval indexes, and configs as versioned artifacts.
- **CI/CD**: automated eval gates (groundedness/safety) before deploy; canary/blue-green rollout.
- **Observability**: tracing (tokens, latency, cost), quality metrics, drift, and user feedback (LangSmith/App Insights/OpenTelemetry).
- **Safety/governance**: guardrails, content safety, RAI controls, audit.
- **Continuous improvement**: capture traffic → curate → re-eval / fine-tune / update RAG.
- Differs from MLOps: prompts as artifacts, non-deterministic outputs, token cost, and eval-as-gate are central.

## 3. Real Enterprise Use Case
A global copilot team: prompts/models/indexes in git, PRs run offline evals in CI, canary deploy with online A/B, full tracing to App Insights (cost/latency/quality dashboards), guardrails in-path, and a weekly loop that mines low-rated conversations to improve prompts and RAG.

## 4. Architecture Diagram (ASCII)
```
 Prompts/Model/Index (git) ─► CI: eval gates (quality+safety)
                                     │ pass
                              Canary/Blue-Green deploy
                                     │
        ┌──── Observability: tokens, latency, cost, quality, feedback ────┐
        │                        (App Insights / OTel)                    │
        └──────► Improve loop: curate traffic ─► re-eval / FT / update RAG ┘
                 Guardrails + RAI + audit run in-path
```

## 5. Interview Questions
1. How is LLMOps different from MLOps?
2. What do you version in an LLM app?
3. How do you deploy prompt/model changes safely?
4. What do you monitor in production?
5. How do you drive continuous improvement?

## 6. Strong Interview Answers
- **vs MLOps**: "LLMOps adds prompts-as-artifacts, non-deterministic evaluation (LLM-as-judge/golden sets), token-cost management, and guardrails/RAI as first-class — versus MLOps's focus on training/feature pipelines."
- **Version**: "Prompts, model/deployment versions, retrieval index/schema, and app config — so any change is traceable and rollback-able."
- **Safe deploy**: "Eval gates in CI, then canary or blue-green with online A/B and automatic rollback on quality/cost/error regressions. Never big-bang a prompt change."
- **Monitor**: "Tokens/cost per feature, latency (TTFT, p95), quality (groundedness/feedback), safety blocks, error/throttle rates, and drift."
- **Improve**: "Mine low-rated/edge-case traffic, curate into eval and training sets, and iterate prompts/RAG/fine-tune — a closed feedback loop."

## 7. Common Mistakes
- Prompts changed ad-hoc, untracked, unevaluated.
- No cost/token observability → bill shock.
- Big-bang prompt/model changes without canary.
- No feedback loop from production data.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Strict eval gates | quality safety | slower releases |
| Canary | safe rollout | more infra/complexity |
| Heavy tracing | visibility | cost/PII handling |

## 9. Production Best Practices
- Everything-as-code (prompts, models, indexes, config).
- CI eval gates + canary/blue-green + auto-rollback.
- Full tracing: cost, latency, quality, feedback.
- Guardrails + RAI + audit in the request path.
- Closed improvement loop from real traffic.

## 10. Security Considerations
- Redact PII in traces/logs; access-control eval data.
- Secrets in Key Vault; Managed Identity everywhere.
- Guardrails + content safety in production path.
- Audit trail for compliance.

## 11. Cost Optimization
- Per-feature token/cost dashboards + budgets/alerts.
- Caching, right-sized models, context trimming.
- Route cheap vs expensive requests; PTU only where justified.

## 12. Troubleshooting Scenarios
- **Cost spike** → trace tokens per feature, find loop/large context.
- **Quality regression** → compare eval metrics across versions, roll back.
- **Latency** → p95 tracing, smaller model/PTU, async, caching.
- **Silent drift** → online metrics + refreshed eval set.

## 13. Hands-on Example
```yaml
# CI step: block deploy if eval below threshold
- run: python eval.py --dataset golden.jsonl --min-groundedness 0.85 \
        --min-safety 0.99 || exit 1
```

## 14. Terraform Example
```hcl
resource "azurerm_application_insights" "llm" {
  name = "llm-appinsights" location = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  application_type = "web"
  workspace_id = azurerm_log_analytics_workspace.rai.id
}
```

## 15. Azure Example
Use **Azure AI Foundry** (prompt flow versioning + evaluation) + **Azure DevOps/GitHub Actions** for CI eval gates + **App Insights** for tracing; deploy endpoints with canary via APIM/Front Door.

## 16. FastAPI / Python Example
```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

@app.post("/chat")
def chat(msg: str):
    with tracer.start_as_current_span("llm") as span:
        r = client.chat.completions.create(model="gpt-4o",
            messages=[{"role":"user","content":msg}])
        span.set_attribute("tokens", r.usage.total_tokens)   # cost telemetry
        span.set_attribute("model", "gpt-4o")
    return {"answer": r.choices[0].message.content}
```

## 17. AKS Example
Run LLM services in AKS with OpenTelemetry sidecars → Managed Prometheus/App Insights; GitOps (ArgoCD) for prompt/config rollout; KEDA scaling; canary via service mesh; eval Jobs in the pipeline.

## 18. How to Remember
**"DevOps + prompts + evals + cost."** Version everything, gate on evaluation, watch tokens, close the loop.

## 19. Real-World Analogy
Running a professional kitchen: recipes (prompts) are versioned, dishes are tasted before serving (eval gates), portions/costs are tracked, and customer feedback constantly refines the menu.

## 20. One-Page Cheat Sheet
- **What**: DevOps/MLOps for LLM apps — build, test, deploy, monitor, improve.
- **Version**: prompts + models + indexes + config.
- **Deploy**: CI eval gates → canary/blue-green → auto-rollback.
- **Monitor**: tokens/cost, latency (p95/TTFT), quality, safety, drift, feedback.
- **Safety**: guardrails + RAI + audit in-path; PII-safe tracing.
- **Loop**: mine traffic → curate → re-eval / fine-tune / update RAG.
- **vs MLOps**: prompts-as-artifacts, non-deterministic eval, token cost central.

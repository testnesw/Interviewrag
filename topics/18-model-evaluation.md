# 18 · Model Evaluation

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Model evaluation is **measuring how good the AI's outputs are** — accuracy, relevance, safety — so you don't ship on gut feel. You test against known examples and metrics.

## 2. Architect-Level Explanation
Systematic quality measurement for LLM systems:
- **Methods**: reference-based (exact/F1/BLEU/ROUGE), **LLM-as-judge** (scored by another model), human evaluation, and task metrics (accuracy, pass@k for code).
- **RAG-specific**: groundedness/faithfulness, answer relevance, context relevance/recall.
- **Safety**: harm categories, jailbreak resistance, bias.
- **Operational**: golden/eval datasets, **online** (A/B, user feedback) vs **offline** eval, regression gating in CI.
- **Tools**: Azure AI Foundry evaluators, promptflow evals, RAGAS, DeepEval.
- Concern: evaluator reliability, dataset drift, and cost of eval runs.

## 3. Real Enterprise Use Case
A RAG copilot has a 500-item golden set. Every prompt/model change runs offline evals (groundedness, relevance, safety) gated in CI; winners go to a canary with online A/B and thumbs feedback before full rollout. No silent regressions.

## 4. Architecture Diagram (ASCII)
```
 Golden dataset ─► Run system ─► Metrics
   (Q, ref, ctx)        │        ├ groundedness
                        │        ├ relevance
                        │        ├ safety/harm
                        ▼        └ task accuracy
              CI gate (pass thresholds?)
                        ▼ pass
               Canary ─► online A/B + user feedback ─► rollout
```

## 5. Interview Questions
1. How do you evaluate an LLM/RAG system?
2. Offline vs online evaluation?
3. What is LLM-as-judge and its pitfalls?
4. How do you evaluate RAG specifically?
5. How do you catch regressions before prod?

## 6. Strong Interview Answers
- **How**: "Build a representative golden set, pick metrics per task (groundedness/relevance/safety for RAG, accuracy/pass@k for code), run offline evals in CI as gates, then validate online with A/B and user feedback."
- **Offline vs online**: "Offline is fast, repeatable, pre-deploy on fixed datasets; online measures real behavior (A/B, feedback, telemetry). You need both — offline to gate, online to confirm."
- **LLM-as-judge**: "Use a strong model to score outputs against criteria — scalable and correlates decently with humans, but has bias (position/verbosity/self-preference). Mitigate with rubrics, pairwise comparison, and periodic human calibration."
- **RAG eval**: "Separate retrieval vs generation: context recall/relevance for the retriever, groundedness/faithfulness + answer relevance for the generator — most failures are retrieval."
- **Regressions**: "Automated eval gates in CI with thresholds; block merges that drop metrics; canary + monitoring online."

## 7. Common Mistakes
- 'Looks good' shipping with no dataset/metrics.
- Only offline or only online (need both).
- Trusting LLM-judge scores without calibration.
- Static eval set that drifts from real traffic.
- Evaluating end-to-end only (can't localize failures).

## 8. Trade-offs
| Method | Pro | Con |
|--------|-----|-----|
| Reference metrics | objective, cheap | poor for open-ended text |
| LLM-as-judge | scalable, flexible | bias, cost |
| Human eval | gold standard | slow, expensive |

## 9. Production Best Practices
- Maintain a versioned, representative golden set.
- Metric suite per task; separate retrieval vs generation.
- CI eval gates with thresholds; block regressions.
- Canary + online A/B + user feedback capture.
- Refresh eval data from real (sampled, anonymized) traffic.

## 10. Security Considerations
- Anonymize/redact PII in eval datasets and logs.
- Include safety/jailbreak/bias tests in the suite.
- Access control on eval data and results.

## 11. Cost Optimization
- Smaller judge models for cheap checks; escalate selectively.
- Cache eval results; run full suite on release, subset on PRs.
- Sample rather than evaluate all traffic online.

## 12. Troubleshooting Scenarios
- **Metric dropped** → diff prompt/model/retrieval; localize retrieval vs generation.
- **Judge disagrees with users** → recalibrate rubric, add human samples.
- **Good offline, bad online** → eval set unrepresentative; refresh from traffic.
- **Flaky scores** → temperature 0 for judge, pairwise comparisons.

## 13. Hands-on Example (RAGAS)
```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_recall
result = evaluate(dataset, metrics=[faithfulness, answer_relevancy, context_recall])
```

## 14. Terraform Example
```hcl
# Store eval datasets + results for governance
resource "azurerm_storage_container" "evals" {
  name                  = "evals"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
```

## 15. Azure Example
Use **Azure AI Foundry evaluators** (groundedness, relevance, coherence, fluency, safety) on a dataset; wire results into the deployment gate; view in the portal.

## 16. FastAPI / Python Example
```python
@app.post("/evaluate")
def run_eval(dataset_id: str):
    scores = []
    for item in load_dataset(dataset_id):
        out = system(item["question"])
        scores.append({
            "grounded": groundedness(out, item["context"]),
            "relevant": relevance(out, item["question"]),
            "safe": safety(out)})
    return aggregate(scores)   # gate on thresholds in CI
```

## 17. AKS Example
Run evaluation as a Kubernetes Job in CI/CD (Argo Workflows) against a candidate model service in AKS; publish metrics to Prometheus/Grafana; block promotion if below threshold.

## 18. How to Remember
**"No metrics, no merge."** Test against a golden set; gate on numbers, not vibes.

## 19. Real-World Analogy
A restaurant's tasting panel before adding a dish to the menu: standardized criteria, repeat tastings, and customer feedback after launch — not just the chef saying "trust me."

## 20. One-Page Cheat Sheet
- **What**: measure output quality with datasets + metrics.
- **Methods**: reference metrics, LLM-as-judge, human eval, task metrics.
- **RAG**: split retrieval (recall/relevance) vs generation (groundedness/relevance).
- **Ops**: golden set → offline CI gate → canary → online A/B + feedback.
- **Judge caveats**: bias → rubrics, pairwise, human calibration.
- **Rule**: both offline and online; block regressions; refresh data from traffic.

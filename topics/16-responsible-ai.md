# 16 · Responsible AI

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Responsible AI means building AI that is **fair, safe, transparent, private, and accountable** — considering its impact on people, not just whether it works.

## 2. Architect-Level Explanation
A governance discipline operationalized across the lifecycle:
- **Microsoft RAI principles**: Fairness, Reliability & Safety, Privacy & Security, Inclusiveness, Transparency, Accountability.
- **Practices**: impact assessments, data governance, bias/fairness testing, explainability, human oversight, content safety, and documentation (model/system cards).
- **Tooling**: Responsible AI dashboard (Azure ML), Content Safety, evaluation for harms/groundedness, audit logging.
- **Regulatory**: EU AI Act risk tiers, NIST AI RMF, ISO/IEC 42001 — architects map controls to obligations.
- Concern: turning principles into enforceable, testable controls in CI/CD and operations.

## 3. Real Enterprise Use Case
A bank deploying a loan-assist model runs fairness testing across protected groups, documents a model card, requires human decision-making (AI is advisory only), logs all inferences for audit, and passes an internal RAI review board before production — mapped to EU AI Act "high-risk" controls.

## 4. Architecture Diagram (ASCII)
```
 Design ─► Impact assessment ─► Data governance
    │
 Build ─► Bias/fairness tests ─► Explainability ─► Harm evaluation
    │
 Deploy ─► Content Safety + human oversight + audit logging
    │
 Operate ─► Monitor drift/harm ─► RAI review board ─► Feedback loop
```

## 5. Interview Questions
1. What are the core Responsible AI principles?
2. How do you operationalize RAI (not just policy)?
3. How do you test for fairness/bias?
4. How does the EU AI Act affect architecture?
5. How do you ensure human oversight?

## 6. Strong Interview Answers
- **Principles**: "Fairness, reliability & safety, privacy & security, inclusiveness, transparency, accountability — I translate each into concrete, testable controls."
- **Operationalize**: "Impact assessments at design, fairness/harm tests in CI, model/system cards, content safety at runtime, audit logging, and a review board gate. Governance as code, not a PDF."
- **Fairness**: "Disaggregated evaluation across protected groups, disparity metrics (e.g., demographic parity/equalized odds where appropriate), and mitigation — using the RAI dashboard."
- **EU AI Act**: "Classify the system's risk tier; high-risk needs risk management, data governance, logging, human oversight, transparency, and conformity assessment — these become architectural requirements."
- **Human oversight**: "Keep AI advisory for consequential decisions, provide explanations, and design clear escalation/override paths."

## 7. Common Mistakes
- Treating RAI as legal box-ticking, not engineering.
- No disaggregated (per-group) evaluation.
- Full automation of high-impact decisions.
- No audit trail or model documentation.

## 8. Trade-offs
| Tension | One side | Other side |
|---------|----------|------------|
| Accuracy vs fairness | best overall metric | equitable across groups |
| Transparency vs IP/security | explainability | protecting model/data |
| Automation vs oversight | speed/cost | safety/accountability |

## 9. Production Best Practices
- RAI impact assessment + review board gate.
- Fairness/harm evaluation in CI; RAI dashboard.
- Model/system cards; full audit logging.
- Human-in-the-loop for consequential decisions.
- Ongoing monitoring for drift, bias, and harm.

## 10. Security Considerations
- Privacy by design (data minimization, PII handling, consent).
- Content safety + prompt-injection defenses.
- Access control and audit over data and model.

## 11. Cost Optimization
- Reuse standardized RAI test suites/templates.
- Automate evaluations to avoid manual review costs.
- Right-size oversight to risk tier (don't over-gate low-risk).

## 12. Troubleshooting Scenarios
- **Biased outputs** → disaggregated eval, mitigate data/model, re-test.
- **Unexplainable decisions** → add explainability (SHAP/feature importance).
- **Compliance gap** → map controls to AI Act/NIST, close missing ones.
- **Harmful generations** → strengthen content safety + evaluation.

## 13. Hands-on Example
```python
from raiutils.cohort import Cohort
# Evaluate model metrics per protected-group cohort (fairness)
report = fairness_report(model, X, y, sensitive_features=X["group"])
```

## 14. Terraform Example
```hcl
# Immutable audit logging for accountability
resource "azurerm_log_analytics_workspace" "rai" {
  name = "rai-logs" location = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  sku = "PerGB2018" retention_in_days = 365
}
```

## 15. Azure Example
Use the **Responsible AI dashboard** in Azure ML (error analysis, fairness, interpretability, counterfactuals); enable Content Safety; log inferences to Log Analytics for audit.

## 16. FastAPI / Python Example
```python
@app.post("/decision")
def decision(app_data: dict, user: User):
    score = model.predict(app_data)
    audit_log(user, app_data, score)          # accountability
    return {"recommendation": score,           # advisory only
            "explanation": explain(app_data),  # transparency
            "requires_human_review": score.borderline}
```

## 17. AKS Example
Run models in AKS with mandatory audit-logging middleware, content safety, and a human-review service for consequential decisions; enforce via Gatekeeper policies (no model without logging sidecar).

## 18. How to Remember
**"FRPITA" → Fairness, Reliability/safety, Privacy, Inclusiveness, Transparency, Accountability.** Build for people, prove it with tests and logs.

## 19. Real-World Analogy
Medical ethics for doctors: competence, do no harm, informed consent, transparency, and accountability — the same duty of care applied to AI systems.

## 20. One-Page Cheat Sheet
- **Principles**: Fairness, Reliability/Safety, Privacy/Security, Inclusiveness, Transparency, Accountability.
- **Operationalize**: impact assessment → fairness/harm tests in CI → model cards → content safety → audit → review board.
- **Fairness**: disaggregated per-group evaluation + mitigation.
- **Oversight**: humans decide consequential outcomes; provide explanations.
- **Regulation**: map to EU AI Act risk tiers / NIST AI RMF / ISO 42001.
- **Tool**: Azure RAI dashboard + Content Safety + Log Analytics.

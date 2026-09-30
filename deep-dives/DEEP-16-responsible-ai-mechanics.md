# DEEP MECHANICS · Responsible AI

> Level 2 — Microsoft's six principles operationalized, bias sources & mitigation,
> fairness metrics, explainability, and the governance lifecycle.

---

## 0. The precise mental model
Responsible AI = a **governance + engineering framework** ensuring AI systems are **fair, reliable, safe, private, inclusive, transparent, and accountable** across their lifecycle. It's not a checkbox — it's practices embedded from **design → data → training → deploy → monitor**. For an architect, it means concrete controls (bias testing, content safety, human oversight, audit) mapped to principles.

---

## 1. Microsoft's six principles (know them)
1. **Fairness** — no unjust bias across groups.
2. **Reliability & Safety** — performs consistently, fails safely.
3. **Privacy & Security** — protects data (PII, encryption, access).
4. **Inclusiveness** — works for diverse users/abilities.
5. **Transparency** — explainable, understandable decisions.
6. **Accountability** — humans responsible; governance & audit.
(Underpinned by human oversight.)

## 2. Where bias comes from
- **Data bias** — training data under/over-represents groups → skewed outputs.
- **Label bias** — human labels carry prejudice.
- **Algorithmic/aggregation bias** — model optimizes overall accuracy, hurting minorities.
- **Feedback loops** — biased predictions shape future data.
Mitigation: representative data, bias audits, reweighting/resampling, fairness constraints, diverse review.

## 3. Fairness metrics (there's no single "fair")
- **Demographic parity** — equal positive rate across groups.
- **Equalized odds** — equal TPR/FPR across groups.
- **Equal opportunity** — equal TPR.
These can **conflict** — you choose which fairness definition fits the context (a trade-off, not a universal answer). Tools: **Fairlearn** (assess/mitigate), Azure ML **Responsible AI dashboard**.

## 4. Explainability / interpretability
- **Global** — which features drive the model overall.
- **Local** — why *this* prediction (**SHAP**, LIME).
- For LLMs: citations/grounding, chain-of-thought transparency, and documenting limitations. Explainability builds trust and enables debugging bias.

## 5. Operationalizing (the lifecycle)
```
Design   → impact assessment, define fairness/harm criteria
Data     → representative, consented, documented (datasheets)
Build    → bias testing, RAI dashboard, eval, red-teaming
Deploy   → content safety, human-in-the-loop, transparency notes
Monitor  → drift, fairness over time, abuse, incident response, audit
```
Microsoft's **Responsible AI Standard** + **impact assessments** formalize this. For GenAI: content filters, groundedness, meta-prompt safety, disclosure that content is AI-generated.

## 6. Governance & accountability
- **Human oversight** — human-in-the-loop for high-stakes decisions; never fully autonomous where harm is possible.
- **Audit & logging** — trace decisions, data lineage.
- **Documentation** — model cards, transparency notes.
- **Regulatory** — EU AI Act risk tiers, GDPR; map system to obligations.

## 7. The hard follow-ups (with answers)
1. **"Six RAI principles?"** → fairness, reliability/safety, privacy/security, inclusiveness, transparency, accountability. (§1)
2. **"Where does bias enter?"** → data, labels, algorithm/aggregation, feedback loops → representative data + audits + fairness constraints. (§2)
3. **"Is there one fairness metric?"** → no; demographic parity vs equalized odds vs equal opportunity conflict — choose per context. (§3)
4. **"Explain a model's decision?"** → SHAP/LIME (local), feature importance (global); LLMs → citations/grounding. (§4)
5. **"Operationalize RAI?"** → across lifecycle: impact assessment→data→bias testing/RAI dashboard→content safety+HITL→monitoring/audit. (§5)
6. **"Tools?"** → Fairlearn, Azure ML Responsible AI dashboard, InterpretML, Content Safety. (§3,4)

## 8. One-screen recall
- RAI = govern AI to be **Fair, Reliable/Safe, Private/Secure, Inclusive, Transparent, Accountable** (+ human oversight), across the lifecycle.
- **Bias sources**: data, labels, algorithm/aggregation, feedback loops → representative data, audits, reweighting, fairness constraints.
- **Fairness metrics** conflict: demographic parity / equalized odds / equal opportunity — **choose per context**. Tool: **Fairlearn**.
- **Explainability**: global (feature importance) + local (**SHAP/LIME**); LLMs → citations/grounding.
- **Lifecycle**: impact assessment → representative/consented data → bias test + **RAI dashboard** + red-team → content safety + **HITL** + transparency → monitor drift/abuse + audit.
- **Governance**: human oversight, logging/lineage, model cards, EU AI Act/GDPR.

> Next: Fine-Tuning.

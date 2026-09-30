# 15 · AI Guardrails

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Guardrails are **safety checks around an LLM** — they filter bad inputs and outputs (hate, violence, jailbreaks, PII, off-topic) so the app behaves safely and on-policy.

## 2. Architect-Level Explanation
A layered defense wrapping the model:
- **Input guardrails**: prompt-injection/jailbreak detection, topic/allow-list, PII detection.
- **Output guardrails**: content moderation (hate/sexual/violence/self-harm), groundedness/hallucination check, PII redaction, format/schema validation.
- **Tools**: **Azure AI Content Safety** (categories + severity, Prompt Shields, groundedness detection), plus policy engines and custom validators.
- **Placement**: pre-call, post-call, and in-loop for agents/tools.
- Architect concerns: latency/cost of extra calls, false positives, and fail-open vs fail-closed policy.

## 3. Real Enterprise Use Case
A healthcare chatbot: Prompt Shields block injection, input PII is flagged, outputs are moderated + groundedness-checked against retrieved clinical docs, and any medical-advice edge cases route to a human. All decisions logged for audit.

## 4. Architecture Diagram (ASCII)
```
 User input
    │  ▼ Input guardrails: injection(Prompt Shield), PII, topic
    ▼
   LLM (+ RAG/tools)
    │  ▼ Output guardrails: moderation, groundedness, PII redaction, schema
    ▼
 Safe response  ── (block / redact / escalate to human) ──► Audit log
```

## 5. Interview Questions
1. What layers of guardrails do you implement?
2. How do you defend against prompt injection/jailbreaks?
3. Fail-open vs fail-closed — how do you decide?
4. How do you reduce false positives?
5. How is groundedness detection different from moderation?

## 6. Strong Interview Answers
- **Layers**: "Input (injection, PII, topic) + output (moderation, groundedness, PII redaction, schema) + in-loop checks for agent tool calls — defense in depth, not one filter."
- **Injection**: "Azure **Prompt Shields**, isolate untrusted/retrieved content from instructions, keep the system prompt authoritative, and constrain tool permissions so a hijack can't do damage."
- **Fail policy**: "High-risk domains (health/finance) fail-closed (block on uncertainty); low-risk internal tools may fail-open with logging. Decide per risk and regulation."
- **False positives**: "Tune severity thresholds per category, use allow-lists for domain terms, and human review to calibrate — measure precision/recall on a labeled set."
- **Groundedness vs moderation**: "Moderation checks for harmful content; groundedness checks the answer is supported by the source context — different failure modes (unsafe vs hallucinated)."

## 7. Common Mistakes
- Output-only filtering (ignoring injection at input).
- Treating retrieved text as trusted instructions.
- One global severity threshold for all categories.
- No logging → can't audit or improve.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Strict thresholds | safer | more false positives, friction |
| Extra guard calls | safety↑ | latency/cost↑ |
| Fail-closed | safe | may block valid requests |

## 9. Production Best Practices
- Defense in depth (input + output + in-loop).
- Content Safety with per-category severity tuning.
- Groundedness check for RAG; schema validation for structured output.
- Human-in-the-loop escalation for high risk.
- Log every block/redaction for audit + tuning.

## 10. Security Considerations
- Prompt-injection is the top threat — Prompt Shields + isolation.
- PII detection/redaction on input, output, and logs.
- Least-privilege tools so bypasses can't cause harm.
- Red-team regularly.

## 11. Cost Optimization
- Run cheap classifiers first; escalate to full moderation selectively.
- Cache guardrail results for repeated content.
- Batch moderation where possible.

## 12. Troubleshooting Scenarios
- **Jailbreak got through** → add Prompt Shields, strengthen system prompt, red-team.
- **Too many blocks** → recalibrate thresholds, add allow-lists.
- **Hallucinations pass** → add groundedness detection, fix retrieval.
- **Latency spike** → parallelize/cheap-first guard checks.

## 13. Hands-on Example (Content Safety)
```python
from azure.ai.contentsafety import ContentSafetyClient
res = cs_client.analyze_text(AnalyzeTextOptions(text=user_input))
if any(c.severity >= 4 for c in res.categories_analysis):
    raise BlockedContent()
```

## 14. Terraform Example
```hcl
resource "azurerm_cognitive_account" "content_safety" {
  name = "guardrails-cs" location = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  kind = "ContentSafety" sku_name = "S0"
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
Enable AOAI **content filtering** policies (adjust severity per category), add **Prompt Shields** and **groundedness detection** via Content Safety in the request path.

## 16. FastAPI / Python Example
```python
@app.post("/safe-chat")
def safe_chat(msg: str, context: str):
    if injection_detected(msg): raise HTTPException(400, "blocked")
    answer = generate(msg, context)
    if not grounded(answer, context): answer = "I don't have enough info."
    return {"answer": redact_pii(moderate(answer))}
```

## 17. AKS Example
Deploy a guardrail sidecar/service in AKS that all LLM traffic passes through (input+output checks) before/after hitting AOAI; scale with HPA; log to Log Analytics.

## 18. How to Remember
**"Bouncer at the door and editor at the exit."** Check what comes in, check what goes out.

## 19. Real-World Analogy
Airport security: screening on entry (input), and customs on exit (output) — with a supervisor called for anything suspicious (human escalation).

## 20. One-Page Cheat Sheet
- **What**: safety checks around the LLM (input + output + in-loop).
- **Input**: Prompt Shields, PII, topic allow-list.
- **Output**: moderation, groundedness, PII redaction, schema.
- **Tool**: Azure AI Content Safety (categories/severity, shields, groundedness).
- **Policy**: fail-closed for high risk; tune thresholds; log everything.
- **Top threat**: prompt injection → isolate untrusted text + least-privilege tools.

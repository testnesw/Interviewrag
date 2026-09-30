# 05 · Prompt Engineering

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Prompt engineering is **writing instructions well** so the LLM gives you the output you want — clear task, context, examples, and format.

## 2. Architect-Level Explanation
A systematic discipline of shaping model behavior via input design:
- **Structure**: system (role/rules) + user (task) + context + few-shot examples + output schema.
- **Techniques**: zero/few-shot, **chain-of-thought** (reasoning), self-consistency, **ReAct** (reason+act with tools), decomposition, **HyDE** (for retrieval).
- **Controls**: delimiters, explicit constraints, refusal/grounding instructions, output schema (JSON).
- Architect view: prompts are **versioned artifacts** with evaluation, not throwaway strings; templated and injection-hardened.

## 3. Real Enterprise Use Case
A support platform standardizes a governed system prompt (tone, policy, refusal rules), few-shot examples per intent, and JSON output schema for downstream automation — versioned in git and evaluated on a golden set before release.

## 4. Architecture Diagram (ASCII)
```
 System prompt (role + rules + safety)
        + Context (RAG chunks)
        + Few-shot examples
        + User task
        + Output schema (JSON)
                 ▼
              LLM ─► Structured, grounded answer
                 ▲
        Injection hardening (retrieved text = untrusted)
```

## 5. Interview Questions
1. Zero-shot vs few-shot vs chain-of-thought?
2. How do you make outputs reliable/parseable?
3. How do you defend prompts against injection?
4. How do you version and evaluate prompts?
5. When does prompting stop being enough (RAG/fine-tune)?

## 6. Strong Interview Answers
- **Techniques**: "Zero-shot for simple tasks; few-shot to demonstrate format/edge cases; chain-of-thought for reasoning-heavy tasks (or hidden reasoning to save tokens). Self-consistency for accuracy on hard problems."
- **Reliability**: "System role + explicit constraints + JSON schema/structured outputs + temperature 0. Validate and retry on schema failure."
- **Injection defense**: "Separate instructions from data, mark retrieved content as untrusted, never let context override system rules, and add allow/deny guardrails plus output filtering."
- **Versioning**: "Prompts live in git with tests; each change runs against a golden eval set (accuracy, grounding, safety) before promotion."

## 7. Common Mistakes
- Vague instructions; no output format.
- Cramming everything into one giant prompt.
- Trusting retrieved/user text as instructions (injection).
- Not versioning/evaluating prompt changes.

## 8. Trade-offs
| Technique | Pro | Con |
|-----------|-----|-----|
| Few-shot | better format/accuracy | more tokens |
| Chain-of-thought | reasoning↑ | tokens/latency↑, can leak reasoning |
| Strict schema | parseable | occasional refusals/retries |

## 9. Production Best Practices
- Templatize prompts; parameterize context.
- Version + eval + A/B prompts.
- Enforce output schema; validate + retry.
- Keep system prompt authoritative and injection-hardened.

## 10. Security Considerations
- Prompt-injection & jailbreak defenses; content isolation.
- Never place secrets in prompts.
- Output moderation before use/display.

## 11. Cost Optimization
- Trim few-shot examples to the minimum that passes eval.
- Use concise system prompts + prompt caching.
- Hidden/limited reasoning to cut tokens.

## 12. Troubleshooting Scenarios
- **Wrong format** → add schema + example + temp 0.
- **Ignores rules** → strengthen system prompt, reorder, use delimiters.
- **Injected behavior** → isolate data, add guardrails.
- **Verbose** → constrain length explicitly.

## 13. Hands-on Example
```text
System: You are a support agent. Answer ONLY from <context>. If unknown, say "I don't know". Output JSON: {answer, citations[]}.
Context: <retrieved chunks>
User: How do I reset my password?
```

## 14. Terraform Example
```hcl
# Store versioned prompt templates as a versioned blob for the app to load
resource "azurerm_storage_blob" "prompt_v3" {
  name                   = "prompts/support/v3.txt"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "prompts"
  type                   = "Block"
  source                 = "prompts/support_v3.txt"
}
```

## 15. Azure Example
Use **Azure AI Foundry Prompt Flow** to author, trace, and evaluate prompts, then deploy the winning variant as an endpoint.

## 16. FastAPI / Python Example
```python
from jinja2 import Template
TEMPLATE = Template(open("prompts/support_v3.txt").read())

@app.post("/support")
def support(q: str, context: str):
    prompt = TEMPLATE.render(question=q, context=context)
    r = client.chat.completions.create(model="gpt-4o", temperature=0,
        response_format={"type": "json_object"},
        messages=[{"role": "system", "content": prompt}])
    return r.choices[0].message.content
```

## 17. AKS Example
Ship prompt templates in a ConfigMap (or mounted volume) so pods reload prompt versions without image rebuilds; roll out via GitOps.

## 18. How to Remember
**"Garbage in, garbage out."** Clear role + context + examples + format = reliable output.

## 19. Real-World Analogy
Briefing a brilliant new intern: the clearer your instructions, examples, and required format, the better their work — and you don't let a sticky note (injected text) override your boss's rules.

## 20. One-Page Cheat Sheet
- **Structure**: system + context + few-shot + task + schema.
- **Techniques**: zero/few-shot, CoT, self-consistency, ReAct, HyDE.
- **Reliable output**: temp 0 + JSON schema + validate/retry.
- **Security**: isolate data, injection-harden, moderate output.
- **Ops**: version prompts in git, evaluate on golden set.
- **Escalate**: prompt → RAG (facts) → fine-tune (behavior).

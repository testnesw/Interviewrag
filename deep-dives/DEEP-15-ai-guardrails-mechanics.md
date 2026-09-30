# DEEP MECHANICS · AI Guardrails & Content Safety

> Level 2 — the layers of defense, input/output filtering, Azure AI Content
> Safety, jailbreak/injection defense, and grounding checks — how you actually
> keep an LLM app safe in production.

---

## 0. The precise mental model
Guardrails = **defense-in-depth around an unpredictable component**. You cannot make the LLM itself guaranteed-safe, so you wrap it: **validate inputs**, **constrain the model**, **filter outputs**, and **limit blast radius** of actions. Safety is a **pipeline of independent checks**, not one setting — each layer catches what others miss.

---

## 1. The layered architecture
```
User input
  ├─ [1] Input guardrails: moderation, injection/jailbreak detection, PII, topic scope
  ▼
LLM (with system prompt + grounding/RAG)
  ├─ [2] Model constraints: system rules, low temp, structured output
  ▼
Model output
  ├─ [3] Output guardrails: content moderation, groundedness check, PII redaction,
  │       schema/format validation, blocked-topic filter
  ▼
  ├─ [4] Action guardrails: least-privilege tools, human-in-the-loop for high impact
Response
```

## 2. Input guardrails
- **Content moderation** — block hate/violence/sexual/self-harm before it reaches the model.
- **Prompt injection / jailbreak detection** — classifiers for "ignore previous instructions" style attacks (Azure **Prompt Shields**).
- **PII detection** — redact before processing/logging.
- **Scope/topic filtering** — reject off-domain requests.

## 3. Output guardrails
- **Content safety** on the response (the model can still generate unsafe text).
- **Groundedness / hallucination check** — verify the answer is supported by the retrieved context (Azure **Groundedness detection**); flag/suppress ungrounded claims.
- **PII redaction**, **format/schema validation**, **citation enforcement**.

## 4. Azure AI Content Safety (the product to name)
Managed service providing:
- **Text & image moderation** across categories (Hate, Sexual, Violence, Self-harm) with **severity levels**.
- **Prompt Shields** — detect direct + indirect (document) prompt injection.
- **Groundedness detection** — is the output grounded in source data?
- **Protected material detection** — copyrighted text/code.
Azure OpenAI also has **built-in content filters** (configurable severity per category) on input and output by default.

## 5. Jailbreak & injection defense (layered — no silver bullet)
- Separate instructions from untrusted data (delimiters); treat RAG/tool content as untrusted (indirect injection).
- Prompt Shields / injection classifiers.
- **Least privilege** on tools/actions so a successful jailbreak can't do damage.
- Human-in-the-loop for irreversible/high-impact actions.
- Output filtering as the last catch.

## 6. Responsible-AI overlap & governance
Guardrails implement Responsible-AI principles operationally: fairness (bias checks), safety (content filters), privacy (PII), transparency (citations, logging). Add **red-teaming/evaluation** before deploy and **monitoring** (abuse, drift) after.

## 7. The hard follow-ups (with answers)
1. **"How do you make an LLM app safe?"** → defense-in-depth: input filter → constrained model → output filter → limited actions. (§1)
2. **"Model still outputs unsafe text despite a system prompt — why guardrails?"** → system prompt isn't a guarantee; independent output moderation catches it. (§3)
3. **"Defend against prompt injection?"** → separate untrusted data, Prompt Shields, least-privilege tools, HITL, output filter. (§5)
4. **"Check the model isn't hallucinating?"** → groundedness detection vs retrieved context; enforce citations. (§3,4)
5. **"What Azure service?"** → Azure AI Content Safety (moderation, Prompt Shields, groundedness, protected material) + Azure OpenAI content filters. (§4)
6. **"Stop PII leaks?"** → detect/redact on input, output, and logs. (§2,3)

## 8. One-screen recall
- Guardrails = **defense-in-depth** around an unpredictable LLM; a **pipeline of independent checks**, not one setting.
- **Input**: moderation, **injection/jailbreak detection (Prompt Shields)**, PII redaction, scope filter.
- **Model**: system rules + low temp + structured output.
- **Output**: content moderation, **groundedness/hallucination check**, PII redaction, schema/citation validation.
- **Action**: **least-privilege tools + human-in-the-loop** for high impact.
- **Azure AI Content Safety**: text/image moderation w/ severity, **Prompt Shields**, **Groundedness detection**, protected-material; + Azure OpenAI built-in content filters.
- Injection defense is layered — **no silver bullet**; least privilege limits blast radius.

> Next: Responsible AI.

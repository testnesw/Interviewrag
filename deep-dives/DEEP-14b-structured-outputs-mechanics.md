# DEEP MECHANICS · Structured Outputs & JSON Mode

> Level 2 — guaranteeing machine-parseable LLM output, JSON mode vs structured
> outputs, schemas, and function calling.

---

## 0. The precise mental model
When an LLM's output must be consumed by **code** (not a human), you need it to be **reliably parseable**. Three levels of guarantee: **prompt-and-hope** (weak) → **JSON mode** (valid JSON, but any shape) → **Structured Outputs** (valid JSON **conforming to your exact schema**, enforced by constrained decoding). Structured Outputs is the strong guarantee.

---

## 1. The three approaches
| Approach | Guarantee | How |
|---|---|---|
| Prompt only ("reply in JSON") | none (can drift, add prose) | instruction |
| **JSON mode** | **valid JSON** (any shape) | `response_format={"type":"json_object"}` |
| **Structured Outputs** | valid JSON **matching your schema** | `response_format` with a **JSON Schema** |
- Structured Outputs uses **constrained decoding** — the model can only emit tokens allowed by the schema → 100% schema-valid.

## 2. Structured Outputs (the strong one)
- Provide a **JSON Schema** (types, required fields, enums, nesting); the API guarantees output conforms.
- Often via a Pydantic model → JSON schema (SDKs auto-convert).
- Eliminates parsing errors, missing fields, hallucinated keys → robust pipelines.
```python
class Extract(BaseModel):
    name: str
    sentiment: Literal["pos","neg","neutral"]
completion = client.responses.parse(..., text_format=Extract)
```

## 3. Function/tool calling vs structured outputs
- **Function calling**: model decides *whether/which* tool to call + produces **arguments** (also schema-constrained) → for **taking actions**.
- **Structured Outputs**: shape the **final answer** as data → for **extraction/response formatting**.
- Both use JSON Schema; different intent (act vs format). Function-call arguments can also be made strict-schema.

## 4. Why it matters
- Powers **extraction** (docs → structured records), **classification**, **routing** (agent decides next step as an enum), **API responses**, **evals** (graders return structured verdicts).
- Removes brittle regex/JSON-repair post-processing.

## 5. Best practices
- Keep schemas **explicit** (required fields, enums over free text, descriptions guide the model).
- **Validate** anyway (defense in depth) with Pydantic → typed object.
- Watch: schema too complex → higher latency/cost; not every model/version supports strict mode.
- For refusals/edge cases, include an escape (e.g., nullable fields or a `status`).

## 6. The hard follow-ups (with answers)
1. **"JSON mode vs structured outputs?"** → JSON mode = valid JSON of *any* shape; structured outputs = valid JSON matching **your schema** (constrained decoding). (§1)
2. **"How is schema conformance guaranteed?"** → **constrained decoding** — only schema-allowed tokens can be generated. (§1)
3. **"Structured outputs vs function calling?"** → format the final answer as data vs decide/execute an action with arguments; both schema-driven. (§3)
4. **"Extract fields from invoices reliably?"** → structured outputs with a Pydantic/JSON schema. (§2/§4)
5. **"Still validate?"** → yes — defense in depth (Pydantic) + handle unsupported models. (§5)
6. **"Downside?"** → complex schemas add latency/cost; support varies by model. (§5)

## 7. One-screen recall
- Need machine-parseable output → **prompt (weak) < JSON mode (valid JSON, any shape) < Structured Outputs (schema-conformant)**.
- **Structured Outputs** = JSON Schema + **constrained decoding** → 100% valid shape; often via Pydantic.
- **Function calling** = schema-constrained **action arguments** (act); structured outputs = **format the answer** (data).
- **Uses**: extraction, classification, routing enums, API responses, eval graders.
- **Practices**: explicit schema (enums/required/descriptions), still **validate** with Pydantic, mind latency/support.

> Next: LLM Observability (LangSmith / tracing).

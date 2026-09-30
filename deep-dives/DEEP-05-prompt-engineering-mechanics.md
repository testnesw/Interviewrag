# DEEP MECHANICS · Prompt Engineering

> Level 2 — how prompts actually steer the model, the techniques that work and
> why (few-shot, CoT, structured output), prompt structure, and prompt injection
> defense.

---

## 0. The precise mental model
A prompt is **in-context conditioning**: you're not training the model, you're **shaping the probability distribution** of the next tokens by what you put in the context window. Good prompting = give the model the right **role, task, constraints, examples, and output format** so the most-likely continuation is the answer you want. Everything is about **reducing ambiguity** for a next-token predictor.

---

## 1. Anatomy of a strong prompt
```
[System]   role + rules + tone + guardrails ("You are a... Always... Never...")
[Context]  grounding facts (RAG results), background
[Task]     the specific instruction, unambiguous
[Examples] few-shot demonstrations (input→output)
[Format]   exact output schema (JSON, headings, length)
```
The **system message** has the strongest steering effect and persists across the chat.

## 2. Core techniques (and why they work)
- **Zero-shot** — just instruction. Works for simple/common tasks.
- **Few-shot** — include examples → model **pattern-matches** the demonstrated input→output mapping. Powerful for format/style consistency.
- **Chain-of-Thought (CoT)** — "think step by step" → model generates intermediate reasoning tokens before the answer → better on multi-step/math because each step conditions the next. Costs more tokens.
- **Role/persona** — "You are an expert X" → shifts distribution toward that domain's vocabulary/style.
- **Structured output** — ask for JSON / provide a schema (or use the API's JSON mode / structured outputs) → parseable, reliable downstream.
- **Delimiters** — fence user content (```), so instructions vs data are unambiguous (also injection defense).

## 3. Decomposition & advanced patterns
- **Prompt chaining** — break a complex task into sequential prompts (extract → transform → summarize). More reliable than one mega-prompt.
- **Self-consistency** — sample multiple CoT paths, take the majority answer.
- **ReAct** — reason + act (tool calls) interleaved (see Agentic AI).
- **Give the model an "out"** — "If you don't know, say so" → reduces hallucination.

## 4. What makes prompts fail
- Ambiguity, conflicting instructions, too much irrelevant context (**dilutes attention** / "lost in the middle"), no output format, expecting fresh facts the model doesn't have (→ RAG).

## 5. Prompt injection — the security angle (interviewers love this)
**Prompt injection** = malicious input overrides your instructions ("ignore previous instructions and..."). **Indirect injection** = malicious instructions hidden in retrieved/RAG content or a web page the model reads.
Defenses (layered — no single fix):
- **Separate instructions from data** with delimiters; treat retrieved content as untrusted.
- **Least privilege on tools** — the model can't do damage it isn't authorized for (RBAC on actions).
- **Output filtering / guardrails**, input validation, and **don't let model output directly trigger high-impact actions** without checks.
- System prompt reinforcement helps but is **not** a guarantee.

## 6. The hard follow-ups (with answers)
1. **"Why does few-shot work?"** → in-context pattern-matching conditions the next-token distribution on your examples. (§2)
2. **"Why does CoT improve accuracy?"** → intermediate reasoning tokens let each step condition the next → better multi-step reasoning. (§2)
3. **"Guarantee JSON output?"** → schema + API structured-output/JSON mode + validate & retry. (§2)
4. **"What is prompt injection and how do you defend?"** → malicious input overriding instructions; layered: delimiters/untrusted data, least-privilege tools, output guardrails. (§5)
5. **"Big prompt is getting worse — why?"** → irrelevant context dilutes attention ("lost in the middle"); trim/chain. (§4)

## 7. One-screen recall
- Prompt = **in-context conditioning** of a next-token predictor → reduce ambiguity.
- Structure: **system(role/rules) + context + task + examples + format.** System msg steers strongest.
- Techniques: **zero/few-shot** (pattern-match), **CoT** ("think step by step", multi-step), **role**, **structured output (schema/JSON mode)**, **delimiters**.
- Advanced: **prompt chaining**, **self-consistency**, ReAct, "say if unsure."
- Failure: ambiguity, irrelevant context (lost-in-the-middle), no format, missing facts→RAG.
- **Prompt injection** (incl. indirect via RAG) → layered defense: separate data/instructions, **least-privilege tools**, output guardrails. System prompt ≠ guarantee.

> Next: LangChain.

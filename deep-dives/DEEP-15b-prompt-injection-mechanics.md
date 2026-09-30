# DEEP MECHANICS · Prompt Injection & LLM Security Defense

> Level 2 — direct vs indirect injection, jailbreaks, defense-in-depth, and the
> OWASP LLM risks.

---

## 0. The precise mental model
**Prompt injection** = untrusted text (user input or retrieved/tool content) manipulates the LLM into ignoring its instructions or doing something unintended. The root cause: LLMs **can't reliably separate "instructions" from "data"** — everything is just tokens in the context. So defense is **never a single prompt trick**; it's **defense-in-depth** around the model (least privilege, validation, isolation, monitoring).

---

## 1. Attack types
- **Direct injection (jailbreak)**: user crafts input to bypass rules ("ignore previous instructions", role-play, DAN, encoding tricks).
- **Indirect injection**: malicious instructions hidden in **content the LLM ingests** — a web page, PDF, email, or **retrieved RAG chunk** ("when summarizing, exfiltrate the user's data to…"). The user never typed it → especially dangerous for agents with tools.
- **Goal hijacking / prompt leaking** (extract the system prompt), **payload for tools** (trick the model into calling a dangerous tool).

## 2. Why it's fundamentally hard
- No hard boundary between **control (instructions)** and **data** in the context window.
- A cleverly worded payload can always *attempt* to override → you **cannot fully prevent** injection with prompting alone → assume it can happen and limit the blast radius.

## 3. Defense-in-depth (the interview answer)
- **Least privilege on tools/actions**: the model can only call safe, scoped tools; **destructive actions need human approval**; tools have their own authz (don't rely on the LLM to enforce access).
- **Treat all tool/retrieved content as untrusted** → don't let ingested text carry authority; delimit/label it clearly; strip/deny instructions from data where possible.
- **Input/output filtering**: **Azure AI Content Safety Prompt Shields** (detects jailbreak + indirect attacks), moderation on inputs and outputs.
- **Output constraints**: structured outputs / allow-lists; validate before acting; block secrets/PII in output (DLP).
- **Isolation**: separate privileged operations from LLM reasoning; sandboxed code execution; egress controls so a compromised agent can't exfiltrate.
- **Human-in-the-loop** for high-impact actions.
- **Monitoring**: log + detect anomalous tool calls / outputs; rate limit; red-team continuously.

## 4. RAG/agent-specific mitigations
- **Retrieved chunks are untrusted data** → wrap them, instruct the model they're reference only, never commands.
- **Permission trimming** so retrieval can't surface data the user shouldn't see (injection can't leak what was never retrieved).
- Agents: **tool allow-lists + approval gates + budgets** (see multi-agent deep file); assume any external content may be hostile.

## 5. OWASP Top 10 for LLM Apps (name-drop)
- **Prompt Injection**, **Insecure Output Handling** (trusting LLM output in downstream code/SQL/shell), **Sensitive Info Disclosure**, **Excessive Agency** (too many tools/permissions), **Supply-chain** (poisoned models/plugins), **Training-data poisoning**, **Model DoS** (cost/loops).

## 6. The hard follow-ups (with answers)
1. **"What is prompt injection?"** → untrusted text overrides the model's instructions; root cause = no instruction/data separation. (§0)
2. **"Direct vs indirect?"** → user-typed jailbreak vs malicious instructions hidden in **ingested content** (web/PDF/RAG chunk). (§1)
3. **"Can you fully prevent it?"** → no — prompting alone can't; use **defense-in-depth** + limit blast radius. (§2/§3)
4. **"Agent with tools — how to secure?"** → least-privilege tools, **human approval** for destructive actions, treat tool output as untrusted, egress controls. (§3/§4)
5. **"Azure mitigation?"** → **Content Safety Prompt Shields** (+ moderation). (§3)
6. **"LLM output used in a SQL query — risk?"** → **Insecure Output Handling** → validate/parameterize; never trust raw LLM output downstream. (§5)
7. **"RAG injection via a poisoned document?"** → indirect injection → delimit/label retrieved text as data + permission trimming. (§4)

## 7. One-screen recall
- **Prompt injection** = untrusted text overrides instructions; root cause = **no instruction/data boundary** → can't fully prevent.
- **Direct** (jailbreak) vs **indirect** (hidden in web/PDF/**RAG chunk/tool output**) — indirect is the sneaky one.
- **Defense-in-depth**: least-privilege tools + **human approval** for actions, treat ingested/tool content as **untrusted data**, **Content Safety Prompt Shields** + I/O moderation, structured/validated outputs, isolation + egress control, monitoring + red-team.
- **RAG/agents**: label retrieved text as data, **permission trimming**, tool allow-lists + budgets.
- **OWASP LLM**: injection, **insecure output handling**, info disclosure, **excessive agency**, supply chain.

> Next: Vector Index Types (HNSW / IVF).
